import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_section.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/oms_controller.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_form_widgets.dart';

/// OMS Action inspection (web: OMSAction.jsx).
class OmsActionScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;

  const OmsActionScreen({super.key, required this.inspectionId});

  @override
  State<OmsActionScreen> createState() => _OmsActionScreenState();
}

class _OmsActionScreenState extends State<OmsActionScreen> {
  late final OmsController c;

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<OmsController>(tag: tag);
    c = Get.put(OmsController(widget.inspectionId), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<OmsController>(tag: widget.inspectionId);
    super.dispose();
  }

  // --------------------------------------------------------------- actions

  Future<void> _addFiles(RxList<File> target) async {
    final error = await c.addFiles(target);
    if (error != null) showInspectionSnack(error);
  }

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
        update ? 'Do you want to Update OMS Action Inspection?' : 'Do you want to submit?');
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
        title: 'OMS',
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
                // Header fields (line, line type, ...) are read-only, same as the web page.
                for (final f in c.headerFields) ...[
                  gap(),
                  _readOnly((f['fieldName'] ?? f['fieldLabel'] ?? 'Field').toString(),
                      c.headerValue(f), 'hdr-${f['fieldID']}'),
                ],
                gap(),
                _number('From KM *', c.fromKm, enabled),
                gap(),
                _number('To KM *', c.toKm, enabled),
                gap(),
                InspectionOptionDropdown(
                  label: 'Train No *',
                  options: c.trainNos,
                  selected: c.selectedTrainNo.value,
                  enabled: enabled,
                  onChanged: c.selectTrainNo,
                ),
                gap(),
                _text('Run No *', c.runNo, enabled),
                gap(),
                _text('Maximum RI *', c.maxRi, enabled),
                gap(),
                _text('Location of Max RI *', c.maxRiLocation, enabled),
                gap(),
                CustomTextField(
                  label: 'Summary *',
                  hintText: 'Enter summary',
                  controller: c.summary,
                  enabled: enabled,
                  maxLines: 4,
                  maxLength: OmsController.maxSummaryLength,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => c.markDirty(),
                ),
              ],
            ),
          ),
          CustSection(
            title: 'Attachment RI',
            child: _attachments(c.riFiles, enabled),
          ),
          CustSection(
            title: 'Attachment of Acceleration Pack (g)',
            child: _attachments(c.accFiles, enabled),
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

  Widget _attachments(RxList<File> files, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: 'Only JPG, JPEG, PNG, PDF, TXT - max 1MB each, up to ${OmsController.maxFiles} files',
          size: AppConstants.detailLabelSize,
          color: AppColors.textDarkSecondary,
        ),
        if (enabled)
          TextButton.icon(
            onPressed: () => _addFiles(files),
            icon: const Icon(Icons.upload_file),
            label: const Text('Add files'),
          ),
        for (var i = 0; i < files.length; i++)
          Row(children: [
            const Icon(Icons.attach_file, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: CustText(
                name: files[i].path.split(RegExp(r'[\\/]')).last,
                size: AppConstants.detailLabelSize,
                color: AppColors.black,
              ),
            ),
            if (enabled)
              IconButton(icon: const Icon(Icons.close), onPressed: () => c.removeFile(files, i)),
          ]),
      ],
    );
  }

  Widget _number(String label, TextEditingController ctrl, bool enabled) => CustomTextField(
        label: label,
        hintText: label.replaceAll(' *', ''),
        controller: ctrl,
        enabled: enabled,
        maxLength: OmsController.maxKmLength,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => c.markDirty(),
      );

  Widget _text(String label, TextEditingController ctrl, bool enabled) => CustomTextField(
        label: label,
        hintText: label.replaceAll(' *', ''),
        controller: ctrl,
        enabled: enabled,
        maxLength: OmsController.maxTextLength,
        onChanged: (_) => c.markDirty(),
      );

  Widget _readOnly(String label, String value, String key) => CustomTextField(
        key: ValueKey(key),
        label: label,
        controller: TextEditingController(text: value),
        enabled: false,
      );
}
