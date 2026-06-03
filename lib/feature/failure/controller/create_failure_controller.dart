import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../service/auth_manager.dart';
import '../model/failure_detail_response.dart';
import '../../../service/session_controller.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import '../../../utils/widgets/cust_dropdown.dart';

class CreateFailureController extends GetxController {
  final ApiClient _apiClient = ApiClient();

  // Loading states
  final isLoading = false.obs;
  final isFaultLoading = false.obs;
  final isEquipmentLoading = false.obs;
  final showMeasurementButton = false.obs;
  final errorMessage = "".obs;
  final encryptedId = "".obs;
  final notificationCode = "".obs;

  // Dynamic Lists from API
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

  // Toggle states
  final isBasicInfoVisible = true.obs;
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

  // File lists for attachments
  final beforeFiles = <Map<String, dynamic>>[].obs;
  final afterFiles = <Map<String, dynamic>>[].obs;
  final rcaFiles = <Map<String, dynamic>>[].obs; // For new RCA uploads

  // Lists for displaying existing API images
  final beforeImagesList = <Map<String, dynamic>>[].obs;
  final afterImagesList = <Map<String, dynamic>>[].obs;
  final rcaImagesList = <Map<String, dynamic>>[].obs;

  // Controllers for text fields
  final failureDescriptionController = TextEditingController();
  final ptwNumberController = TextEditingController();
  final systemController = TextEditingController();
  final trainIdController = TextEditingController();
  final tripDelayUplineController = TextEditingController();
  final tripDelayDownlineController = TextEditingController();
  final passengersAffectedCountController = TextEditingController();
  final trappedDurationController = TextEditingController();
  final rescuedDurationController = TextEditingController();

  // Role / failure-type getters
  bool get isJE => Get.find<SessionController>().selectedRole.value?.roleDescr?.contains("Junior Engineer") ?? false;
  bool get isTechnician => Get.find<SessionController>().selectedRole.value?.roleDescr?.contains("Technician") ?? false;
  bool get isStationController => Get.find<SessionController>().selectedRole.value?.roleDescr?.contains("Station Controller") ?? false;
  bool get isStation => failureCategory.value.toLowerCase() == 'station';
  bool get isMaintenance => failureCategory.value.toLowerCase() == 'maintenance';
  bool get isOCC => failureCategory.value.toLowerCase() == 'occ';
  bool get isDepot => failureCategory.value.toLowerCase() == 'depot';
  final objectPartTextController = TextEditingController();
  final faultTextController = TextEditingController();
  final subLocationController = TextEditingController();
  final natureOfWorkController = TextEditingController();
  final failureTypeController = TextEditingController();
  final trainRunningKmController = TextEditingController();
  final failureRectificationDetailsController = TextEditingController();

  // RCA Popup Controllers
  final popupRootCauseTextController = TextEditingController();
  final popupActionTakenTextController = TextEditingController();

  // Fields from the image (Service Affected sub-fields)
  final trainDelayMinController = TextEditingController();
  final trainDelayNosController = TextEditingController();
  final trainCancelNosController = TextEditingController();
  final trainWithdrawalNosController = TextEditingController();
  final trainReplaceNosController = TextEditingController();

  // Fields from the image (Passenger Deboarding sub-fields)
  final trainDeboardedNosController = TextEditingController();

  // Spare Part Replace Fields
  final selectedMaterialCode = RxnString();
  final uomController = TextEditingController();
  final selectedStoreLocation = RxnString();
  final balanceQtyController = TextEditingController();
  final requiredQtyController = TextEditingController();
  final replacedMaterialsList = <Map<String, dynamic>>[].obs;

  // Material Dismantle Fields
  final selectedDismantleMaterialCode = RxnString();
  final oldSerialNumberController = TextEditingController();
  final oldSerialDismantleDate = Rxn<DateTime>();
  final newSerialNumberController = TextEditingController();
  final newSerialInstallationDate = Rxn<DateTime>();
  final dismantleMaterialsList = <Map<String, dynamic>>[].obs;

  // Dropdown selections
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

  // Master Data Lists for the new logic
  final masterLocations = <Map<String, dynamic>>[].obs;
  final masterFunctionalLocations = <Map<String, dynamic>>[].obs;
  final masterEquipments = <Map<String, dynamic>>[].obs;

  // RCA Popup Selections
  final selectedPopupRootCause = RxnString();
  final selectedPopupActionTaken = RxnString();
  final popupRootCauseFiles = <Map<String, dynamic>>[].obs;
  final popupActionTakenFiles = <Map<String, dynamic>>[].obs;
  final tempPopupRootCauses = <Map<String, dynamic>>[].obs;
  final tempPopupActionTakens = <Map<String, dynamic>>[].obs;
  final isExpandedRca = <int, bool>{}.obs; // Track expansion state per card index
  final selectedMaterialType = RxString("Hardware");
  final materialTypeList = ["Software", "Hardware", "Communication", "Other"];

  // Joint Inspection Fields
  final selectedJointDept = RxnString();
  final selectedJointAssignTo = RxnString();
  final jointInspectionRemarkController = TextEditingController();
  final jointInspectionHistoryList = <Map<String, dynamic>>[].obs;
  
  final jointUserList = <LabelValue>[].obs;
  final isJointUserLoading = false.obs;

  List<LabelValue> get jointInspectionDepartments {
    final List<LabelValue> sourceList = departmentList.isNotEmpty
        ? departmentList
        : Get.find<SessionController>().departments.map((e) => LabelValue(
            label: e.deptName,
            value: e.deptId?.toString(),
          )).toList();

    final currentDept = Get.find<SessionController>().selectedDepartment.value;
    if (currentDept == null) return sourceList;

    return sourceList.where((e) {
      final isSameId = e.value == currentDept.deptId?.toString();
      final isSameName = e.label?.trim().toLowerCase() == currentDept.deptName?.trim().toLowerCase();
      return !isSameId && !isSameName;
    }).toList();
  }

  // Date Selections
  final selectedUnderObservationDate = Rxn<DateTime>();
  final selectedFailureOccurrenceDate = Rxn<DateTime>();
  final selectedFailureAttendedDate = Rxn<DateTime>();
  final selectedActualFailureRectifiedDate = Rxn<DateTime>();
  final selectedFailureCompletedDate = Rxn<DateTime>();

  // Failure Type (to handle the 4 types mentioned by the user)
  final failureCategory = "Maintenance".obs; // Default to Maintenance

  // List for RCA details
  final rcaDetailsList = <Map<String, dynamic>>[].obs;
  final measurementPointsList = <Map<String, dynamic>>[].obs;
  
  final editingReplacedMaterialIndex = (-1).obs;
  final editingDismantleMaterialIndex = (-1).obs;
  final notificationHistoryList = <NotificationActionHistory>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMasterData();
  }

  @override
  void onClose() {
    failureDescriptionController.dispose();
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
    oldSerialNumberController.dispose();
    newSerialNumberController.dispose();
    jointInspectionRemarkController.dispose();
    failureRectificationDetailsController.dispose();
    super.onClose();
  }

  void addRcaDetail() {
    final objectPartId = objectDataList.firstWhere((e) => e.label == selectedObjectPart.value, orElse: () => LabelValue(value: "0")).value;
    final faultId = faultTypeList.firstWhere((e) => e.label == selectedFault.value, orElse: () => LabelValue(value: "0")).value;

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

  // Root Cause Management
  void addRootCauseToRca(int index) {
    if (selectedPopupRootCause.value == null && popupRootCauseTextController.text.isEmpty) return;
    
    final List<Map<String, dynamic>> rootCauses = List.from(rcaDetailsList[index]['rootCauses']);
    rootCauses.add({
      'rootCause': selectedPopupRootCause.value ?? "N/A",
      'rootCauseText': popupRootCauseTextController.text,
      'imagePath': popupRootCauseFiles.isNotEmpty ? popupRootCauseFiles.first['path'] : null,
    });
    
    rcaDetailsList[index]['rootCauses'] = rootCauses;
    rcaDetailsList.refresh();
    
    // Clear popup state
    selectedPopupRootCause.value = null;
    popupRootCauseTextController.clear();
    popupRootCauseFiles.clear();
  }

  void removeRootCauseFromRca(int rcaIndex, int itemIndex) {
    final List<Map<String, dynamic>> rootCauses = List.from(rcaDetailsList[rcaIndex]['rootCauses']);
    rootCauses.removeAt(itemIndex);
    rcaDetailsList[rcaIndex]['rootCauses'] = rootCauses;
    rcaDetailsList.refresh();
  }

  // Action Taken Management
  void addActionTakenToRca(int index) {
    if (selectedPopupActionTaken.value == null && popupActionTakenTextController.text.isEmpty) return;

    final List<Map<String, dynamic>> actionTakens = List.from(rcaDetailsList[index]['actionTakens']);
    actionTakens.add({
      'actionTaken': selectedPopupActionTaken.value ?? "N/A",
      'actionTakenText': popupActionTakenTextController.text,
      'imagePath': popupActionTakenFiles.isNotEmpty ? popupActionTakenFiles.first['path'] : null,
    });

    rcaDetailsList[index]['actionTakens'] = actionTakens;
    rcaDetailsList.refresh();

    // Clear popup state
    selectedPopupActionTaken.value = null;
    popupActionTakenTextController.clear();
    popupActionTakenFiles.clear();
  }

  void removeActionTakenFromRca(int rcaIndex, int itemIndex) {
    final List<Map<String, dynamic>> actionTakens = List.from(rcaDetailsList[rcaIndex]['actionTakens']);
    actionTakens.removeAt(itemIndex);
    rcaDetailsList[rcaIndex]['actionTakens'] = actionTakens;
    rcaDetailsList.refresh();
  }

  // Popup Management
  void addToTempRootCauses() {
    if (selectedPopupRootCause.value == null && popupRootCauseTextController.text.isEmpty) return;
    final rootCauseId = rootCauseList.firstWhere((e) => e.label == selectedPopupRootCause.value, orElse: () => LabelValue(value: "0")).value ?? "0";
    tempPopupRootCauses.add({
      'rootCauseId': rootCauseId,
      'rootCause': selectedPopupRootCause.value ?? "N/A",
      'rootCauseText': popupRootCauseTextController.text,
      'imagePath': popupRootCauseFiles.isNotEmpty ? popupRootCauseFiles.first['path'] : null,
    });
    // Clear current inputs
    selectedPopupRootCause.value = null;
    popupRootCauseTextController.clear();
    popupRootCauseFiles.clear();
  }

  void addToTempActionTakens() {
    if (selectedPopupActionTaken.value == null && popupActionTakenTextController.text.isEmpty) return;
    final actionTakenId = actionTakenList.firstWhere((e) => e.label == selectedPopupActionTaken.value, orElse: () => LabelValue(value: "0")).value ?? "0";
    tempPopupActionTakens.add({
      'actionTakenId': actionTakenId,
      'actionTaken': selectedPopupActionTaken.value ?? "N/A",
      'actionTakenText': popupActionTakenTextController.text,
      'imagePath': popupActionTakenFiles.isNotEmpty ? popupActionTakenFiles.first['path'] : null,
    });
    // Clear current inputs
    selectedPopupActionTaken.value = null;
    popupActionTakenTextController.clear();
    popupActionTakenFiles.clear();
  }

  void savePopupDataToRca(int index) {
    final List<Map<String, dynamic>> rootCauses = List.from(rcaDetailsList[index]['rootCauses']);
    final List<Map<String, dynamic>> actionTakens = List.from(rcaDetailsList[index]['actionTakens']);
    
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
    final raw = item['id'] ?? item['Id'] ?? item['materialReqId'] ?? item['MaterialReqId'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  int _resolveMaterialId(Map<String, dynamic> item) {
    final fromItem = item['Materialid'] ?? item['MaterialId'] ?? item['materialid'];
    if (fromItem != null) {
      if (fromItem is int) return fromItem;
      final parsed = int.tryParse(fromItem.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    final code = (item['MaterialName'] ?? item['materialCode'])?.toString().trim() ?? '';
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
    final label = (item['storeLocation'] ?? item['storageLocationValue'])?.toString().trim() ?? '';
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
      "Quantity": int.tryParse(e['requiredQty']?.toString() ?? e['Quantity']?.toString() ?? "0") ?? 0,
      "UnitMeasurement": e['uom'] ?? e['UnitMeasurement'] ?? "",
      "IssuedQty": int.tryParse(e['issuedQty']?.toString() ?? "0") ?? 0,
      "UsedQty": int.tryParse(e['usedQty']?.toString() ?? e['UsedQty']?.toString() ?? "0") ?? 0,
      "BalanceQty": int.tryParse(e['balanceQty']?.toString() ?? e['BalanceQty']?.toString() ?? "0") ?? 0,
      "RemainingBalanceQTY": e['RemainingBalanceQTY'] ?? 0,
      "StorageLocation": _resolveStorageLocationId(e),
      "InsertUpdateStatusId": statusId,
      "CurrentInsertUpdateStatusId": statusId,
      "Id": recordId,
    };
  }

  void addReplacedMaterial() {
    if (selectedMaterialCode.value != null) {
      final alreadyExists = replacedMaterialsList.any(
        (m) =>
            m['materialCode']?.toString().trim() == selectedMaterialCode.value?.trim() &&
            editingReplacedMaterialIndex.value < 0,
      );
      if (alreadyExists) {
        Get.snackbar(
          "Validation Error",
          "This material is already added.",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      if (editingReplacedMaterialIndex.value >= 0) {
        final existing = replacedMaterialsList[editingReplacedMaterialIndex.value];
        existing['materialCode'] = selectedMaterialCode.value;
        existing['uom'] = uomController.text;
        existing['storeLocation'] = selectedStoreLocation.value;
        existing['balanceQty'] = balanceQtyController.text;
        existing['requiredQty'] = requiredQtyController.text;
        replacedMaterialsList.refresh();
        editingReplacedMaterialIndex.value = -1;
      } else {
        replacedMaterialsList.add({
          'materialCode': selectedMaterialCode.value,
          'uom': uomController.text,
          'storeLocation': selectedStoreLocation.value,
          'balanceQty': balanceQtyController.text,
          'requiredQty': requiredQtyController.text,
          'issuedQty': "0",
          'usedQty': "0",
        });
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
    if (editingReplacedMaterialIndex.value == index) {
      editingReplacedMaterialIndex.value = -1;
      selectedMaterialCode.value = null;
      uomController.clear();
      selectedStoreLocation.value = null;
      balanceQtyController.clear();
      requiredQtyController.clear();
    }
  }

  void addDismantleMaterial() {
    if (selectedDismantleMaterialCode.value != null) {
      if (editingDismantleMaterialIndex.value >= 0) {
        final existing = dismantleMaterialsList[editingDismantleMaterialIndex.value];
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
    oldSerialDismantleDate.value = item['dismantleDate']; // Note: if coming from API, it might be in dismantleDateRaw. We should parse it if needed, or leave it for the user to reselect.
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

  void addJointInspectionHistory() {
    if (selectedJointDept.value != null && selectedJointAssignTo.value != null) {
      jointInspectionHistoryList.add({
        'department': selectedJointDept.value,
        'assignedTo': selectedJointAssignTo.value,
        'assignedDateTime': DateTime.now().toString(), // Mocked
        'remark': jointInspectionRemarkController.text,
        'userRemark': '',
        'status': 'Joint Inspection Pending',
      });
      // Clear inputs
      selectedJointDept.value = null;
      selectedJointAssignTo.value = null;
      jointInspectionRemarkController.clear();
      jointUserList.clear();
    }
  }

  void removeJointInspectionHistory(int index) {
    jointInspectionHistoryList.removeAt(index);
  }

  // Station Popup
  final popupStationList = <LabelValue>[].obs;
  final isPopupStationLoading = false.obs;
  final selectedStationId = Rxn<String>();
  final selectedStationName = Rxn<String>();

  Future<void> fetchAndShowStationPopup() async {
    try {
      isPopupStationLoading.value = true;
      final userId = await AuthManager().getUserId() ?? "1";
      final response = await _apiClient.get("${AppUrls.getStationName}?AssgineUserId=$userId");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['responseCode'] == 200 && responseData['responseOutput'] != null) {
          final List<dynamic> data = responseData['responseOutput'];
          popupStationList.assignAll(data.map((e) => LabelValue(
            label: e['label']?.toString() ?? '',
            value: e['value']?.toString() ?? '',
          )).toList());
        
        Get.dialog(
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Station",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => CustDropdown(
                    label: "Station",
                    hint: "Select Station",
                    items: popupStationList.map((e) => e.label ?? '').toList(),
                    selectedValue: selectedStationName.value,
                    onChanged: (val) {
                      selectedStationName.value = val;
                      selectedStationId.value = popupStationList.firstWhere((e) => e.label == val, orElse: () => LabelValue(value: "0")).value;
                    },
                  )),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (selectedStationName.value != null) {
                            Get.back();
                          } else {
                            Get.snackbar("Error", "Please select a station");
                          }
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          barrierDismissible: false,
        );
        }
      }
    } catch (e) {
      debugPrint("Error fetching stations: $e");
    } finally {
      isPopupStationLoading.value = false;
    }
  }

  Future<void> loadFailureDetails(String failureNo) async {
    encryptedId.value = failureNo;
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;

      final response = await _apiClient.post(
        AppUrls.jeChangeNotification,
        body: {
          "AssignedUserId": userId,
          "Id": failureNo,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final result = FailureDetailResponse.fromJson(jsonBody);

        if (result.responseCode == 200 && result.responseOutput != null) {
          final output = result.responseOutput!;
          
          // Populate Lists
          notificationTypeList.assignAll(output.getCorrNotificationTypeList ?? []);
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
          priorityTypeList.assignAll(output.getPriorityType ?? []);
          faultTypeList.assignAll(output.getFaultData ?? []);
          corrNotificationTypeList.assignAll(output.getCorrNotificationTypeList ?? []);
          
          final List<dynamic>? historyListJson = jsonBody['getNotificationHistory'] as List? ??
                                                 jsonBody['getNotificationActionUserHistory'] as List? ??
                                                 jsonBody['responseOutput']?['getNotificationHistory'] as List? ??
                                                 jsonBody['responseOutput']?['getNotificationActionUserHistory'] as List?;
          if (historyListJson != null) {
            notificationHistoryList.assignAll(historyListJson
                .map((e) => NotificationActionHistory.fromJson(e as Map<String, dynamic>))
                .toList());
          } else {
            notificationHistoryList.assignAll(output.getNotificationActionUserHistory ?? []);
          }

          // Populate Model Data
          if (output.getCreateVMModel != null) {
            final model = output.getCreateVMModel!;
            encryptedId.value = (model.id != null && model.id!.isNotEmpty) ? model.id! : failureNo;
            notificationCode.value = model.notificationCode ?? "";
            if (model.category != null && model.category!.trim().isNotEmpty) {
              failureCategory.value = model.category!.trim();
            }
            
            // Trigger cascading fetch for existing data
            if (model.functionLocationId != null && model.locationTypeId != null) {
              fetchEquipmentAndMeasurements(
                model.functionLocationId.toString(),
                model.locationTypeId.toString(),
                preselectedEquipmentId: model.equipmentId?.toString(),
              );
            }
            
            subLocationController.text = model.locationFailure ?? "";
            
            // Dropdown matching with safety
            selectedPriority.value = model.priorityType;
            selectedDepartment.value = departmentList.firstWhere(
                (e) => e.value == model.deptId?.toString() || e.label == model.deptCode, 
                orElse: () => LabelValue(label: model.deptCode)).label;
            
            selectedNotificationType.value = notificationTypeList.firstWhere(
                (e) => e.value == model.corr_NotificationTypeId.toString(), 
                orElse: () => LabelValue(label: null)).label;
                
            mainStatusName.value = model.mainStatusName;
            final matchedUserStatus = output.getUserStatus?.firstWhere(
                (e) => e.value == model.userStatus.toString(), 
                orElse: () => LabelValue(label: null));
            selectedUserStatus.value = matchedUserStatus?.label;

            selectedLocation.value = masterLocations.firstWhere(
                (e) => e['locationTypeCode'].toString() == model.locationTypeId.toString(),
                orElse: () => <String, dynamic>{})['locationName']?.toString();

            if (model.assignedUserId != null) {
              final matchedUser = userList.firstWhere(
                  (e) => e.value?.toString().trim() == model.assignedUserId.toString().trim(), 
                  orElse: () => LabelValue(label: null));
              selectedPersonResponsible.value = matchedUser.label;
              print("personnnn matched====${selectedPersonResponsible.value} for ID: ${model.assignedUserId}");
            } else {
              selectedPersonResponsible.value = null;
            }
            // Populate RCA Details
            if (output.getObjectANDFaultList != null) {
              rcaDetailsList.clear();
              for (var fault in output.getObjectANDFaultList!) {
                final rectId = fault['rectId'];
                
                final List<Map<String, dynamic>> matchedRootCauses = [];
                if (output.getObjectANDFaultRootCauseList != null) {
                  for (var rc in output.getObjectANDFaultRootCauseList!.where((r) => r['rectId'] == rectId)) {
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
                  for (var ac in output.getObjectANDFaultActionList!.where((a) => a['rectId'] == rectId)) {
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

            // Populate Material Details
            if (output.getMaterialReqDetails != null) {
              replacedMaterialsList.clear();
              for (var mat in output.getMaterialReqDetails!) {
                replacedMaterialsList.add({
                  'id': mat['id'] ?? mat['Id'] ?? mat['materialReqId'] ?? mat['MaterialReqId'] ?? 0,
                  'Materialid': mat['materialid'] ?? mat['materialId'] ?? mat['Materialid'],
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

            // Populate Dismantle Material Details
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

            // Set Toggles if Data Exists
            if (replacedMaterialsList.isNotEmpty) {
              isSparePartReplaced.value = true;
            }
            if (dismantleMaterialsList.isNotEmpty) {
              isMaterialDismantle.value = true;
            }

            // Populate Uploaded Images
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
                    // Fallback to before
                    beforeImagesList.add(imgMap);
                  }
                }
              }
            }



            // Mapping for other dropdowns if needed...
            
            isServiceAffected.value = model.isServiceAffected ?? false;
            isJointInspection.value = model.isJointInspectionReq ?? false;
            isSparePartReplaced.value = model.isHardwareReplaced ?? false;
            isPtwRequired.value = model.isPTWReq ?? false;
            ptwNumberController.text = model.ptwNo ?? "";

            // Service Affected sub-fields
            trainDelayMinController.text = model.trainDelayInMin?.toString() ?? "";
            trainDelayNosController.text = model.trainDelayInNo?.toString() ?? "";
            trainCancelNosController.text = model.noOfTranCancel?.toString() ?? "";
            trainWithdrawalNosController.text = model.noOfTranWithdrawal?.toString() ?? "";
            trainReplaceNosController.text = model.noOfTrainReplace?.toString() ?? "";
            isPassengerDeboarding.value = model.isPassengerDeboarding ?? false;
            trainDeboardedNosController.text = model.noofTrainDeboarded?.toString() ?? "";

            // Location details
            subLocationController.text = model.locationFailure ?? "";
            selectedFunctionalLocation.value = model.funcDescription;

            // Dates
            selectedFailureOccurrenceDate.value = model.actualFailureOccuranceOn != null ? _parseDate(model.actualFailureOccuranceOn!) : null;
            selectedActualFailureRectifiedDate.value = model.actualFailureRectifiedDate != null ? _parseDate(model.actualFailureRectifiedDate!) : null;
            selectedFailureAttendedDate.value = model.failureAttendedDate != null ? _parseDate(model.failureAttendedDate!) : null;
            selectedUnderObservationDate.value = (model.underObservationDate != null && model.underObservationDate!.isNotEmpty) ? _parseDate(model.underObservationDate!) : null;

            // Pre-populate RCA Details from model (if present)
            if (model.getObjectANDFaultList != null && model.getObjectANDFaultList!.isNotEmpty) {
              rcaDetailsList.clear();
              for (var objFault in model.getObjectANDFaultList!) {
                final rcaId = objFault['rectId'];
                final objectPartId = objFault['objectPartId']?.toString();
                final faultId = objFault['faultId']?.toString();

                final rootCauses = (model.getObjectANDFaultRootCauseList ?? [])
                    .where((rc) => rc['rectId'] == rcaId && rc['objectPartId'] == objFault['objectPartId'] && rc['faultId'] == objFault['faultId'])
                    .map((rc) => {
                          'rootCauseId': rc['rcaId']?.toString() ?? "0",
                          'rootCause': rc['rootCasueName'] ?? "N/A",
                          'rootCauseText': rc['rcaText'] ?? "",
                          'imagePath': null,
                        })
                    .toList();

                final actions = (model.getObjectANDFaultActionList ?? [])
                    .where((act) => act['rectId'] == rcaId && act['objectPartId'] == objFault['objectPartId'] && act['faultId'] == objFault['faultId'])
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

            // Rectification
            selectedActualFailureRectified.value = model.failureType; // "Yes" or "No"
            failureRectificationDetailsController.text = model.failureRectificationDetails ?? "";
            // selectedPersonResponsible.value is already mapped using assignedUserId earlier

            // Populate already uploaded images
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
            if (model.imagesPathsAfter != null && model.imagesPathsAfter!.isNotEmpty) {
              final images = model.imagesPathsAfter!.split(',');
              for (var img in images) {
                afterFiles.add({
                  'name': img.split('/').last,
                  'size': 'N/A',
                  'path': img,
                });
              }
            }
            // Add RCA images if available
            if (model.imagesPathsRCA != null && model.imagesPathsRCA!.isNotEmpty) {
              final images = model.imagesPathsRCA!.split(',');
              for (var img in images) {
                // You might want a separate list or add to afterFiles
                afterFiles.add({
                  'name': 'RCA_${img.split('/').last}',
                  'size': 'N/A',
                  'path': img,
                });
              }
            }
          }
        } else {
          errorMessage.value = result.responseMessage ?? "Failed to load details";
        }
      } else {
        errorMessage.value = "Server error: ${response.statusCode}";
      }
    } catch (e) {
      errorMessage.value = "Error: $e";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchJointInspectionUsers(String deptId) async {
    try {
      isJointUserLoading.value = true;
      jointUserList.clear();
      selectedJointAssignTo.value = null;

      final String? userIdStr = await AuthManager().getUserId();
      final int createdBy = int.tryParse(userIdStr ?? "0") ?? 0;

      final response = await _apiClient.get(
        "${AppUrls.getFunctionLocEquipmentNoByDeptIdJI}?deptId=$deptId&createdBy=$createdBy",
      );

      debugPrint("Fetch Joint Users Status: ${response.statusCode}");
      debugPrint("Fetch Joint Users Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final result = FailureDetailResponse.fromJson(jsonBody);
        
        if (result.responseCode == 200 && result.responseOutput != null) {
          final outputJson = jsonBody['responseOutput'];
          if (outputJson != null) {
            final userListJson = (outputJson['getAssgineUserList'] ??
                                   outputJson['getUserList'] ?? 
                                   outputJson['userList'] ?? 
                                   outputJson['getUsers'] ?? 
                                   outputJson['getUserData']) as List?;
            if (userListJson != null) {
              final parsedUsers = userListJson
                  .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                  .where((u) => u.value != "0" && u.label?.trim().toLowerCase() != "select user")
                  .toList();
              jointUserList.assignAll(parsedUsers);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching Joint Inspection users: $e");
    } finally {
      isJointUserLoading.value = false;
    }
  }

  Future<void> fetchMasterData() async {
    try {
      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;
      
      final response = await _apiClient.post(
        AppUrls.getMasterData,
        body: {
          "userId": userId
        }
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        if (jsonBody['success'] == true && jsonBody['data'] != null) {
          final data = jsonBody['data'];
          
          final List<dynamic> locs = data['locations'] ?? [];
          final List<dynamic> funcs = data['functionalLocations'] ?? [];
          final List<dynamic> equips = data['equipments'] ?? [];

          // Remove duplicates to prevent DropdownSearch duplicate item errors
          final uniqueLocs = { for (var e in locs.cast<Map<String, dynamic>>()) e['locationName']?.toString() ?? '': e }
              .values.where((e) => (e['locationName']?.toString() ?? '').isNotEmpty).toList();
              
          final uniqueFuncs = { for (var e in funcs.cast<Map<String, dynamic>>()) e['funcLocationName']?.toString() ?? '': e }
              .values.where((e) => (e['funcLocationName']?.toString() ?? '').isNotEmpty).toList();
              
          final uniqueEquips = { for (var e in equips.cast<Map<String, dynamic>>()) e['equipmentName']?.toString() ?? '': e }
              .values.where((e) => (e['equipmentName']?.toString() ?? '').isNotEmpty).toList();

          masterLocations.assignAll(uniqueLocs);
          masterFunctionalLocations.assignAll(uniqueFuncs);
          masterEquipments.assignAll(uniqueEquips);

          // Initially show all data with a 'Select' option
          locationTypeList.assignAll([
            LabelValue(label: 'Select', value: ''),
            ...masterLocations.map((e) => LabelValue(
              label: e['locationName']?.toString() ?? '',
              value: e['locationTypeCode']?.toString() ?? '', 
            ))
          ]);

          functionalLocationList.assignAll([
            LabelValue(label: 'Select', value: ''),
            ...masterFunctionalLocations.map((e) => LabelValue(
              label: e['funcLocationName']?.toString() ?? '',
              value: e['funcLocId']?.toString() ?? '',
            ))
          ]);

          equipmentList.assignAll([
            LabelValue(label: 'Select', value: ''),
            ...masterEquipments.map((e) => LabelValue(
              label: e['equipmentName']?.toString() ?? '',
              value: e['equipId']?.toString() ?? '',
            ))
          ]);
        }
      }
    } catch (e) {
      debugPrint("Error fetching master data: $e");
    }
  }

  void onLocationChanged(String? locationLabel) {
    if (locationLabel == null || locationLabel == 'Select') {
      selectedLocation.value = locationLabel == 'Select' ? 'Select' : null;
      
      functionalLocationList.assignAll([
        LabelValue(label: 'Select', value: ''),
        ...masterFunctionalLocations.map((e) => LabelValue(
          label: e['funcLocationName']?.toString() ?? '',
          value: e['funcLocId']?.toString() ?? '',
        ))
      ]);
      
      equipmentList.assignAll([
        LabelValue(label: 'Select', value: ''),
        ...masterEquipments.map((e) => LabelValue(
          label: e['equipmentName']?.toString() ?? '',
          value: e['equipId']?.toString() ?? '',
        ))
      ]);
      
      selectedFunctionalLocation.value = locationLabel == 'Select' ? 'Select' : null;
      selectedEquipmentNumber.value = locationLabel == 'Select' ? 'Select' : null;
      return;
    }

    selectedLocation.value = locationLabel;
    
    final locCode = masterLocations.firstWhere(
      (e) => e['locationName'] == locationLabel, 
      orElse: () => <String, dynamic>{}
    )['locationTypeCode']?.toString();
    
    if (locCode != null && locCode.isNotEmpty) {
      final filteredFuncs = masterFunctionalLocations.where((f) => f['location'] == locCode).toList();
      functionalLocationList.assignAll([
        LabelValue(label: 'Select', value: ''),
        ...filteredFuncs.map((e) => LabelValue(
          label: e['funcLocationName']?.toString() ?? '',
          value: e['funcLocId']?.toString() ?? '',
        ))
      ]);
      
      final filteredEquips = masterEquipments.where((eq) => eq['location'] == locCode).toList();
      equipmentList.assignAll([
        LabelValue(label: 'Select', value: ''),
        ...filteredEquips.map((e) => LabelValue(
          label: e['equipmentName']?.toString() ?? '',
          value: e['equipId']?.toString() ?? '',
        ))
      ]);
      
      if (selectedFunctionalLocation.value != null && selectedFunctionalLocation.value != 'Select' &&
          !filteredFuncs.any((f) => f['funcLocationName'] == selectedFunctionalLocation.value)) {
        selectedFunctionalLocation.value = 'Select';
      }
      if (selectedEquipmentNumber.value != null && selectedEquipmentNumber.value != 'Select' &&
          !filteredEquips.any((eq) => eq['equipmentName'] == selectedEquipmentNumber.value)) {
        selectedEquipmentNumber.value = 'Select';
      }
    }
  }

  void onFunctionalLocationChanged(String? funcLabel) {
    if (funcLabel == null || funcLabel == 'Select') {
      selectedFunctionalLocation.value = funcLabel == 'Select' ? 'Select' : null;
      onLocationChanged(selectedLocation.value);
      return;
    }

    selectedFunctionalLocation.value = funcLabel;
    
    final func = masterFunctionalLocations.firstWhere(
      (e) => e['funcLocationName'] == funcLabel, 
      orElse: () => <String, dynamic>{}
    );
    
    final funcCode = func['funcLocation']?.toString();
    final locCode = func['location']?.toString();
    
    if (locCode != null && locCode.isNotEmpty) {
      final loc = masterLocations.firstWhere(
        (e) => e['locationTypeCode'] == locCode,
        orElse: () => <String, dynamic>{}
      );
      if (loc.isNotEmpty) {
        selectedLocation.value = loc['locationName']?.toString();
        
        // Filter Functional locations by this location
        final filteredFuncs = masterFunctionalLocations.where((f) => f['location'] == locCode).toList();
        functionalLocationList.assignAll([
          LabelValue(label: 'Select', value: ''),
          ...filteredFuncs.map((e) => LabelValue(
            label: e['funcLocationName']?.toString() ?? '',
            value: e['funcLocId']?.toString() ?? '',
          ))
        ]);
      }
    }
    
    if (funcCode != null && funcCode.isNotEmpty) {
      final filteredEquips = masterEquipments.where((eq) => eq['functionalLocation'] == funcCode).toList();
      equipmentList.assignAll([
        LabelValue(label: 'Select', value: ''),
        ...filteredEquips.map((e) => LabelValue(
          label: e['equipmentName']?.toString() ?? '',
          value: e['equipId']?.toString() ?? '',
        ))
      ]);
      
      if (selectedEquipmentNumber.value != null && selectedEquipmentNumber.value != 'Select' &&
          !filteredEquips.any((eq) => eq['equipmentName'] == selectedEquipmentNumber.value)) {
        selectedEquipmentNumber.value = 'Select';
      }
    }
    
    selectedFunctionalLocation.value = funcLabel;
  }

  void onEquipmentChanged(String? equipLabel) {
    if (equipLabel == null || equipLabel == 'Select') {
      selectedEquipmentNumber.value = equipLabel == 'Select' ? 'Select' : null;
      onFunctionalLocationChanged(selectedFunctionalLocation.value);
      return;
    }

    selectedEquipmentNumber.value = equipLabel;
    
    final eq = masterEquipments.firstWhere(
      (e) => e['equipmentName'] == equipLabel, 
      orElse: () => <String, dynamic>{}
    );
    
    final funcCode = eq['functionalLocation']?.toString();
    final locCode = eq['location']?.toString();
    
    if (locCode != null && locCode.isNotEmpty) {
       final loc = masterLocations.firstWhere(
         (e) => e['locationTypeCode'] == locCode,
         orElse: () => <String, dynamic>{}
       );
       if (loc.isNotEmpty) {
         selectedLocation.value = loc['locationName']?.toString();
         
         final filteredFuncs = masterFunctionalLocations.where((f) => f['location'] == locCode).toList();
         functionalLocationList.assignAll([
           LabelValue(label: 'Select', value: ''),
           ...filteredFuncs.map((e) => LabelValue(
             label: e['funcLocationName']?.toString() ?? '',
             value: e['funcLocId']?.toString() ?? '',
           ))
         ]);
       }
    }

    if (funcCode != null && funcCode.isNotEmpty) {
      final func = masterFunctionalLocations.firstWhere(
        (e) => e['funcLocation'] == funcCode, 
        orElse: () => <String, dynamic>{}
      );
      
      if (func.isNotEmpty) {
        selectedFunctionalLocation.value = func['funcLocationName']?.toString();
        
        final filteredEquips = masterEquipments.where((e) => e['functionalLocation'] == funcCode).toList();
        equipmentList.assignAll([
          LabelValue(label: 'Select', value: ''),
          ...filteredEquips.map((e) => LabelValue(
            label: e['equipmentName']?.toString() ?? '',
            value: e['equipId']?.toString() ?? '',
          ))
        ]);
      }
    }
    
    selectedEquipmentNumber.value = equipLabel;
  }

  Future<void> fetchFaults(String objectPartId) async {
    try {
      isFaultLoading.value = true;
      faultTypeList.clear(); // Clear existing faults immediately
      debugPrint("Fetching faults for Object ID: $objectPartId");
      final response = await _apiClient.post(
        AppUrls.getFaultMaster,
        body: {
          "ObjectCodeId": objectPartId,
          "FaultCodeId": 0,
        },
      );

      debugPrint("Fetch Faults Response Status: ${response.statusCode}");
      debugPrint("Fetch Faults Response Body: ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final result = FailureDetailResponse.fromJson(jsonBody);
        if (result.responseCode == 200 && result.responseOutput != null) {
          final faults = result.responseOutput!.getFaultData ?? [];
          debugPrint("Found ${faults.length} faults");
          faultTypeList.assignAll(faults);
        } else {
          debugPrint("API Error: ${result.responseMessage}");
        }
      }
    } catch (e) {
      debugPrint("Error fetching faults: $e");
    } finally {
      isFaultLoading.value = false;
    }
  }

  Future<void> fetchEquipmentAndMeasurements(String funcId, String locationTypeId, {String? preselectedEquipmentId}) async {
    try {
      isEquipmentLoading.value = true;
      equipmentList.clear();
      measurementPointsList.clear();
      showMeasurementButton.value = false;

      final response = await _apiClient.get(
        "${AppUrls.getFunctionEqDetailsById}?funcId=$funcId&locationTypeId=$locationTypeId",
      );

      debugPrint("Fetch Equipment Response Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final result = FailureDetailResponse.fromJson(jsonBody);
        if (result.responseCode == 200 && result.responseOutput != null) {
          final output = result.responseOutput!;
          
          if (preselectedEquipmentId != null && preselectedEquipmentId != "0") {
            final matched = equipmentList.firstWhere(
                (e) => e.value?.toString().trim() == preselectedEquipmentId.trim(),
                orElse: () => LabelValue(label: null));
            if (matched.label != null) {
              selectedEquipmentNumber.value = matched.label;
            }
          }

          measurementPointsList.assignAll((output.measurementPoint ?? []).map((e) => {
            ...e,
            'beforeReading': '',
            'afterReading': '',
          }).toList());
          showMeasurementButton.value = measurementPointsList.isNotEmpty;
        }
      }
    } catch (e) {
      debugPrint("Error fetching equipment/measurements: $e");
    } finally {
      isEquipmentLoading.value = false;
    }
  }

  Future<void> fetchRootCauseAndAction(String objectCodeId, String faultCodeId) async {
    try {
      EasyLoading.show(status: 'Loading RCA options...');
      
      final requestBody = {
        "ObjectCodeId": objectCodeId,
        "FaultCodeId": faultCodeId
      };
      
      final response = await _apiClient.post(
        AppUrls.getRootCauseAndActionList,
        body: requestBody,
      );
      
      EasyLoading.dismiss();
      
      final jsonBody = jsonDecode(response.body);
      final result = FailureDetailResponse.fromJson(jsonBody);
      
      if (result.responseCode == 200 && result.responseOutput != null) {
        final output = result.responseOutput!;
        rootCauseList.assignAll(output.getRootCausetData ?? []);
        actionTakenList.assignAll(output.getActionData ?? []);
      } else {
        Get.snackbar("Error", result.responseMessage ?? "Failed to load RCA data");
      }
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint("Fetch RCA Error: $e");
    }
  }

  /// Station Controller create only. JE edit (Maintenance / Station / OCC / Depot) uses [updateFailure].
  Future<void> submitFailure({required bool isCreate}) async {
    if (isStation && isCreate) {
      await createStationFailure();
      return;
    }
    await updateFailure();
  }

  Future<void> createStationFailure() async {
    final description = failureDescriptionController.text.trim();
    if (description.isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Failure Description is required.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (selectedPriority.value == null || selectedPriority.value!.isEmpty) {
      Get.snackbar("Validation Error", "Priority is required.", backgroundColor: Colors.red.withOpacity(0.9), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedDepartment.value == null || selectedDepartment.value!.isEmpty) {
      Get.snackbar("Validation Error", "Department is required.", backgroundColor: Colors.red.withOpacity(0.9), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedLocation.value == null || selectedLocation.value!.isEmpty) {
      Get.snackbar("Validation Error", "Location is required.", backgroundColor: Colors.red.withOpacity(0.9), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedFailureOccurrenceDate.value == null) {
      Get.snackbar("Validation Error", "Actual Failure Occurrence is required.", backgroundColor: Colors.red.withOpacity(0.9), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedFailureCategoryType.value == null || selectedFailureCategoryType.value!.isEmpty) {
      Get.snackbar("Validation Error", "Failure Category Type is required.", backgroundColor: Colors.red.withOpacity(0.9), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      EasyLoading.show(status: 'Saving...');
      final createdBy = int.tryParse(await AuthManager().getUserId() ?? "0") ?? 0;
      final deptId = int.tryParse(
        departmentList.firstWhere((e) => e.label == selectedDepartment.value, orElse: () => LabelValue(value: "0")).value ?? "0",
      ) ?? Get.find<SessionController>().selectedDepartment.value?.deptId ?? 0;

      final body = {
        "Description": description,
        "PriorityType": selectedPriority.value,
        "DeptId": deptId,
        "LocationTypeId": int.tryParse(locationTypeList.firstWhere((e) => e.label == selectedLocation.value, orElse: () => LabelValue(value: "0")).value ?? "0") ?? 0,
        "FunctionLocationId": int.tryParse(functionalLocationList.firstWhere((e) => e.label == selectedFunctionalLocation.value, orElse: () => LabelValue(value: "0")).value ?? "0") ?? 0,
        "LocationFailure": subLocationController.text.trim(),
        "System": systemController.text.trim(),
        "TrainId": trainIdController.text.trim(),
        "ActualFailureOccuranceOn": DateFormat("dd/MM/yyyy HH:mm").format(selectedFailureOccurrenceDate.value!),
        "ActualFailureCompletedDate": selectedFailureCompletedDate.value != null
            ? DateFormat("dd/MM/yyyy HH:mm").format(selectedFailureCompletedDate.value!)
            : null,
        "AssignedUserId": int.tryParse(
          userList.firstWhere((e) => e.label == (selectedFailureReportedBy.value ?? selectedPersonResponsible.value), orElse: () => LabelValue(value: "0")).value ?? "0",
        ) ?? createdBy,
        "Corr_NotificationTypeId": int.tryParse(
          corrNotificationTypeList.firstWhere((e) => e.label == selectedFailureCategoryType.value, orElse: () => LabelValue(value: "0")).value ?? "0",
        ) ?? 0,
        "IsServiceAffected": isServiceAffected.value,
        "TrainDelayInMin": int.tryParse(trainDelayMinController.text) ?? 0,
        "TrainDelayInNo": int.tryParse(tripDelayUplineController.text) ?? int.tryParse(trainDelayNosController.text) ?? 0,
        "NoOfTranCancel": int.tryParse(trainCancelNosController.text) ?? 0,
        "NoOfTranWithdrawal": int.tryParse(trainWithdrawalNosController.text) ?? 0,
        "NoOfTrainReplace": int.tryParse(trainReplaceNosController.text) ?? 0,
        "IsPassengerDeboarding": isPassengerDeboarding.value,
        "NoofTrainDeboarded": int.tryParse(trainDeboardedNosController.text) ?? 0,
        "IsPassengerAffected": isPassengerAffected.value,
        "NoOfPassengerAffected": int.tryParse(passengersAffectedCountController.text),
        "TrappedDuration": trappedDurationController.text.trim().isEmpty ? null : trappedDurationController.text.trim(),
        "RescuedDuration": rescuedDurationController.text.trim().isEmpty ? null : rescuedDurationController.text.trim(),
        "CreatedBy": createdBy,
        "Category": failureCategory.value,
      };

      final response = await _apiClient.post(AppUrls.createStationFailure, body: body);
      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        if (jsonBody['responseCode'] == 200) {
          Get.back();
          Get.snackbar("Success", jsonBody['responseMessage'] ?? "Station failure created successfully");
        } else {
          Get.snackbar("Error", jsonBody['responseMessage'] ?? "Failed to create station failure");
        }
      } else {
        Get.snackbar("Error", "Failed to create station failure: ${response.body}");
      }
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint("Create Station Failure Error: $e");
      Get.snackbar("Error", "An unexpected error occurred");
    }
  }

  Future<void> updateFailure() async {
    try {
      // --- VALIDATION BLOCK ---
      
      // 1. Failure Rectification Details Compulsory
      if (failureRectificationDetailsController.text.trim().isEmpty) {
        Get.snackbar(
          "Validation Error", 
          "Failure Rectification Details is required.",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // 2. Under Observation Date Compulsory if status is "Under Observation"
      if (selectedUserStatus.value == "Under Observation") {
        if (selectedUnderObservationDate.value == null) {
          Get.snackbar(
            "Validation Error", 
            "Under Observation Date is required when status is 'Under Observation'.",
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      // 3. Used Quantity Fields Compulsory
      if (isSparePartReplaced.value) {
        if (replacedMaterialsList.isEmpty) {
          Get.snackbar(
            "Validation Error", 
            "Please add at least one Replaced Material since 'Spare Part Replaced' is enabled.",
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        for (var mat in replacedMaterialsList) {
          final usedQtyStr = mat['usedQty']?.toString().trim() ?? "";
          if (usedQtyStr.isEmpty) {
            Get.snackbar(
              "Validation Error", 
              "Used Quantity is required for all replaced materials.",
              backgroundColor: Colors.red.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
        }
      }

      // 4. RCA Fields Compulsory
      if (isRcaRequired.value) {
        if (rcaDetailsList.isEmpty) {
          Get.snackbar(
            "Validation Error", 
            "Please add at least one RCA detail.",
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        for (var rca in rcaDetailsList) {
          final objPart = rca['objectPart']?.toString().trim() ?? "";
          final objPartText = rca['objectPartText']?.toString().trim() ?? "";
          final fault = rca['fault']?.toString().trim() ?? "";
          final faultText = rca['faultText']?.toString().trim() ?? "";
          
          if (objPart.isEmpty && objPartText.isEmpty) {
            Get.snackbar(
              "Validation Error", 
              "Object Part is required in RCA details.",
              backgroundColor: Colors.red.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
          if (fault.isEmpty && faultText.isEmpty) {
            Get.snackbar(
              "Validation Error", 
              "Fault is required in RCA details.",
              backgroundColor: Colors.red.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
          
          final List rootCauses = rca['rootCauses'] ?? [];
          final List actionTakens = rca['actionTakens'] ?? [];
          
          if (rootCauses.isEmpty) {
            Get.snackbar(
              "Validation Error", 
              "At least one Root Cause is required in RCA details.",
              backgroundColor: Colors.red.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
          if (actionTakens.isEmpty) {
            Get.snackbar(
              "Validation Error", 
              "At least one Action Taken is required in RCA details.",
              backgroundColor: Colors.red.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
        }
      }
      
      // --- END OF VALIDATION ---

      EasyLoading.show(status: 'Updating...');

      final newJeRemark = failureDescriptionController.text.trim();

      final changeNotifictionJE = {
        "Id": encryptedId.value.isEmpty ? "0" : encryptedId.value,
        "Category": failureCategory.value,
        "Remark_JE": newJeRemark,
        "NatureOfWorkId": int.tryParse(natureOfWorkList.firstWhere((e) => e.label == selectedNatureOfWork.value, orElse: () => LabelValue(value: "0")).value ?? "0") ?? 0,
        "TrainRunningKM": trainRunningKmController.text.isEmpty ? null : trainRunningKmController.text,
        "NotificationTypeId": int.tryParse(notificationTypeList.firstWhere((e) => e.label == selectedNotificationType.value, orElse: () => LabelValue(value: "0")).value ?? "0") ?? 0,
        "FunctionLocationId": int.tryParse(functionalLocationList.firstWhere((e) => e.label == selectedFunctionalLocation.value, orElse: () => LabelValue(value: "0")).value ?? "0") ?? 0,
        "EquipmentId": int.tryParse(equipmentList.firstWhere((e) => e.label == selectedEquipmentNumber.value, orElse: () => LabelValue(value: "0")).value ?? "0") ?? 0,
        "PowerBlockRequired": isPowerBlockRequired.value,
        "SICRequired": isSicRequired.value,
        "SICFailureType": 0, // Need to map if available
        "SICResponsiblePerson": 0, // Need to map if available
        "PTWRequired": isPtwRequired.value,
        "PTWNo": ptwNumberController.text,
        "IsServiceAffected": isServiceAffected.value,
        "TrainDelayInMin": int.tryParse(trainDelayMinController.text) ?? 0,
        "TrainDelayInNo": int.tryParse(trainDelayNosController.text) ?? 0,
        "NoOfTranWithdrawal": int.tryParse(trainWithdrawalNosController.text) ?? 0,
        "NoOfTranCancel": int.tryParse(trainCancelNosController.text) ?? 0,
        "NoOfTrainReplace": int.tryParse(trainReplaceNosController.text) ?? 0,
        "IsPassengerDeboarding": isPassengerDeboarding.value,
        "NoofTrainDeboarded": int.tryParse(trainDeboardedNosController.text) ?? 0,
        "FailureAttendedDate": selectedFailureAttendedDate.value != null ? DateFormat("dd/MM/yyyy HH:mm").format(selectedFailureAttendedDate.value!) : null,
        "ActualFailureRectifiedDate": selectedActualFailureRectifiedDate.value != null ? DateFormat("dd/MM/yyyy HH:mm").format(selectedActualFailureRectifiedDate.value!) : null,
        "IsFailureRectifiDetails": isRcaRequired.value,
        "FailureType": selectedActualFailureRectified.value,
        "FailureTypeId": int.tryParse(selectedActualFailureRectified.value == "Yes" ? "1" : "2") ?? 2,
        "IsHardwareReplaced": isSparePartReplaced.value,
        "IsJointInspectionReq": isJointInspection.value,
        "FunctionLocation_JI": 0, // Map from joint inspection selections
        "EquipmentId_JI": 0,
        "UserStatus": int.tryParse(userStatusList.firstWhere((e) => e.label == selectedUserStatus.value, orElse: () => LabelValue(value: "0")).value ?? "0") ?? 0,
        "AssignedUserId": int.tryParse(userList.firstWhere((e) => e.label == selectedPersonResponsible.value, orElse: () => LabelValue(value: "0")).value ?? "0") ?? 0,
        "AssignedUserId_JI": int.tryParse(jointUserList.firstWhere((e) => e.label == selectedJointAssignTo.value, orElse: () => LabelValue(value: "0")).value ?? "0") ?? 0,
        "DeptId_JI": int.tryParse(departmentList.firstWhere((e) => e.label == selectedJointDept.value, orElse: () => LabelValue(value: "0")).value ?? "0") ?? 0,
        "CreatedBy": int.tryParse(await AuthManager().getUserId() ?? "0") ?? 0,
        "IsPassengerAffected": isPassengerAffected.value,
        "NoOfPassengerAffected": isPassengerAffected.value
            ? int.tryParse(passengersAffectedCountController.text)
            : null,
        "TrappedDuration": isPassengerAffected.value && trappedDurationController.text.trim().isNotEmpty
            ? trappedDurationController.text.trim()
            : null,
        "RescuedDuration": isPassengerAffected.value && rescuedDurationController.text.trim().isNotEmpty
            ? rescuedDurationController.text.trim()
            : null,
        "LocationTypeId": locationTypeList.firstWhere((e) => e.label == selectedLocation.value, orElse: () => LabelValue(value: "0")).value,
        "NotificationCode": notificationCode.value,
        "UnderObservationDate": selectedUnderObservationDate.value != null ? DateFormat("dd/MM/yyyy HH:mm").format(selectedUnderObservationDate.value!) : null,
        "FailureRectificationDetails": failureRectificationDetailsController.text.isEmpty ? "N/A" : failureRectificationDetailsController.text,
        "LocationFailure": subLocationController.text,
        "Corr_NotificationTypeId": int.tryParse(corrNotificationTypeList.firstWhere((e) => e.label == selectedNotificationType.value, orElse: () => LabelValue(value: "1")).value ?? "1") ?? 1,
        "ReasonForDelayId": 0
      };

      final payload = {
        "changeNotifictionJE": changeNotifictionJE,
        "materialRequiredDetails": isSparePartReplaced.value
            ? _materialsForSubmit().map(_buildMaterialPayload).toList()
            : <Map<String, dynamic>>[],
        "failureRectification": rcaDetailsList.map((e) => {
          "ObjectPartId": int.tryParse(e['ObjectPartId'].toString()) ?? 0,
          "ObjectPartText": e['objectPartText'] ?? "",
          "FaultId": int.tryParse(e['FaultId'].toString()) ?? 0,
          "FaultText": e['faultText'] ?? "",
          "RootCauseText": (e['rootCauses'] as List).isNotEmpty ? "${e['rootCauses'][0]['rootCauseId']}:${e['rootCauses'][0]['rootCauseText']}" : "",
          "ActionText": (e['actionTakens'] as List).isNotEmpty ? "${e['actionTakens'][0]['actionTakenId']}:${e['actionTakens'][0]['actionTakenText']}" : ""
        }).toList(),
        "getMeasurementPoints": measurementPointsList.map((e) => {
          "measId": e['measId'],
          "measPoint": e['measPoint'],
          "measPointDesc": e['measPointDesc'],
          "unitOfMeasurement": e['unitOfMeasurement'],
          "isRequired": e['isRequired'],
          "beforeReading": num.tryParse(e['beforeReading']?.toString() ?? "") ?? 0,
          "finalConfirmation": true,
          "afterReading": num.tryParse(e['afterReading']?.toString() ?? "") ?? 0
        }).toList(),
        "materialDismantleDetails": isMaterialDismantle.value
            ? dismantleMaterialsList.map((e) {
                final recordId = _materialRecordId(e);
                final statusId = recordId > 0 ? 2 : 1;
                return {
                  "MaterialId": e['materialId'] ?? e['MaterialId'] ?? _resolveMaterialId(e),
                  "MaterialValue": e['materialCode'] ?? "",
                  "MaterialReqId": recordId,
                  "OldSerialNumber": e['oldSerialNo'] ?? "",
                  "NewSerialNumber": e['newSerialNo'] ?? "",
                  "OldSerialNoDismantleDate": e['dismantleDateRaw'] ?? (e['dismantleDate'] != null ? "${e['dismantleDate'].day}/${e['dismantleDate'].month}/${e['dismantleDate'].year}" : ""),
                  "NewSerialNoInstallationDate": e['installationDateRaw'] ?? (e['installationDate'] != null ? "${e['installationDate'].day}/${e['installationDate'].month}/${e['installationDate'].year}" : ""),
                  "InsertUpdateStatusId": statusId,
                  "CurrentInsertUpdateStatusId": statusId,
                  "Id": recordId,
                };
              }).toList()
            : <Map<String, dynamic>>[]
      };

      final fields = {
        "ChangeNotifictionJEVM": jsonEncode(payload)
      };

      final List<http.MultipartFile> files = [];
      if (beforeFiles.isNotEmpty && beforeFiles.first['path'] != null && beforeFiles.first['isNetwork'] != true) {
        files.add(await http.MultipartFile.fromPath('beforeImage', beforeFiles.first['path']));
      }
      if (afterFiles.isNotEmpty && afterFiles.first['path'] != null && afterFiles.first['isNetwork'] != true) {
        files.add(await http.MultipartFile.fromPath('afterImage', afterFiles.first['path']));
      }
      if (rcaFiles.isNotEmpty && rcaFiles.first['path'] != null && rcaFiles.first['isNetwork'] != true) {
        files.add(await http.MultipartFile.fromPath('rcaImage', rcaFiles.first['path']));
      }

      final response = await _apiClient.postMultipart(
        AppUrls.updateChangeNotificationJE,
        fields: fields,
        files: files
      );
      final printStr = "fields===$fields";
      final pattern = RegExp('.{1,800}');
      pattern.allMatches(printStr).forEach((match) => print(match.group(0)));
      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        Get.back();
        Get.snackbar("Success", "Failure updated successfully");
      } else {
        print("response==+${response.body}");
        Get.snackbar("Error", "Failed to update failure: ${response.body}");
      }
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint("Update Error: $e");
      Get.snackbar("Error", "An unexpected error occurred");
    }
  }

  void updateMeasurementReading(int index, String field, String value) {
    var list = List<Map<String, dynamic>>.from(measurementPointsList);
    list[index][field] = value;
    measurementPointsList.assignAll(list);
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateFormat("dd/MM/yyyy HH:mm").parse(dateStr);
    } catch (e) {
      print("Error parsing date: $dateStr - $e");
      return null;
    }
  }
}
