import 'api_helpers.dart';

/// A previously saved OMS action (`getOMSAction`).
class OmsSaved {
  final String fromKm;
  final String toKm;
  final String trainNo;
  final String runNo;
  final String maxRi;
  final String maxRiLocation;
  final String summary;

  const OmsSaved({
    required this.fromKm,
    required this.toKm,
    required this.trainNo,
    required this.runNo,
    required this.maxRi,
    required this.maxRiLocation,
    required this.summary,
  });
}

/// `responseOutput` of `Inspection/GetOMSActionDetails`.
class OmsData {
  final String inspectionNo;
  final String date;

  /// Id the save APIs expect as `InspectionId`.
  final String inspectionId;
  final List<SelectOption> trainNos;
  final OmsSaved? saved;

  const OmsData({
    required this.inspectionNo,
    required this.date,
    required this.inspectionId,
    required this.trainNos,
    required this.saved,
  });

  factory OmsData.fromJson(Map<String, dynamic> j) {
    String s(Map m, String k) => (m[k] ?? '').toString();

    final dateInfo = (j['getInspectionDate'] as Map?) ?? const {};
    // The first person entry is the "Select" placeholder; the real one is second.
    final people = apiList(j['getPersonResponsible']);
    final person = people.length > 1
        ? people[1]
        : (people.isEmpty ? <String, dynamic>{} : people.first);
    final head = j['getOMSAction'];

    return OmsData(
      inspectionNo: s(dateInfo, 'inspectionNo'),
      date: s(dateInfo, 'date'),
      inspectionId: s(person, 'inspectionId'),
      trainNos: apiOptions(j['getTrainNoDropDown']),
      saved: head is Map
          ? OmsSaved(
              fromKm: s(head, 'fromKM'),
              toKm: s(head, 'toKM'),
              trainNo: s(head, 'trainNo'),
              runNo: s(head, 'runNo'),
              maxRi: s(head, 'maxRI'),
              maxRiLocation: s(head, 'locationMaxRI'),
              summary: s(head, 'summary'),
            )
          : null,
    );
  }
}
