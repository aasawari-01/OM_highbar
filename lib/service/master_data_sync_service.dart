import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../core/models/location.dart';
import '../core/models/functional_location.dart';
import '../core/models/equipment.dart';
import '../core/models/measurement_point.dart';
import '../core/models/priority.dart';
import '../core/models/failure_category.dart';
import '../core/models/department.dart';
import '../core/models/master_user.dart';
import '../feature/failure/service/failure_service.dart';
import 'local_database_service.dart';
import 'network_service/api_client.dart';
import 'network_service/app_urls.dart';
import 'auth_manager.dart';

import '../feature/failure/controller/failure_list_controller.dart';

class MasterDataSyncService extends GetxController {
  final ApiClient _apiClient = ApiClient();
  static const int _maxPaginatedPages = 100;
  static bool _syncInProgress = false;
  
  // Reactive sync status for UI to observe
  final RxBool isSyncing = false.obs;
  final RxString syncStatus = ''.obs;


  Future<void> syncMasterData() async {
    if (_syncInProgress) {
      debugPrint("syncMasterData: Already in progress, skipping duplicate sync");
      return;
    }

    _syncInProgress = true;
    isSyncing.value = true;
    syncStatus.value = 'Syncing data...';
    
    try {
      final dbService = LocalDatabaseService();
      final db = await dbService.database;

      // if (count > 0) {
      //   debugPrint("Master data already exists (count: $count). Skipping sync.");
      //   _syncInProgress = false;
      //   isSyncing.value = false;
      //   return;
      // }

      // Show full screen loader for better visibility
      EasyLoading.show(status: 'Initial data synchronization is required before you can use the application.\nEstimated time: 3 minutes\nPlease do not close the application during this process.', maskType: EasyLoadingMaskType.black);
      
      // Clear existing asset data before fresh sync
      await dbService.clearAssetTables();
      debugPrint("syncMasterData: Cleared asset tables for fresh sync");
      
      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;






      // 1. Priority, Failure Category, Users first (lightweight — must not be blocked by pagination)
      syncStatus.value = 'Syncing master data...';
      try {
        await syncStationFailureDropdownMasterData();
      } catch (e) {
        debugPrint("Error fetching lookup master data: $e");
      }

      // 1.5. Sync Departments to local DB for offline use
      syncStatus.value = 'Syncing departments...';
      try {
        await syncDepartmentMasterData();
      } catch (e) {
        debugPrint("Error syncing departments: $e");
      }

      // NOTE: clearAssetTables removed to prevent race condition when 
      // syncMasterData is called concurrently (login background + screen foreground).
      // INSERT OR REPLACE handles upserts correctly.
      debugPrint("syncMasterData: Starting asset sync for userId=$userId");

      // 2. Fetch Locations
      syncStatus.value = 'Syncing locations...';
      try {
        final locRes = await _apiClient.post(
          AppUrls.getMasterData,
          body: {
            "userId": userId,
            "action": "GetLocationMasterData",
            "PageNumber": "1",
            "PageSize": "1000"
          }
        );
        if (locRes.statusCode == 200) {
          final Map<String, dynamic> jsonBody = jsonDecode(locRes.body);
          if (jsonBody['success'] == true && jsonBody['data'] != null) {
            List<dynamic> locs = jsonBody['data']['locations'] ?? [];

            if (locs.isNotEmpty) {
              final mappedLocs = locs.map((e) => LocationModel.fromJson(e)).toList();
              await dbService.insertLocations(mappedLocs);
            }

            // Also check if functionalLocations were bundled in this response
            List<dynamic> funcLocs = jsonBody['data']['functionalLocations'] ?? [];

            if (funcLocs.isNotEmpty) {
              debugPrint("Found ${funcLocs.length} functional locations bundled in GetLocationMasterData response.");
              final mappedFuncLocs = funcLocs.map((e) => FunctionalLocationModel.fromJson(e)).toList();
              await dbService.insertFunctionalLocations(mappedFuncLocs);
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching Location master data: $e");
      }

      // 3. Fetch Functional Locations (Paginated)
      // 4. Fetch Equipments (Paginated)
      // Run both in parallel
      syncStatus.value = 'Syncing functional locations and equipment...';
      debugPrint("syncMasterData: Starting parallel sync of FuncLoc and Equipment");
      await Future.wait([
        _fetchPaginatedMasterData<FunctionalLocationModel>(
          userId,
          'GetFuncLocMasterData',
          dbService,
          (data) => data['functionalLocations'],
          FunctionalLocationModel.fromJson,
          dbService.insertFunctionalLocations
        ).catchError((e) {
          debugPrint("Error fetching FuncLoc master data: $e");
        }),
        _fetchPaginatedMasterData<EquipmentModel>(
          userId,
          'GetEqMasterData',
          dbService,
          (data) => data['equipments'],
          EquipmentModel.fromJson,
          dbService.insertEquipments

        ).catchError((e) {
          debugPrint("Error fetching Equipment master data: $e");
        }),
      ]);
      
      // Log total counts after sync
      final funcLocCount = await dbService.getFunctionalLocations();
      final equipCount = await dbService.getEquipments();
      debugPrint("syncMasterData: Parallel sync complete");
      debugPrint("syncMasterData: Total functional locations in DB: ${funcLocCount.length}");
      debugPrint("syncMasterData: Total equipment in DB: ${equipCount.length}");

      // 5. Fetch Measurement Points (Paginated)
      syncStatus.value = 'Syncing measurement points...';
      try {
        await _fetchPaginatedMasterData<MeasurementPointModel>(
          userId,
          'GetMeasurementPtMasterData',
          dbService,
          (data) => data['measurementPoints'],
          MeasurementPointModel.fromJson,
          dbService.insertMeasurementPoints,
        );
      } catch (e) {
        debugPrint("Error fetching Measurement Points master data: $e");
      }
      
      syncStatus.value = 'Sync complete';
    } catch (e) {
      debugPrint("Error in syncMasterData sequence: $e");
      syncStatus.value = 'Sync failed';
    } finally {
      _syncInProgress = false;
      isSyncing.value = false;
      EasyLoading.dismiss();
    }
  }

  Future<bool> _fetchGetMasterList<T>({
    required int userId,
    required String action,
    required String dataKey,
    required T Function(Map<String, dynamic>) mapper,
    required Future<void> Function(List<T>) insertToDb,
  }) async {
    try {
      final body = {
        'userId': userId,
        'action': action,
      };

      final response = await _apiClient.post(
        AppUrls.getMasterData,
        body: body,
      );

      if (response.statusCode != 200) return false;

      final Map<String, dynamic> jsonBody = jsonDecode(response.body);

      if (jsonBody['success'] != true || jsonBody['data'] == null) {
        return false;
      }

      final List<dynamic> items =
          (jsonBody['data'][dataKey] as List<dynamic>?) ?? [];

      if (items.isEmpty) {
        return false;
      }

      final mappedItems = items.map((e) => mapper(e as Map<String, dynamic>)).toList();
      await insertToDb(mappedItems);
      return true;
    } catch (e) {
      debugPrint('$action failed: $e');
      return false;
    }
  }

  Future<void> syncPriorityMasterData() async {
    try {
      final userId = int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;
      await _fetchGetMasterList(
        userId: userId,
        action: 'GetPriorityMasterData',
        dataKey: 'priorities',
        mapper: PriorityModel.fromJson,
        insertToDb: LocalDatabaseService().insertPriorities,
      );
    } catch (e) {
      debugPrint('Error syncing priority master data: $e');
    }
  }

  Future<void> syncFailureCategoryMasterData() async {
    try {
      final userId = int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;
      await _fetchGetMasterList(
        userId: userId,
        action: 'GetFailureCategoryMasterData',
        dataKey: 'failureCategories',
        mapper: FailureCategoryModel.fromJson,
        insertToDb: LocalDatabaseService().insertFailureCategories,
      );
    } catch (e) {
      debugPrint('Error syncing failure category master data: $e');
    }
  }

  Future<void> syncUserRoleDeptMasterData() async {
    try {
      final userId = int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;
      await _fetchGetMasterList(
        userId: userId,
        action: 'GetUserRoleDeptMasterData',
        dataKey: 'users',
        mapper: MasterUserModel.fromJson,
        insertToDb: LocalDatabaseService().insertMasterUsers,
      );
    } catch (e) {
      debugPrint('Error syncing user master data: $e');
    }
  }

  Future<void> syncDepartmentMasterData() async {
    try {
      final userId = int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;
      debugPrint("syncDepartmentMasterData: Starting sync for userId $userId");
      
      final dbService = LocalDatabaseService();
      final existingDepts = await dbService.getDepartments();
      debugPrint("syncDepartmentMasterData: Existing departments in DB: ${existingDepts.length}");
      
      debugPrint("syncDepartmentMasterData: Calling _fetchGetMasterList with action=GetDeptMasterData");
      final success = await _fetchGetMasterList(
        userId: userId,
        action: 'GetDeptMasterData',
        dataKey: 'departments',
        mapper: DepartmentModel.fromJson,
        insertToDb: LocalDatabaseService().insertDepartments,
      );
      debugPrint("syncDepartmentMasterData: _fetchGetMasterList returned success=$success");
      
      if (success) {
        final depts = await dbService.getDepartments();
        debugPrint("syncDepartmentMasterData: Successfully synced ${depts.length} departments to local storage");
      } else {
        debugPrint("syncDepartmentMasterData: Failed to sync departments");
      }
    } catch (e) {
      debugPrint('Error syncing department master data: $e');
    }
  }

  Future<void> syncStations() async {
    try {
      final userId = await AuthManager().getUserId() ?? '1';
      debugPrint("syncStations: Starting sync for userId $userId");
      
      final dbService = LocalDatabaseService();
      final existingStations = await dbService.getStations();
      debugPrint("syncStations: Existing stations in DB: ${existingStations.length}");
      
      final response = await _apiClient.get('${AppUrls.getStationName}?AssgineUserId=$userId');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['responseCode'] == 200 && body['responseOutput'] != null) {
          final stations = body['responseOutput'] as List;
          await dbService.clearStations();
          await dbService.insertStations(stations.cast<Map<String, dynamic>>());
          final syncedStations = await dbService.getStations();
          debugPrint("syncStations: Successfully synced ${syncedStations.length} stations to local storage");
        } else {
          debugPrint("syncStations: API returned error code ${body['responseCode']}");
        }
      } else {
        debugPrint("syncStations: API HTTP error ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Error syncing stations: $e');
    }
  }

  Future<void> syncStationFailureDropdownMasterData() async {
    await syncPriorityMasterData();
    await syncFailureCategoryMasterData();
    await syncUserRoleDeptMasterData();
    await syncDepartmentMasterData();
    await syncStations();
    
    // Also sync functional locations and equipment for create failure screen
    final dbService = LocalDatabaseService();
    final String? userIdStr = await AuthManager().getUserId();
    final int userId = int.tryParse(userIdStr ?? "0") ?? 0;
    
    try {
      await _fetchPaginatedMasterData<FunctionalLocationModel>(
        userId,
        'GetFuncLocMasterData',
        dbService,
        (data) => data['functionalLocations'],
        FunctionalLocationModel.fromJson,
        dbService.insertFunctionalLocations
      );
      debugPrint("syncStationFailureDropdownMasterData: Functional locations synced");
    } catch (e) {
      debugPrint("syncStationFailureDropdownMasterData: Error syncing functional locations: $e");
    }
    
    try {
      await _fetchPaginatedMasterData<EquipmentModel>(
        userId,
        'GetEqMasterData',
        dbService,
        (data) => data['equipments'],
        EquipmentModel.fromJson,
        dbService.insertEquipments
      );
      debugPrint("syncStationFailureDropdownMasterData: Equipment synced");
    } catch (e) {
      debugPrint("syncStationFailureDropdownMasterData: Error syncing equipment: $e");
    }
  }

  /// Syncs failure list for a specific failure type (Station, Maintenance, etc.)
  Future<void> syncFailureList(String failureType) async {
    if (_syncInProgress) {
      debugPrint("syncFailureList: Already in progress, skipping");
      return;
    }

    // Only sync Station failures to local storage, skip JE and other types
    if (failureType.toLowerCase() != 'station') {
      debugPrint("syncFailureList: Skipping sync for $failureType - only Station failures are stored locally");
      syncStatus.value = 'Not stored (Station only)';
      return;
    }

    _syncInProgress = true;
    isSyncing.value = true;
    syncStatus.value = 'Syncing $failureType failures...';

    try {
      final dbService = LocalDatabaseService();
      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;

      String url;
      Map<String, dynamic> body;

      // Only handle Station failures
      url = AppUrls.getStationFailureListWithData;
      body = {"UserId": userId};

      final response = await _apiClient.post(url, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        
        // Handle new API response structure for Station failures
        if (failureType.toLowerCase() == 'station' && jsonBody['success'] == true) {
          final stationFailureList = jsonBody['data']['stationFailureList'] as List;
          debugPrint("syncFailureList: Found ${stationFailureList.length} station failures");
          
          // Convert to JSON format for database storage with field mapping
          final jsonData = stationFailureList.map((e) {
            final json = Map<String, dynamic>.from(e);
            // Map new API fields to existing database schema
            return {
              'id': json['id'],
              'failureNo': json['failureId']?.toString() ?? json['id']?.toString(),
              'failureDescription': json['failureDescription']?.toString() ?? '',
              'functionalLocation': json['funcationLocation']?.toString() ?? '',
              'statusName': json['statusName']?.toString() ?? '',
              'failureOccuranceDateTime': json['actualFailureOccuranceDate']?.toString() ?? '',
              'locationName': json['location']?.toString() ?? '',
              'priority': json['priority']?.toString() ?? '',
              'departmentName': json['departmentName']?.toString() ?? '',
              'subLocation': json['subLocation']?.toString() ?? '',
              'trainId': json['trainId']?.toString() ?? '',
              'system': json['system']?.toString() ?? '',
              'actualFailureCompletedDateTime': json['actualFailureCompletedDateTime']?.toString() ?? '',
              'isTripAffected': (json['isTripAffected'] == true) ? 1 : 0,
              'tripDelayUpline': json['tripDelayUpline'] ?? 0,
              'tripDelayDownline': json['tripDelayDownline'] ?? 0,
              'tripCancel': json['tripCancel'] ?? 0,
              'isTrainReplace': (json['isTrainReplace'] == true) ? 1 : 0,
              'trainReplace': json['trainReplace']?.toString() ?? '',
              'isTrainDeboarded': (json['isTrainDeboarded'] == true) ? 1 : 0,
              'trainDeboarded': json['trainDeboarded']?.toString() ?? '',
              'numberOfPassengerAffected': json['numberOfPassengerAffected'] ?? 0,
              'isPassengerAffected': (json['isPassengerAffected'] == true) ? 1 : 0,
              'trappedDuration': json['trappedDuration'] ?? 0,
              'rescusedDuration': json['rescusedDuration'] ?? 0,
              'trainDelayInMin': json['trainDelayInMin'] ?? 0,
              'noOfTranWithdrawal': json['noOfTranWithdrawal'] ?? 0,
              'failureReportedby': json['failureReportedby']?.toString() ?? '',
              'failureCategoryTypeText': json['failureCategoryTypeText']?.toString() ?? '',
              'failureRectificationDetails': json['failureRectificationDetails']?.toString() ?? '',
              'carriedOutRemarks': json['carriedOutRemarks']?.toString() ?? '',
              'creationType': 'station',
              'syncStatus': 'online',
              'lastSyncedAt': DateTime.now().toIso8601String(),
              'failureType': failureType,
            };
          }).toList();
          
          await dbService.clearFailureList(failureType);
          await dbService.insertFailureList(jsonData, failureType);
          debugPrint("syncFailureList: Synced ${jsonData.length} $failureType failures to local storage");
          
          // Refresh FailureListController to update UI
          debugPrint("syncFailureList: Attempting to refresh FailureListController with tag: $failureType");
          if (Get.isRegistered<FailureListController>(tag: failureType)) {
            debugPrint("syncFailureList: FailureListController found, calling fetchFailures");
            Future.microtask(() async {
              try {
                await Get.find<FailureListController>(tag: failureType).fetchFailures();
                debugPrint("syncFailureList: fetchFailures completed successfully");
              } catch (e) {
                debugPrint("Error refreshing failure list after sync: $e");
              }
            });
          } else {
            debugPrint("syncFailureList: FailureListController not found with tag: $failureType");
          }
        } else {
          debugPrint("syncFailureList: API returned error - ${jsonBody['responseMessage'] ?? 'Unknown error'}");
          syncStatus.value = 'Sync failed';
        }
      } else {
        debugPrint("syncFailureList: HTTP ${response.statusCode} - ${response.body}");
        syncStatus.value = 'Sync failed';
      }
    } catch (e) {
      debugPrint("Error in syncFailureList: $e");
      syncStatus.value = 'Sync failed';
    } finally {
      _syncInProgress = false;
      isSyncing.value = false;
    }
  }

  /// Syncs pending failure submissions when internet becomes available
  Future<void> syncPendingSubmissions() async {
    if (_syncInProgress) {
      debugPrint("syncPendingSubmissions: Already in progress, skipping");
      return;
    }

    final dbService = LocalDatabaseService();
    final pendingSubmissions = await dbService.getPendingSubmissions();
    
    debugPrint("syncPendingSubmissions: Found ${pendingSubmissions.length} pending submissions");
    
    if (pendingSubmissions.isEmpty) {
      debugPrint("syncPendingSubmissions: No pending submissions to sync");
      return;
    }

    _syncInProgress = true;
    isSyncing.value = true;
    syncStatus.value = 'Syncing pending submissions...';

    try {
      final failureService = FailureService();
      int syncedCount = 0;
      int failedCount = 0;

      for (var submission in pendingSubmissions) {
        try {
          debugPrint("syncPendingSubmissions: Processing submission ${submission['id']}");
          final payload = submission['payload'] as Map<String, dynamic>;
          final failureType = submission['failureType'] as String?;
          debugPrint("syncPendingSubmissions: Failure type: $failureType");
          
          if (failureType == 'Station') {
            debugPrint("syncPendingSubmissions: Calling createStationFailure API");
            final failureNo = await failureService.createStationFailure(payload);
            debugPrint("syncPendingSubmissions: API returned failureNo: $failureNo");
            await dbService.updateSubmissionSynced(submission['id'] as int, true);
            
            // Remove temporary offline entry from FailureList table
            try {
              await dbService.database.then((db) {
                return db.delete(
                  'FailureList',
                  where: 'id = ? AND syncStatus = ?',
                  whereArgs: [submission['id'], 'offline'],
                );
              });
              debugPrint("syncPendingSubmissions: Removed temporary offline entry from FailureList");
            } catch (e) {
              debugPrint("syncPendingSubmissions: Error removing temporary entry: $e");
            }
            
            syncedCount++;
          }
          // Add other failure types as needed
        } catch (e) {
          debugPrint("Error syncing submission ${submission['id']}: $e");
          await dbService.updateSubmissionSynced(
            submission['id'] as int, 
            false, 
            error: e.toString()
          );
          failedCount++;
        }
      }

      // Delete successfully synced submissions
      for (var submission in pendingSubmissions) {
        final synced = submission['synced'] as int? ?? 0;
        if (synced == 1) {
          await dbService.deletePendingSubmission(submission['id'] as int);
        }
      }

      debugPrint("syncPendingSubmissions: Synced $syncedCount, Failed $failedCount");
      syncStatus.value = syncedCount > 0 
          ? 'Synced $syncedCount submissions' 
          : 'Sync complete';
          
      if (syncedCount > 0) {
        Get.snackbar(
          'Sync Complete',
          'Successfully synced $syncedCount pending submissions',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        // Refresh the failure list to show synced data
        if (syncedCount > 0) {
          try {
            // Trigger a refresh of Station failure list
            await syncFailureList('Station');
          } catch (e) {
            debugPrint("Error refreshing failure list after sync: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Error in syncPendingSubmissions: $e");
      syncStatus.value = 'Sync failed';
    } finally {
      _syncInProgress = false;
      isSyncing.value = false;
    }
  }

  /// Syncs only Measurement Points — call this when the local DB table is empty.
  Future<void> syncMeasurementPoints() async {
    try {
      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;
      final dbService = LocalDatabaseService();
      await _fetchPaginatedMasterData<MeasurementPointModel>(
        userId,
        'GetMeasurementPtMasterData',
        dbService,
        (data) => data['measurementPoints'],
        MeasurementPointModel.fromJson,
        dbService.insertMeasurementPoints,
      );
      debugPrint("Measurement Points sync complete.");
    } catch (e) {
      debugPrint("Error syncing Measurement Points: $e");
    }
  }

  Future<void> _fetchPaginatedMasterData<T>(
    int userId,
    String action,
    LocalDatabaseService dbService,
    List<dynamic> Function(Map<String, dynamic>) extractList,
    T Function(Map<String, dynamic>) mapper,
    Future<void> Function(List<T>) insertToDb,
    {List<T> Function(List<T>)? filterList}
  ) async
  {
    int page = 1;
    const int pageSize = 1000;
    int totalItemsFetched = 0;

    while (page <= _maxPaginatedPages) {
      Map<String, dynamic> body = {
        "userId": userId,
        "action": action,
        "PageNumber": page.toString(),
        "PageSize": pageSize.toString(),
      };

      debugPrint("_fetchPaginatedMasterData ($action): Request Body = $body");

      final response = await _apiClient.post(
        AppUrls.getMasterData,
        body: body
      );

      if (response.statusCode != 200) {
        debugPrint("_fetchPaginatedMasterData ($action): Stopping due to non-200 status code: ${response.statusCode}");
        break;
      }

      final Map<String, dynamic> jsonBody = jsonDecode(response.body);
      if (jsonBody['success'] != true || jsonBody['data'] == null) {
        debugPrint("_fetchPaginatedMasterData ($action): Stopping due to success=false or null data");
        break;
      }

      List<dynamic> items = extractList(jsonBody['data']);
      debugPrint("_fetchPaginatedMasterData ($action): Fetched ${items.length} items from API (page $page).");
      if (items.isEmpty) {
        debugPrint("_fetchPaginatedMasterData ($action): Stopping due to empty items on page $page");
        break;
      }

      List<T> mappedItems = items.map((e) => mapper(e as Map<String, dynamic>)).toList();

      if (filterList != null) {
        final beforeFilter = mappedItems.length;
        mappedItems = filterList(mappedItems);
        debugPrint("_fetchPaginatedMasterData ($action): Filtered $beforeFilter items down to ${mappedItems.length}");
      }

      if (mappedItems.isNotEmpty) {
        debugPrint("_fetchPaginatedMasterData ($action): Inserting ${mappedItems.length} items into DB (page $page).");
        await insertToDb(mappedItems);
        totalItemsFetched += mappedItems.length;
      }

      page++;
    }

    debugPrint("_fetchPaginatedMasterData ($action): COMPLETE. Total pages fetched: ${page - 1}, Total items inserted: $totalItemsFetched");

    if (page > _maxPaginatedPages) {
      debugPrint('$action pagination stopped at max pages ($_maxPaginatedPages)');
    }
  }
}
