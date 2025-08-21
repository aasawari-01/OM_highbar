import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/cust_dropdown.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/cust_date_picker.dart';
import 'package:om_mobile/widgets/cust_date_time_picker.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/cust_button.dart';
import 'package:om_mobile/widgets/file_upload_section.dart';
import 'package:om_mobile/widgets/cust_toggle.dart';
import 'constants/app_data.dart';
import 'dart:io';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';

import 'widgets/custom_dialog.dart';

class OCCFailureScreen extends StatefulWidget {
  const OCCFailureScreen({Key? key}) : super(key: key);

  @override
  State<OCCFailureScreen> createState() => _OCCFailureScreenState();
}

class _OCCFailureScreenState extends State<OCCFailureScreen> {
  // OCC Failure Details
  String? _selectedPriority;
  String? _selectedDepartment;
  String? _selectedLocation;
  String? _selectedSystem;
  String? _selectedReportedBy;
  DateTime? _selectedFailureDate;
  DateTime? _selectedRestoredDate;
  String? _selectedReportedTo;
  String? _selectedLine;
  String? _selectedSubLocation;
  final TextEditingController _failureDescriptionController = TextEditingController();
  final TextEditingController _systemController = TextEditingController();
  final TextEditingController _trainIdController = TextEditingController();
  String? _selectedTrainSet;
  DateTime? _selectedFailureCompletedDate;
  String? _selectedFailureReportedBy;

  // Operation Impacted
  bool _isOperationImpacted = false;
  String? _selectedImpactType;
  final TextEditingController _impactDurationController = TextEditingController();

  // Trip Affected
  bool _isTripAffected = false;
  final TextEditingController _tripDelayUplineController = TextEditingController();
  final TextEditingController _tripDelayDownlineController = TextEditingController();
  final TextEditingController _tripDelayInMinController = TextEditingController();
  String? _tripCancel;
  final TextEditingController _tripWithdrawalController = TextEditingController();
  String? _tripOperatorName;

  // Train Replace
  bool _isTrainReplace = false;
  String? _trainReplace;
  String? _selectedReplaceWith;
  TimeOfDay? _replacedTime;

  // Passenger Deboarding
  bool _isPassengerDeboarding = false;
  final TextEditingController _trainDeboardedController = TextEditingController();

  // Passenger Affected
  bool _isPassengerAffected = false;
  final TextEditingController _numPassengerAffectedController = TextEditingController();
  final TextEditingController _trappedDurationController = TextEditingController();
  final TextEditingController _rescuedDurationController = TextEditingController();
  final TextEditingController _wayOfRescueController = TextEditingController();

  // Attachments
  List<File> _attachedFiles = [];

  // Accordion states
  bool failureDetailsExpanded = true;
  bool operationImpactedExpanded = false;
  bool passengerAffectedExpanded = false;
  bool attachmentsExpanded = false;

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "OCC Failure Details",
    "Trip Affected",
    "Passengers Affected",
    "Attachments",
  ];

  final ScrollController _tripAffectedScrollController = ScrollController();
  final GlobalKey _passengerDeboardingKey = GlobalKey();

  List<Widget> get _steps => [
    _buildFailureDetailsStep(),
    _buildTripAffectedStep(),
    _buildPassengersAffectedStep(),
    _buildAttachmentsStep(),
  ];

  @override
  void dispose() {
    _failureDescriptionController.dispose();
    _systemController.dispose();
    _impactDurationController.dispose();
    _tripDelayUplineController.dispose();
    _tripDelayDownlineController.dispose();
    _tripDelayInMinController.dispose();
    _tripWithdrawalController.dispose();
    _trainDeboardedController.dispose();
    _numPassengerAffectedController.dispose();
    _trappedDurationController.dispose();
    _rescuedDurationController.dispose();
    _wayOfRescueController.dispose();
    super.dispose();
  }

  void _selectFailureDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFailureDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedFailureDate = picked;
      });
    }
  }

  void _selectRestoredDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedRestoredDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedRestoredDate = picked;
      });
    }
  }

  Future<void> _selectReplacedTime() async {
    TimeOfDay tempTime = _replacedTime ?? TimeOfDay.now();
    
    TimeOfDay? pickedTime = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) {
        int selectedHour = tempTime.hour;
        int selectedMinute = tempTime.minute;
        bool isAm = selectedHour < 12;
        int displayHour12 = ((selectedHour % 12) == 0) ? 12 : (selectedHour % 12);
        
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.textColor3,
              onPrimary: Colors.white,
              onSurface: AppColors.textColor,
              surface: AppColors.bgColor,
              secondary: AppColors.textColor3,
              onSecondary: Colors.white,
            ),
            dialogBackgroundColor: AppColors.bgColor,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textColor3,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              fillColor: AppColors.white1,
              filled: true,
              labelStyle: TextStyle(color: AppColors.textColor),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.textColor3),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.textColor3, width: 2),
              ),
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              TextEditingController hourController = TextEditingController(
                text: (((selectedHour % 12) == 0) ? 12 : (selectedHour % 12)).toString().padLeft(2, '0'),
              );
              TextEditingController minuteController = TextEditingController(
                text: selectedMinute.toString().padLeft(2, '0'),
              );
              TextEditingController ampmController = TextEditingController(
                text: isAm ? 'AM' : 'PM',
              );
              
              return AlertDialog(
                contentPadding: EdgeInsets.all(0),
                title: CustText(name: 'Select Time', size: 1.8),
                content: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustText(name: 'Hour', size: 1.6, fontWeightName: FontWeight.w500),
                            SizedBox(height: 1 * SizeConfig.heightMultiplier),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedHour = (selectedHour + 1) % 24;
                                  isAm = selectedHour < 12;
                                  hourController.text = (((selectedHour % 12) == 0) ? 12 : (selectedHour % 12)).toString().padLeft(2, '0');
                                });
                              },
                              child: Icon(Icons.keyboard_arrow_up, size: 32, color: AppColors.textColor4),
                            ),
                            SizedBox(
                              width: 48,
                              child: CustomTextField(
                                controller: hourController,
                                keyboardType: TextInputType.number,
                                hintText: '',
                                onChanged: (val) {
                                  int? v = int.tryParse(val);
                                  if (v != null) {
                                    int hourVal = v;
                                    if (hourVal < 1) hourVal = 1;
                                    if (hourVal > 12) hourVal = 12;
                                    setState(() {
                                      // Convert to 24-hour based on isAm
                                      if (isAm) {
                                        selectedHour = hourVal == 12 ? 0 : hourVal;
                                      } else {
                                        selectedHour = hourVal == 12 ? 12 : hourVal + 12;
                                      }
                                      hourController.text = hourVal.toString().padLeft(2, '0');
                                    });
                                  }
                                },
                                onSubmitted: (val) {
                                  int? v = int.tryParse(val);
                                  if (v == null || v < 1 || v > 12) {
                                    setState(() {
                                      hourController.text = (((selectedHour % 12) == 0) ? 12 : (selectedHour % 12)).toString().padLeft(2, '0');
                                    });
                                  }
                                },
                                maxLines: 1,
                                fillColor: Colors.transparent,
                                readOnly: false,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedHour = (selectedHour - 1 + 24) % 24;
                                  isAm = selectedHour < 12;
                                  hourController.text = (((selectedHour % 12) == 0) ? 12 : (selectedHour % 12)).toString().padLeft(2, '0');
                                });
                              },
                              child: Icon(Icons.keyboard_arrow_down, size: 32, color: AppColors.textColor4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustText(name: 'Minute', size: 1.6, color: AppColors.textColor, fontWeightName: FontWeight.w500),
                            SizedBox(height: 1 * SizeConfig.heightMultiplier),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedMinute = (selectedMinute + 1) % 60;
                                  minuteController.text = selectedMinute.toString().padLeft(2, '0');
                                });
                              },
                              child: Icon(Icons.keyboard_arrow_up, size: 32, color: AppColors.textColor4),
                            ),
                            SizedBox(
                              width: 48,
                              child: CustomTextField(
                                controller: minuteController,
                                keyboardType: TextInputType.number,
                                hintText: '',
                                onChanged: (val) {
                                  int? v = int.tryParse(val);
                                  if (v != null) {
                                    int minVal = v;
                                    if (minVal < 0) minVal = 0;
                                    if (minVal > 59) minVal = 59;
                                    setState(() {
                                      selectedMinute = minVal;
                                      minuteController.text = minVal.toString().padLeft(2, '0');
                                    });
                                  }
                                },
                                onSubmitted: (val) {
                                  int? v = int.tryParse(val);
                                  if (v == null || v < 0 || v > 59) {
                                    setState(() {
                                      minuteController.text = selectedMinute.toString().padLeft(2, '0');
                                    });
                                  }
                                },
                                maxLines: 1,
                                fillColor: Colors.transparent,
                                readOnly: false,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedMinute = (selectedMinute - 1 + 60) % 60;
                                  minuteController.text = selectedMinute.toString().padLeft(2, '0');
                                });
                              },
                              child: Icon(Icons.keyboard_arrow_down, size: 32, color: AppColors.textColor4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustText(name: 'AM/PM', size: 1.6, color: AppColors.textColor, fontWeightName: FontWeight.w500),
                            SizedBox(height: 1 * SizeConfig.heightMultiplier),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (!isAm) {
                                    if (selectedHour >= 12) selectedHour -= 12;
                                    isAm = true;
                                  } else {
                                    if (selectedHour < 12) selectedHour += 12;
                                    isAm = false;
                                  }
                                });
                              },
                              child: Icon(Icons.keyboard_arrow_up, size: 32, color: AppColors.textColor4),
                            ),
                            SizedBox(
                              width: 48,
                              child: CustomTextField(
                                controller: ampmController,
                                hintText: '',
                                readOnly: true,
                                maxLines: 1,
                                fillColor: Colors.transparent,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (!isAm) {
                                    if (selectedHour >= 12) selectedHour -= 12;
                                    isAm = true;
                                  } else {
                                    if (selectedHour < 12) selectedHour += 12;
                                    isAm = false;
                                  }
                                });
                              },
                              child: Icon(Icons.keyboard_arrow_down, size: 32, color: AppColors.textColor4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        TimeOfDay(hour: selectedHour, minute: selectedMinute),
                      );
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _replacedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: 'OCC Failure',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 1 * SizeConfig.heightMultiplier,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: FlutterStepIndicator(
              height: 20,
              list: List.generate(_steps.length, (index) => index),
              page: _currentStep,
              division: _steps.length,
              positiveColor: AppColors.gradientStart,
              negativeColor: AppColors.textColor4,
              progressColor: AppColors.gradientStart,
              onChange: (i) {},
            ),
          ),
           SizedBox(height: 1 * SizeConfig.heightMultiplier,),
          Expanded(
            child: _steps[_currentStep],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 1 * SizeConfig.heightMultiplier, horizontal: 4 * SizeConfig.widthMultiplier),
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
          SizedBox(height: 1 * SizeConfig.heightMultiplier),
        ],
      ),
    );
  }

  Widget _buildFailureDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: AccordionCard(
        isExpanded: false,
        expanded: true,
        title: _stepTitles[_currentStep],
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustDropdown(
                    label: 'Priority',
                    hint: 'Priority',
                    items: priorityListValue,
                    selectedValue: _selectedPriority,
                    onChanged: (value) => setState(() => _selectedPriority = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustDropdown(
                    label: 'Department',
                    hint: 'Department',
                    items: departmentListValue,
                    selectedValue: _selectedDepartment,
                    onChanged: (value) => setState(() => _selectedDepartment = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Reported To',
              hint: 'Select Person',
              items: personList,
              selectedValue: _selectedReportedTo,
              onChanged: (value) => setState(() => _selectedReportedTo = value),
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Line',
              hint: 'Select Line',
              items: const ['Line 1', 'Line 2'],
              selectedValue: _selectedLine,
              onChanged: (value) => setState(() => _selectedLine = value),
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Location',
              hint: 'Select Location',
              items: stationListValue,
              selectedValue: _selectedLocation,
              onChanged: (value) => setState(() => _selectedLocation = value),
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Sub Location',
              hint: 'Select Sub Location',
              items: stationListValue,
              selectedValue: _selectedSubLocation,
              onChanged: (value) => setState(() => _selectedSubLocation = value),
            ),
            const SizedBox(height: 16),
            CustText(name: 'System', size: 1.8, fontWeightName: FontWeight.w500),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _systemController,
              hintText: 'Enter System',
              labelText: 'System',
            ),
            const SizedBox(height: 16),
            CustText(name: 'Train Id', size: 1.8, fontWeightName: FontWeight.w500),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _trainIdController,
              hintText: 'Enter Train Id',
              labelText: 'Train Id',
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Train Set',
              hint: 'Select Train Set',
              items: const ['Set 1', 'Set 2'],
              selectedValue: _selectedTrainSet,
              onChanged: (value) => setState(() => _selectedTrainSet = value),
            ),
            const SizedBox(height: 16),
            CustDateTimePicker(
              label: 'Actual Failure Occurrence',
              hint: 'DD/MM/YYYY HH:mm',
              selectedDateTime: _selectedFailureDate,
              onDateTimeSelected: (dateTime) => setState(() => _selectedFailureDate = dateTime),
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Failure Reported By',
              hint: 'Select Person',
              items: personList,
              selectedValue: _selectedFailureReportedBy,
              onChanged: (value) => setState(() => _selectedFailureReportedBy = value),
            ),
            const SizedBox(height: 16),
            CustDateTimePicker(
              label: 'Actual Failure Completed On',
              hint: 'DD/MM/YYYY HH:mm',
              selectedDateTime: _selectedFailureCompletedDate,
              onDateTimeSelected: (dateTime) => setState(() => _selectedFailureCompletedDate = dateTime),
            ),
            const SizedBox(height: 16),
            CustText(name: 'Failure Description', size: 1.8, fontWeightName: FontWeight.w500),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _failureDescriptionController,
              hintText: 'Failure Description',
              labelText: 'Failure Description',
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripAffectedStep() {
    return SingleChildScrollView(
      controller: _tripAffectedScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: AccordionCard(
        isExpanded: false,
        expanded: true,
        title: _stepTitles[_currentStep],
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustText(
                  name: "Trip Affected?",
                  size: 1.8,
                  fontWeightName: FontWeight.w500,
                  color: Colors.black,
                ),
                YesNoToggle(
                  value: _isTripAffected,
                  onChanged: (val) {
                    setState(() {
                      _isTripAffected = val;
                    });
                  },
                ),
              ],
            ),
            if (_isTripAffected) ...[
              const SizedBox(height: 16),
              CustText(name: 'Trip Dealy Upline', size: 1.8, fontWeightName: FontWeight.w500),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _tripDelayUplineController,
                keyboardType: TextInputType.number,
                hintText: 'Enter Trip Delay Upline',
              ),
              const SizedBox(height: 16),
              CustDropdown(
                label: 'Trip Cancel',
                hint: 'Select Trip Cancel',
                items: const ['Yes', 'No'],
                selectedValue: _tripCancel,
                onChanged: (value) {
                  setState(() {
                    _tripCancel = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              CustText(name: 'Trip Dealy Downline', size: 1.8, fontWeightName: FontWeight.w500),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _tripDelayDownlineController,
                keyboardType: TextInputType.number,
                hintText: 'Enter Trip Delay Downline',
              ),
              const SizedBox(height: 16),
              CustText(name: 'Trip Delay In Min', size: 1.8, fontWeightName: FontWeight.w500),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _tripDelayInMinController,
                keyboardType: TextInputType.number,
                hintText: 'Enter Trip Delay In Min',
              ),
              const SizedBox(height: 16),
              CustText(name: 'Trip Withdrawal', size: 1.8, fontWeightName: FontWeight.w500),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _tripWithdrawalController,
                hintText: 'Enter Trip Withdrawal',
              ),
              const SizedBox(height: 16),
              CustDropdown(
                label: 'Trip Operator Name',
                hint: 'Enter Trip Operator Name',
                items: const ['Operator1', 'Operator2'],
                selectedValue: _tripOperatorName,
                onChanged: (value) {
                  setState(() {
                    _tripOperatorName = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CustText(
                    name: "Train Replace",
                    size: 1.8,
                    fontWeightName: FontWeight.w500,
                  ),
                  const SizedBox(width: 8),
                  YesNoToggle(
                    value: _isTrainReplace,
                    onChanged: (val) {
                      setState(() {
                        _isTrainReplace = val;
                      });
                      if (val) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _tripAffectedScrollController.animateTo(
                            _tripAffectedScrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
              if (_isTrainReplace) ...[
                const SizedBox(height: 8),
                CustDropdown(
                  label: 'Train Replace',
                  hint: 'Train Replace',
                  items: const ['Yes', 'No'],
                  selectedValue: _trainReplace,
                  onChanged: (value) {
                    setState(() {
                      _trainReplace = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                CustDropdown(
                  label: 'Replace With',
                  hint: 'Select Train',
                  items: const ['Train 1', 'Train 2'],
                  selectedValue: _selectedReplaceWith,
                  onChanged: (value) {
                    setState(() {
                      _selectedReplaceWith = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                CustText(name: 'Replaced Time', size: 1.8, fontWeightName: FontWeight.w500),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectReplacedTime,
                  child: AbsorbPointer(
                    child: CustomTextField(
                      controller: TextEditingController(
                        text: _replacedTime != null ? _replacedTime!.format(context) : '',
                      ),
                      hintText: 'HH:mm',
                      labelText: 'Replaced Time',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CustText(
                      name: "Passengers Deboarding",
                      size: 1.8,
                      fontWeightName: FontWeight.w500,
                    ),
                    const SizedBox(width: 8),
                    YesNoToggle(
                      value: _isPassengerDeboarding,
                      onChanged: (val) {
                        setState(() {
                          _isPassengerDeboarding = val;
                        });
                        if (val) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            final context = _passengerDeboardingKey.currentContext;
                            if (context != null) {
                              Scrollable.ensureVisible(
                                context,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                alignment: 0.1,
                              );
                            }
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (_isPassengerDeboarding) ...[
                  const SizedBox(height: 8),
                  CustText(name: 'Train Deboarded', size: 1.8, fontWeightName: FontWeight.w500, key: _passengerDeboardingKey),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _trainDeboardedController,
                    hintText: 'Enter Train Deboarded',
                    labelText: 'Train Deboarded',
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPassengersAffectedStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: AccordionCard(
        isExpanded: false,
        expanded: true,
        title: _stepTitles[_currentStep],
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustText(
                  name: "Passengers Affected?",
                  size: 1.8,
                  fontWeightName: FontWeight.w500,
                  color: Colors.black,
                ),
                YesNoToggle(
                  value: _isPassengerAffected,
                  onChanged: (val) {
                    setState(() {
                      _isPassengerAffected = val;
                      print("_isPassengerAffected==$_isPassengerAffected");
                    });
                  },
                ),
              ],
            ),
            if (_isPassengerAffected) ...[
              const SizedBox(height: 16),
              CustText(name: 'Number Of Passengers Affected', size: 1.8, fontWeightName: FontWeight.w500),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _numPassengerAffectedController,
                hintText: 'Enter Number Of Passengers Affected',
                labelText: 'Number Of Passengers Affected',
              ),
              const SizedBox(height: 16),
              CustText(name: 'Trapped Duration', size: 1.8, fontWeightName: FontWeight.w500),
              const SizedBox(height: 8),
              CustomTextField(
                keyboardType: TextInputType.number,
                controller: _trappedDurationController,
                hintText: 'Enter Trapped Duration',
                labelText: 'Trapped Duration',
              ),
              const SizedBox(height: 16),
              CustText(name: 'Rescued Duration', size: 1.8, fontWeightName: FontWeight.w500),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _rescuedDurationController,
                hintText: 'Enter Rescued Duration',
                labelText: 'Rescued Duration',
              ),
              const SizedBox(height: 16),
              CustText(name: 'Way Of Rescue', size: 1.8, fontWeightName: FontWeight.w500),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _wayOfRescueController,
                hintText: 'Way Of Rescue',
                labelText: 'Way Of Rescue',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: AccordionCard(
        isExpanded: false,
        expanded: true,
        title: _stepTitles[_currentStep],
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FileUploadSection(
              files: _attachedFiles,
              onFilesChanged: (files) {
                setState(() {
                  _attachedFiles = files;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
} 