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
import '../controller/buffer_stop_controller.dart';
import '../model/buffer_stop.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_form_widgets.dart';

/// Buffer Stop inspection (web: BufferStop.jsx).
class BufferStopScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;

  const BufferStopScreen({super.key, required this.inspectionId});

  @override
  State<BufferStopScreen> createState() => _BufferStopScreenState();
}

class _BufferStopScreenState extends State<BufferStopScreen> {
  late final BufferStopController c;

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<BufferStopController>(tag: tag);
    c = Get.put(BufferStopController(widget.inspectionId), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<BufferStopController>(tag: widget.inspectionId);
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
        title: 'Buffer Stop',
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
          CustSection(
            title: 'Inspection Details',
            child: Column(
              children: [
                InspectionOptionDropdown(
                  label: 'Month *',
                  options: bufferMonthOptions,
                  selected: c.selectedMonth.value,
                  enabled: enabled,
                  onChanged: c.selectMonth,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                InspectionOptionDropdown(
                  label: 'KMPH *',
                  options: bufferKmphOptions,
                  selected: c.selectedKmph.value,
                  enabled: enabled,
                  onChanged: c.selectKmph,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                _readOnly('Date *', date, 'date'),
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
                const SizedBox(height: AppConstants.elementSpacing),
                InspectionOptionDropdown(
                  label: 'Line (Up / Down) *',
                  options: c.lineTypes,
                  selected: c.selectedLineType.value,
                  enabled: enabled,
                  onChanged: c.selectLineType,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                InspectionOptionDropdown(
                  label: 'Chainage *',
                  options: c.chainages,
                  selected: c.selectedChainage.value,
                  enabled: enabled,
                  onChanged: c.selectChainage,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                _readOnly('Person Responsible *', c.personName.value, 'person'),
                // Header fields are read-only here (same as the web page).
                for (final f in c.headerFields) ...[
                  const SizedBox(height: AppConstants.elementSpacing),
                  _readOnly((f['fieldName'] ?? f['fieldLabel'] ?? 'Field').toString(),
                      c.headerValue(f), 'hdr-${f['fieldID']}'),
                ],
              ],
            ),
          ),
          _checklistSection(),
          CustSection(
            title: 'Remark',
            child: CustomTextField(
              hintText: 'Enter remark',
              controller: c.remark,
              enabled: enabled,
              maxLines: 4,
              maxLength: BufferStopController.maxRemarkLength,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => c.markDirty(),
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

  Widget _checklistSection() {
    final month = c.selectedMonth.value;
    final kmph = c.selectedKmph.value;
    if (month == null || kmph == null) {
      return CustSection(
        title: 'Checklist',
        child: CustText(
          name: 'Select Month and KMPH to see the checklist.',
          size: AppConstants.detailLabelSize,
          color: AppColors.textDarkSecondary,
        ),
      );
    }
    final checklist = c.checklist;
    if (checklist == null) {
      return CustSection(
        title: 'Checklist',
        child: CustText(
          name: 'The checklist for this Month and KMPH is not available for your business area yet.',
          size: AppConstants.detailLabelSize,
          color: AppColors.textDarkSecondary,
        ),
      );
    }
    final editable = c.editable;
    return CustSection(
      title: checklist.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < checklist.rows.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: AppConstants.subElementSpacing),
              const Divider(color: AppColors.dividerColor3, height: 1),
              const SizedBox(height: AppConstants.subElementSpacing),
            ],
            _checkRow(checklist, checklist.rows[i], month, kmph, editable),
          ],
        ],
      ),
    );
  }

  Widget _checkRow(
      BufferChecklist checklist, BufferCheckRow row, String month, String kmph, bool editable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: '${row.srNo}. ${row.checkPoint}',
          size: AppConstants.textSize,
          fontWeightName: FontWeight.w600,
          color: AppColors.black,
        ),
        if (row.standardValue.isNotEmpty) ...[
          const SizedBox(height: 4),
          CustText(
            name: 'Standard Value: ${row.standardValue}',
            size: AppConstants.detailLabelSize,
            color: AppColors.textDarkSecondary,
          ),
        ],
        for (final col in checklist.columns) ...[
          const SizedBox(height: AppConstants.subElementSpacing),
          CustText.formLabel(col.heading),
          const SizedBox(height: AppConstants.labelSpacing),
          _cellField(row.srNo, col, month, kmph, editable),
        ],
      ],
    );
  }

  Widget _cellField(String srNo, BufferColumn col, String month, String kmph, bool editable) {
    return TextFormField(
      // The key restarts the field when another Month / KMPH table is shown.
      key: ValueKey('cell-$month-$kmph-$srNo-${col.key}'),
      initialValue: c.cellValue(srNo, col.key),
      enabled: editable,
      maxLength: BufferStopController.maxCellLength,
      onChanged: (v) => c.setCell(srNo, col.key, v),
      decoration: InputDecoration(
        hintText: col.hint.isEmpty ? null : col.hint,
        filled: true,
        fillColor: editable ? AppColors.white1 : AppColors.containerColor2,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: BorderSide(color: AppColors.textFieldColor),
        ),
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
