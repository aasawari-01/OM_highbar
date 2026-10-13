import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../service/local_database_service.dart';
import 'failure_service.dart';

/// The Section Incharge failure (siFailure) of GetAllFailuresTransactionData
/// does not always carry the same fields: the server now sends the same model
/// as the Junior Engineer list (statusName instead of mainStatusName, no
/// statusId / deptId / locationTypeId, subLocation instead of locationFailure,
/// freq instead of frequency, ISO dates ...). This fills the names the app
/// reads from what the record has, and never overwrites a value that is there.
class SiNormalize {
  /// Status ids by the status name the server sends.
  static const Map<String, int> _statusByName = {
    'created': 1,
    'assigned': 2,
    'work complete': 4,
    'confirm': 4,
    'closed': 39,
    'assigned to department': 205,
  };

  static final Map<int, String?> _userNames = {};

  static bool _blank(dynamic v) =>
      v == null || (v is String && v.trim().isEmpty);

  static int? _int(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));

  /// [deriveRequestFlags] (Section Incharge list only): fills otherRequestFrom
  /// and occRequestStatus, which the server no longer sends, from the creation
  /// type, because the Close / Reject / Delete buttons depend on them.
  static Future<Map<String, dynamic>> normalize(
      Map<String, dynamic> si, Map<String, dynamic> record,
      {bool deriveRequestFlags = false}) async {
    final m = Map<String, dynamic>.from(si);
    final db = LocalDatabaseService();
    try {
      // Status
      if (_blank(m['mainStatusName']) && !_blank(m['statusName'])) {
        m['mainStatusName'] = m['statusName'];
      }
      if (_int(m['statusId']) == null) {
        final name = '${m['statusName'] ?? m['mainStatusName'] ?? ''}'.trim().toLowerCase();
        int? id = _statusByName[name];
        if (id == null) {
          final h = record['correctiveNotificationActionUserHistory'];
          final latest = h is List ? FailureService.latestHistory(h) : null;
          id = _int(latest?['statusId']);
        }
        if (id != null) m['statusId'] = id;
      }

      // Department: id, else name, else the code in the failure number
      if (_int(m['deptId']) == null) {
        int? id = _int(m['mainDeptId']);
        if (id == null && !_blank(m['deptName'])) {
          id = await db.getDeptIdByName('${m['deptName']}');
        }
        if (id == null) {
          final code = '${m['notificationCode'] ?? ''}'.split('/').first.trim();
          if (code.isNotEmpty) id = await db.getDeptIdByCode(code);
        }
        if (id != null) m['deptId'] = id;
      }

      // Text fields under their other names (the server fills one of the two)
      if (_blank(m['description']) && !_blank(m['failureDescription'])) {
        m['description'] = m['failureDescription'];
      }
      if (_blank(m['failureDescription']) && !_blank(m['description'])) {
        m['failureDescription'] = m['description'];
      }
      if (_blank(m['locationFailure']) && !_blank(m['subLocation'])) {
        m['locationFailure'] = m['subLocation'];
      }
      if (_int(m['frequency']) == null && m['freq'] != null) {
        m['frequency'] = m['freq'];
      }
      if (_blank(m['system']) && !_blank(m['systems'])) m['system'] = m['systems'];
      if (_blank(m['subSystem']) && !_blank(m['subSystems'])) {
        m['subSystem'] = m['subSystems'];
      }

      // Date as dd/MM/yyyy HH:mm (the server now sends ISO)
      final occurred = '${m['actualFailureOccuranceOn'] ?? ''}'.trim();
      if (occurred.contains('T')) {
        final d = DateTime.tryParse(occurred);
        if (d != null) {
          m['actualFailureOccuranceOn'] = DateFormat('dd/MM/yyyy HH:mm').format(d);
        }
      }

      // Notification Type: the server sends its name ("Snag"), the form needs the id
      if (_int(m['corr_NotificationTypeId']) == null &&
          !_blank(m['notificationType'])) {
        final wanted = '${m['notificationType']}'.trim().toLowerCase();
        for (final t in await db.getNotificationTypes()) {
          if (t.id != null && (t.notificationType ?? '').trim().toLowerCase() == wanted) {
            m['corr_NotificationTypeId'] = t.id;
            break;
          }
        }
      }

      // Train set failure: the server sends 0 / 1 (or a bool); not a train set
      // failure unless it says so (the Close rule needs an explicit false).
      final t = m['isTrainSetFailure'];
      m['isTrainSetFailure'] = t is bool
          ? t
          : (t is num
              ? t != 0
              : (t is String && (t.toLowerCase() == 'true' || t == '1')));

      if (deriveRequestFlags) {
        final from = '${m['creationType'] ?? ''}'.trim().toLowerCase();
        // Where the request came from: the Close rule asks for the Station
        // Controller's acknowledge for Station and Depot requests.
        if (_blank(m['otherRequestFrom'])) {
          if (from == 'station') m['otherRequestFrom'] = 'Station Request';
          if (from == 'depot') m['otherRequestFrom'] = 'Depot Request';
        }
        // "Yes" = raised by OCC / Station / Depot (Reject For Duplicate),
        // "No" = created by hand (Delete).
        if (_blank(m['occRequestStatus'])) {
          if (from == 'station' || from == 'depot' || from == 'occ') {
            m['occRequestStatus'] = 'Yes';
          } else if (from == 'manual') {
            m['occRequestStatus'] = 'No';
          }
        }
      }

      // Location: the one of the functional location
      final flId = _int(m['functionLocationId']) ?? 0;
      if (_int(m['locationTypeId']) == null && flId > 0) {
        final fl = await db.getFailureFunctionalLocationRow(flId);
        final code = fl?['Location']?.toString().trim() ?? '';
        if (code.isNotEmpty && code.toUpperCase() != 'NULL') {
          final id = await db.getLocationIdByCode(code);
          if (id != null) m['locationTypeId'] = id;
        }
      }

      // Name of the assigned user
      final assigned = _int(m['assignedUserId']) ?? 0;
      if (_blank(m['assignedUseeName']) && assigned > 0) {
        if (!_userNames.containsKey(assigned)) {
          _userNames[assigned] = await db.getUserNameById(assigned);
        }
        final name = _userNames[assigned];
        if (name != null && name.isNotEmpty) m['assignedUseeName'] = name;
      }
    } catch (e) {
      debugPrint('SiNormalize error: $e');
    }
    return m;
  }
}
