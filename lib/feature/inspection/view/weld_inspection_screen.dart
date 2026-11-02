import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_date_time_picker.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_section.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/weld_controller.dart';
import '../model/checklist_rules.dart';
import '../model/weld_inspection.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_form_widgets.dart';

/// Weld Inspection (web: WeldInspection.jsx).
class WeldInspectionScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;

  const WeldInspectionScreen({super.key, required this.inspectionId});

  @override
  State<WeldInspectionScreen> createState() => _WeldInspectionScreenState();
}

class _WeldInspectionScreenState extends State<WeldInspectionScreen> {
  late final WeldController c;

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<WeldController>(tag: tag);
    c = Get.put(WeldController(widget.inspectionId), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<WeldController>(tag: widget.inspectionId);
    super.dispose();
  }

  // --------------------------------------------------------------- actions

  Future<void> _pickDocument() async {
    final error = await c.pickDocument();
    if (error != null) showInspectionSnack(error);
  }

  Future<void> _save({required bool submit}) async {
    if (c.saving.value) return;
    final issue = c.validate();
    if (issue != null) {
      showInspectionSnack(issue, title: 'Validation Error');
      return;
    }
    final confirmed = await showInspectionConfirm(
        submit ? 'Submit' : 'Save Draft',
        submit ? 'Do you want to submit?' : 'Do you want to save draft?');
    if (!confirmed) return;

    try {
      final ok = await c.save(submit: submit);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
        showInspectionSuccess('Data updated successfully.');
      } else {
        showInspectionSnack('Error in saving data');
      }
    } catch (_) {
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
    // Only PopScope listens to `dirty`, so typing does not rebuild the form.
    final scaffold = Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'AtWeld Inspection',
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
          if (c.loading.value) return const CustLoader();
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
    final enabled = c.editable;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InspectionInfoHeader(
            name: c.inspectionName.value,
            date: c.inspectionDate.value,
            number: c.inspectionNo.value,
          ),
          CustSection(
            title: 'Inspection Details',
            child: Column(
              children: [
                _readOnly('Department *', c.deptName.value, 'dept'),
                const SizedBox(height: AppConstants.elementSpacing),
                _readOnly('Inspection Name *', c.inspectionName.value, 'name'),
                const SizedBox(height: AppConstants.elementSpacing),
                _readOnly('Inspection By *', c.personName.value, 'by'),
                for (final f in c.fields) ...[
                  const SizedBox(height: AppConstants.elementSpacing),
                  _dynamicField(f, enabled),
                ],
                if (c.showPointNo) ...[
                  const SizedBox(height: AppConstants.elementSpacing),
                  InspectionOptionDropdown(
                    label: 'Point No',
                    options: c.pointNos,
                    selected: c.selectedPointNo.value,
                    enabled: enabled,
                    onChanged: c.selectPointNo,
                  ),
                ],
              ],
            ),
          ),
          CustSection(
            title: 'Weld Observations',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < c.rows.length; i++) ...[
                  _rowCard(i, c.rows[i], enabled),
                  const SizedBox(height: AppConstants.subElementSpacing),
                ],
                if (c.rows.isEmpty)
                  CustText(
                    name: 'No weld added yet.',
                    size: AppConstants.detailLabelSize,
                    color: AppColors.textDarkSecondary,
                  ),
              ],
            ),
          ),
          if (enabled) _entryForm(),
          Obx(() => InspectionActionBar(
                viewMode: c.readOnly.value,
                saving: c.saving.value,
                onBack: _onBack,
                actions: [
                  InspectionAction('Save Draft', () => _save(submit: false)),
                  if (c.hasDraft.value) InspectionAction('Submit', () => _save(submit: true)),
                ],
              )),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ header fields

  Widget _dynamicField(JsonMap f, bool enabled) {
    final label = fieldLabel(f) + (isMandatoryField(f) ? ' *' : '');
    if (normText(f['fieldType']) == 'select') {
      final options = ((f['selectListItems'] as List?) ?? const [])
          .whereType<Map>()
          .map((o) => MapEntry((o['value'] ?? '').toString(),
              (o['label'] ?? o['value'] ?? '').toString()))
          .toList();
      final current = (f['fieldSelectedValue'] ?? '').toString();
      return CustDropdown(
        label: label,
        hint: 'Select',
        enabled: enabled,
        items: options.map((o) => o.value).toList(),
        selectedValue: options.where((o) => o.key == current).map((o) => o.value).firstOrNull,
        onChanged: (v) {
          final match = options.where((o) => o.value == v);
          c.setFieldValue(f, match.isEmpty || match.first.key == '0' ? '' : match.first.key);
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
        selectedDateTime: parseTimeValue((f['fieldSelectedValue'] ?? '').toString()),
        onDateTimeSelected: (dt) => c.setFieldValue(f, dt == null ? '' : formatTimeValue(dt)),
      );
    }
    return CustomTextField(
      key: ValueKey('field-${f['fieldID']}'),
      label: label,
      controller: TextEditingController(text: (f['fieldSelectedValue'] ?? '').toString()),
      enabled: enabled,
      onChanged: (v) {
        f['fieldSelectedValue'] = v;
        c.markDirty();
      },
    );
  }

  // ------------------------------------------------------------ weld rows


  Widget _rowCard(int i, WeldRow r, bool enabled) => InspectionItemCard(
        head: MapEntry('Weld No:', r.weldNo),
        left: [
          MapEntry('Plinth No./Location', r.plinthNo),
          MapEntry('Rail Panel', r.railPanel),
          MapEntry('Fishplate Status', r.fishplateStatus),
          MapEntry('Document', r.documentName),
        ],
        right: [
          MapEntry('Rail Type', r.railType),
          MapEntry('Visual Status', r.visualStatus),
          MapEntry('Remark', r.remark),
        ],
        onEdit: enabled ? () => c.editRow(i) : null,
        onDelete: enabled ? () => c.deleteRow(i) : null,
      );
  Widget _entryForm() {
    final editing = c.editIndex.value != null;
    Widget gap() => const SizedBox(height: AppConstants.elementSpacing);
    return CustSection(
      title: editing ? 'Edit Weld' : 'Add Weld',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'Weld No',
            controller: c.weldNo,
            maxLength: WeldController.maxCodeLength,
            onChanged: (_) => c.markDirty(),
          ),
          gap(),
          CustomTextField(
            label: 'Plinth No./Location',
            controller: c.plinthNo,
            maxLength: WeldController.maxCodeLength,
            onChanged: (_) => c.markDirty(),
          ),
          gap(),
          InspectionOptionDropdown(
            label: 'Rail Type',
            options: weldRailTypes,
            selected: c.railType.value,
            enabled: true,
            onChanged: (v) => c.railType.value = v ?? c.railType.value,
          ),
          gap(),
          InspectionOptionDropdown(
            label: 'Rail Panel',
            options: weldRailPanels,
            selected: c.railPanel.value,
            enabled: true,
            onChanged: (v) => c.railPanel.value = v ?? c.railPanel.value,
          ),
          gap(),
          InspectionOptionDropdown(
            label: 'Visual Status',
            options: weldVisualStatuses,
            selected: c.visualStatus.value,
            enabled: true,
            onChanged: (v) => c.visualStatus.value = v ?? c.visualStatus.value,
          ),
          gap(),
          InspectionOptionDropdown(
            label: 'Fishplate Status',
            options: weldYesNo,
            selected: c.fishplateStatus.value,
            enabled: true,
            onChanged: (v) => c.fishplateStatus.value = v ?? c.fishplateStatus.value,
          ),
          gap(),
          CustomTextField(
            label: 'Remark',
            hintText: 'Enter remark',
            controller: c.remark,
            maxLength: WeldController.maxRemarkLength,
            onChanged: (_) => c.markDirty(),
          ),
          gap(),
          CustText.formLabel('Document'),
          const SizedBox(height: AppConstants.labelSpacing),
          Row(children: [
            TextButton.icon(
              onPressed: _pickDocument,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            ),
            Expanded(
              child: CustText(
                name: c.documentName.value,
                size: AppConstants.detailLabelSize,
                color: AppColors.textDarkSecondary,
              ),
            ),
            if (c.documentName.value.isNotEmpty)
              IconButton(icon: const Icon(Icons.close), onPressed: c.removeDocument),
          ]),
          gap(),
          Row(children: [
            if (editing) ...[
              Expanded(
                child: CustOutlineButton(
                  name: 'Cancel',
                  size: double.infinity,
                  sHeight: AppConstants.buttonHeight,
                  borderRadius: AppConstants.inputRadius,
                  onSelected: (_) => c.cancelEdit(),
                ),
              ),
              const SizedBox(width: AppConstants.elementSpacing),
            ],
            Expanded(
              child: CustButton(
                name: editing ? 'Update' : 'Add',
                size: double.infinity,
                sHeight: AppConstants.buttonHeight,
                borderRadius: AppConstants.inputRadius,
                onSelected: (_) => c.commitEntry(),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _readOnly(String label, String value, String key) => CustomTextField(
        key: ValueKey(key),
        label: label,
        controller: TextEditingController(text: value),
        enabled: false,
      );
}
