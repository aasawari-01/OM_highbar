import 'api_helpers.dart';

/// One kilometer / LHS / RHS measurement row (`getCreepMeasurementlist` item).
class CreepRow {
  int id;
  String kilometers;
  String lhs;
  String rhs;

  CreepRow({required this.id, required this.kilometers, required this.lhs, required this.rhs});

  factory CreepRow.fromJson(Map<String, dynamic> j) => CreepRow(
        id: int.tryParse('${j['id']}') ?? 0,
        kilometers: (j['kilometers'] ?? '').toString(),
        lhs: (j['lhs'] ?? '').toString(),
        rhs: (j['rhs'] ?? '').toString(),
      );

  Map<String, dynamic> toJson(dynamic inspectionId) => {
        'id': id,
        'InspectionId': inspectionId,
        'kilometers': wireId(kilometers),
        'lhs': lhs,
        'rhs': rhs,
      };
}

/// A previously saved creep measurement header (`getCreepMeasurement`).
class CreepSaved {
  final String creepId;
  final String fromTime;
  final String toTime;
  final String line;
  final String lineUpDown;
  final String locationFrom;
  final String locationTo;
  final String leftRail;
  final String rightRail;
  final String maxTemp;
  final String minTemp;
  final String rectification;
  final String remark;

  const CreepSaved({
    required this.creepId,
    required this.fromTime,
    required this.toTime,
    required this.line,
    required this.lineUpDown,
    required this.locationFrom,
    required this.locationTo,
    required this.leftRail,
    required this.rightRail,
    required this.maxTemp,
    required this.minTemp,
    required this.rectification,
    required this.remark,
  });
}

/// `responseOutput` of `Inspection/GetCreepMeasurementDetails`.
class CreepData {
  final String inspectionNo;
  final String date;

  /// Id the save APIs expect as `InspectionId`.
  final String inspectionId;
  final String personName;
  final String personId;
  final List<SelectOption> lines;
  final List<SelectOption> lineTypes;
  final List<SelectOption> kilometers;
  final CreepSaved? saved;
  final List<CreepRow> rows;

  const CreepData({
    required this.inspectionNo,
    required this.date,
    required this.inspectionId,
    required this.personName,
    required this.personId,
    required this.lines,
    required this.lineTypes,
    required this.kilometers,
    required this.saved,
    required this.rows,
  });

  factory CreepData.fromJson(Map<String, dynamic> j) {
    String s(Map m, String k) => (m[k] ?? '').toString();

    final dateInfo = (j['getInspectionDate'] as Map?) ?? const {};
    // The first person entry is the "Select" placeholder; the real one is second.
    final people = apiList(j['getPersonResponsible']);
    final person = people.length > 1
        ? people[1]
        : (people.isEmpty ? <String, dynamic>{} : people.first);
    final head = j['getCreepMeasurement'];

    return CreepData(
      inspectionNo: s(dateInfo, 'inspectionNo'),
      date: s(dateInfo, 'date'),
      inspectionId: s(person, 'inspectionId'),
      personName: s(person, 'label'),
      personId: s(person, 'value'),
      lines: apiOptions(j['getCurrentCollectionTestDropDown']),
      lineTypes: apiOptions(j['getCurrentInspectionValue']),
      kilometers: apiOptions(j['getkilometervalue']),
      saved: head is Map
          ? CreepSaved(
              creepId: s(head, 'creepMeasurementId'),
              fromTime: s(head, 'fromTime'),
              toTime: s(head, 'toTime'),
              line: s(head, 'line'),
              lineUpDown: s(head, 'lineUpDown'),
              locationFrom: s(head, 'locationFrom'),
              locationTo: s(head, 'locationTo'),
              leftRail: s(head, 'leftRail'),
              rightRail: s(head, 'rightRail'),
              maxTemp: s(head, 'maxRailTemperature'),
              minTemp: s(head, 'minRailTemperature'),
              rectification: s(head, 'reactificationRequirement'),
              remark: s(head, 'remark'),
            )
          : null,
      rows: apiList(j['getCreepMeasurementlists']).map(CreepRow.fromJson).toList(),
    );
  }
}
