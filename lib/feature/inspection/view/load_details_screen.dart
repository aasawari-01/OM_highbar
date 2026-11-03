import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_section.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/load_details_controller.dart';
import '../model/load_details.dart';
import 'widgets/inspection_dialogs.dart';
import 'widgets/inspection_form_widgets.dart';

/// Load Details inspection (web: LoadDetails.jsx): MDB readings added row by row.
class LoadDetailsScreen extends StatefulWidget {
  /// `jeInspectionId` from the JE inspection list.
  final String inspectionId;

  const LoadDetailsScreen({super.key, required this.inspectionId});

  @override
  State<LoadDetailsScreen> createState() => _LoadDetailsScreenState();
}

class _LoadDetailsScreenState extends State<LoadDetailsScreen> {
  // Whole-number readings: up to 10 digits. pf: up to 5 digits and 2 decimals.
  static final _wholeNumber = RegExp(r'^\d{0,10}$');
  static final _decimalNumber = RegExp(r'^\d{0,5}(\.\d{0,2})?$');

  // Readings before this index (MD, Demand) form the first card; the rest the second.
  static const _split = 6;

  late final LoadDetailsController c;

  @override
  void initState() {
    super.initState();
    final tag = widget.inspectionId;
    Get.delete<LoadDetailsController>(tag: tag);
    c = Get.put(LoadDetailsController(widget.inspectionId), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<LoadDetailsController>(tag: widget.inspectionId);
    super.dispose();
  }

  // --------------------------------------------------------------- actions

  void _addRow() {
    final issue = c.validateRow();
    if (issue != null) {
      showInspectionSnack(issue, title: 'Validation Error');
      return;
    }
    c.addRow();
  }

  Future<void> _deleteRow(int index) async {
    final ok = await showInspectionConfirm(
      'Delete Record',
      'Do you want to delete this record?',
    );
    if (ok) c.removeRow(index);
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
        title: 'Load Details',
        showDrawer: false,
        onLeadingPressed: _onBack,
        actions: const [SizedBox(width: 16)],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
    // The form scrolls; Back / Submit stay pinned at the bottom of the screen.
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
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
                        _readOnly((f['fieldName'] ?? f['fieldLabel'] ?? 'Field').toString(),
                            c.headerValue(f), 'hdr-${f['fieldID']}'),
                        const SizedBox(height: AppConstants.elementSpacing),
                      ],
                      // The web view page doesn't repeat the date in the card.
                      if (c.editable) _readOnly('Date Time *', date, 'date'),
                    ],
                  ),
                ),
                if (c.editable) _addRowSection(),
                if (c.rows.isNotEmpty) _rowsSection(),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Obx(() => InspectionActionBar(
                viewMode: c.readOnly.value,
                saving: c.saving.value,
                onBack: _onBack,
                actions: [InspectionAction('Submit', _submit)],
              )),
        ),
      ],
    );
  }

  Widget _addRowSection() {
    final type = c.selectedMdbType.value;
    // Drop only a bare "Select" placeholder, and only when real types remain.
    final all = c.mdbTypes.toList();
    final real = all.where((o) => o.label.trim().toLowerCase() != 'select').toList();
    final options = real.isEmpty ? all : real;
    final selectedLabel = options.where((o) => o.value == type).map((o) => o.label).firstOrNull;
    // Like the web: MD and Demand readings in one card, Line Current and the
    // other readings (pf, kWH, kVAh) in a second card that holds the Add button.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustSection(
          title: 'Add MDB Reading',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustDropdown(
                label: 'MDB Type *',
                hint: 'Select',
                items: options.map((o) => o.label).toList(),
                selectedValue: selectedLabel,
                onChanged: (label) => c.selectMdbType(
                    options.where((o) => o.label == label).map((o) => o.value).firstOrNull),
              ),
              if (options.isEmpty) ...[
                const SizedBox(height: AppConstants.subElementSpacing),
                CustText(
                  name: 'No MDB types were returned by the server.',
                  size: AppConstants.detailLabelSize,
                  color: AppColors.red,
                ),
              ],
              if (type != null)
                for (final f in loadReadingFields.take(_split)) ...[
                  const SizedBox(height: AppConstants.elementSpacing),
                  _reading(f),
                ],
            ],
          ),
        ),
        if (type != null)
          CustSection(
            title: 'Line Current & Other Readings',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final f in loadReadingFields.skip(_split)) ...[
                  _reading(f),
                  const SizedBox(height: AppConstants.elementSpacing),
                ],
                CustButton(
                  name: 'Add',
                  size: double.infinity,
                  sHeight: AppConstants.buttonHeight,
                  borderRadius: AppConstants.inputRadius,
                  onSelected: (_) => _addRow(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _reading(LoadReadingField f) {
    return CustomTextField(
      label: f.label,
      hintText: 'Enter Reading',
      controller: c.inputs[f.payloadKey]!,
      keyboardType: TextInputType.numberWithOptions(decimal: f.decimal),
      inputFormatters: [_formatterFor(f)],
      onChanged: (_) => c.markDirty(),
    );
  }

  /// Rejects any edit that would break the web's digit rules.
  TextInputFormatter _formatterFor(LoadReadingField f) {
    final pattern = f.decimal ? _decimalNumber : _wholeNumber;
    return TextInputFormatter.withFunction(
      (oldValue, newValue) => pattern.hasMatch(newValue.text) ? newValue : oldValue,
    );
  }

  Widget _rowsSection() {
    // View mode (Complete / Closed) shows two tables like the web view page:
    // MD and Demand readings, then Line Current and the other readings.
    if (!c.editable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowsCard('Load Details', loadReadingFields.take(_split)),
          _rowsCard('Line Current & Other Readings', loadReadingFields.skip(_split)),
        ],
      );
    }
    return _rowsCard('MDB Readings (${c.rows.length})', loadReadingFields);
  }

  Widget _rowsCard(String title, Iterable<LoadReadingField> fields) {
    return CustSection(
      title: title,
      child: Column(
        children: [
          for (var i = 0; i < c.rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppConstants.elementSpacing),
            _rowCard(i, c.rows[i], fields),
          ],
        ],
      ),
    );
  }


  Widget _rowCard(int index, LoadRow row, Iterable<LoadReadingField> fields) {
    final entries = [
      for (final f in fields) MapEntry(f.label, row.readings[f.payloadKey] ?? ''),
    ];
    final half = (entries.length + 1) ~/ 2;
    return InspectionItemCard(
      head: MapEntry('MDB Type:', c.mdbLabel(row.mdbType)),
      left: entries.take(half).toList(),
      right: entries.skip(half).toList(),
      onDelete: c.editable ? () => _deleteRow(index) : null,
    );
  }
  Widget _readOnly(String label, String value, String key) => CustomTextField(
        key: ValueKey(key),
        label: label,
        controller: TextEditingController(text: value),
        enabled: false,
      );
}
