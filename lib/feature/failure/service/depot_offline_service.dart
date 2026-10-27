import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../service/local_database_service.dart';
import 'failure_service.dart';

/// DCC Depot failure created without internet: the create call and its images
/// are kept (queue + a "Pending Sync" entry in the list) and sent when the
/// internet is back (MasterDataSyncService.syncPendingSubmissions).
class DepotOfflineService {
  DepotOfflineService({FailureService? failureService})
      : _service = failureService ?? FailureService();

  final FailureService _service;

  static const String queueType = 'Depot';

  /// FailureList key of the entries waiting to be sent, per depot.
  static String listKey(int depotId) => 'DepotOffline_$depotId';

  /// Keeps the picked images with the app: the picker's temporary files can be
  /// removed before the internet is back.
  static Future<List<String>> keepFiles(List<String> paths) async {
    final out = <String>[];
    if (paths.isEmpty) return out;
    final dir = Directory(p.join(
        (await getApplicationDocumentsDirectory()).path, 'depot_offline_files'));
    if (!await dir.exists()) await dir.create(recursive: true);
    for (final path in paths) {
      try {
        final name = '${DateTime.now().microsecondsSinceEpoch}_${p.basename(path)}';
        out.add((await File(path).copy(p.join(dir.path, name))).path);
      } catch (e) {
        debugPrint('DepotOfflineService: could not keep $path: $e');
      }
    }
    return out;
  }

  /// Offline failure number in the format DEPT/MM-YYYY/XXXX (shown until the
  /// server gives the real one).
  static Future<String> offlineNumber(String deptCode) async {
    final now = DateTime.now();
    final monthYear = '${now.month.toString().padLeft(2, '0')}-${now.year}';
    try {
      final db = await LocalDatabaseService().database;
      final rows = await db.rawQuery(
          'SELECT failureNo FROM FailureList WHERE failureNo LIKE ? ORDER BY failureNo DESC LIMIT 1',
          ['$deptCode/$monthYear/%']);
      var next = 1;
      if (rows.isNotEmpty) {
        final parts = '${rows.first['failureNo']}'.split('/');
        if (parts.length >= 3) next = (int.tryParse(parts[2]) ?? 0) + 1;
      }
      return '$deptCode/$monthYear/${next.toString().padLeft(4, '0')}';
    } catch (_) {
      return '$deptCode/$monthYear/${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
    }
  }

  /// Sends one queued create. Returns the real failure number. Throws when the
  /// server cannot be reached (network error) or answers with an error.
  Future<String?> replay(Map<String, dynamic> payload) async {
    final files = <http.MultipartFile>[];
    final saved = payload['files'] is List ? payload['files'] as List : const [];
    for (final path in saved) {
      if (await File('$path').exists()) {
        files.add(await http.MultipartFile.fromPath('beforImage', '$path'));
      }
    }
    final no = await _service.createDepotFailure(
        Map<String, dynamic>.from(payload['body'] as Map),
        files: files);
    for (final path in saved) {
      try {
        await File('$path').delete();
      } catch (_) {}
    }
    return no;
  }
}
