import 'package:intl/intl.dart';

/// Rules for the common inspection checklist (port of the web checklist logic).

typedef JsonMap = Map<String, dynamic>;

const int remarkMaxLength = 100;

String normText(dynamic v) => (v ?? '').toString().trim().toLowerCase();
String normControl(dynamic v) =>
    normText(v).replaceAll(RegExp(r'[\s/_-]+'), '');

bool isRemarkColumn(dynamic name) => RegExp(r'^remarks?$', caseSensitive: false)
    .hasMatch((name ?? '').toString().trim());
bool isObservationColumn(dynamic name) {
  final n = normText(name).replaceAll(RegExp(r'\s+'), ' ');
  return n == 'observation' ||
      n == 'is observation required' ||
      n == 'add to observation' ||
      n == 'addtoobservation';
}

bool isActionColumn(dynamic name) {
  final n = normText(name);
  return n == 'action' || n == 'visit at site';
}

bool isPositiveName(dynamic n) =>
    ['yes', 'okay', 'ok'].contains(normControl(n));
bool isNegativeName(dynamic n) =>
    ['no', 'notokay', 'notok'].contains(normControl(n));
bool isNaName(dynamic n) => normControl(n) == 'na';
bool isNotOkayName(dynamic n) => ['notokay', 'notok'].contains(normControl(n));

bool isRadioControl(JsonMap c) => normText(c['itemType']) == 'radio';
bool isCheckboxControl(JsonMap c) =>
    ['checkbox', 'checkboxes'].contains(normText(c['itemType']));
bool isSelectControl(JsonMap c) =>
    ['select', 'dropdown', 'combobox'].contains(normText(c['itemType']));
bool isTextControl(JsonMap c) =>
    ['text', 'textarea', 'textbox'].contains(normText(c['itemType']));

bool isControlDisabled(JsonMap c) {
  final d = c['itemDisabled'];
  return d == 1 || d == true || d == '1' || normText(d) == 'true';
}

bool isMandatoryField(JsonMap f) {
  final m = f['isMandatory'];
  return m == 1 || m == '1' || m == true || m == 'true';
}

List<JsonMap> columnControls(JsonMap col) =>
    ((col['controlType'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => e as JsonMap)
        .toList();

JsonMap? remarkTextControl(JsonMap col) {
  final controls = columnControls(col);
  for (final c in controls) {
    if (isTextControl(c)) return c;
  }
  return null;
}

/// Remark columns always need a Text control to bind to.
void ensureRemarkControl(JsonMap col) {
  if (remarkTextControl(col) != null) return;
  final list = (col['controlType'] as List?) ?? [];
  list.add(<String, dynamic>{
    'itemListId': 'remark-${col['columnId']}',
    'itemType': 'Text',
    'itemName': 'Remark',
    'itemSelectedValue': '',
  });
  col['controlType'] = list;
}

class TogglePair {
  JsonMap? positive;
  JsonMap? negative;
  JsonMap? na;
  bool isOkayKind = false;
  List<JsonMap> others = [];
}

TogglePair resolveTogglePair(List<JsonMap> radios) {
  final p = TogglePair();
  p.na = radios
      .where((c) => isNaName(c['itemName']))
      .cast<JsonMap?>()
      .firstWhere((_) => true, orElse: () => null);
  final nonNa = radios.where((c) => !isNaName(c['itemName'])).toList();
  JsonMap? byNorm(String n) {
    for (final c in nonNa) {
      if (normControl(c['itemName']) == n) return c;
    }
    return null;
  }

  final yes = byNorm('yes'), no = byNorm('no');
  if (yes != null && no != null) {
    p.positive = yes;
    p.negative = no;
    p.others = nonNa.where((c) => c != yes && c != no).toList();
    return p;
  }
  final okay = byNorm('okay') ?? byNorm('ok');
  final notOkay = byNorm('notokay') ?? byNorm('notok');
  if (okay != null && notOkay != null) {
    p.positive = okay;
    p.negative = notOkay;
    p.isOkayKind = true;
    p.others = nonNa.where((c) => c != okay && c != notOkay).toList();
    return p;
  }
  p.others = nonNa;
  return p;
}

String formatActionLabel(dynamic name) {
  switch (normControl(name)) {
    case 'yes':
      return 'Yes';
    case 'no':
      return 'No';
    case 'okay':
    case 'ok':
      return 'Okay';
    case 'notokay':
    case 'notok':
      return 'Not Okay';
    default:
      return (name ?? '').toString();
  }
}

bool isControlSelected(JsonMap c) => c['itemName'] == c['itemSelectedValue'];

List<JsonMap> rowColumns(JsonMap row) =>
    ((row['columnsType'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => e as JsonMap)
        .toList();

bool isRowNotOkay(JsonMap row) {
  for (final col in rowColumns(row)) {
    if (!isActionColumn(col['columnName'])) continue;
    final pair =
        resolveTogglePair(columnControls(col).where(isRadioControl).toList());
    if (pair.isOkayKind && pair.negative != null) {
      return isControlSelected(pair.negative!);
    }
  }
  return false;
}

bool rowHasObservationYes(JsonMap row) {
  if (row['addToObservation'] == true || row['isObservation'] == true) {
    return true;
  }
  for (final col in rowColumns(row)) {
    if (!isObservationColumn(col['columnName'])) continue;
    return columnControls(col).any((c) =>
        isRadioControl(c) &&
        isControlSelected(c) &&
        isPositiveName(c['itemName']));
  }
  return false;
}

String rowRemark(JsonMap row) {
  final obs = (row['observationRemark'] ?? '').toString();
  if (obs.isNotEmpty) return obs;
  for (final col in rowColumns(row)) {
    if (isRemarkColumn(col['columnName'])) {
      return (remarkTextControl(col)?['itemSelectedValue'] ?? '').toString();
    }
  }
  return '';
}

void setRowRemark(JsonMap row, String text) {
  for (final col in rowColumns(row)) {
    if (!isRemarkColumn(col['columnName'])) continue;
    ensureRemarkControl(col);
    remarkTextControl(col)!['itemSelectedValue'] = text;
  }
  row['_rev'] = ((row['_rev'] as int?) ?? 0) + 1;
}

void setRowObservation(JsonMap row, bool? value) {
  if (value != null) {
    for (final col in rowColumns(row)) {
      if (!isObservationColumn(col['columnName'])) continue;
      final controls = columnControls(col);
      final radios = controls.where(isRadioControl).toList();
      if (radios.isNotEmpty) {
        final yes = radios.firstWhere((c) => isPositiveName(c['itemName']),
            orElse: () => radios.last);
        final no = radios.firstWhere((c) => isNegativeName(c['itemName']),
            orElse: () => radios.first);
        final sel = value ? yes : no;
        for (final c in radios) {
          c['itemSelectedValue'] = identical(c, sel) ? c['itemName'] : '';
        }
      } else if (controls.isNotEmpty) {
        for (var i = 0; i < controls.length; i++) {
          controls[i]['itemSelectedValue'] =
              i == 0 ? (value ? 'Yes' : 'No') : '';
        }
      }
    }
    row['isObservation'] = value;
    row['addToObservation'] = value;
  }
}

String selectedDisplay(JsonMap col) {
  final out = <String>[];
  for (final c in columnControls(col)) {
    final sel = c['itemSelectedValue'];
    if (sel == null || sel == '') continue;
    if (isRadioControl(c)) {
      if (sel.toString() == (c['itemName'] ?? '').toString()) {
        out.add(formatActionLabel(c['itemName']));
      }
    } else if (isCheckboxControl(c)) {
      if (sel == true ||
          sel == '1' ||
          sel == 'true' ||
          sel.toString() == (c['itemName'] ?? '').toString()) {
        out.add((c['itemName'] ?? 'Yes').toString());
      }
    } else {
      out.add(sel.toString());
    }
  }
  return out.isEmpty ? '-' : out.join(', ');
}

/// Columns ordered as the API header list, then any leftovers.
List<JsonMap> orderedColumns(JsonMap row, List<JsonMap> headers) {
  final cols = rowColumns(row);
  if (headers.isEmpty) return cols;
  final out = <JsonMap>[];
  for (final h in headers) {
    final id = (h['headerColumnId'] ?? '').toString();
    final name = normText(h['headerColumnName']);
    for (final c in cols) {
      if ((c['columnId'] ?? '').toString() == id ||
          normText(c['columnName']) == name) {
        if (!out.contains(c)) out.add(c);
        break;
      }
    }
  }
  for (final c in cols) {
    if (!out.contains(c)) out.add(c);
  }
  return out;
}

/// Failure number of a checklist row; empty when none ("0" counts as none).
String rowFailureCode(JsonMap row) {
  for (final v in [row['notificationCode'], row['NotificationCode']]) {
    if (v == null || v is Map || v is List) continue;
    final t = v.toString().trim();
    if (t.isNotEmpty && t != '0') return t;
  }
  return '';
}

void normalizeRow(JsonMap row) {
  for (final col in rowColumns(row)) {
    col['controlType'] = (col['controlType'] is List)
        ? List.of(col['controlType'])
        : <dynamic>[];
    if (isRemarkColumn(col['columnName'])) ensureRemarkControl(col);
  }
  if (!isRowNotOkay(row) || !rowHasObservationYes(row)) {
    setRowObservation(row, false);
    if (!isRowNotOkay(row)) row['observationRemark'] = '';
  }
}

/// Strips UI-only keys (prefixed `_`) before rows are sent to the API.
dynamic stripUiKeys(dynamic v) {
  if (v is Map) {
    return {
      for (final e in v.entries)
        if (!e.key.toString().startsWith('_')) e.key: stripUiKeys(e.value),
    };
  }
  if (v is List) return v.map(stripUiKeys).toList();
  return v;
}

String fieldLabel(JsonMap f) => (f['fieldName'] ??
        f['fieldLabel'] ??
        f['fieldDisplayName'] ??
        f['label'] ??
        'Field')
    .toString();

/// Header fields that hold a time of day (picked with the time picker).
bool isTimeField(JsonMap f) {
  final name = normText(fieldLabel(f));
  return normText(f['fieldType']) == 'time' ||
      name == 'departure time' ||
      name == 'arrival time';
}

const _timeValueFormat = 'HH:mm';

String formatTimeValue(DateTime time) =>
    DateFormat(_timeValueFormat).format(time);

/// Accepts "HH:mm", "HH:mm:ss" or "hh:mm a"; null when empty/unparseable.
DateTime? parseTimeValue(String value) {
  final s = value.trim();
  if (s.isEmpty) return null;
  for (final pattern in const [_timeValueFormat, 'HH:mm:ss', 'hh:mm a']) {
    try {
      final t = DateFormat(pattern).parseStrict(s);
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, t.hour, t.minute);
    } catch (_) {}
  }
  return null;
}
