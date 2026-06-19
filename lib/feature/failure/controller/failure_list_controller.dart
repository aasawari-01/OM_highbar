import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../service/auth_manager.dart';
import '../../../service/session_controller.dart';
import '../model/failure_list_response.dart';

enum StationFailureListTab { active, closed }
enum JEFailureListTab { inbox, jointInspection }

class FailureListController extends GetxController {
  final ApiClient _apiClient = ApiClient();
  final SessionController _sessionController = Get.find<SessionController>();

  final RxList<FailureItem> failures = <FailureItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = "".obs;
  final selectedStationTab = StationFailureListTab.active.obs;
  final selectedJETab = JEFailureListTab.inbox.obs;
  String failureType = 'Maintenance';

  void setFailureType(String type) {
    failureType = type;
  }

  @override
  void onInit() {
    super.onInit();
    // fetchFailures() is called by the view after setFailureType()
    // to avoid double-calls and ensure failureType is set first.
  }

  bool get _isJE {
    final role = _sessionController.selectedRole.value?.roleDescr ?? '';
    return role.contains('Junior Engineer');
  }

  bool get _isStationController {
    final role = _sessionController.selectedRole.value?.roleDescr ?? '';
    return role.contains('Station Controller');
  }

  bool get _useStationFailureListApi => failureType.toLowerCase() == 'station' && _isStationController;

  bool get showStationTabs => _useStationFailureListApi;
  bool get showJETabs => _isJE;

  void setStationTab(StationFailureListTab tab) {
    if (selectedStationTab.value == tab) return;
    selectedStationTab.value = tab;
    fetchFailures();
  }

  void setJETab(JEFailureListTab tab) {
    if (selectedJETab.value == tab) return;
    selectedJETab.value = tab;
    fetchFailures();
  }

  bool _matchesFailureType(FailureItem item) {
    if (_isJE && selectedJETab.value == JEFailureListTab.jointInspection) return true;
    
    final filter = failureType.trim().toLowerCase();
    if (filter.isEmpty) return true;

    if (_useStationFailureListApi) return true;

    final creation = (item.creationType ?? '').trim().toLowerCase();

    if (filter == 'maintenance' || filter == 'maintainance') {
      return creation == 'manual';
    }

    if (creation == filter || creation.contains(filter)) return true;

    final other = (item.otherRequestFrom ?? '').trim().toLowerCase();
    return other == filter || other.contains(filter);
  }

  String _messageFromResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['responseMessage']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    } catch (_) {
      // Fall back to the status code below when the server does not return JSON.
    }
    return "Server error: ${response.statusCode}";
  }

  Future<void> fetchFailures() async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;

      final http.Response response;

      if (_useStationFailureListApi) {
        final isClosedList = selectedStationTab.value == StationFailureListTab.closed;
        response = await _apiClient.post(
          isClosedList ? AppUrls.getStationFailureClosedList : AppUrls.getStationFailureList,
          body: {
            "LocationId": 0,
            "UserId": userId,
            "DepartmentIds": "",
            "Action": isClosedList ? "ClosedFailureList" : "",
          },
        );
      } else if (_isJE && selectedJETab.value == JEFailureListTab.jointInspection) {
        response = await _apiClient.post(
          AppUrls.jeJointInboxList,
          body: {
            "assignedUserId": userId,
            "jobCardId": null,
            "id": null,
            "deptId": null,
            "startDate": null,
            "endDate": null
          },
        );
      } else {
        final int deptId = _sessionController.selectedDepartment.value?.deptId ?? 0;
        response = await _apiClient.post(
          AppUrls.jeInboxList,
          body: {
            "assignedUserId": userId,
            "deptId": deptId,
          },
        );
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final result = FailureListResponse.fromJson(jsonBody);
        if (result.responseCode == 200) {
          final allItems = result.responseOutput;
          final filteredItems = allItems.where((item) => _matchesFailureType(item)).toList();
          failures.assignAll(filteredItems);
        } else {
          errorMessage.value = result.responseMessage ?? "Failed to load data";
        }
      } else {
        failures.clear();
        errorMessage.value = _messageFromResponse(response);
      }
    } catch (e) {
      errorMessage.value = "Error: $e";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reOpenFailure(int id, String remark) async {
    await _updateStationAcknowledgeStatus(id, "UPDATE_REOPEN_OCC_Station", remark);
  }

  Future<void> closeFailure(int id) async {
    await _updateStationAcknowledgeStatus(id, "UPDATE_CLOSED_OCC_Station", "Closed Request");
  }

  Future<void> _updateStationAcknowledgeStatus(int id, String action, String description) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;
      final String userName = _sessionController.userName.value;

      final Map<String, dynamic> payload = {
        "Id": id,
        "StatusId": 202,
        "Action": action,
        "CreatedBy": userId,
        "CreatedByName": userName,
        "Description": description,
      };

      final response = await _apiClient.post(
        AppUrls.updateStationAcknowledgeStatus,
        body: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        if (jsonBody['responseCode'] == 200) {
          Get.snackbar("Success", jsonBody['responseMessage'] ?? "Action completed successfully.", backgroundColor: Colors.green, colorText: Colors.white);
          fetchFailures(); // Refresh list
        } else {
          errorMessage.value = jsonBody['responseMessage'] ?? "Failed to perform action";
          Get.snackbar("Error", errorMessage.value, backgroundColor: AppColors.red, colorText: AppColors.white1);
        }
      } else {
        errorMessage.value = "Server error: ${response.statusCode}";
        Get.snackbar("Error", errorMessage.value, backgroundColor: AppColors.red, colorText: AppColors.white1);
      }
    } catch (e) {
      errorMessage.value = "Error: $e";
      Get.snackbar("Error", errorMessage.value, backgroundColor: AppColors.red, colorText: AppColors.white1);
    } finally {
      isLoading.value = false;
    }
  }
}
