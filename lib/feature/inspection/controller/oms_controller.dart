import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/api_helpers.dart';
import '../model/checklist_rules.dart';
import '../service/attachment_picker.dart';
import '../service/inspection_service.dart';

/// State and rules of the OMS Action screen (web: OMSAction.jsx).
class OmsController extends GetxController {
  static const maxKmLength = 12;
  static const maxTextLength = 100;
  static const maxSummaryLength = 200;
  static const maxFiles = 10;
  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf', 'txt'];

  final String inspectionRef; // jeInspectionId
  OmsController(this.inspectionRef);

  final _service = InspectionService();

  final loading = true.obs;
  final saving = false.obs;
  final dirty = false.obs;
  final error = RxnString();

  /// True once the inspection is Complete/Closed: nothing can be edited.
  final readOnly = false.obs;

  /// True once saved before: the web then offers Update instead of Submit.
  final exists = false.obs;

  final inspectionNo = ''.obs;
  final inspectionDate = ''.obs;
  final inspectionName = ''.obs;

  /// Read-only header fields. The first two are the line and the line type.
  final headerFields = <JsonMap>[].obs;
  final trainNos = <SelectOption>[].obs;

  final selectedTrainNo = RxnString();
  final fromKm = TextEditingController();
  final toKm = TextEditingController();
  final runNo = TextEditingController();
  final maxRi = TextEditingController();
  final maxRiLocation = TextEditingController();
  final summary = TextEditingController();

  /// New attachments for the RI and the acceleration pack.
  final riFiles = <File>[].obs;
  final accFiles = <File>[].obs;

  String _inspectionId = '';

  bool get editable => !readOnly.value;

  List<TextEditingController> get _controllers =>
      [fromKm, toKm, runNo, maxRi, maxRiLocation, summary];

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

  void selectTrainNo(String? v) {
    selectedTrainNo.value = v;
    markDirty();
  }

  // The line and the line type are the first two header fields (as on the web).
  String _headerRaw(int i) =>
      i < headerFields.length ? (headerFields[i]['fieldSelectedValue'] ?? '').toString() : '';

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final data = await _service.getOmsDetails(inspectionRef);

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
      trainNos.assignAll(data.trainNos);

      final saved = data.saved;
      exists.value = saved != null;
      if (saved != null) {
        fromKm.text = saved.fromKm;
        toKm.text = saved.toKm;
        selectedTrainNo.value = saved.trainNo.isEmpty ? null : saved.trainNo;
        runNo.text = saved.runNo;
        maxRi.text = saved.maxRi;
        maxRiLocation.text = saved.maxRiLocation;
        summary.text = saved.summary;
      }

      final st = (basic['status'] ?? '').toString();
      readOnly.value = st == 'Complete' || st == 'Closed';
    } catch (e) {
      debugPrint('Error loading OMS action: $e');
      error.value = 'Unable to load OMS action';
    } finally {
      loading.value = false;
    }
  }

  // ---------------------------------------------------------- attachments

  /// Adds files to [target]. Returns an error message, or null on success/cancel.
  Future<String?> addFiles(RxList<File> target) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );
      if (result == null) return null;
      for (final p in result.files.map((f) => f.path).whereType<String>()) {
        if (target.length >= maxFiles) return 'You can attach up to $maxFiles files';
        final file = File(p);
        if (file.lengthSync() > maxInspectionImageBytes) {
          return 'File size must be 1MB or less';
        }
        target.add(file);
        markDirty();
      }
      return null;
    } catch (e) {
      debugPrint('Error picking attachments: $e');
      return 'Unable to read the file';
    }
  }

  void removeFile(RxList<File> target, int i) {
    target.removeAt(i);
    markDirty();
  }

  // ----------------------------------------------------------------- save

  /// Message for the first missing or invalid field, or null when complete.
  String? validate() {
    if (inspectionDate.value.isEmpty) return 'Please Select Date';
    if (_headerRaw(0).isEmpty) return 'Please Select Line';
    if (_headerRaw(1).isEmpty) return 'Please Select Line (Up/Down)';
    if (fromKm.text.trim().isEmpty) return 'Please add From KM';
    if (toKm.text.trim().isEmpty) return 'Please add To KM';
    if (selectedTrainNo.value == null) return 'Please select Train No';
    if (runNo.text.trim().isEmpty) return 'Please Select Run No';
    if (maxRi.text.trim().isEmpty) return 'Please add Maximum RI';
    if (maxRiLocation.text.trim().isEmpty) return 'Please Select Location of Max RI';
    if (summary.text.trim().isEmpty) return 'Please add Summary';
    final from = num.tryParse(fromKm.text.trim());
    final to = num.tryParse(toKm.text.trim());
    if (from == null || to == null) return 'KM values must be numbers';
    if (to <= from) return 'To Location Should be Greater than From Location';
    return null;
  }

  /// Saves the OMS action. Returns true when the server accepted it.
  Future<bool> save() async {
    saving.value = true;
    try {
      final ok = await _service.saveOms(
        isUpdate: exists.value,
        riFiles: riFiles,
        accFiles: accFiles,
        payload: {
          'InspectionId': wireId(_inspectionId),
          'Date': inspectionDate.value,
          'Line': wireId(_headerRaw(0)),
          'LineType': wireId(_headerRaw(1)),
          'FromKM': fromKm.text.trim(),
          'ToKM': toKm.text.trim(),
          'TrainNo': wireId(selectedTrainNo.value!),
          'RunNo': runNo.text.trim(),
          'MaxRI': maxRi.text.trim(),
          'LocationMaxRI': maxRiLocation.text.trim(),
          'Summary': summary.text.trim(),
        },
      );
      if (ok) dirty.value = false;
      return ok;
    } catch (e) {
      debugPrint('Error saving OMS action: $e');
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
