import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/api_helpers.dart';
import '../model/checklist_rules.dart';
import '../model/creep_request.dart';
import '../service/inspection_service.dart';

/// State and rules of the CREEP Request screen (web: CREEPRequest.jsx).
class CreepController extends GetxController {
  static const maxLocationLength = 12;
  static const maxTemperatureLength = 12;
  static const maxMeasureLength = 50;
  static const maxTextLength = 200;

  final String inspectionRef; // jeInspectionId
  CreepController(this.inspectionRef);

  final _service = InspectionService();

  final loading = true.obs;
  final saving = false.obs;
  final dirty = false.obs;
  final error = RxnString();

  /// True once the inspection is Complete/Closed: nothing can be edited.
  final readOnly = false.obs;

  /// True once the header was saved: the web then offers Update and Final Submit.
  final exists = false.obs;

  final inspectionNo = ''.obs;
  final inspectionDate = ''.obs;
  final inspectionName = ''.obs;
  final personName = ''.obs;
  final headerFields = <JsonMap>[].obs;

  final lines = <SelectOption>[].obs;
  final lineTypes = <SelectOption>[].obs;
  final kilometers = <SelectOption>[].obs;

  final fromTime = Rxn<DateTime>();
  final toTime = Rxn<DateTime>();
  final selectedLine = RxnString();
  final selectedLineType = RxnString();
  final locationFrom = TextEditingController();
  final locationTo = TextEditingController();
  final maxTemp = TextEditingController();
  final minTemp = TextEditingController();
  final rectification = TextEditingController();
  final remark = TextEditingController();
  // Saved rail values the screen has no input for; sent back unchanged.
  String _leftRail = '';
  String _rightRail = '';

  final rows = <CreepRow>[].obs;

  // The row being entered / edited.
  final selectedKm = RxnString();
  final lhs = TextEditingController();
  final rhs = TextEditingController();
  final editIndex = RxnInt();

  String _inspectionId = '';
  String _personId = '';
  String _creepId = '0';

  bool get editable => !readOnly.value;

  List<TextEditingController> get _controllers =>
      [locationFrom, locationTo, maxTemp, minTemp, rectification, remark, lhs, rhs];

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

  void setFromTime(DateTime? v) {
    fromTime.value = v;
    markDirty();
  }

  /// True when [to] is not later than the chosen From Time (minutes of the day).
  bool isNotAfterFrom(DateTime to) {
    final from = fromTime.value;
    if (from == null) return false;
    return to.hour * 60 + to.minute <= from.hour * 60 + from.minute;
  }

  /// Sets the end time and fetches the rail temperatures for the period.
  /// Returns false when the temperatures could not be loaded.
  Future<bool> setToTime(DateTime? v) async {
    toTime.value = v;
    markDirty();
    final from = fromTime.value;
    if (v == null || from == null) return true;
    final t = await _service.getCreepTemperatures(
      date: inspectionDate.value,
      fromTime: formatTimeValue(from),
      toTime: formatTimeValue(v),
    );
    if (t == null) return false;
    maxTemp.text = t.max;
    minTemp.text = t.min;
    return true;
  }

  void selectLine(String? v) {
    selectedLine.value = v;
    markDirty();
  }

  void selectLineType(String? v) {
    selectedLineType.value = v;
    markDirty();
  }

  void selectKm(String? v) => selectedKm.value = v;

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final data = await _service.getCreepDetails(inspectionRef);

      // Header fields and status come from the common inspection API.
      final out = await _service.getCommonInspection(inspectionRef);
      final basic = (out['_basicDetails'] as Map?) ?? const {};
      final chk = (out['_chk'] as Map?) ?? const {};

      inspectionNo.value =
          data.inspectionNo.isNotEmpty ? data.inspectionNo : (basic['inspectionNo'] ?? '').toString();
      inspectionDate.value =
          data.date.isNotEmpty ? data.date : (basic['inspectionScheduledDate'] ?? '').toString();
      inspectionName.value = (basic['inspectionName'] ?? '').toString();
      personName.value = data.personName;
      _personId = data.personId;
      _inspectionId = data.inspectionId;
      headerFields.assignAll(apiList(chk['fieldListData']));
      lines.assignAll(data.lines);
      lineTypes.assignAll(data.lineTypes);
      kilometers.assignAll(data.kilometers);

      final saved = data.saved;
      exists.value = saved != null;
      if (saved != null) {
        _creepId = saved.creepId.isEmpty ? '0' : saved.creepId;
        fromTime.value = parseTimeValue(saved.fromTime);
        toTime.value = parseTimeValue(saved.toTime);
        selectedLine.value = saved.line;
        selectedLineType.value = saved.lineUpDown;
        locationFrom.text = saved.locationFrom;
        locationTo.text = saved.locationTo;
        _leftRail = saved.leftRail;
        _rightRail = saved.rightRail;
        maxTemp.text = saved.maxTemp;
        minTemp.text = saved.minTemp;
        rectification.text = saved.rectification;
        remark.text = saved.remark;
        rows.assignAll(data.rows);
      }

      final st = (basic['status'] ?? '').toString();
      readOnly.value = st == 'Complete' || st == 'Closed';
    } catch (e) {
      debugPrint('Error loading creep request: $e');
      error.value = 'Unable to load creep request';
    } finally {
      loading.value = false;
    }
  }

  // ------------------------------------------------------------ row entry

  void _resetEntry() {
    selectedKm.value = null;
    lhs.clear();
    rhs.clear();
    editIndex.value = null;
  }

  /// Adds or updates the entered row. Returns an error message, or null on success.
  String? commitEntry() {
    if (selectedKm.value == null) return 'Please Select Kilometer';
    if (lhs.text.trim().isEmpty) return 'Please Enter LHS';
    if (rhs.text.trim().isEmpty) return 'Please Enter RHS';

    final km = selectedKm.value!;
    final l = lhs.text.trim();
    final r = rhs.text.trim();
    final i = editIndex.value;
    if (rows.any((x) => x.kilometers == km && x.lhs == l && x.rhs == r)) {
      return 'Data Already Exists';
    }
    if (i == null) {
      rows.add(CreepRow(id: rows.length + 1, kilometers: km, lhs: l, rhs: r));
    } else {
      rows[i] = CreepRow(id: rows[i].id, kilometers: km, lhs: l, rhs: r);
    }
    _resetEntry();
    markDirty();
    return null;
  }

  void editRow(int i) {
    final r = rows[i];
    selectedKm.value = r.kilometers;
    lhs.text = r.lhs;
    rhs.text = r.rhs;
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

  String kmLabel(String value) =>
      kilometers.where((o) => o.value == value).map((o) => o.label).firstOrNull ?? value;

  // ----------------------------------------------------------------- save

  /// Message for the first missing or invalid field, or null when complete.
  String? validate() {
    if (fromTime.value == null) return 'Please Add From Time';
    if (toTime.value == null) return 'Please Add To Time';
    if (isNotAfterFrom(toTime.value!)) return 'To Time must be greater than From Time';
    if (selectedLine.value == null) return 'Please Select Line';
    if (selectedLineType.value == null) return 'Please Select Line (Up/Down)';
    if (locationFrom.text.trim().isEmpty) return 'Please add Location From';
    if (locationTo.text.trim().isEmpty) return 'Please add Location To';
    final from = num.tryParse(locationFrom.text.trim());
    final to = num.tryParse(locationTo.text.trim());
    if (from == null || to == null) return 'Locations must be numbers';
    if (to <= from) return 'To Location Should be Greater than From Location';
    return null;
  }

  JsonMap _header() => {
        'InspectionId': wireId(_inspectionId),
        'Date': inspectionDate.value,
        'FromTime': formatTimeValue(fromTime.value!),
        'ToTime': formatTimeValue(toTime.value!),
        'Line': wireId(selectedLine.value!),
        'LineUpDown': wireId(selectedLineType.value!),
        'LocationFrom': locationFrom.text.trim(),
        'LocationTo': locationTo.text.trim(),
        'LeftRail': _leftRail,
        'RightRail': _rightRail,
        'MaxRailTemperature': maxTemp.text.trim(),
        'MinRailTemperature': minTemp.text.trim(),
        'PersonResponsible': wireId(_personId),
        'ReactificationRequirement': rectification.text.trim(),
        'Remark': remark.text.trim(),
      };

  /// Creates the record (with its rows), or updates the header when it already exists.
  /// Returns true when the server accepted it.
  Future<bool> save() async {
    saving.value = true;
    try {
      final isUpdate = exists.value;
      final ok = await _service.saveCreep(
        isUpdate: isUpdate,
        // Like the web, an update sends the header only.
        payload: isUpdate
            ? _header()
            : {
                ..._header(),
                'CreepMeasurementId': wireId(_creepId),
                'getCreepMeasurementlist':
                    rows.map((r) => r.toJson(wireId(_inspectionId))).toList(),
              },
      );
      if (ok) dirty.value = false;
      return ok;
    } catch (e) {
      debugPrint('Error saving creep request: $e');
      rethrow;
    } finally {
      saving.value = false;
    }
  }

  Future<bool> finalSubmit() async {
    saving.value = true;
    try {
      return await _service.finalSubmitCreep(inspectionRef);
    } catch (e) {
      debugPrint('Error submitting creep request: $e');
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
