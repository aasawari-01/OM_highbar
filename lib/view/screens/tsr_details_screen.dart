import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/cust_button.dart';
import 'package:om_mobile/widgets/cust_date_picker.dart';
import 'package:om_mobile/widgets/cust_dropdown.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/constants/app_data.dart';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';

class TSRDetailsScreen extends StatefulWidget {
  const TSRDetailsScreen({Key? key}) : super(key: key);

  @override
  State<TSRDetailsScreen> createState() => _TSRDetailsScreenState();
}

class _TSRDetailsScreenState extends State<TSRDetailsScreen> {
  // TSR Details
  String? _selectedDepartment;
  DateTime? _selectedImpositionDate;
  TimeOfDay? _selectedImpositionTime;
  String? _selectedLine;
  String? _selectedDirection;
  String? _selectedStationFrom;
  String? _selectedStationTo;
  int _speedRestriction = 0;
  final TextEditingController _specificTSRLocationController = TextEditingController();
  final TextEditingController _reasonForTSRController = TextEditingController();
  DateTime? _selectedExpectedClosingDateTime;

  // TSR Approval Details
  String _tsrNo = "SIG/10-2024/0024";
  String _departmentName = "Department Name";
  DateTime _createdOn = DateTime(2024, 10, 17, 14, 0);
  String _status = "Implemented by TC";
  
  // Operation Details
  String? _selectedTSRByATS;
  String? _selectedTSRByCaution;
  final TextEditingController _additionalCautionController = TextEditingController();
  
  // TSR Implementation
  String? _selectedInformedToStationController;
  final TextEditingController _informedToStationRemarkController = TextEditingController();
  String? _selectedInformedToAllTrains;
  final TextEditingController _informedToAllTrainsRemarkController = TextEditingController();
  String? _selectedInformedToAllCrewController;
  final TextEditingController _informedToAllCrewRemarkController = TextEditingController();
  
  // Complete TSR Details
  final TextEditingController _completeTSRDetailsController = TextEditingController();
  final TextEditingController _completeOperationDetailsController = TextEditingController();
  final TextEditingController _completeImplementationDetailsController = TextEditingController();
  
  // Tab control
  int _selectedTabIndex = 0;

  // View control - true for form, false for details
  bool _showForm = true;

  final List<String> departmentList = ["OCC", "Maintenance", "Operations", "Safety"];
  final List<String> lineList = ["Line A", "Line B", "Line C", "Line D"];
  final List<String> directionList = ["North", "South", "East", "West", "Both"];
  final List<String> stationList = ["Station A", "Station B", "Station C", "Station D"];
  final List<String> tsrByATSList = ["ATS 1", "ATS 2", "ATS 3"];
  final List<String> tsrByCautionList = ["Caution 1", "Caution 2", "Caution 3"];
  final List<String> yesNoList = ["Yes", "No"];

  @override
  void dispose() {
    _specificTSRLocationController.dispose();
    _reasonForTSRController.dispose();
    _additionalCautionController.dispose();
    _informedToStationRemarkController.dispose();
    _informedToAllTrainsRemarkController.dispose();
    _informedToAllCrewRemarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: 'TSR Details',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      backgroundColor: AppColors.bgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 1 * SizeConfig.heightMultiplier),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                children: [
                  // TSR Form Section
                  _buildTSRForm(),
                  SizedBox(height: 2 * SizeConfig.heightMultiplier),
                  
                  // TSR Details Section
                  _buildTSROverviewSection(),
                  SizedBox(height: 1 * SizeConfig.heightMultiplier),
                  _buildTabSection(),
                  SizedBox(height: 1 * SizeConfig.heightMultiplier),
                  _selectedTabIndex == 0 ? _buildTSRFormDetails() : _buildTSRHistory(),
                ],
              ),
            ),
          ),
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTSROverviewSection() {
    return AccordionCard(
      expanded: true,
      onTap: () {},
      isExpanded: false,
      title: "",
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustText(
                name: 'TSR No: $_tsrNo',
                size: 2.0,
                fontWeightName: FontWeight.w600,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.dividerColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CustText(
                  name: 'Status: $_status',
                  size: 1.6,
                  fontWeightName: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Department', _departmentName),
              const SizedBox(height: 4),
              _buildDetailRow('Created On:', "${_createdOn.day.toString().padLeft(2, '0')}-${_createdOn.month.toString().padLeft(2, '0')}-${_createdOn.year} ${_createdOn.hour.toString().padLeft(2, '0')}:${_createdOn.minute.toString().padLeft(2, '0')}"),
            ],
          ),
          const SizedBox(height: 16),
          CustText(
            name: 'Timeline',
            size: 1.8,
            fontWeightName: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustText(
                    name: 'Created',
                    size: 1.6,
                    fontWeightName: FontWeight.w500,
                  ),
                  const SizedBox(width: 8),
                  CustText(
                    name: '${_createdOn.day.toString().padLeft(2, '0')}-${_createdOn.month.toString().padLeft(2, '0')}-${_createdOn.year} ${_createdOn.hour.toString().padLeft(2, '0')}:${_createdOn.minute.toString().padLeft(2, '0')}',
                    size: 1.4,
                    color: AppColors.textColor4,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? AppColors.textColor3 : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: CustText(
                    name: 'TSR Form Details',
                    size: 1.6,
                    color: _selectedTabIndex == 0 ? Colors.white : AppColors.textColor,
                    fontWeightName: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? AppColors.textColor3 : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: CustText(
                    name: 'TSR History',
                    size: 1.6,
                    color: _selectedTabIndex == 1 ? Colors.white : AppColors.textColor,
                    fontWeightName: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTSRForm() {
    return AccordionCard(
      expanded: true,
      onTap: () {},
      isExpanded: false,
      title: "TSR Details",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 1 * SizeConfig.heightMultiplier),
          // Department
          CustDropdown(
            label: 'Department *',
            hint: 'Select Department',
            items: departmentList,
            selectedValue: _selectedDepartment,
            onChanged: (value) {
              setState(() {
                _selectedDepartment = value;
              });
            },
          ),
          SizedBox(height: 2 * SizeConfig.heightMultiplier),
          
          // Imposition Date
          CustDatePicker(
            label: 'Imposition Date',
            hint: 'DD/MM/YYYY',
            selectedDate: _selectedImpositionDate,
            onDateSelected: (date) {
              setState(() {
                _selectedImpositionDate = date;
              });
            },
          ),
          SizedBox(height: 2 * SizeConfig.heightMultiplier),
          
          // Imposition Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustText(
                name: 'Imposition Time',
                size: 1.8,
                fontWeightName: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedImpositionTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedImpositionTime = picked;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: CustomTextField(
                    controller: TextEditingController(
                      text: _selectedImpositionTime != null 
                          ? _selectedImpositionTime!.format(context) 
                          : '',
                    ),
                    hintText: 'HH:mm',
                    suffixIcon: const Icon(Icons.access_time),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2 * SizeConfig.heightMultiplier),
          
          // Line
          CustDropdown(
            label: 'Line',
            hint: 'Select',
            items: lineList,
            selectedValue: _selectedLine,
            onChanged: (value) {
              setState(() {
                _selectedLine = value;
              });
            },
          ),
          SizedBox(height: 2 * SizeConfig.heightMultiplier),
          
          // Direction
          CustDropdown(
            label: 'Direction',
            hint: 'Select Direction',
            items: directionList,
            selectedValue: _selectedDirection,
            onChanged: (value) {
              setState(() {
                _selectedDirection = value;
              });
            },
          ),
          SizedBox(height: 2 * SizeConfig.heightMultiplier),
          
          // Station From
          CustDropdown(
            label: 'Station From',
            hint: 'Select Station',
            items: stationList,
            selectedValue: _selectedStationFrom,
            onChanged: (value) {
              setState(() {
                _selectedStationFrom = value;
              });
            },
          ),
          SizedBox(height: 2 * SizeConfig.heightMultiplier),
          
          // Station To
          CustDropdown(
            label: 'Station To',
            hint: 'Select Station',
            items: stationList,
            selectedValue: _selectedStationTo,
            onChanged: (value) {
              setState(() {
                _selectedStationTo = value;
              });
            },
          ),
          SizedBox(height: 2 * SizeConfig.heightMultiplier),
          
          // Speed Restriction
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustText(
                name: 'Temporary Speed Restriction (In Kmph)',
                size: 1.8,
                fontWeightName: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_speedRestriction > 0) {
                        setState(() {
                          _speedRestriction--;
                        });
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.textColor3,
                  ),
                  Expanded(
                    child: CustomTextField(
                      controller: TextEditingController(
                        text: _speedRestriction.toString().padLeft(2, '0'),
                      ),
                      hintText: '00',
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final intValue = int.tryParse(value) ?? 0;
                        setState(() {
                          _speedRestriction = intValue;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _speedRestriction++;
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.textColor3,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2 * SizeConfig.heightMultiplier),
          
          // Specific TSR Location
          CustText(
            name: 'Specific TSR Location',
            size: 1.8,
            fontWeightName: FontWeight.w500,
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _specificTSRLocationController,
            hintText: 'Enter Location',
          ),
          SizedBox(height: 2 * SizeConfig.heightMultiplier),
          
          // Reason For TSR
          CustText(
            name: 'Reason For TSR',
            size: 1.8,
            fontWeightName: FontWeight.w500,
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _reasonForTSRController,
            hintText: 'Description',
            maxLines: 4,
          ),
          SizedBox(height: 2 * SizeConfig.heightMultiplier),
          
          // Expected Date & Time of Closing
          CustDatePicker(
            label: 'Expected Date & Time of Closing',
            hint: 'DD/MM/YYYY',
            selectedDate: _selectedExpectedClosingDateTime,
            onDateSelected: (date) {
              setState(() {
                _selectedExpectedClosingDateTime = date;
              });
            },
          ),
          SizedBox(height: 1 * SizeConfig.heightMultiplier),
        ],
      ),
    );
  }

  Widget _buildTSRFormDetails() {
    return Column(
      children: [
        // TSR Details Section
        AccordionCard(
          expanded: true,
          onTap: () {},
          isExpanded: false,
          title: "TSR Details",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Two-column layout for TSR Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Department', _departmentName),
                        const SizedBox(height: 12),
                        _buildDetailRow('Time', 'Functional Location'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Direction', 'Actual Failure Occurrence'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Station To', 'Person Responsible'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Specific TSR Location', 'Actual Failure Occurrence'),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Date', 'Location'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Line', 'Equipment Number'),

                        const SizedBox(height: 12),
                        _buildDetailRow('Station From', 'Functional Location'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Temporary Speed Restriction (in Kmph)', 'Actual Failure Occurrence'),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
              _buildDetailRow('Expected Date & Time of Cancellation', 'Person Responsible'),
              const SizedBox(height: 16),
              CustText(
                name: 'Reason for TSR',
                size: 1.8,
                fontWeightName: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: TextEditingController(
                  text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                ),
                hintText: 'Description',
                maxLines: 4,
                enabled: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Operation Details Section
        AccordionCard(
          expanded: true,
          onTap: () {},
          isExpanded: false,
          title: "Operation Details",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustDropdown(
                      label: 'TSR By ATS',
                      hint: 'Select Station',
                      items: tsrByATSList,
                      selectedValue: _selectedTSRByATS,
                      onChanged: (value) {
                        setState(() {
                          _selectedTSRByATS = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustDropdown(
                      label: 'TSR By Caution',
                      hint: 'Select Station',
                      items: tsrByCautionList,
                      selectedValue: _selectedTSRByCaution,
                      onChanged: (value) {
                        setState(() {
                          _selectedTSRByCaution = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustText(
                name: 'Additional Caution (if any)',
                size: 1.8,
                fontWeightName: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _additionalCautionController,
                hintText: 'Description',
                maxLines: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // TSR Implementation Section
        AccordionCard(
          expanded: true,
          onTap: () {},
          isExpanded: false,
          title: "TSR Implementation",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informed To Station Controller
              Row(
                children: [
                  Expanded(
                    child: CustDropdown(
                      label: 'Informed To Station Controller?',
                      hint: 'Select',
                      items: yesNoList,
                      selectedValue: _selectedInformedToStationController,
                      onChanged: (value) {
                        setState(() {
                          _selectedInformedToStationController = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustText(
                          name: 'Enter remark',
                          size: 1.8,
                          fontWeightName: FontWeight.w500,
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _informedToStationRemarkController,
                          hintText: 'Enter remark',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Informed To All Trains
              Row(
                children: [
                  Expanded(
                    child: CustDropdown(
                      label: 'Informed To All Trains?',
                      hint: 'Select',
                      items: yesNoList,
                      selectedValue: _selectedInformedToAllTrains,
                      onChanged: (value) {
                        setState(() {
                          _selectedInformedToAllTrains = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustText(
                          name: 'Enter remark',
                          size: 1.8,
                          fontWeightName: FontWeight.w500,
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _informedToAllTrainsRemarkController,
                          hintText: 'Enter remark',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Informed To All Crew Controller/OCCT
              Row(
                children: [
                  Expanded(
                    child: CustDropdown(
                      label: 'Informed To All Crew Controller/OCCT?',
                      hint: 'Select',
                      items: yesNoList,
                      selectedValue: _selectedInformedToAllCrewController,
                      onChanged: (value) {
                        setState(() {
                          _selectedInformedToAllCrewController = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustText(
                          name: 'Enter remark',
                          size: 1.8,
                          fontWeightName: FontWeight.w500,
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _informedToAllCrewRemarkController,
                          hintText: 'Enter remark',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Complete TSR Details Section
        AccordionCard(
          expanded: true,
          onTap: () {},
          isExpanded: false,
          title: "Complete TSR Details",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with updated status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.textFieldColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustText(
                          name: 'TSR No: $_tsrNo',
                          size: 2.0,
                          fontWeightName: FontWeight.w600,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.dividerColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: CustText(
                            name: 'Status: $_status',
                            size: 1.6,
                            fontWeightName: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow('Department', _departmentName),
                        const SizedBox(height: 4),
                        _buildDetailRow('Created On:', "${_createdOn.day.toString().padLeft(2, '0')}-${_createdOn.month.toString().padLeft(2, '0')}-${_createdOn.year} ${_createdOn.hour.toString().padLeft(2, '0')}:${_createdOn.minute.toString().padLeft(2, '0')}"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustText(
                      name: 'Timeline',
                      size: 1.8,
                      fontWeightName: FontWeight.w600,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTimelineItem('Implemented by TC', '17-10-2024 14:20'),
                        Container(height: 2, width: 50, color: Colors.black),
                        _buildTimelineItem('Approved by CC', '17-10-2024 14:05'),
                        Container(height: 2, width: 50, color: Colors.black),
                        _buildTimelineItem('Created', '17-10-2024 14:00'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // TSR Details Section
              CustText(
                name: 'TSR Details',
                size: 1.8,
                fontWeightName: FontWeight.w600,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Department', _departmentName),
                        const SizedBox(height: 12),
                        _buildDetailRow('Time', 'Functional location'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Station From', 'Functional Location'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Specific TSR Location', 'Actual Failure Occurrence'),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Date', 'Location'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Line', 'Equipment Number'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Station To', 'Person Responsible'),
                        const SizedBox(height: 12),
                        ],
                    ),
                  ),
                ],
              ),
              _buildDetailRow('Temporary Speed Restriction (in Kmph)', 'Actual Failure Occurrence'),
              const SizedBox(height: 12),
              _buildDetailRow('Expected Date & Time of Cancellation', 'Person Responsible'),
              const SizedBox(height: 12),
              _buildDetailRow('Direction', 'Actual Failure Occurrence'),
              const SizedBox(height: 12),
              CustText(
                name:  'Reason for TSR',
                size: 1.4,
                color: AppColors.textColor4,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: TextEditingController(
                  text: 'Lorem ipsum dolor sit amet consectetur. Venenatis donec nisi elementum dictum magna facilisi. Suspendisse faucibus ultrices sed tortor neque elementum natoque quisque. Semper pharetra senectus mauris arcu ipsum nascetur dui egestas aenean. Aenean ut donec senectus malesuada viverra suspendisse. Erat faucibus ipsum odio lobortis. Non non viverra ullamcorper ipsum.',
                ),
                hintText: 'Description',
                maxLines: 4,
                enabled: false,
              ),
              const SizedBox(height: 16),
              
              // Operation Details Section
              CustText(
                name: 'Operation Details',
                size: 1.8,
                fontWeightName: FontWeight.w600,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow('TSR by ATS', 'Yes'),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildDetailRow('TSR by Caution', 'Yes'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustText(
                name:  'Additional Cause',
                size: 1.4,
                color: AppColors.textColor4,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: TextEditingController(
                  text: 'Lorem ipsum dolor sit amet consectetur. Venenatis donec nisi elementum dictum magna facilisi. Suspendisse faucibus ultrices sed tortor neque elementum natoque quisque. Semper pharetra senectus mauris arcu ipsum nascetur dui egestas aenean. Aenean ut donec senectus malesuada viverra suspendisse. Erat faucibus ipsum odio lobortis. Non non viverra ullamcorper ipsum.',
                ),
                hintText: 'Description',
                maxLines: 4,
                enabled: false,
              ),
              const SizedBox(height: 16),
              
              // TSR Implementation Section
              CustText(
                name: 'TSR Implementation',
                size: 1.8,
                fontWeightName: FontWeight.w600,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow('Informed to Station Controller', 'Yes'),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildDetailRow('Informed to All Trains', 'No'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustText(
                name:  'Remark',
                size: 1.4,
                color: AppColors.textColor4,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: TextEditingController(
                  text: 'Lorem ipsum dolor sit amet consectetur. Venenatis donec nisi elementum dictum magna facilisi. Suspendisse faucibus ultrices sed tortor neque elementum natoque quisque. Semper pharetra senectus mauris arcu ipsum nascetur dui egestas aenean. Aenean ut donec senectus malesuada viverra suspendisse. Erat faucibus ipsum odio lobortis. Non non viverra ullamcorper ipsum.',
                ),
                hintText: 'Description',
                maxLines: 4,
                enabled: false,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailRow('Informed to All Crew Controller/DCC', 'No'),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Container(), // Empty space for alignment
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustText(
                name:  'Remark',
                size: 1.4,
                color: AppColors.textColor4,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: TextEditingController(
                  text: 'Lorem ipsum dolor sit amet consectetur. Venenatis donec nisi elementum dictum magna facilisi. Suspendisse faucibus ultrices sed tortor neque elementum natoque quisque. Semper pharetra senectus mauris arcu ipsum nascetur dui egestas aenean. Aenean ut donec senectus malesuada viverra suspendisse. Erat faucibus ipsum odio lobortis. Non non viverra ullamcorper ipsum.',
                ),
                hintText: 'Description',
                maxLines: 4,
                enabled: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: label,
          size: 1.4,
          color: AppColors.textColor4,
        ),
        const SizedBox(height: 4),
        CustText(
          name: value,
          size: 1.6,
          fontWeightName: FontWeight.w500,
        ),
      ],
    );
  }

  Widget _buildTSRHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textFieldColor),
      ),
      child: Center(
        child: CustText(
          name: 'TSR History will be displayed here',
          size: 1.8,
          color: AppColors.textColor4,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.textColor3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () => _rejectTSR(),
            child: const Text('Reject', style: TextStyle(color: AppColors.textColor3)),
          ),
          const SizedBox(width: 16),
          CustButton(
            name: 'Approve',
            size: 30,
            onSelected: (_) => _approveTSR(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.textColor3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textColor3)),
          ),
          const SizedBox(width: 16),
          CustButton(
            name: 'Save',
            size: 30,
            onSelected: (_) => _saveTSR(),
          ),
        ],
      ),
    );
  }

  void _saveTSR() {
    // TODO: Implement save logic
    print('TSR Details saved');
    // Switch to details view after saving
    setState(() {
      _showForm = false;
    });
  }

  void _approveTSR() {
    // TODO: Implement approve logic
    print('TSR Approved');
  }

  void _rejectTSR() {
    // TODO: Implement reject logic
    print('TSR Rejected');
  }

  Widget _buildTimelineItem(String title, String date) {
    return Expanded(
      child: Column(
        children: [
          CustText(
            name: title,
            size: 1.2,
            fontWeightName: FontWeight.w500,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          CustText(
            name: date,
            size: 1.2,
            color: AppColors.textColor4,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 