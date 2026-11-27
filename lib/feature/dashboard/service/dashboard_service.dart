import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:om_mobile/core/controller/session_controller.dart';
import 'package:om_mobile/feature/failure/controller/failure_list_controller.dart';
import 'package:om_mobile/feature/failure/service/failure_service.dart';
import 'package:om_mobile/feature/failure/service/si_normalize.dart';
import 'package:om_mobile/service/local_database_service.dart';

import '../model/dashboard_models.dart';

/// Reads the failure data that is already on the phone (the local copy of
/// mobileAppAPI/GetAllFailuresTransactionData and the offline queue) and turns
/// it into the numbers of the dashboard. It makes no network call, so the
/// dashboard works offline and is cheap to refresh.
class DashboardService {
  DashboardService({LocalDatabaseService? db})
      : _db = db ?? LocalDatabaseService();

  final LocalDatabaseService _db;

  static const int _maxSystems = 5;
  static const int _maxRecent = 5;
  static const int _maxStatuses = 6;

  /// Same role rules as the failure lists.
  static DashboardScope scopeFor(String role) {
    if (role.trim().isEmpty) return DashboardScope.none;
    if (SessionController.isInspectionJERole(role)) return DashboardScope.none;
    if (SessionController.isOccDelegateRole(role)) {
      return DashboardScope.occDelegate;
    }
    if (role.toUpperCase().contains('DCC')) return DashboardScope.depot;
    if (SessionController.isOccFailureCreatorRole(role)) {
      return DashboardScope.occ;
    }
    if (role.contains('Junior Engineer')) return DashboardScope.juniorEngineer;
    if (role.contains('Station Controller')) {
      return DashboardScope.stationController;
    }
    if (role.contains('Section Incharge')) return DashboardScope.sectionIncharge;
    return DashboardScope.none;
  }

  // ── Failures ─────────────────────────────────────────────────────────────

  Future<DashboardSummary> loadSummary({
    required DashboardScope scope,
    required int userId,
    int deptId = 0,
    String? stationId,
    int depotId = 0,
  }) async {
    try {
      switch (scope) {
        case DashboardScope.sectionIncharge:
          return _build(scope, 'Maintenance failures', 'Maintenance',
              await _sectionIncharge(deptId));
        case DashboardScope.juniorEngineer:
          return _junior(userId, deptId);
        case DashboardScope.stationController:
          return _build(scope, 'Station failures', 'Station',
              await _station(stationId));
        case DashboardScope.depot:
          return _build(
              scope, 'Depot failures', 'Depot', await _depot(depotId));
        case DashboardScope.occ:
          return _build(scope, 'OCC failures', 'OCC', await _occ('OCC'));
        case DashboardScope.occDelegate:
          return _build(scope, 'OCC failures', 'OCC', await _occ('FMC'));
        case DashboardScope.none:
          return const DashboardSummary.empty();
      }
    } catch (e) {
      debugPrint('DashboardService.loadSummary: $e');
      return const DashboardSummary.empty();
    }
  }

  Future<List<_Row>> _sectionIncharge(int deptId) async {
    final rows = <_Row>[];
    for (final r in await _db.getSiFailureCache()) {
      try {
        final record = r['record'] as Map<String, dynamic>;
        final si = await SiNormalize.normalize(
            Map<String, dynamic>.from(record['siFailure'] as Map), record,
            deriveRequestFlags: true);
        final itemDept = _int(si['deptId']);
        if (deptId > 0 && itemDept > 0 && itemDept != deptId) continue;
        rows.add(_Row(
          id: _int(si['notificationId']),
          code: _text(si['notificationCode']),
          description: _text(si['description']),
          status: _first([si['mainStatusName'], si['statusName']]),
          system: _first([si['systems'], si['system'], si['deptName']]),
          location: _text(si['locationName']),
          date: _text(si['actualFailureOccuranceOn']),
        ));
      } catch (e) {
        debugPrint('DashboardService: skipped a Section Incharge row: $e');
      }
    }
    return rows;
  }

  Future<DashboardSummary> _junior(int userId, int deptId) async {
    final rows = <_Row>[];
    for (final r in await _db.getJeFailureCache()) {
      try {
        final record = r['record'] as Map<String, dynamic>;
        final je = await SiNormalize.normalize(
            Map<String, dynamic>.from(record['jeFailure'] as Map), record);
        final assigned = _int(je['assignedUserId']);
        if (assigned != 0 && assigned != userId) continue;
        final itemDept = _int(je['mainDeptId']) > 0
            ? _int(je['mainDeptId'])
            : _int(je['deptId']);
        if (deptId > 0 && itemDept > 0 && itemDept != deptId) continue;

        final history = record['correctiveNotificationActionUserHistory'];
        final latest =
            history is List ? FailureService.latestHistory(history) : null;
        rows.add(_Row(
          id: _int(je['notificationId']),
          code: _text(je['notificationCode']),
          description: _text(je['failureDescription']),
          status: _first([je['statusName'], latest?['statusName']]),
          system: _first([je['systems'], je['system']]),
          location: _text(je['locationName']),
          date: _first([
            je['failureOccuranceDateTime'],
            je['actualFailureOccuranceOn'],
          ]),
        ));
      } catch (e) {
        debugPrint('DashboardService: skipped a Junior Engineer row: $e');
      }
    }

    var joint = 0;
    for (final r in await _db.getJeJointCache()) {
      try {
        final record = r['record'] as Map<String, dynamic>;
        final je = Map<String, dynamic>.from(record['jeFailure'] as Map);
        if (_int(je['assignedUserId_JI']) == userId) joint++;
      } catch (_) {}
    }
    return _build(DashboardScope.juniorEngineer, 'Maintenance inbox',
        'Maintenance', rows,
        jointInspection: joint);
  }

  Future<List<_Row>> _station(String? stationId) async {
    final wanted = int.tryParse(stationId ?? '') ?? 0;
    final rows = <_Row>[];
    for (final r in await _db.getStationFailureCache()) {
      try {
        final f = Map<String, dynamic>.from(r['failure'] as Map);
        if (wanted > 0 && _int(f['locationId']) != wanted) continue;
        rows.add(_Row(
          id: _int(f['id']),
          code: _text(f['notificationCode']),
          description: _text(f['failureDescription']),
          status: _text(f['statusName']),
          system: _first([f['system'], f['departmentName']]),
          location: _text(f['location']),
          date: _text(f['actualFailureOccuranceDate']),
        ));
      } catch (e) {
        debugPrint('DashboardService: skipped a station row: $e');
      }
    }
    return rows;
  }

  Future<List<_Row>> _depot(int depotId) async {
    if (depotId <= 0) return const [];
    final rows = <_Row>[];
    for (final r in await _db.getDepotFailureCache(depotId)) {
      try {
        rows.add(_rowOfOccLike(Map<String, dynamic>.from(r['depotFailures'] as Map)));
      } catch (e) {
        debugPrint('DashboardService: skipped a depot row: $e');
      }
    }
    return rows;
  }

  Future<List<_Row>> _occ(String listType) async {
    final rows = <_Row>[];
    for (final r in await _db.getOccFailureCache(listType)) {
      try {
        final record = Map<String, dynamic>.from(r['record'] as Map);
        rows.add(_rowOfOccLike(Map<String, dynamic>.from(record['failure'] as Map)));
      } catch (e) {
        debugPrint('DashboardService: skipped an OCC row: $e');
      }
    }
    return rows;
  }

  _Row _rowOfOccLike(Map<String, dynamic> f) => _Row(
        id: _int(f['id']),
        code: _first([
          f['notificationCode'],
          f['failureNo'],
          f['failureId'],
          f['failureCode'],
        ]),
        description: _text(f['failureDescription']),
        status: _first([f['statusName'], f['mainStatusName'], f['status']]),
        system: _first([f['system'], f['departmentName'], f['reportedTo']]),
        location: _first([f['locationName'], f['location'], f['lineName']]),
        date: _first([f['actualFailureOccuranceDate'], f['createdDate']]),
      );

  // ── Summary ──────────────────────────────────────────────────────────────

  DashboardSummary _build(
    DashboardScope scope,
    String title,
    String listType,
    List<_Row> rows, {
    int? jointInspection,
  }) {
    final byStatus = <String, int>{};
    final bySystem = <String, List<int>>{}; // [open, closed]
    var closed = 0;
    for (final r in rows) {
      final status = r.status.isEmpty ? 'Unknown' : r.status;
      byStatus[status] = (byStatus[status] ?? 0) + 1;
      final stat = bySystem.putIfAbsent(
          r.system.isEmpty ? 'Others' : r.system, () => [0, 0]);
      if (r.isClosed) {
        closed++;
        stat[1]++;
      } else {
        stat[0]++;
      }
    }

    final statuses = byStatus.entries
        .map((e) => DashboardStatusCount(e.key, e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    final systems = bySystem.entries
        .map((e) => DashboardSystemStat(e.key, open: e.value[0], closed: e.value[1]))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final newest = [...rows]..sort((a, b) => b.id.compareTo(a.id));
    return DashboardSummary(
      scope: scope,
      title: title,
      listType: listType,
      total: rows.length,
      open: rows.length - closed,
      closed: closed,
      jointInspection: jointInspection,
      statuses: statuses.take(_maxStatuses).toList(),
      systems: systems.take(_maxSystems).toList(),
      recent: [
        for (final r in newest.take(_maxRecent))
          DashboardRecentFailure(
            code: r.code,
            description: r.description,
            status: r.status,
            location: r.location,
            date: _formatDate(r.date),
            isClosed: r.isClosed,
          ),
      ],
    );
  }

  // ── Offline queue ────────────────────────────────────────────────────────

  /// Names of the queue kinds shown on the dashboard.
  static const Map<String, String> _queueLabels = {
    'Station': 'Station failures',
    'StationAck': 'Acknowledgements',
    'SI': 'Maintenance',
    'JE': 'Junior Engineer',
    'Depot': 'Depot failures',
    'DepotAck': 'Depot updates',
    'OCC': 'OCC failures',
  };

  /// What waits to be sent for the logged-in user. Items another user saved on
  /// this phone are not counted: they are never sent from this login.
  Future<DashboardQueue> loadQueue(String? userId) async {
    try {
      final byType = <String, int>{};
      var total = 0;
      var failed = 0;
      for (final s in await _db.getPendingSubmissions()) {
        final payload = s['payload'];
        if (payload is Map) {
          final owner =
              '${payload['queuedBy'] ?? payload['CreatedBy'] ?? ''}'.trim();
          if (owner.isNotEmpty &&
              (userId ?? '').isNotEmpty &&
              owner != userId) {
            continue;
          }
        }
        total++;
        if ('${s['syncError'] ?? ''}'.trim().isNotEmpty) failed++;
        final kind = _queueLabels['${s['failureType']}'] ?? 'Other';
        byType[kind] = (byType[kind] ?? 0) + 1;
      }
      return DashboardQueue(total: total, failed: failed, byType: byType);
    } catch (e) {
      debugPrint('DashboardService.loadQueue: $e');
      return const DashboardQueue.empty();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static int _int(dynamic v) =>
      v is num ? v.toInt() : (int.tryParse('${v ?? ''}') ?? 0);

  static String _text(dynamic v) {
    final t = v?.toString().trim() ?? '';
    return t == 'null' ? '' : t;
  }

  static String _first(List<dynamic> values) {
    for (final v in values) {
      final t = _text(v);
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  /// "2026-11-23T14:59:00" or "10/27/2026 12:00:00" -> "23 Nov 2026, 14:59".
  static String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    final iso = DateTime.tryParse(raw);
    if (iso != null) return DateFormat('dd MMM yyyy, HH:mm').format(iso);
    return FailureListController.depotDate(raw) ?? raw;
  }
}

/// A failure of any list, reduced to what the dashboard needs.
class _Row {
  _Row({
    required this.id,
    required this.code,
    required this.description,
    required this.status,
    required this.system,
    required this.location,
    required this.date,
  });

  final int id;
  final String code;
  final String description;
  final String status;
  final String system;
  final String location;
  final String date;

  bool get isClosed => status.toLowerCase().contains('close');
}
