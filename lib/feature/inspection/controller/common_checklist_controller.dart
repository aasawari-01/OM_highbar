import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/checklist_attachment.dart';
import '../model/checklist_rules.dart';
import '../service/attachment_picker.dart';
import '../service/inspection_service.dart';

/// What the screen must do after a radio tap, decided by [CommonChecklistController.onRadioTap].
enum RadioTapOutcome {
  /// Nothing to do (view mode, disabled or locked control).
  ignored,

  /// Not Okay -> Okay with an added observation: ask first, then [applySwitchToOkay].
  confirmSwitchToOkay,

  /// Observation Yes -> No: ask first, then [removeObservation].
  confirmRemoveObservation,

  /// Value applied; open the observation popup for the tapped action.
  openObservationPopup,

  /// Value applied, nothing more to show.
  applied,
}

/// A problem found by [CommonChecklistController.validate].
class ChecklistIssue {
  final String message;
  final String? title;

  /// True when it needs a blocking dialog, false for a snack bar.
  final bool asDialog;

  const ChecklistIssue(this.message, {this.title, this.asDialog = false});
}

enum SaveResult { success, failed, error }

/// State and rules of the common inspection checklist screen.
class CommonChecklistController extends GetxController {

  final String inspectionRef; // jeInspectionId
  CommonChecklistController(this.inspectionRef, {bool isView = false})
      : isViewMode = isView.obs;

  final _service = InspectionService();

  final loading = true.obs;
  final error = RxnString();
  final RxBool isViewMode;
  final dirty = false.obs;
  final saving = false.obs;
  final index = 0.obs;

  /// Bumped on every in-place change of [fields]/[rows] so `Obx` rebuilds.
  final revision = 0.obs;

  String inspectionId = '';
  String inspectionName = '';
  JsonMap basic = {};
  List<JsonMap> fields = [];
  List<JsonMap> headers = [];
  List<JsonMap> rows = [];
  final existingAttachments = <dynamic>[];

  List<ChecklistAttachment> get attachmentItems => existingAttachments
      .whereType<Map>()
      .map(ChecklistAttachment.fromJson)
      .toList();
  File? attachment;

  final overallRemarksController = TextEditingController();

  bool get editable => !isViewMode.value;
  JsonMap? get currentRow => rows.isEmpty ? null : rows[index.value];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    overallRemarksController.dispose();
    super.onClose();
  }

  // ------------------------------------------------------------------ data

  List<JsonMap> _maps(dynamic list) => ((list as List?) ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final output = await _service.getCommonInspection(inspectionRef);
      final basicDetails =
          Map<String, dynamic>.from((output['_basicDetails'] ?? {}) as Map);
      final chk = Map<String, dynamic>.from((output['_chk'] ?? {}) as Map);

      final headerFields = _maps(chk['fieldListData']);
      final deptId = (basicDetails['deptId'] ?? '').toString();
      for (final f in headerFields) {
        final fid = (f['fieldID'] ?? '').toString();
        if (deptId == '1' && (fid == '3' || fid == '4')) f['isMandatory'] = 1;
      }
      final bodyRows = _maps(chk['tableBodyItems']);
      bodyRows.forEach(normalizeRow);

      overallRemarksController.text = (basicDetails['additionalInfo'] ??
              chk['overallInspectionRemark'] ??
              basicDetails['overallInspectionRemark'] ??
              basicDetails['remark'] ??
              '')
          .toString();

      basic = basicDetails;
      inspectionId = (chk['inspectionId'] ??
              chk['InspectionId'] ??
              basicDetails['inspectionId'] ??
              basicDetails['InspectionId'] ??
              0)
          .toString();
      inspectionName =
          (chk['inspectionName'] ?? basicDetails['inspectionName'] ?? '')
              .toString();
      existingAttachments
        ..clear()
        ..addAll((chk['attachmentList'] ??
            chk['AttachmentList'] ??
            chk['existingAttachments'] ??
            const []) as List);
      fields = headerFields;
      headers = _maps(chk['tableHeaderList']);
      rows = bodyRows;
      index.value = 0;
      final status = (basicDetails['status'] ?? '').toString();
      if (status == 'Complete' || status == 'Closed') isViewMode.value = true;
      revision.value++;
    } catch (e) {
      debugPrint('Error loading common inspection: $e');
      error.value = 'Unable to load checklist';
    } finally {
      loading.value = false;
    }
  }

  // ------------------------------------------------------------- mutations

  /// Runs [change] and marks the form as edited.
  void touch(VoidCallback change) {
    change();
    dirty.value = true;
    revision.value++;
  }

  void markDirty() => dirty.value = true;

  void goTo(int i) {
    if (i >= 0 && i < rows.length) index.value = i;
  }

  void setFieldValue(JsonMap field, String value) =>
      field['fieldSelectedValue'] = value;

  void _setControlValue(JsonMap row, JsonMap col, JsonMap ctrl, dynamic value) {
    final isRadio = isRadioControl(ctrl);
    final isAction = isRadio && isActionColumn(col['columnName']);
    for (final c in columnControls(col)) {
      if (identical(c, ctrl)) {
        c['itemSelectedValue'] = value;
      } else if (isRadio && isRadioControl(c)) {
        c['itemSelectedValue'] = '';
      }
    }
    if (isAction) {
      // Changing the action clears the remark.
      setRowRemark(row, '');
      row['observationRemark'] = '';
      if (isPositiveName(value)) {
        setRowObservation(row, false);
      } else if (isNegativeName(value) && !rowHasObservationYes(row)) {
        setRowObservation(row, false);
      }
    }
  }

  /// Decides what a tap on [ctrl] means; applies it when no confirmation is needed.
  RadioTapOutcome onRadioTap(JsonMap row, JsonMap col, JsonMap ctrl) {
    if (isViewMode.value || isControlDisabled(ctrl)) {
      return RadioTapOutcome.ignored;
    }
    final isObsCol = isObservationColumn(col['columnName']);
    if (isObsCol && !isRowNotOkay(row)) {
      return RadioTapOutcome.ignored; // locked unless Not Okay
    }

    final name = ctrl['itemName'];
    final selectingObsYes = isObsCol &&
        (isPositiveName(name) || ['true', '1'].contains(normControl(name)));
    final selectingObsNo = isObsCol &&
        (isNegativeName(name) || ['false', '0'].contains(normControl(name)));

    final pair =
        resolveTogglePair(columnControls(col).where(isRadioControl).toList());
    final switchingToOkay = !isObsCol &&
        pair.isOkayKind &&
        isPositiveName(name) &&
        pair.negative != null &&
        isControlSelected(pair.negative!);
    if (switchingToOkay &&
        (rowHasObservationYes(row) || rowRemark(row).trim().isNotEmpty)) {
      return RadioTapOutcome.confirmSwitchToOkay;
    }
    if (selectingObsNo && rowHasObservationYes(row)) {
      return RadioTapOutcome.confirmRemoveObservation;
    }

    touch(() => _setControlValue(row, col, ctrl, name));
    return (selectingObsYes || isNotOkayName(name))
        ? RadioTapOutcome.openObservationPopup
        : RadioTapOutcome.applied;
  }

  void applySwitchToOkay(JsonMap row, JsonMap col, JsonMap ctrl) => touch(() {
        _setControlValue(row, col, ctrl, ctrl['itemName']);
        row['observationRemark'] = '';
      });

  void removeObservation(JsonMap row) => touch(() {
        setRowObservation(row, false);
        setRowRemark(row, '');
        row['observationRemark'] = '';
      });

  void addObservation(JsonMap row, String remark) => touch(() {
        final text = remark.trim();
        setRowObservation(row, true);
        row['observationRemark'] = text;
        setRowRemark(row, text);
      });

  /// "No, Skip" / dismissed popup: observation No, remark cleared.
  void skipObservation(JsonMap row) => removeObservation(row);

  /// Label/value pairs shown in the Not Okay review popup.
  List<MapEntry<String, String>> reviewDetails(
      JsonMap row, JsonMap triggerCol, String actionLabel) {
    final failure = rowFailureCode(row);
    final details = <MapEntry<String, String>>[
      MapEntry('System', (row['systemName'] ?? '-').toString()),
      MapEntry('Sub System', (row['subSystemName'] ?? '-').toString()),
      MapEntry('Failure No', failure.isEmpty ? '-' : failure),
    ];
    final seen = <String>{};
    for (final c in orderedColumns(row, headers)) {
      final label = (c['columnName'] ?? '').toString().trim();
      if (label.isEmpty || isRemarkColumn(label) || isObservationColumn(label)) {
        continue;
      }
      if (!seen.add(label.toLowerCase())) continue;
      details.add(MapEntry(
          label, identical(c, triggerCol) ? actionLabel : selectedDisplay(c)));
    }
    return details;
  }

  // ------------------------------------------------------------ attachment

  /// Lets the user pick an image. Returns an error message, or null on success/cancel.
  Future<String?> pickAttachment() async {
    final picked = await pickInspectionImage();
    final file = picked.file;
    if (file != null) touch(() => attachment = file);
    return picked.error;
  }

  void removeNewAttachment() => touch(() => attachment = null);

  void removeExistingAttachment(ChecklistAttachment att) =>
      touch(() => existingAttachments.remove(att.raw));

  // ------------------------------------------------------------------ save

  /// First problem that blocks a final submit, or null. Drafts are never validated.
  ChecklistIssue? validate({required bool isDraft}) {
    if (isDraft) return null;
    for (final f in fields) {
      if (!isMandatoryField(f)) continue;
      final v = (f['fieldSelectedValue'] ?? '').toString().trim();
      if (v.isEmpty || v.toLowerCase() == 'select') {
        return ChecklistIssue('${fieldLabel(f)} is required');
      }
    }
    // Action No / NA / NotOk needs a remark (same rule as the web).
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final needsRemark = rowColumns(row).any((col) =>
          isActionColumn(col['columnName']) &&
          columnControls(col).any((c) =>
              isRadioControl(c) &&
              isControlSelected(c) &&
              (isNegativeName(c['itemName']) || isNaName(c['itemName']))));
      if (needsRemark && rowRemark(row).trim().isEmpty) {
        index.value = i;
        return const ChecklistIssue(
            'If Action Is No/Na/NotOk Please Enter Remark',
            asDialog: true);
      }
    }
    if (overallRemarksController.text.trim().isEmpty) {
      return const ChecklistIssue('Please enter Overall Remark',
          title: 'Error!', asDialog: true);
    }
    return null;
  }

  Future<SaveResult> save({required bool isDraft}) async {
    saving.value = true;
    try {
      var ok = await _service.saveCommonChecklist(
        id: inspectionRef,
        inspectionId: inspectionId,
        inspectionName: inspectionName,
        fields: fields,
        headers: headers,
        rows: rows,
        overallRemark: overallRemarksController.text,
        existingAttachments: existingAttachments,
        attachment: attachment,
        isDraft: isDraft,
      );
      // Final submit: only call the second API once the first one succeeded.
      if (ok && !isDraft) {
        ok = await _service.markCommonSubmitted(inspectionRef);
      }
      if (ok) dirty.value = false;
      return ok ? SaveResult.success : SaveResult.failed;
    } catch (e) {
      debugPrint('Error saving checklist: $e');
      return SaveResult.error;
    } finally {
      saving.value = false;
    }
  }
}
