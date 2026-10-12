import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_date_time_picker.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_radio.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/cust_toggle.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../../../utils/widgets/custom_dialog.dart';
import '../../../utils/widgets/cust_data_card.dart';

enum InspectionPlan { scheduled, unscheduled }

class InspectionScreen extends StatefulWidget {
  final bool isJEInspectionView;
  
  const InspectionScreen({super.key, this.isJEInspectionView = false});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _designationController = TextEditingController(text: 'Default Account Holder Designation');
  final _remarksController = TextEditingController();
  
  bool _indoorStatus = false;
  String? _selectedStation = 'Khapri - Line 1';

  InspectionPlan _selectedPlan = InspectionPlan.scheduled;
  String? _selectedDepartment;
  String? _selectedInspectionType;
  String? _selectedFrequency;
  DateTime? _selectedInspectionScheduledDate;
  String? _selectedInspectionBy;

  static const List<String> _frequencyOptions = [
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Half-Yearly',
    'Yearly',
  ];

  static const List<String> _departmentOptions = [
    'Signalling',
    'Rolling Stock',
    'Track',
    'Information Technology',
    'Civil',
  ];

  static const Map<String, List<String>> _inspectionTypesByDept = {
    'Signalling': ['Foot plate', 'On-board', 'Stations-SE', 'Wayside', 'General Inspection'],
    'Rolling Stock': ['General Inspection'],
    'Track': ['General Inspection', 'Curve Inspection', 'Creep Measurement'],
    'Information Technology': ['General Inspection'],
    'Civil': ['General Inspection', 'Routine Station Inspection'],
  };

  static const List<String> _inspectionByOptions = [
    'User 1',
    'User 2',
    'User 3',
  ];

  bool get _isScheduled => _selectedPlan == InspectionPlan.scheduled;

  @override
  void dispose() {
    _designationController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _onPlanChanged(InspectionPlan? plan) {
    if (plan == null) return;
    setState(() {
      _selectedPlan = plan;
      if (!_isScheduled) {
        _selectedFrequency = null;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Get.dialog(CustomDialog('Inspection created successfully.'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'Create Inspection',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: widget.isJEInspectionView ? _buildJEForm() : _buildStandardForm(),
        ),
      ),
    );
  }

  Widget _buildStandardForm() {
    return Column(
      children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustText.sectionHeader('Inspection Details', color: AppColors.orangeColor),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustText.formLabel('Inspection'),
                      const SizedBox(height: AppConstants.labelSpacing),
                      Row(
                        children: [
                          CustRadio<InspectionPlan>(
                            value: InspectionPlan.scheduled,
                            groupValue: _selectedPlan,
                            label: 'Scheduled',
                            onChanged: _onPlanChanged,
                          ),
                          const SizedBox(width: AppConstants.sectionSpacing),
                          CustRadio<InspectionPlan>(
                            value: InspectionPlan.unscheduled,
                            groupValue: _selectedPlan,
                            label: 'Unscheduled',
                            onChanged: _onPlanChanged,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustDropdown(
                        label: 'Department',
                        hint: 'Select',
                        items: _departmentOptions,
                        selectedValue: _selectedDepartment,
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value;
                            _selectedInspectionType = null;
                          });
                        },
                      ),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustomTextField(
                        label: 'Designation',
                        controller: _designationController,
                        hintText: 'Default Account Holder Designation',
                        readOnly: true,
                        fillColor: AppColors.containerColor2,
                      ),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustDropdown(
                        label: 'Inspection Type',
                        hint: 'Select inspection type',
                        items: _selectedDepartment != null
                            ? (_inspectionTypesByDept[_selectedDepartment] ?? [])
                            : _inspectionTypesByDept['Signalling']!,
                        selectedValue: _selectedInspectionType,
                        onChanged: (value) => setState(() => _selectedInspectionType = value),
                      ),
                      if (_isScheduled) ...[
                        const SizedBox(height: AppConstants.elementSpacing),
                        CustDropdown(
                          label: 'Frequency',
                          hint: 'Select frequency',
                          items: _frequencyOptions,
                          selectedValue: _selectedFrequency,
                          onChanged: (value) => setState(() => _selectedFrequency = value),
                        ),
                      ],
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustDateTimePicker(
                        pickerType: PickerType.date,
                        label: 'Inspection Scheduled Date',
                        hint: 'Select date',
                        selectedDateTime: _selectedInspectionScheduledDate,
                        onDateTimeSelected: (date) {
                          setState(() => _selectedInspectionScheduledDate = date);
                        },
                      ),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustDropdown(
                        label: 'Inspection By',
                        hint: 'Select inspection by',
                        items: _inspectionByOptions,
                        selectedValue: _selectedInspectionBy,
                        onChanged: (value) => setState(() => _selectedInspectionBy = value),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.screenPadding,
                  AppConstants.elementSpacing,
                  AppConstants.screenPadding,
                  AppConstants.screenPadding,
                ),
                child: CustButton(
                  name: 'Create Inspection',
                  size: double.infinity,
                  sHeight: AppConstants.buttonHeight,
                  onSelected: (_) => _submit(),
                ),
              ),
            ],
    );
  }

  Widget _buildJEForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText.sectionHeader('Inspection Details', color: AppColors.orangeColor),
                const SizedBox(height: AppConstants.elementSpacing),
                CustText.formLabel('Inspection Date : 06/01/2026'),
                const SizedBox(height: AppConstants.elementSpacing),
                CustText.formLabel('Inspection No : U/01-2026-01'),
                const SizedBox(height: AppConstants.elementSpacing),
                CustomTextField(
                  label: 'Department',
                  controller: TextEditingController(text: 'Signalling'),
                  readOnly: true,
                  fillColor: AppColors.containerColor2,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustomTextField(
                  label: 'Inspection Name',
                  controller: TextEditingController(text: 'Station JE'),
                  readOnly: true,
                  fillColor: AppColors.containerColor2,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustomTextField(
                  label: 'Inspection By',
                  controller: TextEditingController(text: 'Dharmesh Solanki'),
                  readOnly: true,
                  fillColor: AppColors.containerColor2,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustDropdown(
                  label: 'Station',
                  hint: 'Select',
                  items: const ['Khapri - Line 1'],
                  selectedValue: _selectedStation,
                  onChanged: (value) => setState(() => _selectedStation = value),
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustDataCard(
                  items: [
                    DataCardItem(
                      label: 'System',
                      isFullWidth: true,
                      valueWidget: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustText(name: 'Indoor status', size: 16, fontWeightName: FontWeight.bold),
                          YesNoToggle(
                            value: _indoorStatus,
                            onChanged: (val) => setState(() => _indoorStatus = val),
                          ),
                        ],
                      ),
                    ),
                    DataCardItem(
                      label: 'Subsystem:',
                      isFullWidth: true,
                      valueWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustText(name: 'Logbooks record, BOC & Other Registers', size: 16, fontWeightName: FontWeight.bold),
                          const SizedBox(height: AppConstants.elementSpacing),
                          CustText(name: 'Cleaning status', size: 16, fontWeightName: FontWeight.bold),
                        ],
                      ),
                    ),
                    DataCardItem(
                      label: 'Remarks',
                      isFullWidth: true,
                      valueWidget: CustomTextField(
                        hintText: 'Enter Remarks',
                        controller: _remarksController,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.screenPadding,
            AppConstants.elementSpacing,
            AppConstants.screenPadding,
            AppConstants.screenPadding,
          ),
          child: CustButton(
            name: 'Save As Draft',
            size: double.infinity,
            borderRadius: AppConstants.cardRadius,
            onSelected: (_) => _submit(),
          ),
        ),
      ],
    );
  }
}
