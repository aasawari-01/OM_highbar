import 'dart:io';
import 'package:om_mobile/utils/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const CreateFailureScreen({
    super.key,
    this.failureType = "Maintenance",
    this.failureNo,
    this.notificationCode,
    this.isUpdate = false,
    this.isFromJointInspection = false,
    this.failureItem,
  });

  @override
  State<CreateFailureScreen> createState() => _CreateFailureScreenState();
}

class _CreateFailureScreenState extends State<CreateFailureScreen>
    with SingleTickerProviderStateMixin {
  late final CreateFailureController controller;
  final session = Get.find<SessionController>();
  final _formKey = GlobalKey<FormState>();
  final _formBottomKey = GlobalKey<FormState>();

  final _stationFormKey = GlobalKey<FormState>();
  final _occFormKey = GlobalKey<FormState>();
  final _depotFormKey = GlobalKey<FormState>();
  final _rcaFormKey = GlobalKey<FormState>();

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

  String? _requiredDropdown(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty || value == "Select") {
      return "$fieldName is required";
    }
    return null;
  }

  String? _requiredText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    return null;
  }

  bool _validateSubmitForms() {
    if (_isOccCreate) {
      return _validateForm(_occFormKey);
    }
    if (_isDepotCreate) {
      return _validateForm(_depotFormKey);
    }
    if (_isStationCreate || _isStationUpdate) {
      debugPrint("step1");
      return _validateForm(_stationFormKey);
    }

    if (controller.replacedMaterialsList.isNotEmpty) {
      debugPrint("step2");
      return _validateForm(_formKey) &&
          _reqQtyFormKeys.values.every((key) => _validateForm(key));
    }
    debugPrint("step3");
    return _validateForm(_formKey);
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

    if (_isDepotView) {
      // DCC opening a depot failure from the list: read-only detail.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadDepotFailureDetails(widget.failureNo!);
      });
    } else if (_isOccUpdate) {
      // FMC user opening an OCC failure that was assigned to them.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadOccFailureForUpdate(widget.failureNo!);
      });
    } else if (widget.failureNo != null) {
      if (widget.isFromJointInspection) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.loadJointInspectionDetails(widget.failureNo!);
        });
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
      } else if (controller.isSectionIncharge &&
          widget.failureType != 'Station') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.loadMaintenanceFailureDetails(
            widget.failureNo!,
            item: widget.failureItem,
            code: widget.notificationCode,
          );
        });
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
          appSnackbar(
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
    } else if (widget.failureType == "Maintenance" && widget.failureNo == null && controller.isSectionIncharge) {
      // Section Incharge creating a new maintenance failure
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadSectionInchargeDropdowns();
      });
    } else if (_isOccCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.isOccController) {
          appSnackbar(
            "Access Denied",
            "Only Chief Controller can create OCC failure.",
            backgroundColor: AppColors.red.withValues(alpha: 0.9),
            colorText: AppColors.white1,
            snackPosition: SnackPosition.BOTTOM,
          );
          if (mounted) Navigator.pop(context);
          return;
        }
        controller.loadOccCreateDropdowns();
      });
    } else if (_isDepotCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.isDcc) {
          appSnackbar(
            "Access Denied",
            "Only DCC can create depot failure.",
            backgroundColor: AppColors.red.withValues(alpha: 0.9),
            colorText: AppColors.white1,
            snackPosition: SnackPosition.BOTTOM,
          );
          if (mounted) Navigator.pop(context);
          return;
        }
        // Same local master data as Station (priority, department, location…).
        controller.loadStationCreateDropdowns();
      });
    }
  }

  /// New depot failure (DCC). Existing depot failures keep the old flow.
  bool get _isDepotCreate =>
      widget.failureType == 'Depot' && widget.failureNo == null;

  /// DCC opening an existing depot failure (read-only detail).
  bool get _isDepotView =>
      widget.failureType == 'Depot' &&
          widget.failureNo != null &&
          !widget.isFromJointInspection &&
          controller.isDcc;

  bool get _isStationCreate =>
      widget.failureType == 'Station' &&
          widget.failureNo == null;

  /// New OCC failure (OCC Controller). Existing OCC failures still open in the
  /// JE change-notification form.
  bool get _isOccCreate =>
      widget.failureType == 'OCC' && widget.failureNo == null;

  /// FMC user, or OCC role, updating an existing OCC failure (web "Update
  /// OCC Failure" / "Update Failure").
  bool get _isOccUpdate =>
      widget.failureType == 'OCC' &&
          widget.failureNo != null &&
          !widget.isFromJointInspection &&
          (controller.isFmcUser || controller.isOccRoleUser);

  bool get _isStationUpdate =>
      widget.failureType == 'Station' &&
          widget.failureNo != null &&
          !controller.isJE;

  bool get _isStationControllerView =>
      widget.failureType == 'Station' &&
          widget.failureNo != null &&
          controller.isStationController &&
          !widget.isUpdate;

// ---------------------------------------------------------
// Maintenance modes
// ---------------------------------------------------------

  bool get _isMaintenance =>
      widget.failureType.toLowerCase() == 'maintenance';

  /// Existing Maintenance failure opened from the failure list.
  /// There is NO separate View/Edit mode in the web flow.
  /// Field editability is controlled by the failure status.
  bool get _isExistingMaintenance =>
      _isMaintenance && widget.failureNo != null;

  int get _maintenanceStatusId => controller.maintenanceStatusId.value;

  /// Web rule: Priority is editable only when statusId == 1.
  bool get _maintenancePriorityEditable =>
      !_isExistingMaintenance || _maintenanceStatusId == 1;

  /// Web rule: most master fields are editable when statusId is 1 or 202.
  bool get _maintenanceOpenOr202Editable =>
      !_isExistingMaintenance ||
          _maintenanceStatusId == 1 ||
          _maintenanceStatusId == 202;

  /// Web rule: Service Affected + its dependent values are editable only
  /// when statusId == 1 (isHideStationRequest is true in the normal flow).
  bool get _maintenanceServiceEditable =>
      !_isExistingMaintenance || _maintenanceStatusId == 1;

// ---------------------------------------------------------
// JE Change Notification
// ---------------------------------------------------------

  bool get _isJointInspectionFlow =>
      widget.isFromJointInspection ||
          controller.isFromJointInspection.value;

  // Section Incharge (Maintenance view/edit) sees RCA data read-only
  bool get _isRcaReadOnly =>
      _isJointInspectionFlow ||
          (controller.isSectionIncharge && _isMaintenance);


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

  /// App bar title: "Create ..." when the user is creating, "Edit ..." when
  /// they can change the failure, "View ... Details" when everything is
  /// read-only for them. Same rule for every failure type and role.
  String get _screenTitle {
    // Keeps the surrounding Obx subscribed (it throws if nothing observable
    // is read) and refreshes the title once the details have loaded.
    controller.isLoading.value;

    final type = widget.failureType;
    final create = 'Create $type Failure';
    final edit = 'Edit $type Failure';
    final view = 'View $type Failure Details';

    // Joint inspection: the user fills in their inspection remark.
    if (_isJointInspectionFlow) return 'Edit Joint Inspection';

    // Depot (DCC)
    if (_isDepotCreate) return create;
    if (_isDepotView) return view;

    // OCC
    if (_isOccCreate) return create;
    if (_isOccUpdate) {
      final closed = (controller.mainStatusName.value ?? '')
          .toLowerCase()
          .contains('close');
      final readOnly = controller.occDelegateReadOnly ||
          controller.occRoleViewOnly ||
          (controller.isOccRoleUser && closed);
      return readOnly ? view : edit;
    }

    // Station
    if (_isStationCreate) return create;
    if (_isStationControllerView) return view;
    if (_isStationUpdate) return edit;

    // Maintenance as Section Incharge: new, or existing (editable by status)
    if (controller.isSectionIncharge && _isMaintenance) {
      if (widget.failureNo == null) return create;
      return _maintenanceOpenOr202Editable ? edit : view;
    }

    // Anyone else opening an existing failure (e.g. JE change notification)
    if (widget.failureNo != null) {
      return controller.isFormDisabled ? view : edit;
    }
    return create;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      // The title depends on details that load after the screen opens, so the
      // app bar rebuilds on its own (CustomAppBar has a fixed height).
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() => CustomAppBar(
        title: _screenTitle,
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
      )),
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
    if (_isDepotView) {
      return _buildDepotView(context);
    }
    if (_isOccUpdate) {
      // Once FMC / TPC / CSS / RSC assign the failure to a department it is
      // no longer theirs to edit: show the read-only view.
      return controller.occDelegateReadOnly
          ? _buildOccAssignedView(context)
          : _buildOccUpdateForm(context);
    }
    if (_isOccCreate) {
      return _buildOccCreateForm(context);
    }
    if (_isDepotCreate) {
      return _buildDepotCreateForm(context);
    }
    if (_isStationCreate ||
        (widget.isUpdate && widget.failureType == 'Station')) {
      return _buildStationCreateForm(context);
    }
    if (_isStationControllerView) {
      return _buildStationControllerView(context);
    }
    if (controller.isSectionIncharge &&
        _isMaintenance &&
        !_isJointInspectionFlow) {
      return Form(
        key: _formKey,
        child: _buildMaintenanceForm(context),
      );
    }

    // JE form for Junior Engineers and other roles
    return Form(key: _formKey, child: _buildJeChangeNotificationForm(context));
  }

  Widget _buildStationCreateForm(BuildContext context) {
    return Form(
      key: _stationFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: _buildFailureHeader(),
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppConstants.screenPadding,right: AppConstants.screenPadding,),
              child: _buildFailureNumberDisplay(),
            ),
            const SizedBox(height: AppConstants.sectionSpacing),
            CustSection(
              title: "Failure Information",
              trailing: _buildExpandCollapseButton(),
              isVisible: controller.isBasicInfoVisible.value,
              child: Column(
                children: [
                  Obx(() {
                    if (controller.isFunctionalLocationLoading.value) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Colors.orange),
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
                      label: "Functional Location *",
                      hint: "Select...",
                      items: controller.functionalLocationList
                          .map((e) => e.label ?? '')
                          .toList(),
                      selectedValue:
                      controller.selectedFunctionalLocation.value,
                      onChanged: (v) =>
                          controller.onFunctionalLocationChanged(v),
                      validator: (val) =>
                          _requiredDropdown(val, "Functional Location"),
                    );
                  }),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => Row(
                    children: [
                      Expanded(
                        child: CustDropdown(
                          label: "Priority *",
                          hint: "Select...",
                          items: controller.priorityTypeList
                              .map((e) => e.label ?? '')
                              .toList(),
                          selectedValue:
                          controller.selectedPriority.value,
                          onChanged: (v) =>
                          controller.selectedPriority.value = v,
                          validator: (val) =>
                              _requiredDropdown(val, "Priority"),
                        ),
                      ),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                        child: CustDropdown(
                          label: "Department *",
                          hint: "Select...",
                          items: controller.departmentList
                              .map((e) => e.label ?? '')
                              .toList(),
                          selectedValue:
                          controller.selectedDepartment.value,
                          onChanged: (v) async =>
                          await controller.onDepartmentChanged(v),
                          validator: (val) =>
                              _requiredDropdown(val, "Department"),
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustomTextField(
                    label: "Failure Description",
                    controller: controller.failureDescriptionController,
                    hintText: "Enter failure description",
                    maxLines: 4,
                    maxLength: 500,
                    enabled: controller.isStationController,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Failure Description is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => CustDropdown(
                    label: "Location",
                    hint: "Select...",
                    items: controller.locationTypeList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue: controller.selectedLocation.value,
                    onChanged: (value) {
                      controller.onLocationChanged(value);
                    },
                    validator: (val) =>
                        _requiredDropdown(val, "Location"),
                  )),
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustomTextField(
                    label: "Sub Location",
                    controller: controller.subLocationController,
                    hintText: "Enter Sub Location",
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() {
                    debugPrint(
                        "Station form: notificationTypeList count = ${controller.notificationTypeList.length}");
                    return CustDropdown(
                      label: "Notification Type *",
                      hint: "Select...",
                      items: controller.notificationTypeList
                          .map((e) => e.label ?? '')
                          .toList(),
                      selectedValue:
                      controller.selectedNotificationType.value,
                      onChanged: (value) => controller
                          .selectedNotificationType.value = value ?? '',
                      validator: (val) =>
                          _requiredDropdown(val, "Notification Type"),
                    );
                  }),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: "System",
                          controller: controller.systemController,
                          hintText: "Enter System",
                        ),
                      ),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                        child: CustomTextField(
                          label: "Train Id",
                          controller: controller.trainIdController,
                          hintText: "Enter Train Id",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => CustDateTimePicker(
                    label: "Actual Failure Occurrence",
                    hint: "DD/MM/YYYY hh:mm",
                    selectedDateTime:
                    controller.selectedFailureOccurrenceDate.value,
                    enabled: _maintenanceOpenOr202Editable,
                    onDateTimeSelected: (dt) {
                      if (!_maintenanceOpenOr202Editable) return;
                      controller.selectedFailureOccurrenceDate.value = dt;
                    },
                    validator: (val) {
                      if (controller.selectedFailureOccurrenceDate.value ==
                          null) {
                        return "Actual Failure Occurrence is required";
                      }
                      return null;
                    },
                  )),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => CustDateTimePicker(
                    label: "Actual Failure Completed Date & Time",
                    hint: "DD/MM/YYYY hh:mm",
                    selectedDateTime:
                    controller.selectedFailureCompletedDate.value,
                    enabled: false,
                    onDateTimeSelected: (dt) =>
                    controller.selectedFailureCompletedDate.value = dt,
                  )),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => CustDropdown(
                    label: "Failure Category Type",
                    hint: "Select...",
                    items: controller.corrNotificationTypeList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue:
                    controller.selectedFailureCategoryType.value,
                    onChanged: (v) =>
                    controller.selectedFailureCategoryType.value = v,
                    validator: (val) =>
                        _requiredDropdown(val, "Failure Category Type"),
                  )),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() {
                    debugPrint(
                        "Station form: departmentId = ${controller.departmentId.value}");
                    if (controller.departmentId.value == 3) {
                      debugPrint(
                          "Station form: Showing department-specific fields for departmentId 3");
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustDropdown(
                                  label: "Nature of Work *",
                                  hint: "Select...",
                                  items: controller.natureOfWorkList
                                      .map((e) => e.label ?? '')
                                      .toList(),
                                  selectedValue:
                                  controller.selectedNatureOfWork.value,
                                  onChanged: (value) => controller
                                      .selectedNatureOfWork
                                      .value = value ?? '',
                                  validator: (val) => _requiredDropdown(
                                      val, "Nature of Work"),
                                ),
                              ),
                              const SizedBox(
                                  width: AppConstants.elementSpacing),
                              Expanded(
                                child: CustDropdown(
                                  label: "Failure Type *",
                                  hint: "Select...",
                                  items: controller.failureCategoryTypeList
                                      .map((e) => e.label ?? '')
                                      .toList(),
                                  selectedValue: controller
                                      .selectedFailureCategoryType.value,
                                  enabled: _maintenanceOpenOr202Editable,
                                  onChanged: (value) {
                                    if (!_maintenanceOpenOr202Editable) return;
                                    controller.selectedFailureCategoryType.value = value ?? '';
                                  },
                                  validator: (val) =>
                                      _requiredDropdown(val, "Failure Type"),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          CustomTextField(
                            label: "Train Running KM *",
                            controller: controller.trainRunningKmController,
                            keyboardType: TextInputType.number,
                            hintText: "Enter Train Running KM",
                            enabled: _maintenanceOpenOr202Editable,
                            validator: (val) =>
                                _requiredText(val, "Train Running KM"),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
            CustSection(
              title: "Trip Affected",
              trailing: Obx(() => YesNoToggle(
                value: controller.isServiceAffected.value,
                enabled: _maintenanceServiceEditable,
                onChanged: (val) {
                  if (!_maintenanceServiceEditable) return;
                  if (val == false) {
                    controller.tripDelayUplineController.clear();
                    controller.trainCancelNosController.clear();
                    controller.tripDelayDownlineController.clear();
                    controller.trainDelayMinController.clear();
                    controller.trainWithdrawalNosController.clear();
                    controller.trainReplaceNosController.clear();
                    controller.trainDeboardedNosController.clear();
                    controller.isPassengerDeboarding.value = false;
                  }
                  controller.isServiceAffected.value = val;
                },
              )),
              isVisible: controller.isServiceAffected.value,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: CustomTextField(
                              label: "Trip Delay Upline (NOS) *",
                              controller:
                              controller.tripDelayUplineController,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Trip Delay Upline",
                              validator: (val) {
                                if (controller.isServiceAffected.value &&
                                    (val == null || val.trim().isEmpty)) {
                                  return "Trip Delay Upline is required";
                                }
                                return null;
                              })),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                          child: CustomTextField(
                              label: "Trip Cancel (NOS) *",
                              controller: controller.trainCancelNosController,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Trip Cancel",
                              validator: (val) {
                                if (controller.isServiceAffected.value &&
                                    (val == null || val.trim().isEmpty)) {
                                  return "Trip Cancel is required";
                                }
                                return null;
                              })),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                          child: CustomTextField(
                              label: "Trip Delay Downline (NOS) *",
                              controller:
                              controller.tripDelayDownlineController,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Trip Delay Downline",
                              validator: (val) {
                                if (controller.isServiceAffected.value &&
                                    (val == null || val.trim().isEmpty)) {
                                  return "Trip Delay Downline is required";
                                }
                                return null;
                              })),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                          child: CustomTextField(
                              label: "Trip Delay in Min. *",
                              controller: controller.trainDelayMinController,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Trains Delayed In Min",
                              validator: (val) {
                                if (controller.isServiceAffected.value &&
                                    (val == null || val.trim().isEmpty)) {
                                  return "Trip Delay in Min is required";
                                }
                                return null;
                              })),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                          child: CustomTextField(
                              label: "Trip Withdrawal (NOS) *",
                              controller:
                              controller.trainWithdrawalNosController,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Train Withdrawal",
                              validator: (val) {
                                if (controller.isServiceAffected.value &&
                                    (val == null || val.trim().isEmpty)) {
                                  return "Trip Withdrawal is required";
                                }
                                return null;
                              })),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                          child: CustomTextField(
                              label: "Train Replace (NOS) *",
                              controller:
                              controller.trainReplaceNosController,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Train Replace",
                              validator: (val) {
                                if (controller.isServiceAffected.value &&
                                    (val == null || val.trim().isEmpty)) {
                                  return "Train Replace is required";
                                }
                                return null;
                              })),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => controller.isServiceAffected.value
                      ? _buildToggleItem(
                      "Passenger Deboarded *",
                      controller.isPassengerDeboarding.value,
                          (val) =>
                      controller.isPassengerDeboarding.value = val)
                      : const SizedBox.shrink()),
                  Obx(() {
                    if (!controller.isPassengerDeboarding.value ||
                        !controller.isServiceAffected.value) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.elementSpacing),
                      child: CustomTextField(
                          label: "Train Deboarded (NOS) *",
                          controller: controller.trainDeboardedNosController,
                          keyboardType: TextInputType.number,
                          hintText: "Enter Number Of Train Deboarded",
                          validator: (val) {
                            if (controller.isPassengerDeboarding.value &&
                                (val == null || val.trim().isEmpty)) {
                              return "Train Deboarded is required";
                            }
                            return null;
                          }),
                    );
                  }),
                ],
              ),
            ),
            CustSection(
              title: "Passenger Affected",
              trailing: Obx(() => YesNoToggle(
                value: controller.isPassengerAffected.value,
                onChanged: (val) {
                  if (val == false) {
                    controller.passengersAffectedCountController.clear();
                    controller.trappedDurationController.clear();
                    controller.rescuedDurationController.clear();
                  }
                  controller.isPassengerAffected.value = val;
                },
              )),
              isVisible: controller.isPassengerAffected.value,
              child: Column(
                children: [
                  CustomTextField(
                      label: "Number Of Passenger Affected *",
                      controller:
                      controller.passengersAffectedCountController,
                      keyboardType: TextInputType.number,
                      hintText: "Enter number of Passenger Affected",
                      validator: (val) {
                        if (controller.isPassengerAffected.value &&
                            (val == null || val.trim().isEmpty)) {
                          return "Number Of Passenger Affected is required";
                        }
                        return null;
                      }),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                          child: CustomTextField(
                              label: "Trapped Duration *",
                              controller:
                              controller.trappedDurationController,
                              hintText: "Enter Trapped Duration",
                              validator: (val) {
                                if (controller.isPassengerAffected.value &&
                                    (val == null || val.trim().isEmpty)) {
                                  return "Trapped Duration is required";
                                }
                                return null;
                              })),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                          child: CustomTextField(
                              label: "Rescued Duration *",
                              controller:
                              controller.rescuedDurationController,
                              hintText: "Enter Rescued Duration",
                              validator: (val) {
                                if (controller.isPassengerAffected.value &&
                                    (val == null || val.trim().isEmpty)) {
                                  return "Number Of Passenger Affected is required";
                                }
                                return null;
                              })),
                    ],
                  ),
                ],
              ),
            ),
            CustSection(
              title: "Attachments",
              child: Column(
                children: [
                  Row(
                    children: [
                      CustText.body("Before ",
                          fontWeightName: FontWeight.w500),
                      const Text("(Max File Size 1MB)",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: AppConstants.sectionSpacing),
                      _buildUploadButton(controller.beforeFiles,
                          enabled: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: controller.beforeFiles
                        .map<Widget>((file) => _buildAttachmentItem(
                        file['name']!,
                        file['size']!,
                        controller.beforeFiles,
                        file))
                        .toList(),
                  )),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.sectionSpacing),
            Row(
              children: [
                Expanded(
                  child: CustOutlineButton(
                    name: "Cancel",
                    size: double.infinity,
                    sHeight: AppConstants.buttonHeight,
                    borderRadius: AppConstants.inputRadius,
                    onSelected: (_) => _handleCancel(),
                  ),
                ),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(
                  child: CustButton(
                    name: "Save",
                    size: double.infinity,
                    sHeight: AppConstants.buttonHeight,
                    borderRadius: AppConstants.inputRadius,
                    onSelected: (_) => _submitForm(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: _buildFailureHeader(),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppConstants.screenPadding,right: AppConstants.screenPadding,),
            child: _buildFailureNumberDisplay(),
          ),
          CustSection(
            title: "Failure Information",
            trailing: _buildExpandCollapseButton(),
            isVisible: controller.isBasicInfoVisible.value,
            child: Column(
              children: [
                Obx(() => Row(
                  children: [
                    Expanded(
                      child: CustDropdown(
                        label: "Priority *",
                        hint: "Select...",
                        items: controller.priorityTypeList
                            .map((e) => e.label ?? '')
                            .toList(),
                        selectedValue: controller.selectedPriority.value,
                        enabled: _maintenancePriorityEditable,
                        onChanged: (value) => controller
                            .selectedPriority.value = value ?? '',
                        validator: (val) =>
                            _requiredDropdown(val, "Priority"),
                      ),
                    ),
                    const SizedBox(width: AppConstants.elementSpacing),
                    Expanded(
                      child: CustDropdown(
                        label: "Department *",
                        hint: "Select...",
                        items: controller.departmentList
                            .map((e) => e.label ?? '')
                            .toList(),
                        selectedValue:
                        controller.selectedDepartment.value,
                        enabled: _maintenanceOpenOr202Editable,
                        onChanged: (value) async {
                          if (!_maintenanceOpenOr202Editable) return;
                          await controller.onDepartmentChanged(value);
                        },
                        validator: (val) =>
                            _requiredDropdown(val, "Department"),
                      ),
                    ),
                  ],
                )),
                const SizedBox(height: AppConstants.elementSpacing),
                Obx(() {
                  return CustDropdown(
                    label: "Location",
                    hint: "Select...",
                    items: controller.locationList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue: controller.selectedLocation.value,
                    enabled: _maintenanceOpenOr202Editable,
                    onChanged: (value) {
                      if (!_maintenanceOpenOr202Editable) return;
                      controller.onLocationChanged(value);
                    },

                  );
                }),
                const SizedBox(height: AppConstants.elementSpacing),
                Obx(() {
                  if (controller.isFunctionalLocationLoading.value) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.orange),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Loading functional locations...',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }
                  return CustDropdown(
                    label: "Functional Location *",
                    hint: "Select...",
                    items: controller.functionalLocationList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue:
                    controller.selectedFunctionalLocation.value,
                    enabled: _maintenanceOpenOr202Editable,
                    onChanged: (value) {
                      if (!_maintenanceOpenOr202Editable) return;
                      controller.onFunctionalLocationChanged(value);
                    },
                    validator: (val) =>
                        _requiredDropdown(val, "Functional Location"),
                  );
                }),
                const SizedBox(height: AppConstants.elementSpacing),
                Row(
                  children: [
                    Expanded(
                      child: controller.systemController.text.isNotEmpty
                          ? CustomTextField(
                        label: "System",
                        controller: controller.systemController,
                        enabled: false,
                      )
                          : CustDropdown(
                        label: "System",
                        hint: "Select...",
                        items: controller.fmecaSystemList
                            .map((e) => e.label ?? '')
                            .toList(),
                        selectedValue:
                        controller.selectedFmecaSystem.value,
                        enabled: _maintenanceOpenOr202Editable,
                        onChanged: (value) {
                          if (!_maintenanceOpenOr202Editable) return;
                          controller.selectedFmecaSystem.value =
                              value ?? '';
                          controller
                              .onMaintenanceFmecaSystemChanged(value);
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.elementSpacing),
                    Expanded(
                      child: controller.subsystemController.text.isNotEmpty
                          ? CustomTextField(
                        label: "Subsystem",
                        controller: controller.subsystemController,
                        enabled: false,
                      )
                          : CustDropdown(
                        label: "Subsystem",
                        hint: "Select...",
                        items: controller.fmecaSubsystemList
                            .map((e) => e.label ?? '')
                            .toList(),
                        selectedValue:
                        controller.selectedFmecaSubsystem.value,
                        enabled: _maintenanceOpenOr202Editable,
                        onChanged: (value) {
                          if (!_maintenanceOpenOr202Editable) return;
                          controller.selectedFmecaSubsystem.value =
                              value ?? '';
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.elementSpacing),
                  ],
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                Obx(() {
                  if (controller.isEquipmentLoading.value) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.orange),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Loading equipment numbers...',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }
                  return CustDropdown(
                    label: "Equipment Number",
                    hint: "Select...",
                    items: controller.equipmentList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue: controller.selectedEquipmentNumber.value,
                    enabled: _maintenanceOpenOr202Editable &&
                        !controller.isEquipmentLoading.value,
                    onChanged: (value) {
                      if (!_maintenanceOpenOr202Editable) return;
                      controller.onEquipmentChanged(value ?? '');
                    },
                  );
                }),
                const SizedBox(height: AppConstants.elementSpacing),
                CustomTextField(
                  label: "Frequency",
                  controller: controller.fmecaFrequencyController,
                  enabled: false,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                Obx(() => CustDateTimePicker(
                  label: "Actual Failure Occurrence *",
                  hint: "DD/MM/YYYY hh:mm",
                  selectedDateTime:
                  controller.selectedFailureOccurrenceDate.value,
                  enabled: _maintenanceOpenOr202Editable,
                  onDateTimeSelected: (dt) =>
                  controller.selectedFailureOccurrenceDate.value = dt,
                  validator: (val) {
                    if (controller.selectedFailureOccurrenceDate.value ==
                        null) {
                      return "Actual Failure Occurrence is required";
                    }
                    return null;
                  },
                )),
                const SizedBox(height: AppConstants.elementSpacing),
                Obx(() => CustDropdown(
                  label: "Person Responsible",
                  hint: "Select...",
                  items: controller.userList
                      .map((e) => e.label ?? '')
                      .toList(),
                  selectedValue: controller.selectedPersonResponsible.value,
                  enabled: _maintenanceOpenOr202Editable,
                  onChanged: (value) {
                    if (!_maintenanceOpenOr202Editable) return;
                    controller.selectedPersonResponsible.value = value;
                  },
                )),
                const SizedBox(height: AppConstants.elementSpacing),
                if (!_isExistingMaintenance ||
                    _maintenanceStatusId == 1 ||
                    _maintenanceStatusId == 202)
                  CustomTextField(
                    label: "Failure Description",
                    controller: controller.failureDescriptionController,
                    hintText: "Enter failure description",
                    maxLines: 4,
                    maxLength: 500,
                    enabled: _maintenanceOpenOr202Editable,
                  ),
                const SizedBox(height: AppConstants.elementSpacing),
                Obx(() => CustDropdown(
                  label: "Notification Type *",
                  hint: "Select...",
                  items: controller.notificationTypeList
                      .map((e) => e.label ?? '')
                      .toList(),
                  selectedValue:
                  controller.selectedNotificationType.value,
                  enabled: _maintenanceOpenOr202Editable,
                  onChanged: (value) {
                    if (!_maintenanceOpenOr202Editable) return;
                    controller.selectedNotificationType.value = value ?? '';
                  },
                  validator: (val) =>
                      _requiredDropdown(val, "Notification Type"),
                )),
                const SizedBox(height: AppConstants.elementSpacing),
                CustomTextField(
                  label: "Sub Location",
                  controller: controller.subLocationController,
                  hintText: "Enter Sub Location",
                  maxLength: 250,
                  enabled: _maintenanceOpenOr202Editable,
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                Obx(() {
                  if (controller.departmentId.value == 3) {
                    final natureOfWorkItems = controller.apiNatureOfWorkList.isNotEmpty
                        ? controller.apiNatureOfWorkList
                        .map((e) => e.label ?? '')
                        .where((e) => e.trim().isNotEmpty)
                        .toList()
                        : controller.natureOfWorkList
                        .map((e) => e.label ?? '')
                        .where((e) => e.trim().isNotEmpty)
                        .toList();

                    debugPrint(
                        "Maintenance Nature of Work count = ${natureOfWorkItems.length}");
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustDropdown(
                                label: "Nature of Work *",
                                hint: "Select...",
                                items: controller.apiNatureOfWorkList.isEmpty
                                    ? controller.natureOfWorkList
                                    .map((e) => e.label ?? '')
                                    .toList()
                                    : controller.apiNatureOfWorkList
                                    .map((e) => e.label ?? '')
                                    .toList(),
                                selectedValue:
                                controller.selectedNatureOfWork.value,
                                enabled: _maintenanceOpenOr202Editable,
                                onChanged: (value) {
                                  if (!_maintenanceOpenOr202Editable) return;
                                  controller.selectedNatureOfWork.value = value ?? '';
                                },
                                validator: (val) =>
                                    _requiredDropdown(val, "Nature of Work"),
                              ),
                            ),
                            const SizedBox(
                                width: AppConstants.elementSpacing),
                            Expanded(
                              child: CustDropdown(
                                label: "Failure Type *",
                                hint: "Select...",
                                items:
                                controller.apiNotificationTypeList.isEmpty
                                    ? controller.failureCategoryTypeList
                                    .map((e) => e.label ?? '')
                                    .toList()
                                    : controller.apiNotificationTypeList
                                    .map((e) => e.label ?? '')
                                    .toList(),
                                selectedValue: controller
                                    .selectedFailureCategoryType.value,
                                enabled: _maintenanceOpenOr202Editable,
                                onChanged: (value) => controller
                                    .selectedFailureCategoryType
                                    .value = value ?? '',
                                validator: (val) =>
                                    _requiredDropdown(val, "Failure Type"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.elementSpacing),
                        CustomTextField(
                          label: "Train Running KM *",
                          controller: controller.trainRunningKmController,
                          keyboardType: TextInputType.number,
                          hintText: "Enter Train Running KM",
                          enabled: _maintenanceOpenOr202Editable,
                          validator: (val) =>
                              _requiredText(val, "Train Running KM"),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
          _buildOccOriginSection(),
          CustSection(
            title: "Service Affected",
            trailing: Obx(
                  () => YesNoToggle(
                value: controller.isServiceAffected.value,
                enabled: _maintenanceServiceEditable,
                onChanged: (val) {
                  if (val == false) {
                    controller.trainDelayMinController.clear();
                    controller.trainDelayNosController.clear();
                    controller.trainCancelNosController.clear();
                    controller.trainWithdrawalNosController.clear();
                    controller.trainReplaceNosController.clear();
                    controller.trainDeboardedNosController.clear();

                    controller.isPassengerDeboarding.value = false;
                  }

                  controller.isServiceAffected.value = val;
                },
              ),
            ),
            isVisible: true,

            // ONE Obx only for the complete Service Affected body
            child: Obx(() {
              final isServiceAffected =
                  controller.isServiceAffected.value;

              if (!isServiceAffected) {
                return const SizedBox.shrink();
              }

              final isPassengerDeboarding =
                  controller.isPassengerDeboarding.value;

              final showSystemDowntime =
                  controller.departmentId.value == 13 ||
                      controller.departmentId.value == 16;

              return Column(
                children: [
                  const SizedBox(height: 16),

                  // Train Delay
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: "Train Delay in Min. *",
                          controller:
                          controller.trainDelayMinController,
                          keyboardType: TextInputType.number,
                          hintText: "Enter delay in minutes",
                          enabled: _maintenanceServiceEditable,
                          validator: (val) =>
                              _requiredText(
                                val,
                                "Train Delay in Min",
                              ),
                        ),
                      ),

                      const SizedBox(
                        width: AppConstants.elementSpacing,
                      ),

                      Expanded(
                        child: CustomTextField(
                          label: "Train Delay (NOS) *",
                          controller:
                          controller.trainDelayNosController,
                          keyboardType: TextInputType.number,
                          hintText:
                          "Enter number of trains delayed",
                          enabled: _maintenanceServiceEditable,
                          validator: (val) =>
                              _requiredText(
                                val,
                                "Train Delay (NOS)",
                              ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: AppConstants.elementSpacing,
                  ),

                  // Train Cancel / Withdrawal
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: "Train Cancel (NOS) *",
                          controller:
                          controller.trainCancelNosController,
                          keyboardType: TextInputType.number,
                          hintText:
                          "Enter number of trains cancelled",
                          enabled: _maintenanceServiceEditable,
                          validator: (val) =>
                              _requiredText(
                                val,
                                "Train Cancel (NOS)",
                              ),
                        ),
                      ),

                      const SizedBox(
                        width: AppConstants.elementSpacing,
                      ),

                      Expanded(
                        child: CustomTextField(
                          label: "Train Withdrawal (NOS) *",
                          controller:
                          controller.trainWithdrawalNosController,
                          keyboardType: TextInputType.number,
                          hintText:
                          "Enter number of trains withdrawn",
                          enabled: _maintenanceServiceEditable,
                          validator: (val) =>
                              _requiredText(
                                val,
                                "Train Withdrawal (NOS)",
                              ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: AppConstants.elementSpacing,
                  ),

                  // Train Replace / System Downtime
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: "Train Replace (NOS) *",
                          controller:
                          controller.trainReplaceNosController,
                          keyboardType: TextInputType.number,
                          hintText:
                          "Enter number of trains replaced",
                          enabled: _maintenanceServiceEditable,
                          validator: (val) =>
                              _requiredText(
                                val,
                                "Train Replace (NOS)",
                              ),
                        ),
                      ),

                      if (showSystemDowntime) ...[
                        const SizedBox(
                          width: AppConstants.elementSpacing,
                        ),

                        Expanded(
                          child: CustDateTimePicker(
                            label: "System Downtime *",
                            hint: "DD/MM/YYYY hh:mm",
                            selectedDateTime:
                            controller.selectedSystemDowntime.value,
                            enabled:
                            _maintenanceServiceEditable,
                            onDateTimeSelected: (dt) {
                              controller
                                  .selectedSystemDowntime
                                  .value = dt;
                            },
                            validator: (val) {
                              if (controller
                                  .selectedSystemDowntime
                                  .value ==
                                  null) {
                                return "System Downtime is required";
                              }

                              return null;
                            },
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(
                    height: AppConstants.elementSpacing,
                  ),

                  // Passenger Deboarded
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustText(
                        name: "Passenger Deboarded",
                        size: AppConstants.textSize,
                        fontWeightName: FontWeight.w600,
                        color: AppColors.orangeColor,
                      ),
                      YesNoToggle(
                        value: isPassengerDeboarding,
                        enabled: _maintenanceServiceEditable,
                        onChanged: (val) {
                          if (!_maintenanceServiceEditable) {
                            return;
                          }

                          controller.isPassengerDeboarding.value = val;

                          if (!val) {
                            controller
                                .trainDeboardedNosController
                                .clear();
                          }
                        },
                      ),
                    ],
                  ),

                  // Train Deboarded
                  if (isPassengerDeboarding)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.elementSpacing,
                      ),
                      child: CustomTextField(
                        label: "Train Deboarded (NOS) *",
                        controller:
                        controller.trainDeboardedNosController,
                        keyboardType: TextInputType.number,
                        hintText:
                        "Enter number of trains deboarded",
                        enabled: _maintenanceServiceEditable,
                        validator: (val) =>
                            _requiredText(
                              val,
                              "Train Deboarded (NOS)",
                            ),
                      ),
                    ),
                ],
              );
            }),
          ),
          // Web: SIC Required is displayed when Department == 3.
          // It is read-only for the existing Maintenance failure.
          Obx(() {
            if (controller.departmentId.value != 3) {
              return const SizedBox.shrink();
            }
            return CustSection(
              title: "SIC Required",
              trailing: YesNoToggle(
                enabled: false,
                value: controller.isSicRequired.value,
                onChanged: (_) {},
              ),
              child: const SizedBox.shrink(),
            );
          }),
          Obx(() {
            // Department rule from the web, plus: an existing failure that
            // already has passenger data must show it whatever the department.
            final showPassengerAffected =
                [4, 5, 6, 8, 9, 10].contains(controller.departmentId.value) ||
                    (_isExistingMaintenance &&
                        controller.isPassengerAffected.value);

            if (!showPassengerAffected) {
              return const SizedBox.shrink();
            }

            final isPassengerAffected =
                controller.isPassengerAffected.value;

            return CustSection(
              title: "Add Passenger Affected",
              trailing: YesNoToggle(
                value: isPassengerAffected,
                enabled: _maintenanceServiceEditable,
                onChanged: (val) {
                  if (!_maintenanceServiceEditable) return;

                  if (!val) {
                    controller.passengersAffectedCountController.clear();
                    controller.trappedDurationController.clear();
                    controller.rescuedDurationController.clear();
                  }

                  controller.isPassengerAffected.value = val;
                },
              ),
              isVisible: true,
              child: isPassengerAffected
                  ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: "Number Of Passenger Affected *",
                          controller:
                          controller.passengersAffectedCountController,
                          keyboardType: TextInputType.number,
                          hintText:
                          "Enter Number Of Passenger Affected",
                          enabled: _maintenanceServiceEditable,
                          validator: (val) {
                            if (controller.isPassengerAffected.value &&
                                (val == null || val.trim().isEmpty)) {
                              return "Number Of Passenger Affected is required";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(
                        width: AppConstants.elementSpacing,
                      ),
                      Expanded(
                        child: CustomTextField(
                          label: "Trapped Duration *",
                          controller:
                          controller.trappedDurationController,
                          hintText: "Enter Trapped Duration",
                          enabled: _maintenanceServiceEditable,
                          validator: (val) {
                            if (controller.isPassengerAffected.value &&
                                (val == null || val.trim().isEmpty)) {
                              return "Trapped Duration is required";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: AppConstants.elementSpacing,
                  ),
                  CustomTextField(
                    label: "Rescued Duration *",
                    controller:
                    controller.rescuedDurationController,
                    hintText: "Enter Rescued Duration",
                    enabled: _maintenanceServiceEditable,
                    validator: (val) {
                      if (controller.isPassengerAffected.value &&
                          (val == null || val.trim().isEmpty)) {
                        return "Rescued Duration is required";
                      }
                      return null;
                    },
                  ),
                ],
              )
                  : const SizedBox.shrink(),
            );
          }),
          Obx(() {
            final showMeasurement =
                controller.showMeasurementButton.value;

            if (!showMeasurement) {
              return const SizedBox.shrink();
            }

            return CustSection(
              title: "Measurement Reading",
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () =>
                        controller.showMeasurementPopup(),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      "Add Measurement Reading",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangeColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount:
                    controller.measurementPoints.length,
                    itemBuilder: (context, index) {
                      final point =
                      controller.measurementPoints[index];

                      return _buildMeasurementCard(
                        point,
                        index,
                      );
                    },
                  ),
                ],
              ),
            );
          }),
          // Joint Inspection hidden for Maintenance form
          // CustSection(
          //   title: "Joint Inspection",
          //   trailing: _buildExpandCollapseButton(),
          //   child: Column(
          //     children: [
          //       const SizedBox(height: 16),
          //       Obx(() => Row(
          //             children: [
          //               Expanded(
          //                 child: CustDropdown(
          //                   label: "Department",
          //                   hint: "Select...",
          //                   items: controller.masterJointInspectionDepartments
          //                       .map((e) => e.label ?? '')
          //                       .toList(),
          //                   selectedValue: controller.selectedJointDept.value,
          //                   onChanged: (value) => controller
          //                       .selectedJointDept.value = value ?? '',
          //                 ),
          //               ),
          //               const SizedBox(width: AppConstants.elementSpacing),
          //               Expanded(
          //                 child: CustDropdown(
          //                   label: "Assign To",
          //                   hint: "Select...",
          //                   items: controller.jointUserList
          //                       .map((e) => e.label ?? '')
          //                       .toList(),
          //                   selectedValue:
          //                       controller.selectedJointAssignTo.value,
          //                   onChanged: (value) => controller
          //                       .selectedJointAssignTo.value = value ?? '',
          //                 ),
          //               ),
          //             ],
          //         )),
          //       const SizedBox(height: AppConstants.elementSpacing),
          //       CustomTextField(
          //         label: "Joint Inspection Remark",
          //         controller: controller.jointInspectionRemarkController,
          //         hintText: "Enter joint inspection remark",
          //         maxLines: 3,
          //         maxLength: 500,
          //       ),
          //     ],
          //   ),
          // ),
          // ------------------------------------------------------------
          // Read-only sections (same conditions as JE failure view)
          // ------------------------------------------------------------
          // PTW
          // PTW
          if (_isExistingMaintenance &&
              _maintenanceStatusId != 1 &&
              _maintenanceStatusId != 202)
            CustSection(
              title: "PTW Required?",
              trailing: YesNoToggle(
                enabled: false,
                value: controller.isPtwRequired.value,
                onChanged: (_) {},
              ),
              isVisible: true,
              child: CustomTextField(
                controller: controller.ptwNumberController,
                label: "PTW Number",
                enabled: false,
              ),
            ),
          // Failure Rectification Details (RCA)
          Obx(() {
            if (controller.rcaDetailsList.isEmpty) {
              return const SizedBox.shrink();
            }
            return CustSection(
              title: "Failure Rectification Details (RCA)",
              child: Column(
                children: controller.rcaDetailsList
                    .asMap()
                    .entries
                    .map((entry) =>
                    _buildRcaDetailCard(entry.value, entry.key))
                    .toList(),
              ),
            );
          }),
          // Failure Type
          Obx(() {
            final type = controller.selectedMaterialType.value ?? '';
            final showFailureType =
                (_isExistingMaintenance &&
                    _maintenanceStatusId != 1 &&
                    _maintenanceStatusId != 202) ||
                    type.isNotEmpty;
            if (!showFailureType) return const SizedBox.shrink();
            return CustSection(
              title: "Failure Type",
              child: Column(
                children: [
                  CustDropdown(
                    label: "Failure Type",
                    hint: "Select...",
                    items: controller.corrFailureTypeList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue: type,
                    enabled: false,
                    onChanged: (_) {},
                  ),
                  if (type == "Other") ...[
                    const SizedBox(height: AppConstants.elementSpacing),
                    CustomTextField(
                      label: "Remark",
                      controller: controller.failureTypeController,
                      enabled: false,
                    ),
                  ],
                ],
              ),
            );
          }),
          // Spare Part Replace (only for Hardware failure type)
          Obx(() {
            if (controller.selectedMaterialType.value != "Hardware") {
              return const SizedBox.shrink();
            }
            return CustSection(
              title: "Spare Part Replace",
              trailing: YesNoToggle(
                enabled: false,
                value: controller.isSparePartReplaced.value,
                onChanged: (_) {},
              ),
              isVisible: controller.isSparePartReplaced.value,
              child: controller.replacedMaterialsList.isEmpty
                  ? const SizedBox.shrink()
                  : _buildReplacedMaterialTable(enabled: false),
            );
          }),
          // Material Dismantle
          Obx(() {
            final showMaterialDismantle =
                _isExistingMaintenance ||
                    controller.dismantleMaterialsList.isNotEmpty;
            if (!showMaterialDismantle) {
              return const SizedBox.shrink();
            }
            return CustSection(
              title: "Material Dismantle",
              trailing: YesNoToggle(
                enabled: false,
                value: controller.isMaterialDismantle.value,
                onChanged: (_) {},
              ),
              child: controller.isMaterialDismantle.value
                  ? _buildDismantleMaterialTable(enabled: false)
                  : const SizedBox.shrink(),
            );
          }),
          // Joint Inspection
          Obx(() {
            final showJointInspection =
                (_isExistingMaintenance &&
                    _maintenanceStatusId != 1 &&
                    _maintenanceStatusId != 202) ||
                    controller.isJointInspection.value ||
                    controller.jointInspectionHistoryList.isNotEmpty;
            if (!showJointInspection) {
              return const SizedBox.shrink();
            }
            return CustSection(
              title: "Joint Inspection",
              trailing: YesNoToggle(
                enabled: false,
                value: controller.isJointInspection.value,
                onChanged: (_) {},
              ),
              child: controller.jointInspectionHistoryList.isEmpty
                  ? const SizedBox.shrink()
                  : _buildJointInspectionTable(enabled: false),
            );
          }),
          // Closure: rectification details, user status and dates
          Obx(() {
            final hasClosure =
                controller.failureRectificationDetailsController.text
                    .trim()
                    .isNotEmpty ||
                    (controller.selectedUserStatus.value ?? '')
                        .trim()
                        .isNotEmpty ||
                    controller.selectedFailureAttendedDate.value != null ||
                    controller.selectedActualFailureRectifiedDate.value !=
                        null;
            final showClosure =
                (_isExistingMaintenance &&
                    _maintenanceStatusId != 1 &&
                    _maintenanceStatusId != 202) ||
                    hasClosure;
            if (!showClosure) return const SizedBox.shrink();
            return CustSection(
              title: "Failure Rectification Details",
              child: Column(
                children: [
                  CustomTextField(
                    label: "Failure Rectification Details",
                    controller:
                    controller.failureRectificationDetailsController,
                    maxLines: 4,
                    enabled: false,
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustDropdown(
                    label: "User Status",
                    hint: "Select",
                    items: controller.userStatusJeList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue: controller.selectedUserStatus.value,
                    enabled: false,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  if (controller.selectedUserStatus.value ==
                      "Under Observation") ...[
                    CustDateTimePicker(
                      label: "Under Observation Date",
                      hint: "DD/MM/YYYY hh:mm",
                      selectedDateTime:
                      controller.selectedUnderObservationDate.value,
                      enabled: false,
                      onDateTimeSelected: (_) {},
                    ),
                    const SizedBox(height: AppConstants.elementSpacing),
                  ],
                  CustDateTimePicker(
                    label: "Failure Attended",
                    hint: "DD/MM/YYYY hh:mm",
                    selectedDateTime:
                    controller.selectedFailureAttendedDate.value,
                    enabled: false,
                    onDateTimeSelected: (_) {},
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustDateTimePicker(
                    label: "Actual Failure Rectified",
                    hint: "DD/MM/YYYY hh:mm",
                    selectedDateTime:
                    controller.selectedActualFailureRectifiedDate.value,
                    enabled: false,
                    onDateTimeSelected: (_) {},
                  ),
                ],
              ),
            );
          }),
          if (!_isExistingMaintenance ||
              _maintenanceStatusId == 1 ||
              _maintenanceStatusId == 202)
            CustSection(
              title: "Attachments",
              child: Column(
                children: [
                  Row(
                    children: [
                      CustText.body("Before ", fontWeightName: FontWeight.w500),
                      const Text("(Max File Size 1MB)",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: AppConstants.sectionSpacing),
                      _buildUploadButton(controller.beforeFiles, enabled: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: controller.beforeFiles
                        .map<Widget>((file) => _buildAttachmentItem(
                        file['name']!,
                        file['size']!,
                        controller.beforeFiles,
                        file))
                        .toList(),
                  )),
                  Obx(() {
                    final hasImages =
                        controller.beforeImagesList.isNotEmpty ||
                            controller.afterImagesList.isNotEmpty ||
                            controller.rcaImagesList.isNotEmpty;
                    if (!hasImages) return const SizedBox.shrink();
                    Widget group(String title, RxList list) => Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustText.body(title),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: list
                                .map<Widget>((file) =>
                                _buildUploadedImagePreview(
                                    file['path']!))
                                .toList(),
                          ),
                        ],
                      ),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
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
                            group("Before:", controller.beforeImagesList),
                            group("After:", controller.afterImagesList),
                            group("RCA:", controller.rcaImagesList),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          // Attachments editor is hidden after status 1/202; still show the
          // images that were already uploaded (read-only).
          if (_isExistingMaintenance &&
              _maintenanceStatusId != 1 &&
              _maintenanceStatusId != 202)
            Obx(() {
              final groups = <String, RxList>{
                "Before:": controller.beforeImagesList,
                "After:": controller.afterImagesList,
                "RCA:": controller.rcaImagesList,
              }..removeWhere((_, l) => l.isEmpty);
              if (groups.isEmpty) return const SizedBox.shrink();
              return CustSection(
                title: "Uploaded Images",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groups.entries
                      .map<Widget>((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustText.body(g.key),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: g.value
                              .map<Widget>((file) =>
                              _buildUploadedImagePreview(file['path']!))
                              .toList(),
                        ),
                      ],
                    ),
                  ))
                      .toList(),
                ),
              );
            }),
          Padding(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: Row(
              children: [
                Expanded(
                  child: CustOutlineButton(
                    name: "Back",
                    size: double.infinity,
                    sHeight: AppConstants.buttonHeight,
                    borderRadius: AppConstants.inputRadius,
                    onSelected: (_) => _handleCancel(),
                  ),
                ),

                // Show Update/Submit button only when applicable
                if (!_isExistingMaintenance ||
                    _maintenanceStatusId == 1 ||
                    _maintenanceStatusId == 202) ...[
                  const SizedBox(width: AppConstants.elementSpacing),

                  Expanded(
                    child: Obx(() => CustButton(
                      name: controller.isSubmitting.value
                          ? "Submitting..."
                          : (_isExistingMaintenance ? "Update" : "Submit"),
                      size: double.infinity,
                      sHeight: AppConstants.buttonHeight,
                      borderRadius: AppConstants.inputRadius,
                      color1: controller.isSubmitting.value ? Colors.grey : null,
                      color2: controller.isSubmitting.value ? Colors.grey : null,
                      onSelected: controller.isSubmitting.value
                          ? null
                          : (_) => _submitForm(),
                    )),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(Map<String, dynamic> point, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    point['description'] ?? 'Measurement Point',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => controller.removeMeasurementPoint(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Unit: ${point['unit'] ?? 'N/A'}"),
            if (point['isReadingRequired'] == true) ...[
              const SizedBox(height: 8),
              const Text("Reading Required: Yes",
                  style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJeChangeNotificationForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child:  _buildFailureHeader(showHistoryIcon: true),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppConstants.screenPadding,right: AppConstants.screenPadding,),
            child: _buildFailureNumberDisplay(fallbackNotificationCode: widget.notificationCode),
          ),
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
                          Obx(() {
                            if (controller.isEquipmentLoading.value) {
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
                                      'Loading equipment numbers...',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // If functional location is selected, but equipmentList only has "Select" or empty, trigger on-demand load
                            final currentFunc = controller.selectedFunctionalLocation.value;
                            if (currentFunc != null &&
                                currentFunc.isNotEmpty &&
                                currentFunc != 'Select' &&
                                controller.equipmentList.length <= 1 &&
                                !controller.isEquipmentLoading.value) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (controller.equipmentList.length <= 1 &&
                                    !controller.isEquipmentLoading.value) {
                                  controller.loadEquipmentsOnDemand(
                                    functionalLocationId: currentFunc,
                                  );
                                }
                              });
                            }

                            return CustDropdown(
                              label: 'Equipment Number *',
                              hint: 'Select equipment number',
                              items: controller.equipmentList
                                  .map((e) => e.label ?? '')
                                  .toList(),
                              selectedValue:
                              controller.selectedEquipmentNumber.value,
                              enabled: !controller.isFormDisabled &&
                                  controller.isJE &&
                                  !_isJointInspectionFlow,
                              onChanged: (value) {
                                if (controller.isFormDisabled) return;
                                controller.onEquipmentChanged(value);
                              },
                              validator: (val) {
                                if (val == null ||
                                    val.trim().isEmpty ||
                                    val == 'Select') {
                                  return 'Equipment Number is required';
                                }
                                return null;
                              },
                            );
                          }),
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
                      Obx(() {
                        debugPrint(
                            "JE form: notificationTypeList count = ${controller.notificationTypeList.length}");
                        return CustDropdown(
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
                            });
                      }),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustomTextField(
                        controller: controller.subLocationController,
                        label: "Sub Location",
                        enabled: !controller.isFormDisabled &&
                            controller.isJE &&
                            !_isJointInspectionFlow,
                      ),
                      const SizedBox(height: AppConstants.elementSpacing),
                      Obx(() {
                        debugPrint(
                            "JE form: departmentId = ${controller.departmentId.value}");
                        if (controller.departmentId.value == 3) {
                          debugPrint(
                              "JE form: Showing department-specific fields for departmentId 3");
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: CustDropdown(
                                      label: "Nature of Work *",
                                      hint: "Select...",
                                      items: controller.natureOfWorkList
                                          .map((e) => e.label ?? '')
                                          .toList(),
                                      selectedValue: controller
                                          .selectedNatureOfWork.value,
                                      onChanged: (value) => controller
                                          .selectedNatureOfWork
                                          .value = value ?? '',
                                      enabled: !controller.isFormDisabled &&
                                          controller.isJE &&
                                          !_isJointInspectionFlow,
                                      validator: (val) => _requiredDropdown(
                                          val, "Nature of Work"),
                                    ),
                                  ),
                                  const SizedBox(
                                      width: AppConstants.elementSpacing),
                                  Expanded(
                                    child: CustDropdown(
                                      label: "Failure Type *",
                                      hint: "Select...",
                                      items: controller
                                          .failureCategoryTypeList
                                          .map((e) => e.label ?? '')
                                          .toList(),
                                      selectedValue: controller
                                          .selectedFailureCategoryType.value,
                                      onChanged: (value) => controller
                                          .selectedFailureCategoryType
                                          .value = value ?? '',
                                      enabled: !controller.isFormDisabled &&
                                          controller.isJE &&
                                          !_isJointInspectionFlow,
                                      validator: (val) => _requiredDropdown(
                                          val, "Failure Type"),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                  height: AppConstants.elementSpacing),
                              CustomTextField(
                                label: "Train Running KM *",
                                controller:
                                controller.trainRunningKmController,
                                keyboardType: TextInputType.number,
                                hintText: "Enter Train Running KM",
                                enabled: !controller.isFormDisabled &&
                                    controller.isJE &&
                                    !_isJointInspectionFlow,
                                validator: (val) =>
                                    _requiredText(val, "Train Running KM"),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      const SizedBox(height: AppConstants.elementSpacing),
                    ],
                  ],
                ),
              ),
              _buildOccOriginSection(),
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
                              ? (item) =>
                              item.trim().toLowerCase().startsWith('close')
                              : null,
                          onChanged: (v) {
                            if (controller.isFormDisabled) return;
                            debugPrint("Selected User Status = $v");
                            debugPrint(
                                "Main Status = ${controller.mainStatusName.value}");
                            debugPrint(
                                "Blocked = ${controller.isCloseUserStatusBlocked}");

                            if (controller.isCloseUserStatusBlocked &&
                                v
                                    ?.trim()
                                    .toLowerCase()
                                    .startsWith('close') ==
                                    true) {
                              controller.showPendingJointInspectionPopup();
                              return;
                            }

                            controller.selectedUserStatus.value = v;
                            // Unfocus the failure rectification details field
                            controller.failureRectificationFocusNode
                                .unfocus();
                          },
                          validator: (value) {
                            if (controller.selectedUserStatus.value == null ||
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
                          lastDate: (controller.selectedFailureOccurrenceDate.value != null &&
                              controller.selectedFailureOccurrenceDate.value!.isAfter(DateTime.now()))
                              ? controller.selectedFailureOccurrenceDate.value!.add(const Duration(days: 30))
                              : DateTime.now().add(const Duration(days: 1)),
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
                          lastDate: ((controller.selectedFailureAttendedDate.value ?? controller.selectedFailureOccurrenceDate.value) != null &&
                              (controller.selectedFailureAttendedDate.value ?? controller.selectedFailureOccurrenceDate.value)!.isAfter(DateTime.now()))
                              ? (controller.selectedFailureAttendedDate.value ?? controller.selectedFailureOccurrenceDate.value)!.add(const Duration(days: 30))
                              : DateTime.now().add(const Duration(days: 1)),
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
                Padding(
                  padding: const EdgeInsets.all(AppConstants.screenPadding),
                  child: Row(
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
                          child: Obx(() => CustButton(
                            name: controller.isSubmitting.value
                                ? "Submitting..."
                                : "Submit",
                            sHeight: AppConstants.buttonHeight,
                            size: double.infinity,
                            color1: controller.isSubmitting.value ? Colors.grey : null,
                            color2: controller.isSubmitting.value ? Colors.grey : null,
                            onSelected: controller.isSubmitting.value
                                ? null
                                : (_) => _isJointInspectionFlow
                                ? _submitJointInspectionForm()
                                : _submitForm(),
                          )),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Common header widget used across all forms
  // ---------------------------------------------------------
  // OCC failure (create)
  // ---------------------------------------------------------

  Widget _occDropdown({
    required String label,
    required RxList<LabelValue> options,
    required RxnString selected,
    required ValueChanged<String?> onChanged,
    String? requiredName,
  }) {
    return Obx(() => CustDropdown(
      label: label,
      hint: "Select...",
      items: options.map((e) => e.label ?? '').toList(),
      selectedValue: selected.value,
      onChanged: onChanged,
      validator: requiredName == null
          ? null
          : (val) => _requiredDropdown(val, requiredName),
    ));
  }

  Widget _occNumberField(
      String label,
      TextEditingController textController,
      String hint, {
        bool Function()? requiredWhen,
        String? requiredMessage,
      }) {
    return CustomTextField(
      label: label,
      controller: textController,
      hintText: hint,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: requiredWhen == null
          ? null
          : (val) {
        if (requiredWhen() && (val == null || val.trim().isEmpty)) {
          return requiredMessage;
        }
        return null;
      },
    );
  }

  Widget _occRow(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppConstants.elementSpacing),
        Expanded(child: right),
      ],
    );
  }

  Widget _occTripSection() {
    const gap = SizedBox(height: AppConstants.elementSpacing);
    return CustSection(
      title: "Trip Affected",
      trailing: Obx(() => YesNoToggle(
        value: controller.isServiceAffected.value,
        onChanged: controller.onOccTripAffectedChanged,
      )),
      isVisible: controller.isServiceAffected.value,
      child: Column(
        children: [
          _occRow(
            _occNumberField(
              "Trip Delay Upline (NOS) *",
              controller.tripDelayUplineController,
              "Enter Trip Delay Upline",
              requiredWhen: () => controller.isServiceAffected.value,
              requiredMessage: "Trip Delay Upline is required",
            ),
            _occNumberField(
              "Trip Cancel (NOS) *",
              controller.trainCancelNosController,
              "Enter Trip Cancel",
              requiredWhen: () => controller.isServiceAffected.value,
              requiredMessage: "Trip Cancel is required",
            ),
          ),
          gap,
          _occRow(
            _occNumberField(
              "Trip Delay Downline (NOS) *",
              controller.tripDelayDownlineController,
              "Enter Trip Delay Downline",
              requiredWhen: () => controller.isServiceAffected.value,
              requiredMessage: "Trip Delay Downline is required",
            ),
            _occNumberField(
              "Trip Delay in Min. *",
              controller.trainDelayMinController,
              "Enter Trip Delay in Min",
              requiredWhen: () => controller.isServiceAffected.value,
              requiredMessage: "Trip Delay in Min is required",
            ),
          ),
          gap,
          _occRow(
            _occNumberField(
              "Trip Withdrawal (NOS) *",
              controller.trainWithdrawalNosController,
              "Enter Trip Withdrawal",
              requiredWhen: () => controller.isServiceAffected.value,
              requiredMessage: "Trip Withdrawal is required",
            ),
            _occDropdown(
              label: "Train Operators Name",
              options: controller.occTrainOperatorList,
              selected: controller.selectedOccTrainOperator,
              onChanged: (v) =>
              controller.selectedOccTrainOperator.value = v,
            ),
          ),
          gap,
          Obx(() => _buildToggleItem(
            "Train Replace",
            controller.occTrainReplaced.value,
            controller.onOccTrainReplacedChanged,
          )),
          Obx(() {
            if (!controller.occTrainReplaced.value) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding:
              const EdgeInsets.only(top: AppConstants.elementSpacing),
              child: Column(
                children: [
                  _occNumberField(
                    "Train Replace (NOS) *",
                    controller.trainReplaceNosController,
                    "Enter Train Replace",
                    requiredWhen: () =>
                    controller.occTrainReplaced.value,
                    requiredMessage: "Train Replace is required",
                  ),
                  gap,
                  CustomTextField(
                    label: "Replaced with",
                    controller: controller.occReplacedWithController,
                    hintText: "Enter Replaced with",
                    maxLength: 250,
                  ),
                  gap,
                  Obx(() => CustDateTimePicker(
                    label: "Replaced Time",
                    hint: "HH:mm",
                    pickerType: PickerType.time,
                    selectedDateTime: controller.occReplacedTime.value,
                    onDateTimeSelected: (dt) =>
                    controller.occReplacedTime.value = dt,
                  )),
                ],
              ),
            );
          }),
          Obx(() => _buildToggleItem(
            "Passenger Deboarding",
            controller.isPassengerDeboarding.value,
            controller.onOccPassengerDeboardingChanged,
          )),
          Obx(() {
            if (!controller.isPassengerDeboarding.value) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding:
              const EdgeInsets.only(top: AppConstants.elementSpacing),
              child: _occNumberField(
                "Train Deboarded (NOS) *",
                controller.trainDeboardedNosController,
                "Enter Number Of Train Deboarded",
                requiredWhen: () =>
                controller.isPassengerDeboarding.value,
                requiredMessage: "Train Deboarded is required",
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _occPassengerSection({bool showWayOfRescue = true}) {
    const gap = SizedBox(height: AppConstants.elementSpacing);
    return CustSection(
      title: "Passenger Affected",
      trailing: Obx(() => YesNoToggle(
        value: controller.isPassengerAffected.value,
        onChanged: controller.onOccPassengerAffectedChanged,
      )),
      isVisible: controller.isPassengerAffected.value,
      child: Column(
        children: [
          _occNumberField(
            "Number Of Passenger Affected *",
            controller.passengersAffectedCountController,
            "Enter number of Passenger Affected",
            requiredWhen: () => controller.isPassengerAffected.value,
            requiredMessage: "Number Of Passenger Affected is required",
          ),
          gap,
          _occRow(
            _occNumberField(
              "Trapped Duration *",
              controller.trappedDurationController,
              "Enter Trapped Duration",
              requiredWhen: () => controller.isPassengerAffected.value,
              requiredMessage: "Trapped Duration is required",
            ),
            _occNumberField(
              "Rescued Duration *",
              controller.rescuedDurationController,
              "Enter Rescued Duration",
              requiredWhen: () => controller.isPassengerAffected.value,
              requiredMessage: "Rescued Duration is required",
            ),
          ),
          if (showWayOfRescue) ...[
            gap,
            CustomTextField(
              label: "Way Of Rescue",
              controller: controller.occWayOfRescueController,
              hintText: "Enter Way Of Rescue",
              maxLength: 250,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // OCC failure (FMC update)
  // ---------------------------------------------------------

  /// Earlier descriptions of an OCC failure (read-only box with author/time).
  Widget _occDescriptionHistory() {
    return Obx(() {
      final history = controller.notificationDescriptionHistoryList;
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        ),
        child: history.isEmpty
            ? const Text('No description added yet.',
            style: TextStyle(color: Colors.grey))
            : ListView.separated(
          shrinkWrap: true,
          itemCount: history.length,
          separatorBuilder: (_, __) => const Divider(height: 12),
          itemBuilder: (_, i) {
            final h = history[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.description ?? ''),
                const SizedBox(height: 2),
                Text(
                  '${h.createdBy ?? ''}  ${h.createdOn ?? ''}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  /// Read-only view of an OCC failure that FMC / TPC / CSS / RSC have already
  /// assigned to a department. Same layout as the Station Controller's
  /// read-only screen (disabled fields, no action buttons), fed by the OCC
  /// failure data.
  Widget _buildOccAssignedView(BuildContext context) {
    const gap = SizedBox(height: AppConstants.elementSpacing);
    Widget row(Widget a, Widget b) => _occRow(a, b);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: _buildFailureHeader(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.screenPadding),
            child: _buildFailureNumberDisplay(),
          ),
          CustSection(
            title: "Failure Information",
            trailing: _buildExpandCollapseButton(),
            isVisible: controller.isBasicInfoVisible.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _occReadOnlyField("Functional Location",
                        () => controller.selectedFunctionalLocation.value ?? ''),
                gap,
                row(
                  _occReadOnlyField("Priority",
                          () => controller.selectedPriority.value ?? ''),
                  _occReadOnlyField("Department",
                          () => controller.selectedDepartment.value ?? ''),
                ),
                gap,
                _occReadOnlyField("Current Status",
                        () => controller.mainStatusName.value ?? ''),
                gap,
                CustText.detailLabel("Failure Description"),
                const SizedBox(height: 6),
                _occDescriptionHistory(),
                gap,
                _occReadOnlyField("Reported To",
                        () => controller.selectedOccReportedTo.value ?? ''),
                gap,
                row(
                  _occReadOnlyController(
                      "Line", controller.occLineDisplayController),
                  _occReadOnlyController(
                      "Location Text", controller.occLocationTextController),
                ),
                gap,
                _occReadOnlyField("Location",
                        () => controller.selectedLocation.value ?? ''),
                gap,
                _occReadOnlyController(
                    "Sub Location", controller.subLocationController),
                gap,
                row(
                  _occReadOnlyField(
                      "System", () => controller.occSystemValue),
                  _occReadOnlyField("Sub System",
                          () => controller.selectedFmecaSubsystem.value ?? ''),
                ),
                gap,
                row(
                  _occReadOnlyController(
                      "Train Id", controller.trainIdController),
                  _occReadOnlyController(
                      "Train Set", controller.occTrainSetDisplayController),
                ),
                gap,
                Obx(() => CustDateTimePicker(
                  label: "Actual Failure Occurrence",
                  hint: "Actual Failure Occurrence",
                  selectedDateTime:
                  controller.selectedFailureOccurrenceDate.value,
                  enabled: false,
                  onDateTimeSelected: (_) {},
                )),
                gap,
                _occReadOnlyField("Failure Reported by",
                        () => controller.selectedFailureReportedBy.value ?? ''),
                gap,
                Obx(() => CustDateTimePicker(
                  label: "Actual Failure Completed Date & Time",
                  hint: "Actual Failure Completed Date & Time",
                  selectedDateTime:
                  controller.selectedFailureCompletedDate.value,
                  enabled: false,
                  onDateTimeSelected: (_) {},
                )),
                gap,
                _occReadOnlyField("Failure Category Type",
                        () => controller.selectedFailureCategoryType.value ?? ''),
                gap,
              ],
            ),
          ),
          Obx(() => controller.occIsStationFailure.value
              ? const SizedBox.shrink()
              : CustSection(
            title: "Trip Information",
            isVisible: controller.isServiceAffected.value,
            trailing: YesNoToggle(
              value: controller.isServiceAffected.value,
              enabled: false,
              onChanged: (_) {},
            ),
            child: Column(
              children: [
                row(
                  _occReadOnlyController("Trip Delay Upline (NOS)",
                      controller.tripDelayUplineController),
                  _occReadOnlyController("Trip Cancel (NOS)",
                      controller.trainCancelNosController),
                ),
                gap,
                row(
                  _occReadOnlyController("Trip Delay Downline (NOS)",
                      controller.tripDelayDownlineController),
                  _occReadOnlyController("Trip Delay in Min.",
                      controller.trainDelayMinController),
                ),
                gap,
                row(
                  _occReadOnlyController("Trip Withdrawal (NOS)",
                      controller.trainWithdrawalNosController),
                  _occReadOnlyController("Train Replace (NOS)",
                      controller.trainReplaceNosController),
                ),
                Obx(() => controller.isPassengerDeboarding.value
                    ? Padding(
                  padding: const EdgeInsets.only(
                      top: AppConstants.elementSpacing),
                  child: _occReadOnlyController("Train Deboarded (NOS)",
                      controller.trainDeboardedNosController),
                )
                    : const SizedBox.shrink()),
              ],
            ),
          )),
          CustSection(
            title: "Passenger Affected",
            isVisible: controller.isPassengerAffected.value,
            trailing: YesNoToggle(
              value: controller.isPassengerAffected.value,
              enabled: false,
              onChanged: (_) {},
            ),
            child: Column(
              children: [
                _occReadOnlyController("Number Of Passenger Affected",
                    controller.passengersAffectedCountController),
                gap,
                row(
                  _occReadOnlyController("Trapped Duration",
                      controller.trappedDurationController),
                  _occReadOnlyController("Rescued Duration",
                      controller.rescuedDurationController),
                ),
              ],
            ),
          ),
          Obx(() {
            final any = controller.beforeImagesList.isNotEmpty ||
                controller.afterImagesList.isNotEmpty ||
                controller.rcaImagesList.isNotEmpty;
            if (!any) return const SizedBox.shrink();
            return CustSection(
              title: "Uploaded Images",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _occImageGroup("Before Images", controller.beforeImagesList),
                  _occImageGroup("After Images", controller.afterImagesList),
                  _occImageGroup("RCA Images", controller.rcaImagesList),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Read-only "OCC Failure Details" for Section Incharge and JE: the fields
  /// OCC / FMC filled in (Reported To, Line, Train Set, ...) that these forms
  /// do not otherwise have. Hidden for failures that did not come from OCC.
  Widget _buildOccOriginSection() {
    return Obx(() {
      final details = controller.occOriginDetails;
      if (details.isEmpty) return const SizedBox.shrink();
      return CustSection(
        title: "OCC Failure Details",
        child: Column(
          children: [
            for (var i = 0; i < details.length; i++) ...[
              if (i > 0) const SizedBox(height: AppConstants.elementSpacing),
              CustomTextField(
                label: details[i].key,
                controller: TextEditingController(text: details[i].value),
                enabled: false,
              ),
            ],
          ],
        ),
      );
    });
  }

  /// Read-only field bound straight to a [TextEditingController]. Use this
  /// (not [_occReadOnlyField]) when the value is not an Rx variable: an Obx
  /// with nothing observable inside throws in GetX.
  Widget _occReadOnlyController(String label, TextEditingController c) {
    return CustomTextField(label: label, controller: c, enabled: false);
  }

  /// Read-only field for a value read from Rx variables (kept in sync via Obx).
  Widget _occReadOnlyField(String label, String Function() value) {
    return Obx(() => CustomTextField(
      label: label,
      controller: TextEditingController(text: value()),
      enabled: false,
    ));
  }

  Future<bool> _confirmOcc(String message) async {
    final ok = await Get.dialog<bool>(
      CustPopup(
        title: 'Confirm',
        message: message,
        confirmText: 'Yes',
        cancelText: 'No',
        onConfirm: () => Get.back(result: true),
        onCancel: () => Get.back(result: false),
        showIcon: true,
        icon: Icons.help_outline,
        iconColor: AppColors.orangeColor,
      ),
    );
    return ok == true;
  }

  /// [kind]: 'assign' | 'draft' | 'close' (see submitOccUpdate).
  Future<void> _occUpdateAction(String kind, String confirmMessage) async {
    FocusScope.of(context).unfocus();
    final errors = controller.occUpdateValidate(kind);
    if (errors.isNotEmpty) {
      appSnackbar(
        'Validation Error',
        errors.first,
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    if (!await _confirmOcc(confirmMessage)) return;
    await controller.submitOccUpdate(kind);
  }

  /// System and Sub System: read-only text when the functional location maps
  /// to a single pair, otherwise dropdowns (web behaviour).
  Widget _occSystemSubsystemFields() {
    return Obx(() {
      final systemReadOnly = controller.fmecaSystemReadOnly.value;
      final subReadOnly = controller.fmecaSubsystemReadOnly.value;
      final systems =
      controller.fmecaSystemList.map((e) => e.label ?? '').toList();
      final subs =
      controller.fmecaSubsystemList.map((e) => e.label ?? '').toList();

      final Widget system = systemReadOnly || systems.isEmpty
          ? CustomTextField(
        label: "System *",
        controller:
        TextEditingController(text: controller.occSystemValue),
        hintText: "Select functional location",
        enabled: false,
      )
          : CustDropdown(
        label: "System *",
        hint: "Select...",
        items: systems,
        selectedValue: controller.selectedFmecaSystem.value,
        onChanged: (v) => controller.onOccSystemChanged(v),
      );

      final Widget subSystem = subReadOnly || subs.isEmpty
          ? CustomTextField(
        label: "Sub System *",
        controller: TextEditingController(
            text: controller.selectedFmecaSubsystem.value ?? ''),
        hintText: "Select system",
        enabled: false,
      )
          : CustDropdown(
        label: "Sub System *",
        hint: "Select...",
        items: subs,
        selectedValue: controller.selectedFmecaSubsystem.value,
        onChanged: controller.onOccSubsystemChanged,
      );

      return Column(
        children: [
          system,
          const SizedBox(height: AppConstants.elementSpacing),
          subSystem,
        ],
      );
    });
  }

  /// System and Sub System as read-only values (update form for the roles an
  /// OCC failure is reported to; they cannot change what OCC entered).
  Widget _occFixedSystemSubsystemFields() {
    return Column(
      children: [
        _occReadOnlyField("System *", () => controller.occSystemValue),
        const SizedBox(height: AppConstants.elementSpacing),
        _occReadOnlyField(
            "Sub System *", () => controller.selectedFmecaSubsystem.value ?? ''),
      ],
    );
  }

  /// OCC role opening a failure that was reported to FMC / TPC / CSS / RSC:
  /// everything is view-only (those roles own the update).
  Widget _occViewOnlyGuard(Widget child) {
    return Obx(() => controller.occRoleViewOnly
        ? Opacity(opacity: 0.6, child: AbsorbPointer(child: child))
        : child);
  }

  Widget _occImageGroup(String title, RxList<Map<String, dynamic>> list) {
    return Obx(() {
      if (list.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: AppConstants.elementSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustText.body(title),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: list
                  .map<Widget>(
                      (file) => _buildUploadedImagePreview(file['path']!))
                  .toList(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildOccUpdateForm(BuildContext context) {
    const gap = SizedBox(height: AppConstants.elementSpacing);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: _buildFailureHeader(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFailureNumberDisplay(),
                Obx(() => controller.occCreatedDateText.value.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CustText.body(
                    "Date & time: ${controller.occCreatedDateText.value}",
                    color: AppColors.textDarkSecondary,
                  ),
                )),
              ],
            ),
          ),
          Obx(() => controller.occRoleViewOnly
              ? Padding(
            padding: const EdgeInsets.fromLTRB(
                AppConstants.screenPadding,
                AppConstants.elementSpacing,
                AppConstants.screenPadding,
                0),
            child: CustText.body(
              "Reported to ${controller.selectedOccReportedTo.value ?? 'another role'}. "
                  "Only that role can update this failure.",
              color: AppColors.orangeColor,
            ),
          )
              : const SizedBox.shrink()),
          const SizedBox(height: AppConstants.sectionSpacing),
          _occViewOnlyGuard(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          CustSection(
            title: "Failure Information",
            trailing: _buildExpandCollapseButton(),
            isVisible: controller.isBasicInfoVisible.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                controller.isOccRoleUser
                    ? _occDropdown(
                  label: "Priority *",
                  options: controller.priorityTypeList,
                  selected: controller.selectedPriority,
                  onChanged: (v) => controller.selectedPriority.value = v,
                )
                    : _occReadOnlyField("Priority",
                        () => controller.selectedPriority.value ?? ''),
                gap,
                CustText.detailLabel("Previously added description"),
                const SizedBox(height: 6),
                _occDescriptionHistory(),
                gap,
                CustomTextField(
                  label: "Failure Description (Max length: 500)",
                  controller: controller.failureDescriptionController,
                  hintText: "Enter failure description",
                  maxLines: 3,
                  maxLength: 500,
                ),
                gap,
                _occDropdown(
                  label: "Department *",
                  options: controller.departmentList,
                  selected: controller.selectedDepartment,
                  onChanged: (v) async =>
                  await controller.onOccUpdateDepartmentChanged(v),
                ),
                gap,
                if (controller.isOccRoleUser) ...[
                  // OCC role can change Reported To / Line / Location Text.
                  _occRow(
                    _occDropdown(
                      label: "Reported To *",
                      options: controller.occReportedToList,
                      selected: controller.selectedOccReportedTo,
                      onChanged: controller.onOccReportedToChanged,
                    ),
                    _occDropdown(
                      label: "Line",
                      options: controller.occLineList,
                      selected: controller.selectedOccLine,
                      onChanged: (v) => controller.selectedOccLine.value = v,
                    ),
                  ),
                  gap,
                  CustomTextField(
                    label: "Location Text",
                    controller: controller.occLocationTextController,
                    hintText: "Enter Location Text",
                    maxLength: 100,
                  ),
                ] else
                  _occRow(
                    _occReadOnlyController(
                        "Line", controller.occLineDisplayController),
                    _occReadOnlyController(
                        "Location Text", controller.occLocationTextController),
                  ),
                gap,
                _occDropdown(
                  label: "Location",
                  options: controller.locationTypeList,
                  selected: controller.selectedLocation,
                  onChanged: (v) => controller.onOccUpdateLocationChanged(v),
                ),
                gap,
                Obx(() {
                  if (controller.isFunctionalLocationLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.orangeColor),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Loading functional locations...',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }
                  return CustDropdown(
                    label: "Functional Location",
                    hint: "Select...",
                    items: controller.functionalLocationList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue: controller.selectedFunctionalLocation.value,
                    onChanged: (v) =>
                        controller.onOccFunctionalLocationChanged(v),
                  );
                }),
                gap,
                CustomTextField(
                  label: "Sub Location",
                  controller: controller.subLocationController,
                  hintText: "Enter Sub Location",
                  maxLength: 100,
                ),
                gap,
                // OCC role picks them; FMC / TPC / CSS / RSC see what OCC set.
                controller.isOccRoleUser
                    ? _occSystemSubsystemFields()
                    : _occFixedSystemSubsystemFields(),
                Obx(() => controller.occIsStationFailure.value
                    ? const SizedBox.shrink()
                    : Padding(
                  padding:
                  const EdgeInsets.only(top: AppConstants.elementSpacing),
                  child: CustomTextField(
                    label: "Train Id",
                    controller: controller.trainIdController,
                    hintText: "Enter Train Id",
                    maxLength: 100,
                  ),
                )),
                gap,
                controller.isOccRoleUser
                    ? _occDropdown(
                  label: "Train Set",
                  options: controller.occTrainSetList,
                  selected: controller.selectedOccTrainSet,
                  onChanged: (v) =>
                  controller.selectedOccTrainSet.value = v,
                )
                    : _occReadOnlyController(
                        "Train Set", controller.occTrainSetDisplayController),
                gap,
                Obx(() => CustDateTimePicker(
                  label: controller.isOccRoleUser
                      ? "Actual Failure Occurrence *"
                      : "Actual Failure Occurrence",
                  hint: "DD/MM/YYYY hh:mm",
                  selectedDateTime:
                  controller.selectedFailureOccurrenceDate.value,
                  enabled: controller.isOccRoleUser,
                  lastDate: DateTime.now(),
                  onDateTimeSelected: (dt) => controller.isOccRoleUser
                      ? controller.selectedFailureOccurrenceDate.value = dt
                      : null,
                )),
                gap,
                _occDropdown(
                  label: "Failure Reported by",
                  options: controller.occReportedByList,
                  selected: controller.selectedFailureReportedBy,
                  onChanged: (v) =>
                  controller.selectedFailureReportedBy.value = v,
                ),
                gap,
                Obx(() => CustDateTimePicker(
                  label: controller.isOccRoleUser
                      ? "Actual Failure Completed Date & Time"
                      : "Actual Failure Completed Date & Time *",
                  hint: "DD/MM/YYYY hh:mm",
                  selectedDateTime:
                  controller.selectedFailureCompletedDate.value,
                  // OCC role: only when Reported To is OCC.
                  enabled: !controller.isOccRoleUser ||
                      controller.occReportedToIsOcc,
                  firstDate: controller.selectedFailureOccurrenceDate.value,
                  lastDate: DateTime.now(),
                  onDateTimeSelected: (dt) =>
                  controller.selectedFailureCompletedDate.value = dt,
                )),
                gap,
                _occDropdown(
                  label: "Failure Category Type *",
                  options: controller.occFailureCategoryList,
                  selected: controller.selectedFailureCategoryType,
                  onChanged: controller.onOccFailureCategoryChanged,
                ),
                Obx(() {
                  if (!controller.occIsCategoryOther) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(
                        top: AppConstants.elementSpacing),
                    child: CustomTextField(
                      label: "Other",
                      controller: controller.occCategoryOtherController,
                      hintText: "Enter Other Text",
                      maxLength: 250,
                    ),
                  );
                }),
              ],
            ),
          ),
          Obx(() => controller.occIsStationFailure.value
              ? const SizedBox.shrink()
              : _occTripSection()),
          _occPassengerSection(),
          CustSection(
            title: "Attachments",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustText.body("Before ", fontWeightName: FontWeight.w500),
                    const Text("(Max File Size 1MB)",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: AppConstants.sectionSpacing),
                    _buildUploadButton(controller.beforeFiles, enabled: true),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() => Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: controller.beforeFiles
                      .map<Widget>((file) => _buildAttachmentItem(
                      file['name']!,
                      file['size']!,
                      controller.beforeFiles,
                      file))
                      .toList(),
                )),
                Obx(() {
                  final any = controller.beforeImagesList.isNotEmpty ||
                      controller.afterImagesList.isNotEmpty ||
                      controller.rcaImagesList.isNotEmpty;
                  if (!any) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Divider(),
                  );
                }),
                _occImageGroup("Before:", controller.beforeImagesList),
                _occImageGroup("After:", controller.afterImagesList),
                _occImageGroup("RCA:", controller.rcaImagesList),
              ],
            ),
          ),
            ],
          )),
          if (controller.isOccRoleUser)
            // OCC role: Update, plus Update And Close when Reported To is OCC.
            // A closed failure is read-only.
            Obx(() {
              final closed = (controller.mainStatusName.value ?? '')
                  .toLowerCase()
                  .contains('close');
              if (closed || controller.occRoleViewOnly) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: CustOutlineButton(
                        name: "Update",
                        size: double.infinity,
                        sHeight: AppConstants.buttonHeight,
                        borderRadius: AppConstants.inputRadius,
                        onSelected: (_) => _occUpdateAction(
                            'update', 'Do you want to update failure?'),
                      ),
                    ),
                    if (controller.occReportedToIsOcc) ...[
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                        child: CustButton(
                          name: "Update And Close",
                          size: double.infinity,
                          sHeight: AppConstants.buttonHeight,
                          borderRadius: AppConstants.inputRadius,
                          onSelected: (_) => _occUpdateAction(
                              'close', 'Do you want to update and close?'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            })
          else
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.screenPadding),
            child: Column(
              children: [
                CustButton(
                  name: "Assign To Department",
                  size: double.infinity,
                  sHeight: AppConstants.buttonHeight,
                  borderRadius: AppConstants.inputRadius,
                  onSelected: (_) => _occUpdateAction(
                      'assign', 'Do you want to assign to department?'),
                ),
                const SizedBox(height: AppConstants.elementSpacing),
                Row(
                  children: [
                    Expanded(
                      child: CustOutlineButton(
                        name: "Save As Draft",
                        size: double.infinity,
                        sHeight: AppConstants.buttonHeight,
                        borderRadius: AppConstants.inputRadius,
                        onSelected: (_) => _occUpdateAction(
                            'draft', 'Do you want to save as draft?'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.elementSpacing),
                    Expanded(
                      child: CustButton(
                        name: "Update And Close",
                        size: double.infinity,
                        sHeight: AppConstants.buttonHeight,
                        borderRadius: AppConstants.inputRadius,
                        onSelected: (_) => _occUpdateAction(
                            'close', 'Do you want to save and close?'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOccCreateForm(BuildContext context) {
    const gap = SizedBox(height: AppConstants.elementSpacing);
    return Form(
      key: _occFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: CustText.sectionHeader(
                "Failure Details",
                color: AppColors.orangeColor,
              ),
            ),
            CustSection(
              title: "Failure Information",
              trailing: _buildExpandCollapseButton(),
              isVisible: controller.isBasicInfoVisible.value,
              child: Column(
                children: [
                  _occRow(
                    _occDropdown(
                      label: "Priority *",
                      options: controller.priorityTypeList,
                      selected: controller.selectedPriority,
                      onChanged: (v) => controller.selectedPriority.value = v,
                      requiredName: "Priority",
                    ),
                    _occDropdown(
                      label: "Department *",
                      options: controller.departmentList,
                      selected: controller.selectedDepartment,
                      onChanged: (v) async =>
                      await controller.onDepartmentChanged(v),
                      requiredName: "Department",
                    ),
                  ),
                  gap,
                  CustomTextField(
                    label: "Failure Description *",
                    controller: controller.failureDescriptionController,
                    hintText: "Enter failure description",
                    maxLines: 4,
                    maxLength: CreateFailureController.occDescriptionMaxLength,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Failure Description is required";
                      }
                      return null;
                    },
                  ),
                  gap,
                  _occDropdown(
                    label: "Location",
                    options: controller.locationTypeList,
                    selected: controller.selectedLocation,
                    onChanged: (v) => controller.onLocationChanged(v),
                  ),
                  gap,
                  Obx(() {
                    if (controller.isFunctionalLocationLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.orangeColor),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Loading functional locations...',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }
                    return CustDropdown(
                      label: "Functional Location",
                      hint: "Select...",
                      items: controller.functionalLocationList
                          .map((e) => e.label ?? '')
                          .toList(),
                      selectedValue: controller.selectedFunctionalLocation.value,
                      onChanged: (v) =>
                          controller.onOccFunctionalLocationChanged(v),
                    );
                  }),
                  gap,
                  _occRow(
                    _occDropdown(
                      label: "Reported To *",
                      options: controller.occReportedToList,
                      selected: controller.selectedOccReportedTo,
                      onChanged: controller.onOccReportedToChanged,
                      requiredName: "Reported To",
                    ),
                    _occDropdown(
                      label: "Line",
                      options: controller.occLineList,
                      selected: controller.selectedOccLine,
                      onChanged: (v) => controller.selectedOccLine.value = v,
                    ),
                  ),
                  gap,
                  CustomTextField(
                    label: "Location Text",
                    controller: controller.occLocationTextController,
                    hintText: "Enter Location Text",
                    maxLength: 100,
                  ),
                  gap,
                  CustomTextField(
                    label: "Sub Location",
                    controller: controller.subLocationController,
                    hintText: "Enter Sub Location",
                    maxLength: 100,
                  ),
                  gap,
                  // System and Sub System (both required on the web page).
                  _occSystemSubsystemFields(),
                  gap,
                  CustomTextField(
                    label: "Train Id",
                    controller: controller.trainIdController,
                    hintText: "Enter Train Id",
                    maxLength: 100,
                  ),
                  gap,
                  _occDropdown(
                    label: "Train Set",
                    options: controller.occTrainSetList,
                    selected: controller.selectedOccTrainSet,
                    onChanged: (v) => controller.selectedOccTrainSet.value = v,
                  ),
                  gap,
                  CustomTextField(
                    label: "Failure Frequency of Gear (Last 12 Months)",
                    controller: controller.occFailureFrequencyController,
                    hintText: "-",
                    enabled: false,
                  ),
                  gap,
                  Obx(() => CustDateTimePicker(
                    label: "Actual Failure Occurrence *",
                    hint: "DD/MM/YYYY hh:mm",
                    selectedDateTime:
                    controller.selectedFailureOccurrenceDate.value,
                    lastDate: DateTime.now(),
                    onDateTimeSelected: (dt) =>
                    controller.selectedFailureOccurrenceDate.value = dt,
                    validator: (val) {
                      if (controller.selectedFailureOccurrenceDate.value ==
                          null) {
                        return "Actual Failure Occurrence is required";
                      }
                      return null;
                    },
                  )),
                  gap,
                  _occDropdown(
                    label: "Failure Reported by *",
                    options: controller.occReportedByList,
                    selected: controller.selectedFailureReportedBy,
                    onChanged: (v) =>
                    controller.selectedFailureReportedBy.value = v,
                    requiredName: "Failure Reported by",
                  ),
                  gap,
                  // Enabled only when Reported To is OCC (then OCC can close).
                  Obx(() => CustDateTimePicker(
                    label: "Actual Failure Completed Date & Time",
                    hint: "DD/MM/YYYY hh:mm",
                    selectedDateTime:
                    controller.selectedFailureCompletedDate.value,
                    enabled: controller.occReportedToIsOcc,
                    firstDate: controller.selectedFailureOccurrenceDate.value,
                    lastDate: DateTime.now(),
                    onDateTimeSelected: (dt) =>
                    controller.selectedFailureCompletedDate.value = dt,
                  )),
                  gap,
                  _occDropdown(
                    label: "Failure Category Type *",
                    options: controller.occFailureCategoryList,
                    selected: controller.selectedFailureCategoryType,
                    onChanged: controller.onOccFailureCategoryChanged,
                    requiredName: "Failure Category Type",
                  ),
                  Obx(() {
                    if (!controller.occIsCategoryOther) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding:
                      const EdgeInsets.only(top: AppConstants.elementSpacing),
                      child: CustomTextField(
                        label: "Other *",
                        controller: controller.occCategoryOtherController,
                        hintText: "Enter Other Text",
                        maxLength: 250,
                        validator: (val) {
                          if (controller.occIsCategoryOther &&
                              (val == null || val.trim().isEmpty)) {
                            return "Other is required";
                          }
                          return null;
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            _occTripSection(),
            _occPassengerSection(),
            CustSection(
              title: "Attachments",
              child: Column(
                children: [
                  Row(
                    children: [
                      CustText.body("Before ", fontWeightName: FontWeight.w500),
                      const Text("(Max File Size 1MB)",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: AppConstants.sectionSpacing),
                      _buildUploadButton(controller.beforeFiles, enabled: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: controller.beforeFiles
                        .map<Widget>((file) => _buildAttachmentItem(
                        file['name']!,
                        file['size']!,
                        controller.beforeFiles,
                        file))
                        .toList(),
                  )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPadding),
              child: Obx(() => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustOutlineButton(
                          name: "Cancel",
                          size: double.infinity,
                          sHeight: AppConstants.buttonHeight,
                          borderRadius: AppConstants.inputRadius,
                          onSelected: (_) => _handleCancel(),
                        ),
                      ),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                        child: CustButton(
                          name: "Save",
                          size: double.infinity,
                          sHeight: AppConstants.buttonHeight,
                          borderRadius: AppConstants.inputRadius,
                          onSelected: (_) => _submitForm(),
                        ),
                      ),
                    ],
                  ),
                  // Only OCC-reported failures can be closed by OCC.
                  if (controller.occReportedToIsOcc) ...[
                    const SizedBox(height: AppConstants.elementSpacing),
                    CustButton(
                      name: "Save and Close",
                      size: double.infinity,
                      sHeight: AppConstants.buttonHeight,
                      borderRadius: AppConstants.inputRadius,
                      onSelected: (_) => _submitOccCreateAndClose(),
                    ),
                  ],
                ],
              )),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Read-only depot failure detail (DCC), loaded from getDepotFailureCreationById.
  Widget _buildDepotView(BuildContext context) {
    const gap = SizedBox(height: AppConstants.elementSpacing);
    return Obx(() {
      if (controller.errorMessage.value.isNotEmpty) {
        return Center(
            child: CustText(name: controller.errorMessage.value, size: 14));
      }
      final d = controller.depotDetail;
      if (d.isEmpty) return const SizedBox.shrink();

      String v(String k) {
        final s = d[k]?.toString().trim() ?? '';
        return (s == 'null') ? '' : s;
      }

      Widget field(String label, String value, {int maxLines = 1}) =>
          CustomTextField(
            label: label,
            controller: TextEditingController(text: value),
            maxLines: maxLines,
            enabled: false,
          );

      String yesNo(String k) => d[k] == true ? 'Yes' : 'No';

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: _buildFailureHeader(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPadding),
              child: _buildFailureNumberDisplay(
                  fallbackNotificationCode: v('failureId')),
            ),
            CustSection(
              title: "Failure Information",
              trailing: _buildExpandCollapseButton(),
              isVisible: controller.isBasicInfoVisible.value,
              child: Column(
                children: [
                  field("Priority", v('priority')),
                  gap,
                  field("Failure Description", v('failureDescription'),
                      maxLines: 3),
                  gap,
                  field("Department", v('departmentName')),
                  gap,
                  field("Location", v('location')),
                  gap,
                  field("Functional Location", v('funcationLocation')),
                  gap,
                  field("Sub Location", v('subLocation')),
                  gap,
                  field("System", v('system')),
                  gap,
                  field("Actual Failure Occurrence",
                      v('actualFailureOccuranceDate')),
                  gap,
                  field("Failure Reported by", v('failureReportedby')),
                  gap,
                  field("Actual Failure Completed Date & Time",
                      v('actualFailureCompletedDateTime')),
                  gap,
                  field("Failure Category Type",
                      v('failureCategoryTypeName')),
                  gap,
                  field("Status", v('statusName')),
                ],
              ),
            ),
            CustSection(
              title: "Trip Affected",
              isVisible: d['isTripAffected'] == true,
              trailing: CustText.body(yesNo('isTripAffected'),
                  fontWeightName: FontWeight.w600),
              child: Column(
                children: [
                  _occRow(field("Trip Delay Upline (NOS)", v('tripDelayUpline')),
                      field("Trip Cancel (NOS)", v('tripCancel'))),
                  gap,
                  _occRow(
                      field("Trip Delay Downline (NOS)", v('tripDelayDownline')),
                      field("Trip Delay in Min.", v('trainDelayInMin'))),
                  gap,
                  _occRow(
                      field("Trip Withdrawal (NOS)", v('noOfTranWithdrawal')),
                      field("Train Replace (NOS)", v('trainReplace'))),
                ],
              ),
            ),
            CustSection(
              title: "Passenger Affected",
              isVisible: d['isPassengerAffected'] == true,
              trailing: CustText.body(yesNo('isPassengerAffected'),
                  fontWeightName: FontWeight.w600),
              child: Column(
                children: [
                  field("Number Of Passenger Affected",
                      v('numberOfPassengerAffected')),
                  gap,
                  _occRow(field("Trapped Duration", v('trappedDuration')),
                      field("Rescued Duration", v('rescusedDuration'))),
                ],
              ),
            ),
            if (controller.depotImages.isNotEmpty)
              CustSection(
                title: "Attachments",
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: controller.depotImages
                      .map<Widget>((url) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ))
                      .toList(),
                ),
              ),
            if (controller.depotHistory.isNotEmpty)
              CustSection(
                title: "History",
                child: Column(
                  children: controller.depotHistory
                      .map<Widget>((h) => Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppConstants.elementSpacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustText.body(h['description']?.toString() ?? '',
                            fontWeightName: FontWeight.w500),
                        CustText(
                          name:
                          "${h['createdBy'] ?? ''}  •  ${h['createdOn'] ?? ''}",
                          size: 12,
                          color: AppColors.textDarkSecondary,
                        ),
                      ],
                    ),
                  ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      );
    });
  }

  /// Depot failure create form (DCC): fields match the web "Create Depot
  /// Failure" page. Dropdown data comes from the existing local master data.
  Widget _buildDepotCreateForm(BuildContext context) {
    const gap = SizedBox(height: AppConstants.elementSpacing);
    return Form(
      key: _depotFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: CustText.sectionHeader(
                "Failure Details",
                color: AppColors.orangeColor,
              ),
            ),
            CustSection(
              title: "Failure Information",
              trailing: _buildExpandCollapseButton(),
              isVisible: controller.isBasicInfoVisible.value,
              child: Column(
                children: [
                  _occDropdown(
                    label: "Priority *",
                    options: controller.priorityTypeList,
                    selected: controller.selectedPriority,
                    onChanged: (v) => controller.selectedPriority.value = v,
                    requiredName: "Priority",
                  ),
                  gap,
                  CustomTextField(
                    label: "Failure Description *",
                    controller: controller.failureDescriptionController,
                    hintText: "Enter failure description",
                    maxLines: 4,
                    maxLength: 500,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Failure Description is required";
                      }
                      return null;
                    },
                  ),
                  gap,
                  _occDropdown(
                    label: "Department *",
                    options: controller.departmentList,
                    selected: controller.selectedDepartment,
                    onChanged: (v) async =>
                    await controller.onDepartmentChanged(v),
                    requiredName: "Department",
                  ),
                  gap,
                  _occDropdown(
                    label: "Location *",
                    options: controller.locationTypeList,
                    selected: controller.selectedLocation,
                    onChanged: (v) => controller.onLocationChanged(v),
                    requiredName: "Location",
                  ),
                  gap,
                  Obx(() {
                    if (controller.isFunctionalLocationLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.orangeColor),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Loading functional locations...',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }
                    return CustDropdown(
                      label: "Functional Location",
                      hint: "Select...",
                      items: controller.functionalLocationList
                          .map((e) => e.label ?? '')
                          .toList(),
                      selectedValue: controller.selectedFunctionalLocation.value,
                      onChanged: (v) =>
                          controller.onOccFunctionalLocationChanged(v),
                    );
                  }),
                  gap,
                  CustomTextField(
                    label: "Sub Location",
                    controller: controller.subLocationController,
                    hintText: "Enter Sub Location",
                    maxLength: 100,
                  ),
                  gap,
                  Obx(() {
                    // Several systems for this functional location -> pick
                    // one; otherwise show the single system read-only.
                    final systems = controller.fmecaSystemList
                        .map((e) => e.label ?? '')
                        .toList();
                    if (systems.length > 1 &&
                        !controller.fmecaSystemReadOnly.value) {
                      return CustDropdown(
                        label: "System",
                        hint: "Select System",
                        items: systems,
                        selectedValue: controller.selectedFmecaSystem.value,
                        onChanged: (v) => controller.onOccSystemChanged(v),
                      );
                    }
                    return CustomTextField(
                      label: "System",
                      controller: controller.occSystemDisplayController,
                      hintText: "Select functional location",
                      enabled: false,
                    );
                  }),
                  gap,
                  Obx(() => CustDateTimePicker(
                    label: "Actual Failure Occurrence *",
                    hint: "DD/MM/YYYY hh:mm",
                    selectedDateTime:
                    controller.selectedFailureOccurrenceDate.value,
                    lastDate: DateTime.now(),
                    onDateTimeSelected: (dt) =>
                    controller.selectedFailureOccurrenceDate.value = dt,
                    validator: (val) {
                      if (controller.selectedFailureOccurrenceDate.value ==
                          null) {
                        return "Actual Failure Occurrence is required";
                      }
                      return null;
                    },
                  )),
                  gap,
                  _occDropdown(
                    label: "Failure Reported by *",
                    options: controller.userList,
                    selected: controller.selectedFailureReportedBy,
                    onChanged: (v) =>
                    controller.selectedFailureReportedBy.value = v,
                    requiredName: "Failure Reported by",
                  ),
                  gap,
                  Obx(() => CustDateTimePicker(
                    label: "Actual Failure Completed Date & Time",
                    hint: "DD/MM/YYYY hh:mm",
                    selectedDateTime:
                    controller.selectedFailureCompletedDate.value,
                    enabled: false,
                    onDateTimeSelected: (dt) =>
                    controller.selectedFailureCompletedDate.value = dt,
                  )),
                  gap,
                  _occDropdown(
                    label: "Failure Category Type *",
                    options: controller.corrNotificationTypeList,
                    selected: controller.selectedFailureCategoryType,
                    onChanged: (v) =>
                    controller.selectedFailureCategoryType.value = v,
                    requiredName: "Failure Category Type",
                  ),
                ],
              ),
            ),
            _occPassengerSection(showWayOfRescue: false),
            CustSection(
              title: "Attachments",
              child: Column(
                children: [
                  Row(
                    children: [
                      CustText.body("Before ", fontWeightName: FontWeight.w500),
                      const Text("(Max File Size 1MB)",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: AppConstants.sectionSpacing),
                      _buildUploadButton(controller.beforeFiles, enabled: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: controller.beforeFiles
                        .map<Widget>((file) => _buildAttachmentItem(
                        file['name']!,
                        file['size']!,
                        controller.beforeFiles,
                        file))
                        .toList(),
                  )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPadding),
              child: Row(
                children: [
                  Expanded(
                    child: CustOutlineButton(
                      name: "Cancel",
                      size: double.infinity,
                      sHeight: AppConstants.buttonHeight,
                      borderRadius: AppConstants.inputRadius,
                      onSelected: (_) => _handleCancel(),
                    ),
                  ),
                  const SizedBox(width: AppConstants.elementSpacing),
                  Expanded(
                    child: CustButton(
                      name: "Save",
                      size: double.infinity,
                      sHeight: AppConstants.buttonHeight,
                      borderRadius: AppConstants.inputRadius,
                      onSelected: (_) => _submitForm(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: _buildFailureHeader(),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppConstants.screenPadding,right: AppConstants.screenPadding,),
            child: _buildFailureNumberDisplay(),
          ),
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
                Obx(() => CustDateTimePicker(
                  label: "Actual Failure Occurrence",
                  hint: "Actual Failure Occurrence",
                  selectedDateTime:
                  controller.selectedFailureOccurrenceDate.value,
                  enabled: false,
                  onDateTimeSelected: (v) {},
                )),
                const SizedBox(height: AppConstants.elementSpacing),
                Obx(() => CustomTextField(
                    label: "Failure Reported by",
                    controller: TextEditingController(
                        text:
                        controller.selectedFailureReportedBy.value ??
                            ''),
                    enabled: false)),
                const SizedBox(height: AppConstants.elementSpacing),
                Obx(() => CustDateTimePicker(
                  label: "Actual Failure Completed Date & Time",
                  hint: "Actual Failure Completed Date & Time",
                  selectedDateTime:
                  controller.selectedFailureCompletedDate.value,
                  enabled: false,
                  onDateTimeSelected: (v) {},
                )),
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
          // CustSection(
          //   title: "Failure Rectification",
          //   child: CustomTextField(
          //     label: "Failure Rectification Details",
          //     controller: controller.failureRectificationDetailsController,
          //     maxLines: 4,
          //     enabled: false,
          //   ),
          // ),
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
            title: "Passenger Affected",
            isVisible: controller.isPassengerAffected.value,
            trailing: Obx(() => YesNoToggle(
              value: controller.isPassengerAffected.value,
              onChanged: (val) =>
              controller.isPassengerAffected.value = val,
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
                        appSnackbar("Error",
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
                        appSnackbar("Error", "Could not pick file.");
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
      appSnackbar(
        AppStrings.validationError,
        "Please fill all compulsory fields marked with *",
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// OCC create: "Save and Close" (completed date mandatory, StatusId 39).
  Future<void> _submitOccCreateAndClose() async {
    FocusScope.of(context).unfocus();
    if (!_validateForm(_occFormKey)) {
      appSnackbar(
        AppStrings.validationError,
        "Please fill all compulsory fields marked with *",
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await controller.createOccFailure(close: true);
  }

  void _submitForm() {
    if (_validateSubmitForms()) {
      if (_isOccCreate) {
        controller.createOccFailure();
        return;
      }
      if (_isDepotCreate) {
        controller.createDepotFailure();
        return;
      }
      if (widget.isUpdate && widget.failureType == 'Station') {
        controller.updateStationFailureDetails(widget.failureNo ?? "0");
        return;
      }
      // RCA validation only for Station failures, not Maintenance
      if (controller.isStation && controller.isRcaRequired.value) {
        final hasExistingRca = controller.rcaDetailsList
            .any((rca) => (rca['isNew'] ?? true) == false);
        final hasNewRca = controller.rcaDetailsList
            .any((rca) => (rca['isNew'] ?? true) == true);

        if (!hasExistingRca && !hasNewRca) {
          appSnackbar(
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
      appSnackbar(
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
                      if (!_isRcaReadOnly && !controller.isFormDisabled)
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
            if (!_isRcaReadOnly)
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
              if (!_isRcaReadOnly)
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
  })
  {
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
  })
  {
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
                                appSnackbar(
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
                            validator: (val) => FormValidators.requiredText(
                                val, 'Used Quantity'),
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
                          validator: (v) =>
                              FormValidators.requiredDropdown(
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
