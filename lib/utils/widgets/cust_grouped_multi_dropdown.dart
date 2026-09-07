import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../constants/app_constants.dart';
import 'cust_button.dart';
import 'cust_text.dart';

class GroupedDropdownItem {
  final String value;
  final String? badge;

  const GroupedDropdownItem(this.value, {this.badge});
}

class GroupedDropdownSection {
  final String title;
  final List<GroupedDropdownItem> items;

  const GroupedDropdownSection({required this.title, required this.items});
}

/// Same look-and-feel as `CustMultiDropdown`, but the picker groups items
/// under section headers (e.g. stations grouped by Line, systems grouped
/// by Department) and can show a small badge per item (e.g. station type).
class CustGroupedMultiDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final List<GroupedDropdownSection> sections;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;
  final FormFieldValidator<List<String>>? validator;

  const CustGroupedMultiDropdown({
    Key? key,
    required this.label,
    required this.hint,
    required this.sections,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.white1
                      : AppColors.textFieldFillColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                  border: Border.all(
                    color: formFieldState.hasError ? Colors.red : Colors.grey.shade300,
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
                        color: enabled ? AppColors.orangeColor : Colors.grey, size: 20),
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
              BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
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
                      itemCount: sections.length,
                      itemBuilder: (context, sectionIndex) {
                        final section = sections[sectionIndex];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: CustText(
                                name: section.title,
                                size: 12,
                                fontWeightName: FontWeight.w700,
                                color: AppColors.orangeColor,
                              ),
                            ),
                            ...section.items.map((item) {
                              final selected = tempSelected.contains(item.value);
                              return CheckboxListTile(
                                value: selected,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: AppColors.orangeColor,
                                title: CustText.body(item.value),
                                subtitle: item.badge == null
                                    ? null
                                    : Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.badge!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                                onChanged: (_) {
                                  setState(() {
                                    if (selected) {
                                      tempSelected.remove(item.value);
                                    } else {
                                      tempSelected.add(item.value);
                                    }
                                  });
                                },
                              );
                            }),
                            if (sectionIndex != sections.length - 1)
                              const Divider(height: 1),
                          ],
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