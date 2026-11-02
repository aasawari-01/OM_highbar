import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_date_time_picker.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_section.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/temperature_controller.dart';
import '../model/temperature_monitoring.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_form_widgets.dart';

/// Temperature Monitoring inspection (web: TemperatureMonitoring.jsx).
class TemperatureMonitoringScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;

  const TemperatureMonitoringScreen({super.key, required this.inspectionId});

  @override
  State<TemperatureMonitoringScreen> createState() => _TemperatureMonitoringScreenState();
}

class _TemperatureMonitoringScreenState extends State<TemperatureMonitoringScreen> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  late final TemperatureController c;

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<TemperatureController>(tag: tag);
    c = Get.put(TemperatureController(widget.inspectionId), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<TemperatureController>(tag: widget.inspectionId);
    super.dispose();
  }

  // --------------------------------------------------------------- actions

  void _commitRow() {
    final issue = c.commitEntry();
    if (issue != null) showInspectionSnack(issue, title: 'Validation Error');
  }

  void _setToDate(DateTime? v) {
    if (v != null && c.isBeforeFrom(v)) {
      showInspectionSnack('To Date must not be before From Date', title: 'Validation Error');
      return;
    }
    c.setToDate(v);
  }

  Future<void> _uploadExcel() async {
    final picked = await c.pickExcel();
    if (picked.error != null) {
      showInspectionSnack(picked.error!);
      return;
    }
    final file = picked.file;
    if (file == null) return;
    if (!await showInspectionConfirm('Upload', 'Do you want to Upload Data?')) return;
    final result = await c.upload(file);
    if (result.isError) {
      showInspectionSnack(result.message);
    } else {
      showInspectionSuccess(result.message);
    }
  }

  Future<void> _save({required bool submit}) async {
    if (c.saving.value) return;
    final issue = c.validate(submit: submit);
    if (issue != null) {
      showInspectionSnack(issue, title: 'Validation Error');
      return;
    }
    final confirmed = await showInspectionConfirm(
        submit ? 'Submit' : 'Save As Draft',
        submit ? 'Do you want to submit?' : 'Do you want to save as draft?');
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
        title: 'Temperature Monitoring',
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
    Widget gap() => const SizedBox(height: AppConstants.elementSpacing);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InspectionInfoHeader(
            name: c.inspectionName.value,
            date: c.inspectionDate.value,
            number: c.inspectionNo.value,
          ),
          if (c.headerFields.isNotEmpty)
            CustSection(
              title: 'Inspection Details',
              child: Column(
                children: [
                  for (var i = 0; i < c.headerFields.length; i++) ...[
                    if (i > 0) gap(),
                    // Header fields are read-only here (same as the web page).
                    _readOnly(
                        (c.headerFields[i]['fieldName'] ?? c.headerFields[i]['fieldLabel'] ?? 'Field')
                            .toString(),
                        c.headerValue(c.headerFields[i]),
                        'hdr-${c.headerFields[i]['fieldID']}'),
                  ],
                ],
              ),
            ),
          if (enabled)
            CustSection(
              title: c.editIndex.value == null ? 'Add Reading' : 'Edit Reading',
              child: Column(
                children: [
                  CustDateTimePicker(
                    label: 'From Date *',
                    hint: 'DD/MM/YYYY',
                    pickerType: PickerType.date,
                    dateFormat: _dateFormat,
                    selectedDateTime: c.fromDate.value,
                    onDateTimeSelected: c.setFromDate,
                  ),
                  gap(),
                  CustDateTimePicker(
                    label: 'To Date *',
                    hint: 'DD/MM/YYYY',
                    pickerType: PickerType.date,
                    dateFormat: _dateFormat,
                    selectedDateTime: c.toDate.value,
                    firstDate: c.fromDate.value,
                    onDateTimeSelected: _setToDate,
                  ),
                  gap(),
                  CustDateTimePicker(
                    label: 'Time *',
                    hint: 'HH:mm',
                    pickerType: PickerType.time,
                    use24Hour: true,
                    selectedDateTime: c.time.value,
                    onDateTimeSelected: c.setTime,
                  ),
                  gap(),
                  CustomTextField(
                    label: 'Temperature *',
                    hintText: 'Temperature',
                    controller: c.temperature,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => c.markDirty(),
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
                        name: c.editIndex.value != null ? 'Save' : 'Add',
                        size: double.infinity,
                        sHeight: AppConstants.buttonHeight,
                        borderRadius: AppConstants.inputRadius,
                        onSelected: (_) => _commitRow(),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          if (enabled)
            CustSection(
              title: 'Attachment',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustText(
                    name: 'Upload an Excel file (xlsx, xls - max 1MB) to replace the readings below.',
                    size: AppConstants.detailLabelSize,
                    color: AppColors.textDarkSecondary,
                  ),
                  TextButton.icon(
                    onPressed: c.saving.value ? null : _uploadExcel,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Excel'),
                  ),
                ],
              ),
            ),
          CustSection(
            title: 'Readings',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < c.rows.length; i++) ...[
                  _rowCard(i, c.rows[i], enabled),
                  const SizedBox(height: AppConstants.subElementSpacing),
                ],
                if (c.rows.isEmpty)
                  CustText(
                    name: 'No readings added yet.',
                    size: AppConstants.detailLabelSize,
                    color: AppColors.textDarkSecondary,
                  ),
              ],
            ),
          ),
          CustSection(
            title: 'Summary',
            child: Column(
              children: [
                _readOnly('Max Temp', c.formatStat(c.maxTemp), 'max-${c.rows.length}'),
                gap(),
                _readOnly('Mean Temp', c.formatStat(c.meanTemp), 'mean-${c.rows.length}'),
                gap(),
                _readOnly('Min Temp', c.formatStat(c.minTemp), 'min-${c.rows.length}'),
                gap(),
                CustomTextField(
                  label: 'Remark',
                  hintText: 'Enter remark',
                  controller: c.remark,
                  enabled: enabled,
                  maxLines: 4,
                  maxLength: TemperatureController.maxRemarkLength,
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
                  InspectionAction('Save As Draft', () => _save(submit: false)),
                  InspectionAction('Submit', () => _save(submit: true)),
                ],
              )),
        ],
      ),
    );
  }


  Widget _rowCard(int i, TempRow r, bool enabled) => InspectionItemCard(
        head: MapEntry('Time:', r.time),
        left: [MapEntry('From Date', r.fromDate),MapEntry('Temperature', '${r.temperature}')],
        right: [MapEntry('To Date', r.toDate)],
        onEdit: enabled ? () => c.editRow(i) : null,
        onDelete: enabled ? () => c.deleteRow(i) : null,
      );
  Widget _readOnly(String label, String value, String key) => CustomTextField(
        key: ValueKey(key),
        label: label,
        controller: TextEditingController(text: value),
        enabled: false,
      );
}
