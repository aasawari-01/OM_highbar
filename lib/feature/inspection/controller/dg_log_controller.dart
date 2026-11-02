import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../model/checklist_rules.dart';
import '../model/api_helpers.dart';
import '../service/inspection_service.dart';

/// State and rules of the DG Log Book screen (web: DGLogBook.jsx).
class DgLogController extends GetxController {
  static const _dateFormat = 'dd/MM/yyyy';

  final String inspectionRef; // jeInspectionId
  DgLogController(this.inspectionRef);

  final _service = InspectionService();

  final loading = true.obs;
  final saving = false.obs;
  final dirty = false.obs;
  final error = RxnString();

  /// True once the inspection is Complete/Closed: nothing can be edited.
  final readOnly = false.obs;

  /// True when a log already exists, so the button says Update.
  final isUpdate = false.obs;

  final inspectionNo = ''.obs;
  final inspectionDate = ''.obs;
  final inspectionName = ''.obs;
  final employeeName = ''.obs;
  final headerFields = <JsonMap>[].obs;
  final dgOptions = <SelectOption>[].obs;

  // Entered values.
  final fuelLevel = TextEditingController();
  final dgRun = TextEditingController();
  final totalRunningHours = TextEditingController();
  final batteryVoltage = TextEditingController();
  final fuelBalance = TextEditingController();
  final remark = TextEditingController();
  final dgStart = Rxn<DateTime>();
  final dgStop = Rxn<DateTime>();
  final selectedDg = RxnString(); // SelectOption.value
  final fuelFilledDate = Rxn<DateTime>();

  /// The fuel filled date is fixed once the server already knows it.
  final fuelDateLocked = false.obs;

  String _inspectionId = '';
  String _employeeId = '';
  String _stationId = '';

  bool get editable => !readOnly.value;

  List<TextEditingController> get _texts => [
        fuelLevel,
        dgRun,
        totalRunningHours,
        batteryVoltage,
        fuelBalance,
        remark
      ];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    for (final c in _texts) {
      c.dispose();
    }
    super.onClose();
  }

  void markDirty() => dirty.value = true;

  void setDgStart(DateTime? t) {
    dgStart.value = t;
    markDirty();
  }

  void setDgStop(DateTime? t) {
    dgStop.value = t;
    markDirty();
  }

  void setDg(String? value) {
    selectedDg.value = (value == '0' || value == '') ? null : value;
    markDirty();
  }

  void setFuelFilledDate(DateTime? d) {
    fuelFilledDate.value = d;
    markDirty();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final details = await _service.getDgLogDetails(inspectionRef);

      // Header fields (station etc.) and status come from the common inspection API.
      final out = await _service.getCommonInspection(inspectionRef);
      final basic = (out['_basicDetails'] as Map?) ?? const {};
      final chk = (out['_chk'] as Map?) ?? const {};
      final fields = ((chk['fieldListData'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      inspectionNo.value = details.inspectionNo.isNotEmpty
          ? details.inspectionNo
          : (basic['inspectionNo'] ?? '').toString();
      inspectionDate.value = details.date.isNotEmpty
          ? details.date
          : (basic['inspectionScheduledDate'] ?? '').toString();
      inspectionName.value = (basic['inspectionName'] ?? '').toString();
      employeeName.value = details.employeeName;
      _employeeId = details.employeeId;
      _inspectionId = details.inspectionId;
      dgOptions.assignAll(details.dgOptions);
      headerFields.assignAll(fields);
      _stationId = fields.isEmpty
          ? ''
          : (fields.first['fieldSelectedValue'] ?? '').toString();

      final saved = details.saved;
      isUpdate.value = saved != null;
      if (saved != null) {
        fuelLevel.text = saved.fuelLevel;
        dgRun.text = saved.dgRun;
        totalRunningHours.text = saved.totalRunningHours;
        batteryVoltage.text = saved.batteryVoltage;
        fuelBalance.text = saved.fuelBalance;
        remark.text = saved.remark;
        dgStart.value = parseTimeValue(saved.dgStart);
        dgStop.value = parseTimeValue(saved.dgStop);
        final hasDg = details.dgOptions.any((o) => o.value == saved.dg);
        selectedDg.value = hasDg ? saved.dg : null;
      }

      final lastFilled = details.lastFuelFilledDate;
      fuelDateLocked.value = lastFilled != null;
      fuelFilledDate.value = lastFilled == null ? null : _parseDate(lastFilled);

      final status = (basic['status'] ?? '').toString();
      readOnly.value = status == 'Complete' || status == 'Closed';
    } catch (e) {
      debugPrint('Error loading DG log: $e');
      error.value = 'Unable to load DG log details';
    } finally {
      loading.value = false;
    }
  }


  DateTime? _parseDate(String v) {
    try {
      return DateFormat(_dateFormat).parseStrict(v.trim());
    } catch (_) {
      return null;
    }
  }

  /// Message for the first missing required field, or null when complete.
  String? validate() {
    bool blank(TextEditingController c) => c.text.trim().isEmpty;
    if (int.tryParse(_stationId) == null || int.parse(_stationId) == 0) {
      return 'Please Select Station Name';
    }
    if (blank(fuelLevel)) return 'Please Add Fuel Level';
    if (dgStart.value == null) return 'Please Add DG Start Time';
    if (dgStop.value == null) return 'Please Add DG Stop Time';
    if (blank(dgRun)) return 'Please Add DG Run';
    if (blank(totalRunningHours)) return 'Please Add Total Running Hrs';
    if (blank(batteryVoltage)) return 'Please Add Battery Voltage';
    if (blank(fuelBalance)) return 'Please Add Fuel Balance';
    if (fuelFilledDate.value == null) {
      return 'Please Select DG Fuel Filled Date';
    }
    if (blank(remark)) return 'Please Add Remark';
    return null;
  }

  /// Creates or updates the log. Returns true when the server accepted it.
  Future<bool> save() async {
    saving.value = true;
    try {
      final ok = await _service.saveDgLog(
        isUpdate: isUpdate.value,
        payload: {
          'InspectionId': wireId(_inspectionId),
          'Date': inspectionDate.value,
          'StationId': wireId(_stationId),
          'PersonResponsible': wireId(_employeeId),
          'FuelLevel': fuelLevel.text.trim(),
          'DGStart': formatTimeValue(dgStart.value!),
          'DGStop': formatTimeValue(dgStop.value!),
          'DGRun': dgRun.text.trim(),
          'TotalRunningHours': totalRunningHours.text.trim(),
          'BatteryVoltage': batteryVoltage.text.trim(),
          'FuelBalance': fuelBalance.text.trim(),
          'Remark': remark.text.trim(),
          'DG': wireId(selectedDg.value ?? '0'),
          'LastfuelfilledDate':
              DateFormat(_dateFormat).format(fuelFilledDate.value!),
        },
      );
      if (ok) dirty.value = false;
      return ok;
    } catch (e) {
      debugPrint('Error saving DG log: $e');
      rethrow;
    } finally {
      saving.value = false;
    }
  }

  /// Label of a header field's chosen select option, else the raw value.
  String headerValue(JsonMap f) {
    final v = (f['fieldSelectedValue'] ?? '').toString();
    for (final o
        in ((f['selectListItems'] as List?) ?? const []).whereType<Map>()) {
      if ((o['value'] ?? '').toString() == v) {
        return (o['label'] ?? v).toString();
      }
    }
    return v;
  }
}
