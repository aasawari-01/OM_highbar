import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../constants/app_constants.dart';
import 'cust_button.dart';
import 'cust_text.dart';

/// Multi-select counterpart to `CustDropdown`, styled the same way (same
/// label placement, border, hint color, chevron) so it drops into a form
/// next to single-select `CustDropdown` fields without looking different.
///
/// Tapping the field opens a checkbox picker (same interaction as the
/// existing popups in this app, e.g. CreateFailureScreen's Action By /
/// Measurement dialogs). Selected items are shown inside the field itself
/// as comma-separated text (truncated with "+N more" once it gets long),
/// matching how a normal dropdown shows its single selected value — no
/// separate chip row underneath.
class CustMultiDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> items;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;
  final FormFieldValidator<List<String>>? validator;

  const CustMultiDropdown({
    Key? key,
    required this.label,
    required this.hint,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
    this.enabled = true,
    this.validator,
  }) : super(key: key);

  String get _displayText {
    if (selectedValues.isEmpty) return '';
    if (selectedValues.length <= 2) return selectedValues.join(', ');
    return '${selectedValues.take(2).join(', ')} +${selectedValues.length - 2} more';
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: selectedValues,
      validator: validator,
      builder: (formFieldState) {
        // Keep the FormField's error state synced with external changes
        // (e.g. controller clears selection on a parent dropdown change).
        if (formFieldState.value != selectedValues) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            formFieldState.didChange(selectedValues);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustText.formLabel(label),
            const SizedBox(height: AppConstants.labelSpacing),
            GestureDetector(
              onTap: enabled ? () => _openPicker(context, formFieldState) : null,
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.white1
                      : AppColors.textFieldFillColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                  border: Border.all(
                    color: formFieldState.hasError
                        ? Colors.red
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedValues.isEmpty ? hint : _displayText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppConstants.textSize,
                          color: selectedValues.isEmpty
                              ? Colors.grey.shade400
                              : AppColors.black,
                        ),
                      ),
                    ),
                    Icon(TablerIcons.chevron_down,
                        color: enabled ? AppColors.orangeColor : Colors.grey,
                        size: 20),
                  ],
                ),
              ),
            ),
            if (formFieldState.hasError) ...[
              const SizedBox(height: 4),
              Text(
                formFieldState.errorText ?? '',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }

  void _openPicker(BuildContext context, FormFieldState<List<String>> formFieldState) {
    final tempSelected = List<String>.from(selectedValues);

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.white1,
            child: ConstrainedBox(
              constraints:
              BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustText.body(label, fontWeightName: FontWeight.bold),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = tempSelected.contains(item);
                        return CheckboxListTile(
                          value: selected,
                          title: CustText.body(item),
                          activeColor: AppColors.orangeColor,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (_) {
                            setState(() {
                              if (selected) {
                                tempSelected.remove(item);
                              } else {
                                tempSelected.add(item);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: CustButton(
                        name: "Done",
                        size: 120,
                        onSelected: (_) {
                          onChanged(tempSelected);
                          formFieldState.didChange(tempSelected);
                          Get.back();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}