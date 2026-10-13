import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../service/local_database_service.dart';

/// What the Junior Engineer filled in the failure form (user status such as
/// Under Observation / In-Process, rectification details, dates, RCA rows,
/// materials), kept on the device by notification id. GetAllFailuresTransactionData
/// does not return all of it, so the failure opens again with what the JE
/// already entered and he can continue or close it.
class JeOverlay {
  static String _key(int notificationId) => 'jeOverlay:$notificationId';

  /// [payload] is the body of the update call (updateChangeNotificationJE).
  static Future<void> save(int notificationId, Map<String, dynamic> payload) async {
    if (notificationId <= 0) return;
    try {
      final je = payload['changeNotifictionJE'] is Map
          ? Map<String, dynamic>.from(payload['changeNotifictionJE'] as Map)
          : <String, dynamic>{};
      String? text(String k) {
        final v = je[k]?.toString().trim();
        return (v == null || v.isEmpty || v == 'N/A') ? null : v;
      }

      int? number(String k) => int.tryParse('${je[k] ?? ''}');
      bool? flag(String k) => je[k] is bool ? je[k] as bool : null;
      List<dynamic>? list(dynamic v) => v is List && v.isNotEmpty ? v : null;

      final m = <String, dynamic>{
        'userStatus': number('UserStatus'),
        'failureRectificationDetails': text('FailureRectificationDetails'),
        'failureAttendedDate': text('FailureAttendedDate'),
        'actualFailureRectifiedDate': text('ActualFailureRectifiedDate'),
        'underObservationDate': text('UnderObservationDate'),
        'failureType': text('FailureType'),
        'failureTypeId': number('FailureTypeId'),
        'ptwNo': text('PTWNo'),
        'isPTWReq': flag('PTWRequired'),
        'isHardwareReplaced': flag('IsHardwareReplaced'),
        'rca': list(je['FailureRectificationJson']),
        'materials': list(payload['materialRequiredDetails']),
        'dismantle': list(payload['materialDismantleDetails']),
      };
      m.removeWhere((k, v) => v == null);
      await LocalDatabaseService().setAppSetting(_key(notificationId), jsonEncode(m));
    } catch (e) {
      debugPrint('JeOverlay.save error: $e');
    }
  }

  static Future<Map<String, dynamic>?> load(int notificationId) async {
    try {
      final v = await LocalDatabaseService().getAppSetting(_key(notificationId));
      if (v == null || v.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(v) as Map);
    } catch (e) {
      debugPrint('JeOverlay.load error: $e');
      return null;
    }
  }
}
