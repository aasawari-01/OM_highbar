import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../service/auth_manager.dart';
import '../model/api_helpers.dart';
import '../model/checklist_rules.dart';
import '../service/attachment_picker.dart';
import '../service/inspection_service.dart';

/// State and rules of the Pilot Train screen (web: PilotTrainInspection.jsx).
class PilotTrainController extends GetxController {
  /// Business area that records trainset, remark and an image.
  static const _extendedBusinessArea = 2200;
  static const maxRemarkLength = 200;

  final String inspectionRef; // jeInspectionId
  PilotTrainController(this.inspectionRef);

  final _service = InspectionService();

  final loading = true.obs;
  final saving = false.obs;
  final dirty = false.obs;
  final error = RxnString();

  /// True once the inspection is Complete/Closed: nothing can be edited.
  final readOnly = false.obs;

  /// True when the business area records trainset, remark and attachment.
  final extended = false.obs;

  final inspectionNo = ''.obs;
  final inspectionDate = ''.obs;
  final inspectionName = ''.obs;
  final headerFields = <JsonMap>[].obs;
  final trainSets = <SelectOption>[].obs;

  final time = Rxn<DateTime>();
  final selectedTrainSet = RxnString();
  final declared = false.obs;
  final remark = TextEditingController();
  final attachment = Rxn<File>();

  String _inspectionId = '';
  // Saved value the screen has no input for; sent back unchanged.
  String _section = '0';
  bool _exists = false;

  bool get editable => !readOnly.value;

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

  void selectTrainSet(String? v) {
    selectedTrainSet.value = v;
    markDirty();
  }

  void setTime(DateTime? v) {
    time.value = v;
    markDirty();
  }

  void setDeclared(bool v) {
    declared.value = v;
    markDirty();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final data = await _service.getPilotTrainDetail(inspectionRef);

      // Header fields and status come from the common inspection API.
      final out = await _service.getCommonInspection(inspectionRef);
      final basic = (out['_basicDetails'] as Map?) ?? const {};
      final chk = (out['_chk'] as Map?) ?? const {};
      final fields = ((chk['fieldListData'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      extended.value = await AuthManager().getBusinessArea() == _extendedBusinessArea;

      inspectionNo.value =
          data.inspectionNo.isNotEmpty ? data.inspectionNo : (basic['inspectionNo'] ?? '').toString();
      inspectionDate.value =
          data.date.isNotEmpty ? data.date : (basic['inspectionScheduledDate'] ?? '').toString();
      inspectionName.value = (basic['inspectionName'] ?? '').toString();
      _inspectionId = data.inspectionId;
      trainSets.assignAll(data.trainSets);
      headerFields.assignAll(fields);

      final saved = data.saved;
      _exists = saved != null;
      if (saved != null) {
        _section = saved.section.isEmpty ? '0' : saved.section;
        time.value = parseTimeValue(saved.time);
        remark.text = saved.remark;
        final id = saved.trainSetId;
        selectedTrainSet.value = data.trainSets.any((o) => o.value == id) ? id : null;
      }

      final st = (basic['status'] ?? '').toString();
      readOnly.value = st == 'Complete' || st == 'Closed';
    } catch (e) {
      debugPrint('Error loading pilot train: $e');
      error.value = 'Unable to load pilot train details';
    } finally {
      loading.value = false;
    }
  }

  /// Picks the attachment. Returns an error message, or null on success/cancel.
  Future<String?> pickAttachment() async {
    final picked = await pickInspectionImage();
    final file = picked.file;
    if (file != null) {
      attachment.value = file;
      markDirty();
    }
    return picked.error;
  }

  void removeAttachment() {
    attachment.value = null;
    markDirty();
  }

  /// Message for the first missing required field, or null when complete.
  String? validate() {
    if (inspectionDate.value.isEmpty) return 'Please select date';
    if (time.value == null) return 'Please Select Time';
    if (!declared.value) return 'Please accept the declaration';
    return null;
  }

  /// Saves the pilot train inspection. Returns true when the server accepted it.
  Future<bool> save() async {
    saving.value = true;
    try {
      final ok = await _service.savePilotTrain(
        isUpdate: _exists,
        payload: {
          'InspectionId': wireId(_inspectionId),
          'Date': inspectionDate.value,
          'Section': wireId(_section),
          'Time': formatTimeValue(time.value!),
          'remark': extended.value ? remark.text.trim() : '',
          'TrainSetId': extended.value ? wireId(selectedTrainSet.value ?? '0') : 0,
        },
        image: extended.value ? attachment.value : null,
      );
      if (ok) dirty.value = false;
      return ok;
    } catch (e) {
      debugPrint('Error saving pilot train: $e');
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
