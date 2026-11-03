import 'dart:io';

import 'package:http/http.dart' as http;

import 'depot_offline_service.dart';
import 'failure_service.dart';

/// OCC failures (Chief Controller creates / updates, FMC / TPC / CSS / RSC
/// update) saved without internet: the call and its images are kept (queue +
/// a "Pending Sync" entry or pending marker in the list) and sent when the
/// internet is back (MasterDataSyncService.syncPendingSubmissions).
class OccOfflineService {
  OccOfflineService({FailureService? failureService})
      : _service = failureService ?? FailureService();

  final FailureService _service;

  static const String queueType = 'OCC';

  /// FailureList key of the OCC failures created offline and not sent yet.
  static const String listKey = 'OccOffline';

  /// Key of the saved Reported To / Line / Reported By / Train Operator lists.
  static const String lookupKey = 'occDeptLocation';

  /// Queue actions.
  static const String actionCreate = 'occCreate';
  static const String actionUpdate = 'occUpdate';

  /// Name shown on the "Pending: ..." chip of a failure with a waiting update.
  static String label(String? action) =>
      action == actionCreate ? 'OCC Failure' : 'OCC Update';

  /// Same keep-the-images rule and offline number format as the depot flow.
  static Future<List<String>> keepFiles(List<String> paths) =>
      DepotOfflineService.keepFiles(paths);

  static Future<String> offlineNumber() =>
      DepotOfflineService.offlineNumber('OCC');

  /// Sends one queued call (create or update: the same endpoint, the body tells
  /// them apart). Returns the server's answer (the new failure number for a
  /// create, the department failure number for an assign). Throws when the
  /// server cannot be reached (network error) or answers with an error.
  Future<String?> replay(Map<String, dynamic> payload) async {
    final files = <http.MultipartFile>[];
    final saved = payload['files'] is List ? payload['files'] as List : const [];
    for (final path in saved) {
      if (await File('$path').exists()) {
        files.add(await http.MultipartFile.fromPath('beforImage', '$path'));
      }
    }
    final result = await _service.createOccFailure(
        Map<String, dynamic>.from(payload['body'] as Map),
        files: files);
    for (final path in saved) {
      try {
        await File('$path').delete();
      } catch (_) {}
    }
    return result;
  }
}
