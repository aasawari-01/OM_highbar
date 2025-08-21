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

class DeepCleaningForm extends StatefulWidget {
  const DeepCleaningForm({Key? key}) : super(key: key);

  @override
  State<DeepCleaningForm> createState() => _DeepCleaningFormState();
}

class _DeepCleaningFormState extends State<DeepCleaningForm> {
  String? _selectedStation;
  DateTime? _selectedDateTime;
  String? _selectedShift;
  final TextEditingController _noOfStaffController = TextEditingController();
  String? _selectedStatus;
  final TextEditingController _natureOfWorkController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "Deep Cleaning Details",
  ];

  final List<String> shiftList = ["Morning", "Evening", "Night"];
  final List<String> statusList = ["Cleaned", "Uncleaned"];

  List<Widget> get _steps => [
    _buildDeepCleaningDetailsStep(),
  ];

  @override
  void dispose() {
    _noOfStaffController.dispose();
    _natureOfWorkController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "Deep Cleaning Form"),
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

  Widget _buildDeepCleaningDetailsStep() {
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
              label: 'Shift *',
              hint: 'Select Shift',
              items: shiftList,
              selectedValue: _selectedShift,
              onChanged: (value) {
                setState(() {
                  _selectedShift = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'No of Staff *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _noOfStaffController,
              hintText: 'Enter No of Staff',
              keyboardType: TextInputType.number,
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
              name: 'Work description * (Max 500 Characters)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _natureOfWorkController,
              hintText: 'Enter Nature of Work',
              maxLines: 4,
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