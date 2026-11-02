import 'api_helpers.dart';

/// One toe load reading (`getToeLoadDetails` item). Values stay as entered text.
class ToeRow {
  int id;
  String reach;
  String pierNo;
  String plinthNo;
  String lhsNonGauge;
  String lhsGauge;
  String lhsTotal;
  String rhsNonGauge;
  String rhsGauge;
  String rhsTotal;
  String basePlateNumber;
  String remark;

  ToeRow({
    required this.id,
    required this.reach,
    required this.pierNo,
    required this.plinthNo,
    required this.lhsNonGauge,
    required this.lhsGauge,
    required this.lhsTotal,
    required this.rhsNonGauge,
    required this.rhsGauge,
    required this.rhsTotal,
    required this.basePlateNumber,
    required this.remark,
  });

  factory ToeRow.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] ?? '').toString();
    return ToeRow(
      id: int.tryParse(s('id')) ?? 0,
      reach: s('reach'),
      pierNo: s('pierNo'),
      plinthNo: s('plinthNo'),
      lhsNonGauge: s('lhsRailNonGaugeside'),
      lhsGauge: s('lhsRailGaugeside'),
      lhsTotal: s('lhsRailTotal'),
      rhsNonGauge: s('rhsRailNonGaugeside'),
      rhsGauge: s('rhsRailGaugeside'),
      rhsTotal: s('rhsRailTotal'),
      basePlateNumber: s('basePlateNumber'),
      remark: s('remark'),
    );
  }

  Map<String, dynamic> toJson(String date) => {
        'id': id,
        'Date': date,
        'Reach': reach,
        'PierNo': pierNo,
        'PlinthNo': plinthNo,
        'LHSRailNonGaugeside': lhsNonGauge,
        'LHSRailGaugeside': lhsGauge,
        'LHSRailTotal': lhsTotal,
        'RHSRailNonGaugeside': rhsNonGauge,
        'RHSRailGaugeside': rhsGauge,
        'RHSRailTotal': rhsTotal,
        'Remark': remark,
        'BasePlateNumber': basePlateNumber,
      };
}

/// `responseOutput` of `Inspection/GetToeLoadDetails`.
class ToeData {
  final String inspectionNo;
  final String date;

  /// Id the save API expects as `InspectionId`.
  final String inspectionId;
  final List<ToeRow> rows;

  const ToeData({
    required this.inspectionNo,
    required this.date,
    required this.inspectionId,
    required this.rows,
  });

  factory ToeData.fromJson(Map<String, dynamic> j) {
    final dateInfo = (j['getInspectionDate'] as Map?) ?? const {};
    // The first person entry is the "Select" placeholder; the real one is second.
    final people = apiList(j['getPersonResponsible']);
    final person = people.length > 1
        ? people[1]
        : (people.isEmpty ? <String, dynamic>{} : people.first);
    return ToeData(
      inspectionNo: (dateInfo['inspectionNo'] ?? '').toString(),
      date: (dateInfo['date'] ?? '').toString(),
      inspectionId: (person['inspectionId'] ?? '').toString(),
      rows: apiList(j['getToeLoadDetails']).map(ToeRow.fromJson).toList(),
    );
  }
}
