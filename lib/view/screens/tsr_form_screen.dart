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
import 'package:om_mobile/tsr_details_screen.dart';

class TSRFormScreen extends StatefulWidget {
  const TSRFormScreen({Key? key}) : super(key: key);

  @override
  State<TSRFormScreen> createState() => _TSRFormScreenState();
}

class _TSRFormScreenState extends State<TSRFormScreen> {
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

  final List<String> departmentList = ["OCC", "Maintenance", "Operations", "Safety"];
  final List<String> lineList = ["Line A", "Line B", "Line C", "Line D"];
  final List<String> directionList = ["North", "South", "East", "West", "Both"];
  final List<String> stationList = ["Station A", "Station B", "Station C", "Station D"];

  @override
  void dispose() {
    _specificTSRLocationController.dispose();
    _reasonForTSRController.dispose();
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
              child: AccordionCard(
                expanded: true,
                onTap: () {},
                isExpanded: false,
                title: "TSR Details",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Department, Imposition Date, Imposition Time
                    Row(
                      children: [
                        Expanded(
                          child: CustDropdown(
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustDatePicker(
                            label: 'Imposition Date',
                            hint: 'DD/MM/YYYY',
                            selectedDate: _selectedImpositionDate,
                            onDateSelected: (date) {
                              setState(() {
                                _selectedImpositionDate = date;
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Row 2: Line, Direction
                    Row(
                      children: [
                        Expanded(
                          child: CustDropdown(
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustDropdown(
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Row 3: Station From, Station To, Speed Restriction
                    Row(
                      children: [
                        Expanded(
                          child: CustDropdown(
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustDropdown(
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Row 4: Specific TSR Location (full width)
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
                    const SizedBox(height: 16),
                    
                    // Row 5: Reason For TSR (full width)
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
                    const SizedBox(height: 16),
                    
                    // Row 6: Expected Date & Time of Closing
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
                  ],
                ),
              ),
            ),
          ),
          Padding(
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
          ),
        ],
      ),
    );
  }

  void _saveTSR() {
    // TODO: Implement save logic
    print('TSR Details saved');
    // Navigate to TSR Details screen after saving
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TSRDetailsScreen(),
      ),
    );
  }
} 