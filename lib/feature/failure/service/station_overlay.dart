import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../service/local_database_service.dart';

/// What the Station Controller typed when creating a failure (trip / passenger
/// details, category, sub location), kept on the device by the failure number
/// the server gave it. The Station failure list of the server does not return
/// all of these (for example the number of passengers affected), so the
/// details screen fills what is missing from here.
class StationOverlay {
  static const String _prefix = 'stationOverlay:';

  static int? _int(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}');

  /// The overlay of a create request body (the same names the list rows use).
  static Future<Map<String, dynamic>> build(Map<String, dynamic> body) async {
    String? categoryText;
    final categoryId = _int(body['FailureCategoryTypeId']) ?? 0;
    if (categoryId > 0) {
      try {
        final rows = await LocalDatabaseService().getFailureCategoryTypeOptions();
        categoryText = rows
            .firstWhere((r) => '${r['ID']}' == '$categoryId')['FailureCategoryType']
            ?.toString();
      } catch (_) {}
    }
    final m = <String, dynamic>{
      'subLocation': body['SubLocation'],
      'trainId': body['TrainId']?.toString(),
      'system': body['System'],
      'isTripAffected': body['IsTripAffected'] is bool ? body['IsTripAffected'] : null,
      'tripDelayUpline': _int(body['TripDelayUpline']),
      'tripDelayDownline': _int(body['TripDelayDownline']),
      'tripCancel': _int(body['TripCancel']),
      'trainDelayInMin': _int(body['TrainDelayInMin']),
      'noOfTranWithdrawal': _int(body['NoOfTranWithdrawal']),
      'isTrainReplace': body['IsTrainReplace'] is bool ? body['IsTrainReplace'] : null,
      'trainReplace': _int(body['TrainReplace']),
      'isTrainDeboarded':
          body['IsTrainDeboarded'] is bool ? body['IsTrainDeboarded'] : null,
      'trainDeboarded': _int(body['TrainDeboarded']),
      'isPassengerAffected':
          body['IsPassengerAffected'] is bool ? body['IsPassengerAffected'] : null,
      'numberOfPassengerAffected': _int(body['NumberOfPassengerAffected']),
      'trappedDuration': _int(body['TrappedDuration']),
      'rescusedDuration': _int(body['RescusedDuration']),
      'failureCategoryTypeText': categoryText,
    };
    m.removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
    return m;
  }

  /// [codes] is what the create call returned (several, separated by comma,
  /// when one failure was created per department).
  static Future<void> save(String? codes, Map<String, dynamic> overlay) async {
    if (overlay.isEmpty) return;
    try {
      final db = LocalDatabaseService();
      for (final c in (codes ?? '').split(RegExp(r'[,;\s]+'))) {
        if (c.trim().isEmpty) continue;
        await db.setAppSetting('$_prefix${c.trim()}', jsonEncode(overlay));
      }
    } catch (e) {
      debugPrint('StationOverlay.save error: $e');
    }
  }

  /// All saved overlays by failure number.
  static Future<Map<String, Map<String, dynamic>>> loadAll() async {
    final out = <String, Map<String, dynamic>>{};
    try {
      final rows = await LocalDatabaseService().getAppSettingsByPrefix(_prefix);
      rows.forEach((key, value) {
        try {
          out[key.substring(_prefix.length)] =
              Map<String, dynamic>.from(jsonDecode(value) as Map);
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('StationOverlay.loadAll error: $e');
    }
    return out;
  }
}
