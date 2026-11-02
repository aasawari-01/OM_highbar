import 'api_helpers.dart';

/// One numeric reading of a load row (MD, demand, line current, pf, kWH, kVAh).
class LoadReadingField {
  final String label;
  final String payloadKey; // key sent to the API
  final String responseKey; // key returned by GetLoadDetails

  /// True for pf: up to 5 digits and 2 decimals. Others are up to 10 digits.
  final bool decimal;

  const LoadReadingField(this.label, this.payloadKey, this.responseKey, {this.decimal = false});
}

const loadReadingFields = <LoadReadingField>[
  LoadReadingField('MD KVA', 'MdKva', 'mdKva'),
  LoadReadingField('MD KW', 'MdKW', 'mdKW'),
  LoadReadingField('MD KVAR', 'MdKVAR', 'mdKVAR'),
  LoadReadingField('Demand(DM) KVA', 'DemandMdKVA', 'demandMdKVA'),
  LoadReadingField('Demand(DM) KW', 'DemandMdKW', 'demandMdKW'),
  LoadReadingField('Demand(DM) KVAR', 'DemandMdKVAR', 'demandMdKVAR'),
  LoadReadingField('Line Current(A) KVA', 'LineCurrentKVA', 'lineCurrentKVA'),
  LoadReadingField('Line Current(A) KW', 'LineCurrentKW', 'lineCurrentKW'),
  LoadReadingField('Line Current(A) KVAR', 'LineCurrentKVAR', 'lineCurrentKVAR'),
  LoadReadingField('pf', 'OtherPF', 'otherPF', decimal: true),
  LoadReadingField('kWH', 'OtherkWH', 'otherkWH'),
  LoadReadingField('kVAh', 'OtherkVAH', 'otherkVAH'),
];

/// One MDB row: its type and the readings, keyed by [LoadReadingField.payloadKey].
class LoadRow {
  /// Server id; null for a row added on this screen.
  final String? id;
  final String mdbType;
  final Map<String, String> readings;

  const LoadRow({this.id, required this.mdbType, required this.readings});

  factory LoadRow.fromJson(Map<String, dynamic> j) {
    final id = (j['id'] ?? '').toString();
    return LoadRow(
      id: id.isEmpty ? null : id,
      mdbType: (j['mdbType'] ?? '').toString(),
      readings: {
        for (final f in loadReadingFields) f.payloadKey: (j[f.responseKey] ?? '').toString(),
      },
    );
  }

  /// Row in the shape `insertLoadDetailsInspection` expects.
  Map<String, dynamic> toPayload() => {
        'Id': id == null ? null : wireId(id!),
        'MdbType': wireId(mdbType),
        ...readings,
      };
}

/// `responseOutput` of `Inspection/GetLoadDetails`.
class LoadDetailsData {
  final String inspectionNo;
  final String date;

  /// Id the save API expects as `InspectionId`.
  final String inspectionId;
  final List<SelectOption> mdbTypes;
  final List<LoadRow> rows;

  /// Totals of the saved header (`getLoadView[0]`); sent back unchanged on save.
  final String pf;
  final String kwh;
  final String kvah;

  const LoadDetailsData({
    required this.inspectionNo,
    required this.date,
    required this.inspectionId,
    required this.mdbTypes,
    required this.rows,
    required this.pf,
    required this.kwh,
    required this.kvah,
  });

  factory LoadDetailsData.fromJson(Map<String, dynamic> j) {
    final dateInfo = (j['getInspectionDate'] as Map?) ?? const {};
    // The first person entry is the "Select" placeholder; the real one is second.
    final people = apiList(j['getPersonResponsible']);
    final person = people.length > 1
        ? people[1]
        : (people.isEmpty ? <String, dynamic>{} : people.first);
    final view = apiList(j['getLoadView']);
    final header = view.isEmpty ? const <String, dynamic>{} : view.first;

    return LoadDetailsData(
      inspectionNo: (dateInfo['inspectionNo'] ?? '').toString(),
      date: (dateInfo['date'] ?? '').toString(),
      inspectionId: (person['inspectionId'] ?? '').toString(),
      mdbTypes: apiOptions(j['getMDBType']),
      rows: apiList(j['getLoadDetailsView']).map(LoadRow.fromJson).toList(),
      pf: (header['pf'] ?? '').toString(),
      kwh: (header['kwh'] ?? '').toString(),
      kvah: (header['kvah'] ?? '').toString(),
    );
  }
}
