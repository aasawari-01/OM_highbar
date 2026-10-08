import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../service/auth_manager.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../../../utils/widgets/sync_icon_button.dart';

typedef _Json = Map<String, dynamic>;

const int _remarkMaxLength = 100;

// ───────────────────────── helpers (port of the web checklist rules) ─────────

String _norm(dynamic v) => (v ?? '').toString().trim().toLowerCase();
String _normControl(dynamic v) =>
    _norm(v).replaceAll(RegExp(r'[\s/_-]+'), '');

bool _isRemarkCol(dynamic name) => RegExp(r'^remarks?$', caseSensitive: false).hasMatch((name ?? '').toString().trim());
bool _isObservationCol(dynamic name) {
  final n = _norm(name).replaceAll(RegExp(r'\s+'), ' ');
  return n == 'observation' ||
      n == 'is observation required' ||
      n == 'add to observation' ||
      n == 'addtoobservation';
}

bool _isActionCol(dynamic name) {
  final n = _norm(name);
  return n == 'action' || n == 'visit at site';
}

bool _isPositive(dynamic n) => ['yes', 'okay', 'ok'].contains(_normControl(n));
bool _isNegative(dynamic n) => ['no', 'notokay', 'notok'].contains(_normControl(n));
bool _isNa(dynamic n) => _normControl(n) == 'na';
bool _isNotOkayName(dynamic n) => ['notokay', 'notok'].contains(_normControl(n));

bool _isRadio(_Json c) => _norm(c['itemType']) == 'radio';
bool _isCheckbox(_Json c) => ['checkbox', 'checkboxes'].contains(_norm(c['itemType']));
bool _isSelect(_Json c) => ['select', 'dropdown', 'combobox'].contains(_norm(c['itemType']));
bool _isTextType(_Json c) => ['text', 'textarea', 'textbox'].contains(_norm(c['itemType']));

bool _isDisabled(_Json c) {
  final d = c['itemDisabled'];
  return d == 1 || d == true || d == '1' || _norm(d) == 'true';
}

bool _isMandatory(_Json f) {
  final m = f['isMandatory'];
  return m == 1 || m == '1' || m == true || m == 'true';
}

List<_Json> _controls(_Json col) =>
    ((col['controlType'] as List?) ?? const []).whereType<Map>().map((e) => e as _Json).toList();

_Json? _remarkTextControl(_Json col) {
  final controls = _controls(col);
  for (final c in controls) {
    if (_isTextType(c)) return c;
  }
  return null;
}

/// Remark columns always need a Text control to bind to.
void _ensureRemarkControl(_Json col) {
  if (_remarkTextControl(col) != null) return;
  final list = (col['controlType'] as List?) ?? [];
  list.add(<String, dynamic>{
    'itemListId': 'remark-${col['columnId']}',
    'itemType': 'Text',
    'itemName': 'Remark',
    'itemSelectedValue': '',
  });
  col['controlType'] = list;
}

class _TogglePair {
  _Json? positive;
  _Json? negative;
  _Json? na;
  bool isOkayKind = false;
  List<_Json> others = [];
}

_TogglePair _resolvePair(List<_Json> radios) {
  final p = _TogglePair();
  p.na = radios.where((c) => _isNa(c['itemName'])).cast<_Json?>().firstWhere((_) => true, orElse: () => null);
  final nonNa = radios.where((c) => !_isNa(c['itemName'])).toList();
  _Json? byNorm(String n) {
    for (final c in nonNa) {
      if (_normControl(c['itemName']) == n) return c;
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

String _actionLabel(dynamic name) {
  switch (_normControl(name)) {
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

bool _isSelected(_Json c) => c['itemName'] == c['itemSelectedValue'];

List<_Json> _columns(_Json row) =>
    ((row['columnsType'] as List?) ?? const []).whereType<Map>().map((e) => e as _Json).toList();

bool _rowNotOkay(_Json row) {
  for (final col in _columns(row)) {
    if (!_isActionCol(col['columnName'])) continue;
    final pair = _resolvePair(_controls(col).where(_isRadio).toList());
    if (pair.isOkayKind && pair.negative != null) return _isSelected(pair.negative!);
  }
  return false;
}

bool _rowHasObservationYes(_Json row) {
  if (row['addToObservation'] == true || row['isObservation'] == true) return true;
  for (final col in _columns(row)) {
    if (!_isObservationCol(col['columnName'])) continue;
    return _controls(col).any((c) => _isRadio(c) && _isSelected(c) && _isPositive(c['itemName']));
  }
  return false;
}

String _rowRemark(_Json row) {
  final obs = (row['observationRemark'] ?? '').toString();
  if (obs.isNotEmpty) return obs;
  for (final col in _columns(row)) {
    if (_isRemarkCol(col['columnName'])) {
      return (_remarkTextControl(col)?['itemSelectedValue'] ?? '').toString();
    }
  }
  return '';
}

void _setRemark(_Json row, String text) {
  for (final col in _columns(row)) {
    if (!_isRemarkCol(col['columnName'])) continue;
    _ensureRemarkControl(col);
    _remarkTextControl(col)!['itemSelectedValue'] = text;
  }
  row['_rev'] = ((row['_rev'] as int?) ?? 0) + 1;
}

void _setObservation(_Json row, bool? value) {
  if (value != null) {
    for (final col in _columns(row)) {
      if (!_isObservationCol(col['columnName'])) continue;
      final controls = _controls(col);
      final radios = controls.where(_isRadio).toList();
      if (radios.isNotEmpty) {
        final yes = radios.firstWhere((c) => _isPositive(c['itemName']), orElse: () => radios.last);
        final no = radios.firstWhere((c) => _isNegative(c['itemName']), orElse: () => radios.first);
        final sel = value ? yes : no;
        for (final c in radios) {
          c['itemSelectedValue'] = identical(c, sel) ? c['itemName'] : '';
        }
      } else if (controls.isNotEmpty) {
        for (var i = 0; i < controls.length; i++) {
          controls[i]['itemSelectedValue'] = i == 0 ? (value ? 'Yes' : 'No') : '';
        }
      }
    }
    row['isObservation'] = value;
    row['addToObservation'] = value;
  }
}

String _selectedDisplay(_Json col) {
  final out = <String>[];
  for (final c in _controls(col)) {
    final sel = c['itemSelectedValue'];
    if (sel == null || sel == '') continue;
    if (_isRadio(c)) {
      if (sel.toString() == (c['itemName'] ?? '').toString()) out.add(_actionLabel(c['itemName']));
    } else if (_isCheckbox(c)) {
      if (sel == true || sel == '1' || sel == 'true' || sel.toString() == (c['itemName'] ?? '').toString()) {
        out.add((c['itemName'] ?? 'Yes').toString());
      }
    } else {
      out.add(sel.toString());
    }
  }
  return out.isEmpty ? '-' : out.join(', ');
}

/// Columns ordered as the API header list, then any leftovers.
List<_Json> _orderedColumns(_Json row, List<_Json> headers) {
  final cols = _columns(row);
  if (headers.isEmpty) return cols;
  final out = <_Json>[];
  for (final h in headers) {
    final id = (h['headerColumnId'] ?? '').toString();
    final name = _norm(h['headerColumnName']);
    for (final c in cols) {
      if ((c['columnId'] ?? '').toString() == id || _norm(c['columnName']) == name) {
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

void _normalizeRow(_Json row) {
  for (final col in _columns(row)) {
    col['controlType'] = (col['controlType'] is List) ? List.of(col['controlType']) : <dynamic>[];
    if (_isRemarkCol(col['columnName'])) _ensureRemarkControl(col);
  }
  if (!_rowNotOkay(row) || !_rowHasObservationYes(row)) {
    _setObservation(row, false);
    if (!_rowNotOkay(row)) row['observationRemark'] = '';
  }
}

// ──────────────────────────────── screen ────────────────────────────────────

class CommonInspectionChecklistScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list. Null shows sample data.
  final String? inspectionId;
  final bool isView;

  const CommonInspectionChecklistScreen({super.key, this.inspectionId, this.isView = false});

  @override
  State<CommonInspectionChecklistScreen> createState() => _CommonInspectionChecklistScreenState();
}

class _CommonInspectionChecklistScreenState extends State<CommonInspectionChecklistScreen> {
  static const int _maxAttachmentBytes = 1024 * 1024;

  final _apiClient = ApiClient();
  bool _loading = true;
  String? _error;
  bool _isViewMode = false;
  bool _dirty = false;

  bool _saving = false;
  String _inspectionId = "";
  String _inspectionName = "";
  List<dynamic> _existingAttachments = [];

  _Json _basic = {};
  List<_Json> _fields = [];
  List<_Json> _headers = [];
  List<_Json> _rows = [];
  int _index = 0;

  final _overallRemarksController = TextEditingController();
  File? _attachment;

  @override
  void initState() {
    super.initState();
    _isViewMode = widget.isView;
    _load();
  }

  @override
  void dispose() {
    _overallRemarksController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ data

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = widget.inspectionId;
      _Json output;
      if (id == null || id.isEmpty) {
        output = _sampleData();
      } else {
        final token = await AuthManager().getToken();
        final res = await _apiClient.post(
          AppUrls.getCommonInspection,
          headers: {
            'accept': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: {'Id': id},
        );
        if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
        final body = jsonDecode(res.body) as _Json;
        output = Map<String, dynamic>.from(body['responseOutput'] as Map);
      }
      final basic = Map<String, dynamic>.from((output['_basicDetails'] ?? {}) as Map);
      final chk = Map<String, dynamic>.from((output['_chk'] ?? {}) as Map);

      final fields = ((chk['fieldListData'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final deptId = (basic['deptId'] ?? '').toString();
      for (final f in fields) {
        final fid = (f['fieldID'] ?? '').toString();
        if (deptId == '1' && (fid == '3' || fid == '4')) f['isMandatory'] = 1;
      }
      final rows = ((chk['tableBodyItems'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      for (final r in rows) {
        _normalizeRow(r);
      }
      final status = (basic['status'] ?? '').toString();
      _overallRemarksController.text = (basic['additionalInfo'] ??
              chk['overallInspectionRemark'] ??
              basic['overallInspectionRemark'] ??
              basic['remark'] ??
              '')
          .toString();
      if (!mounted) return;
      setState(() {
        _basic = basic;
        _inspectionId = (chk["inspectionId"] ?? chk["InspectionId"] ?? basic["inspectionId"] ?? basic["InspectionId"] ?? 0).toString();
        _inspectionName = (chk["inspectionName"] ?? basic["inspectionName"] ?? "").toString();
        _existingAttachments = List.of((chk["attachmentList"] ?? chk["AttachmentList"] ?? chk["existingAttachments"] ?? const []) as List);
        _fields = fields;
        _headers = ((chk['tableHeaderList'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _rows = rows;
        _index = 0;
        if (status == 'Complete' || status == 'Closed') _isViewMode = true;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading common inspection: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load checklist';
      });
    }
  }

  // TODO: remove once the API is reachable from every environment.
  _Json _sampleData() {
    _Json col(int id, String name, List<_Json> controls) =>
        {'columnId': id, 'columnName': name, 'controlType': controls};
    _Json radio(int id, String name) =>
        {'itemListId': id, 'itemType': 'Radio', 'itemName': name, 'itemSelectedValue': ''};
    return {
      '_basicDetails': {
        'inspectionNo': 'U/01-2026-01',
        'deptName': 'Signalling',
        'personResponsible': 'Dharmesh Solanki',
        'inspectionScheduledDate': '06/01/2026',
        'status': 'Assigned',
      },
      '_chk': {
        'fieldListData': [],
        'tableHeaderList': [],
        'tableBodyItems': List.generate(
          5,
          (i) => {
            'subSystemId': i + 1,
            'systemName': 'Dev System ${i + 1}',
            'subSystemName': 'Dev Sub System ${i + 1}-1',
            'columnsType': [
              col(1, 'Action', [radio(11, 'Okay'), radio(12, 'Not Okay'), radio(13, 'NA')]),
              col(2, 'Add To Observation', [radio(21, 'Yes'), radio(22, 'No')]),
              col(3, 'Remarks', []),
            ],
          },
        ),
      },
    };
  }

  // ------------------------------------------------------------- mutations

  void _touch(VoidCallback fn) => setState(() {
        fn();
        _dirty = true;
      });

  void _setControlValue(_Json row, _Json col, _Json ctrl, dynamic value) {
    final isRadio = _isRadio(ctrl);
    final isAction = isRadio && _isActionCol(col['columnName']);
    for (final c in _controls(col)) {
      if (identical(c, ctrl)) {
        c['itemSelectedValue'] = value;
      } else if (isRadio && _isRadio(c)) {
        c['itemSelectedValue'] = '';
      }
    }
    if (isAction) {
      // Changing the action clears the remark.
      _setRemark(row, '');
      row['observationRemark'] = '';
      if (_isPositive(value)) {
        _setObservation(row, false);
      } else if (_isNegative(value) && !_rowHasObservationYes(row)) {
        _setObservation(row, false);
      }
    }
  }

  Future<void> _onRadioTap(_Json row, _Json col, _Json ctrl) async {
    if (_isViewMode || _isDisabled(ctrl)) return;
    final isObsCol = _isObservationCol(col['columnName']);
    if (isObsCol && !_rowNotOkay(row)) return; // locked unless Not Okay

    final name = ctrl['itemName'];
    final selectingObsYes = isObsCol && (_isPositive(name) || ['true', '1'].contains(_normControl(name)));
    final selectingObsNo = isObsCol && (_isNegative(name) || ['false', '0'].contains(_normControl(name)));

    // Not Okay -> Okay removes an added observation: confirm first.
    final pair = _resolvePair(_controls(col).where(_isRadio).toList());
    final switchingToOkay = !isObsCol &&
        pair.isOkayKind &&
        _isPositive(name) &&
        pair.negative != null &&
        _isSelected(pair.negative!);
    if (switchingToOkay && (_rowHasObservationYes(row) || _rowRemark(row).trim().isNotEmpty)) {
      final ok = await _confirm(
        'Switch to Okay?',
        'If you mark this as Okay, the added observation will be removed. Do you want to continue?',
      );
      if (ok != true) return;
      _touch(() {
        _setControlValue(row, col, ctrl, name);
        row['observationRemark'] = '';
      });
      return;
    }

    // Observation Yes -> No: confirm removal.
    if (selectingObsNo && _rowHasObservationYes(row)) {
      final ok = await _confirm(
        'Remove observation?',
        'Do you want to remove this point from observation? It will not be logged for follow-up and reporting.',
        confirmLabel: 'Yes, Remove',
        cancelLabel: 'Cancel',
      );
      if (ok != true) return;
      _touch(() {
        _setObservation(row, false);
        _setRemark(row, '');
        row['observationRemark'] = '';
      });
      return;
    }

    _touch(() => _setControlValue(row, col, ctrl, name));

    if (selectingObsYes || _isNotOkayName(name)) {
      await _showNotOkayPopup(row, col, _actionLabel(name));
    }
  }

  // ---------------------------------------------------------------- popup

  Future<void> _showNotOkayPopup(_Json row, _Json triggerCol, String actionLabel) async {
    final details = <MapEntry<String, String>>[
      MapEntry('System', (row['systemName'] ?? '-').toString()),
      MapEntry('Sub System', (row['subSystemName'] ?? '-').toString()),
    ];
    final seen = <String>{};
    for (final c in _orderedColumns(row, _headers)) {
      final label = (c['columnName'] ?? '').toString().trim();
      if (label.isEmpty || _isRemarkCol(label) || _isObservationCol(label)) continue;
      if (!seen.add(label.toLowerCase())) continue;
      final isTrigger = identical(c, triggerCol);
      details.add(MapEntry(label, isTrigger ? actionLabel : _selectedDisplay(c)));
    }

    final remarkInitial = _rowRemark(row);
    var remark = remarkInitial;
    var showError = false;

    // true = add observation, false = skip / dismissed (observation No).
    final bool? add = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.white1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: CustText(
                      name: 'Not Okay-Review Item',
                      size: AppConstants.headerSize,
                      color: AppColors.black,
                      fontWeightName: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: const Icon(TablerIcons.x, color: AppColors.textDarkPrimary, size: 24),
                  ),
                ]),
                const SizedBox(height: AppConstants.elementSpacing),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.containerColor2,
                    borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final d in details) _popupRow(d.key, d.value),
                      const SizedBox(height: AppConstants.subElementSpacing),
                      CustText.formLabel('Remark *'),
                      const SizedBox(height: AppConstants.labelSpacing),
                      TextFormField(
                        initialValue: remark,
                        maxLines: 4,
                        maxLength: _remarkMaxLength,
                        keyboardType: TextInputType.multiline,
                        onChanged: (v) {
                          remark = v;
                          if (showError) setD(() => showError = false);
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter remark',
                          filled: true,
                          fillColor: AppColors.white1,
                          errorText: showError ? 'Remark is required' : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                            borderSide: BorderSide(color: AppColors.textFieldColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustText(
                        name: 'Do you want to add this item to Observations?',
                        size: AppConstants.formLabelSize,
                        fontWeightName: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      const SizedBox(height: 4),
                      CustText(
                        name: 'This will log it as an observation record for follow up and reporting.',
                        size: AppConstants.detailLabelSize,
                        color: AppColors.textDarkSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                Row(children: [
                  Expanded(
                    child: CustOutlineButton(
                      name: 'No, Skip',
                      size: double.infinity,
                      sHeight: 38,
                      onSelected: (_) => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustButton(
                      name: 'Yes, Add to Observation',
                      size: double.infinity,
                      sHeight: 38,
                      fontSize: 14,
                      onSelected: (_) {
                        if (remark.trim().isEmpty) {
                          setD(() => showError = true);
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (add == true) {
      _touch(() {
        final text = remark.trim();
        _setObservation(row, true);
        row['observationRemark'] = text;
        _setRemark(row, text);
      });
      _snack('Observation added successfully.');
    } else {
      // Dismiss / No, Skip -> observation No, remark cleared.
      _touch(() {
        _setObservation(row, false);
        row['observationRemark'] = '';
        _setRemark(row, '');
      });
    }
  }

  Future<bool?> _confirm(String title, String message,
      {String confirmLabel = 'Yes', String cancelLabel = 'No'}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white1,
        title: CustText(name: title, size: AppConstants.headerSize, fontWeightName: FontWeight.w600),
        content: CustText(name: message, size: AppConstants.formLabelSize),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelLabel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirmLabel)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- actions

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg'],
      );
      final path = result?.files.single.path;
      if (path == null) return;
      final file = File(path);
      if (file.lengthSync() > _maxAttachmentBytes) {
        _snack('File size must be 1MB or less');
        return;
      }
      setState(() {
        _attachment = file;
        _dirty = true;
      });
    } catch (e) {
      debugPrint('Error picking attachment: $e');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _showErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.white1,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.sectionSpacing),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.containerColor2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.cancel_outlined, color: AppColors.red, size: 36),
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              CustText(
                name: message,
                textAlign: TextAlign.center,
                size: AppConstants.headerSize,
                color: AppColors.black,
                fontWeightName: FontWeight.w600,
              ),
              const SizedBox(height: AppConstants.sectionSpacing),
              CustButton(
                name: 'OK',
                size: 160,
                sHeight: 44,
                onSelected: (_) => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validate() {
    for (final f in _fields) {
      if (!_isMandatory(f)) continue;
      final v = (f['fieldSelectedValue'] ?? '').toString().trim();
      if (v.isEmpty || v.toLowerCase() == 'select') {
        _snack('${_fieldLabel(f)} is required');
        return false;
      }
    }
    // Action No / NA / NotOk needs a remark (same rule as the web).
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final needsRemark = _columns(row).any((col) =>
          _isActionCol(col['columnName']) &&
          _controls(col).any((c) =>
              _isRadio(c) && _isSelected(c) && (_isNegative(c['itemName']) || _isNa(c['itemName']))));
      if (needsRemark && _rowRemark(row).trim().isEmpty) {
        setState(() => _index = i);
        _showErrorDialog('If Action Is No/Na/NotOk Please Enter Remark');
        return false;
      }
    }
    return true;
  }

  /// Strips UI-only keys (prefixed `_`) before sending rows to the API.
  dynamic _clean(dynamic v) {
    if (v is Map) {
      return {
        for (final e in v.entries)
          if (!e.key.toString().startsWith('_')) e.key: _clean(e.value),
      };
    }
    if (v is List) return v.map(_clean).toList();
    return v;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthManager().getToken();
    return {
      'accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<int> _userId() async => int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;

  bool _isSuccess(String body) {
    try {
      final j = jsonDecode(body) as Map<String, dynamic>;
      return j['responseMessage'] == 'Success' || j['responseCode'] == 200 || j['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// API 1: Inspection/SaveCommonInspectionCheckListData (multipart).
  Future<bool> _saveChecklist({required bool isDraft}) async {
    final res = await _apiClient.postMultipart(
      AppUrls.saveCommonInspectionCheckListData,
      headers: await _authHeaders(),
      fields: {
        'Id': widget.inspectionId ?? '',
        'CreatedBy': (await _userId()).toString(),
        'InspectionId': _inspectionId,
        'InspectionName': _inspectionName,
        'FieldListData': jsonEncode(_clean(_fields)),
        'TableHeaderList': jsonEncode(_clean(_headers)),
        'TableBodyItems': jsonEncode(_clean(_rows)),
        'OverallInspectionRemark': _overallRemarksController.text,
        'ExistingAttachments': jsonEncode(_existingAttachments),
        if (_attachment == null) 'AttachmentList': '[]',
        'IsDraft': isDraft.toString(),
      },
      files: [
        if (_attachment != null)
          await http.MultipartFile.fromPath('AttachmentList', _attachment!.path),
      ],
    );
    return res.statusCode == 200 && _isSuccess(res.body);
  }

  /// API 2: Inspection/UpdateIsSavedCommonInspection (final submit only).
  Future<bool> _markSubmitted() async {
    final res = await _apiClient.post(
      AppUrls.updateIsSavedCommonInspection,
      headers: await _authHeaders(),
      body: {'JEInspectionId': widget.inspectionId, 'CreatedBy': await _userId()},
    );
    return res.statusCode == 200 && _isSuccess(res.body);
  }

  Future<void> _submit({required bool isDraft}) async {
    if (_saving) return;
    if (widget.inspectionId == null || widget.inspectionId!.isEmpty) {
      _snack('Sample data cannot be saved');
      return;
    }
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      var ok = await _saveChecklist(isDraft: isDraft);
      // Final submit: only call the second API once the first one succeeded.
      if (ok && !isDraft) ok = await _markSubmitted();
      if (!mounted) return;
      if (ok) {
        _dirty = false;
        _snack(isDraft ? 'Saved as draft' : 'Inspection submitted successfully');
        Navigator.pop(context, true);
      } else {
        _snack('Error in saving data');
      }
    } catch (e) {
      debugPrint('Error saving checklist: $e');
      if (mounted) _snack('Error in request');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _saveAsDraft() => _submit(isDraft: true);

  void _finalSubmit() => _submit(isDraft: false);

  Future<void> _onBack() async {
    if (_dirty && !_isViewMode) {
      final leave = await _confirm(
        'Unsaved changes',
        'Changes you made may not be saved. Leave this page?',
        confirmLabel: 'Leave',
        cancelLabel: 'Stay',
      );
      if (leave != true) return;
    }
    if (mounted) Navigator.pop(context);
  }

  String _fieldLabel(_Json f) =>
      (f['fieldName'] ?? f['fieldLabel'] ?? f['fieldDisplayName'] ?? f['label'] ?? 'Field').toString();

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !(_dirty && !_isViewMode),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.appBarColor,
        appBar: CustomAppBar(
          title: 'Common Inspection Checklist',
          showDrawer: false,
          onLeadingPressed: _onBack,
          actions: const [SyncIconButton(), SizedBox(width: 16)],
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.white1,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.orangeColor))
              : _error != null
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ]),
                    )
                  : _body(),
        ),
      ),
    );
  }

  Widget _body() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText.formLabel('Inspection Date : ${_basic['inspectionScheduledDate'] ?? ''}'),
          const SizedBox(height: AppConstants.labelSpacing),
          CustText(
            name: 'Inspection No : ${_basic['inspectionNo'] ?? ''}',
            size: AppConstants.formLabelSize,
            color: AppColors.orangeColor,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          _readOnly('Department', (_basic['deptName'] ?? '').toString()),
          const SizedBox(height: AppConstants.elementSpacing),
          _readOnly('Inspection By', (_basic['personResponsible'] ?? '').toString()),
          for (final f in _fields) ...[
            const SizedBox(height: AppConstants.elementSpacing),
            _dynamicField(f),
          ],
          const SizedBox(height: AppConstants.elementSpacing),
          if (_rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No checklist items')),
            )
          else
            _itemCard(),
          const SizedBox(height: AppConstants.elementSpacing),
          CustomTextField(
            label: 'Overall Remarks',
            hintText: 'Enter Remarks',
            controller: _overallRemarksController,
            readOnly: _isViewMode,
            onChanged: (_) => _dirty = true,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          _attachmentSection(),
          if (!_isViewMode) ...[
            const SizedBox(height: AppConstants.sectionSpacing),
            Row(children: [
              Expanded(
                child: CustButton(
                  name: 'Save as a Draft',
                  size: double.infinity,
                  sHeight: AppConstants.buttonHeight,
                  fontSize: 16,
                  onSelected: (_) => _saveAsDraft(),
                ),
              ),
              const SizedBox(width: AppConstants.elementSpacing),
              Expanded(
                child: CustButton(
                  name: 'Final Submit',
                  size: double.infinity,
                  sHeight: AppConstants.buttonHeight,
                  fontSize: 16,
                  onSelected: (_) => _finalSubmit(),
                ),
              ),
            ]),
          ],
          const SizedBox(height: AppConstants.elementSpacing),
          CustOutlineButton(
            name: _isViewMode ? 'Back' : 'Cancel',
            size: double.infinity,
            sHeight: AppConstants.buttonHeight,
            onSelected: (_) => _onBack(),
          ),
        ],
      ),
    );
  }

  Widget _readOnly(String label, String value) => CustomTextField(
        key: ValueKey('ro-$label-$value'),
        label: label,
        controller: TextEditingController(text: value),
        readOnly: true,
        fillColor: AppColors.containerColor2,
      );

  Widget _dynamicField(_Json f) {
    final label = _fieldLabel(f) + (_isMandatory(f) ? ' *' : '');
    final type = _norm(f['fieldType']);
    final enabled = !_isViewMode;
    if (type == 'select') {
      final options = ((f['selectListItems'] as List?) ?? const [])
          .whereType<Map>()
          .map((o) => MapEntry((o['value'] ?? '').toString(), (o['label'] ?? o['value'] ?? '').toString()))
          .toList();
      final current = (f['fieldSelectedValue'] ?? '').toString();
      final selected = options.where((o) => o.key == current).map((o) => o.value).cast<String?>().firstWhere((_) => true, orElse: () => null);
      return CustDropdown(
        label: label,
        hint: 'Select',
        enabled: enabled,
        items: options.map((o) => o.value).toList(),
        selectedValue: selected,
        onChanged: (v) {
          final match = options.where((o) => o.value == v);
          _touch(() => f['fieldSelectedValue'] = match.isEmpty ? '' : match.first.key);
        },
      );
    }
    return CustomTextField(
      key: ValueKey('field-${f['fieldID']}'),
      label: label,
      controller: TextEditingController(text: (f['fieldSelectedValue'] ?? '').toString()),
      readOnly: !enabled,
      onChanged: (v) {
        f['fieldSelectedValue'] = v;
        _dirty = true;
      },
    );
  }

  // ------------------------------------------------------------- item card

  Widget _itemCard() {
    final row = _rows[_index];
    final failure = (row['notificationCode'] ?? row['NotificationCode'] ?? '').toString().trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.white1,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.textFieldColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText(
            name: 'Item ${_index + 1} to ${_rows.length}',
            size: AppConstants.detailLabelSize,
            color: AppColors.textDarkSecondary,
          ),
          const SizedBox(height: AppConstants.subElementSpacing),
          CustText.detailLabel('System'),
          CustText(name: (row['systemName'] ?? '-').toString(), size: 16, fontWeightName: FontWeight.bold),
          const SizedBox(height: AppConstants.subElementSpacing),
          CustText.detailLabel('Sub system:'),
          CustText(name: (row['subSystemName'] ?? '-').toString(), size: 16, fontWeightName: FontWeight.bold),
          if (failure.isNotEmpty && failure != '0') ...[
            const SizedBox(height: AppConstants.subElementSpacing),
            CustText.detailLabel('Failure No:'),
            CustText(name: failure, size: 16, color: AppColors.orangeColor, fontWeightName: FontWeight.bold),
          ],
          for (final col in _orderedColumns(row, _headers)) ...[
            const SizedBox(height: AppConstants.elementSpacing),
            _columnWidget(row, col),
          ],
          const SizedBox(height: AppConstants.elementSpacing),
          _pagination(),
        ],
      ),
    );
  }

  Widget _columnWidget(_Json row, _Json col) {
    final name = (col['columnName'] ?? '').toString();
    final label = _isRemarkCol(name) ? 'Remarks' : name;
    final isObs = _isObservationCol(name);
    final locked = _isViewMode || (isObs && !_rowNotOkay(row));

    Widget body;
    if (_isRemarkCol(name)) {
      final ctrl = _remarkTextControl(col)!;
      body = TextFormField(
        key: ValueKey('rm-${row['subSystemId']}-${col['columnId']}-${row['_rev'] ?? 0}'),
        initialValue: (ctrl['itemSelectedValue'] ?? '').toString(),
        enabled: !_isViewMode && !_isDisabled(ctrl),
        maxLines: 3,
        minLines: 1,
        maxLength: _remarkMaxLength,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          hintText: 'Enter Remarks',
          filled: true,
          fillColor: AppColors.white1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.inputRadius),
            borderSide: BorderSide(color: AppColors.textFieldColor),
          ),
        ),
        onChanged: (v) {
          ctrl['itemSelectedValue'] = v;
          _dirty = true;
        },
      );
    } else {
      final controls = _controls(col);
      if (controls.isEmpty) return const SizedBox.shrink();
      final radios = controls.where(_isRadio).toList();
      final pair = _resolvePair(radios);
      final children = <Widget>[];

      if (pair.positive != null && pair.negative != null) {
        // Negative first, as in the design (Not Okay | Okay).
        children.add(_choice(pair.negative!, locked, () => _onRadioTap(row, col, pair.negative!)));
        children.add(_choice(pair.positive!, locked, () => _onRadioTap(row, col, pair.positive!)));
        if (pair.na != null) children.add(_naRadio(pair.na!, locked, () => _onRadioTap(row, col, pair.na!)));
        for (final c in pair.others) {
          children.add(_choice(c, locked, () => _onRadioTap(row, col, c)));
        }
      } else {
        for (final c in radios) {
          children.add(_choice(c, locked, () => _onRadioTap(row, col, c)));
        }
      }
      for (final c in controls.where(_isCheckbox)) {
        final on = c['itemSelectedValue'] == c['itemName'] ||
            c['itemSelectedValue'] == '1' ||
            c['itemSelectedValue'] == true;
        children.add(Row(mainAxisSize: MainAxisSize.min, children: [
          Checkbox(
            value: on,
            activeColor: AppColors.orangeColor,
            onChanged: (_isViewMode || _isDisabled(c))
                ? null
                : (v) => _touch(() => c['itemSelectedValue'] = (v ?? false) ? (c['itemName'] ?? '1') : ''),
          ),
          CustText(name: (c['itemName'] ?? '').toString(), size: AppConstants.detailLabelSize),
        ]));
      }
      for (final c in controls.where(_isSelect)) {
        final opts = ((c['selectListItems'] ?? c['itemOptions'] ?? c['options']) as List?) ?? const [];
        final values = opts
            .map((o) => o is Map ? (o['label'] ?? o['value'] ?? o['itemName'] ?? '').toString() : o.toString())
            .where((s) => s.isNotEmpty)
            .toList();
        final cur = (c['itemSelectedValue'] ?? '').toString();
        children.add(SizedBox(
          width: double.infinity,
          child: CustDropdown(
            label: (c['itemName'] ?? '').toString(),
            hint: 'Select',
            enabled: !locked && !_isDisabled(c),
            items: values,
            selectedValue: values.contains(cur) ? cur : null,
            onChanged: (v) => _touch(() => c['itemSelectedValue'] = v ?? ''),
          ),
        ));
      }
      for (final c in controls.where((c) => _isTextType(c))) {
        children.add(SizedBox(
          width: double.infinity,
          child: TextFormField(
            initialValue: (c['itemSelectedValue'] ?? '').toString(),
            enabled: !locked && !_isDisabled(c),
            onChanged: (v) {
              c['itemSelectedValue'] = v;
              _dirty = true;
            },
          ),
        ));
      }
      if (children.isEmpty) return const SizedBox.shrink();
      body = Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: children);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText.formLabel(label),
        const SizedBox(height: AppConstants.labelSpacing),
        body,
      ],
    );
  }

  Widget _choice(_Json ctrl, bool locked, VoidCallback onTap) {
    final selected = _isSelected(ctrl);
    final disabled = locked || _isDisabled(ctrl);
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 90,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.orangeColor : AppColors.white1,
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          border: Border.all(
            color: selected
                ? AppColors.orangeColor
                : (disabled ? AppColors.textFieldColor : AppColors.textDarkPrimary),
          ),
        ),
        child: CustText(
          name: _actionLabel(ctrl['itemName']),
          size: 14,
          color: selected
              ? AppColors.white1
              : (disabled ? AppColors.textDarkSecondary : AppColors.textDarkPrimary),
        ),
      ),
    );
  }

  Widget _naRadio(_Json ctrl, bool locked, VoidCallback onTap) {
    final disabled = locked || _isDisabled(ctrl);
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          _isSelected(ctrl) ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: disabled ? AppColors.textFieldColor : AppColors.orangeColor,
        ),
        const SizedBox(width: 4),
        CustText(name: 'NA', size: AppConstants.detailLabelSize),
      ]),
    );
  }

  Widget _pagination() {
    final canPrev = _index > 0;
    final canNext = _index < _rows.length - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          color: AppColors.orangeColor,
          disabledColor: AppColors.textFieldColor,
          onPressed: canPrev ? () => setState(() => _index--) : null,
        ),
        CustText(name: '${_index + 1}', size: 16, fontWeightName: FontWeight.bold),
        IconButton(
          icon: const Icon(TablerIcons.chevron_right),
          color: AppColors.orangeColor,
          disabledColor: AppColors.textFieldColor,
          onPressed: canNext ? () => setState(() => _index++) : null,
        ),
      ],
    );
  }

  Widget _attachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: 'Attachment (Only PNG, JPEG, JPG – max 1MB)',
          size: AppConstants.detailLabelSize,
          color: AppColors.textDarkSecondary,
        ),
        const SizedBox(height: AppConstants.labelSpacing),
        if (!_isViewMode)
          CustButton(
            name: 'Add File',
            size: 100,
            sHeight: 36,
            fontSize: 14,
            onSelected: (_) => _pickAttachment(),
          ),
        if (_attachment != null) ...[
          const SizedBox(height: AppConstants.labelSpacing),
          Row(children: [
            Expanded(
              child: CustText(
                name: _attachment!.path.split(Platform.pathSeparator).last,
                size: AppConstants.detailValueSize,
              ),
            ),
            if (!_isViewMode)
              GestureDetector(
                onTap: () => setState(() => _attachment = null),
                child: const Icon(TablerIcons.x, size: 18),
              ),
          ]),
        ],
      ],
    );
  }

  Widget _popupRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: CustText(name: label, size: AppConstants.detailLabelSize, color: AppColors.textDarkSecondary),
          ),
          Expanded(child: CustText(name: value, size: 14, fontWeightName: FontWeight.bold)),
        ],
      ),
    );
  }
}
