import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/cust_button.dart';
import 'package:om_mobile/widgets/cust_date_picker.dart';
import 'package:om_mobile/widgets/cust_dropdown.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/station_failure_screen.dart';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';
import 'constants/app_data.dart';

import 'complaint_feedback_screen.dart';
import 'widgets/custom_dialog.dart'; // For CustDatePicker

enum InspectionPlan { scheduled, unscheduled }

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({Key? key}) : super(key: key);

  @override
  _InspectionScreenState createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  InspectionPlan _selectedPlan = InspectionPlan.scheduled; // Default to Scheduled
  String? _selectedDepartment;
  String? _selectedInspectionType;
  String? _selectedFrequency;
  DateTime? _selectedInspectionScheduledDate;
  String? _selectedInspectionBy;

  String? _selectedFromStation;
  String? _selectedToStation;
  String? _selectedTrain;
  String? _selectedDepot;
  String? _selectedLocationOfTrain;
  String? _selectedDccName;

  final List<String> trainList = ['Train 1', 'Train 2', 'Train 3'];
  final List<String> depotList = ['Depot 1', 'Depot 2', 'Depot 3'];
  final List<String> locationOfTrainList = ['Location 1', 'Location 2', 'Location 3'];
  final List<String> dccNameList = ['DCC 1', 'DCC 2', 'DCC 3'];

  // Map of department to inspection types
  final Map<String, List<String>> departmentInspectionTypes = {
    'Signalling': [
      'Foot plate',
      'On-board',
      'Stations-SE',
      'Wayside',
      'OCC/BOCC',
      'General Inspection',
      'Stations-JE',
    ],
    'Rolling Stock': [
      'General Inspection',
    ],
    'Track': [
      'Curve Inspection',
      'General Inspection',
      'Creep Measurement',
      'Temperature Monitoring',
      'OMS',
      'Pilot Train Inspection',
      'Cab Inspection',
      'Foot Ins',
      'Toe Load',
      'Turn Out',
      'Buffer Stop',
      'Ultrasonic Flaw Detection USFD',
      'Inspection of floating track - slab with spring',
      'scissor crossover inspection',
      'atweld inspection',
    ],
    'Information Technology': [
      'General Inspection',
    ],
    'Civil': [
      'General Inspection',
      'Detailed station inspection',
      'Inspection of Gaddigodaam OWG Bridge',
      'Routine Station Inspection',
      'Routine Inspection of Viaduct',
      'Detailed Inspection of Structural Steelworks of Station',
      'Detailed Inspection of Structural Steel Bridge',
      'Routine Inspection of Structural Steelworks of Station',
      'Routine Inspection of Structural Steel Bridge',
      'Detailed Depot Inspection Report',
      'Routine Depot Inspection Report',
      'Routine Premonsoon Test',
      'Inspection of Structural Steel View Cutter',
      'Inspection of Structural Signal Post Platform',
      'Inspection Details of POT PTFE/ Spherical Bearing',
      'Special Inspection of Viaduct',
      'Inspection Details of Elastomeric Bearing',
      'Detailed Inspection of Viaduct',
    ],
    'Human Resource': [
      'General Inspection',
    ],
    'Operation Chief Controller': [
      'General Inspection',
    ],
    'Crew Management System': [
      'General Inspection',
    ],
  };

  // Map of department and inspection type to required fields
  final Map<String, Map<String, List<String>>> inspectionFields = {
    'Signalling': {
      'Foot plate': ['From Station', 'To Station'],
      'On-board': ['Train', 'Depot', 'Location of Train', 'DCC Name'],
      'Stations-SE': ['Station'],
      'Wayside': ['From Station', 'To Station'],
      'OCC/BOCC': ['Default'],
      'General Inspection': ['Default'],
      'Stations-JE': ['Station'],
    },
    'Rolling Stock': {
      'General Inspection': ['Default'],
    },
    'Track': {
      'Curve Inspection': ['Track Functional Location *'],
      'General Inspection': ['Default'],
      'Creep Measurement': ['Start Kilometer', 'End Kilometer', 'From Station', 'To Station'],
      'Temperature Monitoring': ['Station'],
      'OMS': ['Line', 'Line (Up/Down)'],
      'Pilot Train Inspection': ['From Station', 'To Station'],
      'Cab Inspection': ['From Station', 'To Station'],
      'Foot Ins': ['Station'],
      'Toe Load': ['Station', 'Start Kilometer', 'End Kilometer', 'From Station', 'To Station'],
      'Turn Out': ['Default'],
      'Buffer Stop': ['Station', 'Functional Location'],
      'Ultrasonic Flaw Detection USFD': ['Name of Operator', 'InspectionUFDI Plan', 'Station', 'Start Kilometer', 'End Kilometer', 'From Station', 'To Station'],
      'Inspection of floating track - slab with spring': ['Station', 'Line (Up/Down)'],
      'scissor crossover inspection': ['Default'],
      'atweld inspection': ['Depot', 'Line', 'Track Structure', 'From Station', 'To Station', 'Other Lines(depot)'],
    },
    'Information Technology': {
      'General Inspection': ['Default'],
    },
    'Civil': {
      'General Inspection': ['Default'],
      'Detailed station inspection': ['Station', 'Reach', 'Month', 'Start Date', 'End Date'],
      'Inspection of Gaddigodaam OWG Bridge': ['Reach', 'Last Inspection Date', 'start date', 'end date', 'span between pier no', 'type of girder', 'effective length', 'CRN No'],
      'Routine Station Inspection': ['Station', 'Month', 'Start Date', 'End Date'],
      'Routine Inspection of Viaduct': ['section (7-07 chainage)', 'span no', 'pier no', 'viaduct structure type'],
      'Detailed Inspection of Structural Steelworks of Station': ['station', 'Reach', 'Last Inspection Date', 'start date', 'end date'],
      'Detailed Inspection of Structural Steel Bridge': ['Name of Section', 'Last Inspection Date', 'Start Date', 'End Date', 'No of Girders', 'Span Between Pier No', 'From Station', 'To Station', 'Type of Girder', 'Effective Length', 'CRN No.'],
      'Routine Inspection of Structural Steelworks of Station': ['station', 'Reach', 'Last Inspection Date', 'start date', 'end date'],
      'Routine Inspection of Structural Steel Bridge': ['Reach', 'Last Inspection Date', 'Start Date', 'End Date', 'No of Girders', 'Span Between Pier No', 'From Station', 'To Station', 'Type of Girder', 'Effective Length'],
      'Detailed Depot Inspection Report': ['Station', 'Building Structure', 'Month', 'Start Date', 'End Date'],
      'Routine Depot Inspection Report': ['Station', 'Building Structure', 'Month', 'Start Date', 'End Date'],
      'Routine Premonsoon Test': ['Station'],
      'Inspection of Structural Steel View Cutter': ['Name of Section', 'From Station', 'To Station', 'Span No', 'Span Length', 'Last Inspection Date', 'Start Date', 'End Date'],
      'Inspection of Structural Signal Post Platform': ['Name of Section', 'From Station', 'To Station', 'Span No', 'No. of Signal Post Platforms', 'Last Inspection Date', 'Start Date', 'End Date'],
      'Inspection Details of POT PTFE/ Spherical Bearing': ['Default'],
      'Special Inspection of Viaduct': ['Reach', 'From Station', 'To Station', 'Viaduct Category', 'Location', 'Span No', 'Pier No', 'Viaduct Structure Type', 'Start Date', 'End Date', 'ORN No', 'URN No.'],
      'Inspection Details of Elastomeric Bearing': ['Reach', 'From Station', 'To Station', 'Viaduct Category', 'Location', 'Span No.', 'Pier No.', 'Viaduct Structure Type', 'Entry Date', 'ORN No'],
      'Detailed Inspection of Viaduct': ['Span No.', 'Pier No.', 'Viaduct Structure Type'],
    },
    'Human Resource': {
      'General Inspection': ['Default'],
    },
    'Operation Chief Controller': {
      'General Inspection': ['Default'],
    },
    'Crew Management System': {
      'General Inspection': ['Default'],
    },
  };

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "Inspection Details",
  ];

  List<Widget> get _steps => [
    _buildInspectionDetailsStep(),
  ];

  // Controllers for dynamic fields
  final Map<String, TextEditingController> _fieldControllers = {};

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate, ValueChanged<DateTime?> onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      onDateSelected(picked);
    }
  }


  List<String> getSelectedFields() {
    if (_selectedDepartment != null && _selectedInspectionType != null) {
      return inspectionFields[_selectedDepartment!]?[_selectedInspectionType!] ?? [];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: 'Create Inspection',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 1 * SizeConfig.heightMultiplier,),
          Expanded(
            child: _steps[_currentStep],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 1 * SizeConfig.heightMultiplier, horizontal: 4 * SizeConfig.widthMultiplier),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustButton(
                  name: 'Submit',
                  size: 30,
                  onSelected: (p0) {
                    Get.dialog(CustomDialog("Saved Successfully."));
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 1 * SizeConfig.heightMultiplier,)
        ],
      ),
    );
  }

  Widget _buildInspectionDetailsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 2 * SizeConfig.heightMultiplier, left: 12, right: 12, bottom: 12),
      child: AccordionCard(
        isExpanded: false,
        expanded: true,
        title: _stepTitles[_currentStep],
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustText(
              name: "Inspection Plan",
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            Row(
              children: [
                _buildCircularCheckbox(
                  label: 'Scheduled',
                  value: InspectionPlan.scheduled,
                  groupValue: _selectedPlan,
                  onChanged: (InspectionPlan? value) {
                    setState(() {
                      _selectedPlan = value!;
                    });
                  },
                ),
                _buildCircularCheckbox(
                  label: 'Unscheduled',
                  value: InspectionPlan.unscheduled,
                  groupValue: _selectedPlan,
                  onChanged: (InspectionPlan? value) {
                    setState(() {
                      _selectedPlan = value!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 2 * SizeConfig.heightMultiplier),
            CustDropdown(
              label: 'Department',
              hint: 'Select',
              items: departmentInspectionTypes.keys.toList(),
              selectedValue: _selectedDepartment,
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value;
                  _selectedInspectionType = null; // Reset inspection type when department changes
                });
              },
            ),
            SizedBox(height: 2 * SizeConfig.heightMultiplier),
            CustText(
              name: "Designation",
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            SizedBox(height: 1 * SizeConfig.heightMultiplier),
            CustomTextField(
              controller: TextEditingController(text: 'Default Account Holder Designation'),
              hintText: 'Default Account Holder Designation',
              readOnly: true,
              fillColor: AppColors.textFieldFillColor,
            ),
            SizedBox(height: 2 * SizeConfig.heightMultiplier),
            CustDropdown(
              label: 'Inspection Type',
              hint: 'Select inspection type',
              items: _selectedDepartment != null && departmentInspectionTypes[_selectedDepartment!] != null
                  ? departmentInspectionTypes[_selectedDepartment!]!
                  : departmentInspectionTypes["Signalling"]!,
              selectedValue: _selectedInspectionType,
              onChanged: (value) {
                setState(() {
                  _selectedInspectionType = value;
                });
              },
            ),
            SizedBox(height: 2 * SizeConfig.heightMultiplier),
            CustDropdown(
              label: 'Frequency',
              hint: 'Select frequency',
              items: const ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Half-Yearly', 'Yearly'],
              selectedValue: _selectedFrequency,
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value;
                });
              },
            ),
            SizedBox(height: 2 * SizeConfig.heightMultiplier),
            if (_selectedPlan == InspectionPlan.scheduled) ...[
              CustDatePicker(
                label: 'Inspection Scheduled Date',
                hint: 'Select date',
                selectedDate: _selectedInspectionScheduledDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedInspectionScheduledDate = date;
                  });
                },
              ),
              SizedBox(height: 2 * SizeConfig.heightMultiplier),
              CustDropdown(
                label: 'Inspection By',
                hint: 'Select inspection by',
                items: const ['User 1', 'User 2', 'User 3'],
                selectedValue: _selectedInspectionBy,
                onChanged: (value) {
                  setState(() {
                    _selectedInspectionBy = value;
                  });
                },
              ),
              ...getSelectedFields().map((field) {
                if (field == 'Default') {
                  return SizedBox.shrink();
                }
                if (field == 'From Station') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2 * SizeConfig.heightMultiplier),
                      CustDropdown(
                        label: field,
                        hint: 'Select $field',
                        items: stationListValue,
                        selectedValue: _selectedFromStation,
                        onChanged: (value) {
                          setState(() {
                            _selectedFromStation = value;
                          });
                        },
                      ),
                    ],
                  );
                }

                if (field == 'To Station') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2 * SizeConfig.heightMultiplier),
                      CustDropdown(
                        label: field,
                        hint: 'Select $field',
                        items: stationListValue,
                        selectedValue: _selectedToStation,
                        onChanged: (value) {
                          setState(() {
                            _selectedToStation = value;
                          });
                        },
                      ),
                    ],
                  );
                }
                if (field == 'Train') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2 * SizeConfig.heightMultiplier),
                      CustDropdown(
                        label: field,
                        hint: 'Select $field',
                        items: trainList,
                        selectedValue: _selectedTrain,
                        onChanged: (value) {
                          setState(() {
                            _selectedTrain = value;
                          });
                        },
                      ),
                    ],
                  );
                }
                if (field == 'Depot') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2 * SizeConfig.heightMultiplier),
                      CustDropdown(
                        label: field,
                        hint: 'Select $field',
                        items: depotList,
                        selectedValue: _selectedDepot,
                        onChanged: (value) {
                          setState(() {
                            _selectedDepot = value;
                          });
                        },
                      ),
                    ],
                  );
                }
                if (field == 'Location of Train') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2 * SizeConfig.heightMultiplier),
                      CustDropdown(
                        label: field,
                        hint: 'Select $field',
                        items: locationOfTrainList,
                        selectedValue: _selectedLocationOfTrain,
                        onChanged: (value) {
                          setState(() {
                            _selectedLocationOfTrain = value;
                          });
                        },
                      ),
                    ],
                  );
                }
                if (field == 'DCC Name') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2 * SizeConfig.heightMultiplier),
                      CustDropdown(
                        label: field,
                        hint: 'Select $field',
                        items: dccNameList,
                        selectedValue: _selectedDccName,
                        onChanged: (value) {
                          setState(() {
                            _selectedDccName = value;
                          });
                        },
                      ),
                    ],
                  );
                }
                _fieldControllers.putIfAbsent(field, () => TextEditingController());
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2 * SizeConfig.heightMultiplier),
                    CustText(
                      name: field,
                      size: 1.8,
                      fontWeightName: FontWeight.w500,
                    ),
                    SizedBox(height: 1 * SizeConfig.heightMultiplier),
                    CustomTextField(
                      controller: _fieldControllers[field]!,
                      hintText: 'Enter $field',
                    ),
                  ],
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCircularCheckbox({
    required String label,
    required InspectionPlan value,
    required InspectionPlan groupValue,
    required ValueChanged<InspectionPlan?> onChanged,
  }) {
    final bool isSelected = (value == groupValue);
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24, // Size of the circular checkbox
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.appBarColor : Colors.grey,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.appBarColor : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: 8),
              CustText(name: label, size: 1.6),
            ],
          ),
        ),
      ),
    );
  }
} 