import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_date_time_picker.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_section.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/dg_log_controller.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_form_widgets.dart';

/// DG Log Book inspection (web: DGLogBook.jsx).
class DgLogBookScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;

  const DgLogBookScreen({super.key, required this.inspectionId});

  @override
  State<DgLogBookScreen> createState() => _DgLogBookScreenState();
}

class _DgLogBookScreenState extends State<DgLogBookScreen> {
  static const _maxValueLength = 6;
  static const _maxRemarkLength = 180;

  late final DgLogController c;

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<DgLogController>(tag: tag);
    c = Get.put(DgLogController(widget.inspectionId), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<DgLogController>(tag: widget.inspectionId);
    super.dispose();
  }

  // --------------------------------------------------------------- actions

  Future<void> _submit() async {
    if (c.saving.value) return;
    final issue = c.validate();
    if (issue != null) {
      showInspectionSnack(issue, title: 'Validation Error');
      return;
    }
    final update = c.isUpdate.value;
    final confirmed = await showInspectionConfirm(
      update ? 'Update DG Log' : 'Submit',
      update
          ? 'Do you want to update the DG Log inspection?'
          : 'Do you want to submit?',
    );
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
        title: 'DG Log Consumption',
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
    final date = c.inspectionDate.value;
    final enabled = c.editable;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InspectionInfoHeader(
            name: c.inspectionName.value,
            date: date,
            number: c.inspectionNo.value,
          ),
          // Header fields are read-only here (same as the web page).
          CustSection(
            title: 'Inspection Details',
            child: Column(
              children: [
                for (final f in c.headerFields) ...[
                  _readOnly(
                      (f['fieldName'] ?? f['fieldLabel'] ?? 'Field').toString(),
                      c.headerValue(f),
                      'hdr-${f['fieldID']}'),
                  const SizedBox(height: AppConstants.elementSpacing),
                ],
                _readOnly('Date *', date, 'date'),
                const SizedBox(height: AppConstants.elementSpacing),
                _readOnly('Employee Name *', c.employeeName.value, 'employee'),
              ],
            ),
          ),
          CustSection(
            title: 'DG Details',
            child: Column(
              children: [
                _text('Fuel Level *', 'Fuel Level', c.fuelLevel, enabled),
                const SizedBox(height: AppConstants.elementSpacing),
                _time(
                    'DG Start Time *', c.dgStart.value, c.setDgStart, enabled),
                const SizedBox(height: AppConstants.elementSpacing),
                _time('DG Stop Time *', c.dgStop.value, c.setDgStop, enabled),
                const SizedBox(height: AppConstants.elementSpacing),
                _text('DG Run Hours *', 'DG Run', c.dgRun, enabled),
                const SizedBox(height: AppConstants.elementSpacing),
                _text('Total Running Hrs *', 'Total Running Hrs',
                    c.totalRunningHours, enabled),
                const SizedBox(height: AppConstants.elementSpacing),
                _text('Battery Voltage *', 'Battery Voltage', c.batteryVoltage,
                    enabled),
              ],
            ),
          ),
          CustSection(
            title: 'Fuel Details',
            child: Column(
              children: [
                _text('Fuel Balance in Ltrs *', 'Fuel Balance', c.fuelBalance,
                    enabled),
                const SizedBox(height: AppConstants.elementSpacing),
                _dgDropdown(enabled),
                const SizedBox(height: AppConstants.elementSpacing),
                CustDateTimePicker(
                  label: 'DG Fuel Filled Date *',
                  hint: 'DD/MM/YYYY',
                  pickerType: PickerType.date,
                  enabled: enabled && !c.fuelDateLocked.value,
                  selectedDateTime: c.fuelFilledDate.value,
                  onDateTimeSelected: c.setFuelFilledDate,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustomTextField(
                  label: 'Remark *',
                  hintText: 'Remark',
                  controller: c.remark,
                  enabled: enabled,
                  maxLines: 5,
                  maxLength: _maxRemarkLength,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => c.markDirty(),
                ),
              ],
            ),
          ),
          Obx(() => InspectionActionBar(
                viewMode: c.readOnly.value,
                saving: c.saving.value,
                onBack: _onBack,
                actions: [
                  InspectionAction(
                      c.isUpdate.value ? 'Update' : 'Submit', _submit)
                ],
              )),
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

  Widget _text(String label, String hint, TextEditingController controller,
      bool enabled) {
    return CustomTextField(
      label: label,
      hintText: hint,
      controller: controller,
      enabled: enabled,
      maxLength: _maxValueLength,
      onChanged: (_) => c.markDirty(),
    );
  }

  Widget _time(String label, DateTime? value, ValueChanged<DateTime?> onChanged,
      bool enabled) {
    return CustDateTimePicker(
      label: label,
      hint: 'hh:mm',
      pickerType: PickerType.time,
      use24Hour: true,
      enabled: enabled,
      selectedDateTime: value,
      onDateTimeSelected: onChanged,
    );
  }

  Widget _dgDropdown(bool enabled) {
    final options = c.dgOptions;
    final selected = options
        .where((o) => o.value == c.selectedDg.value)
        .map((o) => o.label)
        .firstOrNull;
    return CustDropdown(
      label: 'DG',
      hint: 'Select',
      enabled: enabled,
      items: options.map((o) => o.label).toList(),
      selectedValue: selected,
      onChanged: (label) => c.setDg(options
          .where((o) => o.label == label)
          .map((o) => o.value)
          .firstOrNull),
    );
  }
}
