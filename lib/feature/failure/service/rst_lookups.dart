import 'dart:async';

import '../../../core/models/label_value.dart';
import '../../../service/local_database_service.dart';
import 'failure_log.dart';
import 'failure_service.dart';

/// The dropdown lists of the RST forms (the web's getRSTNotificationDetailsById
/// lists). Each answer is saved the first time the server is reached (the login
/// sync does it) and read from the saved copy when there is no internet.
class RstLookups {
  RstLookups({FailureService? failureService, LocalDatabaseService? db})
      : _service = failureService ?? FailureService(),
        _db = db ?? LocalDatabaseService();

  final FailureService _service;
  final LocalDatabaseService _db;

  static const String ddlKey = 'rstDdl'; // create page lists
  static const String partBKey = 'rstPartB'; // responsible persons, SIC, JI depts
  static String deptKey(String deptId) => 'rstDept_$deptId';
  static String jiUsersKey(String deptId) => 'rstJiUsers_$deptId';

  Future<Map<String, dynamic>> _cached(
      String key, Future<Map<String, dynamic>> Function() load) async {
    // The saved copy is shown at once (no waiting on the network); it is
    // refreshed in the background for the next time.
    Map<String, dynamic>? saved;
    try {
      saved = await _db.getOccLookup(key);
    } catch (e) {
      // An old oversized row cannot be read back (CursorWindow): treat it as
      // not saved, the fresh answer replaces it.
      failureLog('RstLookups $key: saved copy unreadable ($e)');
    }
    Future<Map<String, dynamic>> refresh() async {
      final fresh = _prune(await load().timeout(const Duration(seconds: 12)));
      await _db.saveOccLookup(key, fresh);
      return fresh;
    }

    if (saved != null && saved.isNotEmpty) {
      unawaited(refresh().then((_) {}, onError: (Object e) {
        failureLog('RstLookups $key: refresh failed ($e)');
      }));
      return saved;
    }
    try {
      return await refresh();
    } catch (e) {
      failureLog('RstLookups $key: nothing saved and not reachable ($e)');
      return <String, dynamic>{};
    }
  }

  /// The server's answers also carry the whole functional-location and
  /// equipment lists (hundreds of thousands of rows, tens of MB): those are not
  /// saved (the local tables are queried instead), the small lists are.
  static Map<String, dynamic> _prune(Map<String, dynamic> answer) {
    final out = <String, dynamic>{};
    answer.forEach((k, v) {
      final size = v is Map ? v.length : (v is List ? v.length : 0);
      if (size <= 1000) out[k] = v;
    });
    return out;
  }

  /// Priority, department, failure type, nature of work, functional location
  /// filters (create page).
  Future<Map<String, dynamic>> createPage() =>
      _cached(ddlKey, () => _service.getRstLookups('0', 'getAllDDLRSTPage'));

  /// Responsible persons, SIC types / persons and joint inspection departments
  /// (Part B). [failureId] is the failure the web opens (any failure works: the
  /// lists do not depend on it).
  Future<Map<String, dynamic>> partB(String failureId) => _cached(
      partBKey,
      () => _service.getRstLookups(failureId, 'getRSTNotificationDetailsById'));

  /// Functional locations and equipment of one department.
  Future<Map<String, dynamic>> departmentLists(String deptId) => _cached(
      deptKey(deptId), () => _service.getRstDepartmentLists(deptId));

  /// Users of a joint inspection department.
  Future<Map<String, dynamic>> jiUsers(String deptId) => _cached(
      jiUsersKey(deptId),
      () => _service.getRstLookups(deptId, 'getJoinInspectionUserDetails'));

  /// Only what is already saved (no call): used while offline.
  Future<Map<String, dynamic>> saved(String key) async =>
      await _db.getOccLookup(key) ?? <String, dynamic>{};

  /// Saves the lists the forms need offline: the create page, the department
  /// lists of the departments on it, and the Part B lists (taken with
  /// [anyFailureId], when the user already has a failure).
  Future<void> prefetch({String? anyFailureId}) async {
    try {
      // Only the Part B lists: the create page lists and the department
      // functional-location / equipment lists come from the local tables.
      if ((anyFailureId ?? '').isNotEmpty) await partB(anyFailureId!);
    } catch (e) {
      failureLog('RstLookups.prefetch: $e');
    }
  }

  /// The items of a lookup list: the server sends them as a list or as a map
  /// keyed by position.
  static List<Map<String, dynamic>> values(dynamic v) {
    final Iterable items =
        v is Map ? v.values : (v is List ? v : const []);
    return [
      for (final e in items)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  /// A lookup list as dropdown options (label / value).
  static List<LabelValue> options(dynamic v) => [
        for (final e in values(v))
          if ('${e['label'] ?? ''}'.trim().isNotEmpty)
            LabelValue(label: '${e['label']}'.trim(), value: '${e['value'] ?? ''}'),
      ];
}
