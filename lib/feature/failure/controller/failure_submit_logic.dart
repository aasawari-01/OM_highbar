import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../constants/colors.dart';
import '../../../constants/strings.dart';
import '../../../core/models/label_value.dart';
import '../../../service/auth_manager.dart';
import '../../../service/local_database_service.dart';
import '../../../service/session_controller.dart';
import 'failure_form_state.dart';
import 'failure_material_logic.dart';
import 'failure_rca_logic.dart';
import '../model/failure_list_response.dart';
import '../service/failure_service.dart';

mixin FailureSubmitLogic on GetxController, FailureFormState, FailureMaterialLogic, FailureRcaLogic {
  FailureService get _failureService => FailureService();
  void _refreshFailureListAfterSubmission(bool isStation);
  String _lookupValue(List<LabelValue> list, String? label, {String fallback = "0"});
  int _lookupLocationId(List<LabelValue> list, String? label);
  void showPendingJointInspectionPopup();
  int resolveNotificationId();

  List<Map<String, dynamic>> _jointInspectionHistoryForSubmit() {
    final notifId = resolveNotificationId();
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
      
      // Get locationTypeId instead of locationTypeCode
      final locationId = _lookupLocationId(locationTypeList, selectedLocation.value);
      debugPrint("locationId===$locationId");
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

      // Try to submit to API, if fails save locally for offline sync
      try {
        debugPrint("createStationFailure: Attempting API submission");
        final failureNo = await _failureService.createStationFailure(body);
        debugPrint("createStationFailure: API success, failureNo: $failureNo");
        
        _refreshFailureListAfterSubmission(isStation);
        
        EasyLoading.dismiss();
        Get.back();
        final message = (failureNo != null && failureNo.isNotEmpty)
            ? 'Station failure created: $failureNo'
            : AppStrings.failureCreated;
        Get.snackbar(AppStrings.success, message);
      } catch (apiError) {
        debugPrint("API submission failed, saving locally: $apiError");
        // Save to local database for later sync
        try {
          final dbService = LocalDatabaseService();
          final id = await dbService.insertPendingSubmission(body, 'Station');
          debugPrint("createStationFailure: Saved locally with id: $id");
          
          // Verify it was saved
          final pending = await dbService.getPendingSubmissions();
          debugPrint("createStationFailure: Total pending submissions: ${pending.length}");
          
          // Add to FailureList table so it shows in the list immediately
          final tempFailureId = DateTime.now().millisecondsSinceEpoch.toString();
          final failureItem = {
            'id': id, // Use pending submission ID
            'failureNo': tempFailureId,
            'failureDescription': body['FailureDescription'] ?? '',
            'functionalLocation': body['FuncationLocationIds']?.toString() ?? '',
            'statusName': 'Pending Sync',
            'failureOccuranceDateTime': body['ActualFailureOccuranceDate'] ?? '',
            'locationName': body['LocationId']?.toString() ?? '',
            'priority': body['PriorityId']?.toString() ?? '',
            'departmentName': body['DepartmentIds']?.toString() ?? '',
            'creationType': 'station',
            'syncStatus': 'offline',
            'lastSyncedAt': DateTime.now().toIso8601String(),
            'failureType': 'Station',
          };
          await dbService.insertFailureList([failureItem], 'Station');
          debugPrint("createStationFailure: Added to FailureList table for immediate display");
          
          _refreshFailureListAfterSubmission(isStation);
        } catch (dbError) {
          debugPrint("Error saving to local database: $dbError");
        }
        
        EasyLoading.dismiss();
        Get.back();
        Get.snackbar(
          "Saved Offline",
          "Failure saved locally. Will sync when internet is available.",
          backgroundColor: AppColors.orangeColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint("Create Station Failure Error: $e");
      Get.snackbar("Error", "An unexpected error occurred");
    }
  }

  Future<void> updateFailure() async {
    try {
      print("updateFailure");
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
        "Corr_NotificationTypeId": int.tryParse(notificationTypeList
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
            ? materialsForSubmit().map(buildMaterialPayload).toList()
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
          "isRequired": false,
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
            ? [
                ...dismantleMaterialsList.map((e) {
                  final recordId = materialRecordId(e);
                  final statusId = recordId > 0 ? 2 : 1;
                  
                  // Format dates to dd/MM/yyyy HH:mm format for API
                  String formatDismantleDate(dynamic date) {
                    if (date == null) return "";
                    if (date is DateTime) return DateFormat('dd/MM/yyyy HH:mm').format(date);
                    if (date is String) {
                      // Try to parse and reformat to dd/MM/yyyy HH:mm
                      try {
                        final dt = DateTime.parse(date); // ISO8601
                        return DateFormat('dd/MM/yyyy HH:mm').format(dt);
                      } catch (e) {
                        try {
                          final dt = DateFormat('dd/MM/yyyy HH:mm').parse(date);
                          return date; // Already in correct format
                        } catch (e2) {
                          try {
                            final dt = DateFormat('dd-MM-yyyy HH:mm').parse(date);
                            return DateFormat('dd/MM/yyyy HH:mm').format(dt);
                          } catch (e3) {
                            return date.toString();
                          }
                        }
                      }
                    }
                    return "";
                  }
                  
                  return {
                    "MaterialId": e['materialId'] ?? resolveMaterialId(e),
                    "MaterialValue": e['materialCode'] ?? "",
                    "MaterialReqId": recordId,
                    "OldSerialNumber": e['oldSerialNumber'] ?? "",
                    "NewSerialNumber": e['newSerialNumber'] ?? "",
                    "OldSerialNoDismantleDate": formatDismantleDate(e['oldSerialDismantleDate']),
                    "NewSerialNoInstallationDate": formatDismantleDate(e['newSerialInstallationDate']),
                    "InsertUpdateStatusId": statusId,
                    "CurrentInsertUpdateStatusId": statusId,
                    "Id": recordId,
                  };
                }).toList(),
                // Add deleted items with delete status
                ...deletedDismantleMaterialsList.map((e) {
                  return {
                    "MaterialId": e['materialId'] ?? resolveMaterialId(e),
                    "MaterialValue": e['materialCode'] ?? "",
                    "MaterialReqId": e['id'],
                    "OldSerialNumber": e['oldSerialNumber'] ?? "",
                    "NewSerialNumber": e['newSerialNumber'] ?? "",
                    "OldSerialNoDismantleDate": e['oldSerialDismantleDate'] ?? "",
                    "NewSerialNoInstallationDate": e['newSerialInstallationDate'] ?? "",
                    "InsertUpdateStatusId": 3, // 3 = Delete
                    "CurrentInsertUpdateStatusId": 3,
                    "Id": e['id'],
                  };
                }).toList(),
              ]
            : <Map<String, dynamic>>[]
      };
    print("payload===${payload["materialDismantleDetails"]}");
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
      const encoder = JsonEncoder.withIndent('  ');
      debugPrint(
        encoder.convert(payload),
        wrapWidth: 1024,
      );
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
}
