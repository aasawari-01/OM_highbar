import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../service/auth_manager.dart';
import '../model/api_helpers.dart';
import '../model/buffer_stop.dart';
import '../model/checklist_rules.dart';
import '../service/inspection_service.dart';

/// State and rules of the Buffer Stop screen (web: BufferStop.jsx).
class BufferStopController extends GetxController {
  /// Business area that records the three-column checklist; the others use four columns.
  static const standardBusinessArea = 2200;
  static const maxCellLength = 250;
  static const maxRemarkLength = 200;

  final String inspectionRef; // jeInspectionId
  BufferStopController(this.inspectionRef);

  final _service = InspectionService();

  final loading = true.obs;
  final saving = false.obs;
  final dirty = false.obs;
  final error = RxnString();

  /// True once the inspection is Complete/Closed: nothing can be edited.
  final readOnly = false.obs;

  final inspectionNo = ''.obs;
  final inspectionDate = ''.obs;
  final inspectionName = ''.obs;
  final personName = ''.obs;
  final headerFields = <JsonMap>[].obs;
  final lineTypes = <SelectOption>[].obs;
  final chainages = <SelectOption>[].obs;

  final selectedMonth = RxnString();
  final selectedKmph = RxnString();
  final time = Rxn<DateTime>();
  final selectedLineType = RxnString();
  final selectedChainage = RxnString();
  final remark = TextEditingController();

  /// Checklist cells (span = month, km = kmph, srNo, column1..column4).
  final List<JsonMap> _cells = [];

  String _inspectionId = '';
  String _personId = '';
  int? _businessArea;

  bool get editable => !readOnly.value;

  bool get _standardArea => _businessArea == standardBusinessArea;

  /// Checklist table for the chosen Month / KMPH, or null when there is none for this user.
  BufferChecklist? get checklist {
    if (selectedMonth.value == null || selectedKmph.value == null || _businessArea == null) {
      return null;
    }
    return bufferChecklistFor(selectedMonth.value, selectedKmph.value, standardArea: _standardArea);
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    remark.dispose();
    super.onClose();
  }

  void markDirty() => dirty.value = true;

  void selectMonth(String? v) {
    selectedMonth.value = v;
    markDirty();
  }

  void selectKmph(String? v) {
    selectedKmph.value = v;
    markDirty();
  }

  void selectLineType(String? v) {
    selectedLineType.value = v;
    markDirty();
  }

  void selectChainage(String? v) {
    selectedChainage.value = v;
    markDirty();
  }

  void setTime(DateTime? v) {
    time.value = v;
    markDirty();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final data = await _service.getBufferStopDetails(inspectionRef);

      // Header fields and status come from the common inspection API.
      final out = await _service.getCommonInspection(inspectionRef);
      final basic = (out['_basicDetails'] as Map?) ?? const {};
      final chk = (out['_chk'] as Map?) ?? const {};
      final fields = ((chk['fieldListData'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _businessArea = await AuthManager().getBusinessArea();

      inspectionNo.value =
          data.inspectionNo.isNotEmpty ? data.inspectionNo : (basic['inspectionNo'] ?? '').toString();
      inspectionDate.value =
          data.date.isNotEmpty ? data.date : (basic['inspectionScheduledDate'] ?? '').toString();
      inspectionName.value = (basic['inspectionName'] ?? '').toString();
      personName.value = data.personName;
      _personId = data.personId;
      _inspectionId = data.inspectionId;
      lineTypes.assignAll(data.lineTypes);
      chainages.assignAll(data.chainages);
      headerFields.assignAll(fields);
      _cells
        ..clear()
        ..addAll(data.checklist);

      final saved = data.saved;
      if (saved != null) {
        selectedMonth.value = saved.month;
        selectedKmph.value = saved.kmph;
        time.value = parseTimeValue(saved.time);
        selectedLineType.value =
            _resolveSaved(lineTypes, saved.lineTypeId, saved.lineTypeName);
        selectedChainage.value =
            _resolveSaved(chainages, saved.chainageId, saved.chainageName);
        remark.text = saved.remark;
      }

      final st = (basic['status'] ?? '').toString();
      readOnly.value = st == 'Complete' || st == 'Closed';
    } catch (e) {
      debugPrint('Error loading buffer stop: $e');
      error.value = 'Unable to load buffer stop details';
    } finally {
      loading.value = false;
    }
  }

  /// Finds the option of a saved line type / chainage: by id, then by label
  /// (ignoring case and spacing). When the options lack it, the saved name is
  /// added as an option so the saved value is still shown.
  String? _resolveSaved(RxList<SelectOption> options, String id, String name) {
    String norm(String s) => s.trim().toLowerCase();
    if (id.isNotEmpty) {
      for (final o in options) {
        if (o.value == id) return o.value;
      }
    }
    if (name.trim().isNotEmpty) {
      for (final o in options) {
        if (norm(o.label) == norm(name)) return o.value;
      }
      final value = id.isNotEmpty ? id : name;
      options.add(SelectOption(value, name));
      return value;
    }
    return null;
  }

  JsonMap? _cell(String srNo) {
    for (final c in _cells) {
      if ('${c['span']}' == selectedMonth.value &&
          '${c['km']}' == selectedKmph.value &&
          '${c['srNo']}' == srNo) {
        return c;
      }
    }
    return null;
  }

  /// Entered text of a checklist cell.
  String cellValue(String srNo, String column) => (_cell(srNo)?[column] ?? '').toString();

  void setCell(String srNo, String column, String value) {
    final cell = _cell(srNo);
    if (cell != null) {
      cell[column] = value;
    } else {
      _cells.add({
        'span': selectedMonth.value,
        'km': selectedKmph.value,
        'srNo': srNo,
        'businessArea': _businessArea,
        column: value,
      });
    }
    markDirty();
  }

  /// Message for the first missing required field, or null when complete.
  String? validate() {
    if (selectedMonth.value == null) return 'Please Select Month';
    if (selectedKmph.value == null) return 'Please Select KMPH';
    if (time.value == null) return 'Please Select Time';
    if (selectedLineType.value == null) return 'Please Select Line (Up / Down)';
    if (selectedChainage.value == null) return 'Please Select Chainage';
    if (checklist == null) {
      return 'The checklist for this Month and KMPH is not available for your business area yet.';
    }
    return null;
  }

  JsonMap _header() => {
        'InspectionId': wireId(_inspectionId),
        'Date': inspectionDate.value,
        'KMPH': wireId(selectedKmph.value!),
        'Month': selectedMonth.value,
        'Time': formatTimeValue(time.value!),
        // A saved name (no id from the server) is left out, as the web does.
        if (int.tryParse(selectedLineType.value!) != null) 'LineUpDown': wireId(selectedLineType.value!),
        if (int.tryParse(selectedChainage.value!) != null) 'Chainage': wireId(selectedChainage.value!),
        'PersonResponsibleId': wireId(_personId),
        'Remark': remark.text.trim(),
      };

  /// Submits the buffer stop with its checklist. Returns true when the server accepted it.
  Future<bool> save() async {
    saving.value = true;
    try {
      final ok = await _service.insertBufferStop(
        header: _header(),
        checklist: _cells,
        legacy: bufferLegacyPlaceholder(selectedMonth.value!, selectedKmph.value!),
      );
      if (ok) dirty.value = false;
      return ok;
    } catch (e) {
      debugPrint('Error saving buffer stop: $e');
      rethrow;
    } finally {
      saving.value = false;
    }
  }

  /// Label of a header field's chosen select option, else the raw value.
  String headerValue(JsonMap f) {
    final v = (f['fieldSelectedValue'] ?? '').toString();
    for (final o in ((f['selectListItems'] as List?) ?? const []).whereType<Map>()) {
      if ((o['value'] ?? '').toString() == v) return (o['label'] ?? v).toString();
    }
    return v;
  }
}
