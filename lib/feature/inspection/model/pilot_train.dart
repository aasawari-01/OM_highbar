import 'api_helpers.dart';

/// A previously saved pilot train inspection (`getPilotTrain`).
class PilotTrainSaved {
  final String section;
  final String time;
  final String remark;
  final String trainSetId;

  const PilotTrainSaved({
    required this.section,
    required this.time,
    required this.remark,
    required this.trainSetId,
  });
}

/// `responseOutput` of `Inspection/GetPilotTrainDetail`.
class PilotTrainData {
  final String inspectionNo;
  final String date;

  /// Id the save APIs expect as `InspectionId`.
  final String inspectionId;
  final List<SelectOption> trainSets;
  final PilotTrainSaved? saved;

  const PilotTrainData({
    required this.inspectionNo,
    required this.date,
    required this.inspectionId,
    required this.trainSets,
    required this.saved,
  });

  factory PilotTrainData.fromJson(Map<String, dynamic> j) {
    String s(Map m, String k) => (m[k] ?? '').toString();

    final dateInfo = (j['getInspectionDate'] as Map?) ?? const {};
    // The first person entry is the "Select" placeholder; the real one is second.
    final people = apiList(j['getPersonResponsible']);
    final person = people.length > 1
        ? people[1]
        : (people.isEmpty ? <String, dynamic>{} : people.first);
    final head = j['getPilotTrain'];

    return PilotTrainData(
      inspectionNo: s(dateInfo, 'inspectionNo'),
      date: s(dateInfo, 'date'),
      inspectionId: s(person, 'inspectionId'),
      trainSets: apiOptions(j['getTrainSetList'])
        ..sort((a, b) => (int.tryParse(a.value) ?? 0).compareTo(int.tryParse(b.value) ?? 0)),
      saved: head is Map
          ? PilotTrainSaved(
              section: s(head, 'section'),
              time: s(head, 'time'),
              remark: s(head, 'remark'),
              trainSetId: s(head, 'trainSetId'),
            )
          : null,
    );
  }
}
