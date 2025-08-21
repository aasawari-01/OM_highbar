import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/cust_dropdown.dart';
import 'package:om_mobile/widgets/cust_text.dart';

import 'constants/app_data.dart';

class FilterPopup extends StatefulWidget {
  const FilterPopup({Key? key}) : super(key: key);

  @override
  State<FilterPopup> createState() => _FilterPopupState();
}

class _FilterPopupState extends State<FilterPopup> {
  // Example filter state
  Set<String> selectedPriorities = {'Low'};
  Set<String> selectedStatuses = {'Assigned'};
  Set<String> selectedTypes = {'OCC'};
  String? selectedDepartment;
  String? selectedLocation;
  String? selectedShowData = 'All';
  DateTime? selectedDate;
  bool serviceAffected = false;

  final List<String> priorities = ['Low', 'Medium', 'High', 'Very High'];
  final List<String> statuses = ['Assigned', 'Reassigned'];
  final List<String> types = ['OCC', 'Station'];
  final List<String> showDataOptions = ['All', 'Created', 'Reassigned', 'Resolved', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: CustText(
                name: 'All Filters',
                size: 2,
                color: AppColors.textColor,
                fontWeightName: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Priority
            _buildSectionLabel('Priority'),
            Wrap(
              spacing: 1 * SizeConfig.widthMultiplier,
              children: priorities.map((p) => ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedPriorities.contains(p))
                      Icon(Icons.check, color: AppColors.textColor3, size: 5 * SizeConfig.widthMultiplier),
                    if (selectedPriorities.contains(p))
                      const SizedBox(width: 4), // Decrease this for less gap
                    CustText(
                      name: p,
                      size: 1.3,
                      color: selectedPriorities.contains(p) ? AppColors.textColor3 : AppColors.textColor,
                      fontWeightName: selectedPriorities.contains(p) ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ],
                ),
                selected: selectedPriorities.contains(p),
                selectedColor: AppColors.textColor3.withOpacity(0.1),
                onSelected: (_) {
                  setState(() {
                    if (selectedPriorities.contains(p)) {
                      selectedPriorities.remove(p);
                    } else {
                      selectedPriorities.add(p);
                    }
                  });
                },
                backgroundColor: Colors.white,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selectedPriorities.contains(p) ? AppColors.textColor3 : Colors.grey.shade300,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              )).toList(),
            ),
            const SizedBox(height: 16),
            // Assign Status
            _buildSectionLabel('Assign Status'),
            Wrap(
              spacing: 8,
              children: statuses.map((s) => ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedStatuses.contains(s))
                      Icon(Icons.check, color: AppColors.textColor3, size: 16),
                    if (selectedStatuses.contains(s))
                      const SizedBox(width: 4),
                    CustText(
                      name: s,
                      size: 1.3,
                      color: selectedStatuses.contains(s) ? AppColors.textColor3 : AppColors.textColor,
                      fontWeightName: selectedStatuses.contains(s) ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ],
                ),
                selected: selectedStatuses.contains(s),
                selectedColor: AppColors.textColor3.withOpacity(0.1),
                onSelected: (_) {
                  setState(() {
                    if (selectedStatuses.contains(s)) {
                      selectedStatuses.remove(s);
                    } else {
                      selectedStatuses.add(s);
                    }
                  });
                },
                backgroundColor: Colors.white,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selectedStatuses.contains(s) ? AppColors.textColor3 : Colors.grey.shade300,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              )).toList(),
            ),
            const SizedBox(height: 16),
            // Creation Type
            _buildSectionLabel('Creation Type'),
            Wrap(
              spacing: 8,
              children: types.map((t) => ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedTypes.contains(t))
                      Icon(Icons.check, color: AppColors.textColor3, size: 16),
                    if (selectedTypes.contains(t))
                      const SizedBox(width: 4),
                    CustText(
                      name: t,
                      size: 1.3,
                      color: selectedTypes.contains(t) ? AppColors.textColor3 : AppColors.textColor,
                      fontWeightName: selectedTypes.contains(t) ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ],
                ),
                selected: selectedTypes.contains(t),
                selectedColor: AppColors.textColor3.withOpacity(0.1),
                onSelected: (_) {
                  setState(() {
                    if (selectedTypes.contains(t)) {
                      selectedTypes.remove(t);
                    } else {
                      selectedTypes.add(t);
                    }
                  });
                },
                backgroundColor: Colors.white,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selectedTypes.contains(t) ? AppColors.textColor3 : Colors.grey.shade300,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              )).toList(),
            ),
            const SizedBox(height: 16),
            _buildDropdown("Department",'Select Department', departmentListValue, (val) {
              setState(() => selectedDepartment = val);
            }),
            const SizedBox(height: 16),
            // Location Dropdown
            _buildDropdown('Location','Select Location', stationListValue, (val) {
              setState(() => selectedLocation = val);
            }),
            const SizedBox(height: 16),
            // Show Data Dropdown
            CustDropdown(
              label: 'Show Data',
              hint: 'Select',
              items: showDataOptions,
              selectedValue: selectedShowData,
              onChanged: (val) {
                setState(() => selectedShowData = val);
              },
            ),
            const SizedBox(height: 16),
            // Date Picker
            _buildSectionLabel('Failure Occurrence Date'),
            _buildDatePicker(context),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: serviceAffected,
                  onChanged: (val) {
                    setState(() => serviceAffected = val ?? false);
                  },
                  activeColor: AppColors.textColor3,
                ),
                CustText(
                  name: 'Passengers Affected',
                  size: 1.5,
                  fontWeightName: FontWeight.w500,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Buttons (Apply first, then Clear)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Apply filter logic
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textColor3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: CustText(
                      name: 'Apply Filters',
                      size: 1.5,
                      color: Colors.white,
                      fontWeightName: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Clear logic
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.textColor3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: CustText(
                      name: 'Clear',
                      size: 1.5,
                      color: AppColors.textColor3,
                      fontWeightName: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: CustText(
      name: label,
      size: 1.8,
      fontWeightName: FontWeight.w500,
    ),
  );

  Widget _buildDropdown(String label, String hint, List<String> value, ValueChanged<String?> onChanged) {
    return CustDropdown(label: label, hint: hint, items: value, onChanged: onChanged);
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: CustText(
                name: selectedDate == null
                    ? 'Select Date'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                size: 1.3,
                color: selectedDate == null ? AppColors.textColor4 : AppColors.textColor,
              ),
            ),
            const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}