import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../service/auth_manager.dart';
import '../../../service/local_database_service.dart';
import '../../../service/network_service/network_errors.dart';
import 'failure_log.dart';
import 'failure_service.dart';
import 'rst_offline_service.dart';

/// An attachment to send: the multipart field and the file on the device.
class RstFile {
  const RstFile(this.field, this.path);
  final String field;
  final String path;
}

enum RstSubmitState { sent, queued }

class RstSubmitResult {
  const RstSubmitResult(this.state, this.message);
  final RstSubmitState state;

  /// What the server answered (the new failure number for a create).
  final String? message;

  bool get queued => state == RstSubmitState.queued;
}

/// Sends one RST call. With internet it goes straight to the server; without it
/// (or when the server cannot be reached) the call and its images are kept on
/// the device and sent by the sync when the internet is back. A server error
/// (the server answered "no") is thrown and nothing is kept.
class RstSubmitHelper {
  RstSubmitHelper({FailureService? failureService})
      : _service = failureService ?? FailureService();

  final FailureService _service;

  Future<RstSubmitResult> submit({
    required String action,
    required String endpoint,
    required Map<String, dynamic> body,
    String? field,
    bool asJson = false,
    List<RstFile> files = const [],
    int notificationId = 0,

    /// A create also gets a "Pending Sync" entry in the list; give its details.
    Map<String, dynamic>? offlineEntry,
  }) async {
    try {
      final multipart = <http.MultipartFile>[];
      for (final f in files) {
        multipart.add(await http.MultipartFile.fromPath(f.field, f.path));
      }
      final answer = await _service
          .sendRstCall(
            endpoint,
            fields: asJson ? null : {field ?? '': _json(body)},
            jsonBody: asJson ? body : null,
            files: multipart,
          )
          .timeout(const Duration(seconds: 60));
      // A closed / deleted failure leaves the list without a word from the
      // server: the next sync takes everything.
      if (action == RstOfflineService.actionClose ||
          action == RstOfflineService.actionDelete) {
        await LocalDatabaseService().setAppSetting('rstTxnFullNeeded', '1');
      }
      return RstSubmitResult(RstSubmitState.sent, answer);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      failureLog('RstSubmitHelper: $action kept for later ($e)');
      await _queue(
        action: action,
        endpoint: endpoint,
        body: body,
        field: field,
        asJson: asJson,
        files: files,
        notificationId: notificationId,
        offlineEntry: offlineEntry,
      );
      return const RstSubmitResult(RstSubmitState.queued, null);
    }
  }

  static String _json(Map<String, dynamic> body) => jsonEncode(body);

  Future<void> _queue({
    required String action,
    required String endpoint,
    required Map<String, dynamic> body,
    required String? field,
    required bool asJson,
    required List<RstFile> files,
    required int notificationId,
    required Map<String, dynamic>? offlineEntry,
  }) async {
    final db = LocalDatabaseService();
    final me = await AuthManager().getUserId() ?? '';
    final kept = <Map<String, String>>[];
    for (final f in files) {
      final copy = await RstOfflineService.keepFiles([f.path]);
      if (copy.isNotEmpty) kept.add({'field': f.field, 'path': copy.first});
    }
    final sid = await db.insertPendingSubmission({
      'action': action,
      'queuedBy': me,
      'notificationId': notificationId,
      'endpoint': endpoint,
      'field': field,
      'asJson': asJson,
      'body': body,
      'files': kept,
    }, RstOfflineService.queueType);

    if (action == RstOfflineService.actionCreate) {
      final entry = offlineEntry ?? const <String, dynamic>{};
      await db.insertFailureList([
        {
          'id': -(sid * 10),
          'failureNo': await RstOfflineService.offlineNumber(),
          'failureDescription': entry['failureDescription'] ?? '',
          'functionalLocation': entry['functionalLocation'] ?? '',
          'statusName': 'Pending Sync',
          'failureOccuranceDateTime': entry['failureOccuranceDateTime'] ?? '',
          'priority': entry['priority'] ?? '',
          'departmentName': entry['departmentName'] ?? '',
          'creationType': 'RST',
          'syncStatus': 'offline',
        }
      ], RstOfflineService.listKey);
      return;
    }
    if (notificationId > 0) {
      await db.setRstPending(notificationId, action);
      final record = await db.getRstFailureCacheRow(notificationId);
      if (record != null) {
        await db.saveRstFailureRecord(
            notificationId, RstLocalPatch.apply(action, record, body));
      }
    }
  }
}

/// What the screen shows of a change that is waiting to be sent: the stored
/// record gets the new values (the server's copy replaces it after the send).
class RstLocalPatch {
  RstLocalPatch._();

  static Map<String, dynamic> apply(
      String action, Map<String, dynamic> record, Map<String, dynamic> body) {
    final out = Map<String, dynamic>.from(record);
    final f = out['failure'] is Map
        ? Map<String, dynamic>.from(out['failure'] as Map)
        : <String, dynamic>{};
    List<Map<String, dynamic>> rows(dynamic v) => v is List
        ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)]
        : <Map<String, dynamic>>[];

    switch (action) {
      case RstOfflineService.actionAssign:
        f['trainRunningKM'] = int.tryParse('${body['TrainRunningKM']}') ?? f['trainRunningKM'];
        f['assignedUserId'] = int.tryParse('${body['ResponsiblePersonId']}') ?? f['assignedUserId'];
        f['isSICReq'] = body['IsSICRequired'] == true;
        f['isJointInspectionReq'] = body['IsJoinInspectionRequired'] == true;
        f['isOHEReq'] = body['IsOHEReq'] == true;
        out['sicDetails'] = [
          for (final s in rows(body['DataSIC']))
            if ('${s['IsDeleted']}' != '1')
              {
                'notificationId': f['notificationId'],
                'id': s['Id'],
                'sicTypeId': int.tryParse('${s['SICTypeId']}') ?? 0,
                'sicType': s['SICType'],
                'responsiblePersonId': int.tryParse('${s['ResponsiblePersonId']}') ?? 0,
                'responsiblePerson': s['ResponsiblePerson'],
                'isDeleted': 0,
              }
        ];
        out['joinInspectionDetails'] = [
          for (final j in rows(body['DataJI']))
            if ('${j['IsDeleted']}' != '1')
              {
                'id': j['Id'],
                'jI_Dept_Id': int.tryParse('${j['JI_Dept_Id']}') ?? 0,
                'jI_Dept_Name': j['JI_Dept_Name'],
                'jI_ResponsiblePersonId': int.tryParse('${j['JI_ResponsiblePersonId']}') ?? 0,
                'jI_ResponsiblePerson': j['JI_ResponsiblePerson'],
                'jI_Remark': j['JI_Remark'],
                'jI_Status': j['JI_Status'],
                'jI_StatusId': j['JI_StatusId'],
                'isDeleted': false,
              }
        ];
        f['statusName'] = 'Assigned';
        break;
      case RstOfflineService.actionAccept:
        f['isWorkAllotedAccept'] = body['IsWorkAllotedAccept'] == true;
        f['powerBlockRequired'] = body['IsPowerBlockReq'] == true;
        out['workAllotedDetails'] = [
          for (final w in rows(body['DataWorkAlloted']))
            {
              'notificationId': f['notificationId'],
              'id': w['Id'],
              'maintainerUserId': int.tryParse('${w['MaintainerUserId']}') ?? 0,
              'maintainerUserName': w['MaintainerUserName'],
              'workAllotedId': w['WorkAllotedId'] ?? 0,
              'workAllotedName': w['WorkAllotedName'],
              'isDeleted': 0,
            }
        ];
        break;
      case RstOfflineService.actionRca:
        final je = body['changeNotifictionJE'];
        if (je is Map) {
          f['failureTypeId'] = je['FailureTypeId'];
          f['isHardwareReplaced'] = je['IsHardwareReplaced'] == true;
          f['isMaterialSwapped'] = je['IsMaterialSwapped'] == true;
          f['carriedOutRemarks'] = je['Description'];
        }
        break;
      case RstOfflineService.actionCompletion:
        f['isWorkCompletion'] = true;
        f['userStatus'] = body['TrainStatusId'];
        f['failureAttendedDate'] = body['ActualWorkStartDate'];
        f['actualFailureRectifiedDate'] = body['ActualWorkCompleteDate'];
        break;
      case RstOfflineService.actionClose:
        f['statusName'] = 'Closed';
        f['statusId'] = 39;
        break;
      case RstOfflineService.actionDelete:
        f['isDeleted'] = true;
        break;
      default:
        break;
    }
    out['failure'] = f;
    return out;
  }
}
