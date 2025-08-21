import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/constants/app_data.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/cust_button.dart';
import 'package:om_mobile/widgets/cust_date_time_picker.dart';
import 'package:om_mobile/widgets/cust_dropdown.dart';
import 'package:om_mobile/widgets/cust_radio.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';
import 'package:om_mobile/widgets/file_upload_section.dart';

import 'widgets/custom_dialog.dart';

class GatePassDetailsForm extends StatefulWidget {
  const GatePassDetailsForm({Key? key}) : super(key: key);

  @override
  State<GatePassDetailsForm> createState() => _GatePassDetailsFormState();
}

class _GatePassDetailsFormState extends State<GatePassDetailsForm> {
  // Dropdown Values
  String? _selectedStation;
  String? _selectedReturnableType;
  String? _selectedEmployee;
  String? _selectedDepartment;

  // Input Fields
  DateTime? _selectedDateTime;
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // File Upload
  List<File> _attachedFiles = [];

  final List<String> returnableTypeList = ["Returnable", "Non-Returnable"];
  int _currentStep = 0;

  final List<String> _stepTitles = [
    "Gate Pass Details",
  ];

  List<Widget> get _steps => [_buildGatePassDetailsStep()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "Gate Pass Details Form"),
      backgroundColor: AppColors.bgColor,
      body: Column(
        children: [
          Expanded(child: _steps[_currentStep]),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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

  Widget _buildGatePassDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: AccordionCard(
        expanded: true,
        isExpanded: false,
        title: _stepTitles[_currentStep],
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustDropdown(
              label: 'Station *',
              hint: 'Select Station',
              items: stationListValue,
              selectedValue: _selectedStation,
              onChanged: (value) => setState(() => _selectedStation = value),
            ),
            const SizedBox(height: 16),
            CustDateTimePicker(
              label: 'Date & Time *',
              hint: 'DD/MM/YYYY hh:mm',
              selectedDateTime: _selectedDateTime,
              onDateTimeSelected: (dateTime) =>
                  setState(() => _selectedDateTime = dateTime),
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Returnable/Non-Returnable *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            Row(
              children: returnableTypeList.map((option) => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CustRadio<String>(
                  value: option,
                  groupValue: _selectedReturnableType ?? '',
                  label: option,
                  onChanged: (value) {
                    setState(() {
                      _selectedReturnableType = value;
                    });
                  },
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Purpose of Issue * (Max 100)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            SizedBox(height: 1 * SizeConfig.heightMultiplier),
            CustomTextField(
              controller: _purposeController,
              maxLength: 100,
              hintText: 'Enter Purpose of Issue',
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Employee Name of Receiver *',
              hint: 'Select',
              items: [],
              selectedValue: _selectedEmployee,
              onChanged: (value) => setState(() => _selectedEmployee = value),
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Department *',
              hint: 'Select',
              items: departmentListValue,
              selectedValue: _selectedDepartment,
              onChanged: (value) => setState(() => _selectedDepartment = value),
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Mobile No. * (Max 10)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            SizedBox(height: 1 * SizeConfig.heightMultiplier),
            CustomTextField(
              controller: _phoneController,
              maxLength: 10,
              keyboardType: TextInputType.number,
              hintText: 'Enter Phone No.',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Description of Item * (Max 500)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            SizedBox(height: 1 * SizeConfig.heightMultiplier),
            CustomTextField(
              controller: _descriptionController,
              maxLength: 500,
              maxLines: 4,
              hintText: 'Description of Item',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Attachments: * (Max File Size 1 MB)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
             SizedBox(height: 1 * SizeConfig.heightMultiplier),
            FileUploadSection(
              files: _attachedFiles,
              onFilesChanged: (files) {
                setState(() {
                  _attachedFiles = files;
                });
              },
            ),          ],
        ),
      ),
    );
  }
}

