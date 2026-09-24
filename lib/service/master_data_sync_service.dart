import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../constants/colors.dart';
import '../feature/failure/service/failure_service.dart';
import '../core/controller/global_master_data_controller.dart';
import '../core/controller/session_controller.dart';
import 'local_database_service.dart';
import '../service/auth_manager.dart';
import 'network_service/app_urls.dart';

class MasterDataSyncService extends GetxController {
  bool _syncInProgress = false;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;
  
  // Reusable service instances to optimize memory and avoid repeated allocations
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final FailureService _failureService = FailureService();
  
  // Reactive sync status for UI to observe
  final RxBool isSyncing = false.obs;
  final RxString syncStatus = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _startConnectivityMonitoring();
    _startPeriodicSync();
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      final isConnected = results.contains(ConnectivityResult.wifi) || 
                          results.contains(ConnectivityResult.mobile) ||
                          results.contains(ConnectivityResult.ethernet);
      
      if (isConnected && _wasOffline) {
        debugPrint("MasterDataSyncService: Internet restored, triggering sync");
        _wasOffline = false;
        // Sync station failures when internet comes back online
        await syncFailureList('Station');
        // Sync last selected station details
        await _syncLastSelectedStation();
      } else if (!isConnected) {
        debugPrint("MasterDataSyncService: Internet lost");
        _wasOffline = true;
      }
    });
  }

  void _startPeriodicSync() {
    // Check for pending submissions every 15 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!_syncInProgress) {
        try {
          final pending = await _dbService.getPendingSubmissions();
          if (pending.isNotEmpty) {
            debugPrint("Periodic sync: Found ${pending.length} pending submissions.");
            await syncPendingSubmissions();
          }
        } catch (e) {
          debugPrint("Periodic sync error: $e");
        }
      }
    });
  }

  /// A reusable wrapper for sync tasks to handle state and error management cleanly
  Future<void> _executeSyncTask(String startMessage, Future<void> Function() task) async {
    if (_syncInProgress) {
      debugPrint("Sync already in progress, skipping duplicate request.");
      return;
    }

    _syncInProgress = true;
    isSyncing.value = true;
    syncStatus.value = startMessage;
    
    try {
      await task();
    } catch (e) {
      debugPrint("Sync Error: $e");
      syncStatus.value = 'Sync failed: $e';
    } finally {
      _syncInProgress = false;
      isSyncing.value = false;
    }
  }

  Future<void> syncMasterData() async {
    await _executeSyncTask('Loading data from assets...', () async {
      debugPrint("syncMasterData: Loading all data from asset databases");
      await _dbService.forceImportFromAssets();
      
      debugPrint("syncMasterData: Reloading GlobalMasterDataController");
      await Get.find<GlobalMasterDataController>().reloadMasterData();
      
      syncStatus.value = 'Data loaded from assets';
    });
  }

  /// Syncs master data from API using lastSyncDate to get only changed data
  Future<void> syncMasterDataFromAPI() async {
    debugPrint("syncMasterDataFromAPI: STARTING");
    await _executeSyncTask('Syncing master data from server...', () async {
      debugPrint("syncMasterDataFromAPI: Inside sync task");
      final userId = await AuthManager().getUserId() ?? 1;
      final lastSyncDate = await _getLastSyncDate();
      
      final apiUrl = '${AppUrls.baseUrl}${AppUrls.getMasterData}';
      
      final requestBody = {
        "userId": userId,
        "action": "",
        "pageNumber": 0,
        "pageSize": 0,
        "lastSyncDate": lastSyncDate,
        "syncType": "all"
      };
      
      debugPrint("syncMasterDataFromAPI: Calling API with lastSyncDate: $lastSyncDate");
      debugPrint("syncMasterDataFromAPI: API URL: $apiUrl");
      debugPrint("syncMasterDataFromAPI: Request body: ${jsonEncode(requestBody)}");
      
      // Total steps: API call + 6 data types = 7 steps
      final totalSteps = 7;
      int completedSteps = 0;
      
      // Update status before API call
      completedSteps++;
      final percentage = ((completedSteps / totalSteps) * 100).toInt();
      syncStatus.value = 'Connecting to server... $percentage%';
      EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value);
      debugPrint("syncMasterDataFromAPI: ${syncStatus.value}");
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint("syncMasterDataFromAPI: API call timed out after 30 seconds");
          throw Exception('API request timed out');
        },
      );
      
      debugPrint("syncMasterDataFromAPI: Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint("syncMasterDataFromAPI: Response data: $responseData");
        
        if (responseData['success'] == true) {
          final data = responseData['data'];
          int totalUpdates = 0;
          
          debugPrint("syncMasterDataFromAPI: Starting to sync data types");
          
          // Sync functional locations
          if (data['functionalLocations'] != null) {
            completedSteps++;
            final percentage = ((completedSteps / totalSteps) * 100).toInt();
            syncStatus.value = 'Syncing functional locations... $percentage%';
            EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value);
            debugPrint("syncMasterDataFromAPI: ${syncStatus.value}");
            final funcLocs = data['functionalLocations'] as List;
            await _dbService.updateFunctionalLocationsFromAPI(funcLocs);
            totalUpdates += funcLocs.length;
            debugPrint("syncMasterDataFromAPI: Updated ${funcLocs.length} functional locations");
          } else {
            debugPrint("syncMasterDataFromAPI: No functional locations to sync");
          }
          
          // Sync measurement points
          if (data['measurementPoints'] != null) {
            completedSteps++;
            final percentage = ((completedSteps / totalSteps) * 100).toInt();
            syncStatus.value = 'Syncing measurement points... $percentage%';
            EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value);
            debugPrint("syncMasterDataFromAPI: ${syncStatus.value}");
            final measPoints = data['measurementPoints'] as List;
            await _dbService.updateMeasurementPointsFromAPI(measPoints);
            totalUpdates += measPoints.length;
            debugPrint("syncMasterDataFromAPI: Updated ${measPoints.length} measurement points");
          } else {
            debugPrint("syncMasterDataFromAPI: No measurement points to sync");
          }
          
          // Sync locations
          if (data['locations'] != null) {
            completedSteps++;
            final percentage = ((completedSteps / totalSteps) * 100).toInt();
            syncStatus.value = 'Syncing locations... $percentage%';
            EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value);
            debugPrint("syncMasterDataFromAPI: ${syncStatus.value}");
            final locations = data['locations'] as List;
            await _dbService.updateLocationsFromAPI(locations);
            totalUpdates += locations.length;
            debugPrint("syncMasterDataFromAPI: Updated ${locations.length} locations");
          } else {
            debugPrint("syncMasterDataFromAPI: No locations to sync");
          }
          
          // Sync users
          if (data['users'] != null) {
            completedSteps++;
            final percentage = ((completedSteps / totalSteps) * 100).toInt();
            syncStatus.value = 'Syncing users... $percentage%';
            EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value);
            debugPrint("syncMasterDataFromAPI: ${syncStatus.value}");
            final users = data['users'] as List;
            await _dbService.updateUsersFromAPI(users);
            totalUpdates += users.length;
            debugPrint("syncMasterDataFromAPI: Updated ${users.length} users");
          } else {
            debugPrint("syncMasterDataFromAPI: No users to sync");
          }
          
          // Sync materials
          if (data['materials'] != null) {
            completedSteps++;
            final percentage = ((completedSteps / totalSteps) * 100).toInt();
            syncStatus.value = 'Syncing materials... $percentage%';
            EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value);
            debugPrint("syncMasterDataFromAPI: ${syncStatus.value}");
            final materials = data['materials'] as List;
            await _dbService.updateMaterialsFromAPI(materials);
            totalUpdates += materials.length;
            debugPrint("syncMasterDataFromAPI: Updated ${materials.length} materials");
          } else {
            debugPrint("syncMasterDataFromAPI: No materials to sync");
          }
          
          // Sync priorities
          if (data['priorities'] != null) {
            completedSteps++;
            final percentage = ((completedSteps / totalSteps) * 100).toInt();
            syncStatus.value = 'Syncing priorities... $percentage%';
            EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value);
            debugPrint("syncMasterDataFromAPI: ${syncStatus.value}");
            final priorities = data['priorities'] as List;
            await _dbService.updatePrioritiesFromAPI(priorities);
            totalUpdates += priorities.length;
            debugPrint("syncMasterDataFromAPI: Updated ${priorities.length} priorities");
          } else {
            debugPrint("syncMasterDataFromAPI: No priorities to sync");
          }
          
          debugPrint("syncMasterDataFromAPI: Updating last sync date");
          // Update last sync date
          await _setLastSyncDate(DateTime.now().toIso8601String().split('T')[0]);
          
          debugPrint("syncMasterDataFromAPI: Reloading master data controller");
          // Reload master data controller
          await Get.find<GlobalMasterDataController>().reloadMasterData();
          
          syncStatus.value = 'Synced $totalUpdates records from server';
          debugPrint("syncMasterDataFromAPI: ${syncStatus.value}");
          EasyLoading.showSuccess('Successfully synced $totalUpdates records');
        } else {
          syncStatus.value = 'Sync failed: ${responseData['message']}';
          debugPrint("syncMasterDataFromAPI: ${syncStatus.value}");
          EasyLoading.showError(syncStatus.value);
        }
      } else {
        syncStatus.value = 'Sync failed: ${response.reasonPhrase}';
        debugPrint("syncMasterDataFromAPI: ${syncStatus.value}");
        EasyLoading.showError(syncStatus.value);
      }
    });
    debugPrint("syncMasterDataFromAPI: FINISHED");
  }

  Future<String> _getLastSyncDate() async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      "SELECT value FROM AppSettings WHERE key = 'lastSyncDate'"
    );
    if (result.isNotEmpty) {
      return result.first['value']?.toString() ?? '2026-08-01';
    }
    return '2026-08-01';
  }

  Future<void> _setLastSyncDate(String date) async {
    final db = await _dbService.database;
    await db.rawInsert(
      "INSERT OR REPLACE INTO AppSettings (key, value) VALUES ('lastSyncDate', ?)",
      [date]
    );
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

  /// Syncs failure list for a specific failure type
  /// If forceFullSync is true, sends null as lastSyncDate to get all data
  Future<void> syncFailureList(String failureType, {bool forceFullSync = false}) async {
    await _executeSyncTask('Syncing $failureType failures...', () async {
      if (failureType == 'Station') {
        final lastSyncDate = forceFullSync ? null : await _getStationFailureLastSyncDate();
        final failures = await _failureService.getStationFailureListWithData(lastSyncDate: lastSyncDate);
        
        try {
          final masterDataController = Get.find<GlobalMasterDataController>();
          
          // CPU/Memory Optimization: Use a HashMap for O(1) lookups instead of O(N) list search per failure
          final locationMap = {
            for (var loc in masterDataController.locationTypeList) 
              loc.value: loc.label
          };

          final enrichedFailures = failures.map((failure) {
            final enriched = Map<String, dynamic>.from(failure);
            if (enriched.containsKey('locationId')) {
              final locationId = enriched['locationId'].toString();
              enriched['locationName'] = locationMap[locationId] ?? enriched['location']?.toString() ?? '';
            }
            // Set syncStatus to 'online' for all items fetched from API
            enriched['syncStatus'] = 'online';
            return enriched;
          }).toList();
          
          await _dbService.clearFailureList(failureType);
          await _dbService.insertFailureList(enrichedFailures, failureType);
          // Update last sync date
          await _setStationFailureLastSyncDate(DateTime.now().toIso8601String().split('T')[0]);
          syncStatus.value = 'Synced ${enrichedFailures.length} station failures';
        } catch (e) {
          debugPrint("syncFailureList enrichment error: $e");
          // Fallback: insert without enrichment
          for (var failure in failures) {
            failure['syncStatus'] = 'online';
          }
          await _dbService.clearFailureList(failureType);
          await _dbService.insertFailureList(failures, failureType);
          syncStatus.value = 'Synced ${failures.length} station failures (without enrichment)';
        }
        
        // Refresh the UI controller if it is currently registered
        try {
          if (Get.isRegistered(tag: failureType)) {
            final failureListController = Get.find(tag: failureType);
            await failureListController.fetchFailures(forceRefresh: true);
          }
        } catch (e) {
          debugPrint("Could not refresh failure list controller: $e");
        }
      } else {
        syncStatus.value = 'Sync not implemented for $failureType';
      }
    });
  }

  /// Syncs pending failure submissions when internet becomes available
  Future<void> syncPendingSubmissions() async {
    final pendingSubmissions = await _dbService.getPendingSubmissions();
    if (pendingSubmissions.isEmpty) return;

    await _executeSyncTask('Syncing pending submissions...', () async {
      int syncedCount = 0;

      for (var submission in pendingSubmissions) {
        try {
          final payload = submission['payload'] as Map<String, dynamic>;
          final failureType = submission['failureType'] as String?;
          
          if (failureType == 'Station') {
            // Get the API response with the actual failure number
            final apiFailureNo = await _failureService.createStationFailure(payload);
            debugPrint("syncPendingSubmissions: API returned failureNo: $apiFailureNo");
            
            await _dbService.updateSubmissionSynced(submission['id'] as int, true);
            
            // Update the offline entry in FailureList table with the API response
            try {
              final db = await _dbService.database;
              
              // Debug: Check all entries in FailureList
              final allEntries = await db.query('FailureList');
              debugPrint("syncPendingSubmissions: Total FailureList entries: ${allEntries.length}");
              for (var entry in allEntries) {
                debugPrint("syncPendingSubmissions: Entry - id: ${entry['id']}, failureNo: ${entry['failureNo']}, syncStatus: ${entry['syncStatus']}");
              }
              
              // Get the offline entry
              final offlineEntries = await db.query(
                'FailureList',
                where: 'id = ? AND syncStatus = ?',
                whereArgs: [submission['id'], 'offline'],
              );
              
              debugPrint("syncPendingSubmissions: Query for id=${submission['id']}, syncStatus='offline' returned ${offlineEntries.length} entries");
              
              if (offlineEntries.isNotEmpty) {
                // Update the existing offline entry with API response
                await db.update(
                  'FailureList',
                  {
                    'failureNo': apiFailureNo,
                    'statusName': 'Open',
                    'syncStatus': 'synced',
                    'lastSyncedAt': DateTime.now().toIso8601String(),
                  },
                  where: 'id = ?',
                  whereArgs: [submission['id']],
                );
                debugPrint("syncPendingSubmissions: Updated offline entry with API failureNo: $apiFailureNo");
              } else {
                debugPrint("syncPendingSubmissions: No offline entry found for id: ${submission['id']}");
              }
            } catch (e) {
              debugPrint("Error updating offline entry: $e");
            }
            
            await _dbService.deletePendingSubmission(submission['id'] as int);
            syncedCount++;
          }
        } catch (e) {
          debugPrint("Error syncing submission ${submission['id']}: $e");
          await _dbService.updateSubmissionSynced(
            submission['id'] as int, 
            false, 
            error: e.toString()
          );
        }
      }

      syncStatus.value = syncedCount > 0 
          ? 'Synced $syncedCount submissions' 
          : 'Sync complete';
          
      if (syncedCount > 0) {
        Get.snackbar(
          'Sync Complete',
          'Successfully synced $syncedCount pending submissions',
          backgroundColor: AppColors.green,
          colorText: AppColors.white1,
        );
        debugPrint("syncPendingSubmissions: Triggering station failure sync after offline submission");
        await syncFailureList('Station');
      }
    });
  }

  /// Syncs the last selected station when internet is restored
  Future<void> _syncLastSelectedStation() async {
    try {
      final session = Get.find<SessionController>();
      final stationId = session.selectedStationId.value;
      final stationName = session.selectedStationName.value;
      
      if (stationId != null && stationId.isNotEmpty && stationId != '0' && stationName != null && stationName.isNotEmpty) {
        debugPrint("_syncLastSelectedStation: Syncing station $stationName (ID: $stationId)");
        final stationIdInt = int.tryParse(stationId) ?? 0;
        final success = await _failureService.saveUserStationDetails(stationIdInt, stationName);
        if (success) {
          debugPrint("_syncLastSelectedStation: Successfully synced station details");
        } else {
          debugPrint("_syncLastSelectedStation: Failed to sync station details");
        }
      } else {
        debugPrint("_syncLastSelectedStation: No station selected, skipping sync");
      }
    } catch (e) {
      debugPrint("_syncLastSelectedStation error: $e");
    }
  }
}
