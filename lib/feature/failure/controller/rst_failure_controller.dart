import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/widgets/cust_dropdown.dart';

class RstFailureController extends GetxController {
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
  final selectedDoNotReport = RxnString();
  
  // Attachments
  final afterFiles = <Map<String, dynamic>>[].obs;

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

  // Dummy Dropdown Lists
  final dummyPriorityList = ['High', 'Medium', 'Low'];
  final dummyDepartmentList = ['Rolling Stock', 'Civil'];
  final dummyFailureTypeList = ['Train-Failure', 'Station-Failure'];
  final dummyLineList = ['T201'];
  final dummyTrainSetList = ['T01'];
  final dummyRoomList = ['A01'];
  final dummySystemList = ['Aux Supply Elect'];
  final dummyFunctionalLocationList = ['L1M-T01-A01_RST-AEE-GDB'];
  final dummyEquipmentList = ['1S000000G-GROUNDING BOX'];
  final dummyNatureOfWorkList = ['Depot Fault'];
  final dummyDoNotReportList = ['Failure'];
  
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
      Get.snackbar("Error", "Please select SIC Type and Responsible Person");
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
      Get.snackbar("Error", "Please select Department and Responsible Person");
    }
  }

  void removeJointInspection(int index) {
    jointInspectionList.removeAt(index);
  }

  // --- Part C Fields ---
  final isAcceptResponsibility = false.obs;
  final isPowerBlockRequired = false.obs;
  final selectedMaintainerName = RxnString();
  final workAllotedController = TextEditingController();

  // --- Part D Fields ---
  final selectedPartDFailureType = RxnString();
  final isFailureRectification = false.obs;
  final selectedObjectPart = RxnString();
  final selectedFault = RxnString();
  final faultList = <Map<String, String>>[].obs;
  final activityCarriedOutController = TextEditingController();
  
  final isMaterialRequired = false.obs;
  final selectedMaterialCode = RxnString();
  final selectedStoreLocation = RxnString();
  final requiredQuantityController = TextEditingController();
  
  final isMaterialDismantle = false.obs;
  final selectedDismantleMaterialCode = RxnString();
  final oldSerialNumberController = TextEditingController();
  final oldSerialDismantleDate = RxnString();
  final newSerialNumberController = TextEditingController();
  final newSerialInstallationDate = RxnString();

  void addFault() {
    if (selectedObjectPart.value != null && selectedFault.value != null) {
      faultList.add({
        "objectPart": selectedObjectPart.value!,
        "fault": selectedFault.value!,
      });
      selectedObjectPart.value = null;
      selectedFault.value = null;
    } else {
      Get.snackbar("Error", "Please select Object Part and Fault");
    }
  }

  void removeFault(int index) {
    faultList.removeAt(index);
  }

  // --- Material Required ---
  final materialRequiredList = <Map<String, String>>[].obs;

  void addMaterialRequired() {
    if (selectedMaterialCode.value != null && selectedStoreLocation.value != null && requiredQuantityController.text.isNotEmpty) {
      materialRequiredList.add({
        'materialCode': selectedMaterialCode.value!,
        'storeLocation': selectedStoreLocation.value!,
        'requiredQty': requiredQuantityController.text,
      });
      // Reset
      selectedMaterialCode.value = null;
      selectedStoreLocation.value = null;
      requiredQuantityController.clear();
    }
  }

  void removeMaterialRequired(int index) {
    materialRequiredList.removeAt(index);
  }

  // --- Dismantle Material ---
  final dismantleMaterialList = <Map<String, String>>[].obs;

  void addDismantleMaterial() {
    if (selectedDismantleMaterialCode.value != null && oldSerialNumberController.text.isNotEmpty && newSerialNumberController.text.isNotEmpty) {
      dismantleMaterialList.add({
        'materialCode': selectedDismantleMaterialCode.value!,
        'oldSerial': oldSerialNumberController.text,
        'oldDismantleDate': oldSerialDismantleDate.value ?? '',
        'newSerial': newSerialNumberController.text,
        'newInstallDate': newSerialInstallationDate.value ?? '',
      });
      // Reset
      selectedDismantleMaterialCode.value = null;
      oldSerialNumberController.clear();
      newSerialNumberController.clear();
      oldSerialDismantleDate.value = null;
      newSerialInstallationDate.value = null;
    }
  }

  void removeDismantleMaterial(int index) {
    dismantleMaterialList.removeAt(index);
  }

  // --- Part E Fields ---
  final isPersonsWithdrawn = false.obs;
  final actualWorkStart = RxnString();
  final actualWorkComplete = RxnString();
  final selectedTrainStatus = RxnString();
  final uploadRcaFiles = <Map<String, dynamic>>[].obs;

  // --- Part F Fields ---
  final isSicPerformed = false.obs;
  final isFollowUpActionCompleted = false.obs;
  final sicChecklistRemarkController = TextEditingController();
  final isEquipmentLockingExpanded = true.obs;
  final isDmrChecked = false.obs;
  final isTcChecked = false.obs;
  final isTmbChecked = false.obs;
  final checklistRemarkController = TextEditingController();

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
    super.onClose();
  }
}
