import 'package:flutter/material.dart' hide Action;
import 'package:get/get.dart';
import 'package:http/http.dart' as http_pkg;
import 'package:get/get_connect/http/src/multipart/multipart_file.dart' as http;
import '../../../constants/colors.dart';
import '../../../constants/strings.dart';
import '../../../core/models/label_value.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../utils/widgets/cust_popup.dart';
import '../model/rst_failure_full_response.dart';
import '../../../service/local_database_service.dart';
import '../service/failure_service.dart';

class RstFailureController extends GetxController {
  final FailureService _failureService = FailureService();
  final LocalDatabaseService _dbService = LocalDatabaseService();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = "".obs;
  final Rx<RstFetchData?> rstFailureData = Rx<RstFetchData?>(null);
  final RxBool isViewOnly = true.obs;
// Attachments
  final beforeFiles = <Map<String, dynamic>>[].obs;   // BEFORE_NOT  → Part A (view-only)
  final afterFiles = <Map<String, dynamic>>[].obs;    // AFTER_NOT   → Part E
  final uploadRcaFiles = <Map<String, dynamic>>[].obs; // RCA_NOT    → Part E
  // RST Master Data Lists
  final RxList<LabelValue> rstFailureTypeList = <LabelValue>[].obs;
  final RxList<LabelValue> rstObjectPartList = <LabelValue>[].obs;
  final RxList<LabelValue> rstMaterialList = <LabelValue>[].obs;
  final RxList<LabelValue> rstTrainStatusList = <LabelValue>[].obs;
  
  // Master Data Lists from Local Storage
  final RxList<LabelValue> priorityList = <LabelValue>[].obs;
  final RxList<LabelValue> departmentList = <LabelValue>[].obs;
  final RxList<LabelValue> notificationTypeList = <LabelValue>[].obs;
  final RxList<LabelValue> functionalLocationList = <LabelValue>[].obs;
  final RxList<LabelValue> equipmentList = <LabelValue>[].obs;
  final RxList<LabelValue> natureOfWorkList = <LabelValue>[].obs;
  
  // Cascading Filter Lists for Functional Location
  final RxList<LabelValue> planningPlantList = <LabelValue>[].obs;
  final RxList<LabelValue> trainSetNoList = <LabelValue>[].obs;
  final RxList<LabelValue> roomList = <LabelValue>[].obs;
  final RxList<LabelValue> systemList = <LabelValue>[].obs;
  final selectedPlanningPlant = RxnString();
  final selectedTrainSetNoFilter = RxnString();
  final selectedRoomFilter = RxnString();
  final selectedSystemFilter = RxnString();
  // Expansion States
  final isPartAExpanded = true.obs;
  final isPartBExpanded = true.obs;
  final isPartCExpanded = true.obs;
  final isPartDExpanded = true.obs;
  final isPartEExpanded = true.obs;
  final isPartFExpanded = true.obs;

  // Part A Fields
  final selectedPriority = RxnString();
  final selectedDepartment = RxnString();
  final selectedNotificationType = RxnString();
  final selectedFailureType = RxnString();
  final failureDescriptionController = TextEditingController();
  final searchLocationController = TextEditingController();
  final selectedLine = RxnString();
  final selectedTrainSetNo = RxnString();
  final selectedRoom = RxnString();
  final selectedSystem = RxnString();
  final selectedFunctionalLocation = RxnString();
  final selectedEquipmentName = RxnString();
  final selectedNatureOfWork = RxnString();
  final selectedNatureOfWorkId = RxnString();
  final selectedDoNotReport = RxnString();
  
  // Service Affected Fields
  final isServiceAffected = false.obs;
  final trainDelayInMinController = TextEditingController();
  final trainDelayInNoController = TextEditingController();
  final noOfTrainCancelController = TextEditingController();
  final noOfTrainWithdrawalController = TextEditingController();

  // Notification History
  final Rx<Map<String, dynamic>?> notificationHistory = Rx<Map<String, dynamic>?>(null);
  final noOfTrainReplaceController = TextEditingController();
  final isPassengerDeboarding = false.obs;
  final noOfTrainDeboardedController = TextEditingController();
  final isTrainReplace = false.obs;
  
  // Main Line Fault Fields (for WorkNatureId == 10)
  final locationOfFailureController = TextEditingController();
  final actualFailureOccuranceOn = Rxn<DateTime>();
  final mainLineActionTakenByController = TextEditingController();
  final trainOperatorNameController = TextEditingController();
  final mainLineActionController = TextEditingController();
  

  // Part B Fields
  final selectedResponsiblePerson = RxnString();
  final trainRunningKmController = TextEditingController();
  
  final isSicType = false.obs;
  final selectedSicType = RxnString();
  final selectedSicResponsiblePerson = RxnString();
  final sicTypeList = <Map<String, String>>[].obs;

  final isJointInspection = false.obs;
  final selectedJointInspectionDept = RxnString();
  final selectedJointInspectionResponsiblePerson = RxnString();
  final jointInspectionRemarksController = TextEditingController();
  final jointInspectionList = <Map<String, String>>[].obs;
  
  // Handlers for Add Buttons
  void addSicType() {
    if (selectedSicType.value != null && selectedSicResponsiblePerson.value != null) {
      sicTypeList.add({
        "sicType": selectedSicType.value!,
        "responsiblePerson": selectedSicResponsiblePerson.value!,
      });
      selectedSicType.value = null;
      selectedSicResponsiblePerson.value = null;
    } else {
      Get.snackbar("Error", "Please select SIC Type and Responsible Person",backgroundColor: AppColors.red,colorText: AppColors.white1);
    }
  }

  void removeSicType(int index) {
    sicTypeList.removeAt(index);
  }

  void addJointInspection() {
    if (selectedJointInspectionDept.value != null && selectedJointInspectionResponsiblePerson.value != null) {
      jointInspectionList.add({
        "department": selectedJointInspectionDept.value!,
        "responsiblePerson": selectedJointInspectionResponsiblePerson.value!,
        "remarks": jointInspectionRemarksController.text,
      });
      selectedJointInspectionDept.value = null;
      selectedJointInspectionResponsiblePerson.value = null;
      jointInspectionRemarksController.clear();
    } else {
      Get.snackbar("Error", "Please select Department and Responsible Person",backgroundColor: AppColors.red,colorText: AppColors.white1);
    }
  }

  void removeJointInspection(int index) {
    jointInspectionList.removeAt(index);
  }


  List<Map<String, dynamic>> _newlyPickedFiles(List<Map<String, dynamic>> list) {
    return list.where((f) => (f['id'] == null || f['id'] == '0') && (f['path']?.toString().isNotEmpty ?? false)).toList();
  }

  Future<List<http_pkg.MultipartFile>> _buildMultipartFiles(
      List<Map<String, dynamic>> files,
      String fieldName,
      ) async {
    final result = <http_pkg.MultipartFile>[];
    for (final f in files) {
      final path = f['path']?.toString() ?? '';
      if (path.isEmpty) continue;
      result.add(await http_pkg.MultipartFile.fromPath(
        fieldName,
        path,
        filename: f['name']?.toString(),
      ));
    }
    return result;
  }

  void _populateDocuments(List<dynamic> raw) {
    beforeFiles.clear();
    afterFiles.clear();
    uploadRcaFiles.clear();

    for (final doc in raw) {
      final map = doc as Map<String, dynamic>;

      final String docType =
      (map['documentType'] ?? '').toString().toUpperCase();

      final String fileName =
      (map['fileName'] ?? '').toString();

      final fileEntry = {
        'id': map['id']?.toString() ?? '0',
        'name': fileName.split('/').last,
        'size': map['fileSize']?.toString() ?? '',
        'url': "${AppUrls.imageUrl}$fileName",
        'path': '',
        'isNetwork': true,
      };

      if (docType == "BEFORE_NOT") {
        beforeFiles.add(fileEntry);
      } else if (docType == "AFTER_NOT") {
        afterFiles.add(fileEntry);
      } else if (docType == "RCA_NOT") {
        uploadRcaFiles.add(fileEntry);
      }
    }

    debugPrint("Before Images : ${beforeFiles.length}");
    debugPrint("After Images  : ${afterFiles.length}");
    debugPrint("RCA Images    : ${uploadRcaFiles.length}");
  }
  // --- Part C Fields ---
  final isAcceptResponsibility = false.obs;
  final isPowerBlockRequired = false.obs;
  final isOHEReq = false.obs;
  final selectedMaintainerName = RxnString();
  final workAllotedController = TextEditingController();
// Part C - Work Alloted list (was missing entirely)
  final workAllotedList = <Map<String, String>>[].obs;


  // --- Part D Fields ---
  final selectedPartDFailureType = RxnString();
  final isFailureRectification = false.obs;
  final selectedObjectPart = RxnString();
  final selectedFault = RxnString();
  final objectPartTextController = TextEditingController();
  final faultTextController = TextEditingController();
  final faultList = <Map<String, String>>[].obs;
  final faultDropdownList = <LabelValue>[].obs;
  final isFaultLoading = false.obs;
  final activityCarriedOutController = TextEditingController();
  
  // RCA and Action lists
  final rootCauseList = <LabelValue>[].obs;
  final actionTakenList = <LabelValue>[].obs;
  final selectedRootCause = RxnString();
  final selectedActionTaken = RxnString();
  
  // RCA popup variables
  final popupRootCauseTextController = TextEditingController();
  final popupActionTakenTextController = TextEditingController();
  final popupRootCauseFiles = <Map<String, dynamic>>[].obs;
  final popupActionTakenFiles = <Map<String, dynamic>>[].obs;
  final tempPopupRootCauses = <Map<String, dynamic>>[].obs;
  final tempPopupActionTakens = <Map<String, dynamic>>[].obs;
  final selectedPopupRootCause = RxnString();
  final selectedPopupActionTaken = RxnString();
  final isExpandedRca = <int, bool>{}.obs;
  final rcaDetailsList = <Map<String, dynamic>>[].obs;
  final selectedPopupRootCauseOther = RxnString();
  final selectedPopupActionTakenOther = RxnString();
  
  final isMaterialRequired = false.obs;
  final selectedMaterialCode = RxnString();
  final selectedStoreLocation = RxnString();
  final requiredQuantityController = TextEditingController();
  final storageLocationList = <LabelValue>[].obs;

  final isMaterialDismantle = false.obs;
  final selectedDismantleMaterialCode = RxnString();
  final oldSerialNumberController = TextEditingController();
  final newSerialNumberController = TextEditingController();
  final oldSerialDismantleDate = Rxn<DateTime>();       // ✅ changed from RxnString
  final newSerialInstallationDate = Rxn<DateTime>();    // ✅ changed from RxnString
  final editingDismantleMaterialIndex = (-1).obs;

  void addFault() {
    if (selectedObjectPart.value != null && selectedFault.value != null) {
      final objectPartId = selectedObjectPart.value == "Other"
          ? "0"
          : (rstObjectPartList.firstWhereOrNull((e) => e.label == selectedObjectPart.value)?.value ?? "0");
      final faultId = selectedFault.value == "Other"
          ? "0"
          : (faultDropdownList.firstWhereOrNull((e) => e.label == selectedFault.value)?.value ?? "0");

      final objectPartText = selectedObjectPart.value == "Other" ? objectPartTextController.text : '';
      final faultText = selectedFault.value == "Other" ? faultTextController.text : '';

      faultList.add({
        "objectPart": selectedObjectPart.value!,
        "objectPartId": objectPartId,      // ✅ store real ID now
        "objectPartText": objectPartText,
        "fault": selectedFault.value!,
        "faultId": faultId,                // ✅ store real ID now
        "faultText": faultText,
      });

      selectedObjectPart.value = null;
      selectedFault.value = null;
      objectPartTextController.clear();
      faultTextController.clear();
    } else {
      Get.snackbar("Error", "Please select Object Part and Fault",backgroundColor: AppColors.red,colorText: AppColors.white1);
    }
  }

  void removeFault(int index) {
    faultList.removeAt(index);
  }

  /// Fetch faults when Object Part is changed
  Future<void> fetchFaults(String objectPartId) async {
    try {
      isFaultLoading.value = true;
      faultDropdownList.clear();
      final faults = await _failureService.getFaults(objectPartId);
      faultDropdownList.assignAll(faults);
    } catch (e) {
      debugPrint('fetchFaults error: $e');
    } finally {
      isFaultLoading.value = false;
    }
  }

  /// Fetch RCA and Action when fault is selected
  Future<void> fetchRootCauseAndAction(String objectCodeId, String faultCodeId) async {
    try {
      final data = await _failureService.getRootCauseAndAction(objectCodeId, faultCodeId);
      rootCauseList.assignAll(data.rootCauses);
      actionTakenList.assignAll(data.actionTaken);
    } catch (e) {
      debugPrint('fetchRootCauseAndAction error: $e');
    }
  }

  // Add near other Part D RxStrings:
  final uomController = TextEditingController();
  final balanceQtyController = TextEditingController();

  Future<void> fetchMCDRequiredQuantity(int objectCodeId, int faultCodeId) async {
    try {
      final data = await _failureService.getMCDRequiredQuantity(objectCodeId, faultCodeId);
      uomController.text = data['baseUnitOfMeasure']?.toString() ?? ''; // ✅
    } catch (e) {
      debugPrint('fetchMCDRequiredQuantity error: $e');
      uomController.text = '';
    }
  }

  Future<void> fetchMaterialBalancedQty(int materialId, int storageLocationId) async {
    try {
      final userId = await _failureService.getUserId();
      final data = await _failureService.getMaterialBalancedQty(materialId, storageLocationId, userId);
      balanceQtyController.text = data['balancedData']?.toString() ?? ''; // ✅
    } catch (e) {
      debugPrint('fetchMaterialBalancedQty error: $e');
      balanceQtyController.text = '';
    }
  }// RCA Methods

  void toggleRcaExpansion(int index) {
    isExpandedRca[index] = !(isExpandedRca[index] ?? false);
  }

  void addToTempRootCauses() {
    if (selectedPopupRootCause.value != null) {
      final isOther = selectedPopupRootCause.value == "Other";
      final rootCauseText = isOther ? popupRootCauseTextController.text : '';

      tempPopupRootCauses.add({
        'rootCause': selectedPopupRootCause.value,
        'rootCauseText': rootCauseText,
        'imagePath': popupRootCauseFiles.isNotEmpty ? popupRootCauseFiles.first['path'] : null,
      });
      selectedPopupRootCause.value = null;
      popupRootCauseTextController.clear();
      popupRootCauseFiles.clear();
    } else {
      Get.snackbar("Error", "Please select Root Cause",backgroundColor: AppColors.red,colorText: AppColors.white1);
    }
  }

  void addToTempActionTakens() {
    if (selectedPopupActionTaken.value != null) {
      final isOther = selectedPopupActionTaken.value == "Other";
      final actionTakenText = isOther ? popupActionTakenTextController.text : '';

      tempPopupActionTakens.add({
        'actionTaken': selectedPopupActionTaken.value,
        'actionTakenText': actionTakenText,
        'imagePath': popupActionTakenFiles.isNotEmpty ? popupActionTakenFiles.first['path'] : null,
      });
      selectedPopupActionTaken.value = null;
      popupActionTakenTextController.clear();
      popupActionTakenFiles.clear();
    } else {
      Get.snackbar("Error", "Please select Action Taken",backgroundColor: AppColors.red,colorText: AppColors.white1);
    }
  }

  void clearPopupState() {
    selectedPopupRootCause.value = null;
    selectedPopupActionTaken.value = null;
    popupRootCauseTextController.clear();
    popupActionTakenTextController.clear();
    popupRootCauseFiles.clear();
    popupActionTakenFiles.clear();
    tempPopupRootCauses.clear();
    tempPopupActionTakens.clear();
  }

  void savePopupDataToRca(int faultIndex) {
    if (faultIndex < faultList.length) {
      final fault = faultList[faultIndex];
      final existingIndex = rcaDetailsList.indexWhere(
            (r) => r['objectPart'] == fault['objectPart'] && r['fault'] == fault['fault'],
      );

      if (existingIndex >= 0) {
        final existing = Map<String, dynamic>.from(rcaDetailsList[existingIndex]);
        final updatedRootCauses = List<Map<String, dynamic>>.from(existing['rootCauses'] ?? [])
          ..addAll(tempPopupRootCauses);
        final updatedActionTakens = List<Map<String, dynamic>>.from(existing['actionTakens'] ?? [])
          ..addAll(tempPopupActionTakens);

        existing['rootCauses'] = updatedRootCauses;
        existing['actionTakens'] = updatedActionTakens;

        rcaDetailsList[existingIndex] = existing; // ✅ triggers RxList notify
        isExpandedRca[existingIndex] = true;
      } else {
        rcaDetailsList.add({
          'objectPart': fault['objectPart'],
          'objectPartText': fault['objectPartText'] ?? '',
          'fault': fault['fault'],
          'faultText': fault['faultText'] ?? '',
          'rootCauses': List<Map<String, dynamic>>.from(tempPopupRootCauses),
          'actionTakens': List<Map<String, dynamic>>.from(tempPopupActionTakens),
        });
        isExpandedRca[rcaDetailsList.length - 1] = true;
      }

      tempPopupRootCauses.clear();
      tempPopupActionTakens.clear();
    }
  }
  void removeRootCauseFromRca(int rcaIndex, int rootCauseIndex) {
    if (rcaIndex < rcaDetailsList.length) {
      final rootCauses = rcaDetailsList[rcaIndex]['rootCauses'] as List<Map<String, dynamic>>;
      rootCauses.removeAt(rootCauseIndex);
    }
  }

  void removeActionTakenFromRca(int rcaIndex, int actionIndex) {
    if (rcaIndex < rcaDetailsList.length) {
      final actionTakens = rcaDetailsList[rcaIndex]['actionTakens'] as List<Map<String, dynamic>>;
      actionTakens.removeAt(actionIndex);
    }
  }

  void saveRcaDetails(int faultIndex) {
    if (faultIndex < faultList.length) {
      final fault = faultList[faultIndex];
      rcaDetailsList.add({
        'objectPart': fault['objectPart'],
        'fault': fault['fault'],
        'rootCauses': List<Map<String, dynamic>>.from(tempPopupRootCauses),
        'actionTakens': List<Map<String, dynamic>>.from(tempPopupActionTakens),
      });
      tempPopupRootCauses.clear();
      tempPopupActionTakens.clear();
      isExpandedRca[rcaDetailsList.length - 1] = true;
    }
  }

  void removeRcaDetail(Map<String, dynamic> item) {
    rcaDetailsList.remove(item);
  }

  void toggleMaterialExpansion(int index) {
    isExpandedMaterial[index] = !(isExpandedMaterial[index] ?? false);
  }


  void removeMaterialRequired(int index) {
    materialRequiredList.removeAt(index);
  }

  // --- Dismantle Material ---
  final dismantleMaterialList = <Map<String, String>>[].obs;
  final isExpandedDismantle = <int, bool>{}.obs;

  void toggleDismantleExpansion(int index) {
    isExpandedDismantle[index] = !(isExpandedDismantle[index] ?? false);
  }

  DateTime? _parseDdMmYyyy(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('/');
    if (parts.length != 3) return null;
    return DateTime(
      int.tryParse(parts[2]) ?? DateTime.now().year,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[0]) ?? 1,
    );
  }

  void addDismantleMaterial() {
    if (selectedDismantleMaterialCode.value == null ||
        oldSerialNumberController.text.trim().isEmpty ||
        oldSerialDismantleDate.value == null ||
        newSerialNumberController.text.trim().isEmpty ||
        newSerialInstallationDate.value == null) {
      Get.snackbar("Error", "Please fill all required fields",backgroundColor: AppColors.red,colorText: AppColors.white1);
      return;
    }

    final materialMatch = rstMaterialList.firstWhereOrNull((m) => m.label == selectedDismantleMaterialCode.value);

    final newItem = {
      'id': '0',
      'materialId': materialMatch?.value ?? '0',
      'materialReqId': '0',
      'materialCode': selectedDismantleMaterialCode.value!,
      'oldSerial': oldSerialNumberController.text,
      'oldDismantleDate':
      "${oldSerialDismantleDate.value!.day}/${oldSerialDismantleDate.value!.month}/${oldSerialDismantleDate.value!.year}",
      'newSerial': newSerialNumberController.text,
      'newInstallDate':
      "${newSerialInstallationDate.value!.day}/${newSerialInstallationDate.value!.month}/${newSerialInstallationDate.value!.year}",
    };

    if (editingDismantleMaterialIndex.value >= 0) {
      final index = editingDismantleMaterialIndex.value;
      final existing = dismantleMaterialList[index];
      dismantleMaterialList[index] = {
        ...newItem,
        'id': existing['id'] ?? '0',
        'materialReqId': existing['materialReqId'] ?? '0',
      };
      dismantleMaterialList.refresh();
      editingDismantleMaterialIndex.value = -1;
    } else {
      dismantleMaterialList.add(newItem);
    }

    // Reset
    selectedDismantleMaterialCode.value = null;
    oldSerialNumberController.clear();
    newSerialNumberController.clear();
    oldSerialDismantleDate.value = null;
    newSerialInstallationDate.value = null;
  }

  void startEditDismantleMaterial(int index) {
    final item = dismantleMaterialList[index];
    editingDismantleMaterialIndex.value = index;
    selectedDismantleMaterialCode.value = item['materialCode'];
    oldSerialNumberController.text = item['oldSerial'] ?? '';
    newSerialNumberController.text = item['newSerial'] ?? '';
    oldSerialDismantleDate.value = _parseDdMmYyyy(item['oldDismantleDate']);
    newSerialInstallationDate.value = _parseDdMmYyyy(item['newInstallDate']);
  }

  void cancelEditDismantleMaterial() {
    editingDismantleMaterialIndex.value = -1;
    selectedDismantleMaterialCode.value = null;
    oldSerialNumberController.clear();
    newSerialNumberController.clear();
    oldSerialDismantleDate.value = null;
    newSerialInstallationDate.value = null;
  }

  void removeDismantleMaterial(int index) {
    dismantleMaterialList.removeAt(index);
    if (editingDismantleMaterialIndex.value == index) {
      cancelEditDismantleMaterial();
    } else if (editingDismantleMaterialIndex.value > index) {
      editingDismantleMaterialIndex.value--;
    }
  }

  // --- Part E Fields ---
  final isPersonsWithdrawn = false.obs;
  final actualWorkStart = Rxn<DateTime>();
  final actualWorkComplete = Rxn<DateTime>();
  final selectedTrainStatus = RxnString();

  // --- Part F Fields ---
  final isSicPerformed = false.obs;
  final isFollowUpActionCompleted = false.obs;
  final sicChecklistRemarkController = TextEditingController();
  final isEquipmentLockingExpanded = true.obs;
  final isDmrChecked = false.obs;
  final isTcChecked = false.obs;
  final isTmbChecked = false.obs;
  final checklistRemarkController = TextEditingController();

  Future<void> fetchRstFailureData(int notificationId) async {
    debugPrint("fetchRstFailureData: CALLED with notificationId=$notificationId");
    isLoading.value = true;
    errorMessage.value = "";
    debugPrint("fetchRstFailureData: Starting fetch for notificationId=$notificationId");

    try {
      debugPrint("fetchRstFailureData: Loading master data from DB...");
      await _loadRstMasterDataFromDb();
      debugPrint("fetchRstFailureData: Master data loaded");
      
      debugPrint("fetchRstFailureData: Calling getRstFailureFullData API...");
      final fullData = await _failureService.getRstFailureFullData(notificationId);
      debugPrint("fetchRstFailureData: API data received, rstFetchData=${fullData.rstFetchData.notificationId}");

      // Populate notification history
      if (fullData.notificationHistory != null) {
        notificationHistory.value = fullData.notificationHistory!.toJson();
        debugPrint("fetchRstFailureData: Notification history populated");
      }

      debugPrint("fetchRstFailureData: Parsing RstFetchData...");
      final data = RstFetchData.fromJson(fullData.rstFetchData.toJson());
      rstFailureData.value = data;
      debugPrint("fetchRstFailureData: RstFetchData parsed, description=${data.description}");
      
      debugPrint("fetchRstFailureData: Populating fields...");
      _populateFieldsFromData(data);
      debugPrint("fetchRstFailureData: Fields populated");

      debugPrint("fetchRstFailureData: Populating joint inspections...");
      _populateJointInspections(fullData.jointInspections);
      debugPrint("fetchRstFailureData: Joint inspections hydrated, count=${jointInspectionList.length}");
      
      debugPrint("fetchRstFailureData: Populating work alloted users...");
      _populateWorkAllotedUsers(fullData.workAllotedUsers);
      debugPrint("fetchRstFailureData: Work alloted users hydrated, count=${workAllotedList.length}");
      
      debugPrint("fetchRstFailureData: Populating rectification details...");
      _populateRectificationDetails(fullData.rectificationDetails);
      debugPrint("fetchRstFailureData: Rectification details hydrated, count=${faultList.length}");
      
      debugPrint("fetchRstFailureData: Populating actions and root causes...");
      _populateActionsAndRootCauses(fullData.rectificationDetails, fullData.actions, fullData.rootCauses);
      debugPrint("fetchRstFailureData: Actions and root causes hydrated, count=${rcaDetailsList.length}");

      // isFailureRectifiDetails isn't always present in the response.
      // If there's actual fault/rectification data, show the section regardless.
      if (fullData.rectificationDetails.isNotEmpty) {
        isFailureRectification.value = true;
        debugPrint("fetchRstFailureData: Set isFailureRectification=true");
      }

      debugPrint("fetchRstFailureData: Populating materials required...");
      _populateMaterialsRequired(fullData.materials);
      debugPrint("fetchRstFailureData: Materials required hydrated, count=${materialRequiredList.length}");
      
      debugPrint("fetchRstFailureData: Populating materials swapped...");
      _populateMaterialsSwapped(fullData.materialSerialNumbers);
      debugPrint("fetchRstFailureData: Materials swapped hydrated, count=${dismantleMaterialList.length}");
      
      debugPrint("fetchRstFailureData: Populating assignment history...");
      _populateAssignmentHistory(fullData.assignmentHistory);
      debugPrint("fetchRstFailureData: Assignment history hydrated, count=${assignmentHistoryList.length}");

      debugPrint("fetchRstFailureData: Populating documents...");
      debugPrint("fetchRstFailureData: Raw documents=${fullData.documents}");
      _populateDocuments(fullData.documents);
      debugPrint("fetchRstFailureData: Documents hydrated, beforeFiles=${beforeFiles.length}, afterFiles=${afterFiles.length}, uploadRcaFiles=${uploadRcaFiles.length}");
      debugPrint("fetchRstFailureData: All data hydrated successfully");
    } catch (e, stackTrace) {
      debugPrint("fetchRstFailureData: ERROR - $e");
      debugPrint("fetchRstFailureData: STACK TRACE - $stackTrace");
      errorMessage.value = "Error: ${e.toString()}";
    } finally {
      isLoading.value = false;
      debugPrint("fetchRstFailureData: Loading complete, isLoading=false");
    }
  }

  Future<void> submitPartE() async {
    final notificationId = rstFailureData.value?.notificationId;
    if (notificationId == null) {
      Get.snackbar("Error", "Missing notification Id",backgroundColor: AppColors.red,colorText: AppColors.white1);
      return;
    }
    if (!isPersonsWithdrawn.value) {
      Get.snackbar("Error", "Please confirm the declaration",backgroundColor: AppColors.red,colorText: AppColors.white1);
      return;
    }
    if (actualWorkStart.value == null) {
      Get.snackbar("Error", "Please select Actual Work Start",backgroundColor: AppColors.red,colorText: AppColors.white1);
      return;
    }
    if (actualWorkComplete.value == null) {
      Get.snackbar("Error", "Please select Actual Work Complete",backgroundColor: AppColors.red,colorText: AppColors.white1);
      return;
    }
    if (selectedTrainStatus.value == null) {
      Get.snackbar("Error", "Please select Train Status",backgroundColor: AppColors.red,colorText: AppColors.white1);
      return;
    }

    final trainStatusMatch = rstTrainStatusList.firstWhereOrNull(
          (e) => e.label == selectedTrainStatus.value,
    );
    final trainStatusId = trainStatusMatch?.value ?? '0';

    try {
      isLoading.value = true;

      final afterMultipart = await _buildMultipartFiles(_newlyPickedFiles(afterFiles), 'afterImage');
      final rcaMultipart = await _buildMultipartFiles(_newlyPickedFiles(uploadRcaFiles), 'rcaImage');

      final msg = await _failureService.updateRstNotificationCompletion(
        notificationId: notificationId,
        trainStatusId: trainStatusId,
        actualWorkStart: actualWorkStart.value!,
        actualWorkComplete: actualWorkComplete.value!,
        afterImages: afterMultipart,
        rcaImages: rcaMultipart,
      );

      Get.snackbar("Success", msg,);
      await fetchRstFailureData(notificationId); // refreshes documents list with real ids/paths from server
    } catch (e) {
      Get.snackbar("Error", e.toString(),backgroundColor: AppColors.red,colorText: AppColors.white1);
    } finally {
      isLoading.value = false;
    }
  }

  void _populateJointInspections(List<JointInspection> raw) {
    jointInspectionList.assignAll(raw.map((e) => {
      'department': e.jI_Dept_Name,
      'responsiblePerson': e.jI_ResponsiblePerson,
      'remark': e.jI_Remark ?? '',
      'status': e.jI_Status,
      'statusId': e.jI_StatusId.toString(),
    }));
  }

  void _populateWorkAllotedUsers(List<WorkAllotedUser> raw) {
    workAllotedList.assignAll(raw.map((e) => {
      'id': e.id.toString(),                       // real DB id from server
      'name': e.maintainerUserName,
      'maintainerUserId': e.maintainerUserId.toString(),
      'workAlloted': e.workAllotedName,
      'workAllotedId': e.workAllotedId.toString(),
    }));
  }

  void _populateRectificationDetails(List<RectificationDetail> raw) {
    faultList.assignAll(raw.map((e) => {
      'objectPart': e.objectName ?? '',
      'objectPartId': e.objectPartId.toString(),
      'objectPartText': e.objectPartText ?? '',
      'fault': e.faultName ?? '',
      'faultId': e.faultId.toString(),
      'faultText': e.faultText ?? '',
    }));
  }

  final RxList<LabelValue> maintainerUserList = <LabelValue>[].obs;

  List<String> get maintainerUserStrings =>
      maintainerUserList.map((e) => e.label ?? '').where((e) => e.isNotEmpty).toList();

  String? get _selectedMaintainerUserId {
    final match = maintainerUserList.firstWhereOrNull((e) => e.label == selectedMaintainerName.value);
    return match?.value;
  }
  Future<void> _loadMaintainerUsers() async {
    final users = (await LocalDatabaseService().getMasterUsers())
        .map((e) => e.toJson())
        .toList();

    // Defensive key lookup — adjust once you confirm the actual field names
    // in master_user.dart (dept id / role id column names).
    String? _val(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        if (m[k] != null) return m[k].toString();
      }
      return null;
    }

    final filtered = users.where((u) {
      final deptId = _val(u, ['deptId', 'departmentId', 'DeptId', 'DepartmentId']);
      final roleId = _val(u, ['roleId', 'userRoleId', 'RoleId', 'UserRoleId']);
      return deptId == '3' && roleId == '5';
    }).toList();

    maintainerUserList.assignAll(
      filtered
          .where((e) => (e['userName']?.toString() ?? '').isNotEmpty)
          .map((e) => LabelValue(
        label: e['userName']?.toString() ?? '',
        value: e['userId']?.toString() ?? '',
      )),
    );
  }

  void addWorkAlloted() {
    if (selectedMaintainerName.value != null && workAllotedController.text.isNotEmpty) {
      workAllotedList.add({
        'id': '0', // new entry, not yet persisted
        'name': selectedMaintainerName.value!,
        'maintainerUserId': _selectedMaintainerUserId ?? '0',
        'workAlloted': workAllotedController.text,
        'workAllotedId': '0',
      });
      selectedMaintainerName.value = null;
      workAllotedController.clear();
    } else {
      Get.snackbar("Error", "Please select Name and enter Work Alloted",backgroundColor: AppColors.red,colorText: AppColors.white1);
    }
  }


  // --- Material Required (extended) ---
  final materialRequiredList = <Map<String, String>>[].obs;
  final isExpandedMaterial = <int, bool>{}.obs;
  final editingMaterialRequiredIndex = (-1).obs;
  final usedQtyControllers = <int, TextEditingController>{};
  final usedQtyFocusNodes = <int, FocusNode>{};

  void addMaterialRequired() {
    // Check for duplicate material
    final isDuplicate = materialRequiredList.any((item) =>
        item['materialCode'] == selectedMaterialCode.value &&
        item['storeLocation'] == selectedStoreLocation.value
    );
    
    if (isDuplicate && editingMaterialRequiredIndex.value < 0) {
      Get.snackbar("Duplicate", "Selected material already exists!",backgroundColor: AppColors.red,colorText: AppColors.white1);
      return;
    }

    final materialMatch = rstMaterialList.firstWhereOrNull((m) => m.label == selectedMaterialCode.value);
    final storeLocMatch = storageLocationList.firstWhereOrNull((s) => s.label == selectedStoreLocation.value);

    final newItem = <String, String>{
      'id': '0',
      'materialId': materialMatch?.value ?? '0',
      'materialCode': selectedMaterialCode.value!,
      'storeLocationId': storeLocMatch?.value ?? '0',
      'storeLocation': selectedStoreLocation.value!,
      'requiredQty': requiredQuantityController.text,
      'balanceQty': balanceQtyController.text.isNotEmpty ? balanceQtyController.text : '0.00',
      'uom': uomController.text,
      'usedQty': '',
    };

    if (editingMaterialRequiredIndex.value >= 0) {
      final index = editingMaterialRequiredIndex.value;
      final existing = materialRequiredList[index];
      materialRequiredList[index] = {
        ...newItem,
        'id': existing['id'] ?? '0',
        'usedQty': existing['usedQty'] ?? '',
      };
      materialRequiredList.refresh();
      editingMaterialRequiredIndex.value = -1;
    } else {
      materialRequiredList.add(newItem);
    }
    // Reset
    selectedMaterialCode.value = null;
    selectedStoreLocation.value = null;
    requiredQuantityController.clear();
    uomController.clear();
    balanceQtyController.clear();
  }

  void startEditMaterialRequired(int index) {
    final item = materialRequiredList[index];
    editingMaterialRequiredIndex.value = index;
    selectedMaterialCode.value = item['materialCode'];
    selectedStoreLocation.value = item['storeLocation'];
    requiredQuantityController.text = item['requiredQty'] ?? '';
    uomController.text = item['uom'] ?? '';
    balanceQtyController.text = item['balanceQty'] ?? '';
  }

  void cancelEditMaterialRequired() {
    editingMaterialRequiredIndex.value = -1;
    selectedMaterialCode.value = null;
    selectedStoreLocation.value = null;
    requiredQuantityController.clear();
    uomController.clear();
    balanceQtyController.clear();
  }

  /// ✅ #5-equivalent for RST — validates every item's Used Qty at once.
  /// Call this from the Part D "Submit" button.
  bool validateMaterialRequiredUsedQty() {
    List<int> errorIndices = [];
    for (int i = 0; i < materialRequiredList.length; i++) {
      final item = materialRequiredList[i];
      final usedQty = int.tryParse(item['usedQty'] ?? '0') ?? 0;
      final requiredQty = int.tryParse(item['requiredQty'] ?? '0') ?? 0;
      if (usedQty > requiredQty) {
        errorIndices.add(i);
        isExpandedMaterial[i] = true;
      }
    }
    if (errorIndices.isNotEmpty) {
      final msg = errorIndices.length > 1
          ? 'Used Quantity cannot be greater than Required Quantity for ${errorIndices.length} items.'
          : 'Used Quantity cannot be greater than Required Quantity.';
      Get.snackbar("Invalid Quantity", msg,
          backgroundColor: Colors.red.withOpacity(0.9), colorText: Colors.white);
      return false;
    }
    return true;
  }
  // Part C - tracks index of work-alloted entry currently being edited (-1 = not editing / adding new)
  final editingWorkAllotedIndex = (-1).obs;

  void startEditWorkAlloted(int index) {
    final item = workAllotedList[index];
    editingWorkAllotedIndex.value = index;
    selectedMaintainerName.value = item['name'];
    workAllotedController.text = item['workAlloted'] ?? '';
  }

  void cancelEditWorkAlloted() {
    editingWorkAllotedIndex.value = -1;
    selectedMaintainerName.value = null;
    workAllotedController.clear();
  }

  void saveWorkAlloted() {
    if (selectedMaintainerName.value == null || workAllotedController.text.isEmpty) {
      Get.snackbar("Error", "Please select Name and enter Work Alloted",backgroundColor: AppColors.red,colorText: AppColors.white1);
      return;
    }

    if (editingWorkAllotedIndex.value >= 0) {
      // Update existing entry in place, preserving its id/workAllotedId
      final index = editingWorkAllotedIndex.value;
      final existing = workAllotedList[index];
      workAllotedList[index] = {
        ...existing,
        'name': selectedMaintainerName.value!,
        'maintainerUserId': _selectedMaintainerUserId ?? existing['maintainerUserId'] ?? '0',
        'workAlloted': workAllotedController.text,
      };
      workAllotedList.refresh();
    } else {
      // New entry
      workAllotedList.add({
        'id': '0',
        'name': selectedMaintainerName.value!,
        'maintainerUserId': _selectedMaintainerUserId ?? '0',
        'workAlloted': workAllotedController.text,
        'workAllotedId': '0',
      });
    }

    cancelEditWorkAlloted();
  }

  void removeWorkAlloted(int index) {
    workAllotedList.removeAt(index);
    if (editingWorkAllotedIndex.value == index) {
      cancelEditWorkAlloted();
    } else if (editingWorkAllotedIndex.value > index) {
      editingWorkAllotedIndex.value--;
    }
  }

  Future<void> submitPartC() async {
    final notificationId = rstFailureData.value?.notificationId;
    if (notificationId == null) {
      Get.snackbar("Error", "Missing notification Id",backgroundColor: AppColors.red,colorText: AppColors.white1);
      return;
    }
    if (workAllotedList.isEmpty) {
      Get.snackbar("Error", "Please add at least one work alloted entry",backgroundColor: AppColors.red,colorText: AppColors.white1);
      return;
    }

    final dataWorkAlloted = workAllotedList.map((e) => {
      "Id": int.tryParse(e['id'] ?? '0') ?? 0,
      "MaintainerUserName": e['name'],
      "MaintainerUserId": e['maintainerUserId'],
      "WorkAllotedName": e['workAlloted'],
      "WorkAllotedId": int.tryParse(e['workAllotedId'] ?? '0') ?? 0,
      "IsDeleted": 0,
    }).toList();

    try {
      isLoading.value = true;
      final msg = await _failureService.updateRstNotificationAccept(
        notificationId: notificationId,
        dataWorkAlloted: dataWorkAlloted,
        isWorkAllotedAccept: isAcceptResponsibility.value,
        isPowerBlockReq: isPowerBlockRequired.value,
      );
      Get.dialog(
        CustPopup(
          title: AppStrings.success,
          message: msg,
          icon: Icons.error_outline,
          iconColor: Colors.red,
          confirmText: "OK",
          onConfirm: () => Get.back(),
        ),
      );
      // Refresh to pick up server-assigned Ids for newly added entries
      await fetchRstFailureData(notificationId);
    } catch (e) {
      Get.snackbar("Error", e.toString(),backgroundColor: AppColors.red,colorText: AppColors.white1);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitPartD() async {
    final notificationId = rstFailureData.value?.notificationId;
    if (notificationId == null) {
      Get.snackbar("Error", "Missing notification Id",backgroundColor: AppColors.red,colorText: AppColors.white1);
      return;
    }
    if (!validateMaterialRequiredUsedQty()) return;

    final userId = await _failureService.getUserId();

    // --- changeNotifictionJE ---
    final changeNotifictionJE = {
      "Id": notificationId,
      "NotificationId": notificationId,
      "Description": failureDescriptionController.text,
      "FailureTypeId": int.tryParse(selectedPartDFailureType.value ?? '') ?? 0,
      "IsHardwareReplaced": isMaterialRequired.value,
      "NotificationCode": rstFailureData.value?.notificationCode ?? '',
      "IsMaterialSwapped": isMaterialDismantle.value,
      "CreatedBy": userId,
    };

    // --- materialRequiredDetails ---
    final materialRequiredDetails = materialRequiredList.map((e) {
      final materialId = int.tryParse(e['materialId'] ?? '0') ?? 0;
      final storeLocId = int.tryParse(e['storeLocationId'] ?? '0') ?? 0;
      final balance = double.tryParse(e['balanceQty'] ?? '0') ?? 0;
      final used = int.tryParse(e['usedQty'] ?? '0') ?? 0;
      final existingId = int.tryParse(e['id'] ?? '0') ?? 0;
      final statusId = existingId > 0 ? 2 : 1; // 2 = updating a fetched row, 1 = new

      return {
        "Materialid": materialId,
        "Quantity": int.tryParse(e['requiredQty'] ?? '0') ?? 0,
        "UnitMeasurement": e['uom'] ?? '',
        "IssuedQty": used,
        "UsedQty": used,
        "BalanceQty": balance,
        "RemainingBalanceQTY": balance - used,
        "StorageLocation": storeLocId,
        "InsertUpdateStatusId": statusId,
        "CurrentInsertUpdateStatusId": statusId,
        "Id": existingId,
      };
    }).toList();

    // --- failureRectification ---
    final failureRectification = <Map<String, dynamic>>[];
    for (final fault in faultList) {
      final rca = rcaDetailsList.firstWhereOrNull(
            (r) => r['objectPart'] == fault['objectPart'] && r['fault'] == fault['fault'],
      );

      String rootCauseText = '';
      String actionText = '';
      if (rca != null) {
        final rootCauses = List<Map<String, dynamic>>.from(rca['rootCauses'] ?? []);
        final actionTakens = List<Map<String, dynamic>>.from(rca['actionTakens'] ?? []);

        rootCauseText = rootCauses.map((rc) {
          final match = rootCauseList.firstWhereOrNull((l) => l.label == rc['rootCause']);
          return "${match?.value ?? '0'}:${rc['rootCauseText'] ?? ''}";
        }).join(',');

        actionText = actionTakens.map((at) {
          final match = actionTakenList.firstWhereOrNull((l) => l.label == at['actionTaken']);
          return "${match?.value ?? '0'}:${at['actionTakenText'] ?? ''}";
        }).join(',');
      }

      failureRectification.add({
        "ObjectPartId": int.tryParse(fault['objectPartId'] ?? '0') ?? 0,
        "ObjectPartText": fault['objectPartText'] ?? '',
        "FaultId": int.tryParse(fault['faultId'] ?? '0') ?? 0,
        "FaultText": fault['faultText'] ?? '',
        "RootCauseText": rootCauseText,
        "ActionText": actionText,
      });
    }

    // --- materialDismantleDetails ---
    final materialDismantleDetails = dismantleMaterialList.map((e) {
      final existingId = int.tryParse(e['id'] ?? '0') ?? 0;
      final statusId = existingId > 0 ? 2 : 1;
      return {
        "MaterialId": int.tryParse(e['materialId'] ?? '0') ?? 0,
        "MaterialReqId": int.tryParse(e['materialReqId'] ?? '0') ?? 0,
        "OldSerialNumber": e['oldSerial'] ?? '',
        "NewSerialNumber": e['newSerial'] ?? '',
        "OldSerialNoDismantleDate": e['oldDismantleDate'] ?? '',
        "NewSerialNoInstallationDate": e['newInstallDate'] ?? '',
        "InsertUpdateStatusId": statusId,
        "CurrentInsertUpdateStatusId": statusId,
        "Id": existingId,
      };
    }).toList();

    final materialSwappedDetails = <Map<String, dynamic>>[];

    final payload = {
      "changeNotifictionJE": changeNotifictionJE,
      "materialRequiredDetails": materialRequiredDetails,
      "failureRectification": failureRectification,
      "materialDismantleDetails": materialDismantleDetails,
      "materialSwappedDetails": materialSwappedDetails,
    };

    try {
      isLoading.value = true;
      final msg = await _failureService.updateNotificationRSTRCAMaterialJE(payload);
      Get.dialog(
        CustPopup(
          title: AppStrings.success,
          message: msg,
          icon: Icons.error_outline,
          iconColor: Colors.red,
          confirmText: "OK",
          onConfirm: () => Get.back(),
        ),
      );
      await fetchRstFailureData(notificationId);
    } catch (e) {
      Get.snackbar("Error", e.toString(),backgroundColor: AppColors.red,colorText: AppColors.white1);
    } finally {
      isLoading.value = false;
    }
  }
  void _populateMaterialsRequired(List<dynamic> raw) {
    materialRequiredList.assignAll(raw.map((e) {
      final qty = e['quantity'];
      final used = e['usedQty'];
      return {
        'id': e['id']?.toString() ?? '0',
        'materialId': e['materialId']?.toString() ?? '0',
        'materialCode': e['materialValue']?.toString() ?? '',
        'storeLocationId': e['storageLocation']?.toString() ?? '',
        'storeLocation': e['storageLocationValue']?.toString() ?? '',
        'requiredQty': qty != null ? (qty as num).toInt().toString() : '0',
        'balanceQty': e['balanceQty']?.toString() ?? '0',
        'uom': e['unitOfMeasurement']?.toString() ?? '',
        'usedQty': (used != null && (used as num) > 0) ? used.toInt().toString() : '',
      };
    }));
  }

  void _populateActionsAndRootCauses(
      List<RectificationDetail> rectDetails,
      List<Action> actions,
      List<RootCause> rootCauses,
      )
  {
    rcaDetailsList.clear();
    for (final rect in rectDetails) {
      final matchingActions = actions.where((a) => a.rectId == rect.rectId).map((a) => {
        'actionTaken': a.actionName,
        'actionTakenText': a.actionText,
      }).toList();

      final matchingRootCauses = rootCauses.where((r) => r.rectId == rect.rectId).map((r) => {
        'rootCause': r.rootCasueName,
        'rootCauseText': r.rcaText,
      }).toList();

      if (matchingActions.isNotEmpty || matchingRootCauses.isNotEmpty) {
        rcaDetailsList.add({
          'objectPart': rect.objectName,
          'objectPartText': rect.objectPartText,
          'fault': rect.faultName,
          'faultText': rect.faultText,
          'rootCauses': matchingRootCauses,
          'actionTakens': matchingActions,
        });
      }
    }
  }


  String? _formatDateIfValid(String? raw) {
  if (raw == null || raw.isEmpty || raw.startsWith('0001-01-01')) return null;
  return raw;
  }

  void _populateMaterialsSwapped(List<dynamic> raw) {
    dismantleMaterialList.assignAll(raw.map((e) => {
      'id': e['id']?.toString() ?? '0',
      'materialId': e['materialId']?.toString() ?? '0',
      'materialReqId': e['materialReqId']?.toString() ?? '0',
      'materialCode': e['materialValue']?.toString() ?? '',
      'oldSerial': e['oldSerialNumber']?.toString() ?? '',
      'oldDismantleDate': e['oldSerialNoDismantleDate']?.toString() ?? '',
      'newSerial': e['newSerialNumber']?.toString() ?? '',
      'newInstallDate': e['newSerialNoInstallationDate']?.toString() ?? '',
    }));
  }
  final assignmentHistoryList = <Map<String, String>>[].obs;

  void _populateAssignmentHistory(List<AssignmentHistory> raw) {
    assignmentHistoryList.assignAll(raw.map((e) => {
      'assgineUserName': e.assgineUserName.trim(),
      'createdOn': _formatAssignmentDate(e.createdOn),
      'statusName': e.statusName,
    }));
  }

  String _formatAssignmentDate(String raw) {
    try {
      final dt = DateTime.parse(raw); // handles "2026-03-07T19:09:00"
      String two(int n) => n.toString().padLeft(2, '0');
      return "${two(dt.day)}-${two(dt.month)}-${dt.year} ${two(dt.hour)}:${two(dt.minute)}";
    } catch (_) {
      return raw;
    }
  }
  String? get selectedPartDFailureTypeLabel {
    if (selectedPartDFailureType.value == null) return null;
    final match = rstFailureTypeList.firstWhereOrNull(
          (e) => e.value == selectedPartDFailureType.value,
    );
    return match?.label;
  }


  void onPartDFailureTypeChanged(String? label) {
    if (label == null) {
      selectedPartDFailureType.value = null;
      return;
    }
    final match = rstFailureTypeList.firstWhereOrNull((e) => e.label == label);
    selectedPartDFailureType.value = match?.value ?? label;
  }

  Future<void> _loadRstMasterDataFromDb() async {
    final existingFailureTypes = await _dbService.getRstFailureTypes();
    final existingObjectParts = await _dbService.getRstObjectParts();
    final existingMaterials = await _dbService.getRstMaterials();
    final existingTrainStatuses = await _dbService.getRstTrainStatuses();
    final existingStorageLocations = await _dbService.getRstStorageLocations(); // ✅ add this check

    if (existingFailureTypes.isEmpty ||
        existingObjectParts.isEmpty ||
        existingMaterials.isEmpty ||
        existingTrainStatuses.isEmpty ||
        existingStorageLocations.isEmpty) { // ✅ include in the gate
      try {
        await _failureService.fetchRstMasterData();
      } catch (e) {
        debugPrint('Error refreshing RST master data: $e');
      }
    }
    // Load RST master data
    final failureTypes = await _dbService.getRstFailureTypes();
    rstFailureTypeList.assignAll(
      failureTypes.map((e) => LabelValue(
        label: e.failureType ?? '',
        value: e.id?.toString() ?? '',
      )),
    );

    final objectParts = await _dbService.getRstObjectParts();
    rstObjectPartList.assignAll(
      objectParts.map((e) => LabelValue(
        label: e.objectCodeDesc ?? '',
        value: e.id?.toString() ?? '',
      )),
    );

    final materials = await _dbService.getRstMaterials();
    rstMaterialList.assignAll(
      materials.map((e) => LabelValue(
        label: e.material ?? '',
        value: e.materialRowId?.toString() ?? '',
      )),
    );

    final storageLocations = await _dbService.getRstStorageLocations();
    storageLocationList.assignAll(storageLocations);

    final trainStatuses = await _dbService.getRstTrainStatuses();
    rstTrainStatusList.assignAll(
      trainStatuses.map((e) => LabelValue(
        label: e.statusDescr ?? '',
        value: e.statusId?.toString() ?? '',
      )),
    );

    // Load general master data
    final priorities = await _dbService.getPriorities();
    priorityList.assignAll(
      priorities.map((e) => LabelValue(label: e.priorityDesc ?? '', value: e.priorityId.toString())).toList(),
    );

    final departments = await _dbService.getDepartments();
    departmentList.assignAll(
      departments.map((e) => LabelValue(label: e.deptName ?? '', value: e.deptId.toString())).toList(),
    );

    // TODO: Add notification types when API is available
    // final notificationTypes = await _dbService.getNotificationTypes();
    // notificationTypeList.assignAll(
    //   notificationTypes.map((e) => LabelValue(label: e.notificationTypeName ?? '', value: e.notificationTypeId.toString())).toList(),
    // );

    final funcLocations = await _dbService.getFunctionalLocations();
    functionalLocationList.assignAll(
      funcLocations.map((e) => LabelValue(label: e.funcLocationName, value: e.funcLocId.toString())).toList(),
    );
    
    // Load cascading filter data from functional locations
    _loadCascadingFilterData(funcLocations);

    final equipments = await _dbService.getEquipments();
    equipmentList.assignAll(
      equipments.map((e) => LabelValue(label: e.equipmentName, value: e.equipId.toString())).toList(),
    );

    final natures = await _dbService.getFailureCategories();
    natureOfWorkList.assignAll(
      natures.map((e) => LabelValue(label: e.failureCategoryType ?? '', value: e.id.toString())).toList(),
    );
    await _loadMaintainerUsers();
  }

  void _loadCascadingFilterData(List<dynamic> funcLocations) {
    // Extract unique values for cascading filters
    // Note: FunctionalLocationModel doesn't have planningPlant, trainSetNo, room, system fields
    // These will need to be added to the model or loaded from a different source
    // For now, we'll use empty lists
    planningPlantList.clear();
    trainSetNoList.clear();
    roomList.clear();
    systemList.clear();
  }

  // Cascading filter methods
  void onPlanningPlantChanged(String? value) {
    selectedPlanningPlant.value = value;
    selectedTrainSetNoFilter.value = null;
    selectedRoomFilter.value = null;
    selectedSystemFilter.value = null;
    selectedFunctionalLocation.value = null;
    _filterFunctionalLocations();
  }

  void onTrainSetNoChanged(String? value) {
    selectedTrainSetNoFilter.value = value;
    selectedRoomFilter.value = null;
    selectedSystemFilter.value = null;
    selectedFunctionalLocation.value = null;
    _filterFunctionalLocations();
  }

  void onRoomChanged(String? value) {
    selectedRoomFilter.value = value;
    selectedSystemFilter.value = null;
    selectedFunctionalLocation.value = null;
    _filterFunctionalLocations();
  }

  void onSystemChanged(String? value) {
    selectedSystemFilter.value = value;
    selectedFunctionalLocation.value = null;
    _filterFunctionalLocations();
  }

  void _filterFunctionalLocations() {
    // Filter functional location list based on selected cascading filters
    // This would need to be implemented based on the actual data structure
    // For now, we'll keep all functional locations
  }

  Future<void> fetchRstMasterDataFromApi() async {
    try {
      await _failureService.fetchRstMasterData();
      await _loadRstMasterDataFromDb();
    } catch (e) {
      debugPrint('Error fetching RST master data: $e');
    }
  }


  // Helper methods to convert LabelValue lists to string lists for dropdowns
  List<String> get rstFailureTypeStrings => rstFailureTypeList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get rstObjectPartStrings => rstObjectPartList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get rstMaterialStrings => rstMaterialList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get rstTrainStatusStrings => rstTrainStatusList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get priorityStrings => priorityList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get departmentStrings => departmentList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get notificationTypeStrings => notificationTypeList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get functionalLocationStrings => functionalLocationList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get equipmentStrings => equipmentList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get natureOfWorkStrings => natureOfWorkList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get planningPlantStrings => planningPlantList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get trainSetNoFilterStrings => trainSetNoList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get roomFilterStrings => roomList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get systemFilterStrings => systemList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get faultStrings => faultDropdownList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get rootCauseStrings => rootCauseList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get actionTakenStrings => actionTakenList.map((e) => e.label).where((e) => e != null).cast<String>().toList();
  List<String> get storageLocationStrings => storageLocationList.map((e) => e.label).where((e) => e != null).cast<String>().toList();

  /// Returns the label string for the currently selected nature-of-work ID.
  /// Used by the dropdown widget which displays labels, not IDs.
  String? get selectedNatureOfWorkLabel {
    if (selectedNatureOfWork.value == null) return null;
    final match = natureOfWorkList.firstWhereOrNull(
      (e) => e.value == selectedNatureOfWork.value,
    );
    return match?.label;
  }


  void _populateFieldsFromData(RstFetchData data) {
    if (data.priorityType != null) {
      final priority = priorityList.firstWhereOrNull((e) => e.label == data.priorityType);
      selectedPriority.value = priority?.label ?? data.priorityType;
    } else {
      selectedPriority.value = null;
    }

    selectedDepartment.value=data.deptName;
  print("selected dept---${selectedDepartment.value}");
    // Notification Type - hardcoded based on ID
    selectedFailureType.value = data.notificationType;

    // Description
    failureDescriptionController.text = data.description ?? '';

    // Functional Location - prefer ID match, fallback to name match
    if (data.functionLocationId != null && data.functionLocationId! > 0) {
      final funcLoc = functionalLocationList.firstWhereOrNull((e) => e.value == data.functionLocationId.toString());
      selectedFunctionalLocation.value = funcLoc?.label ?? data.funcDescription;
    } else if (data.funcDescription != null && data.funcDescription!.isNotEmpty) {
      final funcLoc = functionalLocationList.firstWhereOrNull((e) => e.label == data.funcDescription);
      selectedFunctionalLocation.value = funcLoc?.label ?? data.funcDescription;
    } else {
      selectedFunctionalLocation.value = null;
    }

    // Equipment Name - prefer ID match, fallback to name match
    if (data.equipmentId != null && data.equipmentId! > 0) {
      final equip = equipmentList.firstWhereOrNull((e) => e.value == data.equipmentId.toString());
      selectedEquipmentName.value = equip?.label ?? data.equipmentName;
    } else if (data.equipmentName != null && data.equipmentName!.isNotEmpty) {
      final equip = equipmentList.firstWhereOrNull((e) => e.label == data.equipmentName);
      selectedEquipmentName.value = equip?.label ?? data.equipmentName;
    } else {
      selectedEquipmentName.value = null;
    }
    selectedNatureOfWork.value=data.workName;
    selectedNatureOfWorkId.value=data.natureOfWorkId.toString();
    print("data.workName===${data.workName}");
    
    // Do not Report
    selectedDoNotReport.value = data.doNotReport?.toString();
    
    // Main Line Fault Fields (for WorkNatureId == 10)
    locationOfFailureController.text = data.locationFailure ?? '';
    if (data.actualFailureOccuranceOn != null && data.actualFailureOccuranceOn!.isNotEmpty) {
      // Parse date format "03/07/2026 01:00"
      try {
        final parts = data.actualFailureOccuranceOn!.split(' ');
        if (parts.length >= 2) {
          final dateParts = parts[0].split('/');
          if (dateParts.length == 3) {
            actualFailureOccuranceOn.value = DateTime(
              int.parse(dateParts[2]), // year
              int.parse(dateParts[1]), // month
              int.parse(dateParts[0]), // day
            );
          }
        }
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }
    mainLineActionTakenByController.text = data.mainLineActionTakenBy ?? '';
    trainOperatorNameController.text = data.trainOperatorName ?? '';
    mainLineActionController.text = data.mainLineActionTaken ?? '';
    
    // Service Affected Fields
    isServiceAffected.value = data.isServiceAffected == true;
    trainDelayInMinController.text = data.trainDelayInMin?.toString() ?? '';
    trainDelayInNoController.text = data.trainDelayInNo?.toString() ?? '';
    noOfTrainCancelController.text = data.noOfTranCancel?.toString() ?? '';
    noOfTrainWithdrawalController.text = data.noOfTranWithdrawal?.toString() ?? '';
    noOfTrainReplaceController.text = data.noOfTrainReplace?.toString() ?? '';
    isTrainReplace.value = data.isTrainReplace == true;
    
    // Passenger Deboarding Fields
    isPassengerDeboarding.value = data.isPassengerDeboarding == true;
    noOfTrainDeboardedController.text = data.noofTrainDeboarded?.toString() ?? '';
    
    // Part B Fields
    trainRunningKmController.text = data.trainRunningKM?.toString() ?? '';
    // updatedByName is the display name of the person who last updated (Responsible Person in Part B)
    // assignedUseeName is often empty; updatedByName carries the actual name
    final responsibleName = (data.updatedByName?.isNotEmpty == true)
        ? data.updatedByName
        : (data.assignedUseeName?.isNotEmpty == true ? data.assignedUseeName : null);
    selectedResponsiblePerson.value = responsibleName;
    isSicType.value = data.isSICReq == true;
    isJointInspection.value = data.isJointInspectionReq == true;
    isOHEReq.value = data.isOHEReq == true;
    isPowerBlockRequired.value = data.powerBlockRequired == true;
  // Part C Fields
  isAcceptResponsibility.value = data.isWorkAllotedAccept == true;

  // Part D Fields
  // Use failureTypeId (int) for dropdown matching, NOT failureType ('Yes'/'No' string)
  selectedPartDFailureType.value = data.failureTypeId?.toString();
  isFailureRectification.value = data.isFailureRectifiDetails == true;
  isMaterialRequired.value = data.isHardwareReplaced == true;
  isMaterialDismantle.value = data.isMaterialSwapped == true;
  // Part D - Activity Carried Out
  activityCarriedOutController.text = data.carriedOutRemarks ?? '';
   // Part F Fields
  // actualWorkStart = when maintenance was attended, NOT the failure occurrence date
    actualWorkStart.value = _parseFlexibleDate(data.failureAttendedDate);
    actualWorkComplete.value = _parseFlexibleDate(data.actualFailureRectifiedDate);
  // statusName is null in API; lookup label from rstTrainStatusList using statusId
  final ts = rstTrainStatusList.firstWhereOrNull(
    (e) => e.value == data.statusId?.toString(),
  );
  selectedTrainStatus.value = ts?.label;
  }

  DateTime? _parseFlexibleDate(String? raw) {
    if (raw == null || raw.isEmpty || raw.startsWith('0001-01-01')) return null;
    try {
      return DateTime.parse(raw); // ISO format, e.g. "2026-03-07T18:54:00"
    } catch (_) {
      // fallback: "DD/MM/YYYY hh:mm"
      final parts = raw.split(' ');
      final dateParts = parts.first.split('/');
      if (dateParts.length == 3) {
        final timeParts = parts.length > 1 ? parts[1].split(':') : ['0', '0'];
        return DateTime(
          int.tryParse(dateParts[2]) ?? DateTime.now().year,
          int.tryParse(dateParts[1]) ?? 1,
          int.tryParse(dateParts[0]) ?? 1,
          int.tryParse(timeParts[0]) ?? 0,
          timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0,
        );
      }
      return null;
    }
  }


  @override
  void onClose() {
    failureDescriptionController.dispose();
    searchLocationController.dispose();
    trainRunningKmController.dispose();
    jointInspectionRemarksController.dispose();
    workAllotedController.dispose();
    activityCarriedOutController.dispose();
    requiredQuantityController.dispose();
    oldSerialNumberController.dispose();
    newSerialNumberController.dispose();
    sicChecklistRemarkController.dispose();
    checklistRemarkController.dispose();
    // New controllers
    locationOfFailureController.dispose();
    mainLineActionTakenByController.dispose();
    trainOperatorNameController.dispose();
    mainLineActionController.dispose();
    trainDelayInMinController.dispose();
    trainDelayInNoController.dispose();
    noOfTrainCancelController.dispose();
    noOfTrainWithdrawalController.dispose();
    noOfTrainReplaceController.dispose();
    noOfTrainDeboardedController.dispose();
    super.onClose();
  }
}
