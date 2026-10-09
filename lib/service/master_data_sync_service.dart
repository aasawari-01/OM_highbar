import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../constants/colors.dart';
import '../feature/failure/service/failure_service.dart';
import '../feature/failure/controller/failure_list_controller.dart';
import '../core/controller/global_master_data_controller.dart';
import '../core/controller/session_controller.dart';
import 'local_database_service.dart';
import 'network_service/network_errors.dart';
import '../feature/failure/service/si_offline_service.dart';
import '../feature/failure/service/je_offline_service.dart';
import '../feature/failure/service/station_overlay.dart';
import '../service/auth_manager.dart';
import 'network_service/app_urls.dart';

class MasterDataSyncService extends GetxController {
  bool _syncInProgress = false;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  // Station failures that the server refused are tried again with a growing
  // pause (15s, 30s, ... 10 min) and at most [_autoRetryLimit] times by the
  // timer. Internet coming back and the sync button try them all again.
  static const int _autoRetryLimit = 6;
  final Map<int, DateTime> _retryAfter = {};
  
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
    // Started without internet: the first "connected" event must trigger a sync.
    Connectivity().checkConnectivity().then((results) {
      final connected = results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.ethernet);
      if (!connected) _wasOffline = true;
    }).catchError((_) {});
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
        // Send what was saved offline right away (after the connection settles).
        await Future.delayed(const Duration(seconds: 2));
        try {
          await syncPendingSubmissions(force: true);
        } catch (e) {
          debugPrint('MasterDataSyncService: pending sync after reconnect: $e');
        }
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
          final now = DateTime.now();
          final pending = (await _dbService.getPendingSubmissions()).where((p) {
            if (p['failureType'] == JeOfflineService.queueType) return true;
            final attempts = int.tryParse('${p['attempts']}') ?? 0;
            final wait = _retryAfter[p['id'] as int];
            return attempts < _autoRetryLimit && (wait == null || !wait.isAfter(now));
          }).toList();
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
      // The bundled files replaced the synced data: fetch changes again.
      await _dbService.setAppSetting('lastSyncDate', '');
      
      debugPrint("syncMasterData: Reloading GlobalMasterDataController");
      await Get.find<GlobalMasterDataController>().reloadMasterData();
      
      syncStatus.value = 'Data loaded from assets';
    });
  }

  Future<bool>? _transactionSyncRunning;

  /// Downloads the failure lists of the logged-in user (station failures and
  /// Section Incharge failures, one call: GetAllFailuresTransactionData) into
  /// the local copy, so the lists and details work offline. The first sync (or
  /// [forceAll]) takes everything; later syncs send the last sync date and
  /// merge only the changes. Returns false if the server could not be reached.
  Future<bool> syncFailureTransactions({bool forceAll = false}) {
    // Login, the list screens and the sync button can ask at the same time.
    return _transactionSyncRunning ??=
        _syncFailureTransactions(forceAll).whenComplete(() {
          _transactionSyncRunning = null;
        });
  }

  Future<bool> _syncFailureTransactions(bool forceAll) async {
    const lastSyncKey = 'failureTxnLastSync';
    const userKey = 'failureTxnUserId';
    try {
      final userId = await AuthManager().getUserId() ?? '';
      // A different user on this device must not see the previous user's copy.
      if (await _dbService.getAppSetting(userKey) != userId) {
        await _dbService.clearStationFailureCache();
        await _dbService.clearSiFailureCache();
        await _dbService.clearJeFailureCache();
        await _dbService.setAppSetting(lastSyncKey, '');
        await _dbService.setAppSetting(userKey, userId);
      }
      final last = await _dbService.getAppSetting(lastSyncKey);
      final incremental = !forceAll && (last ?? '').isNotEmpty;

      final res = await _failureService
          .getFailureTransactions(lastSyncDate: incremental ? last : null)
          .timeout(Duration(seconds: incremental ? 12 : 90));
      if (incremental) {
        await _dbService.upsertStationFailureCache(res.stationRecords);
        await _dbService.upsertSiFailureCache(res.siRecords);
        await _dbService.upsertJeFailureCache(res.jeRecords);
      } else {
        await _dbService.replaceStationFailureCache(res.stationRecords);
        await _dbService.replaceSiFailureCache(res.siRecords);
        await _dbService.replaceJeFailureCache(res.jeRecords);
      }
      final downloaded = DateTime.tryParse(res.downloadedAt ?? '')?.toUtc();
      await _dbService.setAppSetting(
          lastSyncKey,
          DateFormat('yyyy-MM-dd').format(downloaded ?? DateTime.now().toUtc()));
      debugPrint('syncFailureTransactions: ${incremental ? 'incremental' : 'full'} '
          'sync done, station=${res.stationRecords.length} '
          'si=${res.siRecords.length} je=${res.jeRecords.length}');
      return true;
    } catch (e) {
      debugPrint('syncFailureTransactions: failed, keeping the local copy: $e');
      return false;
    }
  }

  /// What the sync button does (same as the login sync): dropdown master data
  /// by last sync date, then any failures waiting to be sent.
  Future<void> syncMasterAndPending() async {
    await syncMasterDataFromAPI();
    await syncFailureTransactions();
    await syncPendingSubmissions(force: true);
  }

  /// Syncs master data from API using lastSyncDate to get only changed data
  Future<void> syncMasterDataFromAPI() async {
    debugPrint("syncMasterDataFromAPI: STARTING");
    await _executeSyncTask('Syncing master data from server...', () async {
      debugPrint("syncMasterDataFromAPI: Inside sync task");
      try {
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
      EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value, maskType: EasyLoadingMaskType.none);
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
            EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value, maskType: EasyLoadingMaskType.none);
            debugPrint("syncMasterDataFromAPI: ${syncStatus.value}");
            final funcLocs = data['functionalLocations'] as List;
            await _dbService.updateFunctionalLocationsFromAPI(funcLocs);
            // Same table the failure-form dropdowns read from.
            await _dbService.upsertFunctionalLocationsToMaster(funcLocs,
                onProgress: (done, total) {
              syncStatus.value = 'Syncing functional locations... $done/$total';
              EasyLoading.showProgress(total == 0 ? 1.0 : done / total,
                  status: syncStatus.value,
                  maskType: EasyLoadingMaskType.none);
            });
            totalUpdates += funcLocs.length;
            debugPrint("syncMasterDataFromAPI: Updated ${funcLocs.length} functional locations");
          } else {
            debugPrint("syncMasterDataFromAPI: No functional locations to sync");
          }

          // Sync equipment (dropdown table)
          if (data['equipments'] != null) {
            final equipments = data['equipments'] as List;
            await _dbService.upsertEquipmentsToMaster(equipments,
                onProgress: (done, total) {
              syncStatus.value = 'Syncing equipment... $done/$total';
              EasyLoading.showProgress(total == 0 ? 1.0 : done / total,
                  status: syncStatus.value,
                  maskType: EasyLoadingMaskType.none);
            });
            totalUpdates += equipments.length;
            debugPrint("syncMasterDataFromAPI: Updated ${equipments.length} equipments");
          } else {
            debugPrint("syncMasterDataFromAPI: No equipments to sync");
          }
          
          // Sync measurement points
          if (data['measurementPoints'] != null) {
            completedSteps++;
            final percentage = ((completedSteps / totalSteps) * 100).toInt();
            syncStatus.value = 'Syncing measurement points... $percentage%';
            EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value, maskType: EasyLoadingMaskType.none);
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
            EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value, maskType: EasyLoadingMaskType.none);
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
            EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value, maskType: EasyLoadingMaskType.none);
            debugPrint("syncMasterDataFromAPI: ${syncStatus.value}");
            final users = data['users'] as List;
            // Users are saved in UserMaster.db, the table they are read from.
            // (The old insert into the small MasterUsers table has columns it
            // does not have and failed the whole sync.)
            await _dbService.upsertUsersToMaster(users);
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
            EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value, maskType: EasyLoadingMaskType.none);
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
            EasyLoading.showProgress(percentage / 100.0, status: syncStatus.value, maskType: EasyLoadingMaskType.none);
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
      } catch (e) {
        // Never leave the progress popup on screen when the sync fails.
        debugPrint("syncMasterDataFromAPI: failed: $e");
        EasyLoading.showError('Master data sync failed');
        rethrow;
      }
    });
    debugPrint("syncMasterDataFromAPI: FINISHED");
  }

  Future<String> _getLastSyncDate() async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      "SELECT value FROM AppSettings WHERE key = 'lastSyncDate'"
    );
    if (await _dbService.getAppSetting('usersMasterBackfillV1') != 'done') {
      await _dbService.setAppSetting('usersMasterBackfillV1', 'done');
      return await _dbService.getMasterBaselineDate() ?? '2026-08-01';
    }
    if (result.isNotEmpty) {
      final saved = result.first['value']?.toString();
      if (saved != null && saved.isNotEmpty) return saved;
    }
    // First sync: start from the date of the data bundled in the asset
    // databases so nothing changed after the export is missed.
    return await _dbService.getMasterBaselineDate() ?? '2026-08-01';
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
    // Offline failure lists are not in use for now: the server no longer has
    // the GetStationFailureListWithData procedure, and the lists load online.
    // Only the dropdown master data is synced (syncMasterDataFromAPI).
    return;
    // ignore: dead_code
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
  Future<void> syncPendingSubmissions({bool force = false}) async {
    final pendingSubmissions = await _dbService.getPendingSubmissions();
    if (pendingSubmissions.isEmpty) return;
    if (force) _retryAfter.clear();

    await _executeSyncTask('Syncing pending submissions...', () async {
      int syncedCount = 0;
      var resync = false; // a queued action was dropped: reload the server state
      final siOffline = SiOfflineService(failureService: _failureService);
      final jeOffline = JeOfflineService(failureService: _failureService);
      final syncedNumbers = <String>[]; // real failure numbers of Station failures
      var stationSynced = 0;
      var stationFailed = 0;
      var siSynced = 0; // Section Incharge: sent and failed
      var siFailed = 0;
      final siCreatedNumbers = <String>[];
      final siActionCounts = <String, int>{};

      for (var submission in pendingSubmissions) {
        if (submission['failureType'] == 'Station') {
          final sid = submission['id'] as int;
          final payload = Map<String, dynamic>.from(submission['payload'] as Map);
          final attempts = int.tryParse('${submission['attempts']}') ?? 0;
          // Never send what another user saved on this device.
          final me = await AuthManager().getUserId() ?? '';
          final owner = payload['CreatedBy']?.toString() ?? '';
          if (owner.isNotEmpty && me.isNotEmpty && owner != me) {
            debugPrint('syncPendingSubmissions: station failure $sid belongs to user $owner, skipped');
            continue;
          }
          if (!force &&
              (attempts >= _autoRetryLimit ||
                  (_retryAfter[sid]?.isAfter(DateTime.now()) ?? false))) {
            continue;
          }
          try {
            final no = await _failureService
                .createStationFailure(payload)
                .timeout(const Duration(seconds: 60));
            await StationOverlay.save(no, await StationOverlay.build(payload));
            await _dbService.deletePendingSubmission(sid);
            // The real failure comes back with the next list sync.
            await _dbService.deleteStationOfflineEntries(sid);
            _retryAfter.remove(sid);
            syncedCount++;
            stationSynced++;
            if ((no ?? '').trim().isNotEmpty) syncedNumbers.add(no!.trim());
          } catch (e) {
            if (isNetworkError(e)) {
              debugPrint('syncPendingSubmissions: server not reached, stopping');
              break; // still offline: the rest waits
            }
            // The server answered with an error: keep the failure, show why.
            final reason = e.toString().replaceFirst('Exception: ', '');
            final n = await _dbService.recordSubmissionFailure(sid, reason);
            await _dbService.markStationOfflineEntries(sid, failed: true, error: reason);
            _retryAfter[sid] =
                DateTime.now().add(Duration(seconds: (15 * (1 << n.clamp(0, 6))).clamp(15, 600)));
            stationFailed++;
            debugPrint('syncPendingSubmissions: station failure $sid failed ($n): $reason');
          }
          continue;
        }

        // Section Incharge: create / update / assign / close ... saved offline.
        if (submission['failureType'] == SiOfflineService.queueType) {
          final sid = submission['id'] as int;
          final payload = Map<String, dynamic>.from(submission['payload'] as Map);
          final action = payload['action']?.toString() ?? '';
          final nid = int.tryParse('${payload['notificationId']}') ?? 0;
          final attempts = int.tryParse('${submission['attempts']}') ?? 0;
          // Never send what another user saved on this device.
          final me = await AuthManager().getUserId() ?? '';
          final owner = payload['queuedBy']?.toString() ?? '';
          if (owner.isNotEmpty && me.isNotEmpty && owner != me) {
            debugPrint('syncPendingSubmissions: SI item $sid belongs to user $owner, skipped');
            continue;
          }
          if (!force &&
              (attempts >= _autoRetryLimit ||
                  (_retryAfter[sid]?.isAfter(DateTime.now()) ?? false))) {
            continue;
          }

          // The server refused it: keep it, show why, try again later.
          Future<void> failIt(String reason) async {
            final n = await _dbService.recordSubmissionFailure(sid, reason);
            if (action == 'create') {
              await _dbService.markSiCreateEntry(sid, failed: true, error: reason);
            } else if (nid > 0) {
              await _dbService.setSiPendingError(nid, reason);
            }
            _retryAfter[sid] = DateTime.now()
                .add(Duration(seconds: (15 * (1 << n.clamp(0, 6))).clamp(15, 600)));
            siFailed++;
            debugPrint('syncPendingSubmissions: SI $action $sid failed ($n): $reason');
          }

          try {
            final ok = await siOffline.replay(payload).timeout(const Duration(seconds: 90));
            if (ok) {
              await _dbService.deletePendingSubmission(sid);
              if (action == 'create') {
                // The real failure comes back with the next list sync.
                await _dbService.deleteSiCreateEntry(sid);
                final no = siOffline.lastCreatedNumber?.trim() ?? '';
                if (no.isNotEmpty) siCreatedNumbers.add(no);
              } else if (nid > 0) {
                await _dbService.clearSiFailurePending(nid);
              }
              final label = SiOfflineService.label(action);
              siActionCounts[label] = (siActionCounts[label] ?? 0) + 1;
              _retryAfter.remove(sid);
              syncedCount++;
              siSynced++;
              resync = true;
            } else {
              await failIt('The server did not accept it');
            }
          } catch (e) {
            if (isNetworkError(e)) {
              debugPrint('syncPendingSubmissions: server not reached, stopping');
              break; // still offline: the rest waits
            }
            await failIt(e.toString().replaceFirst('Exception: ', ''));
          }
          continue;
        }

        final isJe = submission['failureType'] == JeOfflineService.queueType;
        if (isJe) {
          // Section Incharge actions (assign, close, update, create, ...)
          final sid = submission['id'] as int;
          final payload = Map<String, dynamic>.from(submission['payload'] as Map);
          final action = payload['action']?.toString() ?? '';
          final nid = int.tryParse('${payload['notificationId']}') ?? 0;

          Future<void> dropIt(String reason) async {
            debugPrint('syncPendingSubmissions: giving up $action ($reason)');
            await _dbService.deletePendingSubmission(sid);
            if (nid > 0) {
              isJe
                  ? await _dbService.clearJeFailurePending(nid)
                  : await _dbService.clearSiFailurePending(nid);
            }
            if (action == 'create') {
              final db = await _dbService.database;
              await db.update('FailureList', {'syncStatus': 'failed'},
                  where: 'id = ?', whereArgs: [-sid]);
            }
            resync = true;
            Get.snackbar(
              'Not sent',
              '${SiOfflineService.label(action)} could not be sent: $reason',
              backgroundColor: AppColors.red,
              colorText: AppColors.white1,
            );
          }

          try {
            final ok = await (isJe
                    ? jeOffline.replay(payload)
                    : siOffline.replay(payload))
                .timeout(const Duration(seconds: 90));
            if (ok) {
              await _dbService.deletePendingSubmission(sid);
              if (nid > 0) {
                isJe
                    ? await _dbService.clearJeFailurePending(nid)
                    : await _dbService.clearSiFailurePending(nid);
              }
              if (action == 'create') {
                final db = await _dbService.database;
                await db.update('FailureList', {'syncStatus': 'synced'},
                    where: 'id = ?', whereArgs: [-sid]);
              }
              syncedCount++;
              resync = true;
            } else {
              await dropIt('the server did not accept it');
            }
          } catch (e) {
            if (isNetworkError(e)) {
              debugPrint('syncPendingSubmissions: server not reached, stopping');
              break; // still offline: try again later
            }
            final attempts = await _dbService.recordSubmissionFailure(sid, e.toString());
            if (attempts >= 3) await dropIt(e.toString());
          }
          continue;
        }

      }

      syncStatus.value = syncedCount > 0 
          ? 'Synced $syncedCount submissions' 
          : 'Sync complete';
          
      if (stationSynced > 0 || stationFailed > 0) {
        final lines = <String>[
          if (stationSynced > 0)
            '$stationSynced offline failure${stationSynced == 1 ? '' : 's'} synced'
                '${syncedNumbers.isEmpty ? '' : ': ${syncedNumbers.join(', ')}'}',
          if (stationFailed > 0)
            '$stationFailed could not be sent. Open the list to retry or discard.',
        ];
        Get.snackbar(
          stationFailed > 0 ? 'Sync finished with errors' : 'Sync Complete',
          lines.join('\n'),
          backgroundColor: stationFailed > 0 ? AppColors.red : AppColors.green,
          colorText: AppColors.white1,
          duration: const Duration(seconds: 6),
        );
      }
      if (siSynced > 0 || siFailed > 0) {
        final lines = <String>[
          if (siCreatedNumbers.isNotEmpty)
            'Created: ${siCreatedNumbers.join(', ')}',
          if (siActionCounts.entries.any((e) => e.key != 'Create'))
            'Sent: ${siActionCounts.entries.where((e) => e.key != 'Create').map((e) => e.value > 1 ? '${e.key} x${e.value}' : e.key).join(', ')}',
          if (siFailed > 0)
            '$siFailed could not be sent. Open the list to retry or discard.',
        ];
        Get.snackbar(
          siFailed > 0 ? 'Sync finished with errors' : 'Sync Complete',
          lines.join('\n'),
          backgroundColor: siFailed > 0 ? AppColors.red : AppColors.green,
          colorText: AppColors.white1,
          duration: const Duration(seconds: 6),
        );
      }
      if (syncedCount > stationSynced + siSynced) {
        Get.snackbar(
          'Sync Complete',
          'Successfully synced ${syncedCount - stationSynced - siSynced} pending submissions',
          backgroundColor: AppColors.green,
          colorText: AppColors.white1,
        );
      }
      if (syncedCount > 0 || resync || stationFailed > 0 || siFailed > 0) {
        debugPrint("syncPendingSubmissions: Reloading lists after offline submissions");
        // Bring the server's state of what was just sent (a dropped action gets a
        // full reload so its local change disappears).
        await syncFailureTransactions(forceAll: resync);
        // A list screen that is open shows the new state right away. (The lists
        // are registered by type and tag, so both are needed to find them.)
        for (final tag in const ['Station', 'Maintenance', 'JE']) {
          try {
            if (Get.isRegistered<FailureListController>(tag: tag)) {
              await Get.find<FailureListController>(tag: tag).fetchFailures();
            }
          } catch (e) {
            debugPrint("Could not refresh $tag list: $e");
          }
        }
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
