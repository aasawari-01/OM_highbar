import 'dart:convert';
import 'package:flutter/foundation.dart';
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
import 'local_database_service.dart';
import 'network_service/api_client.dart';
import 'network_service/app_urls.dart';
import 'auth_manager.dart';

class MasterDataSyncService extends GetxController {
  final ApiClient _apiClient = ApiClient();
  static const int _maxPaginatedPages = 100;
  static bool _syncInProgress = false;
  
  // Reactive sync status for UI to observe
  final RxBool isSyncing = false.obs;
  final RxString syncStatus = ''.obs;

  String _normalizeSyncDate(String? value) {
    if (value == null || value.isEmpty) return '';
    return value.trim();
  }

  Future<void> syncMasterData() async {
    if (_syncInProgress) {
      debugPrint("syncMasterData: Already in progress, skipping duplicate sync");
      return;
    }

    _syncInProgress = true;
    isSyncing.value = true;
    syncStatus.value = 'Syncing data...';
    
    // Show full screen loader for better visibility
    EasyLoading.show(status: 'Syncing master data...', maskType: EasyLoadingMaskType.black);
    
    try {
      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;
      final int? userBusinessArea = await AuthManager().getBusinessArea();

      final dbService = LocalDatabaseService();

      List<String> validPlantIds = [];
      if (userBusinessArea != null) {
        try {
          final plantsRes = await _apiClient.post(
            AppUrls.getMasterData,
            body: {
              "userId": userId,
              "action": "GetPlantsMasterData"
            }
          );
          if (plantsRes.statusCode == 200) {
            final Map<String, dynamic> jsonBody = jsonDecode(plantsRes.body);
            if (jsonBody['success'] == true && jsonBody['data'] != null) {
              final List<dynamic> plants = jsonBody['data']['planningPlants'] ?? [];
              validPlantIds = plants
                  .where((p) =>
              p['businessArea'].toString() ==
                  userBusinessArea.toString())
                  .map((p) => p['plant'].toString().trim())
                  .toList();
            }
          }
        } catch (e) {
          debugPrint("Error fetching GetPlantsMasterData: $e");
        }
      }

      // 1. Priority, Failure Category, Users first (lightweight — must not be blocked by pagination)
      syncStatus.value = 'Syncing master data...';
      try {
        await syncStationFailureDropdownMasterData();
      } catch (e) {
        debugPrint("Error fetching lookup master data: $e");
      }

      // NOTE: clearAssetTables removed to prevent race condition when 
      // syncMasterData is called concurrently (login background + screen foreground).
      // INSERT OR REPLACE handles upserts correctly.
      debugPrint("syncMasterData: Starting asset sync for userId=$userId, validPlantIds=$validPlantIds");

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
            if (validPlantIds.isNotEmpty) {
              locs = locs.where((l) => validPlantIds.contains((l['businessLocation'] ?? l['plantId'])?.toString().trim())).toList();
            }
            if (locs.isNotEmpty) {
              final mappedLocs = locs.map((e) => LocationModel.fromJson(e)).toList();
              await dbService.insertLocations(mappedLocs);
            }

            // Also check if functionalLocations were bundled in this response
            List<dynamic> funcLocs = jsonBody['data']['functionalLocations'] ?? [];
            if (validPlantIds.isNotEmpty) {
              funcLocs = funcLocs.where((f) => validPlantIds.contains(f['planningPlant']?.toString().trim())).toList();
            }
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
          dbService.insertFunctionalLocations,
          filterList: validPlantIds.isEmpty ? null : (items) => items.where((item) => validPlantIds.contains(item.planningPlant)).toList()
        ).catchError((e) {
          debugPrint("Error fetching FuncLoc master data: $e");
        }),
        _fetchPaginatedMasterData<EquipmentModel>(
          userId,
          'GetEqMasterData',
          dbService,
          (data) => data['equipments'],
          EquipmentModel.fromJson,
          dbService.insertEquipments,
          filterList: validPlantIds.isEmpty ? null : (items) {
            debugPrint("syncMasterData: Equipment filter check - validPlantIds=$validPlantIds, items.length=${items.length}");
            if (items.isNotEmpty) {
              final firstItemPlant = items[0].planningPlant?.trim();
              debugPrint("syncMasterData: First item planningPlant (raw)=${items[0].planningPlant}, (trimmed)=$firstItemPlant");
              debugPrint("syncMasterData: Contains check: ${validPlantIds.contains(firstItemPlant)}");
            }
            final filtered = items.where((item) => validPlantIds.contains(item.planningPlant?.trim())).toList();
            debugPrint("syncMasterData: Equipment filter - input ${items.length}, filtered ${filtered.length}");
            if (filtered.isEmpty && items.isNotEmpty) {
              final samplePlants = items.take(3).map((e) => e.planningPlant).toList();
              debugPrint("syncMasterData: Sample equipment planningPlants (raw): $samplePlants");
              final sampleTrimmed = items.take(3).map((e) => e.planningPlant?.trim()).toList();
              debugPrint("syncMasterData: Sample equipment planningPlants (trimmed): $sampleTrimmed");
              debugPrint("syncMasterData: validPlantIds: $validPlantIds");
            }
            return filtered;
          }
        ).catchError((e) {
          debugPrint("Error fetching Equipment master data: $e");
        }),
      ]);
      
      final equipCount = await dbService.getEquipments();
      debugPrint("syncMasterData: Parallel sync complete, equipment in DB: ${equipCount.length}");

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
      final success = await _fetchGetMasterList(
        userId: userId,
        action: 'GetDeptMasterData',
        dataKey: 'departments',
        mapper: DepartmentModel.fromJson,
        insertToDb: LocalDatabaseService().insertDepartments,
      );
      if (success) {
        final dbService = LocalDatabaseService();
        final depts = await dbService.getDepartments();
        debugPrint("syncDepartmentMasterData: Successfully synced ${depts.length} departments to local storage");
      } else {
        debugPrint("syncDepartmentMasterData: Failed to sync departments");
      }
    } catch (e) {
      debugPrint('Error syncing department master data: $e');
    }
  }

  Future<void> syncStationFailureDropdownMasterData() async {
    await syncPriorityMasterData();
    await syncFailureCategoryMasterData();
    await syncUserRoleDeptMasterData();
    await syncDepartmentMasterData();
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

      if (response.statusCode != 200) break;

      final Map<String, dynamic> jsonBody = jsonDecode(response.body);
      if (jsonBody['success'] != true || jsonBody['data'] == null) break;

      List<dynamic> items = extractList(jsonBody['data']);
      debugPrint("_fetchPaginatedMasterData ($action): Fetched ${items.length} items from API (page $page).");
      if (items.isEmpty) break;

      List<T> mappedItems = items.map((e) => mapper(e as Map<String, dynamic>)).toList();

      if (filterList != null) {
        mappedItems = filterList(mappedItems);
      }

      if (mappedItems.isNotEmpty) {
        debugPrint("_fetchPaginatedMasterData ($action): Inserting ${mappedItems.length} filtered items into DB.");
        await insertToDb(mappedItems);
      }

      page++;
    }

    if (page > _maxPaginatedPages) {
      debugPrint('$action pagination stopped at max pages ($_maxPaginatedPages)');
    }
  }
}
