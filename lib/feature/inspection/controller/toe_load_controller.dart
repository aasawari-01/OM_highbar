import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/api_helpers.dart';
import '../model/checklist_rules.dart';
import '../model/toe_load.dart';
import '../service/inspection_service.dart';

/// State and rules of the Toe Load Testing screen (web: ToeLoadTesting.jsx).
class ToeLoadController extends GetxController {
  static const maxRemarkLength = 200;

  final String inspectionRef; // jeInspectionId
  ToeLoadController(this.inspectionRef);

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
  final headerFields = <JsonMap>[].obs;

  // The reading being entered / edited.
  final reach = TextEditingController();
  final pierNo = TextEditingController();
  final plinthNo = TextEditingController();
  final lhsNonGauge = TextEditingController();
  final lhsGauge = TextEditingController();
  final rhsNonGauge = TextEditingController();
  final rhsGauge = TextEditingController();
  final basePlate = TextEditingController();
  final remark = TextEditingController();
  final lhsTotal = ''.obs;
  final rhsTotal = ''.obs;

  final rows = <ToeRow>[].obs;
  final editIndex = RxnInt();

  String _inspectionId = '';

  bool get editable => !readOnly.value;

  List<TextEditingController> get _controllers => [
        reach,
        pierNo,
        plinthNo,
        lhsNonGauge,
        lhsGauge,
        rhsNonGauge,
        rhsGauge,
        basePlate,
        remark,
      ];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.onClose();
  }

  void markDirty() => dirty.value = true;

  /// Sum of two entered readings; empty entries count as 0.
  String _sum(String a, String b) {
    final total = (double.tryParse(a.trim()) ?? 0) + (double.tryParse(b.trim()) ?? 0);
    return total == total.roundToDouble() ? total.toInt().toString() : total.toString();
  }

  /// Recomputes both totals from the entry fields; call after a reading changed.
  void recalc() {
    lhsTotal.value = _sum(lhsNonGauge.text, lhsGauge.text);
    rhsTotal.value = _sum(rhsNonGauge.text, rhsGauge.text);
    markDirty();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final data = await _service.getToeLoadDetails(inspectionRef);

      final out = await _service.getCommonInspection(inspectionRef);
      final basic = (out['_basicDetails'] as Map?) ?? const {};
      final chk = (out['_chk'] as Map?) ?? const {};

      inspectionNo.value =
          data.inspectionNo.isNotEmpty ? data.inspectionNo : (basic['inspectionNo'] ?? '').toString();
      inspectionDate.value =
          data.date.isNotEmpty ? data.date : (basic['inspectionScheduledDate'] ?? '').toString();
      inspectionName.value = (basic['inspectionName'] ?? '').toString();
      _inspectionId = data.inspectionId;
      headerFields.assignAll(apiList(chk['fieldListData']));
      rows.assignAll(data.rows);
      recalc();
      dirty.value = false;

      final st = (basic['status'] ?? '').toString();
      readOnly.value = st == 'Complete' || st == 'Closed';
    } catch (e) {
      debugPrint('Error loading toe load: $e');
      error.value = 'Unable to load toe load testing';
    } finally {
      loading.value = false;
    }
  }

  // ------------------------------------------------------------ row entry

  /// Message for the first missing required reading field, or null when complete.
  String? _validateEntry() {
    if (reach.text.trim().isEmpty) return 'Please Enter Reach';
    if (pierNo.text.trim().isEmpty) return 'Please Enter Pier No / Ring No';
    if (plinthNo.text.trim().isEmpty) return 'Please Enter Plinth No';
    return null;
  }

  ToeRow _entry(int id) => ToeRow(
        id: id,
        reach: reach.text.trim(),
        pierNo: pierNo.text.trim(),
        plinthNo: plinthNo.text.trim(),
        lhsNonGauge: lhsNonGauge.text.trim(),
        lhsGauge: lhsGauge.text.trim(),
        lhsTotal: lhsTotal.value,
        rhsNonGauge: rhsNonGauge.text.trim(),
        rhsGauge: rhsGauge.text.trim(),
        rhsTotal: rhsTotal.value,
        basePlateNumber: basePlate.text.trim(),
        remark: remark.text.trim(),
      );

  /// After a save, like the web, only the readings and remark are cleared so the
  /// location fields can be reused for the next row.
  void _clearReadings() {
    for (final c in [lhsNonGauge, lhsGauge, rhsNonGauge, rhsGauge, remark]) {
      c.clear();
    }
    lhsTotal.value = '';
    rhsTotal.value = '';
  }

  /// Adds the entered reading. Returns an error message, or null on success.
  String? addEntry() {
    final issue = _validateEntry();
    if (issue != null) return issue;
    rows.add(_entry(rows.length + 1));
    _clearReadings();
    markDirty();
    return null;
  }

  /// Saves the reading being edited. Returns an error message, or null on success.
  String? saveEdit() {
    final i = editIndex.value;
    if (i == null) return null;
    final issue = _validateEntry();
    if (issue != null) return issue;
    rows[i] = _entry(rows[i].id);
    _resetEntry();
    markDirty();
    return null;
  }

  void _resetEntry() {
    for (final c in _controllers) {
      c.clear();
    }
    lhsTotal.value = '';
    rhsTotal.value = '';
    editIndex.value = null;
  }

  void editRow(int i) {
    final r = rows[i];
    reach.text = r.reach;
    pierNo.text = r.pierNo;
    plinthNo.text = r.plinthNo;
    lhsNonGauge.text = r.lhsNonGauge;
    lhsGauge.text = r.lhsGauge;
    rhsNonGauge.text = r.rhsNonGauge;
    rhsGauge.text = r.rhsGauge;
    basePlate.text = r.basePlateNumber;
    remark.text = r.remark;
    lhsTotal.value = r.lhsTotal;
    rhsTotal.value = r.rhsTotal;
    editIndex.value = i;
  }

  void cancelEdit() => _resetEntry();

  void deleteRow(int i) {
    if (editIndex.value == i) {
      _resetEntry();
    } else if (editIndex.value != null && editIndex.value! > i) {
      editIndex.value = editIndex.value! - 1;
    }
    rows.removeAt(i);
    markDirty();
  }

  // ----------------------------------------------------------------- save

  /// Submits the readings. Returns true when the server accepted it.
  Future<bool> save() async {
    saving.value = true;
    try {
      final ok = await _service.saveToeLoad(
        inspectionId: _inspectionId,
        date: inspectionDate.value,
        rows: rows,
      );
      if (ok) dirty.value = false;
      return ok;
    } catch (e) {
      debugPrint('Error saving toe load: $e');
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
