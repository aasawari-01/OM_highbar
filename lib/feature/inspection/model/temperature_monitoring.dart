import 'api_helpers.dart';

/// One reading of the temperature table.
class TempRow {
  int id;
  String fromDate; // dd/MM/yyyy
  String toDate; // dd/MM/yyyy
  String time; // HH:mm
  double temperature;

  TempRow({
    required this.id,
    required this.fromDate,
    required this.toDate,
    required this.time,
    required this.temperature,
  });

  /// A row of the Excel upload; the API names its keys in either case.
  factory TempRow.fromUpload(int id, Map<String, dynamic> j) {
    String s(String a, String b) => (j[a] ?? j[b] ?? '').toString();
    return TempRow(
      id: id,
      fromDate: s('FromDate', 'fromdate'),
      toDate: s('ToDate', 'todate'),
      time: s('TimeValue', 'Time'),
      temperature: double.tryParse(s('TemperatureValue', 'Temperature')) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'Id': id,
        'Temperature': temperature,
        'Time': time,
        'Fromdate': fromDate,
        'Todate': toDate,
      };
}

/// `responseOutput` of `Inspection/getTempMonDetails`.
class TempData {
  final String inspectionNo;
  final String date;

  /// Id the save APIs expect as `InspectionId`.
  final String inspectionId;

  const TempData({required this.inspectionNo, required this.date, required this.inspectionId});

  factory TempData.fromJson(Map<String, dynamic> j) {
    final dateInfo = (j['getInspectionDate'] as Map?) ?? const {};
    // The first entry is the "Select" placeholder; the real one is second.
    final values = apiList(j['getCurrentInspectionValue']);
    final current = values.length > 1
        ? values[1]
        : (values.isEmpty ? <String, dynamic>{} : values.first);
    return TempData(
      inspectionNo: (dateInfo['inspectionNo'] ?? '').toString(),
      date: (dateInfo['date'] ?? '').toString(),
      inspectionId: (current['inspectionId'] ?? '').toString(),
    );
  }
}
