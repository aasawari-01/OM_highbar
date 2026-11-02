import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/api_helpers.dart';
import '../model/checklist_rules.dart';
import '../model/weld_inspection.dart';
import '../service/inspection_service.dart';

/// State and rules of the Weld Inspection screen (web: WeldInspection.jsx).
class WeldController extends GetxController {
  static const maxCodeLength = 10;
  static const maxRemarkLength = 256;
  static const _trackStructureName = 'track structure';
  // Track Structure value that asks for a point number (TurnOut).
  static const _turnOutValue = '2';

  final String inspectionRef; // jeInspectionId
  WeldController(this.inspectionRef);

  final _service = InspectionService();

  final loading = true.obs;
  final saving = false.obs;
  final dirty = false.obs;
  final error = RxnString();

  /// True once the inspection is Complete/Closed: nothing can be edited.
  final readOnly = false.obs;

  /// True once a draft exists: the web only offers Submit from then on.
  final hasDraft = false.obs;

  final inspectionNo = ''.obs;
  final inspectionDate = ''.obs;
  final inspectionName = ''.obs;
  final deptName = ''.obs;
  final personName = ''.obs;

  /// Editable header fields; bumped [revision] to redraw after a change.
  final fields = <JsonMap>[].obs;
  final revision = 0.obs;

  final pointNos = <SelectOption>[].obs;
  final selectedPointNo = RxnString();

  final rows = <WeldRow>[].obs;

  // The row being entered / edited.
  final weldNo = TextEditingController();
  final plinthNo = TextEditingController();
  final remark = TextEditingController();
  final railType = '880'.obs;
  final railPanel = 'Left'.obs;
  final visualStatus = 'OK'.obs;
  final fishplateStatus = 'Yes'.obs;
  final documentName = ''.obs;
  String _document = '';

  /// Index in [rows] being edited, or null when adding a new row.
  final editIndex = RxnInt();

  bool get editable => !readOnly.value;

  /// The Track Structure field decides whether a point number is asked.
  bool get showPointNo {
    revision.value;
    for (final f in fields) {
      if (normText(f['fieldName']) == _trackStructureName) {
        return (f['fieldSelectedValue'] ?? '').toString() == _turnOutValue;
      }
    }
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    weldNo.dispose();
    plinthNo.dispose();
    remark.dispose();
    super.onClose();
  }

  void markDirty() => dirty.value = true;

  void setFieldValue(JsonMap field, String value) {
    field['fieldSelectedValue'] = value;
    if (normText(field['fieldName']) == _trackStructureName && value != _turnOutValue) {
      selectedPointNo.value = null;
    }
    revision.value++;
    markDirty();
  }

  void selectPointNo(String? v) {
    selectedPointNo.value = v;
    markDirty();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final out = await _service.getCommonInspection(inspectionRef);
      final basic = (out['_basicDetails'] as Map?) ?? const {};
      final chk = (out['_chk'] as Map?) ?? const {};

      inspectionNo.value = (basic['inspectionNo'] ?? '').toString();
      inspectionDate.value = (basic['inspectionScheduledDate'] ?? '').toString();
      inspectionName.value = (basic['inspectionName'] ?? '').toString();
      deptName.value = (basic['deptName'] ?? '').toString();
      personName.value = (basic['personResponsible'] ?? '').toString();
      fields.assignAll(apiList(chk['fieldListData']));
      pointNos.assignAll(apiOptions(out['_getTurnOutInspectionPointNoList']));

      final data = await _service.getWeldDetails(inspectionRef);
      hasDraft.value = data.hasDetails;
      selectedPointNo.value = data.pointNo.isEmpty ? null : data.pointNo;
      rows.assignAll(data.rows);

      final st = (basic['status'] ?? '').toString();
      readOnly.value = st == 'Complete' || st == 'Closed';
    } catch (e) {
      debugPrint('Error loading weld inspection: $e');
      error.value = 'Unable to load weld inspection';
    } finally {
      loading.value = false;
    }
  }

  // ------------------------------------------------------------ row entry

  static const _mimeByExtension = {
    'pdf': 'application/pdf',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'gif': 'image/gif',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'txt': 'text/plain',
  };

  /// Picks the row's document. Returns an error message, or null on success/cancel.
  Future<String?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      final path = result?.files.single.path;
      if (path == null) return null;
      final name = path.split(RegExp(r'[\\/]')).last;
      final dot = name.lastIndexOf('.');
      final mime = _mimeByExtension[dot >= 0 ? name.substring(dot + 1).toLowerCase() : ''] ??
          'application/octet-stream';
      _document = 'data:$mime;base64,${base64Encode(await File(path).readAsBytes())}';
      documentName.value = name;
      markDirty();
      return null;
    } catch (e) {
      debugPrint('Error picking document: $e');
      return 'Unable to read the file';
    }
  }

  void removeDocument() {
    _document = '';
    documentName.value = '';
    markDirty();
  }

  void _resetEntry() {
    weldNo.clear();
    plinthNo.clear();
    remark.clear();
    railType.value = '880';
    railPanel.value = 'Left';
    visualStatus.value = 'OK';
    fishplateStatus.value = 'Yes';
    _document = '';
    documentName.value = '';
    editIndex.value = null;
  }

  WeldRow _entry() => WeldRow(
        weldNo: weldNo.text.trim(),
        plinthNo: plinthNo.text.trim(),
        remark: remark.text.trim(),
        railType: railType.value,
        railPanel: railPanel.value,
        visualStatus: visualStatus.value,
        fishplateStatus: fishplateStatus.value,
        documentName: documentName.value,
        document: _document,
      );

  /// Adds the entered row, or replaces the one being edited.
  void commitEntry() {
    final i = editIndex.value;
    if (i == null) {
      rows.add(_entry());
    } else {
      rows[i] = _entry();
    }
    _resetEntry();
    markDirty();
  }

  void editRow(int i) {
    final r = rows[i];
    weldNo.text = r.weldNo;
    plinthNo.text = r.plinthNo;
    remark.text = r.remark;
    railType.value = r.railType;
    railPanel.value = r.railPanel;
    visualStatus.value = r.visualStatus;
    fishplateStatus.value = r.fishplateStatus;
    _document = r.document;
    documentName.value = r.documentName;
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

  /// Message for the first problem, or null when ready to save.
  String? validate() {
    if (rows.isEmpty) return 'Please add atleast one checklist before submitting.';
    return null;
  }

  /// Saves as a draft ([submit] false) or submits. Returns true when the server accepted it.
  Future<bool> save({required bool submit}) async {
    saving.value = true;
    try {
      final ok = await _service.saveWeld(
        id: inspectionRef,
        fields: fields,
        pointNo: showPointNo ? (selectedPointNo.value ?? '') : '',
        rows: rows,
        status: submit ? 1 : 0,
      );
      if (ok) dirty.value = false;
      return ok;
    } catch (e) {
      debugPrint('Error saving weld inspection: $e');
      rethrow;
    } finally {
      saving.value = false;
    }
  }
}
