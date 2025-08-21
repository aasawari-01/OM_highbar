
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_data.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/cust_date_time_picker.dart';
import 'package:om_mobile/widgets/cust_dropdown.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/cust_date_picker.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/cust_button.dart';
import 'package:om_mobile/widgets/custom_dialog.dart';

class AssetRegisterForm extends StatefulWidget {
  const AssetRegisterForm({Key? key}) : super(key: key);

  @override
  State<AssetRegisterForm> createState() => _AssetRegisterFormState();
}

class _AssetRegisterFormState extends State<AssetRegisterForm> {
  String? _selectedStation;
  DateTime? _deliveryDate;
  final TextEditingController _assetDescriptionController = TextEditingController();
  final TextEditingController _nameOfAssetController = TextEditingController();
  final TextEditingController _financeAssetCodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();

  @override
  void dispose() {
    _assetDescriptionController.dispose();
    _nameOfAssetController.dispose();
    _financeAssetCodeController.dispose();
    _quantityController.dispose();
    _modelNumberController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "Asset Register Form"),
      backgroundColor: AppColors.bgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildAssetsDetailsStep(),
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
  Widget _buildAssetsDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: AccordionCard(
        expanded: true,
        onTap: () {},
        isExpanded: false,
        title: "Asset Details",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustDropdown(
              label: 'Station',
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
              hint: 'Select Date & Time',
              selectedDateTime: _deliveryDate,
              onDateTimeSelected: (dateTime) {
                setState(() {
                  _deliveryDate = dateTime;
                });
              },
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Name of Asset*',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _nameOfAssetController,
              hintText: 'Enter Name of Asset',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Finance Asset Code',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _financeAssetCodeController,
              hintText: 'Enter Finance Asset Code',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Quantity',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _quantityController,
              hintText: 'Enter Quantity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Model Number',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _modelNumberController,
              hintText: 'Enter Model Number',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Asset Description',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _assetDescriptionController,
              hintText: 'Enter Asset Description',
              maxLines: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

} 