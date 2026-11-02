import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_date_time_picker.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_section.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/pilot_train_controller.dart';
import 'widgets/checklist_attachment_section.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_form_widgets.dart';

/// Pilot Train inspection (web: PilotTrainInspection.jsx).
class PilotTrainScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;

  const PilotTrainScreen({super.key, required this.inspectionId});

  @override
  State<PilotTrainScreen> createState() => _PilotTrainScreenState();
}

class _PilotTrainScreenState extends State<PilotTrainScreen> {
  static const _declaration =
      'We designated MAHA-Metro personnel have done the cab piloting of the '
      'below-mentioned section upon verification & confirmation, it is certified '
      'that the mentioned section is clear & free from any infringement (i.e., men, '
      'machine, and materials of different contractors including MAHA-Metro '
      'personnel, are withdrawn from the section.) and the section is now for '
      'carrying out train movement.';

  late final PilotTrainController c;

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<PilotTrainController>(tag: tag);
    c = Get.put(PilotTrainController(widget.inspectionId), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<PilotTrainController>(tag: widget.inspectionId);
    super.dispose();
  }

  // --------------------------------------------------------------- actions

  Future<void> _pickAttachment() async {
    final error = await c.pickAttachment();
    if (error != null) showInspectionSnack(error);
  }

  Future<void> _submit() async {
    if (c.saving.value) return;
    final issue = c.validate();
    if (issue != null) {
      showInspectionSnack(issue, title: 'Validation Error');
      return;
    }
    final confirmed = await showInspectionConfirm('Submit', 'Do you want to submit?');
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
        title: 'Pilot Train Inspection',
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

  /// The API sends dd/MM/yyyy; this screen shows MM/dd/yyyy.
  static String _mmddyyyy(String d) {
    final p = d.split('/');
    if (p.length != 3) return d;
    return '${p[1]}/${p[0]}/${p[2]}';
  }

  Widget _body() {
    final date = _mmddyyyy(c.inspectionDate.value);
    final enabled = c.editable;
    final extended = c.extended.value;
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
                  const SizedBox(height: AppConstants.elementSpacing),
                  _readOnly((f['fieldName'] ?? f['fieldLabel'] ?? 'Field').toString(),
                      c.headerValue(f), 'hdr-${f['fieldID']}'),
                ],
                const SizedBox(height: AppConstants.elementSpacing),
                CustDateTimePicker(
                  label: 'Time *',
                  hint: 'HH:mm',
                  pickerType: PickerType.time,
                  use24Hour: true,
                  enabled: enabled,
                  selectedDateTime: c.time.value,
                  onDateTimeSelected: c.setTime,
                ),
                if (extended) ...[
                  const SizedBox(height: AppConstants.elementSpacing),
                  InspectionOptionDropdown(
                    label: 'Trainset',
                    options: c.trainSets,
                    selected: c.selectedTrainSet.value,
                    enabled: enabled,
                    onChanged: c.selectTrainSet,
                  ),
                ],
              ],
            ),
          ),
          if (extended)
            CustSection(
              title: 'Remark',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    hintText: 'Enter remark',
                    controller: c.remark,
                    enabled: enabled,
                    maxLines: 4,
                    maxLength: PilotTrainController.maxRemarkLength,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onChanged: (_) => c.markDirty(),
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  ChecklistAttachmentSection(
                    isViewMode: !enabled,
                    existingAttachments: const [],
                    newAttachment: c.attachment.value,
                    onAdd: _pickAttachment,
                    onRemoveExisting: (_) {},
                    onRemoveNew: c.removeAttachment,
                  ),
                ],
              ),
            ),
          CustSection(
            title: 'Declaration *',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: c.declared.value,
                  onChanged: enabled ? (v) => c.setDeclared(v ?? false) : null,
                  activeColor: AppColors.orangeColor,
                  checkColor: AppColors.white1,
                  side: const BorderSide(color: AppColors.orangeColor, width: 1.5),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: CustText(
                      name: _declaration,
                      size: AppConstants.detailLabelSize,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(() => InspectionActionBar(
                viewMode: c.readOnly.value,
                saving: c.saving.value,
                onBack: _onBack,
                actions: [InspectionAction('Submit', _submit)],
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
}
