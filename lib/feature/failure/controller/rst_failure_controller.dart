
import 'package:om_mobile/feature/failure/view/shared/failure_toast.dart';
import 'package:om_mobile/feature/failure/service/failure_log.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:get/get.dart';
import '../../../constants/colors.dart';
import '../../../constants/strings.dart';
import '../../../core/models/label_value.dart';
import '../../../service/network_service/app_urls.dart';
import '../model/rst_failure_full_response.dart';
import '../../../service/local_database_service.dart';
import '../../../service/auth_manager.dart';
import '../../../utils/widgets/success_popup.dart';
import '../service/failure_service.dart';
import '../service/rst_lookups.dart';
import '../service/rst_offline_service.dart';
import '../service/rst_record_mapper.dart';
import '../service/rst_submit_helper.dart';
import '../../../core/controller/global_master_data_controller.dart';
import '../../../core/controller/session_controller.dart';
import '../../../service/master_data_sync_service.dart';

class RstFailureController extends GetxController {
  final FailureService _failureService = FailureService();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final GlobalMasterDataController _globalData = Get.find<GlobalMasterDataController>();
  final RstLookups _lookups = RstLookups();
  final RstSubmitHelper _submitHelper = RstSubmitHelper();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = "".obs;
  final Rx<RstFetchData?> rstFailureData = Rx<RstFetchData?>(null);

  /// Part A fields are read-only unless the PPIO creates a failure or edits one
  /// that is not assigned yet.
  final RxBool isViewOnly = true.obs;

  /// The PPIO is creating a new failure (no record yet).
  final RxBool createMode = false.obs;

  /// An action on this failure is waiting to be sent (see RstOfflineService).
  final RxnString pendingAction = RxnString();

  // --- Roles: PPIO does A / B (and closes in the list), Junior Engineer C-F. ---
  String get _role => Get.isRegistered<SessionController>()
      ? Get.find<SessionController>().selectedRole.value?.roleDescr ?? ''
      : '';
  bool get isPpio => SessionController.isRstPpioRole(_role);
  bool get isJe => SessionController.isRstJeRole(_role);

  /// Part A: the PPIO, while creating or until the failure is assigned.
  bool get canEditPartA => isPpio && (createMode.value || _statusId == 1);

  /// Part B: the PPIO, once the failure exists, until the work is accepted.
  bool get canEditPartB =>
      isPpio && !createMode.value && !isAcceptResponsibility.value;

  /// Parts C, D, E: the Junior Engineer.
  bool get canEditPartsCDE => isJe && !createMode.value;

  int get _statusId => rstFailureData.value?.statusId ?? 0;
// Attachments
  final beforeFiles = <Map<String, dynamic>>[].obs;   // BEFORE_NOT  → Part A (view-only)
  final afterFiles = <Map<String, dynamic>>[].obs;    // AFTER_NOT   → Part E
  final uploadRcaFiles = <Map<String, dynamic>>[].obs; // RCA_NOT    → Part E
  // RST Master Data Lists
  final RxList<LabelValue> rstFailureTypeList = <LabelValue>[].obs;
  final RxList<LabelValue> rstObjectPartList = <LabelValue>[].obs;
  final RxList<LabelValue> rstMaterialList = <LabelValue>[].obs;
  final RxList<LabelValue> rstTrainStatusList = <LabelValue>[].obs;
  // Every user status (incl. Closed), for showing a saved value.
  final List<LabelValue> _trainStatusAll = [];

  // NEW: RST View dropdowns from asset DB
  final RxList<LabelValue> rstFaultMasterList = <LabelValue>[].obs;
  final RxList<LabelValue> rstOldRootCauseList = <LabelValue>[].obs;
  final RxList<LabelValue> rstStoreLocationList = <LabelValue>[].obs;
  
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
  final isPartGExpanded = true.obs;

  // Part A Fields
  final selectedPriority = RxnString();
  final selectedDepartment = RxnString();
  final selectedNotificationType = RxnString();
  final selectedFailureType = RxnString();
  final failureDescriptionController = TextEditingController();

  /// Earlier descriptions of an existing failure (read-only list above the box).
  final descriptionHistory = <Map<String, String>>[].obs;
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
  // Part B lookup lists (saved for offline use, see RstLookups).
  final responsiblePersonOptions = <LabelValue>[].obs;
  final sicTypeOptions = <LabelValue>[].obs;
  final sicPersonOptions = <LabelValue>[].obs;
  final jointDeptOptions = <LabelValue>[].obs;
  final jointUserOptions = <LabelValue>[].obs;

  // Rows removed from the lists that exist on the server are sent as deleted.
  final _deletedSic = <Map<String, dynamic>>[];
  final _deletedJoint = <Map<String, dynamic>>[];

  String? _valueOf(List<LabelValue> list, String? label) {
    if (label == null) return null;
    return list.firstWhereOrNull((e) => e.label == label)?.value;
  }

  List<String> _labels(List<LabelValue> list) =>
      list.map((e) => e.label ?? '').where((e) => e.isNotEmpty).toList();

  List<String> get responsiblePersonStrings => _labels(responsiblePersonOptions);
  List<String> get sicTypeStrings => _labels(sicTypeOptions);
  List<String> get sicPersonStrings => _labels(sicPersonOptions);
  List<String> get jointDeptStrings => _labels(jointDeptOptions);
  List<String> get jointUserStrings => _labels(jointUserOptions);

  /// Row of the SIC list being edited (null: adding a new one).
  final editingSicIndex = RxnInt();

  void addSicType() {
    if (selectedSicType.value != null && selectedSicResponsiblePerson.value != null) {
      final editing = editingSicIndex.value;
      final row = <String, String>{
        // An edited row keeps its id so the server updates it.
        "id": editing != null ? (sicTypeList[editing]['id'] ?? "0") : "0",
        "sicTypeId": _valueOf(sicTypeOptions, selectedSicType.value) ?? "0",
        "sicType": selectedSicType.value!,
        "responsiblePersonId":
            _valueOf(sicPersonOptions, selectedSicResponsiblePerson.value) ?? "0",
        "responsiblePerson": selectedSicResponsiblePerson.value!,
      };
      if (editing != null) {
        sicTypeList[editing] = row;
      } else {
        sicTypeList.add(row);
      }
      cancelSicEdit();
    } else {
      FailureToast.show(AppStrings.error, "Please select SIC Type and Responsible Person");
    }
  }

  /// Puts a row back into the form so it can be changed.
  void editSicType(int index) {
    final row = sicTypeList[index];
    editingSicIndex.value = index;
    selectedSicType.value = row['sicType'];
    selectedSicResponsiblePerson.value = row['responsiblePerson'];
  }

  void cancelSicEdit() {
    editingSicIndex.value = null;
    selectedSicType.value = null;
    selectedSicResponsiblePerson.value = null;
  }

  void removeSicType(int index) {
    final row = sicTypeList[index];
    if ((int.tryParse(row['id'] ?? '0') ?? 0) > 0) _deletedSic.add(row);
    sicTypeList.removeAt(index);
    if (editingSicIndex.value != null) cancelSicEdit();
  }

  /// Users of the joint inspection department just picked.
  Future<void> onJointDeptChanged(String? label) async {
    selectedJointInspectionDept.value = label;
    selectedJointInspectionResponsiblePerson.value = null;
    jointUserOptions.clear();
    final deptId = _valueOf(jointDeptOptions, label);
    if (deptId == null || deptId.isEmpty) return;
    // Responsible person: the Junior Engineers of the chosen department.
    final jes = await _dbService.getJuniorEngineersForDepartment(
      deptId: int.tryParse(deptId) ?? 0,
      businessArea: await AuthManager().getBusinessArea(),
    );
    if (jes.isNotEmpty) {
      jointUserOptions.assignAll([
        for (final u in jes)
          LabelValue(label: '${u['UserName']}', value: '${u['UserId']}')
      ]);
      return;
    }
    final data = await _lookups.jiUsers(deptId);
    jointUserOptions.assignAll(RstLookups.options(data['getJIUserList']));
  }

  /// Row of the joint inspection list being edited (null: adding a new one).
  final editingJointIndex = RxnInt();

  void addJointInspection() {
    if (selectedJointInspectionDept.value != null && selectedJointInspectionResponsiblePerson.value != null) {
      final deptId = _valueOf(jointDeptOptions, selectedJointInspectionDept.value) ?? "0";
      final editing = editingJointIndex.value;
      if (jointInspectionList.asMap().entries
          .any((e) => e.key != editing && e.value['deptId'] == deptId)) {
        FailureToast.show(AppStrings.error, "Department already exist");
        return;
      }
      final row = <String, String>{
        // An edited row keeps its id / status so the server updates it.
        "id": editing != null ? (jointInspectionList[editing]['id'] ?? "0") : "0",
        "deptId": deptId,
        "personId":
            _valueOf(jointUserOptions, selectedJointInspectionResponsiblePerson.value) ?? "0",
        "department": selectedJointInspectionDept.value!,
        "responsiblePerson": selectedJointInspectionResponsiblePerson.value!,
        "remark": jointInspectionRemarksController.text,
        "status": editing != null
            ? (jointInspectionList[editing]['status'] ?? "Create join Inspection")
            : "Create join Inspection",
        "statusId": editing != null
            ? (jointInspectionList[editing]['statusId'] ?? "40")
            : "40",
      };
      if (editing != null) {
        jointInspectionList[editing] = row;
      } else {
        jointInspectionList.add(row);
      }
      cancelJointEdit();
    } else {
      FailureToast.show(AppStrings.error, "Please select Department and Responsible Person");
    }
  }

  /// Puts a row back into the form so it can be changed.
  Future<void> editJointInspection(int index) async {
    final row = jointInspectionList[index];
    editingJointIndex.value = index;
    await onJointDeptChanged(row['department']);
    selectedJointInspectionResponsiblePerson.value = row['responsiblePerson'];
    jointInspectionRemarksController.text = row['remark'] ?? '';
  }

  void cancelJointEdit() {
    editingJointIndex.value = null;
    selectedJointInspectionDept.value = null;
    selectedJointInspectionResponsiblePerson.value = null;
    jointUserOptions.clear();
    jointInspectionRemarksController.clear();
  }

  void removeJointInspection(int index) {
    final row = jointInspectionList[index];
    if ((int.tryParse(row['id'] ?? '0') ?? 0) > 0) _deletedJoint.add(row);
    jointInspectionList.removeAt(index);
    if (editingJointIndex.value != null) cancelJointEdit();
  }

  void _populateSicDetails(List<dynamic> raw) {
    _deletedSic.clear();
    sicTypeList.assignAll([
      for (final e in raw)
        if (e is Map && '${e['isDeleted']}' != '1' && '${e['isDeleted']}' != 'true')
          {
            "id": '${e['id'] ?? 0}',
            "sicTypeId": '${e['sicTypeId'] ?? 0}',
            "sicType": '${e['sicType'] ?? ''}',
            "responsiblePersonId": '${e['responsiblePersonId'] ?? 0}',
            "responsiblePerson": '${e['responsiblePerson'] ?? ''}',
          }
    ]);
  }


  List<Map<String, dynamic>> _newlyPickedFiles(List<Map<String, dynamic>> list) {
    return list.where((f) => (f['id'] == null || f['id'] == '0') && (f['path']?.toString().isNotEmpty ?? false)).toList();
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

    failureLog("Before Images : ${beforeFiles.length}");
    failureLog("After Images  : ${afterFiles.length}");
    failureLog("RCA Images    : ${uploadRcaFiles.length}");
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

  /// objectPart.db rows by id (SystemGroup / ObjectCode used to find faults).
  final Map<String, Map<String, dynamic>> _objectPartMeta = {};

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
      FailureToast.show(AppStrings.error, "Please select Object Part and Fault");
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
      // Faults of the chosen object part, from faultMaster.db (offline).
      final meta = _objectPartMeta[objectPartId];
      final rows = await _dbService.getFaultOptions(
          systemGroup: meta?['group']?.toString(),
          objectCode: meta?['code']?.toString());
      if (rows.isNotEmpty) {
        // Label: SystemGroup-FaultCode-FaultDescr (unique, empty parts left out).
        String clean(Object? v) {
          final s = (v ?? '').toString().trim();
          return s.toLowerCase() == 'null' ? '' : s;
        }

        final seen = <String>{};
        faultDropdownList.assignAll([
          for (final f in rows)
            LabelValue(
              label: () {
                final base = [clean(f['group']), clean(f['code']), clean(f['name'])]
                    .where((e) => e.isNotEmpty)
                    .join('-');
                return seen.add(base) ? base : '$base (${f['id']})';
              }(),
              value: '${f['id']}',
            )
        ]);
      } else {
        faultDropdownList.assignAll(await _failureService.getFaults(objectPartId));
      }
    } catch (e) {
      failureLog('fetchFaults error: $e');
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
      failureLog('fetchRootCauseAndAction error: $e');
    }
  }

  // Add near other Part D RxStrings:
  final uomController = TextEditingController();
  final balanceQtyController = TextEditingController();

  Future<void> fetchMCDRequiredQuantity(int objectCodeId, int faultCodeId) async {
    // Unit of measurement from materialMaster.db (offline), as on the other
    // failure forms; "N/A" when the material has none.
    uomController.text = await _dbService.getMaterialUnit(objectCodeId);
  }

  /// Balance quantity: shows 0.00 straight away (as on the other failure forms)
  /// and is replaced by the store's figure when the server answers.
  Future<void> fetchMaterialBalancedQty(int materialId, int storageLocationId) async {
    balanceQtyController.text = '0.00';
    try {
      final userId = await _failureService.getUserId();
      final data = await _failureService.getMaterialBalancedQty(materialId, storageLocationId, userId);
      final v = data['balancedData']?.toString() ?? '';
      if (v.isNotEmpty && !_closed) balanceQtyController.text = v;
    } catch (e) {
      failureLog('fetchMaterialBalancedQty (offline?): $e');
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
      FailureToast.show(AppStrings.error, "Please select Root Cause");
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
      FailureToast.show(AppStrings.error, "Please select Action Taken");
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
      FailureToast.show(AppStrings.error, "Please fill all required fields");
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
  final trainStatusResetKey = 0.obs;

  // --- Part F: the SIC rows of the failure and their (read-only) checksheets ---
  final sicChecks = <Map<String, String>>[].obs;
  final isSicWorkCompleted = false.obs;
  final openSicCheck = Rxn<Map<String, String>>();
  final sheetHeaders = <Map<String, dynamic>>[].obs;
  final sheetLines = <Map<String, dynamic>>[].obs;
  final sheetLoading = false.obs;
  final sheetUnavailable = false.obs;
  final expandedSheetHeader = RxnString();

  void _populateSicChecks(List<dynamic> raw, bool completed) {
    isSicWorkCompleted.value = completed;
    String s(Object? v) => (v ?? '').toString();
    sicChecks.assignAll([
      for (final e in raw)
        if (e is Map)
          {
            'id': s(e['id']),
            'sicType': s(e['sicType']),
            'sicTypeId': s(e['sicTypeId']),
            'responsiblePerson': s(e['responsiblePerson']),
            'status': s(e['status']),
            'remark': s(e['remark']),
            'checkSIC1': s(e['checkSIC1']),
            'checkSIC2': s(e['checkSIC2']),
          }
    ]);
  }

  /// Opens one SIC row's checksheet (read-only, as on the web), built offline
  /// from the SIC header and item masters.
  Future<void> openSicChecksheet(Map<String, String> row) async {
    openSicCheck.value = row;
    sheetHeaders.clear();
    sheetLines.clear();
    sheetUnavailable.value = false;
    expandedSheetHeader.value = null;
    sheetLoading.value = true;
    try {
      // From the bundled masters (works offline): the headers of the row's SIC
      // type (SICHeaderMaster), then the items of those headers (SICItemMaster).
      final typeId = int.tryParse(row['sicTypeId'] ?? '') ??
          await _dbService.getSicTypeIdByName(row['sicType'] ?? '');
      if (typeId == null) {
        sheetUnavailable.value = true;
        return;
      }
      final headers = await _dbService.getSicHeadersForType(typeId);
      final items = await _dbService.getSicItemsForHeaders([
        for (final h in headers)
          if (int.tryParse('${h['headerId']}') != null) int.parse('${h['headerId']}')
      ]);
      if (_closed) return;
      sheetHeaders.assignAll(headers);
      sheetLines.assignAll(items);
      sheetUnavailable.value = sheetHeaders.isEmpty;
      if (sheetHeaders.isNotEmpty) {
        expandedSheetHeader.value = '${sheetHeaders.first['headerId']}';
      }
    } catch (e) {
      failureLog('openSicChecksheet error: $e');
      sheetUnavailable.value = true;
    } finally {
      sheetLoading.value = false;
    }
  }

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
    failureLog("fetchRstFailureData: CALLED with notificationId=$notificationId");
    isLoading.value = true;
    errorMessage.value = "";
    failureLog("fetchRstFailureData: Starting fetch for notificationId=$notificationId");

    try {
      failureLog("fetchRstFailureData: Loading master data from DB...");
      await _loadRstMasterDataFromDb();
      failureLog("fetchRstFailureData: Master data loaded");
      if (_closed) return; // the screen was closed while loading

      // From the local copy (works offline); the server only when this failure
      // is not in the copy yet.
      final fullData = await _loadFullData(notificationId);
      if (_closed) return;
      failureLog("fetchRstFailureData: API data received, rstFetchData=${fullData.rstFetchData.notificationId}");

      // Populate notification history
      notificationHistory.value = fullData.notificationHistory.toJson();
      failureLog("fetchRstFailureData: Notification history populated");
    
      failureLog("fetchRstFailureData: Parsing RstFetchData...");
      final data = RstFetchData.fromJson(fullData.rstFetchData.toJson());
      rstFailureData.value = data;
      failureLog("fetchRstFailureData: RstFetchData parsed, description=${data.description}");
      
      failureLog("fetchRstFailureData: Populating fields...");
      _populateFieldsFromData(data);
      failureLog("fetchRstFailureData: Fields populated");
      isViewOnly.value = !canEditPartA;
      _populateSicDetails(fullData.sicUsers);
      _populateSicChecks(fullData.sicCheckList, data.isSICWorkCompletion == true);
      if (canEditPartA || canEditPartB) await _loadFormLookups(data.deptId);
      if (isJe) await _loadMaintainerUsers(data.deptId);

      failureLog("fetchRstFailureData: Populating joint inspections...");
      _populateJointInspections(fullData.jointInspections);
      failureLog("fetchRstFailureData: Joint inspections hydrated, count=${jointInspectionList.length}");
      
      failureLog("fetchRstFailureData: Populating work alloted users...");
      _populateWorkAllotedUsers(fullData.workAllotedUsers);
      failureLog("fetchRstFailureData: Work alloted users hydrated, count=${workAllotedList.length}");
      
      failureLog("fetchRstFailureData: Populating rectification details...");
      _populateRectificationDetails(fullData.rectificationDetails);
      failureLog("fetchRstFailureData: Rectification details hydrated, count=${faultList.length}");
      
      failureLog("fetchRstFailureData: Populating actions and root causes...");
      _populateActionsAndRootCauses(fullData.rectificationDetails, fullData.actions, fullData.rootCauses);
      failureLog("fetchRstFailureData: Actions and root causes hydrated, count=${rcaDetailsList.length}");

      // isFailureRectifiDetails isn't always present in the response.
      // If there's actual fault/rectification data, show the section regardless.
      if (fullData.rectificationDetails.isNotEmpty) {
        isFailureRectification.value = true;
        failureLog("fetchRstFailureData: Set isFailureRectification=true");
      }

      failureLog("fetchRstFailureData: Populating materials required...");
      _populateMaterialsRequired(fullData.materials);
      failureLog("fetchRstFailureData: Materials required hydrated, count=${materialRequiredList.length}");
      
      failureLog("fetchRstFailureData: Populating materials swapped...");
      _populateMaterialsSwapped(fullData.materialSerialNumbers);
      failureLog("fetchRstFailureData: Materials swapped hydrated, count=${dismantleMaterialList.length}");
      
      failureLog("fetchRstFailureData: Populating assignment history...");
      _populateAssignmentHistory(fullData.assignmentHistory);
      failureLog("fetchRstFailureData: Assignment history hydrated, count=${assignmentHistoryList.length}");

      failureLog("fetchRstFailureData: Populating documents...");
      failureLog("fetchRstFailureData: Raw documents=${fullData.documents}");
      _populateDocuments(fullData.documents);
      failureLog("fetchRstFailureData: Documents hydrated, beforeFiles=${beforeFiles.length}, afterFiles=${afterFiles.length}, uploadRcaFiles=${uploadRcaFiles.length}");
      failureLog("fetchRstFailureData: All data hydrated successfully");
    } catch (e, stackTrace) {
      failureLog("fetchRstFailureData: ERROR - $e");
      failureLog("fetchRstFailureData: STACK TRACE - $stackTrace");
      errorMessage.value = "Error: ${e.toString()}";
    } finally {
      isLoading.value = false;
      failureLog("fetchRstFailureData: Loading complete, isLoading=false");
    }
  }

  Future<RstFailureFullResponse> _loadFullData(int notificationId) async {
    final record = await _dbService.getRstFailureCacheRow(notificationId);
    pendingAction.value = await _dbService.getRstPendingAction(notificationId);
    if (record != null) return RstRecordMapper.toFullResponse(record);
    return _failureService.getRstFailureFullData(notificationId);
  }

  /// After a part is submitted (as on the other failures): refresh the stored
  /// copy, go back to the list and show the result pop-up there.
  Future<void> _finish(RstSubmitResult result, String action, {String? message}) async {
    if (!result.queued) {
      try {
        await Get.find<MasterDataSyncService>().syncRstFailures();
      } catch (e) {
        failureLog('_finish: sync failed: $e');
      }
    }
    final code = rstFailureData.value?.notificationCode ?? '';
    final done = message ??
        '${RstOfflineService.label(action)} submitted successfully.'
            '${code.isNotEmpty ? '\nFailure No: $code' : ''}';
    Get.back(); // to the list (it refreshes when it comes back into view)
    showResultPopup(
      title: result.queued ? 'Saved Offline' : 'Success',
      message: result.queued
          ? '${RstOfflineService.label(action)} saved on this device. It is sent automatically when the internet is back, and you will be told when it is done.'
          : done,
      icon: result.queued ? Icons.cloud_off_outlined : Icons.check_circle_outline,
      iconColor: result.queued ? AppColors.orangeColor : AppColors.green,
    );
  }

  String _fmtDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}";
  }

  // ---- Part E Train Status rules of the live web ----
  // Statuses are recognised by name: the bundled userStatus.db numbers them
  // differently from the web's server.
  static String _norm(String? s) => (s ?? '').trim().toUpperCase();

  static const String _jiPendingMessage =
      'Joint Inspection is pending. Train status cannot be set as CFIT';
  static const String _iblPendingMessage =
      'IBL request is pending. Train status cannot be set as CFIT';

  // A pending joint inspection stops CFIT.
  // A pending IBL request stops every status except In-Process and Escalated.
  static const Set<String> _blockedByIbl = {
    'CFIT', 'PFIT', 'PTNF', 'CTUM', 'UNDER OBSERVATION'
  };

  /// Joint inspections still pending (joint inspection status 40).
  bool get _hasPendingJointInspection =>
      jointInspectionList.any((j) => '${j['statusId']}' == '40');

  /// An IBL (power block) request is pending: Power Block is required and the
  /// IBL has not been completed yet. The server's own IBL status is kept in
  /// statusId_IBL; it is read as "not completed" while empty / 0.
  bool get _hasPendingIbl {
    final d = rstFailureData.value;
    if (d == null || d.powerBlockRequired != true) return false;
    return (d.iblId ?? 0) == 0 || (d.statusIdIbl ?? 0) == 0;
  }

  /// The message to show when [label] cannot be chosen now, or null.
  String? _trainStatusBlock(String? label) {
    final s = _norm(label);
    if (s == 'CFIT' && _hasPendingJointInspection) return _jiPendingMessage;
    if (_blockedByIbl.contains(s) && _hasPendingIbl) return _iblPendingMessage;
    return null;
  }

  /// Picking a Train Status in Part E, with the web's pending checks.
  void onTrainStatusChanged(String? label) {
    final block = _trainStatusBlock(label);
    if (block != null) {
      selectedTrainStatus.value = null;
      // Rebuild the dropdown so it drops the value it still shows.
      trainStatusResetKey.value++;
      FailureToast.show(AppStrings.error, block);
      return;
    }
    selectedTrainStatus.value = label;
  }
  Future<void> submitPartE() async {
    final notificationId = rstFailureData.value?.notificationId;
    if (notificationId == null) {
      FailureToast.show(AppStrings.error, "Missing notification Id");
      return;
    }
    if (!isPersonsWithdrawn.value) {
      FailureToast.show(AppStrings.error, "Please confirm the declaration");
      return;
    }
    // Same order as the web: the declaration, then Train Status. The web never
    // makes the two work dates mandatory (its date check compares the status
    // with a number and so never applies), so they are optional here too.
    if ((selectedTrainStatus.value ?? '').isEmpty) {
      FailureToast.show(AppStrings.error, "Please select Train Status");
      return;
    }
    final trainStatusMatch = rstTrainStatusList.firstWhereOrNull(
          (e) => e.label == selectedTrainStatus.value,
    );
    final trainStatusId = trainStatusMatch?.value ?? '0';
    if (trainStatusId == '0' || trainStatusId.isEmpty) {
      FailureToast.show(AppStrings.error, "Please select Train Status");
      return;
    }
    if (actualWorkStart.value != null &&
        actualWorkComplete.value != null &&
        actualWorkComplete.value!.isBefore(actualWorkStart.value!)) {
      FailureToast.show(AppStrings.error,
          "Actual Work Complete cannot be before Actual Work Start");
      return;
    }
    final block = _trainStatusBlock(selectedTrainStatus.value);
    if (block != null) {
      FailureToast.show(AppStrings.error, block);
      return;
    }
    try {
      isLoading.value = true;

      final userId = await _failureService.getUserId();
      final result = await _submitHelper.submit(
        action: RstOfflineService.actionCompletion,
        endpoint: AppUrls.updateRSTNotificationCompletion,
        field: 'RSTWorkCompletionDetails',
        notificationId: notificationId,
        body: {
          "Id": notificationId,
          "IsWorkCompletion": true,
          "TrainStatusId": trainStatusId,
          "ActualWorkStartDate":
              actualWorkStart.value == null ? '' : _fmtDateTime(actualWorkStart.value!),
          "ActualWorkCompleteDate": actualWorkComplete.value == null
              ? ''
              : _fmtDateTime(actualWorkComplete.value!),
          "UserId": userId,
          "CreatedBy": userId,
        },
        files: [
          for (final f in _newlyPickedFiles(afterFiles))
            RstFile('afterImage', f['path'].toString()),
          for (final f in _newlyPickedFiles(uploadRcaFiles))
            RstFile('rcaImage', f['path'].toString()),
        ],
      );
      await _finish(result, RstOfflineService.actionCompletion);
    } catch (e) {
      FailureToast.show(AppStrings.error, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  void _populateJointInspections(List<JointInspection> raw) {
    _deletedJoint.clear();
    jointInspectionList.assignAll(raw.where((i) => !i.isDeleted).map((i) => {
      'id': i.id.toString(),
      'deptId': i.jiDeptId.toString(),
      'personId': i.jiResponsiblePersonId.toString(),
      'department': i.jiDeptName,
      'responsiblePerson': i.jiResponsiblePerson,
      'remark': i.jiRemark ?? '',
      'status': i.jiStatus,
      'statusId': i.jiStatusId.toString(),
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
  /// Part C "Name": the Junior Engineers of the failure's department
  /// (local user master, filtered query, works offline).
  Future<void> _loadMaintainerUsers(int? failureDeptId) async {
    final deptId = failureDeptId ??
        int.tryParse(_valueOf(departmentList, selectedDepartment.value) ?? '') ??
        0;
    final jes = await _dbService.getJuniorEngineersForDepartment(
      deptId: deptId,
      businessArea: await AuthManager().getBusinessArea(),
    );
    maintainerUserList.assignAll([
      for (final u in jes)
        LabelValue(label: '${u['UserName']}', value: '${u['UserId']}')
    ]);
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
      FailureToast.show(AppStrings.error, "Please select Name and enter Work Alloted");
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
      FailureToast.show("Duplicate", "Selected material already exists!");
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
      'issuedQty': '0',
      'usedQty': '',
    };

    if (editingMaterialRequiredIndex.value >= 0) {
      final index = editingMaterialRequiredIndex.value;
      final existing = materialRequiredList[index];
      materialRequiredList[index] = {
        ...newItem,
        'id': existing['id'] ?? '0',
        'usedQty': existing['usedQty'] ?? '',
        'issuedQty': existing['issuedQty'] ?? '0',
      };
      materialRequiredList.refresh();
      editingMaterialRequiredIndex.value = -1;
    } else {
      // Newest first and opened, like the other failure forms.
      final shifted = <int, bool>{};
      isExpandedMaterial.forEach((k, v) => shifted[k + 1] = v);
      isExpandedMaterial
        ..clear()
        ..addAll(shifted);
      materialRequiredList.insert(0, newItem);
      isExpandedMaterial[0] = true;
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
      FailureToast.show("Invalid Quantity", msg,
          backgroundColor: AppColors.red.withValues(alpha: 0.9), colorText: AppColors.white1);
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
      FailureToast.show(AppStrings.error, "Please select Name and enter Work Alloted");
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
      FailureToast.show(AppStrings.error, "Missing notification Id");
      return;
    }
    if (workAllotedList.isEmpty) {
      FailureToast.show(AppStrings.error, "Please add at least one work alloted entry");
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
      final userId = await _failureService.getUserId();
      final result = await _submitHelper.submit(
        action: RstOfflineService.actionAccept,
        endpoint: AppUrls.updateRSTNotificationAccept,
        field: 'RSTUpdateNotificationAccept',
        notificationId: notificationId,
        body: {
          "Id": notificationId,
          "DataWorkAlloted": dataWorkAlloted,
          "IsWorkAllotedAccept": isAcceptResponsibility.value,
          "UserId": userId,
          "IsPowerBlockReq": isPowerBlockRequired.value,
        },
      );
      await _finish(result, RstOfflineService.actionAccept);
    } catch (e) {
      FailureToast.show(AppStrings.error, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  /// Part D rules (as on the web), checked on Submit instead of the field
  /// validators: returns the first problem, or null when Part D can be sent.
  String? partDValidationError() {
    if ((selectedPartDFailureType.value ?? '').isEmpty) {
      return 'Please select failure type';
    }
    if (isFailureRectification.value && faultList.isEmpty) {
      return 'Please add failure rectification data (Object Part and Fault)';
    }
    if (isMaterialRequired.value && materialRequiredList.isEmpty) {
      return 'Please add material data';
    }
    if (isMaterialDismantle.value && dismantleMaterialList.isEmpty) {
      return 'Please add material dismantle data';
    }
    return null;
  }

  Future<void> submitPartD() async {
    final notificationId = rstFailureData.value?.notificationId;
    if (notificationId == null) {
      FailureToast.show(AppStrings.error, "Missing notification Id");
      return;
    }
    if (!validateMaterialRequiredUsedQty()) return;

    final userId = await _failureService.getUserId();

    // --- changeNotifictionJE ---
    final changeNotifictionJE = {
      "Id": notificationId,
      "NotificationId": notificationId,
      // Part D's "Details of activity Carried Out" (null when empty, as on the web).
      "Description": activityCarriedOutController.text.trim().isEmpty
          ? null
          : activityCarriedOutController.text.trim(),
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
        "IssuedQty": int.tryParse(e['issuedQty'] ?? '0') ?? 0,
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
      final result = await _submitHelper.submit(
        action: RstOfflineService.actionRca,
        endpoint: AppUrls.updateNotificationRSTRCAMaterialJE,
        field: 'ChangeRSTNotifictionJEVM',
        notificationId: notificationId,
        body: payload,
      );
      await _finish(result, RstOfflineService.actionRca);
    } catch (e) {
      FailureToast.show(AppStrings.error, e.toString().replaceFirst('Exception: ', ''));
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
        'issuedQty': (e['issuedQty'] is num) ? (e['issuedQty'] as num).toInt().toString() : '0',
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
        // await _failureService.fetchRstMasterData();
      } catch (e) {
        failureLog('Error refreshing RST master data: $e');
      }
    }
    // Load RST master data
    // Part D lists come from the bundled dbs (PartDRstFailureType.db,
    // objectPart.db); the old cached tables are only a fallback.
    final partDTypes = await _dbService.getPartDFailureTypeOptions();
    if (partDTypes.isNotEmpty) {
      rstFailureTypeList.assignAll([
        for (final t in partDTypes)
          LabelValue(label: '${t['name']}', value: '${t['id']}')
      ]);
    } else {
      final failureTypes = await _dbService.getRstFailureTypes();
      rstFailureTypeList.assignAll(
        failureTypes.map((e) => LabelValue(
              label: e.failureType ?? '',
              value: e.id?.toString() ?? '',
            )),
      );
    }

    final partRows = await _dbService.getObjectPartOptions();
    if (partRows.isNotEmpty) {
      _objectPartMeta.clear();
      for (final p in partRows) {
        _objectPartMeta['${p['id']}'] = p;
      }
      // Label: SystemGroup-ObjectCode-ObjectDescr (empty parts left out).
      String clean(Object? v) {
        final s = (v ?? '').toString().trim();
        return s.toLowerCase() == 'null' ? '' : s;
      }

      final seen = <String>{};
      rstObjectPartList.assignAll([
        for (final p in partRows)
          LabelValue(
            label: () {
              final base = [clean(p['group']), clean(p['code']), clean(p['name'])]
                  .where((e) => e.isNotEmpty)
                  .join('-');
              // Labels pick the row, so they must be unique.
              return seen.add(base) ? base : '$base (${p['id']})';
            }(),
            value: '${p['id']}',
          )
      ]);
    } else {
      final objectParts = await _dbService.getRstObjectParts();
      rstObjectPartList.assignAll(
        objectParts.map((e) => LabelValue(
              label: e.objectCodeDesc ?? '',
              value: e.id?.toString() ?? '',
            )),
      );
    }

    // Same material list as the other failure forms (materialMaster.db).
    final masters = await _dbService.getMaterialMasters();
    if (masters.isNotEmpty) {
      rstMaterialList.assignAll(masters.map((e) {
        final d = (e.description ?? '').trim();
        final label = d.isEmpty
            ? (e.material ?? '')
            : (d.contains(' - ') ? d : '${e.material ?? ''} - $d');
        return LabelValue(label: label, value: e.materialRowId?.toString() ?? '');
      }));
    } else {
      final materials = await _dbService.getRstMaterials();
      rstMaterialList.assignAll(
        materials.map((e) => LabelValue(
              label: e.material ?? '',
              value: e.materialRowId?.toString() ?? '',
            )),
      );
    }

    // Store Location: StoreLocation.db, the same source and label as the other
    // failure forms; the old cached table is only a fallback.
    final stores = await _dbService.getStoreLocations();
    if (stores.isNotEmpty) {
      storageLocationList.assignAll(stores.map((e) => LabelValue(
          label: e.storeLocationDesc ?? e.storeLocation ?? '',
          value: e.storeLocationId?.toString() ?? '')));
    } else {
      storageLocationList.assignAll(await _dbService.getRstStorageLocations());
    }

    // Part E Train Status: userStatus.db (same label as the other failure forms),
    // every status except "Closed". The old cached table is only a fallback.
    final userStatuses = await _dbService.getUserStatuses();
    if (userStatuses.isNotEmpty) {
      final all = [
        for (final e in userStatuses)
          LabelValue(
              label: (e.statusName ?? e.statusDescr ?? '').trim(),
              value: e.statusId?.toString() ?? '')
      ].where((e) => (e.label ?? '').isNotEmpty).toList();
      _trainStatusAll
        ..clear()
        ..addAll(all);
      rstTrainStatusList.assignAll(all.where((e) {
        final l = (e.label ?? '').toLowerCase();
        return !l.contains('closed') && !l.contains('escalat');
      }));
    } else {
      final trainStatuses = await _dbService.getRstTrainStatuses();
      rstTrainStatusList.assignAll(
        trainStatuses.map((e) => LabelValue(
              label: e.statusDescr ?? '',
              value: e.statusId?.toString() ?? '',
            )),
      );
      _trainStatusAll
        ..clear()
        ..addAll(rstTrainStatusList);
    }

    // Load general master data
    final priorities = await _dbService.getPriorities();
    priorityList.assignAll(
      priorities.map((e) => LabelValue(label: e.priorityDesc ?? '', value: e.priorityId.toString())).toList(),
    );

    final departments =
        _allowedDepartments(await _dbService.getDepartments(), (d) => d.deptId);
    departmentList.assignAll(departments
        .map((e) => LabelValue(label: e.deptName, value: e.deptId.toString(), uniqueId: e.workCenter))
        .toList());

    // The functional-location (~300k rows) and equipment (~200k rows) tables
    // are NOT loaded here: the failure's own location / equipment names come
    // with its record, and the lists are filtered queries run only when the
    // user changes the department / location (as on the other forms).
    functionalLocationList.clear();
    equipmentList.clear();
    _loadCascadingFilterData(const []);

    await _loadLocalTypeLists();
  }

  // ---- "Search By Superior Functional Location OR Asset Tag" (as on the web) ----
  // Shown once a department is chosen. Superior = short location code (< 29
  // characters), Asset Tag = long. Then, each a query on fun_loc.db:
  //   Line        = PlanningPlant, in the user's business area
  //   TrainSet No = Location, of the department's work center and the Line
  //   Room        = Room, of that Location
  //   System      = TechObjectType, of that Room
  // and the Functional Location list is what matches all the chosen filters.
  static const String searchBySuperior = 'Superior Functional Location';
  static const String searchByAssetTag = 'Asset Tag';
  static const List<String> searchByOptions = [searchBySuperior, searchByAssetTag];

  final showLocationFilter = false.obs; // the Search By field is visible
  final selectedSearchBy = RxnString();

  bool? get _longCodes {
    switch (selectedSearchBy.value) {
      case searchByAssetTag:
        return true;
      case searchBySuperior:
        return false;
      default:
        return null;
    }
  }

  String? get _workCenter {
    final wc = departmentList
        .firstWhereOrNull((e) => e.label == selectedDepartment.value)
        ?.uniqueId;
    return (wc ?? '').isEmpty ? null : wc;
  }

  /// Filter options: no empty / "null" entries and no duplicates.
  List<LabelValue> _asOptions(List<String> values) {
    final seen = <String>{};
    final out = <LabelValue>[];
    for (final raw in values) {
      final v = raw.trim();
      if (v.isEmpty || v.toLowerCase() == 'null') continue;
      if (!seen.add(v.toLowerCase())) continue;
      out.add(LabelValue(label: v, value: v));
    }
    return out;
  }

  // The failure's own saved location (name + id). It must always show and stay
  // selected on an existing failure, even when the filtered list (department /
  // business area) does not contain it, or is empty for this role.
  String? _savedLocName;
  String? _savedLocId;

  void _ensureSavedLocation() {
    final name = _savedLocName;
    if (name == null || name.isEmpty) return;
    if (functionalLocationList.every((e) => e.label != name)) {
      functionalLocationList.insert(
          0, LabelValue(label: name, value: _savedLocId ?? '0'));
    }
  }

  /// The Functional Location list: everything that matches the chosen filters.
  Future<void> _refreshLocationList() async {
    final locs = await _dbService.getFunctionalLocationsByFilters(
      businessArea: await AuthManager().getBusinessArea(),
      workCenter: _workCenter,
      plant: selectedPlanningPlant.value,
      location: selectedTrainSetNoFilter.value,
      room: selectedRoomFilter.value,
      system: selectedSystemFilter.value,
      longCodes: _longCodes,
    );
    functionalLocationList.assignAll(locs.map((e) => LabelValue(
        label: e.funcLocationName.isNotEmpty ? e.funcLocationName : e.funcLocation,
        value: e.funcLocId.toString())));
    _ensureSavedLocation();
    final sel = selectedFunctionalLocation.value;
    if (sel != null && functionalLocationList.every((e) => e.label != sel)) {
      selectedFunctionalLocation.value = null;
      selectedEquipmentName.value = null;
      equipmentList.clear();
    }
  }

  void _loadCascadingFilterData(List<dynamic> funcLocations) {
    showLocationFilter.value = false;
    selectedSearchBy.value = null;
    selectedPlanningPlant.value = null;
    selectedTrainSetNoFilter.value = null;
    selectedRoomFilter.value = null;
    selectedSystemFilter.value = null;
    planningPlantList.clear();
    trainSetNoList.clear();
    roomList.clear();
    systemList.clear();
  }

  Future<void> onSearchByChanged(String? value) async {
    selectedSearchBy.value = value;
    selectedPlanningPlant.value = null;
    selectedTrainSetNoFilter.value = null;
    selectedRoomFilter.value = null;
    selectedSystemFilter.value = null;
    selectedFunctionalLocation.value = null;
    trainSetNoList.clear();
    roomList.clear();
    systemList.clear();
    // Line: PlanningPlant column, filtered by business area.
    planningPlantList.assignAll(value == null
        ? <LabelValue>[]
        : _asOptions(await _dbService.getFunctionalLocationDistinct('PlanningPlant',
            businessArea: await AuthManager().getBusinessArea())));
    await _refreshLocationList();
  }

  Future<void> onPlanningPlantChanged(String? value) async {
    selectedPlanningPlant.value = value;
    selectedTrainSetNoFilter.value = null;
    selectedRoomFilter.value = null;
    selectedSystemFilter.value = null;
    selectedFunctionalLocation.value = null;
    roomList.clear();
    systemList.clear();
    // TrainSet No: Location column, by work center and planning plant.
    trainSetNoList.assignAll(value == null
        ? <LabelValue>[]
        : _asOptions(await _dbService.getFunctionalLocationDistinct('Location',
            businessArea: await AuthManager().getBusinessArea(),
            workCenter: _workCenter,
            plant: value)));
    await _refreshLocationList();
  }

  Future<void> onTrainSetNoChanged(String? value) async {
    selectedTrainSetNoFilter.value = value;
    selectedRoomFilter.value = null;
    selectedSystemFilter.value = null;
    selectedFunctionalLocation.value = null;
    systemList.clear();
    // Room: Room column of that Location.
    roomList.assignAll(value == null
        ? <LabelValue>[]
        : _asOptions(await _dbService.getFunctionalLocationDistinct('Room',
            businessArea: await AuthManager().getBusinessArea(),
            workCenter: _workCenter,
            plant: selectedPlanningPlant.value,
            location: value)));
    await _refreshLocationList();
  }

  Future<void> onRoomChanged(String? value) async {
    selectedRoomFilter.value = value;
    selectedSystemFilter.value = null;
    selectedFunctionalLocation.value = null;
    // System: TechObjectType column of that Room.
    systemList.assignAll(value == null
        ? <LabelValue>[]
        : _asOptions(await _dbService.getFunctionalLocationDistinct('TechObjectType',
            businessArea: await AuthManager().getBusinessArea(),
            workCenter: _workCenter,
            plant: selectedPlanningPlant.value,
            location: selectedTrainSetNoFilter.value,
            room: value)));
    await _refreshLocationList();
  }

  Future<void> onSystemChanged(String? value) async {
    selectedSystemFilter.value = value;
    selectedFunctionalLocation.value = null;
    await _refreshLocationList();
  }

  // Future<void> fetchRstMasterDataFromApi() async {
  //   try {
  //     await _failureService.fetchRstMasterData();
  //     await _loadRstMasterDataFromDb();
  //   } catch (e) {
  //     failureLog('Error fetching RST master data: $e');
  //   }
  // }


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

    selectedDepartment.value = data.deptName ??
        departmentList.firstWhereOrNull((e) => e.value == data.deptId?.toString())?.label;
  failureLog("selected dept---${selectedDepartment.value}");
    // Failure Type: the local list's name for the record's id.
    selectedFailureType.value = notificationTypeList
            .firstWhereOrNull((e) => e.value == data.notificationTypeId?.toString())
            ?.label ??
        data.notificationType ??
        data.failureTypeName;
    _filterNature();

    // Description: an existing failure shows its earlier descriptions as a
    // read-only list and an empty box for a new one (as on the web).
    failureDescriptionController.text = '';
    final items = [
      for (final e in (notificationHistory.value?['descriptionItems'] as List? ?? const []))
        if (e is Map && '${e['description']}'.trim().isNotEmpty)
          Map<String, String>.from(e.map((k, v) => MapEntry('$k', '$v')))
    ];
    if (items.isEmpty && (data.description ?? '').trim().isNotEmpty) {
      items.add({
        'description': data.description!.trim(),
        'createdBy': data.createdByName ?? '',
        'createdOn': data.createdOn ?? '',
      });
    }
    descriptionHistory.assignAll(items);

    // Functional Location - prefer ID match, fallback to name match
    // The full name is functionLocationName (e.g. BOGIES-RST-L1M-T03-A03-BOG);
    // funcDescription is only its short description (BOGIES).
    final locName = (data.functionLocationName ?? '').trim().isNotEmpty
        ? data.functionLocationName
        : data.funcDescription;
    if (data.functionLocationId != null && data.functionLocationId! > 0) {
      final funcLoc = functionalLocationList.firstWhereOrNull((e) => e.value == data.functionLocationId.toString());
      selectedFunctionalLocation.value = funcLoc?.label ?? locName;
    } else if (locName != null && locName.isNotEmpty) {
      final funcLoc = functionalLocationList.firstWhereOrNull((e) => e.label == locName);
      selectedFunctionalLocation.value = funcLoc?.label ?? locName;
    } else {
      selectedFunctionalLocation.value = null;
    }
    _savedLocName = selectedFunctionalLocation.value;
    _savedLocId = (data.functionLocationId ?? 0) > 0
        ? data.functionLocationId.toString()
        : null;
    _ensureSavedLocation();

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
    selectedNatureOfWork.value = data.workName ??
        data.natureOfWorkName ??
        natureOfWorkList
            .firstWhereOrNull((e) => e.value == data.natureOfWorkId?.toString())
            ?.label;
    selectedNatureOfWorkId.value=data.natureOfWorkId.toString();
    failureLog("data.workName===${data.workName}");
    
    // Do not Report
    selectedDoNotReport.value = data.doNotReport?.toString();
    
    // Main Line Fault Fields (for WorkNatureId == 10)
    locationOfFailureController.text = data.locationFailure ?? '';
    // "03/07/2026 01:00" (date and time)
    actualFailureOccuranceOn.value = _parseFlexibleDate(data.actualFailureOccuranceOn);
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
  // The saved train status is the failure's userStatus; looked up in the full
  // list (a closed failure may carry "Closed", which is not offered to pick).
  final savedStatus = (data.userStatus ?? '').trim();
  final ts = _trainStatusAll.firstWhereOrNull((e) => e.value == savedStatus) ??
      _trainStatusAll.firstWhereOrNull((e) => e.value == data.statusId?.toString());
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


  // ===========================================================================
  // Part A (PPIO creates / edits) and Part B (PPIO assigns)
  // ===========================================================================

  final _natureAll = <Map<String, dynamic>>[];

  /// The PPIO opens the create form: no record, Part A editable.
  Future<void> initCreate() async {
    createMode.value = true;
    isViewOnly.value = false;
    isLoading.value = true;
    errorMessage.value = "";
    try {
      // Only the four lists Part A shows; the RST work-detail lists (materials,
      // object parts, users ...) are not needed to create a failure.
      await Future.wait([_loadCreateMasterData(), _loadLocalTypeLists()]);
    } catch (e) {
      failureLog('initCreate: $e');
      errorMessage.value = "Error: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCreateMasterData() async {
    final priorities = await _dbService.getPriorities();
    priorityList.assignAll(priorities
        .map((e) => LabelValue(label: e.priorityDesc ?? '', value: e.priorityId.toString())));
    final departments =
        _allowedDepartments(await _dbService.getDepartments(), (d) => d.deptId);
    departmentList.assignAll(departments.map((e) => LabelValue(
        label: e.deptName, value: e.deptId.toString(), uniqueId: e.workCenter)));
    // Functional locations and equipment are the big tables: they are loaded
    // only after the department / location is chosen (as on the other forms).
    functionalLocationList.clear();
    equipmentList.clear();
  }

  /// Functional locations of the chosen department (its work center) in the
  /// user's business area - a filtered query, not the whole table.
  Future<void> _loadFunctionalLocationsForDepartment(String? deptLabel) async {
    functionalLocationList.clear();
    equipmentList.clear();
    _loadCascadingFilterData(const []);
    final dept = departmentList.firstWhereOrNull((e) => e.label == deptLabel);
    if (dept == null) return;
    await _refreshLocationList();
    // The Search By field appears once the department's locations are known.
    showLocationFilter.value = functionalLocationList.isNotEmpty;
  }

  /// The departments this user can raise RST failures for: the ones the PPIO
  /// role is mapped to (e.g. Rolling Stock, Depot Equipment), not every
  /// department. Anyone else (or no mapping found) sees the full list.
  List<T> _allowedDepartments<T>(List<T> all, int? Function(T) idOf) {
    if (!isPpio || !Get.isRegistered<SessionController>()) return all;
    final ids = Get.find<SessionController>()
        .roleDeptMappings
        .where((r) => SessionController.isRstPpioRole(r.roleDescr ?? ''))
        .map((r) => r.deptId)
        .toSet();
    final filtered = all.where((d) => ids.contains(idOf(d))).toList();
    return filtered.isEmpty ? all : filtered;
  }

  /// Equipment of the chosen functional location.
  Future<void> onFunctionalLocationChanged(String? label) async {
    selectedFunctionalLocation.value = label;
    selectedEquipmentName.value = null;
    equipmentList.clear();
    if (label == null || label.isEmpty) return;
    // The equipment table links to a location by its code ("CODE - name"),
    // not by id.
    final eq = await _dbService.getEquipmentsFiltered(
      functionalLocationId: label,
    );
    equipmentList.assignAll(
        eq.map((e) => LabelValue(label: e.equipmentName, value: e.equipId.toString())));
  }

  /// Failure Type (notificationType.db) and Nature of Work (natureOfWork.db):
  /// the bundled databases, already loaded into the master data at login. No
  /// server call.
  Future<void> _loadLocalTypeLists() async {
    // Failure Type: assets/RstFailureType.db (Train-Failure, M&P-Activity ...).
    final types = await _dbService.getRstFailureTypeOptions();
    notificationTypeList.assignAll([
      for (final t in types) LabelValue(label: '${t['name']}', value: '${t['id']}')
    ]);

    // Nature of Work: natureOfWork.db, each row linked to a failure type; the
    // list shows the ones of the chosen Failure Type (as on the web).
    final natures = await _dbService.getNatureOfWorkRows();
    _natureAll
      ..clear()
      ..addAll([
        for (final n in natures)
          {'label': n['name'], 'value': '${n['id']}', 'notificationTypeId': n['typeId']}
      ]);
    _filterNature();
  }

  /// Dropdown lists of the Part A / Part B forms, from the server or, without
  /// internet, from the copy saved at login (RstLookups).
  Future<void> _loadFormLookups(int? deptId) async {
    // Priority, department, failure type and nature of work are the local
    // lists already loaded; the functional locations of the failure's
    // department are a filtered query.
    if (canEditPartA && selectedDepartment.value != null) {
      await _loadFunctionalLocationsForDepartment(selectedDepartment.value);
    }

    final data = rstFailureData.value;
    if (canEditPartB && data != null) {
      final id = (data.notificationEncryptId ?? '').isNotEmpty
          ? data.notificationEncryptId!
          : '${data.notificationId}';
      // Responsible Person: the Junior Engineers (role JE) of the failure's
      // department in the user's business area, from the local user master
      // (works offline).
      final deptId = data.deptId ??
          int.tryParse(_valueOf(departmentList, selectedDepartment.value) ?? '') ??
          0;
      final jes = await _dbService.getJuniorEngineersForDepartment(
        deptId: deptId,
        businessArea: await AuthManager().getBusinessArea(),
      );
      responsiblePersonOptions.assignAll([
        for (final u in jes)
          LabelValue(label: '${u['UserName']}', value: '${u['UserId']}')
      ]);

      final b = await _lookups.partB(id);
      // The server's list is only the fallback when no local user matches.
      if (responsiblePersonOptions.isEmpty) {
        responsiblePersonOptions
            .assignAll(RstLookups.options(b['getResponsiblePersonList']));
      }
      // SIC types come from the bundled SICType.db; server list is the fallback.
      final sicRows = await _dbService.getSicTypeOptions();
      if (sicRows.isNotEmpty) {
        sicTypeOptions.assignAll([
          for (final r in sicRows)
            LabelValue(label: '${r['name']}', value: '${r['id']}')
        ]);
      } else {
        sicTypeOptions.assignAll(RstLookups.options(b['getSICTypeList']));
      }
      // "Boogie SIC" is not offered for RST failures.
      sicTypeOptions.removeWhere(
          (e) => (e.label ?? '').toLowerCase().contains('boogie'));
      // SIC Responsible Person: same Junior Engineers as Part B's Responsible
      // Person (the failure's department); server list only as fallback.
      if (jes.isNotEmpty) {
        sicPersonOptions.assignAll(responsiblePersonOptions);
      } else {
        sicPersonOptions
            .assignAll(RstLookups.options(b['getSICResponsiblePerson']));
      }
      // Joint inspection departments: every department except the failure's own
      // (local dept master; server list as fallback).
      final allDepts = await _dbService.getDepartments();
      final joint = <LabelValue>[
        for (final d in allDepts)
          if (d.deptId != null &&
              d.deptId != deptId &&
              d.deptName.trim().isNotEmpty)
            LabelValue(label: d.deptName.trim(), value: '${d.deptId}')
      ]..sort((a, b) =>
          (a.label ?? '').toLowerCase().compareTo((b.label ?? '').toLowerCase()));
      if (joint.isNotEmpty) {
        jointDeptOptions.assignAll(joint);
      } else {
        jointDeptOptions.assignAll(RstLookups.options(b['getDepartmentList'])
            .where((e) => e.value != '$deptId'));
      }
      final assigned = responsiblePersonOptions
          .firstWhereOrNull((e) => e.value == '${data.assignedUserId}');
      if (assigned != null) selectedResponsiblePerson.value = assigned.label;
    }
  }

  /// Nature of Work depends on the Failure Type.
  void _filterNature() {
    final typeId = _valueOf(notificationTypeList, selectedFailureType.value);
    final rows = typeId == null
        ? <Map<String, dynamic>>[] // empty until a Failure Type is chosen
        : _natureAll.where((n) => '${n['notificationTypeId']}' == typeId).toList();
    natureOfWorkList.assignAll(RstLookups.options(rows));
  }

  void onPriorityChanged(String? v) => selectedPriority.value = v;

  Future<void> onDepartmentChanged(String? label) async {
    selectedDepartment.value = label;
    selectedFunctionalLocation.value = null;
    selectedEquipmentName.value = null;
    await _loadFunctionalLocationsForDepartment(label);
  }

  void onFailureTypeChanged(String? label) {
    selectedFailureType.value = label;
    selectedNatureOfWork.value = null;
    selectedNatureOfWorkId.value = null;
    _filterNature();
  }

  void onNatureOfWorkChanged(String? label) {
    selectedNatureOfWork.value = label;
    selectedNatureOfWorkId.value = _valueOf(natureOfWorkList, label);
  }

  // Service Affected is part of the Main Line Fault block; Train Replace and
  // Passenger Deboarding are inside Service Affected (as on the web).
  bool get _serviceAffectedOn =>
      selectedNatureOfWorkId.value == '10' && isServiceAffected.value;
  bool get _deboardingOn => _serviceAffectedOn && isPassengerDeboarding.value;

  String? _requiredMissing() {
    String blank(TextEditingController c) => c.text.trim();
    if (selectedPriority.value == null) return "Please select priority";
    if (selectedDepartment.value == null) return "Please select department";
    if (selectedFailureType.value == null) return "Please select failure type";
    // Required when creating; on an update the new description is optional.
    if (createMode.value && blank(failureDescriptionController).isEmpty) {
      return "Please enter description";
    }
    if (selectedFunctionalLocation.value == null) return "Please select functional location";
    if (selectedNatureOfWorkId.value == null) return "Please select nature of work";
    final nature = selectedNatureOfWorkId.value;
    if (nature == '10') {
      if (blank(locationOfFailureController).isEmpty) return "Please enter location of failure";
      if (actualFailureOccuranceOn.value == null) return "Please select actual failure occurrence";
      if (blank(mainLineActionTakenByController).isEmpty) return "Please enter main line action taken by";
      if (blank(trainOperatorNameController).isEmpty) return "Please enter train operator name";
      if (blank(mainLineActionController).isEmpty) return "Please enter main line action";
    }
    if (nature == '27' && actualFailureOccuranceOn.value == null) {
      return "Please select actual failure occurrence";
    }
    if (_serviceAffectedOn) {
      if (blank(trainDelayInMinController).isEmpty) return "Please enter train delay in min";
      if (blank(trainDelayInNoController).isEmpty) return "Please enter train delay (NOS)";
      if (blank(noOfTrainCancelController).isEmpty) return "Please enter train cancel (NOS)";
      if (blank(noOfTrainWithdrawalController).isEmpty) return "Please enter train withdrawal (NOS)";
    }
    if (_deboardingOn && blank(noOfTrainDeboardedController).isEmpty) {
      return "Please enter number of train deboarded";
    }
    if (selectedDoNotReport.value == null) return "Please select do not report";
    return null;
  }

  /// Part A: creates the failure (PPIO), or updates it while it is not
  /// assigned. Works offline: the call is kept and sent when the internet is
  /// back. Returns true when it was sent or kept.
  /// [finishAfter] false: do not leave the screen (Part B is submitted next).
  Future<bool> submitPartA({bool finishAfter = true}) async {
    final missing = _requiredMissing();
    if (missing != null) {
      FailureToast.show(AppStrings.error, missing);
      return false;
    }
    final create = createMode.value;
    final notificationId = rstFailureData.value?.notificationId ?? 0;
    final userId = await _failureService.getUserId();
    final nature = selectedNatureOfWorkId.value;
    final needsDate = nature == '10' || nature == '27';
    final dateText = needsDate && actualFailureOccuranceOn.value != null
        ? _fmtDateTime(actualFailureOccuranceOn.value!)
        : '';
    final deptId = _valueOf(departmentList, selectedDepartment.value) ?? '0';
    final body = <String, dynamic>{
      if (!create) 'NotificationId': notificationId,
      'NatureOfWorkId': nature,
      'Description': failureDescriptionController.text.trim(),
      'DeptId': deptId,
      'PriorityId': _valueOf(priorityList, selectedPriority.value) ?? '0',
      if (!create) 'TrainRunningKM': trainRunningKmController.text.trim(),
      'NotificationTypeId': _valueOf(notificationTypeList, selectedFailureType.value) ?? '0',
      'FunctionLocationId': _valueOf(functionalLocationList, selectedFunctionalLocation.value) ?? '0',
      'EquipmentId': _valueOf(equipmentList, selectedEquipmentName.value) ?? 0,
      'ActualFailureOccuranceOn': dateText,
      'IsServiceAffected': _serviceAffectedOn,
      'TrainDelayInMin': _serviceAffectedOn ? trainDelayInMinController.text.trim() : '',
      'TrainDelayInNo': _serviceAffectedOn ? trainDelayInNoController.text.trim() : '',
      'NoOfTranCancel': _serviceAffectedOn ? noOfTrainCancelController.text.trim() : '',
      'NoOfTranWithdrawal': _serviceAffectedOn ? noOfTrainWithdrawalController.text.trim() : '',
      'NoOfTrainReplace': '',
      'IsPassengerDeboarding': _deboardingOn,
      'NoofTrainDeboarded': _deboardingOn ? noOfTrainDeboardedController.text.trim() : '',
      'LocationFailure': nature == '10' ? locationOfFailureController.text.trim() : '',
      'MainLineActionTakenBy': nature == '10' ? mainLineActionTakenByController.text.trim() : '',
      'TrainOperatorName': nature == '10' ? trainOperatorNameController.text.trim() : '',
      'MainLineActionTaken': nature == '10' ? mainLineActionController.text.trim() : '',
      'DoNotReport': selectedDoNotReport.value,
      'CreatedBy': userId,
      'IsTrainReplace': _serviceAffectedOn && isTrainReplace.value,
    };
    try {
      isLoading.value = true;
      final action = create ? RstOfflineService.actionCreate : RstOfflineService.actionUpdate;
      final result = await _submitHelper.submit(
        action: action,
        endpoint: create
            ? AppUrls.createRSTNotificationDetails
            : AppUrls.updateRSTNotificationDetails,
        field: 'RSTCorrectiveNotification',
        body: body,
        notificationId: notificationId,
        files: [
          for (final f in _newlyPickedFiles(beforeFiles))
            RstFile('beforImage', f['path'].toString()),
        ],
        offlineEntry: {
          if (failureDescriptionController.text.trim().isNotEmpty)
            'failureDescription': failureDescriptionController.text.trim(),
          'functionalLocation': selectedFunctionalLocation.value,
          'failureOccuranceDateTime': dateText,
          'priority': selectedPriority.value,
          'departmentName': selectedDepartment.value,
        },
      );
      final no = (result.message ?? '').trim();
      if (!finishAfter) return true;
      await _finish(
        result,
        action,
        message: create
            ? 'RST failure created successfully.${no.isNotEmpty ? '\nFailure No: $no' : ''}'
            : 'RST failure updated successfully.'
                '${(rstFailureData.value?.notificationCode ?? '').isNotEmpty ? '\nFailure No: ${rstFailureData.value!.notificationCode}' : ''}',
      );
      return true;
    } catch (e) {
      FailureToast.show(AppStrings.error, e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// The one Submit of the PPIO's editable parts: Part A (create, or update
  /// before assignment) and / or Part B (assign). When both are open, A is
  /// saved first, then B, and the user leaves the screen once.
  Future<void> submitPpioParts() async {
    if (createMode.value) {
      await submitPartA();
    } else if (canEditPartA && canEditPartB) {
      if (await submitPartA(finishAfter: false)) await submitPartB();
    } else if (canEditPartA) {
      await submitPartA();
    } else if (canEditPartB) {
      await submitPartB();
    }
  }

  /// Part B: the PPIO assigns the failure (responsible person, SIC, joint
  /// inspection). Works offline.
  Future<void> submitPartB() async {
    final data = rstFailureData.value;
    final notificationId = data?.notificationId;
    if (notificationId == null) {
      FailureToast.show(AppStrings.error, "Missing notification Id");
      return;
    }
    final personId = _valueOf(responsiblePersonOptions, selectedResponsiblePerson.value) ??
        (data?.assignedUserId?.toString());
    if (personId == null || personId.isEmpty || personId == '0') {
      FailureToast.show(AppStrings.error, "Please select responsible person");
      return;
    }
    if (trainRunningKmController.text.trim().isEmpty) {
      FailureToast.show(AppStrings.error, "Please enter train running KM");
      return;
    }
    if (isSicType.value && sicTypeList.isEmpty) {
      FailureToast.show(AppStrings.error, "Please add SIC type");
      return;
    }
    if (isJointInspection.value && jointInspectionList.isEmpty) {
      FailureToast.show(AppStrings.error, "Please add joint inspection");
      return;
    }
    final userId = await _failureService.getUserId();
    Map<String, dynamic> sic(Map<String, dynamic> r, int deleted) => {
          'Id': int.tryParse('${r['id']}') ?? 0,
          'SICTypeId': '${r['sicTypeId']}',
          'SICType': r['sicType'],
          'ResponsiblePersonId': '${r['responsiblePersonId']}',
          'ResponsiblePerson': r['responsiblePerson'],
          'IsDeleted': deleted,
        };
    Map<String, dynamic> joint(Map<String, dynamic> r, int deleted) => {
          'Id': int.tryParse('${r['id']}') ?? 0,
          'JI_Dept_Id': '${r['deptId']}',
          'JI_Dept_Name': r['department'],
          'JI_ResponsiblePersonId': '${r['personId']}',
          'JI_ResponsiblePerson': r['responsiblePerson'],
          'JI_Remark': r['remark'],
          'JI_FunctionalLocation': '',
          'JI_EquipementName': '',
          'JI_Status': r['status'],
          'JI_StatusId': int.tryParse('${r['statusId']}') ?? 40,
          'IsDeleted': deleted,
        };
    final body = <String, dynamic>{
      'Id': notificationId,
      'TrainRunningKM': trainRunningKmController.text.trim(),
      'ResponsiblePersonId': personId,
      'IsSICRequired': isSicType.value,
      'DataSIC': [
        for (final r in sicTypeList) sic(r, 0),
        for (final r in _deletedSic) sic(r, 1),
      ],
      'DataJI': [
        for (final r in jointInspectionList) joint(r, 0),
        for (final r in _deletedJoint) joint(r, 1),
      ],
      'IsJoinInspectionRequired': isJointInspection.value,
      'UserId': userId,
      'IsOHEReq': true,
    };
    try {
      isLoading.value = true;
      final result = await _submitHelper.submit(
        action: RstOfflineService.actionAssign,
        endpoint: AppUrls.updateRSTNotificationAssignment,
        field: 'RSTUpdateNotificationAssignment',
        body: body,
        notificationId: notificationId,
      );
      await _finish(result, RstOfflineService.actionAssign);
    } catch (e) {
      FailureToast.show(AppStrings.error, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadRstDropdowns();
  }

  void _loadRstDropdowns() {
    // Copy RST data from GlobalMasterDataController
    rstFaultMasterList.assignAll(_globalData.rstFaultMasterList);
    rstOldRootCauseList.assignAll(_globalData.rstOldRootCauseList);
    rstStoreLocationList.assignAll(_globalData.rstStoreLocationList);
  }

  /// Set when the screen is closed: async loads still running must not touch
  /// the (disposed) text controllers.
  bool _closed = false;

  @override
  void onClose() {
    _closed = true;
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
