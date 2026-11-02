import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/bms_fields.dart';
import '../model/checklist_rules.dart';
import '../service/inspection_service.dart';

/// State and rules of the BMS inspection screen.
class BmsController extends GetxController {
  final String inspectionRef; // jeInspectionId
  BmsController(this.inspectionRef, {bool isView = false})
      : isViewMode = isView.obs;

  final _service = InspectionService();

  final loading = true.obs;
  final saving = false.obs;
  final dirty = false.obs;
  final RxBool isViewMode;
  final error = RxnString();

  final inspectionNo = ''.obs;
  final inspectionDate = ''.obs;
  final inspectionName = ''.obs;
  final headerFields = <JsonMap>[].obs;
  String _stationId = '';

  /// One text controller per reading, keyed by [BmsField.payloadKey].
  final inputs = <String, TextEditingController>{
    for (final s in bmsSections)
      for (final f in s.fields) f.payloadKey: TextEditingController(),
  };

  bool get editable => !isViewMode.value;

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

  /// API sends numbers (2.00); show them without a trailing ".0".
  String _readingText(dynamic v) {
    if (v == null) return '';
    if (v is num && v == v.truncate()) return v.truncate().toString();
    return v.toString();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final bms = await _service.getBmsDetails(inspectionRef);
      final dateInfo = (bms['getInspectionDate'] as Map?) ?? const {};
      final saved = bms['addBMSDetailsModels'];
      if (saved is Map) {
        for (final s in bmsSections) {
          for (final f in s.fields) {
            inputs[f.payloadKey]!.text = _readingText(saved[f.responseKey]);
          }
        }
      }

      // Header fields (station etc.) and status come from the common inspection API.
      final out = await _service.getCommonInspection(inspectionRef);
      final basic = (out['_basicDetails'] as Map?) ?? const {};
      final chk = (out['_chk'] as Map?) ?? const {};
      final fields = ((chk['fieldListData'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      inspectionNo.value =
          (dateInfo['inspectionNo'] ?? basic['inspectionNo'] ?? '').toString();
      inspectionDate.value =
          (dateInfo['date'] ?? basic['inspectionScheduledDate'] ?? '')
              .toString();
      inspectionName.value = (basic['inspectionName'] ?? '').toString();
      headerFields.assignAll(fields);
      _stationId = fields.isEmpty
          ? ''
          : (fields.first['fieldSelectedValue'] ?? '').toString();
      final status = (basic['status'] ?? '').toString();
      if (status == 'Complete' || status == 'Closed') isViewMode.value = true;
    } catch (e) {
      debugPrint('Error loading BMS: $e');
      error.value = 'Unable to load BMS details';
    } finally {
      loading.value = false;
    }
  }

  /// Label of a select field's chosen option, else the raw value.
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

  /// Saves the readings. Returns true when the server accepted them.
  Future<bool> save({required bool isDraft}) async {
    saving.value = true;
    try {
      final ok = await _service.saveBms(
        isDraft: isDraft,
        payload: {
          'InspectionNo': inspectionRef,
          'Date': inspectionDate.value,
          'reachid': '',
          'stationid': _stationId,
          for (final s in bmsSections)
            for (final f in s.fields) f.payloadKey: inputs[f.payloadKey]!.text,
        },
      );
      if (ok) dirty.value = false;
      return ok;
    } catch (e) {
      debugPrint('Error saving BMS: $e');
      rethrow;
    } finally {
      saving.value = false;
    }
  }
}
