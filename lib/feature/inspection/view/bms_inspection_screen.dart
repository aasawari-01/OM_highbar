import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_section.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/bms_controller.dart';
import '../model/bms_fields.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_form_widgets.dart';

/// BMS inspection (web: BMS.jsx). Meter readings, saved as draft or final submit.
class BmsInspectionScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;
  final bool isView;

  const BmsInspectionScreen(
      {super.key, required this.inspectionId, this.isView = false});

  @override
  State<BmsInspectionScreen> createState() => _BmsInspectionScreenState();
}

class _BmsInspectionScreenState extends State<BmsInspectionScreen> {
  late final BmsController c;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<BmsController>(tag: tag);
    c = Get.put(BmsController(widget.inspectionId, isView: widget.isView),
        tag: tag);
  }

  @override
  void dispose() {
    Get.delete<BmsController>(tag: widget.inspectionId);
    super.dispose();
  }

  // --------------------------------------------------------------- actions

  Future<void> _submit({required bool isDraft}) async {
    if (c.saving.value) return;
    if (!isDraft && !(_formKey.currentState?.validate() ?? false)) return;

    final confirmed = await showInspectionConfirm(
      isDraft ? 'Save as Draft' : 'Submit',
      isDraft ? 'Do you want to save as draft?' : 'Do you want to submit?',
    );
    if (!confirmed) return;

    try {
      final ok = await c.save(isDraft: isDraft);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
        showInspectionSuccess(isDraft
            ? 'Data saved successfully.'
            : 'Data updated successfully.');
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
    // The scaffold is built once; only PopScope listens to `dirty`.
    final scaffold = Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'BMS',
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
    final viewMode = c.isViewMode.value;
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InspectionInfoHeader(
              name: c.inspectionName.value,
              date: c.inspectionDate.value,
              number: c.inspectionNo.value,
            ),
            // Header fields are read-only here (same as the web page).
            if (c.headerFields.isNotEmpty)
              CustSection(
                title: 'Inspection Details',
                child: Column(
                  children: [
                    for (var i = 0; i < c.headerFields.length; i++) ...[
                      if (i > 0)
                        const SizedBox(height: AppConstants.elementSpacing),
                      CustomTextField(
                        key: ValueKey('hdr-${c.headerFields[i]['fieldID']}'),
                        label: (c.headerFields[i]['fieldName'] ??
                                c.headerFields[i]['fieldLabel'] ??
                                'Field')
                            .toString(),
                        controller: TextEditingController(
                            text: c.headerValue(c.headerFields[i])),
                        enabled: false,
                      ),
                    ],
                  ],
                ),
              ),
            for (final s in bmsSections) _sectionCard(s, enabled: !viewMode),
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
      ),
    );
  }

  Widget _sectionCard(BmsSection section, {required bool enabled}) {
    return CustSection(
      title: section.title,
      child: Column(children: [
        for (var i = 0; i < section.fields.length; i++) ...[
          if (i > 0) const SizedBox(height: AppConstants.elementSpacing),
          _numberField(section.fields[i], enabled: enabled),
        ],
      ]),
    );
  }

  Widget _numberField(BmsField f, {required bool enabled}) {
    return CustomTextField(
      label: f.required ? '${f.label} *' : f.label,
      hintText: 'Enter value',
      controller: c.inputs[f.payloadKey]!,
      enabled: enabled,
      maxLength: 10,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // Digits with up to 2 decimals (web: /^[0-9]*(\.[0-9]{0,2})?$/).
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*(\.[0-9]{0,2})?$'))
      ],
      onChanged: (_) => c.markDirty(),
      validator: f.required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'Please enter ${f.label}' : null
          : null,
    );
  }
}
