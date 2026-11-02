import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/api_helpers.dart';
import '../model/checklist_rules.dart';
import '../service/inspection_service.dart';

/// State and rules of the Foot Inspection screen (web: FootInspection.jsx).
class FootController extends GetxController {
  static const maxLocationLength = 12;
  static const maxTextLength = 200;
  static const _fromStationName = 'from station';
  static const _toStationName = 'to station';

  final String inspectionRef; // jeInspectionId
  FootController(this.inspectionRef);

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
  final personName = ''.obs;

  /// Editable header fields (all required, as on the web).
  final fields = <JsonMap>[].obs;
  final lineTypes = <SelectOption>[].obs;

  final time = Rxn<DateTime>();
  final selectedLineType = RxnString();
  final locationFrom = TextEditingController();
  final locationTo = TextEditingController();
  final observation = TextEditingController();
  final remark = TextEditingController();

  String _inspectionId = '';
  String _personId = '';

  bool get editable => !readOnly.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    locationFrom.dispose();
    locationTo.dispose();
    observation.dispose();
    remark.dispose();
    super.onClose();
  }

  void markDirty() => dirty.value = true;

  void setTime(DateTime? v) {
    time.value = v;
    markDirty();
  }

  void selectLineType(String? v) {
    selectedLineType.value = v;
    markDirty();
  }

  /// Stores a header field's value. No rebuild: text fields keep their cursor.
  void setFieldValue(JsonMap field, String value) {
    field['fieldSelectedValue'] = value;
    markDirty();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final data = await _service.getFootDetails(inspectionRef);

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
      lineTypes.assignAll(data.lineTypes);
      fields.assignAll(apiList(chk['fieldListData']));

      final saved = data.saved;
      exists.value = saved != null;
      if (saved != null) {
        time.value = parseTimeValue(saved.time);
        selectedLineType.value = saved.lineUpDown.isEmpty ? null : saved.lineUpDown;
        locationFrom.text = saved.locationFrom;
        locationTo.text = saved.locationTo;
        observation.text = saved.observation;
        remark.text = saved.remark;
      }

      final st = (basic['status'] ?? '').toString();
      readOnly.value = st == 'Complete' || st == 'Closed';
    } catch (e) {
      debugPrint('Error loading foot inspection: $e');
      error.value = 'Unable to load foot inspection';
    } finally {
      loading.value = false;
    }
  }

  /// Message for the first empty header field, or null when all are filled.
  String? validate() {
    for (final f in fields) {
      if ((f['fieldSelectedValue'] ?? '').toString().trim().isEmpty) {
        return 'Please fill ${fieldLabel(f)}';
      }
    }
    return null;
  }

  String? _stationValue(String name) {
    for (final f in fields) {
      if (normText(f['fieldName']) == name) {
        final v = (f['fieldSelectedValue'] ?? '').toString();
        return v.isEmpty ? null : v;
      }
    }
    return null;
  }

  /// Saves the foot inspection. Returns true when the server accepted it.
  Future<bool> save() async {
    saving.value = true;
    try {
      final from = _stationValue(_fromStationName);
      final to = _stationValue(_toStationName);
      final line = selectedLineType.value;
      final ok = await _service.saveFoot(
        id: inspectionRef,
        fields: fields,
        isUpdate: exists.value,
        payload: {
          'InspectionId': wireId(_inspectionId),
          'Date': inspectionDate.value,
          'Time': time.value == null ? null : formatTimeValue(time.value!),
          'LineUpDown': line == null ? null : wireId(line),
          'LocationFrom': locationFrom.text.trim(),
          'LocationTo': locationTo.text.trim(),
          'StationFrom': from == null ? null : wireId(from),
          'StationTo': to == null ? null : wireId(to),
          'PersonalResponsibleId': wireId(_personId),
          'Observation': observation.text.trim(),
          'Remark': remark.text.trim(),
        },
      );
      if (ok) dirty.value = false;
      return ok;
    } catch (e) {
      debugPrint('Error saving foot inspection: $e');
      rethrow;
    } finally {
      saving.value = false;
    }
  }
}
