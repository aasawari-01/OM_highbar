import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/constants/app_data.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/cust_button.dart';
import 'package:om_mobile/widgets/cust_date_picker.dart';
import 'package:om_mobile/widgets/cust_date_time_picker.dart';
import 'package:om_mobile/widgets/cust_dropdown.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/file_upload_section.dart';
import 'package:om_mobile/widgets/cust_toggle.dart';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';
import 'dart:io';

import 'widgets/custom_dialog.dart';

class PenaltyRegisterForm extends StatefulWidget {
  const PenaltyRegisterForm({Key? key}) : super(key: key);

  @override
  State<PenaltyRegisterForm> createState() => _PenaltyRegisterFormState();
}

class _PenaltyRegisterFormState extends State<PenaltyRegisterForm> {
  String? _selectedStation;
  DateTime? _selectedDateTime;
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _passengerNameController = TextEditingController();
  final TextEditingController _passengerAddressController = TextEditingController();
  bool _amountDepositedToBank = false;
  DateTime? _amountDepositionDate;
  final TextEditingController _receiptNoController = TextEditingController();
  List<File> _uploadedFiles = [];
  final TextEditingController _penaltyDescriptionController = TextEditingController();

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "Penalty Register Details",
  ];

  List<Widget> get _steps => [
    _buildPenaltyRegisterDetailsStep(),
  ];

  @override
  void dispose() {
    _sectionController.dispose();
    _amountController.dispose();
    _passengerNameController.dispose();
    _passengerAddressController.dispose();
    _receiptNoController.dispose();
    _penaltyDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "Penalty Register Form"),
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

  Widget _buildPenaltyRegisterDetailsStep() {
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
              name: 'Section of Penalty',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _sectionController,
              hintText: 'Enter Section of Penalty',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Amount *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _amountController,
              hintText: 'Enter Amount',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Name of Passenger *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _passengerNameController,
              hintText: 'Enter Name of Passenger',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Address of Passenger *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _passengerAddressController,
              hintText: 'Enter Address of Passenger',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Amount Deposited To Bank *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            YesNoToggle(
              value: _amountDepositedToBank,
              onChanged: (val) {
                setState(() {
                  _amountDepositedToBank = val;
                  if (!val) _amountDepositionDate = null;
                });
              },
            ),
            if (_amountDepositedToBank) ...[
              const SizedBox(height: 16),
              CustDatePicker(
                label: 'Amount deposition date *',
                hint: 'Select Date',
                selectedDate: _amountDepositionDate,
                onDateSelected: (date) {
                  setState(() {
                    _amountDepositionDate = date;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            CustText(
              name: 'Receipt No',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _receiptNoController,
              hintText: 'Enter Receipt No',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Upload Attachment',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            FileUploadSection(
              files: _uploadedFiles,
              onFilesChanged: (files) {
                setState(() {
                  _uploadedFiles = files;
                });
              },
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Penalty Description *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _penaltyDescriptionController,
              hintText: 'Enter Penalty Description',
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }
} 