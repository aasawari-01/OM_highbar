import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/constants/app_data.dart';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/responsive_helper.dart';
import '../../../utils/widgets/accordion_card.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_date_time_picker.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_radio.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../../../utils/widgets/sync_icon_button.dart';


class PTWFormScreen extends StatefulWidget {
  const PTWFormScreen({Key? key}) : super(key: key);

  @override
  State<PTWFormScreen> createState() => _PTWFormScreenState();
}

class _PTWFormScreenState extends State<PTWFormScreen> {
  // PTW Request Details
  String _selectedRequestType ="Scheduled"; // Scheduled/Emergency
  String? _selectedPTWType;
  String? _selectedVehicleMovement;
  String? _selectedNatureOfWork;
  final TextEditingController _workDescriptionController = TextEditingController();

  // Line and Depot Details
  String? _selectedLocationType = "Line";// Line/Depot
  String? _selectedLine;
  String? _selectedDepot;
  String? _selectedLocationFrom;
  String? _selectedLocationTo;
  String? _selectedDepotLocationFrom;
  String? _selectedDepotLocationTo;
  String? _selectedImpactOnRevenue;

  // Staff Details
  String? _selectedUploadType; // Single/Bulk Upload

  // PTW Staff Date Details
  DateTime? _selectedFromDateTime;
  DateTime? _selectedToDateTime;
  String? _selectedArea;
  String? _selectedSubLocation;
  String? _selectedEntryPoint;
  String? _selectedPriority;
  String? _selectedExitPoint;

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "PTW Request Details",
    "Line and Depot Details",
    "Staff Details",
    "PTW Staff Date Details",
  ];

  final List<String> requestTypeList = ["Scheduled", "Emergency"];
  final List<String> ptwTypeList = ["With Shadow Power Block", "Without Shadow Power Block", "Without Power Block"];
  final List<String> vehicleMovementList = ["Yes", "No"];
  final List natureOfWorkList = [{ "id": 1, "value": 'Train Testing' },
      { "id": 2, "value": 'To Handlling' },
      { "id": 3, "value": 'Inspection' },
      { "id": 4, "value": 'CMV Movement' },
      { "id": 5, "value": 'Trolly Movement' },
      { "id": 6, "value":  'MockDrill' },
      { "id": 7, "value":  'CyclicCheck' },
      { "id": 8, "value":  'Modification'},
      { "id": 9, "value":  'Cleaning' },
      { "id": 10, "value":  'Main Line Fault' },
      { "id": 11, "value":  'DepotFault' },
      { "id": 12, "value":  'Overhaul'},
      { "id": 13, "value":  'Other' }
      ];
  final List<String> locationTypeList = ["Line", "Depot"];
  final List<String> lineList = ["Line 1", "Line 2"];
  final List<String> depotList = ["Depot 1", "Depot 2"];
  final List<String> impactOnRevenueList = ["Yes", "No"];
  final List<Map<String, dynamic>> areaList = [
    {'id': 1, 'value': 'Mainline'},
    {'id': 2, 'value': 'Depot'},
    {'id': 3, 'value': 'Station'},
    {'id': 4, 'value': 'Workshop'},
    {'id': 5, 'value': 'Technical Room'}
  ];
  final List<String> subLocationList = ['Up Line',
    'Down line',
    'Both Up Line & Down line',
    'Up Line Plateform',
    'Down Line Plateform'
    'Both Up Line Plateform & Down Line Plateform'];
  final List<String> priorityList = ['Low', 'Medium', 'High', 'Very High'];

  List<Widget> get _steps => [
    _buildPTWRequestDetailsStep(),
    _buildLineAndDepotDetailsStep(),
    _buildStaffDetailsStep(_selectedLocationType),
    _buildPTWStaffDateDetailsStep(),
  ];

  @override
  void dispose() {
    _workDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: 'PTW Request Form',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: const SyncIconButton(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppConstants.elementSpacing),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: AppConstants.elementSpacing),
            child: FlutterStepIndicator(
              height: 20,
              list: List.generate(_steps.length, (index) => index),
              page: _currentStep,
              division: _steps.length,
              positiveColor: AppColors.gradientStart,
              negativeColor: AppColors.textDarkSecondary,
              progressColor: AppColors.gradientStart,
              onChange: (i) {},
            ),
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          Expanded(
            child: _steps[_currentStep],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: AppConstants.elementSpacing),
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
                    onSelected: (_) => _submitForm(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPTWRequestDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: AccordionCard(
        expanded: true,
        onTap: () {},
        isExpanded: false,
        title: _stepTitles[_currentStep],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustText.formLabel('Type of Request *'),
            const SizedBox(height: AppConstants.labelSpacing),
            Row(
              children: requestTypeList.map((option) => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CustRadio<String>(
                  value: option,
                  groupValue: _selectedRequestType ?? '',
                  label: option,
                  onChanged: (value) {
                    setState(() {
                      _selectedRequestType = value!;
                    });
                  },
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Type Of PTW *',
              hint: 'Select Type Of PTW',
              items: ptwTypeList,
              selectedValue: _selectedPTWType,
              onChanged: (value) {
                setState(() {
                  _selectedPTWType = value;
                });
              },
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustText.formLabel("Vehicle Movement Required *"),
            const SizedBox(height: AppConstants.labelSpacing),
            Row(
              children: vehicleMovementList.map((option) => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CustRadio<String>(
                  value: option,
                  groupValue: _selectedVehicleMovement ?? '',
                  label: option,
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleMovement = value;
                    });
                  },
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Nature Of Work *',
              hint: 'Select Nature Of Work',
              items: natureOfWorkList.map((item) => item['value'] as String).toList(),
              selectedValue: _selectedNatureOfWork,
              onChanged: (value) {
                setState(() {
                  _selectedNatureOfWork = value;
                });
              },
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustText.formLabel('Work Description *'),
            const SizedBox(height: AppConstants.labelSpacing),
            CustomTextField(
              controller: _workDescriptionController,
              hintText: 'Enter Work Description',
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineAndDepotDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: AccordionCard(
        expanded: true,
        onTap: () {},
        isExpanded: false,
        title: _stepTitles[_currentStep],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustText.formLabel('Location Type *'),
            const SizedBox(height: AppConstants.labelSpacing),
            Row(
              children: locationTypeList.map((option) => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CustRadio<String>(
                  value: option,
                  groupValue: _selectedLocationType ?? '',
                  label: option,
                  onChanged: (value) {
                    setState(() {
                      _selectedLocationType = value;
                    });
                  },
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            if (_selectedLocationType == "Line") ...[
              CustDropdown(
                label: 'Line *',
                hint: 'Select Line',
                items: lineList,
                selectedValue: _selectedLine,
                onChanged: (value) {
                  setState(() {
                    _selectedLine = value;
                  });
                },
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              CustDropdown(
                label: 'Location/Station From *',
                hint: 'Select Depot Location/Station From',
                items: stationListValue,
                selectedValue: _selectedLocationFrom,
                onChanged: (value) {
                  setState(() {
                    _selectedLocationFrom = value;
                  });
                },
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              CustDropdown(
                label: 'Location/Station To *',
                hint: 'Select Depot Location/Station To',
                items: stationListValue,
                selectedValue: _selectedLocationTo,
                onChanged: (value) {
                  setState(() {
                    _selectedLocationTo = value;
                  });
                },
              ),
              const SizedBox(height: AppConstants.elementSpacing),
            ],
            if (_selectedLocationType == "Depot") ...[
              CustDropdown(
                label: 'Depot *',
                hint: 'Select Depot',
                items: depotList,
                selectedValue: _selectedDepot,
                onChanged: (value) {
                  setState(() {
                    _selectedDepot = value;
                  });
                },
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              CustDropdown(
                label: 'Depot Location/Station From *',
                hint: 'Select Depot Location/Station From',
                items: stationListValue,
                selectedValue: _selectedDepotLocationFrom,
                onChanged: (value) {
                  setState(() {
                    _selectedDepotLocationFrom = value;
                  });
                },
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              CustDropdown(
                label: 'Depot Location/Station To *',
                hint: 'Select Depot Location/Station To',
                items: stationListValue,
                selectedValue: _selectedDepotLocationTo,
                onChanged: (value) {
                  setState(() {
                    _selectedDepotLocationTo = value;
                  });
                },
              ),
              const SizedBox(height: AppConstants.elementSpacing),
            ],
            CustText.formLabel('Impact On Revenue/Operation *'),
            const SizedBox(height: AppConstants.labelSpacing),
            Row(
              children: impactOnRevenueList.map((option) => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CustRadio<String>(
                  value: option,
                  groupValue: _selectedImpactOnRevenue ?? '',
                  label: option,
                  onChanged: (value) {
                    setState(() {
                      _selectedImpactOnRevenue = value!;
                    });
                  },
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffDetailsStep(_selectedLocationType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: AccordionCard(
        expanded: true,
        onTap: () {},
        isExpanded: false,
        title: _stepTitles[_currentStep],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs for Single Upload and Bulk Upload
            // Container(
            //   decoration: BoxDecoration(
            //     border: Border.all(color: AppColors.textFieldColor),
            //     borderRadius: BorderRadius.circular(8),
            //   ),
            //   child: Row(
            //     children: uploadTypeList.map((type) {
            //       final isSelected = _selectedUploadType == type;
            //       return Expanded(
            //         child: GestureDetector(
            //           onTap: () {
            //             setState(() {
            //               _selectedUploadType = type;
            //             });
            //           },
            //           child: Container(
            //             padding: const EdgeInsets.symmetric(vertical: 12),
            //             decoration: BoxDecoration(
            //               color: isSelected ? AppColors.textBlueSecondary : Colors.transparent,
            //               borderRadius: BorderRadius.circular(8),
            //             ),
            //             child: Center(
            //               child: CustText(
            //                 name: type,
            //                 size: 16,
            //                 color: isSelected ? Colors.white : AppColors.textDarkPrimary,
            //                 fontWeightName: FontWeight.w500,
            //               ),
            //             ),
            //           ),
            //         ),
            //       );
            //     }).toList(),
            //   ),
            // ),
            const SizedBox(height: AppConstants.elementSpacing),
            Align(
              alignment: Alignment.centerRight,
              child: CustButton(
                name: 'Add Staff Details',
                size: 50,
                onSelected: (bool _) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AddStaffDetailsDialog(selectedLocationType: _selectedLocationType);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPTWStaffDateDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: AccordionCard(
        expanded: true,
        onTap: () {},
        isExpanded: false,
        title: _stepTitles[_currentStep],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustDateTimePicker(
              label: 'From Date & Time *',
              hint: 'DD/MM/YYYY HH:mm',
              selectedDateTime: _selectedFromDateTime,
              onDateTimeSelected: (dateTime) {
                setState(() {
                  _selectedFromDateTime = dateTime;
                  // Clear "To Date & Time" when "From Date & Time" changes
                  if (_selectedToDateTime != null && dateTime != null && _selectedToDateTime!.isBefore(dateTime)) {
                    _selectedToDateTime = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            AbsorbPointer(
              absorbing: _selectedFromDateTime == null,
              child: Opacity(
                opacity: _selectedFromDateTime == null ? 0.5 : 1.0,
                child: CustDateTimePicker(
                  label: 'To Date & Time *',
                  hint: _selectedFromDateTime == null ? 'Select From Date & Time first' : 'DD/MM/YYYY HH:mm',
                  selectedDateTime: _selectedToDateTime,
                  onDateTimeSelected: (dateTime) {
                    if (dateTime == null) return;

                    if (_selectedFromDateTime != null && dateTime.isAfter(_selectedFromDateTime!)) {
                      setState(() {
                        _selectedToDateTime = dateTime;
                      });
                    } else {
                      // Show error message if selected date is before or equal to from date
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('To Date & Time must be after From Date & Time'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: 'Area *',
              hint: 'Select Area',
              items: areaList.map((item) => item['value'] as String).toList(),
              selectedValue: _selectedArea,
              onChanged: (value) {
                setState(() {
                  _selectedArea = value;
                });
              },
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: 'Sub Location *',
              hint: 'Select Sub Location',
              items: subLocationList,
              selectedValue: _selectedSubLocation,
              onChanged: (value) {
                setState(() {
                  _selectedSubLocation = value;
                });
              },
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: 'Entry Point *',
              hint: 'Select Entry Point',
              items: stationListValue,
              selectedValue: _selectedEntryPoint,
              onChanged: (value) {
                setState(() {
                  _selectedEntryPoint = value;
                });
              },
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: 'Priority *',
              hint: 'Select Priority',
              items: priorityList,
              selectedValue: _selectedPriority,
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value;
                });
              },
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: 'Exit Point *',
              hint: 'Select Exit Point',
              items: stationListValue,
              selectedValue: _selectedExitPoint,
              onChanged: (value) {
                setState(() {
                  _selectedExitPoint = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    // TODO: Implement submit logic
    print('PTW Form submitted');
  }
}

class AddStaffDetailsDialog extends StatefulWidget {
  final String? selectedLocationType;
  
  const AddStaffDetailsDialog({
    Key? key,
    this.selectedLocationType,
  }) : super(key: key);

  @override
  State<AddStaffDetailsDialog> createState() => _AddStaffDetailsDialogState();
}

class _AddStaffDetailsDialogState extends State<AddStaffDetailsDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedOrganization;
  final TextEditingController _designationController = TextEditingController();
  String? _selectedRole;
  String? _selectedStaffEntryPoint;

  final List<String> organizationList = [
    'Maha Metro',
    'Other'
  ];
  final List<String> roleList = ['EPIC','PTW Coordinator','Shift Supervisor'];
  final List<String> staffEntryPointList = [
    'Entry Point 1',
    'Entry Point 2',
    'Entry Point 3',
    'Entry Point 4'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 15, bottom: 10, right: 15),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: CustText(
              name: "Add Staff Details",
              size: 18,
              color: AppColors.textBlueSecondary,
              fontWeightName: FontWeight.w500,
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 32,
                    runSpacing: 24,
                    children: [
                      SizedBox(
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustText(
                              name: 'Name',
                              size: 18,
                              fontWeightName: FontWeight.w500,
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _nameController,
                              hintText: 'Enter name',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustDropdown(
                              label: 'Organization',
                              hint: 'Select Organization',
                              items: organizationList,
                              selectedValue: _selectedOrganization,
                              onChanged: (value) {
                                setState(() {
                                  _selectedOrganization = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustText(
                              name: 'Designation',
                              size: 18,
                              fontWeightName: FontWeight.w500,
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _designationController,
                              hintText: 'Enter Designation',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustDropdown(
                              label: 'Role',
                              hint: 'Select Role',
                              items: roleList,
                              selectedValue: _selectedRole,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if(widget.selectedLocationType == "Line")...[
                        SizedBox(
                          width: 320,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustDropdown(
                                label: 'Staff Entry Point',
                                hint: 'Select Staff Entry Point',
                                items: stationListValue,
                                selectedValue: _selectedStaffEntryPoint,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStaffEntryPoint = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.textBlueSecondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textBlueSecondary)),
                      ),
                      const SizedBox(width: 16),
                      CustButton(
                        name: "Save",
                        size: 30,
                        onSelected: (p0) {
                          Navigator.pop(context);
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 