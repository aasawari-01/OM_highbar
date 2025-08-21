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
import 'package:om_mobile/widgets/cust_radio.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/cust_toggle.dart';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';

import 'widgets/custom_dialog.dart';

class FirstAidRegisterForm extends StatefulWidget {
  const FirstAidRegisterForm({Key? key}) : super(key: key);

  @override
  State<FirstAidRegisterForm> createState() => _FirstAidRegisterFormState();
}

class _FirstAidRegisterFormState extends State<FirstAidRegisterForm> {
  String? _selectedStation;
  DateTime? _selectedDateTime;
  final TextEditingController _passengerNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  String? _selectedConsentForAmbulance;
  final TextEditingController _firstAidProviderController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _medicineDetailsRequired = false;
  final TextEditingController _medicineDetailsController = TextEditingController();
  bool _hospitalDetailsRequired = false;
  final TextEditingController _hospitalDetailsController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "First Aid Register Details",
  ];

  final List<String> genderList = ["Male", "Female", "Others"];
  final List<String> consentAmbulanceList = ["Required", "Not required"];

  List<Widget> get _steps => [
    _buildFirstAidRegisterDetailsStep(),
  ];

  @override
  void dispose() {
    _passengerNameController.dispose();
    _mobileNumberController.dispose();
    _ageController.dispose();
    _firstAidProviderController.dispose();
    _reasonController.dispose();
    _medicineDetailsController.dispose();
    _hospitalDetailsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "First Aid Register Form"),
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

  Widget _buildFirstAidRegisterDetailsStep() {
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
              name: 'Passenger Name *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _passengerNameController,
              hintText: 'Enter Passenger Name',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Mobile Number *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _mobileNumberController,
              hintText: 'Enter Mobile Number',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Age * (Max 100)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _ageController,
              hintText: 'Enter Age',
              keyboardType: TextInputType.number,
              maxLength: 3,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final intValue = int.tryParse(newValue.text);
                  if (intValue != null && intValue > 100) {
                    return oldValue;
                  }
                  return newValue;
                }),
              ],
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Gender *',
              hint: 'Select Gender',
              items: genderList,
              selectedValue: _selectedGender,
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Consent for Ambulance *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            Row(
              children: consentAmbulanceList.map((option) => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CustRadio<String>(
                  value: option,
                  groupValue: _selectedConsentForAmbulance ?? '',
                  label: option,
                  onChanged: (value) {
                    setState(() {
                      _selectedConsentForAmbulance = value;
                    });
                  },
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'First Aid Provider Name *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _firstAidProviderController,
              hintText: 'Enter First Aid Provider Name',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Reason *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _reasonController,
              hintText: 'Enter Reason',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Medicine Details Required ?',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            YesNoToggle(
              value: _medicineDetailsRequired,
              onChanged: (val) {
                setState(() {
                  _medicineDetailsRequired = val;
                  if (!val) _medicineDetailsController.clear();
                });
              },
            ),
            if (_medicineDetailsRequired) ...[
              const SizedBox(height: 16),
              CustText(
                name: 'Medicine Details',
                size: 1.8,
                fontWeightName: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _medicineDetailsController,
                hintText: 'Enter Medicine Details',
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 16),
            CustText(
              name: 'Hospital Details Required ?',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            YesNoToggle(
              value: _hospitalDetailsRequired,
              onChanged: (val) {
                setState(() {
                  _hospitalDetailsRequired = val;
                  if (!val) _hospitalDetailsController.clear();
                });
              },
            ),
            if (_hospitalDetailsRequired) ...[
              const SizedBox(height: 16),
              CustText(
                name: 'Hospital Details',
                size: 1.8,
                fontWeightName: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _hospitalDetailsController,
                hintText: 'Enter Hospital Details',
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 16),
            CustText(
              name: 'Address of Injured person * (Max 500)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _addressController,
              hintText: 'Enter Address',
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }
} 