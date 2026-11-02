import 'api_helpers.dart';
import 'checklist_rules.dart';

/// One row of a buffer stop checklist table. [srNo] is the key the API stores it under.
class BufferCheckRow {
  final String srNo;
  final String checkPoint;
  final String standardValue;

  const BufferCheckRow(this.srNo, this.checkPoint, this.standardValue);
}

const bufferMonthOptions = <SelectOption>[
  SelectOption('6 Month', '6 Month'),
  SelectOption('12 Month', '12 Month'),
];

const bufferKmphOptions = <SelectOption>[
  SelectOption('10', '10'),
  SelectOption('25', '25'),
];

const _halfYearly25 = <BufferCheckRow>[
  BufferCheckRow('1', 'Check for Damage to Front Frame Fixings', 'Condition of front frame'),
  BufferCheckRow('2', 'Check for damage to the impact pad & main frame', 'Condition of rubber pad & main Frame'),
  BufferCheckRow('3', 'Check for movement from the starting point of the trailing friction shoes', '0 mm'),
  BufferCheckRow('4', 'Torque on --', ''),
  BufferCheckRow('5', 'Anti-lift Shoes', '215 Nm with grease progressively'),
  BufferCheckRow('6', 'Main Frame', '350 Nm'),
  BufferCheckRow(
      '7',
      'Trailing Friction Shoes 6 coach -4 +9 on each rail 3 coach – 3 + 3 on each rail *Refer installation drawing',
      '75 Nm with Grease progressively'),
  BufferCheckRow('8', 'Total Installation Length', '6 coaches: 25 m 3 coaches: 22 m'),
  BufferCheckRow('9', 'Check for visible signs of degradation in the rubber impact pad', 'Condition of rubber pad'),
];

const _yearly25 = <BufferCheckRow>[
  BufferCheckRow('1', 'Check for movement from the start points of the main frame', '0 mm'),
  BufferCheckRow('2', 'Check for movement from the start point of the trailing friction Shoes', '0 mm'),
  BufferCheckRow(
      '3',
      'Refit the anti-lift shoes & friction shoes & tighten with the recommended torques. as per installation drawing [refer manual]',
      'Refit & tighten the anti-lift shoes & friction shoes'),
  BufferCheckRow('4', 'Check for damage to front frame fixings', 'Condition of front frame'),
  BufferCheckRow('5', 'Check for damage to the impact pad & main frame', 'Condition of rubber pad & main Frame'),
  BufferCheckRow('6', 'Torque on --', ''),
  BufferCheckRow('7', 'Anti-lift Shoes', '215 Nm with Grease Progressively'),
  BufferCheckRow('8', 'Main Frame', '350 Nm'),
  BufferCheckRow(
      '9',
      'Trailing Friction Shoes 6 coach -4 +9 on each rail 3 coach – 3 + 3 on each rail *Refer installation drawing.',
      '75 Nm with Grease progressively'),
  BufferCheckRow('10', 'Total Installation Length', '6 coaches: 25 m 3 coaches: 22 m'),
  BufferCheckRow('11', 'Check for visible signs of degradation in the rubber impact pad.', 'Condition of rubber pad'),
];

const _halfYearly10 = <BufferCheckRow>[
  BufferCheckRow('1', 'Check for damage to front frame fixings', 'Condition of Front Frame'),
  BufferCheckRow('2', 'Check for damage to the impact pad & main frame', 'Condition of rubber pad & main Frame'),
  BufferCheckRow('3', 'Check for movement from the starting point of the trailing friction shoes', '0 mm'),
  BufferCheckRow('4', 'Torque on --', ''),
  BufferCheckRow('5', 'Anti-lift Shoes', '350 Nm'),
  BufferCheckRow('6', 'Main Frame', '350 Nm'),
  BufferCheckRow('7', 'Trailing Friction Shoes', '150- 165 Nm'),
  BufferCheckRow('8', 'Total Installation Length', '6.319'),
  BufferCheckRow('9', 'Check for visible signs of degradation in the rubber impact pad.', 'Condition of rubber pad'),
];

const _yearly10 = <BufferCheckRow>[
  BufferCheckRow('1', 'Check for movement from the start points of the main frame', '0 mm'),
  BufferCheckRow('2', 'Check for movement from the start point of the trailing friction Shoes', '0 mm'),
  BufferCheckRow(
      '3',
      'Refit the anti-lift shoes & friction shoes & tighten with the recommended torques. as per installation drawing [refer manual]',
      'Refit & tighten the anti-lift shoes & friction shoes'),
  BufferCheckRow('4', 'Check for damage to front frame fixings', 'Condition of front frame'),
  BufferCheckRow('5', 'Check for damage to the impact pad & main frame', 'Condition of rubber pad & main Frame'),
  BufferCheckRow('6', 'Torque on --', ''),
  BufferCheckRow('7', 'Anti-lift Shoes', '215 Nm with Grease Progressively'),
  BufferCheckRow('8', 'Main Frame', '350 Nm'),
  BufferCheckRow(
      '9',
      'Trailing Friction Shoes 3 coach 2+1 on each rail 6 coach 3 + 1 on each rail.',
      '75 Nm +/- 2 with Grease progressively'),
  BufferCheckRow('10', 'Total installation length (inclusive of 1.904 m body)', '3 coach -6.6m 6 coach -10 m'),
  BufferCheckRow('11', 'Check for visible signs of degradation in the rubber impact pad.', 'Condition of rubber pad'),
];


/// One entry column of a checklist table (`column1`.. in the API).
class BufferColumn {
  final String key;
  final String heading;
  final String hint;

  const BufferColumn(this.key, this.heading, [this.hint = '']);
}

/// A checklist table for one Month / KMPH choice.
class BufferChecklist {
  final String title;
  final List<BufferColumn> columns;
  final List<BufferCheckRow> rows;

  const BufferChecklist(this.title, this.columns, this.rows);
}

// Business area 2200 records three free-text columns per row.
const _standardColumns = <BufferColumn>[
  BufferColumn('column1', 'Work Assessment Date'),
  BufferColumn('column2', 'Measured Value'),
  BufferColumn('column3', 'Action to be Taken'),
];

// Every other business area records a date and a Y/N for preventive and modified maintenance.
const _maintenanceColumns = <BufferColumn>[
  BufferColumn('column1', 'Preventive Maintenance: Measured Details Date', 'DD/MM/YYYY'),
  BufferColumn('column2', 'Preventive Maintenance: Action Required Y/N', 'Y/N'),
  BufferColumn('column3', 'Modified Maintenance: Measured Details Date', 'DD/MM/YYYY'),
  BufferColumn('column4', 'Modified Maintenance: Action Required Y/N', 'Y/N'),
];

// Rows of the other business areas' 6 Month / 10 KMPH table; note the 4a/4b/4c keys.
const _maintenanceHalfYearly10 = <BufferCheckRow>[
  BufferCheckRow('1', 'Check for damage to the impact pad & main frame', 'Condition of rubber pad & main Frame'),
  BufferCheckRow('2', 'Check for movement from the starting point of the main frame', '0 mm'),
  BufferCheckRow('3', 'Check for movement from the starting point of the trailing friction shoe', '0 mm'),
  BufferCheckRow('4', 'Torque on --', ''),
  BufferCheckRow('4a', 'Anti-lift Shoes', '350 Nm'),
  BufferCheckRow('4b', 'Main Frame', '350 Nm'),
  BufferCheckRow('4c', 'Trailing Friction Shoes', '150 - 165 Nm'),
  BufferCheckRow('5', 'Total Installation Length', '6.319'),
  BufferCheckRow('6', 'Check for visible signs of degradation in the rubber impact pad.', 'Condition of rubber pad'),
];

const _maintenanceYearly10 = <BufferCheckRow>[
  BufferCheckRow('1', 'Remove anti-lift shoes and check for damage and wear', 'Damage/Broken/Corrosion/Other'),
  BufferCheckRow('2', 'Remove and check all friction shoes for damage', 'Damage/Broken/Corrosion/Other'),
  BufferCheckRow('3', 'Refit the anti-lift shoes & friction shoes & tighten with the recommended torques.', 'Properly/Unproperly'),
  BufferCheckRow('4', 'Check for damage to front frame fixings', 'Yes/No'),
  BufferCheckRow('5', 'Check for damage to the impact pad & main frame', 'Yes/No'),
  BufferCheckRow('6', 'Check for movement from the start point of the main frame', '0 mm'),
  BufferCheckRow('7', 'Check for movement from the starting point of the trailing friction shoes', '0 mm'),
  BufferCheckRow('8', 'Torque on --', ''),
  BufferCheckRow('8a', 'Anti-lift shoes', '350 Nm'),
  BufferCheckRow('8b', 'Main frame', '350 Nm'),
  BufferCheckRow('8c', 'Trailing friction shoes', '150- 165 Nm'),
  BufferCheckRow('9', 'Total installation length', '6.319'),
  BufferCheckRow('10', 'Check for visible signs of degradation in the rubber impact pad', 'Condition of rubber pad'),
];

// Same rows as the 10 KMPH half-yearly table; only the installation length differs.
const _maintenanceHalfYearly25 = <BufferCheckRow>[
  BufferCheckRow('1', 'Check for damage to the impact pad & main frame', 'Condition of rubber pad & main Frame'),
  BufferCheckRow('2', 'Check for movement from the starting point of the main frame', '0 mm'),
  BufferCheckRow('3', 'Check for movement from the starting point of the trailing friction shoe', '0 mm'),
  BufferCheckRow('4', 'Torque on --', ''),
  BufferCheckRow('4a', 'Anti-lift Shoes', '350 Nm'),
  BufferCheckRow('4b', 'Main Frame', '350 Nm'),
  BufferCheckRow('4c', 'Trailing Friction Shoes', '150 - 165 Nm'),
  BufferCheckRow('5', 'Total Installation Length', '14.834'),
  BufferCheckRow('6', 'Check for visible signs of degradation in the rubber impact pad.', 'Condition of rubber pad'),
];

// Unlike the 10 KMPH table, the sub-rows under "Torque on --" use plain keys 9 to 11.
const _maintenanceYearly25 = <BufferCheckRow>[
  BufferCheckRow('1', 'Remove anti-lift shoes and check for damage and wear', 'Damage/Broken/Corrosion/Other'),
  BufferCheckRow('2', 'Remove and check all friction shoes for damage', 'Damage/Broken/Corrosion/Other'),
  BufferCheckRow('3', 'Refit the anti-lift shoes & friction shoes & tighten with the recommended torques.', 'Refit & tighten the anti-lift shoes & friction shoes'),
  BufferCheckRow('4', 'Check for damage to front frame fixings', 'Condition of front frame'),
  BufferCheckRow('5', 'Check for damage to the impact pad & main frame', 'Condition of rubber pad & main Frame'),
  BufferCheckRow('6', 'Check for movement from the start point of the main frame', '0 mm'),
  BufferCheckRow('7', 'Check for movement from the starting point of the trailing friction shoes', '0 mm'),
  BufferCheckRow('8', 'Torque on --', ''),
  BufferCheckRow('9', 'Anti-lift shoes', '350 Nm'),
  BufferCheckRow('10', 'Main frame', '350 Nm'),
  BufferCheckRow('11', 'Trailing friction shoes', '150- 165 Nm'),
  BufferCheckRow('12', 'Total installation length', '14.834'),
  BufferCheckRow('13', 'Check for visible signs of degradation in the rubber impact pad', 'Condition of rubber pad'),
];

/// Section title of the checklist for a Month / KMPH choice.
String bufferChecklistTitle(String? month, String? kmph) {
  final period = month == '6 Month' ? 'Half Yearly' : 'Yearly';
  return '$period Work Assessment: Buffer Stop for $kmph KMPH';
}

/// Checklist table for a Month / KMPH choice and business area, or null when it has none.
/// [standardArea] is true for business area 2200.
BufferChecklist? bufferChecklistFor(String? month, String? kmph, {required bool standardArea}) {
  final title = bufferChecklistTitle(month, kmph);
  if (standardArea) {
    switch ('$month|$kmph') {
      case '6 Month|25':
        return BufferChecklist(title, _standardColumns, _halfYearly25);
      case '12 Month|25':
        return BufferChecklist(title, _standardColumns, _yearly25);
      case '6 Month|10':
        return BufferChecklist(title, _standardColumns, _halfYearly10);
      case '12 Month|10':
        return BufferChecklist(title, _standardColumns, _yearly10);
    }
    return null;
  }
  switch ('$month|$kmph') {
    case '6 Month|10':
      return BufferChecklist(title, _maintenanceColumns, _maintenanceHalfYearly10);
    case '12 Month|10':
      return BufferChecklist('Yearly Inspection: Buffer Stop for 10 KMPH', _maintenanceColumns, _maintenanceYearly10);
    case '6 Month|25':
      return BufferChecklist('Half Yearly Inspection: Buffer Stop for 25 KMPH', _maintenanceColumns, _maintenanceHalfYearly25);
    case '12 Month|25':
      return BufferChecklist('Yearly Inspection: Buffer Stop for 25 KMPH', _maintenanceColumns, _maintenanceYearly25);
  }
  return null;
}

/// API key of the legacy per-variant arrays the web still sends (empty) with every submit,
/// with the item names of that variant.
const _legacyHalfYearItems = [
  'CheckforDamageFrontFrame',
  'CheckforDamageMainFrame',
  'CheckforMovementFrictionSheos',
  'TorqueOn',
  'AntiliftShoe',
  'MainFrameThreeFiftyNm',
  'TrailingFrictionShoes',
  'TotalInstallationLength',
  'Checkforvisiblesignsofdegradation',
];
const _legacyYearlyItems = [
  'CheckforMovementMainFrame',
  'CheckforMovementFrictionSheos',
  'RefitAntiLiftShoes',
  'CheckforDamageFrameFixing',
  'CheckforDamageMainFrame',
  'TorqueOn',
  'AntiliftShoe',
  'MainFrameThreeFiftyNm',
  'TrailingFrictionShoes',
  'TotalInstallationLength',
  'Checkforvisiblesignsofdegradation',
];

/// The `{apiKey: [three empty rows]}` the web sends for the chosen Month / KMPH.
/// The entered values travel in the common checklist instead.
Map<String, List<Map<String, dynamic>>> bufferLegacyPlaceholder(String month, String kmph) {
  final half = month == '6 Month';
  final key = '${half ? 'getBufferHalfYear' : 'getBufferYearly'}${kmph == '10' ? 'Ten' : 'TwentyFive'}kmph';
  final items = half ? _legacyHalfYearItems : _legacyYearlyItems;
  return {
    key: List.generate(3, (_) => {'Id': 0, for (final i in items) i: ''}),
  };
}

/// A previously saved buffer stop header (`getBufferStop`).
class BufferSaved {
  final String kmph;
  final String month;
  final String time;
  final String lineTypeName;
  final String chainageName;
  final String lineTypeId;
  final String chainageId;
  final String remark;

  const BufferSaved({
    required this.kmph,
    required this.month,
    required this.time,
    required this.lineTypeName,
    required this.chainageName,
    this.lineTypeId = '',
    this.chainageId = '',
    required this.remark,
  });
}

/// `responseOutput` of `Inspection/GetBufferStopDetails`.
class BufferStopData {
  final String inspectionNo;
  final String date;

  /// Id the save APIs expect as `InspectionId`.
  final String inspectionId;
  final String personName;
  final String personId;
  final List<SelectOption> lineTypes;
  final List<SelectOption> chainages;
  final BufferSaved? saved;

  /// Saved checklist cells, one map per (span, km, srNo); round-tripped on save.
  final List<JsonMap> checklist;

  const BufferStopData({
    required this.inspectionNo,
    required this.date,
    required this.inspectionId,
    required this.personName,
    required this.personId,
    required this.lineTypes,
    required this.chainages,
    required this.saved,
    required this.checklist,
  });

  factory BufferStopData.fromJson(Map<String, dynamic> j) {
    String s(Map m, String k) => (m[k] ?? '').toString();

    final dateInfo = (j['getInspectionDate'] as Map?) ?? const {};
    // The first person entry is the "Select" placeholder; the real one is second.
    final people = apiList(j['getPersonResponsible']);
    final person = people.length > 1
        ? people[1]
        : (people.isEmpty ? <String, dynamic>{} : people.first);
    final head = j['getBufferStop'];

    // A saved record can come back without the date / person blocks (null);
    // its own header carries the same values.
    final saved = head is Map ? head : const {};
    String pick(String a, String b) => a.isNotEmpty ? a : b;

    return BufferStopData(
      inspectionNo: pick(s(dateInfo, 'inspectionNo'), s(saved, 'inspectionNo')),
      date: pick(s(dateInfo, 'date'), s(saved, 'date')),
      inspectionId: s(person, 'inspectionId'),
      personName: pick(s(person, 'label'), s(saved, 'personName')),
      personId: s(person, 'value'),
      lineTypes: apiOptions(j['getLineTypeDropDown']),
      chainages: apiOptions(j['getChainageDropDown']),
      saved: head is Map
          ? BufferSaved(
              kmph: s(head, 'kmph'),
              month: s(head, 'month'),
              time: s(head, 'time'),
              lineTypeName: s(head, 'lineTypeName'),
              chainageName: s(head, 'chainageName'),
              lineTypeId: s(head, 'lineUpDown'),
              chainageId: s(head, 'chainage'),
              remark: s(head, 'remark'),
            )
          : null,
      checklist: apiList(j['getBufferStopCommonCheckList']),
    );
  }
}
