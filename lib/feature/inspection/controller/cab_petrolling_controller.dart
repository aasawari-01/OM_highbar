import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../service/auth_manager.dart';
import '../model/api_helpers.dart';
import '../model/cab_petrolling.dart';
import '../model/checklist_rules.dart';
import '../service/attachment_picker.dart';
import '../service/inspection_service.dart';

/// State and rules of the Cab Petrolling Action screen (web: CabPetrollingAction.jsx).
class CabPetrollingController extends GetxController {
  /// Business area whose locations are called "Station" instead of "Location".
  static const _stationBusinessArea = 2200;
  static const minTrainNo = 1;
  static const maxTrainNo = 40;
  static const maxTextLength = 200;

  final String inspectionRef; // jeInspectionId
  CabPetrollingController(this.inspectionRef);

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

  /// "Station" or "Location", depending on the user's business area.
  final locationWord = 'Location'.obs;

  final lines = <CabLineOption>[].obs;
  final lineTypes = <SelectOption>[].obs;
  final locations = <SelectOption>[].obs;
  final locationsLoading = false.obs;

  // Chosen values (option `value`s).
  final selectedLine = RxnString();
  final selectedLineType = RxnString();
  final selectedFrom = RxnString();
  final selectedTo = RxnString();

  final trainNo = TextEditingController();
  final remark = TextEditingController();

  /// Yes ("1") / No ("0") / unanswered ("") per [CabChecklistRow.statusKey].
  final status = <String, String>{}.obs;

  /// Observation text per [CabChecklistRow.observationKey].
  final observations = <String, TextEditingController>{
    for (final r in cabChecklistRows) r.observationKey: TextEditingController(),
  };

  final attachment = Rxn<File>();

  /// Read-only record shown once the inspection is Complete/Closed (null when it could not be loaded).
  final view = Rxn<CabViewData>();

  String _inspectionId = '';
  String _detailId = '';
  // Saved values the screen has no input for; sent back unchanged.
  String _inspection = '';
  String _actionTaken = '';
  // Train No as saved; the 1-40 rule applies only to a value the user enters.
  String _savedTrainNo = '';

  bool get editable => !readOnly.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    trainNo.dispose();
    remark.dispose();
    for (final c in observations.values) {
      c.dispose();
    }
    super.onClose();
  }

  void markDirty() => dirty.value = true;

  /// The API lists a "Select" placeholder (value 0) first; it is not a choice.
  String? _real(String? v) => (v == null || v.isEmpty || v == '0') ? null : v;

  /// Drops the API's "Select ..." entry (e.g. "Select Line"), which is not a choice.
  List<T> _withoutPlaceholder<T>(List<T> items, String Function(T) label) {
    final real = items.where((e) => !label(e).trim().toLowerCase().startsWith('select')).toList();
    return real.isEmpty ? items : real;
  }

  void selectLineType(String? v) {
    selectedLineType.value = _real(v);
    markDirty();
  }

  void selectFrom(String? v) {
    selectedFrom.value = _real(v);
    markDirty();
  }

  void selectTo(String? v) {
    selectedTo.value = _real(v);
    markDirty();
  }

  void setStatus(String key, String value) {
    status[key] = value;
    markDirty();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final data = await _service.getCabPetrollingDetails(inspectionRef);

      // Header fields and status come from the common inspection API.
      final out = await _service.getCommonInspection(inspectionRef);
      final basic = (out['_basicDetails'] as Map?) ?? const {};
      final chk = (out['_chk'] as Map?) ?? const {};
      final fields = ((chk['fieldListData'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final area = await AuthManager().getBusinessArea();
      locationWord.value = area == _stationBusinessArea ? 'Station' : 'Location';

      inspectionNo.value =
          data.inspectionNo.isNotEmpty ? data.inspectionNo : (basic['inspectionNo'] ?? '').toString();
      inspectionDate.value =
          data.date.isNotEmpty ? data.date : (basic['inspectionScheduledDate'] ?? '').toString();
      inspectionName.value = (basic['inspectionName'] ?? '').toString();
      _inspectionId = data.inspectionId;
      lines.assignAll(_withoutPlaceholder(data.lines, (l) => l.label));
      lineTypes.assignAll(_withoutPlaceholder(data.lineTypes, (o) => o.label));
      headerFields.assignAll(fields);

      for (final r in cabChecklistRows) {
        status[r.statusKey] = '';
      }
      final saved = data.saved;
      if (saved != null) {
        _detailId = saved.detailId;
        _inspection = saved.inspection;
        _actionTaken = saved.actionTaken;
        selectedLine.value = _real(saved.line);
        selectedLineType.value = _real(saved.lineType);
        trainNo.text = saved.trainNo;
        _savedTrainNo = saved.trainNo.trim();
        remark.text = saved.remark;
        for (final r in cabChecklistRows) {
          status[r.statusKey] = saved.answers[r.statusKey] ?? '';
          observations[r.observationKey]!.text = saved.answers[r.observationKey] ?? '';
        }
        await _loadLocations(saved.planningPlantId);
        selectedFrom.value = _real(saved.fromLocation);
        selectedTo.value = _real(saved.toLocation);
      }

      final st = (basic['status'] ?? '').toString();
      readOnly.value = st == 'Complete' || st == 'Closed';
      view.value = null;
      if (readOnly.value) {
        try {
          view.value = await _service.getCabPetrollingView(inspectionRef);
        } catch (e) {
          // Falls back to the locked edit form.
          debugPrint('Error loading cab petrolling view: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading cab petrolling: $e');
      error.value = 'Unable to load cab petrolling details';
    } finally {
      loading.value = false;
    }
  }

  Future<bool> _loadLocations(String planningPlantId) async {
    locationsLoading.value = true;
    try {
      locations.assignAll(_withoutPlaceholder(
          await _service.getLocations(planningPlantId), (o) => o.label));
      return true;
    } catch (e) {
      debugPrint('Error loading locations: $e');
      locations.clear();
      return false;
    } finally {
      locationsLoading.value = false;
    }
  }

  /// Picks a line and loads its locations. Returns false when they could not be loaded.
  Future<bool> selectLine(String? value) async {
    selectedLine.value = _real(value);
    selectedFrom.value = null;
    selectedTo.value = null;
    locations.clear();
    markDirty();
    final line = selectedLine.value;
    if (line == null) return true;
    final plant = lines.firstWhereOrNull((l) => l.value == line)?.planningPlantId ?? '';
    return _loadLocations(plant);
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
    if (selectedLine.value == null) return 'Please Select Line';
    if (selectedLineType.value == null) return 'Please Select Line (Up/Down)';
    if (selectedFrom.value == null) return 'Please Select From ${locationWord.value}';
    if (selectedTo.value == null) return 'Please Select To ${locationWord.value}';
    final train = int.tryParse(trainNo.text.trim());
    if (trainNo.text.trim().isEmpty) return 'Please Select Train No';
    final entered = trainNo.text.trim() != _savedTrainNo;
    if (entered && (train == null || train < minTrainNo || train > maxTrainNo)) {
      return 'Train No must be between $minTrainNo and $maxTrainNo';
    }
    return null;
  }

  /// Saves the cab petrolling. Returns true when the server accepted it.
  Future<bool> save() async {
    saving.value = true;
    try {
      final ok = await _service.saveCabPetrolling(
        header: {
          'InspectionId': wireId(_inspectionId),
          'Date': inspectionDate.value,
          'Line': wireId(selectedLine.value!),
          'LineType': wireId(selectedLineType.value!),
          'FromLocation': wireId(selectedFrom.value!),
          'ToLocation': wireId(selectedTo.value!),
          'TrainNo': trainNo.text.trim(),
          'Inspection': _inspection,
          'ActionTaken': _actionTaken,
          'Remark': remark.text.trim(),
        },
        checklist: {
          'Id': wireId(_detailId.isEmpty ? '0' : _detailId),
          for (final r in cabChecklistRows) ...{
            r.statusKey: status[r.statusKey] ?? '',
            r.observationKey: observations[r.observationKey]!.text.trim(),
          },
        },
        image: attachment.value,
      );
      if (ok) dirty.value = false;
      return ok;
    } catch (e) {
      debugPrint('Error saving cab petrolling: $e');
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
