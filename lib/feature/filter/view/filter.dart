import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';

import '../../../constants/app_data.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/responsive_helper.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_date_time_picker.dart';
import 'package:get/get.dart';
import '../../../service/session_controller.dart';
import '../../../core/models/label_value.dart';
import '../../../service/local_database_service.dart';
import '../../../service/auth_manager.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import 'dart:convert';
class FilterPopup extends StatefulWidget {
  final Set<String> initialStatuses;
  final Function(Set<String>) onApply;

  const FilterPopup({
    Key? key,
    required this.initialStatuses,
    required this.onApply,
  }) : super(key: key);

  @override
  State<FilterPopup> createState() => _FilterPopupState();
}

class _FilterPopupState extends State<FilterPopup> {
  // Example filter state
  Set<String> selectedPriorities = {'Low'};
  late Set<String> selectedStatuses;
  Set<String> selectedTypes = {'OCC'};
  String? selectedDepartment;
  String? selectedLocation;
  String? selectedShowData = 'All';
  DateTime? selectedDate;
  bool serviceAffected = false;

  final List<String> priorities = ['Low', 'Medium', 'High', 'Very High'];
  final List<String> statuses = ['Assigned', 'Open', 'Closed'];
  final List<String> types = ['OCC', 'Station'];
  final List<String> showDataOptions = ['All', 'Created', 'Reassigned', 'Resolved', 'Completed'];

  List<String> departmentListValue = [];
  List<String> stationListValue = [];

  @override
  void initState() {
    super.initState();
    selectedStatuses = Set.from(widget.initialStatuses);
    _loadData();
  }

  Future<void> _loadData() async {
    final session = Get.find<SessionController>();
    final dbService = LocalDatabaseService();
    
    var locations = await dbService.getLocations();
    
    final userId = await AuthManager().getUserId() ?? "0";
    final userBusinessArea = await AuthManager().getBusinessArea();
    List<String> validPlantIds = [];

    if (userBusinessArea != null) {
      try {
        final plantsRes = await ApiClient().post(
          AppUrls.getMasterData,
          body: {
            "userId": int.tryParse(userId) ?? 0,
            "action": "GetPlantsMasterData"
          }
        );
        if (plantsRes.statusCode == 200) {
          final Map<String, dynamic> jsonBody = jsonDecode(plantsRes.body);
          if (jsonBody['success'] == true && jsonBody['data'] != null) {
            final List<dynamic> plants = jsonBody['data']['planningPlants'] ?? [];
            validPlantIds = plants
                .where((p) => p['businessArea'].toString() == userBusinessArea.toString())
                .map((p) => p['plant'].toString().trim())
                .toList();
          }
        }
      } catch (e) {
        debugPrint("Error fetching validPlantIds for filter: $e");
      }
    }
    
    if (validPlantIds.isNotEmpty) {
      locations = locations.where((l) => validPlantIds.contains(l.plantId?.toString().trim())).toList();
    }
    
    if (mounted) {
      setState(() {
        departmentListValue = session.departments
            .map((e) => e.deptName ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        stationListValue = locations
            .map((e) => e.locationName ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: AppConstants.elementSpacing),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: CustText.sectionHeader('All Filters', color: AppColors.textDarkPrimary),
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            // Priority
            _buildSectionLabel('Priority'),
            Wrap(
              spacing:ResponsiveHelper.spacing(context, 8),
              children: priorities.map((p) => ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedPriorities.contains(p))
                      Icon(Icons.check, color: AppColors.darkBlue, size:ResponsiveHelper.height(context, 20)),
                    if (selectedPriorities.contains(p))
                      const SizedBox(width: 4), // Decrease this for less gap
                    CustText(
                      name: p,
                      size: 13,
                      color: selectedPriorities.contains(p) ? AppColors.darkBlue : AppColors.textDarkPrimary,
                      fontWeightName: selectedPriorities.contains(p) ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ],
                ),
                selected: selectedPriorities.contains(p),
                selectedColor: AppColors.darkBlue.withOpacity(0.1),
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
                    color: selectedPriorities.contains(p) ? AppColors.darkBlue : Colors.grey.shade300,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              )).toList(),
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            // Assign Status
            _buildSectionLabel('Assign Status'),
            Wrap(
              spacing: 8,
              children: statuses.map((s) => ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedStatuses.contains(s))
                      Icon(Icons.check, color: AppColors.darkBlue, size: 16),
                    if (selectedStatuses.contains(s))
                      const SizedBox(width: 4),
                    CustText(
                      name: s,
                      size: 13,
                      color: selectedStatuses.contains(s) ? AppColors.darkBlue : AppColors.textDarkPrimary,
                      fontWeightName: selectedStatuses.contains(s) ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ],
                ),
                selected: selectedStatuses.contains(s),
                selectedColor: AppColors.darkBlue.withOpacity(0.1),
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
                    color: selectedStatuses.contains(s) ? AppColors.darkBlue : Colors.grey.shade300,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              )).toList(),
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            // Creation Type
            _buildSectionLabel('Creation Type'),
            Wrap(
              spacing: 8,
              children: types.map((t) => ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedTypes.contains(t))
                      Icon(Icons.check, color: AppColors.darkBlue, size: 16),
                    if (selectedTypes.contains(t))
                      const SizedBox(width: 4),
                    CustText(
                      name: t,
                      size: 13,
                      color: selectedTypes.contains(t) ? AppColors.darkBlue : AppColors.textDarkPrimary,
                      fontWeightName: selectedTypes.contains(t) ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ],
                ),
                selected: selectedTypes.contains(t),
                selectedColor: AppColors.darkBlue.withOpacity(0.1),
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
                    color: selectedTypes.contains(t) ? AppColors.darkBlue : Colors.grey.shade300,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              )).toList(),
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            _buildDropdown("Department",'Select Department', departmentListValue, (val) {
              setState(() => selectedDepartment = val);
            }),
            const SizedBox(height: AppConstants.elementSpacing),
            // Location Dropdown
            _buildDropdown('Location','Select Location', stationListValue, (val) {
              setState(() => selectedLocation = val);
            }),
            const SizedBox(height: AppConstants.elementSpacing),
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
            const SizedBox(height: AppConstants.elementSpacing),
            // Date Picker
            CustDateTimePicker(
              label: 'Failure Occurrence Date',
              hint: 'Select Date',
              pickerType: PickerType.date,
              selectedDateTime: selectedDate,
              onDateTimeSelected: (picked) {
                setState(() => selectedDate = picked);
              },
            ),
            const SizedBox(height: AppConstants.sectionSpacing),
            Row(
              children: [
                Checkbox(
                  value: serviceAffected,
                  onChanged: (val) {
                    setState(() => serviceAffected = val ?? false);
                  },
                  activeColor: AppColors.darkBlue,
                ),
                CustText(
                  name: 'Passengers Affected',
                  size: 15,
                  fontWeightName: FontWeight.w500,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            // Buttons (Apply first, then Clear)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(selectedStatuses);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: CustText(
                      name: 'Apply Filters',
                      size: 15,
                      color: Colors.white,
                      fontWeightName: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedStatuses.clear();
                      });
                      widget.onApply(selectedStatuses);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.darkBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: CustText(
                      name: 'Clear',
                      size: 15,
                      color: AppColors.darkBlue,
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
    child: CustText.formLabel(label),
  );

  Widget _buildDropdown(String label, String hint, List<String> value, ValueChanged<String?> onChanged) {
    return CustDropdown(label: label, hint: hint, items: value, onChanged: onChanged);
  }


}
