import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../service/auth_manager.dart';
import '../../../service/local_database_service.dart';
import '../../../core/controller/session_controller.dart';
import '../../../service/master_data_sync_service.dart';
import 'failure_service.dart';
import 'si_ids.dart';

/// Junior Engineer actions that also work without internet: the failure form
/// is tried online; if the server cannot be reached it is saved locally (queue
/// + the failure is marked as waiting) and sent when internet returns
/// (MasterDataSyncService.syncPendingSubmissions).
class JeOfflineService {
  JeOfflineService({FailureService? failureService})
      : _service = failureService ?? FailureService();

  final FailureService _service;
  final LocalDatabaseService _db = LocalDatabaseService();

  static const String queueType = 'JE';

  /// The encrypted id (jobCardNo) of a failure, which the update call sends as
  /// the failure Id. It comes with each jeFailure of the sync.
  Future<String> encryptedIdFor(
      {required int notificationId,
      String? code,
      bool retryAfterSync = true}) async {
    final row = await _db.findJeFailure(notificationId: notificationId, code: code);
    final record = row?['record'] as Map<String, dynamic>?;
    final je = record?['jeFailure'] is Map ? record!['jeFailure'] as Map : const {};
    final fromSync = encryptedIdFromSiFailure(je, notificationId);
    if (fromSync != null) return fromSync;
    final kept = record?['encryptedId']?.toString() ?? '';
    if (kept.isNotEmpty) return kept;

    // Not in the synced data: the inbox lists carry it as the failure number.
    final deptId = Get.isRegistered<SessionController>()
        ? Get.find<SessionController>().selectedDepartment.value?.deptId ?? 0
        : 0;
    final found = await _service.findJeEncryptedId(
        notificationId: notificationId, code: code, deptId: deptId);
    if ((found ?? '').isNotEmpty) {
      await _db.setJeEncryptedId(notificationId, found!);
      return found;
    }

    // Failures downloaded before the server sent jobCardNo have no id yet and
    // an incremental sync would not bring them again: download all once.
    if (retryAfterSync) {
      final synced = await Get.find<MasterDataSyncService>()
          .syncFailureTransactions(forceAll: true);
      if (!synced) {
        throw TimeoutException('Server not reached to get the failure id');
      }
      return encryptedIdFor(
          notificationId: notificationId, code: code, retryAfterSync: false);
    }
    throw Exception(
        'The failure id (jobCardNo) is missing in the synced data, so this cannot be sent.');
  }

  /// Keeps the picked images with the app: the picker's temporary files can be
  /// removed before the internet is back.
  Future<Map<String, String>> _keepFiles(Map<String, String> filePaths) async {
    final out = <String, String>{};
    if (filePaths.isEmpty) return out;
    final dir = Directory(p.join(
        (await getApplicationDocumentsDirectory()).path, 'je_offline_files'));
    if (!await dir.exists()) await dir.create(recursive: true);
    for (final e in filePaths.entries) {
      try {
        final name = '${DateTime.now().microsecondsSinceEpoch}_${p.basename(e.value)}';
        out[e.key] = (await File(e.value).copy(p.join(dir.path, name))).path;
      } catch (err) {
        debugPrint('JeOfflineService: could not keep ${e.value}: $err');
      }
    }
    return out;
  }

  /// The failure form saved offline (UpdateChangeNotificationJE payload plus
  /// its images, by field name: beforeImage / afterImage / rcaImage).
  Future<void> queueUpdate({
    required int notificationId,
    required Map<String, dynamic> payload,
    Map<String, String> filePaths = const {},
  }) async {
    final kept = await _keepFiles(filePaths);
    await _db.insertPendingSubmission({
      'action': 'update',
      'notificationId': notificationId,
      'queuedBy': await AuthManager().getUserId(),
      'payload': payload,
      'files': kept,
    }, queueType);
    await _db.setJeFailurePending(notificationId, 'update');
  }

  /// Sends one queued action. true = done. Throws when the server cannot be
  /// reached (network error) or answers with an error.
  Future<bool> replay(Map<String, dynamic> p0) async {
    final action = p0['action']?.toString() ?? '';
    final nid = int.tryParse('${p0['notificationId']}') ?? 0;
    switch (action) {
      case 'update':
        final payload = Map<String, dynamic>.from(p0['payload'] as Map);
        final je = payload['changeNotifictionJE'] is Map
            ? Map<String, dynamic>.from(payload['changeNotifictionJE'] as Map)
            : <String, dynamic>{};
        // The form may have been saved with the numeric id.
        final id = je['Id']?.toString() ?? '';
        if (id.isEmpty || id == '0' || RegExp(r'^\d+$').hasMatch(id)) {
          je['Id'] = await encryptedIdFor(notificationId: nid);
          payload['changeNotifictionJE'] = je;
        }
        final files = <http.MultipartFile>[];
        final saved = p0['files'] is Map ? p0['files'] as Map : const {};
        for (final e in saved.entries) {
          final path = e.value.toString();
          if (await File(path).exists()) {
            files.add(await http.MultipartFile.fromPath(e.key.toString(), path));
          }
        }
        await _service.updateJEFailure(payload, files: files);
        for (final e in saved.entries) {
          try {
            await File(e.value.toString()).delete();
          } catch (_) {}
        }
        return true;
      default:
        return false;
    }
  }
}
