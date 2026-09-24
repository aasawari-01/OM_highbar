import 'package:dart_des/dart_des.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../constants/app_constants.dart';
import '../../../constants/colors.dart';
import '../../../constants/strings.dart';
import '../../../core/models/cause_of_failure.dart';
import '../../../core/models/label_value.dart';
import '../../../core/models/measurement_point.dart';
import '../../../core/models/root_cause.dart';
import '../../../service/auth_manager.dart';
import '../../../service/local_database_service.dart';
import '../../../service/master_data_sync_service.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../service/network_service/api_client.dart';
import '../../../core/controller/session_controller.dart';
import '../../../core/controller/global_master_data_controller.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_popup.dart';
import '../../../utils/network_utils.dart';
import '../../auth_login/model/login_response.dart';
import '../model/failure_detail_response.dart';
import '../model/joint_inspection_history.dart';
import '../model/failure_list_response.dart';
import '../view/maintenance_history_screen.dart';
import 'failure_list_controller.dart';
import '../../../core/models/functional_location.dart';
import '../../../core/models/equipment.dart';
import '../service/failure_service.dart';
import 'failure_form_state.dart';
import 'failure_rca_logic.dart';
import 'failure_material_logic.dart';
import 'failure_submit_logic.dart';
import 'failure_joint_inspection_logic.dart';
import 'failure_data_loading_logic.dart';
import 'failure_ui_helper_logic.dart';

class CreateFailureController extends GetxController with FailureFormState, FailureRcaLogic, FailureMaterialLogic, FailureSubmitLogic, FailureJointInspectionLogic, FailureDataLoadingLogic, FailureUIHelperLogic {
  final FailureService _failureService = FailureService();

  /// Shows a validation error snackbar with the first error.
  void _showErrorDialog(String message) {
    final lines = message.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;
    Get.snackbar(
      'Validation Error',
      lines.first,
      backgroundColor: AppColors.red.withValues(alpha: 0.9),
      colorText: AppColors.white1,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void showErrorDialog(String message) {
    _showErrorDialog(message);
  }

  @override
  void showPendingJointInspectionPopup() {
    Get.dialog(
      CustPopup(
        title: 'Joint Inspection Pending',
        message: 'Joint inspection is pending. Please close this first.',
        showIcon: true,
        icon: Icons.error_outline,
        iconColor: AppColors.darkRed,
        confirmText: 'OK',
        onCancel: () {
          selectedUserStatus.value="Select User status";
          Get.back();
        },
        onConfirm: () {
          selectedUserStatus.value="Select User status";
          Get.back();
        },
      ),
      barrierDismissible: false,
    );
  }

  /// Refreshes the appropriate failure list controller based on user role and failure type
  @override
  void refreshFailureListAfterSubmission(bool isStation) {
    final session = Get.find<SessionController>();
    final role = session.selectedRole.value?.roleDescr ?? '';
    final isJE = role.contains('Junior Engineer');
    final isStationController = role.contains('Station Controller');

    if (isStationController) {
      // For Station Controller, call API to get updated station failure list
      if (Get.isRegistered<MasterDataSyncService>()) {
        Future.microtask(() async {
          try {
            // Call API to sync station failure list with latest data from server
            await Get.find<MasterDataSyncService>().syncFailureList('Station', forceFullSync: true);
            // Refresh the UI controller to show the updated list
            if (Get.isRegistered<FailureListController>(tag: 'Station')) {
              await Get.find<FailureListController>(tag: 'Station').fetchFailures();
            }
            debugPrint("refreshFailureListAfterSubmission: Successfully synced station failure list from API");
          } catch (e) {
            debugPrint("Error syncing failure list after creation: $e");
          }
        });
      }
    } else if (isJE) {
      // For JE users, refresh the appropriate controller based on failure type
      final controllerTag = isStation ? 'Station' : 'Maintenance';
      if (Get.isRegistered<FailureListController>(tag: controllerTag)) {
        Future.microtask(() async {
          try {
            await Get.find<FailureListController>(tag: controllerTag).fetchFailures();
          } catch (e) {
            debugPrint("Error refreshing JE failure list: $e");
          }
        });
      }
    }
  }

  void onFailureAttendedDateSelected(DateTime? date) {
    selectedFailureAttendedDate.value = date;
    if (selectedActualFailureRectifiedDate.value != null && date != null) {
      if (selectedActualFailureRectifiedDate.value!.isBefore(date)) {
        selectedActualFailureRectifiedDate.value = null;
      }
    }
  }

  void onActualFailureRectifiedDateSelected(DateTime? date) {
    selectedActualFailureRectifiedDate.value = date;
    if (date == null || selectedFailureOccurrenceDate.value == null) {
      showReasonForDelayPopup.value = false;
      reasonForDelayId.value = 0;
      selectedReasonForDelay.value = null;
      return;
    }

    final duration = date.difference(selectedFailureOccurrenceDate.value!);
    final isCritical = selectedPriority.value?.toLowerCase() == "critical";

    if (isCritical) {
      if (duration.inHours >= 3) {
        if (reasonForDelayId.value == 0) {
          showReasonForDelayPopupDialog();
        }
      } else {
        reasonForDelayId.value = 0;
        selectedReasonForDelay.value = null;
      }
    } else {
      if (duration.inDays >= 1) {
        if (reasonForDelayId.value == 0) {
          showReasonForDelayPopupDialog();
        }
      } else {
        reasonForDelayId.value = 0;
        selectedReasonForDelay.value = null;
      }
    }
  }

  void showReasonForDelayPopupDialog() {
    Get.dialog(
      CustPopup(
        title: "Reason For Delay",
        showIcon: true,
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.orangeColor,
        customContent: Obx(
              () => CustDropdown(
            label: "Reason For Delay *",
            hint: "Select Reason For Delay",
            items: reasonForDelayList.map((e) => e.label ?? "").toList(),
            selectedValue: selectedReasonForDelay.value,
            onChanged: (value) {
              selectedReasonForDelay.value = value;

              final match = reasonForDelayList.firstWhere(
                    (e) => e.label == value,
                orElse: () => LabelValue(value: "0"),
              );

              reasonForDelayId.value =
                  int.tryParse(match.value ?? "0") ?? 0;
            },
          ),
        ),

        confirmText: "Save",
        cancelText: "Cancel",

        onConfirm: () {
          Get.back();
        },

        onCancel: () {
          selectedActualFailureRectifiedDate.value = null;
          Get.back();
        },
      ),
      barrierDismissible: false,
    );
  }




  @override
  void onInit() {
    super.onInit();
    _globalData = Get.find<GlobalMasterDataController>();
    _initializeAllData();
  }

  Future<void> _initializeAllData() async {
    try {
      // Ensure global data is loaded
      if (!_globalData.isLoaded) {
        await _globalData.loadMasterData();
      }

      // Copy global data to local lists
      _copyGlobalDataToLocal(_globalData);

      debugPrint("_initializeAllData: userList count after load = ${userList.length}");

      // Auto-select logged-in user in "Failure Reported By" field
      await _autoSelectFailureReportedBy();

      await fetchMasterJointInspectionDepartments();
    } catch (e) {
      debugPrint("Error in _initializeAllData: $e");
    }
  }

  void _copyGlobalDataToLocal(GlobalMasterDataController globalData) {
    priorityTypeList.assignAll(globalData.priorityTypeList);
    locationTypeList.assignAll(globalData.locationTypeList);
    functionalLocationList.assignAll(globalData.functionalLocationList);
    equipmentList.assignAll(globalData.equipmentList);
    departmentList.assignAll(globalData.departmentList);
    userList.assignAll(globalData.userList);
    corrNotificationTypeList.assignAll(globalData.corrNotificationTypeList);
    storageLocationList.assignAll(globalData.storageLocationList);
    reasonForDelayList.assignAll(globalData.reasonForDelayList);
    objectDataList.assignAll(globalData.objectDataList);
    rootCauseList.assignAll(globalData.rootCauseList);
    causeList.assignAll(globalData.causeList);
    actionList.assignAll(globalData.actionList);
    rcaFailureCategoryList.assignAll(globalData.rcaFailureCategoryList);

    // NEW: Copy JE view data from asset DB
    corrFailureTypeList.assignAll(globalData.corrFailureTypeList);
    userStatusJeList.assignAll(globalData.userStatusJeList);
    materialMasterList.assignAll(globalData.materialMasterList);

    // NEW: Copy RST view data from asset DB
    rstFaultMasterList.assignAll(globalData.rstFaultMasterList);
    rstOldRootCauseList.assignAll(globalData.rstOldRootCauseList);
    rstStoreLocationList.assignAll(globalData.rstStoreLocationList);

    masterLocations.assignAll(globalData.masterLocations);
    masterFunctionalLocations.assignAll(globalData.masterFunctionalLocations);
    masterEquipments.assignAll(globalData.masterEquipments);
    masterDepartments.assignAll(globalData.masterDepartments);
    masterRootCauses.assignAll(globalData.masterRootCauses);
    masterCauseOfFailures.assignAll(globalData.masterCauseOfFailures);
    masterRcaFailureCategories.assignAll(globalData.masterRcaFailureCategories);

    // Debug logging for masterDepartments
    debugPrint("_copyGlobalDataToLocal: masterDepartments count = ${masterDepartments.length}");
    if (masterDepartments.isNotEmpty) {
      debugPrint("_copyGlobalDataToLocal: Sample masterDepartments data:");
      for (int i = 0; i < masterDepartments.length && i < 3; i++) {
        final dept = masterDepartments[i];
        debugPrint("  [$i] DeptName: ${dept['DeptName']}, DeptId: ${dept['DeptId']}");
      }
    }

    // Load master users on-demand if not already loaded
    if (masterUsers.isEmpty) {
      _loadMasterUsersOnDemand();
    } else {
      masterUsers.assignAll(globalData.masterUsers);
    }
  }

  Future<void> _loadMasterUsersOnDemand() async {
    // Only load if not already loaded
    if (isUsersLoaded.value && masterUsers.isNotEmpty) {
      debugPrint('_loadMasterUsersOnDemand: Users already loaded, skipping');
      return;
    }

    debugPrint('_loadMasterUsersOnDemand: Loading master users from SQLite');
    final dbService = LocalDatabaseService();
    final users = await dbService.getMasterUsers();

    // Convert users to Map with consistent key names (PascalCase as in MasterUserModel.toJson())
    masterUsers.assignAll(users.map((e) => e.toJson()).toList());
    isUsersLoaded.value = true;
    debugPrint('_loadMasterUsersOnDemand: Loaded ${users.length} master users');

    // Show sample data for debugging - show both PascalCase and camelCase keys
    if (masterUsers.isNotEmpty) {
      debugPrint('_loadMasterUsersOnDemand: Sample user data:');
      for (int i = 0; i < masterUsers.length && i < 3; i++) {
        final user = masterUsers[i];
        debugPrint('  [$i] UserId: ${user['UserId']}, UserName: ${user['UserName']}, DeptId: ${user['DeptId']}, RoleDescr: ${user['RoleDescr']}');
        debugPrint('      camelCase: userName: ${user['userName']}, deptId: ${user['deptId']}, roleDescr: ${user['roleDescr']}');
      }
    }

    // Force UI update
    masterUsers.refresh();
  }



  // Reference to global master data to avoid redundant DB calls
  late final GlobalMasterDataController _globalData;

  @override
  void onClose() {
    dispose();
    super.onClose();
  }

  @override
  int resolveNotificationId() {
    if (notificationId.value > 0) return notificationId.value;
    return int.tryParse(encryptedId.value) ?? 0;
  }

  final popupStationList = <LabelValue>[].obs;
  final isPopupStationLoading = false.obs;
  final session = Get.find<SessionController>();


  Future<void> fetchAndShowStationPopup() async {
    isPopupStationLoading.value = true;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white1,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDarkSecondary,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(15),
            child: Obx(() {
              if (isPopupStationLoading.value) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CustLoader(),
                    const SizedBox(height: 16),
                    const Text("Fetching stations...", style: TextStyle(color: AppColors.textDarkSecondary)),
                  ],
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.back();
                      },
                      child: const Icon(TablerIcons.x, color: AppColors.textDarkPrimary, size: 24),
                    ),
                  ),
                  CustText(name: "Select Station", size: AppConstants.headerSize, color: AppColors.black, fontWeightName: FontWeight.w600),
                  const SizedBox(height: 16),
                  CustDropdown(
                    label: "Station",
                    hint: "Select Station",
                    items: popupStationList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue: session.selectedStationName.value,
                    onChanged: (val) {
                      session.selectedStationName.value = val;
                      session.selectedStationId.value = popupStationList
                          .firstWhere((e) => e.label == val,
                          orElse: () => LabelValue(value: "0"))
                          .value;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: CustOutlineButton(
                          name: "Cancel",
                          size: double.infinity,
                          sHeight: 35,
                          onSelected: (_) {
                            Get.back();
                            Get.back();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustButton(
                          name: "OK",
                          size: double.infinity,
                          sHeight: 35,
                          onSelected: (_) {
                            if (session.selectedStationName.value != null && session.selectedStationName.value!.isNotEmpty) {
                              Get.back();
                            } else {
                              Get.snackbar(AppStrings.error, "Please select a station",
                                backgroundColor: AppColors.red.withValues(alpha: 0.9),
                                colorText: AppColors.white1,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final stations = await _failureService.getStationNames();
      popupStationList.assignAll(stations);
    } catch (e) {
      debugPrint('Error fetching stations: $e');
    } finally {
      isPopupStationLoading.value = false;
    }
  }

  Future<void> loadJointInspectionDetails(String failureNo) async {
    encryptedId.value = failureNo;
    notificationId.value = 0;
    jointInspectionFailureNo.value = "";
    try {
      isLoading.value = true;
      errorMessage.value = "";

      // Joint Inspection API disabled - manage from frontend
      // Load from local data or use existing failure details
      debugPrint("loadJointInspectionDetails: API disabled, loading from local data");
      errorMessage.value = "Joint Inspection details loaded from local data";

      // Load master data from DB
      await loadMasterDataFromDb();
      await loadFunctionalLocationsOnDemand();

    } catch (e) {
      errorMessage.value = "An error occurred: $e";
      debugPrint("loadJointInspectionDetails error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitJointInspection() async {
    if (selectedJiFunctionalLocation.value == null || selectedJiFunctionalLocation.value!.isEmpty) {
      Get.snackbar(
        AppStrings.validationError,
        "Please select Functional Location.",
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (jiUserRemarkController.text.trim().isEmpty) {
      Get.snackbar(
        AppStrings.validationError,
        "Please enter User's Remark.",
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      EasyLoading.show(status: 'Submitting...');

      // Joint Inspection API disabled - manage from frontend
      // Add to local history and return success
      debugPrint("submitJointInspection: API disabled, managing from frontend");

      // Add to joint inspection history list
      final String? userIdStr = await AuthManager().getUserId();
      final String? userName = await AuthManager().getUserName();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;

      jointInspectionHistoryList.add(JointInspectionHistory(
        jiId: DateTime.now().millisecondsSinceEpoch,
        remark: jiUserRemarkController.text.trim(),
        assignedTo: int.tryParse(jiAssignTo.value ?? "0"),
        deptId: int.tryParse(jiDepartment.value ?? "0") ?? 0,
        notificationId: resolveNotificationId(),
        createdBy: userId,
        createdByName: userName ?? "",
        type: "AddNewJointInspection",
      ));

      Get.back(result: true);
      Get.snackbar(AppStrings.success, "Joint Inspection added successfully",
          backgroundColor: AppColors.green,
          colorText: AppColors.white1,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(AppStrings.error, e.toString());
    } finally {
      EasyLoading.dismiss();
    }
  }


  Future<void> loadFailureDetails(String failureNo) async {
    encryptedId.value = failureNo;
    notificationId.value = 0;
    jointInspectionHistoryList.clear();
    pushLoading();
    try {
      isLoading.value = true;
      errorMessage.value = "";

      // Clear only specific lists that need to be refreshed
      locationTypeList.clear();
      functionalLocationList.clear();
      equipmentList.clear();

      // Load master data (small tables only - large tables loaded on-demand)
      await loadMasterDataFromDb();

      // Skip loading functional locations during screen init - load lazily when dropdown opens
      // This prevents UI blocking with 84,609 functional locations

      // JE change notification API call for online flow
      final result = await _failureService.getFailureDetails(failureNo);

      if (result.responseCode == 200 && result.responseOutput != null) {
        final output = result.responseOutput!;
        final failureDetailResponse = result;

        // Skip dropdowns from API - use local data instead (much faster, no memory issues)
        // All dropdowns are already loaded from local DB in _copyGlobalDataToLocal()
        // notificationTypeList.assignAll(corrNotificationTypeList);
        // natureOfWorkList.assignAll(output.getNatureOfWorkList ?? []);
        // departmentList.assignAll(output.getDepartmentList ?? []);
        // userList.assignAll(output.getUserList ?? []);
        // objectDataList.assignAll(output.getObjectData ?? []);
        // materialDataList.assignAll(output.getMaterialData ?? []);
        // reasonForDelayList.assignAll(output.getReasonForDelayList ?? []);
        // final statuses = output.getUserStatus ?? [];
        // userStatusList.assignAll(statuses.where((status) {
        //   final val = int.tryParse(status.value ?? "999") ?? 999;
        //   return val == 0 || val <= 29;
        // }).toList());
        // storageLocationList.assignAll(output.getStorageLocation ?? []);
        // faultTypeList.assignAll(output.getFaultData ?? []);
        // _mergeLocationDropdownsFromOutput(output);

        // Keep only essential API data that's not available locally
        notificationHistoryList.assignAll(
            output.getNotificationActionUserHistory ?? []);

        notificationDescriptionHistoryList.assignAll(
            output.getNotificationHistory ?? []);

        if (output.getJoinInspectionHistory != null) {
          jointInspectionHistoryList.assignAll(
              output.getJoinInspectionHistory!
                  .map((item) => JointInspectionHistory.fromJson(item))
                  .toList()
          );
        }

        // Parse FailureRectificationJson from top-level response if available
        bool rcaLoadedFromOutput = false;
        String? rcaJsonSource = failureDetailResponse.failureRectificationJson ??
            output.getCreateVMModel?.failureRectificationJson;

        debugPrint("=== RCA JSON SOURCE CHECK ===");
        debugPrint("failureDetailResponse.failureRectificationJson: ${failureDetailResponse.failureRectificationJson?.length ?? 0} chars");
        debugPrint("failureDetailResponse.failureRectificationJson value: '${failureDetailResponse.failureRectificationJson}'");
        debugPrint("output.getCreateVMModel?.failureRectificationJson: ${output.getCreateVMModel?.failureRectificationJson?.length ?? 0} chars");
        debugPrint("output.getCreateVMModel?.failureRectificationJson value: '${output.getCreateVMModel?.failureRectificationJson}'");
        debugPrint("Final rcaJsonSource: ${rcaJsonSource?.length ?? 0} chars");
        debugPrint("Final rcaJsonSource value: '${rcaJsonSource}'");

        if (output.getCreateVMModel != null) {
          final model = output.getCreateVMModel!;
          encryptedId.value = (model.id != null && model.id!.isNotEmpty)
              ? model.id!
              : failureNo;
          notificationId.value = model.notificationId ?? 0;
          notificationCode.value = model.notificationCode ?? "";
          if (model.category != null && model.category!.trim().isNotEmpty) {
            failureCategory.value = model.category!.trim();
          }

          // Populate system and subsystem from API response if available
          if (model.systems != null && model.systems!.isNotEmpty) {
            systemController.text = model.systems!;
            debugPrint("System set from model: '${model.systems}'");
          }
          if (model.subSystems != null && model.subSystems!.isNotEmpty) {
            subsystemController.text = model.subSystems!;
            debugPrint("Subsystem set from model: '${model.subSystems}'");
          } else {
            debugPrint("Subsystem is null or empty in model");
          }

          // Parse FailureRectificationJson after system/subsystem are populated
          if (rcaJsonSource != null && rcaJsonSource.isNotEmpty) {
            try {
              debugPrint("=== RCA LOADING START ===");
              debugPrint("failureRectificationJson source: ${rcaJsonSource.length} chars");

              dynamic decoded;
              if (rcaJsonSource.startsWith('[')) {
                decoded = jsonDecode(rcaJsonSource);
              } else {
                // Fallback: try to parse as-is in case it's already a list
                decoded = rcaJsonSource;
              }
              debugPrint("Decoded FailureRectificationJson type: ${decoded.runtimeType}");
              if (decoded is List) {
                final parsedRca = List<Map<String, dynamic>>.from(decoded);
                debugPrint("RCA Data Check - Parsed FailureRectificationJson: ${parsedRca.length} items");
                debugPrint("First RCA item: ${parsedRca.isNotEmpty ? parsedRca[0] : 'empty'}");

                // Parse JE format RCA data
                rcaDetailsList.clear();

                // Get system and subsystem from parent model if available
                final parentSystem = model.systems ?? "";
                final parentSubsystem = model.subSystems ?? "";
                debugPrint("Parent system: '$parentSystem', subsystem: '$parentSubsystem'");
                debugPrint("Parent subsystem length: ${parentSubsystem.length}");
                debugPrint("Controller subsystemController.text: '${subsystemController.text}'");

                for (var fault in parsedRca) {
                  debugPrint("Processing fault item: $fault");
                  final List<Map<String, dynamic>> rootCauses = [];
                  // Support both PascalCase and camelCase field names
                  final rootCauseId = fault['rootCauseId'] ?? fault['RootCauseId'];
                  final causeOfFailureId = fault['causeOfFailureId'] ?? fault['CauseOfFailureId'];
                  debugPrint("rootCauseId: $rootCauseId, causeOfFailureId: $causeOfFailureId");
                  if (rootCauseId != null && int.tryParse(rootCauseId.toString()) != 0) {
                    rootCauses.add({
                      'causeId': causeOfFailureId?.toString() ?? "0",
                      'cause': fault['cause'] ?? fault['Cause'] ?? "",
                      'rootCauseId': rootCauseId?.toString() ?? "0",
                      'rootCause': fault['rootCause'] ?? fault['RootCause'] ?? "",
                      'causeText': fault['rootCauseText'] ?? fault['RootCauseText'] ?? "",
                      'imagePath': null
                    });
                    debugPrint("Added root cause: ${rootCauses.last}");
                  }

                  final List<Map<String, dynamic>> actionTakens = [];
                  // Support both PascalCase and camelCase field names
                  final actionTakenId = fault['actionTakenId'] ?? fault['ActionTakenId'];
                  debugPrint("actionTakenId: $actionTakenId");
                  if (actionTakenId != null && int.tryParse(actionTakenId.toString()) != 0) {
                    actionTakens.add({
                      'actionTakenId': actionTakenId?.toString() ?? "0",
                      'actionTaken': fault['actionTaken'] ?? fault['ActionTaken'] ?? "",
                      'actionTakenText': fault['actionTakenText'] ?? fault['ActionTakenText'] ?? "",
                      'imagePath': null
                    });
                    debugPrint("Added action taken: ${actionTakens.last}");
                  }

                  // Use system/subsystem from fault item if available, otherwise use parent values
                  // If parent values are empty, use the controller's text fields as fallback
                  final systemValue = fault['system'] ?? fault['System'] ?? parentSystem ?? systemController.text;
                  final subsystemValue = fault['subsystem'] ?? fault['SubSystem'] ?? parentSubsystem ?? subsystemController.text;

                  // Look up failure category name from master data if not provided in the item
                  final failureCategoryId = (fault['failureCategoryId'] ?? fault['FailureCategoryId'])?.toString() ?? "0";
                  String failureCategoryName = fault['failureCategoryText'] ?? fault['FailureCategoryText'] ?? "";
                  if (failureCategoryName.isEmpty && failureCategoryId != "0") {
                    // Look up from rcaFailureCategoryList (List<LabelValue>)
                    final categoryMatch = rcaFailureCategoryList.firstWhere(
                          (cat) => cat.value?.toString() == failureCategoryId,
                      orElse: () => LabelValue(label: "", value: ""),
                    );
                    if (categoryMatch.label != null && categoryMatch.label!.isNotEmpty) {
                      failureCategoryName = categoryMatch.label!;
                      debugPrint("Looked up failure category name: '$failureCategoryName' for ID: $failureCategoryId");
                    }
                  }

                  final rcaItem = {
                    'system': systemValue,
                    'subsystem': subsystemValue,
                    'FailureCategoryId': failureCategoryId,
                    'failureCategory': failureCategoryName,
                    'rootCauses': rootCauses,
                    'actionTakens': actionTakens,
                    // RST fields (empty for JE format)
                    'ObjectPartId': "0",
                    'objectPart': "",
                    'objectPartText': "",
                    'FaultId': "0",
                    'fault': "",
                    'faultText': "",
                  };
                  debugPrint("Adding RCA item to list: $rcaItem");
                  rcaDetailsList.add(rcaItem);
                }
                debugPrint("RCA data loaded from FailureRectificationJson: ${rcaDetailsList.length} items");
                rcaLoadedFromOutput = true;
                debugPrint("=== RCA LOADING END ===");
              }
            } catch (e) {
              debugPrint("RCA Data Check - Failed to parse FailureRectificationJson: $e");
            }
          } else {
            debugPrint("FailureRectificationJson is null or empty in all sources");
          }

          await _applyLocationSelectionsFromModel(model, output: output);
          selectedDepartment.value = departmentList
              .firstWhere(
                  (e) =>
              e.value == model.deptId?.toString() ||
                  e.label == model.deptCode,
              orElse: () => LabelValue(label: model.deptCode))
              .label;

          _refilterFunctionalLocationForCurrentSelections();
          _refilterEquipmentForCurrentSelections();
          await filterRcaFailureCategoriesBySystem();
          final funcLocEntry = masterFunctionalLocations.firstWhere(
                (e) =>
            e['funcLocId']?.toString() == model.functionLocationId?.toString() ||
                e['funcLocation']?.toString() == model.funcLocation?.toString(),
            orElse: () => <String, dynamic>{},
          );
          if (funcLocEntry.isNotEmpty) {
            final objectNumber = funcLocEntry['objectNumber']?.toString();
            final objectKey = funcLocEntry['objectKey']?.toString();
            final valueToUse = (objectNumber != null && objectNumber.isNotEmpty) ? objectNumber : objectKey;
            await _checkMeasurementPoints(valueToUse);
          }
          subLocationController.text = model.locationFailure ?? "";

          selectedPriority.value = model.priorityType;
          selectedDepartment.value = departmentList
              .firstWhere(
                  (e) =>
              e.value == model.deptId?.toString() ||
                  e.label == model.deptCode,
              orElse: () => LabelValue(label: model.deptCode))
              .label;
          await filterRcaFailureCategoriesBySystem();

          // Use corrNotificationTypeList from local DB for selection
          selectedNotificationType.value = corrNotificationTypeList
              .firstWhere(
                  (e) => e.value == model.corrNotificationTypeId.toString(),
              orElse: () => corrNotificationTypeList.isNotEmpty ? corrNotificationTypeList.first : LabelValue(label: null))
              .label;

          mainStatusName.value = model.mainStatusName;
          final matchedUserStatus = output.getUserStatus?.firstWhere(
                  (e) => e.value == model.userStatus.toString(),
              orElse: () => LabelValue(label: null));
          selectedUserStatus.value = matchedUserStatus?.label;

          if (model.assignedUserId != null) {
            final matchedUser = userList.firstWhere(
                    (e) =>
                e.value?.toString().trim() ==
                    model.assignedUserId.toString().trim(),
                orElse: () => LabelValue(label: null));
            selectedPersonResponsible.value = matchedUser.label;
          } else {
            selectedPersonResponsible.value = null;
          }

          // Only load RCA from model if not already loaded from output
          if (!rcaLoadedFromOutput) {
            debugPrint("RCA Data Check - getObjectANDFaultList: ${output.getObjectANDFaultList?.length ?? 0} items");
            debugPrint("RCA Data Check - getObjectANDFaultRootCauseList: ${output.getObjectANDFaultRootCauseList?.length ?? 0} items");
            debugPrint("RCA Data Check - getObjectANDFaultActionList: ${output.getObjectANDFaultActionList?.length ?? 0} items");
            debugPrint("RCA Data Check - model.getObjectANDFaultList: ${model.getObjectANDFaultList?.length ?? 0} items");
            debugPrint("RCA Data Check - model.failureRectificationDetails: ${model.failureRectificationDetails?.length ?? 0} chars");
            debugPrint("RCA Data Check - model.failureRectificationDetails value: '${model.failureRectificationDetails}'");
            debugPrint("RCA Data Check - model.failureRectificationJson: ${model.failureRectificationJson?.length ?? 0} chars");
            debugPrint("RCA Data Check - model.failureRectificationJson value: '${model.failureRectificationJson}'");
            debugPrint("RCA Data Check - failureDetailResponse.failureRectificationJson: ${failureDetailResponse.failureRectificationJson?.length ?? 0} chars");
            debugPrint("RCA Data Check - failureDetailResponse.failureRectificationJson value: '${failureDetailResponse.failureRectificationJson}'");

            // Try to parse failureRectificationDetails as JSON if it's not empty
            List<Map<String, dynamic>>? parsedFailureRectification;
            if (model.failureRectificationDetails != null &&
                model.failureRectificationDetails!.isNotEmpty &&
                model.failureRectificationDetails!.length > 5) {
              try {
                final decoded = jsonDecode(model.failureRectificationDetails!);
                if (decoded is List) {
                  parsedFailureRectification = List<Map<String, dynamic>>.from(decoded);
                  debugPrint("RCA Data Check - Parsed failureRectificationDetails as list: ${parsedFailureRectification.length} items");
                } else if (decoded is Map) {
                  debugPrint("RCA Data Check - failureRectificationDetails is a Map, keys: ${decoded.keys}");
                }
              } catch (e) {
                debugPrint("RCA Data Check - Failed to parse failureRectificationDetails: $e");
              }
            }

            // Try to load from model.getObjectANDFaultList if output doesn't have it
            final faultList = output.getObjectANDFaultList ?? model.getObjectANDFaultList ?? parsedFailureRectification;
            final rootCauseList = output.getObjectANDFaultRootCauseList ?? model.getObjectANDFaultRootCauseList;
            final actionList = output.getObjectANDFaultActionList ?? model.getObjectANDFaultActionList;

            // Try to parse FailureRectificationJson from top-level response or model
            debugPrint("=== MODEL RCA LOADING START ===");
            List<Map<String, dynamic>>? parsedFailureRectificationJson;
            final failureRectificationJsonSource = failureDetailResponse.failureRectificationJson ?? model.failureRectificationJson;
            debugPrint("failureRectificationJsonSource from model: $failureRectificationJsonSource");
            if (failureRectificationJsonSource != null && failureRectificationJsonSource!.isNotEmpty) {
              try {
                final decoded = jsonDecode(failureRectificationJsonSource!);
                debugPrint("Decoded model FailureRectificationJson type: ${decoded.runtimeType}");
                if (decoded is List) {
                  parsedFailureRectificationJson = List<Map<String, dynamic>>.from(decoded);
                  debugPrint("RCA Data Check - Parsed FailureRectificationJson as list: ${parsedFailureRectificationJson.length} items");
                  if (parsedFailureRectificationJson.isNotEmpty) {
                    debugPrint("First model RCA item: ${parsedFailureRectificationJson[0]}");
                  }
                }
              } catch (e) {
                debugPrint("RCA Data Check - Failed to parse FailureRectificationJson: $e");
              }
            } else {
              debugPrint("failureRectificationJsonSource is null or empty");
            }

            // Use FailureRectificationJson if available, otherwise use the other lists
            final finalFaultList = parsedFailureRectificationJson ?? faultList;
            debugPrint("finalFaultList type: ${finalFaultList?.runtimeType}, length: ${finalFaultList?.length ?? 0}");
            debugPrint("=== MODEL RCA LOADING END ===");

            if (finalFaultList != null) {
              debugPrint("=== FINAL RCA LOADING START ===");
              debugPrint("Loading RCA data from API: ${finalFaultList.length} items");
              if (finalFaultList.isNotEmpty) {
                debugPrint("First item keys: ${finalFaultList[0].keys}");
                debugPrint("First item: ${finalFaultList[0]}");
              }
              rcaDetailsList.clear();

              // Check if this is JE format (from FailureRectificationJson) or RST format (from getObjectANDFaultList)
              final isJEFormat = finalFaultList.isNotEmpty &&
                  (finalFaultList[0].containsKey('System') ||
                      finalFaultList[0].containsKey('SubSystem') ||
                      finalFaultList[0].containsKey('FailureCategoryId'));

              debugPrint("RCA Data Check - isJEFormat: $isJEFormat");

              if (isJEFormat) {
                // Handle JE format from FailureRectificationJson
                for (var fault in finalFaultList) {
                  debugPrint("Processing JE RCA item: $fault");

                  final List<Map<String, dynamic>> rootCauses = [];
                  // Support both PascalCase and camelCase field names
                  final rootCauseId = fault['rootCauseId'] ?? fault['RootCauseId'];
                  final causeOfFailureId = fault['causeOfFailureId'] ?? fault['CauseOfFailureId'];
                  final rootCauseLabel = fault['rootCause'] ?? fault['RootCause'] ?? "";
                  final causeLabel = fault['cause'] ?? fault['Cause'] ?? "";

                  debugPrint("JE RCA - rootCauseId: $rootCauseId, causeOfFailureId: $causeOfFailureId, rootCause: $rootCauseLabel, cause: $causeLabel");

                  // Add root cause if ID exists (allow text to be empty)
                  if (rootCauseId != null && int.tryParse(rootCauseId.toString()) != null && int.tryParse(rootCauseId.toString())! > 0) {
                    rootCauses.add({
                      'causeId': causeOfFailureId?.toString() ?? "0",
                      'cause': causeLabel,
                      'rootCauseId': rootCauseId?.toString() ?? "0",
                      'rootCause': rootCauseLabel,
                      'causeText': fault['rootCauseText'] ?? fault['RootCauseText'] ?? "",
                      'imagePath': null
                    });
                    debugPrint("Added root cause: ID=$rootCauseId, label=$rootCauseLabel, causeText=${fault['rootCauseText']}");
                  }

                  final List<Map<String, dynamic>> actionTakens = [];
                  // Support both PascalCase and camelCase field names
                  final actionTakenId = fault['actionTakenId'] ?? fault['ActionTakenId'];
                  final actionTakenLabel = fault['actionTaken'] ?? fault['ActionTaken'] ?? "";

                  debugPrint("JE RCA - actionTakenId: $actionTakenId, actionTaken: $actionTakenLabel");

                  // Add action if ID exists (allow text to be empty)
                  if (actionTakenId != null && int.tryParse(actionTakenId.toString()) != null && int.tryParse(actionTakenId.toString())! > 0) {
                    actionTakens.add({
                      'actionTakenId': actionTakenId?.toString() ?? "0",
                      'actionTaken': actionTakenLabel,
                      'actionTakenText': fault['actionTakenText'] ?? fault['ActionTakenText'] ?? "",
                      'imagePath': null
                    });
                    debugPrint("Added action taken: ID=$actionTakenId, label=$actionTakenLabel, actionTakenText=${fault['actionTakenText']}");
                  }

                  rcaDetailsList.add({
                    'system': fault['system'] ?? fault['System'] ?? "",
                    'subsystem': fault['subsystem'] ?? fault['SubSystem'] ?? "",
                    'FailureCategoryId': (fault['failureCategoryId'] ?? fault['FailureCategoryId'])?.toString() ?? "0",
                    'failureCategory': fault['failureCategoryText'] ?? fault['FailureCategoryText'] ?? "",
                    'rootCauses': rootCauses,
                    'actionTakens': actionTakens,
                    // RST fields (empty for JE format)
                    'ObjectPartId': "0",
                    'objectPart': "",
                    'objectPartText': "",
                    'FaultId': "0",
                    'fault': "",
                    'faultText': "",
                  });
                }
              } else {
                // Handle RST format from getObjectANDFaultList
                for (var fault in finalFaultList) {
                  final rectId = fault['rectId'];

                  final List<Map<String, dynamic>> matchedRootCauses = [];
                  if (rootCauseList != null) {
                    for (var rc in rootCauseList
                        .where((r) => r['rectId'] == rectId)) {
                      matchedRootCauses.add({
                        'causeId': "0", // API doesn't provide cause ID
                        'cause': rc['rootCasueName'] ?? "N/A", // Map root cause name to cause field
                        'rootCauseId': rc['rcaId'].toString(),
                        'rootCause': rc['rootCasueName'] ?? "N/A",
                        'causeText': rc['rcaText'] ?? "", // Map rcaText to causeText
                        'imagePath': null
                      });
                    }
                  }

                  final List<Map<String, dynamic>> matchedActions = [];
                  if (actionList != null) {
                    for (var ac in actionList
                        .where((a) => a['rectId'] == rectId)) {
                      matchedActions.add({
                        'actionTakenId': ac['actionId'].toString(),
                        'actionTaken': ac['actionName'] ?? "N/A",
                        'actionTakenText': ac['actionText'] ?? "",
                        'imagePath': null
                      });
                    }
                  }

                  rcaDetailsList.add({
                    'ObjectPartId': fault['objectPartId']?.toString() ?? "0",
                    'objectPart': fault['objectName'] ?? "",
                    'objectPartText': fault['objectPartText'] ?? "",
                    'FaultId': fault['faultId']?.toString() ?? "0",
                    'fault': fault['faultName'] ?? "",
                    'faultText': fault['faultText'] ?? "",
                    'rootCauses': matchedRootCauses,
                    'actionTakens': matchedActions,
                    // JE-specific fields - add from fault data if available
                    'system': fault['system'] ?? systemController.text,
                    'subsystem': fault['subsystem'] ?? subsystemController.text,
                    'failureCategory': fault['failureCategory'] ?? "",
                    'FailureCategoryId': fault['FailureCategoryId']?.toString() ?? "0",
                  });
                }
              }
              debugPrint("RCA data loaded from API: ${rcaDetailsList.length} items");
              if (rcaDetailsList.isNotEmpty) {
                debugPrint("rcaDetailsList[0]: ${rcaDetailsList[0]}");
              }
              debugPrint("=== FINAL RCA LOADING END ===");
            } else {
              debugPrint("No RCA data in API response - finalFaultList is null");
            }
          } // End of if (!rcaLoadedFromOutput)

          // Load Material Requirement Details from API
          if (output.getMaterialReqDetails != null && output.getMaterialReqDetails!.isNotEmpty) {
            debugPrint("=== Loading Material Requirement Details ===");
            replacedMaterialsList.clear();
            for (var item in output.getMaterialReqDetails!) {
              final materialId = item['materialid'] ?? item['MaterialId'];
              final materialValue = item['materialValue'] ?? item['MaterialValue'];
              final quantity = item['quantity'] ?? item['Quantity'];
              final issuedQty = item['issuedQty'] ?? item['IssuedQty'];
              final balanceQty = item['balanceQty'] ?? item['BalanceQty'];
              final storageLocation = item['storageLocation'] ?? item['StorageLocation'];
              final storageLocationValue = item['storageLocationValue'] ?? item['StorageLocationValue'];
              final uom = item['unitOfMeasurement'] ?? item['UnitOfMeasurement'];
              final usedQty = item['usedQty'] ?? item['UsedQty'];
              final id = item['id'];

              replacedMaterialsList.add({
                'id': id,
                'materialId': materialId,
                'materialCode': materialValue,
                'materialName': materialValue,
                'requiredQty': quantity?.toString(),
                'issuedQty': issuedQty?.toString(),
                'usedQty': usedQty?.toString(),
                'balanceQty': balanceQty?.toString(),
                'storeLocation': storageLocationValue,
                'storageLocation': storageLocation,
                'uom': uom,
                'RemainingBalanceQTY': item['remainingBalanceQTY'] ?? item['RemainingBalanceQTY'],
              });
            }
            debugPrint("Loaded ${replacedMaterialsList.length} material requirement details");
          }

          // Load Material Dismantle Details from API
          if (output.getMaterialDismantleDetails != null && output.getMaterialDismantleDetails!.isNotEmpty) {
            debugPrint("=== Loading Material Dismantle Details ===");
            dismantleMaterialsList.clear();
            for (var item in output.getMaterialDismantleDetails!) {
              final materialId = item['materialId'] ?? item['MaterialId'];
              final materialValue = item['materialValue'] ?? item['MaterialValue'];
              final oldSerialNumber = item['oldSerialNumber'] ?? item['OldSerialNumber'];
              final newSerialNumber = item['newSerialNumber'] ?? item['NewSerialNumber'];
              final oldSerialDismantleDate = item['oldSerialNoDismantleDate'] ?? item['OldSerialNoDismantleDate'];
              final newSerialInstallationDate = item['newSerialNoInstallationDate'] ?? item['NewSerialNoInstallationDate'];
              final id = item['id'];

              dismantleMaterialsList.add({
                'id': id,
                'materialId': materialId,
                'materialCode': materialValue,
                'materialName': materialValue,
                'oldSerialNumber': oldSerialNumber,
                'newSerialNumber': newSerialNumber,
                'oldSerialDismantleDate': oldSerialDismantleDate,
                'newSerialInstallationDate': newSerialInstallationDate,
              });
            }
            debugPrint("Loaded ${dismantleMaterialsList.length} material dismantle details");
            isMaterialDismantle.value = true;
          }

          if (dismantleMaterialsList.isNotEmpty) {
            isMaterialDismantle.value = true;
          }

          if (output.getImageBefor != null) {
            beforeImagesList.clear();
            afterImagesList.clear();
            rcaImagesList.clear();
            for (var img in output.getImageBefor!) {
              final fileName = img['fileName']?.toString() ?? '';
              final docType = img['documentType']?.toString() ?? '';
              if (fileName.isNotEmpty) {
                final imgMap = {
                  'name': fileName.split('/').last,
                  'path': fileName,
                  'isNetwork': true
                };
                if (docType == 'BEFORE_NOT') {
                  beforeImagesList.add(imgMap);
                } else if (docType == 'AFTER_NOT') {
                  afterImagesList.add(imgMap);
                } else if (docType == 'RCA_NOT') {
                  rcaImagesList.add(imgMap);
                } else {
                  beforeImagesList.add(imgMap);
                }
              }
            }
          }

          selectedMaterialType.value = mapFailureTypeIdToMaterialType(model.failureTypeId);
          isServiceAffected.value = model.isServiceAffected ?? false;
          isJointInspection.value = model.isJointInspectionReq ?? false;
          isSparePartReplaced.value = model.isHardwareReplaced ?? false;
          isPtwRequired.value = model.isPTWReq ?? false;
          ptwNumberController.text = model.ptwNo ?? "";

          trainDelayMinController.text =
              model.trainDelayInMin?.toString() ?? "";
          trainDelayNosController.text =
              model.trainDelayInNo?.toString() ?? "";
          trainCancelNosController.text =
              model.noOfTranCancel?.toString() ?? "";
          trainWithdrawalNosController.text =
              model.noOfTranWithdrawal?.toString() ?? "";
          trainReplaceNosController.text =
              model.noOfTrainReplace?.toString() ?? "";
          isPassengerDeboarding.value = model.isPassengerDeboarding ?? false;
          trainDeboardedNosController.text =
              model.noofTrainDeboarded?.toString() ?? "";
          _applyPassengerAffectedFromModel(model);

          selectedFailureOccurrenceDate.value =
          model.actualFailureOccuranceOn != null
              ? _parseDate(model.actualFailureOccuranceOn!)
              : null;
          selectedActualFailureRectifiedDate.value =
          model.actualFailureRectifiedDate != null
              ? _parseDate(model.actualFailureRectifiedDate!)
              : null;
          selectedFailureAttendedDate.value =
          model.failureAttendedDate != null
              ? _parseDate(model.failureAttendedDate!)
              : null;
          selectedUnderObservationDate.value =
          (model.underObservationDate != null &&
              model.underObservationDate!.isNotEmpty)
              ? _parseDate(model.underObservationDate!)
              : null;

          // RCA data loading from API disabled - manage from frontend
          // RCA data is managed through failure_rca_logic.dart (addRcaDetail, removeRcaDetail, etc.)

          selectedActualFailureRectified.value = model.failureType;
          failureRectificationDetailsController.text =
              model.failureRectificationDetails ?? "";

          beforeFiles.clear();
          afterFiles.clear();
          if (model.imagesPaths != null && model.imagesPaths!.isNotEmpty) {
            final images = model.imagesPaths!.split(',');
            for (var img in images) {
              beforeFiles.add({
                'name': img.split('/').last,
                'size': 'N/A',
                'path': img,
              });
            }
          }
          if (model.imagesPathsAfter != null &&
              model.imagesPathsAfter!.isNotEmpty) {
            final images = model.imagesPathsAfter!.split(',');
            for (var img in images) {
              afterFiles.add({
                'name': img.split('/').last,
                'size': 'N/A',
                'path': img,
              });
            }
          }
          if (model.imagesPathsRCA != null &&
              model.imagesPathsRCA!.isNotEmpty) {
            final images = model.imagesPathsRCA!.split(',');
            for (var img in images) {
              afterFiles.add({
                'name': 'RCA_${img.split('/').last}',
                'size': 'N/A',
                'path': img,
              });
            }
          }
        }

      } else {
        errorMessage.value = result.responseMessage ?? 'Failed to load details';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      debugPrint("loadFailureDetails error: $e");
    } finally {
      popLoading();
    }
  }

  Future<void> loadStationFailureDetails(String id) async {
    encryptedId.value = id;
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final output = await _failureService.getStationFailureDetails(id);

      if (output['getFailureCreationDetails'] != null) {
        final details = output['getFailureCreationDetails'];
        originalFailureId.value = details['id'];
        notificationCode.value = details['failureId'] ?? '';
        selectedPriority.value = details['priority'];
        mainStatusName.value = details['statusName'];
        failureDescriptionController.text = details['failureDescription'] ?? '';
        selectedDepartment.value = details['departmentName'];
        originalDepartmentId.value =
            details['departmentId_1'] ?? details['departmentId'];
        selectedLocation.value = details['location'];
        originalLocationId.value = details['locationId'];
        selectedFunctionalLocation.value = details['funcationLocation'];
        debugPrint("loadFailureDetails: funcationLocation set to: ${selectedFunctionalLocation.value}");
        subLocationController.text = details['subLocation'] ?? '';
        systemController.text = details['system'] ?? '';
        trainIdController.text = details['trainId'] ?? '';
        await filterRcaFailureCategoriesBySystem();

        if (details['actualFailureOccuranceDate'] != null) {
          selectedFailureOccurrenceDate.value = DateFormat('dd-MM-yyyy HH:mm')
              .parse(details['actualFailureOccuranceDate']);
        }
        if (details['actualFailureCompletedDateTime'] != null) {
          selectedFailureCompletedDate.value = DateFormat('dd-MM-yyyy HH:mm')
              .parse(details['actualFailureCompletedDateTime']);
        }

        selectedFailureReportedBy.value = details['failureReportedby'];
        selectedFailureCategoryType.value = details['failureCategoryTypeText'];
        failureRectificationDetailsController.text =
            details['failureRectificationDetails'] ?? '';

        isTripAffected.value = details['isTripAffected'] ?? false;
        tripDelayUplineController.text =
            details['tripDelayUpline']?.toString() ?? '';
        trainCancelNosController.text =
            details['tripCancel']?.toString() ?? '';
        tripDelayDownlineController.text =
            details['tripDelayDownline']?.toString() ?? '';
        trainDelayMinController.text =
            details['trainDelayInMin']?.toString() ?? '';
        trainWithdrawalNosController.text =
            details['noOfTranWithdrawal']?.toString() ?? '';
        trainReplaceNosController.text =
            details['trainReplace']?.toString() ?? '';

        isPassengerDeboarding.value = details['isTrainDeboarded'] ?? false;
        trainDeboardedNosController.text =
            details['trainDeboarded']?.toString() ?? '';

        isPassengerAffected.value = details['isPassengerAffected'] ?? false;
        numberOfPassengerAffectedController.text =
            details['numberOfPassengerAffected']?.toString() ?? '';
        trappedDurationController.text =
            details['trappedDuration']?.toString() ?? '';
        rescuedDurationController.text =
            details['rescusedDuration']?.toString() ?? '';

        if (output['getImageBefor'] != null) {
          final List<dynamic> images = output['getImageBefor'];
          beforeImagesList.clear();
          for (var img in images) {
            final fileName = img['fileName']?.toString() ?? '';
            if (fileName.isNotEmpty) {
              beforeImagesList.add({
                'name': fileName.split('/').last,
                'path': fileName,
                'isNetwork': true,
              });
            }
          }
        }
      }

      final historyListJson =
      output['getNotificationActionUserHistory'] as List?;
      if (historyListJson != null) {
        notificationHistoryList.assignAll(historyListJson
            .map((e) =>
            NotificationActionHistory.fromJson(e as Map<String, dynamic>))
            .toList());
      }

      final descHistoryJson = output['getNotificationHistory'] as List?;
      if (descHistoryJson != null) {
        notificationDescriptionHistoryList.assignAll(descHistoryJson
            .map((e) => NotificationHistory.fromJson(e as Map<String, dynamic>))
            .toList());
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }


  String? _departmentCodeForLabel(String? label) {
    if (label == null || label.isEmpty) return null;
    final departments = Get.find<SessionController>().departments;
    final match = departments.firstWhere((e) => e.deptName == label,
        orElse: () => DeptMaster());
    return match.deptId?.toString();
  }

  Future<void> updateStationFailureDetails(String id) async {
    try {
      List<String> errors = [];


      if (selectedPriority.value == null || selectedPriority.value!.isEmpty || selectedPriority.value == 'Select') {
        errors.add("Priority is required.");
      }
      if (selectedDepartment.value == null || selectedDepartment.value!.isEmpty || selectedDepartment.value == 'Select') {
        errors.add("Department is required.");
      }
      final description = failureDescriptionController.text.trim();
      if (description.isEmpty) errors.add("Failure Description is required.");

      if (selectedLocation.value == null || selectedLocation.value!.isEmpty || selectedLocation.value == 'Select') {
        errors.add("Location is required.");
      }
      if (selectedFunctionalLocation.value == null || selectedFunctionalLocation.value!.isEmpty || selectedFunctionalLocation.value == 'Select') {
        errors.add("Functional Location is required.");
      }
      if (selectedFailureOccurrenceDate.value == null) {
        errors.add("Actual Failure Occurrence is required.");
      }
      if (selectedFailureCategoryType.value == null || selectedFailureCategoryType.value!.isEmpty || selectedFailureCategoryType.value == 'Select') {
        errors.add("Failure Category Type is required.");
      }

      if (isServiceAffected.value) {
        if (tripDelayUplineController.text.trim().isEmpty) errors.add("Trip Delay Upline is required.");
        if (tripDelayDownlineController.text.trim().isEmpty) errors.add("Trip Delay Downline is required.");
        if (trainCancelNosController.text.trim().isEmpty) errors.add("Train Cancel Nos is required.");
        if (trainDelayMinController.text.trim().isEmpty) errors.add("Train Delay (Min) is required.");
        if (trainWithdrawalNosController.text.trim().isEmpty) errors.add("Train Withdrawal Nos is required.");
        if (trainReplaceNosController.text.trim().isEmpty) errors.add("Train Replace Nos is required.");
      }

      if (isPassengerDeboarding.value) {
        if (trainDeboardedNosController.text.trim().isEmpty) errors.add("Train Deboarded Nos is required.");
      }

      if (isPtwRequired.value) {
        if (ptwNumberController.text.trim().isEmpty) errors.add("PTW Number is required.");
      }

      if (errors.isNotEmpty) {
        Get.snackbar(
          'Validation Error',
          errors.first,
          backgroundColor: AppColors.red.withValues(alpha: 0.9),
          colorText: AppColors.white1,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      isLoading.value = true;
      errorMessage.value = "";

      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;

      final int finalLocationId =
          int.tryParse(locationCodeForLabel(selectedLocation.value) ?? "0") ??
              originalLocationId.value ??
              0;
      final int finalDeptId = int.tryParse(
          _departmentCodeForLabel(selectedDepartment.value) ?? "0") ??
          originalDepartmentId.value ??
          0;

      final Map<String, dynamic> payload = {
        "Id": originalFailureId.value ?? 0,
        "PriorityId": 1, // Defaulting as it's not strictly mapped
        "DepartmentIds": finalDeptId.toString(),
        "DepartmentId_1": finalDeptId,
        "DepartmentId_2": 0,
        "DepartmentId_3": 0,
        "FailureDescription": failureDescriptionController.text,
        "LocationId": finalLocationId,
        "SubLocation": subLocationController.text,
        "System": systemController.text,
        "FuncationLocationIds": "",
        "FuncationLocationId_1": 0,
        "FuncationLocationId_2": 0,
        "FuncationLocationId_3": 0,
        "TrainId": trainIdController.text,
        "ActualFailureOccuranceDate":
        selectedFailureOccurrenceDate.value != null
            ? DateFormat("dd-MM-yyyy HH:mm")
            .format(selectedFailureOccurrenceDate.value!)
            : "",
        "FailureReportedbyId": 0,
        "ActualFailureCompletedDateTime":
        selectedFailureCompletedDate.value != null
            ? DateFormat("dd-MM-yyyy HH:mm")
            .format(selectedFailureCompletedDate.value!)
            : null,
        "IsTripAffected": isTripAffected.value,
        "TripDelayUpline": tripDelayUplineController.text.isNotEmpty
            ? int.tryParse(tripDelayUplineController.text)
            : null,
        "TripDelayDownline": tripDelayDownlineController.text.isNotEmpty
            ? int.tryParse(tripDelayDownlineController.text)
            : null,
        "TripCancel": trainCancelNosController.text.isNotEmpty
            ? int.tryParse(trainCancelNosController.text)
            : null,
        "TrainDelayInMin": trainDelayMinController.text.isNotEmpty
            ? int.tryParse(trainDelayMinController.text)
            : null,
        "NoOfTranWithdrawal": trainWithdrawalNosController.text.isNotEmpty
            ? int.tryParse(trainWithdrawalNosController.text)
            : null,
        "IsTrainReplace": trainReplaceNosController.text.isNotEmpty &&
            int.tryParse(trainReplaceNosController.text) != null &&
            int.parse(trainReplaceNosController.text) > 0,
        "TrainReplace": trainReplaceNosController.text.isNotEmpty
            ? int.tryParse(trainReplaceNosController.text)
            : null,
        "IsTrainDeboarded": isPassengerDeboarding.value,
        "TrainDeboarded": trainDeboardedNosController.text.isNotEmpty
            ? int.tryParse(trainDeboardedNosController.text)
            : null,
        "IsPassengerAffected": isPassengerAffected.value,
        "NumberOfPassengerAffected":
        numberOfPassengerAffectedController.text.isNotEmpty
            ? int.tryParse(numberOfPassengerAffectedController.text)
            : null,
        "TrappedDuration": trappedDurationController.text.isNotEmpty
            ? int.tryParse(trappedDurationController.text)
            : null,
        "RescusedDuration": rescuedDurationController.text.isNotEmpty
            ? int.tryParse(rescuedDurationController.text)
            : null,
        "CreatedBy": userId
      };

      try {
        await _failureService.updateStationFailure(payload);
        debugPrint("steppppp");
        Get.back(result: true);
        Get.snackbar(AppStrings.success, AppStrings.failureUpdated,
            backgroundColor: AppColors.green, colorText: AppColors.white1);

      } catch (e, s) {
        debugPrint("UPDATE ERROR: $e");
        debugPrint(s.toString());
        errorMessage.value = e.toString();
        Get.snackbar(AppStrings.error, errorMessage.value,
            backgroundColor: AppColors.red, colorText: AppColors.white1);
      } finally {
        isLoading.value = false;
      }
    } catch (e, s) {
      debugPrint("UPDATE ERROR: $e");
      debugPrint(s.toString());
      errorMessage.value = 'Error: $e';
      Get.snackbar(AppStrings.error, errorMessage.value,
          backgroundColor: AppColors.red, colorText: AppColors.white1);
    }
  }

  @override
  Future<void> fetchJointInspectionUsers(String deptId) async {
    try {
      isJointUserLoading.value = true;
      jointUserList.clear();

      // Joint Inspection Users API disabled - manage from frontend
      // Load users from local master data
      debugPrint("fetchJointInspectionUsers: API disabled, loading from local master data for deptId=$deptId");
      debugPrint("fetchJointInspectionUsers: masterUsers count = ${masterUsers.length}");

      // Show sample user data for debugging
      if (masterUsers.isNotEmpty) {
        debugPrint("fetchJointInspectionUsers: Sample user data:");
        for (int i = 0; i < masterUsers.length && i < 5; i++) {
          final user = masterUsers[i];
          debugPrint("  [$i] UserId: ${user['UserId']}, UserName: ${user['UserName']}, DeptId: ${user['DeptId']}, RoleDescr: ${user['RoleDescr']}");
        }

        // Show users in the target department
        debugPrint("fetchJointInspectionUsers: Users in department $deptId:");
        final deptUsers = masterUsers.where((user) => user['DeptId']?.toString() == deptId).toList();
        debugPrint("fetchJointInspectionUsers: Found ${deptUsers.length} users in department $deptId");
        for (int i = 0; i < deptUsers.length && i < 5; i++) {
          final user = deptUsers[i];
          debugPrint("  [$i] UserId: ${user['UserId']}, UserName: ${user['UserName']}, RoleDescr: ${user['RoleDescr']}");
        }
      }

      // Filter users from masterUsers based on department only
      final filteredUsers = masterUsers.where((user) {
        final userDeptId = user['DeptId']?.toString() ?? '';
        final userId = user['UserId']?.toString() ?? '';

        // Construct userName from FirstName and LastName (since UserName column is null in DB)
        final firstName = user['FirstName']?.toString() ?? '';
        final lastName = user['LastName']?.toString() ?? '';
        final userName = (firstName + ' ' + lastName).trim();

        // Filter by department ID (handle both string and int comparisons)
        final deptMatch = userDeptId == deptId ||
            int.tryParse(userDeptId) == int.tryParse(deptId);

        // Exclude invalid users
        final isValidUser = userId.isNotEmpty && userId != '0' &&
            userName.isNotEmpty && userName.toLowerCase() != 'select user';

        return deptMatch && isValidUser;
      }).toList();

      // Print filtered user list for verification
      debugPrint("fetchJointInspectionUsers: Filtered user list for department $deptId:");
      for (int i = 0; i < filteredUsers.length && i < 10; i++) {
        final user = filteredUsers[i];
        final roleDescr = user['RoleDescr']?.toString() ?? '';
        final firstName = user['FirstName']?.toString() ?? '';
        final lastName = user['LastName']?.toString() ?? '';
        final userName = (firstName + ' ' + lastName).trim();
        debugPrint("  [$i] UserId: ${user['UserId']}, UserName: $userName, DeptId: ${user['DeptId']}, RoleDescr: $roleDescr");
      }
      if (filteredUsers.length > 10) {
        debugPrint("  ... and ${filteredUsers.length - 10} more users");
      }
      debugPrint("fetchJointInspectionUsers: Found ${filteredUsers.length} users for department $deptId");

      // Convert to LabelValue
      final labelValueUsers = filteredUsers.map((user) {
        // Construct userName from FirstName and LastName (since UserName column is null in DB)
        final firstName = user['FirstName']?.toString() ?? '';
        final lastName = user['LastName']?.toString() ?? '';
        final userName = (firstName + ' ' + lastName).trim();
        return LabelValue(
          label: userName,
          value: user['UserId']?.toString() ?? '',
        );
      }).toList();

      jointUserList.assignAll(labelValueUsers);
    } catch (e) {
      debugPrint('fetchJointInspectionUsers error: $e');
    } finally {
      isJointUserLoading.value = false;
    }
  }

  void _mergeLocationDropdownsFromOutput(FailureDetailOutput output) {
    final locs = output.getLocationTypeList;
    if (locs != null && locs.isNotEmpty) {
      final filtered = locs.where((e) => e.label?.trim().isNotEmpty == true && e.label?.toLowerCase() != 'select').toList();
      if (filtered.isNotEmpty) {
        for (var item in filtered) {
          if (!locationTypeList.any((e) => e.label == item.label)) {
            locationTypeList.add(item);
          }
        }
      }
    }

    final funcs = output.getFunctionalLocationList;
    if (funcs != null && funcs.isNotEmpty) {
      final filtered = funcs.where((e) => e.value?.trim().isNotEmpty == true && e.value?.toLowerCase() != 'select' && e.label?.toLowerCase() != 'select functional location').toList();
      if (filtered.isNotEmpty) {
        for (var item in filtered) {
          final labelValue = LabelValue(
            label: item.label ?? '',
            value: item.value ?? '',
          );
          if (!functionalLocationList.any((e) => e.label == labelValue.label)) {
            functionalLocationList.add(labelValue);
          }
          if (!masterFunctionalLocations.any((e) => e['funcLocId']?.toString() == item.value)) {
            masterFunctionalLocations.add({
              'funcLocId': item.value,
              'funcLocationName': item.label,
              'location': null,
              'workCenter': null,
              'fromApi': true,
            });
          }
        }
      }
    }

    final equips = output.getEquipmentList ?? output.getEquipmentDetails;
    if (equips != null && equips.isNotEmpty) {
      final filtered = equips.where((e) => e.label?.trim().isNotEmpty == true && e.label?.toLowerCase() != 'select').toList();
      if (filtered.isNotEmpty) {
        for (var item in filtered) {
          if (!equipmentList.any((e) => e.label == item.label)) {
            equipmentList.add(item);
          }
        }
      }
    }
  }

  String? _labelFromValueList(List<LabelValue>? list, int? id) {
    if (list == null || id == null) return null;
    for (final item in list) {
      if (item.value?.toString() == id.toString()) {
        return item.label;
      }
    }
    return null;
  }

  String? _masterLocationName(int? locationTypeId) {
    if (locationTypeId == null) return null;
    final idText = locationTypeId.toString();

    for (final item in locationTypeList) {
      if (item.value == idText) {
        return item.label;
      }
    }

    for (final item in masterLocations) {
      if (item['locationTypeId']?.toString() == idText) {
        return item['locationName']?.toString();
      }
    }
    return null;
  }

  String? _masterFunctionalLocationName(int? functionLocationId) {
    if (functionLocationId == null) return null;
    debugPrint('_masterFunctionalLocationName: Looking for functionLocationId=$functionLocationId');
    debugPrint('_masterFunctionalLocationName: masterFunctionalLocations count=${masterFunctionalLocations.length}');
    debugPrint('_masterFunctionalLocationName: functionalLocationList count=${functionalLocationList.length}');

    // First try to find in functionalLocationList (from JE change notification API)
    for (final item in functionalLocationList) {
      if (item.value == functionLocationId.toString()) {
        debugPrint('_masterFunctionalLocationName: Found match in functionalLocationList - label=${item.label}, value=${item.value}');
        return item.label;
      }
    }

    // Then try masterFunctionalLocations (from DB)
    if (masterFunctionalLocations.isNotEmpty) {
      debugPrint('_masterFunctionalLocationName: First item funcLocId=${masterFunctionalLocations.first['funcLocId']}, funcLocationName=${masterFunctionalLocations.first['funcLocationName']}');
    }
    for (final item in masterFunctionalLocations) {
      final idText = functionLocationId.toString();
      if (item['funcLocId']?.toString() == idText ||
          item['functionLocationId']?.toString() == idText) {
        final name = item['funcLocationName']?.toString();
        debugPrint('_masterFunctionalLocationName: Found match in masterFunctionalLocations - funcLocId=${item['funcLocId']}, funcLocationName=$name');
        return name;
      }
    }
    debugPrint('_masterFunctionalLocationName: No match found for functionLocationId=$functionLocationId');
    return null;
  }

  String? _masterEquipmentName(int? equipmentId) {
    if (equipmentId == null) return null;
    final idText = equipmentId.toString();

    // First try equipmentList (merged from API response)
    for (final item in equipmentList) {
      if (item.value == idText) {
        return item.label;
      }
    }

    // Then try masterEquipments (from local DB)
    for (final item in masterEquipments) {
      if (item['equipId']?.toString() == idText ||
          item['equipmentId']?.toString() == idText) {
        return item['equipmentName']?.toString();
      }
    }
    return null;
  }

  Future<void> _applyLocationSelectionsFromModel(
      CreateVMModel model, {
        FailureDetailOutput? output,
      }) async {
    debugPrint("_applyLocationSelectionsFromModel: Starting - funcLocation=${model.funcLocation}, functionLocationId=${model.functionLocationId}");
    String? locationName = model.locationName?.trim();
    locationName ??= _masterLocationName(model.locationTypeId);   // ADD THIS LINE

    String? funcLocation = model.funcLocation?.trim();
    funcLocation ??= _masterFunctionalLocationName(model.functionLocationId);
    debugPrint("_applyLocationSelectionsFromModel: After lookup - funcLocation=$funcLocation");
    String? equipmentName = model.equipmentName?.trim();

    equipmentName ??= _labelFromValueList(equipmentList, model.equipmentId);
    equipmentName ??= _masterEquipmentName(model.equipmentId);

    if (locationName != null && locationName.isNotEmpty) {
      ensureDropdownOption(
        locationTypeList,
        locationName,
        model.locationTypeId?.toString() ?? '',
      );
      selectedLocation.value = locationName;
      locationDisplayController.text = locationName;
    }

    if (funcLocation != null && funcLocation.isNotEmpty) {
      ensureDropdownOption(
        functionalLocationList,
        funcLocation,
        model.functionLocationId?.toString() ?? '',
      );
      selectedFunctionalLocation.value = funcLocation;
      functionalLocationDisplayController.text = funcLocation;

      // Populate system and subsystem from functional location data
      debugPrint("_applyLocationSelectionsFromModel: Looking for functional location - funcLocId: ${model.functionLocationId}, funcLocation: ${model.funcLocation}");
      debugPrint("_applyLocationSelectionsFromModel: masterFunctionalLocations count: ${masterFunctionalLocations.length}");
      debugPrint("_applyLocationSelectionsFromModel: Current systemController.text: '${systemController.text}', subsystemController.text: '${subsystemController.text}'");
      if (masterFunctionalLocations.isNotEmpty) {
        debugPrint("_applyLocationSelectionsFromModel: Sample functional locations: ${masterFunctionalLocations.take(3).map((e) => {'funcLocId': e['funcLocId'], 'funcLocation': e['funcLocation'], 'techObjectType': e['techObjectType'], 'subSystem': e['subSystem']}).toList()}");
      }
      final funcLocEntry = masterFunctionalLocations.firstWhere(
            (e) =>
        e['funcLocId']?.toString() == model.functionLocationId?.toString() ||
            (model.funcLocation != null && e['funcLocation']?.toString() == model.funcLocation?.toString()),
        orElse: () => <String, dynamic>{},
      );

      debugPrint("_applyLocationSelectionsFromModel: Found functional location entry: ${funcLocEntry.isNotEmpty}");
      if (funcLocEntry.isNotEmpty) {
        debugPrint("_applyLocationSelectionsFromModel: funcLocEntry data: $funcLocEntry");
        // Only populate from functional location if API didn't provide system/subsystem
        final techObjectType = funcLocEntry['techObjectType']?.toString() ?? funcLocEntry['objectKey']?.toString() ?? '';
        final subSystem = funcLocEntry['subSystem']?.toString() ?? '';

        debugPrint("_applyLocationSelectionsFromModel: techObjectType='$techObjectType', subSystem='$subSystem'");

        if (systemController.text.isEmpty && techObjectType.isNotEmpty) {
          systemController.text = techObjectType;
          debugPrint("_applyLocationSelectionsFromModel: Set system from functional location");
        }
        if (subsystemController.text.isEmpty && subSystem.isNotEmpty) {
          subsystemController.text = subSystem;
          debugPrint("_applyLocationSelectionsFromModel: Set subsystem from functional location");
        }
        debugPrint("Populated system: ${systemController.text}, subsystem: ${subsystemController.text}");
        await filterRcaFailureCategoriesBySystem();
      } else {
        debugPrint("_applyLocationSelectionsFromModel: Functional location not found in master data");
      }
    }

    if (equipmentName != null && equipmentName.isNotEmpty) {
      ensureDropdownOption(
        equipmentList,
        equipmentName,
        model.equipmentId?.toString() ?? '',
      );
      selectedEquipmentNumber.value = equipmentName;
      equipmentDisplayController.text = equipmentName;
    }
  }

  /// Returns the raw `funcLocation` code (not funcLocId) for a given funcLocationName label.
  /// Needed because equipment.functionalLocation stores the funcLocation CODE, not the id or display name.
  String? _funcLocationCodeForLabel(String? funcLocationLabel) {
    if (funcLocationLabel == null || funcLocationLabel.isEmpty || funcLocationLabel == 'Select') {
      return null;
    }
    final func = masterFunctionalLocations.firstWhere(
          (e) => e['funcLocationName']?.toString() == funcLocationLabel,
      orElse: () => <String, dynamic>{},
    );
    final code = func['funcLocation']?.toString();
    return (code != null && code.isNotEmpty) ? code : null;
  }

  /// Direct filter: equipment.location == Location.locationTypeCode (if provided)
  /// AND equipment.functionalLocation == FunctionalLocation.funcLocation (if provided).
  List<Map<String, dynamic>> _filterEquipments({String? locCode, String? funcLocCode}) {
    Iterable<Map<String, dynamic>> filtered = masterEquipments;

    if (locCode != null && locCode.isNotEmpty) {
      filtered = filtered.where((eq) =>
      (eq['location']?.toString().trim().toUpperCase() ?? '') ==
          locCode.trim().toUpperCase());
    }

    if (funcLocCode != null && funcLocCode.isNotEmpty) {
      filtered = filtered.where((eq) =>
      (eq['functionalLocation']?.toString().trim().toUpperCase() ?? '') ==
          funcLocCode.trim().toUpperCase());
    }

    return filtered.toList();
  }
  Future<void> onDepartmentChanged(String? departmentLabel) async {
    selectedDepartment.value = (departmentLabel == null || departmentLabel == 'Select') ? null : departmentLabel;
    resetFunctionalAndEquipmentSelections();

    // Load functional locations on-demand when department changes
    await loadFunctionalLocationsOnDemand();

    _updateFunctionalLocationAndEquipmentOptions();
    await filterRcaFailureCategoriesBySystem();
  }

  Future<void> onLocationChanged(String? locationLabel) async {
    selectedLocation.value = (locationLabel == null || locationLabel == 'Select') ? null : locationLabel;
    resetFunctionalAndEquipmentSelections();

    // Load functional locations on-demand when location changes
    await loadFunctionalLocationsOnDemand();

    _updateFunctionalLocationAndEquipmentOptions();
  }

  void _updateFunctionalLocationAndEquipmentOptions() async {
    // Safety check: if masterFunctionalLocations is empty, don't crash
    if (masterFunctionalLocations.isEmpty) {
      debugPrint('_updateFunctionalLocationAndEquipmentOptions: masterFunctionalLocations is empty, skipping');
      return;
    }

    final hasLocation = selectedLocation.value != null && selectedLocation.value != 'Select';
    final hasDept = selectedDepartment.value != null && selectedDepartment.value != 'Select';

    String? locCode;
    if (hasLocation) {
      locCode = locationCodeForLabel(selectedLocation.value);
    }

    String? workCenter;
    if (hasDept) {
      workCenter = getCurrentWorkCenterFromDept();
    }

    debugPrint('_updateFunctionalLocationAndEquipmentOptions: hasLocation=$hasLocation, locCode=$locCode, hasDept=$hasDept, workCenter=$workCenter');

    final filteredFuncs = masterFunctionalLocations.where((e) {
      bool match = true;

      if (hasLocation && locCode != null && locCode.isNotEmpty) {
        final funcLoc = e['location']?.toString().trim().toUpperCase();
        if (funcLoc != null && funcLoc.isNotEmpty) { // Only filter if funcLoc is not empty
          match = match && (funcLoc == locCode.trim().toUpperCase());
        }
      }

      if (hasDept && workCenter != null && workCenter.isNotEmpty) {
        final funcWorkCenter = e['workCenter']?.toString().trim().toUpperCase();
        if (funcWorkCenter != null && funcWorkCenter.isNotEmpty) { // Only filter if funcWorkCenter is not empty
          match = match && (funcWorkCenter == workCenter.trim().toUpperCase());
        }
      }

      return match;
    }).toList();

    debugPrint('_updateFunctionalLocationAndEquipmentOptions: Filtered to ${filteredFuncs.length} functional locations');
    setFunctionalLocationOptions(filteredFuncs);

    // Equipment is only populated once a Functional Location is selected.
    // Location alone should narrow Functional Location choices, not Equipment.
    final hasFuncLoc = selectedFunctionalLocation.value != null &&
        selectedFunctionalLocation.value != 'Select';
    if (hasFuncLoc) {
      final funcLocCode = _funcLocationCodeForLabel(selectedFunctionalLocation.value);
      final filteredEquipments = _filterEquipments(locCode: locCode, funcLocCode: funcLocCode);
      setEquipmentOptions(filteredEquipments);
    } else {
      // No functional location selected — clear equipment list entirely.
      setEquipmentOptions([]);
    }
  }

  void onJiFunctionalLocationChanged(String? label) {
    selectedJiFunctionalLocation.value = label;
    if (label == null || label.isEmpty) {
      jiFunctionalLocationId.value = null;
      jiFunctionalLocation.value = null;
      return;
    }
    final matched = functionalLocationList.firstWhere(
          (e) => e.label == label,
      orElse: () => LabelValue(value: "0"),
    );
    jiFunctionalLocationId.value = matched.value;
    jiFunctionalLocation.value = label;

    // Auto-select location based on functional location
    final func = masterFunctionalLocations.firstWhere(
          (e) {
        final name = e['funcLocationName']?.toString() ?? '';
        final loc = e['funcLocation']?.toString() ?? '';
        return (name.isNotEmpty ? name : loc) == label;
      },
      orElse: () => <String, dynamic>{},
    );

    if (func.isEmpty) {
      return;
    }

    final funcLocationCode = func['location']?.toString();

    if (funcLocationCode != null && funcLocationCode.isNotEmpty) {
      final locationMatch = locationTypeList.firstWhere(
            (e) => e.uniqueId == funcLocationCode,
        orElse: () => LabelValue(),
      );

      if (locationMatch.label?.isEmpty == true) {
        final locationMatchByName = locationTypeList.firstWhere(
              (e) => e.label == funcLocationCode,
          orElse: () => LabelValue(),
        );

        if (locationMatchByName.label?.isNotEmpty == true) {
          selectedLocation.value = locationMatchByName.label;
          locationDisplayController.text = locationMatchByName.label ?? '';
        }
      } else {
        selectedLocation.value = locationMatch.label;
        locationDisplayController.text = locationMatch.label ?? '';
      }
    }

    // Auto-select department based on functional location's workCenter
    final funcWorkCenter = func['workCenter']?.toString();

    if (funcWorkCenter != null && funcWorkCenter.isNotEmpty) {
      LabelValue? deptMatch;
      for (var dept in departmentList) {
        if (dept.uniqueId?.toString() == funcWorkCenter) {
          deptMatch = dept;
          break;
        }
      }
      if (deptMatch == null) {
        for (var dept in departmentList) {
          final wc = getWorkCenterForDept(dept.value, deptLabel: dept.label);
          if (wc == funcWorkCenter) {
            deptMatch = dept;
            break;
          }
        }
      }
      if (deptMatch != null && deptMatch.label?.isNotEmpty == true) {
        selectedDepartment.value = deptMatch.label;
        departmentDisplayController.text = deptMatch.label ?? '';
      }
    }
  }

  void onJiEquipmentChanged(String? label) {
    selectedJiEquipmentNumber.value = label;
    if (label == null || label.isEmpty) {
      jiEquipmentId.value = null;
      jiEquipmentNumber.value = null;
      return;
    }
    final matched = equipmentList.firstWhere(
          (e) => e.label == label,
      orElse: () => LabelValue(value: "0"),
    );
    jiEquipmentId.value = int.tryParse(matched.value ?? "0");
    jiEquipmentNumber.value = label;
  }

  Future<void> onFunctionalLocationChanged(String? funcLabel) async {
    debugPrint('onFunctionalLocationChanged: funcLabel=$funcLabel');
    if (funcLabel == null || funcLabel == 'Select') {
      selectedFunctionalLocation.value = funcLabel == 'Select' ? 'Select' : null;
      selectedEquipmentNumber.value = 'Select';
      showMeasurementButton.value = false;
      setEquipmentOptions([]);
      systemController.clear();
      subsystemController.clear();
      return;
    }

    selectedFunctionalLocation.value = funcLabel;
    selectedEquipmentNumber.value = 'Select';

    final func = masterFunctionalLocations.firstWhere(
          (e) {
        final name = e['funcLocationName']?.toString() ?? '';
        final loc = e['funcLocation']?.toString() ?? '';
        return (name.isNotEmpty ? name : loc) == funcLabel;
      },
      orElse: () => <String, dynamic>{},
    );

    if (func.isEmpty) {
      return;
    }

    debugPrint("onFunctionalLocationChanged: Functional location data keys: ${func.keys.toList()}");
    debugPrint("onFunctionalLocationChanged: Functional location full data: $func");
    final funcObjectNumber = func['objectNumber']?.toString();
    debugPrint("onFunctionalLocationChanged: Functional location objectNumber: $funcObjectNumber");

    // Populate System and Subsystem fields from functional location
    systemController.text = func['techObjectType']?.toString() ?? func['objectKey']?.toString() ?? '';
    subsystemController.text = func['subSystem']?.toString() ?? '';
    // Don't filter RCA categories for station - use failure_category.db static list
    debugPrint('onFunctionalLocationChanged: corrNotificationTypeList count before: ${corrNotificationTypeList.length}');
    debugPrint('onFunctionalLocationChanged: corrNotificationTypeList items: ${corrNotificationTypeList.map((e) => e.label).toList()}');

    // Auto-select location based on functional location
    final funcLocationCode = func['location']?.toString();

    if (funcLocationCode != null && funcLocationCode.isNotEmpty) {
      final locationMatch = locationTypeList.firstWhere(
            (e) => e.uniqueId == funcLocationCode,
        orElse: () => LabelValue(),
      );

      if (locationMatch.label?.isEmpty == true) {
        final locationMatchByName = locationTypeList.firstWhere(
              (e) => e.label == funcLocationCode,
          orElse: () => LabelValue(),
        );

        if (locationMatchByName.label?.isNotEmpty == true) {
          selectedLocation.value = locationMatchByName.label;
          locationDisplayController.text = locationMatchByName.label ?? '';
        }
      } else {
        selectedLocation.value = locationMatch.label;
        locationDisplayController.text = locationMatch.label ?? '';
      }
    }

    // Auto-select department based on functional location's workCenter
    final funcWorkCenter = func['workCenter']?.toString();
    if (funcWorkCenter != null && funcWorkCenter.isNotEmpty) {
      LabelValue? deptMatch;
      for (var dept in departmentList) {
        if (dept.uniqueId?.toString() == funcWorkCenter) {
          deptMatch = dept;
          break;
        }
      }
      if (deptMatch == null) {
        for (var dept in departmentList) {
          final wc = getWorkCenterForDept(dept.value, deptLabel: dept.label);
          if (wc == funcWorkCenter) {
            deptMatch = dept;
            break;
          }
        }
      }
      if (deptMatch != null && deptMatch.label?.isNotEmpty == true) {
        selectedDepartment.value = deptMatch.label;
        departmentDisplayController.text = deptMatch.label ?? '';
      }
    }

    _updateFunctionalLocationAndEquipmentOptions();
    ensureDropdownOption(
      functionalLocationList,
      funcLabel,
      func['funcLocId']?.toString() ?? func['funcLocation']?.toString() ?? '',
    );
    selectedFunctionalLocation.value = funcLabel;

    final funcCode = func['funcLocation']?.toString();
    debugPrint('onFunctionalLocationChanged: funcCode=$funcCode, funcLocId=${func['funcLocId']}');
    if (funcCode != null && funcCode.isNotEmpty) {
      // Load equipment on-demand when functional location is selected
      // Pass funcLocation CODE (not ID) because equipment table stores the code
      debugPrint('onFunctionalLocationChanged: Calling loadEquipmentsOnDemand with funcCode=$funcCode');
      await loadEquipmentsOnDemand(functionalLocationId: funcCode);

      // Filter equipment ONLY by functional location (not by location code)
      final filteredEquipments = _filterEquipments(funcLocCode: funcCode);
      debugPrint('onFunctionalLocationChanged: Filtered ${filteredEquipments.length} equipments');
      setEquipmentOptions(filteredEquipments);

      // Use functional location's objectNumber to find measurement points
      final funcObjectNumber = func['objectNumber']?.toString();
      debugPrint("onFunctionalLocationChanged: Functional location objectNumber: $funcObjectNumber");
      _checkMeasurementPoints(funcObjectNumber);

      // FMECA: Load System/Subsystem for Section Incharge
      if (isSectionIncharge) {
        final locationTypeId = selectedLocation.value != null
            ? locationCodeForLabel(selectedLocation.value)
            : '';
        final funcLocId = func['funcLocId']?.toString() ?? func['funcLocation']?.toString() ?? '';

        if (locationTypeId != null && locationTypeId.isNotEmpty && funcLocId.isNotEmpty) {
          debugPrint('onFunctionalLocationChanged: Loading FMECA data for Section Incharge');
          await fetchFmecaSystemSubsystemByFuncLoc(locationTypeId, funcLocId);

          // Set frequency from functional location data
          final frequency = func['frequency'] ?? 0;
          fmecaFrequency.value = frequency is int ? frequency : int.tryParse(frequency.toString()) ?? 0;
          fmecaFrequencyController.text = fmecaFrequency.value.toString();
        }
      }
    }
  }

  /// Re-filters equipmentList to match the currently selected Location/Functional Location.
  /// Call this after loading an existing failure's details, since those flows set the
  /// selections directly without going through the normal filter path.
  void _refilterEquipmentForCurrentSelections() {
    final hasLocation = selectedLocation.value != null && selectedLocation.value != 'Select';
    final hasFuncLoc = selectedFunctionalLocation.value != null && selectedFunctionalLocation.value != 'Select';

    if (!hasFuncLoc) {
      // No functional location resolved — nothing to filter equipment by; leave as-is
      // (or clear, matching the "equipment only shows once func loc chosen" rule).
      return;
    }

    final locCode = hasLocation ? locationCodeForLabel(selectedLocation.value) : null;
    final funcLocCode = _funcLocationCodeForLabel(selectedFunctionalLocation.value);

    final filtered = _filterEquipments(locCode: locCode, funcLocCode: funcLocCode);
    setEquipmentOptions(filtered);
  }

  /// Re-filters functionalLocationList to match the currently selected Department
  /// (via workCenter) and Location. Preserves the currently selected functional
  /// location even if it falls outside the filter, so server-loaded data doesn't disappear.
  void _refilterFunctionalLocationForCurrentSelections() {


    final hasLocation = selectedLocation.value != null && selectedLocation.value != 'Select';
    final hasDept = selectedDepartment.value != null && selectedDepartment.value != 'Select';

    String? locCode;
    if (hasLocation) {
      locCode = locationCodeForLabel(selectedLocation.value);
    }

    String? workCenter;
    if (hasDept) {
      final dept = departmentList.firstWhere(
            (e) => e.label == selectedDepartment.value,
        orElse: () => LabelValue(),
      );
      // Use workCenter from departmentList uniqueId if available (from API)
      // Otherwise fall back to looking up in masterDepartments
      if (dept.uniqueId != null && dept.uniqueId.toString().trim().isNotEmpty) {
        workCenter = dept.uniqueId.toString();
      } else {
        workCenter = getWorkCenterForDept(dept.value, deptLabel: selectedDepartment.value);
      }
    }

    final filteredFuncs = masterFunctionalLocations.where((e) {
      bool match = true;
      if (hasLocation && locCode != null && locCode.isNotEmpty) {
        match = match && (e['location']?.toString().trim().toUpperCase() == locCode.trim().toUpperCase());
      }
      if (hasDept && workCenter != null && workCenter.isNotEmpty) {
        final funcWorkCenter = e['workCenter']?.toString().trim().toUpperCase();
        match = match && (funcWorkCenter == workCenter.trim().toUpperCase());
      }
      return match;
    }).toList();


    setFunctionalLocationOptions(filteredFuncs);

    // Preserve currently selected value if it fell outside the filtered set.
    final currentFuncLoc = selectedFunctionalLocation.value;
    if (currentFuncLoc != null && currentFuncLoc.isNotEmpty && currentFuncLoc != 'Select') {
      ensureDropdownOption(functionalLocationList, currentFuncLoc, '');
    }
  }

  void onEquipmentChanged(String? equipLabel) {
    if (equipLabel == null || equipLabel == 'Select') {
      selectedEquipmentNumber.value = equipLabel == 'Select' ? 'Select' : null;
      return;
    }

    selectedEquipmentNumber.value = equipLabel;

    final eq = masterEquipments.firstWhere(
            (e) => e['equipmentName'] == equipLabel,
        orElse: () => <String, dynamic>{});

    // Check measurement points using equipment's object number
    // This should match the functional location's ObjectNumber
    final equipObjectNumber = eq['objectNumber']?.toString();
    debugPrint("onEquipmentChanged: Equipment object number: $equipObjectNumber");
    _checkMeasurementPoints(equipObjectNumber);

    // Note: Removed auto-selection of location and functional location based on equipment
    // to prevent overriding user's manual selections. Equipment is filtered based on
    // the already-selected location and functional location, so it shouldn't change them.

    final funcCode = eq['functionalLocation']?.toString();
    if (funcCode != null && funcCode.isNotEmpty) {
      final func = masterFunctionalLocations.firstWhere(
              (e) => e['funcLocation'] == funcCode,
          orElse: () => <String, dynamic>{});

      if (func.isNotEmpty) {
        // Only update functional location if it's not already selected
        if (selectedFunctionalLocation.value == null ||
            selectedFunctionalLocation.value!.isEmpty ||
            selectedFunctionalLocation.value == 'Select') {
          final funcName = func['funcLocationName']?.toString() ?? funcCode;
          selectedFunctionalLocation.value = funcName;
          functionalLocationDisplayController.text = funcName;
          ensureDropdownOption(
            functionalLocationList,
            funcName,
            func['funcLocId']?.toString() ?? '',
          );
        }
      }
    }
  }

  Future<void> _checkMeasurementPoints(String? objectNumber) async {
    if (objectNumber == null || objectNumber.isEmpty) {
      showMeasurementButton.value = false;
      measurementPointsList.clear();
      return;
    }

    try {
      final dbService = LocalDatabaseService();

      // First try local database with filter
      List<MeasurementPointModel> matchingMeasurements =
      await dbService.getMeasurementPointsFromLocal(objectNumber: objectNumber);

      // If local DB has no results, query assets database directly with filter
      if (matchingMeasurements.isEmpty) {
        debugPrint("_checkMeasurementPoints: No results from local DB, querying assets database with filter");
        matchingMeasurements = await dbService.getMeasurementPointsFromAssetsFiltered(objectNumber);

        // Insert matching results into local DB for future use
        if (matchingMeasurements.isNotEmpty) {
          await dbService.insertMeasurementPoints(matchingMeasurements);
          debugPrint("_checkMeasurementPoints: Inserted ${matchingMeasurements.length} measurement points into local DB");
        }
      }

      if (matchingMeasurements.isNotEmpty) {
        measurementPointsList.assignAll(matchingMeasurements
            .map((m) => {
          "measPoint": m.measPoint,
          "measPointDesc": m.measPointDesc,
          "measRangeUnit": m.measRangeUnit,
          "internalCharNo": m.internalCharNo,
          "targetValue": m.targetValue,
          "measId": m.measId,
          "reading": "",
          "readingDescr": "",
          "uom": m.measRangeUnit,
          "UnitMeasurement": m.measRangeUnit
        })
            .toList());
        showMeasurementButton.value = true;
        debugPrint("_checkMeasurementPoints: Found ${matchingMeasurements.length} measurement points for objectNumber: $objectNumber");
      } else {
        measurementPointsList.clear();
        showMeasurementButton.value = false;
        debugPrint("_checkMeasurementPoints: No matching measurement points for objectNumber: $objectNumber");
      }
    } catch (e) {
      measurementPointsList.clear();
      showMeasurementButton.value = false;
      debugPrint("_checkMeasurementPoints error: $e");
    }
  }

  Future<void> fetchFaults(String objectPartId) async {
    try {
      isFaultLoading.value = true;
      faultTypeList.clear();
      final faults = await _failureService.getFaults(objectPartId);
      faultTypeList.assignAll(faults);
    } catch (e) {
      debugPrint('fetchFaults error: $e');
    } finally {
      isFaultLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers — single source of truth for cause / root-cause filtering
  // ---------------------------------------------------------------------------

  /// Returns a [LabelValue] list of causes filtered by [workCenter],
  /// [businessArea], [failureCategoryId] and the current system text.
  List<LabelValue> _buildCauseList({
    required String workCenter,
    required String businessArea,
    String? failureCategoryId,
  }) {
    final currentSystem = systemController.text.trim();
    final globalMasterData = Get.find<GlobalMasterDataController>();

    return globalMasterData.masterCauseOfFailures
        .map(CauseOfFailureModel.fromJson)
        .where((c) {
      final wcMatch   = workCenter.isEmpty        || (c.workCenter   ?? '').isEmpty || (c.workCenter   ?? '').toLowerCase().contains(workCenter.toLowerCase());
      final baMatch   = businessArea.isEmpty      || (c.businessArea == null) || c.businessArea.toString() == businessArea;
      final catMatch  = failureCategoryId == null || failureCategoryId.isEmpty ||
          c.failureCategoryId?.toString().trim() == failureCategoryId.trim();
      final sysMatch  = currentSystem.isEmpty     || (c.systems      ?? '').isEmpty || (c.systems      ?? '').toLowerCase().contains(currentSystem.toLowerCase());
      return wcMatch && baMatch && catMatch && sysMatch;
    })
        .map((c) => LabelValue(
      label: c.cause,
      value: c.causeOfFailureId?.toString() ?? '',
    ))
        .toList();
  }

  /// Resolves the numeric ID for the currently selected RCA failure category.
  /// [selectedRcaFailureCategory] holds the **label** (display text), so we
  /// must look up by label, not by value.
  String? _resolveRcaCategoryId() {
    final label = selectedRcaFailureCategory.value;
    debugPrint('_resolveRcaCategoryId: selectedRcaFailureCategory.value=$label');
    if (label == null || label.isEmpty || label == 'Select') {
      debugPrint('_resolveRcaCategoryId: Returning null (label is null/empty/Select)');
      return null;
    }
    final matched = rcaFailureCategoryList
        .firstWhereOrNull((e) => e.label == label);
    debugPrint('_resolveRcaCategoryId: Matched category: ${matched?.label}, value: ${matched?.value}');
    return matched?.value;
  }

  /// Returns a [LabelValue] list of root causes filtered by context.
  List<LabelValue> _buildRootCauseList({
    required String causeId,
    String? failureCategoryId,
    String? workCenter,
    String? businessArea,
    String? currentSystem,
  }) {
    final globalMasterData = Get.find<GlobalMasterDataController>();

    return globalMasterData.masterRootCauses
        .map(RootCauseModel.fromJson)
        .where((rc) {
      final wcMatch   = workCenter == null || workCenter.isEmpty        || (rc.workCenter   ?? '').isEmpty || (rc.workCenter   ?? '').toLowerCase().contains(workCenter.toLowerCase());
      final baMatch   = businessArea == null || businessArea.isEmpty      || (rc.businessArea == null) || rc.businessArea.toString() == businessArea;
      final sysMatch  = currentSystem == null || currentSystem.isEmpty     || (rc.systems      ?? '').isEmpty || (rc.systems      ?? '').toLowerCase().contains(currentSystem.toLowerCase());

      final catMatch  = failureCategoryId == null || failureCategoryId.isEmpty ||
          rc.failureCategoryId?.toString().trim() == failureCategoryId.trim();
      final causeMatch = rc.causeOfFailureId?.toString().trim() == causeId.trim();

      return wcMatch && baMatch && sysMatch && catMatch && causeMatch;
    })
        .map((rc) => LabelValue(
      label: rc.rootCause,
      value: rc.rootCauseId?.toString() ?? '',
    ))
        .toList();
  }

  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // FMECA Methods for Section Incharge
  // ---------------------------------------------------------------------------

  Future<void> fetchFmecaSystemSubsystemByFuncLoc(
      String locationTypeId, String funcLocId) async {
    if (locationTypeId.isEmpty || funcLocId.isEmpty || selectedDepartment.value == null) {
      debugPrint('fetchFmecaSystemSubsystemByFuncLoc: Missing required parameters');
      return;
    }

    try {
      final session = Get.find<SessionController>();
      final apiClient = ApiClient();
      final userId = await AuthManager().getUserId();

      final requestBody = {
        'userId': userId,
        'system': '',
        'locationTypeId': int.tryParse(locationTypeId) ?? 0,
        'funcLocId': int.tryParse(funcLocId) ?? 0,
        'action': 'GetSystemSubSystemByFuncLoc',
        'failureCategoryId': 0,
        'causeOfFailureId': 0,
        'departmentIds': selectedDepartment.value,
      };

      debugPrint('fetchFmecaSystemSubsystemByFuncLoc: Request body: $requestBody');

      final response = await apiClient.post(
        'GetFailureStandDropDownDataNew',
        body: requestBody,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decodedData = jsonDecode(response.body);
        final output = decodedData['data'] ?? decodedData['responseOutput'] ?? {};
        final subsystemsOnFuncLocs = output['subsystemsOnFuncLocs'] ?? [];

        debugPrint('fetchFmecaSystemSubsystemByFuncLoc: Got ${subsystemsOnFuncLocs.length} subsystem pairs');

        _applyFmecaSystemSubsystemPairs(subsystemsOnFuncLocs);
      } else {
        debugPrint('fetchFmecaSystemSubsystemByFuncLoc: API error ${response.statusCode}');
        _applyFmecaSystemSubsystemPairs([]);
      }
    } catch (e) {
      debugPrint('fetchFmecaSystemSubsystemByFuncLoc: Error $e');
      _applyFmecaSystemSubsystemPairs([]);
    }
  }

  void _applyFmecaSystemSubsystemPairs(List<dynamic> pairs) {
    final list = pairs.cast<Map<String, dynamic>>();

    if (list.isEmpty) {
      fmecaSystemList.clear();
      fmecaSubsystemList.clear();
      selectedFmecaSystem.value = null;
      selectedFmecaSubsystem.value = null;
      fmecaSystemReadOnly.value = false;
      fmecaSubsystemReadOnly.value = false;
      return;
    }

    if (list.length == 1) {
      final only = list[0];
      selectedFmecaSystem.value = only['system']?.toString() ?? '';
      selectedFmecaSubsystem.value = only['subSystem']?.toString() ?? '';
      fmecaSystemController.text = selectedFmecaSystem.value ?? '';
      fmecaSubsystemController.text = selectedFmecaSubsystem.value ?? '';
      fmecaSystemList.clear();
      fmecaSubsystemList.clear();
      fmecaSystemReadOnly.value = true;
      fmecaSubsystemReadOnly.value = true;
      return;
    }

    final uniqueSystems = <String>{};
    for (final p in list) {
      final system = p['system']?.toString();
      if (system != null && system.isNotEmpty) {
        uniqueSystems.add(system);
      }
    }

    final systemOptions = uniqueSystems
        .map((s) => LabelValue(label: s, value: s))
        .toList();

    fmecaSystemList.assignAll(systemOptions);
    fmecaSystemReadOnly.value = false;
    fmecaSubsystemReadOnly.value = false;
    selectedFmecaSystem.value = null;
    selectedFmecaSubsystem.value = null;
    fmecaSubsystemList.clear();

    if (uniqueSystems.length == 1) {
      final systemVal = uniqueSystems.first;
      selectedFmecaSystem.value = systemVal;
      fmecaSystemReadOnly.value = true;

      final subsystemOptions = list
          .where((p) => p['system']?.toString() == systemVal && p['subSystem'] != null)
          .map((p) => LabelValue(
        label: p['subSystem']?.toString() ?? '',
        value: p['subSystem']?.toString() ?? '',
      ))
          .toList();

      final uniqueSubsystems = <String, LabelValue>{};
      for (final opt in subsystemOptions) {
        uniqueSubsystems[opt.value ?? ''] = opt;
      }

      fmecaSubsystemList.assignAll(uniqueSubsystems.values.toList());

      if (uniqueSubsystems.length == 1) {
        selectedFmecaSubsystem.value = uniqueSubsystems.values.first.value;
        fmecaSubsystemReadOnly.value = true;
      }
    }
  }

  List<LabelValue> _getSubsystemOptionsForSystem(String systemVal) {
    return fmecaSubsystemList.where((opt) {
      // In a real implementation, you'd need to store the system-subsystem relationships
      // For now, we'll return all subsystems
      return true;
    }).toList();
  }

  void onFmecaSystemChanged(String? value) {
    if (value == null || value.isEmpty || value == 'Select') {
      selectedFmecaSystem.value = null;
      selectedFmecaSubsystem.value = null;
      fmecaSubsystemList.clear();
      return;
    }

    selectedFmecaSystem.value = value;
    fmecaSystemController.text = value;

    // Filter subsystems based on selected system
    // This would need the actual system-subsystem relationship data
    // For now, we'll load all available subsystems
    // In a real implementation, you'd filter based on the selected system
  }

  void onFmecaSubsystemChanged(String? value) {
    if (value == null || value.isEmpty || value == 'Select') {
      selectedFmecaSubsystem.value = null;
      return;
    }

    selectedFmecaSubsystem.value = value;
    fmecaSubsystemController.text = value;
  }

  Future<void> fetchRootCauseAndAction(
      String objectCodeId, String faultCodeId) async {
    try {
      final globalMasterData = Get.find<GlobalMasterDataController>();
      final system = systemController.text.trim();
      final workCenter = getCurrentWorkCenterFromDept() ?? '';
      final businessArea = await getCurrentBusinessArea() ?? '';

      // selectedRcaFailureCategory holds the label → look up the numeric ID
      // Prioritize dropdown selection over passed parameters
      final dropdownFailureCategoryId = _resolveRcaCategoryId();

      // Use dropdown selection if available, otherwise use passed parameter
      final failureCategoryId = (dropdownFailureCategoryId != null)
          ? dropdownFailureCategoryId
          : (objectCodeId != "0" ? objectCodeId : null);

      debugPrint('fetchRootCauseAndAction: system=$system, businessArea=$businessArea, workCenter=$workCenter, failureCategoryId=$failureCategoryId (dropdown: $dropdownFailureCategoryId, passed: $objectCodeId)');

      // Causes - preserve filtered list if it was already filtered (has fewer than total)
      // Only rebuild if we have a valid failureCategoryId to filter by
      final totalCauses = globalMasterData.masterCauseOfFailures.length;
      if (causeList.length < totalCauses && failureCategoryId == null) {
        // Cause list was already filtered but we don't have a category to filter by
        // Preserve the existing filtered list
        debugPrint('fetchRootCauseAndAction: Preserving existing filtered cause list (${causeList.length} causes)');
      } else {
        final causes = _buildCauseList(
          workCenter: workCenter,
          businessArea: businessArea,
          failureCategoryId: failureCategoryId,
        );
        causeList.assignAll(causes);
        debugPrint('fetchRootCauseAndAction: ${causes.length} causes from $totalCauses total');
      }

      final currentCause = selectedCause.value;
      if (currentCause != null && currentCause.isNotEmpty) {
        final failureCategoryId = _resolveRcaCategoryId();
        final workCenter = getCurrentWorkCenterFromDept() ?? '';
        final businessArea = await getCurrentBusinessArea() ?? '';
        final currentSystem = systemController.text.trim();

        final rootCauses = _buildRootCauseList(
          causeId: currentCause,
          failureCategoryId: failureCategoryId,
          workCenter: workCenter,
          businessArea: businessArea,
          currentSystem: currentSystem,
        );
        rootCauseList.assignAll(rootCauses);
        debugPrint('fetchRootCauseAndAction: ${rootCauses.length} root causes for causeId=$currentCause');
      } else {
        rootCauseList.clear();
      }

      // Actions
      actionTakenList.assignAll(globalMasterData.actionList);
      actionList.assignAll(globalMasterData.actionList);
      debugPrint('fetchRootCauseAndAction: ${actionList.length} actions loaded');
    } catch (e) {
      Get.snackbar(AppStrings.error, e.toString());
    }
  }

  void onRcaFailureCategorySelected(String? categoryValue) {
    selectedRcaFailureCategory.value = categoryValue;
    _filterCausesByRcaCategory();
  }

  void _filterCausesByRcaCategory() async {
    try {
      final workCenter        = getCurrentWorkCenterFromDept() ?? '';
      final businessArea      = await getCurrentBusinessArea() ?? '';
      // selectedRcaFailureCategory holds the label → look up the numeric ID
      final failureCategoryId = _resolveRcaCategoryId();

      debugPrint('_filterCausesByRcaCategory: businessArea=$businessArea, workCenter=$workCenter, failureCategoryId=$failureCategoryId');

      final causes = _buildCauseList(
        workCenter: workCenter,
        businessArea: businessArea,
        failureCategoryId: failureCategoryId,
      );
      causeList.assignAll(causes);
      debugPrint('_filterCausesByRcaCategory: ${causes.length} causes');
    } catch (e) {
      debugPrint('_filterCausesByRcaCategory error: $e');
    }
  }

  void onCauseSelected(String? causeValue) async {
    debugPrint('onCauseSelected: START - causeValue=$causeValue');
    selectedCause.value = causeValue;
    if (causeValue != null && causeValue.isNotEmpty) {
      // Resolve cause ID from label (dropdown passes label, need ID for root cause filtering)
      final causeId = _resolveCauseId(causeValue);
      debugPrint('onCauseSelected: Resolved causeId=$causeId from label=$causeValue');

      if (causeId == null) {
        debugPrint('onCauseSelected: Could not resolve causeId, clearing root causes');
        rootCauseList.clear();
        return;
      }

      // Filter root causes by ONLY cause ID
      debugPrint('onCauseSelected: Filtering root causes by causeId=$causeId only');

      final rootCauses = _buildRootCauseList(causeId: causeId);
      rootCauseList.assignAll(rootCauses);
      debugPrint('onCauseSelected: ${rootCauses.length} root causes for causeId=$causeId');
    } else {
      rootCauseList.clear();
      debugPrint('onCauseSelected: Cleared root causes (no cause selected)');
    }
  }

  /// Resolve cause ID from cause label (for root cause filtering)
  String? _resolveCauseId(String causeLabel) {
    final matched = causeList.firstWhereOrNull((e) => e.label == causeLabel);
    debugPrint('_resolveCauseId: Matched cause: ${matched?.label}, value: ${matched?.value}');
    return matched?.value;
  }

  Future<List<LabelValue>> getFilteredCausesByFailureCategory(String? failureCategoryId) async {
    if (failureCategoryId == null || failureCategoryId.isEmpty) return [];

    final workCenter   = getCurrentWorkCenterFromDept() ?? '';
    final businessArea = await getCurrentBusinessArea() ?? '';

    final causes = _buildCauseList(
      workCenter: workCenter,
      businessArea: businessArea,
      failureCategoryId: failureCategoryId,
    );

    debugPrint('getFilteredCausesByFailureCategory: ${causes.length} causes for failureCategoryId=$failureCategoryId');
    return causes;
  }

  Future<void> _autoSelectFailureReportedBy() async {
    debugPrint("_autoSelectFailureReportedBy: userList count = ${userList.length}");
    debugPrint("_autoSelectFailureReportedBy: userList sample = ${userList.take(3).map((e) => {'label': e.label, 'value': e.value}).toList()}");

    // Don't overwrite if already set (e.g. re-entrant call)
    if (selectedFailureReportedBy.value != null &&
        selectedFailureReportedBy.value!.isNotEmpty) {
      debugPrint("_autoSelectFailureReportedBy: Already set to ${selectedFailureReportedBy.value}, skipping");
      return;
    }
    final currentUserId = await AuthManager().getUserId();
    debugPrint("_autoSelectFailureReportedBy: currentUserId = $currentUserId");
    if (currentUserId == null || currentUserId.isEmpty) {
      debugPrint("_autoSelectFailureReportedBy: currentUserId is null or empty");
      return;
    }

    final matched = userList.firstWhere(
          (e) => e.value == currentUserId,
      orElse: () => LabelValue(label: null),
    );
    debugPrint("_autoSelectFailureReportedBy: matched user = ${matched.label}");
    if (matched.label != null && matched.label!.isNotEmpty) {
      selectedFailureReportedBy.value = matched.label;
      debugPrint("_autoSelectFailureReportedBy: Auto-selected ${matched.label}");
    } else {
      debugPrint("_autoSelectFailureReportedBy: No matching user found for userId $currentUserId");
      // Try to find user directly from masterUsers
      final userFromMaster = masterUsers.firstWhere(
            (e) => e['UserId']?.toString() == currentUserId,
        orElse: () => <String, dynamic>{},
      );
      if (userFromMaster.isNotEmpty) {
        final firstName = userFromMaster['FirstName']?.toString() ?? '';
        final lastName = userFromMaster['LastName']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) {
          selectedFailureReportedBy.value = fullName;
          debugPrint("_autoSelectFailureReportedBy: Auto-selected from masterUsers: $fullName");
        }
      }
    }
  }


  Future<void> loadStationCreateDropdowns() async {
    try {
      debugPrint("loadStationCreateDropdowns: Loading master data");

      final globalData = Get.find<GlobalMasterDataController>();

      // Load all master data for station users
      if (!globalData.isLoaded) {
        await globalData.initOnLogin();
      }

      // Copy global data to local lists
      _copyGlobalDataToLocal(globalData);

      // Ensure functional locations are loaded from local database for offline mode
      if (masterFunctionalLocations.isEmpty) {
        debugPrint("loadStationCreateDropdowns: masterFunctionalLocations empty, loading from local DB");
        await loadMasterDataFromDb();
      }

      // Ensure users are loaded from local database for offline mode
      if (userList.isEmpty || userList.length == 1) { // Only "Select" option
        debugPrint("loadStationCreateDropdowns: userList empty, loading from local DB");
        await loadMasterDropdownsFromDb(refreshIfEmpty: true);
      }

      await _autoSelectFailureReportedBy();

      debugPrint("loadStationCreateDropdowns: isStationController = $isStationController");
      debugPrint("loadStationCreateDropdowns: masterFunctionalLocations count = ${masterFunctionalLocations.length}");
      debugPrint("loadStationCreateDropdowns: functionalLocationList count = ${functionalLocationList.length}");
      debugPrint("loadStationCreateDropdowns: userList count = ${userList.length}");

      // Station is already selected in SessionController from login popup
      final session = Get.find<SessionController>();
      debugPrint("loadStationCreateDropdowns: Station from session: ${session.selectedStationName.value}");
    } catch (e) {
      debugPrint("loadStationCreateDropdowns error: $e");
    }
  }

  /// Loads full master data including RCA data for JE view
  Future<void> loadJEDropdowns() async {
    try {
      debugPrint("loadJEDropdowns: Using global master data with RCA data");

      final globalData = Get.find<GlobalMasterDataController>();

      // Load full master data if not already loaded
      if (!globalData.isLoaded) {
        await globalData.initOnLogin();
      }

      // Copy all global data to local lists
      _copyGlobalDataToLocal(globalData);

      await _autoSelectFailureReportedBy();

      debugPrint("loadJEDropdowns: masterFunctionalLocations count = ${masterFunctionalLocations.length}");
      debugPrint("loadJEDropdowns: userList count = ${userList.length}");
      debugPrint("loadJEDropdowns: masterRcaFailureCategories count = ${masterRcaFailureCategories.length}");
      debugPrint("loadJEDropdowns: masterCauseOfFailures count = ${masterCauseOfFailures.length}");
    } catch (e) {
      debugPrint("loadJEDropdowns error: $e");
    }
  }

  void _applyPassengerAffectedFromModel(CreateVMModel model) {
    final count = model.noOfPassengerAffected;
    final trapped = model.trappedDuration;
    final rescued = model.rescuedDuration;

    final hasPassengerData = model.isPassengerAffected == true ||
        (count != null && count > 0) ||
        (trapped != null && trapped.isNotEmpty) ||
        (rescued != null && rescued.isNotEmpty);

    isPassengerAffected.value = hasPassengerData;
    numberOfPassengerAffectedController.text = count?.toString() ?? '';
    trappedDurationController.text = trapped ?? '';
    rescuedDurationController.text = rescued ?? '';
  }

  @override
  String lookupValue(dynamic list, String? label,
      {String fallback = "0"}) {
    if (label == null || label.isEmpty || label == 'Select') return fallback;
    return list
        .firstWhere((e) => e.label == label,
        orElse: () => LabelValue(value: fallback))
        .value ??
        fallback;
  }

  @override
  int lookupLocationId(dynamic list, String? label,
      {String fallback = "0"}) {
    if (label == null || label.isEmpty || label == 'Select') return int.tryParse(fallback) ?? 0;
    // Now locationTypeId is stored in value field
    return int.tryParse(
        list
            .firstWhere((e) => e.label == label,
            orElse: () => LabelValue(value: fallback))
            .value ??
            fallback) ?? 0;
  }


  void updateMeasurementReading(int index, String field, String value) {
    var list = List<Map<String, dynamic>>.from(measurementPointsList);
    list[index][field] = value;
    measurementPointsList.assignAll(list);
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;

    try {
      try {
        final date = DateFormat('MM/dd/yyyy HH:mm:ss').parse(dateStr);
        // Check if the parsed date is valid (not default/invalid like 1900)
        if (date.year < 1900) return null;
        return date;
      } catch (e) {
        final date = DateFormat('dd/MM/yyyy HH:mm').parse(dateStr);
        // Check if the parsed date is valid (not default/invalid like 1900)
        if (date.year < 1900) return null;
        return date;
      }
    } catch (e) {
      debugPrint('Error parsing date: $dateStr — $e');
      return null;
    }
  }

  Future<void> handleScannedQR(String url) async {
    try {
      debugPrint('QR Scan: Raw URL: $url');
      final uri = Uri.tryParse(url);
      if (uri == null || uri.pathSegments.isEmpty) {
        Get.snackbar('Error', 'Invalid QR Code URL', backgroundColor: AppColors.red, colorText: AppColors.white1);
        return;
      }
      final encryptedIdBase64 = uri.pathSegments.last;
      debugPrint('QR Scan: Encrypted ID from URL: $encryptedIdBase64');
      final decryptedId = await _decryptQRId(encryptedIdBase64);
      debugPrint('QR Scan: Decrypted ID: $decryptedId');

      // Check internet connectivity
      final hasInternet = await NetworkUtils.checkConnectivity();
      debugPrint('QR Scan: Internet available: $hasInternet');

      if (hasInternet) {
        // Online mode: Call API to get data with encrypted ID
        await _populateDataFromApi(encryptedIdBase64);
      } else {
        // Offline mode: Use local DB lookup with decrypted ID
        await _populateDataFromScannedId(decryptedId);
      }
    } catch (e) {
      debugPrint('QR Scan Error: $e');
      Get.snackbar('Error', 'Failed to process QR Code: $e', backgroundColor: AppColors.red, colorText: AppColors.white1);
    }
  }

  Future<String> _decryptQRId(String encryptedId) async {
    try {
      final bytes = base64Decode(encryptedId);
      final innerBase64Str = String.fromCharCodes(bytes.where((b) => b != 0));
      final innerBytes = base64Decode(innerBase64Str);
      final str = "H3#@*iLvcL!k31q4l1ncL#@.^.";
      final keyBytes = utf8.encode(str.substring(0, 8));
      final msIv = [0x12, 0x34, 0x56, 0x78, 0x90, 0xAB, 0xCD, 0xEF];
      final des = DES(key: keyBytes, mode: DESMode.CBC, paddingType: DESPaddingType.PKCS7, iv: msIv);
      final decrypted = des.decrypt(innerBytes);
      final decodedStr = utf8.decode(decrypted);
      return decodedStr.replaceAll(RegExp(r'\x00'), '').trim();
    } catch (e) {
      debugPrint("QR Decryption Error: $e");
      return encryptedId;
    }
  }

  Future<void> _populateDataFromApi(String decryptedId) async {
    try {
      EasyLoading.show(status: 'Fetching data from server...');

      final userId = await AuthManager().getUserId() ?? 1;
      final apiUrl = '${AppUrls.baseUrl8080}${AppUrls.getAllDataByFuncLocId}';

      final requestBody = {
        "CreatedBy": userId,
        "FuncLocId": decryptedId,
        "IsSearchFilter": 0
      };

      debugPrint('QR Scan API: Calling $apiUrl with body: $requestBody ');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      debugPrint('QR Scan API: Response status: ${response.statusCode}');
      debugPrint('QR Scan API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['responseCode'] == 200 && responseData['responseOutput'] != null) {
          debugPrint('QR Scan API: Successfully parsed response output');

          EasyLoading.dismiss();

          // Navigate to MaintenanceHistoryScreen with showAssetQR = true
          Get.to(() => const MaintenanceHistoryScreen(showAssetQR: true), arguments: decryptedId);
        } else {
          EasyLoading.dismiss();
          debugPrint('QR Scan API: Invalid response code or missing data');
          Get.snackbar('Error', 'Invalid response from server',
              backgroundColor: AppColors.red, colorText: AppColors.white1);
          // Fallback to offline mode
          await _populateDataFromScannedId(decryptedId);
        }
      } else {
        EasyLoading.dismiss();
        debugPrint('QR Scan API: Non-200 status code');
        Get.snackbar('Error', 'Server error: ${response.statusCode}',
            backgroundColor: AppColors.red, colorText: AppColors.white1);
        // Fallback to offline mode
        await _populateDataFromScannedId(decryptedId);
      }
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('QR Scan API Error: $e');
      Get.snackbar('Error', 'Failed to fetch data from server: $e',
          backgroundColor: AppColors.red, colorText: AppColors.white1);
      // Fallback to offline mode
      await _populateDataFromScannedId(decryptedId);
    }
  }

  Future<void> _populateDataFromScannedId(String scannedId) async {
    final dbService = LocalDatabaseService();
    final db = await dbService.database;
    final cleanId = scannedId.trim();
    final intId = int.tryParse(cleanId);

    debugPrint('QR Scan: Looking for functional location with ID: $cleanId (parsed as int: $intId)');

    List<Map<String, Object?>> funcResults = [];

    // First try by funcLocId if it's an integer
    if (intId != null) {
      funcResults = await db.rawQuery(
        'SELECT funcLocation, funcLocId, funcLocationName, location, objectNumber, workCenter FROM FunctionalLocations WHERE funcLocId = ? LIMIT 1',
        [intId],
      );
      debugPrint('QR Scan: Query by funcLocId=$intId returned ${funcResults.length} results');
    }

    // If no results by ID, try by funcLocation code (string)
    if (funcResults.isEmpty) {
      funcResults = await db.rawQuery(
        'SELECT funcLocation, funcLocId, funcLocationName, location, objectNumber, workCenter FROM FunctionalLocations WHERE funcLocation = ? LIMIT 1',
        [cleanId],
      );
      debugPrint('QR Scan: Query by funcLocation="$cleanId" returned ${funcResults.length} results');
    }

    // If still no results, try a LIKE search for partial matches
    if (funcResults.isEmpty) {
      funcResults = await db.rawQuery(
        'SELECT funcLocation, funcLocId, funcLocationName, location, objectNumber, workCenter FROM FunctionalLocations WHERE funcLocation LIKE ? LIMIT 1',
        ['%$cleanId%'],
      );
      debugPrint('QR Scan: Query by funcLocation LIKE "%$cleanId%" returned ${funcResults.length} results');
    }

    if (funcResults.isEmpty) {
      final allFuncLocs = await db.rawQuery('SELECT funcLocId, funcLocation, funcLocationName FROM FunctionalLocations LIMIT 10');
      debugPrint('QR Scan: Sample functional locations in DB (first 10): $allFuncLocs');
      final totalCount = await db.rawQuery('SELECT COUNT(*) as cnt FROM FunctionalLocations');
      debugPrint('QR Scan: Total functional locations in DB: ${totalCount.first['cnt']}');

      final check90225 = await db.rawQuery('SELECT funcLocId, funcLocation, funcLocationName FROM FunctionalLocations WHERE funcLocId = 90225');
      debugPrint('QR Scan: Check for ID 90225: ${check90225.isNotEmpty ? "FOUND" : "NOT FOUND"}');
      if (check90225.isNotEmpty) {
        debugPrint('QR Scan: ID 90225 details: $check90225');
      }

      Get.snackbar('Not Found',
          'Functional location not found in master data for ID: $cleanId. Total in DB: ${totalCount.first['cnt']}',
          backgroundColor: AppColors.red, colorText: AppColors.white1);
      return;
    }

    final match = FunctionalLocationModel.fromJson(funcResults.first);

    // Make sure master caches are actually populated before we try to match against them
    if (masterFunctionalLocations.isEmpty || masterLocations.isEmpty) {
      await loadMasterDataFromDb();
    }
    if (masterDepartments.isEmpty || departmentList.isEmpty) {
      // await loadDepartments();
    }

    debugPrint('QR Scan Offline: masterDepartments count=${masterDepartments.length}');
    debugPrint('QR Scan Offline: departmentList count=${departmentList.length}');
    debugPrint('QR Scan Offline: departmentList sample=${departmentList.take(5).map((e) => {'label': e.label, 'value': e.value, 'uniqueId': e.uniqueId}).toList()}');

    final existsInMaster = masterFunctionalLocations.any((e) =>
    e['funcLocId']?.toString() == match.funcLocId?.toString() ||
        e['funcLocation'] == match.funcLocation);

    if (!existsInMaster) {
      masterFunctionalLocations.add(match.toJson());
    }
    ensureDropdownOption(
      functionalLocationList,
      match.funcLocationName,
      match.funcLocId?.toString() ?? match.funcLocation,
    );

    selectedFunctionalLocation.value = match.funcLocationName;
    functionalLocationDisplayController.text = match.funcLocationName;

    // --- Resolve Location NAME from the raw location CODE on the func loc ---
    String? locName;
    final locCode = match.location.toString();
    if (locCode.isNotEmpty) {
      final loc = masterLocations.firstWhere(
            (e) =>
        e['locationTypeCode']?.toString() == locCode ||
            e['locationTypeId']?.toString() == locCode,
        orElse: () => <String, dynamic>{},
      );
      locName = loc['locationName']?.toString();
    }
    if (locName != null && locName.isNotEmpty) {
      ensureDropdownOption(locationTypeList, locName, locCode);
      selectedLocation.value = locName;
      locationDisplayController.text = locName;
    } else {
      debugPrint('QR scan: could not resolve location name for code=$locCode');
    }

    // --- Resolve Department via workCenter, same fallback order used elsewhere ---
    String? deptName;
    final workCenter = match.workCenter.toString().trim();
    if (workCenter.isNotEmpty) {
      final deptFromList = departmentList.firstWhere(
            (e) =>
        (e.uniqueId?.toString().trim().toUpperCase() ?? '') ==
            workCenter.toUpperCase(),
        orElse: () => LabelValue(),
      );
      deptName = deptFromList.label;

      deptName ??= masterDepartments.firstWhere(
            (d) =>
        (d['workCenter']?.toString().trim().toUpperCase() ?? '') ==
            workCenter.toUpperCase(),
        orElse: () => <String, dynamic>{},
      )['deptName']?.toString();
    }
    if (deptName != null && deptName.isNotEmpty) {
      selectedDepartment.value = deptName;
      departmentDisplayController.text = deptName;
    } else {
      debugPrint(
          'QR scan: could not resolve department for workCenter=$workCenter');
    }

    // --- Refresh dependent dropdowns (this filters func-loc/equipment lists) ---
    _updateFunctionalLocationAndEquipmentOptions();

    // The filter step above rebuilds functionalLocationList from scratch and may
    // drop our scanned entry if it doesn't match the resolved dept/location — re-add it.
    ensureDropdownOption(
      functionalLocationList,
      match.funcLocationName,
      match.funcLocId?.toString() ?? match.funcLocation,
    );
    selectedFunctionalLocation.value = match.funcLocationName;

    // --- Equipment for this functional location ---
    final equipResults = await db.rawQuery(
      'SELECT equipId, equipmentName, functionalLocation, location, equipNo, equipDesc FROM Equipments WHERE functionalLocation = ? LIMIT 1',
      [match.funcLocation],
    );

    if (equipResults.isNotEmpty) {
      final equipMatch = EquipmentModel.fromJson(equipResults.first);
      ensureDropdownOption(
        equipmentList,
        equipMatch.equipmentName,
        equipMatch.equipId?.toString() ?? equipMatch.equipNo,
      );
      selectedEquipmentNumber.value = equipMatch.equipmentName;
      equipmentDisplayController.text = equipMatch.equipmentName;
    }

    await _checkMeasurementPoints(match.objectKey.toString());

    Get.snackbar('Success', 'Asset data populated successfully',
        backgroundColor: AppColors.green, colorText: AppColors.white1);
  }

  // ON-DEMAND: Load functional locations with SQL filtering
  Future<void> loadFunctionalLocationsOnDemand({
    int? businessArea,
    String? workCenter,
    String? location,
  }) async {
    // Only load if not already loaded
    if (isFunctionalLocationsLoaded.value && functionalLocationList.isNotEmpty) {
      debugPrint('loadFunctionalLocationsOnDemand: Functional locations already loaded, skipping');
      return;
    }

    isFunctionalLocationLoading.value = true;
    debugPrint('loadFunctionalLocationsOnDemand: Loading with filters - businessArea: $businessArea, workCenter: $workCenter, location: $location');
    final dbService = LocalDatabaseService();
    final funcLocs = await dbService.getFunctionalLocationsFiltered(
      businessArea: businessArea ?? await AuthManager().getBusinessArea(),
      workCenter: workCenter,
      location: location,
      // No limit - load all filtered results
    );

    masterFunctionalLocations.assignAll(funcLocs.map((e) => e.toJson()).toList());
    functionalLocationList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...funcLocs.map((e) => LabelValue(
        label: e.funcLocationName.isNotEmpty ? e.funcLocationName : e.funcLocation,
        value: e.funcLocId?.toString() ?? '',
      )),
    ]);
    isFunctionalLocationsLoaded.value = true;
    debugPrint('loadFunctionalLocationsOnDemand: Loaded ${funcLocs.length} functional locations');
    isFunctionalLocationLoading.value = false;
  }

  // ON-DEMAND: Load equipment with SQL filtering
  Future<void> loadEquipmentsOnDemand({
    int? businessArea,
    String? functionalLocationId,
    String? workCenter,
  }) async {
    isEquipmentLoading.value = true;
    debugPrint('loadEquipmentsOnDemand: Loading with filters - businessArea: $businessArea, functionalLocationId: $functionalLocationId, workCenter: $workCenter');
    final dbService = LocalDatabaseService();
    final equipments = await dbService.getEquipmentsFiltered(
      businessArea: businessArea, // Don't default - only filter if explicitly provided
      functionalLocationId: functionalLocationId,
      workCenter: workCenter,
      // No limit - load all filtered results
    );

    masterEquipments.assignAll(equipments.map((e) => e.toJson()).toList());
    equipmentList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...equipments.map((e) => LabelValue(
        label: e.equipmentName.isNotEmpty ? e.equipmentName : e.equipDesc,
        value: e.equipId?.toString() ?? '',
      )),
    ]);
    debugPrint('loadEquipmentsOnDemand: Loaded ${equipments.length} equipments');
    isEquipmentLoading.value = false;
  }

  Future<void> loadStationFailureDetailsFromData(FailureItem failureItem) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Populate form fields from FailureItem
      originalFailureId.value = failureItem.id;
      notificationCode.value = failureItem.notificationCode ?? failureItem.failureNo ?? '';
      selectedPriority.value = failureItem.priority;
      mainStatusName.value = failureItem.statusName;
      failureDescriptionController.text = failureItem.failureDescription ?? '';
      selectedDepartment.value = failureItem.departmentName;
      originalDepartmentId.value = failureItem.departmentId_1;
      selectedLocation.value = failureItem.locationName;
      originalLocationId.value = failureItem.locationId;
      selectedFunctionalLocation.value = failureItem.functionalLocation;
      debugPrint("loadStationFailureDetailsFromData: functionalLocation=${failureItem.functionalLocation}, set to=${selectedFunctionalLocation.value}");
      subLocationController.text = failureItem.subLocation ?? '';
      systemController.text = failureItem.system ?? '';
      trainIdController.text = failureItem.trainId ?? '';
      await filterRcaFailureCategoriesBySystem();

      if (failureItem.failureOccuranceDateTime != null) {
        selectedFailureOccurrenceDate.value = _parseDate(failureItem.failureOccuranceDateTime!);
      }
      if (failureItem.actualFailureCompletedDateTime != null) {
        selectedFailureCompletedDate.value = _parseDate(failureItem.actualFailureCompletedDateTime!);
      }

      selectedFailureReportedBy.value = failureItem.failureReportedby;
      selectedFailureCategoryType.value = failureItem.failureCategoryTypeText;
      failureRectificationDetailsController.text = failureItem.failureRectificationDetails ?? '';

      isTripAffected.value = failureItem.isTripAffected ?? false;
      tripDelayUplineController.text = failureItem.tripDelayUpline?.toString() ?? '';
      trainCancelNosController.text = failureItem.tripCancel?.toString() ?? '';
      tripDelayDownlineController.text = failureItem.tripDelayDownline?.toString() ?? '';
      trainDelayMinController.text = failureItem.trainDelayInMin?.toString() ?? '';
      trainWithdrawalNosController.text = failureItem.noOfTranWithdrawal?.toString() ?? '';

      if (failureItem.getImageBefor != null) {
        beforeImagesList.clear();
        for (var img in failureItem.getImageBefor!) {
          final fileName = img['fileName']?.toString() ?? '';
          if (fileName.isNotEmpty) {
            beforeImagesList.add({
              'name': fileName.split('/').last,
              'path': fileName,
              'isNetwork': true,
            });
          }
        }
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      debugPrint('Error in loadStationFailureDetailsFromData: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadJEFailureDetailsFromData(FailureItem failureItem) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      locationTypeList.clear();
      functionalLocationList.clear();
      equipmentList.clear();
      await loadMasterDataFromDb();

      // Load functional locations on-demand based on business area
      await loadFunctionalLocationsOnDemand();

      // Populate form fields from FailureItem (JE inbox list data)
      encryptedId.value = failureItem.failureNo ?? failureItem.id?.toString() ?? '';
      notificationId.value = failureItem.id ?? 0;
      notificationCode.value = failureItem.notificationCode ?? failureItem.failureNo ?? '';
      failureCategory.value = failureItem.creationType ?? 'Manual';

      // Populate basic fields from FailureItem
      failureDescriptionController.text = failureItem.failureDescription ?? '';
      selectedDepartment.value = failureItem.departmentName;
      selectedLocation.value = failureItem.locationName;
      selectedFunctionalLocation.value = failureItem.functionalLocation;
      selectedEquipmentNumber.value = failureItem.equipmentDescription;
      subLocationController.text = failureItem.subLocation ?? '';
      systemController.text = failureItem.system ?? '';
      subsystemController.text = failureItem.subSystems ?? '';
      trainIdController.text = failureItem.trainId ?? '';

      selectedPriority.value = failureItem.priority;
      mainStatusName.value = failureItem.statusName;

      // Set notification type to default for JE offline flow (use corrNotificationTypeList from local DB)
      if (corrNotificationTypeList.isNotEmpty) {
        selectedNotificationType.value = corrNotificationTypeList.first.label;
      }

      await filterRcaFailureCategoriesBySystem();

      if (failureItem.failureOccuranceDateTime != null) {
        selectedFailureOccurrenceDate.value = _parseDate(failureItem.failureOccuranceDateTime!);
      }
      if (failureItem.actualFailureCompletedDateTime != null) {
        selectedActualFailureRectifiedDate.value = _parseDate(failureItem.actualFailureCompletedDateTime!);
      }

      selectedFailureReportedBy.value = failureItem.failureReportedby;
      selectedFailureCategoryType.value = failureItem.failureCategoryTypeText;
      failureRectificationDetailsController.text = failureItem.failureRectificationDetails ?? '';
      // carriedOutRemarksController.text = failureItem.carriedOutRemarks ?? '';

      // Load RCA data from FailureItem if available
      if (failureItem.getObjectANDFaultList != null) {
        rcaDetailsList.clear();
        for (var fault in failureItem.getObjectANDFaultList!) {
          final rectId = fault['rectId'];

          final List<Map<String, dynamic>> matchedRootCauses = [];
          if (failureItem.getObjectANDFaultRootCauseList != null) {
            for (var rc in failureItem.getObjectANDFaultRootCauseList!
                .where((r) => r['rectId'] == rectId)) {
              matchedRootCauses.add({
                'causeId': "0", // API doesn't provide cause ID
                'cause': rc['rootCasueName'] ?? "N/A", // Map root cause name to cause field
                'rootCauseId': rc['rcaId'].toString(),
                'rootCause': rc['rootCasueName'] ?? "N/A",
                'causeText': rc['rcaText'] ?? "", // Map rcaText to causeText
                'imagePath': null
              });
            }
          }

          final List<Map<String, dynamic>> matchedActions = [];
          if (failureItem.getObjectANDFaultActionList != null) {
            for (var ac in failureItem.getObjectANDFaultActionList!
                .where((a) => a['rectId'] == rectId)) {
              matchedActions.add({
                'actionTakenId': ac['actionId'].toString(),
                'actionTaken': ac['actionName'] ?? "N/A",
                'actionTakenText': ac['actionText'] ?? "",
                'imagePath': null
              });
            }
          }

          rcaDetailsList.add({
            'ObjectPartId': fault['objectPartId']?.toString() ?? "0",
            'objectPart': fault['objectName'] ?? "",
            'objectPartText': fault['objectPartText'] ?? "",
            'FaultId': fault['faultId']?.toString() ?? "0",
            'fault': fault['faultName'] ?? "",
            'faultText': fault['faultText'] ?? "",
            'rootCauses': matchedRootCauses,
            'actionTakens': matchedActions,
          });
        }
      }

      // Load images if available
      if (failureItem.getImageBefor != null) {
        beforeImagesList.clear();
        afterImagesList.clear();
        rcaImagesList.clear();
        for (var img in failureItem.getImageBefor!) {
          final fileName = img['fileName']?.toString() ?? '';
          final docType = img['documentType']?.toString() ?? '';
          if (fileName.isNotEmpty) {
            final imgMap = {
              'name': fileName.split('/').last,
              'path': fileName,
              'isNetwork': true
            };
            if (docType == 'BEFORE_NOT') {
              beforeImagesList.add(imgMap);
            } else if (docType == 'AFTER_NOT') {
              afterImagesList.add(imgMap);
            } else if (docType == 'RCA_NOT') {
              rcaImagesList.add(imgMap);
            } else {
              beforeImagesList.add(imgMap);
            }
          }
        }
      }

      debugPrint("loadJEFailureDetailsFromData: Loaded details from FailureItem for offline JE flow");
    } catch (e) {
      errorMessage.value = 'Error: $e';
      debugPrint('Error in loadJEFailureDetailsFromData: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Sets asset data from MaintenanceHistoryScreen arguments
  /// Populates functional location and dependent fields based on funcLocId
  Future<void> setAssetDataFromQR(Map<String, dynamic> args) async {
    try {
      debugPrint('setAssetDataFromQR: Received args: $args');

      // Make sure master caches are populated
      if (masterFunctionalLocations.isEmpty || masterLocations.isEmpty) {
        await loadMasterDataFromDb();
      }

      final funcLocId = args['funcLocId']?.toString();
      final funcLocation = args['funcLocation']?.toString();
      final description = args['description']?.toString();
      final department = args['department']?.toString();
      final deptId = args['deptId']?.toString();
      final location = args['location']?.toString();

      String? selectedFuncLocName;

      if (funcLocId != null && funcLocId.isNotEmpty) {
        // Try to find the functional location in master data by funcLocId
        final match = masterFunctionalLocations.firstWhere(
              (e) => e['funcLocId']?.toString() == funcLocId,
          orElse: () => <String, dynamic>{},
        );

        if (match.isNotEmpty) {
          // Use the name from master data (funcLocationName)
          final masterFuncLocName = match['funcLocationName']?.toString();
          if (masterFuncLocName != null && masterFuncLocName.isNotEmpty) {
            ensureDropdownOption(
              functionalLocationList,
              masterFuncLocName,
              funcLocId,
            );
            selectedFunctionalLocation.value = masterFuncLocName;
            functionalLocationDisplayController.text = masterFuncLocName;
            selectedFuncLocName = masterFuncLocName;
            debugPrint('setAssetDataFromQR: Populated functional location from master data: $masterFuncLocName (funcLocId: $funcLocId)');
          } else {
            // Fallback to funcLocation if master data name is empty
            if (funcLocation != null && funcLocation.isNotEmpty) {
              ensureDropdownOption(
                functionalLocationList,
                funcLocation,
                funcLocId,
              );
              selectedFunctionalLocation.value = funcLocation;
              functionalLocationDisplayController.text = funcLocation;
              selectedFuncLocName = funcLocation;
              debugPrint('setAssetDataFromQR: Populated functional location from funcLocation: $funcLocation (funcLocId: $funcLocId)');
            }
          }
        } else {
          // Fallback to using funcLocation from arguments
          if (funcLocation != null && funcLocation.isNotEmpty) {
            ensureDropdownOption(
              functionalLocationList,
              funcLocation,
              funcLocId,
            );
            selectedFunctionalLocation.value = funcLocation;
            functionalLocationDisplayController.text = funcLocation;
            selectedFuncLocName = funcLocation;
            debugPrint('setAssetDataFromQR: Populated functional location from funcLocation: $funcLocation (funcLocId: $funcLocId)');
          } else if (description != null && description.isNotEmpty) {
            // Last fallback to description
            ensureDropdownOption(
              functionalLocationList,
              description,
              funcLocId,
            );
            selectedFunctionalLocation.value = description;
            functionalLocationDisplayController.text = description;
            selectedFuncLocName = description;
            debugPrint('setAssetDataFromQR: Populated functional location from description: $description (funcLocId: $funcLocId)');
          }
        }
      } else if (funcLocation != null && funcLocation.isNotEmpty) {
        // Fallback if funcLocId is not available, use funcLocation
        ensureDropdownOption(
          functionalLocationList,
          funcLocation,
          funcLocation,
        );
        selectedFunctionalLocation.value = funcLocation;
        functionalLocationDisplayController.text = funcLocation;
        selectedFuncLocName = funcLocation;
        debugPrint('setAssetDataFromQR: Populated functional location without funcLocId: $funcLocation');
      }

      // Refresh dependent dropdowns
      _updateFunctionalLocationAndEquipmentOptions();

      // Ensure the selected functional location remains in the list after filtering
      if (selectedFuncLocName != null && selectedFuncLocName.isNotEmpty) {
        ensureDropdownOption(
          functionalLocationList,
          selectedFuncLocName,
          funcLocId ?? funcLocation ?? '',
        );
        selectedFunctionalLocation.value = selectedFuncLocName;
      }

      // Populate department if provided
      if (department != null && department.isNotEmpty) {
        final deptMatch = departmentList.firstWhere(
              (e) => e.label == department || e.value == deptId,
          orElse: () => LabelValue(label: department, value: deptId ?? '0'),
        );
        selectedDepartment.value = deptMatch.label;
        debugPrint('setAssetDataFromQR: Populated department: $deptMatch.label');
      }

      // Populate location if provided
      if (location != null && location.isNotEmpty) {
        final locMatch = locationTypeList.firstWhere(
              (e) => e.label == location,
          orElse: () => LabelValue(label: location, value: location),
        );
        selectedLocation.value = locMatch.label;
        debugPrint('setAssetDataFromQR: Populated location: $locMatch.label');
      }

    } catch (e) {
      debugPrint('Error in setAssetDataFromQR: $e');
    }
  }

  /// Populates the read-only "Observation Detail" panel when the form is
  /// opened from the Inspection module's "Not Okay" flow. This is distinct
  /// from Joint Inspection (isFromJointInspection) — it's a failure created
  /// FROM an inspection finding, not a request for a joint inspection.
  ///
  /// Accepts either camelCase (app-native) or PascalCase (API) keys since the
  /// exact shape of what the Inspection module hands over via navigation
  /// arguments hasn't been confirmed yet — verify these key names against
  /// that screen and adjust `pick(...)` below if they differ.
  void setInspectionObservationContext(Map<String, dynamic> args) {
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = args[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return null;
    }

    final data = <String, dynamic>{
      'inspectionNo': pick(['inspectionNo', 'InspectionNo']),
      'scheduleDate': pick(
          ['inspectedDateDisplay', 'inspectionScheduleDate', 'ScheduleDate']),
      'createdOn': pick(['createdOnDisplay', 'createdOn', 'CreatedOn']),
      'personResponsible':
      pick(['personResponsible', 'PersonResponsible']),
      'system': pick(['systemName', 'system', 'System']),
      'subSystem': pick(['subSystem', 'SubSystem']),
      'status': pick(['status', 'Status']) ?? 'Not Okay',
      'remark': pick(['remark', 'Remark']),
      'overallRemark': pick(
          ['overallInspectionRemark', 'overallRemark', 'OverallRemark']),
    };

    // Only populate if we actually found something, so the panel stays
    // hidden (inspectionObservation.isEmpty) rather than showing all "N/A".
    if (data.values.any((v) => v != null)) {
      inspectionObservation.assignAll(data);
    }
  }
}