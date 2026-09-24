import 'dart:convert';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/constants/strings.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../service/auth_manager.dart';
import '../../../core/controller/session_controller.dart';
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
  
  // Staff filter for Section Incharge
  final RxList<StaffItem> staffList = <StaffItem>[].obs;
  final RxnInt selectedStaffId = RxnInt(null);
  final RxnString selectedStaffName = RxnString(null);

  List<FailureItem> get filteredFailures {
    var list = failures.where((item) => _matchesFailureType(item)).toList();
    
    // Station Filter for Station Controller
    if (failureType.toLowerCase() == 'station') {
      final session = Get.find<SessionController>();
      final selectedStationId = session.selectedStationId.value;
      final selectedStationName = session.selectedStationName.value;
      debugPrint("filteredFailures: Station filter - selectedStationId=$selectedStationId, selectedStationName=$selectedStationName");
      
      if (selectedStationId != null && selectedStationId.isNotEmpty && selectedStationId != '0') {
        final beforeFilter = list.length;
        
        // Log all location names for debugging BEFORE filtering
        debugPrint("filteredFailures: All location names in current list (before filter):");
        for (var item in list) {
          debugPrint("  - locationName: '${item.locationName}', locationId: '${item.locationId}'");
        }
        
        // Try to filter by locationId first
        list = list.where((item) => (item.locationId?.toString() ?? '') == selectedStationId).toList();
        debugPrint("filteredFailures: After locationId filter: ${list.length} results");
        
        // If no results, try filtering by locationName with partial match
        if (list.isEmpty && selectedStationName != null && selectedStationName.isNotEmpty) {
          debugPrint("filteredFailures: No results by locationId, trying locationName match");
          // Normalize station name: remove spaces, dashes, convert to lowercase
          final normalizedStationName = selectedStationName.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
          debugPrint("filteredFailures: Normalized station name: $normalizedStationName");
          
          // Need to use the original unfiltered list for name matching
          final originalList = failures.where((item) => _matchesFailureType(item)).toList();
          
          debugPrint("filteredFailures: Comparing with ${originalList.length} failures");
          list = originalList.where((item) {
            final locationName = (item.locationName ?? '').toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
            debugPrint("filteredFailures: Comparing '$locationName' with '$normalizedStationName'");
            // Check if normalized names match or contain each other
            return locationName.contains(normalizedStationName) || 
                   normalizedStationName.contains(locationName) ||
                   locationName == normalizedStationName;
          }).toList();
          debugPrint("filteredFailures: Location name match results: ${list.length}");
        }
        
        debugPrint("filteredFailures: Station filter - before=$beforeFilter, after=${list.length}");
      }
    }
    
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
    debugPrint("setFailureType: type='$type', final failureType='$failureType'");
  }


  bool get _isJE {
    final role = _sessionController.selectedRole.value?.roleDescr ?? '';
    return role.contains('Junior Engineer');
  }

  bool get _isStationController {
    final role = _sessionController.selectedRole.value?.roleDescr ?? '';
    return role.contains('Station Controller');
  }

  bool get _isSectionIncharge {
    final role = _sessionController.selectedRole.value?.roleDescr ?? '';
    final result = role.contains('Section Incharge');
    debugPrint("_isSectionIncharge: role='$role', result=$result");
    return result;
  }

  bool get _useStationFailureListApi => failureType.toLowerCase() == 'station' && _isStationController;

  bool get showStationTabs => _useStationFailureListApi;
  bool get showJETabs => _isJE;
  bool get showSectionInchargeList => _isSectionIncharge;
  
  // Section Incharge uses the same failure list as general users
  bool get useSectionInchargeApi => _isSectionIncharge;

  void setJETab(JEFailureListTab tab) {
    if (selectedJETab.value == tab) return;
    selectedJETab.value = tab;
    fetchFailures();
  }

  bool _matchesFailureType(FailureItem item) {
    final filter = failureType.trim().toLowerCase();
    debugPrint("_matchesFailureType: filter='$filter', _isSectionIncharge=$_isSectionIncharge, _isJE=$_isJE, _useStationFailureListApi=$_useStationFailureListApi");
    
    if (filter.isEmpty) return true;

    if (_useStationFailureListApi) return true;

    // Section Incharge sees all failure types
    if (_isSectionIncharge) {
      debugPrint("_matchesFailureType: Section Incharge - showing all failures");
      return true;
    }

    final creation = (item.creationType ?? '').trim().toLowerCase();
    debugPrint("_matchesFailureType: creationType='$creation'");

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


  Future<void> fetchFailures({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      isOfflineMode.value = false;
      debugPrint("fetchFailures: Starting fetch for type $failureType, forceRefresh=$forceRefresh, isJE=$_isJE");

      // JE users fetch from API with offline fallback (same pattern as Station Controller)
      if (_isJE) {
        debugPrint("fetchFailures: JE user - fetching from API with offline fallback");
        
        // Use composite key for JE: 'JE_inbox' or 'JE_jointInspection'
        final jeFailureType = 'JE_${selectedJETab.value.name}';
        debugPrint("fetchFailures: JE failureType key: $jeFailureType");
        
        // Try to fetch from API
        bool apiSuccess = false;
        try {
          await _fetchFromApi();
          if (failures.isNotEmpty) {
            // Save to local DB on API success using JE-specific key
            await _dbService.clearFailureList(jeFailureType);
            await _dbService.insertFailureList(failures.map((e) => e.toJson()).toList(), jeFailureType);
            debugPrint("fetchFailures: Saved ${failures.length} JE failures to local DB with key: $jeFailureType");
            apiSuccess = true;
          }
        } catch (e) {
          debugPrint("fetchFailures: JE API failed, falling back to local DB: $e");
          isOfflineMode.value = true;
          errorMessage.value = ""; // Clear error when falling back to local DB
        }
        
        // If API failed or returned empty, load from local DB
        if (!apiSuccess || failures.isEmpty) {
          debugPrint("fetchFailures: JE - loading failures from local DB with key: $jeFailureType");
          final localFailures = await _dbService.getFailureList(jeFailureType);
          debugPrint("fetchFailures: Found ${localFailures.length} failures in local DB");
          
          if (localFailures.isNotEmpty) {
            final failureItems = localFailures.map((e) => FailureItem.fromJson(e)).toList();
            final filteredItems = failureItems.where((item) => _matchesFailureType(item)).toList();
            
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
            errorMessage.value = ""; // Clear error message when local data loads successfully
            debugPrint("fetchFailures: Loaded ${filteredItems.length} failures from local DB for JE");
          } else {
            debugPrint("fetchFailures: No local data found for JE with key: $jeFailureType");
            isOfflineMode.value = true;
            if (!apiSuccess) {
              errorMessage.value = "No data available. Please sync with internet connection.";
            } else {
              errorMessage.value = "No failures found.";
            }
          }
        }
      } else if (failureType.toLowerCase() == 'station') {
        debugPrint("fetchFailures: Station Controller - fetching from API if possible");
        
        // Try to fetch from API
        bool apiSuccess = false;
        try {
          // Get last sync date for station failures
          final lastSyncDate = await _getStationFailureLastSyncDate();
          final apiFailures = await _failureService.getStationFailureListWithData(lastSyncDate: lastSyncDate);
          if (apiFailures.isNotEmpty) {
            final failureItems = apiFailures.map((e) => FailureItem.fromJson(e)).toList();
            await _dbService.clearFailureList(failureType);
            await _dbService.insertFailureList(failureItems.map((e) => e.toJson()).toList(), failureType);
            debugPrint("fetchFailures: Saved ${failureItems.length} station failures to local DB");
            // Update last sync date
            await _setStationFailureLastSyncDate(DateTime.now().toIso8601String().split('T')[0]);
            apiSuccess = true;
          } else if (lastSyncDate == null) {
            // Only clear local DB if this was a full sync (lastSyncDate=null) and server returned empty
            await _dbService.clearFailureList(failureType);
            debugPrint("fetchFailures: Full sync returned empty, cleared local DB");
          }
          // If lastSyncDate is not null (incremental sync) and apiFailures is empty, do nothing
          // This means no new data since last sync, keep existing local data
        } catch (e) {
          debugPrint("fetchFailures: API failed, falling back to local DB: $e");
          isOfflineMode.value = true;
        }
        
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
          if (!apiSuccess) {
            errorMessage.value = "No data available. Please sync with internet connection.";
          } else {
            errorMessage.value = "No failures found.";
          }
        }
      } else if (_isSectionIncharge) {
        // Section Incharge users fetch from API with offline fallback
        debugPrint("fetchFailures: Section Incharge - fetching from API with offline fallback");
        
        final cacheKey = 'SectionIncharge_list';
        debugPrint("fetchFailures: Section Incharge failureType key: $cacheKey");
        
        // Try to fetch from API
        bool apiSuccess = false;
        try {
          await _fetchFromApi();
          if (failures.isNotEmpty) {
            // Save to local DB on API success
            await _dbService.clearFailureList(cacheKey);
            await _dbService.insertFailureList(failures.map((e) => e.toJson()).toList(), cacheKey);
            debugPrint("fetchFailures: Saved ${failures.length} Section Incharge failures to local DB");
            apiSuccess = true;
          }
        } catch (e) {
          debugPrint("fetchFailures: Section Incharge API failed, falling back to local DB: $e");
          isOfflineMode.value = true;
          errorMessage.value = "";
        }
        
        // If API failed or returned empty, load from local DB
        if (!apiSuccess || failures.isEmpty) {
          debugPrint("fetchFailures: Section Incharge - loading failures from local DB");
          final localFailures = await _dbService.getFailureList(cacheKey);
          debugPrint("fetchFailures: Found ${localFailures.length} failures in local DB");
          
          if (localFailures.isNotEmpty) {
            final failureItems = localFailures.map((e) => FailureItem.fromJson(e)).toList();
            final filteredItems = failureItems.where((item) => _matchesFailureType(item)).toList();
            
            // Sort by notificationId in descending order (newest first) - matching React code
            filteredItems.sort((a, b) {
              final aId = a.id ?? 0;
              final bId = b.id ?? 0;
              return bId.compareTo(aId); // Descending order
            });
            
            failures.assignAll(filteredItems);
            errorMessage.value = "";
            debugPrint("fetchFailures: Loaded ${filteredItems.length} failures from local DB for Section Incharge (sorted by notificationId)");
          } else {
            debugPrint("fetchFailures: No local data found for Section Incharge");
            isOfflineMode.value = true;
            if (!apiSuccess) {
              errorMessage.value = "No data available. Please sync with internet connection.";
            } else {
              errorMessage.value = "No failures found.";
            }
          }
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
      
      // Use appropriate API endpoint based on user role
      String apiUrl;
      Map<String, dynamic> body;
      
      if (_isSectionIncharge) {
        // Section Incharge uses NotificationListSI endpoint
        apiUrl = AppUrls.sectionInchargeNotificationList;
        
        // Include staff filter if selected
        final assignedUserId = selectedStaffId.value;
        body = {
          "userId": userId,
          "deptID": deptId,
          "fromDate": null,
          "toDate": null,
          "assignedUserId": assignedUserId,
        };
        debugPrint("_fetchFromApi: Calling Section Incharge API: $apiUrl with assignedUserId: $assignedUserId");
      } else {
        // JE users use their respective endpoints
        apiUrl = selectedJETab.value == JEFailureListTab.jointInspection
            ? AppUrls.jeJointInboxList
            : AppUrls.jeInboxList;
        body = {
          "assignedUserId": userId,
          "deptId": deptId,
        };
        debugPrint("_fetchFromApi: Calling JE API: $apiUrl for tab: ${selectedJETab.value}");
      }
      
      final response = await _apiClient.post(
        apiUrl,
        body: body,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        if (jsonBody['responseCode'] == 200) {
          final result = FailureListResponse.fromJson(jsonBody);
          if (result.responseCode == 200) {
            final allItems = result.responseOutput;
            final filteredItems = allItems.where((item) => _matchesFailureType(item)).toList();
            
            // Sort by notificationId in descending order (newest first) - matching React code
            if (_isSectionIncharge) {
              filteredItems.sort((a, b) {
                final aId = a.id ?? 0;
                final bId = b.id ?? 0;
                return bId.compareTo(aId); // Descending order
              });
            } else {
              // For JE users, sort by creationType: Manual, Station, Depot, OCC
              final creationTypeOrder = {'Manual': 0, 'Station': 1, 'Depot': 2, 'OCC': 3};
              filteredItems.sort((a, b) {
                final aType = (a.creationType ?? '').trim();
                final bType = (b.creationType ?? '').trim();
                final aOrder = creationTypeOrder[aType] ?? 999;
                final bOrder = creationTypeOrder[bType] ?? 999;
                return aOrder.compareTo(bOrder);
              });
            }
            
            failures.assignAll(filteredItems);
            debugPrint("_fetchFromApi: Loaded ${filteredItems.length} failures from API (sorted by ${_isSectionIncharge ? 'notificationId' : 'creationType'})");
            
            // Extract staff list for Section Incharge from userDetails
            if (_isSectionIncharge && jsonBody['responseOutput'] != null) {
              final userDetails = jsonBody['responseOutput']['userDetails'] as List<dynamic>?;
              if (userDetails != null && userDetails.isNotEmpty) {
                final staffItems = userDetails.map((e) => StaffItem.fromJson(e as Map<String, dynamic>)).toList();
                staffList.assignAll(staffItems);
                debugPrint("_fetchFromApi: Loaded ${staffItems.length} staff members for Section Incharge");
              }
            }
            
            // Data will be saved to local DB in fetchFailures method after API success
            // This enables offline fallback for JE users
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
    debugPrint("reOpenFailure: Called with id: $id, remark: $remark");
    await _updateStationAcknowledgeStatus(id, "UPDATE_REOPEN_OCC_Station", remark);
  }

  Future<void> closeFailure(int id) async {
    debugPrint("closeFailure: Called with id: $id");
    await _updateStationAcknowledgeStatus(id, "UPDATE_CLOSED_OCC_Station", "Closed Request");
  }

  Future<String?> _getStationFailureLastSyncDate() async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      "SELECT value FROM AppSettings WHERE key = 'stationFailureLastSyncDate'"
    );
    if (result.isNotEmpty) {
      return result.first['value']?.toString();
    }
    return null; // Return null to get all data on first sync
  }

  Future<void> _setStationFailureLastSyncDate(String date) async {
    final db = await _dbService.database;
    await db.rawInsert(
      "INSERT OR REPLACE INTO AppSettings (key, value) VALUES ('stationFailureLastSyncDate', ?)",
      [date]
    );
  }

  /// Force refresh station failures without lastSyncDate (get all data)
  Future<void> refreshAllStationFailures() async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      
      final apiFailures = await _failureService.getStationFailureListWithData(lastSyncDate: null);
      if (apiFailures.isNotEmpty) {
        final failureItems = apiFailures.map((e) => FailureItem.fromJson(e)).toList();
        await _dbService.clearFailureList('Station');
        await _dbService.insertFailureList(failureItems.map((e) => e.toJson()).toList(), 'Station');
        debugPrint("refreshAllStationFailures: Saved ${failureItems.length} station failures to local DB");
        // Update last sync date
        await _setStationFailureLastSyncDate(DateTime.now().toIso8601String().split('T')[0]);
        // Reload from local DB
        final localFailures = await _dbService.getFailureList('Station');
        final localFailureItems = localFailures.map((e) => FailureItem.fromJson(e)).toList();
        final filteredItems = localFailureItems.where((item) => _matchesFailureType(item)).toList();
        failures.assignAll(filteredItems);
        debugPrint("refreshAllStationFailures: Loaded ${filteredItems.length} failures from local DB");
        Get.snackbar(
          'Sync Complete',
          'Successfully synced ${failureItems.length} station failures',
          backgroundColor: AppColors.green,
          colorText: AppColors.white1,
        );
      } else {
        await _dbService.clearFailureList('Station');
        failures.clear();
        Get.snackbar(
          'Sync Complete',
          'No station failures found',
          backgroundColor: AppColors.orangeColor,
          colorText: AppColors.white1,
        );
      }
    } catch (e) {
      debugPrint("refreshAllStationFailures: Error: $e");
      errorMessage.value = "Error: $e";
      Get.snackbar(
        'Sync Failed',
        'Failed to sync station failures: $e',
        backgroundColor: AppColors.red,
        colorText: AppColors.white1,
      );
    } finally {
      isLoading.value = false;
    }
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

      debugPrint("_updateStationAcknowledgeStatus: Request body: $payload");

      final response = await _apiClient.post(
        AppUrls.updateStationAcknowledgeStatus,
        body: payload,
      );

      debugPrint("_updateStationAcknowledgeStatus: Response status: ${response.statusCode}");
      debugPrint("_updateStationAcknowledgeStatus: Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        if (jsonBody['responseCode'] == 200) {
          Get.snackbar("Success", jsonBody['responseMessage'] ?? "Action completed successfully.", backgroundColor: AppColors.green, colorText: AppColors.white1);
          fetchFailures(); // Refresh list
        } else {
          errorMessage.value = jsonBody['responseMessage'] ?? "Failed to perform action";
          Get.snackbar(AppStrings.error, errorMessage.value, backgroundColor: AppColors.red, colorText: AppColors.white1);
        }
      } else {
        errorMessage.value = "Server error: ${response.statusCode}";
        Get.snackbar(AppStrings.error, errorMessage.value, backgroundColor: AppColors.red, colorText: AppColors.white1);
      }
    } catch (e) {
      debugPrint("_updateStationAcknowledgeStatus: Error: $e");
      errorMessage.value = "Error: $e";
      Get.snackbar(AppStrings.error, errorMessage.value, backgroundColor: AppColors.red, colorText: AppColors.white1);
    } finally {
      isLoading.value = false;
    }
  }
}
