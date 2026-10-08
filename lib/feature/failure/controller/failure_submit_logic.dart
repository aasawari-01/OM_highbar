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
import '../../../utils/widgets/success_popup.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../core/controller/session_controller.dart';
import 'failure_form_state.dart';
import 'failure_material_logic.dart';
import 'failure_rca_logic.dart';
import '../service/failure_service.dart';
import '../service/si_offline_service.dart';
import '../service/je_offline_service.dart';
import '../../../service/network_service/network_errors.dart';
import '../view/failure_list_screen.dart';

mixin FailureSubmitLogic
on GetxController, FailureFormState, FailureMaterialLogic, FailureRcaLogic {
  FailureService get _failureService => FailureService();
  void refreshFailureListAfterSubmission(bool isStation);
  String lookupValue(dynamic list, String? label, {String fallback = "0"});
  int lookupLocationId(dynamic list, String? label);
  void showPendingJointInspectionPopup();
  int resolveNotificationId();
  bool get isMaintenanceFailure;

  /// Generates offline failure number in format: DEPT/MM-YYYY/XXXX
  Future<String> _generateOfflineFailureNumber(String deptCode) async {
    final now = DateTime.now();
    final monthYear = '${now.month.toString().padLeft(2, '0')}-${now.year}';

    try {
      // Query the database to get the highest failure number for this month
      final dbService = LocalDatabaseService();
      final db = await dbService.database;

      final results = await db.rawQuery(
          "SELECT failureNo FROM FailureList WHERE failureNo LIKE ? ORDER BY failureNo DESC LIMIT 1",
          ['$deptCode/$monthYear/%']);

      int nextSequence = 1;
      if (results.isNotEmpty) {
        final lastFailureNo = results.first['failureNo'] as String;
        // Extract the sequence number from the last failure number
        final parts = lastFailureNo.split('/');
        if (parts.length >= 3) {
          final lastSequence = int.tryParse(parts[2]) ?? 0;
          nextSequence = lastSequence + 1;
        }
      }

      return '$deptCode/$monthYear/${nextSequence.toString().padLeft(4, '0')}';
    } catch (e) {
      debugPrint("Error generating offline failure number: $e");
      // Fallback to timestamp-based approach if database query fails
      final sequence = DateTime.now().millisecondsSinceEpoch % 10000;
      return '$deptCode/$monthYear/${sequence.toString().padLeft(4, '0')}';
    }
  }

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
    if (isSectionIncharge && isMaintenanceFailure && isCreate) {
      await createMaintenanceFailure();
      return;
    }
    if (isSectionIncharge && isMaintenanceFailure && !isCreate) {
      await updateMaintenanceFailure();
      return;
    }
    await updateFailure();
  }

  Future<void> createStationFailure() async {
    if (!isStationController) {
      Get.snackbar(
        "Access Denied",
        "Only Station Controller can create station failure.",
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

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
    // The functional location may offer several systems / sub systems (API).
    if (fmecaSystemList.isNotEmpty &&
        (selectedFmecaSystem.value ?? '').isEmpty) {
      errors.add("System is required.");
    }
    if (fmecaSubsystemList.isNotEmpty &&
        (selectedFmecaSubsystem.value ?? '').isEmpty) {
      errors.add("Sub System is required.");
    }

    // FMECA validation for Section Incharge
    if (isSectionIncharge) {
      if (selectedFmecaSystem.value == null ||
          selectedFmecaSystem.value!.isEmpty ||
          selectedFmecaSystem.value == 'Select') {
        errors.add("System is required.");
      }
      if (selectedFmecaSubsystem.value == null ||
          selectedFmecaSubsystem.value!.isEmpty ||
          selectedFmecaSubsystem.value == 'Select') {
        errors.add("Subsystem is required.");
      }
      if (fmecaFrequency.value == 0) {
        errors.add("Frequency is required.");
      }
    }

    // Actual Failure Occurrence validation for all users
    if (selectedFailureOccurrenceDate.value == null) {
      errors.add("Actual Failure Occurrence is required.");
    }

    // Notification Type validation for all users
    // if (selectedNotificationType.value == null || selectedNotificationType.value!.isEmpty || selectedNotificationType.value == 'Select') {
    //   errors.add("Notification Type is required.");
    // }

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

    try {
      EasyLoading.show(status: 'Saving...');
      final createdBy =
          int.tryParse(await AuthManager().getUserId() ?? "0") ?? 0;

      final deptIdStr = lookupValue(
        departmentList,
        selectedDepartment.value,
        fallback: Get.find<SessionController>()
            .selectedDepartment
            .value
            ?.deptId
            ?.toString() ??
            "0",
      );

      // Get department code for offline failure number generation
      // Use the workCenter from functional location (e.g., SIG) as dept code
      final deptCode = 'SIG'; // Default to SIG for station failures

      final priorityId = lookupValue(priorityTypeList, selectedPriority.value);

      // Get locationTypeId instead of locationTypeCode
      final locationId =
      lookupLocationId(locationTypeList, selectedLocation.value);
      debugPrint("locationId===$locationId");
      final funcLocId =
      lookupValue(functionalLocationList, selectedFunctionalLocation.value);
      // Failure Category Type picked on the form (Safety, Security, ...).
      final stationCategoryId = lookupValue(
          apiFailureCategoryList, selectedFailureCategoryType.value);
      // Use logged-in user ID as failure reported by for station failures
      final failureReportedById =
          int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;
      final trainReplace = int.tryParse(trainReplaceNosController.text) ?? 0;

      final body = <String, dynamic>{
        "PriorityId": priorityId,
        ...departmentCreateFields(deptIdStr),
        "FailureDescription": description,
        "LocationId": locationId,
        "SubLocation": subLocationController.text.trim(),
        // System / Sub System come from the functional location's API pairs.
        "System": (selectedFmecaSystem.value ?? '').isNotEmpty
            ? selectedFmecaSystem.value
            : systemController.text.trim(),
        "SubSystem": selectedFmecaSubsystem.value ?? '',
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
        debugPrint(
            "createStationFailure: API endpoint: ${AppUrls.createStationFailure}");
        debugPrint("createStationFailure: Request payload: $body");
        final failureNo = await _failureService.createStationFailure(body);
        debugPrint("createStationFailure: API success, failureNo: $failureNo");

        // Save successfully created failure to local database for display
        try {
          final dbService = LocalDatabaseService();
          final locationId = body['LocationId'];
          final locationName = locationTypeList
              .firstWhere((e) => e.value == locationId.toString(),
              orElse: () => LabelValue(
                  label: locationId.toString(),
                  value: locationId.toString()))
              .label;

          final failureItem = {
            'id': DateTime.now().millisecondsSinceEpoch,
            'failureNo': failureNo,
            'failureDescription': body['FailureDescription'] ?? '',
            'functionalLocation':
            body['FuncationLocationIds']?.toString() ?? '',
            'statusName': 'Open',
            'failureOccuranceDateTime':
            body['ActualFailureOccuranceDate'] ?? '',
            'actualFailureOccuranceDatetime':
            body['ActualFailureOccuranceDate'] ?? '',
            'subLocation': body['SubLocation'] ?? '',
            'trainId': body['TrainId'] ?? '',
            'system': body['System'] ?? '',
            'locationName': locationName,
            'priority': body['PriorityId']?.toString() ?? '',
            'departmentName': body['DepartmentIds']?.toString() ?? '',
            'creationType': 'station',
            'syncStatus': 'synced',
            'lastSyncedAt': DateTime.now().toIso8601String(),
            'failureType': 'Station',
          };
          await dbService.insertFailureList([failureItem], 'Station');
          debugPrint(
              "createStationFailure: Added successfully created failure to local DB");
        } catch (dbError) {
          debugPrint("Error saving successful failure to local DB: $dbError");
        }

        refreshFailureListAfterSubmission(isStation);

        // Wait for refresh to complete before dismissing
        await Future.delayed(const Duration(milliseconds: 500));

        EasyLoading.dismiss();
        Get.back();
        showFailureCreatedPopup(type: 'Station', failureNo: failureNo);
      } catch (apiError) {
        debugPrint("API submission failed, saving locally: $apiError");
        // Save to local database for later sync
        try {
          final dbService = LocalDatabaseService();
          final id = await dbService.insertPendingSubmission(body, 'Station');
          debugPrint("createStationFailure: Saved locally with id: $id");

          // Verify it was saved
          final pending = await dbService.getPendingSubmissions();
          debugPrint(
              "createStationFailure: Total pending submissions: ${pending.length}");

          // Add to FailureList table so it shows in the list immediately
          final locationId = body['LocationId'];
          final locationName = locationTypeList
              .firstWhere((e) => e.value == locationId.toString(),
              orElse: () => LabelValue(
                  label: locationId.toString(),
                  value: locationId.toString()))
              .label;

          // The server creates one failure per selected department, so each
          // department gets its own offline entry (max 3). The single
          // functional location belongs to one department (its work center):
          // only that entry shows it. Entry ids are negative and encode the
          // pending submission id: -(submissionId * 10 + index).
          final deptLabels = selectedDepartments.isNotEmpty
              ? selectedDepartments.toList()
              : <String>[
            if ((selectedDepartment.value ?? '').isNotEmpty)
              selectedDepartment.value!
          ];
          final flId = int.tryParse(funcLocId) ?? 0;
          final flRow = flId > 0
              ? await dbService.getFailureFunctionalLocationRow(flId)
              : null;
          final flWorkCenter =
          (flRow?['WorkCenter'] ?? '').toString().trim().toUpperCase();
          final labels = deptLabels.isEmpty ? <String>[''] : deptLabels;
          for (var i = 0; i < labels.length && i < 3; i++) {
            final label = labels[i];
            final deptId = int.tryParse(lookupValue(departmentList, label)) ?? 0;
            final code =
                (deptId > 0 ? await dbService.getDeptCodeById(deptId) : null) ??
                    deptCode;
            final offlineFailureNo = await _generateOfflineFailureNumber(code);
            final showsFl = labels.length <= 1 ||
                (flWorkCenter.isNotEmpty && flWorkCenter == code.toUpperCase());

            final failureItem = {
              'id': -(id * 10 + i),
              'failureNo': offlineFailureNo,
              'failureDescription': body['FailureDescription'] ?? '',
              'functionalLocation':
              showsFl ? (selectedFunctionalLocation.value ?? '') : '',
              'statusName': 'Pending Sync',
              'failureOccuranceDateTime':
              body['ActualFailureOccuranceDate'] ?? '',
              'actualFailureOccuranceDatetime':
              body['ActualFailureOccuranceDate'] ?? '',
              'subLocation': body['SubLocation'] ?? '',
              'trainId': body['TrainId'] ?? '',
              'system': body['System'] ?? '',
              'locationName': locationName,
              'priority': selectedPriority.value ?? '',
              'departmentName': label,
              'creationType': 'station',
              'syncStatus': 'offline',
              'lastSyncedAt': DateTime.now().toIso8601String(),
              'failureType': 'Station',
            };
            await dbService.insertFailureList([failureItem], 'Station');
            debugPrint(
                "createStationFailure: Added offline entry for '$label' with failureNo: $offlineFailureNo");
          }

          refreshFailureListAfterSubmission(isStation);
        } catch (dbError) {
          debugPrint("Error saving to local database: $dbError");
        }

        EasyLoading.dismiss();
        Get.back();
        showResultPopup(
          title: "Saved Offline",
          message: "Failure saved locally. Will sync when internet is available.",
          icon: Icons.cloud_off_outlined,
          iconColor: AppColors.orangeColor,
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint("Create Station Failure Error: $e");
      Get.snackbar(AppStrings.error, "An unexpected error occurred");
    }
  }

  Future<void> createMaintenanceFailure() async {
    if (!isSectionIncharge) {
      Get.snackbar(
        "Access Denied",
        "Only Section Incharge can create maintenance failure.",
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: AppColors.white1,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Prevent multiple submissions
    if (isSubmitting.value) {
      debugPrint("createMaintenanceFailure: Already submitting, ignoring duplicate request");
      return;
    }

    List<String> errors = [];

    // Basic validation
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

    // // FMECA validation for Section Incharge
    // if (selectedSystem.value == null ||
    //     selectedSystem.value!.isEmpty ||
    //     selectedSystem.value == 'Select') {
    //   errors.add("System is required.");
    // }
    // if (selectedSubsystem.value == null ||
    //     selectedSubsystem.value!.isEmpty ||
    //     selectedSubsystem.value == 'Select') {
    //   errors.add("Subsystem is required.");
    // }

    // Actual Failure Occurrence validation
    if (selectedFailureOccurrenceDate.value == null) {
      errors.add("Actual Failure Occurrence is required.");
    }

    // Notification Type validation
    if (selectedNotificationType.value == null ||
        selectedNotificationType.value!.isEmpty ||
        selectedNotificationType.value == 'Select') {
      errors.add("Notification Type is required.");
    }

    // Service Affected validation
    if (isServiceAffected.value) {
      if (trainDelayMinController.text.trim().isEmpty)
        errors.add("Train Delay in Min is required.");
      if (trainDelayNosController.text.trim().isEmpty)
        errors.add("Train Delay (NOS) is required.");
      if (trainCancelNosController.text.trim().isEmpty)
        errors.add("Train Cancel (NOS) is required.");
      if (trainWithdrawalNosController.text.trim().isEmpty)
        errors.add("Train Withdrawal (NOS) is required.");
      if (trainReplaceNosController.text.trim().isEmpty)
        errors.add("Train Replace (NOS) is required.");
    }

    // Passenger Deboarding validation
    if (isPassengerDeboarding.value) {
      if (trainDeboardedNosController.text.trim().isEmpty)
        errors.add("Train Deboarded (NOS) is required.");
    }

    // Passenger Affected validation
    if (isPassengerAffected.value) {
      if (numberOfPassengerAffectedController.text.trim().isEmpty)
        errors.add("Number Of Passenger Affected is required.");
      if (trappedDurationController.text.trim().isEmpty)
        errors.add("Trapped Duration is required.");
      if (rescuedDurationController.text.trim().isEmpty)
        errors.add("Rescued Duration is required.");
    }

    // Department 3 specific validation
    if (departmentId.value == 3) {
      if (selectedNatureOfWork.value == null ||
          selectedNatureOfWork.value!.isEmpty ||
          selectedNatureOfWork.value == 'Select') {
        errors.add("Nature of Work is required.");
      }
      if (trainRunningKmController.text.trim().isEmpty)
        errors.add("Train Running KM is required.");
    }

    // System Downtime validation for departments 13 and 16
    if ((departmentId.value == 13 || departmentId.value == 16) &&
        isServiceAffected.value) {
      if (selectedSystemDowntime.value == null) {
        errors.add("System Downtime is required.");
      }
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

    try {
      isSubmitting.value = true;
      EasyLoading.show(status: 'Saving...');
      final createdBy =
          int.tryParse(await AuthManager().getUserId() ?? "0") ?? 0;
      final userName = await AuthManager().getUserName() ?? '';

      // Map dropdown values to IDs
      final priorityId = lookupValue(priorityTypeList, selectedPriority.value);
      final deptId = lookupValue(departmentList, selectedDepartment.value);
      final locationTypeId =
      lookupValue(locationTypeList, selectedLocation.value);
      final functionLocationId =
      lookupValue(functionalLocationList, selectedFunctionalLocation.value);
      final equipmentId =
      lookupValue(equipmentList, selectedEquipmentNumber.value);
      // The form's "Notification Type" (Failure, Snag, ...) is the corrective
      // notification type, as on the update request (Corr_NotificationTypeId).
      final corrNotificationTypeId = lookupValue(
          corrNotificationTypeList, selectedNotificationType.value);
      // NotificationTypeId is the "Failure Type" shown for department 3 only.
      final failureTypes = apiNotificationTypeList.isNotEmpty
          ? apiNotificationTypeList
          : failureCategoryTypeList;
      final notificationTypeId = departmentId.value == 3
          ? lookupValue(failureTypes, selectedFailureCategoryType.value)
          : "0";
      // Assign to the selected Person Responsible; fall back to the
      // logged-in user when none is selected.
      final selectedPersonId =
          int.tryParse(lookupValue(userList, selectedPersonResponsible.value));
      final assignedUserId = (selectedPersonId != null && selectedPersonId > 0)
          ? selectedPersonId
          : createdBy;
      // Look up in the same list the Nature of Work dropdown shows.
      final natureOfWorkId = lookupValue(
          apiNatureOfWorkList.isNotEmpty ? apiNatureOfWorkList : natureOfWorkList,
          selectedNatureOfWork.value);

      // Format date
      final actualFailureOccuranceOn = DateFormat("dd/MM/yyyy HH:mm")
          .format(selectedFailureOccurrenceDate.value!);

      // Format system downtime if available
      final systemDowntime = selectedSystemDowntime.value != null
          ? DateFormat("dd/MM/yyyy HH:mm").format(selectedSystemDowntime.value!)
          : "";

      // Build API request body according to specification
      final requestBody = {
        'failureDescription': description,
        'natureOfWorkId': int.tryParse(natureOfWorkId) ?? 0,
        'trainRunningKM': trainRunningKmController.text.trim().isEmpty
            ? null
            : trainRunningKmController.text.trim(),
        'notificationTypeId': int.tryParse(notificationTypeId) ?? 0,
        'functionLocationId': int.tryParse(functionLocationId) ?? 0,
        'equipmentId': int.tryParse(equipmentId) ?? 0,
        'actualFailureOccuranceOn': actualFailureOccuranceOn,
        'assignedUserId': int.tryParse(assignedUserId.toString()) ?? createdBy,
        'isServiceAffected': isServiceAffected.value,
        'trainDelayInMin':
        int.tryParse(trainDelayMinController.text.trim()) ?? 0,
        'trainDelayInNo':
        int.tryParse(trainDelayNosController.text.trim()) ?? 0,
        'noOfTranWithdrawal':
        int.tryParse(trainWithdrawalNosController.text.trim()) ?? 0,
        'noOfTranCancel':
        int.tryParse(trainCancelNosController.text.trim()) ?? 0,
        'noOfTrainReplace':
        int.tryParse(trainReplaceNosController.text.trim()) ?? 0,
        'isPassengerDeboarding': isPassengerDeboarding.value,
        'noofTrainDeboarded':
        int.tryParse(trainDeboardedNosController.text.trim()) ?? 0,
        'isOHEReq': isOheRequired.value,
        'isSICReq': isSicRequired.value,
        'isJointInspectionReq': isJointInspection.value,
        'assignedUserId_JI': assignedUserIdJI.value,
        'deptId_JI': deptIdJI.value,
        'deptId': int.tryParse(deptId) ?? 0,
        'remarkJE': remarkJE.value ?? 0,
        'isPassengerAffected': isPassengerAffected.value,
        'noOfPassengerAffected': isPassengerAffected.value
            ? int.tryParse(numberOfPassengerAffectedController.text.trim())
            : null,
        'trappedDuration': isPassengerAffected.value
            ? trappedDurationController.text.trim()
            : null,
        'rescuedDuration': isPassengerAffected.value
            ? rescuedDurationController.text.trim()
            : null,
        'locationTypeId': locationTypeId,
        'systemDowntime': systemDowntime,
        'measurementPointIds': measurementPointIdsController.text.trim(),
        'priorityId': int.tryParse(priorityId) ?? 0,
        'assignedUseeName': userName,
        'locationFailure': subLocationController.text.trim(),
        'corrNotificationTypeId': int.tryParse(corrNotificationTypeId) ?? 0,
        // The Section Incharge form fills the FMECA fields (from the API).
        'system': selectedFmecaSystem.value ?? selectedSystem.value ?? '',
        'subSystem':
        selectedFmecaSubsystem.value ?? selectedSubsystem.value ?? '',
        'frequency': fmecaFrequency.value ?? frequencyValue.value ?? 0,
      };

      debugPrint("Maintenance Form Submission Request: $requestBody");

      Map<String, dynamic> response;
      try {
        response =
        await _failureService.submitMaintenanceNotificationForm(requestBody);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // No connection: save the failure locally (shown in the list with an
        // orange dot) and send it when internet returns.
        await _saveMaintenanceOffline(requestBody, int.tryParse(deptId) ?? 0);
        EasyLoading.dismiss();
        isSubmitting.value = false;
        refreshFailureListAfterSubmission(false);
        Get.offAll(() => const FailureListScreen(failureType: 'Maintenance'));
        showResultPopup(
          title: "Saved Offline",
          message: "Failure saved locally. Will sync when internet is available.",
          icon: Icons.cloud_off_outlined,
          iconColor: AppColors.orangeColor,
        );
        return;
      }

      EasyLoading.dismiss();
      isSubmitting.value = false;

      if (response['responseCode'] == 200) {
        final failureNo = response['responseOutput'] as String? ?? '';
        // notificationId can be used for future reference if needed
        // final notificationId = response['data'] as int? ?? 0;

        refreshFailureListAfterSubmission(false);
        Get.offAll(() => const FailureListScreen(failureType: 'Maintenance'));
        showFailureCreatedPopup(type: 'Maintenance', failureNo: failureNo);
      } else {
        Get.snackbar(
          "Error",
          response['responseMessage'] ?? "Failed to create maintenance failure",
          backgroundColor: AppColors.red.withValues(alpha: 0.9),
          colorText: AppColors.white1,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      isSubmitting.value = false;
      debugPrint("Create Maintenance Failure Error: $e");
      Get.snackbar(AppStrings.error, "An unexpected error occurred: $e");
    }
  }

  /// Queues a maintenance failure created without internet and adds it to the
  /// list (orange dot, negative id = -queueId) until it is sent.
  Future<void> _saveMaintenanceOffline(
      Map<String, dynamic> requestBody, int deptId) async {
    final db = LocalDatabaseService();
    final queueId = await SiOfflineService().queueCreate(requestBody, labels: {
      'funcLocation': selectedFunctionalLocation.value ?? '',
      'equipmentName': selectedEquipmentNumber.value ?? '',
      'locationName': selectedLocation.value ?? '',
      'priorityType': selectedPriority.value ?? '',
      'personResponsible': selectedPersonResponsible.value ?? '',
      'notificationType': selectedNotificationType.value ?? '',
    });
    final code = (deptId > 0 ? await db.getDeptCodeById(deptId) : null) ?? 'SIG';
    final failureNo = await _generateOfflineFailureNumber(code);
    await db.insertFailureList([
      {
        'id': -queueId,
        'failureNo': failureNo,
        'failureDescription': requestBody['failureDescription'] ?? '',
        'functionalLocation': selectedFunctionalLocation.value ?? '',
        'statusName': 'Pending Sync',
        'failureOccuranceDateTime': requestBody['actualFailureOccuranceOn'] ?? '',
        'actualFailureOccuranceDatetime': requestBody['actualFailureOccuranceOn'] ?? '',
        'subLocation': requestBody['locationFailure'] ?? '',
        'system': requestBody['system'] ?? '',
        'locationName': selectedLocation.value ?? '',
        'priority': selectedPriority.value ?? '',
        'departmentName': selectedDepartment.value ?? '',
        'creationType': 'Manual',
        'syncStatus': 'offline',
        'lastSyncedAt': DateTime.now().toIso8601String(),
        'failureType': 'Maintenance',
      }
    ], 'Maintenance');
  }

  Future<void> updateMaintenanceFailure() async {
    // Prevent multiple submissions
    if (isSubmitting.value) {
      debugPrint("updateMaintenanceFailure: Already submitting, ignoring duplicate request");
      return;
    }

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
    if (selectedFunctionalLocation.value == null ||
        selectedFunctionalLocation.value!.isEmpty ||
        selectedFunctionalLocation.value == 'Select') {
      errors.add("Functional Location is required.");
    }
    if (selectedFailureOccurrenceDate.value == null) {
      errors.add("Actual Failure Occurrence is required.");
    }
    if (selectedNotificationType.value == null ||
        selectedNotificationType.value!.isEmpty ||
        selectedNotificationType.value == 'Select') {
      errors.add("Notification Type is required.");
    }

    if (isServiceAffected.value) {
      if (trainDelayMinController.text.trim().isEmpty) errors.add("Train Delay in Min is required.");
      if (trainDelayNosController.text.trim().isEmpty) errors.add("Train Delay (NOS) is required.");
      if (trainCancelNosController.text.trim().isEmpty) errors.add("Train Cancel (NOS) is required.");
      if (trainWithdrawalNosController.text.trim().isEmpty) errors.add("Train Withdrawal (NOS) is required.");
      if (trainReplaceNosController.text.trim().isEmpty) errors.add("Train Replace (NOS) is required.");
    }
    if (isPassengerDeboarding.value && trainDeboardedNosController.text.trim().isEmpty) {
      errors.add("Train Deboarded (NOS) is required.");
    }
    if (isPassengerAffected.value) {
      if (numberOfPassengerAffectedController.text.trim().isEmpty) errors.add("Number Of Passenger Affected is required.");
      if (trappedDurationController.text.trim().isEmpty) errors.add("Trapped Duration is required.");
      if (rescuedDurationController.text.trim().isEmpty) errors.add("Rescued Duration is required.");
    }

    final deptId = int.tryParse(lookupValue(departmentList, selectedDepartment.value)) ?? 0;
    if (deptId == 3) {
      if (selectedNatureOfWork.value == null || selectedNatureOfWork.value!.isEmpty || selectedNatureOfWork.value == 'Select') {
        errors.add("Nature of Work is required.");
      }
      if (selectedFailureCategoryType.value == null || selectedFailureCategoryType.value!.isEmpty || selectedFailureCategoryType.value == 'Select') {
        errors.add("Failure Type is required.");
      }
      if (trainRunningKmController.text.trim().isEmpty) {
        errors.add("Train Running KM is required.");
      }
    }
    if ((deptId == 13 || deptId == 16) && isServiceAffected.value && selectedSystemDowntime.value == null) {
      errors.add("System Downtime is required.");
    }

    if (errors.isNotEmpty) {
      Get.snackbar('Validation Error', errors.first,
          backgroundColor: AppColors.red.withValues(alpha: 0.9),
          colorText: AppColors.white1,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isSubmitting.value = true;
      EasyLoading.show(status: 'Updating...');
      final createdBy = int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;
      final userName = await AuthManager().getUserName() ?? '';

      String? nullableId(String value) =>
          value.trim().isEmpty || value.trim() == '0' ? null : value.trim();

      final priorityId = int.tryParse(lookupValue(priorityTypeList, selectedPriority.value));
      final departmentValue = lookupValue(departmentList, selectedDepartment.value);
      final locationValue = lookupValue(locationTypeList, selectedLocation.value);
      final functionLocationValue = lookupValue(functionalLocationList, selectedFunctionalLocation.value);
      final equipmentValue = lookupValue(equipmentList, selectedEquipmentNumber.value);
      final corrNotificationTypeId = int.tryParse(lookupValue(corrNotificationTypeList, selectedNotificationType.value));
      final natureId = deptId == 3
          ? int.tryParse(
        lookupValue(natureOfWorkList, selectedNatureOfWork.value),
      ) ?? 0
          : 0;

      final failureTypeId = deptId == 3
          ? int.tryParse(
        lookupValue(notificationTypeList, selectedFailureCategoryType.value),
      ) ?? 0
          : 0;

      final assignedUserId = int.tryParse(
        lookupValue(userList, selectedPersonResponsible.value),
      );
      final frequency = int.tryParse(fmecaFrequencyController.text.trim()) ?? 0;
      final systemDowntime = selectedSystemDowntime.value == null
          ? ''
          : DateFormat('dd/MM/yyyy HH:mm').format(selectedSystemDowntime.value!);

      // A failure from the local copy carries only the numeric id here; the
      // update call needs the encrypted one. Without a connection the numeric
      // id stays and the queued update resolves it when it is sent.
      var notificationCode = encryptedId.value;
      if (RegExp(r'^\d+$').hasMatch(notificationCode)) {
        try {
          notificationCode = await SiOfflineService()
              .encryptedIdFor(notificationId: resolveNotificationId());
        } catch (e) {
          if (!isNetworkError(e)) rethrow;
        }
      }

      final payload = <String, dynamic>{
        'NotificationCode': notificationCode,
        'NotificationId': resolveNotificationId(),
        'Description': failureDescriptionController.text.trim(),
        'NatureOfWorkId': natureId,
        'TrainRunningKM': deptId == 3 ? double.tryParse(trainRunningKmController.text.trim()) : null,
        'NotificationTypeId': failureTypeId,
        'FunctionLocationId': int.tryParse(functionLocationValue) ?? 0,
        'EquipmentId': nullableId(equipmentValue) == null ? null : int.tryParse(equipmentValue),
        'Frequency': frequency,
        'frequency': frequency,
        'ActualFailureOccuranceOn': DateFormat('dd/MM/yyyy HH:mm').format(selectedFailureOccurrenceDate.value!),
        'AssignedUserId': assignedUserId,
        'IsServiceAffected': isServiceAffected.value,
        'TrainDelayInMin': isServiceAffected.value ? int.tryParse(trainDelayMinController.text.trim()) : null,
        'TrainDelayInNo': isServiceAffected.value ? int.tryParse(trainDelayNosController.text.trim()) : null,
        'NoOfTranWithdrawal': isServiceAffected.value ? int.tryParse(trainWithdrawalNosController.text.trim()) : null,
        'NoOfTranCancel': isServiceAffected.value ? int.tryParse(trainCancelNosController.text.trim()) : null,
        'NoOfTrainReplace': isServiceAffected.value ? int.tryParse(trainReplaceNosController.text.trim()) : null,
        'IsPassengerDeboarding': isPassengerDeboarding.value,
        'NoofTrainDeboarded': isPassengerDeboarding.value ? int.tryParse(trainDeboardedNosController.text.trim()) : null,
        'IsOHEReq': isOheRequired.value,
        'IsSICReq': isSicRequired.value,
        'IsJointInspectionReq': isJointInspection.value,
        'AssignedUserId_JI': assignedUserIdJI.value,
        'DeptId_JI': deptIdJI.value,
        'DeptId': deptId,
        'Remark_JE': remarkJE.value ?? '',
        'CreatedBy': createdBy,
        'IsPassengerAffected': isPassengerAffected.value,
        'NoOfPassengerAffected': isPassengerAffected.value ? int.tryParse(numberOfPassengerAffectedController.text.trim()) : null,
        'TrappedDuration': isPassengerAffected.value ? trappedDurationController.text.trim() : null,
        'RescuedDuration': isPassengerAffected.value ? rescuedDurationController.text.trim() : null,
        'LocationTypeId':  maintenanceLocationTypeId.value,
        'SystemDowntime': systemDowntime,
        'MeasurementPointIds': measurementPointIdsController.text.trim(),
        'PriorityId': priorityId,
        'LocationFailure': subLocationController.text.trim(),
        'Corr_NotificationTypeId': corrNotificationTypeId,
        'System': systemController.text.trim(),
        'SubSystem': subsystemController.text.trim(),
      };

      debugPrint('Maintenance update payload: $payload');
      Map<String, dynamic> response;
      var savedOffline = false;
      try {
        response = await _failureService.updateMaintenanceFailure(payload);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // No connection: keep the change locally, it is sent when internet returns.
        await SiOfflineService().queueUpdate(payload);
        savedOffline = true;
        response = {
          'responseMessage':
          'Saved offline. It will be sent when internet is available.'
        };
      }
      EasyLoading.dismiss();
      isSubmitting.value = false;

      refreshFailureListAfterSubmission(false);
      // Leave the form first: Get.back() after a snackbar would only pop the
      // snackbar and leave the user on this page.
      Get.back(result: true);
      Get.snackbar(savedOffline ? 'Saved Offline' : 'Success',
          response['responseMessage']?.toString() ?? 'Data Edit Successfully',
          backgroundColor: savedOffline ? AppColors.orangeColor : AppColors.green,
          colorText: AppColors.white1);
    } catch (e) {
      EasyLoading.dismiss();
      isSubmitting.value = false;
      debugPrint('Update Maintenance Failure Error: $e');
      Get.snackbar(AppStrings.error, e.toString(),
          backgroundColor: AppColors.red.withValues(alpha: 0.9),
          colorText: AppColors.white1);
    }
  }

  Future<void> updateFailure() async {
    try {
      debugPrint("updateFailure");
      List<String> errors = [];

      // Get current logged-in user for assigned user
      final createdBy =
          int.tryParse(await AuthManager().getUserId() ?? "0") ?? 0;

      if (failureRectificationDetailsController.text.trim().isEmpty) {
        errors.add("Failure Rectification Details is required.");
      }

      if (isCloseUserStatusBlocked &&
          (selectedUserStatus.value
                  ?.trim()
                  .toLowerCase()
                  .startsWith('close') ??
              false)) {
        showPendingJointInspectionPopup();
        return;
      }

      if (selectedNotificationType.value == null ||
          selectedNotificationType.value!.isEmpty ||
          selectedNotificationType.value == 'Select') {
        errors.add("Notification Type is required.");
      }

      if (isTripAffected.value) {
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

      if (selectedUserStatus.value == "Under Observation") {
        if (selectedUnderObservationDate.value == null) {
          errors.add(
              "Under Observation Date is required when status is 'Under Observation'.");
        }
      }

      if (isSparePartReplaced.value) {
        if (replacedMaterialsList.isEmpty) {
          errors.add(
              "Please add at least one Replaced Material since 'Spare Part Replaced' is enabled.");
        } else {
          for (var mat in replacedMaterialsList) {
            final usedQtyStr = mat['usedQty']?.toString().trim() ?? "";
            if (usedQtyStr.isEmpty) {
              errors
                  .add("Used Quantity is required for all replaced materials.");
              break;
            }
          }
        }
      }

      // RCA validation only for Station failures, not Maintenance
      if (isStation && isRcaRequired.value) {
        if (rcaDetailsList.isEmpty) {
          errors.add("Please add at least one RCA detail.");
        } else {
          for (int i = 0; i < rcaDetailsList.length; i++) {
            var rca = rcaDetailsList[i];

            // Check for JE-specific fields (subsystem, failureCategory)
            final subsystem = rca['subsystem']?.toString().trim() ?? "";
            final failureCategory =
                rca['failureCategory']?.toString().trim() ?? "";

            // Check for RST-specific fields (objectPart, fault)
            final objPart = rca['objectPart']?.toString().trim() ?? "";
            final objPartText = rca['objectPartText']?.toString().trim() ?? "";
            final fault = rca['fault']?.toString().trim() ?? "";
            final faultText = rca['faultText']?.toString().trim() ?? "";

            // Validate based on failure type
            // JE failures use subsystem + failureCategory
            // RST failures use objectPart + fault
            if (subsystem.isNotEmpty || failureCategory.isNotEmpty) {
              // JE RCA validation
              if (subsystem.isEmpty) {
                errors.add("Subsystem is required in RCA item ${i + 1}.");
              }
              if (failureCategory.isEmpty) {
                errors
                    .add("Failure Category is required in RCA item ${i + 1}.");
              }
            } else if (objPart.isNotEmpty ||
                objPartText.isNotEmpty ||
                fault.isNotEmpty ||
                faultText.isNotEmpty) {
              // RST RCA validation
              if (objPart.isEmpty && objPartText.isEmpty) {
                errors.add("Object Part is required in RCA item ${i + 1}.");
              }
              if (fault.isEmpty && faultText.isEmpty) {
                errors.add("Fault is required in RCA item ${i + 1}.");
              }
            } else {
              // No valid RCA data
              errors.add(
                  "Either Subsystem or Object Part is required in RCA item ${i + 1}.");
            }

            final List rootCauses = rca['rootCauses'] ?? [];
            final List actionTakens = rca['actionTakens'] ?? [];

            if (rootCauses.isEmpty) {
              errors.add(
                  "At least one Root Cause is required in RCA item ${i + 1}.");
            }
            if (actionTakens.isEmpty) {
              errors.add(
                  "At least one Action Taken is required in RCA item ${i + 1}.");
            }
          }
        }
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

      // --- END OF VALIDATION ---

      EasyLoading.show(status: 'Updating...');

      final newJeRemark = failureDescriptionController.text.trim();

      // Resolve User Status value/ID (e.g. "27" for Closed)
      String userStatusValue = "0";
      final trimmedSelectedStatus =
          (selectedUserStatus.value ?? "").trim().toLowerCase();

      LabelValue? matchedStatus;
      for (final e in userStatusJeList) {
        if ((e.label ?? "").trim().toLowerCase() == trimmedSelectedStatus) {
          matchedStatus = e;
          break;
        }
      }
      if (matchedStatus == null) {
        for (final e in userStatusList) {
          if ((e.label ?? "").trim().toLowerCase() == trimmedSelectedStatus) {
            matchedStatus = e;
            break;
          }
        }
      }

      if (matchedStatus?.value != null &&
          matchedStatus!.value!.isNotEmpty &&
          matchedStatus.value != "0") {
        userStatusValue = matchedStatus.value!;
      } else if (int.tryParse(selectedUserStatus.value ?? "") != null) {
        userStatusValue = selectedUserStatus.value!;
      } else if (trimmedSelectedStatus.startsWith("close")) {
        userStatusValue = "27"; // Closed
      } else if (trimmedSelectedStatus.contains("observation")) {
        userStatusValue = "26"; // Under Observation
      } else if (trimmedSelectedStatus.contains("process")) {
        userStatusValue = "28"; // In-Process
      } else if (trimmedSelectedStatus.contains("escalat")) {
        userStatusValue = "29"; // Escalated
      }

      final changeNotifictionJE = {
        "Id": encryptedId.value.isEmpty ? "0" : encryptedId.value,
        "Description": failureDescriptionController.text.trim().isNotEmpty
            ? failureDescriptionController.text.trim()
            : null,
        "Category": failureCategory.value,
        "Remark_JE": newJeRemark,
        "NatureOfWorkId": int.tryParse(natureOfWorkList
                .firstWhere((e) => e.label == selectedNatureOfWork.value,
                    orElse: () => LabelValue(value: "0"))
                .value ??
            "0"),
        "TrainRunningKM": trainRunningKmController.text.isEmpty
            ? null
            : trainRunningKmController.text,
        "NotificationTypeId": int.tryParse(notificationTypeList
                .firstWhere(
                    (e) => e.label == selectedNotificationType.value,
                    orElse: () => corrNotificationTypeList.firstWhere(
                        (e) => e.label == selectedNotificationType.value,
                        orElse: () => LabelValue(value: "0")))
                .value ??
            "0"),
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
        "OHERequired": isOheRequired.value,
        "SICRequired": isSicRequired.value,
        "SICFailureType": 0,
        "SICResponsiblePerson": 0,
        "PTWRequired": isPtwRequired.value,
        "PTWNo": ptwNumberController.text,
        "IsServiceAffected": isServiceAffected.value,
        "TrainDelayInMin": int.tryParse(trainDelayMinController.text),
        "TrainDelayInNo": int.tryParse(trainDelayNosController.text),
        "NoOfTranWithdrawal":
            int.tryParse(trainWithdrawalNosController.text),
        "NoOfTranCancel": int.tryParse(trainCancelNosController.text),
        "NoOfTrainReplace": int.tryParse(trainReplaceNosController.text),
        "IsPassengerDeboarding": isPassengerDeboarding.value,
        "NoofTrainDeboarded":
            int.tryParse(trainDeboardedNosController.text),
        "System": isSectionIncharge
            ? (selectedFmecaSystem.value ?? "")
            : (systemController.text.isNotEmpty
                ? systemController.text
                : (rcaDetailsList.isNotEmpty &&
                        rcaDetailsList[0]['system'] != null
                    ? rcaDetailsList[0]['system']
                    : "")),
        "SubSystem": isSectionIncharge
            ? (selectedFmecaSubsystem.value ?? "")
            : (subsystemController.text.isNotEmpty
                ? subsystemController.text
                : (rcaDetailsList.isNotEmpty &&
                        rcaDetailsList[0]['subsystem'] != null
                    ? rcaDetailsList[0]['subsystem']
                    : "")),
        "Frequency": isSectionIncharge
            ? fmecaFrequency.value
            : 0,
        "failureCategoryId": rcaDetailsList.isNotEmpty
            ? int.tryParse(rcaDetailsList[0]['FailureCategoryId']?.toString() ??
                    "0") ??
                0
            : int.tryParse(rcaFailureCategoryList
                    .firstWhere(
                        (e) => e.label == selectedRcaFailureCategory.value,
                        orElse: () => LabelValue(value: "0"))
                    .value ??
                "0") ??
                0,
        "FailureCategory": rcaDetailsList.isNotEmpty
            ? rcaDetailsList[0]['failureCategory'] ?? ""
            : (selectedRcaFailureCategory.value ?? ""),
        "causeOfFailureId": rcaDetailsList.isNotEmpty &&
                rcaDetailsList[0]['rootCauses'] is List &&
                (rcaDetailsList[0]['rootCauses'] as List).isNotEmpty
            ? int.tryParse(
                    rcaDetailsList[0]['rootCauses'][0]['causeId']?.toString() ??
                        "0") ??
                0
            : 0,
        "Cause": rcaDetailsList.isNotEmpty &&
                rcaDetailsList[0]['rootCauses'] is List &&
                (rcaDetailsList[0]['rootCauses'] as List).isNotEmpty
            ? rcaDetailsList[0]['rootCauses'][0]['cause'] ?? ""
            : "",
        "CauseOfFailureOtherText": rcaDetailsList.isNotEmpty &&
                rcaDetailsList[0]['rootCauses'] is List &&
                (rcaDetailsList[0]['rootCauses'] as List).isNotEmpty
            ? rcaDetailsList[0]['rootCauses'][0]['causeText'] ?? ""
            : "",
        "rootCauseIdN": rcaDetailsList.isNotEmpty &&
                rcaDetailsList[0]['rootCauses'] is List &&
                (rcaDetailsList[0]['rootCauses'] as List).isNotEmpty
            ? int.tryParse(rcaDetailsList[0]['rootCauses'][0]['rootCauseId']
                    ?.toString() ??
                "0") ??
                0
            : 0,
        "rootCauseId": rcaDetailsList.isNotEmpty &&
                rcaDetailsList[0]['rootCauses'] is List &&
                (rcaDetailsList[0]['rootCauses'] as List).isNotEmpty
            ? int.tryParse(rcaDetailsList[0]['rootCauses'][0]['rootCauseId']
                    ?.toString() ??
                "0") ??
                0
            : 0,
        "rootCauseTextN": rcaDetailsList.isNotEmpty &&
                rcaDetailsList[0]['rootCauses'] is List &&
                (rcaDetailsList[0]['rootCauses'] as List).isNotEmpty
            ? rcaDetailsList[0]['rootCauses'][0]['rootCauseText'] ?? ""
            : "",
        "rootCause": rcaDetailsList.isNotEmpty &&
                rcaDetailsList[0]['rootCauses'] is List &&
                (rcaDetailsList[0]['rootCauses'] as List).isNotEmpty
            ? rcaDetailsList[0]['rootCauses'][0]['rootCause'] ?? ""
            : "",
        "ActionTakenId": rcaDetailsList.isNotEmpty &&
                rcaDetailsList[0]['actionTakens'] is List &&
                (rcaDetailsList[0]['actionTakens'] as List).isNotEmpty
            ? int.tryParse(rcaDetailsList[0]['actionTakens'][0]['actionTakenId']
                    ?.toString() ??
                "0") ??
                0
            : 0,
        "ActionTakenText": rcaDetailsList.isNotEmpty &&
                rcaDetailsList[0]['actionTakens'] is List &&
                (rcaDetailsList[0]['actionTakens'] as List).isNotEmpty
            ? (() {
                final at = rcaDetailsList[0]['actionTakens'][0];
                final id = at['actionTakenId']?.toString() ?? "0";
                final txt = at['actionTakenText']?.toString() ?? "";
                if (txt.contains(":")) return txt;
                return id != "0" ? "$id:$txt" : txt;
              })()
            : "",
        "FailureAttendedDate": selectedFailureAttendedDate.value != null &&
                selectedFailureAttendedDate.value!.year > 1900
            ? DateFormat("dd/MM/yyyy HH:mm")
                .format(selectedFailureAttendedDate.value!)
            : null,
        "ActualFailureRectifiedDate":
            selectedActualFailureRectifiedDate.value != null &&
                    selectedActualFailureRectifiedDate.value!.year > 1900
                ? DateFormat("dd/MM/yyyy HH:mm")
                    .format(selectedActualFailureRectifiedDate.value!)
                : null,
        "IsFailureRectifiDetails": isRcaRequired.value,
        "IsFmecaFailureRectificationDetails": true,
        "FailureType": selectedActualFailureRectified.value ?? "No",
        "FailureTypeId": "1",
        "IsHardwareReplaced": isSparePartReplaced.value,
        "IsJointInspectionReq": isJointInspection.value,
        "FunctionLocation_JI": isJointInspection.value ? 0 : null,
        "EquipmentId_JI": isJointInspection.value ? 0 : null,
        "UserStatus": userStatusValue,
        "AssignedUserId": createdBy,
        "AssignedUserId_JI": isJointInspection.value
            ? (int.tryParse(jointUserList
                    .firstWhere((e) => e.label == selectedJointAssignTo.value,
                        orElse: () => LabelValue(value: "0"))
                    .value ??
                "0"))
            : null,
        "CreatedUserId": createdBy,
        "UpdatedUserId": createdBy,
        "DeptId_JI": isJointInspection.value
            ? (int.tryParse(departmentList
                    .firstWhere((e) => e.label == selectedJointDept.value,
                        orElse: () => LabelValue(value: "0"))
                    .value ??
                "0"))
            : null,
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
        "LocationTypeId": locationTypeList
                .firstWhere((e) => e.label == selectedLocation.value,
                    orElse: () => LabelValue(value: "0"))
                .value ??
            "0",
        "NotificationCode": notificationCode.value,
        "UnderObservationDate": selectedUnderObservationDate.value != null &&
                selectedUnderObservationDate.value!.year > 1900
            ? DateFormat("dd/MM/yyyy HH:mm")
                .format(selectedUnderObservationDate.value!)
            : "",
        "FailureRectificationDetails":
            failureRectificationDetailsController.text.isEmpty
                ? "N/A"
                : failureRectificationDetailsController.text,
        "LocationFailure": subLocationController.text,
        "Corr_NotificationTypeId": int.tryParse(corrNotificationTypeList
                .firstWhere(
                    (e) =>
                        e.label ==
                        ((selectedFailureCategoryType.value?.isNotEmpty ?? false)
                            ? selectedFailureCategoryType.value
                            : selectedNotificationType.value),
                    orElse: () => LabelValue(value: "1"))
                .value ??
            "1") ??
            1,
        "ReasonForDelayId": reasonForDelayId.value,
      };

      // Build failure rectification array for API
      final failureRectificationJson = rcaDetailsList.map((e) {
        // Extract data from nested rootCauses array
        final rootCauses = e['rootCauses'] as List?;
        final firstRootCause =
            rootCauses != null && rootCauses.isNotEmpty ? rootCauses[0] : null;

        // Extract data from nested actionTakens array
        final actionTakens = e['actionTakens'] as List?;
        final firstActionTaken =
            actionTakens != null && actionTakens.isNotEmpty ? actionTakens[0] : null;

        final rootCauseIdVal = firstRootCause != null
            ? int.tryParse(firstRootCause['rootCauseId']?.toString() ?? "0") ?? 0
            : 0;
        final actionTakenIdVal = firstActionTaken != null
            ? int.tryParse(firstActionTaken['actionTakenId']?.toString() ?? "0") ?? 0
            : 0;

        return {
          "System": isSectionIncharge
              ? (selectedFmecaSystem.value ?? "")
              : (systemController.text.isNotEmpty
                  ? systemController.text
                  : (e['system'] ?? "")),
          "SubSystem": isSectionIncharge
              ? (selectedFmecaSubsystem.value ?? "")
              : (subsystemController.text.isNotEmpty
                  ? subsystemController.text
                  : (e['subsystem'] ?? "")),
          "FailureCategoryId":
              int.tryParse(e['FailureCategoryId']?.toString() ?? "0") ?? 0,
          "FailureCategoryText": e['failureCategory'] ?? "",
          "CauseOfFailureId": firstRootCause != null
              ? int.tryParse(firstRootCause['causeId']?.toString() ?? "0") ?? 0
              : 0,
          "CauseOfFailureText":
              firstRootCause != null ? (firstRootCause['cause'] ?? "") : "",
          "Cause": firstRootCause != null ? (firstRootCause['cause'] ?? "") : "",
          "RootCauseId": rootCauseIdVal,
          "rootCauseId": rootCauseIdVal,
          "RootCause":
              firstRootCause != null ? (firstRootCause['rootCause'] ?? "") : "",
          "RootCauseText": firstRootCause != null
              ? (firstRootCause['causeText'] ??
                  firstRootCause['rootCauseText'] ??
                  "")
              : "",
          "ActionTakenId": actionTakenIdVal,
          "ActionTaken": firstActionTaken != null
              ? (firstActionTaken['actionTaken'] ?? "")
              : "",
          "ActionTakenText": firstActionTaken != null
              ? (firstActionTaken['actionTakenText'] ?? "")
              : ""
        };
      }).toList();

      // Add FailureRectificationJson to changeNotifictionJE
      changeNotifictionJE['FailureRectificationJson'] =
          failureRectificationJson;

      final payload = {
        "changeNotifictionJE": changeNotifictionJE,
        "materialRequiredDetails": isSparePartReplaced.value
            ? materialsForSubmit().map(buildMaterialPayload).toList()
            : <Map<String, dynamic>>[],
        "failureRectification": rcaDetailsList.map((e) {
          final rootCauses = e['rootCauses'] as List?;
          final firstRootCause =
              rootCauses != null && rootCauses.isNotEmpty ? rootCauses[0] : null;

          final actionTakens = e['actionTakens'] as List?;
          final firstActionTaken =
              actionTakens != null && actionTakens.isNotEmpty
                  ? actionTakens[0]
                  : null;

          final rootCauseId = firstRootCause != null
              ? (firstRootCause['rootCauseId']?.toString() ?? "0")
              : "0";
          final rootCauseName = firstRootCause != null
              ? (firstRootCause['rootCause']?.toString() ??
                  firstRootCause['rootCauseText']?.toString() ??
                  "")
              : "";

          final actionTakenId = firstActionTaken != null
              ? (firstActionTaken['actionTakenId']?.toString() ?? "0")
              : "0";
          final actionTakenText = firstActionTaken != null
              ? (firstActionTaken['actionTakenText']?.toString() ?? "")
              : "";

          final rootCauseFormatted =
              (rootCauseId != "0" && !rootCauseName.contains(":"))
                  ? "$rootCauseId:$rootCauseName"
                  : rootCauseName;

          final actionFormatted =
              (actionTakenId != "0" && !actionTakenText.contains(":"))
                  ? "$actionTakenId:$actionTakenText"
                  : (actionTakenText.isNotEmpty
                      ? actionTakenText
                      : (firstActionTaken != null &&
                              firstActionTaken['actionTaken'] != null
                          ? "$actionTakenId:${firstActionTaken['actionTaken']}"
                          : ""));

          return {
            "RootCauseText": rootCauseFormatted,
            "ActionText": actionFormatted,
          };
        }).toList(),
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
              if (date is DateTime)
                return DateFormat('dd/MM/yyyy HH:mm').format(date);
              if (date is String) {
                // Try to parse and reformat to dd/MM/yyyy HH:mm
                try {
                  final dt = DateTime.parse(date); // ISO8601
                  return DateFormat('dd/MM/yyyy HH:mm').format(dt);
                } catch (e) {
                  try {
                    // ignore: unused_local_variable
                    final _ = DateFormat('dd/MM/yyyy HH:mm').parse(date);
                    return date; // Already in correct format
                  } catch (e2) {
                    try {
                      final dt =
                      DateFormat('dd-MM-yyyy HH:mm').parse(date);
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
              "OldSerialNoDismantleDate":
              formatDismantleDate(e['oldSerialDismantleDate']),
              "NewSerialNoInstallationDate":
              formatDismantleDate(e['newSerialInstallationDate']),
              "InsertUpdateStatusId": statusId,
              "CurrentInsertUpdateStatusId": statusId,
              "Id": recordId,
            };
          }),
          // Add deleted items with delete status
          ...deletedDismantleMaterialsList.map((e) {
            return {
              "MaterialId": e['materialId'] ?? resolveMaterialId(e),
              "MaterialValue": e['materialCode'] ?? "",
              "MaterialReqId": e['id'],
              "OldSerialNumber": e['oldSerialNumber'] ?? "",
              "NewSerialNumber": e['newSerialNumber'] ?? "",
              "OldSerialNoDismantleDate":
              e['oldSerialDismantleDate'] ?? "",
              "NewSerialNoInstallationDate":
              e['newSerialInstallationDate'] ?? "",
              "InsertUpdateStatusId": 3, // 3 = Delete
              "CurrentInsertUpdateStatusId": 3,
              "Id": e['id'],
            };
          }),
        ]
            : <Map<String, dynamic>>[]
      };
      debugPrint("payload===${payload["materialDismantleDetails"]}");
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
      try {
        await _failureService
            .updateJEFailure(payload, files: files)
            .timeout(const Duration(seconds: 90));
      } catch (e) {
        if (!isNetworkError(e) || !isJE || resolveNotificationId() <= 0) rethrow;
        // No connection: keep the form and its images, send them when internet
        // returns (the failure shows "Pending: Update" in the list).
        await JeOfflineService().queueUpdate(
          notificationId: resolveNotificationId(),
          payload: payload,
          filePaths: {
            if (beforeFiles.isNotEmpty &&
                beforeFiles.first['path'] != null &&
                beforeFiles.first['isNetwork'] != true)
              'beforeImage': beforeFiles.first['path'].toString(),
            if (afterFiles.isNotEmpty &&
                afterFiles.first['path'] != null &&
                afterFiles.first['isNetwork'] != true)
              'afterImage': afterFiles.first['path'].toString(),
            if (rcaFiles.isNotEmpty &&
                rcaFiles.first['path'] != null &&
                rcaFiles.first['isNetwork'] != true)
              'rcaImage': rcaFiles.first['path'].toString(),
          },
        );
        EasyLoading.dismiss();
        refreshFailureListAfterSubmission(isStation);
        Get.back(result: true);
        Get.snackbar('Saved Offline',
            'Failure saved locally. Will sync when internet is available.',
            backgroundColor: AppColors.orangeColor, colorText: AppColors.white1);
        return;
      }
      EasyLoading.dismiss();
      // Reload the JE inbox list(s) so the closed/updated failure shows.
      refreshFailureListAfterSubmission(isStation);
      Get.back(result: true);
      Get.snackbar(AppStrings.success, AppStrings.failureUpdated,
          backgroundColor: AppColors.green, colorText: AppColors.white1);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('updateFailure error: $e');
      Get.snackbar(AppStrings.error, 'An unexpected error occurred');
    }
  }
}
