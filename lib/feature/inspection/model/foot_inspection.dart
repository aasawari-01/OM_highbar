import 'api_helpers.dart';

/// A previously saved foot inspection (`getFootInspection`).
class FootSaved {
  final String time;
  final String lineUpDown;
  final String locationFrom;
  final String locationTo;
  final String observation;
  final String remark;

  const FootSaved({
    required this.time,
    required this.lineUpDown,
    required this.locationFrom,
    required this.locationTo,
    required this.observation,
    required this.remark,
  });
}

/// `responseOutput` of `Inspection/GetFootInspectionDetails`.
class FootData {
  final String inspectionNo;
  final String date;

  /// Id the save APIs expect as `InspectionId`.
  final String inspectionId;
  final String personName;
  final String personId;
  final List<SelectOption> lineTypes;
  final FootSaved? saved;

  const FootData({
    required this.inspectionNo,
    required this.date,
    required this.inspectionId,
    required this.personName,
    required this.personId,
    required this.lineTypes,
    required this.saved,
  });

  factory FootData.fromJson(Map<String, dynamic> j) {
    String s(Map m, String k) => (m[k] ?? '').toString();

    final dateInfo = (j['getInspectionDate'] as Map?) ?? const {};
    // The first person entry is the "Select" placeholder; the real one is second.
    final people = apiList(j['getPersonResponsible']);
    final person = people.length > 1
        ? people[1]
        : (people.isEmpty ? <String, dynamic>{} : people.first);
    final head = j['getFootInspection'];

    return FootData(
      inspectionNo: s(dateInfo, 'inspectionNo'),
      date: s(dateInfo, 'date'),
      inspectionId: s(person, 'inspectionId'),
      personName: s(person, 'label'),
      personId: s(person, 'value'),
      lineTypes: apiOptions(j['getLineTypeDropDown']),
      saved: head is Map
          ? FootSaved(
              time: s(head, 'time'),
              lineUpDown: s(head, 'lineUpDown'),
              locationFrom: s(head, 'locationFrom'),
              locationTo: s(head, 'locationTo'),
              observation: s(head, 'observation'),
              remark: s(head, 'remark'),
            )
          : null,
    );
  }
}
