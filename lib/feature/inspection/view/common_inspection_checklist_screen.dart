import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_section.dart';
import '../../../utils/widgets/cust_date_time_picker.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/common_checklist_controller.dart';
import '../model/checklist_rules.dart';
import 'widgets/checklist_attachment_section.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_form_widgets.dart';

class CommonInspectionChecklistScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;
  final bool isView;

  const CommonInspectionChecklistScreen(
      {super.key, required this.inspectionId, this.isView = false});

  @override
  State<CommonInspectionChecklistScreen> createState() =>
      _CommonInspectionChecklistScreenState();
}

class _CommonInspectionChecklistScreenState
    extends State<CommonInspectionChecklistScreen> {
  late final CommonChecklistController c;

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<CommonChecklistController>(tag: tag);
    c = Get.put(
        CommonChecklistController(widget.inspectionId, isView: widget.isView),
        tag: tag);
  }

  @override
  void dispose() {
    Get.delete<CommonChecklistController>(tag: widget.inspectionId);
    super.dispose();
  }

  // --------------------------------------------------------------- actions

  Future<void> _onRadioTap(JsonMap row, JsonMap col, JsonMap ctrl) async {
    switch (c.onRadioTap(row, col, ctrl)) {
      case RadioTapOutcome.ignored:
      case RadioTapOutcome.applied:
        return;
      case RadioTapOutcome.confirmSwitchToOkay:
        final ok = await showInspectionConfirm(
          'Switch to Okay?',
          'If you mark this as Okay, the added observation will be removed. Do you want to continue?',
        );
        if (ok) c.applySwitchToOkay(row, col, ctrl);
      case RadioTapOutcome.confirmRemoveObservation:
        final ok = await showInspectionConfirm(
          'Remove observation?',
          'Do you want to remove this point from observation? It will not be logged for follow-up and reporting.',
          confirmText: 'Yes, Remove',
          cancelText: 'Cancel',
        );
        if (ok) c.removeObservation(row);
      case RadioTapOutcome.openObservationPopup:
        await _showNotOkayPopup(row, col, formatActionLabel(ctrl['itemName']));
    }
  }

  Future<void> _showNotOkayPopup(
      JsonMap row, JsonMap triggerCol, String actionLabel) async {
    final review = await showNotOkayReview(
      details: c.reviewDetails(row, triggerCol, actionLabel),
      initialRemark: rowRemark(row),
    );
    if (review != null && review.addToObservation) {
      c.addObservation(row, review.remark);
      showInspectionSnack('Observation added successfully.', isError: false);
    } else {
      c.skipObservation(row);
    }
  }

  Future<void> _pickAttachment() async {
    final error = await c.pickAttachment();
    if (error != null) showInspectionSnack(error);
  }

  Future<void> _submit({required bool isDraft}) async {
    if (c.saving.value) return;
    final issue = c.validate(isDraft: isDraft);
    if (issue != null) {
      if (issue.asDialog) {
        showInspectionErrorPopup(issue.message, title: issue.title ?? 'Error');
      } else {
        showInspectionSnack(issue.message, title: 'Validation Error');
      }
      return;
    }
    final result = await c.save(isDraft: isDraft);
    if (!mounted) return;
    switch (result) {
      case SaveResult.success:
        Navigator.pop(context, true);
        showInspectionSuccess(
            isDraft ? 'Saved as draft.' : 'Inspection submitted successfully.');
      case SaveResult.failed:
        showInspectionSnack('Error in saving data');
      case SaveResult.error:
        showInspectionSnack('Error in request');
    }
  }

  Future<void> _onBack() async {
    if (c.dirty.value && c.editable && !await showUnsavedChangesConfirm()) {
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    // The scaffold is built once; only PopScope listens to `dirty`, so the first
    // keystroke does not rebuild (and reset) the text fields in the body.
    final scaffold = Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'Common Inspection Checklist',
        showDrawer: false,
        onLeadingPressed: _onBack,
        actions: const [SizedBox(width: 16)],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() {
          if (c.loading.value) {
            return const CustLoader();
          }
          if (c.error.value != null) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(c.error.value!),
                TextButton(onPressed: c.load, child: const Text('Retry')),
              ]),
            );
          }
          return _body();
        }),
      ),
    );
    return Obx(() => PopScope(
          canPop: !(c.dirty.value && c.editable),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _onBack();
          },
          child: scaffold,
        ));
  }

  Widget _body() {
    c.revision.value; // rebuild when fields/rows are edited in place
    final basic = c.basic;
    final viewMode = c.isViewMode.value;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InspectionInfoHeader(
            name: c.inspectionName,
            date: (basic['inspectionScheduledDate'] ?? '').toString(),
            number: (basic['inspectionNo'] ?? '').toString(),
          ),
          CustSection(
            title: 'Inspection Details',
            child: Column(
              children: [
                _readOnly('Department', (basic['deptName'] ?? '').toString()),
                const SizedBox(height: AppConstants.elementSpacing),
                _readOnly('Inspection By',
                    (basic['personResponsible'] ?? '').toString()),
                for (final f in c.fields) ...[
                  const SizedBox(height: AppConstants.elementSpacing),
                  _dynamicField(f),
                ],
              ],
            ),
          ),
          CustSection(
            title: 'Checklist',
            child: c.rows.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No checklist items')),
                  )
                : _itemCard(),
          ),
          CustSection(
            title: 'Overall Remarks',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  hintText: 'Enter Remarks',
                  controller: c.overallRemarksController,
                  enabled: !viewMode,
                  maxLines: 3,
                  onChanged: (_) => c.markDirty(),
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                ChecklistAttachmentSection(
                  isViewMode: viewMode,
                  existingAttachments: c.attachmentItems,
                  newAttachment: c.attachment,
                  onAdd: _pickAttachment,
                  onRemoveExisting: c.removeExistingAttachment,
                  onRemoveNew: c.removeNewAttachment,
                ),
              ],
            ),
          ),
          Obx(() => InspectionActionBar(
                viewMode: c.isViewMode.value,
                saving: c.saving.value,
                onBack: _onBack,
                actions: [
                  InspectionAction(
                      'Save as a Draft', () => _submit(isDraft: true)),
                  InspectionAction(
                      'Final Submit', () => _submit(isDraft: false)),
                ],
              )),
        ],
      ),
    );
  }

  Widget _readOnly(String label, String value) => CustomTextField(
        key: ValueKey('ro-$label-$value'),
        label: label,
        controller: TextEditingController(text: value),
        enabled: false,
      );

  // ---------------------------------------------------------- header fields

  Widget _dynamicField(JsonMap f) {
    final label = fieldLabel(f) + (isMandatoryField(f) ? ' *' : '');
    final enabled = c.editable;
    if (normText(f['fieldType']) == 'select') {
      final options = ((f['selectListItems'] as List?) ?? const [])
          .whereType<Map>()
          .map((o) => MapEntry((o['value'] ?? '').toString(),
              (o['label'] ?? o['value'] ?? '').toString()))
          .toList();
      final current = (f['fieldSelectedValue'] ?? '').toString();
      final selected = options
          .where((o) => o.key == current)
          .map((o) => o.value)
          .firstOrNull;
      return CustDropdown(
        label: label,
        hint: 'Select',
        enabled: enabled,
        items: options.map((o) => o.value).toList(),
        selectedValue: selected,
        onChanged: (v) {
          final match = options.where((o) => o.value == v);
          c.touch(
              () => c.setFieldValue(f, match.isEmpty || match.first.key == '0' ? '' : match.first.key));
        },
      );
    }
    if (isTimeField(f)) {
      return CustDateTimePicker(
        key: ValueKey('field-${f['fieldID']}'),
        label: label,
        hint: 'Select time',
        pickerType: PickerType.time,
        use24Hour: true,
        enabled: enabled,
        selectedDateTime:
            parseTimeValue((f['fieldSelectedValue'] ?? '').toString()),
        onDateTimeSelected: (dt) => c.touch(
            () => c.setFieldValue(f, dt == null ? '' : formatTimeValue(dt))),
      );
    }
    return CustomTextField(
      key: ValueKey('field-${f['fieldID']}'),
      label: label,
      controller: TextEditingController(
          text: (f['fieldSelectedValue'] ?? '').toString()),
      enabled: enabled,
      onChanged: (v) {
        c.setFieldValue(f, v);
        c.markDirty();
      },
    );
  }

  // ------------------------------------------------------------- item card

  Widget _itemCard() {
    final row = c.rows[c.index.value];
    final failure = rowFailureCode(row);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: 'Item ${c.index.value + 1} to ${c.rows.length}',
          size: AppConstants.detailLabelSize,
          color: AppColors.textDarkSecondary,
        ),
        const SizedBox(height: AppConstants.subElementSpacing),
        CustText.detailLabel('System'),
        CustText(
            name: (row['systemName'] ?? '-').toString(),
            size: 16,
            fontWeightName: FontWeight.bold),
        const SizedBox(height: AppConstants.subElementSpacing),
        CustText.detailLabel('Sub system:'),
        CustText(
            name: (row['subSystemName'] ?? '-').toString(),
            size: 16,
            fontWeightName: FontWeight.bold),
        const SizedBox(height: AppConstants.subElementSpacing),
        CustText.detailLabel('Failure No:'),
        CustText(
          name: failure.isEmpty ? '-' : failure,
          size: 16,
          color: failure.isEmpty ? AppColors.black : AppColors.orangeColor,
          fontWeightName: FontWeight.bold,
        ),
        for (final col in orderedColumns(row, c.headers)) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          _columnWidget(row, col),
        ],
        const SizedBox(height: AppConstants.elementSpacing),
        _pagination(),
      ],
    );
  }

  Widget _columnWidget(JsonMap row, JsonMap col) {
    final name = (col['columnName'] ?? '').toString();
    final label = isRemarkColumn(name) ? 'Remarks' : name;
    final locked =
        !c.editable || (isObservationColumn(name) && !isRowNotOkay(row));

    final Widget body;
    if (isRemarkColumn(name)) {
      body = _remarkField(row, col);
    } else {
      final children = _controlWidgets(row, col, locked);
      if (children.isEmpty) return const SizedBox.shrink();
      body = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText.formLabel(label),
        const SizedBox(height: AppConstants.labelSpacing),
        body,
      ],
    );
  }

  Widget _remarkField(JsonMap row, JsonMap col) {
    final ctrl = remarkTextControl(col)!;
    final enabled = c.editable && !isControlDisabled(ctrl);
    return TextFormField(
      key: ValueKey(
          'rm-${row['subSystemId']}-${col['columnId']}-${row['_rev'] ?? 0}'),
      initialValue: (ctrl['itemSelectedValue'] ?? '').toString(),
      enabled: enabled,
      maxLines: 3,
      minLines: 1,
      maxLength: remarkMaxLength,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: 'Enter Remarks',
        filled: true,
        fillColor: enabled ? AppColors.white1 : AppColors.containerColor2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: BorderSide(color: AppColors.textFieldColor),
        ),
      ),
      onChanged: (v) {
        ctrl['itemSelectedValue'] = v;
        c.markDirty();
      },
    );
  }

  List<Widget> _controlWidgets(JsonMap row, JsonMap col, bool locked) {
    final controls = columnControls(col);
    final radios = controls.where(isRadioControl).toList();
    final pair = resolveTogglePair(radios);
    final children = <Widget>[];

    if (pair.positive != null && pair.negative != null) {
      // Negative first, as in the design (Not Okay | Okay).
      children.add(_choice(
          pair.negative!, locked, () => _onRadioTap(row, col, pair.negative!)));
      children.add(_choice(
          pair.positive!, locked, () => _onRadioTap(row, col, pair.positive!)));
      if (pair.na != null) {
        children.add(
            _naRadio(pair.na!, locked, () => _onRadioTap(row, col, pair.na!)));
      }
      for (final ctrl in pair.others) {
        children.add(_choice(ctrl, locked, () => _onRadioTap(row, col, ctrl)));
      }
    } else {
      for (final ctrl in radios) {
        children.add(_choice(ctrl, locked, () => _onRadioTap(row, col, ctrl)));
      }
    }

    for (final ctrl in controls.where(isCheckboxControl)) {
      final on = ctrl['itemSelectedValue'] == ctrl['itemName'] ||
          ctrl['itemSelectedValue'] == '1' ||
          ctrl['itemSelectedValue'] == true;
      children.add(Row(mainAxisSize: MainAxisSize.min, children: [
        Checkbox(
          value: on,
          activeColor: AppColors.orangeColor,
          onChanged: (!c.editable || isControlDisabled(ctrl))
              ? null
              : (v) => c.touch(() => ctrl['itemSelectedValue'] =
                  (v ?? false) ? (ctrl['itemName'] ?? '1') : ''),
        ),
        CustText(
            name: (ctrl['itemName'] ?? '').toString(),
            size: AppConstants.detailLabelSize),
      ]));
    }

    for (final ctrl in controls.where(isSelectControl)) {
      final opts = ((ctrl['selectListItems'] ??
              ctrl['itemOptions'] ??
              ctrl['options']) as List?) ??
          const [];
      final values = opts
          .map((o) => o is Map
              ? (o['label'] ?? o['value'] ?? o['itemName'] ?? '').toString()
              : o.toString())
          .where((s) => s.isNotEmpty)
          .toList();
      final current = (ctrl['itemSelectedValue'] ?? '').toString();
      children.add(SizedBox(
        width: double.infinity,
        child: CustDropdown(
          label: (ctrl['itemName'] ?? '').toString(),
          hint: 'Select',
          enabled: !locked && !isControlDisabled(ctrl),
          items: values,
          selectedValue: values.contains(current) ? current : null,
          onChanged: (v) => c.touch(() => ctrl['itemSelectedValue'] = v ?? ''),
        ),
      ));
    }

    for (final ctrl in controls.where(isTextControl)) {
      children.add(SizedBox(
        width: double.infinity,
        child: TextFormField(
          initialValue: (ctrl['itemSelectedValue'] ?? '').toString(),
          enabled: !locked && !isControlDisabled(ctrl),
          onChanged: (v) {
            ctrl['itemSelectedValue'] = v;
            c.markDirty();
          },
        ),
      ));
    }
    return children;
  }

  Widget _choice(JsonMap ctrl, bool locked, VoidCallback onTap) {
    final selected = isControlSelected(ctrl);
    final disabled = locked || isControlDisabled(ctrl);
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 90,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.orangeColor : AppColors.white1,
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          border: Border.all(
            color: selected
                ? AppColors.orangeColor
                : (disabled
                    ? AppColors.textFieldColor
                    : AppColors.textDarkPrimary),
          ),
        ),
        child: CustText(
          name: formatActionLabel(ctrl['itemName']),
          size: 14,
          color: selected
              ? AppColors.white1
              : (disabled
                  ? AppColors.textDarkSecondary
                  : AppColors.textDarkPrimary),
        ),
      ),
    );
  }

  Widget _naRadio(JsonMap ctrl, bool locked, VoidCallback onTap) {
    final disabled = locked || isControlDisabled(ctrl);
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isControlSelected(ctrl)
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: disabled ? AppColors.textFieldColor : AppColors.orangeColor,
        ),
        const SizedBox(width: 4),
        CustText(name: 'NA', size: AppConstants.detailLabelSize),
      ]),
    );
  }

  Widget _pagination() {
    final i = c.index.value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          color: AppColors.orangeColor,
          disabledColor: AppColors.textFieldColor,
          onPressed: i > 0 ? () => c.goTo(i - 1) : null,
        ),
        CustText(name: '${i + 1}', size: 16, fontWeightName: FontWeight.bold),
        IconButton(
          icon: const Icon(TablerIcons.chevron_right),
          color: AppColors.orangeColor,
          disabledColor: AppColors.textFieldColor,
          onPressed: i < c.rows.length - 1 ? () => c.goTo(i + 1) : null,
        ),
      ],
    );
  }
}
