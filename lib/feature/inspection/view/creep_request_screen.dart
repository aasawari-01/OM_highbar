import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_date_time_picker.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_section.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/creep_controller.dart';
import '../model/creep_request.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_form_widgets.dart';

/// CREEP Request inspection (web: CREEPRequest.jsx).
class CreepRequestScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;

  const CreepRequestScreen({super.key, required this.inspectionId});

  @override
  State<CreepRequestScreen> createState() => _CreepRequestScreenState();
}

class _CreepRequestScreenState extends State<CreepRequestScreen> {
  late final CreepController c;

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<CreepController>(tag: tag);
    c = Get.put(CreepController(widget.inspectionId), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<CreepController>(tag: widget.inspectionId);
    super.dispose();
  }

  // --------------------------------------------------------------- actions

  Future<void> _setToTime(DateTime? v) async {
    if (v != null && c.isNotAfterFrom(v)) {
      showInspectionSnack('To Time must be greater than From Time', title: 'Validation Error');
      return;
    }
    final loaded = await c.setToTime(v);
    if (!loaded) showInspectionSnack('Unable to load rail temperatures');
  }

  void _commitRow() {
    final issue = c.commitEntry();
    if (issue != null) showInspectionSnack(issue, title: 'Validation Error');
  }

  Future<void> _submit() async {
    if (c.saving.value) return;
    final issue = c.validate();
    if (issue != null) {
      showInspectionSnack(issue, title: 'Validation Error');
      return;
    }
    final confirmed = await showInspectionConfirm(
        c.exists.value ? 'Update' : 'Submit',
        c.exists.value ? 'Do you want to Update Creep Measurement?' : 'Do you want to submit?');
    if (!confirmed) return;

    try {
      final ok = await c.save();
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

  Future<void> _finalSubmit() async {
    if (c.saving.value) return;
    try {
      final ok = await c.finalSubmit();
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
        title: 'CREEP Request',
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
    final date = c.inspectionDate.value;
    Widget gap() => const SizedBox(height: AppConstants.elementSpacing);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InspectionInfoHeader(
            name: c.inspectionName.value,
            date: date,
            number: c.inspectionNo.value,
          ),
          CustSection(
            title: 'Inspection Details',
            child: Column(
              children: [
                _readOnly('Date *', date, 'date'),
                // Header fields are read-only here (same as the web page).
                for (final f in c.headerFields) ...[
                  gap(),
                  _readOnly((f['fieldName'] ?? f['fieldLabel'] ?? 'Field').toString(),
                      c.headerValue(f), 'hdr-${f['fieldID']}'),
                ],
                gap(),
                CustDateTimePicker(
                  label: 'From Time *',
                  hint: 'HH:mm',
                  pickerType: PickerType.time,
                  use24Hour: true,
                  enabled: enabled,
                  selectedDateTime: c.fromTime.value,
                  onDateTimeSelected: c.setFromTime,
                ),
                gap(),
                CustDateTimePicker(
                  label: 'To Time *',
                  hint: 'HH:mm',
                  pickerType: PickerType.time,
                  use24Hour: true,
                  enabled: enabled,
                  selectedDateTime: c.toTime.value,
                  onDateTimeSelected: _setToTime,
                ),
                gap(),
                InspectionOptionDropdown(
                  label: 'Line *',
                  options: c.lines,
                  selected: c.selectedLine.value,
                  enabled: enabled,
                  onChanged: c.selectLine,
                ),
                gap(),
                InspectionOptionDropdown(
                  label: 'Line (Up/Down) *',
                  options: c.lineTypes,
                  selected: c.selectedLineType.value,
                  enabled: enabled,
                  onChanged: c.selectLineType,
                ),
                gap(),
                _number('Location From (In KM) *', c.locationFrom, enabled,
                    CreepController.maxLocationLength),
                gap(),
                _number('Location To (In KM) *', c.locationTo, enabled,
                    CreepController.maxLocationLength),
                gap(),
                CustomTextField(
                  label: 'Max Rail Temperature',
                  controller: c.maxTemp,
                  enabled: enabled,
                  maxLength: CreepController.maxTemperatureLength,
                  onChanged: (_) => c.markDirty(),
                ),
                gap(),
                CustomTextField(
                  label: 'Min Rail Temperature',
                  controller: c.minTemp,
                  enabled: enabled,
                  maxLength: CreepController.maxTemperatureLength,
                  onChanged: (_) => c.markDirty(),
                ),
                gap(),
                _readOnly('Person Responsible *', c.personName.value, 'person'),
              ],
            ),
          ),
          CustSection(
            title: 'Measurements',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (enabled) ...[
                  InspectionOptionDropdown(
                    label: 'Kilometer *',
                    options: c.kilometers,
                    selected: c.selectedKm.value,
                    enabled: true,
                    onChanged: c.selectKm,
                  ),
                  gap(),
                  CustomTextField(
                    label: 'LHS',
                    controller: c.lhs,
                    maxLength: CreepController.maxMeasureLength,
                  ),
                  gap(),
                  CustomTextField(
                    label: 'RHS',
                    controller: c.rhs,
                    maxLength: CreepController.maxMeasureLength,
                  ),
                  gap(),
                  Row(children: [
                    if (c.editIndex.value != null) ...[
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
                        name: c.editIndex.value != null ? 'Update' : 'Add',
                        size: double.infinity,
                        sHeight: AppConstants.buttonHeight,
                        borderRadius: AppConstants.inputRadius,
                        onSelected: (_) => _commitRow(),
                      ),
                    ),
                  ]),
                  gap(),
                ],
                for (var i = 0; i < c.rows.length; i++) ...[
                  _rowCard(i, c.rows[i], enabled),
                  const SizedBox(height: AppConstants.subElementSpacing),
                ],
                if (c.rows.isEmpty)
                  CustText(
                    name: 'No measurements added yet.',
                    size: AppConstants.detailLabelSize,
                    color: AppColors.textDarkSecondary,
                  ),
              ],
            ),
          ),
          CustSection(
            title: 'Remarks',
            child: Column(
              children: [
                CustomTextField(
                  label: 'Rectification Requirement',
                  hintText: 'Enter rectification requirement',
                  controller: c.rectification,
                  enabled: enabled,
                  maxLines: 4,
                  maxLength: CreepController.maxTextLength,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => c.markDirty(),
                ),
                gap(),
                CustomTextField(
                  label: 'Remarks',
                  hintText: 'Enter remarks',
                  controller: c.remark,
                  enabled: enabled,
                  maxLines: 4,
                  maxLength: CreepController.maxTextLength,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => c.markDirty(),
                ),
              ],
            ),
          ),
          // Like the web, the actions only show once a measurement row exists.
          Obx(() => InspectionActionBar(
                viewMode: c.readOnly.value || c.rows.isEmpty,
                saving: c.saving.value,
                onBack: _onBack,
                actions: [
                  InspectionAction(c.exists.value ? 'Update' : 'Submit', _submit),
                  if (c.exists.value) InspectionAction('Final Submit', _finalSubmit),
                ],
              )),
        ],
      ),
    );
  }


  Widget _rowCard(int i, CreepRow r, bool enabled) => InspectionItemCard(
        head: MapEntry('Kilometer:', c.kmLabel(r.kilometers)),
        left: [MapEntry('LHS', r.lhs)],
        right: [MapEntry('RHS', r.rhs)],
        onEdit: enabled ? () => c.editRow(i) : null,
        onDelete: enabled ? () => c.deleteRow(i) : null,
      );
  Widget _number(String label, TextEditingController ctrl, bool enabled, int maxLength) =>
      CustomTextField(
        label: label,
        controller: ctrl,
        enabled: enabled,
        maxLength: maxLength,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => c.markDirty(),
      );

  Widget _readOnly(String label, String value, String key) => CustomTextField(
        key: ValueKey(key),
        label: label,
        controller: TextEditingController(text: value),
        enabled: false,
      );
}
