import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/models/label_value.dart';
import '../../../core/models/root_cause.dart';
import '../../../core/controller/global_master_data_controller.dart';
import 'failure_form_state.dart';

mixin FailureRcaLogic on GetxController, FailureFormState {

  void showErrorDialog(String message);

  final rcaDetailsList = <Map<String, dynamic>>[].obs;
  final tempPopupRootCauses = <Map<String, dynamic>>[].obs;
  final tempPopupActionTakens = <Map<String, dynamic>>[].obs;
  final selectedPopupCause = RxnString();
  final selectedPopupAction = RxnString();
  final isExpandedRca = <int, bool>{}.obs;

  void addRcaDetail() {
    final failureCategoryId = rcaFailureCategoryList
        .firstWhere((e) => e.label == selectedRcaFailureCategory.value,
        orElse: () => LabelValue(value: "0"))
        .value;

    rcaDetailsList.add({
      'subsystem': subsystemController.text,
      'FailureCategoryId': failureCategoryId,
      'failureCategory': selectedRcaFailureCategory.value ?? "",
      'rootCauses': <Map<String, dynamic>>[],
      'actionTakens': <Map<String, dynamic>>[],
    });
    selectedRcaFailureCategory.value = null;
  }

  void removeRcaDetail(Map<String, dynamic> item) {
    rcaDetailsList.remove(item);
  }

  void addRootCauseToRca(int index) {
    if (selectedPopupCause.value == null &&
        selectedPopupRootCause.value == null &&
        popupCauseTextController.text.trim().isEmpty) {
      showErrorDialog('Please select Cause and Root Cause before adding.');
      return;
    }

    final causeId = causeList
        .firstWhere((e) => e.label == selectedPopupCause.value,
        orElse: () => LabelValue(value: "0"))
        .value;
    
    final rootCauseId = rootCauseList
        .firstWhere((e) => e.label == selectedPopupRootCause.value,
        orElse: () => LabelValue(value: "0"))
        .value;

    final List<Map<String, dynamic>> rootCauses =
    List.from(rcaDetailsList[index]['rootCauses']);
    rootCauses.add({
      'causeId': causeId ?? "0",
      'cause': selectedPopupCause.value ?? "N/A",
      'rootCauseId': rootCauseId ?? "0",
      'rootCause': selectedPopupRootCause.value ?? "N/A",
      'causeText': popupCauseTextController.text,
      'imagePath': popupRootCauseFiles.isNotEmpty
          ? popupRootCauseFiles.first['path']
          : null,
    });

    rcaDetailsList[index]['rootCauses'] = rootCauses;
    rcaDetailsList.refresh();

    selectedPopupCause.value = null;
    selectedPopupRootCause.value = null;
    popupCauseTextController.clear();
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
    if (selectedPopupAction.value == null &&
        popupActionTextController.text.trim().isEmpty) {
      showErrorDialog('Please select Action or enter Action Text before adding.');
      return;
    }

    final actionTakenId = actionTakenList
        .firstWhere((e) => e.label == selectedPopupAction.value,
        orElse: () => LabelValue(value: "0"))
        .value;

    final List<Map<String, dynamic>> actionTakens =
    List.from(rcaDetailsList[index]['actionTakens']);
    actionTakens.add({
      'actionTakenId': actionTakenId ?? "0",
      'actionTaken': selectedPopupAction.value ?? "N/A",
      'actionTakenText': popupActionTextController.text,
      'imagePath': popupActionTakenFiles.isNotEmpty
          ? popupActionTakenFiles.first['path']
          : null,
    });

    rcaDetailsList[index]['actionTakens'] = actionTakens;
    rcaDetailsList.refresh();

    selectedPopupAction.value = null;
    popupActionTextController.clear();
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
    final causeId = causeList
        .firstWhere((e) => e.label == selectedPopupCause.value,
        orElse: () => LabelValue(value: "0"))
        .value ??
        "0";
    final rootCauseId = popupRootCauseList
        .firstWhere((e) => e.label == selectedPopupRootCause.value,
        orElse: () => LabelValue(value: "0"))
        .value ??
        "0";

    debugPrint("Adding to tempPopupRootCauses - cause: ${selectedPopupCause.value}, rootCause: ${selectedPopupRootCause.value}, rootCauseId: $rootCauseId, causeText: ${popupCauseTextController.text}");
    
    tempPopupRootCauses.add({
      'causeId': causeId,
      'cause': selectedPopupCause.value ?? "N/A",
      'rootCauseId': rootCauseId,
      'rootCause': selectedPopupRootCause.value ?? "N/A",
      'causeText': popupCauseTextController.text,
      'imagePath': popupRootCauseFiles.isNotEmpty
          ? popupRootCauseFiles.first['path']
          : null,
    });
    
    debugPrint("tempPopupRootCauses after add: $tempPopupRootCauses");
    
    selectedPopupCause.value = null;
    selectedPopupRootCause.value = null;
    popupCauseTextController.clear();
    popupRootCauseFiles.clear();
  }

  void addToTempActionTakens() {
    final actionTakenId = actionTakenList
        .firstWhere((e) => e.label == selectedPopupAction.value,
        orElse: () => LabelValue(value: "0"))
        .value ??
        "0";
    
    debugPrint("Adding to tempPopupActionTakens - action: ${selectedPopupAction.value}, actionText: ${popupActionTextController.text}");
    debugPrint("actionTakenList: ${actionTakenList.map((e) => e.label).toList()}");
    
    tempPopupActionTakens.add({
      'actionTakenId': actionTakenId,
      'actionTaken': selectedPopupAction.value ?? "N/A",
      'actionTakenText': popupActionTextController.text,
      'imagePath': popupActionTakenFiles.isNotEmpty
          ? popupActionTakenFiles.first['path']
          : null,
    });
    
    debugPrint("tempPopupActionTakens after add: $tempPopupActionTakens");
    
    selectedPopupAction.value = null;
    popupActionTextController.clear();
    popupActionTakenFiles.clear();
  }

  void savePopupDataToRca(int index) {
    final List<Map<String, dynamic>> rootCauses =
    List.from(rcaDetailsList[index]['rootCauses']);
    final List<Map<String, dynamic>> actionTakens =
    List.from(rcaDetailsList[index]['actionTakens']);

    debugPrint("Before save - tempPopupRootCauses: $tempPopupRootCauses");
    debugPrint("Before save - tempPopupActionTakens: $tempPopupActionTakens");
    debugPrint("Before save - existing rootCauses: $rootCauses");
    debugPrint("Before save - existing actionTakens: $actionTakens");

    rootCauses.addAll(tempPopupRootCauses);
    actionTakens.addAll(tempPopupActionTakens);

    debugPrint("After save - combined rootCauses: $rootCauses");
    debugPrint("After save - combined actionTakens: $actionTakens");

    rcaDetailsList[index]['rootCauses'] = rootCauses;
    rcaDetailsList[index]['actionTakens'] = actionTakens;
    rcaDetailsList.refresh();

    debugPrint("After save - rcaDetailsList[$index]: ${rcaDetailsList[index]}");

    clearPopupState();
  }

  void clearPopupState() {
    tempPopupRootCauses.clear();
    tempPopupActionTakens.clear();
    selectedPopupCause.value = null;
    selectedPopupRootCause.value = null;
    selectedPopupAction.value = null;
    popupCauseTextController.clear();
    popupActionTextController.clear();
    popupRootCauseFiles.clear();
    popupActionTakenFiles.clear();
    popupRootCauseList.clear();
  }

  void filterPopupRootCauses(String? selectedCauseLabel) {
    if (selectedCauseLabel == null || selectedCauseLabel.isEmpty) {
      popupRootCauseList.clear();
      selectedPopupRootCause.value = null;
      return;
    }

    final globalMasterData = Get.find<GlobalMasterDataController>();
    final causeId = causeList
        .firstWhere((e) => e.label == selectedCauseLabel,
        orElse: () => LabelValue(value: "0"))
        .value ?? "0";

    final rootCauses = globalMasterData.masterRootCauses
        .map(RootCauseModel.fromJson)
        .where((rc) {
          final causeMatch = rc.causeOfFailureId?.toString().trim() == causeId.trim();
          return causeMatch;
        })
        .map((rc) => LabelValue(
              label: rc.rootCause,
              value: rc.rootCauseId?.toString() ?? '',
            ))
        .toList();

    popupRootCauseList.assignAll(rootCauses);
    debugPrint("filterPopupRootCauses: Filtered ${rootCauses.length} root causes for causeId=$causeId");
  }

  void toggleRcaExpansion(int index) {
    isExpandedRca[index] = !(isExpandedRca[index] ?? false);
  }
}
