import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../service/local_database_service.dart';
import '../../../service/master_data_sync_service.dart';
import '../../../service/network_service/network_errors.dart';
import 'failure_service.dart';
import 'si_ids.dart';

enum SiOutcome { done, queued, rejected }

/// Section Incharge actions that also work without internet: the action is
/// tried online; if the server cannot be reached it is saved locally (queue +
/// a change on the local copy of the failure) and sent when internet returns
/// (MasterDataSyncService.syncPendingSubmissions).
class SiOfflineService {
  SiOfflineService({FailureService? failureService})
      : _service = failureService ?? FailureService();

  final FailureService _service;
  final LocalDatabaseService _db = LocalDatabaseService();

  /// failureType of the queued rows.
  static const String queueType = 'SI';

  /// How long an action waits for the server before it is saved offline.
  static const Duration onlineTimeout = Duration(seconds: 30);

  static String label(String? action) {
    switch (action) {
      case 'assign':
        return 'Assign';
      case 'reassign':
        return 'Reassign';
      case 'correction':
        return 'Send for correction';
      case 'reject':
        return 'Reject';
      case 'delete':
        return 'Delete';
      case 'close':
        return 'Close';
      case 'update':
        return 'Update';
      case 'create':
        return 'Create';
      default:
        return action ?? '';
    }
  }

  /// The encrypted id (jobCardNo) of a failure, which assign / close / update
  /// need. The server returns it in the details model ("Id"), so it is read
  /// once from the details API and kept with the local copy. Throws a network
  /// error when it cannot be read because the server cannot be reached.
  Future<String> encryptedIdFor(
      {required int notificationId,
      String? code,
      bool retryAfterSync = true}) async {
    final row = await _db.findSiFailure(notificationId: notificationId, code: code);
    final record = row?['record'] as Map<String, dynamic>?;
    final cached = record?['encryptedId']?.toString() ?? '';
    if (cached.isNotEmpty) return cached;

    final siMap = record?['siFailure'] is Map ? record!['siFailure'] as Map : const {};
    // The sync carries the encrypted id (the web list's jobCardNo) in siFailure.
    final fromSync = encryptedIdFromSiFailure(siMap, notificationId);
    if (fromSync != null) {
      await _db.setSiEncryptedId(notificationId, fromSync);
      return fromSync;
    }
    // Failures downloaded before the server sent jobCardNo have no id yet and
    // an incremental sync would not bring them again: download everything once.
    if (retryAfterSync) {
      final synced = await Get.find<MasterDataSyncService>()
          .syncFailureTransactions(forceAll: true);
      if (!synced) {
        // No connection: the caller saves the action and retries when online.
        throw TimeoutException('Server not reached to get the failure id');
      }
      return encryptedIdFor(
          notificationId: notificationId, code: code, retryAfterSync: false);
    }
    debugPrint('SiOfflineService: no encrypted id for $notificationId '
        '(siFailure keys: ${siMap.keys.take(6).toList()}...)');
    throw Exception(
        'The failure id (jobCardNo) is missing in the synced data, so this cannot be sent.');
  }

  /// done = the server did it, queued = saved offline, rejected = the server
  /// said no (nothing is saved).
  Future<SiOutcome> run({
    required String action,
    required int notificationId,
    required Map<String, dynamic> args,
    Map<String, dynamic>? patch,
    required Future<bool> Function() online,
  }) async {
    try {
      final ok = await online().timeout(onlineTimeout);
      return ok ? SiOutcome.done : SiOutcome.rejected;
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      debugPrint('SiOfflineService: $action saved offline ($e)');
      await _queue(
          action: action, notificationId: notificationId, args: args, patch: patch);
      return SiOutcome.queued;
    }
  }

  Future<int> _queue({
    required String action,
    required int notificationId,
    required Map<String, dynamic> args,
    Map<String, dynamic>? patch,
  }) async {
    final id = await _db.insertPendingSubmission(
        {'action': action, 'notificationId': notificationId, ...args}, queueType);
    if (notificationId > 0) {
      await _db.setSiFailurePending(notificationId, action, patch: patch);
    }
    return id;
  }

  /// The edit form of an existing failure, saved offline. The change is also
  /// applied to the local copy so the details show it.
  Future<void> queueUpdate(Map<String, dynamic> payload) async {
    final notificationId = int.tryParse('${payload['NotificationId']}') ?? 0;
    final patch = <String, dynamic>{};
    payload.forEach((key, value) {
      if (key == 'NotificationCode' || key == 'NotificationId' || key == 'CreatedBy') {
        return;
      }
      patch[key.isEmpty ? key : key[0].toLowerCase() + key.substring(1)] = value;
    });
    await _queue(
        action: 'update',
        notificationId: notificationId,
        args: {'payload': payload},
        patch: patch);
  }

  /// A new maintenance failure saved offline. Returns the queue id (the list
  /// entry uses -id).
  Future<int> queueCreate(Map<String, dynamic> formData,
      {Map<String, dynamic> labels = const {}}) {
    // [labels] are the names shown on the form (not sent to the server); the
    // details screen uses them to show the failure while it is offline.
    return _db.insertPendingSubmission({
      'action': 'create',
      'notificationId': 0,
      'formData': formData,
      'labels': labels,
    }, queueType);
  }

  /// Sends one queued action. true = done, false = the server refused it.
  /// Throws when the server cannot be reached (network error) or answers with
  /// an error.
  Future<bool> replay(Map<String, dynamic> p) async {
    final action = p['action']?.toString() ?? '';
    final nid = int.tryParse('${p['notificationId']}') ?? 0;
    final userId = int.tryParse('${p['assignedUserId']}') ?? 0;
    final description = p['description']?.toString() ?? action;

    switch (action) {
      case 'assign':
      case 'reassign':
        return _service.assignUserNotification(
            notificationId: await encryptedIdFor(notificationId: nid),
            assignedUserId: userId,
            description: description);
      case 'correction':
        return _service.sendForCorrection(
            notificationId: nid, assignedUserId: userId, description: description);
      case 'reject':
        return _service.rejectNotification(
            notificationId: nid, description: description);
      case 'delete':
        return _service.deleteNotification(
            notificationId: nid, description: description);
      case 'close':
        return _service.closeNotification(
            jobCardNo: await encryptedIdFor(notificationId: nid),
            assignedUserId: userId);
      case 'update':
        final payload = Map<String, dynamic>.from(p['payload'] as Map);
        // The edit form may have been saved with the numeric id.
        payload['NotificationCode'] = await encryptedIdFor(notificationId: nid);
        await _service.updateMaintenanceFailure(payload);
        return true;
      case 'create':
        await _service.submitMaintenanceNotificationForm(
            Map<String, dynamic>.from(p['formData'] as Map));
        return true;
      default:
        return false;
    }
  }
}
