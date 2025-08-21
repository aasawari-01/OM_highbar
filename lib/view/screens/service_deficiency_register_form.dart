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

class ServiceDeficiencyRegisterForm extends StatefulWidget {
  const ServiceDeficiencyRegisterForm({Key? key}) : super(key: key);

  @override
  State<ServiceDeficiencyRegisterForm> createState() => _ServiceDeficiencyRegisterFormState();
}

class _ServiceDeficiencyRegisterFormState extends State<ServiceDeficiencyRegisterForm> {
  String? _selectedStation;
  DateTime? _selectedDateTime;
  final TextEditingController _staffNameController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  String? _selectedDutyShift;
  String? _selectedStatus;
  String? _selectedPenaltyClause;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "Service Deficiency Details",
  ];

  final List<String> dutyShiftList = ["Morning", "Evening", "Night", "General"];
  final List<String> statusList = ["Open", "Closed"];
  final List<String> penaltyClauseList = ["Man", "Machine"];

  List<Widget> get _steps => [
    _buildServiceDeficiencyDetailsStep(),
  ];

  @override
  void dispose() {
    _staffNameController.dispose();
    _sectionController.dispose();
    _descriptionController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "Service Deficiency Register Form"),
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

  Widget _buildServiceDeficiencyDetailsStep() {
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
            CustText(
              name: 'Name of Staff *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _staffNameController,
              hintText: 'Enter Name of Staff',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Section *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _sectionController,
              hintText: 'Enter Section',
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Duty Shift *',
              hint: 'Select Duty Shift',
              items: dutyShiftList,
              selectedValue: _selectedDutyShift,
              onChanged: (value) {
                setState(() {
                  _selectedDutyShift = value;
                });
              },
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
            CustDropdown(
              label: 'Penalty Clause *',
              hint: 'Select Penalty Clause',
              items: penaltyClauseList,
              selectedValue: _selectedPenaltyClause,
              onChanged: (value) {
                setState(() {
                  _selectedPenaltyClause = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Description of Service Deficiencies * (Max 500 Characters)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _descriptionController,
              hintText: 'Enter Description',
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Remark * (Max 500 Characters)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _remarkController,
              hintText: 'Enter Remark',
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }
} 