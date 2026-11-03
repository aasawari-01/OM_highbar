import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/api_helpers.dart';
import '../model/checklist_rules.dart';
import '../model/load_details.dart';
import '../service/inspection_service.dart';

/// State and rules of the Load Details screen (web: LoadDetails.jsx).
class LoadDetailsController extends GetxController {
  final String inspectionRef; // jeInspectionId
  LoadDetailsController(this.inspectionRef);

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
  final mdbTypes = <SelectOption>[].obs;

  /// MDB type chosen for the row being entered; the readings show once it is set.
  final selectedMdbType = RxnString();

  /// Rows saved on the server plus rows added on this screen.
  final rows = <LoadRow>[].obs;

  /// One text controller per reading of the row being entered.
  final inputs = <String, TextEditingController>{
    for (final f in loadReadingFields) f.payloadKey: TextEditingController(),
  };

  String _inspectionId = '';
  String _stationId = '';
  String _pf = '';
  String _kwh = '';
  String _kvah = '';

  bool get editable => !readOnly.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    for (final c in inputs.values) {
      c.dispose();
    }
    super.onClose();
  }

  void markDirty() => dirty.value = true;

  void selectMdbType(String? value) {
    // TEMP: remove once the MDB type problem is found.
    debugPrint('[LoadDetails] picked MDB value="$value"; options=${mdbTypes.map((o) => '"${o.value}=${o.label}"').toList()}');
    selectedMdbType.value = (value == null || value.isEmpty) ? null : value;
    markDirty();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final data = await _service.getLoadDetails(inspectionRef);

      // Header fields (station etc.) and status come from the common inspection API.
      final out = await _service.getCommonInspection(inspectionRef);
      final basic = (out['_basicDetails'] as Map?) ?? const {};
      final chk = (out['_chk'] as Map?) ?? const {};
      final fields = ((chk['fieldListData'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      inspectionNo.value =
          data.inspectionNo.isNotEmpty ? data.inspectionNo : (basic['inspectionNo'] ?? '').toString();
      inspectionDate.value =
          data.date.isNotEmpty ? data.date : (basic['inspectionScheduledDate'] ?? '').toString();
      inspectionName.value = (basic['inspectionName'] ?? '').toString();
      _inspectionId = data.inspectionId;
      _pf = data.pf;
      _kwh = data.kwh;
      _kvah = data.kvah;
      mdbTypes.assignAll(data.mdbTypes);
      rows.assignAll(data.rows);
      selectedMdbType.value = null;
      headerFields.assignAll(fields);
      _stationId = fields.isEmpty ? '' : (fields.first['fieldSelectedValue'] ?? '').toString();

      final status = (basic['status'] ?? '').toString();
      readOnly.value = status == 'Complete' || status == 'Closed';
    } catch (e) {
      debugPrint('Error loading load details: $e');
      error.value = 'Unable to load load details';
    } finally {
      loading.value = false;
    }
  }

  /// Label of an MDB type value, or the value itself when unknown.
  String mdbLabel(String value) {
    for (final o in mdbTypes) {
      if (o.value == value) return o.label;
    }
    return value;
  }

  /// Message when the row being entered cannot be added, or null.
  String? validateRow() {
    if (selectedMdbType.value == null) return 'Please Select MDB Type';
    return null;
  }

  /// Adds the row being entered to [rows] and clears the inputs.
  void addRow() {
    rows.add(LoadRow(
      mdbType: selectedMdbType.value!,
      readings: {for (final e in inputs.entries) e.key: e.value.text.trim()},
    ));
    for (final c in inputs.values) {
      c.clear();
    }
    selectedMdbType.value = null;
    markDirty();
  }

  void removeRow(int index) {
    rows.removeAt(index);
    markDirty();
  }

  /// Saves all rows. Returns true when the server accepted them.
  Future<bool> save() async {
    saving.value = true;
    try {
      final ok = await _service.saveLoadDetails(
        header: {
          'InspectionId': wireId(_inspectionId),
          'Date': inspectionDate.value,
          'StationId': wireId(_stationId),
          'MDBType': wireId(selectedMdbType.value ?? '0'),
          'PF': _pf,
          'KWH': _kwh,
          'KVAH': _kvah,
        },
        rows: rows.map((r) => r.toPayload()).toList(),
      );
      if (ok) dirty.value = false;
      return ok;
    } catch (e) {
      debugPrint('Error saving load details: $e');
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
