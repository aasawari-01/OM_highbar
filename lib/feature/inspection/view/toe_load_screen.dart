import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_section.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/toe_load_controller.dart';
import '../model/toe_load.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_form_widgets.dart';

/// Toe Load Testing inspection (web: ToeLoadTesting.jsx).
class ToeLoadScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;

  const ToeLoadScreen({super.key, required this.inspectionId});

  @override
  State<ToeLoadScreen> createState() => _ToeLoadScreenState();
}

class _ToeLoadScreenState extends State<ToeLoadScreen> {
  late final ToeLoadController c;

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<ToeLoadController>(tag: tag);
    c = Get.put(ToeLoadController(widget.inspectionId), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<ToeLoadController>(tag: widget.inspectionId);
    super.dispose();
  }

  // --------------------------------------------------------------- actions

  void _commitRow() {
    final issue = c.editIndex.value == null ? c.addEntry() : c.saveEdit();
    if (issue != null) showInspectionSnack(issue, title: 'Validation Error');
  }

  Future<void> _submit() async {
    if (c.saving.value) return;
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
        title: 'Toe Load',
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
          if (enabled) _entryForm(),
          CustSection(
            title: 'Toe Load (kgf)',
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

  Widget _entryForm() {
    final editing = c.editIndex.value != null;
    Widget gap() => const SizedBox(height: AppConstants.elementSpacing);
    return CustSection(
      title: editing ? 'Edit Reading' : 'Add Reading',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text('Reach *', 'Enter Reach', c.reach),
          gap(),
          _text('Pier No / Ring No *', 'Enter Pier No / Ring No', c.pierNo),
          gap(),
          _text('Plinth No *', 'Enter Plinth No', c.plinthNo),
          gap(),
          _number('LHS Rail Seat On Non Gauge Side', c.lhsNonGauge),
          gap(),
          _number('LHS Rail Seat On Gauge Side', c.lhsGauge),
          gap(),
          _readOnly('LHS Rail Seat Total', c.lhsTotal.value, 'lhs-${c.lhsTotal.value}'),
          gap(),
          _number('RHS Rail Seat On Non Gauge Side', c.rhsNonGauge),
          gap(),
          _number('RHS Rail Seat On Gauge Side', c.rhsGauge),
          gap(),
          _readOnly('RHS Rail Seat Total', c.rhsTotal.value, 'rhs-${c.rhsTotal.value}'),
          gap(),
          _text('Base Plate Number', 'Enter Base Plate Number', c.basePlate),
          gap(),
          CustomTextField(
            label: 'Remark',
            hintText: 'Enter remark',
            controller: c.remark,
            maxLines: 4,
            maxLength: ToeLoadController.maxRemarkLength,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => c.markDirty(),
          ),
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
                name: editing ? 'Save' : 'Add',
                size: double.infinity,
                sHeight: AppConstants.buttonHeight,
                borderRadius: AppConstants.inputRadius,
                onSelected: (_) => _commitRow(),
              ),
            ),
          ]),
        ],
      ),
    );
  }


  Widget _rowCard(int i, ToeRow r, bool enabled) => InspectionItemCard(
        head: MapEntry('Reach:', r.reach),
        left: [
          MapEntry('Pier No / Ring No', r.pierNo),
          MapEntry('LHS Non-Gauge Side', r.lhsNonGauge),
          MapEntry('LHS Gauge Side', r.lhsGauge),
          MapEntry('LHS Total', r.lhsTotal),
          MapEntry('Base Plate Number', r.basePlateNumber),
        ],
        right: [
          MapEntry('Plinth No', r.plinthNo),
          MapEntry('RHS Non-Gauge Side', r.rhsNonGauge),
          MapEntry('RHS Gauge Side', r.rhsGauge),
          MapEntry('RHS Total', r.rhsTotal),
          MapEntry('Remarks', r.remark),
        ],
        onEdit: enabled ? () => c.editRow(i) : null,
        onDelete: enabled ? () => c.deleteRow(i) : null,
      );
  Widget _text(String label, String hint, TextEditingController ctrl) => CustomTextField(
        label: label,
        hintText: hint,
        controller: ctrl,
        onChanged: (_) => c.markDirty(),
      );

  Widget _number(String label, TextEditingController ctrl) => CustomTextField(
        label: label,
        hintText: label,
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        onChanged: (_) => c.recalc(),
      );

  Widget _readOnly(String label, String value, String key) => CustomTextField(
        key: ValueKey(key),
        label: label,
        controller: TextEditingController(text: value),
        enabled: false,
      );
}
