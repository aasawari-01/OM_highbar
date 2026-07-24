import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../constants/strings.dart';
import '../../../constants/colors.dart';
import '../../../core/models/label_value.dart';
import '../../../service/session_controller.dart';
import '../../../service/auth_manager.dart';
import 'failure_form_state.dart';
import '../model/joint_inspection_history.dart';
import '../service/failure_service.dart';

mixin FailureJointInspectionLogic on GetxController, FailureFormState {
  FailureService get _failureService => FailureService();
  int resolveNotificationId();

  final editingJointInspectionIndex = (-1).obs;

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

  void _parseJointInspectionHistoryFromResponse(dynamic historyJson) {
    if (historyJson is List && historyJson.isNotEmpty) {
      _updateJointInspectionList(historyJson);
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
          backgroundColor: Colors.orange, colorText: Colors.white);
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
          backgroundColor: Colors.green, colorText: Colors.white);
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
          backgroundColor: Colors.green, colorText: Colors.white);
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

  void _updateJointInspectionList(List<dynamic> output) {
    jointInspectionHistoryList.assignAll(
        output.map((e) => JointInspectionHistory.fromJson(e as Map<String, dynamic>)).toList()
    );
  }

  Future<void> fetchJointInspectionUsers(String deptId) async {
    try {
      final users = await _failureService.getJIUsers(deptId);
      jointUserList.assignAll(users);
    } catch (e) {
      debugPrint('fetchJointInspectionUsers error: $e');
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
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('removeJointInspectionHistory error: $e');
      Get.snackbar(AppStrings.error, 'Failed to delete joint inspection');
    }
  }
}
