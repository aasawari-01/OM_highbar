import 'package:flutter/material.dart';
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
import 'package:flutter/services.dart';

class CashCheckDetailsRegisterForm extends StatefulWidget {
  const CashCheckDetailsRegisterForm({Key? key}) : super(key: key);

  @override
  State<CashCheckDetailsRegisterForm> createState() => _CashCheckDetailsRegisterFormState();
}

class _CashCheckDetailsRegisterFormState extends State<CashCheckDetailsRegisterForm> {
  String? _selectedStation;
  DateTime? _selectedDateTime;
  final TextEditingController _inspectingAuthorityController = TextEditingController();
  String? _selectedShift;
  final List<String> operatorNames = ["John Doe", "Jane Smith", "Alex Brown"];
  String? _selectedOperator;
  final List<String> actionTaken = ["Hold", "Cancel", "Completed"];
  String? _selectedActionTaken;
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _eosNoController = TextEditingController();
  final TextEditingController _amountEOSController = TextEditingController();
  final TextEditingController _amountCheckController = TextEditingController();
  double? _difference;
  final TextEditingController _upiAmountController = TextEditingController();
  final TextEditingController _outstandingAmountController = TextEditingController();
  final TextEditingController _actionTakenController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "Cash Check Details",
  ];

  final List<String> shiftList = ["Morning", "Evening", "Night", "General"];

  List<Widget> get _steps => [
    _buildCashCheckDetailsStep(),
  ];

  @override
  void dispose() {
    _inspectingAuthorityController.dispose();
    _employeeIdController.dispose();
    _eosNoController.dispose();
    _amountEOSController.dispose();
    _amountCheckController.dispose();
    _upiAmountController.dispose();
    _outstandingAmountController.dispose();
    _actionTakenController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _updateDifference() {
    final eos = double.tryParse(_amountEOSController.text) ?? 0.0;
    final check = double.tryParse(_amountCheckController.text) ?? 0.0;
    setState(() {
      _difference = eos - check;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "Cash Check Details Register Form"),
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
                    // TODO: Implement submit logic
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCheckDetailsStep() {
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
              name: 'Name of Inspecting Authority *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _inspectingAuthorityController,
              hintText: 'Enter Name of Inspecting Authority',
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
            CustDropdown(
              label: 'Name Of Operator *',
              hint: 'Select Operator',
              items: operatorNames,
              selectedValue: _selectedOperator,
              onChanged: (value) {
                setState(() {
                  _selectedOperator = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Employee Id *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _employeeIdController,
              hintText: 'Enter Employee Id',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'EOS No. *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _eosNoController,
              hintText: 'Enter EOS No.',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Amount as per EOS *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _amountEOSController,
              hintText: 'Enter Amount as per EOS',
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateDifference(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Amount as per Check *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _amountCheckController,
              hintText: 'Enter Amount as per Check',
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateDifference(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Difference',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              readOnly: true,
              fillColor: AppColors.textFieldFillColor,
              controller: TextEditingController(text: _difference == null ? '' : _difference!.toStringAsFixed(2)),
              hintText: 'Difference',
              enabled: false,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'UPI Amount',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _upiAmountController,
              hintText: 'Enter UPI Amount',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'OutStanding Amount',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _outstandingAmountController,
              hintText: 'Enter OutStanding Amount',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Action Taken *',
              hint: 'Select Action Taken',
              items: actionTaken,
              selectedValue: _selectedActionTaken,
              onChanged: (value) {
                setState(() {
                  _selectedActionTaken = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Remarks * (Max 500 Characters)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _remarksController,
              hintText: 'Enter Remarks',
              maxLines: 3,
              maxLength: 500,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
} 