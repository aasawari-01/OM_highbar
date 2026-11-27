/// Which failure data a role sees on the dashboard. It follows the same rules
/// as the failure lists, so the numbers on the dashboard match the lists.
enum DashboardScope {
  sectionIncharge,
  juniorEngineer,
  stationController,
  depot,
  occ,
  occDelegate,
  none,
}

/// How many failures have one status (for example "Assigned").
class DashboardStatusCount {
  const DashboardStatusCount(this.name, this.count);

  final String name;
  final int count;
}

/// Open and closed failures of one system (bar of the chart).
class DashboardSystemStat {
  const DashboardSystemStat(this.label, {this.open = 0, this.closed = 0});

  final String label;
  final int open;
  final int closed;

  int get total => open + closed;
}

/// One line of the "Recent failures" card.
class DashboardRecentFailure {
  const DashboardRecentFailure({
    required this.code,
    required this.description,
    required this.status,
    required this.location,
    required this.date,
    required this.isClosed,
  });

  final String code;
  final String description;
  final String status;
  final String location;
  final String date;
  final bool isClosed;
}

/// Everything the dashboard shows about the failures of the selected role.
class DashboardSummary {
  const DashboardSummary({
    required this.scope,
    required this.title,
    required this.listType,
    this.total = 0,
    this.open = 0,
    this.closed = 0,
    this.jointInspection,
    this.statuses = const [],
    this.systems = const [],
    this.recent = const [],
  });

  const DashboardSummary.empty()
      : scope = DashboardScope.none,
        title = '',
        listType = '',
        total = 0,
        open = 0,
        closed = 0,
        jointInspection = null,
        statuses = const [],
        systems = const [],
        recent = const [];

  final DashboardScope scope;

  /// Name of the failure list shown on the cards ("Maintenance failures").
  final String title;

  /// failureType of the FailureListScreen that opens from the cards.
  final String listType;
  final int total;
  final int open;
  final int closed;

  /// Joint inspections assigned to the user (Junior Engineer only).
  final int? jointInspection;
  final List<DashboardStatusCount> statuses;
  final List<DashboardSystemStat> systems;
  final List<DashboardRecentFailure> recent;

  bool get hasSource => scope != DashboardScope.none;
}

/// Failure actions saved on the phone that wait for internet.
class DashboardQueue {
  const DashboardQueue({
    this.total = 0,
    this.failed = 0,
    this.byType = const {},
  });

  const DashboardQueue.empty()
      : total = 0,
        failed = 0,
        byType = const {};

  /// Everything still to be sent (includes [failed]).
  final int total;

  /// Items the server refused: they stay in the queue and need attention.
  final int failed;

  /// Waiting items per kind ("Station", "Maintenance", ...).
  final Map<String, int> byType;
}
