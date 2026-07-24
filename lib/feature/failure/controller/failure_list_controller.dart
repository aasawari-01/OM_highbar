import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../service/auth_manager.dart';
import '../../../service/session_controller.dart';
import '../../../service/local_database_service.dart';
import '../model/failure_list_response.dart';
import '../service/failure_service.dart';

enum JEFailureListTab { inbox, jointInspection }

class FailureListController extends GetxController {
  final FailureService _failureService = FailureService();
  final ApiClient _apiClient = ApiClient();
  final SessionController _sessionController = Get.find<SessionController>();
  final LocalDatabaseService _dbService = LocalDatabaseService();

  final RxList<FailureItem> failures = <FailureItem>[].obs;
  final RxString searchQuery = "".obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = "".obs;
  final RxBool isOfflineMode = false.obs;

  List<FailureItem> get filteredFailures {
    var list = failures.where((item) => _matchesFailureType(item)).toList();
    
    // Status Filter
    if (selectedStatusFilter.value.isNotEmpty) {
      final status = selectedStatusFilter.value.toLowerCase();
      list = list.where((item) => (item.statusName ?? '').toLowerCase() == status).toList();
    }
    
    if (searchQuery.value.trim().isEmpty) return list;
    
    final q = searchQuery.value.trim().toLowerCase();
    return list.where((item) {
      final code = (item.notificationCode ?? '').toLowerCase();
      final loc = (item.locationName ?? '').toLowerCase();
      final status = (item.statusName ?? '').toLowerCase();
      return code.contains(q) || loc.contains(q) || status.contains(q);
    }).toList();
  }
  final RxString selectedStatusFilter = "".obs;
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

  void setJETab(JEFailureListTab tab) {
    if (selectedJETab.value == tab) return;
    selectedJETab.value = tab;
    fetchFailures();
  }

  bool _matchesFailureType(FailureItem item) {
    final filter = failureType.trim().toLowerCase();
    if (filter.isEmpty) return true;

    if (_useStationFailureListApi) return true;

    final creation = (item.creationType ?? '').trim().toLowerCase();

    // For JE users: Maintenance tab shows Manual, Station tab shows Station
    if (_isJE) {
      if (filter == 'maintenance' || filter == 'maintainance') {
        return creation == 'manual';
      }
      if (filter == 'station') {
        return creation == 'station';
      }
      return true;
    }

    // For non-JE users
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
  Future<void> fetchFailures({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      isOfflineMode.value = false;
      debugPrint("fetchFailures: Starting fetch for type $failureType, forceRefresh=$forceRefresh, isJE=$_isJE");

      // JE users always fetch from API regardless of failure type
      // Station Controller users load Station failures from local DB
      if (_isJE) {
        debugPrint("fetchFailures: JE user - fetching from API");
        await _fetchFromApi();
      } else if (failureType.toLowerCase() == 'station') {
        debugPrint("fetchFailures: Station Controller - loading Station failures from local DB");
        final localFailures = await _dbService.getFailureList(failureType);
        debugPrint("fetchFailures: Found ${localFailures.length} failures in local DB");
        
        if (localFailures.isNotEmpty) {
          final failureItems = localFailures.map((e) => FailureItem.fromJson(e)).toList();
          final filteredItems = failureItems.where((item) => _matchesFailureType(item)).toList();
          failures.assignAll(filteredItems);
          debugPrint("fetchFailures: Loaded ${filteredItems.length} failures from local DB for type $failureType");
        } else {
          debugPrint("fetchFailures: No local data found for type $failureType");
          isOfflineMode.value = true;
          errorMessage.value = "No data available. Please sync with internet connection.";
        }
      } else {
        // For other types (Maintenance, etc.) for non-JE users
        debugPrint("fetchFailures: Fetching $failureType failures from API");
        await _fetchFromApi();
      }
    } catch (e) {
      debugPrint("fetchFailures: Error loading: $e");
      errorMessage.value = "Error: $e";
      isOfflineMode.value = true;
    } finally {
      isLoading.value = false;
      debugPrint("fetchFailures: Complete, total failures: ${failures.length}");
    }
  }

  Future<void> _fetchFromApi() async {
    try {
      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;
      
      final sessionController = Get.find<SessionController>();
      final int deptId = sessionController.selectedDepartment.value?.deptId ?? 0;
      
      // Skip if no department selected
      if (deptId == 0) {
        debugPrint("_fetchFromApi: No department selected (deptId=0)");
        errorMessage.value = "Please select a department first";
        return;
      }
      
      // Use appropriate API endpoint based on JE tab
      final apiUrl = selectedJETab.value == JEFailureListTab.jointInspection
          ? AppUrls.jeJointInboxList
          : AppUrls.jeInboxList;
      
      debugPrint("_fetchFromApi: Calling API: $apiUrl for tab: ${selectedJETab.value}");
      
      final response = await _apiClient.post(
        apiUrl,
        body: {
          "assignedUserId": userId,
          "deptId": deptId,
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        if (jsonBody['responseCode'] == 200) {
          final result = FailureListResponse.fromJson(jsonBody);
          if (result.responseCode == 200) {
            final allItems = result.responseOutput;
            final filteredItems = allItems.where((item) => _matchesFailureType(item)).toList();
            
            // Sort by creationType: Manual, Station, Depot, OCC
            final creationTypeOrder = {'Manual': 0, 'Station': 1, 'Depot': 2, 'OCC': 3};
            filteredItems.sort((a, b) {
              final aType = (a.creationType ?? '').trim();
              final bType = (b.creationType ?? '').trim();
              final aOrder = creationTypeOrder[aType] ?? 999;
              final bOrder = creationTypeOrder[bType] ?? 999;
              return aOrder.compareTo(bOrder);
            });
            
            failures.assignAll(filteredItems);
            debugPrint("_fetchFromApi: Loaded ${filteredItems.length} failures from API (sorted by creationType)");
          } else {
            errorMessage.value = result.responseMessage ?? "Failed to fetch failures";
          }
        } else {
          errorMessage.value = jsonBody['responseMessage'] ?? "Failed to fetch failures";
        }
      } else {
        // Try to extract error message from response body even for non-200 status codes
        try {
          final Map<String, dynamic> jsonBody = jsonDecode(response.body);
          errorMessage.value = jsonBody['responseMessage'] ?? "Server error: ${response.statusCode}";
        } catch (e) {
          errorMessage.value = "Server error: ${response.statusCode}";
        }
      }
    } catch (e) {
      debugPrint("_fetchFromApi: Error fetching from API: $e");
      errorMessage.value = "Error: $e";
      isOfflineMode.value = true;
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
