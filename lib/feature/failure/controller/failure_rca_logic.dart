import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/label_value.dart';
import '../../../constants/colors.dart';
import 'failure_form_state.dart';

mixin FailureRcaLogic on GetxController, FailureFormState {

  void showErrorDialog(String message);

  final rcaDetailsList = <Map<String, dynamic>>[].obs;
  final tempPopupRootCauses = <Map<String, dynamic>>[].obs;
  final tempPopupActionTakens = <Map<String, dynamic>>[].obs;
  final isExpandedRca = <int, bool>{}.obs;

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
      showErrorDialog('Please select or enter a Root Cause before adding.');
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
      showErrorDialog('Please select or enter an Action Taken before adding.');
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
}
