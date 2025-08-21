import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/cust_button.dart';
import 'package:om_mobile/widgets/cust_date_time_picker.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';

import 'widgets/custom_dialog.dart';

class PrivateNumberBookForm extends StatefulWidget {
  const PrivateNumberBookForm({Key? key}) : super(key: key);

  @override
  State<PrivateNumberBookForm> createState() => _PrivateNumberBookFormState();
}

class _PrivateNumberBookFormState extends State<PrivateNumberBookForm> {
  late final String _privateNumber;
  DateTime? _selectedDateTime;
  final TextEditingController _pnExchangeWithController = TextEditingController();
  final TextEditingController _pnReceivedController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "Private Number Book Details",
  ];

  @override
  void initState() {
    super.initState();
    _privateNumber = _generateRandomPrivateNumber();
  }

  String _generateRandomPrivateNumber() {
    final rand = Random();
    return 'PN${rand.nextInt(900000) + 100000}';
  }

  List<Widget> get _steps => [
    _buildPrivateNumberBookDetailsStep(),
  ];

  @override
  void dispose() {
    _pnExchangeWithController.dispose();
    _pnReceivedController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "Private Number Book Form"),
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

  Widget _buildPrivateNumberBookDetailsStep() {
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
            CustText(
              name: 'Private Number *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: TextEditingController(text: _privateNumber),
              hintText: 'Private Number',
              readOnly: true,
              fillColor: AppColors.textFieldColor,
              enabled: false,
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
              name: 'PN Exchange With *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _pnExchangeWithController,
              hintText: 'Enter PN Exchange With',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'PN Received *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _pnReceivedController,
              hintText: 'Enter PN Received',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Purpose for which utilized * (Max 500 Characters)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _purposeController,
              hintText: 'Enter Purpose',
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }
} 