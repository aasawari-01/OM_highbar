import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/constants/app_data.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/cust_button.dart';
import 'package:om_mobile/widgets/cust_date_picker.dart';
import 'package:om_mobile/widgets/cust_dropdown.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';

import 'widgets/custom_dialog.dart';

class TomShiftLoginForm extends StatefulWidget {
  const TomShiftLoginForm({Key? key}) : super(key: key);

  @override
  State<TomShiftLoginForm> createState() => _TomShiftLoginFormState();
}

class _TomShiftLoginFormState extends State<TomShiftLoginForm> {
  String? _selectedStation;
  String? _selectedCreatedFor;
  String? _selectedDutyShift;
  DateTime? _selectedDate;
  TimeOfDay? _reportingTime;
  final TextEditingController _shiftNoController = TextEditingController();
  final TextEditingController _privateCashController = TextEditingController();
  final TextEditingController _earningsEOSController = TextEditingController();
  final TextEditingController _totalCashDepositedController = TextEditingController();
  final TextEditingController _imprestReturnedController = TextEditingController();

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "TOM Shift Details",
    "Cash Details",
  ];

  final List<String> createdForList = ["TOM", "EFO"];
  final List<String> dutyShiftList = ["Morning", "Evening", "Night"];

  List<Widget> get _steps => [
    _buildShiftDetailsStep(),
  ];

  @override
  void dispose() {
    _shiftNoController.dispose();
    _privateCashController.dispose();
    _earningsEOSController.dispose();
    _totalCashDepositedController.dispose();
    _imprestReturnedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "TOM Shift Login Form"),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  CustOutlineButton(
                    name: 'Back',
                    size: 30,
                    onSelected: (_) => setState(() => _currentStep--),
                  ),
                if (_currentStep < _steps.length - 1)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: CustButton(
                        name: 'Next',
                        size: 30,
                        onSelected: (_) => setState(() => _currentStep++),
                      ),
                    ),
                  ),
                if (_currentStep == _steps.length - 1)
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

  Widget _buildShiftDetailsStep() {
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
            CustDropdown(
              label: 'Created for *',
              hint: 'Select Created for',
              items: createdForList,
              selectedValue: _selectedCreatedFor,
              onChanged: (value) {
                setState(() {
                  _selectedCreatedFor = value;
                });
              },
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
            CustDatePicker(
              label: 'Date *',
              hint: 'DD/MM/YYYY',
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Reporting Time *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _reportingTime ?? TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() {
                    _reportingTime = picked;
                  });
                }
              },
              child: AbsorbPointer(
                child: CustomTextField(
                  controller: TextEditingController(
                    text: _reportingTime != null ? _reportingTime!.format(context) : '',
                  ),
                  hintText: 'HH:mm',
                  readOnly: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Shift No.',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _shiftNoController,
              hintText: 'Enter Shift No.',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Private Cash *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _privateCashController,
              hintText: 'Enter Private Cash',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Earnings as Per EOS *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _earningsEOSController,
              hintText: 'Enter Earnings as Per EOS',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Total Cash Deposited (Excluding Imprest) *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _totalCashDepositedController,
              hintText: 'Enter Total Cash Deposited',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Imprest Returned / Handed Over',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _imprestReturnedController,
              hintText: 'Enter Imprest Returned / Handed Over',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

} 