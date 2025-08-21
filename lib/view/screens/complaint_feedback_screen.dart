import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/cust_button.dart';
import 'package:om_mobile/widgets/cust_date_picker.dart';
import 'package:om_mobile/widgets/cust_dropdown.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart'; // Import CustomAppBar
import 'dart:io';
import 'package:om_mobile/widgets/file_upload_section.dart';
import 'package:om_mobile/constants/app_data.dart';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';

import 'widgets/custom_dialog.dart';

class ComplaintFeedbackScreen extends StatefulWidget {
  const ComplaintFeedbackScreen({Key? key}) : super(key: key);

  @override
  _ComplaintFeedbackScreenState createState() => _ComplaintFeedbackScreenState();
}

class _ComplaintFeedbackScreenState extends State<ComplaintFeedbackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  final GlobalKey _scrollViewKey = GlobalKey();

  // State variables for dropdowns in Complaint Details
  String? _selectedComplaintFeedback;
  DateTime? _selectedDate;
  String? _selectedComplaintType;
  String? _selectedComplaintCategory;
  String? _selectedIncidentLocation;

  // TextEditingController for Description in Complaint Details
  final TextEditingController _complaintDetailsDescriptionController = TextEditingController();
  final TextEditingController _complainantDescriptionController = TextEditingController();

  // State variables for Complainant Details
  final TextEditingController _complainantNameController = TextEditingController();
  final TextEditingController _complainantMobileNumberController = TextEditingController();
  final TextEditingController _complainantEmailAddressController = TextEditingController();
  String? _selectedComplainantCategory;
  String? _selectedComplainantIncidentLocation;

  // State variables for Remark
  String? _selectedSource;
  String? _selectedUserAssign;
  final TextEditingController _stationControllerRemark = TextEditingController();


  // Keys for each section to measure their positions
  final GlobalKey _complaintDetailsKey = GlobalKey();
  final GlobalKey _complainantDetailsKey = GlobalKey();
  final GlobalKey _remarkKey = GlobalKey();
  final GlobalKey _attachmentsKey = GlobalKey();

  // Store section heights
  double _complaintDetailsHeight = 0;
  double _complainantDetailsHeight = 0;
  double _remarkHeight = 0;
  double _attachmentsHeight = 0;

  // Add this new state variable
  List<File> _attachedFiles = [];

  // Accordion expanded states
  bool complaintDetailsExpanded = true;
  bool complainantDetailsExpanded = false;
  bool remarkExpanded = false;
  bool attachmentsExpanded = false;

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "Complaint Details",
    "Complainant Details",
    "Remark",
    "Attachments",
  ];

  List<Widget> get _steps => [
    _buildComplaintDetailsStep(),
    _buildComplainantDetailsStep(),
    _buildRemarkStep(),
    _buildAttachmentsStep(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 tabs now
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    // Schedule a post-frame callback to measure section heights
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureSectionHeights();
    });
  }

  void _measureSectionHeights() {
    final complaintDetailsContext = _complaintDetailsKey.currentContext;
    final complainantDetailsContext = _complainantDetailsKey.currentContext;
    final remarkContext = _remarkKey.currentContext;
    final attachmentsContext = _attachmentsKey.currentContext;

    if (complaintDetailsContext != null) {
      final box = complaintDetailsContext.findRenderObject() as RenderBox?;
      if (box != null) {
        _complaintDetailsHeight = box.size.height;
      }
    }

    if (complainantDetailsContext != null) {
      final box = complainantDetailsContext.findRenderObject() as RenderBox?;
      if (box != null) {
        _complainantDetailsHeight = box.size.height;
      }
    }

    if (remarkContext != null) {
      final box = remarkContext.findRenderObject() as RenderBox?;
      if (box != null) {
        _remarkHeight = box.size.height;
      }
    }

    if (attachmentsContext != null) {
      final box = attachmentsContext.findRenderObject() as RenderBox?;
      if (box != null) {
        _attachmentsHeight = box.size.height;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _tabController.dispose();
    _complaintDetailsDescriptionController.dispose();
    _complainantNameController.dispose();
    _complainantMobileNumberController.dispose();
    _complainantEmailAddressController.dispose();
    _stationControllerRemark.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final scrollOffset = _scrollController.offset;

    final RenderBox? scrollViewRenderBox = _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;

    if (scrollViewRenderBox == null) return;

    double getLocalOffset(GlobalKey key) {
      final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        // Convert global offset of the section to local offset within the scroll view
        final Offset localOffset = scrollViewRenderBox.globalToLocal(box.localToGlobal(Offset.zero));
        return localOffset.dy;
      }
      return double.infinity;
    }

    final complaintDetailsLocalPosition = getLocalOffset(_complaintDetailsKey);
    final complainantDetailsLocalPosition = getLocalOffset(_complainantDetailsKey);
    final remarkLocalPosition = getLocalOffset(_remarkKey);
    final attachmentsLocalPosition = getLocalOffset(_attachmentsKey);

    const double threshold = 50.0;

    if (scrollOffset >= attachmentsLocalPosition - threshold) {
      if (_tabController.index != 3) {
        _tabController.animateTo(3);
      }
    } else if (scrollOffset >= remarkLocalPosition - threshold) {
      if (_tabController.index != 2) {
        _tabController.animateTo(2);
      }
    } else if (scrollOffset >= complainantDetailsLocalPosition - threshold) {
      if (_tabController.index != 1) {
        _tabController.animateTo(1);
      }
    } else if (_tabController.index != 0) {
        _tabController.animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: 'Complaint & Feedback',
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
          SizedBox(height: 1 * SizeConfig.heightMultiplier),
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
          SizedBox(height: 1 * SizeConfig.heightMultiplier,)
        ],
      ),
    );
  }

  Widget _buildComplaintDetailsStep() {
    return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child:AccordionCard(
                              isExpanded: false,
                              expanded: true,
                              title: _stepTitles[_currentStep],
                              onTap: () {},
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustDropdown(
                                    label: 'Complaint/Feedback',
                                    hint: 'Select',
                                    items: complaintTypesValue,
                                    selectedValue: _selectedComplaintFeedback,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedComplaintFeedback = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 2 * SizeConfig.heightMultiplier),
                                  CustDatePicker(
                                    label: 'Date',
                                    hint: 'Select date',
                                    selectedDate: _selectedDate,
                                    onDateSelected: (date) {
                                      setState(() {
                                        _selectedDate = date;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 2 * SizeConfig.heightMultiplier),
                                  CustDropdown(
                                    label: 'Complaint Type',
                                    hint: 'Select complaint type',
                                    items: complaintTypesValue,
                                    selectedValue: _selectedComplaintType,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedComplaintType = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 2 * SizeConfig.heightMultiplier),
                                  CustDropdown(
                                    label: 'Complaint Category',
                                    hint: 'Select complaint category',
                                    items: staffComplaintCategoriesValue,
                                    selectedValue: _selectedComplaintCategory,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedComplaintCategory = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 2 * SizeConfig.heightMultiplier),
                                  CustDropdown(
                                    label: 'Incident Location',
                                    hint: 'Select incident location',
                                    items: const ['Incident 1', 'Incident 2','Incident 3'],
                                    selectedValue: _selectedIncidentLocation,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedIncidentLocation = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 2 * SizeConfig.heightMultiplier),
                                  CustText(
                                    name: "Description",
                                    size: 1.8,
                                    fontWeightName: FontWeight.w500,
                                  ),
                                  SizedBox(height: 1 * SizeConfig.heightMultiplier),
                                  CustomTextField(controller: _complaintDetailsDescriptionController, hintText: 'Description', maxLines: 4),
                                ],
                              ),
                            ),
    );
  }

  Widget _buildComplainantDetailsStep() {
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
                                  CustText(
                                    name: "Complainant Name",
                                    size: 1.8,
                                    fontWeightName: FontWeight.w500,
                                  ),
                                  SizedBox(height: 1 * SizeConfig.heightMultiplier),
                                  CustomTextField(controller: _complainantNameController, hintText: 'Enter name'),
                                  SizedBox(height: 2 * SizeConfig.heightMultiplier),
                                  CustText(
                                    name: "Complainant Mobile Number",
                                    size: 1.8,
                                    fontWeightName: FontWeight.w500,
                                  ),
                                  SizedBox(height: 1 * SizeConfig.heightMultiplier),
                                  CustomTextField(controller: _complainantMobileNumberController,keyboardType: TextInputType.number, hintText: 'Enter mobile number'),
                                  SizedBox(height: 2 * SizeConfig.heightMultiplier),
                                  CustDropdown(
                                    label: 'Complaint Category',
                                    hint: 'Select category',
                                    items: staffComplaintCategoriesValue,
                                    selectedValue: _selectedComplainantCategory,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedComplainantCategory = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 2 * SizeConfig.heightMultiplier),
                                  CustDropdown(
                                    label: 'Incident Location',
                                    hint: 'Select incident location',
                                    items: const ['Incident 1', 'Incident 2','Incident 3'],
                                    selectedValue: _selectedComplainantIncidentLocation,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedComplainantIncidentLocation = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 2 * SizeConfig.heightMultiplier),
                                  CustText(
                                    name: "Description",
                                    size: 1.8,
                                    fontWeightName: FontWeight.w500,
                                  ),
                                  SizedBox(height: 8),
                                  CustomTextField(controller: _complainantDescriptionController, hintText: 'Description', maxLines: 4),
                                ],
                              ),
                            ),
    );
  }

  Widget _buildRemarkStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child:AccordionCard(
                              isExpanded: false,
                              expanded: true,
                              title: _stepTitles[_currentStep],
                              onTap: () {},
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustDropdown(
                                    label: 'Source',
                                    hint: 'Select source',
                                    items: sourceListValue,
                                    selectedValue: _selectedSource,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedSource = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 2 * SizeConfig.heightMultiplier),
                                  CustDropdown(
                                    label: 'User Assign',
                                    hint: 'Select user',
                                    items: const ['User 1', 'User 2'],
                                    selectedValue: _selectedUserAssign,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedUserAssign = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 2 * SizeConfig.heightMultiplier),
                                  CustText(
                                    name: "Station Controller Remark",
                                    size: 1.8,
                                    fontWeightName: FontWeight.w500,
                                  ),
                                  SizedBox(height: 1 * SizeConfig.heightMultiplier),
                                  CustomTextField(controller: _stationControllerRemark, hintText: 'Enter remark', maxLines: 4),
                                ],
                              ),
                            ),
    );
  }

  Widget _buildAttachmentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child:AccordionCard(
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

  // Helper method to build file list item
  Widget _buildFileListItem(String fileName, String fileSize) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.dividerColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Container(
            height: 5 * SizeConfig.heightMultiplier,
            width:  5 * SizeConfig.heightMultiplier,
            decoration: BoxDecoration(color: AppColors.containerColor,borderRadius: BorderRadius.circular(5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: fileName, size: 1.7,color: AppColors.black,),
                CustText(name: fileSize, size: 1.4,color: Colors.black,),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey), // Remove icon
            onPressed: () {
              // TODO: Implement remove file logic
            },
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final dashPath = Path();
    final dashCount = (size.width / (dashWidth + dashSpace)).floor();
    final dashCountVertical = (size.height / (dashWidth + dashSpace)).floor();

    // Draw horizontal dashes
    for (int i = 0; i < dashCount; i++) {
      final startX = i * (dashWidth + dashSpace);
      dashPath.moveTo(startX, 0);
      dashPath.lineTo(startX + dashWidth, 0);
    }

    // Draw vertical dashes
    for (int i = 0; i < dashCountVertical; i++) {
      final startY = i * (dashWidth + dashSpace);
      dashPath.moveTo(size.width, startY);
      dashPath.lineTo(size.width, startY + dashWidth);
    }

    // Draw bottom horizontal dashes
    for (int i = 0; i < dashCount; i++) {
      final startX = i * (dashWidth + dashSpace);
      dashPath.moveTo(startX, size.height);
      dashPath.lineTo(startX + dashWidth, size.height);
    }

    // Draw left vertical dashes
    for (int i = 0; i < dashCountVertical; i++) {
      final startY = i * (dashWidth + dashSpace);
      dashPath.moveTo(0, startY);
      dashPath.lineTo(0, startY + dashWidth);
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

