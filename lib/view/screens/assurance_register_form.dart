import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_data.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/cust_button.dart';
import 'package:om_mobile/widgets/cust_date_picker.dart';
import 'package:om_mobile/widgets/cust_dropdown.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/file_upload_section.dart';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';

import 'widgets/custom_dialog.dart';

class AssuranceRegisterForm extends StatefulWidget {
  const AssuranceRegisterForm({Key? key}) : super(key: key);

  @override
  State<AssuranceRegisterForm> createState() => _AssuranceRegisterFormState();
}

class _AssuranceRegisterFormState extends State<AssuranceRegisterForm> {
  // Field values
  String? _selectedDocumentType;
  String? _selectedLine;
  DateTime? _assuranceTopicDate;
  String? _selectedStationLocation;
  final TextEditingController _documentNumberController = TextEditingController();
  final TextEditingController _assuranceTopicDescriptionController = TextEditingController();
  List<String> _uploadedFiles = [];

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "Assurance Details",
  ];

  // Dropdown values
  final List<String> documentTypeList = [
    "Temporary Instruction",
    "Safety Circular",
    "Special Instruction",
    "Standard Operating Procedure",
    "Joint Procedure",
    "Statutory",
    "Manual",
    "Instruction",
    "Other",
  ];

  final List<String> lineList = [
    "Line 1", "Line 2","Line 3"
  ];

  final List<String> stationLocationList = [
    "KHP -  Khapri ",
    "NAP - New Airport ",
    "SAT -  Airport South ",
    "NAO -  Airport ",
    "UJR -  Ujjwal Nagar ",
    "JIN -  Jaiprakash Nagar ",
    "CQE -  Charapati Square ",
    "AJS -  Ajni Square ",
    "RHC -  Rahate Colony ",
    "CSS -  Congress Nagar ",
    "SIT -  SitaBuldi ",
    "ZOM -  Zero Mile ",
    "KPR -  Kasturchand Park ",
    "GSE -  GaddiGodam Square ",
    "KVW -  Kadvi Chowk ",
    "IDK -  Indora Chowk ",
    "NAR -  Nari Road ",
    "AQS -  Automotive Square ",
    "PJG -  Prajapati Nagar ",
    "LON - LOKMANYA",
    "BAN - BANSI NAGAR",
    "VAN - VASUDEO NAGR",
    "RRR - RACHNA RING ROAD",
    "SBN - SUBHASH NAGAR",
    "DPC - DHARAMPETH COLLEGE",
    "LAD - LAD SQUARE",
    "SNS - SHANKAR NAGAR",
    "IOE - INSTITUTE OF ENGINEER",
    "JRS - JHANSI RANI SQUARE",
    "CMS - COTTON MARKET SQUARE",
    "NRS - NAGPUR RAILWAY STATION",
    "DVC - DOSAR VAISHYA CHOWK",
    "AGN - AGRASEN",
    "CHC - CHITAROLI CHOWK",
    "TEE - TELEPHONE EXCHANGE",
    "AMC - AMBEDKAR CHOWK",
    "VDC - VAISHNO DEVI CHOWK",
    "SIT - SitaBuldi"
  ];

  List<Widget> get _steps => [
    _buildDocumentDetailsStep(),
  ];

  @override
  void dispose() {
    _documentNumberController.dispose();
    _assuranceTopicDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "Assurance Register Form"),
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

  Widget _buildDocumentDetailsStep() {
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
              label: 'Document Type',
              hint: 'Select Document Type',
              items: documentTypeList,
              selectedValue: _selectedDocumentType,
              onChanged: (value) {
                setState(() {
                  _selectedDocumentType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Line',
              hint: 'Select Line',
              items: lineList,
              selectedValue: _selectedLine,
              onChanged: (value) {
                setState(() {
                  _selectedLine = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustDatePicker(
              label: 'Assurance Topic Date',
              hint: 'DD/MM/YYYY',
              selectedDate: _assuranceTopicDate,
              onDateSelected: (date) {
                setState(() {
                  _assuranceTopicDate = date;
                });
              },
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Station/Location',
              hint: 'Select Station/Location',
              items: stationListValue,
              selectedValue: _selectedStationLocation,
              onChanged: (value) {
                setState(() {
                  _selectedStationLocation = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Document Number',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _documentNumberController,
              hintText: 'Enter Document Number',
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Assurance Topic Description',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _assuranceTopicDescriptionController,
              hintText: 'Enter Assurance Topic Description',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Attachment',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            FileUploadSection(files: [], onFilesChanged: (p0) {

            },)
          ],
        ),
      ),
    );
  }


} 