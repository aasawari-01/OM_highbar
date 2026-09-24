import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/label_value.dart';
import '../../../core/controller/session_controller.dart';
import '../model/joint_inspection_history.dart';
import '../model/failure_detail_response.dart';

mixin FailureFormState on GetxController {
  final isLoading = false.obs;
  int _loadingRefCount = 0;

  void pushLoading() {
    _loadingRefCount++;
    isLoading.value = true;
  }

  void popLoading() {
    _loadingRefCount = (_loadingRefCount - 1).clamp(0, 1 << 30);
    if (_loadingRefCount == 0) isLoading.value = false;
  }

  final isFaultLoading = false.obs;
  final isEquipmentLoading = false.obs;
  final isFunctionalLocationLoading = false.obs;
  final isUsersLoaded = false.obs;
  final isFunctionalLocationsLoaded = false.obs;
  final isUserListLoading = false.obs;
  final showMeasurementButton = false.obs;
  final errorMessage = "".obs;
  final encryptedId = "".obs;
  final notificationId = 0.obs;
  final jointInspectionFailureNo = "".obs;
  final notificationCode = "".obs;

  // Backs the read-only "Observation Detail" panel shown when the form is
  // opened from an Inspection "Not Okay" flow (via QR / nav arguments).
  final inspectionObservation = <String, dynamic>{}.obs;

  // Dropdown lists
  final notificationTypeList = <LabelValue>[].obs;
  final natureOfWorkList = <LabelValue>[].obs;
  final departmentList = <LabelValue>[].obs;
  final userList = <LabelValue>[].obs;
  final functionalLocationList = <LabelValue>[].obs;
  final equipmentList = <LabelValue>[].obs;
  final objectDataList = <LabelValue>[].obs;
  final materialDataList = <LabelValue>[].obs;
  final userStatusList = <LabelValue>[].obs;
  final locationTypeList = <LabelValue>[].obs;
  final storageLocationList = <LabelValue>[].obs;
  final reasonForDelayList = <LabelValue>[].obs;
  final priorityTypeList = <LabelValue>[].obs;
  final faultTypeList = <LabelValue>[].obs;
  final rootCauseList = <LabelValue>[].obs;
  final actionTakenList = <LabelValue>[].obs;
  final causeList = <LabelValue>[].obs;
  final actionList = <LabelValue>[].obs;
  final corrNotificationTypeList = <LabelValue>[].obs;
  final jointUserList = <LabelValue>[].obs;
  final masterJointInspectionDepartments = <LabelValue>[].obs;

  // NEW: JE View dropdowns from asset DB
  final corrFailureTypeList = <LabelValue>[].obs;
  final userStatusJeList = <LabelValue>[].obs;
  final materialMasterList = <LabelValue>[].obs;

  // NEW: RST View dropdowns from asset DB
  final rstFaultMasterList = <LabelValue>[].obs;
  final rstOldRootCauseList = <LabelValue>[].obs;
  final rstStoreLocationList = <LabelValue>[].obs;

  // FMECA fields for Section Incharge
  final fmecaSystemList = <LabelValue>[].obs;
  final fmecaSubsystemList = <LabelValue>[].obs;
  final selectedFmecaSystem = RxnString();
  final selectedFmecaSubsystem = RxnString();
  final fmecaFrequency = RxnInt();
  final fmecaSystemReadOnly = false.obs;
  final fmecaSubsystemReadOnly = false.obs;

  // Form selections
  final selectedPriority = RxnString();
  final selectedDepartment = RxnString();
  final selectedLocation = RxnString();
  final selectedFunctionalLocation = RxnString();
  final selectedEquipmentNumber = RxnString();
  final selectedPersonResponsible = RxnString();
  final selectedNotificationType = RxnString();
  final selectedObjectPart = RxnString();
  final selectedFault = RxnString();
  final mainStatusName = RxnString();
  final selectedUserStatus = RxnString();
  final selectedActualFailureRectified = RxnString();
  final selectedNatureOfWork = RxnString();
  final selectedFailureCategoryType = RxnString();
  final selectedFailureReportedBy = RxnString();
  final selectedCause = RxnString();
  final selectedAction = RxnString();
  final selectedRcaFailureCategory = RxnString();
  final rcaFailureCategoryList = <LabelValue>[].obs;
  final masterRcaFailureCategories = <Map<String, dynamic>>[].obs;
  final masterRootCauses = <Map<String, dynamic>>[].obs;
  final masterCauseOfFailures = <Map<String, dynamic>>[].obs;

  // RCA popup selections
  final selectedPopupCause = RxnString();
  final selectedPopupAction = RxnString();
  final popupRootCauseList = <LabelValue>[].obs;

  final selectedJointDept = RxnString();
  final selectedJointAssignTo = RxnString();
  final jiDepartment = RxnString();
  final jiEquipmentNumber = RxnString();
  final selectedJiFunctionalLocation = RxnString();
  final selectedJiEquipmentNumber = RxnString();
  final jiAssignTo = RxnString();
  final jiRemark = RxnString();
  final jiFunctionalLocation = RxnString();
  final jiEquipmentId = RxnInt();
  final jiFunctionalLocationId = RxnString();

  final selectedMaterialType = RxnString();
  final materialTypeList = ["Software", "Hardware", "Communication", "Other"];

  final failureCategory = "Maintenance".obs;

  final originalLocationId = RxnInt();
  final originalDepartmentId = RxnInt();
  final originalFailureId = RxnInt();

  // Booleans
  final isBasicInfoVisible = true.obs;
  final isTripAffected = false.obs;
  final isServiceAffected = false.obs;
  final isPassengerDeboarding = false.obs;
  final isPowerBlockRequired = false.obs;
  final isOheRequired = false.obs;
  final isSicRequired = false.obs;
  final isPassengerAffected = false.obs;
  final isPtwRequired = false.obs;
  final isRcaRequired = true.obs;
  final isSparePartReplaced = false.obs;
  final isMaterialDismantle = false.obs;
  final isJointInspection = false.obs;
  final isFromJointInspection = false.obs;
  final isJointUserLoading = false.obs;

  // TextEditingControllers
  final failureDescriptionController = TextEditingController();
  final priorityDisplayController = TextEditingController();
  final departmentDisplayController = TextEditingController();
  final locationDisplayController = TextEditingController();
  final functionalLocationDisplayController = TextEditingController();
  final equipmentDisplayController = TextEditingController();
  final personResponsibleDisplayController = TextEditingController();
  final jiDepartmentDisplayController = TextEditingController();
  final jiAssignToDisplayController = TextEditingController();
  final jiRemarkDisplayController = TextEditingController();
  final ptwNumberController = TextEditingController();
  final systemController = TextEditingController();
  final subsystemController = TextEditingController();
  final fmecaSystemController = TextEditingController();
  final fmecaSubsystemController = TextEditingController();
  final fmecaFrequencyController = TextEditingController();
  final trainIdController = TextEditingController();
  final tripDelayUplineController = TextEditingController();
  final tripDelayDownlineController = TextEditingController();
  final passengersAffectedCountController = TextEditingController();
  final numberOfPassengerAffectedController = TextEditingController();
  final trappedDurationController = TextEditingController();
  final rescuedDurationController = TextEditingController();
  final objectPartTextController = TextEditingController();
  final faultTextController = TextEditingController();
  final subLocationController = TextEditingController();
  final natureOfWorkController = TextEditingController();
  final failureTypeController = TextEditingController();
  final trainRunningKmController = TextEditingController();
  final failureRectificationDetailsController = TextEditingController();
  final popupRootCauseTextController = TextEditingController();
  final popupActionTakenTextController = TextEditingController();
  final popupCauseTextController = TextEditingController();
  final popupActionTextController = TextEditingController();
  final trainDelayMinController = TextEditingController();
  final trainDelayNosController = TextEditingController();
  final trainCancelNosController = TextEditingController();
  final trainWithdrawalNosController = TextEditingController();
  final trainReplaceNosController = TextEditingController();
  final trainDeboardedNosController = TextEditingController();
  final uomController = TextEditingController();
  final balanceQtyController = TextEditingController();
  final requiredQtyController = TextEditingController();
  final oldSerialNumberController = TextEditingController();
  final newSerialNumberController = TextEditingController();
  final jointInspectionRemarkController = TextEditingController();
  final jiUserRemarkController = TextEditingController();

  final failureRectificationFocusNode = FocusNode();
  final requiredQtyFocusNode = FocusNode();

  // Dates
  final selectedUnderObservationDate = Rxn<DateTime>();
  final selectedFailureOccurrenceDate = Rxn<DateTime>();
  final selectedFailureAttendedDate = Rxn<DateTime>();
  final selectedActualFailureRectifiedDate = Rxn<DateTime>();
  final selectedFailureCompletedDate = Rxn<DateTime>();
  final oldSerialDismantleDate = Rxn<DateTime>();
  final newSerialInstallationDate = Rxn<DateTime>();

  // Attachments
  final beforeFiles = <Map<String, dynamic>>[].obs;
  final afterFiles = <Map<String, dynamic>>[].obs;
  final rcaFiles = <Map<String, dynamic>>[].obs;
  final beforeImagesList = <Map<String, dynamic>>[].obs;
  final afterImagesList = <Map<String, dynamic>>[].obs;
  final rcaImagesList = <Map<String, dynamic>>[].obs;

  // Lists
  final notificationHistoryList = <NotificationActionHistory>[].obs;
  final notificationDescriptionHistoryList = <NotificationHistory>[].obs;
  final jointInspectionHistoryList = <JointInspectionHistory>[].obs;

  // Inline "history at this Functional Location" (from getFunctionEqDetailsById
  // response's functionalHistory / functionalHistoryPrev). Distinct from the
  // standalone MaintenanceHistoryScreen, which is a separate asset-level browser.
  final maintenanceHistoryList = <Map<String, dynamic>>[].obs;
  final maintenanceHistoryListPrev = <Map<String, dynamic>>[].obs;
  final selectedHistoryTab = 'current'.obs;

  // Master data lists
  final masterLocations = <Map<String, dynamic>>[].obs;
  final masterFunctionalLocations = <Map<String, dynamic>>[].obs;
  final masterEquipments = <Map<String, dynamic>>[].obs;
  final masterDepartments = <Map<String, dynamic>>[].obs;
  final masterUsers = <Map<String, dynamic>>[].obs;

  // Popup state
  final selectedPopupRootCause = RxnString();
  final selectedPopupActionTaken = RxnString();
  final popupRootCauseFiles = <Map<String, dynamic>>[].obs;
  final popupActionTakenFiles = <Map<String, dynamic>>[].obs;

  // Reason for delay
  final showReasonForDelayPopup = false.obs;
  final selectedReasonForDelay = RxnString();
  final reasonForDelayId = 0.obs;

  @override
  void onClose() {
    super.onClose();
    failureDescriptionController.dispose();
    priorityDisplayController.dispose();
    departmentDisplayController.dispose();
    locationDisplayController.dispose();
    functionalLocationDisplayController.dispose();
    equipmentDisplayController.dispose();
    personResponsibleDisplayController.dispose();
    jiDepartmentDisplayController.dispose();
    jiAssignToDisplayController.dispose();
    jiRemarkDisplayController.dispose();
    systemController.dispose();
    subsystemController.dispose();
    fmecaSystemController.dispose();
    fmecaSubsystemController.dispose();
    fmecaFrequencyController.dispose();
    trainIdController.dispose();
    tripDelayUplineController.dispose();
    tripDelayDownlineController.dispose();
    passengersAffectedCountController.dispose();
    numberOfPassengerAffectedController.dispose();
    trappedDurationController.dispose();
    rescuedDurationController.dispose();
    ptwNumberController.dispose();
    objectPartTextController.dispose();
    subLocationController.dispose();
    natureOfWorkController.dispose();
    failureTypeController.dispose();
    trainRunningKmController.dispose();
    trainDelayMinController.dispose();
    trainDelayNosController.dispose();
    trainCancelNosController.dispose();
    trainWithdrawalNosController.dispose();
    trainReplaceNosController.dispose();
    trainDeboardedNosController.dispose();
    faultTextController.dispose();
    popupRootCauseTextController.dispose();
    popupActionTakenTextController.dispose();
    uomController.dispose();
    balanceQtyController.dispose();
    requiredQtyController.dispose();
    oldSerialNumberController.dispose();
    newSerialNumberController.dispose();
    jointInspectionRemarkController.dispose();
    failureRectificationDetailsController.dispose();
    jiUserRemarkController.dispose();
    failureRectificationFocusNode.dispose();
    requiredQtyFocusNode.dispose();
  }

  bool get isJE =>
      Get.find<SessionController>()
          .selectedRole
          .value
          ?.roleDescr
          ?.contains("Junior Engineer") ??
          false;

  bool get isTechnician =>
      Get.find<SessionController>()
          .selectedRole
          .value
          ?.roleDescr
          ?.contains("Technician") ??
          false;

  bool get isStationController =>
      Get.find<SessionController>()
          .selectedRole
          .value
          ?.roleDescr
          ?.contains("Station Controller") ??
          false;

  bool get isSectionIncharge =>
      Get.find<SessionController>()
          .selectedRole
          .value
          ?.roleDescr
          ?.contains("Section Incharge") ??
          false;

  bool get isStation => failureCategory.value.toLowerCase() == 'station';
  bool get isMaintenance =>
      failureCategory.value.toLowerCase() == 'maintenance';
  bool get isOCC => failureCategory.value.toLowerCase() == 'occ';
  bool get isDepot => failureCategory.value.toLowerCase() == 'depot';

  bool _isPendingJointInspectionStatus(String? status) {
    return status?.trim().toLowerCase() == 'joint inspection pending';
  }

  bool get isJointInspectionPending {
    if (_isPendingJointInspectionStatus(mainStatusName.value)) return true;
    return jointInspectionHistoryList.any(
          (item) => _isPendingJointInspectionStatus(item.statusName),
    );
  }

  bool get isCloseUserStatusBlocked => isJE && isJointInspectionPending;

  bool get isJointInspectionPendingStatus =>
      _isPendingJointInspectionStatus(mainStatusName.value);

  bool get isFormDisabled => isJointInspectionPendingStatus;
}