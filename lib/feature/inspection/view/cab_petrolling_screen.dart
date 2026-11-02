import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_section.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/cab_petrolling_controller.dart';
import '../model/cab_petrolling.dart';
import 'widgets/checklist_attachment_section.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_form_widgets.dart';

/// Cab Petrolling Action inspection (web: CabPetrollingAction.jsx).
class CabPetrollingScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;

  const CabPetrollingScreen({super.key, required this.inspectionId});

  @override
  State<CabPetrollingScreen> createState() => _CabPetrollingScreenState();
}

class _CabPetrollingScreenState extends State<CabPetrollingScreen> {
  late final CabPetrollingController c;

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<CabPetrollingController>(tag: tag);
    c = Get.put(CabPetrollingController(widget.inspectionId), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<CabPetrollingController>(tag: widget.inspectionId);
    super.dispose();
  }

  // --------------------------------------------------------------- actions

  Future<void> _selectLine(String? value) async {
    final loaded = await c.selectLine(value);
    if (!loaded) showInspectionSnack('Unable to load locations');
  }

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
        title: 'Cab Petrolling Action',
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
    final saved = c.view.value;
    if (c.readOnly.value && saved != null) return _viewBody(saved);
    final date = c.inspectionDate.value;
    final enabled = c.editable;
    final word = c.locationWord.value;
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
                _readOnly('Date *', date, 'date'),
                for (final f in c.headerFields) ...[
                  const SizedBox(height: AppConstants.elementSpacing),
                  _readOnly((f['fieldName'] ?? f['fieldLabel'] ?? 'Field').toString(),
                      c.headerValue(f), 'hdr-${f['fieldID']}'),
                ],
              ],
            ),
          ),
          CustSection(
            title: 'Route Details',
            child: Column(
              children: [
                _lineDropdown(enabled),
                const SizedBox(height: AppConstants.elementSpacing),
                InspectionOptionDropdown(
                  label: 'Line (Up/Down) *',
                  options: c.lineTypes,
                  selected: c.selectedLineType.value,
                  enabled: enabled,
                  onChanged: c.selectLineType,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                InspectionOptionDropdown(
                  label: 'From $word *',
                  options: c.locations,
                  selected: c.selectedFrom.value,
                  enabled: enabled && !c.locationsLoading.value,
                  onChanged: c.selectFrom,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                InspectionOptionDropdown(
                  label: 'To $word *',
                  options: c.locations,
                  selected: c.selectedTo.value,
                  enabled: enabled && !c.locationsLoading.value,
                  onChanged: c.selectTo,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustomTextField(
                  label: 'Train No *',
                  hintText: 'Train No',
                  controller: c.trainNo,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: enabled ? [FilteringTextInputFormatter.digitsOnly] : null,
                  onChanged: (_) => c.markDirty(),
                ),
              ],
            ),
          ),
          CustSection(
            title: 'Checklist',
            child: Column(
              children: [
                for (var i = 0; i < cabChecklistRows.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: AppConstants.subElementSpacing),
                    const Divider(color: AppColors.dividerColor3, height: 1),
                    const SizedBox(height: AppConstants.subElementSpacing),
                  ],
                  _checklistRow(cabChecklistRows[i], enabled),
                ],
              ],
            ),
          ),
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
                  maxLength: CabPetrollingController.maxTextLength,
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

  Widget _lineDropdown(bool enabled) {
    final selected =
        c.lines.where((l) => l.value == c.selectedLine.value).map((l) => l.label).firstOrNull;
    return CustDropdown(
      label: 'Line *',
      hint: 'Select',
      enabled: enabled,
      items: c.lines.map((l) => l.label).toList(),
      selectedValue: selected,
      onChanged: (label) => _selectLine(c.lines.where((l) => l.label == label).map((l) => l.value).firstOrNull),
    );
  }

  Widget _checklistRow(CabChecklistRow row, bool enabled) {
    final answer = c.status[row.statusKey] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: '${row.sr}. ${row.label}',
          size: AppConstants.textSize,
          fontWeightName: FontWeight.w600,
          color: AppColors.black,
        ),
        const SizedBox(height: AppConstants.subElementSpacing),
        Row(children: [
          InspectionChoice(
            label: 'No',
            selected: answer == '0',
            enabled: enabled,
            onTap: () => c.setStatus(row.statusKey, '0'),
          ),
          const SizedBox(width: AppConstants.subElementSpacing),
          InspectionChoice(
            label: 'Yes',
            selected: answer == '1',
            enabled: enabled,
            onTap: () => c.setStatus(row.statusKey, '1'),
          ),
        ]),
        const SizedBox(height: AppConstants.subElementSpacing),
        CustomTextField(
          hintText: 'Observation',
          controller: c.observations[row.observationKey]!,
          enabled: enabled,
          maxLength: CabPetrollingController.maxTextLength,
          onChanged: (_) => c.markDirty(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- view mode

extension _CabViewMode on _CabPetrollingScreenState {
  /// Read-only record from `GetCabPetrollingView` (web: CabPetrollingActionView).
  Widget _viewBody(CabViewData v) {
    final word = c.locationWord.value;
    String dash(String s) => s.isEmpty ? '-' : s;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
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
                      for (final f in c.headerFields) ...[
                        _readOnly((f['fieldName'] ?? f['fieldLabel'] ?? 'Field').toString(),
                            c.headerValue(f), 'hdr-${f['fieldID']}'),
                        const SizedBox(height: AppConstants.elementSpacing),
                      ],
                      _readOnly('Date *', c.inspectionDate.value, 'date'),
                      const SizedBox(height: AppConstants.elementSpacing),
                      _readOnly('Line *', v.line, 'v-line'),
                      const SizedBox(height: AppConstants.elementSpacing),
                      _readOnly('Line (Up/Down) *', v.lineType, 'v-type'),
                      const SizedBox(height: AppConstants.elementSpacing),
                      _readOnly('From $word *', v.fromLocation, 'v-from'),
                      const SizedBox(height: AppConstants.elementSpacing),
                      _readOnly('To $word *', v.toLocation, 'v-to'),
                      const SizedBox(height: AppConstants.elementSpacing),
                      _readOnly('Train No *', v.trainNo, 'v-train'),
                    ],
                  ),
                ),
                CustSection(
                  title: 'Checklist',
                  child: Column(
                    children: [
                      for (var i = 0; i < cabChecklistRows.length; i++) ...[
                        if (i > 0) ...[
                          const SizedBox(height: AppConstants.subElementSpacing),
                          const Divider(color: AppColors.dividerColor3, height: 1),
                          const SizedBox(height: AppConstants.subElementSpacing),
                        ],
                        _viewRow(cabChecklistRows[i], v),
                      ],
                    ],
                  ),
                ),
                CustSection(
                  title: 'Remark',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustText.detailValue(dash(v.remark)),
                      if (v.filePath.isNotEmpty) ...[
                        const SizedBox(height: AppConstants.elementSpacing),
                        CustText.formLabel('Attachment'),
                        const SizedBox(height: AppConstants.labelSpacing),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                          child: Image.network(
                            _fileUrl(v.filePath),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => CustText.detailValue('Attachment unavailable'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: InspectionActionBar(
            viewMode: true,
            saving: false,
            onBack: _onBack,
            actions: const [],
          ),
        ),
      ],
    );
  }

  Widget _viewRow(CabChecklistRow row, CabViewData v) {
    final status = v.answers[row.statusKey] ?? '';
    final answer = status == 'True' ? 'Yes' : (status == 'False' ? 'No' : '-');
    final observation = v.answers[row.observationKey] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: '${row.sr}. ${row.label}',
          size: AppConstants.textSize,
          fontWeightName: FontWeight.w600,
          color: AppColors.black,
        ),
        const SizedBox(height: AppConstants.subElementSpacing),
        Row(children: [
          InspectionChoice(label: 'No', selected: answer == 'No', enabled: false, onTap: () {}),
          const SizedBox(width: AppConstants.subElementSpacing),
          InspectionChoice(label: 'Yes', selected: answer == 'Yes', enabled: false, onTap: () {}),
        ]),
        if (observation.isNotEmpty) ...[
          const SizedBox(height: AppConstants.subElementSpacing),
          CustText.detailValue(observation),
        ],
      ],
    );
  }

  /// Uploaded files live on the server root, next to the `api/` path.
  String _fileUrl(String path) {
    final root = AppUrls.baseUrl.replaceFirst(RegExp(r'api/?$'), '');
    return '$root${path.replaceFirst(RegExp(r'^/+'), '')}';
  }
}
