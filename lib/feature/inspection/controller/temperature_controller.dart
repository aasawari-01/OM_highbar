import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../model/api_helpers.dart';
import '../model/checklist_rules.dart';
import '../model/temperature_monitoring.dart';
import '../service/attachment_picker.dart';
import '../service/inspection_service.dart';

/// State and rules of the Temperature Monitoring screen (web: TemperatureMonitoring.jsx).
class TemperatureController extends GetxController {
  static const maxRemarkLength = 200;
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  final String inspectionRef; // jeInspectionId
  TemperatureController(this.inspectionRef);

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

  final fromDate = Rxn<DateTime>();
  final toDate = Rxn<DateTime>();
  final time = Rxn<DateTime>();
  final temperature = TextEditingController();
  final remark = TextEditingController();

  final rows = <TempRow>[].obs;
  final editIndex = RxnInt();

  String _inspectionId = '';

  bool get editable => !readOnly.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    temperature.dispose();
    remark.dispose();
    super.onClose();
  }

  void markDirty() => dirty.value = true;

  // ------------------------------------------------------------ statistics

  double? get maxTemp => rows.isEmpty ? null : rows.map((r) => r.temperature).reduce((a, b) => a > b ? a : b);
  double? get minTemp => rows.isEmpty ? null : rows.map((r) => r.temperature).reduce((a, b) => a < b ? a : b);
  double? get meanTemp =>
      rows.isEmpty ? null : rows.map((r) => r.temperature).reduce((a, b) => a + b) / rows.length;

  String formatStat(double? v) => v == null ? '' : v.toStringAsFixed(2);

  // ----------------------------------------------------------------- load

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final data = await _service.getTempMonDetails(inspectionRef);

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

      final st = (basic['status'] ?? '').toString();
      readOnly.value = st == 'Complete' || st == 'Closed';
    } catch (e) {
      debugPrint('Error loading temperature monitoring: $e');
      error.value = 'Unable to load temperature monitoring';
    } finally {
      loading.value = false;
    }
  }

  // ------------------------------------------------------------ row entry

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// True when [to] is a day before the chosen From Date.
  bool isBeforeFrom(DateTime to) {
    final from = fromDate.value;
    return from != null && _day(to).isBefore(_day(from));
  }

  void setFromDate(DateTime? v) {
    fromDate.value = v;
    // A To Date that is now before the new From Date no longer fits.
    final to = toDate.value;
    if (v != null && to != null && isBeforeFrom(to)) toDate.value = null;
    markDirty();
  }

  void setToDate(DateTime? v) {
    toDate.value = v;
    markDirty();
  }

  void setTime(DateTime? v) {
    time.value = v;
    markDirty();
  }

  void _resetEntry() {
    fromDate.value = null;
    toDate.value = null;
    time.value = null;
    temperature.clear();
    editIndex.value = null;
  }

  /// Adds or updates the entered reading. Returns an error message, or null on success.
  String? commitEntry() {
    if (fromDate.value == null) return 'Please select From Date';
    if (toDate.value == null) return 'Please select To Date';
    if (isBeforeFrom(toDate.value!)) return 'To Date must not be before From Date';
    if (time.value == null) return 'Please select Time';
    final t = double.tryParse(temperature.text.trim());
    if (t == null) return 'Please select Temperature';

    final timeText = formatTimeValue(time.value!);
    final i = editIndex.value;
    if (i == null && rows.any((r) => r.time == timeText && r.temperature == t)) {
      return 'Data Already Exists';
    }
    final row = TempRow(
      id: i == null ? rows.length + 1 : rows[i].id,
      fromDate: _dateFormat.format(fromDate.value!),
      toDate: _dateFormat.format(toDate.value!),
      time: timeText,
      temperature: t,
    );
    if (i == null) {
      rows.add(row);
    } else {
      rows[i] = row;
    }
    _resetEntry();
    markDirty();
    return null;
  }

  DateTime? _parseDate(String s) {
    try {
      return _dateFormat.parseStrict(s);
    } catch (_) {
      return null;
    }
  }

  void editRow(int i) {
    final r = rows[i];
    fromDate.value = _parseDate(r.fromDate);
    toDate.value = _parseDate(r.toDate);
    time.value = parseTimeValue(r.time);
    temperature.text = r.temperature.toString();
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

  // --------------------------------------------------------- Excel upload

  /// Picks an Excel file (xlsx/xls, at most 1MB). Returns an error message when it is not
  /// usable, null otherwise; [picked] is null when the user cancelled.
  Future<({File? file, String? error})> pickExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xls'],
      );
      final path = result?.files.single.path;
      if (path == null) return (file: null, error: null);
      final file = File(path);
      if (file.lengthSync() > maxInspectionImageBytes) {
        return (file: null, error: 'File size should not be greater than 1 MB.');
      }
      return (file: file, error: null);
    } catch (e) {
      debugPrint('Error picking excel: $e');
      return (file: null, error: 'Unable to read the file');
    }
  }

  /// Replaces the readings with those of [file]. Returns a message to show, and whether
  /// it is an error.
  Future<({String message, bool isError})> upload(File file) async {
    saving.value = true;
    try {
      final uploaded = await _service.uploadTemperatureFile(file);
      if (uploaded.isEmpty) {
        return (message: 'No data found in the uploaded file', isError: true);
      }
      rows.assignAll(uploaded);
      _resetEntry();
      markDirty();
      return (message: 'Data uploaded successfully', isError: false);
    } catch (e) {
      return (message: e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      saving.value = false;
    }
  }

  // ----------------------------------------------------------------- save

  /// Message for the first problem, or null when ready to save. A submit also needs a remark.
  String? validate({required bool submit}) {
    if (rows.isEmpty) return submit ? 'Please Add Atleast One Record' : 'Please Add Time and Temperature';
    if (submit && remark.text.trim().isEmpty) return 'Please Enter Remark';
    return null;
  }

  /// Saves the readings as a draft, or submits them. Returns true when the server accepted it.
  Future<bool> save({required bool submit}) async {
    saving.value = true;
    try {
      final ok = await _service.saveTemperature(
        inspectionId: _inspectionId,
        date: inspectionDate.value,
        remark: remark.text.trim(),
        rows: rows,
      );
      if (!ok) return false;
      if (submit && !await _service.markTemperatureSubmitted(_inspectionId)) return false;
      dirty.value = false;
      return true;
    } catch (e) {
      debugPrint('Error saving temperature monitoring: $e');
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
