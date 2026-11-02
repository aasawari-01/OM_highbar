import 'api_helpers.dart';

/// A previously saved DG log (`getDGLog`); present when the log is being updated.
class DgLogEntry {
  final String fuelLevel;
  final String dgStart;
  final String dgStop;
  final String dgRun;
  final String totalRunningHours;
  final String batteryVoltage;
  final String fuelBalance;
  final String remark;
  final String dg;

  const DgLogEntry({
    required this.fuelLevel,
    required this.dgStart,
    required this.dgStop,
    required this.dgRun,
    required this.totalRunningHours,
    required this.batteryVoltage,
    required this.fuelBalance,
    required this.remark,
    required this.dg,
  });

  factory DgLogEntry.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] ?? '').toString();
    return DgLogEntry(
      fuelLevel: s('fuelLevel'),
      dgStart: s('dgStart'),
      dgStop: s('dgStop'),
      dgRun: s('dgRun'),
      totalRunningHours: s('totalRunningHours'),
      batteryVoltage: s('batteryVoltage'),
      fuelBalance: s('fuelBalance'),
      remark: s('remark'),
      dg: s('dg'),
    );
  }
}

/// `responseOutput` of `Inspection/GetDGLogDetails`.
class DgLogDetails {
  final String inspectionNo;
  final String date;
  final String employeeName;
  final String employeeId;

  /// Id the save APIs expect as `InspectionId`.
  final String inspectionId;
  final List<SelectOption> dgOptions;
  final DgLogEntry? saved;

  /// `getDGLogNew.lastfuelfilledDate`; null when the server has no date yet.
  final String? lastFuelFilledDate;

  const DgLogDetails({
    required this.inspectionNo,
    required this.date,
    required this.employeeName,
    required this.employeeId,
    required this.inspectionId,
    required this.dgOptions,
    required this.saved,
    required this.lastFuelFilledDate,
  });

  /// True when a log already exists, so saving is an update.
  bool get isUpdate => saved != null;

  factory DgLogDetails.fromJson(Map<String, dynamic> j) {
    final dateInfo = (j['getInspectionDate'] as Map?) ?? const {};
    // The first entry is the "Select" placeholder; the person is the second one.
    final people = apiList(j['getPersonResponsible']);
    final person = people.length > 1
        ? people[1]
        : (people.isEmpty ? <String, dynamic>{} : people.first);
    final saved = j['getDGLog'];
    final fuelNew = j['getDGLogNew'];

    return DgLogDetails(
      inspectionNo: (dateInfo['inspectionNo'] ?? '').toString(),
      date: (dateInfo['date'] ?? '').toString(),
      employeeName: (person['label'] ?? '').toString(),
      employeeId: (person['value'] ?? '').toString(),
      inspectionId: (person['inspectionId'] ?? '').toString(),
      dgOptions: apiOptions(j['getDGDropDown']),
      saved: saved is Map
          ? DgLogEntry.fromJson(Map<String, dynamic>.from(saved))
          : null,
      lastFuelFilledDate:
          fuelNew is Map ? _nonEmpty(fuelNew['lastfuelfilledDate']) : null,
    );
  }
}

String? _nonEmpty(dynamic v) {
  final s = (v ?? '').toString().trim();
  return s.isEmpty ? null : s;
}
