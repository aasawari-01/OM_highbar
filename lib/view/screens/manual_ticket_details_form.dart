import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class ManualTicketDetailsForm extends StatefulWidget {
  const ManualTicketDetailsForm({Key? key}) : super(key: key);

  @override
  State<ManualTicketDetailsForm> createState() => _ManualTicketDetailsFormState();
}

class _ManualTicketDetailsFormState extends State<ManualTicketDetailsForm> {
  String? _selectedStation;
  DateTime? _selectedDateTime;
  final TextEditingController _operatorNameController = TextEditingController();
  String? _selectedSourceStation;
  String? _selectedDestinationStation;
  final TextEditingController _fareAmountController = TextEditingController();
  final TextEditingController _serialNoController = TextEditingController();

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "Manual Ticket Details",
  ];

  List<Widget> get _steps => [
    _buildManualTicketDetailsStep(),
  ];

  @override
  void dispose() {
    _operatorNameController.dispose();
    _fareAmountController.dispose();
    _serialNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "Manual Ticket Details Form"),
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

  Widget _buildManualTicketDetailsStep() {
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
              name: 'Name of TOM/EFO Operator',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _operatorNameController,
              hintText: 'Enter Name of TOM/EFO Operator',
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Source Station *',
              hint: 'Select Source Station',
              items: stationListValue,
              selectedValue: _selectedSourceStation,
              onChanged: (value) {
                setState(() {
                  _selectedSourceStation = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Destination Station *',
              hint: 'Select Destination Station',
              items: stationListValue,
              selectedValue: _selectedDestinationStation,
              onChanged: (value) {
                setState(() {
                  _selectedDestinationStation = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Amount of Fare *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _fareAmountController,
              hintText: 'Enter Amount of Fare',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Serial No *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _serialNoController,
              hintText: 'Enter Serial No',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
} 