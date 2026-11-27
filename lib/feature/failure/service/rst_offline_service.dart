import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'depot_offline_service.dart';
import 'failure_service.dart';

/// RST failures (PPIO creates / assigns / closes, Junior Engineer accepts /
/// fills the work details, completion and SIC) saved without internet: the call
/// and its images are kept (queue + a "Pending Sync" entry in the list or a
/// pending marker on the failure) and sent when the internet is back
/// (MasterDataSyncService.syncPendingSubmissions).
class RstOfflineService {
  RstOfflineService({FailureService? failureService})
      : _service = failureService ?? FailureService();

  final FailureService _service;

  static const String queueType = 'RST';

  /// FailureList key of the RST failures created offline and not sent yet.
  static const String listKey = 'RstOffline';

  /// Queue actions (one per part of the web flow).
  static const String actionCreate = 'rstCreate'; // Part A
  static const String actionUpdate = 'rstUpdate'; // Part A edit
  static const String actionAssign = 'rstAssign'; // Part B
  static const String actionAccept = 'rstAccept'; // Part C
  static const String actionRca = 'rstRca'; // Part D
  static const String actionCompletion = 'rstCompletion'; // Part E
  static const String actionClose = 'rstClose'; // Part G
  static const String actionDelete = 'rstDelete';

  /// Name shown on the "Pending: ..." chip of a failure with a waiting action.
  static String label(String? action) {
    switch (action) {
      case actionCreate:
        return 'RST Failure';
      case actionUpdate:
        return 'Failure Update';
      case actionAssign:
        return 'Assignment';
      case actionAccept:
        return 'Acceptance';
      case actionRca:
        return 'Work Details';
      case actionCompletion:
        return 'Work Completion';
      case actionClose:
        return 'Close';
      case actionDelete:
        return 'Delete';
      default:
        return 'RST Action';
    }
  }

  /// Same keep-the-images rule and offline number format as the depot flow.
  static Future<List<String>> keepFiles(List<String> paths) =>
      DepotOfflineService.keepFiles(paths);

  static Future<String> offlineNumber() =>
      DepotOfflineService.offlineNumber('RST');

  /// Sends one queued call. Returns the server's answer (the new failure number
  /// for a create). Throws when the server cannot be reached (network error) or
  /// answers with an error.
  ///
  /// payload: {action, queuedBy, notificationId, endpoint, field, body, asJson,
  /// files: [{field, path}]}
  Future<String?> replay(Map<String, dynamic> payload) async {
    final files = <http.MultipartFile>[];
    final saved = payload['files'] is List ? payload['files'] as List : const [];
    for (final f in saved) {
      if (f is! Map) continue;
      final path = '${f['path']}';
      if (await File(path).exists()) {
        files.add(await http.MultipartFile.fromPath('${f['field']}', path));
      }
    }
    final body = Map<String, dynamic>.from(payload['body'] as Map);
    final asJson = payload['asJson'] == true;
    final result = await _service.sendRstCall(
      '${payload['endpoint']}',
      fields: asJson ? null : {'${payload['field']}': jsonEncode(body)},
      jsonBody: asJson ? body : null,
      files: files,
    );
    for (final f in saved) {
      try {
        if (f is Map) await File('${f['path']}').delete();
      } catch (_) {}
    }
    return result;
  }
}
