/// One row of `Inspection/getJEInspectionList`.
class JEInspectionItem {
  final int id;
  final String jeInspectionId;
  final String inspectionNo;
  final String deptName;
  final String inspectionName;
  final String inspectionType;
  final String inspectionScheduledDate;
  final String todayDate;
  final String createdName;
  final String status;
  final String statusName;
  final int isSkip;
  final int countSkip;

  const JEInspectionItem({
    required this.id,
    required this.jeInspectionId,
    required this.inspectionNo,
    required this.deptName,
    required this.inspectionName,
    required this.inspectionType,
    required this.inspectionScheduledDate,
    required this.todayDate,
    required this.createdName,
    required this.status,
    required this.statusName,
    required this.isSkip,
    required this.countSkip,
  });

  factory JEInspectionItem.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] ?? '').toString();
    int i(String k) => int.tryParse(s(k)) ?? 0;
    return JEInspectionItem(
      id: i('id'),
      jeInspectionId: s('jeInspectionId'),
      inspectionNo: s('inspectionNo'),
      deptName: s('deptName'),
      inspectionName: s('inspectionName'),
      inspectionType: s('inspectionType'),
      inspectionScheduledDate: s('inspectionScheduledDate'),
      todayDate: s('todayDate'),
      createdName: s('createdName'),
      status: s('status'),
      statusName: s('statusName'),
      isSkip: i('isSkip'),
      countSkip: i('countSKip'),
    );
  }

  /// Same status mapping as the web `jeInspectionStatusText`.
  String get statusText {
    switch (status) {
      case '153':
        return 'Assigned';
      case '154':
        return 'ReAssigned';
      case '155':
        return 'InProcess';
      case '156':
        return 'Skip';
      case '157':
        return 'Complete';
      case '158':
        return 'Closed';
      case '194':
        return 'Send For Correction';
      case '341':
        return 'Completed With Observations';
      default:
        return statusName;
    }
  }

  bool get canFill =>
      isSkip != 1 && (status == '153' || status == '154' || status == '155');

  bool get canFillObservation =>
      isSkip != 1 && statusName == 'Completed With Observations';

  bool get canView => status == '157';

  /// Skip is offered only on the scheduled day for freshly assigned items.
  bool get canSkip =>
      status == '153' &&
      inspectionScheduledDate == todayDate &&
      isSkip != 1 &&
      countSkip <= 0;

  bool get pendingSkipAck =>
      status == '153' && inspectionScheduledDate == todayDate && isSkip == 1;
}
