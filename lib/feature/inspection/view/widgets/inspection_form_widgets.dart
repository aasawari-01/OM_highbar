import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/widgets/cust_button.dart';
import '../../../../utils/widgets/cust_dropdown.dart';
import '../../../../utils/widgets/cust_text.dart';
import '../../model/api_helpers.dart';

/// Inspection date and number line shown at the top of every inspection form.
class InspectionInfoHeader extends StatelessWidget {
  final String name;
  final String date;
  final String number;

  const InspectionInfoHeader(
      {super.key,
      required this.name,
      required this.date,
      required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name.isNotEmpty) ...[
            CustText(
              name: name,
              size: AppConstants.headerSize,
              color: AppColors.black,
              fontWeightName: FontWeight.w700,
            ),
            const SizedBox(height: AppConstants.labelSpacing),
          ],
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustText.formLabel("Inspection No : "),
                    CustText.detailValue(number.isEmpty ? '-' : number)
                  ],),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  CustText.formLabel("Inspection Date : "),
                  CustText.detailValue(date.isEmpty ? '-' : date)
                ],),

          ]),
        ],
      ),
    );
  }
}

/// A primary button of [InspectionActionBar].
class InspectionAction {
  final String label;
  final VoidCallback onTap;

  const InspectionAction(this.label, this.onTap);
}

/// Bottom buttons of an inspection form: the actions (hidden in view mode) and Back.
/// One action sits next to Back; several actions share a row above Back.
class InspectionActionBar extends StatelessWidget {
  final bool viewMode;
  final bool saving;
  final List<InspectionAction> actions;
  final VoidCallback onBack;

  const InspectionActionBar({
    super.key,
    required this.viewMode,
    required this.saving,
    required this.actions,
    required this.onBack,
  });

  Widget _primary(InspectionAction a) => CustButton(
        name: saving ? 'Please wait...' : a.label,
        size: double.infinity,
        sHeight: AppConstants.buttonHeight,
        borderRadius: AppConstants.inputRadius,
        color1: saving ? Colors.grey : null,
        color2: saving ? Colors.grey : null,
        onSelected: saving ? null : (_) => a.onTap(),
      );

  Widget get _back => CustOutlineButton(
        name: 'Back',
        size: double.infinity,
        sHeight: AppConstants.buttonHeight,
        borderRadius: AppConstants.inputRadius,
        onSelected: (_) => onBack(),
      );

  @override
  Widget build(BuildContext context) {
    final shown = viewMode ? const <InspectionAction>[] : actions;
    final Widget content;
    if (shown.length == 1) {
      content = Row(children: [
        Expanded(child: _back),
        const SizedBox(width: AppConstants.elementSpacing),
        Expanded(child: _primary(shown.first)),
      ]);
    } else {
      content = Column(children: [
        if (shown.isNotEmpty) ...[
          Row(children: [
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) const SizedBox(width: AppConstants.elementSpacing),
              Expanded(child: _primary(shown[i])),
            ],
          ]),
          const SizedBox(height: AppConstants.elementSpacing),
        ],
        _back,
      ]);
    }
    return Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: content);
  }
}

/// A selectable pill (e.g. No / Yes) styled like the checklist's action buttons.
class InspectionChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const InspectionChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 90,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.orangeColor : AppColors.white1,
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          border: Border.all(
            color: selected
                ? AppColors.orangeColor
                : (enabled ? AppColors.textDarkPrimary : AppColors.textFieldColor),
          ),
        ),
        child: CustText(
          name: label,
          size: 14,
          color: selected
              ? AppColors.white1
              : (enabled ? AppColors.textDarkPrimary : AppColors.textDarkSecondary),
        ),
      ),
    );
  }
}

/// Drop-down over [SelectOption]s that keeps the chosen option's `value`, not its label.
class InspectionOptionDropdown extends StatelessWidget {
  final String label;
  final List<SelectOption> options;
  final String? selected;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const InspectionOptionDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // The API lists a "Select" placeholder (value 0) first; it is not a choice.
    final real = options.where((o) => o.value.isNotEmpty && o.value != '0').toList();
    final shown = real.where((o) => o.value == selected).map((o) => o.label).firstOrNull;
    return CustDropdown(
      label: label,
      hint: 'Select',
      enabled: enabled,
      items: real.map((o) => o.label).toList(),
      selectedValue: shown,
      onChanged: (l) => onChanged(real.where((o) => o.label == l).map((o) => o.value).firstOrNull),
    );
  }
}

/// Card of one added item (a weld, a reading, a measurement): a headline
/// label/value, two columns of details, and edit / delete icons when editable.
class InspectionItemCard extends StatelessWidget {
  final MapEntry<String, String>? head;
  final List<MapEntry<String, String>> left;
  final List<MapEntry<String, String>> right;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const InspectionItemCard({
    super.key,
    this.head,
    required this.left,
    this.right = const [],
    this.onEdit,
    this.onDelete,
  });

  Widget _pair(MapEntry<String, String> e) => Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.elementSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustText.detailLabel(e.key),
            CustText.detailValue(e.value.trim().isEmpty ? '-' : e.value),
          ],
        ),
      );

  Widget _column(List<MapEntry<String, String>> items) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final e in items) _pair(e)]);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.subElementSpacing),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        border: Border.all(color: AppColors.dividerColor3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (head != null) _pair(head!),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _column(left)),
                    if (right.isNotEmpty) ...[
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(child: _column(right)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
          if (onDelete != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        ],
      ),
    );
  }
}
