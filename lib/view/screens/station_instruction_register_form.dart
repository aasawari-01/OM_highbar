import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/constants/app_data.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/cust_button.dart';
import 'package:om_mobile/widgets/cust_date_time_picker.dart';
import 'package:om_mobile/widgets/cust_dropdown.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';

import 'widgets/custom_dialog.dart';

class StationInstructionRegisterForm extends StatefulWidget {
  const StationInstructionRegisterForm({Key? key}) : super(key: key);

  @override
  State<StationInstructionRegisterForm> createState() => _StationInstructionRegisterFormState();
}

class _StationInstructionRegisterFormState extends State<StationInstructionRegisterForm> {
  String? _selectedStation;
  DateTime? _selectedDateTime;
  String? _selectedOfficer;
  String? _selectedDesignation;
  String? _selectedDepartment;
  final TextEditingController _applicableForController = TextEditingController();
  String? _selectedStatus;
  final TextEditingController _instructionDetailsController = TextEditingController();

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "Station Instruction Details",
  ];

  // Placeholder lists for officers, designations, departments
  final List<String> officerList = [
    "Officer A", "Officer B", "Officer C"
  ];
  final List<String> designationList = [
    "Manager", "Supervisor", "Inspector"
  ];
  final List<String> statusList = ["Issued", "Canceled", "In-Process"];

  List<Widget> get _steps => [
    _buildStationInstructionDetailsStep(),
  ];

  @override
  void dispose() {
    _applicableForController.dispose();
    _instructionDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "Station Instruction Register Form"),
      backgroundColor: AppColors.bgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _steps[_currentStep],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustButton(
                  name: 'Submit',
                  size: 30,
                  onSelected: (_) {
                    Get.dialog(CustomDialog("Saved Successfully."));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationInstructionDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: AccordionCard(
        expanded: true,
        onTap: () {},
        isExpanded: false,
        title: _stepTitles[_currentStep],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustDropdown(
              label: 'Station *',
              hint: 'Select Station',
              items: stationListValue,
              selectedValue: _selectedStation,
              onChanged: (value) {
                setState(() {
                  _selectedStation = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustDateTimePicker(
              label: 'Date & Time *',
              hint: 'DD/MM/YYYY hh:mm',
              selectedDateTime: _selectedDateTime,
              onDateTimeSelected: (dateTime) {
                setState(() {
                  _selectedDateTime = dateTime;
                });
              },
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Instruction Issuing Officer Name *',
              hint: 'Select Officer',
              items: officerList,
              selectedValue: _selectedOfficer,
              onChanged: (value) {
                setState(() {
                  _selectedOfficer = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Designation *',
              hint: 'Select Designation',
              items: designationList,
              selectedValue: _selectedDesignation,
              onChanged: (value) {
                setState(() {
                  _selectedDesignation = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Department *',
              hint: 'Select Department',
              items: departmentListValue,
              selectedValue: _selectedDepartment,
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Applicable For * (Max 100 Characters)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _applicableForController,
              hintText: 'Enter Applicable For',
              maxLines: 2,
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Status *',
              hint: 'Select Status',
              items: statusList,
              selectedValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Instruction Details * (Max 500 Characters)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _instructionDetailsController,
              hintText: 'Enter Instruction Details',
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }
} 