import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/constants/strings.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/feature/failure/view/maintenance_history_screen.dart';
import '../../../../service/network_service/app_urls.dart';
import '../../../../service/master_data_sync_service.dart';
import '../../../../utils/responsive_helper.dart';
import '../../../../utils/widgets/cust_button.dart';
import '../../../../utils/widgets/cust_date_time_picker.dart';
import '../../../../utils/widgets/cust_dropdown.dart';
import '../../../../utils/widgets/cust_loader.dart';
import '../../../../utils/widgets/cust_popup.dart';
import '../../../../utils/widgets/cust_section.dart';
import '../../../../utils/widgets/cust_text.dart';
import '../../../../utils/widgets/cust_textfield.dart';
import '../../../../utils/widgets/cust_toggle.dart';
import '../../../../utils/widgets/custom_app_bar.dart';
import '../../../../utils/widgets/sync_icon_button.dart';
import '../../../../constants/app_constants.dart';
import '../../controller/create_failure_controller.dart';
import '../../../../utils/widgets/cust_data_card.dart';
import '../../../../core/controller/session_controller.dart';
import '../../../../core/models/label_value.dart';
import '../../model/failure_list_response.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../shared/form_field_config.dart';
import '../shared/unified_form_builder.dart';
import '../shared/form_validators.dart';

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

    final dashPath = Path();
    final dashCount = (size.width / (dashWidth + dashSpace)).floor();
    final dashCountVertical = (size.height / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startX = i * (dashWidth + dashSpace);
      dashPath.moveTo(startX, 0);
      dashPath.lineTo(startX + dashWidth, 0);
    }

    for (int i = 0; i < dashCountVertical; i++) {
      final startY = i * (dashWidth + dashSpace);
      dashPath.moveTo(size.width, startY);
      dashPath.lineTo(size.width, startY + dashWidth);
    }

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

class CreateFailureScreen extends StatefulWidget {
  final String failureType;
  final String? failureNo;
  final String? notificationCode;
  final bool isUpdate;
  final bool isFromJointInspection;
  final FailureItem? failureItem;

  const CreateFailureScreen(
      {super.key,
        this.failureType = "Maintenance",
        this.failureNo,
        this.notificationCode,
        this.isUpdate = false,
        this.isFromJointInspection = false,
        this.failureItem});

  @override
  State<CreateFailureScreen> createState() => _CreateFailureScreenState();
}

class _CreateFailureScreenState extends State<CreateFailureScreen>
    with SingleTickerProviderStateMixin {
  late final CreateFailureController controller;
  final session = Get.find<SessionController>();
  final _formKey = GlobalKey<FormState>();
  final _stationFormKey = GlobalKey<FormState>();
  final _formBottomKey = GlobalKey<FormState>();

  final _jointInspectionFormKey = GlobalKey<FormState>();
  final _jointInspectionOherDeptFormKey = GlobalKey<FormState>();
  final _sparePartFormKey = GlobalKey<FormState>();

  final _rcaRootCausePopupFormKey = GlobalKey<FormState>();
  final _rcaActionPopupFormKey = GlobalKey<FormState>();
  final _reqQtyFormKeys = <int, GlobalKey<FormState>>{};
  final _dismantleFormKey = GlobalKey<FormState>();

  void _scanQRCode() async {
    String? res = await SimpleBarcodeScanner.scanBarcode(
      context,
      barcodeAppBar: const BarcodeAppBar(
        appBarTitle: 'Scan QR Code',
        centerTitle: false,
        enableBackButton: true,
        backButtonIcon: Icon(Icons.arrow_back),
      ),
      isShowFlashIcon: true,
      delayMillis: 500,
      cameraFace: CameraFace.back,
    );
    if (res != null && res != '-1' && res.isNotEmpty) {
      controller.handleScannedQR(res);
    }
  }



  bool _validateForm(GlobalKey<FormState> key) {
    final isValid = key.currentState?.validate() ?? false;
    if (!isValid) {
      debugPrint("Form validation failed for key: $key");
      _scrollToFirstError(key);
    }
    return isValid;
  }

  void _scrollToFirstError(GlobalKey<FormState> formKey) {
    final formState = formKey.currentState;
    if (formState == null) return;

    // Validate to trigger error messages
    formState.validate();

    // Scroll to the form to show error messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = formKey.currentContext;
      if (context == null) return;

      Scrollable.ensureVisible(
        context,
        alignment: 0.0,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return "";

    // If it's already a DateTime
    if (dateValue is DateTime) {
      return DateFormat('dd/MM/yyyy hh:mm a').format(dateValue);
    }

    // If it's a string, try to parse it
    if (dateValue is String) {
      try {
        // Try parsing with various formats
        try {
          final dt = DateTime.parse(dateValue); // ISO8601 format
          return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
        } catch (e) {
          try {
            final dt = DateFormat('dd-MM-yyyy HH:mm').parse(dateValue);
            return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
          } catch (e2) {
            try {
              final dt = DateFormat('dd/MM/yyyy HH:mm').parse(dateValue);
              return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
            } catch (e3) {
              try {
                // ignore: unused_local_variable
                final _ = DateFormat('dd/MM/yyyy hh:mm a').parse(dateValue);
                return dateValue; // Already in correct format
              } catch (e4) {
                try {
                  final dt = DateFormat('MM/dd/yyyy HH:mm:ss').parse(dateValue);
                  return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
                } catch (e5) {
                  // Return as-is if parsing fails
                  return dateValue;
                }
              }
            }
          }
        }
      } catch (e) {
        return dateValue;
      }
    }

    return "";
  }

  bool _validateSubmitForms() {
    if (_isStationCreate || _isStationUpdate) {
      debugPrint("step1");
      return _validateForm(_stationFormKey);
    }

    if (controller.replacedMaterialsList.isNotEmpty) {
      debugPrint("step2");
      return _validateForm(_formKey) &&
          _validateForm(_formBottomKey) &&
          _reqQtyFormKeys.values.every((key) => _validateForm(key));
    }
    debugPrint("step3");
    return _validateForm(_formKey) && _validateForm(_formBottomKey);
  }

  bool _hasUnsavedChanges() {
    return controller.failureDescriptionController.text.isNotEmpty ||
        controller.selectedPriority.value != null ||
        controller.selectedDepartment.value != null ||
        controller.selectedLocation.value != null ||
        controller.selectedFunctionalLocation.value != null ||
        controller.selectedFailureCategoryType.value != null ||
        controller.selectedFailureOccurrenceDate.value != null ||
        controller.isServiceAffected.value ||
        controller.isPassengerAffected.value ||
        controller.isPtwRequired.value;
  }

  void _handleCancel() {
    if (_hasUnsavedChanges()) {
      Get.dialog(
        CustPopup(
          title: 'Unsaved Changes',
          message:
          'Changes you made may not be saved. Do you want to continue?',
          confirmText: 'Yes',
          cancelText: 'No',
          onConfirm: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          onCancel: () => Navigator.pop(context),
          showIcon: true,
          icon: Icons.warning_amber_outlined,
          iconColor: AppColors.orangeColor,
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CreateFailureController>()) {
      Get.delete<CreateFailureController>();
    }
    controller = Get.put(CreateFailureController());
    controller.failureCategory.value = widget.failureType;
    controller.isFromJointInspection.value = widget.isFromJointInspection;
    controller.failureDescriptionController.clear();

    // Check if arguments are passed from MaintenanceHistoryScreen
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      controller.setAssetDataFromQR(args);
      controller.setInspectionObservationContext(args);
    }

    if (widget.failureNo != null) {
      if (widget.isFromJointInspection) {
        controller.loadJointInspectionDetails(widget.failureNo!);
      } else if (widget.failureType == 'Station' &&
          controller.isStationController) {
        // Station Controller: use offline data if available, otherwise API
        if (widget.failureItem != null) {
          controller.loadStationFailureDetailsFromData(widget.failureItem!);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.loadStationFailureDetails(widget.failureNo!);
          });
        }
      } else if (controller.isJE) {
        // JE users: focus on online API flow first
        // Use API flow regardless of whether FailureItem is available
        if (widget.failureNo != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.loadFailureDetails(widget.failureNo!);
          });
        } else if (widget.failureItem != null) {
          // Fallback to offline flow only if failureNo is not available
          controller.loadJEFailureDetailsFromData(widget.failureItem!);
        }
      } else {
        // Fallback to API for other scenarios
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.loadFailureDetails(widget.failureNo!);
        });
      }
    } else if (widget.failureType == "Station") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.isStationController) {
          Get.snackbar(
            "Access Denied",
            "Only Station Controller can create station failure.",
            backgroundColor: AppColors.red.withValues(alpha: 0.9),
            colorText: AppColors.white1,
            snackPosition: SnackPosition.BOTTOM,
          );
          if (mounted) Navigator.pop(context);
          return;
        }
        // // Show station popup immediately; load dropdown master data in parallel
        // if (session.selectedStationId.value == null) {
        //   controller.fetchAndShowStationPopup();
        // }
        // Load appropriate dropdowns based on user type
        if (widget.failureType == 'Station') {
          controller.loadStationCreateDropdowns();
        } else {
          controller.loadJEDropdowns();
        }
      });
    }
  }

  /// Station Controller create only.
  bool get _isStationCreate =>
      widget.failureType == 'Station' && widget.failureNo == null;
  bool get _isStationUpdate =>
      widget.failureType == 'Station' &&
          widget.failureNo != null &&
          !controller.isJE;

  /// Station Controller view (read-only for existing station failure).
  bool get _isStationControllerView =>
      widget.failureType == 'Station' &&
          widget.failureNo != null &&
          controller.isStationController &&
          !widget.isUpdate;

  /// JE Change Notification — Maintenance, Station, OCC, Depot (existing failure).
  bool get _isJeChangeNotification =>
      widget.failureNo != null && !_isStationControllerView;

  bool get _isJointInspectionFlow =>
      widget.isFromJointInspection || controller.isFromJointInspection.value;

  void _showMeasurementDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.white1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustText.body("Measurement Reading",
                      fontWeightName: FontWeight.bold),
                  IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, size: 20)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Obx(() => ListView.builder(
                shrinkWrap: true,
                itemCount: controller.measurementPointsList.length,
                itemBuilder: (context, index) {
                  final item = controller.measurementPointsList[index];
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white1,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustText.detailLabel("Measurement Point"),
                        const SizedBox(height: 4),
                        CustText(
                          name: item['measPoint']?.toString() ?? '-',
                          size: 16,
                          color: AppColors.black,
                          fontWeightName: FontWeight.bold,
                        ),
                        const SizedBox(height: 12),
                        const Divider(
                            color: AppColors.dividerColor3, height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  CustText.detailLabel("Before Readings"),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: item['beforeReading'],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: "0",
                                      hintStyle: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade400),
                                      isDense: true,
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(4),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300)),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(4),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(4),
                                          borderSide: const BorderSide(
                                              color:
                                              AppColors.orangeColor)),
                                    ),
                                    onChanged: (v) =>
                                        controller.updateMeasurementReading(
                                            index, 'beforeReading', v),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  CustText.detailLabel("After Readings"),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: item['afterReading'],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: "0",
                                      hintStyle: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade400),
                                      isDense: true,
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(4),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300)),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(4),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(4),
                                          borderSide: const BorderSide(
                                              color:
                                              AppColors.orangeColor)),
                                    ),
                                    onChanged: (v) =>
                                        controller.updateMeasurementReading(
                                            index, 'afterReading', v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              )),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: CustButton(
                  name: "Save Changes",
                  size: 150,
                  onSelected: (_) => Get.back(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionByDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.white1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustText(
                      name: 'Action By',
                      size: 18,
                      color: AppColors.orangeColor,
                      fontWeightName: FontWeight.bold,
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, size: 22),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List
              Flexible(
                child: Obx(() {
                  final list = controller.notificationHistoryList;
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No action history available.',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return CustDataCard(
                        items: [
                          DataCardItem(
                              label: 'Action By',
                              value: item.actionBy ?? '-',
                              isFullWidth: true),
                          DataCardItem(
                              label: 'Status',
                              value: item.statusName ?? '-',
                              isFullWidth: true),
                          DataCardItem(
                              label: 'Action Date And Time',
                              value: item.actionOn ?? '-',
                              isFullWidth: true),
                          DataCardItem(
                              label: 'Remark',
                              value: item.remark ?? '-',
                              isFullWidth: true),
                        ],
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: _isJeChangeNotification
            ? 'Edit ${widget.failureType} Failure'
            : 'Create ${widget.failureType} Failure',
        showDrawer: false,
        onLeadingPressed: () {
          _handleCancel();
        },
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: const SyncIconButton(),
          ),
          if (_isStationCreate)
            GestureDetector(
              onTap: _scanQRCode,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(
                  TablerIcons.qrcode,
                  size: AppConstants.iconSize,
                  color: AppColors.white1,
                ),
              ),
            )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Obx(() {
          final syncService = Get.find<MasterDataSyncService>();
          if (syncService.isSyncing.value || controller.isLoading.value) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CustLoader(),
                const SizedBox(height: 16),
                CustText(
                  name: controller.isLoading.value
                      ? "Loading failure details..."
                      : syncService.syncStatus.value,
                  size: 14,
                  color: AppColors.orangeColor,
                ),
              ],
            );
          }
          // Removed blocking loader - data loads in background
          return _buildFailureFormBody(context);
        }),
      ),
    );
  }

  Widget _buildFailureFormBody(BuildContext context) {
    if (_isStationCreate ||
        (widget.isUpdate && widget.failureType == 'Station')) {
      // _buildStationCreateForm -> UnifiedFormBuilder.buildForm already
      // wraps its content in a Form(key: _stationFormKey, ...); do not
      // wrap it in a second Form with the same key here.
      return _buildStationCreateForm(context);
    }
    if (_isStationControllerView) {
      return _buildStationControllerView(context);
    }

    if (controller.isSectionIncharge) {
      return UnifiedFormBuilder.buildForm(
        userRole: UserRole.sectionIncharge,
        controller: controller,
        formKey: _formKey,
        isFormDisabled: controller.isFormDisabled,
        onSubmit: _submitForm,
        onCancel: _handleCancel,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFailureHeader(showHistoryIcon: true),
            const SizedBox(height: AppConstants.elementSpacing),
            _buildFailureNumberDisplay(),
          ],
        ),
      );
    }

    // The real JE form (below) is NOT self-wrapping like UnifiedFormBuilder -
    // it needs this Form(key: _formKey) around it for validators to work.
    return Form(key: _formKey, child: _buildJeChangeNotificationForm(context));
  }

  Widget _buildStationCreateForm(BuildContext context) {
    return UnifiedFormBuilder.buildForm(
      userRole: UserRole.stationController,
      controller: controller,
      formKey: _stationFormKey,
      isFormDisabled: controller.isFormDisabled,
      onSubmit: _submitForm,
      onCancel: _handleCancel,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFailureHeader(),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildFailureNumberDisplay(),
        ],
      ),
    );
  }

  Widget _buildJeChangeNotificationForm(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFailureHeader(showHistoryIcon: true),
            const SizedBox(height: AppConstants.elementSpacing),
            _buildFailureNumberDisplay(
                fallbackNotificationCode: widget.notificationCode),
            const SizedBox(height: AppConstants.sectionSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustSection(
                  title: "Failure Information",
                  trailing: _buildExpandCollapseButton(),
                  isVisible: controller.isBasicInfoVisible.value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isJointInspectionFlow) ...[
                        Row(
                          children: [
                            Expanded(
                                child: CustomTextField(
                                    label: "Priority",
                                    controller:
                                    controller.priorityDisplayController,
                                    enabled: false)),
                            const SizedBox(width: AppConstants.elementSpacing),
                            Expanded(
                                child: CustomTextField(
                                    label: "Department",
                                    controller:
                                    controller.departmentDisplayController,
                                    enabled: false)),
                          ],
                        ),
                      ] else
                        Obx(() => Row(
                          children: [
                            Expanded(
                                child: CustDropdown(
                                  label: "Priority",
                                  hint: "Priority",
                                  items: controller.priorityTypeList
                                      .map((e) => e.label ?? '')
                                      .toList(),
                                  selectedValue:
                                  controller.selectedPriority.value,
                                  onChanged: (value) =>
                                  controller.selectedPriority.value = value,
                                  enabled: false,
                                )),
                            const SizedBox(
                                width: AppConstants.elementSpacing),
                            Expanded(
                                child: CustDropdown(
                                  label: "Department",
                                  hint: "Department",
                                  items: controller.departmentList
                                      .map((e) => e.label ?? '')
                                      .toList()
                                      .isNotEmpty
                                      ? controller.departmentList
                                      .map((e) => e.label ?? '')
                                      .toList()
                                      : Get.find<SessionController>()
                                      .departments
                                      .map((e) => e.deptName ?? '')
                                      .toList(),
                                  selectedValue:
                                  controller.selectedDepartment.value ??
                                      Get.find<SessionController>()
                                          .selectedDepartment
                                          .value
                                          ?.deptName,
                                  onChanged: (value) async {
                                    await controller.onDepartmentChanged(value);
                                  },
                                  enabled: false,
                                )),
                          ],
                        )),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustText.formLabel("Failure Description:"),
                      Obx(() {
                        if (controller
                            .notificationDescriptionHistoryList.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  height: ResponsiveHelper.spacing(
                                      context, AppConstants.labelSpacing)),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                  Border.all(color: Colors.grey.shade200),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: controller
                                      .notificationDescriptionHistoryList
                                      .length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = controller
                                        .notificationDescriptionHistoryList[
                                    index];
                                    return Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          CustText(
                                            name: item.description ?? "",
                                            size: 13,
                                            color: AppColors.textDarkPrimary,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: CustText(
                                                  name: item.createdBy ??
                                                      "Unknown User",
                                                  size: 11,
                                                  color: AppColors
                                                      .textDarkSecondary,
                                                  overflow:
                                                  TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              CustText(
                                                name: item.createdOn ?? "",
                                                size: 11,
                                                color:
                                                AppColors.textDarkSecondary,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      if (!_isJointInspectionFlow) ...[
                        const SizedBox(height: AppConstants.labelSpacing),
                        CustomTextField(
                          controller: controller.failureDescriptionController,
                          hintText: "Enter description",
                          maxLines: 4,
                          enabled: !controller.isFormDisabled &&
                              (controller.isJE && !_isJointInspectionFlow ||
                                  controller.isTechnician),
                        ),
                      ],
                      const SizedBox(height: AppConstants.elementSpacing),
                      if (_isJointInspectionFlow) ...[
                        CustomTextField(
                          label: "Location",
                          controller: controller.locationDisplayController,
                          enabled: false,
                        ),
                        const SizedBox(height: AppConstants.elementSpacing),
                        CustomTextField(
                          label: "Functional Location",
                          controller:
                          controller.functionalLocationDisplayController,
                          enabled: false,
                        ),
                        const SizedBox(height: AppConstants.elementSpacing),
                        CustomTextField(
                          label: "Equipment Number",
                          controller: controller.equipmentDisplayController,
                          enabled: false,
                        ),
                        const SizedBox(height: AppConstants.elementSpacing),
                        CustomTextField(
                          label: "Person Responsible",
                          controller:
                          controller.personResponsibleDisplayController,
                          enabled: false,
                        ),
                        const SizedBox(height: AppConstants.elementSpacing),
                        Obx(() => CustDateTimePicker(
                            label: "Actual Failure Occurrence",
                            hint: "Actual Failure Occurrence",
                            selectedDateTime:
                            controller.selectedFailureOccurrenceDate.value,
                            enabled: false,
                            onDateTimeSelected: (_) {})),
                        const SizedBox(height: AppConstants.elementSpacing),
                        Obx(() => CustDateTimePicker(
                            label: "Failure Attended",
                            hint: "Failure Attended",
                            selectedDateTime:
                            controller.selectedFailureAttendedDate.value,
                            enabled: false,
                            onDateTimeSelected: (date) => controller
                                .onFailureAttendedDateSelected(date))),
                        const SizedBox(height: AppConstants.elementSpacing),
                        Obx(() => CustDateTimePicker(
                            label: "Actual Failure Rectified*",
                            hint: "Actual Failure Rectified",
                            selectedDateTime: controller
                                .selectedActualFailureRectifiedDate.value,
                            enabled: false,
                            onDateTimeSelected: (date) => controller
                                .selectedActualFailureRectifiedDate
                                .value = date)),
                        const SizedBox(height: AppConstants.elementSpacing),
                      ] else
                        Obx(() => Column(
                          children: [
                            CustDropdown(
                              label: 'Location *',
                              hint: 'Select location',
                              items: controller.locationTypeList
                                  .map((e) => e.label ?? '')
                                  .toList(),
                              selectedValue:
                              controller.selectedLocation.value,
                              enabled: !controller.isFormDisabled &&
                                  controller.isJE &&
                                  !_isJointInspectionFlow,
                              onChanged: (value) {
                                controller.onLocationChanged(value);
                              },
                              validator: (val) {
                                if (val == null ||
                                    val.trim().isEmpty ||
                                    val == "Select") {
                                  return "Location is required";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(
                                height: AppConstants.elementSpacing),
                            Obx(() {
                              if (controller
                                  .isFunctionalLocationLoading.value) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                          const AlwaysStoppedAnimation<
                                              Color>(Colors.orange),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Loading functional locations...',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return CustDropdown(
                                label: 'Functional Location *',
                                hint: 'Select functional location',
                                items: controller.functionalLocationList
                                    .map((e) => e.label ?? '')
                                    .toList(),
                                selectedValue: controller
                                    .selectedFunctionalLocation.value,
                                enabled: !controller.isFormDisabled &&
                                    controller.isJE &&
                                    !_isJointInspectionFlow,
                                onChanged: (value) {
                                  debugPrint(
                                      'JE view: onFunctionalLocationChanged called with value: $value');
                                  controller
                                      .onFunctionalLocationChanged(value);
                                },
                                validator: (val) {
                                  if (val == null ||
                                      val.trim().isEmpty ||
                                      val == "Select") {
                                    return "Functional Location is required";
                                  }
                                  return null;
                                },
                              );
                            }),
                            const SizedBox(
                                height: AppConstants.elementSpacing),
                            CustomTextField(
                              label: "System",
                              controller: controller.systemController,
                              enabled: false,
                            ),
                            const SizedBox(
                                height: AppConstants.elementSpacing),
                            CustomTextField(
                              label: "Subsystem",
                              controller: controller.subsystemController,
                              enabled: false,
                            ),
                            const SizedBox(
                                height: AppConstants.elementSpacing),
                            CustDropdown(
                              label: 'Equipment Number *',
                              hint: controller.isEquipmentLoading.value
                                  ? 'Loading...'
                                  : 'Select equipment number',
                              items: controller.equipmentList
                                  .map((e) => e.label ?? '')
                                  .toList(),
                              selectedValue:
                              controller.selectedEquipmentNumber.value,
                              enabled: !controller.isFormDisabled &&
                                  controller.isJE &&
                                  !_isJointInspectionFlow &&
                                  !controller.isEquipmentLoading.value,
                              onChanged: (value) {
                                if (controller.isFormDisabled) return;
                                controller.onEquipmentChanged(value);
                              },
                            ),
                            const SizedBox(
                                height: AppConstants.elementSpacing),
                            CustDateTimePicker(
                              label: "Actual Failure Occurrence",
                              hint: "Actual Failure Occurrence",
                              selectedDateTime: controller
                                  .selectedFailureOccurrenceDate.value,
                              enabled: false,
                              onDateTimeSelected: (value) => controller
                                  .selectedFailureOccurrenceDate
                                  .value = value,
                            ),
                          ],
                        )),
                      if (!_isJointInspectionFlow) ...[
                        const SizedBox(height: AppConstants.elementSpacing),
                        Obx(() => CustDropdown(
                            label: 'Notification Type *',
                            hint: 'Select Type',
                            items: controller.notificationTypeList
                                .map((e) => e.label ?? '')
                                .toList(),
                            selectedValue:
                            controller.selectedNotificationType.value,
                            enabled: !controller.isFormDisabled &&
                                controller.isJE &&
                                !_isJointInspectionFlow,
                            validator: (v) => controller.isJE &&
                                !_isJointInspectionFlow
                                ? _requiredDropdown(
                                controller.selectedNotificationType.value,
                                'Notification Type')
                                : null,
                            onChanged: (v) {
                              if (controller.isFormDisabled) return;
                              controller.selectedNotificationType.value = v;
                            })),
                        const SizedBox(height: AppConstants.elementSpacing),
                        CustomTextField(
                          controller: controller.subLocationController,
                          label: "Sub Location",
                          enabled: !controller.isFormDisabled &&
                              controller.isJE &&
                              !_isJointInspectionFlow,
                        ),
                        const SizedBox(height: AppConstants.elementSpacing),
                      ],
                    ],
                  ),
                ),
                CustSection(
                  title: "Service Affected *",
                  trailing: Obx(() => YesNoToggle(
                    value: controller.isServiceAffected.value,
                    onChanged: controller.isFormDisabled
                        ? (_) {}
                        : (val) {
                      controller.trainDelayNosController.clear();
                      controller.tripDelayUplineController.clear();
                      controller.trainCancelNosController.clear();
                      controller.tripDelayDownlineController.clear();
                      controller.trainDelayMinController.clear();
                      controller.trainWithdrawalNosController.clear();
                      controller.trainReplaceNosController.clear();
                      controller.isPassengerDeboarding.value = false;
                      controller.isServiceAffected.value = val;
                    },
                    enabled: !controller.isFormDisabled &&
                        controller.isJE &&
                        !_isJointInspectionFlow,
                  )),
                  isVisible: controller.isServiceAffected.value,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: CustomTextField(
                                label: "Train Delay In Min. *",
                                controller: controller.trainDelayMinController,
                                keyboardType: TextInputType.number,
                                enabled: controller.isJE && !_isJointInspectionFlow,
                                validator: (val) =>
                                controller.isServiceAffected.value
                                    ? _requiredText(val, 'Train Delay In Min.')
                                    : null,
                              )),
                          const SizedBox(width: AppConstants.elementSpacing),
                          Expanded(
                              child: CustomTextField(
                                label: "Train Delay (NOS) *",
                                controller: controller.trainDelayNosController,
                                keyboardType: TextInputType.number,
                                enabled: controller.isJE && !_isJointInspectionFlow,
                                validator: (val) =>
                                controller.isServiceAffected.value
                                    ? _requiredText(val, 'Train Delay (NOS)')
                                    : null,
                              )),
                        ],
                      ),
                      const SizedBox(height: AppConstants.elementSpacing),
                      Row(
                        children: [
                          Expanded(
                              child: CustomTextField(
                                label: "Train Cancel (NOS) *",
                                controller: controller.trainCancelNosController,
                                keyboardType: TextInputType.number,
                                enabled: controller.isJE && !_isJointInspectionFlow,
                                validator: (val) =>
                                controller.isServiceAffected.value
                                    ? _requiredText(val, 'Train Cancel (NOS)')
                                    : null,
                              )),
                          const SizedBox(width: AppConstants.elementSpacing),
                          Expanded(
                              child: CustomTextField(
                                label: "Train Withdrawal (NOS) *",
                                controller: controller.trainWithdrawalNosController,
                                keyboardType: TextInputType.number,
                                enabled: controller.isJE && !_isJointInspectionFlow,
                                validator: (val) => controller
                                    .isServiceAffected.value
                                    ? _requiredText(val, 'Train Withdrawal (NOS)')
                                    : null,
                              )),
                        ],
                      ),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustomTextField(
                        label: "Train Replace (NOS) *",
                        controller: controller.trainReplaceNosController,
                        keyboardType: TextInputType.number,
                        enabled: !controller.isFormDisabled &&
                            controller.isJE &&
                            !_isJointInspectionFlow,
                        validator: (val) => controller.isServiceAffected.value
                            ? _requiredText(val, 'Train Replace (NOS)')
                            : null,
                      ),
                      const SizedBox(height: AppConstants.elementSpacing),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustText(
                            name: "Passenger Deboarded",
                            size: AppConstants.textSize,
                            fontWeightName: FontWeight.w600,
                            color: AppColors.orangeColor,
                          ),
                          Obx(() => YesNoToggle(
                            value: controller.isPassengerDeboarding.value,
                            onChanged: (val) {
                              if (controller.isFormDisabled) return;
                              controller.trainDeboardedNosController
                                  .clear();
                              controller.isPassengerDeboarding.value = val;
                            },
                            enabled: !controller.isFormDisabled &&
                                controller.isJE &&
                                !_isJointInspectionFlow,
                          )),
                        ],
                      ),
                      Obx(() {
                        if (!controller.isPassengerDeboarding.value) {
                          return const SizedBox.shrink();
                        }
                        return CustomTextField(
                          label: "Train Deboarded (NOS) *",
                          controller: controller.trainDeboardedNosController,
                          keyboardType: TextInputType.number,
                          enabled: !controller.isFormDisabled &&
                              controller.isJE &&
                              !_isJointInspectionFlow,
                          validator: (val) =>
                          controller.isPassengerDeboarding.value
                              ? _requiredText(val, 'Train Deboarded (NOS)')
                              : null,
                        );
                      }),
                    ],
                  ),
                ),
                if (widget.failureType != "Maintenance")
                  CustSection(
                    title: "Passenger Affected *",
                    trailing: Obx(() => YesNoToggle(
                      value: controller.isPassengerAffected.value,
                      onChanged: (val) {
                        if (controller.isFormDisabled) return;
                        if (val == false) {
                          controller.passengersAffectedCountController
                              .clear();
                          controller.trappedDurationController.clear();
                          controller.rescuedDurationController.clear();
                        } else if (val == true) {
                          controller.passengersAffectedCountController
                              .clear();
                          controller.trappedDurationController.clear();
                          controller.rescuedDurationController.clear();
                        }
                        controller.isPassengerAffected.value = val;
                      },
                      enabled: !controller.isFormDisabled &&
                          controller.isJE &&
                          !_isJointInspectionFlow,
                    )),
                    isVisible: controller.isPassengerAffected.value,
                    child: Column(
                      children: [
                        CustomTextField(
                          label: "Number Of Passenger Affected *",
                          controller:
                          controller.passengersAffectedCountController,
                          keyboardType: TextInputType.number,
                          enabled: !controller.isFormDisabled &&
                              controller.isJE &&
                              !_isJointInspectionFlow,
                          hintText: "Enter number of Passenger Affected",
                          validator: (val) =>
                          controller.isPassengerAffected.value
                              ? _requiredText(
                              val, 'Number Of Passenger Affected')
                              : null,
                        ),
                        const SizedBox(height: AppConstants.elementSpacing),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: "Trapped Duration (In Min)",
                                controller:
                                controller.trappedDurationController,
                                keyboardType: TextInputType.number,
                                enabled:
                                controller.isJE && !_isJointInspectionFlow,
                                hintText: "Enter Trapped Duration",
                              ),
                            ),
                            const SizedBox(width: AppConstants.elementSpacing),
                            Expanded(
                              child: CustomTextField(
                                label: "Rescued Duration (In Min)",
                                controller:
                                controller.rescuedDurationController,
                                keyboardType: TextInputType.number,
                                enabled:
                                controller.isJE && !_isJointInspectionFlow,
                                hintText: "Enter Rescued Duration",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                CustSection(
                  title: "PTW Required? *",
                  trailing: Obx(() => YesNoToggle(
                    enabled: !controller.isFormDisabled &&
                        !_isJointInspectionFlow,
                    value: controller.isPtwRequired.value,
                    onChanged: (val) {
                      if (controller.isFormDisabled) return;
                      if (val == false) {
                        controller.ptwNumberController.clear();
                      } else if (val == true) {
                        controller.ptwNumberController.clear();
                      }
                      controller.isPtwRequired.value = val;
                    },
                  )),
                  isVisible: controller.isPtwRequired.value,
                  child: Column(
                    children: [
                      CustomTextField(
                          controller: controller.ptwNumberController,
                          label: "PTW Number *",
                          keyboardType: TextInputType.number,
                          hintText: "Enter PTW Number",
                          enabled: !controller.isFormDisabled,
                          validator: (val) {
                            if (controller.isPtwRequired.value &&
                                (val == null || val.trim().isEmpty)) {
                              return "PTW Number is required";
                            }
                            return null;
                          }),
                    ],
                  ),
                ),
              ],
            ),
            CustSection(
              title: "Failure Rectification Details (RCA)",
              child: Column(
                children: [
                  if (!_isJointInspectionFlow)
                    Form(
                      key: _rcaFormKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: controller.subsystemController,
                            label: "Subsystem *",
                            enabled: !controller.isFormDisabled,
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          Obx(() => CustDropdown(
                            label: 'Failure Category *',
                            hint: 'Failure Category',
                            items: controller.rcaFailureCategoryList
                                .map((e) => e.label ?? '')
                                .toList(),
                            selectedValue:
                            controller.selectedRcaFailureCategory.value,
                            enabled: !controller.isFormDisabled &&
                                (controller.isJE ||
                                    controller.isTechnician),
                            validator: (v) => _requiredDropdown(
                              controller.selectedRcaFailureCategory.value,
                              'Failure Category',
                            ),
                            onChanged: (v) =>
                                controller.onRcaFailureCategorySelected(v),
                          )),
                          const SizedBox(height: AppConstants.elementSpacing),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: CustButton(
                              name: "Add",
                              size: 100,
                              fontSize: AppConstants.buttonFontSize,
                              onSelected: !controller.isFormDisabled &&
                                  (controller.isJE ||
                                      controller.isTechnician)
                                  ? (_) {
                                if (_validateForm(_rcaFormKey)) {
                                  controller.addRcaDetail();
                                  _rcaFormKey.currentState?.reset();
                                }
                              }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => Column(
                    children: controller.rcaDetailsList
                        .asMap()
                        .entries
                        .map((entry) =>
                        _buildRcaDetailCard(entry.value, entry.key))
                        .toList(),
                  )),
                  const SizedBox(height: AppConstants.elementSpacing),
                ],
              ),
            ),
            Obx(() => CustSection(
              title: "Failure Type",
              child: Column(
                children: [
                  CustDropdown(
                    label: "Failure Type *",
                    hint: "Select Failure Type",
                    items: controller.corrFailureTypeList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue: controller.selectedMaterialType.value,
                    enabled: !controller.isFormDisabled &&
                        (controller.isJE || controller.isTechnician),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          value == 'Select Failure Type') {
                        return 'Please select failure type';
                      }
                      return null;
                    },
                    onChanged: (v) {
                      if (controller.isFormDisabled) return;
                      controller.selectedMaterialType.value = v!;
                    },
                  ),
                  if (controller.selectedMaterialType.value == "Other") ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                        label: "Remark",
                        controller: controller.failureTypeController,
                        enabled: !controller.isFormDisabled &&
                            (controller.isJE || controller.isTechnician)),
                  ]
                ],
              ),
            )),
            Obx(() {
              if (controller.selectedMaterialType.value != "Hardware") {
                return const SizedBox.shrink();
              }

              return CustSection(
                title: "Spare Part Replace",
                trailing: YesNoToggle(
                  value: controller.isSparePartReplaced.value,
                  onChanged: (val) {
                    if (controller.isFormDisabled) return;
                    if (val == false) {
                      controller.replacedMaterialsList.clear();
                    } else if (val == true) {
                      controller.replacedMaterialsList.clear();
                    }
                    controller.isSparePartReplaced.value = val;
                  },
                  enabled: !controller.isFormDisabled &&
                      controller.isJE &&
                      controller.replacedMaterialsList.isEmpty,
                ),
                isVisible: controller.isSparePartReplaced.value,
                child: controller.isSparePartReplaced.value
                    ? _buildSparePartReplaceSection(
                  enabled: !controller.isFormDisabled &&
                      (controller.isJE || controller.isTechnician),
                )
                    : const SizedBox.shrink(),
              );
            }),
            Obx(() {
              if (controller.selectedMaterialType.value != "Hardware" &&
                  controller.replacedMaterialsList.isEmpty) {
                return const SizedBox.shrink();
              }

              return CustSection(
                title: "Material Dismantle",
                isVisible: controller.isMaterialDismantle.value,
                trailing: YesNoToggle(
                  value: controller.isMaterialDismantle.value,
                  onChanged: (val) {
                    if (controller.isFormDisabled) return;
                    if (val == false) {
                      controller.dismantleMaterialsList.clear();
                    } else if (val == true) {
                      controller.dismantleMaterialsList.clear();
                    }
                    controller.isMaterialDismantle.value = val;
                  },
                  enabled: !controller.isFormDisabled &&
                      (controller.isJE || controller.isTechnician) &&
                      controller.dismantleMaterialsList.isEmpty,
                ),
                child: _buildMaterialDismantleSection(
                  enabled: !controller.isFormDisabled &&
                      (controller.isJE || controller.isTechnician),
                ),
              );
            }),
            if (!_isJointInspectionFlow)
              CustSection(
                title: "Joint Inspection *",
                trailing: Obx(() => YesNoToggle(
                  value: controller.isJointInspection.value,
                  onChanged: (val) {
                    if (controller.isFormDisabled) return;
                    controller.isJointInspection.value = val;
                  },
                  enabled: !controller.isFormDisabled &&
                      controller.isJE &&
                      controller.jointInspectionHistoryList.isEmpty,
                )),
                isVisible: controller.isJointInspection.value,
                child: Obx(
                      () => _buildJointInspectionSection(
                    enabled: controller.isJE,
                  ),
                ),
              ),
            Obx(
                  () => controller.showMeasurementButton.value
                  ? CustSection(
                title: "Measurement Reading",
                child: Align(
                  alignment: Alignment.centerRight,
                  child: CustButton(
                    name: "Measurement Reading",
                    fontSize: AppConstants.buttonFontSize,
                    size: 200,
                    onSelected: (_) => _showMeasurementDialog(),
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
            Form(
              key: _formBottomKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustSection(
                    title: "Attachments",
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CustText.body("After ",
                                fontWeightName: FontWeight.w500),
                            const Text("(Max File Size 1MB)",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const SizedBox(width: AppConstants.sectionSpacing),
                            if (!_isJointInspectionFlow)
                              _buildUploadButton(controller.afterFiles,
                                  enabled: controller.isJE &&
                                      !_isJointInspectionFlow ||
                                      controller.isTechnician),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Obx(() => Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: controller.afterFiles
                              .map<Widget>((file) => _buildAttachmentItem(
                              file['name']!,
                              file['size']!,
                              controller.afterFiles,
                              file))
                              .toList(),
                        )),
                        const SizedBox(height: AppConstants.sectionSpacing),
                        Row(
                          children: [
                            CustText.body("Upload RCA ",
                                fontWeightName: FontWeight.w500),
                            const Text("(Max File Size 1MB)",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const SizedBox(width: AppConstants.sectionSpacing),
                            if (!_isJointInspectionFlow)
                              _buildUploadButton(controller.rcaFiles,
                                  enabled: controller.isJE &&
                                      !_isJointInspectionFlow ||
                                      controller.isTechnician),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Obx(() => Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: controller.rcaFiles
                              .map<Widget>((file) => _buildAttachmentItem(
                              file['name']!,
                              file['size']!,
                              controller.rcaFiles,
                              file))
                              .toList(),
                        )),
                        const SizedBox(height: AppConstants.sectionSpacing),
                        Obx(() {
                          final hasImages =
                              controller.beforeImagesList.isNotEmpty ||
                                  controller.afterImagesList.isNotEmpty ||
                                  controller.rcaImagesList.isNotEmpty;
                          if (!hasImages) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const SizedBox(
                                  height: AppConstants.sectionSpacing),
                              CustText(
                                name: "Display Uploaded Images:",
                                color: AppColors.textDarkSecondary,
                                fontWeightName: FontWeight.w500,
                                size: AppConstants.textSize,
                              ),
                              const SizedBox(height: AppConstants.labelSpacing),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        CustText.body("Before:"),
                                        const SizedBox(height: 8),
                                        Obx(() => Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: controller
                                              .beforeImagesList
                                              .map<Widget>((file) =>
                                              _buildUploadedImagePreview(
                                                  file['path']!))
                                              .toList(),
                                        )),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        CustText.body("After:"),
                                        const SizedBox(height: 8),
                                        Obx(() => Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: controller
                                              .afterImagesList
                                              .map<Widget>((file) =>
                                              _buildUploadedImagePreview(
                                                  file['path']!))
                                              .toList(),
                                        )),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        CustText.body("RCA:"),
                                        const SizedBox(height: 8),
                                        Obx(() => Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: controller.rcaImagesList
                                              .map<Widget>((file) =>
                                              _buildUploadedImagePreview(
                                                  file['path']!))
                                              .toList(),
                                        )),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  if (!_isJointInspectionFlow)
                    CustSection(
                      title: "Failure Rectification Details",
                      child: Column(
                        children: [
                          CustomTextField(
                            label: "Failure Rectification Details *",
                            controller: controller
                                .failureRectificationDetailsController,
                            focusNode: controller.failureRectificationFocusNode,
                            hintText: "Enter Rectification Details",
                            enabled: !controller.isFormDisabled &&
                                controller.isJE &&
                                !_isJointInspectionFlow,
                            maxLines: 4,
                            autofocus: false,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "Failure Rectification Details is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          CustDropdown(
                            label: "User Status *",
                            hint: "Select",
                            items: controller.userStatusJeList
                                .map((e) => e.label ?? '')
                                .toList(),
                            selectedValue: controller.selectedUserStatus.value,
                            enabled: !controller.isFormDisabled &&
                                controller.isJE &&
                                !_isJointInspectionFlow,
                            disabledItemFn: controller.isCloseUserStatusBlocked
                                ? (item) => item.trim().toLowerCase() == 'close'
                                : null,
                            onChanged: (v) {
                              if (controller.isFormDisabled) return;
                              debugPrint("Selected User Status = $v");
                              debugPrint(
                                  "Main Status = ${controller.mainStatusName.value}");
                              debugPrint(
                                  "Blocked = ${controller.isCloseUserStatusBlocked}");

                              if (controller.isCloseUserStatusBlocked &&
                                  v?.trim().toLowerCase() == 'closed') {
                                controller.showPendingJointInspectionPopup();
                                return;
                              }

                              controller.selectedUserStatus.value = v;
                              // Unfocus the failure rectification details field
                              controller.failureRectificationFocusNode
                                  .unfocus();
                            },
                            validator: (value) {
                              if (controller.selectedUserStatus.value ==
                                  null ||
                                  controller.selectedUserStatus.value!
                                      .trim()
                                      .isEmpty ||
                                  controller.selectedUserStatus.value ==
                                      "Select User Status") {
                                return "User Status is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          if (controller.selectedUserStatus.value ==
                              "Under Observation") ...[
                            CustDateTimePicker(
                              label: "Under Observation Date *",
                              hint: "DD/MM/YYYY hh:mm",
                              selectedDateTime:
                              controller.selectedUnderObservationDate.value,
                              enabled: !controller.isFormDisabled &&
                                  controller.isJE &&
                                  !_isJointInspectionFlow,
                              firstDate: DateTime.now(),
                              validator: (val) {
                                if (controller.selectedUserStatus.value ==
                                    "Under Observation" &&
                                    controller.selectedUnderObservationDate
                                        .value ==
                                        null) {
                                  return "Under Observation Date is required";
                                }
                                return null;
                              },
                              onDateTimeSelected: (dt) {
                                if (controller.isFormDisabled) return;
                                controller.selectedUnderObservationDate.value =
                                    dt;
                                controller.failureRectificationFocusNode
                                    .unfocus();
                              },
                            ),
                            const SizedBox(height: AppConstants.elementSpacing),
                          ],
                          CustDateTimePicker(
                            label: "Failure Attended *",
                            hint: "DD/MM/YYYY hh:mm",
                            selectedDateTime:
                            controller.selectedFailureAttendedDate.value,
                            enabled: !controller.isFormDisabled &&
                                controller.isJE &&
                                !_isJointInspectionFlow,
                            firstDate:
                            controller.selectedFailureOccurrenceDate.value,
                            lastDate: DateTime.now(),
                            onDateTimeSelected: (dateTime) {
                              if (controller.isFormDisabled) return;
                              controller
                                  .onFailureAttendedDateSelected(dateTime);
                              controller.failureRectificationFocusNode
                                  .unfocus();
                            },
                            validator: (value) {
                              if (controller
                                  .selectedFailureAttendedDate.value ==
                                  null) {
                                return "Failure Attended is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          CustDateTimePicker(
                            label: "Actual Failure Rectified *",
                            hint: "DD/MM/YYYY hh:mm",
                            selectedDateTime: controller
                                .selectedActualFailureRectifiedDate.value,
                            enabled: !controller.isFormDisabled &&
                                controller.isJE &&
                                !_isJointInspectionFlow,
                            firstDate: controller
                                .selectedFailureAttendedDate.value ??
                                controller.selectedFailureOccurrenceDate.value,
                            lastDate: DateTime.now(),
                            onDateTimeSelected: (dateTime) {
                              if (controller.isFormDisabled) return;
                              controller.onActualFailureRectifiedDateSelected(
                                  dateTime);
                              controller.failureRectificationFocusNode
                                  .unfocus();
                            },
                            validator: (value) {
                              if (controller.selectedActualFailureRectifiedDate
                                  .value ==
                                  null) {
                                return "Actual Failure Rectified is required";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  if (_isJointInspectionFlow) ...[
                    const SizedBox(height: AppConstants.sectionSpacing),
                    _buildJointInspectionActionFields(),
                    const SizedBox(height: AppConstants.sectionSpacing),
                  ],
                  Row(
                    children: [
                      if (controller.isFormDisabled)
                        Expanded(
                          child: CustButton(
                            name: "Back",
                            sHeight: AppConstants.buttonHeight,
                            size: double.infinity,
                            onSelected: (_) => _handleCancel(),
                          ),
                        )
                      else ...[
                        Expanded(
                          child: CustOutlineButton(
                            name: "Cancel",
                            size: double.infinity,
                            sHeight: AppConstants.buttonHeight,
                            onSelected: (_) => _handleCancel(),
                          ),
                        ),
                        const SizedBox(width: AppConstants.elementSpacing),
                        Expanded(
                          child: CustButton(
                            name: "Submit",
                            sHeight: AppConstants.buttonHeight,
                            size: double.infinity,
                            onSelected: (_) => _isJointInspectionFlow
                                ? _submitJointInspectionForm()
                                : _submitForm(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Common header widget used across all forms
  Widget _buildFailureHeader({bool showHistoryIcon = false}) {
    return Row(
      children: [
        CustText.sectionHeader(
          "Failure Details",
          color: AppColors.orangeColor,
        ),
        Spacer(),
        GestureDetector(
          onTap: _showActionByDialog,
          child: Icon(
            TablerIcons.user_check,
            size: 24,
            color: AppColors.orangeColor,
          ),
        ),
        if (showHistoryIcon) ...[
          SizedBox(width: 10),
          GestureDetector(
            onTap: () => Get.to(() => MaintenanceHistoryScreen()),
            child: Icon(TablerIcons.history,
                size: 24, color: AppColors.orangeColor),
          ),
        ],
      ],
    );
  }

  // Common failure number display widget
  Widget _buildFailureNumberDisplay({String? fallbackNotificationCode}) {
    return Obx(() => CustText.body(
      "Failure No.: ${(controller.notificationCode.value.isNotEmpty ? controller.notificationCode.value : fallbackNotificationCode) ?? ""} ${controller.mainStatusName.value == null ? "" : "(${controller.mainStatusName.value ?? ''})"}",
      size: 18,
      color: AppColors.black,
      fontWeightName: FontWeight.w600,
    ));
  }

  // Common expand/collapse button for sections
  Widget _buildExpandCollapseButton() {
    return Obx(() => IconButton(
      icon: Icon(
        controller.isBasicInfoVisible.value ? Icons.remove : Icons.add,
        color: AppColors.orangeColor,
        size: 30,
      ),
      onPressed: () {
        controller.isBasicInfoVisible.value =
        !controller.isBasicInfoVisible.value;
      },
    ));
  }

  Widget _buildStationControllerView(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFailureHeader(),
            const SizedBox(height: AppConstants.elementSpacing),
            _buildFailureNumberDisplay(),
            const SizedBox(height: AppConstants.sectionSpacing),
            Obx(() => CustSection(
              title: "Failure Information",
              trailing: _buildExpandCollapseButton(),
              isVisible: controller.isBasicInfoVisible.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => CustomTextField(
                      label: "Functional Location",
                      controller: TextEditingController(
                          text:
                          controller.selectedFunctionalLocation.value ??
                              ''),
                      enabled: false)),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                          child: Obx(() => CustomTextField(
                              label: "Priority",
                              controller: TextEditingController(
                                  text: controller.selectedPriority.value ??
                                      ''),
                              enabled: false))),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                          child: Obx(() => CustomTextField(
                              label: "Department",
                              controller: TextEditingController(
                                  text:
                                  controller.selectedDepartment.value ??
                                      ''),
                              enabled: false))),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => CustomTextField(
                      label: "Current Status",
                      controller: TextEditingController(
                          text: controller.mainStatusName.value ?? ''),
                      enabled: false)),
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustomTextField(
                    label: "Failure Description",
                    controller: controller.failureDescriptionController,
                    maxLines: 3,
                    enabled: false,
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => CustomTextField(
                      label: "Location",
                      controller: TextEditingController(
                          text: controller.selectedLocation.value ?? ''),
                      enabled: false)),
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustomTextField(
                      label: "Sub Location",
                      controller: controller.subLocationController,
                      enabled: false),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                          child: CustomTextField(
                              label: "System",
                              controller: controller.systemController,
                              enabled: false)),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                          child: CustomTextField(
                              label: "Train Id",
                              controller: controller.trainIdController,
                              enabled: false)),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustDateTimePicker(
                    label: "Actual Failure Occurrence",
                    hint: "Actual Failure Occurrence",
                    selectedDateTime:
                    controller.selectedFailureOccurrenceDate.value,
                    enabled: false,
                    onDateTimeSelected: (v) {},
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => CustomTextField(
                      label: "Failure Reported by",
                      controller: TextEditingController(
                          text:
                          controller.selectedFailureReportedBy.value ??
                              ''),
                      enabled: false)),
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustDateTimePicker(
                    label: "Actual Failure Completed Date & Time",
                    hint: "Actual Failure Completed Date & Time",
                    selectedDateTime:
                    controller.selectedFailureCompletedDate.value,
                    enabled: false,
                    onDateTimeSelected: (v) {},
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => CustomTextField(
                      label: "Failure Category Type",
                      controller: TextEditingController(
                          text: controller
                              .selectedFailureCategoryType.value ??
                              ''),
                      enabled: false)),
                  const SizedBox(height: AppConstants.elementSpacing),
                ],
              ),
            )),
            CustSection(
              title: "Failure Rectification",
              child: CustomTextField(
                label: "Failure Rectification Details",
                controller: controller.failureRectificationDetailsController,
                maxLines: 4,
                enabled: false,
              ),
            ),
            CustSection(
              title: "Trip Information",
              isVisible: controller.isTripAffected.value,
              trailing: Obx(() => YesNoToggle(
                value: controller.isTripAffected.value,
                onChanged: (val) => controller.isTripAffected.value = val,
              )),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: "Trip Delay Upline (NOS)",
                          controller: controller.tripDelayUplineController,
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                        child: CustomTextField(
                          label: "Trip Cancel (NOS)",
                          controller: controller.trainCancelNosController,
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: "Trip Delay Downline (NOS)",
                          controller: controller.tripDelayDownlineController,
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                        child: CustomTextField(
                          label: "Trip Delay in Min.",
                          controller: controller.trainDelayMinController,
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: "Trip Withdrawal (NOS)",
                          controller: controller.trainWithdrawalNosController,
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                        child: CustomTextField(
                          label: "Train Replace (NOS)",
                          controller: controller.trainReplaceNosController,
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  if (controller.isPassengerDeboarding.value) ...[
                    const SizedBox(height: AppConstants.elementSpacing),
                    CustomTextField(
                      label: "Train Deboarded (NOS)",
                      controller: controller.trainDeboardedNosController,
                      enabled: false,
                    ),
                  ]
                ],
              ),
            ),
            CustSection(
              title: "Passenger Information",
              isVisible: controller.isPassengerDeboarding.value,
              trailing: Obx(() => YesNoToggle(
                value: controller.isPassengerDeboarding.value,
                onChanged: (val) =>
                controller.isPassengerDeboarding.value = val,
              )),
              child: Column(
                children: [
                  CustomTextField(
                    label: "Number Of Passenger Affected",
                    controller: controller.passengersAffectedCountController,
                    enabled: false,
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: "Trapped Duration",
                          controller: controller.trappedDurationController,
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                        child: CustomTextField(
                          label: "Rescued Duration",
                          controller: controller.rescuedDurationController,
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Obx(() {
              if (controller.beforeImagesList.isEmpty) {
                return const SizedBox.shrink();
              }
              return CustSection(
                title: "Uploaded Images",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustText.body("Before Images"),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.beforeImagesList
                          .map<Widget>(
                            (file) => _buildUploadedImagePreview(file['path']!),
                      )
                          .toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// JE edit form — Maintenance, Station, OCC, Depot (matches web "Change Notification JE").
  Widget _buildJointInspectionActionFields() {
    return CustSection(
      title: "Joint Inspection Details",
      child: Form(
        key: _jointInspectionOherDeptFormKey,
        child: Column(
          children: [
            const SizedBox(height: AppConstants.elementSpacing),
            CustomTextField(
              label: "Department",
              controller: controller.jiDepartmentDisplayController,
              enabled: false,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustomTextField(
              label: "Assign To",
              controller: controller.jiAssignToDisplayController,
              enabled: false,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: "Functional Location *",
              hint: "Select...",
              items: controller.functionalLocationList
                  .map((e) => e.label ?? '')
                  .toList(),
              selectedValue: controller.selectedJiFunctionalLocation.value,
              enabled: true,
              onChanged: controller.onJiFunctionalLocationChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please select Functional Location";
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: "Equipment Number",
              hint: "Select...",
              items:
              controller.equipmentList.map((e) => e.label ?? '').toList(),
              selectedValue: controller.selectedJiEquipmentNumber.value,
              enabled: true,
              onChanged: controller.onJiEquipmentChanged,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustomTextField(
              label: "Joint Inspection Remark",
              controller: controller.jiRemarkDisplayController,
              maxLines: 3,
              enabled: false,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustomTextField(
              label: "User's Remark * (Max length: 500)",
              controller: controller.jiUserRemarkController,
              maxLines: 3,
              enabled: true,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter User's Remark";
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
      String title, bool value, ValueChanged<bool> onChanged,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.labelSpacing),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.elementSpacing,
            vertical: AppConstants.labelSpacing),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textFieldFillColor),
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: CustText.body(title,
                    color: enabled ? AppColors.orangeColor : Colors.grey,
                    fontWeightName: FontWeight.w500)),
            YesNoToggle(value: value, onChanged: onChanged, enabled: enabled),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedImagePreview(String path) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          "${AppUrls.baseUrl.replaceAll('/api/', '/')}$path",
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildUploadButton(List<Map<String, dynamic>> targetList,
      {bool enabled = true}) {
    return CustOutlineButton(
      name: "Upload",
      size: 100,
      sHeight: 25,
      fontSize: AppConstants.buttonFontSize,
      borderColor: AppColors.orangeColor,
      textDarkPrimary: AppColors.orangeColor,
      onSelected: enabled
          ? (_) {
        _showUploadPopup(targetList);
      }
          : null,
    );
  }

  void _showUploadPopup(List<Map<String, dynamic>> targetList) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white1,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child:
                  const Icon(Icons.close, color: AppColors.black, size: 24),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _uploadPopupOption(
                    icon: TablerIcons.camera,
                    onTap: () async {
                      try {
                        Get.back();
                        final ImagePicker picker = ImagePicker();
                        final XFile? image =
                        await picker.pickImage(source: ImageSource.camera);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          final sizeInMb = bytes.length / (1024 * 1024);
                          targetList.add({
                            'name': image.name,
                            'size': '${sizeInMb.toStringAsFixed(1)} MB',
                            'path': image.path,
                          });
                        }
                      } catch (e) {
                        debugPrint("Error picking image: $e");
                        Get.snackbar("Error",
                            "Could not capture photo. Please check camera permissions.");
                      }
                    },
                  ),
                  const SizedBox(width: 30),
                  _uploadPopupOption(
                    icon: TablerIcons.paperclip,
                    onTap: () async {
                      try {
                        Get.back();
                        final FilePickerResult? result =
                        await FilePicker.platform.pickFiles();
                        if (result != null) {
                          for (var file in result.files) {
                            final sizeInMb = file.size / (1024 * 1024);
                            targetList.add({
                              'name': file.name,
                              'size': '${sizeInMb.toStringAsFixed(1)} MB',
                              'path': file.path,
                            });
                          }
                        }
                      } catch (e) {
                        debugPrint("Error picking file: $e");
                        Get.snackbar("Error", "Could not pick file.");
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustText.body(
                "Upload Files or Take Photos",
                size: 16,
                color: AppColors.textMutedLight,
                fontWeightName: FontWeight.w600,
              ),
              const SizedBox(height: AppConstants.labelSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadPopupOption(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.buttonOutlineColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(icon, color: AppColors.black, size: 25),
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(String name, String size,
      List<Map<String, dynamic>> targetList, Map<String, dynamic> file) {
    return GestureDetector(
      onTap: () => _showFilePreview(file),
      child: Container(
        width: (MediaQuery.of(context).size.width - 44) / 2,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(TablerIcons.photo,
                  color: AppColors.textMutedLight, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustText(
                      name: name,
                      size: 14,
                      color: AppColors.textDarkPrimary,
                      maxLines: 1),
                  CustText(
                      name: size, size: 12, color: AppColors.textDarkSecondary),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                targetList.remove(file);
              },
              child: const Icon(Icons.close,
                  size: 20, color: AppColors.textDarkSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilePreview(Map<String, dynamic> file) {
    final String path = file['path'] ?? '';
    final String name = file['name'] ?? 'File Preview';
    final bool isImage = name.toLowerCase().endsWith('.jpg') ||
        name.toLowerCase().endsWith('.jpeg') ||
        name.toLowerCase().endsWith('.png');

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white1,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: CustText(
                    name: name,
                    size: 16,
                    color: AppColors.black,
                    fontWeightName: FontWeight.bold),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.black),
                  onPressed: () => Get.back(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: isImage && path.isNotEmpty
                    ? Image.file(
                  File(path),
                  fit: BoxFit.contain,
                )
                    : Column(
                  children: [
                    const Icon(TablerIcons.file_description,
                        size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    CustText(
                        name: "Preview not available for this file type",
                        size: 14,
                        color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _submitJointInspectionForm() {
    if (_jointInspectionOherDeptFormKey.currentState?.validate() ?? false) {
      controller.submitJointInspection();
    } else {
      Get.snackbar(
        AppStrings.validationError,
        "Please fill all compulsory fields marked with *",
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _submitForm() {
    if (_validateSubmitForms()) {
      if (widget.isUpdate && widget.failureType == 'Station') {
        controller.updateStationFailureDetails(widget.failureNo ?? "0");
        return;
      }
      if (!controller.isStation && controller.isRcaRequired.value) {
        final hasExistingRca = controller.rcaDetailsList
            .any((rca) => (rca['isNew'] ?? true) == false);
        final hasNewRca = controller.rcaDetailsList
            .any((rca) => (rca['isNew'] ?? true) == true);

        if (!hasExistingRca && !hasNewRca) {
          Get.snackbar(
            AppStrings.validationError,
            "At least one RCA detail is required.",
            backgroundColor: AppColors.red.withValues(alpha: 0.9),
            colorText: AppColors.white1,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }
      controller.submitFailure(isCreate: widget.failureNo == null);
    } else {
      debugPrint("this error");
      Get.snackbar(
        AppStrings.validationError,
        "Please fill all compulsory fields marked with *",
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildRcaDetailCard(Map<String, dynamic> item, int index) {
    final List<Map<String, dynamic>> rootCauses = item['rootCauses'] ?? [];
    final List<Map<String, dynamic>> actionTakens = item['actionTakens'] ?? [];

    return Obx(() {
      final bool isExpanded = controller.isExpandedRca[index] ?? false;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
              color: AppColors.textFieldFillColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustText.detailLabel(item.containsKey('subsystem')
                            ? "Subsystem"
                            : "Object Part"),
                        const SizedBox(height: AppConstants.labelSpacing),
                        CustText.detailValue(
                            item['subsystem'] ?? item['objectPart'] ?? "N/A"),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (!_isJointInspectionFlow && !controller.isFormDisabled)
                        IconButton(
                          icon: const Icon(TablerIcons.trash,
                              color: Colors.grey, size: 24),
                          onPressed: () => controller.removeRcaDetail(item),
                        ),
                      IconButton(
                        icon: Icon(
                            isExpanded
                                ? TablerIcons.chevron_up
                                : TablerIcons.chevron_down,
                            color: AppColors.orangeColor),
                        onPressed: () => controller.toggleRcaExpansion(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustText.detailLabel("Failure Category"),
                    const SizedBox(height: AppConstants.labelSpacing),
                    CustText.detailValue(item['failureCategory']),
                    const SizedBox(height: 16),
                    if (rootCauses.isNotEmpty || actionTakens.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            TabBar(
                              labelColor: AppColors.orangeColor,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: AppColors.orangeColor,
                              indicatorSize: TabBarIndicatorSize.tab,
                              onTap: (index) {
                                // Optional: handle tab switch if needed
                              },
                              tabs: const [
                                Tab(text: "Root Cause"),
                                Tab(text: "Action Taken"),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Builder(
                              builder: (context) {
                                final tabController =
                                DefaultTabController.of(context);
                                return AnimatedBuilder(
                                  animation: tabController,
                                  builder: (context, _) {
                                    final bool isRootCauseTab =
                                        tabController.index == 0;
                                    final currentList = isRootCauseTab
                                        ? rootCauses
                                        : actionTakens;

                                    return Column(
                                      children: currentList
                                          .asMap()
                                          .entries
                                          .map((entry) => isRootCauseTab
                                          ? _buildRcaSubItem(
                                        cause: entry.value['cause'],
                                        rootCause:
                                        entry.value['rootCause'],
                                        causeText: entry
                                            .value['causeText'] ??
                                            '',
                                        imagePath:
                                        entry.value['imagePath'],
                                        onDelete: () => controller
                                            .removeRootCauseFromRca(
                                            index, entry.key),
                                        isActionItem: false,
                                      )
                                          : _buildRcaSubItem(
                                        cause: null,
                                        rootCause: entry
                                            .value['actionTaken'],
                                        causeText: entry.value[
                                        'actionTakenText'] ??
                                            '',
                                        imagePath:
                                        entry.value['imagePath'],
                                        onDelete: () => controller
                                            .removeActionTakenFromRca(
                                            index, entry.key),
                                        isActionItem: true,
                                      ))
                                          .toList(),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (!_isJointInspectionFlow)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CustButton(
                  name: "Add RCA",
                  size: 100,
                  fontSize: AppConstants.buttonFontSize,
                  onSelected: (_) async {
                    final failureCategoryId =
                        item['FailureCategoryId']?.toString() ?? "0";
                    await controller.fetchRootCauseAndAction(
                        failureCategoryId, "0");
                    _showAddRcaPopup(index);
                  },
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildRcaSubItem({
    String? cause,
    String? rootCause,
    required String causeText,
    String? imagePath,
    required VoidCallback onDelete,
    bool isActionItem = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isActionItem) ...[
                  // Action item display
                  if (rootCause != null && rootCause.isNotEmpty) ...[
                    CustText.detailLabel("Action"),
                    const SizedBox(height: AppConstants.labelSpacing),
                    CustText.detailValue(rootCause),
                    const SizedBox(height: AppConstants.elementSpacing),
                  ],
                  CustText.detailLabel("Action Text"),
                  const SizedBox(height: AppConstants.labelSpacing),
                  CustText.detailValue(causeText),
                ] else ...[
                  // Root cause item display
                  if (cause != null && cause.isNotEmpty) ...[
                    CustText.detailLabel("Cause"),
                    const SizedBox(height: AppConstants.labelSpacing),
                    CustText.detailValue(cause),
                    const SizedBox(height: AppConstants.elementSpacing),
                  ],
                  if (rootCause != null && rootCause.isNotEmpty) ...[
                    CustText.detailLabel("Root Cause"),
                    const SizedBox(height: AppConstants.labelSpacing),
                    CustText.detailValue(rootCause),
                    const SizedBox(height: AppConstants.elementSpacing),
                  ],
                  CustText.detailLabel("Cause Text"),
                  const SizedBox(height: AppConstants.labelSpacing),
                  CustText.detailValue(causeText),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              if (!_isJointInspectionFlow)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(TablerIcons.trash,
                      color: AppColors.red, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddRcaPopup(int index) {
    // Clear popup state and reset root cause list
    controller.clearPopupState();

    Get.dialog(
      DefaultTabController(
        length: 2,
        child: Dialog(
          backgroundColor: AppColors.white1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius)),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.iconColor,
                          size: AppConstants.iconSize,
                        ),
                        onPressed: () {
                          controller.clearPopupState();
                          Get.back();
                        },
                      ),
                    ],
                  ),
                ),
                TabBar(
                  labelColor: AppColors.orangeColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.orangeColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    _buildTabWithBadge(
                        "Root Cause", controller.tempPopupRootCauses),
                    _buildTabWithBadge(
                        "Action", controller.tempPopupActionTakens),
                  ],
                ),
                Flexible(
                  child: TabBarView(
                    children: [
                      _buildRootCausePopupTab(
                        index: index,
                        formKey: _rcaRootCausePopupFormKey,
                        onAddClick: () {
                          controller.addToTempRootCauses();
                        },
                        onSave: () {
                          controller.savePopupDataToRca(index);
                          Get.back();
                        },
                      ),
                      _buildActionPopupTab(
                        index: index,
                        formKey: _rcaActionPopupFormKey,
                        onAddClick: () {
                          controller.addToTempActionTakens();
                        },
                        onSave: () {
                          controller.savePopupDataToRca(index);
                          Get.back();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabWithBadge(String title, RxList list) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // const SizedBox(width: AppConstants.labelSpacing),
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.grey.shade300, width: 1),
          //     borderRadius: BorderRadius.circular(20),
          //   ),
          //   child: CustText.body(
          //     list.length.toString(),
          //     size: 10,
          //     color: const Color(0xFF8E99B2),
          //     fontWeightName: FontWeight.w600,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildRootCausePopupTab({
    required int index,
    required GlobalKey<FormState> formKey,
    required VoidCallback onAddClick,
    required VoidCallback onSave,
  }) {
    final createController = Get.find<CreateFailureController>();
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => CustDropdown(
                    label: "Cause *",
                    hint: "Select Cause",
                    items: createController.causeList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue:
                    createController.selectedPopupCause.value,
                    onChanged: (v) {
                      createController.selectedPopupCause.value = v;
                      // Filter root causes based on selected cause
                      createController.filterPopupRootCauses(v);
                    },
                  )),
                  const SizedBox(height: 16),
                  Obx(() => CustDropdown(
                    label: "Root Cause *",
                    hint: "Select Root Cause",
                    items: createController.popupRootCauseList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue:
                    createController.selectedPopupRootCause.value,
                    onChanged: (v) {
                      createController.selectedPopupRootCause.value = v;
                    },
                  )),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: "Cause Text *",
                    controller: createController.popupCauseTextController,
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Wrap(
                    spacing: 8,
                    children: createController.popupRootCauseFiles
                        .map((file) => Chip(
                      label: Text(file['name'],
                          style: const TextStyle(fontSize: 10)),
                      onDeleted: () => createController
                          .popupRootCauseFiles
                          .remove(file),
                    ))
                        .toList(),
                  )),
                  const SizedBox(height: 12),
                  CustButton(
                      name: "Add",
                      size: 100,
                      fontSize: AppConstants.buttonFontSize,
                      sHeight: 40,
                      onSelected: (_) => onAddClick()),
                  const SizedBox(height: 24),
                  Obx(() => Column(
                    children: createController.tempPopupRootCauses
                        .asMap()
                        .entries
                        .map((entry) => _buildRcaSubItem(
                      cause: entry.value['cause'],
                      rootCause: entry.value['rootCause'],
                      causeText: entry.value['causeText'] ?? '',
                      imagePath: entry.value['imagePath'],
                      onDelete: () => createController
                          .tempPopupRootCauses
                          .removeAt(entry.key),
                      isActionItem: false,
                    ))
                        .toList(),
                  )),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustButton(
            name: "Save",
            size: double.infinity,
            fontSize: AppConstants.buttonFontSize,
            onSelected: (_) => onSave(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionPopupTab({
    required int index,
    required GlobalKey<FormState> formKey,
    required VoidCallback onAddClick,
    required VoidCallback onSave,
  }) {
    final createController = Get.find<CreateFailureController>();
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => CustDropdown(
                    label: "Action *",
                    hint: "Select Action",
                    items: createController.actionTakenList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue:
                    createController.selectedPopupAction.value,
                    onChanged: (v) {
                      createController.selectedPopupAction.value = v;
                    },
                  )),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: "Action Text *",
                    controller: createController.popupActionTextController,
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Wrap(
                    spacing: 8,
                    children: createController.popupActionTakenFiles
                        .map((file) => Chip(
                      label: Text(file['name'],
                          style: const TextStyle(fontSize: 10)),
                      onDeleted: () => createController
                          .popupActionTakenFiles
                          .remove(file),
                    ))
                        .toList(),
                  )),
                  const SizedBox(height: 12),
                  CustButton(
                      name: "Add",
                      size: 100,
                      fontSize: AppConstants.buttonFontSize,
                      sHeight: 40,
                      onSelected: (_) => onAddClick()),
                  const SizedBox(height: 24),
                  Obx(() => Column(
                    children: createController.tempPopupActionTakens
                        .asMap()
                        .entries
                        .map((entry) => _buildRcaSubItem(
                      cause: null,
                      rootCause: entry.value['actionTaken'],
                      causeText:
                      entry.value['actionTakenText'] ?? '',
                      imagePath: entry.value['imagePath'],
                      onDelete: () => createController
                          .tempPopupActionTakens
                          .removeAt(entry.key),
                      isActionItem: true,
                    ))
                        .toList(),
                  )),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustButton(
            name: "Save",
            size: double.infinity,
            fontSize: AppConstants.buttonFontSize,
            onSelected: (_) => onSave(),
          ),
        ),
      ],
    );
  }

  Widget _buildSparePartReplaceSection({bool enabled = true}) {
    return Obx(() {
      if (controller.selectedMaterialType.value != "Hardware" ||
          !controller.isSparePartReplaced.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustDropdown(
              label: "Failure Type",
              hint: "Select...",
              items: controller.materialTypeList,
              selectedValue: controller.selectedMaterialType.value,
              enabled: enabled,
              onChanged: (v) => controller.selectedMaterialType.value = v!,
            ),
            if ((controller.selectedMaterialType.value ?? '').toLowerCase() ==
                "other") ...[
              const SizedBox(height: AppConstants.elementSpacing),
              CustomTextField(
                  label: "Other",
                  controller: controller.failureTypeController,
                  enabled: enabled),
            ],
            if (controller.selectedMaterialType.value == "Hardware") ...[
              const SizedBox(height: AppConstants.elementSpacing),
              _buildToggleItem(
                  "Spare Part Replace",
                  controller.isSparePartReplaced.value,
                      (val) => controller.isSparePartReplaced.value = val,
                  enabled: enabled),
            ],
            if (controller.selectedMaterialType.value == "Hardware") ...[
              const SizedBox(height: AppConstants.elementSpacing),
              _buildMaterialDismantleSection(enabled: controller.isJE),
            ],
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppConstants.elementSpacing),
          Form(
            key: _sparePartFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustDropdown(
                  label: "Material Code & Description *",
                  hint: "Select...",
                  items: controller.materialMasterList
                      .map((e) => e.label ?? '')
                      .toList(),
                  selectedValue: controller.selectedMaterialCode.value,
                  enabled: enabled && !controller.isFormDisabled,
                  validator: (v) => FormValidators.requiredDropdown(
                    controller.selectedMaterialCode.value,
                    'Material Code & Description',
                  ),
                  onChanged: (v) {
                    if (controller.isFormDisabled) return;
                    controller.selectedMaterialCode.value = v;
                    controller.uomController.text = "NO";
                    // Unfocus all used qty fields
                    for (final focusNode
                    in controller.usedQtyFocusNodes.values) {
                      focusNode.unfocus();
                    }
                  },
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustomTextField(
                    label: "Unit of Measurement",
                    controller: controller.uomController,
                    enabled: false),
                const SizedBox(height: AppConstants.elementSpacing),
                CustDropdown(
                  label: "Store Location *",
                  hint: "Select...",
                  items: controller.storageLocationList
                      .map((e) => e.label ?? '')
                      .toList(),
                  selectedValue: controller.selectedStoreLocation.value,
                  enabled: enabled && !controller.isFormDisabled,
                  validator: (v) => FormValidators.requiredDropdown(
                    controller.selectedStoreLocation.value,
                    'Store Location',
                  ),
                  onChanged: (v) {
                    if (controller.isFormDisabled) return;
                    controller.selectedStoreLocation.value = v;
                    controller.balanceQtyController.text = "0.00";
                    controller.requiredQtyFocusNode.unfocus();
                    // Unfocus all used qty fields
                    for (final focusNode
                    in controller.usedQtyFocusNodes.values) {
                      focusNode.unfocus();
                    }
                  },
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                Row(
                  children: [
                    Expanded(
                        child: CustomTextField(
                            label: "Balance Quantity",
                            controller: controller.balanceQtyController,
                            enabled: false)),
                    const SizedBox(width: AppConstants.elementSpacing),
                    Expanded(
                        child: CustomTextField(
                          label: "Required Quantity *",
                          controller: controller.requiredQtyController,
                          focusNode: controller.requiredQtyFocusNode,
                          hintText: "Enter Required Quantity",
                          enabled: enabled && !controller.isFormDisabled,
                          keyboardType: TextInputType.number,
                          autofocus: false,
                          validator: (val) =>
                              FormValidators.requiredText(val, 'Required Quantity'),
                        )),
                  ],
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustButton(
                  name: controller.editingReplacedMaterialIndex.value >= 0
                      ? "Update Material"
                      : "Add Material",
                  size: 150,
                  fontSize: AppConstants.buttonFontSize,
                  onSelected: enabled && !controller.isFormDisabled
                      ? (_) {
                    if (_validateForm(_sparePartFormKey)) {
                      controller.addReplacedMaterial();
                    }
                  }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          if (controller.replacedMaterialsList.isNotEmpty)
            _buildReplacedMaterialTable(enabled: enabled),
        ],
      );
    });
  }

  Widget _buildReplacedMaterialTable({bool enabled = true}) {
    return Obx(() => Column(
      children:
      controller.replacedMaterialsList.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isExpanded = controller.isExpandedReplaced[index] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.white1,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(
                color: AppColors.textFieldFillColor.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustText.detailLabel("Material Description"),
                          const SizedBox(height: AppConstants.labelSpacing),
                          CustText.detailValue(item['materialCode'] ?? ""),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (enabled && !controller.isFormDisabled) ...[
                          IconButton(
                            icon: const Icon(TablerIcons.pencil,
                                color: AppColors.orangeColor, size: 20),
                            onPressed: () =>
                                controller.editReplacedMaterial(index),
                            padding: const EdgeInsets.only(right: 12),
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(TablerIcons.trash,
                                color: Colors.grey, size: 20),
                            onPressed: () =>
                                controller.removeReplacedMaterial(index),
                            padding: const EdgeInsets.only(right: 12),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                        IconButton(
                          icon: Icon(
                              isExpanded
                                  ? TablerIcons.chevron_up
                                  : TablerIcons.chevron_down,
                              color: AppColors.orangeColor,
                              size: 20),
                          onPressed: () =>
                              controller.toggleReplacedExpansion(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _reqQtyFormKeys.putIfAbsent(
                      index, () => GlobalKey<FormState>()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final ctrl = controller.usedQtyControllers
                              .putIfAbsent(
                              index, () => TextEditingController());
                          final focusNode = controller.usedQtyFocusNodes
                              .putIfAbsent(index, () => FocusNode());
                          // Sync controller text with data
                          if (ctrl.text !=
                              (item['usedQty']?.toString() ?? '')) {
                            ctrl.text = item['usedQty']?.toString() ?? '';
                          }
                          return CustomTextField(
                            key: ValueKey('used_qty_$index'),
                            label: "Used Qty",
                            controller: ctrl,
                            focusNode: focusNode,
                            enabled: enabled,
                            hintText: "Enter Used Quantity",
                            keyboardType: TextInputType.number,
                            autofocus: false,
                            onChanged: (val) {
                              final usedQty = int.tryParse(val) ?? 0;
                              final requiredQty = int.tryParse(
                                  item['requiredQty']?.toString() ??
                                      "0") ??
                                  0;

                              if (usedQty > requiredQty) {
                                // Clear the invalid value
                                controller.replacedMaterialsList[index]
                                ['usedQty'] = "";
                                ctrl.clear();
                                // Show snackbar
                                Get.snackbar(
                                  'Invalid Quantity',
                                  'Used Quantity cannot be greater than Required Quantity.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.darkRed,
                                  colorText: AppColors.white1,
                                  duration: const Duration(seconds: 3),
                                );
                                return;
                              }
                              controller.replacedMaterialsList[index]
                              ['usedQty'] = val;
                            },
                            validator: (val) =>
                                FormValidators.requiredText(val, 'Used Quantity'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = (constraints.maxWidth - 10) / 2;
                      Widget buildCol(String label, String value) {
                        return SizedBox(
                          width: width,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustText.detailLabel(label),
                              const SizedBox(height: 2),
                              CustText.detailValue(value),
                            ],
                          ),
                        );
                      }

                      return Wrap(
                        runSpacing: 10,
                        spacing: 10,
                        children: [
                          buildCol(
                              "Unit of Measurement", item['uom'] ?? ""),
                          buildCol("Storage Location",
                              item['storeLocation'] ?? ""),
                          buildCol("Balance Qty",
                              item['balanceQty']?.toString() ?? ""),
                          buildCol("Required Qty",
                              item['requiredQty']?.toString() ?? ""),
                          buildCol("Issued Qty",
                              item['issuedQty']?.toString() ?? "0"),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    ));
  }

  Widget _buildMaterialDismantleSection({bool enabled = true}) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.isMaterialDismantle.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          Form(
            key: _dismantleFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (context) {
                  final sparePartItems = controller.replacedMaterialsList
                      .map((e) => e['materialCode'] as String? ?? '')
                      .where((e) => e.isNotEmpty)
                      .toList();
                  return CustDropdown(
                    label: "Material Code & Description *",
                    hint: "Select...",
                    items: sparePartItems,
                    selectedValue:
                    controller.selectedDismantleMaterialCode.value,
                    enabled: enabled &&
                        !controller.isFormDisabled &&
                        sparePartItems.isNotEmpty,
                    validator: (v) => FormValidators.requiredDropdown(
                      controller.selectedDismantleMaterialCode.value,
                      'Material Code & Description',
                    ),
                    onChanged: (v) {
                      if (controller.isFormDisabled) return;
                      controller.selectedDismantleMaterialCode.value = v;
                    },
                  );
                }),
                const SizedBox(height: AppConstants.elementSpacing),
                CustomTextField(
                  label: "Old Serial Number *",
                  controller: controller.oldSerialNumberController,
                  hintText: "Enter Old Series Number",
                  enabled: enabled && !controller.isFormDisabled,
                  validator: (val) =>
                      FormValidators.requiredText(val, 'Old Serial Number'),
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustDateTimePicker(
                  label: "Old Serial No Dismantle Date *",
                  hint: "DD/MM/YYYY hh:mm",
                  selectedDateTime: controller.oldSerialDismantleDate.value,
                  enabled: enabled && !controller.isFormDisabled,
                  lastDate: DateTime.now(),
                  validator: (val) =>
                  controller.oldSerialDismantleDate.value == null
                      ? 'Old Serial No Dismantle Date is required'
                      : null,
                  onDateTimeSelected: (dt) {
                    if (controller.isFormDisabled) return;
                    controller.oldSerialDismantleDate.value = dt;
                  },
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustomTextField(
                  label: "New Serial Number *",
                  controller: controller.newSerialNumberController,
                  hintText: "Enter New Series Number",
                  enabled: enabled && !controller.isFormDisabled,
                  validator: (val) =>
                      FormValidators.requiredText(val, 'New Serial Number'),
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustDateTimePicker(
                  label: "New Serial No Installation Date *",
                  hint: "DD/MM/YYYY hh:mm",
                  selectedDateTime:
                  controller.newSerialInstallationDate.value,
                  enabled: enabled && !controller.isFormDisabled,
                  lastDate: DateTime.now(),
                  validator: (val) =>
                  controller.newSerialInstallationDate.value == null
                      ? 'New Serial No Installation Date is required'
                      : null,
                  onDateTimeSelected: (dt) {
                    if (controller.isFormDisabled) return;
                    controller.newSerialInstallationDate.value = dt;
                  },
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustButton(
                  name: controller.editingDismantleMaterialIndex.value >= 0
                      ? "Update"
                      : "Add",
                  size: 100,
                  fontSize: AppConstants.buttonFontSize,
                  onSelected: enabled && !controller.isFormDisabled
                      ? (_) {
                    if (_validateForm(_dismantleFormKey)) {
                      controller.addDismantleMaterial();
                    }
                  }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          if (controller.dismantleMaterialsList.isNotEmpty)
            _buildDismantleMaterialTable(enabled: enabled),
        ],
      ],
    ));
  }

  Widget _buildDismantleMaterialTable({bool enabled = true}) {
    return Obx(() => Column(
      children:
      controller.dismantleMaterialsList.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isExpanded = controller.isExpandedDismantle[index] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.white1,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(
                color: AppColors.textFieldFillColor.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustText.detailLabel("Material Description"),
                          const SizedBox(height: AppConstants.labelSpacing),
                          CustText.detailValue(item['materialCode'] ?? ""),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (enabled && !controller.isFormDisabled) ...[
                          IconButton(
                            icon: const Icon(TablerIcons.pencil,
                                color: AppColors.orangeColor, size: 20),
                            onPressed: () =>
                                controller.editDismantleMaterial(index),
                            padding: const EdgeInsets.only(right: 12),
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(TablerIcons.trash,
                                color: Colors.grey, size: 20),
                            onPressed: () =>
                                controller.removeDismantleMaterial(index),
                            padding: const EdgeInsets.only(right: 12),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                        IconButton(
                          icon: Icon(
                              isExpanded
                                  ? TablerIcons.chevron_up
                                  : TablerIcons.chevron_down,
                              color: AppColors.orangeColor,
                              size: 20),
                          onPressed: () =>
                              controller.toggleDismantleExpansion(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = (constraints.maxWidth - 10) / 2;
                      Widget buildCol(String label, String value) {
                        return SizedBox(
                          width: width,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustText.detailLabel(label),
                              const SizedBox(height: 2),
                              CustText.detailValue(value),
                            ],
                          ),
                        );
                      }

                      return Wrap(
                        runSpacing: 10,
                        spacing: 10,
                        children: [
                          buildCol("Old Serial Number",
                              item['oldSerialNumber'] ?? ""),
                          buildCol("Dismantle Date",
                              _formatDate(item['oldSerialDismantleDate'])),
                          buildCol("New Serial Number",
                              item['newSerialNumber'] ?? ""),
                          buildCol(
                              "Installation Date",
                              _formatDate(
                                  item['newSerialInstallationDate'])),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    ));
  }

  Widget _buildJointInspectionSection({bool enabled = true}) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.isJointInspection.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          Form(
            key: _jointInspectionFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: CustDropdown(
                          label: "Department *",
                          hint: "Select...",
                          items: controller.jointInspectionDepartments
                              .map((e) => e.label ?? '')
                              .toList(),
                          selectedValue: controller.selectedJointDept.value,
                          enabled: enabled,
                          validator: (v) => FormValidators.requiredDropdown(
                            controller.selectedJointDept.value,
                            'Department',
                          ),
                          onChanged: (v) {
                            controller.selectedJointDept.value = v;
                            controller.selectedJointAssignTo.value = null;
                            controller.jointUserList.clear();
                            if (v != null) {
                              final dept = controller.jointInspectionDepartments
                                  .firstWhere(
                                    (e) => e.label == v,
                                orElse: () => LabelValue(value: "0"),
                              );
                              if (dept.value != "0" && dept.value != null) {
                                controller
                                    .fetchJointInspectionUsers(dept.value!);
                              }
                            }
                          },
                        )),
                    const SizedBox(width: AppConstants.elementSpacing),
                    Expanded(
                        child: Obx(() => CustDropdown(
                          label: "Assign To *",
                          hint: controller.isJointUserLoading.value
                              ? "Loading..."
                              : "Select...",
                          items: controller.jointUserList
                              .map((e) => e.label ?? '')
                              .toList(),
                          selectedValue:
                          controller.selectedJointAssignTo.value,
                          enabled: enabled &&
                              !controller.isJointUserLoading.value,
                          validator: (v) => FormValidators.requiredDropdown(
                            controller.selectedJointAssignTo.value,
                            'Assign To',
                          ),
                          onChanged: (v) => controller
                              .selectedJointAssignTo.value = v,
                        ))),
                  ],
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustomTextField(
                  label: "Joint Inspection Remark *",
                  controller: controller.jointInspectionRemarkController,
                  maxLines: 3,
                  enabled: enabled,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Joint Inspection Remark is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                CustButton(
                  name: controller.editingJointInspectionIndex.value >= 0
                      ? "Update"
                      : "Add",
                  size: 100,
                  fontSize: AppConstants.buttonFontSize,
                  onSelected: enabled
                      ? (_) async {
                    if (!_validateForm(_jointInspectionFormKey)) {
                      return;
                    }
                    if (controller
                        .editingJointInspectionIndex.value >=
                        0) {
                      await controller.updateJointInspectionHistory();
                    } else {
                      await controller.addJointInspectionHistory();
                    }
                    _jointInspectionFormKey.currentState?.reset();
                    controller.jointInspectionRemarkController
                        .clear();
                  }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          if (controller.jointInspectionHistoryList.isNotEmpty)
            _buildJointInspectionTable(enabled: enabled),
        ],
      ],
    ));
  }

  Widget _buildJointInspectionTable({bool enabled = true}) {
    return Column(
      children:
      controller.jointInspectionHistoryList.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return CustDataCard(
          items: [
            DataCardItem(label: 'Department', value: item.deptName ?? ""),
            DataCardItem(label: 'Assigned To', value: item.assignedUserName),
            DataCardItem(
                label: 'Assigned Date/Time',
                value: item.assignedDateTime,
                isFullWidth: true),
            DataCardItem(
                label: 'Remark', value: item.remark ?? "", isFullWidth: true),
            DataCardItem(
                label: 'User Remark',
                value: (item.userRemark != null && item.userRemark!.isNotEmpty)
                    ? item.userRemark!
                    : "N/A",
                isFullWidth: true),
            DataCardItem(
                label: 'Status',
                value: item.statusName ?? "",
                isFullWidth: true),
          ],
          onEdit: enabled ? () => controller.editJointInspection(index) : null,
          onDelete: enabled
              ? () => controller.removeJointInspectionHistory(index)
              : null,
        );
      }).toList(),
    );
  }
}

/// Kept for existing call sites (home_screen.dart, failure_list_screen.dart)
/// that reference `CreateMaintenanceForm` directly as a `const` widget.
/// Maintenance failures go through this same [CreateFailureScreen]
/// (`failureType` already defaults to `"Maintenance"`), so this is just a
/// forwarding alias rather than a separate screen/file to keep in sync.
class CreateMaintenanceForm extends StatelessWidget {
  const CreateMaintenanceForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreateFailureScreen();
  }
}