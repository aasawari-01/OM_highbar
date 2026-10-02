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
import '../../../utils/widgets/success_popup.dart';
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

class CreateFailureController extends GetxController
    with
        FailureFormState,
        FailureRcaLogic,
        FailureMaterialLogic,
        FailureSubmitLogic,
        FailureJointInspectionLogic,
        FailureDataLoadingLogic,
        FailureUIHelperLogic {
  final FailureService _failureService = FailureService();

  /// Status returned by getCreateVMModel for an existing Maintenance failure.
  /// Web edit rules use statusId directly (1 / 202 / other).
  final maintenanceStatusId = 0.obs;
  final maintenanceLocationTypeId = 0.obs;

  // ===========================================================================
  // OCC FAILURE (create) — state
  // Shared fields (priority, department, location, functional location,
  // description, sub location, train id, occurrence date, trip / passenger
  // fields, beforeFiles) reuse the existing FailureFormState members.
  // ===========================================================================
  final occLineList = <LabelValue>[].obs;
  final occTrainSetList = <LabelValue>[].obs;
  final occReportedToList = <LabelValue>[].obs;
  final occReportedByList = <LabelValue>[].obs;
  final occFailureCategoryList = <LabelValue>[].obs;
  final occTrainOperatorList = <LabelValue>[].obs;

  final selectedOccLine = RxnString();
  final selectedOccTrainSet = RxnString();
  final selectedOccReportedTo = RxnString();
  final selectedOccTrainOperator = RxnString();

  /// "Failure Frequency of Gear (Last 12 Months)" — read-only, comes from the
  /// selected functional location's master row.
  final occFailureFrequency = RxnInt();

  final occTrainReplaced = false.obs;
  final occReplacedTime = Rxn<DateTime>();
  final occLocationTextController = TextEditingController();
  final occCategoryOtherController = TextEditingController();
  final occReplacedWithController = TextEditingController();
  final occWayOfRescueController = TextEditingController();
  // Read-only display fields (bound to the two values derived from the
  // selected functional location).
  final occFailureFrequencyController = TextEditingController();
  final occSystemDisplayController = TextEditingController();

  // ---- OCC failure (FMC update) state --------------------------------------
  /// Read-only values shown on the FMC update screen.
  final occLineDisplayController = TextEditingController();
  final occTrainSetDisplayController = TextEditingController();
  final occCreatedDateText = ''.obs;

  /// Values carried over from the loaded failure and sent back on save.
  int occLoadedRoleId = 0;
  int occLoadedPriorityId = 0;
  int occLoadedLineId = 0;
  int occLoadedTrainSetId = 0;
  int occLoadedLocationId = 0;
  int occLoadedDepartmentId = 0;
  String occLoadedOccurrenceRaw = '';

  /// Web hides Train Id and the Trip Affected block for station failures.
  final occIsStationFailure = false.obs;
  final occUpdateLoaded = false.obs;

  /// Sub Systems for the System currently picked (from the FMECA pairs).
  List<Map<String, dynamic>> _occFmecaPairs = <Map<String, dynamic>>[];

  static const int occDescriptionMaxLength = 3000;
  static const int occMaxAttachmentBytes = 1024 * 1024; // 1 MB, same as web

  /// Chief Controller: the role that creates OCC failures.
  bool get isOccController {
    final role =
        Get.find<SessionController>().selectedRole.value?.roleDescr ?? '';
    return SessionController.isOccFailureCreatorRole(role);
  }

  /// Chief Controller (not FMC / TPC / CSS / RSC): creates OCC failures and
  /// updates / closes the ones in the OCC failure list.
  bool get isOccRoleUser => isOccController && !isFmcUser;

  /// Web rule: only when "Reported To" is OCC can the OCC user enter the
  /// completed date/time and close the failure.
  bool get occReportedToIsOcc =>
      (selectedOccReportedTo.value ?? '').trim().toUpperCase() == 'OCC';

  /// FMC / TPC / CSS / RSC user: a role an OCC failure can be reported to.
  /// (Name kept from when FMC was the only one.)
  bool get isFmcUser {
    final role =
        Get.find<SessionController>().selectedRole.value?.roleDescr ?? '';
    return SessionController.isOccDelegateRole(role);
  }

  /// Read-only "OCC Failure Details" shown to Section Incharge and JE when a
  /// failure originated from an OCC failure (label, value), empty otherwise.
  final occOriginDetails = <MapEntry<String, String>>[].obs;

  void _applyOccOrigin(CreateVMModel model) {
    // Only failures that came from OCC; nothing for ordinary failures or ones
    // raised by other sources (e.g. "Depot Request"). The API marks them with
    // otherRequestFrom ("OCC Request"); a failure opened from an OCC list
    // (failureCategory is the list type) counts too, in case that is empty.
    final fromOcc =
        (model.otherRequestFrom ?? '').toUpperCase().contains('OCC') ||
            failureCategory.value.toLowerCase() == 'occ';
    if (!fromOcc) {
      occOriginDetails.clear();
      return;
    }

    String v(String? s) => (s == null || s.isEmpty) ? '-' : s;
    // Core fields are always listed (blank shown as "-"); the rest only when
    // OCC actually filled them in.
    final core = <MapEntry<String, String>>[
      MapEntry('Request From', v(model.otherRequestFrom)),
      if ((model.reportedTo ?? '').isNotEmpty)
        MapEntry('Reported To', model.reportedTo!),
      MapEntry('Line', v(model.occLineName)),
      MapEntry('Train Set', v(model.occTrainSetName)),
      MapEntry('Location Text', v(model.occLocationText)),
      MapEntry('Train Id', v(model.occTrainId)),
      MapEntry('System', v(model.occSystemName)),
      MapEntry('Sub Location', v(model.occSubLocation)),
      MapEntry('Failure Category Type', v(model.occFailureCategory)),
    ];
    final optional = <MapEntry<String, String>>[
      MapEntry('Train Operator', model.occTrainOperatorName ?? ''),
      MapEntry('Train Replaced With', model.occTrainReplacedRemark ?? ''),
      MapEntry('Train Replaced Time', model.occTrainReplacedTime ?? ''),
      MapEntry('Way Of Rescue', model.occWayOfRescue ?? ''),
    ].where((e) => e.value.isNotEmpty);
    occOriginDetails.assignAll([...core, ...optional]);
  }

  /// Whether the loaded OCC failure was reported to OCC itself. If it was
  /// reported to FMC / TPC / CSS / RSC, that role owns the update and the OCC
  /// role can only view it.
  final occLoadedReportedToIsOcc = true.obs;

  bool get occRoleViewOnly => isOccRoleUser && !occLoadedReportedToIsOcc.value;

  /// True once the failure has been assigned to a department (a department
  /// notification exists). From then on it belongs to that department's
  /// Section Incharge / JE, so FMC / TPC / CSS / RSC can only view it.
  final occIsAssigned = false.obs;

  bool get occDelegateReadOnly => isFmcUser && occIsAssigned.value;

  /// System / Sub System are fixed on the update form (set when OCC created
  /// the failure), so a functional-location change must not reset them.
  bool get _occSystemFixed => isOccRoleUser || isFmcUser;

  /// The web treats Failure Category Type id 3 ("Other") as needing free text.
  bool get occIsCategoryOther {
    final label = selectedFailureCategoryType.value;
    if (label == null || label.isEmpty) return false;
    final value = lookupValue(occFailureCategoryList, label, fallback: '');
    return value == '3' || label.trim().toLowerCase() == 'other';
  }

  @override
  bool get isMaintenanceFailure =>
      failureCategory.value.toLowerCase() == 'maintenance';

  /// Shows a validation error snackbar with the first error.
  void _showErrorDialog(String message) {
    final lines =
    message.split('\n').where((l) => l.trim().isNotEmpty).toList();
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
          selectedUserStatus.value = "Select User status";
          Get.back();
        },
        onConfirm: () {
          selectedUserStatus.value = "Select User status";
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
    final isSectionIncharge = role.contains('Section Incharge');

    if (isSectionIncharge) {
      // Section Incharge's list (opened as 'Maintenance') shows all failures.
      if (Get.isRegistered<FailureListController>(tag: 'Maintenance')) {
        Future.microtask(() async {
          try {
            await Get.find<FailureListController>(tag: 'Maintenance')
                .fetchFailures();
          } catch (e) {
            debugPrint("Error refreshing Section Incharge failure list: $e");
          }
        });
      }
    } else if (isStationController) {
      // For Station Controller, call API to get updated station failure list
      if (Get.isRegistered<MasterDataSyncService>()) {
        Future.microtask(() async {
          try {
            // Call API to sync station failure list with latest data from server
            await Get.find<MasterDataSyncService>()
                .syncFailureList('Station', forceFullSync: true);
            // Refresh the UI controller to show the updated list
            if (Get.isRegistered<FailureListController>(tag: 'Station')) {
              await Get.find<FailureListController>(tag: 'Station')
                  .fetchFailures();
            }
            debugPrint(
                "refreshFailureListAfterSubmission: Successfully synced station failure list from API");
          } catch (e) {
            debugPrint("Error syncing failure list after creation: $e");
          }
        });
      }
    } else if (isJE) {
      // A JE has several inbox lists (Maintenance, Station, OCC, Depot) and
      // the failure may be opened from any of them, so refresh every one that
      // is currently open.
      for (final controllerTag in const ['Maintenance', 'Station', 'OCC', 'Depot']) {
        if (Get.isRegistered<FailureListController>(tag: controllerTag)) {
          Future.microtask(() async {
            try {
              await Get.find<FailureListController>(tag: controllerTag)
                  .fetchFailures();
            } catch (e) {
              debugPrint("Error refreshing JE failure list ($controllerTag): $e");
            }
          });
        }
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

              reasonForDelayId.value = int.tryParse(match.value ?? "0") ?? 0;
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
    _initFuture = _initializeAllData();
  }

  /// Startup load (local master data + lookup). The Section Incharge loader
  /// waits for it so its API values are not overwritten afterwards.
  Future<void>? _initFuture;

  Future<void> _initializeAllData() async {
    try {
      // Ensure global data is loaded
      if (!_globalData.isLoaded) {
        await _globalData.loadMasterData();
      }

      // Copy global data to local lists
      _copyGlobalDataToLocal(_globalData);
      await loadNotificationTypesFromLocalDb();
      await _ensureLocationsLoaded();

      debugPrint(
          "_initializeAllData: userList count after load = ${userList.length}");
      await loadLookupDataForNewFailure();
      // Auto-select logged-in user in "Failure Reported By" field
      await _autoSelectFailureReportedBy();

      await fetchMasterJointInspectionDepartments();

      // Load lookup data for new failure creation (Nature of Work, Failure Type)

    } catch (e) {
      debugPrint("Error in _initializeAllData: $e");
    }
  }

  /// Person Responsible options exactly as the lookup API returns them
  /// (getUserList), not filtered by department.
  final apiPersonResponsibleList = <LabelValue>[].obs;

  Future<void>? _lookupFuture;

  /// Runs the lookup API once and shares the result with every caller
  /// (initial load and the Section Incharge person list). If it came back
  /// empty (e.g. offline) the next call tries again.
  Future<void> loadLookupDataForNewFailure() =>
      _lookupFuture ??= _fetchLookupDataForNewFailure();

  Future<void> _fetchLookupDataForNewFailure() async {
    try {
      debugPrint("loadLookupDataForNewFailure: Calling lookup API");
      final result = await _failureService.getLookupCreateCorrNotification();

      if (result.responseCode == 200 && result.responseOutput != null) {
        final output = result.responseOutput!;
        print("naturee eof work==${output.getNatureOfWorkList}");
        apiNatureOfWorkList.assignAll(output.getNatureOfWorkList ?? []);
        print("getNotificationTypeList==${output.getNotificationTypeList}");
        apiNotificationTypeList.assignAll(output.getNotificationTypeList ?? []);
        // Drop only the "Select User" placeholder row (value 0).
        apiPersonResponsibleList.assignAll((output.getUserList ?? const <LabelValue>[])
            .where((u) =>
        (u.label ?? '').trim().isNotEmpty &&
            (u.value ?? '').isNotEmpty &&
            u.value != '0'));
        debugPrint(
            "loadLookupDataForNewFailure: Loaded ${apiNatureOfWorkList.length} nature of work items");
        debugPrint(
            "loadLookupDataForNewFailure: Loaded ${apiNotificationTypeList.length} notification type items");
        debugPrint(
            "loadLookupDataForNewFailure: Loaded ${apiPersonResponsibleList.length} person responsible items");
      }
      if (apiPersonResponsibleList.isEmpty && apiNatureOfWorkList.isEmpty) {
        _lookupFuture = null; // nothing came back: allow a retry
      }
    } catch (e) {
      _lookupFuture = null;
      debugPrint("Error loading lookup data for new failure: $e");
      debugPrint(
          "loadLookupDataForNewFailure: API failed - dropdowns will be empty");
      // Do not fallback to local data - use only API data
    }
  }

  /// Loads Notification Type dropdown ONLY from local notificationType.db.
  Future<void> loadNotificationTypesFromLocalDb() async {
    try {
      final notifTypes = await LocalDatabaseService().getNotificationTypes();
      notificationTypeList.assignAll([
        LabelValue(label: 'Select', value: ''),
        ...notifTypes.map((e) => LabelValue(
          label: e.notificationType ?? '',
          value: e.id?.toString() ?? '',
        )),
      ]);
      debugPrint(
          "loadNotificationTypesFromLocalDb: count = ${notificationTypeList.length}");
    } catch (e) {
      debugPrint("loadNotificationTypesFromLocalDb error: $e");
    }
  }

  void _copyGlobalDataToLocal(GlobalMasterDataController globalData) {
    priorityTypeList.assignAll(globalData.priorityTypeList);
    locationTypeList.assignAll(globalData.locationTypeList);
    _syncLocationList();
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

    // NEW: Copy additional master data from asset DB
    // Notification types come ONLY from local notificationType.db (see loadNotificationTypesFromLocalDb)
    natureOfWorkList.assignAll(globalData.natureOfWorkList);
    failureCategoryTypeList.assignAll(globalData.failureCategoryTypeList);

    // Debug logging for new lists
    debugPrint(
        "_copyGlobalDataToLocal: notificationTypeList count = ${notificationTypeList.length}");
    debugPrint(
        "_copyGlobalDataToLocal: natureOfWorkList count = ${natureOfWorkList.length}");
    debugPrint(
        "_copyGlobalDataToLocal: failureCategoryTypeList count = ${failureCategoryTypeList.length}");

    // NEW: Copy JE view data from asset DB
    corrFailureTypeList.assignAll(globalData.corrFailureTypeList);
    userStatusJeList.assignAll(globalData.userStatusJeList);
    userStatusList.assignAll(globalData.userStatusList);
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
    debugPrint(
        "_copyGlobalDataToLocal: masterDepartments count = ${masterDepartments.length}");
    if (masterDepartments.isNotEmpty) {
      debugPrint("_copyGlobalDataToLocal: Sample masterDepartments data:");
      for (int i = 0; i < masterDepartments.length && i < 3; i++) {
        final dept = masterDepartments[i];
        debugPrint(
            "  [$i] DeptName: ${dept['DeptName']}, DeptId: ${dept['DeptId']}");
      }
    }

    // Load master users on-demand if not already loaded
    if (masterUsers.isEmpty) {
      _loadMasterUsersOnDemand();
    } else {
      masterUsers.assignAll(globalData.masterUsers);
    }
  }

  /// Keeps [locationList] (read by the Maintenance form's Location dropdown)
  /// in sync with [locationTypeList]. Previously [locationList] was only filled
  /// inside loadMasterDataFromDb(), which the create flow never calls.
  void _syncLocationList() {
    locationList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...locationTypeList.where(
              (l) => (l.label ?? '').trim().isNotEmpty && l.label != 'Select'),
    ]);
  }

  /// Falls back to the local DB if the global cache had no locations.
  Future<void> _ensureLocationsLoaded() async {
    final hasReal = locationTypeList
        .any((l) => (l.label ?? '').trim().isNotEmpty && l.label != 'Select');
    if (!hasReal) {
      debugPrint(
          '_ensureLocationsLoaded: global cache empty, loading from local DB');
      final locations = await LocalDatabaseService().getLocations();
      masterLocations.assignAll(locations.map((e) => e.toJson()).toList());
      locationTypeList.assignAll([
        LabelValue(label: 'Select', value: ''),
        ...locations.map((e) => LabelValue(
          label: e.locationName,
          value: e.locationTypeId?.toString() ?? '',
        )),
      ]);
    }
    _syncLocationList();
    debugPrint(
        '_ensureLocationsLoaded: locationList count = ${locationList.length}');
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
        debugPrint(
            '  [$i] UserId: ${user['UserId']}, UserName: ${user['UserName']}, DeptId: ${user['DeptId']}, RoleDescr: ${user['RoleDescr']}');
        debugPrint(
            '      camelCase: userName: ${user['userName']}, deptId: ${user['deptId']}, roleDescr: ${user['roleDescr']}');
      }
    }

    // Force UI update
    masterUsers.refresh();
  }

  // Reference to global master data to avoid redundant DB calls
  late final GlobalMasterDataController _globalData;

  @override
  void onClose() {
    occLocationTextController.dispose();
    occCategoryOtherController.dispose();
    occReplacedWithController.dispose();
    occWayOfRescueController.dispose();
    occFailureFrequencyController.dispose();
    occSystemDisplayController.dispose();
    occLineDisplayController.dispose();
    occTrainSetDisplayController.dispose();
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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    const Text("Fetching stations...",
                        style: TextStyle(color: AppColors.textDarkSecondary)),
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
                      child: const Icon(TablerIcons.x,
                          color: AppColors.textDarkPrimary, size: 24),
                    ),
                  ),
                  CustText(
                      name: "Select Station",
                      size: AppConstants.headerSize,
                      color: AppColors.black,
                      fontWeightName: FontWeight.w600),
                  const SizedBox(height: 16),
                  CustDropdown(
                    label: "Station",
                    hint: "Select Station",
                    items: popupStationList.map((e) => e.label ?? '').toList(),
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
                            if (session.selectedStationName.value != null &&
                                session.selectedStationName.value!.isNotEmpty) {
                              Get.back();
                            } else {
                              Get.snackbar(
                                AppStrings.error,
                                "Please select a station",
                                backgroundColor:
                                AppColors.red.withValues(alpha: 0.9),
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
  Map<String, dynamic> _jeScreenRaw = {};
  Future<void> loadJointInspectionDetails(String failureNo) async {
    encryptedId.value = failureNo;
    notificationId.value = 0;
    jointInspectionFailureNo.value = "";
    try {
      isLoading.value = true;
      errorMessage.value = "";

      await loadMasterDataFromDb();

      Map<String, dynamic> json;
      try {
        json = await _failureService.getJIScreenDetailsRaw(failureNo);
      } catch (apiError) {
        debugPrint("loadJointInspectionDetails: API failed: $apiError");
        errorMessage.value = "Failed to load details. Please try again.";
        return;
      }

      final code = json['responseCode'];
      final output = json['responseOutput'];
      if (code == 200 && output is Map<String, dynamic>) {
        await _applyJeScreenDetails(output, failureNo);
      } else {
        errorMessage.value =
            json['responseMessage']?.toString() ?? "Failed to load joint inspection details.";
      }
    } catch (e) {
      errorMessage.value = "An error occurred: $e";
      debugPrint("loadJointInspectionDetails error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Label for an id inside one of the {label,value} lists of the response.
  String _labelFromList(dynamic list, dynamic id) {
    if (list is! List || id == null) return '';
    final idStr = id.toString();
    if (idStr.isEmpty || idStr == '0') return '';
    for (final e in list) {
      if (e is Map && e['value']?.toString() == idStr) {
        return e['label']?.toString() ?? '';
      }
    }
    return '';
  }

  /// API dates look like "06/26/2026 11:00:00" (MM/dd/yyyy) -> try that first.
  DateTime? _parseJeDate(dynamic raw) {
    final s = raw?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    for (final p in ['MM/dd/yyyy HH:mm:ss', 'MM/dd/yyyy HH:mm']) {
      try {
        return DateFormat(p).parseStrict(s);
      } catch (_) {}
    }
    return _parseDate(s);
  }

  Future<void> _applyJeScreenDetails(
      Map<String, dynamic> output, String failureNo) async {
    final je = output['jeScreenDetails'];
    if (je is! Map) {
      errorMessage.value = "No JE screen details returned.";
      return;
    }
    _jeScreenRaw = Map<String, dynamic>.from(je);
    // ---- ids / header -------------------------------------------------------
    encryptedId.value = failureNo;
    notificationId.value = int.tryParse(je['failureNo']?.toString() ?? '') ?? 0;
    notificationCode.value = je['notificationCode']?.toString() ?? '';
    jointInspectionFailureNo.value = je['failureNo']?.toString() ?? '';

    // ---- basic info ---------------------------------------------------------
    failureDescriptionController.text =
        je['failureDescriptions']?.toString() ?? '';
    final priority = je['priorityType']?.toString() ?? '';
    selectedPriority.value = priority.isEmpty ? null : priority;
    priorityDisplayController.text = priority;

    final deptLabel = _labelFromList(output['department'], je['deptId']);
    selectedDepartment.value = deptLabel.isEmpty ? null : deptLabel;
    departmentDisplayController.text = deptLabel;

    if ((je['system'] ?? '').toString().isNotEmpty) {
      systemController.text = je['system'].toString();
    }
    if ((je['subSystem'] ?? '').toString().isNotEmpty) {
      subsystemController.text = je['subSystem'].toString();
    }

    // ---- location (API sends id "0" / "" when nothing chosen) ---------------
    locationDisplayController.text = je['locationTypeName']?.toString() ?? '';

    String funcLabel = (je['functionalLocationName'] ?? '').toString();
    if (funcLabel.isEmpty) {
      funcLabel = _labelFromList(output['functionalLocation'], je['functionLocationId']);
    }
    functionalLocationDisplayController.text = funcLabel;
    if (funcLabel.isNotEmpty) selectedFunctionalLocation.value = funcLabel;

    String equipLabel = (je['equipmentName'] ?? '').toString();
    if (equipLabel.isEmpty) {
      equipLabel = _labelFromList(output['equipment'], je['equipmentId']);
    }
    equipmentDisplayController.text = equipLabel;
    if (equipLabel.isNotEmpty) selectedEquipmentNumber.value = equipLabel;

    // ---- person responsible (id "93" -> "93-Mr.Vaibhav Bhopale") -----------
    final person = _labelFromList(output['personResponsible'], je['personResponsible']);
    selectedPersonResponsible.value = person.isEmpty ? null : person;
    personResponsibleDisplayController.text = person;

    // ---- dates --------------------------------------------------------------
    selectedFailureOccurrenceDate.value = _parseJeDate(je['actualFailureOccuranceOn']);
    selectedFailureAttendedDate.value = _parseJeDate(je['failureAttendedOn']);
    selectedActualFailureRectifiedDate.value = _parseJeDate(je['actualFailureRectifiedOn']);

    // ---- PTW / service / passenger -----------------------------------------
    isPtwRequired.value = je['isPTWReq'] == true;
    ptwNumberController.text = je['ptwNo']?.toString() ?? '';
    isSparePartReplaced.value = je['isHardwareReplaced'] == true;

    isServiceAffected.value = je['isServiceAffected'] == true;
    trainDelayMinController.text = je['trainDelayInMin']?.toString() ?? '';
    trainDelayNosController.text = je['trainDelayInNo']?.toString() ?? '';
    trainCancelNosController.text = je['noOfTranCancel']?.toString() ?? '';
    trainWithdrawalNosController.text = je['noOfTranWithdrawal']?.toString() ?? '';
    trainReplaceNosController.text = je['noOfTrainReplace']?.toString() ?? '';

    isPassengerDeboarding.value = je['isPassengerDeboarding'] == true;
    trainDeboardedNosController.text = je['noofTrainDeboarded']?.toString() ?? '';

    isPassengerAffected.value = je['isPassengerAffected'] == true;
    numberOfPassengerAffectedController.text =
        je['noOfPassengerAffected']?.toString() ?? '';
    trappedDurationController.text = je['trappedDuration']?.toString() ?? '';
    rescuedDurationController.text = je['rescuedDuration']?.toString() ?? '';

    // ---- failure type / rectification (JE flags) ----------------------------
    isJointInspection.value = je['isJointInspectionReq'] == true;

    // ---- joint inspection request the JE raised -----------------------------
    final jiDept = _labelFromList(output['department'], je['deptId_JI']);
    final jiUser = _labelFromList(output['personResponsible'], je['assignedUserId_JI']);
    jiDepartment.value = je['deptId_JI']?.toString();
    jiAssignTo.value = je['assignedUserId_JI']?.toString();
    jiDepartmentDisplayController.text = jiDept;
    jiAssignToDisplayController.text = jiUser;
    jiRemarkDisplayController.text = je['remark_JI']?.toString() ?? '';
    jiUserRemarkController.text = je['userRemark_JI']?.toString() ?? '';

    // JI Functional Location dropdown comes from this API (already filtered
    // for the JI department). Drop the "Select ..." placeholder (value 0).
    final fl = (output['functionalLocation'] as List?) ?? [];
    final flItems = fl
        .where((e) => e['value']?.toString() != '0')
        .map((e) => LabelValue(
        label: e['label']?.toString(), value: e['value']?.toString()))
        .toList();
    if (flItems.isNotEmpty) functionalLocationList.assignAll(flItems);

    // ---- histories ----------------------------------------------------------
    final hist = output['notificationHistory'];
    if (hist is List) {
      try {
        notificationDescriptionHistoryList.assignAll(hist
            .map((e) => NotificationHistory.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList());
      } catch (e) {
        debugPrint('notificationHistory parse error (check keys in '
            'NotificationHistory.fromJson): $e');
      }
    }

    // ---- images -------------------------------------------------------------
    List<Map<String, dynamic>> imgs(dynamic src) => (src is List ? src : [])
        .where((e) => (e['FileName'] ?? '').toString().isNotEmpty)
        .map<Map<String, dynamic>>((e) => {
      'name': e['FileName'].toString().split('/').last,
      'path': e['FileName'].toString(),
      'isNetwork': true,
    })
        .toList();
    beforeImagesList.assignAll(imgs(output['beforeImageDetails']));
    afterImagesList.assignAll(imgs(output['afterImageDetails']));
    rcaImagesList.assignAll(imgs(output['rcaImageDetails']));

    // ---- RCA rows (Object Part / Fault + Root cause + Action) ---------------
    final faults = (output['failureRectificationDetails'] as List?) ?? [];
    final causes = (output['failureRootCauseDetails'] as List?) ?? [];
    final actions = (output['failureActionDetails'] as List?) ?? [];
    rcaDetailsList.clear();
    for (final f in faults) {
      final rectId = f['RectId'];
      rcaDetailsList.add({
        'system': systemController.text,
        'subsystem': subsystemController.text,
        'FailureCategoryId': '0',
        'failureCategory': '',
        'ObjectPartId': '0',
        'objectPart': f['ObjectPart']?.toString() ?? '',
        'objectPartText': f['ObjectPartText']?.toString() ?? '',
        'FaultId': '0',
        'fault': f['Fault']?.toString() ?? '',
        'faultText': f['FaultText']?.toString() ?? '',
        'rootCauses': causes
            .where((c) => c['RectId'] == rectId)
            .map((c) => {
          'causeId': '0',
          'cause': '',
          'rootCauseId': '0',
          'rootCause': c['RCADescs']?.toString() ?? '',
          'causeText': c['RCAText']?.toString() ?? '',
          'imagePath': null,
        })
            .toList(),
        'actionTakens': actions
            .where((a) => a['RectId'] == rectId)
            .map((a) => {
          'actionTakenId': '0',
          'actionTaken': a['ActionDescs']?.toString() ?? '',
          'actionTakenText': a['ActionText']?.toString() ?? '',
          'imagePath': null,
        })
            .toList(),
      });
    }
    await _enrichFromJeChangeNotification(failureNo);
    await filterRcaFailureCategoriesBySystem();
    errorMessage.value = "";
  }

  Future<void> _enrichFromJeChangeNotification(String failureNo) async {
    final needLocation = locationDisplayController.text.trim().isEmpty ||
        functionalLocationDisplayController.text.trim().isEmpty ||
        equipmentDisplayController.text.trim().isEmpty;
    final needSystem = systemController.text.trim().isEmpty ||
        subsystemController.text.trim().isEmpty;
    final needCategory = rcaDetailsList.any(
            (r) => (r['failureCategory'] ?? '').toString().isEmpty);
    if (!needLocation && !needSystem && !needCategory) return;

    try {
      final resp = await _failureService.getFailureDetails(failureNo);
      final model = resp.responseOutput?.getCreateVMModel;
      if (model == null) {
        debugPrint('JI enrich: getCreateVMModel is null');
        return;
      }

      // ---- Location / Functional Location / Equipment ----------------------
      final loc = model.locationName?.trim() ?? '';
      if (loc.isNotEmpty && locationDisplayController.text.trim().isEmpty) {
        locationDisplayController.text = loc;
        selectedLocation.value = loc;
      }
      final fl = model.funcLocation?.trim() ?? '';
      if (fl.isNotEmpty && functionalLocationDisplayController.text.trim().isEmpty) {
        functionalLocationDisplayController.text = fl;
        selectedFunctionalLocation.value = fl;
      }
      final eq = model.equipmentName?.trim() ?? '';
      if (eq.isNotEmpty && equipmentDisplayController.text.trim().isEmpty) {
        equipmentDisplayController.text = eq;
        selectedEquipmentNumber.value = eq;
      }

      // ---- System / Subsystem ----------------------------------------------
      if ((model.systems ?? '').isNotEmpty && systemController.text.isEmpty) {
        systemController.text = model.systems!;
      }
      if ((model.subSystems ?? '').isNotEmpty && subsystemController.text.isEmpty) {
        subsystemController.text = model.subSystems!;
      }

      // ---- RCA rows: subsystem + failure category --------------------------
      List<dynamic> rcaJson = [];
      final src = resp.failureRectificationJson ?? model.failureRectificationJson;
      if (src != null && src.trim().startsWith('[')) {
        try {
          rcaJson = jsonDecode(src) as List;
        } catch (_) {}
      }

      for (var i = 0; i < rcaDetailsList.length; i++) {
        final row = rcaDetailsList[i];
        final api = i < rcaJson.length && rcaJson[i] is Map
            ? rcaJson[i] as Map
            : const {};

        // Subsystem
        final sub = (api['subsystem'] ?? api['SubSystem'] ?? model.subSystems ?? '')
            .toString();
        if (sub.isNotEmpty) row['subsystem'] = sub;
        final sys = (api['system'] ?? api['System'] ?? model.systems ?? '').toString();
        if (sys.isNotEmpty) row['system'] = sys;

        // Failure category (text first, else look up by id)
        var cat = (api['failureCategoryText'] ?? api['FailureCategoryText'] ?? '')
            .toString();
        final catId = (api['failureCategoryId'] ?? api['FailureCategoryId'] ?? '')
            .toString();
        if (cat.isEmpty && catId.isNotEmpty && catId != '0') {
          cat = rcaFailureCategoryList
              .firstWhere((c) => c.value?.toString() == catId,
              orElse: () => LabelValue(label: ''))
              .label ??
              '';
        }
        if (cat.isNotEmpty) {
          row['failureCategory'] = cat;
          row['FailureCategoryId'] = catId.isEmpty ? '0' : catId;
        }
      }
      rcaDetailsList.refresh();
    } catch (e) {
      debugPrint('JI enrich failed: $e');
    }
  }


  Future<void> submitJointInspection() async {
    if (selectedJiFunctionalLocation.value == null ||
        selectedJiFunctionalLocation.value!.isEmpty) {
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


      final String? userIdStr = await AuthManager().getUserId();
      // final String? userName = await AuthManager().getUserName();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;

      final payload = <String, dynamic>{
        ..._jeScreenRaw,
        'NotificationId': resolveNotificationId(),
        'userRemark_JI': jiUserRemarkController.text.trim(),
        'FunctionLocation_JI':
        int.tryParse(jiFunctionalLocationId.value ?? '0') ?? 0,
        'EquipmentId_JI': jiEquipmentId.value ?? 0,
        'AssignedUserId_JI': int.tryParse(jiAssignTo.value ?? '0') ?? 0,
        'DeptId_JI': int.tryParse(jiDepartment.value ?? '0') ?? 0,
        'CreatedBy': userId,
        'UpdatedUserId': userId,
      };
      debugPrint("submitJointInspection: payload=$payload");

      final message = await _failureService.submitJIScreenData(payload);


      Get.back(result: true);
      Get.snackbar(AppStrings.success, message,
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
        if (isJE) await _applyJeApiLists(output);

        // Skip dropdowns from API - use local data instead (much faster, no memory issues)
        // All dropdowns are already loaded from local DB in _copyGlobalDataToLocal()
        // notificationTypeList.assignAll(corrNotificationTypeList);
        // natureOfWorkList.assignAll(output.getNatureOfWorkList ?? []);
        // departmentList.assignAll(output.getDepartmentList ?? []);
        // userList.assignAll(output.getUserList ?? []);
        // objectDataList.assignAll(output.getObjectData ?? []);
        // materialDataList.assignAll(output.getMaterialData ?? []);
        // reasonForDelayList.assignAll(output.getReasonForDelayList ?? []);

        // Notification Type must come from local notificationType.db (not API)
        if (notificationTypeList.length <= 1) {
          await loadNotificationTypesFromLocalDb();
        }

        // Load API-based dropdowns for Maintenance form
        apiNatureOfWorkList.assignAll(output.getNatureOfWorkList ?? []);
        apiNotificationTypeList.assignAll(output.getNotificationTypeList ?? []);
        debugPrint(
            "loadFailureDetails: Loaded ${apiNatureOfWorkList.length} nature of work items from API");
        debugPrint(
            "loadFailureDetails: Loaded ${apiNotificationTypeList.length} notification type items from API");
        // final statuses = output.getUserStatus ?? [];
        // userStatusList.assignAll(statuses.where((status) {
        //   final val = int.tryParse(status.value ?? "999") ?? 999;
        //   return val == 0 || val <= 29;
        // }).toList());
        // storageLocationList.assignAll(output.getStorageLocation ?? []);
        // faultTypeList.assignAll(output.getFaultData ?? []);
        // _mergeLocationDropdownsFromOutput(output);

        // Keep only essential API data that's not available locally
        notificationHistoryList
            .assignAll(output.getNotificationActionUserHistory ?? []);

        notificationDescriptionHistoryList
            .assignAll(output.getNotificationHistory ?? []);

        if (output.getJoinInspectionHistory != null) {
          jointInspectionHistoryList.assignAll(output.getJoinInspectionHistory!
              .map((item) => JointInspectionHistory.fromJson(item))
              .toList());
        }

        // Parse FailureRectificationJson from top-level response if available
        bool rcaLoadedFromOutput = false;
        String? rcaJsonSource =
            failureDetailResponse.failureRectificationJson ??
                output.getCreateVMModel?.failureRectificationJson;

        debugPrint("=== RCA JSON SOURCE CHECK ===");
        debugPrint(
            "failureDetailResponse.failureRectificationJson: ${failureDetailResponse.failureRectificationJson?.length ?? 0} chars");
        debugPrint(
            "failureDetailResponse.failureRectificationJson value: '${failureDetailResponse.failureRectificationJson}'");
        debugPrint(
            "output.getCreateVMModel?.failureRectificationJson: ${output.getCreateVMModel?.failureRectificationJson?.length ?? 0} chars");
        debugPrint(
            "output.getCreateVMModel?.failureRectificationJson value: '${output.getCreateVMModel?.failureRectificationJson}'");
        debugPrint("Final rcaJsonSource: ${rcaJsonSource?.length ?? 0} chars");
        debugPrint("Final rcaJsonSource value: '${rcaJsonSource}'");

        if (output.getCreateVMModel != null) {
          final model = output.getCreateVMModel!;
          _applyOccOrigin(model);
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
              debugPrint(
                  "failureRectificationJson source: ${rcaJsonSource.length} chars");

              dynamic decoded;
              if (rcaJsonSource.startsWith('[')) {
                decoded = jsonDecode(rcaJsonSource);
              } else {
                // Fallback: try to parse as-is in case it's already a list
                decoded = rcaJsonSource;
              }
              debugPrint(
                  "Decoded FailureRectificationJson type: ${decoded.runtimeType}");
              if (decoded is List) {
                final parsedRca = List<Map<String, dynamic>>.from(decoded);
                debugPrint(
                    "RCA Data Check - Parsed FailureRectificationJson: ${parsedRca.length} items");
                debugPrint(
                    "First RCA item: ${parsedRca.isNotEmpty ? parsedRca[0] : 'empty'}");

                // Parse JE format RCA data
                rcaDetailsList.clear();

                // Get system and subsystem from parent model if available
                final parentSystem = model.systems ?? "";
                final parentSubsystem = model.subSystems ?? "";
                debugPrint(
                    "Parent system: '$parentSystem', subsystem: '$parentSubsystem'");
                debugPrint(
                    "Parent subsystem length: ${parentSubsystem.length}");
                debugPrint(
                    "Controller subsystemController.text: '${subsystemController.text}'");

                for (var fault in parsedRca) {
                  debugPrint("Processing fault item: $fault");
                  final List<Map<String, dynamic>> rootCauses = [];
                  // Support both PascalCase and camelCase field names
                  final rootCauseId =
                      fault['rootCauseId'] ?? fault['RootCauseId'];
                  final causeOfFailureId =
                      fault['causeOfFailureId'] ?? fault['CauseOfFailureId'];
                  debugPrint(
                      "rootCauseId: $rootCauseId, causeOfFailureId: $causeOfFailureId");
                  if (rootCauseId != null &&
                      int.tryParse(rootCauseId.toString()) != 0) {
                    rootCauses.add({
                      'causeId': causeOfFailureId?.toString() ?? "0",
                      'cause': fault['cause'] ?? fault['Cause'] ?? "",
                      'rootCauseId': rootCauseId?.toString() ?? "0",
                      'rootCause':
                      fault['rootCause'] ?? fault['RootCause'] ?? "",
                      'causeText': fault['rootCauseText'] ??
                          fault['RootCauseText'] ??
                          "",
                      'imagePath': null
                    });
                    debugPrint("Added root cause: ${rootCauses.last}");
                  }

                  final List<Map<String, dynamic>> actionTakens = [];
                  // Support both PascalCase and camelCase field names
                  final actionTakenId =
                      fault['actionTakenId'] ?? fault['ActionTakenId'];
                  debugPrint("actionTakenId: $actionTakenId");
                  if (actionTakenId != null &&
                      int.tryParse(actionTakenId.toString()) != 0) {
                    actionTakens.add({
                      'actionTakenId': actionTakenId?.toString() ?? "0",
                      'actionTaken':
                      fault['actionTaken'] ?? fault['ActionTaken'] ?? "",
                      'actionTakenText': fault['actionTakenText'] ??
                          fault['ActionTakenText'] ??
                          "",
                      'imagePath': null
                    });
                    debugPrint("Added action taken: ${actionTakens.last}");
                  }

                  // Use system/subsystem from fault item if available, otherwise use parent values
                  // If parent values are empty, use the controller's text fields as fallback
                  final systemValue = fault['system'] ??
                      fault['System'] ??
                      parentSystem ??
                      systemController.text;
                  final subsystemValue = fault['subsystem'] ??
                      fault['SubSystem'] ??
                      parentSubsystem ??
                      subsystemController.text;

                  // Look up failure category name from master data if not provided in the item
                  final failureCategoryId =
                      (fault['failureCategoryId'] ?? fault['FailureCategoryId'])
                          ?.toString() ??
                          "0";
                  String failureCategoryName = fault['failureCategoryText'] ??
                      fault['FailureCategoryText'] ??
                      "";
                  if (failureCategoryName.isEmpty && failureCategoryId != "0") {
                    // Look up from rcaFailureCategoryList (List<LabelValue>)
                    final categoryMatch = rcaFailureCategoryList.firstWhere(
                          (cat) => cat.value?.toString() == failureCategoryId,
                      orElse: () => LabelValue(label: "", value: ""),
                    );
                    if (categoryMatch.label != null &&
                        categoryMatch.label!.isNotEmpty) {
                      failureCategoryName = categoryMatch.label!;
                      debugPrint(
                          "Looked up failure category name: '$failureCategoryName' for ID: $failureCategoryId");
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
                debugPrint(
                    "RCA data loaded from FailureRectificationJson: ${rcaDetailsList.length} items");
                rcaLoadedFromOutput = true;
                debugPrint("=== RCA LOADING END ===");
              }
            } catch (e) {
              debugPrint(
                  "RCA Data Check - Failed to parse FailureRectificationJson: $e");
            }
          } else {
            debugPrint(
                "FailureRectificationJson is null or empty in all sources");
          }

          if (siApiMode) {
            // JE: lists from the details response + GetFailureStandDropDownDataNew
            await _applySiSavedSelections(model, output, loadPersons: false);
          } else {
          await _applyLocationSelectionsFromModel(model, output: output);
          selectedDepartment.value = departmentList
              .firstWhere(
                  (e) =>
              e.value == model.deptId?.toString() ||
                  e.label == model.deptCode,
              orElse: () => LabelValue(label: model.deptCode))
              .label;

          _refilterFunctionalLocationForCurrentSelections();
          await _refilterEquipmentForCurrentSelections();

          final funcToLoad = model.funcLocation ?? selectedFunctionalLocation.value;
          if (funcToLoad != null && funcToLoad.isNotEmpty && funcToLoad != 'Select') {
            final cleanCode = funcToLoad.contains(' - ')
                ? funcToLoad.split(' - ').first.trim()
                : funcToLoad.trim();
            await loadEquipmentsOnDemand(functionalLocationId: cleanCode);
            if (model.equipmentName != null && model.equipmentName!.isNotEmpty) {
              selectedEquipmentNumber.value = model.equipmentName;
              ensureDropdownOption(equipmentList, model.equipmentName!, model.equipmentId?.toString() ?? '');
            }
          }
          }

          await filterRcaFailureCategoriesBySystem();
          final funcLocEntry = masterFunctionalLocations.firstWhere(
                (e) =>
            e['funcLocId']?.toString() ==
                model.functionLocationId?.toString() ||
                e['funcLocation']?.toString() == model.funcLocation?.toString(),
            orElse: () => <String, dynamic>{},
          );
          if (funcLocEntry.isNotEmpty) {
            final objectNumber = funcLocEntry['objectNumber']?.toString();
            final objectKey = funcLocEntry['objectKey']?.toString();
            final valueToUse = (objectNumber != null && objectNumber.isNotEmpty)
                ? objectNumber
                : objectKey;
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

          // Lookup notification type: check notificationTypeList first using notificationTypeId, then fallback to corrNotificationTypeId
          String? matchedNotif;
          if (!siApiMode &&
              model.notificationTypeId != null &&
              model.notificationTypeId != 0) {
            matchedNotif = notificationTypeList
                .firstWhere(
                    (e) => e.value == model.notificationTypeId.toString(),
                orElse: () => LabelValue(label: null))
                .label;
          }
          if (matchedNotif == null || matchedNotif.isEmpty) {
            matchedNotif = corrNotificationTypeList
                .firstWhere(
                    (e) => e.value == model.corrNotificationTypeId.toString(),
                orElse: () => corrNotificationTypeList.isNotEmpty
                    ? corrNotificationTypeList.first
                    : LabelValue(label: null))
                .label;
          }
          selectedNotificationType.value = matchedNotif;

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
            debugPrint(
                "RCA Data Check - getObjectANDFaultList: ${output.getObjectANDFaultList?.length ?? 0} items");
            debugPrint(
                "RCA Data Check - getObjectANDFaultRootCauseList: ${output.getObjectANDFaultRootCauseList?.length ?? 0} items");
            debugPrint(
                "RCA Data Check - getObjectANDFaultActionList: ${output.getObjectANDFaultActionList?.length ?? 0} items");
            debugPrint(
                "RCA Data Check - model.getObjectANDFaultList: ${model.getObjectANDFaultList?.length ?? 0} items");
            debugPrint(
                "RCA Data Check - model.failureRectificationDetails: ${model.failureRectificationDetails?.length ?? 0} chars");
            debugPrint(
                "RCA Data Check - model.failureRectificationDetails value: '${model.failureRectificationDetails}'");
            debugPrint(
                "RCA Data Check - model.failureRectificationJson: ${model.failureRectificationJson?.length ?? 0} chars");
            debugPrint(
                "RCA Data Check - model.failureRectificationJson value: '${model.failureRectificationJson}'");
            debugPrint(
                "RCA Data Check - failureDetailResponse.failureRectificationJson: ${failureDetailResponse.failureRectificationJson?.length ?? 0} chars");
            debugPrint(
                "RCA Data Check - failureDetailResponse.failureRectificationJson value: '${failureDetailResponse.failureRectificationJson}'");

            // Try to parse failureRectificationDetails as JSON if it's not empty
            List<Map<String, dynamic>>? parsedFailureRectification;
            if (model.failureRectificationDetails != null &&
                model.failureRectificationDetails!.isNotEmpty &&
                model.failureRectificationDetails!.length > 5) {
              try {
                final decoded = jsonDecode(model.failureRectificationDetails!);
                if (decoded is List) {
                  parsedFailureRectification =
                  List<Map<String, dynamic>>.from(decoded);
                  debugPrint(
                      "RCA Data Check - Parsed failureRectificationDetails as list: ${parsedFailureRectification.length} items");
                } else if (decoded is Map) {
                  debugPrint(
                      "RCA Data Check - failureRectificationDetails is a Map, keys: ${decoded.keys}");
                }
              } catch (e) {
                debugPrint(
                    "RCA Data Check - Failed to parse failureRectificationDetails: $e");
              }
            }

            // Try to load from model.getObjectANDFaultList if output doesn't have it
            final faultList = output.getObjectANDFaultList ??
                model.getObjectANDFaultList ??
                parsedFailureRectification;
            final rootCauseList = output.getObjectANDFaultRootCauseList ??
                model.getObjectANDFaultRootCauseList;
            final actionList = output.getObjectANDFaultActionList ??
                model.getObjectANDFaultActionList;

            // Try to parse FailureRectificationJson from top-level response or model
            debugPrint("=== MODEL RCA LOADING START ===");
            List<Map<String, dynamic>>? parsedFailureRectificationJson;
            final failureRectificationJsonSource =
                failureDetailResponse.failureRectificationJson ??
                    model.failureRectificationJson;
            debugPrint(
                "failureRectificationJsonSource from model: $failureRectificationJsonSource");
            if (failureRectificationJsonSource != null &&
                failureRectificationJsonSource!.isNotEmpty) {
              try {
                final decoded = jsonDecode(failureRectificationJsonSource!);
                debugPrint(
                    "Decoded model FailureRectificationJson type: ${decoded.runtimeType}");
                if (decoded is List) {
                  parsedFailureRectificationJson =
                  List<Map<String, dynamic>>.from(decoded);
                  debugPrint(
                      "RCA Data Check - Parsed FailureRectificationJson as list: ${parsedFailureRectificationJson.length} items");
                  if (parsedFailureRectificationJson.isNotEmpty) {
                    debugPrint(
                        "First model RCA item: ${parsedFailureRectificationJson[0]}");
                  }
                }
              } catch (e) {
                debugPrint(
                    "RCA Data Check - Failed to parse FailureRectificationJson: $e");
              }
            } else {
              debugPrint("failureRectificationJsonSource is null or empty");
            }

            // Use FailureRectificationJson if available, otherwise use the other lists
            final finalFaultList = parsedFailureRectificationJson ?? faultList;
            debugPrint(
                "finalFaultList type: ${finalFaultList?.runtimeType}, length: ${finalFaultList?.length ?? 0}");
            debugPrint("=== MODEL RCA LOADING END ===");

            if (finalFaultList != null) {
              debugPrint("=== FINAL RCA LOADING START ===");
              debugPrint(
                  "Loading RCA data from API: ${finalFaultList.length} items");
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
                  final rootCauseId =
                      fault['rootCauseId'] ?? fault['RootCauseId'];
                  final causeOfFailureId =
                      fault['causeOfFailureId'] ?? fault['CauseOfFailureId'];
                  final rootCauseLabel =
                      fault['rootCause'] ?? fault['RootCause'] ?? "";
                  final causeLabel = fault['cause'] ?? fault['Cause'] ?? "";

                  debugPrint(
                      "JE RCA - rootCauseId: $rootCauseId, causeOfFailureId: $causeOfFailureId, rootCause: $rootCauseLabel, cause: $causeLabel");

                  // Add root cause if ID exists (allow text to be empty)
                  if (rootCauseId != null &&
                      int.tryParse(rootCauseId.toString()) != null &&
                      int.tryParse(rootCauseId.toString())! > 0) {
                    rootCauses.add({
                      'causeId': causeOfFailureId?.toString() ?? "0",
                      'cause': causeLabel,
                      'rootCauseId': rootCauseId?.toString() ?? "0",
                      'rootCause': rootCauseLabel,
                      'causeText': fault['rootCauseText'] ??
                          fault['RootCauseText'] ??
                          "",
                      'imagePath': null
                    });
                    debugPrint(
                        "Added root cause: ID=$rootCauseId, label=$rootCauseLabel, causeText=${fault['rootCauseText']}");
                  }

                  final List<Map<String, dynamic>> actionTakens = [];
                  // Support both PascalCase and camelCase field names
                  final actionTakenId =
                      fault['actionTakenId'] ?? fault['ActionTakenId'];
                  final actionTakenLabel =
                      fault['actionTaken'] ?? fault['ActionTaken'] ?? "";

                  debugPrint(
                      "JE RCA - actionTakenId: $actionTakenId, actionTaken: $actionTakenLabel");

                  // Add action if ID exists (allow text to be empty)
                  if (actionTakenId != null &&
                      int.tryParse(actionTakenId.toString()) != null &&
                      int.tryParse(actionTakenId.toString())! > 0) {
                    actionTakens.add({
                      'actionTakenId': actionTakenId?.toString() ?? "0",
                      'actionTaken': actionTakenLabel,
                      'actionTakenText': fault['actionTakenText'] ??
                          fault['ActionTakenText'] ??
                          "",
                      'imagePath': null
                    });
                    debugPrint(
                        "Added action taken: ID=$actionTakenId, label=$actionTakenLabel, actionTakenText=${fault['actionTakenText']}");
                  }

                  rcaDetailsList.add({
                    'system': fault['system'] ?? fault['System'] ?? "",
                    'subsystem': fault['subsystem'] ?? fault['SubSystem'] ?? "",
                    'FailureCategoryId': (fault['failureCategoryId'] ??
                        fault['FailureCategoryId'])
                        ?.toString() ??
                        "0",
                    'failureCategory': fault['failureCategoryText'] ??
                        fault['FailureCategoryText'] ??
                        "",
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
                    for (var rc
                    in rootCauseList.where((r) => r['rectId'] == rectId)) {
                      matchedRootCauses.add({
                        'causeId': "0", // API doesn't provide cause ID
                        'cause': rc['rootCasueName'] ??
                            "N/A", // Map root cause name to cause field
                        'rootCauseId': rc['rcaId'].toString(),
                        'rootCause': rc['rootCasueName'] ?? "N/A",
                        'causeText':
                        rc['rcaText'] ?? "", // Map rcaText to causeText
                        'imagePath': null
                      });
                    }
                  }

                  final List<Map<String, dynamic>> matchedActions = [];
                  if (actionList != null) {
                    for (var ac
                    in actionList.where((a) => a['rectId'] == rectId)) {
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
                    'FailureCategoryId':
                    fault['FailureCategoryId']?.toString() ?? "0",
                  });
                }
              }
              debugPrint(
                  "RCA data loaded from API: ${rcaDetailsList.length} items");
              if (rcaDetailsList.isNotEmpty) {
                debugPrint("rcaDetailsList[0]: ${rcaDetailsList[0]}");
              }
              debugPrint("=== FINAL RCA LOADING END ===");
            } else {
              debugPrint(
                  "No RCA data in API response - finalFaultList is null");
            }
          } // End of if (!rcaLoadedFromOutput)

          // Load Material Requirement Details from API
          if (output.getMaterialReqDetails != null &&
              output.getMaterialReqDetails!.isNotEmpty) {
            debugPrint("=== Loading Material Requirement Details ===");
            replacedMaterialsList.clear();
            for (var item in output.getMaterialReqDetails!) {
              final materialId = item['materialid'] ?? item['MaterialId'];
              final materialValue =
                  item['materialValue'] ?? item['MaterialValue'];
              final quantity = item['quantity'] ?? item['Quantity'];
              final issuedQty = item['issuedQty'] ?? item['IssuedQty'];
              final balanceQty = item['balanceQty'] ?? item['BalanceQty'];
              final storageLocation =
                  item['storageLocation'] ?? item['StorageLocation'];
              final storageLocationValue =
                  item['storageLocationValue'] ?? item['StorageLocationValue'];
              final uom =
                  item['unitOfMeasurement'] ?? item['UnitOfMeasurement'];
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
                'RemainingBalanceQTY':
                item['remainingBalanceQTY'] ?? item['RemainingBalanceQTY'],
              });
            }
            debugPrint(
                "Loaded ${replacedMaterialsList.length} material requirement details");
          }

          // Load Material Dismantle Details from API
          if (output.getMaterialDismantleDetails != null &&
              output.getMaterialDismantleDetails!.isNotEmpty) {
            debugPrint("=== Loading Material Dismantle Details ===");
            dismantleMaterialsList.clear();
            for (var item in output.getMaterialDismantleDetails!) {
              final materialId = item['materialId'] ?? item['MaterialId'];
              final materialValue =
                  item['materialValue'] ?? item['MaterialValue'];
              final oldSerialNumber =
                  item['oldSerialNumber'] ?? item['OldSerialNumber'];
              final newSerialNumber =
                  item['newSerialNumber'] ?? item['NewSerialNumber'];
              final oldSerialDismantleDate = item['oldSerialNoDismantleDate'] ??
                  item['OldSerialNoDismantleDate'];
              final newSerialInstallationDate =
                  item['newSerialNoInstallationDate'] ??
                      item['NewSerialNoInstallationDate'];
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
            debugPrint(
                "Loaded ${dismantleMaterialsList.length} material dismantle details");
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

          selectedMaterialType.value =
              mapFailureTypeIdToMaterialType(model.failureTypeId);
          isServiceAffected.value = model.isServiceAffected ?? false;
          isJointInspection.value = model.isJointInspectionReq ?? false;
          isSparePartReplaced.value = model.isHardwareReplaced ?? false;
          isPtwRequired.value = model.isPTWReq ?? false;
          ptwNumberController.text = model.ptwNo ?? "";

          trainDelayMinController.text =
              model.trainDelayInMin?.toString() ?? "";
          trainDelayNosController.text = model.trainDelayInNo?.toString() ?? "";
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
          selectedFailureAttendedDate.value = model.failureAttendedDate != null
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
        _stationDetails = Map<String, dynamic>.from(details as Map);
        originalFailureId.value = details['id'];
        notificationCode.value = details['failureId'] ?? '';
        selectedPriority.value = details['priority'];
        mainStatusName.value = details['statusName'] ??
            details['mainStatusName'] ??
            details['status'] ??
            details['statusDescription'] ??
            'Open';
        failureDescriptionController.text = details['failureDescription'] ?? '';
        selectedDepartment.value = details['departmentName'];
        originalDepartmentId.value =
            details['departmentId_1'] ?? details['departmentId'];
        selectedLocation.value = details['location'];
        originalLocationId.value = details['locationId'];
        selectedFunctionalLocation.value = details['funcationLocation'];
        debugPrint(
            "loadFailureDetails: funcationLocation set to: ${selectedFunctionalLocation.value}");
        final funcToLoad = details['funcationLocation']?.toString();
        if (funcToLoad != null && funcToLoad.isNotEmpty && funcToLoad != 'Select') {
          final cleanCode = funcToLoad.contains(' - ')
              ? funcToLoad.split(' - ').first.trim()
              : funcToLoad.trim();
          await loadEquipmentsOnDemand(functionalLocationId: cleanCode);
        }
        subLocationController.text = details['subLocation'] ?? '';
        systemController.text = details['system'] ?? '';
        trainIdController.text = details['trainId'] ?? '';
        await filterRcaFailureCategoriesBySystem();

        final occurDate = details['actualFailureOccuranceDate'] ??
            details['actualFailureOccuranceDatetime'] ??
            details['actualFailureOccuranceOn'] ??
            details['failureOccuranceDateTime'];
        if (occurDate != null && occurDate.toString().trim().isNotEmpty) {
          selectedFailureOccurrenceDate.value =
              _parseDate(occurDate.toString());
        }
        final completedDate = details['actualFailureCompletedDateTime'] ??
            details['actualFailureCompletedDate'];
        if (completedDate != null && completedDate.toString().trim().isNotEmpty) {
          selectedFailureCompletedDate.value =
              _parseDate(completedDate.toString());
        }

        selectedFailureReportedBy.value = details['failureReportedby'];
        selectedFailureCategoryType.value = details['failureCategoryTypeText'];
        failureRectificationDetailsController.text =
            details['failureRectificationDetails'] ?? '';

        isTripAffected.value = details['isTripAffected'] ?? false;
        tripDelayUplineController.text =
            details['tripDelayUpline']?.toString() ?? '';
        trainCancelNosController.text = details['tripCancel']?.toString() ?? '';
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

      if (selectedPriority.value == null ||
          selectedPriority.value!.isEmpty ||
          selectedPriority.value == 'Select') {
        errors.add("Priority is required.");
      }
      if (selectedDepartment.value == null ||
          selectedDepartment.value!.isEmpty ||
          selectedDepartment.value == 'Select') {
        errors.add("Department is required.");
      }
      final description = failureDescriptionController.text.trim();
      if (description.isEmpty) errors.add("Failure Description is required.");

      if (selectedLocation.value == null ||
          selectedLocation.value!.isEmpty ||
          selectedLocation.value == 'Select') {
        errors.add("Location is required.");
      }
      if (selectedFunctionalLocation.value == null ||
          selectedFunctionalLocation.value!.isEmpty ||
          selectedFunctionalLocation.value == 'Select') {
        errors.add("Functional Location is required.");
      }
      if (selectedFailureOccurrenceDate.value == null) {
        errors.add("Actual Failure Occurrence is required.");
      }
      if (selectedFailureCategoryType.value == null ||
          selectedFailureCategoryType.value!.isEmpty ||
          selectedFailureCategoryType.value == 'Select') {
        errors.add("Failure Category Type is required.");
      }

      if (isServiceAffected.value) {
        if (tripDelayUplineController.text.trim().isEmpty)
          errors.add("Trip Delay Upline is required.");
        if (tripDelayDownlineController.text.trim().isEmpty)
          errors.add("Trip Delay Downline is required.");
        if (trainCancelNosController.text.trim().isEmpty)
          errors.add("Train Cancel Nos is required.");
        if (trainDelayMinController.text.trim().isEmpty)
          errors.add("Train Delay (Min) is required.");
        if (trainWithdrawalNosController.text.trim().isEmpty)
          errors.add("Train Withdrawal Nos is required.");
        if (trainReplaceNosController.text.trim().isEmpty)
          errors.add("Train Replace Nos is required.");
      }

      if (isPassengerDeboarding.value) {
        if (trainDeboardedNosController.text.trim().isEmpty)
          errors.add("Train Deboarded Nos is required.");
      }

      if (isPtwRequired.value) {
        if (ptwNumberController.text.trim().isEmpty)
          errors.add("PTW Number is required.");
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

      // Ids come from the API lists (what the user picked); the saved ids are
      // only a fallback.
      final int pickedLocationId =
      _apiIdFor(locationTypeList, selectedLocation.value);
      final int finalLocationId = pickedLocationId > 0
          ? pickedLocationId
          : (originalLocationId.value ?? 0);
      final int pickedDeptId =
      _apiIdFor(departmentList, selectedDepartment.value);
      final int finalDeptId =
      pickedDeptId > 0 ? pickedDeptId : (originalDepartmentId.value ?? 0);
      final int funcLocId =
      _apiIdFor(functionalLocationList, selectedFunctionalLocation.value);
      final int priorityId =
      _apiIdFor(priorityTypeList, selectedPriority.value);
      final int categoryId = _apiIdFor(
          apiFailureCategoryList, selectedFailureCategoryType.value);

      final Map<String, dynamic> payload = {
        "Id": originalFailureId.value ?? 0,
        "PriorityId": priorityId > 0 ? priorityId : 1,
        "DepartmentIds": finalDeptId.toString(),
        "DepartmentId_1": finalDeptId,
        "DepartmentId_2": 0,
        "DepartmentId_3": 0,
        "FailureDescription": failureDescriptionController.text,
        "LocationId": finalLocationId,
        "SubLocation": subLocationController.text,
        "System": (selectedFmecaSystem.value ?? '').isNotEmpty
            ? selectedFmecaSystem.value
            : systemController.text,
        "SubSystem": selectedFmecaSubsystem.value ?? '',
        "FuncationLocationIds": funcLocId > 0 ? funcLocId.toString() : "",
        "FuncationLocationId_1": funcLocId,
        "FuncationLocationId_2": 0,
        "FuncationLocationId_3": 0,
        "TrainId": trainIdController.text,
        "ActualFailureOccuranceDate":
        selectedFailureOccurrenceDate.value != null
            ? DateFormat("dd-MM-yyyy HH:mm")
            .format(selectedFailureOccurrenceDate.value!)
            : "",
        "FailureReportedbyId": userId,
        "FailureCategoryTypeId": categoryId,
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
      debugPrint(
          "fetchJointInspectionUsers: API disabled, loading from local master data for deptId=$deptId");
      debugPrint(
          "fetchJointInspectionUsers: masterUsers count = ${masterUsers.length}");

      // Show sample user data for debugging
      if (masterUsers.isNotEmpty) {
        debugPrint("fetchJointInspectionUsers: Sample user data:");
        for (int i = 0; i < masterUsers.length && i < 5; i++) {
          final user = masterUsers[i];
          debugPrint(
              "  [$i] UserId: ${user['UserId']}, UserName: ${user['UserName']}, DeptId: ${user['DeptId']}, RoleDescr: ${user['RoleDescr']}");
        }

        // Show users in the target department
        debugPrint("fetchJointInspectionUsers: Users in department $deptId:");
        final deptUsers = masterUsers
            .where((user) => user['DeptId']?.toString() == deptId)
            .toList();
        debugPrint(
            "fetchJointInspectionUsers: Found ${deptUsers.length} users in department $deptId");
        for (int i = 0; i < deptUsers.length && i < 5; i++) {
          final user = deptUsers[i];
          debugPrint(
              "  [$i] UserId: ${user['UserId']}, UserName: ${user['UserName']}, RoleDescr: ${user['RoleDescr']}");
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
        final isValidUser = userId.isNotEmpty &&
            userId != '0' &&
            userName.isNotEmpty &&
            userName.toLowerCase() != 'select user';

        return deptMatch && isValidUser;
      }).toList();

      // Print filtered user list for verification
      debugPrint(
          "fetchJointInspectionUsers: Filtered user list for department $deptId:");
      for (int i = 0; i < filteredUsers.length && i < 10; i++) {
        final user = filteredUsers[i];
        final roleDescr = user['RoleDescr']?.toString() ?? '';
        final firstName = user['FirstName']?.toString() ?? '';
        final lastName = user['LastName']?.toString() ?? '';
        final userName = (firstName + ' ' + lastName).trim();
        debugPrint(
            "  [$i] UserId: ${user['UserId']}, UserName: $userName, DeptId: ${user['DeptId']}, RoleDescr: $roleDescr");
      }
      if (filteredUsers.length > 10) {
        debugPrint("  ... and ${filteredUsers.length - 10} more users");
      }
      debugPrint(
          "fetchJointInspectionUsers: Found ${filteredUsers.length} users for department $deptId");

      // masterUsers has one row per user/role/department mapping, so the same
      // person can appear several times: keep one entry per UserId.
      final seenUserIds = <String>{};
      final uniqueUsers = filteredUsers
          .where((user) => seenUserIds.add(user['UserId']?.toString() ?? ''))
          .toList();

      // Convert to LabelValue
      final labelValueUsers = uniqueUsers.map((user) {
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
      final filtered = locs
          .where((e) =>
      e.label?.trim().isNotEmpty == true &&
          e.label?.toLowerCase() != 'select')
          .toList();
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
      final filtered = funcs
          .where((e) =>
      e.value?.trim().isNotEmpty == true &&
          e.value?.toLowerCase() != 'select' &&
          e.label?.toLowerCase() != 'select functional location')
          .toList();
      if (filtered.isNotEmpty) {
        for (var item in filtered) {
          final labelValue = LabelValue(
            label: item.label ?? '',
            value: item.value ?? '',
          );
          if (!functionalLocationList.any((e) => e.label == labelValue.label)) {
            functionalLocationList.add(labelValue);
          }
          if (!masterFunctionalLocations
              .any((e) => e['funcLocId']?.toString() == item.value)) {
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
      final filtered = equips
          .where((e) =>
      e.label?.trim().isNotEmpty == true &&
          e.label?.toLowerCase() != 'select')
          .toList();
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
    debugPrint(
        '_masterFunctionalLocationName: Looking for functionLocationId=$functionLocationId');
    debugPrint(
        '_masterFunctionalLocationName: masterFunctionalLocations count=${masterFunctionalLocations.length}');
    debugPrint(
        '_masterFunctionalLocationName: functionalLocationList count=${functionalLocationList.length}');

    // First try to find in functionalLocationList (from JE change notification API)
    for (final item in functionalLocationList) {
      if (item.value == functionLocationId.toString()) {
        debugPrint(
            '_masterFunctionalLocationName: Found match in functionalLocationList - label=${item.label}, value=${item.value}');
        return item.label;
      }
    }

    // Then try masterFunctionalLocations (from DB)
    if (masterFunctionalLocations.isNotEmpty) {
      debugPrint(
          '_masterFunctionalLocationName: First item funcLocId=${masterFunctionalLocations.first['funcLocId']}, funcLocationName=${masterFunctionalLocations.first['funcLocationName']}');
    }
    for (final item in masterFunctionalLocations) {
      final idText = functionLocationId.toString();
      if (item['funcLocId']?.toString() == idText ||
          item['functionLocationId']?.toString() == idText) {
        final name = item['funcLocationName']?.toString();
        debugPrint(
            '_masterFunctionalLocationName: Found match in masterFunctionalLocations - funcLocId=${item['funcLocId']}, funcLocationName=$name');
        return name;
      }
    }
    debugPrint(
        '_masterFunctionalLocationName: No match found for functionLocationId=$functionLocationId');
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
      })
  async {
    debugPrint(
        "_applyLocationSelectionsFromModel: Starting - funcLocation=${model.funcLocation}, functionLocationId=${model.functionLocationId}");
    String? locationName = model.locationName?.trim();
    locationName ??= _masterLocationName(model.locationTypeId); // ADD THIS LINE

    String? funcLocation = model.funcLocation?.trim();
    funcLocation ??= _masterFunctionalLocationName(model.functionLocationId);
    debugPrint(
        "_applyLocationSelectionsFromModel: After lookup - funcLocation=$funcLocation");
    String? equipmentName = model.equipmentName?.trim();

    equipmentName ??= _labelFromValueList(equipmentList, model.equipmentId);
    equipmentName ??= _masterEquipmentName(model.equipmentId);

    if (locationName != null && locationName.isNotEmpty) {
      final locationId = model.locationTypeId?.toString() ?? '';

      ensureDropdownOption(
        locationTypeList,
        locationName,
        locationId,
      );

      selectedLocation.value = locationName;
      locationDisplayController.text = locationName;

      maintenanceLocationTypeId.value =
          int.tryParse(locationId) ?? 0;

      debugPrint(
        'Existing Maintenance Location: '
            'name=$locationName, '
            'LocationTypeId=${maintenanceLocationTypeId.value}',
      );
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
      debugPrint(
          "_applyLocationSelectionsFromModel: Looking for functional location - funcLocId: ${model.functionLocationId}, funcLocation: ${model.funcLocation}");
      debugPrint(
          "_applyLocationSelectionsFromModel: masterFunctionalLocations count: ${masterFunctionalLocations.length}");
      debugPrint(
          "_applyLocationSelectionsFromModel: Current systemController.text: '${systemController.text}', subsystemController.text: '${subsystemController.text}'");
      if (masterFunctionalLocations.isNotEmpty) {
        debugPrint(
            "_applyLocationSelectionsFromModel: Sample functional locations: ${masterFunctionalLocations.take(3).map((e) => {
              'funcLocId': e['funcLocId'],
              'funcLocation': e['funcLocation'],
              'techObjectType': e['techObjectType'],
              'subSystem': e['subSystem']
            }).toList()}");
      }
      final funcLocEntry = masterFunctionalLocations.firstWhere(
            (e) =>
        e['funcLocId']?.toString() ==
            model.functionLocationId?.toString() ||
            (model.funcLocation != null &&
                e['funcLocation']?.toString() ==
                    model.funcLocation?.toString()),
        orElse: () => <String, dynamic>{},
      );

      debugPrint(
          "_applyLocationSelectionsFromModel: Found functional location entry: ${funcLocEntry.isNotEmpty}");
      if (funcLocEntry.isNotEmpty) {
        debugPrint(
            "_applyLocationSelectionsFromModel: funcLocEntry data: $funcLocEntry");
        // Only populate from functional location if API didn't provide system/subsystem
        final techObjectType = funcLocEntry['techObjectType']?.toString() ??
            funcLocEntry['objectKey']?.toString() ??
            '';
        final subSystem = funcLocEntry['subSystem']?.toString() ?? '';

        debugPrint(
            "_applyLocationSelectionsFromModel: techObjectType='$techObjectType', subSystem='$subSystem'");

        if (systemController.text.isEmpty && techObjectType.isNotEmpty) {
          systemController.text = techObjectType;
          debugPrint(
              "_applyLocationSelectionsFromModel: Set system from functional location");
        }
        if (subsystemController.text.isEmpty && subSystem.isNotEmpty) {
          subsystemController.text = subSystem;
          debugPrint(
              "_applyLocationSelectionsFromModel: Set subsystem from functional location");
        }
        debugPrint(
            "Populated system: ${systemController.text}, subsystem: ${subsystemController.text}");
        await filterRcaFailureCategoriesBySystem();
      } else {
        debugPrint(
            "_applyLocationSelectionsFromModel: Functional location not found in master data");
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
    if (funcLocationLabel == null ||
        funcLocationLabel.isEmpty ||
        funcLocationLabel == 'Select') {
      return null;
    }
    final cleanCode = funcLocationLabel.contains(' - ')
        ? funcLocationLabel.split(' - ').first.trim()
        : funcLocationLabel.trim();

    final func = masterFunctionalLocations.firstWhere(
          (e) => e['funcLocationName']?.toString() == funcLocationLabel ||
          e['funcLocation']?.toString() == funcLocationLabel ||
          e['funcLocation']?.toString().toUpperCase() == cleanCode.toUpperCase(),
      orElse: () => <String, dynamic>{},
    );
    final code = func['funcLocation']?.toString();
    return (code != null && code.isNotEmpty) ? code : cleanCode;
  }

  /// Direct filter: equipment.location == Location.locationTypeCode (if provided)
  /// AND equipment.functionalLocation == FunctionalLocation.funcLocation (if provided).
  List<Map<String, dynamic>> _filterEquipments(
      {String? locCode, String? funcLocCode}) {
    Iterable<Map<String, dynamic>> filtered = masterEquipments;

    if (locCode != null && locCode.isNotEmpty) {
      final cleanLoc = locCode.contains(' - ')
          ? locCode.split(' - ').first.trim().toUpperCase()
          : locCode.trim().toUpperCase();
      filtered = filtered.where((eq) {
        final eqLoc = eq['location']?.toString().trim().toUpperCase() ?? '';
        return eqLoc == cleanLoc || eqLoc == locCode.trim().toUpperCase();
      });
    }

    if (funcLocCode != null && funcLocCode.isNotEmpty) {
      final cleanFunc = funcLocCode.contains(' - ')
          ? funcLocCode.split(' - ').first.trim().toUpperCase()
          : funcLocCode.trim().toUpperCase();
      filtered = filtered.where((eq) {
        final eqFl = eq['functionalLocation']?.toString().trim().toUpperCase() ?? '';
        final eqClean = eqFl.contains(' - ')
            ? eqFl.split(' - ').first.trim().toUpperCase()
            : eqFl;
        return eqFl == funcLocCode.trim().toUpperCase() ||
            eqFl == cleanFunc ||
            eqClean == cleanFunc;
      });
    }

    return filtered.toList();
  }

  Future<void> onDepartmentChanged(String? departmentLabel) async {
    if (siApiMode) return _onSiDepartmentChanged(departmentLabel);
    selectedDepartment.value =
    (departmentLabel == null || departmentLabel == 'Select')
        ? null
        : departmentLabel;

    // Set departmentId based on selected department label
    if (departmentLabel != null && departmentLabel != 'Select') {
      final dept = departmentList.firstWhere(
            (d) => d.label == departmentLabel,
        orElse: () => LabelValue(value: '0'),
      );
      departmentId.value = int.tryParse(dept.value ?? '0') ?? 0;
      debugPrint(
          "onDepartmentChanged: Set departmentId to ${departmentId.value} for department: $departmentLabel");
    } else {
      departmentId.value = null;
      debugPrint("onDepartmentChanged: Cleared departmentId");
    }
    if (isSectionIncharge) await loadPersonResponsibleForDept();
    resetFunctionalAndEquipmentSelections();

    // Load functional locations on-demand when department changes
    await loadFunctionalLocationsOnDemand();

    _updateFunctionalLocationAndEquipmentOptions();
    await filterRcaFailureCategoriesBySystem();

    // OCC role: the System / Sub System options depend on the department.
    if (isOccRoleUser && failureCategory.value.toLowerCase() == 'occ') {
      await loadOccSystemSubsystems();
    }
  }

  int get selectedLocationTypeId {
    final selected = selectedLocation.value;

    if (selected == null ||
        selected.isEmpty ||
        selected == 'Select') {
      return 0;
    }

    final item = locationTypeList.firstWhereOrNull(
          (e) => e.label?.trim() == selected.trim(),
    );

    return int.tryParse(item?.value ?? '0') ?? 0;
  }

  Future<void> onLocationChanged(String? locationLabel) async {
    if (siApiMode) return _onSiLocationChanged(locationLabel);
    if (locationLabel == null ||
        locationLabel.isEmpty ||
        locationLabel == 'Select') {
      selectedLocation.value = null;
      maintenanceLocationTypeId.value = 0;

      resetFunctionalAndEquipmentSelections();

      await loadFunctionalLocationsOnDemand();
      _updateFunctionalLocationAndEquipmentOptions();
      return;
    }

    selectedLocation.value = locationLabel;

    final location = locationTypeList.firstWhereOrNull(
          (e) => e.label?.trim() == locationLabel.trim(),
    );

    maintenanceLocationTypeId.value =
        int.tryParse(location?.value ?? '0') ?? 0;

    debugPrint(
      'onLocationChanged: '
          'Location=$locationLabel, '
          'LocationTypeId=${maintenanceLocationTypeId.value}',
    );

    resetFunctionalAndEquipmentSelections();

    await loadFunctionalLocationsOnDemand();

    _updateFunctionalLocationAndEquipmentOptions();
  }

  void _updateFunctionalLocationAndEquipmentOptions() async {
    // Safety check: if masterFunctionalLocations is empty, don't crash
    if (masterFunctionalLocations.isEmpty) {
      debugPrint(
          '_updateFunctionalLocationAndEquipmentOptions: masterFunctionalLocations is empty, skipping');
      return;
    }

    final hasLocation =
        selectedLocation.value != null && selectedLocation.value != 'Select';
    final hasDept = selectedDepartment.value != null &&
        selectedDepartment.value != 'Select';

    String? locCode;
    if (hasLocation) {
      locCode = locationCodeForLabel(selectedLocation.value);
    }

    String? workCenter;
    if (hasDept) {
      workCenter = getCurrentWorkCenterFromDept();
    }

    debugPrint(
        '_updateFunctionalLocationAndEquipmentOptions: hasLocation=$hasLocation, locCode=$locCode, hasDept=$hasDept, workCenter=$workCenter');

    final filteredFuncs = masterFunctionalLocations.where((e) {
      bool match = true;

      if (hasLocation && locCode != null && locCode.isNotEmpty) {
        final funcLoc = e['location']?.toString().trim().toUpperCase();
        if (funcLoc != null && funcLoc.isNotEmpty) {
          // Only filter if funcLoc is not empty
          match = match && (funcLoc == locCode.trim().toUpperCase());
        }
      }

      if (hasDept && workCenter != null && workCenter.isNotEmpty) {
        final funcWorkCenter = e['workCenter']?.toString().trim().toUpperCase();
        if (funcWorkCenter != null && funcWorkCenter.isNotEmpty) {
          // Only filter if funcWorkCenter is not empty
          match = match && (funcWorkCenter == workCenter.trim().toUpperCase());
        }
      }

      return match;
    }).toList();

    debugPrint(
        '_updateFunctionalLocationAndEquipmentOptions: Filtered to ${filteredFuncs.length} functional locations');
    setFunctionalLocationOptions(filteredFuncs);

    // Equipment is only populated once a Functional Location is selected.
    // Location alone should narrow Functional Location choices, not Equipment.
    final hasFuncLoc = selectedFunctionalLocation.value != null &&
        selectedFunctionalLocation.value != 'Select';
    if (hasFuncLoc) {
      final funcLocCode =
      _funcLocationCodeForLabel(selectedFunctionalLocation.value);
      final filteredEquipments =
      _filterEquipments(locCode: locCode, funcLocCode: funcLocCode);
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
    if (siApiMode) return _onSiFunctionalLocationChanged(funcLabel);
    debugPrint('onFunctionalLocationChanged: funcLabel=$funcLabel');

    // ------------------------------------------------------------
    // CLEAR DATA WHEN FUNCTIONAL LOCATION IS CLEARED
    // ------------------------------------------------------------
    if (funcLabel == null || funcLabel == 'Select') {
      selectedFunctionalLocation.value =
      funcLabel == 'Select' ? 'Select' : null;

      selectedEquipmentNumber.value = 'Select';
      showMeasurementButton.value = false;

      setEquipmentOptions([]);

      systemController.clear();
      subsystemController.clear();

      // Clear Location also
      selectedLocation.value = null;
      locationDisplayController.clear();

      return;
    }

    // ------------------------------------------------------------
    // SET SELECTED FUNCTIONAL LOCATION
    // ------------------------------------------------------------
    selectedFunctionalLocation.value = funcLabel;
    selectedEquipmentNumber.value = 'Select';

    final cleanCode = funcLabel.contains(' - ')
        ? funcLabel.split(' - ').first.trim()
        : funcLabel.trim();

    // ------------------------------------------------------------
    // FIND FUNCTIONAL LOCATION MASTER DATA
    // ------------------------------------------------------------
    Map<String, dynamic> func = masterFunctionalLocations.firstWhere(
          (e) {
        final name = e['funcLocationName']?.toString().trim() ?? '';
        final loc = e['funcLocation']?.toString().trim() ?? '';

        return (name.isNotEmpty ? name : loc) == funcLabel.trim() ||
            loc.toUpperCase() == cleanCode.toUpperCase() ||
            name.toUpperCase().startsWith(cleanCode.toUpperCase());
      },
      orElse: () => <String, dynamic>{},
    );

    // If not found in memory, query local fun_loc database
    if (func.isEmpty) {
      try {
        final funLocDb = await LocalDatabaseService().funLocDatabase;
        final tables = await funLocDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        final tableName = tables
            .map((t) => t['name'] as String)
            .firstWhere((n) => n != 'sqlite_sequence' && n != 'android_metadata', orElse: () => '');
        if (tableName.isNotEmpty) {
          final res = await funLocDb.rawQuery(
            'SELECT * FROM "$tableName" WHERE UPPER(TRIM(FuncLocation)) = UPPER(?) LIMIT 1',
            [cleanCode],
          );
          if (res.isNotEmpty) {
            final row = res.first;
            func = {
              'funcLocId': row['FuncLocId'],
              'funcLocation': row['FuncLocation'],
              'funcLocationName': row['FuncLocationName'] ?? row['FuncLocation'],
              'location': row['Location'],
              'workCenter': row['WorkCenter'],
              'techObjectType': row['TechObjectType'],
              'subSystem': row['SubSystem'],
              'objectNumber': row['ObjectNumber'],
              'objectKey': row['ObjectKey'],
            };
            masterFunctionalLocations.add(func);
            debugPrint('onFunctionalLocationChanged: Resolved from funLocDatabase: $func');
          }
        }
      } catch (e) {
        debugPrint('onFunctionalLocationChanged DB lookup error: $e');
      }
    }

    if (func.isEmpty) {
      debugPrint(
        'onFunctionalLocationChanged: Functional location not found in DB for $funcLabel, using fallback map',
      );
      func = {
        'funcLocation': cleanCode,
        'funcLocationName': funcLabel,
      };
    }

    debugPrint(
      'onFunctionalLocationChanged: Functional location data keys: '
          '${func.keys.toList()}',
    );

    debugPrint(
      'onFunctionalLocationChanged: Functional location full data: $func',
    );

    final funcObjectNumber = func['objectNumber']?.toString();

    debugPrint(
      'onFunctionalLocationChanged: '
          'Functional location objectNumber: $funcObjectNumber',
    );

    // ------------------------------------------------------------
    // POPULATE SYSTEM
    // ------------------------------------------------------------
    systemController.text =
        func['techObjectType']?.toString() ??
            func['objectKey']?.toString() ??
            '';

    // ------------------------------------------------------------
    // POPULATE SUBSYSTEM
    // ------------------------------------------------------------
    subsystemController.text =
        func['subSystem']?.toString() ?? '';

    // ------------------------------------------------------------
    // RCA DEBUG
    // ------------------------------------------------------------
    debugPrint(
      'onFunctionalLocationChanged: '
          'corrNotificationTypeList count before: '
          '${corrNotificationTypeList.length}',
    );

    debugPrint(
      'onFunctionalLocationChanged: '
          'corrNotificationTypeList items: '
          '${corrNotificationTypeList.map((e) => e.label).toList()}',
    );

    // ============================================================
// AUTO-SELECT LOCATION BASED ON FUNCTIONAL LOCATION
// ============================================================

    final funcLocationCode =
    func['location']?.toString().trim();

    debugPrint(
      '========== AUTO LOCATION START ==========',
    );

    debugPrint(
      'Selected Functional Location = $funcLabel',
    );

    debugPrint(
      'Functional Location Code = $funcLocationCode',
    );

    debugPrint(
      'Location Type List Count = ${locationTypeList.length}',
    );

    debugPrint(
      'Master Locations Count = ${masterLocations.length}',
    );

    LabelValue? locationMatch;

// ------------------------------------------------------------
// 1. MATCH locationTypeList.value
// ------------------------------------------------------------

    if (funcLocationCode != null &&
        funcLocationCode.isNotEmpty) {
      locationMatch = locationTypeList.firstWhereOrNull(
            (e) =>
        e.value?.toString().trim().toUpperCase() ==
            funcLocationCode.toUpperCase(),
      );
    }

// ------------------------------------------------------------
// 2. MATCH locationTypeList.uniqueId
// ------------------------------------------------------------

    if (locationMatch == null &&
        funcLocationCode != null &&
        funcLocationCode.isNotEmpty) {
      locationMatch = locationTypeList.firstWhereOrNull(
            (e) =>
        e.uniqueId?.toString().trim().toUpperCase() ==
            funcLocationCode.toUpperCase(),
      );
    }

// ------------------------------------------------------------
// 3. MATCH locationTypeList.label
// ------------------------------------------------------------

    if (locationMatch == null &&
        funcLocationCode != null &&
        funcLocationCode.isNotEmpty) {
      locationMatch = locationTypeList.firstWhereOrNull(
            (e) =>
        e.label?.toString().trim().toUpperCase() ==
            funcLocationCode.toUpperCase(),
      );
    }

// ------------------------------------------------------------
// 4. MATCH MASTER LOCATIONS
// ------------------------------------------------------------

    if (locationMatch == null &&
        funcLocationCode != null &&
        funcLocationCode.isNotEmpty) {

      for (final location in masterLocations) {

        final locationTypeId =
        location['locationTypeId']?.toString().trim();

        final locationTypeCode =
        location['locationTypeCode']?.toString().trim();

        final locationName =
        location['locationName']?.toString().trim();

        if (locationTypeId == funcLocationCode ||
            locationTypeCode?.toUpperCase() ==
                funcLocationCode.toUpperCase() ||
            locationName?.toUpperCase() ==
                funcLocationCode.toUpperCase()) {

          locationMatch = LabelValue(
            label: locationName,
            value: locationTypeId ?? '',
          );

          break;
        }
      }
    }

// ------------------------------------------------------------
// 5. SET LOCATION
// ------------------------------------------------------------

    if (locationMatch != null &&
        locationMatch.label != null &&
        locationMatch.label!.trim().isNotEmpty) {

      final locationLabel =
      locationMatch.label!.trim();

      final locationValue =
          locationMatch.value?.toString() ?? '';

      // VERY IMPORTANT:
      // Make sure this option exists in dropdown items.
      ensureDropdownOption(
        locationTypeList,
        locationLabel,
        locationValue,
      );

      // Set selected Location
      selectedLocation.value = locationLabel;

      // Set Location ID
      maintenanceLocationTypeId.value =
          int.tryParse(locationValue) ?? 0;

      // Update display controller
      locationDisplayController.text =
          locationLabel;

      debugPrint(
        '========== AUTO LOCATION SUCCESS ==========',
      );

      debugPrint(
        'Location Label = $locationLabel',
      );

      debugPrint(
        'Location Value = $locationValue',
      );

      debugPrint(
        'Selected Location = ${selectedLocation.value}',
      );

    } else {

      debugPrint(
        '========== AUTO LOCATION FAILED ==========',
      );

      debugPrint(
        'Could NOT find Location for '
            'Functional Location Code = $funcLocationCode',
      );
    }

    final funcWorkCenter =
    func['workCenter']?.toString().trim();

    debugPrint(
      'onFunctionalLocationChanged: '
          'funcWorkCenter="$funcWorkCenter"',
    );

    if (funcWorkCenter != null &&
        funcWorkCenter.isNotEmpty) {
      LabelValue? deptMatch;

      // ----------------------------------------------------------
      // MATCH DEPARTMENT BY UNIQUE ID
      // ----------------------------------------------------------
      for (var dept in departmentList) {
        if (dept.uniqueId?.toString().trim() ==
            funcWorkCenter) {
          deptMatch = dept;
          break;
        }
      }

      // ----------------------------------------------------------
      // MATCH DEPARTMENT BY WORK CENTER
      // ----------------------------------------------------------
      if (deptMatch == null) {
        for (var dept in departmentList) {
          final wc = getWorkCenterForDept(
            dept.value,
            deptLabel: dept.label,
          );

          if (wc?.toString().trim() == funcWorkCenter) {
            deptMatch = dept;
            break;
          }
        }
      }

      // ----------------------------------------------------------
      // SET DEPARTMENT
      // ----------------------------------------------------------
      if (deptMatch != null &&
          deptMatch.label?.trim().isNotEmpty == true) {
        selectedDepartment.value =
            deptMatch.label;

        departmentDisplayController.text =
            deptMatch.label ?? '';

        debugPrint(
          'onFunctionalLocationChanged: '
              'Department AUTO SELECTED = ${deptMatch.label}',
        );
      }
    }

    // ============================================================
    // UPDATE FUNCTIONAL LOCATION / EQUIPMENT OPTIONS
    // ============================================================

    ensureDropdownOption(
      functionalLocationList,
      funcLabel,
      func['funcLocId']?.toString() ??
          func['funcLocation']?.toString() ??
          '',
    );

    selectedFunctionalLocation.value = funcLabel;

    _updateFunctionalLocationAndEquipmentOptions();

    selectedFunctionalLocation.value = funcLabel;

    // ============================================================
    // EQUIPMENT
    // ============================================================

    final funcCode =
    func['funcLocation']?.toString().trim();

    debugPrint(
      'onFunctionalLocationChanged: '
          'funcCode=$funcCode, '
          'funcLocId=${func['funcLocId']}',
    );

    if (funcCode != null &&
        funcCode.isNotEmpty) {
      // ----------------------------------------------------------
      // LOAD EQUIPMENT ON DEMAND
      // ----------------------------------------------------------
      debugPrint(
        'onFunctionalLocationChanged: '
            'Calling loadEquipmentsOnDemand with '
            'funcCode=$funcCode',
      );

      await loadEquipmentsOnDemand(
        functionalLocationId: funcCode,
      );

      // ----------------------------------------------------------
      // MEASUREMENT POINTS
      // ----------------------------------------------------------
      final funcObjectNumber =
      func['objectNumber']?.toString();

      debugPrint(
        'onFunctionalLocationChanged: '
            'Functional location objectNumber: '
            '$funcObjectNumber',
      );

      _checkMeasurementPoints(
        funcObjectNumber,
      );

      // ==========================================================
      // FMECA - SECTION INCHARGE
      // ==========================================================

      if (isSectionIncharge) {
        final locationTypeId =
        selectedLocation.value != null
            ? locationCodeForLabel(
          selectedLocation.value,
        )
            : '';

        final funcLocId =
            func['funcLocId']?.toString() ??
                func['funcLocation']?.toString() ??
                '';

        if (locationTypeId != null &&
            locationTypeId.isNotEmpty &&
            funcLocId.isNotEmpty) {
          debugPrint(
            'onFunctionalLocationChanged: '
                'Loading FMECA data for Section Incharge',
          );

          await fetchFmecaSystemSubsystemByFuncLoc(
            locationTypeId,
            funcLocId,
          );

          // ------------------------------------------------------
          // SET FREQUENCY
          // ------------------------------------------------------
          final frequency =
              func['frequency'] ?? 0;

          fmecaFrequency.value =
          frequency is int
              ? frequency
              : int.tryParse(
            frequency.toString(),
          ) ??
              0;

          fmecaFrequencyController.text =
              fmecaFrequency.value.toString();
        }
      }
    }
  }
  /// Re-filters equipmentList to match the currently selected Location/Functional Location.
  /// Call this after loading an existing failure's details, since those flows set the
  /// selections directly without going through the normal filter path.
  Future<void> _refilterEquipmentForCurrentSelections() async {
    final hasLocation =
        selectedLocation.value != null && selectedLocation.value != 'Select';
    final hasFuncLoc = selectedFunctionalLocation.value != null &&
        selectedFunctionalLocation.value != 'Select';

    if (!hasFuncLoc) {
      // No functional location resolved — nothing to filter equipment by; leave as-is
      return;
    }

    final locCode =
    hasLocation ? locationCodeForLabel(selectedLocation.value) : null;
    final funcLocCode =
        _funcLocationCodeForLabel(selectedFunctionalLocation.value) ??
            (selectedFunctionalLocation.value!.contains(' - ')
                ? selectedFunctionalLocation.value!.split(' - ').first.trim()
                : selectedFunctionalLocation.value!.trim());

    if (masterEquipments.isEmpty) {
      await loadEquipmentsOnDemand(functionalLocationId: funcLocCode);
    } else {
      final filtered =
      _filterEquipments(locCode: locCode, funcLocCode: funcLocCode);
      if (filtered.isNotEmpty) {
        setEquipmentOptions(filtered);
      } else {
        await loadEquipmentsOnDemand(functionalLocationId: funcLocCode);
      }
    }
  }

  /// Re-filters functionalLocationList to match the currently selected Department
  /// (via workCenter) and Location. Preserves the currently selected functional
  /// location even if it falls outside the filter, so server-loaded data doesn't disappear.
  void _refilterFunctionalLocationForCurrentSelections() {
    final hasLocation =
        selectedLocation.value != null && selectedLocation.value != 'Select';
    final hasDept = selectedDepartment.value != null &&
        selectedDepartment.value != 'Select';

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
        workCenter = getWorkCenterForDept(dept.value,
            deptLabel: selectedDepartment.value);
      }
    }

    final filteredFuncs = masterFunctionalLocations.where((e) {
      bool match = true;
      if (hasLocation && locCode != null && locCode.isNotEmpty) {
        match = match &&
            (e['location']?.toString().trim().toUpperCase() ==
                locCode.trim().toUpperCase());
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
    if (currentFuncLoc != null &&
        currentFuncLoc.isNotEmpty &&
        currentFuncLoc != 'Select') {
      ensureDropdownOption(functionalLocationList, currentFuncLoc, '');
    }
  }

  Future<void> onEquipmentChanged(String? equipLabel) async {
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
    debugPrint(
        "onEquipmentChanged: Equipment object number: $equipObjectNumber");
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
      List<MeasurementPointModel> matchingMeasurements = await dbService
          .getMeasurementPointsFromLocal(objectNumber: objectNumber);

      // If local DB has no results, query assets database directly with filter
      if (matchingMeasurements.isEmpty) {
        debugPrint(
            "_checkMeasurementPoints: No results from local DB, querying assets database with filter");
        matchingMeasurements = await dbService
            .getMeasurementPointsFromAssetsFiltered(objectNumber);

        // Insert matching results into local DB for future use
        if (matchingMeasurements.isNotEmpty) {
          await dbService.insertMeasurementPoints(matchingMeasurements);
          debugPrint(
              "_checkMeasurementPoints: Inserted ${matchingMeasurements.length} measurement points into local DB");
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
        debugPrint(
            "_checkMeasurementPoints: Found ${matchingMeasurements.length} measurement points for objectNumber: $objectNumber");
      } else {
        measurementPointsList.clear();
        showMeasurementButton.value = false;
        debugPrint(
            "_checkMeasurementPoints: No matching measurement points for objectNumber: $objectNumber");
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
      final wcMatch = workCenter.isEmpty ||
          (c.workCenter ?? '').isEmpty ||
          (c.workCenter ?? '')
              .toLowerCase()
              .contains(workCenter.toLowerCase());
      final baMatch = businessArea.isEmpty ||
          (c.businessArea == null) ||
          c.businessArea.toString() == businessArea;
      final catMatch = failureCategoryId == null ||
          failureCategoryId.isEmpty ||
          c.failureCategoryId?.toString().trim() ==
              failureCategoryId.trim();
      final sysMatch = currentSystem.isEmpty ||
          (c.systems ?? '').isEmpty ||
          (c.systems ?? '')
              .toLowerCase()
              .contains(currentSystem.toLowerCase());
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
    debugPrint(
        '_resolveRcaCategoryId: selectedRcaFailureCategory.value=$label');
    if (label == null || label.isEmpty || label == 'Select') {
      debugPrint(
          '_resolveRcaCategoryId: Returning null (label is null/empty/Select)');
      return null;
    }
    final matched =
    rcaFailureCategoryList.firstWhereOrNull((e) => e.label == label);
    debugPrint(
        '_resolveRcaCategoryId: Matched category: ${matched?.label}, value: ${matched?.value}');
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
      final wcMatch = workCenter == null ||
          workCenter.isEmpty ||
          (rc.workCenter ?? '').isEmpty ||
          (rc.workCenter ?? '')
              .toLowerCase()
              .contains(workCenter.toLowerCase());
      final baMatch = businessArea == null ||
          businessArea.isEmpty ||
          (rc.businessArea == null) ||
          rc.businessArea.toString() == businessArea;
      final sysMatch = currentSystem == null ||
          currentSystem.isEmpty ||
          (rc.systems ?? '').isEmpty ||
          (rc.systems ?? '')
              .toLowerCase()
              .contains(currentSystem.toLowerCase());

      final catMatch = failureCategoryId == null ||
          failureCategoryId.isEmpty ||
          rc.failureCategoryId?.toString().trim() ==
              failureCategoryId.trim();
      final causeMatch =
          rc.causeOfFailureId?.toString().trim() == causeId.trim();

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
    if (locationTypeId.isEmpty ||
        funcLocId.isEmpty ||
        selectedDepartment.value == null) {
      debugPrint(
          'fetchFmecaSystemSubsystemByFuncLoc: Missing required parameters');
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

      debugPrint(
          'fetchFmecaSystemSubsystemByFuncLoc: Request body: $requestBody');

      final response = await apiClient.post(
        'GetFailureStandDropDownDataNew',
        body: requestBody,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decodedData = jsonDecode(response.body);
        final output =
            decodedData['data'] ?? decodedData['responseOutput'] ?? {};
        final subsystemsOnFuncLocs = output['subsystemsOnFuncLocs'] ?? [];

        debugPrint(
            'fetchFmecaSystemSubsystemByFuncLoc: Got ${subsystemsOnFuncLocs.length} subsystem pairs');

        _applyFmecaSystemSubsystemPairs(subsystemsOnFuncLocs);
      } else {
        debugPrint(
            'fetchFmecaSystemSubsystemByFuncLoc: API error ${response.statusCode}');
        _applyFmecaSystemSubsystemPairs([]);
      }
    } catch (e) {
      debugPrint('fetchFmecaSystemSubsystemByFuncLoc: Error $e');
      _applyFmecaSystemSubsystemPairs([]);
    }
  }

  void _applyFmecaSystemSubsystemPairs(List<dynamic> pairs) {
    final list = pairs.cast<Map<String, dynamic>>();
    _occFmecaPairs = List<Map<String, dynamic>>.from(list);

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

    final systemOptions =
    uniqueSystems.map((s) => LabelValue(label: s, value: s)).toList();

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
          .where((p) =>
      p['system']?.toString() == systemVal && p['subSystem'] != null)
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

  Future<void> onFmecaSystemChanged(String? value) async {
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

      debugPrint(
          'fetchRootCauseAndAction: system=$system, businessArea=$businessArea, workCenter=$workCenter, failureCategoryId=$failureCategoryId (dropdown: $dropdownFailureCategoryId, passed: $objectCodeId)');

      // Causes - preserve filtered list if it was already filtered (has fewer than total)
      // Only rebuild if we have a valid failureCategoryId to filter by
      final totalCauses = globalMasterData.masterCauseOfFailures.length;
      if (causeList.length < totalCauses && failureCategoryId == null) {
        // Cause list was already filtered but we don't have a category to filter by
        // Preserve the existing filtered list
        debugPrint(
            'fetchRootCauseAndAction: Preserving existing filtered cause list (${causeList.length} causes)');
      } else {
        final causes = _buildCauseList(
          workCenter: workCenter,
          businessArea: businessArea,
          failureCategoryId: failureCategoryId,
        );
        causeList.assignAll(causes);
        debugPrint(
            'fetchRootCauseAndAction: ${causes.length} causes from $totalCauses total');
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
        debugPrint(
            'fetchRootCauseAndAction: ${rootCauses.length} root causes for causeId=$currentCause');
      } else {
        rootCauseList.clear();
      }

      // Actions
      actionTakenList.assignAll(globalMasterData.actionList);
      actionList.assignAll(globalMasterData.actionList);
      debugPrint(
          'fetchRootCauseAndAction: ${actionList.length} actions loaded');
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
      final workCenter = getCurrentWorkCenterFromDept() ?? '';
      final businessArea = await getCurrentBusinessArea() ?? '';
      // selectedRcaFailureCategory holds the label → look up the numeric ID
      final failureCategoryId = _resolveRcaCategoryId();

      debugPrint(
          '_filterCausesByRcaCategory: businessArea=$businessArea, workCenter=$workCenter, failureCategoryId=$failureCategoryId');

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
      debugPrint(
          'onCauseSelected: Resolved causeId=$causeId from label=$causeValue');

      if (causeId == null) {
        debugPrint(
            'onCauseSelected: Could not resolve causeId, clearing root causes');
        rootCauseList.clear();
        return;
      }

      // Filter root causes by ONLY cause ID
      debugPrint(
          'onCauseSelected: Filtering root causes by causeId=$causeId only');

      final rootCauses = _buildRootCauseList(causeId: causeId);
      rootCauseList.assignAll(rootCauses);
      debugPrint(
          'onCauseSelected: ${rootCauses.length} root causes for causeId=$causeId');
    } else {
      rootCauseList.clear();
      debugPrint('onCauseSelected: Cleared root causes (no cause selected)');
    }
  }

  /// Resolve cause ID from cause label (for root cause filtering)
  String? _resolveCauseId(String causeLabel) {
    final matched = causeList.firstWhereOrNull((e) => e.label == causeLabel);
    debugPrint(
        '_resolveCauseId: Matched cause: ${matched?.label}, value: ${matched?.value}');
    return matched?.value;
  }

  Future<List<LabelValue>> getFilteredCausesByFailureCategory(
      String? failureCategoryId) async {
    if (failureCategoryId == null || failureCategoryId.isEmpty) return [];

    final workCenter = getCurrentWorkCenterFromDept() ?? '';
    final businessArea = await getCurrentBusinessArea() ?? '';

    final causes = _buildCauseList(
      workCenter: workCenter,
      businessArea: businessArea,
      failureCategoryId: failureCategoryId,
    );

    debugPrint(
        'getFilteredCausesByFailureCategory: ${causes.length} causes for failureCategoryId=$failureCategoryId');
    return causes;
  }

  Future<void> _autoSelectFailureReportedBy() async {
    debugPrint(
        "_autoSelectFailureReportedBy: userList count = ${userList.length}");
    debugPrint(
        "_autoSelectFailureReportedBy: userList sample = ${userList.take(3).map((e) => {
          'label': e.label,
          'value': e.value
        }).toList()}");

    // Don't overwrite if already set (e.g. re-entrant call)
    if (selectedFailureReportedBy.value != null &&
        selectedFailureReportedBy.value!.isNotEmpty) {
      debugPrint(
          "_autoSelectFailureReportedBy: Already set to ${selectedFailureReportedBy.value}, skipping");
      return;
    }
    final currentUserId = await AuthManager().getUserId();
    debugPrint("_autoSelectFailureReportedBy: currentUserId = $currentUserId");
    if (currentUserId == null || currentUserId.isEmpty) {
      debugPrint(
          "_autoSelectFailureReportedBy: currentUserId is null or empty");
      return;
    }

    final matched = userList.firstWhere(
          (e) => e.value == currentUserId,
      orElse: () => LabelValue(label: null),
    );
    debugPrint("_autoSelectFailureReportedBy: matched user = ${matched.label}");
    if (matched.label != null && matched.label!.isNotEmpty) {
      selectedFailureReportedBy.value = matched.label;
      debugPrint(
          "_autoSelectFailureReportedBy: Auto-selected ${matched.label}");
    } else {
      debugPrint(
          "_autoSelectFailureReportedBy: No matching user found for userId $currentUserId");
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
          debugPrint(
              "_autoSelectFailureReportedBy: Auto-selected from masterUsers: $fullName");
        }
      }
    }
  }

  /// Priority, Department, Location, Reported by and Failure Category Type for
  /// the Depot create form (DCC), all from getDepotFailureCreationDeptLocation.
  /// Functional location and system follow the selections (shared handlers).
  Future<void> loadDepotCreateDropdowns() async {
    pushLoading();
    try {
      final out = await _failureService.getDepotFailureLookups();
      priorityTypeList.assignAll(_apiOptions(out['getPriorityTypeList']));
      departmentList.assignAll(_apiOptions(out['getDepartmentList']));
      locationTypeList.assignAll(_apiOptions(out['getLocationTypeList']));
      apiFailureCategoryList
          .assignAll(_apiOptions(out['getFailureCategoryType']));
      userList.assignAll(_apiOptions(out['getFailureReportedbyList']));

      // Default "Failure Reported by" to the logged-in user, like the web.
      final me = await AuthManager().getUserId();
      selectedFailureReportedBy.value =
          userList.firstWhereOrNull((u) => u.value == me)?.label;
      debugPrint('loadDepotCreateDropdowns: priorities=${priorityTypeList.length}, '
          'departments=${departmentList.length}, locations=${locationTypeList.length}, '
          'categories=${apiFailureCategoryList.length}');
    } catch (e) {
      debugPrint('loadDepotCreateDropdowns error: $e');
    } finally {
      popLoading();
    }
  }

  // ===========================================================================
  // STATION FAILURE dropdowns — API only (no local data)
  // ===========================================================================

  /// funcLocId -> failure frequency, from the functional-location API.
  final Map<String, int> _apiFuncLocFrequency = {};

  /// Raw failure details of the station failure being edited.
  Map<String, dynamic> _stationDetails = <String, dynamic>{};

  /// API rows ({label, value}) -> options, without the "Select ..." row (0).
  List<LabelValue> _apiOptions(dynamic raw) {
    if (raw is! List) return <LabelValue>[];
    return raw
        .whereType<Map>()
        .map((e) => LabelValue(
      label: e['label']?.toString().trim() ?? '',
      value: e['value']?.toString() ?? '',
      uniqueId: e['uniqueId'],
    ))
        .where((o) => (o.label ?? '').isNotEmpty && o.value != '0')
        .toList();
  }

  /// Priority, Department, Location, Reported by and Failure Category Type
  /// for the Station form, all from getStationFailureCreationDeptLocation.
  Future<void> loadStationCreateDropdowns() async {
    pushLoading();
    try {
      final out = await _failureService.getStationFailureLookups();
      priorityTypeList.assignAll(_apiOptions(out['getPriorityTypeList']));
      departmentList.assignAll(_apiOptions(out['getDepartmentList']));
      locationTypeList.assignAll(_apiOptions(out['getLocationTypeList']));
      apiFailureCategoryList
          .assignAll(_apiOptions(out['getFailureCategoryType']));
      userList.assignAll(_apiOptions(out['getFailureReportedbyList']));

      // Station failures are reported by the logged-in user.
      final me = await AuthManager().getUserId();
      selectedFailureReportedBy.value =
          userList.firstWhereOrNull((u) => u.value == me)?.label;
      debugPrint(
          'loadStationCreateDropdowns: priorities=${priorityTypeList.length}, '
              'departments=${departmentList.length}, locations=${locationTypeList.length}, '
              'categories=${apiFailureCategoryList.length}');
    } catch (e) {
      debugPrint('loadStationCreateDropdowns error: $e');
    } finally {
      popLoading();
    }
  }

  int _apiIdFor(List<LabelValue> list, String? label) =>
      int.tryParse(list.firstWhereOrNull((e) => e.label == label)?.value ?? '') ??
          0;

  /// Clears the system fields (they depend on the functional location).
  void _apiClearSystem() {
    selectedFmecaSystem.value = null;
    selectedFmecaSubsystem.value = null;
    fmecaSystemList.clear();
    fmecaSubsystemList.clear();
    fmecaSystemReadOnly.value = false;
    fmecaSubsystemReadOnly.value = false;
    systemController.clear();
    subsystemController.clear();
    occSystemDisplayController.clear();
  }

  Future<void> onApiDepartmentChanged(String? label) async {
    final none = label == null || label.isEmpty || label == 'Select';
    selectedDepartment.value = none ? null : label;
    departmentId.value = none ? null : _apiIdFor(departmentList, label);
    selectedFunctionalLocation.value = null;
    functionalLocationList.clear();
    _apiClearSystem();
    await _loadApiFunctionalLocations();
  }

  Future<void> onApiLocationChanged(String? label) async {
    final none = label == null || label.isEmpty || label == 'Select';
    selectedLocation.value = none ? null : label;
    selectedFunctionalLocation.value = null;
    functionalLocationList.clear();
    _apiClearSystem();
    await _loadApiFunctionalLocations();
  }

  /// Functional locations depend on both the department and the location.
  Future<void> _loadApiFunctionalLocations() async {
    final dept = departmentId.value ?? 0;
    final loc = _apiIdFor(locationTypeList, selectedLocation.value);
    if (dept <= 0 || loc <= 0) {
      functionalLocationList.clear();
      return;
    }
    isFunctionalLocationLoading.value = true;
    try {
      final rows = await _failureService.getStationFunctionalLocations(
          locationTypeId: loc, departmentIds: dept.toString());
      _apiFuncLocFrequency.clear();
      final options = <LabelValue>[];
      for (final r in rows) {
        final id = r['funcLocId']?.toString() ?? '';
        final name = r['functionalLocation']?.toString().trim() ?? '';
        if (id.isEmpty || name.isEmpty) continue;
        options.add(LabelValue(label: name, value: id));
        _apiFuncLocFrequency[id] =
            int.tryParse(r['frequency']?.toString() ?? '') ?? 0;
      }
      // The department / location may have changed again while waiting.
      if (departmentId.value == dept &&
          _apiIdFor(locationTypeList, selectedLocation.value) == loc) {
        functionalLocationList.assignAll(options);
      }
    } catch (e) {
      debugPrint('_loadApiFunctionalLocations error: $e');
    } finally {
      isFunctionalLocationLoading.value = false;
    }
  }

  /// Picking a functional location loads its System / Sub System pairs.
  Future<void> onApiFunctionalLocationChanged(String? label) async {
    final none = label == null || label.isEmpty || label == 'Select';
    selectedFunctionalLocation.value = none ? null : label;
    _apiClearSystem();
    if (none) return;
    await _loadApiSystemSubsystem();
  }

  Future<void> _loadApiSystemSubsystem() async {
    final funcId = _apiIdFor(
        functionalLocationList, selectedFunctionalLocation.value);
    final dept = departmentId.value ?? 0;
    final loc = _apiIdFor(locationTypeList, selectedLocation.value);
    if (funcId <= 0) return;
    try {
      final pairs = await _failureService.getSystemSubsystemsByFuncLoc(
          locationTypeId: loc,
          funcLocId: funcId,
          departmentIds: dept > 0 ? dept.toString() : '');
      _applyFmecaSystemSubsystemPairs(pairs);
      systemController.text = occSystemValue;
      subsystemController.text = selectedFmecaSubsystem.value ?? '';
      occSystemDisplayController.text = occSystemValue;
    } catch (e) {
      debugPrint('_loadApiSystemSubsystem error: $e');
    }
  }

  /// Edit of a rejected station failure: load the API lists, then the failure,
  /// then select the saved values by id (the details return names that can
  /// differ from the lookup labels, e.g. "Khapari" vs "KHP - Khapari").
  Future<void> loadStationFailureForUpdate(String id) async {
    await loadStationCreateDropdowns();
    await loadStationFailureDetails(id);
    await _applyStationSavedSelections();
  }

  Future<void> _applyStationSavedSelections() async {
    final d = _stationDetails;
    if (d.isEmpty) return;

    String? labelFor(List<LabelValue> list, dynamic id) {
      final v = id?.toString();
      if (v == null || v.isEmpty || v == '0') return null;
      return list.firstWhereOrNull((e) => e.value == v)?.label;
    }

    selectedDepartment.value =
        labelFor(departmentList, d['departmentId_1'] ?? d['departmentId']) ??
            selectedDepartment.value;
    departmentId.value = _apiIdFor(departmentList, selectedDepartment.value);
    selectedLocation.value =
        labelFor(locationTypeList, d['locationId']) ?? selectedLocation.value;
    selectedFailureCategoryType.value =
        labelFor(apiFailureCategoryList, d['failureCategoryTypeId']);
    selectedPriority.value =
        labelFor(priorityTypeList, d['priorityId']) ?? selectedPriority.value;

    await _loadApiFunctionalLocations();
    final funcLabel = labelFor(functionalLocationList,
        d['funcationLocationId'] ?? d['funcationLocationId_1']);
    if (funcLabel != null) {
      selectedFunctionalLocation.value = funcLabel;
      await _loadApiSystemSubsystem();
    }
    // Keep the saved system if the API pairs didn't supply one.
    final savedSystem = d['system']?.toString().trim() ?? '';
    if (savedSystem.isNotEmpty && (selectedFmecaSystem.value ?? '').isEmpty) {
      selectedFmecaSystem.value = savedSystem;
      systemController.text = savedSystem;
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
      await loadNotificationTypesFromLocalDb();

      await _autoSelectFailureReportedBy();

      debugPrint(
          "loadJEDropdowns: masterFunctionalLocations count = ${masterFunctionalLocations.length}");
      debugPrint("loadJEDropdowns: userList count = ${userList.length}");
      debugPrint(
          "loadJEDropdowns: masterRcaFailureCategories count = ${masterRcaFailureCategories.length}");
      debugPrint(
          "loadJEDropdowns: masterCauseOfFailures count = ${masterCauseOfFailures.length}");
    } catch (e) {
      debugPrint("loadJEDropdowns error: $e");
    }
  }

  Future<void> loadPersonResponsibleForDept() async {
    debugPrint('loadPersonResponsibleForDept: called, deptId=${departmentId.value}, masterUsers=${masterUsers.length}');
    // Show whatever getUserList the lookup API returned, as-is (not filtered
    // by department, so it also shows before a department is picked). The
    // local master-users table below is only an offline fallback (it can be
    // stale or map roles differently).
    await loadLookupDataForNewFailure();
    if (apiPersonResponsibleList.isNotEmpty) {
      userList.assignAll(
          [LabelValue(label: 'Select', value: ''), ...apiPersonResponsibleList]);
      selectedPersonResponsible.value = null;
      debugPrint(
          'loadPersonResponsibleForDept: ${apiPersonResponsibleList.length} users from lookup API');
      return;
    }

    final deptId = departmentId.value;
    if (deptId == null || deptId <= 0) {
      userList.assignAll([LabelValue(label: 'Select', value: '')]);
      selectedPersonResponsible.value = null;
      return;
    }

    if (masterUsers.isEmpty) await _loadMasterUsersOnDemand();

    final businessArea = (await AuthManager().getBusinessArea())?.toString();

    final seenIds = <String>{};
    final jes = masterUsers.where((u) {
      final id = u['UserId']?.toString() ?? '';
      if (id.isEmpty || id == '0') return false;
      if (u['DeptId']?.toString() != deptId.toString()) return false;
      if (!(u['RoleDescr']?.toString().toLowerCase() ?? '').contains('junior engineer')) return false;
      if (businessArea != null &&
          businessArea.isNotEmpty &&
          u['BusinessArea']?.toString() != businessArea) {
        return false;
      }
      return seenIds.add(id); // one entry per UserId
    }).toList();

    String nameOf(Map u) {
      final n = (u['userName'] ?? u['UserName'])?.toString().trim() ?? '';
      if (n.isNotEmpty) return n;
      return '${u['FirstName'] ?? ''} ${u['LastName'] ?? ''}'.trim();
    }

    // Count names so identical names can be told apart by employee code.
    final nameCount = <String, int>{};
    for (final u in jes) {
      final n = nameOf(u);
      nameCount[n] = (nameCount[n] ?? 0) + 1;
    }

    final items = <LabelValue>[];
    for (final u in jes) {
      final n = nameOf(u);
      if (n.isEmpty) continue;
      final emp = u['EmpCode']?.toString() ?? '';
      final label = (nameCount[n]! > 1 && emp.isNotEmpty) ? '$n ($emp)' : n;
      items.add(LabelValue(label: label, value: u['UserId'].toString()));
    }
    items.sort((a, b) => (a.label ?? '').compareTo(b.label ?? ''));

    userList.assignAll([LabelValue(label: 'Select', value: ''), ...items]);
    selectedPersonResponsible.value = null;
    debugPrint('loadPersonResponsibleForDept: ${items.length} JEs for dept $deptId, businessArea=$businessArea');
  }  /// Loads master data for Section Incharge maintenance failure creation

  // ===========================================================================
  // SECTION INCHARGE - maintenance failure creation: dropdowns from the APIs
  // (no local data). The Station flow shares the _api* helpers above.
  // ===========================================================================

  /// True while the Section Incharge create form is active: the shared
  /// department / location / functional-location handlers then use the APIs.
  bool siApiMode = false;

  /// Priority, department, location, notification type and failure category
  /// from GetLookupCreateCorrNotification. Person responsible, functional
  /// location, system / sub system and equipment follow the selections.
  Future<void> loadSectionInchargeDropdowns() async {
    pushLoading();
    try {
      await _loadSiLookups();
      userList.assignAll([LabelValue(label: 'Select', value: '')]);
      if ((departmentId.value ?? 0) > 0) await _loadSiPersonResponsible();
    } catch (e) {
      debugPrint('loadSectionInchargeDropdowns error: $e');
    } finally {
      popLoading();
    }
  }

  /// Priority, department, location and notification type from the lookup
  /// API. Shared by the create form and by an existing failure's view / edit.
  Future<void> _loadSiLookups() async {
    siApiMode = true;
    await _initFuture;
    final out = await _failureService.getLookupCreateCorrNotificationRaw();
    priorityTypeList.assignAll(_apiOptions(out['getPriorityType']));
    departmentList.assignAll(_apiOptions(out['getDepartmentList']));
    // The form lists locationList but resolves ids through locationTypeList.
    final locations = _apiOptions(out['getLocationType']);
    locationTypeList.assignAll(locations);
    locationList.assignAll(locations);
    // "Notification Type" on this form is the corrective notification type
    // (Failure, Snag, ...): getCorrNotificationTypeList.
    final corrTypes = _apiOptions(out['getCorrNotificationTypeList']);
    corrNotificationTypeList.assignAll(corrTypes);
    notificationTypeList
        .assignAll([LabelValue(label: 'Select', value: ''), ...corrTypes]);
    debugPrint('_loadSiLookups: priorities=${priorityTypeList.length}, '
        'departments=${departmentList.length}, locations=${locations.length}');
  }

  /// JE role dropdown data, online:
  /// - Notification Type: getCorrNotificationTypeList from the failure-details
  ///   response (jeChangeNotification) - the only list taken from it.
  /// - Priority, Department, Location: the lookup API (same as Section Incharge).
  /// - Functional location, equipment, system / sub system:
  ///   GetFailureStandDropDownDataNew through the shared handlers.
  Future<void> _applyJeApiLists(FailureDetailOutput output) async {
    try {
      await _loadSiLookups(); // also switches the shared handlers to the APIs
    } catch (e) {
      siApiMode = true;
      debugPrint('_applyJeApiLists: lookups failed: $e');
    }

    final types = (output.getCorrNotificationTypeList ?? const <LabelValue>[])
        .where((o) =>
    (o.label ?? '').trim().isNotEmpty &&
        (o.value ?? '').isNotEmpty &&
        o.value != '0')
        .toList();
    if (types.isNotEmpty) {
      corrNotificationTypeList.assignAll(types);
      notificationTypeList
          .assignAll([LabelValue(label: 'Select', value: ''), ...types]);
    }
    debugPrint('_applyJeApiLists: notification types=${types.length}, '
        'locations=${locationTypeList.length}');
  }

  /// Existing failure (e.g. one created by the Station Controller, DCC or OCC
  /// that reached the Section Incharge): select its saved values in the
  /// API-loaded dropdowns, by id. Values the API no longer lists are added so
  /// the saved choice still shows.
  Future<void> _applySiSavedSelections(
      CreateVMModel model, FailureDetailOutput output,
      {bool loadPersons = true}) async {
    String? labelFor(List<LabelValue> list, dynamic id) {
      final v = id?.toString();
      if (v == null || v.isEmpty || v == '0') return null;
      return list.firstWhereOrNull((e) => e.value == v)?.label;
    }

    // Priority
    selectedPriority.value =
        labelFor(priorityTypeList, model.priorityId) ??
            model.priorityType ??
            model.category;

    // Department
    var deptLabel = labelFor(departmentList, model.deptId);
    if (deptLabel == null && (model.deptCode ?? '').isNotEmpty) {
      deptLabel = model.deptCode;
      ensureDropdownOption(
          departmentList, deptLabel!, model.deptId?.toString() ?? '');
    }
    if (deptLabel != null) {
      selectedDepartment.value = deptLabel;
      departmentId.value = model.deptId ?? 0;
    }

    // Location (the form lists locationList, ids resolve via locationTypeList)
    var locLabel = labelFor(locationTypeList, model.locationTypeId);
    if (locLabel == null && (model.locationName ?? '').isNotEmpty) {
      locLabel = model.locationName;
      ensureDropdownOption(
          locationTypeList, locLabel!, model.locationTypeId?.toString() ?? '');
      ensureDropdownOption(
          locationList, locLabel, model.locationTypeId?.toString() ?? '');
    }
    if (locLabel != null) {
      selectedLocation.value = locLabel;
      locationDisplayController.text = locLabel;
      maintenanceLocationTypeId.value = model.locationTypeId ?? 0;
    }

    // Functional location (API list for this department + location)
    await _loadApiFunctionalLocations();
    var funcLabel = labelFor(functionalLocationList, model.functionLocationId);
    if (funcLabel == null) {
      final saved = (model.funcLocation ?? '').trim();
      if (saved.isNotEmpty) {
        funcLabel = saved;
        ensureDropdownOption(functionalLocationList, saved,
            model.functionLocationId?.toString() ?? '');
      }
    }
    if (funcLabel != null) {
      selectedFunctionalLocation.value = funcLabel;
      functionalLocationDisplayController.text = funcLabel;
      final freq = _apiFuncLocFrequency[
      model.functionLocationId?.toString() ?? ''] ??
          model.frequency ??
          0;
      fmecaFrequency.value = freq;
      fmecaFrequencyController.text = freq.toString();

      await Future.wait([_loadApiSystemSubsystem(), _loadSiEquipment()]);

      // Keep the saved system / sub system if the API pairs didn't set them.
      if ((selectedFmecaSystem.value ?? '').isEmpty &&
          (model.systems ?? '').isNotEmpty) {
        selectedFmecaSystem.value = model.systems;
        systemController.text = model.systems!;
      }
      if ((selectedFmecaSubsystem.value ?? '').isEmpty &&
          (model.subSystems ?? '').isNotEmpty) {
        selectedFmecaSubsystem.value = model.subSystems;
        fmecaSubsystemController.text = model.subSystems!;
      }

      // Equipment number
      var eqLabel = labelFor(equipmentList, model.equipmentId);
      eqLabel ??= (model.equipmentName ?? '').isNotEmpty
          ? model.equipmentName
          : null;
      if (eqLabel != null) {
        ensureDropdownOption(
            equipmentList, eqLabel, model.equipmentId?.toString() ?? '');
        selectedEquipmentNumber.value = eqLabel;
        equipmentDisplayController.text = eqLabel;
      }
    }

    if (!loadPersons) return;
    // Person responsible: the department's users from the API; the details'
    // own getUserList only if that call returned nobody.
    await _loadSiPersonResponsible();
    if (userList.length <= 1) {
      final detailUsers = (output.getUserList ?? const <LabelValue>[]).where((u) =>
      (u.label ?? '').trim().isNotEmpty &&
          (u.value ?? '').isNotEmpty &&
          u.value != '0' &&
          (u.label ?? '').trim().toLowerCase() != 'select user');
      if (detailUsers.isNotEmpty) {
        userList.assignAll([LabelValue(label: 'Select', value: ''), ...detailUsers]);
      }
    }
  }

  /// Person Responsible for the chosen department (getAssgineUserList).
  Future<void> _loadSiPersonResponsible() async {
    final dept = departmentId.value ?? 0;
    var users = <LabelValue>[];
    if (dept > 0) {
      try {
        users = await _failureService.getAssgineUsersByDept(deptId: dept);
      } catch (e) {
        debugPrint('_loadSiPersonResponsible error: $e');
      }
      // The department may have changed again while waiting.
      if (departmentId.value != dept) return;
    }
    userList.assignAll([LabelValue(label: 'Select', value: ''), ...users]);
    selectedPersonResponsible.value = null;
  }

  /// Clears what depends on the functional location.
  void _siClearFunctionalDerived() {
    selectedFunctionalLocation.value = null;
    functionalLocationList.clear();
    _apiClearSystem();
    equipmentList.clear();
    selectedEquipmentNumber.value = null;
    fmecaFrequency.value = null;
    fmecaFrequencyController.clear();
  }

  Future<void> _onSiDepartmentChanged(String? label) async {
    final none = label == null || label.isEmpty || label == 'Select';
    selectedDepartment.value = none ? null : label;
    departmentId.value = none ? null : _apiIdFor(departmentList, label);
    _siClearFunctionalDerived();
    await Future.wait([_loadSiPersonResponsible(), _loadApiFunctionalLocations()]);
  }

  Future<void> _onSiLocationChanged(String? label) async {
    final none = label == null || label.isEmpty || label == 'Select';
    selectedLocation.value = none ? null : label;
    maintenanceLocationTypeId.value =
    none ? 0 : _apiIdFor(locationTypeList, label);
    _siClearFunctionalDerived();
    await _loadApiFunctionalLocations();
  }

  Future<void> _onSiFunctionalLocationChanged(String? label) async {
    final none = label == null || label.isEmpty || label == 'Select';
    selectedFunctionalLocation.value = none ? null : label;
    _apiClearSystem();
    equipmentList.clear();
    selectedEquipmentNumber.value = null;
    fmecaFrequency.value = null;
    fmecaFrequencyController.clear();
    if (none) return;

    final funcId = _apiIdFor(functionalLocationList, label);
    final frequency = _apiFuncLocFrequency['$funcId'] ?? 0;
    fmecaFrequency.value = frequency;
    fmecaFrequencyController.text = frequency.toString();
    await Future.wait([_loadApiSystemSubsystem(), _loadSiEquipment()]);
    await filterRcaFailureCategoriesBySystem();
  }

  /// Equipment numbers of the chosen functional location (GetEquipmentNumber).
  Future<void> _loadSiEquipment() async {
    final funcLabel = selectedFunctionalLocation.value;
    final funcId = _apiIdFor(functionalLocationList, funcLabel);
    if (funcId <= 0) return;
    final dept = departmentId.value ?? 0;
    isEquipmentLoading.value = true;
    try {
      final rows = await _failureService.getEquipmentNumbersByFuncLoc(
          locationTypeId: _apiIdFor(locationTypeList, selectedLocation.value),
          funcLocId: funcId,
          departmentIds: dept > 0 ? dept.toString() : '');
      final options = <LabelValue>[];
      for (final r in rows) {
        final id = r['equipId']?.toString() ?? '';
        final name = r['equipmentDetail']?.toString().trim() ?? '';
        if (id.isEmpty || name.isEmpty) continue;
        options.add(LabelValue(label: name, value: id));
      }
      // The user may have picked another functional location meanwhile.
      if (selectedFunctionalLocation.value != funcLabel) return;
      equipmentList.assignAll([LabelValue(label: 'Select', value: ''), ...options]);
    } catch (e) {
      debugPrint('_loadSiEquipment error: $e');
    } finally {
      isEquipmentLoading.value = false;
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
    // The Section Incharge maintenance form reads this controller instead.
    passengersAffectedCountController.text = count?.toString() ?? '';
    trappedDurationController.text = trapped ?? '';
    rescuedDurationController.text = rescued ?? '';
  }

  @override
  String lookupValue(dynamic list, String? label, {String fallback = "0"}) {
    if (label == null || label.isEmpty || label == 'Select') return fallback;
    return list
        .firstWhere((e) => e.label == label,
        orElse: () => LabelValue(value: fallback))
        .value ??
        fallback;
  }

  @override
  int lookupLocationId(dynamic list, String? label, {String fallback = "0"}) {
    if (label == null || label.isEmpty || label == 'Select')
      return int.tryParse(fallback) ?? 0;
    // Now locationTypeId is stored in value field
    return int.tryParse(list
        .firstWhere((e) => e.label == label,
        orElse: () => LabelValue(value: fallback))
        .value ??
        fallback) ??
        0;
  }

  void updateMeasurementReading(int index, String field, String value) {
    var list = List<Map<String, dynamic>>.from(measurementPointsList);
    list[index][field] = value;
    measurementPointsList.assignAll(list);
  }

  DateTime? _parseDate(String dateStr) {
    final trimmed = dateStr.trim();
    if (trimmed.isEmpty) return null;

    try {
      final iso = DateTime.tryParse(trimmed);
      if (iso != null && iso.year >= 1900) return iso;
    } catch (_) {}

    final formats = [
      'dd/MM/yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm',
      'dd/MM/yyyy hh:mm:ss a',
      'dd/MM/yyyy hh:mm a',
      'MM/dd/yyyy HH:mm:ss',
      'MM/dd/yyyy HH:mm',
      'MM/dd/yyyy hh:mm:ss a',
      'MM/dd/yyyy hh:mm a',
      'dd-MM-yyyy HH:mm:ss',
      'dd-MM-yyyy HH:mm',
      'dd-MM-yyyy hh:mm:ss a',
      'dd-MM-yyyy hh:mm a',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd',
    ];

    for (final pattern in formats) {
      try {
        final d = DateFormat(pattern).parseLoose(trimmed);
        if (d.year >= 1900) return d;
      } catch (_) {}
    }

    debugPrint('Error parsing date: $dateStr');
    return null;
  }

  Future<void> handleScannedQR(String url) async {
    try {
      debugPrint('QR Scan: Raw URL: $url');
      final uri = Uri.tryParse(url);
      if (uri == null || uri.pathSegments.isEmpty) {
        Get.snackbar('Error', 'Invalid QR Code URL',
            backgroundColor: AppColors.red, colorText: AppColors.white1);
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
      Get.snackbar('Error', 'Failed to process QR Code: $e',
          backgroundColor: AppColors.red, colorText: AppColors.white1);
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
      final des = DES(
          key: keyBytes,
          mode: DESMode.CBC,
          paddingType: DESPaddingType.PKCS7,
          iv: msIv);
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

      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      )
          .timeout(const Duration(seconds: 15));

      debugPrint('QR Scan API: Response status: ${response.statusCode}');
      debugPrint('QR Scan API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['responseCode'] == 200 &&
            responseData['responseOutput'] != null) {
          debugPrint('QR Scan API: Successfully parsed response output');

          EasyLoading.dismiss();

          // Navigate to MaintenanceHistoryScreen with showAssetQR = true
          Get.to(() => const MaintenanceHistoryScreen(showAssetQR: true),
              arguments: decryptedId);
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

    debugPrint(
        'QR Scan: Looking for functional location with ID: $cleanId (parsed as int: $intId)');

    List<Map<String, Object?>> funcResults = [];

    // First try by funcLocId if it's an integer
    if (intId != null) {
      funcResults = await db.rawQuery(
        'SELECT funcLocation, funcLocId, funcLocationName, location, objectNumber, workCenter FROM FunctionalLocations WHERE funcLocId = ? LIMIT 1',
        [intId],
      );
      debugPrint(
          'QR Scan: Query by funcLocId=$intId returned ${funcResults.length} results');
    }

    // If no results by ID, try by funcLocation code (string)
    if (funcResults.isEmpty) {
      funcResults = await db.rawQuery(
        'SELECT funcLocation, funcLocId, funcLocationName, location, objectNumber, workCenter FROM FunctionalLocations WHERE funcLocation = ? LIMIT 1',
        [cleanId],
      );
      debugPrint(
          'QR Scan: Query by funcLocation="$cleanId" returned ${funcResults.length} results');
    }

    // If still no results, try a LIKE search for partial matches
    if (funcResults.isEmpty) {
      funcResults = await db.rawQuery(
        'SELECT funcLocation, funcLocId, funcLocationName, location, objectNumber, workCenter FROM FunctionalLocations WHERE funcLocation LIKE ? LIMIT 1',
        ['%$cleanId%'],
      );
      debugPrint(
          'QR Scan: Query by funcLocation LIKE "%$cleanId%" returned ${funcResults.length} results');
    }

    if (funcResults.isEmpty) {
      final allFuncLocs = await db.rawQuery(
          'SELECT funcLocId, funcLocation, funcLocationName FROM FunctionalLocations LIMIT 10');
      debugPrint(
          'QR Scan: Sample functional locations in DB (first 10): $allFuncLocs');
      final totalCount =
      await db.rawQuery('SELECT COUNT(*) as cnt FROM FunctionalLocations');
      debugPrint(
          'QR Scan: Total functional locations in DB: ${totalCount.first['cnt']}');

      final check90225 = await db.rawQuery(
          'SELECT funcLocId, funcLocation, funcLocationName FROM FunctionalLocations WHERE funcLocId = 90225');
      debugPrint(
          'QR Scan: Check for ID 90225: ${check90225.isNotEmpty ? "FOUND" : "NOT FOUND"}');
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

    debugPrint(
        'QR Scan Offline: masterDepartments count=${masterDepartments.length}');
    debugPrint(
        'QR Scan Offline: departmentList count=${departmentList.length}');
    debugPrint(
        'QR Scan Offline: departmentList sample=${departmentList.take(5).map((e) => {
          'label': e.label,
          'value': e.value,
          'uniqueId': e.uniqueId
        }).toList()}');

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

      deptName ??= masterDepartments
          .firstWhere(
            (d) =>
        (d['workCenter']?.toString().trim().toUpperCase() ?? '') ==
            workCenter.toUpperCase(),
        orElse: () => <String, dynamic>{},
      )['deptName']
          ?.toString();
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
    if (isFunctionalLocationsLoaded.value &&
        functionalLocationList.isNotEmpty) {
      debugPrint(
          'loadFunctionalLocationsOnDemand: Functional locations already loaded, skipping');
      return;
    }

    isFunctionalLocationLoading.value = true;
    debugPrint(
        'loadFunctionalLocationsOnDemand: Loading with filters - businessArea: $businessArea, workCenter: $workCenter, location: $location');
    final dbService = LocalDatabaseService();
    final funcLocs = await dbService.getFunctionalLocationsFiltered(
      businessArea: businessArea ?? await AuthManager().getBusinessArea(),
      workCenter: workCenter,
      location: location,
      // No limit - load all filtered results
    );

    masterFunctionalLocations
        .assignAll(funcLocs.map((e) => e.toJson()).toList());
    functionalLocationList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...funcLocs.map((e) => LabelValue(
        label: e.funcLocationName.isNotEmpty
            ? e.funcLocationName
            : e.funcLocation,
        value: e.funcLocId?.toString() ?? '',
      )),
    ]);
    isFunctionalLocationsLoaded.value = true;
    debugPrint(
        'loadFunctionalLocationsOnDemand: Loaded ${funcLocs.length} functional locations');
    isFunctionalLocationLoading.value = false;
  }

  // ON-DEMAND: Load equipment with SQL filtering & API fallback
  Future<void> loadEquipmentsOnDemand({
    int? businessArea,
    String? functionalLocationId,
    String? workCenter,
  }) async {
    isEquipmentLoading.value = true;
    debugPrint(
        'loadEquipmentsOnDemand: Loading with filters - businessArea: $businessArea, functionalLocationId: $functionalLocationId, workCenter: $workCenter');
    final dbService = LocalDatabaseService();
    final equipments = await dbService.getEquipmentsFiltered(
      businessArea:
      businessArea, // Don't default - only filter if explicitly provided
      functionalLocationId: functionalLocationId,
      workCenter: workCenter,
      // No limit - load all filtered results
    );

    masterEquipments.assignAll(equipments.map((e) => e.toJson()).toList());
    final newItems = <LabelValue>[
      LabelValue(label: 'Select', value: ''),
      ...equipments.map((e) => LabelValue(
        label: e.equipmentName.isNotEmpty
            ? e.equipmentName
            : (e.equipDesc.isNotEmpty ? e.equipDesc : e.equipNo),
        value: e.equipId?.toString() ?? e.equipNo,
      )),
    ];

    // Check API as fallback/enrichment if functionalLocationId is present
    if (functionalLocationId != null && functionalLocationId.trim().isNotEmpty) {
      final cleanCode = functionalLocationId.contains(' - ')
          ? functionalLocationId.split(' - ').first.trim()
          : functionalLocationId.trim();
      try {
        final response = await _failureService.getFunctionalLocationDetails(cleanCode);
        if (response.details?.equipmentList != null &&
            response.details!.equipmentList!.isNotEmpty) {
          for (final eq in response.details!.equipmentList!) {
            if (eq.label != null && eq.label!.isNotEmpty && eq.label != 'Select') {
              if (!newItems.any((existing) =>
              existing.label == eq.label ||
                  (existing.value?.isNotEmpty == true && existing.value == eq.value))) {
                newItems.add(eq);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('loadEquipmentsOnDemand: API check error: $e');
      }
    }

    // Preserve existing selection if valid
    final currentSelected = selectedEquipmentNumber.value;
    if (currentSelected != null &&
        currentSelected.isNotEmpty &&
        currentSelected != 'Select') {
      if (!newItems.any((e) => e.label == currentSelected)) {
        newItems.add(LabelValue(label: currentSelected, value: currentSelected));
      }
    } else if (newItems.length == 2) {
      // Auto-select if there is exactly 1 option (Select + 1 item)
      selectedEquipmentNumber.value = newItems[1].label;
    }

    equipmentList.assignAll(newItems);
    debugPrint(
        'loadEquipmentsOnDemand: Final equipmentList count = ${equipmentList.length}');
    isEquipmentLoading.value = false;
  }

  Future<void> loadStationFailureDetailsFromData(
      FailureItem failureItem) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print("failureItem=++${failureItem}");
      debugPrint("========== STATION VIEW DATA ==========");
      debugPrint("failureNo = ${failureItem.failureNo}");
      debugPrint("notificationCode = ${failureItem.notificationCode}");
      debugPrint("description = ${failureItem.failureDescription}");
      debugPrint("department = ${failureItem.departmentName}");
      debugPrint("location = ${failureItem.locationName}");
      debugPrint("functionalLocation = ${failureItem.functionalLocation}");
      debugPrint("priority = ${failureItem.priority}");
      debugPrint("subLocation = ${failureItem.subLocation}");
      debugPrint("system = ${failureItem.system}");
      debugPrint("trainId = ${failureItem.trainId}");
      debugPrint("tripAffected = ${failureItem.isTripAffected}");
      debugPrint("tripDelayUpline = ${failureItem.tripDelayUpline}");
      debugPrint("tripDelayDownline = ${failureItem.tripDelayDownline}");
      debugPrint("tripCancel = ${failureItem.tripCancel}");
      debugPrint("trainReplace = ${failureItem.trainReplace}");
      debugPrint("trainDeboarded = ${failureItem.trainDeboarded}");
      debugPrint("passengerAffected = ${failureItem.isPassengerAffected}");
      debugPrint("passengerCount = ${failureItem.numberOfPassengerAffected}");
      debugPrint("========================================");
      // Populate form fields from FailureItem
      originalFailureId.value = failureItem.id;
      notificationCode.value =
          failureItem.notificationCode ?? failureItem.failureNo ?? '';
      selectedPriority.value = failureItem.priority;
      mainStatusName.value = (failureItem.statusName != null && failureItem.statusName!.isNotEmpty)
          ? failureItem.statusName
          : (failureItem.statusDescription != null && failureItem.statusDescription!.isNotEmpty
          ? failureItem.statusDescription
          : 'Open');
      failureDescriptionController.text = failureItem.failureDescription ?? '';
      selectedDepartment.value = failureItem.departmentName;
      originalDepartmentId.value = failureItem.departmentId_1;
      selectedLocation.value = failureItem.locationName;
      originalLocationId.value = failureItem.locationId;
      selectedFunctionalLocation.value = failureItem.functionalLocation;
      debugPrint(
          "loadStationFailureDetailsFromData: functionalLocation=${failureItem.functionalLocation}, set to=${selectedFunctionalLocation.value}");
      final funcToLoad = failureItem.functionalLocation;
      if (funcToLoad != null && funcToLoad.isNotEmpty && funcToLoad != 'Select') {
        final cleanCode = funcToLoad.contains(' - ')
            ? funcToLoad.split(' - ').first.trim()
            : funcToLoad.trim();
        await loadEquipmentsOnDemand(functionalLocationId: cleanCode);
      }
      subLocationController.text = failureItem.subLocation ?? '';
      print("failureItem.subLocation==${failureItem.subLocation}");
      systemController.text = failureItem.system ?? '';
      trainIdController.text = failureItem.trainId ?? '';
      await filterRcaFailureCategoriesBySystem();

      final occurDateStr = (failureItem.failureOccuranceDateTime?.isNotEmpty == true)
          ? failureItem.failureOccuranceDateTime
          : failureItem.actualFailureOccuranceDatetime;
      if (occurDateStr != null && occurDateStr.isNotEmpty) {
        selectedFailureOccurrenceDate.value = _parseDate(occurDateStr);
      }
      final completedDateStr = failureItem.actualFailureCompletedDateTime;
      if (completedDateStr != null && completedDateStr.isNotEmpty) {
        selectedFailureCompletedDate.value = _parseDate(completedDateStr);
      }

      selectedFailureReportedBy.value = failureItem.failureReportedby;
      selectedFailureCategoryType.value = failureItem.failureCategoryTypeText;
      failureRectificationDetailsController.text =
          failureItem.failureRectificationDetails ?? '';

      // Trip / Service Affected
      isTripAffected.value = failureItem.isTripAffected ?? false;
      isServiceAffected.value = failureItem.isTripAffected ?? false;
      tripDelayUplineController.text =
          failureItem.tripDelayUpline?.toString() ?? '';
      trainCancelNosController.text = failureItem.tripCancel?.toString() ?? '';
      tripDelayDownlineController.text =
          failureItem.tripDelayDownline?.toString() ?? '';
      trainDelayMinController.text =
          failureItem.trainDelayInMin?.toString() ?? '';
      trainWithdrawalNosController.text =
          failureItem.noOfTranWithdrawal?.toString() ?? '';
      trainReplaceNosController.text =
          failureItem.trainReplace?.toString() ?? '';

      // Train Deboarded
      isPassengerDeboarding.value = failureItem.isTrainDeboarded ?? false;
      trainDeboardedNosController.text =
          failureItem.trainDeboarded?.toString() ?? '';

      // Passenger Affected
      isPassengerAffected.value = failureItem.isPassengerAffected ?? false;
      passengersAffectedCountController.text =
          failureItem.numberOfPassengerAffected?.toString() ?? '';
      trappedDurationController.text =
          failureItem.trappedDuration?.toString() ?? '';
      rescuedDurationController.text =
          failureItem.rescusedDuration?.toString() ?? '';

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
      encryptedId.value =
          failureItem.failureNo ?? failureItem.id?.toString() ?? '';
      notificationId.value = failureItem.id ?? 0;
      notificationCode.value =
          failureItem.notificationCode ?? failureItem.failureNo ?? '';
      failureCategory.value = failureItem.creationType ?? 'Manual';

      // Populate basic fields from FailureItem
      failureDescriptionController.text = failureItem.failureDescription ?? '';
      selectedDepartment.value = failureItem.departmentName;
      selectedLocation.value = failureItem.locationName;
      selectedFunctionalLocation.value = failureItem.functionalLocation;
      selectedEquipmentNumber.value = failureItem.equipmentDescription;
      final funcToLoad = failureItem.functionalLocation;
      if (funcToLoad != null && funcToLoad.isNotEmpty && funcToLoad != 'Select') {
        final cleanCode = funcToLoad.contains(' - ')
            ? funcToLoad.split(' - ').first.trim()
            : funcToLoad.trim();
        await loadEquipmentsOnDemand(functionalLocationId: cleanCode);
        if (failureItem.equipmentDescription != null && failureItem.equipmentDescription!.isNotEmpty) {
          selectedEquipmentNumber.value = failureItem.equipmentDescription;
          ensureDropdownOption(equipmentList, failureItem.equipmentDescription!, failureItem.equipmentId?.toString() ?? '');
        }
      }
      subLocationController.text = failureItem.subLocation ?? '';
      systemController.text = failureItem.system ?? '';
      subsystemController.text = failureItem.subSystems ?? '';
      trainIdController.text = failureItem.trainId ?? '';

      selectedPriority.value = failureItem.priority;
      mainStatusName.value = failureItem.statusName;

      // Set notification type to default (use notificationTypeList from local DB)
      if (notificationTypeList.isNotEmpty) {
        selectedNotificationType.value = notificationTypeList.firstWhere(
              (e) => e.label != 'Select' && (e.label?.isNotEmpty ?? false),
          orElse: () => notificationTypeList.first,
        ).label;
      } else if (corrNotificationTypeList.isNotEmpty) {
        selectedNotificationType.value = corrNotificationTypeList.first.label;
      }

      await filterRcaFailureCategoriesBySystem();

      if (failureItem.failureOccuranceDateTime != null) {
        selectedFailureOccurrenceDate.value =
            _parseDate(failureItem.failureOccuranceDateTime!);
      }
      if (failureItem.actualFailureCompletedDateTime != null) {
        selectedActualFailureRectifiedDate.value =
            _parseDate(failureItem.actualFailureCompletedDateTime!);
      }

      selectedFailureReportedBy.value = failureItem.failureReportedby;
      selectedFailureCategoryType.value = failureItem.failureCategoryTypeText;
      failureRectificationDetailsController.text =
          failureItem.failureRectificationDetails ?? '';
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
                'cause': rc['rootCasueName'] ??
                    "N/A", // Map root cause name to cause field
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

      debugPrint(
          "loadJEFailureDetailsFromData: Loaded details from FailureItem for offline JE flow");
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
            debugPrint(
                'setAssetDataFromQR: Populated functional location from master data: $masterFuncLocName (funcLocId: $funcLocId)');
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
              debugPrint(
                  'setAssetDataFromQR: Populated functional location from funcLocation: $funcLocation (funcLocId: $funcLocId)');
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
            debugPrint(
                'setAssetDataFromQR: Populated functional location from funcLocation: $funcLocation (funcLocId: $funcLocId)');
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
            debugPrint(
                'setAssetDataFromQR: Populated functional location from description: $description (funcLocId: $funcLocId)');
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
        debugPrint(
            'setAssetDataFromQR: Populated functional location without funcLocId: $funcLocation');
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
        debugPrint(
            'setAssetDataFromQR: Populated department: $deptMatch.label');
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

  String? _resolveLabel(
      List<LabelValue>? apiList,
      RxList<LabelValue> localList, // was List<LabelValue>
      dynamic id,
      ) {
    if (id == null) return null;
    final idText = id.toString();
    if (idText.isEmpty || idText == '0') return null;

    final label = localList.firstWhereOrNull((e) => e.value == idText)?.label ??
        apiList?.firstWhereOrNull((e) => e.value == idText)?.label;

    if (label != null && label.isNotEmpty) {
      ensureDropdownOption(localList, label, idText);
    }
    return label;
  }

  Future<void> loadMaintenanceFailureDetails(
      String failureNo, {
        FailureItem? item,
        String? code,
      }) async {
    encryptedId.value = failureNo;
    notificationId.value = 0;
    pushLoading();
    try {
      isLoading.value = true;
      errorMessage.value = "";
      await loadMasterDataFromDb();
      // Dropdowns of this form come from the APIs, not local data.
      try {
        await _loadSiLookups();
      } catch (e) {
        debugPrint('SI details: lookups failed: $e');
      }

      final result = await _failureService.getMaintenanceFailureDetails([
        failureNo,
        item?.id?.toString() ?? '',
        item?.notificationCode ?? '',
        code ?? '',
      ]);
      final output = result.responseOutput;
      final model = output?.getCreateVMModel;

      if (result.responseCode != 200 || output == null || model == null) {
        debugPrint('SI details: model null, using list item fallback');
        if (item != null) {
          await _populateMaintenanceFromListItem(item);
        } else {
          errorMessage.value = 'Failure details not found';
        }
        return;
      }

      notificationId.value = model.notificationId ?? 0;
      notificationCode.value = model.notificationCode ?? '';
      maintenanceStatusId.value = model.statusId ?? 0;
      maintenanceLocationTypeId.value =
          model.locationTypeId ?? 0;
      debugPrint(
        'MAINTENANCE WEB STATUS => '
            'statusId=${model.statusId}, '
            'mainStatusName=${model.mainStatusName}, '
            'notificationId=${model.notificationId}',
      );

      mainStatusName.value = model.mainStatusName;
      _applyOccOrigin(model);
      notificationHistoryList
          .assignAll(output.getNotificationActionUserHistory ?? []);
      notificationDescriptionHistoryList
          .assignAll(output.getNotificationHistory ?? []);

      await _applySiSavedSelections(model, output);

      if ((model.frequency ?? 0) > 0) {
        fmecaFrequencyController.text = model.frequency.toString();
      }

      // final eqLabel = _resolveLabel(
      //     output.getEquipmentList, equipmentList, model.equipmentId) ??
      //     model.equipmentName;
      // if (eqLabel != null && eqLabel.isNotEmpty)
      //   selectedEquipmentNumber.value = eqLabel;

      failureDescriptionController.text = model.description ?? '';
      subLocationController.text = model.locationFailure ?? '';
      selectedFailureOccurrenceDate.value =
      model.actualFailureOccuranceOn != null
          ? _parseDate(model.actualFailureOccuranceOn!)
          : null;
      selectedPersonResponsible.value =
          _labelFromValueList(userList, model.assignedUserId);
      ptwNumberController.text = model.ptwNo ?? '';
      // Notification Type = the corrective notification type (Failure, Snag...)
      selectedNotificationType.value =
          _labelFromValueList(corrNotificationTypeList, model.corrNotificationTypeId);
      // Nature of Work / Failure Type (department 3) are looked up in the same
      // lists their dropdowns show.
      selectedNatureOfWork.value = _labelFromValueList(
          apiNatureOfWorkList.isNotEmpty ? apiNatureOfWorkList : natureOfWorkList,
          model.natureOfWorkId);
      selectedFailureCategoryType.value = _labelFromValueList(
          apiNotificationTypeList.isNotEmpty
              ? apiNotificationTypeList
              : failureCategoryTypeList,
          model.notificationTypeId);
      trainRunningKmController.text = model.trainRunningKm ?? '';

      isServiceAffected.value = model.isServiceAffected ?? false;
      trainDelayMinController.text = model.trainDelayInMin?.toString() ?? '';
      trainDelayNosController.text = model.trainDelayInNo?.toString() ?? '';
      trainCancelNosController.text = model.noOfTranCancel?.toString() ?? '';
      trainWithdrawalNosController.text =
          model.noOfTranWithdrawal?.toString() ?? '';
      trainReplaceNosController.text = model.noOfTrainReplace?.toString() ?? '';
      selectedSystemDowntime.value = (model.systemDowntime ?? '').isNotEmpty
          ? _parseDate(model.systemDowntime!)
          : null;

      isPassengerDeboarding.value = model.isPassengerDeboarding ?? false;
      trainDeboardedNosController.text =
          model.noofTrainDeboarded?.toString() ?? '';
      _applyPassengerAffectedFromModel(model);

      // Closure details the JE entered when closing the failure; the Section
      // Incharge sees them read-only (Failure Rectification Details section).
      failureRectificationDetailsController.text =
          model.failureRectificationDetails ?? '';
      selectedActualFailureRectified.value = model.failureType;
      final userStatus = (output.getUserStatus ?? const <LabelValue>[])
          .firstWhereOrNull((e) => e.value == model.userStatus?.toString());
      if (userStatus?.label != null && userStatus!.label!.isNotEmpty) {
        ensureDropdownOption(
            userStatusJeList, userStatus.label!, userStatus.value ?? '');
        selectedUserStatus.value = userStatus.label;
      }
      selectedFailureAttendedDate.value =
      (model.failureAttendedDate ?? '').isNotEmpty
          ? _parseDate(model.failureAttendedDate!)
          : null;
      selectedActualFailureRectifiedDate.value =
      (model.actualFailureRectifiedDate ?? '').isNotEmpty
          ? _parseDate(model.actualFailureRectifiedDate!)
          : null;
      selectedUnderObservationDate.value =
      (model.underObservationDate ?? '').isNotEmpty
          ? _parseDate(model.underObservationDate!)
          : null;

      isOheRequired.value = model.isOHEReq ?? false;
      isSicRequired.value = model.isSICReq ?? false;
      isJointInspection.value = model.isJointInspectionReq ?? false;

      beforeFiles.clear();
      if ((model.imagesPaths ?? '').isNotEmpty) {
        for (final img in model.imagesPaths!.split(',')) {
          beforeFiles
              .add({'name': img.split('/').last, 'size': 'N/A', 'path': img});
        }
      }

      // Images already uploaded (e.g. by a DCC when creating a depot failure)
      // come in getImageBefor; show them in "Display Uploaded Images".
      beforeImagesList.clear();
      afterImagesList.clear();
      rcaImagesList.clear();
      for (final img in output.getImageBefor ?? const <Map<String, dynamic>>[]) {
        final fileName = img['fileName']?.toString() ?? '';
        if (fileName.isEmpty) continue;
        final imgMap = {
          'name': fileName.split('/').last,
          'path': fileName,
          'isNetwork': true
        };
        final docType = img['documentType']?.toString() ?? '';
        if (docType == 'AFTER_NOT') {
          afterImagesList.add(imgMap);
        } else if (docType == 'RCA_NOT') {
          rcaImagesList.add(imgMap);
        } else {
          beforeImagesList.add(imgMap);
        }
      }
    } catch (e, st) {
      errorMessage.value = 'Error: $e';
      debugPrint('loadMaintenanceFailureDetails error: $e\n$st');
    } finally {
      isLoading.value = false;
      popLoading();
    }
  }

  /// Fallback when the API returns no model: fill what the list row already has.
  Future<void> _populateMaintenanceFromListItem(FailureItem item) async {
    notificationCode.value = item.notificationCode ?? item.failureNo ?? '';
    // List fallback does not expose the numeric statusId, so keep the
    // default 0 (all status-sensitive fields remain disabled until the
    // detail API supplies the actual status).
    maintenanceStatusId.value = 0;
    mainStatusName.value = item.statusName;
    failureDescriptionController.text = item.failureDescription ?? '';
    subLocationController.text = item.subLocation ?? '';
    selectedPriority.value = item.priority;
    if (item.departmentName != null) {
      selectedDepartment.value = item.departmentName;
      await onDepartmentChanged(item.departmentName);
      selectedDepartment.value = item.departmentName;
    }
    if (item.locationName != null) {
      selectedLocation.value = item.locationName;
      await onLocationChanged(item.locationName!);
      selectedLocation.value = item.locationName;
    }
    if (item.functionalLocation != null) {
      ensureDropdownOption(
          functionalLocationList, item.functionalLocation!, '');
      selectedFunctionalLocation.value = item.functionalLocation;
    }
    if (item.failureOccuranceDateTime != null) {
      selectedFailureOccurrenceDate.value =
          _parseDate(item.failureOccuranceDateTime!);
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
      'personResponsible': pick(['personResponsible', 'PersonResponsible']),
      'system': pick(['systemName', 'system', 'System']),
      'subSystem': pick(['subSystem', 'SubSystem']),
      'status': pick(['status', 'Status']) ?? 'Not Okay',
      'remark': pick(['remark', 'Remark']),
      'overallRemark':
      pick(['overallInspectionRemark', 'overallRemark', 'OverallRemark']),
    };

    // Only populate if we actually found something, so the panel stays
    // hidden (inspectionObservation.isEmpty) rather than showing all "N/A".
    if (data.values.any((v) => v != null)) {
      inspectionObservation.assignAll(data);
    }
  }

  // ===========================================================================
  // OCC FAILURE (create)
  // ===========================================================================

  /// The web API returns lists as objects or arrays of {label, value}; accept
  /// either, and a few key spellings, and drop the "Select" placeholder rows.
  List<LabelValue> _occParseList(Map<String, dynamic> output, List<String> keys) {
    dynamic raw;
    for (final k in keys) {
      if (output[k] != null) {
        raw = output[k];
        break;
      }
    }
    if (raw == null) return <LabelValue>[];
    final Iterable items = raw is Map ? raw.values : (raw is List ? raw : const []);
    final result = <LabelValue>[];
    for (final item in items) {
      if (item is! Map) continue;
      final label = (item['label'] ?? item['Label'] ?? item['text'])?.toString().trim() ?? '';
      final value = (item['value'] ?? item['Value'] ?? item['id'])?.toString() ?? '';
      if (label.isEmpty || label.toLowerCase() == 'select') continue;
      result.add(LabelValue(label: label, value: value));
    }
    result.sort((a, b) =>
        (int.tryParse(a.value ?? '') ?? 1 << 30)
            .compareTo(int.tryParse(b.value ?? '') ?? 1 << 30));
    return result;
  }

  List<LabelValue> _occWithoutSelect(Iterable<LabelValue> src) => src
      .where((e) =>
  (e.label ?? '').trim().isNotEmpty &&
      (e.label ?? '').trim().toLowerCase() != 'select')
      .toList();

  /// Loads everything the OCC create form needs. Priority / Department /
  /// Location / Functional Location come from the local master data (same as
  /// Station); Line, Train Set, Reported To, Train Operator, Reported By and
  /// Failure Category Type come from getFailureCreationDeptLocation, with
  /// local fallbacks where a local list exists.
  Future<void> loadOccCreateDropdowns() async {
    pushLoading();
    try {
      final globalData = Get.find<GlobalMasterDataController>();
      if (!globalData.isLoaded) {
        await globalData.initOnLogin();
      }
      _copyGlobalDataToLocal(globalData);
      await loadNotificationTypesFromLocalDb();
      if (masterFunctionalLocations.isEmpty) {
        await loadMasterDataFromDb();
      }
      if (userList.isEmpty || userList.length == 1) {
        await loadMasterDropdownsFromDb(refreshIfEmpty: true);
      }

      // Reported To, Line, Train Set, Reported By, Train Operator and Failure
      // Category Type all come from this one API.
      Map<String, dynamic> deptLoc = <String, dynamic>{};
      try {
        deptLoc = await _failureService.getOccDeptLocationLookups();
      } catch (e) {
        debugPrint('loadOccCreateDropdowns: dept/location lookup failed: $e');
      }
      List<LabelValue> pick(Map<String, dynamic> src, List<String> keys) =>
          _occParseList(src, keys).where((e) => e.value != '0').toList();

      occLineList.assignAll(pick(deptLoc, ['getLineList']));
      occTrainSetList.assignAll(pick(deptLoc, ['getTrainSetList']));
      occReportedToList.assignAll(pick(deptLoc, ['getRoleList']));
      occTrainOperatorList.assignAll(
          pick(deptLoc, ['getTrainOpeartorList', 'getTrainOperatorList']));

      // Failure Reported by; falls back to the local users.
      final reportedBy = pick(deptLoc, ['getFailureReportedbyList']);
      occReportedByList.assignAll(
          reportedBy.isNotEmpty ? reportedBy : _occWithoutSelect(userList));

      final categories = pick(deptLoc, ['getFailureCategoryType']);
      occFailureCategoryList.assignAll(categories.isNotEmpty
          ? categories
          : _occWithoutSelect(failureCategoryTypeList.isNotEmpty
          ? failureCategoryTypeList
          : corrNotificationTypeList));

      // Default "Failure Reported by" to the logged-in user, like the web.
      final currentUserId = await AuthManager().getUserId();
      if (currentUserId != null &&
          (selectedFailureReportedBy.value == null ||
              selectedFailureReportedBy.value!.isEmpty)) {
        final me = occReportedByList
            .firstWhereOrNull((e) => e.value == currentUserId);
        if (me != null) selectedFailureReportedBy.value = me.label;
      }

      // OCC role: System / Sub System options (no-op for other roles).
      await loadOccSystemSubsystems();
    } catch (e) {
      debugPrint('loadOccCreateDropdowns error: $e');
    } finally {
      popLoading();
    }
  }

  Map<String, dynamic> _occFunctionalLocationRow(String label) {
    final clean =
    label.contains(' - ') ? label.split(' - ').first.trim() : label.trim();
    return masterFunctionalLocations.firstWhere(
          (e) =>
      e['funcLocationName']?.toString() == label ||
          e['funcLocation']?.toString() == label ||
          e['funcLocation']?.toString().toUpperCase() == clean.toUpperCase(),
      orElse: () => <String, dynamic>{},
    );
  }

  /// Functional Location changed on the OCC form: run the normal handler, then
  /// fill "Failure Frequency of Gear" and the System options.
  Future<void> onOccFunctionalLocationChanged(String? label) async {
    await onFunctionalLocationChanged(label);

    occFailureFrequency.value = null;
    occFailureFrequencyController.clear();
    // System / Sub System are not tied to the functional location for the OCC
    // role (picked freely) nor for FMC / TPC / CSS / RSC (fixed by OCC), so
    // the functional location must not reset or refill them.
    if (!_occSystemFixed) occSystemDisplayController.clear();
    if (label == null || label.isEmpty || label == 'Select') {
      if (!_occSystemFixed) _applyFmecaSystemSubsystemPairs([]);
      return;
    }

    final row = _occFunctionalLocationRow(label);
    final f = row['frequency'];
    occFailureFrequency.value = f is int ? f : int.tryParse(f?.toString() ?? '');
    occFailureFrequencyController.text =
        occFailureFrequency.value?.toString() ?? '';

    if (_occSystemFixed) return; // System / Sub System are not tied to it

    final funcLocId =
        row['funcLocId']?.toString() ?? row['funcLocation']?.toString() ?? '';
    final locCode = locationCodeForLabel(selectedLocation.value) ?? '0';
    _applyFmecaSystemSubsystemPairs([]);
    await fetchFmecaSystemSubsystemByFuncLoc(locCode, funcLocId);
    occSystemDisplayController.text = occSystemValue;
  }

  /// User picked a System from the dropdown (only shown when the functional
  /// location maps to more than one system).
  Future<void> onOccSystemChanged(String? value) async {
    await onFmecaSystemChanged(value);
    occSystemDisplayController.text = occSystemValue;
    _occLoadSubsystemsForSelectedSystem();
  }

  /// Fills the Sub System options for the picked System from the FMECA pairs.
  void _occLoadSubsystemsForSelectedSystem() {
    final system = selectedFmecaSystem.value;
    selectedFmecaSubsystem.value = null;
    fmecaSubsystemController.clear();
    if (system == null || system.isEmpty) {
      fmecaSubsystemList.clear();
      return;
    }
    final subs = <String, LabelValue>{};
    for (final p in _occFmecaPairs) {
      if (p['system']?.toString() != system) continue;
      final sub = p['subSystem']?.toString() ?? '';
      if (sub.isNotEmpty) subs[sub] = LabelValue(label: sub, value: sub);
    }
    fmecaSubsystemList.assignAll(subs.values.toList());
    if (subs.length == 1) {
      selectedFmecaSubsystem.value = subs.values.first.value;
      fmecaSubsystemController.text = selectedFmecaSubsystem.value ?? '';
      fmecaSubsystemReadOnly.value = true;
    } else {
      fmecaSubsystemReadOnly.value = false;
    }
  }

  /// System shown on the OCC form: the FMECA system if there is one, else
  /// whatever the functional-location handler wrote into the text field.
  String get occSystemValue {
    final s = selectedFmecaSystem.value;
    if (s != null && s.isNotEmpty && s != 'Select') return s;
    if (fmecaSystemController.text.trim().isNotEmpty) {
      return fmecaSystemController.text.trim();
    }
    return systemController.text.trim();
  }

  void onOccTripAffectedChanged(bool value) {
    if (!value) {
      tripDelayUplineController.clear();
      trainCancelNosController.clear();
      tripDelayDownlineController.clear();
      trainDelayMinController.clear();
      trainWithdrawalNosController.clear();
      selectedOccTrainOperator.value = null;
      onOccTrainReplacedChanged(false);
      onOccPassengerDeboardingChanged(false);
    }
    isServiceAffected.value = value;
  }

  void onOccTrainReplacedChanged(bool value) {
    if (!value) {
      trainReplaceNosController.clear();
      occReplacedWithController.clear();
      occReplacedTime.value = null;
    }
    occTrainReplaced.value = value;
  }

  void onOccPassengerDeboardingChanged(bool value) {
    if (!value) trainDeboardedNosController.clear();
    isPassengerDeboarding.value = value;
  }

  void onOccPassengerAffectedChanged(bool value) {
    if (!value) {
      passengersAffectedCountController.clear();
      trappedDurationController.clear();
      rescuedDurationController.clear();
      occWayOfRescueController.clear();
    }
    isPassengerAffected.value = value;
  }

  /// OCC role: System / Sub System are free dropdowns (not tied to the
  /// functional location), fed by subsystemsForOccs for the chosen
  /// department. A previous selection is kept when it is still offered.
  Future<void> loadOccSystemSubsystems() async {
    if (!isOccRoleUser) return;
    try {
      final rows = await _failureService.getOccSystemSubsystems(
          departmentIds: departmentId.value?.toString() ?? '');

      final pairs = <Map<String, dynamic>>[];
      final systems = <String>[];
      for (final r in rows) {
        final system = _occStr(r['system']);
        if (system.isEmpty) continue; // rows without a system can't be picked
        final subs = r['subSystem'];
        if (!systems.contains(system)) systems.add(system);
        if (subs is List) {
          for (final s in subs) {
            final sub = _occStr(s);
            if (sub.isNotEmpty) pairs.add({'system': system, 'subSystem': sub});
          }
        }
      }
      systems.sort();

      final keepSystem = selectedFmecaSystem.value;
      final keepSub = selectedFmecaSubsystem.value;

      _occFmecaPairs = pairs;
      fmecaSystemList
          .assignAll(systems.map((s) => LabelValue(label: s, value: s)));
      fmecaSystemReadOnly.value = false;
      fmecaSubsystemReadOnly.value = false;

      if (keepSystem != null && systems.contains(keepSystem)) {
        selectedFmecaSystem.value = keepSystem;
        _occLoadSubsystemsForSelectedSystem();
        if (keepSub != null &&
            fmecaSubsystemList.any((e) => e.value == keepSub)) {
          selectedFmecaSubsystem.value = keepSub;
          fmecaSubsystemController.text = keepSub;
        }
      } else {
        selectedFmecaSystem.value = null;
        selectedFmecaSubsystem.value = null;
        fmecaSubsystemList.clear();
      }
      occSystemDisplayController.text = occSystemValue;
    } catch (e) {
      debugPrint('loadOccSystemSubsystems error: $e');
    }
  }

  /// Reported To changed. Completed date/time only applies to OCC-reported
  /// failures, so clear it when moving away from OCC.
  void onOccReportedToChanged(String? label) {
    selectedOccReportedTo.value = label;
    if (!occReportedToIsOcc) selectedFailureCompletedDate.value = null;
  }

  void onOccFailureCategoryChanged(String? label) {
    selectedFailureCategoryType.value = label;
    if (!occIsCategoryOther) occCategoryOtherController.clear();
  }

  bool _occBlank(String? v) => v == null || v.trim().isEmpty;
  bool _occUnselected(String? v) =>
      v == null || v.trim().isEmpty || v == 'Select';

  /// Same rules as the web page's required (*) fields.
  List<String> _occValidate({bool close = false}) {
    final errors = <String>[];
    if (_occUnselected(selectedPriority.value)) errors.add('Priority is required.');
    if (_occBlank(failureDescriptionController.text)) {
      errors.add('Failure Description is required.');
    }
    if (_occUnselected(selectedDepartment.value)) errors.add('Department is required.');
    if (_occUnselected(selectedOccReportedTo.value)) errors.add('Reported To is required.');
    if (selectedFailureOccurrenceDate.value == null) {
      errors.add('Actual Failure Occurrence is required.');
    }
    if (_occUnselected(selectedFailureReportedBy.value)) {
      errors.add('Failure Reported by is required.');
    }
    if (_occUnselected(selectedFailureCategoryType.value)) {
      errors.add('Failure Category Type is required.');
    } else if (occIsCategoryOther && _occBlank(occCategoryOtherController.text)) {
      errors.add('Other failure category is required.');
    }

    // System / Sub System are required on the web page; they can only be
    // chosen when the functional location offered some, so only enforce then.
    if (fmecaSystemList.isNotEmpty && _occBlank(occSystemValue)) {
      errors.add('System is required.');
    }
    if (fmecaSubsystemList.isNotEmpty &&
        _occUnselected(selectedFmecaSubsystem.value)) {
      errors.add('Sub System is required.');
    }

    // Completed date/time: only OCC-reported failures, mandatory to close.
    final done = selectedFailureCompletedDate.value;
    if (close && done == null) {
      errors.add('Actual Failure Completed Date & Time is required.');
    }
    if (done != null &&
        selectedFailureOccurrenceDate.value != null &&
        done.isBefore(selectedFailureOccurrenceDate.value!)) {
      errors.add('Completed time cannot be before the failure occurrence.');
    }

    if (isServiceAffected.value) {
      if (_occBlank(tripDelayUplineController.text)) errors.add('Trip Delay Upline is required.');
      if (_occBlank(trainCancelNosController.text)) errors.add('Trip Cancel is required.');
      if (_occBlank(tripDelayDownlineController.text)) errors.add('Trip Delay Downline is required.');
      if (_occBlank(trainDelayMinController.text)) errors.add('Trip Delay in Min is required.');
      if (_occBlank(trainWithdrawalNosController.text)) errors.add('Trip Withdrawal is required.');
      if (occTrainReplaced.value && _occBlank(trainReplaceNosController.text)) {
        errors.add('Train Replace is required.');
      }
      if (isPassengerDeboarding.value && _occBlank(trainDeboardedNosController.text)) {
        errors.add('Train Deboarded is required.');
      }
    }
    if (isPassengerAffected.value) {
      if (_occBlank(passengersAffectedCountController.text)) {
        errors.add('Number Of Passenger Affected is required.');
      }
      if (_occBlank(trappedDurationController.text)) errors.add('Trapped Duration is required.');
      if (_occBlank(rescuedDurationController.text)) errors.add('Rescued Duration is required.');
    }
    return errors;
  }

  int? _occInt(TextEditingController c) => int.tryParse(c.text.trim());

  int _occId(List<LabelValue> list, String? label) =>
      int.tryParse(lookupValue(list, label)) ?? 0;

  void _occError(String message) {
    Get.snackbar(
      'Validation Error',
      message,
      backgroundColor: AppColors.red.withValues(alpha: 0.9),
      colorText: AppColors.white1,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  /// [close] = "Save and Close" (StatusId 39, completed date mandatory);
  /// otherwise "Save" (StatusId 1). Mirrors the web insertFailureDetails call.
  Future<void> createOccFailure({bool close = false}) async {
    if (!isOccController) {
      Get.snackbar(
        'Access Denied',
        'Only Chief Controller can create OCC failure.',
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (close && !occReportedToIsOcc) {
      _occError('Only failures reported to OCC can be closed by OCC.');
      return;
    }
    final errors = _occValidate(close: close);
    if (errors.isNotEmpty) {
      _occError(errors.first);
      return;
    }

    try {
      // Attachments first, so a too-large file fails before any loader shows.
      final files = <http.MultipartFile>[];
      for (final f in beforeFiles) {
        final path = f['path']?.toString();
        if (path == null || path.isEmpty || f['isNetwork'] == true) continue;
        final part = await http.MultipartFile.fromPath('beforImage', path,
            filename: f['name']?.toString());
        if (part.length > occMaxAttachmentBytes) {
          _occError('${f['name']} is larger than 1 MB.');
          return;
        }
        files.add(part);
      }

      EasyLoading.show(status: 'Saving...');
      final createdBy =
          int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;

      final deptId = lookupValue(departmentList, selectedDepartment.value);
      final funcLocId =
      lookupValue(functionalLocationList, selectedFunctionalLocation.value);
      final fmt = DateFormat('dd/MM/yyyy HH:mm');

      final body = <String, dynamic>{
        'PriorityId': lookupValue(priorityTypeList, selectedPriority.value),
        'DepartmentIds': deptId,
        'DepartmentId_1': deptId,
        'DepartmentId_2': 0,
        'DepartmentId_3': 0,
        'FailureDescription': failureDescriptionController.text.trim(),
        'LocationId':
        lookupLocationId(locationTypeList, selectedLocation.value),
        'LocationText': occLocationTextController.text.trim(),
        'SubLocation': subLocationController.text.trim(),
        'System': occSystemValue,
        'FuncationLocationIds': funcLocId == '0' ? '' : funcLocId,
        'FuncationLocationId_1': funcLocId == '0' ? 0 : funcLocId,
        'FuncationLocationId_2': 0,
        'FuncationLocationId_3': 0,
        'TrainId': trainIdController.text.trim(),
        'LineId': _occId(occLineList, selectedOccLine.value),
        'TrainSetId': _occId(occTrainSetList, selectedOccTrainSet.value),
        'ReportedToId': _occId(occReportedToList, selectedOccReportedTo.value),
        'ActualFailureOccuranceDate':
        fmt.format(selectedFailureOccurrenceDate.value!),
        'FailureReportedbyId':
        _occId(occReportedByList, selectedFailureReportedBy.value),
        'FailureCategoryTypeId':
        _occId(occFailureCategoryList, selectedFailureCategoryType.value),
        'FailureCategoryTypeText': occIsCategoryOther
            ? occCategoryOtherController.text.trim()
            : '',
        'IsTripAffected': isServiceAffected.value,
        'IsTrainReplace': isServiceAffected.value && occTrainReplaced.value,
        'IsTrainDeboarded':
        isServiceAffected.value && isPassengerDeboarding.value,
        'IsPassengerAffected': isPassengerAffected.value,
        'CreatedBy': createdBy,
      };

      if (isServiceAffected.value) {
        body['TripDelayUpline'] = _occInt(tripDelayUplineController);
        body['TripDelayDownline'] = _occInt(tripDelayDownlineController);
        body['TripCancel'] = _occInt(trainCancelNosController);
        body['TrainDelayInMin'] = _occInt(trainDelayMinController);
        body['NoOfTranWithdrawal'] = _occInt(trainWithdrawalNosController);
        body['OccTrainOpeartorId'] =
            _occId(occTrainOperatorList, selectedOccTrainOperator.value);
        if (occTrainReplaced.value) {
          body['TrainReplace'] = _occInt(trainReplaceNosController);
          body['TrainReplacedWithRemark'] =
              occReplacedWithController.text.trim();
          body['TrainReplacedWithTime'] = occReplacedTime.value != null
              ? DateFormat('HH:mm').format(occReplacedTime.value!)
              : '';
        }
        if (isPassengerDeboarding.value) {
          body['TrainDeboarded'] = _occInt(trainDeboardedNosController);
        }
      }
      if (isPassengerAffected.value) {
        body['NumberOfPassengerAffected'] =
            _occInt(passengersAffectedCountController);
        body['TrappedDuration'] = _occInt(trappedDurationController);
        body['RescusedDuration'] = _occInt(rescuedDurationController);
        body['OccWayOfRescueRemark'] = occWayOfRescueController.text.trim();
      }

      // Fields the web page sends in addition to the form values.
      body['Action'] = 'INSERTFAILURENOTIFUCATION';
      body['RoleId'] = _occId(occReportedToList, selectedOccReportedTo.value);
      body['SubSystem'] = (selectedFmecaSubsystem.value ?? '').trim();
      body['Frequency'] = occFailureFrequency.value ?? 0;
      body['StatusId'] = close ? 39 : 1;
      body['ActualFailureCompletedDateTime'] =
      (occReportedToIsOcc && selectedFailureCompletedDate.value != null)
          ? fmt.format(selectedFailureCompletedDate.value!)
          : '';

      debugPrint('createOccFailure: payload $body, files=${files.length}');
      final failureNo = await _failureService.createOccFailure(body, files: files);

      if (Get.isRegistered<FailureListController>(tag: 'OCC')) {
        Future.microtask(() async {
          try {
            await Get.find<FailureListController>(tag: 'OCC').fetchFailures();
          } catch (e) {
            debugPrint('createOccFailure: list refresh failed: $e');
          }
        });
      }

      EasyLoading.dismiss();
      Get.back();
      showFailureCreatedPopup(
          type: 'OCC', failureNo: failureNo, closed: close);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('createOccFailure error: $e');
      Get.snackbar(
        AppStrings.error,
        'Could not save OCC failure. Please check your connection and try again.',
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ===========================================================================
  // DEPOT FAILURE (DCC create)
  // ===========================================================================

  bool get isDcc {
    final role =
        Get.find<SessionController>().selectedRole.value?.roleDescr ?? '';
    return role.toUpperCase().contains('DCC');
  }

  final depotDetail = <String, dynamic>{}.obs;
  final depotHistory = <Map<String, dynamic>>[].obs;
  final depotImages = <String>[].obs;

  /// Loads an existing depot failure for the read-only DCC detail view.
  Future<void> loadDepotFailureDetails(String id) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final output = await _failureService.getDepotFailureById(id);
      final d = output['getFailureCreationDetails'];
      if (d is! Map) {
        errorMessage.value = 'Failure details not found.';
        return;
      }
      final detail = Map<String, dynamic>.from(d);
      // Category label comes from the lookup list sent with the details.
      final catId = detail['failureCategoryTypeId']?.toString();
      final cats = output['getFailureCategoryType'];
      if (cats is List) {
        for (final c in cats) {
          if (c is Map && c['value']?.toString() == catId) {
            detail['failureCategoryTypeName'] = c['label'];
            break;
          }
        }
      }
      depotDetail.assignAll(detail);
      notificationCode.value = detail['failureId']?.toString() ?? '';
      mainStatusName.value = detail['statusName']?.toString();

      final history = output['getNotificationHistory'];
      depotHistory.assignAll(history is List
          ? history.whereType<Map>().map((e) => Map<String, dynamic>.from(e))
          : <Map<String, dynamic>>[]);

      final images = output['getImageBefor'];
      depotImages.assignAll(images is List
          ? images
          .whereType<Map>()
          .map((e) => e['fileName']?.toString() ?? '')
          .where((f) => f.isNotEmpty)
          .map((f) => '${AppUrls.imageUrl}$f')
          : <String>[]);
    } catch (e) {
      debugPrint('loadDepotFailureDetails error: $e');
      errorMessage.value = 'Failed to load details. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createDepotFailure() async {
    if (!isDcc) {
      Get.snackbar(
        'Access Denied',
        'Only DCC can create depot failure.',
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final errors = <String>[];
    if (_occUnselected(selectedPriority.value)) errors.add('Priority is required.');
    if (_occBlank(failureDescriptionController.text)) {
      errors.add('Failure Description is required.');
    }
    if (_occUnselected(selectedDepartment.value)) errors.add('Department is required.');
    if (_occUnselected(selectedLocation.value)) errors.add('Location is required.');
    if (selectedFailureOccurrenceDate.value == null) {
      errors.add('Actual Failure Occurrence is required.');
    }
    if (_occUnselected(selectedFailureReportedBy.value)) {
      errors.add('Failure Reported by is required.');
    }
    if (_occUnselected(selectedFailureCategoryType.value)) {
      errors.add('Failure Category Type is required.');
    }
    if (isPassengerAffected.value) {
      if (_occBlank(passengersAffectedCountController.text)) {
        errors.add('Number Of Passenger Affected is required.');
      }
      if (_occBlank(trappedDurationController.text)) errors.add('Trapped Duration is required.');
      if (_occBlank(rescuedDurationController.text)) errors.add('Rescued Duration is required.');
    }
    if (errors.isNotEmpty) {
      _occError(errors.first);
      return;
    }

    try {
      final files = <http.MultipartFile>[];
      for (final f in beforeFiles) {
        final path = f['path']?.toString();
        if (path == null || path.isEmpty || f['isNetwork'] == true) continue;
        final part = await http.MultipartFile.fromPath('beforImage', path,
            filename: f['name']?.toString());
        if (part.length > occMaxAttachmentBytes) {
          _occError('${f['name']} is larger than 1 MB.');
          return;
        }
        files.add(part);
      }

      EasyLoading.show(status: 'Saving...');
      final createdBy =
          int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;

      final deptId = lookupValue(departmentList, selectedDepartment.value);
      final funcLocId =
      lookupValue(functionalLocationList, selectedFunctionalLocation.value);
      final reportedById =
          int.tryParse(lookupValue(userList, selectedFailureReportedBy.value)) ??
              createdBy;
      final fmt = DateFormat('dd/MM/yyyy HH:mm');

      final body = <String, dynamic>{
        'PriorityId': lookupValue(priorityTypeList, selectedPriority.value),
        'DepartmentIds': deptId,
        'DepartmentId_1': deptId,
        'DepartmentId_2': 0,
        'DepartmentId_3': 0,
        'FailureDescription': failureDescriptionController.text.trim(),
        'LocationId':
        lookupLocationId(locationTypeList, selectedLocation.value),
        'SubLocation': subLocationController.text.trim(),
        'System': occSystemValue,
        'FuncationLocationIds': funcLocId == '0' ? '' : funcLocId,
        'FuncationLocationId_1': funcLocId == '0' ? 0 : funcLocId,
        'FuncationLocationId_2': 0,
        'FuncationLocationId_3': 0,
        'TrainId': '',
        'ActualFailureOccuranceDate':
        fmt.format(selectedFailureOccurrenceDate.value!),
        'FailureReportedbyId': reportedById,
        'ActualFailureCompletedDateTime': '',
        'IsTripAffected': false,
        'TripDelayUpline': null,
        'TripDelayDownline': null,
        'TripCancel': null,
        'TrainDelayInMin': null,
        'NoOfTranWithdrawal': null,
        'IsTrainReplace': false,
        'TrainReplace': null,
        'IsTrainDeboarded': false,
        'TrainDeboarded': null,
        'IsPassengerAffected': isPassengerAffected.value,
        'NumberOfPassengerAffected': isPassengerAffected.value
            ? _occInt(passengersAffectedCountController)
            : null,
        'TrappedDuration':
        isPassengerAffected.value ? _occInt(trappedDurationController) : null,
        'RescusedDuration':
        isPassengerAffected.value ? _occInt(rescuedDurationController) : null,
        'CreatedBy': createdBy,
        'FailureCategoryTypeId':
        lookupValue(apiFailureCategoryList, selectedFailureCategoryType.value),
        'FailureCategoryTypeText': '',
      };

      debugPrint('createDepotFailure: payload $body, files=${files.length}');
      final failureNo =
      await _failureService.createDepotFailure(body, files: files);

      if (Get.isRegistered<FailureListController>(tag: 'Depot')) {
        Future.microtask(() async {
          try {
            await Get.find<FailureListController>(tag: 'Depot').fetchFailures();
          } catch (e) {
            debugPrint('createDepotFailure: list refresh failed: $e');
          }
        });
      }

      EasyLoading.dismiss();
      Get.back();
      showFailureCreatedPopup(type: 'Depot', failureNo: failureNo);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('createDepotFailure error: $e');
      Get.snackbar(
        AppStrings.error,
        'Could not save depot failure. Please check your connection and try again.',
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ===========================================================================
  // OCC FAILURE (FMC update)
  // ===========================================================================

  /// Server sends some lists as arrays, some as {"0": {...}} objects.
  List<Map<String, dynamic>> _occValues(dynamic raw) {
    final Iterable items =
    raw is Map ? raw.values : (raw is List ? raw : const []);
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String _occStr(dynamic v) => v?.toString().trim() ?? '';

  int _occToInt(dynamic v) => int.tryParse(_occStr(v)) ?? 0;

  String? _occLabelFor(List<LabelValue> list, dynamic value) {
    final v = _occStr(value);
    if (v.isEmpty || v == '0') return null;
    return list.firstWhereOrNull((e) => e.value == v)?.label;
  }

  /// Loads an OCC failure into the shared form state for the FMC user.
  Future<void> loadOccFailureForUpdate(String id) async {
    encryptedId.value = id;
    occUpdateLoaded.value = false;
    pushLoading();
    try {
      // Lookup lists + master data first (also used by the create form).
      await loadOccCreateDropdowns();

      final output = await _failureService.getOccFailureById(id);
      final raw = output['getFailureCreationDetails'];
      if (raw is! Map) {
        throw Exception('Failure details not found');
      }
      final d = Map<String, dynamic>.from(raw);

      occLoadedRoleId = _occToInt(d['roleId']);
      occLoadedPriorityId = _occToInt(d['priorityId']);
      occLoadedLineId = _occToInt(d['lineId']);
      occLoadedTrainSetId = _occToInt(d['trainSetId']);
      occLoadedLocationId = _occToInt(d['locationId']);
      occLoadedDepartmentId =
          _occToInt(d['departmentId_1'] ?? d['departmentId']);
      originalFailureId.value = _occToInt(d['id']);
      notificationCode.value = _occStr(d['failureId']);
      mainStatusName.value = _occStr(d['statusName']).isEmpty
          ? null
          : _occStr(d['statusName']);
      occCreatedDateText.value = _occStr(d['createdDate']);
      occIsStationFailure.value = d['isStationController'] == true;
      occIsAssigned.value = _occStr(d['deptNotificationCode']).isNotEmpty ||
          _occToInt(d['deptNotificationId']) > 0;

      // New description is typed fresh; earlier ones are shown as history.
      failureDescriptionController.clear();

      selectedPriority.value =
          _occLabelFor(priorityTypeList, d['priorityId']) ??
              _occStr(d['priority']);
      if (selectedPriority.value!.isEmpty) selectedPriority.value = null;

      final deptLabel = _occLabelFor(departmentList, occLoadedDepartmentId) ??
          _occStr(d['departmentName']);
      selectedDepartment.value = deptLabel.isEmpty ? null : deptLabel;
      departmentId.value = occLoadedDepartmentId == 0 ? null : occLoadedDepartmentId;

      final locLabel = _occLabelFor(locationTypeList, d['locationId']) ??
          _occStr(d['location']);
      selectedLocation.value = locLabel.isEmpty ? null : locLabel;
      maintenanceLocationTypeId.value = occLoadedLocationId;

      // Functional Location options depend on department + location.
      resetFunctionalAndEquipmentSelections();
      await loadFunctionalLocationsOnDemand();
      _updateFunctionalLocationAndEquipmentOptions();

      final funcId = _occStr(d['funcationLocationId']);
      final funcName = _occStr(d['funcationLocation']);
      if (funcId.isNotEmpty && funcId != '0') {
        var item = functionalLocationList
            .firstWhereOrNull((e) => e.value == funcId);
        if (item == null) {
          item = LabelValue(
              label: funcName.isEmpty ? funcId : funcName, value: funcId);
          functionalLocationList.insert(0, item);
        }
        selectedFunctionalLocation.value = item.label;

        final row = masterFunctionalLocations.firstWhere(
              (e) => e['funcLocId']?.toString() == funcId,
          orElse: () => <String, dynamic>{},
        );
        final f = row['frequency'];
        occFailureFrequency.value =
        f is int ? f : int.tryParse(f?.toString() ?? '');
        occFailureFrequencyController.text =
            occFailureFrequency.value?.toString() ?? '';
      } else {
        selectedFunctionalLocation.value = null;
      }

      subLocationController.text = _occStr(d['subLocation']);
      occLocationTextController.text = _occStr(d['locationText']);
      trainIdController.text = _occStr(d['trainId']);
      occLineDisplayController.text = _occStr(d['lineIdName']);
      occTrainSetDisplayController.text = _occStr(d['trainSetName']);
      // The OCC role edits these (FMC sees them read-only above).
      selectedOccReportedTo.value =
          _occLabelFor(occReportedToList, d['roleId']);
      final reportedToName =
      (selectedOccReportedTo.value ?? _occStr(d['roleName']))
          .trim()
          .toUpperCase();
      occLoadedReportedToIsOcc.value =
          reportedToName.isEmpty || reportedToName == 'OCC';
      selectedOccLine.value = _occLabelFor(occLineList, d['lineId']);
      selectedOccTrainSet.value =
          _occLabelFor(occTrainSetList, d['trainSetId']);

      // System / Sub System: fetch the valid pairs, then restore what was saved.
      final loadedSys =
      _occStr(d['system'] ?? d['System']);
      final loadedSub = _occStr(
          d['subSystem'] ?? d['SubSystem'] ?? d['subsystem'] ?? d['Subsystem']);
      if (isOccRoleUser) {
        // OCC role: options come from subsystemsForOccs for this department.
        await loadOccSystemSubsystems();
      } else {
        _applyFmecaSystemSubsystemPairs([]);
        if (occLoadedLocationId != 0 && funcId.isNotEmpty && funcId != '0') {
          await fetchFmecaSystemSubsystemByFuncLoc(
              occLoadedLocationId.toString(), funcId);
        }
      }
      if (loadedSys.isNotEmpty &&
          (selectedFmecaSystem.value == null ||
              selectedFmecaSystem.value!.isEmpty)) {
        if (!fmecaSystemList.any((e) => e.label == loadedSys)) {
          fmecaSystemList.add(LabelValue(label: loadedSys, value: loadedSys));
        }
        selectedFmecaSystem.value = loadedSys;
        fmecaSystemController.text = loadedSys;
        _occLoadSubsystemsForSelectedSystem();
      }
      if (loadedSub.isNotEmpty &&
          (selectedFmecaSubsystem.value == null ||
              selectedFmecaSubsystem.value!.isEmpty)) {
        if (!fmecaSubsystemList.any((e) => e.label == loadedSub)) {
          fmecaSubsystemList.add(LabelValue(label: loadedSub, value: loadedSub));
        }
        selectedFmecaSubsystem.value = loadedSub;
        fmecaSubsystemController.text = loadedSub;
      }
      occSystemDisplayController.text = occSystemValue;

      // Dates
      occLoadedOccurrenceRaw = _occStr(d['actualFailureOccuranceDate']);
      selectedFailureOccurrenceDate.value = occLoadedOccurrenceRaw.isEmpty
          ? null
          : _parseDate(occLoadedOccurrenceRaw);
      final completed = _occStr(d['actualFailureCompletedDateTime']);
      selectedFailureCompletedDate.value =
      completed.isEmpty ? null : _parseDate(completed);

      selectedFailureReportedBy.value =
          _occLabelFor(occReportedByList, d['failureReportedbyId']) ??
              _occStr(d['failureReportedby']);
      if (selectedFailureReportedBy.value!.isEmpty) {
        selectedFailureReportedBy.value = null;
      }

      selectedFailureCategoryType.value =
          _occLabelFor(occFailureCategoryList, d['failureCategoryTypeId']);
      occCategoryOtherController.text = _occStr(d['failureCategoryTypeText']);

      // Trip
      isServiceAffected.value = d['isTripAffected'] == true;
      tripDelayUplineController.text = _occStr(d['tripDelayUpline']);
      tripDelayDownlineController.text = _occStr(d['tripDelayDownline']);
      trainCancelNosController.text = _occStr(d['tripCancel']);
      trainDelayMinController.text = _occStr(d['trainDelayInMin']);
      trainWithdrawalNosController.text = _occStr(d['noOfTranWithdrawal']);
      selectedOccTrainOperator.value =
          _occLabelFor(occTrainOperatorList, d['occTrainOpeartorId']);

      occTrainReplaced.value = d['isTrainReplace'] == true;
      trainReplaceNosController.text = _occStr(d['trainReplace']);
      occReplacedWithController.text = _occStr(d['trainReplacedWithRemark']);
      final replacedTime = _occStr(d['trainReplacedWithTime']);
      occReplacedTime.value = null;
      if (replacedTime.isNotEmpty) {
        try {
          final t = DateFormat('HH:mm').parseLoose(replacedTime);
          final now = DateTime.now();
          occReplacedTime.value =
              DateTime(now.year, now.month, now.day, t.hour, t.minute);
        } catch (_) {}
      }

      isPassengerDeboarding.value = d['isTrainDeboarded'] == true;
      trainDeboardedNosController.text = _occStr(d['trainDeboarded']);

      // Passenger
      isPassengerAffected.value = d['isPassengerAffected'] == true;
      passengersAffectedCountController.text =
          _occStr(d['numberOfPassengerAffected']);
      trappedDurationController.text = _occStr(d['trappedDuration']);
      rescuedDurationController.text = _occStr(d['rescusedDuration']);
      occWayOfRescueController.text = _occStr(d['occWayOfRescueRemark']);

      // Existing attachments (view only) + new uploads
      beforeFiles.clear();
      beforeImagesList.clear();
      afterImagesList.clear();
      rcaImagesList.clear();
      for (final img in _occValues(output['getImageBefor'])) {
        final fileName = _occStr(img['fileName']);
        if (fileName.isEmpty) continue;
        final entry = <String, dynamic>{
          'name': fileName.split('/').last,
          'path': fileName,
          'isNetwork': true,
          'id': img['id'],
        };
        switch (_occStr(img['documentType'])) {
          case 'BEFORE_NOT':
            beforeImagesList.add(entry);
            break;
          case 'AFTER_NOT':
            afterImagesList.add(entry);
            break;
          case 'RCA_NOT':
            rcaImagesList.add(entry);
            break;
        }
      }

      notificationDescriptionHistoryList.assignAll(
          _occValues(output['getNotificationHistory'])
              .map(NotificationHistory.fromJson)
              .toList());
      notificationHistoryList.assignAll(
          _occValues(output['getNotificationActionUserHistory'])
              .map(NotificationActionHistory.fromJson)
              .toList());

      occUpdateLoaded.value = true;
    } catch (e) {
      debugPrint('loadOccFailureForUpdate error: $e');
      errorMessage.value = 'Error: $e';
      Get.snackbar(
        AppStrings.error,
        'Could not load OCC failure. Please check your connection and try again.',
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      popLoading();
    }
  }

  void _occClearFunctionalDerived() {
    occFailureFrequency.value = null;
    occFailureFrequencyController.clear();
    // System / Sub System stay as they are for these roles.
    if (_occSystemFixed) return;
    occSystemDisplayController.clear();
    _applyFmecaSystemSubsystemPairs([]);
  }

  /// Department changed on the FMC update form: functional location and the
  /// system fields depend on it, so clear them like the web does.
  Future<void> onOccUpdateDepartmentChanged(String? label) async {
    await onDepartmentChanged(label);
    _occClearFunctionalDerived();
  }

  Future<void> onOccUpdateLocationChanged(String? label) async {
    await onLocationChanged(label);
    _occClearFunctionalDerived();
  }

  /// The web flips status 204 -> 179 on the production host only.
  bool get occIsProdServer => AppUrls.baseUrl.contains('digi.mahametro.org');

  /// Sub System / System change on the update form.
  void onOccSubsystemChanged(String? value) => onFmecaSubsystemChanged(value);

  /// [kind]: 'assign' (Assign To Department), 'draft' (Save As Draft) or
  /// 'close' (Update And Close) — the same three actions as the web page.
  List<String> occUpdateValidate(String kind) {
    final errors = <String>[];
    if (_occUnselected(selectedPriority.value)) errors.add('Priority is required.');
    if (kind == 'assign' && _occUnselected(selectedDepartment.value)) {
      errors.add('Department is required.');
    }
    if (_occBlank(occSystemValue)) errors.add('System is required.');
    if (_occUnselected(selectedFmecaSubsystem.value)) {
      errors.add('Sub System is required.');
    }
    if (selectedFailureOccurrenceDate.value == null) {
      errors.add('Actual Failure Occurrence is required.');
    }
    if (kind == 'close') {
      final done = selectedFailureCompletedDate.value;
      if (done == null) {
        errors.add('Actual Failure Completed Date & Time is required.');
      } else if (selectedFailureOccurrenceDate.value != null &&
          done.isBefore(selectedFailureOccurrenceDate.value!)) {
        errors.add('Completed time cannot be before the failure occurrence.');
      }
    }
    if (!occIsStationFailure.value && isServiceAffected.value) {
      if (_occBlank(tripDelayUplineController.text)) errors.add('Trip Delay Upline is required.');
      if (_occBlank(tripDelayDownlineController.text)) errors.add('Trip Delay Downline is required.');
      if (_occBlank(trainCancelNosController.text)) errors.add('Trip Cancel is required.');
      if (_occBlank(trainDelayMinController.text)) errors.add('Trip Delay in Min is required.');
      if (_occBlank(trainWithdrawalNosController.text)) errors.add('Trip Withdrawal is required.');
      if (occTrainReplaced.value && _occBlank(trainReplaceNosController.text)) {
        errors.add('Train Replace is required.');
      }
      if (isPassengerDeboarding.value && _occBlank(trainDeboardedNosController.text)) {
        errors.add('Train Deboarded is required.');
      }
    }
    if (isPassengerAffected.value) {
      if (_occBlank(passengersAffectedCountController.text)) {
        errors.add('Number Of Passenger Affected is required.');
      }
      if (_occBlank(trappedDurationController.text)) errors.add('Trapped Duration is required.');
      if (_occBlank(rescuedDurationController.text)) errors.add('Rescued Duration is required.');
    }
    return errors;
  }

  /// Sends the FMC user's update. Caller has already asked for confirmation.
  Future<bool> submitOccUpdate(String kind) async {
    if (!isFmcUser && !isOccRoleUser) {
      Get.snackbar(
        'Access Denied',
        'Only OCC, FMC, TPC, CSS or RSC users can update this OCC failure.',
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (occRoleViewOnly) {
      _occError('This failure was reported to another role; only that role can update it.');
      return false;
    }
    if (occDelegateReadOnly) {
      _occError('This failure is already assigned to a department and can no longer be updated.');
      return false;
    }
    if (kind == 'close' && isOccRoleUser && !occReportedToIsOcc) {
      _occError('Only failures reported to OCC can be closed by OCC.');
      return false;
    }
    final errors = occUpdateValidate(kind);
    if (errors.isNotEmpty) {
      _occError(errors.first);
      return false;
    }

    try {
      final files = <http.MultipartFile>[];
      for (final f in beforeFiles) {
        final path = f['path']?.toString();
        if (path == null || path.isEmpty || f['isNetwork'] == true) continue;
        final part = await http.MultipartFile.fromPath('beforImage', path,
            filename: f['name']?.toString());
        if (part.length > occMaxAttachmentBytes) {
          _occError('${f['name']} is larger than 1 MB.');
          return false;
        }
        files.add(part);
      }

      EasyLoading.show(status: 'Saving...');
      final createdBy =
          int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;
      final fmt = DateFormat('dd/MM/yyyy HH:mm');

      final deptId = lookupValue(departmentList, selectedDepartment.value,
          fallback: occLoadedDepartmentId.toString());
      final funcLocId = lookupValue(
          functionalLocationList, selectedFunctionalLocation.value,
          fallback: '');
      final trip = !occIsStationFailure.value && isServiceAffected.value;
      final replaced = trip && occTrainReplaced.value;
      final deboarded = trip && isPassengerDeboarding.value;

      final body = <String, dynamic>{
        'Action': kind == 'assign'
            ? 'UpdateAndAssgineToDepartment'
            : 'UPDATEFAILURENOTIFUCATION',
        'Id': originalFailureId.value ?? 0,
        'RoleId': isOccRoleUser && _occId(occReportedToList, selectedOccReportedTo.value) != 0
            ? _occId(occReportedToList, selectedOccReportedTo.value)
            : occLoadedRoleId,
        'PriorityId': _occId(priorityTypeList, selectedPriority.value) == 0
            ? occLoadedPriorityId
            : _occId(priorityTypeList, selectedPriority.value),
        // The web update sends the department as a number.
        'DepartmentIds': int.tryParse(deptId) ?? 0,
        'DepartmentId_1': int.tryParse(deptId) ?? 0,
        'DepartmentId_2': 0,
        'DepartmentId_3': 0,
        'FailureDescription': failureDescriptionController.text.trim(),
        'LocationId': lookupLocationId(
            locationTypeList, selectedLocation.value,
            fallback: occLoadedLocationId.toString()),
        'SubLocation': subLocationController.text.trim(),
        'System': occSystemValue,
        'SubSystem': (selectedFmecaSubsystem.value ?? '').trim(),
        'FuncationLocationIds': funcLocId,
        'FuncationLocationId_1': int.tryParse(funcLocId) ?? 0,
        'FuncationLocationId_2': 0,
        'FuncationLocationId_3': 0,
        'TrainId': trainIdController.text.trim(),
        // FMC cannot change the occurrence, so the original text goes back
        // as-is. The OCC role can: send the new value only if it changed.
        'ActualFailureOccuranceDate': (occLoadedOccurrenceRaw.isNotEmpty &&
            !(isOccRoleUser &&
                selectedFailureOccurrenceDate.value !=
                    _parseDate(occLoadedOccurrenceRaw)))
            ? occLoadedOccurrenceRaw
            : fmt.format(selectedFailureOccurrenceDate.value!),
        'FailureReportedbyId':
        _occId(occReportedByList, selectedFailureReportedBy.value),
        'ActualFailureCompletedDateTime':
        selectedFailureCompletedDate.value != null
            ? fmt.format(selectedFailureCompletedDate.value!)
            : null,
        'IsTripAffected': isServiceAffected.value,
        'TripDelayUpline': trip ? _occInt(tripDelayUplineController) : null,
        'TripDelayDownline': trip ? _occInt(tripDelayDownlineController) : null,
        'TripCancel': trip ? _occInt(trainCancelNosController) : null,
        'TrainDelayInMin': trip ? _occInt(trainDelayMinController) : null,
        'NoOfTranWithdrawal': trip ? _occInt(trainWithdrawalNosController) : null,
        'IsTrainReplace': occTrainReplaced.value,
        'TrainReplace': replaced ? _occInt(trainReplaceNosController) : null,
        'IsTrainDeboarded': isPassengerDeboarding.value,
        'TrainDeboarded': deboarded ? _occInt(trainDeboardedNosController) : null,
        'IsPassengerAffected': isPassengerAffected.value,
        'NumberOfPassengerAffected': isPassengerAffected.value
            ? _occInt(passengersAffectedCountController)
            : null,
        'TrappedDuration':
        isPassengerAffected.value ? _occInt(trappedDurationController) : null,
        'RescusedDuration':
        isPassengerAffected.value ? _occInt(rescuedDurationController) : null,
        'CreatedBy': createdBy,
        'StatusId': kind == 'close'
            ? 39
            : (isOccRoleUser ? 1 : (occIsProdServer ? 179 : 204)),
        'LocationText': occLocationTextController.text.trim(),
        'LineId': isOccRoleUser &&
            _occId(occLineList, selectedOccLine.value) != 0
            ? _occId(occLineList, selectedOccLine.value)
            : occLoadedLineId,
        'TrainSetId': isOccRoleUser &&
            _occId(occTrainSetList, selectedOccTrainSet.value) != 0
            ? _occId(occTrainSetList, selectedOccTrainSet.value)
            : occLoadedTrainSetId,
        // Empty values go as null on update (as the web does), not 0 / "".
        'OCCTrainOpeartorId': _occId(occTrainOperatorList, selectedOccTrainOperator.value) == 0
            ? null
            : _occId(occTrainOperatorList, selectedOccTrainOperator.value),
        'OCCWayOfRescueRemark': occWayOfRescueController.text.trim().isEmpty
            ? null
            : occWayOfRescueController.text.trim(),
        'TrainReplacedWithRemark': occReplacedWithController.text.trim().isEmpty
            ? null
            : occReplacedWithController.text.trim(),
        'TrainReplacedWithTime': occReplacedTime.value != null
            ? DateFormat('HH:mm').format(occReplacedTime.value!)
            : null,
        'FailureCategoryTypeId':
        _occId(occFailureCategoryList, selectedFailureCategoryType.value),
        'FailureCategoryTypeText': occIsCategoryOther
            ? occCategoryOtherController.text.trim()
            : '',
      };

      debugPrint('submitOccUpdate($kind): payload $body, files=${files.length}');
      final result = await _failureService.createOccFailure(body, files: files);

      if (Get.isRegistered<FailureListController>(tag: 'OCC')) {
        Future.microtask(() async {
          try {
            await Get.find<FailureListController>(tag: 'OCC').fetchFailures();
          } catch (e) {
            debugPrint('submitOccUpdate: list refresh failed: $e');
          }
        });
      }

      EasyLoading.dismiss();
      Get.back(result: true);
      final no = notificationCode.value;
      showResultPopup(
        message: kind == 'assign'
            ? 'Failure No. $no updated successfully.'
            '${(result != null && result.isNotEmpty) ? '\nDepartment Failure No $result created successfully.' : ''}'
            : kind == 'close'
            ? 'Failure No. $no updated and closed successfully.'
            : kind == 'update'
            ? 'Failure No. $no updated successfully.'
            : 'Failure No. $no saved as draft.',
      );
      return true;
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('submitOccUpdate error: $e');
      Get.snackbar(
        AppStrings.error,
        'Could not save OCC failure. Please check your connection and try again.',
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
