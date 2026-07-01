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
import '../../../core/models/label_value.dart';
import '../../../service/auth_manager.dart';
import '../../../service/local_database_service.dart';
import '../../../service/master_data_sync_service.dart';
import '../../../service/session_controller.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_popup.dart';
import '../../auth_login/model/login_response.dart';
import '../model/failure_detail_response.dart';
import '../model/joint_inspection_history.dart';
import '../service/failure_service.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';

class CreateFailureController extends GetxController {
  final FailureService _failureService = FailureService();
  final ApiClient _apiClient = ApiClient();

  final isLoading = false.obs;
  // Add near isLoading declaration
  int _loadingRefCount = 0;

  void _pushLoading() {
    _loadingRefCount++;
    isLoading.value = true;
  }

  void _popLoading() {
    _loadingRefCount = (_loadingRefCount - 1).clamp(0, 1 << 30);
    if (_loadingRefCount == 0) isLoading.value = false;
  }
  final isFaultLoading = false.obs;
  final isEquipmentLoading = false.obs;
  final showMeasurementButton = false.obs;
  final errorMessage = "".obs;
  final encryptedId = "".obs;
  final notificationId = 0.obs;
  final jointInspectionFailureNo = "".obs;
  final notificationCode = "".obs;

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

  final isBasicInfoVisible = true.obs;
  final isTripAffected = false.obs;
  final isServiceAffected = false.obs;
  final isPassengerDeboarding = false.obs;
  final isPowerBlockRequired = false.obs;
  final isSicRequired = false.obs;
  final isPassengerAffected = false.obs;
  final corrNotificationTypeList = <LabelValue>[].obs;
  final isPtwRequired = false.obs;
  final isRcaRequired = true.obs;
  final isSparePartReplaced = false.obs;
  final isMaterialDismantle = false.obs;
  final isJointInspection = false.obs;

  final beforeFiles = <Map<String, dynamic>>[].obs;
  final afterFiles = <Map<String, dynamic>>[].obs;
  final rcaFiles = <Map<String, dynamic>>[].obs; // For new RCA uploads

  final beforeImagesList = <Map<String, dynamic>>[].obs;
  final afterImagesList = <Map<String, dynamic>>[].obs;
  final rcaImagesList = <Map<String, dynamic>>[].obs;

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
  final trainIdController = TextEditingController();
  final tripDelayUplineController = TextEditingController();
  final tripDelayDownlineController = TextEditingController();
  final passengersAffectedCountController = TextEditingController();
  final trappedDurationController = TextEditingController();
  final rescuedDurationController = TextEditingController();

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

  /// Shows a validation error snackbar with the first error.
  void _showErrorDialog(String message) {
    final lines = message.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;
    Get.snackbar(
      'Validation Error',
      lines.first,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void showPendingJointInspectionPopup() {
    Get.dialog(
      CustPopup(
        title: 'Joint Inspection Pending',
        message: 'Joint inspection is pending. Please close this first.',
        showIcon: true,
        icon: Icons.error_outline,
        iconColor: AppColors.darkRed,
        confirmText: 'OK',
        onConfirm: () {
          selectedUserStatus.value="Select User status";
          Get.back();
        },
      ),
      barrierDismissible: false,
    );
  }

  bool get isStationController =>
      Get.find<SessionController>()
          .selectedRole
          .value
          ?.roleDescr
          ?.contains("Station Controller") ??
      false;
  bool get isStation => failureCategory.value.toLowerCase() == 'station';
  bool get isMaintenance =>
      failureCategory.value.toLowerCase() == 'maintenance';
  bool get isOCC => failureCategory.value.toLowerCase() == 'occ';
  bool get isDepot => failureCategory.value.toLowerCase() == 'depot';
  final objectPartTextController = TextEditingController();
  final faultTextController = TextEditingController();
  final subLocationController = TextEditingController();
  final natureOfWorkController = TextEditingController();
  final failureTypeController = TextEditingController();
  final trainRunningKmController = TextEditingController();
  final failureRectificationDetailsController = TextEditingController();
  final failureRectificationFocusNode = FocusNode();
  final popupRootCauseTextController = TextEditingController();
  final popupActionTakenTextController = TextEditingController();

  final trainDelayMinController = TextEditingController();
  final trainDelayNosController = TextEditingController();
  final trainCancelNosController = TextEditingController();
  final trainWithdrawalNosController = TextEditingController();
  final trainReplaceNosController = TextEditingController();

  final trainDeboardedNosController = TextEditingController();

  final selectedMaterialCode = RxnString();
  final uomController = TextEditingController();
  final selectedStoreLocation = RxnString();
  final balanceQtyController = TextEditingController();
  final requiredQtyController = TextEditingController();
  final requiredQtyFocusNode = FocusNode();
  final replacedMaterialsList = <Map<String, dynamic>>[].obs;
  final usedQtyControllers = <int, TextEditingController>{}.obs;
  final usedQtyFocusNodes = <int, FocusNode>{}.obs;

  final selectedDismantleMaterialCode = RxnString();
  final oldSerialNumberController = TextEditingController();
  final oldSerialDismantleDate = Rxn<DateTime>();
  final newSerialNumberController = TextEditingController();
  final newSerialInstallationDate = Rxn<DateTime>();
  final dismantleMaterialsList = <Map<String, dynamic>>[].obs;

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

  final masterLocations = <Map<String, dynamic>>[].obs;
  final masterFunctionalLocations = <Map<String, dynamic>>[].obs;
  final masterEquipments = <Map<String, dynamic>>[].obs;
  final selectedPopupRootCause = RxnString();
  final selectedPopupActionTaken = RxnString();
  final popupRootCauseFiles = <Map<String, dynamic>>[].obs;
  final popupActionTakenFiles = <Map<String, dynamic>>[].obs;
  final tempPopupRootCauses = <Map<String, dynamic>>[].obs;
  final tempPopupActionTakens = <Map<String, dynamic>>[].obs;
  final isExpandedRca =
      <int, bool>{}.obs; // Track expansion state per card index
  final selectedMaterialType = RxnString();
  final materialTypeList = ["Software", "Hardware", "Communication", "Other"];
  final _originalLocationId = RxnInt();
  final _originalDepartmentId = RxnInt();
  final _originalFailureId = RxnInt();

  final selectedJointDept = RxnString();
  final selectedJointAssignTo = RxnString();
  final jointInspectionRemarkController = TextEditingController();
  final jointInspectionHistoryList = <JointInspectionHistory>[].obs;

  final jointUserList = <LabelValue>[].obs;
  final isJointUserLoading = false.obs;

  final masterJointInspectionDepartments = <LabelValue>[].obs;

  Future<void> fetchMasterJointInspectionDepartments() async {
    try {
      final depts = await _failureService.getDeptMasterData();
      masterJointInspectionDepartments.assignAll(depts);
    } catch (e) {
      debugPrint('fetchMasterJointInspectionDepartments error: $e');
    }
  }

  List<LabelValue> get jointInspectionDepartments {
    final List<LabelValue> sourceList = masterJointInspectionDepartments.isNotEmpty
        ? masterJointInspectionDepartments
        : Get.find<SessionController>()
            .departments
            .map((e) => LabelValue(
                  label: e.deptName,
                  value: e.deptId?.toString(),
                ))
            .toList();

    final currentDept = Get.find<SessionController>().selectedDepartment.value;
    if (currentDept == null) return sourceList;

    return sourceList.where((e) {
      final isSameId = e.value == currentDept.deptId?.toString();
      final isSameName = e.label?.trim().toLowerCase() ==
          currentDept.deptName?.trim().toLowerCase();
      return !isSameId && !isSameName;
    }).toList();
  }

  final selectedUnderObservationDate = Rxn<DateTime>();
  final selectedFailureOccurrenceDate = Rxn<DateTime>();
  final selectedFailureAttendedDate = Rxn<DateTime>();
  final selectedActualFailureRectifiedDate = Rxn<DateTime>();
  
  final showReasonForDelayPopup = false.obs;
  final selectedReasonForDelay = RxnString();
  final reasonForDelayId = 0.obs;

  void onFailureAttendedDateSelected(DateTime? date) {
    selectedFailureAttendedDate.value = date;
    // Reset rectified date if it's before the new attended date
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
            // if (reasonForDelayId.value == 0) {
            //   Get.snackbar(
            //     "Required",
            //     "Please select Reason For Delay",
            //     snackPosition: SnackPosition.BOTTOM,
            //     backgroundColor: AppColors.darkRed,
            //     colorText: Colors.white,
            //   );
            //   return;
            // }

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


  final selectedFailureCompletedDate = Rxn<DateTime>();

  final failureCategory = "Maintenance".obs;

  final rcaDetailsList = <Map<String, dynamic>>[].obs;
  final measurementPointsList = <Map<String, dynamic>>[].obs;

  final editingReplacedMaterialIndex = (-1).obs;
  final editingDismantleMaterialIndex = (-1).obs;
  final notificationHistoryList = <NotificationActionHistory>[].obs;
  final notificationDescriptionHistoryList = <NotificationHistory>[].obs;

  // Joint Inspection Specific
  final isFromJointInspection = false.obs;
  final jiUserRemarkController = TextEditingController();
  final jiDepartment = RxnString();
  final jiEquipmentNumber = RxnString();
  final selectedJiFunctionalLocation = RxnString();
  final selectedJiEquipmentNumber = RxnString();
  final jiAssignTo = RxnString();
  final jiRemark = RxnString();
  final jiFunctionalLocation = RxnString();
  final jiEquipmentId = RxnInt();
  final jiFunctionalLocationId = RxnString();

  @override
  void onInit() {
    super.onInit();
    _initializeAllData();
  }

  Future<void> _initializeAllData() async {
    _pushLoading();
    try {
      await Future.wait([
        fetchMasterJointInspectionDepartments(),
        _loadMasterDataFromDb(),
        _loadMasterDropdownsFromDb(refreshIfEmpty: true),
        _loadDepartments(),
      ]);
    } catch (e) {
      debugPrint("Error in _initializeAllData: $e");
    } finally {
      _popLoading();
    }
  }

  Future<void> _loadDepartments() async {
    final depts = await LocalDatabaseService().getDepartments();
    masterDepartments.assignAll(depts);
    debugPrint("Loaded ${depts.length} departments to masterDepartments");

    // Unconditionally populate departmentList from local database
    departmentList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...depts.map((e) => LabelValue(
            label: e['deptName']?.toString() ?? '',
            value: e['deptId']?.toString() ?? '',
          )),
    ]);
  }

  String? _getWorkCenterForDept(String? deptId) {
    if (deptId == null || deptId.isEmpty) return null;
    debugPrint("Searching deptId = $deptId");

    // Use cached departments
    final dept = masterDepartments.firstWhere(
          (e) => e['deptId'].toString() == deptId,
      orElse: () => <String, dynamic>{},
    );

    debugPrint("Matched Department = $dept");
    debugPrint("WorkCenter = ${dept['workCenter']}");

    return dept['workCenter']?.toString();
  }

  @override
  void onClose() {
    // Text controllers
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
    trainIdController.dispose();
    tripDelayUplineController.dispose();
    tripDelayDownlineController.dispose();
    passengersAffectedCountController.dispose();
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
    requiredQtyFocusNode.dispose();
    oldSerialNumberController.dispose();
    newSerialNumberController.dispose();
    jointInspectionRemarkController.dispose();
    failureRectificationDetailsController.dispose();
    failureRectificationFocusNode.dispose();
    super.onClose();
  }

  void addRcaDetail() {
    final objectPartId = objectDataList
        .firstWhere((e) => e.label == selectedObjectPart.value,
            orElse: () => LabelValue(value: "0"))
        .value;
    final faultId = faultTypeList
        .firstWhere((e) => e.label == selectedFault.value,
            orElse: () => LabelValue(value: "0"))
        .value;

    rcaDetailsList.add({
      'ObjectPartId': objectPartId,
      'objectPart': selectedObjectPart.value ?? "",
      'objectPartText': objectPartTextController.text,
      'FaultId': faultId,
      'fault': selectedFault.value ?? "",
      'faultText': faultTextController.text,
      'rootCauses': <Map<String, dynamic>>[],
      'actionTakens': <Map<String, dynamic>>[],
    });
    // Clear temp inputs
    selectedObjectPart.value = null;
    objectPartTextController.clear();
    selectedFault.value = null;
    faultTextController.clear();
  }

  void removeRcaDetail(Map<String, dynamic> item) {
    rcaDetailsList.remove(item);
  }

  void addRootCauseToRca(int index) {
    if (selectedPopupRootCause.value == null &&
        popupRootCauseTextController.text.trim().isEmpty) {
      _showErrorDialog('Please select or enter a Root Cause before adding.');
      return;
    }

    final List<Map<String, dynamic>> rootCauses =
        List.from(rcaDetailsList[index]['rootCauses']);
    rootCauses.add({
      'rootCause': selectedPopupRootCause.value ?? "N/A",
      'rootCauseText': popupRootCauseTextController.text,
      'imagePath': popupRootCauseFiles.isNotEmpty
          ? popupRootCauseFiles.first['path']
          : null,
    });

    rcaDetailsList[index]['rootCauses'] = rootCauses;
    rcaDetailsList.refresh();

    // Clear popup state
    selectedPopupRootCause.value = null;
    popupRootCauseTextController.clear();
    popupRootCauseFiles.clear();
  }

  void removeRootCauseFromRca(int rcaIndex, int itemIndex) {
    final List<Map<String, dynamic>> rootCauses =
        List.from(rcaDetailsList[rcaIndex]['rootCauses']);
    rootCauses.removeAt(itemIndex);
    rcaDetailsList[rcaIndex]['rootCauses'] = rootCauses;
    rcaDetailsList.refresh();
  }

  void addActionTakenToRca(int index) {
    if (selectedPopupActionTaken.value == null &&
        popupActionTakenTextController.text.trim().isEmpty) {
      _showErrorDialog('Please select or enter an Action Taken before adding.');
      return;
    }

    final List<Map<String, dynamic>> actionTakens =
        List.from(rcaDetailsList[index]['actionTakens']);
    actionTakens.add({
      'actionTaken': selectedPopupActionTaken.value ?? "N/A",
      'actionTakenText': popupActionTakenTextController.text,
      'imagePath': popupActionTakenFiles.isNotEmpty
          ? popupActionTakenFiles.first['path']
          : null,
    });

    rcaDetailsList[index]['actionTakens'] = actionTakens;
    rcaDetailsList.refresh();

    // Clear popup state
    selectedPopupActionTaken.value = null;
    popupActionTakenTextController.clear();
    popupActionTakenFiles.clear();
  }

  void removeActionTakenFromRca(int rcaIndex, int itemIndex) {
    final List<Map<String, dynamic>> actionTakens =
        List.from(rcaDetailsList[rcaIndex]['actionTakens']);
    actionTakens.removeAt(itemIndex);
    rcaDetailsList[rcaIndex]['actionTakens'] = actionTakens;
    rcaDetailsList.refresh();
  }

  void addToTempRootCauses() {
    final rootCauseId = rootCauseList
            .firstWhere((e) => e.label == selectedPopupRootCause.value,
                orElse: () => LabelValue(value: "0"))
            .value ??
        "0";
    tempPopupRootCauses.add({
      'rootCauseId': rootCauseId,
      'rootCause': selectedPopupRootCause.value ?? "N/A",
      'rootCauseText': popupRootCauseTextController.text,
      'imagePath': popupRootCauseFiles.isNotEmpty
          ? popupRootCauseFiles.first['path']
          : null,
    });
    // Clear current inputs
    selectedPopupRootCause.value = null;
    popupRootCauseTextController.clear();
    popupRootCauseFiles.clear();
  }

  void addToTempActionTakens() {
    final actionTakenId = actionTakenList
            .firstWhere((e) => e.label == selectedPopupActionTaken.value,
                orElse: () => LabelValue(value: "0"))
            .value ??
        "0";
    tempPopupActionTakens.add({
      'actionTakenId': actionTakenId,
      'actionTaken': selectedPopupActionTaken.value ?? "N/A",
      'actionTakenText': popupActionTakenTextController.text,
      'imagePath': popupActionTakenFiles.isNotEmpty
          ? popupActionTakenFiles.first['path']
          : null,
    });
    // Clear current inputs
    selectedPopupActionTaken.value = null;
    popupActionTakenTextController.clear();
    popupActionTakenFiles.clear();
  }

  void savePopupDataToRca(int index) {
    final List<Map<String, dynamic>> rootCauses =
        List.from(rcaDetailsList[index]['rootCauses']);
    final List<Map<String, dynamic>> actionTakens =
        List.from(rcaDetailsList[index]['actionTakens']);

    rootCauses.addAll(tempPopupRootCauses);
    actionTakens.addAll(tempPopupActionTakens);

    rcaDetailsList[index]['rootCauses'] = rootCauses;
    rcaDetailsList[index]['actionTakens'] = actionTakens;
    rcaDetailsList.refresh();

    clearPopupState();
  }

  void clearPopupState() {
    tempPopupRootCauses.clear();
    tempPopupActionTakens.clear();
    selectedPopupRootCause.value = null;
    selectedPopupActionTaken.value = null;
    popupRootCauseTextController.clear();
    popupActionTakenTextController.clear();
    popupRootCauseFiles.clear();
    popupActionTakenFiles.clear();
  }

  void toggleRcaExpansion(int index) {
    isExpandedRca[index] = !(isExpandedRca[index] ?? false);
  }

  final isExpandedReplaced = <int, bool>{}.obs;
  final isExpandedDismantle = <int, bool>{}.obs;

  void toggleReplacedExpansion(int index) {
    isExpandedReplaced[index] = !(isExpandedReplaced[index] ?? false);
  }

  void toggleDismantleExpansion(int index) {
    isExpandedDismantle[index] = !(isExpandedDismantle[index] ?? false);
  }

  int _materialRecordId(Map<String, dynamic> item) {
    final raw = item['id'] ??
        item['Id'] ??
        item['materialReqId'] ??
        item['MaterialReqId'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  int _resolveMaterialId(Map<String, dynamic> item) {
    final fromItem =
        item['Materialid'] ?? item['MaterialId'] ?? item['materialid'];
    if (fromItem != null) {
      if (fromItem is int) return fromItem;
      final parsed = int.tryParse(fromItem.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    final code =
        (item['MaterialName'] ?? item['materialCode'])?.toString().trim() ?? '';
    if (code.isEmpty) return 0;
    final match = materialDataList.firstWhere(
      (m) => m.label?.trim() == code,
      orElse: () => LabelValue(value: "0"),
    );
    return int.tryParse(match.value ?? '0') ?? 0;
  }

  int _resolveStorageLocationId(Map<String, dynamic> item) {
    final fromItem = item['StorageLocation'] ?? item['storageLocation'];
    if (fromItem is int && fromItem > 0) return fromItem;
    final parsed = int.tryParse(fromItem?.toString() ?? '');
    if (parsed != null && parsed > 0) return parsed;
    final label = (item['storeLocation'] ?? item['storageLocationValue'])
            ?.toString()
            .trim() ??
        '';
    if (label.isEmpty) return 0;
    final match = storageLocationList.firstWhere(
      (s) => s.label?.trim() == label,
      orElse: () => LabelValue(value: "0"),
    );
    return int.tryParse(match.value ?? '0') ?? 0;
  }

  List<Map<String, dynamic>> _materialsForSubmit() {
    final seenIds = <int>{};
    final result = <Map<String, dynamic>>[];
    for (final item in replacedMaterialsList) {
      final code = item['materialCode']?.toString().trim() ?? '';
      if (code.isEmpty) continue;
      final recordId = _materialRecordId(item);
      if (recordId > 0) {
        if (seenIds.contains(recordId)) continue;
        seenIds.add(recordId);
      }
      result.add(item);
    }
    return result;
  }

  Map<String, dynamic> _buildMaterialPayload(Map<String, dynamic> e) {
    final recordId = _materialRecordId(e);
    final isExisting = recordId > 0;
    final statusId = isExisting ? 2 : 1;
    return {
      "Materialid": _resolveMaterialId(e),
      "MaterialValue": e['MaterialName'] ?? e['materialCode'] ?? "",
      "Quantity": int.tryParse(e['requiredQty']?.toString() ??
              e['Quantity']?.toString() ??
              "0") ??
          0,
      "UnitMeasurement": e['uom'] ?? e['UnitMeasurement'] ?? "",
      "IssuedQty": int.tryParse(e['issuedQty']?.toString() ?? "0") ?? 0,
      "UsedQty": int.tryParse(
              e['usedQty']?.toString() ?? e['UsedQty']?.toString() ?? "0") ??
          0,
      "BalanceQty": int.tryParse(e['balanceQty']?.toString() ??
              e['BalanceQty']?.toString() ??
              "0") ??
          0,
      "RemainingBalanceQTY": e['RemainingBalanceQTY'] ?? 0,
      "StorageLocation": _resolveStorageLocationId(e),
      "InsertUpdateStatusId": statusId,
      "CurrentInsertUpdateStatusId": statusId,
      "Id": recordId,
    };
  }

  void addReplacedMaterial() {
    if (selectedMaterialCode.value != null) {
      if (editingReplacedMaterialIndex.value >= 0) {
        final existing =
            replacedMaterialsList[editingReplacedMaterialIndex.value];
        existing['materialCode'] = selectedMaterialCode.value;
        existing['uom'] = uomController.text;
        existing['storeLocation'] = selectedStoreLocation.value;
        existing['balanceQty'] = balanceQtyController.text;
        existing['requiredQty'] = requiredQtyController.text;
        replacedMaterialsList.refresh();
        editingReplacedMaterialIndex.value = -1;
      } else {
        final newIndex = replacedMaterialsList.length;
        replacedMaterialsList.add({
          'materialCode': selectedMaterialCode.value,
          'uom': uomController.text,
          'storeLocation': selectedStoreLocation.value,
          'balanceQty': balanceQtyController.text,
          'requiredQty': requiredQtyController.text,
          'issuedQty': "0",
          'usedQty': "",
        });
        // Auto-expand the newly added item
        isExpandedReplaced[newIndex] = true;
      }

      // Clear inputs
      selectedMaterialCode.value = null;
      uomController.clear();
      selectedStoreLocation.value = null;
      balanceQtyController.clear();
      requiredQtyController.clear();
    }
  }

  void editReplacedMaterial(int index) {
    final item = replacedMaterialsList[index];
    selectedMaterialCode.value = item['materialCode'];
    uomController.text = item['uom'] ?? "";
    selectedStoreLocation.value = item['storeLocation'];
    balanceQtyController.text = item['balanceQty']?.toString() ?? "";
    requiredQtyController.text = item['requiredQty']?.toString() ?? "";
    editingReplacedMaterialIndex.value = index;
  }

  void removeReplacedMaterial(int index) {
    replacedMaterialsList.removeAt(index);
    isExpandedReplaced.remove(index);
    // Dispose and remove the controller and focus node for this index
    usedQtyControllers[index]?.dispose();
    usedQtyControllers.remove(index);
    usedQtyFocusNodes[index]?.dispose();
    usedQtyFocusNodes.remove(index);
    // Rebuild controllers for remaining items
    _rebuildUsedQtyControllers();
    if (editingReplacedMaterialIndex.value == index) {
      editingReplacedMaterialIndex.value = -1;
      selectedMaterialCode.value = null;
      uomController.clear();
      selectedStoreLocation.value = null;
      balanceQtyController.clear();
      requiredQtyController.clear();
    }
  }

  void _rebuildUsedQtyControllers() {
    // Clear existing controllers and focus nodes
    for (final controller in usedQtyControllers.values) {
      controller.dispose();
    }
    for (final focusNode in usedQtyFocusNodes.values) {
      focusNode.dispose();
    }
    usedQtyControllers.clear();
    usedQtyFocusNodes.clear();
    // Rebuild controllers for current list
    for (int i = 0; i < replacedMaterialsList.length; i++) {
      usedQtyControllers[i] = TextEditingController(text: replacedMaterialsList[i]['usedQty']?.toString() ?? '');
      usedQtyFocusNodes[i] = FocusNode();
    }
  }

  void addDismantleMaterial() {
    if (selectedDismantleMaterialCode.value != null) {
      if (editingDismantleMaterialIndex.value >= 0) {
        final existing =
            dismantleMaterialsList[editingDismantleMaterialIndex.value];
        existing['materialCode'] = selectedDismantleMaterialCode.value;
        existing['oldSerialNo'] = oldSerialNumberController.text;
        existing['dismantleDate'] = oldSerialDismantleDate.value;
        existing['newSerialNo'] = newSerialNumberController.text;
        existing['installationDate'] = newSerialInstallationDate.value;
        dismantleMaterialsList.refresh();
        editingDismantleMaterialIndex.value = -1;
      } else {
        dismantleMaterialsList.add({
          'materialCode': selectedDismantleMaterialCode.value,
          'oldSerialNo': oldSerialNumberController.text,
          'dismantleDate': oldSerialDismantleDate.value,
          'newSerialNo': newSerialNumberController.text,
          'installationDate': newSerialInstallationDate.value,
        });
      }

      // Clear inputs
      selectedDismantleMaterialCode.value = null;
      oldSerialNumberController.clear();
      oldSerialDismantleDate.value = null;
      newSerialNumberController.clear();
      newSerialInstallationDate.value = null;
    }
  }

  void editDismantleMaterial(int index) {
    final item = dismantleMaterialsList[index];
    selectedDismantleMaterialCode.value = item['materialCode'];
    oldSerialNumberController.text = item['oldSerialNo'] ?? "";
    oldSerialDismantleDate.value = item[
        'dismantleDate']; // Note: if coming from API, it might be in dismantleDateRaw. We should parse it if needed, or leave it for the user to reselect.
    newSerialNumberController.text = item['newSerialNo'] ?? "";
    newSerialInstallationDate.value = item['installationDate'];
    editingDismantleMaterialIndex.value = index;
  }

  void removeDismantleMaterial(int index) {
    dismantleMaterialsList.removeAt(index);
    if (editingDismantleMaterialIndex.value == index) {
      editingDismantleMaterialIndex.value = -1;
      selectedDismantleMaterialCode.value = null;
      oldSerialNumberController.clear();
      oldSerialDismantleDate.value = null;
      newSerialNumberController.clear();
      newSerialInstallationDate.value = null;
    }
  }

  final editingJointInspectionIndex = (-1).obs;

  int _resolveNotificationId() {
    if (notificationId.value > 0) return notificationId.value;
    return int.tryParse(encryptedId.value) ?? 0;
  }

  void _parseJointInspectionHistoryFromResponse(dynamic historyJson) {
    if (historyJson is List && historyJson.isNotEmpty) {
      _updateJointInspectionList(historyJson);
    }
  }

  List<Map<String, dynamic>> _jointInspectionHistoryForSubmit() {
    final notifId = _resolveNotificationId();
    return jointInspectionHistoryList
        .map((item) => {
              "JIId": item.jiId ?? 0,
              "Remark": item.remark ?? "",
              "AssignedTo": item.assignedTo?.toString() ?? "0",
              "DeptId": item.deptId?.toString() ?? "0",
              "NotificationId": notifId,
              "CreatedBy": item.createdBy ?? 0,
              "Type": item.type ?? "AddNewJointInspection",
              "CreatedByName": item.createdByName ?? "",
            })
        .toList();
  }

  Future<void> fetchJointInspectionHistory() async {
    final notifId = _resolveNotificationId();
    if (notifId <= 0) return;
    try {
      final list = await _failureService.getJIHistory(notifId);
      jointInspectionHistoryList.assignAll(list);
    } catch (e) {
      debugPrint('fetchJointInspectionHistory error: $e');
    }
  }

  void editJointInspection(int index) {
    editingJointInspectionIndex.value = index;
    final item = jointInspectionHistoryList[index];
    selectedJointDept.value = item.deptName;
    final deptId = item.deptId;
    if (deptId != null && deptId.toString().isNotEmpty) {
      fetchJointInspectionUsers(deptId.toString()).then((_) {
        // Try to match exact label
        final matched = jointUserList.firstWhere(
            (e) =>
                e.label == item.assignedUserName ||
                e.value == item.assignedTo?.toString(),
            orElse: () => LabelValue(label: null));
        selectedJointAssignTo.value = matched.label;
      });
    } else {
      selectedJointAssignTo.value = item.assignedUserName;
    }
    jointInspectionRemarkController.text = item.remark ?? '';
  }

  Future<void> addJointInspectionHistory() async {
    // Validation
    final dept = jointInspectionDepartments.firstWhere(
      (e) => e.label == selectedJointDept.value,
      orElse: () => LabelValue(value: '0'),
    );
    final alreadyExists = jointInspectionHistoryList.any((item) =>
        item.deptName == selectedJointDept.value ||
        item.deptId?.toString() == dept.value);
    if (alreadyExists) {
      _showErrorDialog(
          'Department ${selectedJointDept.value} is already in inspection');
      return;
    }
    final notifId = _resolveNotificationId();
    if (notifId <= 0) {
      _showErrorDialog(AppStrings.notificationIdUnresolvable);
      return;
    }
    try {
      EasyLoading.show(status: AppStrings.adding);
      final userIdStr = await AuthManager().getUserId();
      final userId = int.tryParse(userIdStr ?? '0') ?? 0;
      final userName = Get.find<SessionController>().userName.value.isNotEmpty
          ? Get.find<SessionController>().userName.value
          : 'User';
      final assignTo = jointUserList.firstWhere(
        (e) => e.label == selectedJointAssignTo.value,
        orElse: () => LabelValue(value: '0'),
      );
      final body = {
        'JIId': 0,
        'Remark': jointInspectionRemarkController.text,
        'AssignedTo': assignTo.value ?? '0',
        'DeptId': dept.value ?? '0',
        'CreatedBy': userId,
        'Type': 'AddNewJointInspection',
        'NotificationId': notifId,
        'CreatedByName': userName,
      };
      final updated = await _failureService.addJIEntry(body);
      EasyLoading.dismiss();
      jointInspectionHistoryList.assignAll(updated);
      _clearJointInspectionInputs();
      Get.snackbar(AppStrings.success, AppStrings.jiAdded,
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(AppStrings.error, 'An error occurred: $e');
    }
  }

  Future<void> updateJointInspectionHistory() async {
    if (editingJointInspectionIndex.value < 0) return;
    try {
      EasyLoading.show(status: AppStrings.updating);
      final userIdStr = await AuthManager().getUserId();
      final userId = int.tryParse(userIdStr ?? '0') ?? 0;
      final userName = Get.find<SessionController>().userName.value.isNotEmpty
          ? Get.find<SessionController>().userName.value
          : 'User';
      final dept = jointInspectionDepartments.firstWhere(
        (e) => e.label == selectedJointDept.value,
        orElse: () => LabelValue(value: '0'),
      );
      final assignTo = jointUserList.firstWhere(
        (e) => e.label == selectedJointAssignTo.value,
        orElse: () => LabelValue(value: '0'),
      );
      final notifId = _resolveNotificationId();
      final jiId =
          jointInspectionHistoryList[editingJointInspectionIndex.value].jiId ?? 0;
      final body = {
        'JIId': jiId,
        'Remark': jointInspectionRemarkController.text,
        'AssignedTo': assignTo.value ?? '0',
        'DeptId': dept.value ?? '0',
        'CreatedBy': userId,
        'Type': 'UpdateJointInspection',
        'NotificationId': notifId,
        'CreatedByName': userName,
      };
      final updated = await _failureService.updateJIEntry(body);
      EasyLoading.dismiss();
      jointInspectionHistoryList.assignAll(updated);
      _clearJointInspectionInputs();
      Get.snackbar(AppStrings.success, AppStrings.jiUpdated,
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(AppStrings.error, 'An error occurred: $e');
    }
  }

  void _clearJointInspectionInputs() {
    editingJointInspectionIndex.value = -1;
    selectedJointDept.value = null;
    selectedJointAssignTo.value = null;
    jointInspectionRemarkController.clear();
    jointUserList.clear();
  }

  void _updateJointInspectionList(List<dynamic> output) {
    jointInspectionHistoryList.assignAll(
      output.map((e) => JointInspectionHistory.fromJson(e as Map<String, dynamic>)).toList()
    );
  }

  String? _labelForValue(List<LabelValue> list, dynamic value) {
    final valueText = value?.toString().trim();
    if (valueText == null || valueText.isEmpty || valueText == "0") {
      return null;
    }
    final matched = list.firstWhere(
      (e) => e.value?.toString().trim() == valueText,
      orElse: () => LabelValue(label: null),
    );
    return matched.label?.toString().trim().isNotEmpty == true
        ? matched.label
        : valueText;
  }

  String? _textOrNull(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String _mapFailureTypeIdToMaterialType(int? failureTypeId) {
    // Map failureTypeId to material type string
    // Adjust these mappings based on your actual API values
    switch (failureTypeId) {
      case 1:
        return "Software";
      case 2:
        return "Hardware";
      case 3:
        return "Communication";
      case 4:
        return "Other";
      default:
        return "Other"; // Default fallback
    }
  }

  Future<void> removeJointInspectionHistory(int index) async {
    try {
      EasyLoading.show(status: AppStrings.deleting);
      final notifId = _resolveNotificationId();
      final jiId = jointInspectionHistoryList[index].jiId ?? 0;
      final updated = await _failureService.deleteJIEntry(jiId, notifId);
      EasyLoading.dismiss();
      if (updated != null) {
        jointInspectionHistoryList.assignAll(updated);
      } else {
        jointInspectionHistoryList.removeAt(index);
      }
      if (editingJointInspectionIndex.value == index) {
        _clearJointInspectionInputs();
      }
      Get.snackbar(AppStrings.success, AppStrings.jiDeleted,
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(AppStrings.error, 'An error occurred: $e');
    }
  }

  final popupStationList = <LabelValue>[].obs;
  final isPopupStationLoading = false.obs;
  final session = Get.find<SessionController>();


  Future<void> fetchAndShowStationPopup() async {
    isPopupStationLoading.value = true;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
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
                  color: AppColors.textColor4,
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
                    const Text("Fetching stations...", style: TextStyle(color: AppColors.textColor3)),
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
                      child: const Icon(TablerIcons.x, color: AppColors.textColor, size: 24),
                    ),
                  ),
                  CustText(name: "Select Station", size: AppConstants.HeaderSize, color: AppColors.textColor7, fontWeightName: FontWeight.w600),
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
                              Get.snackbar("Error", "Please select a station",
                                backgroundColor: Colors.red.withOpacity(0.9),
                                colorText: Colors.white,
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

      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;

      final apiClient = ApiClient();
      final response = await apiClient.get(
        '${AppUrls.getJointInspectionJEScreenDetails}?notificationID=$failureNo&userId=$userId',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final responseOutput = jsonBody['responseOutput'];

        debugPrint("GetJointInspectionJEScreenDetails responseCode: ${jsonBody['responseCode']}");
        debugPrint("GetJointInspectionJEScreenDetails responseOutput keys: ${responseOutput?.keys.toList()}");

        if (jsonBody['responseCode'] == 200 && responseOutput != null) {
          // Populate dropdown lists from top-level arrays
          final List<dynamic>? deptListJson =
              responseOutput['department'] as List?;
          if (deptListJson != null) {
            departmentList.assignAll(deptListJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .toList());
            debugPrint("JI departmentList populated with ${departmentList.length} items");
            debugPrint("JI departmentList first 3: ${departmentList.take(3).toList()}");
          }
          final List<dynamic>? userListJson =
              responseOutput['personResponsible'] as List?;
          if (userListJson != null) {
            userList.assignAll(userListJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .toList());
            debugPrint("JI userList populated with ${userList.length} items");
            debugPrint("JI userList first 3: ${userList.take(3).toList()}");
          }
          final List<dynamic>? funcLocJson =
              responseOutput['functionalLocation'] as List?;
          if (funcLocJson != null) {
            final filtered = funcLocJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .where((e) => e.label?.toLowerCase() != 'select')
                .map((e) => LabelValue(label: e.label ?? '', value: e.value ?? ''))
                .toList();
            functionalLocationList.assignAll(filtered);
            debugPrint("JI functionalLocationList populated with ${functionalLocationList.length} items");
          }
          final List<dynamic>? equipJson = responseOutput['equipment'] as List?;
          if (equipJson != null) {
            final filtered = equipJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .where((e) => e.label?.toLowerCase() != 'select')
                .map((e) => LabelValue(label: e.label ?? '', value: e.value ?? ''))
                .toList();
            equipmentList.assignAll(filtered);
            debugPrint("JI equipmentList populated with ${equipmentList.length} items");
          }
          final List<dynamic>? objPartJson =
              responseOutput['objectPart'] as List?;
          if (objPartJson != null) {
            objectDataList.assignAll(objPartJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .toList());
          }
          final List<dynamic>? matCodeJson =
              responseOutput['materialCode'] as List?;
          if (matCodeJson != null) {
            materialDataList.assignAll(matCodeJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .toList());
          }
          final List<dynamic>? statusJson = responseOutput['status'] as List?;
          if (statusJson != null) {
            userStatusList.assignAll((statusJson
                    .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                    .toList())
                .where((status) {
              final val = int.tryParse(status.value ?? "999") ?? 999;
              return val == 0 || val <= 29;
            }).toList());
          }

          // Parse notification history
          final List<dynamic>? historyJson =
              responseOutput['notificationHistory'] as List?;
          if (historyJson != null) {
            notificationDescriptionHistoryList.assignAll(historyJson
                .map((e) => NotificationHistory.fromJson(
                    e as Map<String, dynamic>))
                .toList());
          }

          // Parse notification action history (for Action By dialog)
          final List<dynamic>? actionHistoryJson =
              responseOutput['notificationActionHistory'] as List? ??
              responseOutput['getNotificationActionUserHistory'] as List?;
          if (actionHistoryJson != null) {
            notificationHistoryList.assignAll(actionHistoryJson
                .map((e) => NotificationActionHistory.fromJson(
                    e as Map<String, dynamic>))
                .toList());
            debugPrint("JI notificationHistoryList populated with ${notificationHistoryList.length} items");
          }

          final Map<String, dynamic>? je = responseOutput['jeScreenDetails'];
          debugPrint("GetJointInspectionJEScreenDetails jeScreenDetails: $je");
          if (je == null) {
            debugPrint("ERROR: jeScreenDetails is null in API response");
            errorMessage.value = "jeScreenDetails is null in API response";
          } else {
            debugPrint("jeScreenDetails keys: ${je.keys.toList()}");
            debugPrint("jeScreenDetails deptId_JI: ${je['deptId_JI']}");
            debugPrint("jeScreenDetails assignedUserId_JI: ${je['assignedUserId_JI']}");
            debugPrint("jeScreenDetails functionLocation_JI: ${je['functionLocation_JI']}");
            debugPrint("jeScreenDetails equipmentId_JI: ${je['equipmentId_JI']}");
          }
          if (je != null) {
            final detailFailureNo = je['Id']?.toString().trim();
            final detailNotificationId =
                je['notificationId']?.toString().trim();
            notificationId.value =
                int.tryParse(detailNotificationId ?? "") ?? 0;
            jointInspectionFailureNo.value =
                je['failureNo']?.toString().trim().isNotEmpty == true
                    ? je['failureNo'].toString().trim()
                    : detailFailureNo?.isNotEmpty == true
                        ? detailFailureNo!
                        : detailNotificationId?.isNotEmpty == true
                            ? detailNotificationId!
                            : "";
            notificationCode.value = je['notificationCode'] ?? "";
            mainStatusName.value = je['status'];
            selectedPriority.value = je['priorityType'];
            priorityDisplayController.text = je['priorityType']?.toString() ?? "";
            failureDescriptionController.text = je['failureDescriptions'] ?? "";

            selectedDepartment.value = departmentList
                .firstWhere((e) => e.value == je['deptId']?.toString(),
                    orElse: () => LabelValue(label: ""))
                .label;
            departmentDisplayController.text =
                selectedDepartment.value ?? je['deptId']?.toString() ?? "";

            selectedLocation.value = je['locationTypeName']?.toString();
            // Use functionalLocationName (full display name) from API response
            final funcLocName = (_textOrNull(je['functionalLocationName']) ??
                    _labelForValue(functionalLocationList, je['functionLocationId']));
            selectedFunctionalLocation.value = funcLocName;
            // Use equipmentName from API response
            final equipName = (_textOrNull(je['equipmentName']) ??
                    _labelForValue(equipmentList, je['equipmentId']));
            selectedEquipmentNumber.value = equipName;
            locationDisplayController.text = selectedLocation.value ?? "";
            functionalLocationDisplayController.text =
                selectedFunctionalLocation.value ?? "";
            equipmentDisplayController.text = selectedEquipmentNumber.value ?? "";

            debugPrint('Joint Inspection: actualFailureOccuranceOn from API = ${je['actualFailureOccuranceOn']}');
            selectedFailureOccurrenceDate.value =
                je['actualFailureOccuranceOn'] != null
                    ? _parseDate(je['actualFailureOccuranceOn']!)
                    : null;
            debugPrint('Joint Inspection: selectedFailureOccurrenceDate = ${selectedFailureOccurrenceDate.value}');

            selectedPersonResponsible.value =
                _labelForValue(userList, je['personResponsible']);
            // Fallback: if not found in userList, show raw ID value
            personResponsibleDisplayController.text =
                selectedPersonResponsible.value ??
                je['personResponsible']?.toString() ??
                "";

            isPtwRequired.value = je['isPTWReq'] ?? false;
            if (isPtwRequired.value) {
              ptwNumberController.text = je['ptwNo'] ?? "";
            }

            selectedFailureAttendedDate.value = je['failureAttendedOn'] != null
                ? _parseDate(je['failureAttendedOn']!)
                : null;
            selectedActualFailureRectifiedDate.value =
                je['actualFailureRectifiedOn'] != null
                    ? _parseDate(je['actualFailureRectifiedOn']!)
                    : null;

            isServiceAffected.value = je['isServiceAffected'] ?? false;
            if (isServiceAffected.value) {
              trainDelayMinController.text =
                  je['trainDelayInMin']?.toString() ?? "0";
              trainDelayNosController.text =
                  je['trainDelayInNo']?.toString() ?? "0";
              trainCancelNosController.text =
                  je['noOfTranCancel']?.toString() ?? "0";
              trainWithdrawalNosController.text =
                  je['noOfTranWithdrawal']?.toString() ?? "0";
              trainReplaceNosController.text =
                  je['noOfTrainReplace']?.toString() ?? "0";
            }

            isPassengerDeboarding.value = je['isPassengerDeboarding'] ?? false;
            if (isPassengerDeboarding.value) {
              trainDeboardedNosController.text =
                  je['noofTrainDeboarded']?.toString() ?? "0";
            }

            isJointInspection.value = je['isJointInspectionReq'] ?? false;
            isSparePartReplaced.value = je['isHardwareReplaced'] ?? false;
            isSicRequired.value = je['isSICReq'] ?? false;

            // Passenger Affected
            isPassengerAffected.value = je['isPassengerAffected'] ?? false;
            if (isPassengerAffected.value) {
              passengersAffectedCountController.text =
                  je['noOfPassengerAffected']?.toString() ?? "";
              trappedDurationController.text =
                  je['trappedDuration']?.toString() ?? "";
              rescuedDurationController.text =
                  je['rescuedDuration']?.toString() ?? "";
            }

            // JI-specific fields from jeScreenDetails
            debugPrint("JI deptId_JI: ${je['deptId_JI']}, assignedUserId_JI: ${je['assignedUserId_JI']}");
            debugPrint("JI departmentList length: ${departmentList.length}, userList length: ${userList.length}");
            jiDepartment.value = _labelForValue(departmentList, je['deptId_JI']);
            jiAssignTo.value =
                _labelForValue(userList, je['assignedUserId_JI']);
            debugPrint("JI jiDepartment.value: ${jiDepartment.value}, jiAssignTo.value: ${jiAssignTo.value}");
            // Fallback: if lookup fails, try to display raw ID or alternative field names
            if (jiDepartment.value == null || jiDepartment.value!.isEmpty) {
              jiDepartment.value = je['deptId_JI']?.toString() ?? je['DeptId_JI']?.toString() ?? je['departmentName_JI']?.toString();
              debugPrint("JI jiDepartment fallback: ${jiDepartment.value}");
            }
            if (jiAssignTo.value == null || jiAssignTo.value!.isEmpty) {
              jiAssignTo.value = je['assignedUserId_JI']?.toString() ?? je['AssignedUserId_JI']?.toString() ?? je['assignedUserName_JI']?.toString();
              debugPrint("JI jiAssignTo fallback: ${jiAssignTo.value}");
            }
            jiDepartmentDisplayController.text = jiDepartment.value ?? "";
            jiAssignToDisplayController.text = jiAssignTo.value ?? "";
            jiFunctionalLocation.value =
                _textOrNull(je['functionalLocationName_JI']) ??
                    _labelForValue(
                        functionalLocationList, je['functionLocation_JI']);
            jiRemark.value = je['remark_JI']?.toString();
            jiRemarkDisplayController.text = jiRemark.value ?? "";
            jiEquipmentId.value = je['equipmentId_JI'] is int
                ? je['equipmentId_JI']
                : int.tryParse(je['equipmentId_JI']?.toString() ?? "0");
            jiFunctionalLocationId.value =
                je['functionLocation_JI']?.toString();
            selectedJiFunctionalLocation.value = jiFunctionalLocation.value;
            jiEquipmentNumber.value =
                _labelForValue(equipmentList, je['equipmentId_JI']);
            selectedJiEquipmentNumber.value = jiEquipmentNumber.value;
          }

          // Parse RCA from failureRectificationDetails (JI uses different keys)
          final List<dynamic>? rcaJson =
              responseOutput['failureRectificationDetails'] as List?;
          if (rcaJson != null && rcaJson.isNotEmpty) {
            rcaDetailsList.clear();
            for (var fault in rcaJson) {
              final rectId = fault['RectId'];

              final List<Map<String, dynamic>> matchedRootCauses = [];
              final List<dynamic>? rootCauseJson =
                  responseOutput['failureRootCauseDetails'] as List?;
              if (rootCauseJson != null) {
                for (var rc
                    in rootCauseJson.where((r) => r['RectId'] == rectId)) {
                  matchedRootCauses.add({
                    'rootCauseId': rc['RectId']?.toString() ?? "0",
                    'rootCause': rc['RCADescs'] ?? "N/A",
                    'rootCauseText': rc['RCAText'] ?? "",
                    'imagePath': null,
                  });
                }
              }

              final List<Map<String, dynamic>> matchedActions = [];
              final List<dynamic>? actionJson =
                  responseOutput['failureActionDetails'] as List?;
              if (actionJson != null) {
                for (var ac in actionJson.where((a) => a['RectId'] == rectId)) {
                  matchedActions.add({
                    'actionTakenId': ac['RectId']?.toString() ?? "0",
                    'actionTaken': ac['ActionDescs'] ?? "N/A",
                    'actionTakenText': ac['ActionText'] ?? "",
                    'imagePath': null,
                  });
                }
              }

              rcaDetailsList.add({
                'ObjectPartId': "0",
                'objectPart': fault['ObjectPart'] ?? "",
                'objectPartText': fault['ObjectPartText'] ?? "",
                'FaultId': "0",
                'fault': fault['Fault'] ?? "",
                'faultText': fault['FaultText'] ?? "",
                'rootCauses': matchedRootCauses,
                'actionTakens': matchedActions,
              });
            }
          }

          // Parse images
          beforeImagesList.clear();
          afterImagesList.clear();
          rcaImagesList.clear();
          final List<dynamic>? beforeImgs =
              responseOutput['beforeImageDetails'] as List?;
          if (beforeImgs != null) {
            for (var img in beforeImgs) {
              final fileName = img['FileName']?.toString() ?? '';
              if (fileName.isNotEmpty) {
                beforeImagesList.add({
                  'name': fileName.split('/').last,
                  'path': fileName,
                  'isNetwork': true
                });
              }
            }
          }
          final List<dynamic>? afterImgs =
              responseOutput['afterImageDetails'] as List?;
          if (afterImgs != null) {
            for (var img in afterImgs) {
              final fileName = img['FileName']?.toString() ?? '';
              if (fileName.isNotEmpty) {
                afterImagesList.add({
                  'name': fileName.split('/').last,
                  'path': fileName,
                  'isNetwork': true
                });
              }
            }
          }
          final List<dynamic>? rcaImgs =
              responseOutput['rcaImageDetails'] as List?;
          if (rcaImgs != null) {
            for (var img in rcaImgs) {
              final fileName = img['FileName']?.toString() ?? '';
              if (fileName.isNotEmpty) {
                rcaImagesList.add({
                  'name': fileName.split('/').last,
                  'path': fileName,
                  'isNetwork': true
                });
              }
            }
          }
        } else {
          errorMessage.value =
              jsonBody['responseMessage'] ?? "Failed to load details";
        }
      } else {
        errorMessage.value =
            "Failed to load data. Status code: ${response.statusCode}";
      }
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
        "Validation Error",
        "Please select Functional Location.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (jiUserRemarkController.text.trim().isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Please enter User's Remark.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      EasyLoading.show(status: 'Submitting...');
      final String? userIdStr = await AuthManager().getUserId();
      final String? userName = await AuthManager().getUserName();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;
      final failureNo = jointInspectionFailureNo.value.trim();
      if (failureNo.isEmpty) {
        EasyLoading.dismiss();
        Get.snackbar(
          "Validation Error",
          "Unable to resolve Failure No. Please reload the details and try again.",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final payload = {
        "FailureNo": failureNo,
        "FunctionLocation_JI": jiFunctionalLocationId.value ?? "",
        "EquipmentId_JI": jiEquipmentId.value ?? 0,
        "UserRemark_JI": jiUserRemarkController.text.trim(),
        "CreatedBy": userId,
        "CreatedByName": userName ?? ""
      };

      final message = await _failureService.submitJIScreenData(payload);
      Get.snackbar(AppStrings.success, message,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      Get.back(result: true);
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
    _pushLoading();
    try {
      isLoading.value = true;
      errorMessage.value = "";
      locationTypeList.clear();
      functionalLocationList.clear();
      equipmentList.clear();
      await _loadMasterDataFromDb();

      // Delegate HTTP call to service
      final result = await _failureService.getFailureDetails(failureNo);

      if (result.responseCode == 200 && result.responseOutput != null) {
          final output = result.responseOutput!;

          notificationTypeList
              .assignAll(output.getCorrNotificationTypeList ?? []);
          natureOfWorkList.assignAll(output.getNatureOfWorkList ?? []);
          departmentList.assignAll(output.getDepartmentList ?? []);
          userList.assignAll(output.getUserList ?? []);
          objectDataList.assignAll(output.getObjectData ?? []);
          materialDataList.assignAll(output.getMaterialData ?? []);
          final statuses = output.getUserStatus ?? [];
          userStatusList.assignAll(statuses.where((status) {
            final val = int.tryParse(status.value ?? "999") ?? 999;
            return val == 0 || val <= 29;
          }).toList());
          storageLocationList.assignAll(output.getStorageLocation ?? []);
          faultTypeList.assignAll(output.getFaultData ?? []);
          _mergeLocationDropdownsFromOutput(output);

          notificationHistoryList.assignAll(
              output.getNotificationActionUserHistory ?? []);

          notificationDescriptionHistoryList.assignAll(
              output.getNotificationHistory ?? []);

          // Load joint inspection history from initial response
          if (output.getJoinInspectionHistory != null) {
            jointInspectionHistoryList.assignAll(
              output.getJoinInspectionHistory!
                  .map((item) => JointInspectionHistory.fromJson(item))
                  .toList()
            );
          }

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

            _applyLocationSelectionsFromModel(model, output: output);

            subLocationController.text = model.locationFailure ?? "";

            selectedPriority.value = model.priorityType;
            selectedDepartment.value = departmentList
                .firstWhere(
                    (e) =>
                        e.value == model.deptId?.toString() ||
                        e.label == model.deptCode,
                    orElse: () => LabelValue(label: model.deptCode))
                .label;

            selectedNotificationType.value = notificationTypeList
                .firstWhere(
                    (e) => e.value == model.corr_NotificationTypeId.toString(),
                    orElse: () => LabelValue(label: null))
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
              print(
                  "personnnn matched====${selectedPersonResponsible.value} for ID: ${model.assignedUserId}");
            } else {
              selectedPersonResponsible.value = null;
            }
            if (output.getObjectANDFaultList != null) {
              rcaDetailsList.clear();
              for (var fault in output.getObjectANDFaultList!) {
                final rectId = fault['rectId'];

                final List<Map<String, dynamic>> matchedRootCauses = [];
                if (output.getObjectANDFaultRootCauseList != null) {
                  for (var rc in output.getObjectANDFaultRootCauseList!
                      .where((r) => r['rectId'] == rectId)) {
                    matchedRootCauses.add({
                      'rootCauseId': rc['rcaId'].toString(),
                      'rootCause': rc['rootCasueName'] ?? "N/A",
                      'rootCauseText': rc['rcaText'] ?? "",
                      'imagePath': null
                    });
                  }
                }

                final List<Map<String, dynamic>> matchedActions = [];
                if (output.getObjectANDFaultActionList != null) {
                  for (var ac in output.getObjectANDFaultActionList!
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

            if (output.getMaterialReqDetails != null) {
              replacedMaterialsList.clear();
              for (var mat in output.getMaterialReqDetails!) {
                replacedMaterialsList.add({
                  'id': mat['id'] ??
                      mat['Id'] ??
                      mat['materialReqId'] ??
                      mat['MaterialReqId'] ??
                      0,
                  'Materialid': mat['materialid'] ??
                      mat['materialId'] ??
                      mat['Materialid'],
                  'materialCode': mat['materialValue'] ?? "",
                  'requiredQty': mat['quantity']?.toString() ?? "0",
                  'uom': mat['unitOfMeasurement'] ?? "",
                  'issuedQty': mat['issuedQty']?.toString() ?? "0",
                  'usedQty': mat['usedQty']?.toString() ?? "0",
                  'balanceQty': mat['balanceQty']?.toString() ?? "0",
                  'RemainingBalanceQTY': mat['remainingBalanceQTY'] ?? 0,
                  'StorageLocation': mat['storageLocation'],
                  'storeLocation': mat['storageLocationValue'] ?? "",
                });
              }
            }

            if (output.getMaterialDismantleDetails != null) {
              dismantleMaterialsList.clear();
              for (var dis in output.getMaterialDismantleDetails!) {
                dismantleMaterialsList.add({
                  'id': dis['id'],
                  'materialId': dis['materialId'],
                  'materialCode': dis['materialValue'] ?? "",
                  'oldSerialNo': dis['oldSerialNumber'] ?? "",
                  'newSerialNo': dis['newSerialNumber'] ?? "",
                  'dismantleDateRaw': dis['oldSerialNoDismantleDate'],
                  'installationDateRaw': dis['newSerialNoInstallationDate'],
                });
              }
            }

            if (replacedMaterialsList.isNotEmpty) {
              isSparePartReplaced.value = true;
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
            selectedMaterialType.value = _mapFailureTypeIdToMaterialType(model.failureTypeId);
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

            // Dates
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

            // Pre-populate RCA Details from model (if present)
            if (model.getObjectANDFaultList != null &&
                model.getObjectANDFaultList!.isNotEmpty) {
              rcaDetailsList.clear();
              for (var objFault in model.getObjectANDFaultList!) {
                final rcaId = objFault['rectId'];
                final objectPartId = objFault['objectPartId']?.toString();
                final faultId = objFault['faultId']?.toString();

                final rootCauses = (model.getObjectANDFaultRootCauseList ?? [])
                    .where((rc) =>
                        rc['rectId'] == rcaId &&
                        rc['objectPartId'] == objFault['objectPartId'] &&
                        rc['faultId'] == objFault['faultId'])
                    .map((rc) => {
                          'rootCauseId': rc['rcaId']?.toString() ?? "0",
                          'rootCause': rc['rootCasueName'] ?? "N/A",
                          'rootCauseText': rc['rcaText'] ?? "",
                          'imagePath': null,
                        })
                    .toList();

                final actions = (model.getObjectANDFaultActionList ?? [])
                    .where((act) =>
                        act['rectId'] == rcaId &&
                        act['objectPartId'] == objFault['objectPartId'] &&
                        act['faultId'] == objFault['faultId'])
                    .map((act) => {
                          'actionTakenId': act['actionId']?.toString() ?? "0",
                          'actionTaken': act['actionName'] ?? "N/A",
                          'actionTakenText': act['actionText'] ?? "",
                          'imagePath': null,
                        })
                    .toList();

                rcaDetailsList.add({
                  'ObjectPartId': objFault['objectPartId']?.toString() ?? "0",
                  'objectPart': objFault['objectName'] ?? "",
                  'objectPartText': objFault['objectPartText'] ?? "",
                  'FaultId': objFault['faultId']?.toString() ?? "0",
                  'fault': objFault['faultName'] ?? "",
                  'faultText': objFault['faultText'] ?? "",
                  'rootCauses': rootCauses,
                  'actionTakens': actions,
                });
              }
            }

            print("RCA DETAILS LIST LENGTH: ${rcaDetailsList.length}");
            if (rcaDetailsList.isNotEmpty) {
              print("FIRST RCA ITEM: ${rcaDetailsList.first}");
            }

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
    } finally {
      _popLoading();
    }
  }

  Future<void> loadStationFailureDetails(String id) async {
    encryptedId.value = id;
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Delegate HTTP call to service — returns the responseOutput map or throws
      final output = await _failureService.getStationFailureDetails(id);

      if (output['getFailureCreationDetails'] != null) {
        final details = output['getFailureCreationDetails'];
        _originalFailureId.value = details['id'];
        notificationCode.value = details['failureId'] ?? '';
        selectedPriority.value = details['priority'];
        mainStatusName.value = details['statusName'];
        failureDescriptionController.text = details['failureDescription'] ?? '';
        selectedDepartment.value = details['departmentName'];
        _originalDepartmentId.value =
            details['departmentId_1'] ?? details['departmentId'];
        selectedLocation.value = details['location'];
        _originalLocationId.value = details['locationId'];
        selectedFunctionalLocation.value = details['funcationLocation'];
        subLocationController.text = details['subLocation'] ?? '';
        systemController.text = details['system'] ?? '';
        trainIdController.text = details['trainId'] ?? '';

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
        passengersAffectedCountController.text =
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
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
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
          int.tryParse(_locationCodeForLabel(selectedLocation.value) ?? "0") ??
              _originalLocationId.value ??
              0;
      final int finalDeptId = int.tryParse(
              _departmentCodeForLabel(selectedDepartment.value) ?? "0") ??
          _originalDepartmentId.value ??
          0;

      final Map<String, dynamic> payload = {
        "Id": _originalFailureId.value ?? 0,
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
            passengersAffectedCountController.text.isNotEmpty
                ? int.tryParse(passengersAffectedCountController.text)
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
        print("steppppp");
        Get.back(result: true);
        Get.snackbar(AppStrings.success, AppStrings.failureUpdated,
            backgroundColor: Colors.green, colorText: Colors.white);

      } catch (e, s) {
        print("UPDATE ERROR: $e");
        print(s);
        errorMessage.value = e.toString();
        Get.snackbar(AppStrings.error, errorMessage.value,
            backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        isLoading.value = false;
      }
    } catch (e, s) {
      print("UPDATE ERROR: $e");
      print(s);
      errorMessage.value = 'Error: $e';
      Get.snackbar(AppStrings.error, errorMessage.value,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> fetchJointInspectionUsers(String deptId) async {
    try {
      isJointUserLoading.value = true;
      jointUserList.clear();
      selectedJointAssignTo.value = null;
      final users = await _failureService.getJIUsers(deptId);
      jointUserList.assignAll(users);
    } catch (e) {
      debugPrint('fetchJointInspectionUsers error: $e');
    } finally {
      isJointUserLoading.value = false;
    }
  }

  void _ensureDropdownOption(
      RxList<LabelValue> list, String label, String value) {
    if (label.trim().isEmpty) return;
    if (label.trim().toLowerCase() == 'select') return;
    if (!list.any((e) => e.label?.trim() == label.trim())) {
      list.add(LabelValue(label: label.trim(), value: value));
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
      // Only use API response if it contains actual data (not just "Select Functional Location")
      final filtered = funcs.where((e) => e.value?.trim().isNotEmpty == true && e.value?.toLowerCase() != 'select' && e.label?.toLowerCase() != 'select functional location').toList();
      if (filtered.isNotEmpty) {
        for (var item in filtered) {
          // Display the funcLocationName as the label for selection
          final labelValue = LabelValue(
            label: item.label ?? '',   // show funcLocationName e.g. "N01-206-DNL-SIG-ALD-APN-A1202 - CBTC  ACCESS POINT AT DN LINE, 206"
            value: item.value ?? '',
          );
          if (!functionalLocationList.any((e) => e.label == labelValue.label)) {
            functionalLocationList.add(labelValue);
          }
          // Also add to masterFunctionalLocations for filtering
          if (!masterFunctionalLocations.any((e) => e['funcLocId']?.toString() == item.value)) {
            masterFunctionalLocations.add({
              'funcLocId': item.value,
              'funcLocationName': item.label,
              'location': null,  // API doesn't provide location, should not be filtered
              'workCenter': null,  // API doesn't provide workCenter, should not be filtered
              'fromApi': true,  // Mark as from API to always include
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
    for (final item in masterLocations) {
      if (item['locationTypeId']?.toString() == locationTypeId.toString()) {
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
    for (final item in masterEquipments) {
      final idText = equipmentId.toString();
      if (item['equipId']?.toString() == idText ||
          item['equipmentId']?.toString() == idText) {
        return item['equipmentName']?.toString();
      }
    }
    return null;
  }

  void _applyLocationSelectionsFromModel(
    CreateVMModel model, {
    FailureDetailOutput? output,
  }) {
    String? locationName = model.locationName?.trim();
    String? funcLocation = model.funcLocation?.trim();
    funcLocation ??= _masterFunctionalLocationName(model.functionLocationId);
    String? equipmentName = model.equipmentName?.trim();

    locationName ??= _masterLocationName(model.locationTypeId);
    equipmentName ??= _masterEquipmentName(model.equipmentId);

    if (locationName != null && locationName.isNotEmpty) {
      _ensureDropdownOption(
        locationTypeList,
        locationName,
        model.locationTypeId?.toString() ?? '',
      );
      selectedLocation.value = locationName;
      locationDisplayController.text = locationName;
    }

    if (funcLocation != null && funcLocation.isNotEmpty) {
      _ensureDropdownOption(
        functionalLocationList,
        funcLocation,
        model.functionLocationId?.toString() ?? '',
      );
      selectedFunctionalLocation.value = funcLocation;
      functionalLocationDisplayController.text = funcLocation;
    }

    if (equipmentName != null && equipmentName.isNotEmpty) {
      _ensureDropdownOption(
        equipmentList,
        equipmentName,
        model.equipmentId?.toString() ?? '',
      );
      selectedEquipmentNumber.value = equipmentName;
      equipmentDisplayController.text = equipmentName;
    }
  }

  Future<void> _loadMasterDataFromDb() async {
    final dbService = LocalDatabaseService();

    final locs = await dbService.getLocations();
    final funcs = await dbService.getFunctionalLocations();
    final equips = await dbService.getEquipments();

    // Don't filter by plant IDs - the data doesn't match the valid plant IDs
    // Filtering should be done at API sync level if needed
    final filteredLocs = locs;
    final filteredFuncs = funcs;
    final filteredEquips = equips;

    final uniqueLocs = {
      for (var e in filteredLocs) e['locationName']?.toString() ?? '': e
    }
        .values
        .where((e) => (e['locationName']?.toString() ?? '').isNotEmpty && (e['locationName']?.toString().toLowerCase() != 'select'))
        .toList();

    final uniqueFuncs = {
      for (var e in filteredFuncs) e['funcLocationName']?.toString() ?? '': e
    }
        .values
        .where((e) => 
          (e['funcLocationName']?.toString() ?? '').isNotEmpty && 
          (e['funcLocationName']?.toString().toLowerCase() != 'select')
        )
        .toList();

    final uniqueEquips = {
      for (var e in filteredEquips) e['equipmentName']?.toString() ?? '': e
    }
        .values
        .where((e) => (e['equipmentName']?.toString() ?? '').isNotEmpty && (e['equipmentName']?.toString().toLowerCase() != 'select'))
        .toList();

    masterLocations.assignAll(uniqueLocs);
    masterFunctionalLocations.assignAll(uniqueFuncs);
    masterEquipments.assignAll(uniqueEquips);

    // Only add "Select" if list is empty (first initialization)
    if (locationTypeList.isEmpty) {
      locationTypeList.add(LabelValue(label: 'Select', value: ''));
    }
    for (var item in masterLocations.where((e) => (e['locationName']?.toString() ?? '').toLowerCase() != 'select')) {
      final labelValue = LabelValue(
            label: item['locationName']?.toString() ?? '',
            value: item['locationTypeId']?.toString() ?? '',
          );
      if (!locationTypeList.any((e) => e.label == labelValue.label)) {
        locationTypeList.add(labelValue);
      }
    }

    if (functionalLocationList.isEmpty) {
      functionalLocationList.add(LabelValue(label: 'Select', value: ''));
    }
    for (var item in masterFunctionalLocations.where((e) => (e['funcLocationName']?.toString() ?? '').toLowerCase() != 'select')) {
      final labelValue = LabelValue(
            label: item['funcLocationName']?.toString() ?? '',
            value: item['funcLocId']?.toString() ?? '',
          );
      if (!functionalLocationList.any((e) => e.label == labelValue.label)) {
        functionalLocationList.add(labelValue);
      }
    }

    if (equipmentList.isEmpty) {
      equipmentList.add(LabelValue(label: 'Select', value: ''));
    }
    for (var item in masterEquipments.where((e) => (e['equipmentName']?.toString() ?? '').toLowerCase() != 'select')) {
      final labelValue = LabelValue(
            label: item['equipmentName']?.toString() ?? '',
            value: item['equipId']?.toString() ?? '',
          );
      if (!equipmentList.any((e) => e.label == labelValue.label)) {
        equipmentList.add(labelValue);
      }
    }
  }

  Map<String, dynamic> _locationByName(String? locationLabel) {
    if (locationLabel == null || locationLabel == 'Select') return {};
    return masterLocations.firstWhere(
      (e) => e['locationName']?.toString() == locationLabel,
      orElse: () => <String, dynamic>{},
    );
  }

  String? _locationCodeForLabel(String? locationLabel) {
    final loc = _locationByName(locationLabel);
    final code = loc['locationTypeCode']?.toString();
    debugPrint("_locationCodeForLabel: locationLabel=$locationLabel, locationTypeCode=$code");
    debugPrint("_locationCodeForLabel: full location data=$loc");
    return (code != null && code.isNotEmpty) ? code : null;
  }

  void _resetFunctionalAndEquipmentSelections() {
    selectedFunctionalLocation.value = 'Select';
    selectedEquipmentNumber.value = 'Select';
    showMeasurementButton.value = false;
  }

  void _resetLocationFunctionalAndEquipmentSelections() {
    selectedFunctionalLocation.value = 'Select';
    selectedEquipmentNumber.value = 'Select';
    showMeasurementButton.value = false;
  }
  final masterDepartments = <Map<String, dynamic>>[].obs;

  void _setLocationOptions(List<Map<String, dynamic>> locs) {
    locationTypeList.clear();
    locationTypeList.add(LabelValue(label: 'Select', value: ''));
    locationTypeList.addAll(
      locs
          .where((e) => (e['locationName']?.toString() ?? '').isNotEmpty && (e['locationName']?.toString() ?? '').toLowerCase() != 'select')
          .map((e) => LabelValue(
                label: e['locationName']?.toString() ?? '',
                value: e['locationTypeId']?.toString() ?? '',
              ))
          .toList(),
    );
  }

  void _setFunctionalLocationOptions(List<Map<String, dynamic>> funcs) {
    functionalLocationList.clear();
    functionalLocationList.add(LabelValue(label: 'Select', value: ''));
    functionalLocationList.addAll(
      funcs
          .where((e) => (e['funcLocationName']?.toString() ?? '').isNotEmpty && (e['funcLocationName']?.toString() ?? '').toLowerCase() != 'select')
          .map((e) => LabelValue(
                // Display funcLocation code (e.g. "M2-L1-ST01") as the label
                label: e['funcLocationName']?.toString() ?? '',
                value: e['funcLocId']?.toString() ?? '',
              ))
          .toList(),
    );
  }

  void _setEquipmentOptions(List<Map<String, dynamic>> equips) {
    equipmentList.clear();
    equipmentList.add(LabelValue(label: 'Select', value: ''));
    equipmentList.addAll(
      equips.where((e) => (e['equipmentName']?.toString() ?? '').toLowerCase() != 'select').map((e) => LabelValue(
            label: e['equipmentName']?.toString() ?? '',
            value: e['equipId']?.toString() ?? '',
          )).toList()
    );
  }

  List<Map<String, dynamic>> _equipmentsForLocationCode(String? locCode) {
    if (locCode == null || locCode.isEmpty) return masterEquipments;
    return masterEquipments
        .where((eq) => eq['location']?.toString() == locCode)
        .toList();
  }

  void onDepartmentChanged(String? departmentLabel) {
    selectedDepartment.value = (departmentLabel == null || departmentLabel == 'Select') ? null : departmentLabel;
    _resetFunctionalAndEquipmentSelections();
    _updateFunctionalLocationAndEquipmentOptions();
  }

  void onLocationChanged(String? locationLabel) {
    selectedLocation.value = (locationLabel == null || locationLabel == 'Select') ? null : locationLabel;
    _resetFunctionalAndEquipmentSelections();
    _updateFunctionalLocationAndEquipmentOptions();
  }

  void _updateFunctionalLocationAndEquipmentOptions() {
    final hasLocation = selectedLocation.value != null && selectedLocation.value != 'Select';
    final hasDept = selectedDepartment.value != null && selectedDepartment.value != 'Select';

    String? locCode;
    if (hasLocation) {
      locCode = _locationCodeForLabel(selectedLocation.value);
    }

    String? workCenter;
    if (hasDept) {
      final dept = departmentList.firstWhere(
            (e) => e.label == selectedDepartment.value,
        orElse: () => LabelValue(),
      );
      workCenter = _getWorkCenterForDept(dept.value);
    }

    final filteredFuncs = masterFunctionalLocations.where((e) {
      bool match = true;

      if (hasLocation && locCode != null && locCode.isNotEmpty) {
        match = match && (e['location']?.toString().trim().toUpperCase() == locCode.trim().toUpperCase());
      }
      
      if (hasDept && workCenter != null && workCenter.isNotEmpty) {
        match = match && (e['workCenter']?.toString().trim().toUpperCase() == workCenter.trim().toUpperCase());
      }

      return match;
    }).toList();

    _setFunctionalLocationOptions(filteredFuncs);

    if (hasLocation && locCode != null && locCode.isNotEmpty) {
      _setEquipmentOptions(_equipmentsForLocationCode(locCode));
    } else {
      _setEquipmentOptions(masterEquipments);
    }
  }

  void onJiFunctionalLocationChanged(String? label) {
    selectedJiFunctionalLocation.value = label;
    selectedJiEquipmentNumber.value = null;
    jiEquipmentId.value = null;
    jiEquipmentNumber.value = null;
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

  void onFunctionalLocationChanged(String? funcLabel) {
    if (funcLabel == null || funcLabel == 'Select') {
      selectedFunctionalLocation.value =
          funcLabel == 'Select' ? 'Select' : null;
      selectedEquipmentNumber.value = 'Select';
      showMeasurementButton.value = false;
      _setEquipmentOptions(_equipmentsForLocationCode(
          _locationCodeForLabel(selectedLocation.value)));
      return;
    }

    selectedFunctionalLocation.value = funcLabel;
    selectedEquipmentNumber.value = 'Select';

    // funcLabel is now the funcLocationName (full display name), need to find the funcLocation code
    final func = masterFunctionalLocations.firstWhere(
      (e) => e['funcLocationName']?.toString() == funcLabel,
      orElse: () => <String, dynamic>{},
    );

    // Auto-select location based on functional location
    final locCode = func['location']?.toString();
    if (locCode != null && locCode.isNotEmpty) {
      final loc = masterLocations.firstWhere(
        (e) => e['locationTypeCode']?.toString() == locCode ||
               e['locationTypeId']?.toString() == locCode,
        orElse: () => <String, dynamic>{},
      );
      if (loc.isNotEmpty) {
        final locName = loc['locationName']?.toString();
        if (locName != null && locName.isNotEmpty) {
          selectedLocation.value = locName;
          locationDisplayController.text = locName;
        }
      }
    }

    final funcCode = func['funcLocation']?.toString();
    if (funcCode != null && funcCode.isNotEmpty) {
      final filteredEquips = masterEquipments
          .where((eq) => eq['functionalLocation']?.toString() == funcCode)
          .toList();
      _setEquipmentOptions(filteredEquips);
      _checkMeasurementPoints(func['objectNumber']?.toString());
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

    // Auto-select location based on equipment
    final locCode = eq['location']?.toString();
    if (locCode != null && locCode.isNotEmpty) {
      final loc = masterLocations.firstWhere(
        (e) => e['locationTypeCode']?.toString() == locCode ||
               e['locationTypeId']?.toString() == locCode,
        orElse: () => <String, dynamic>{},
      );
      if (loc.isNotEmpty) {
        final locName = loc['locationName']?.toString();
        if (locName != null && locName.isNotEmpty) {
          selectedLocation.value = locName;
          locationDisplayController.text = locName;
        }
      }
    }

    final funcCode = eq['functionalLocation']?.toString();
    if (funcCode != null && funcCode.isNotEmpty) {
      final func = masterFunctionalLocations.firstWhere(
          (e) => e['funcLocation'] == funcCode,
          orElse: () => <String, dynamic>{});

      if (func.isNotEmpty) {
        // Display funcLocation CODE as the selected value (matching the dropdown label)
        selectedFunctionalLocation.value = funcCode;
        functionalLocationDisplayController.text = funcCode;
        // Also ensure the dropdown list includes this func loc
        _ensureDropdownOption(
          functionalLocationList,
          funcCode,
          func['funcLocId']?.toString() ?? '',
        );
        _checkMeasurementPoints(func['objectNumber']?.toString());
      }
    }
  }

  Future<void> _checkMeasurementPoints(String? objectNumber) async {
    debugPrint("Checking Measurement Points for objectNumber: $objectNumber");
    if (objectNumber == null || objectNumber.isEmpty) {
      showMeasurementButton.value = false;
      measurementPointsList.clear();
      return;
    }

    final dbService = LocalDatabaseService();
    List<Map<String, dynamic>> allMeasurements =
        await dbService.getMeasurementPoints();
    debugPrint("Total Measurement Points in DB: ${allMeasurements.length}");

    // Only sync if it has NEVER been synced before (meta date is still the default)
    final meta = await dbService.getSyncMeta('GetMeasurementPtMasterData');
    final neverSynced = meta['createdOn'] == '2024-01-01';
    if (allMeasurements.isEmpty && neverSynced) {
      debugPrint("Measurement Points never synced – fetching from API...");
      await MasterDataSyncService().syncMeasurementPoints();
      allMeasurements = await dbService.getMeasurementPoints();
      debugPrint(
          "After sync – Total Measurement Points in DB: ${allMeasurements.length}");
    } else if (allMeasurements.isEmpty) {
      debugPrint(
          "Sync already ran (meta: ${meta['createdOn']}) but no matching data in DB.");
    }

    final matchingMeasurements = allMeasurements
        .where((m) =>
            m['objectNo']?.toString().trim() == objectNumber.toString().trim())
        .toList();
    debugPrint(
        "Matching Measurement Points found: ${matchingMeasurements.length}");

    if (matchingMeasurements.isNotEmpty) {
      measurementPointsList.assignAll(matchingMeasurements
          .map((m) => {
                "measPoint": m['measPoint'],
                "measPointDesc": m['measPointDesc'],
                "measRangeUnit": m['measRangeUnit'],
                "internalCharNo": m['internalCharNo'],
                "targetValue": m['targetValue'],
                "measId": m['measId'],
                "reading": "",
                "readingDescr": "",
                "uom": m['measRangeUnit'],
                "UnitMeasurement": m['measRangeUnit']
              })
          .toList());
      showMeasurementButton.value = true;
    } else {
      measurementPointsList.clear();
      showMeasurementButton.value = false;
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

  Future<void> fetchRootCauseAndAction(
      String objectCodeId, String faultCodeId) async {
    try {
      EasyLoading.show(status: 'Loading RCA options...');
      final data =
          await _failureService.getRootCauseAndAction(objectCodeId, faultCodeId);
      EasyLoading.dismiss();
      rootCauseList.assignAll(data.rootCauses);
      actionTakenList.assignAll(data.actionTaken);
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(AppStrings.error, e.toString());
    }
  }

  Future<void> _loadMasterDropdownsFromDb({bool refreshIfEmpty = false}) async {
    final dbService = LocalDatabaseService();

    if (refreshIfEmpty) {
      try {
        final priorities = await dbService.getPriorities();
        final categories = await dbService.getFailureCategories();
        final users = await dbService.getMasterUsers();
        if (priorities.isEmpty || categories.isEmpty || users.isEmpty) {
          await MasterDataSyncService().syncStationFailureDropdownMasterData();
        }
      } catch (e) {
        debugPrint('_loadMasterDropdownsFromDb sync error: $e');
        await MasterDataSyncService().syncStationFailureDropdownMasterData();
      }
    }

    final priorities = await dbService.getPriorities();
    priorityTypeList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...priorities
          .where((e) => (e['priorityDesc']?.toString() ?? '').isNotEmpty && (e['priorityDesc']?.toString().toLowerCase() != 'select'))
          .map((e) => LabelValue(
                label: e['priorityDesc']?.toString() ?? '',
                value: e['priorityId']?.toString() ?? '',
              )),
    ]);

    final categories = await dbService.getFailureCategories();
    corrNotificationTypeList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...categories
          .where((e) => (e['failureCategoryType']?.toString() ?? '').isNotEmpty && (e['failureCategoryType']?.toString().toLowerCase() != 'select'))
          .map((e) => LabelValue(
                label: e['failureCategoryType']?.toString() ?? '',
                value: e['id']?.toString() ?? '',
              )),
    ]);

    final users = await dbService.getMasterUsers();
    debugPrint('loadMasterDataFromDb: Total users from DB = ${users.length}');
    // Deduplicate users by userId to avoid repeating names
    final uniqueUsers = <String, Map<String, dynamic>>{};
    for (final user in users) {
      final userId = user['userId']?.toString() ?? '';
      if (userId.isNotEmpty && (user['userName']?.toString() ?? '').isNotEmpty) {
        uniqueUsers.putIfAbsent(userId, () => user);
      }
    }
    userList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...uniqueUsers.values
          .where((e) => (e['userName']?.toString() ?? '').isNotEmpty && (e['userName']?.toString().toLowerCase() != 'select'))
          .map((e) => LabelValue(
                label: e['userName']?.toString() ?? '',
                value: e['userId']?.toString() ?? '',
              )),
    ]);
    debugPrint('loadMasterDataFromDb: userList count after deduplication = ${userList.length}');

    priorityTypeList.refresh();
    corrNotificationTypeList.refresh();
    userList.refresh();
  }

  Future<void> loadStationCreateDropdowns() async {
    try {
      isLoading.value = true;
      debugPrint("loadStationCreateDropdowns: loading from local DB");

      await _loadMasterDropdownsFromDb();

      // Now load everything from local DB into reactive lists
      await _loadMasterDataFromDb();

      debugPrint("loadStationCreateDropdowns: isStationController = $isStationController");
      debugPrint("loadStationCreateDropdowns: masterFunctionalLocations count = ${masterFunctionalLocations.length}");
      
      // Always reload departments from local storage after sync
      await _loadDepartments();
    } catch (e) {
      debugPrint("loadStationCreateDropdowns error: $e");
    } finally {
      isLoading.value = false;
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
    passengersAffectedCountController.text = count?.toString() ?? '';
    trappedDurationController.text = trapped ?? '';
    rescuedDurationController.text = rescued ?? '';
  }

  String _lookupValue(List<LabelValue> list, String? label,
      {String fallback = "0"}) {
    if (label == null || label.isEmpty || label == 'Select') return fallback;
    return list
            .firstWhere((e) => e.label == label,
                orElse: () => LabelValue(value: fallback))
            .value ??
        fallback;
  }

  Future<void> submitFailure({required bool isCreate}) async {
    if (isStation && isCreate) {
      await createStationFailure();
      return;
    }
    await updateFailure();
  }

  Future<void> createStationFailure() async {
    if (!isStationController) {
      Get.snackbar(
        "Access Denied",
        "Only Station Controller can create station failure.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

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
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      EasyLoading.show(status: 'Saving...');
      final createdBy =
          int.tryParse(await AuthManager().getUserId() ?? "0") ?? 0;

      final deptIdStr = _lookupValue(
        departmentList,
        selectedDepartment.value,
        fallback: Get.find<SessionController>()
                .selectedDepartment
                .value
                ?.deptId
                ?.toString() ??
            "0",
      );
      final priorityId = _lookupValue(priorityTypeList, selectedPriority.value);
      final locationId = _lookupValue(locationTypeList, selectedLocation.value);
      print("locationId===$locationId");
      final funcLocId = _lookupValue(
          functionalLocationList, selectedFunctionalLocation.value);
      final stationCategoryId = corrNotificationTypeList
              .firstWhere((e) => e.label?.toLowerCase() == 'station',
                  orElse: () => LabelValue(value: "4"))
              .value ??
          "4";
      final failureReportedById = int.tryParse(
              _lookupValue(userList, selectedFailureReportedBy.value)) ??
          0;
      final trainReplace = int.tryParse(trainReplaceNosController.text) ?? 0;

      final body = <String, dynamic>{
        "PriorityId": priorityId,
        "DepartmentIds": deptIdStr,
        "DepartmentId_1": deptIdStr,
        "DepartmentId_2": 0,
        "DepartmentId_3": 0,
        "FailureDescription": description,
        "LocationId": locationId,
        "SubLocation": subLocationController.text.trim(),
        "System": systemController.text.trim(),
        "TrainId": trainIdController.text.trim(),
        "ActualFailureOccuranceDate": DateFormat("dd/MM/yyyy HH:mm")
            .format(selectedFailureOccurrenceDate.value!),
        "FailureReportedbyId": failureReportedById,
        "IsTripAffected": isServiceAffected.value,
        "IsTrainReplace": trainReplace > 0,
        "IsTrainDeboarded": isPassengerDeboarding.value,
        "IsPassengerAffected": isPassengerAffected.value,
        "CreatedBy": createdBy,
        "FailureCategoryTypeId": stationCategoryId,
        "FailureCategoryTypeText": "",
        "ActualFailureCompletedDateTime":
            selectedFailureCompletedDate.value != null
                ? DateFormat("dd/MM/yyyy HH:mm")
                    .format(selectedFailureCompletedDate.value!)
                : "",
      };

      if (funcLocId != "0") {
        body["FuncationLocationIds"] = funcLocId;
        body["FuncationLocationId_1"] = funcLocId;
        body["FuncationLocationId_2"] = 0;
        body["FuncationLocationId_3"] = 0;
      } else {
        body["FuncationLocationIds"] = "";
        body["FuncationLocationId_1"] = 0;
        body["FuncationLocationId_2"] = 0;
        body["FuncationLocationId_3"] = 0;
      }

      if (tripDelayUplineController.text.trim().isNotEmpty) {
        body["TripDelayUpline"] =
            int.tryParse(tripDelayUplineController.text.trim());
      }
      if (tripDelayDownlineController.text.trim().isNotEmpty) {
        body["TripDelayDownline"] =
            int.tryParse(tripDelayDownlineController.text.trim());
      }
      if (trainCancelNosController.text.trim().isNotEmpty) {
        body["TripCancel"] = int.tryParse(trainCancelNosController.text.trim());
      }
      if (trainDelayMinController.text.trim().isNotEmpty) {
        body["TrainDelayInMin"] =
            int.tryParse(trainDelayMinController.text.trim());
      }
      if (trainWithdrawalNosController.text.trim().isNotEmpty) {
        body["NoOfTranWithdrawal"] =
            int.tryParse(trainWithdrawalNosController.text.trim());
      }
      if (trainReplaceNosController.text.trim().isNotEmpty) {
        body["TrainReplace"] =
            int.tryParse(trainReplaceNosController.text.trim());
      }
      if (trainDeboardedNosController.text.trim().isNotEmpty) {
        body["TrainDeboarded"] =
            int.tryParse(trainDeboardedNosController.text.trim());
      }
      if (passengersAffectedCountController.text.trim().isNotEmpty) {
        body["NumberOfPassengerAffected"] =
            int.tryParse(passengersAffectedCountController.text.trim());
      }
      if (trappedDurationController.text.trim().isNotEmpty) {
        body["TrappedDuration"] =
            int.tryParse(trappedDurationController.text.trim());
      }
      if (rescuedDurationController.text.trim().isNotEmpty) {
        body["RescusedDuration"] =
            int.tryParse(rescuedDurationController.text.trim());
      }

      final failureNo = await _failureService.createStationFailure(body);
      EasyLoading.dismiss();
      Get.back();
      final message = (failureNo != null && failureNo.isNotEmpty)
          ? 'Station failure created: $failureNo'
          : AppStrings.failureCreated;
      Get.snackbar(AppStrings.success, message);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint("Create Station Failure Error: $e");
      Get.snackbar("Error", "An unexpected error occurred");
    }
  }

  Future<void> updateFailure() async {
    try {
      List<String> errors = [];

      if (failureRectificationDetailsController.text.trim().isEmpty) {
        errors.add("Failure Rectification Details is required.");
      }

      if (isCloseUserStatusBlocked &&
          selectedUserStatus.value?.trim().toLowerCase() == 'close') {
        showPendingJointInspectionPopup();
        return;
      }

      if (selectedNotificationType.value == null || selectedNotificationType.value!.isEmpty || selectedNotificationType.value == 'Select') {
        errors.add("Notification Type is required.");
      }

      if (isTripAffected.value) {
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

      if (selectedUserStatus.value == "Under Observation") {
        if (selectedUnderObservationDate.value == null) {
          errors.add("Under Observation Date is required when status is 'Under Observation'.");
        }
      }

      if (isSparePartReplaced.value) {
        if (replacedMaterialsList.isEmpty) {
          errors.add("Please add at least one Replaced Material since 'Spare Part Replaced' is enabled.");
        } else {
          for (var mat in replacedMaterialsList) {
            final usedQtyStr = mat['usedQty']?.toString().trim() ?? "";
            if (usedQtyStr.isEmpty) {
              errors.add("Used Quantity is required for all replaced materials.");
              break;
            }
          }
        }
      }

      if (isRcaRequired.value) {
        if (rcaDetailsList.isEmpty) {
          errors.add("Please add at least one RCA detail.");
        } else {
          for (int i = 0; i < rcaDetailsList.length; i++) {
            var rca = rcaDetailsList[i];
            final objPart = rca['objectPart']?.toString().trim() ?? "";
            final objPartText = rca['objectPartText']?.toString().trim() ?? "";
            final fault = rca['fault']?.toString().trim() ?? "";
            final faultText = rca['faultText']?.toString().trim() ?? "";

            if (objPart.isEmpty && objPartText.isEmpty) {
              errors.add("Object Part is required in RCA item ${i + 1}.");
            }
            if (fault.isEmpty && faultText.isEmpty) {
              errors.add("Fault is required in RCA item ${i + 1}.");
            }

            final List rootCauses = rca['rootCauses'] ?? [];
            final List actionTakens = rca['actionTakens'] ?? [];

            if (rootCauses.isEmpty) {
              errors.add("At least one Root Cause is required in RCA item ${i + 1}.");
            }
            if (actionTakens.isEmpty) {
              errors.add("At least one Action Taken is required in RCA item ${i + 1}.");
            }
          }
        }
      }

      if (errors.isNotEmpty) {
        Get.snackbar(
          'Validation Error',
          errors.first,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // --- END OF VALIDATION ---

      EasyLoading.show(status: 'Updating...');

      final newJeRemark = failureDescriptionController.text.trim();

      final changeNotifictionJE = {
        "Id": encryptedId.value.isEmpty ? "0" : encryptedId.value,
        "Category": failureCategory.value,
        "Remark_JE": newJeRemark,
        "NatureOfWorkId": int.tryParse(natureOfWorkList
                    .firstWhere((e) => e.label == selectedNatureOfWork.value,
                        orElse: () => LabelValue(value: "0"))
                    .value ??
                "0") ??
            0,
        "TrainRunningKM": trainRunningKmController.text.isEmpty
            ? null
            : trainRunningKmController.text,
        "NotificationTypeId": int.tryParse(notificationTypeList
                    .firstWhere(
                        (e) => e.label == selectedNotificationType.value,
                        orElse: () => LabelValue(value: "0"))
                    .value ??
                "0") ??
            0,
        "FunctionLocationId": int.tryParse(functionalLocationList
                    .firstWhere(
                        (e) => e.label == selectedFunctionalLocation.value,
                        orElse: () => LabelValue(value: "0"))
                    .value ??
                "0") ??
            0,
        "EquipmentId": int.tryParse(equipmentList
                    .firstWhere((e) => e.label == selectedEquipmentNumber.value,
                        orElse: () => LabelValue(value: "0"))
                    .value ??
                "0") ??
            0,
        "PowerBlockRequired": isPowerBlockRequired.value,
        "SICRequired": isSicRequired.value,
        "SICFailureType": 0, // Need to map if available
        "SICResponsiblePerson": 0, // Need to map if available
        "PTWRequired": isPtwRequired.value,
        "PTWNo": ptwNumberController.text,
        "IsServiceAffected": isServiceAffected.value,
        "TrainDelayInMin": int.tryParse(trainDelayMinController.text) ?? 0,
        "TrainDelayInNo": int.tryParse(trainDelayNosController.text) ?? 0,
        "NoOfTranWithdrawal":
            int.tryParse(trainWithdrawalNosController.text) ?? 0,
        "NoOfTranCancel": int.tryParse(trainCancelNosController.text) ?? 0,
        "NoOfTrainReplace": int.tryParse(trainReplaceNosController.text) ?? 0,
        "IsPassengerDeboarding": isPassengerDeboarding.value,
        "NoofTrainDeboarded":
            int.tryParse(trainDeboardedNosController.text) ?? 0,
        "FailureAttendedDate": selectedFailureAttendedDate.value != null
            ? DateFormat("dd/MM/yyyy HH:mm")
                .format(selectedFailureAttendedDate.value!)
            : null,
        "ActualFailureRectifiedDate":
            selectedActualFailureRectifiedDate.value != null
                ? DateFormat("dd/MM/yyyy HH:mm")
                    .format(selectedActualFailureRectifiedDate.value!)
                : null,
        "IsFailureRectifiDetails": isRcaRequired.value,
        "FailureType": selectedActualFailureRectified.value,
        "FailureTypeId": int.tryParse(
                selectedActualFailureRectified.value == "Yes" ? "1" : "2") ??
            2,
        "IsHardwareReplaced": isSparePartReplaced.value,
        "IsJointInspectionReq": isJointInspection.value,
        "FunctionLocation_JI": 0, // Map from joint inspection selections
        "EquipmentId_JI": 0,
        "UserStatus": int.tryParse(userStatusList
                    .firstWhere((e) => e.label == selectedUserStatus.value,
                        orElse: () => LabelValue(value: "0"))
                    .value ??
                "0") ??
            0,
        "AssignedUserId": int.tryParse(userList
                    .firstWhere(
                        (e) => e.label == selectedPersonResponsible.value,
                        orElse: () => LabelValue(value: "0"))
                    .value ??
                "0") ??
            0,
        "AssignedUserId_JI": int.tryParse(jointUserList
                    .firstWhere((e) => e.label == selectedJointAssignTo.value,
                        orElse: () => LabelValue(value: "0"))
                    .value ??
                "0") ??
            0,
        "DeptId_JI": int.tryParse(departmentList
                    .firstWhere((e) => e.label == selectedJointDept.value,
                        orElse: () => LabelValue(value: "0"))
                    .value ??
                "0") ??
            0,
        "CreatedBy": int.tryParse(await AuthManager().getUserId() ?? "0") ?? 0,
        "IsPassengerAffected": isPassengerAffected.value,
        "NoOfPassengerAffected": isPassengerAffected.value
            ? int.tryParse(passengersAffectedCountController.text)
            : null,
        "TrappedDuration": isPassengerAffected.value &&
                trappedDurationController.text.trim().isNotEmpty
            ? trappedDurationController.text.trim()
            : null,
        "RescuedDuration": isPassengerAffected.value &&
                rescuedDurationController.text.trim().isNotEmpty
            ? rescuedDurationController.text.trim()
            : null,
        "LocationTypeId": int.tryParse(
              locationTypeList
                      .firstWhere((e) => e.label == selectedLocation.value,
                          orElse: () => LabelValue(value: "0"))
                      .value ??
                  "0",
            ) ??
            0,
        "NotificationCode": notificationCode.value,
        "UnderObservationDate": selectedUnderObservationDate.value != null
            ? DateFormat("dd/MM/yyyy HH:mm")
                .format(selectedUnderObservationDate.value!)
            : null,
        "FailureRectificationDetails":
            failureRectificationDetailsController.text.isEmpty
                ? "N/A"
                : failureRectificationDetailsController.text,
        "LocationFailure": subLocationController.text,
        "Corr_NotificationTypeId": int.tryParse(corrNotificationTypeList
                    .firstWhere(
                        (e) => e.label == selectedNotificationType.value,
                        orElse: () => LabelValue(value: "1"))
                    .value ??
                "1") ??
            1,
        "ReasonForDelayId": reasonForDelayId.value,
      };

      final payload = {
        "Action": "UPDATE_JE_NOTIFICATIONMob",
        "changeNotifictionJE": changeNotifictionJE,
        "materialRequiredDetails": isSparePartReplaced.value
            ? _materialsForSubmit().map(_buildMaterialPayload).toList()
            : <Map<String, dynamic>>[],
        "failureRectification": rcaDetailsList
            .map((e) => {
                  "ObjectPartId":
                      int.tryParse(e['ObjectPartId'].toString()) ?? 0,
                  "ObjectPartText": e['objectPartText'] ?? "",
                  "FaultId": int.tryParse(e['FaultId'].toString()) ?? 0,
                  "FaultText": e['faultText'] ?? "",
                  "RootCauseText": (e['rootCauses'] as List).isNotEmpty
                      ? "${e['rootCauses'][0]['rootCauseId']}:${e['rootCauses'][0]['rootCauseText']}"
                      : "",
                  "ActionText": (e['actionTakens'] as List).isNotEmpty
                      ? "${e['actionTakens'][0]['actionTakenId']}:${e['actionTakens'][0]['actionTakenText']}"
                      : ""
                })
            .toList(),
        "getMeasurementPoints": measurementPointsList
            .map((e) => {
                  "measId": e['measId'],
                  "measPoint": e['measPoint'],
                  "measPointDesc": e['measPointDesc'],
                  "unitOfMeasurement": e['unitOfMeasurement'],
                  "isRequired": e['isRequired'],
                  "beforeReading":
                      num.tryParse(e['beforeReading']?.toString() ?? "") ?? 0,
                  "finalConfirmation": true,
                  "afterReading":
                      num.tryParse(e['afterReading']?.toString() ?? "") ?? 0
                })
            .toList(),
        "joinInspectionHistory": isJointInspection.value
            ? _jointInspectionHistoryForSubmit()
            : <Map<String, dynamic>>[],
        "materialDismantleDetails": isMaterialDismantle.value
            ? dismantleMaterialsList.map((e) {
                final recordId = _materialRecordId(e);
                final statusId = recordId > 0 ? 2 : 1;
                return {
                  "MaterialId": e['materialId'] ??
                      e['MaterialId'] ??
                      _resolveMaterialId(e),
                  "MaterialValue": e['materialCode'] ?? "",
                  "MaterialReqId": recordId,
                  "OldSerialNumber": e['oldSerialNo'] ?? "",
                  "NewSerialNumber": e['newSerialNo'] ?? "",
                  "OldSerialNoDismantleDate": e['dismantleDateRaw'] ??
                      (e['dismantleDate'] != null
                          ? "${e['dismantleDate'].day}/${e['dismantleDate'].month}/${e['dismantleDate'].year}"
                          : ""),
                  "NewSerialNoInstallationDate": e['installationDateRaw'] ??
                      (e['installationDate'] != null
                          ? "${e['installationDate'].day}/${e['installationDate'].month}/${e['installationDate'].year}"
                          : ""),
                  "InsertUpdateStatusId": statusId,
                  "CurrentInsertUpdateStatusId": statusId,
                  "Id": recordId,
                };
              }).toList()
            : <Map<String, dynamic>>[]
      };

      // Build files list from local (non-network) selections
      final List<http.MultipartFile> files = [];
      if (beforeFiles.isNotEmpty &&
          beforeFiles.first['path'] != null &&
          beforeFiles.first['isNetwork'] != true) {
        files.add(await http.MultipartFile.fromPath(
            'beforeImage', beforeFiles.first['path']));
      }
      if (afterFiles.isNotEmpty &&
          afterFiles.first['path'] != null &&
          afterFiles.first['isNetwork'] != true) {
        files.add(await http.MultipartFile.fromPath(
            'afterImage', afterFiles.first['path']));
      }
      if (rcaFiles.isNotEmpty &&
          rcaFiles.first['path'] != null &&
          rcaFiles.first['isNetwork'] != true) {
        files.add(await http.MultipartFile.fromPath(
            'rcaImage', rcaFiles.first['path']));
      }

      await _failureService.updateJEFailure(payload, files: files);
      EasyLoading.dismiss();
      Get.back();
      Get.snackbar(AppStrings.success, AppStrings.failureUpdated,
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('updateFailure error: $e');
      Get.snackbar(AppStrings.error, 'An unexpected error occurred');
    }
  }

  void updateMeasurementReading(int index, String field, String value) {
    var list = List<Map<String, dynamic>>.from(measurementPointsList);
    list[index][field] = value;
    measurementPointsList.assignAll(list);
  }

  DateTime? _parseDate(String dateStr) {
    try {
      // Try MM/dd/yyyy HH:mm:ss format first (US format from API)
      try {
        return DateFormat('MM/dd/yyyy HH:mm:ss').parse(dateStr);
      } catch (e) {
        // Fallback to dd/MM/yyyy HH:mm format
        return DateFormat('dd/MM/yyyy HH:mm').parse(dateStr);
      }
    } catch (e) {
      debugPrint('Error parsing date: $dateStr — $e');
      return null;
    }
  }
}
