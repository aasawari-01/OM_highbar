import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_date_time_picker.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_section.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/foot_controller.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_dynamic_field.dart';
import 'widgets/inspection_form_widgets.dart';

/// Foot Inspection (web: FootInspection.jsx).
class FootInspectionScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;

  const FootInspectionScreen({super.key, required this.inspectionId});

  @override
  State<FootInspectionScreen> createState() => _FootInspectionScreenState();
}

class _FootInspectionScreenState extends State<FootInspectionScreen> {
  late final FootController c;

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<FootController>(tag: tag);
    c = Get.put(FootController(widget.inspectionId), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<FootController>(tag: widget.inspectionId);
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
    final update = c.exists.value;
    final confirmed = await showInspectionConfirm(
        update ? 'Update' : 'Submit',
        update ? 'Do you want to Update Foot Inspection?' : 'Do you want to submit?');
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
        title: 'Foot Inspection',
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
                for (final f in c.fields) ...[
                  gap(),
                  InspectionDynamicField(
                    field: f,
                    enabled: enabled,
                    required: true,
                    onChanged: (v) => c.setFieldValue(f, v),
                  ),
                ],
                gap(),
                _readOnly('Person Responsible', c.personName.value, 'person'),
                gap(),
                CustDateTimePicker(
                  label: 'Time',
                  hint: 'HH:mm',
                  pickerType: PickerType.time,
                  use24Hour: true,
                  enabled: enabled,
                  selectedDateTime: c.time.value,
                  onDateTimeSelected: c.setTime,
                ),
                gap(),
                InspectionOptionDropdown(
                  label: 'Line (Up/Down)',
                  options: c.lineTypes,
                  selected: c.selectedLineType.value,
                  enabled: enabled,
                  onChanged: c.selectLineType,
                ),
                gap(),
                _number('Location From (In KM)', c.locationFrom, enabled),
                gap(),
                _number('Location To (In KM)', c.locationTo, enabled),
              ],
            ),
          ),
          CustSection(
            title: 'Observation',
            child: Column(
              children: [
                _multiline('Observation', 'Enter observation', c.observation, enabled),
                gap(),
                _multiline('Remark', 'Enter remark', c.remark, enabled),
              ],
            ),
          ),
          Obx(() => InspectionActionBar(
                viewMode: c.readOnly.value,
                saving: c.saving.value,
                onBack: _onBack,
                actions: [InspectionAction(c.exists.value ? 'Update' : 'Submit', _submit)],
              )),
        ],
      ),
    );
  }

  Widget _number(String label, TextEditingController ctrl, bool enabled) => CustomTextField(
        label: label,
        hintText: label,
        controller: ctrl,
        enabled: enabled,
        maxLength: FootController.maxLocationLength,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => c.markDirty(),
      );

  Widget _multiline(String label, String hint, TextEditingController ctrl, bool enabled) =>
      CustomTextField(
        label: label,
        hintText: hint,
        controller: ctrl,
        enabled: enabled,
        maxLines: 4,
        maxLength: FootController.maxTextLength,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        onChanged: (_) => c.markDirty(),
      );

  Widget _readOnly(String label, String value, String key) => CustomTextField(
        key: ValueKey(key),
        label: label,
        controller: TextEditingController(text: value),
        enabled: false,
      );
}
