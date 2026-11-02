import 'api_helpers.dart';

/// One Yes/No row of the cab petrolling checklist and its observation text.
class CabChecklistRow {
  final int sr;
  final String label;
  final String statusKey; // key sent to the API
  final String observationKey;
  final String statusResponseKey; // key returned by getCabPetrollingDetails
  final String observationResponseKey;

  const CabChecklistRow(
    this.sr,
    this.label,
    this.statusKey,
    this.observationKey,
    this.statusResponseKey,
    this.observationResponseKey,
  );
}

const cabChecklistRows = <CabChecklistRow>[
  CabChecklistRow(1, 'Pilot Morning Train', 'PilotMorningStatus', 'PilotMorningObservation',
      'pilotMorningStatus', 'pilotMorningObservation'),
  CabChecklistRow(2, 'OCC Initiated', 'OCCInitiatedStatus', 'OCCInitiatedObservation',
      'occInitiatedStatus', 'occInitiatedObservation'),
  CabChecklistRow(3, 'Ride Was Smooth', 'RideWasStatus', 'RideWasObservation', 'rideWasStatus',
      'rideWasObservation'),
  CabChecklistRow(4, 'Any Visual Abnormality Noticed', 'AnyVisualAbnormalityStatus',
      'AnyVisualAbnormalityObservation', 'anyVisualAbnormalityStatus', 'anyVisualAbnormalityObservation'),
  CabChecklistRow(5, 'Lubrication Outer Rail of Sharp Curve', 'LubricationOuterStatus',
      'LubricationOuterObservation', 'lubricationOuterStatus', 'lubricationOuterObservation'),
  CabChecklistRow(6, 'WFL On/Off', 'WFLStatus', 'WFLObservation', 'wflStatus', 'wflObservation'),
  CabChecklistRow(7, 'Signage Board Status', 'SignageStatus', 'SignageObservation', 'signageStatus',
      'signageObservation'),
  CabChecklistRow(8, 'Water Stagnation', 'WaterStatus', 'WaterObservation', 'waterStatus',
      'waterObservation'),
  CabChecklistRow(9, 'Section Free From Obstacle', 'SectionFreeStatus', 'SectionFreeObservation',
      'sectionFreeStatus', 'sectionFreeObservation'),
  CabChecklistRow(10, 'Any Loose Item/Cleanness', 'AnyLooseStatus', 'AnyLooseObservation',
      'anyLooseStatus', 'anyLooseObservation'),
];

/// A line option; its plant id decides which locations can be picked.
class CabLineOption {
  final String value;
  final String label;
  final String planningPlantId;

  const CabLineOption(this.value, this.label, this.planningPlantId);
}

/// A previously saved cab petrolling (`getCabPetrolling` + its checklist).
class CabSaved {
  final String line;
  final String planningPlantId;
  final String lineType;
  final String fromLocation;
  final String toLocation;
  final String trainNo;
  final String inspection;
  final String actionTaken;
  final String remark;

  /// Id of the checklist record (`getCabPetrollingInspectionDetailsList.id`).
  final String detailId;

  /// Status and observation texts keyed by [CabChecklistRow.statusKey]/[CabChecklistRow.observationKey].
  final Map<String, String> answers;

  const CabSaved({
    required this.line,
    required this.planningPlantId,
    required this.lineType,
    required this.fromLocation,
    required this.toLocation,
    required this.trainNo,
    required this.inspection,
    required this.actionTaken,
    required this.remark,
    required this.detailId,
    required this.answers,
  });
}

/// `responseOutput` of `Inspection/getCabPetrollingDetails`.
class CabPetrollingData {
  final String inspectionNo;
  final String date;

  /// Id the save API expects as `InspectionId`.
  final String inspectionId;
  final List<CabLineOption> lines;
  final List<SelectOption> lineTypes;
  final CabSaved? saved;

  const CabPetrollingData({
    required this.inspectionNo,
    required this.date,
    required this.inspectionId,
    required this.lines,
    required this.lineTypes,
    required this.saved,
  });

  factory CabPetrollingData.fromJson(Map<String, dynamic> j) {
    String s(Map m, String k) => (m[k] ?? '').toString();

    final dateInfo = (j['getInspectionDate'] as Map?) ?? const {};
    // The first person entry is the "Select" placeholder; the real one is second.
    final people = apiList(j['getPersonResponsible']);
    final person = people.length > 1
        ? people[1]
        : (people.isEmpty ? <String, dynamic>{} : people.first);

    CabSaved? saved;
    final head = j['getCabPetrolling'];
    if (head is Map) {
      final detail = (j['getCabPetrollingInspectionDetailsList'] as Map?) ?? const {};
      saved = CabSaved(
        line: s(head, 'line'),
        planningPlantId: s(head, 'planningPlantId'),
        lineType: s(head, 'lineType'),
        fromLocation: s(head, 'fromLocation'),
        toLocation: s(head, 'toLocation'),
        trainNo: s(head, 'trainNo'),
        inspection: s(head, 'inspection'),
        actionTaken: s(head, 'actionTaken'),
        remark: s(head, 'remark'),
        detailId: s(detail, 'id'),
        answers: {
          for (final r in cabChecklistRows) ...{
            r.statusKey: s(detail, r.statusResponseKey),
            r.observationKey: s(detail, r.observationResponseKey),
          },
        },
      );
    }

    return CabPetrollingData(
      inspectionNo: s(dateInfo, 'inspectionNo'),
      date: s(dateInfo, 'date'),
      inspectionId: s(person, 'inspectionId'),
      lines: apiList(j['getCurrentCollectionTestDropDown'])
          .map((o) => CabLineOption(s(o, 'value'), s(o, 'label'), s(o, 'planningPlantId')))
          .toList(),
      lineTypes: apiOptions(j['getLineTypeDropDown']),
      saved: saved,
    );
  }
}

/// `responseOutput` of `Inspection/GetCabPetrollingView` (read-only display of a saved record).
class CabViewData {
  final String line;
  final String lineType;
  final String fromLocation;
  final String toLocation;
  final String trainNo;
  final String remark;

  /// Server-relative path of the attached image, or empty.
  final String filePath;

  /// 'True' / 'False' and observation text keyed like [CabSaved.answers].
  final Map<String, String> answers;

  const CabViewData({
    required this.line,
    required this.lineType,
    required this.fromLocation,
    required this.toLocation,
    required this.trainNo,
    required this.remark,
    required this.filePath,
    required this.answers,
  });

  factory CabViewData.fromJson(Map<String, dynamic> j) {
    String s(Map m, String k) => (m[k] ?? '').toString();
    final head = (j['getCabPetrollingInspectionList'] as Map?) ?? const {};
    final detail = (j['getCabPetrollingInspectionDetailsList'] as Map?) ?? const {};
    return CabViewData(
      line: s(head, 'lineName'),
      lineType: s(head, 'lineTypeName'),
      fromLocation: s(head, 'fromLocationName'),
      toLocation: s(head, 'toLocationName'),
      trainNo: s(head, 'trainNo'),
      remark: s(head, 'remark'),
      filePath: s(head, 'filepath'),
      answers: {
        for (final r in cabChecklistRows) ...{
          r.statusKey: s(detail, r.statusResponseKey),
          r.observationKey: s(detail, r.observationResponseKey),
        },
      },
    );
  }
}
