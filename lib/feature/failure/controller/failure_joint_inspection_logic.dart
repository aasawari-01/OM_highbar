import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../constants/colors.dart';
import '../../../constants/strings.dart';
import '../../../core/models/label_value.dart';
import '../../../core/controller/session_controller.dart';
import '../../../service/auth_manager.dart';
import 'failure_form_state.dart';

import '../service/failure_service.dart';

mixin FailureJointInspectionLogic on GetxController, FailureFormState {
  FailureService get _failureService => FailureService();
  int resolveNotificationId();

  final editingJointInspectionIndex = (-1).obs;

  Future<void> fetchMasterJointInspectionDepartments() async {
    try {
      // final depts = await _failureService.getDeptMasterData();
      // masterJointInspectionDepartments.assignAll(depts);
    } catch (e) {
      debugPrint('fetchMasterJointInspectionDepartments error: $e');
    }
  }

  List<LabelValue> get jointInspectionDepartments {
    // Use masterDepartments from master data instead of SessionController departments
    // to show all available departments, not just the user's assigned departments
    
    // Try camelCase keys first (from DepartmentModel.toJson())
    final List<LabelValue> camelCaseList = masterDepartments.map((e) => LabelValue(
      label: e['deptName']?.toString() ?? '',
      value: e['deptId']?.toString() ?? '',
    )).toList();
    
    // Try PascalCase keys (from database columns)
    final List<LabelValue> pascalCaseList = masterDepartments.map((e) => LabelValue(
      label: e['DeptName']?.toString() ?? '',
      value: e['DeptId']?.toString() ?? '',
    )).toList();
    
    // Use whichever has valid labels
    final List<LabelValue> sourceList = masterJointInspectionDepartments.isNotEmpty
        ? masterJointInspectionDepartments
        : (camelCaseList.any((e) => e.label?.isNotEmpty == true) ? camelCaseList : pascalCaseList);

    // Fallback to SessionController departments if masterDepartments is empty
    if (sourceList.isEmpty) {
      debugPrint("jointInspectionDepartments: Using SessionController departments as fallback");
      final sessionDepts = Get.find<SessionController>().departments;
      final fallbackList = sessionDepts.map((e) => LabelValue(
        label: e.deptName ?? '',
        value: e.deptId?.toString() ?? '',
      )).toList();
      return fallbackList;
    }

    // Return all departments without filtering to ensure dropdown is never empty
    return sourceList;
  }

  Future<void> fetchJointInspectionHistory() async {
    final notifId = resolveNotificationId();
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
        final matched = jointUserList.firstWhere(
                (e) =>
            e.label == item.assignedUserName ||
                e.value == item.assignedTo?.toString(),
            orElse: () => LabelValue(value: '0'),
        );
        selectedJointAssignTo.value = matched.label;
      });
    } else {
      selectedJointAssignTo.value = item.assignedUserName;
    }
    jointInspectionRemarkController.text = item.remark ?? '';
  }

  Future<void> addJointInspectionHistory() async {
    final dept = jointInspectionDepartments.firstWhere(
          (e) => e.label == selectedJointDept.value,
      orElse: () => LabelValue(value: '0'),
    );
    final alreadyExists = jointInspectionHistoryList.any((item) =>
    item.deptName == selectedJointDept.value ||
        item.deptId?.toString() == dept.value);
    if (alreadyExists) {
      Get.snackbar('Already Exists', 'Joint inspection for this department already exists',
          backgroundColor: AppColors.orangeColor, colorText: AppColors.white1);
      return;
    }

    try {
      EasyLoading.show(status: AppStrings.adding);
      final notifId = resolveNotificationId();
      final assignTo = jointUserList.firstWhere(
              (e) => e.label == selectedJointAssignTo.value,
          orElse: () => LabelValue(value: '0'),
      );
      final userId = int.tryParse(await AuthManager().getUserId() ?? "0") ?? 0;
      final userName = Get.find<SessionController>().userName.value.isNotEmpty
          ? Get.find<SessionController>().userName.value
          : 'User';
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
          backgroundColor: AppColors.green, colorText: AppColors.white1);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('addJointInspectionHistory error: $e');
      Get.snackbar(AppStrings.error, 'Failed to add joint inspection');
    }
  }

  Future<void> updateJointInspectionHistory() async {
    if (editingJointInspectionIndex.value < 0) return;
    try {
      EasyLoading.show(status: AppStrings.updating);
      final notifId = resolveNotificationId();
      final assignTo = jointUserList.firstWhere(
              (e) => e.label == selectedJointAssignTo.value,
          orElse: () => LabelValue(value: '0'),
      );
      final userId = int.tryParse(await AuthManager().getUserId() ?? "0") ?? 0;
      final userName = Get.find<SessionController>().userName.value.isNotEmpty
          ? Get.find<SessionController>().userName.value
          : 'User';
      final dept = jointInspectionDepartments.firstWhere(
            (e) => e.label == selectedJointDept.value,
        orElse: () => LabelValue(value: '0'),
      );
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
          backgroundColor: AppColors.green, colorText: AppColors.white1);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('updateJointInspectionHistory error: $e');
      Get.snackbar(AppStrings.error, 'Failed to update joint inspection');
    }
  }

  void _clearJointInspectionInputs() {
    editingJointInspectionIndex.value = -1;
    selectedJointDept.value = null;
    selectedJointAssignTo.value = null;
    jointInspectionRemarkController.clear();
    jointUserList.clear();
  }



  Future<void> fetchJointInspectionUsers(String deptId) async {
    try {
      isJointUserLoading.value = true;
      jointUserList.clear();
      
      // Joint Inspection Users API disabled - manage from frontend
      // Load users from local master data
      debugPrint("fetchJointInspectionUsers: API disabled, loading from local master data for deptId=$deptId");
      debugPrint("fetchJointInspectionUsers: masterUsers count = ${masterUsers.length}");
      
      // Simple filter by DeptId only
      final filteredUsers = masterUsers.where((user) {
        // Use PascalCase keys (matching database columns)
        final userDeptId = user['DeptId']?.toString() ?? '';
        final userId = user['UserId']?.toString() ?? '';

        // Construct userName from FirstName and LastName (since UserName column is null in DB)
        final firstName = user['FirstName']?.toString() ?? '';
        final lastName = user['LastName']?.toString() ?? '';
        final initial = user['Initial']?.toString() ?? '';
        final userName = (firstName + ' ' + lastName).trim();

        // Filter by department ID (handle both string and int comparisons)
        final deptMatch = userDeptId == deptId ||
                          int.tryParse(userDeptId) == int.tryParse(deptId);

        // Exclude invalid users
        final isValidUser = userId.isNotEmpty && userId != '0' &&
                           userName.isNotEmpty && userName.toLowerCase() != 'select user';

        return deptMatch && isValidUser;
      }).toList();

      // Print filtered user list for verification
      debugPrint("fetchJointInspectionUsers: Filtered user list for department $deptId:");
      for (int i = 0; i < filteredUsers.length && i < 10; i++) {
        final user = filteredUsers[i];
        final roleDescr = user['RoleDescr']?.toString() ?? '';
        final firstName = user['FirstName']?.toString() ?? '';
        final lastName = user['LastName']?.toString() ?? '';
        final userName = (firstName + ' ' + lastName).trim();
        debugPrint("  [$i] UserId: ${user['UserId']}, UserName: $userName, DeptId: ${user['DeptId']}, RoleDescr: $roleDescr");
      }
      if (filteredUsers.length > 10) {
        debugPrint("  ... and ${filteredUsers.length - 10} more users");
      }
      
      debugPrint("fetchJointInspectionUsers: Found ${filteredUsers.length} users for department $deptId");
      
      // Convert to LabelValue
      final labelValueUsers = filteredUsers.map((user) {
        // Construct userName from FirstName and LastName (since UserName column is null in DB)
        final firstName = user['FirstName']?.toString() ?? '';
        final lastName = user['LastName']?.toString() ?? '';
        final userName = (firstName + ' ' + lastName).trim();
        return LabelValue(
          label: userName,
          value: user['UserId']?.toString() ?? '',
        );
      }).toList();
      
      jointUserList.assignAll(labelValueUsers);
    } catch (e) {
      debugPrint('fetchJointInspectionUsers error: $e');
    } finally {
      isJointUserLoading.value = false;
    }
  }

  Future<void> removeJointInspectionHistory(int index) async {
    try {
      EasyLoading.show(status: AppStrings.deleting);
      final notifId = resolveNotificationId();
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
          backgroundColor: AppColors.green, colorText: AppColors.white1);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('removeJointInspectionHistory error: $e');
      Get.snackbar(AppStrings.error, 'Failed to delete joint inspection');
    }
  }
}
