import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../service/auth_manager.dart';
import '../../../core/controller/session_controller.dart';
import '../../../service/local_database_service.dart';
import '../model/failure_list_response.dart';
import '../service/failure_service.dart';
import '../service/si_ids.dart';
import '../service/station_overlay.dart';
import '../../../service/master_data_sync_service.dart';

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

  /// FMC / TPC / CSS / RSC users get the OCC failures reported to them from a
  /// dedicated API.
  bool get _isFmc {
    final role = _sessionController.selectedRole.value?.roleDescr ?? '';
    return SessionController.isOccDelegateRole(role);
  }

  /// DCC users see depot failures for the depot they selected.
  bool get isDcc {
    final role = _sessionController.selectedRole.value?.roleDescr ?? '';
    return role.toUpperCase().contains('DCC');
  }

  /// Chief Controller (the OCC-failure creator role) sees the OCC failures
  /// from getFailureList.
  bool get _isOccRole {
    final role = _sessionController.selectedRole.value?.roleDescr ?? '';
    return SessionController.isOccFailureCreatorRole(role) && !_isFmc;
  }

  bool get _useOccFailureListApi =>
      failureType.toLowerCase() == 'occ' && _isOccRole;

  bool get _useDepotFailureListApi => failureType.toLowerCase() == 'depot' && isDcc;

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

    if (_isFmc) return true;

    if (_useDepotFailureListApi) return true;

    if (_useOccFailureListApi) return true;

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

      if (_isFmc) {
        await _fetchFmcFailures();
      } else if (_useDepotFailureListApi) {
        await _fetchDepotFailures();
      } else if (_useOccFailureListApi) {
        await _fetchOccRoleFailures();
      } else if (_isJE) {
        // Junior Engineer: lists come from the local copy (synced from
        // GetAllFailuresTransactionData), so they also work offline.
        await _fetchJeFailures();
      } else if (_useStationFailureListApi) {
        await _fetchStationControllerFailures(forceAll: forceRefresh);
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
        // Section Incharge: lists come from the local copy (synced from
        // GetAllFailuresTransactionData), so they also work offline.
        await _fetchSectionInchargeFailures();
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

  int? _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');

  /// Section Incharge list: syncs the changes (also done at login), then shows
  /// the local copy of siFailureList for the selected department, plus failures
  /// created offline that are still waiting to be sent (orange dot).
  Future<void> _fetchSectionInchargeFailures() async {
    final synced = await Get.find<MasterDataSyncService>().syncFailureTransactions();
    if (!synced) {
      debugPrint('_fetchSectionInchargeFailures: server not reached, using local copy');
      isOfflineMode.value = true;
    }

    final deptId = _sessionController.selectedDepartment.value?.deptId ?? 0;
    final staffId = selectedStaffId.value;

    final deptNames = <int, String?>{};
    final deptCodes = <int, String?>{};
    final locNames = <int, String?>{};
    final flNames = <int, String?>{};

    final items = <FailureItem>[];
    for (final row in await _dbService.getSiFailureCache()) {
      try {
        final record = row['record'] as Map<String, dynamic>;
        final si = Map<String, dynamic>.from(record['siFailure'] as Map);
        final notificationId = _toInt(si['notificationId']);
        if (notificationId == null) continue;

        final itemDept = _toInt(si['deptId']) ?? 0;
        if (deptId > 0 && itemDept > 0 && itemDept != deptId) continue;
        final assigned = _toInt(si['assignedUserId']) ?? 0;
        if (staffId != null && staffId > 0 && assigned != staffId) continue;

        final locId = _toInt(si['locationTypeId']) ?? 0;
        final flId = _toInt(si['functionLocationId']) ?? 0;
        if (itemDept > 0 && !deptNames.containsKey(itemDept)) {
          deptNames[itemDept] = await _dbService.getDeptNameById(itemDept);
          deptCodes[itemDept] = await _dbService.getDeptCodeById(itemDept);
        }
        if (locId > 0 && !locNames.containsKey(locId)) {
          locNames[locId] = await _dbService.getLocationNameById(locId);
        }
        if (flId > 0 && !flNames.containsKey(flId)) {
          final fl = await _dbService.getFailureFunctionalLocationRow(flId);
          final code = fl?['FuncLocation']?.toString() ?? '';
          final desc = fl?['FuncDescription']?.toString() ?? '';
          flNames[flId] = code.isEmpty ? null : (desc.isEmpty ? code : '$code - $desc');
        }

        final occurred = si['actualFailureOccuranceOn']?.toString();
        final pendingAction = row['pendingAction']?.toString();
        final pendingError = row['pendingError']?.toString() ?? '';
        items.add(FailureItem(
          id: notificationId,
          // The numeric notification id is what the assign / close / ... calls
          // send as jobCardNo and what the details call looks the failure up by.
          failureNo: encryptedIdFromSiFailure(si, notificationId) ??
              notificationId.toString(),
          notificationCode: si['notificationCode']?.toString(),
          jobCardId: encryptedIdFromSiFailure(si, notificationId) ??
              notificationId.toString(),
          failureDescription: si['description']?.toString(),
          functionLocationId: flId > 0 ? flId : null,
          functionalLocation: flNames[flId],
          statusName: si['mainStatusName']?.toString(),
          statusId: _toInt(si['statusId']),
          failureOccuranceDateTime: occurred,
          actualFailureOccuranceDatetime: occurred,
          assignedUserId: assigned > 0 ? assigned : null,
          assignedUseeName: si['assignedUseeName']?.toString(),
          occRequestStatus: si['occRequestStatus']?.toString(),
          otherRequestFrom: si['otherRequestFrom']?.toString(),
          locationName: locNames[locId],
          creationType: 'Manual',
          priority: si['priorityType']?.toString(),
          departmentName: deptNames[itemDept],
          subLocation: si['locationFailure']?.toString(),
          system: si['system']?.toString(),
          subSystems: si['subSystem']?.toString(),
          isTrainSetFailure: si['isTrainSetFailure'] as bool?,
          occRequestStatusId: _toInt(si['occRequestStatusId']),
          freq: _toInt(si['frequency']),
          frequency: si['frequency']?.toString(),
          createdDate: si['createdOn']?.toString(),
          deptCode: deptCodes[itemDept],
          deptId: itemDept > 0 ? itemDept : null,
          syncStatus: pendingAction == null
              ? 'synced'
              : (pendingError.isEmpty ? 'offline' : 'failed'),
          remarks: pendingError.isEmpty ? null : pendingError,
          pendingAction: pendingAction,
        ));
      } catch (e) {
        debugPrint('_fetchSectionInchargeFailures: skipped bad row: $e');
      }
    }
    items.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    // Staff the Section Incharge can assign to: the Junior Engineers of his
    // departments, from the local user table.
    try {
      final deptIds = <int>{
        for (final d in _sessionController.departments)
          if (d.deptId != null) d.deptId!,
        if (deptId > 0) deptId,
      };
      final staff = await _dbService.getJuniorEngineersForDepartments(deptIds,
          businessArea: await AuthManager().getBusinessArea());
      staffList.assignAll(staff.map((r) => StaffItem(
        userId: _toInt(r['UserId']),
        userName: r['UserName']?.toString(),
        deptID: _toInt(r['DeptId']),
        deptName: r['DeptName']?.toString(),
      )));
    } catch (e) {
      debugPrint('_fetchSectionInchargeFailures: staff list error: $e');
    }

    // Created offline and not sent yet: kept in FailureList until synced.
    final pending = <FailureItem>[];
    for (final r in await _dbService.getFailureList(failureType)) {
      // 'failed' = the server refused it: stays visible with Retry / Discard.
      if (r['syncStatus'] == 'offline' || r['syncStatus'] == 'failed') {
        try {
          pending.add(FailureItem.fromJson(r));
        } catch (_) {}
      }
    }
    // Newest first (offline entries have negative ids: -(submissionId)).
    pending.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

    failures.assignAll([...pending, ...items]);
    if (failures.isEmpty) {
      errorMessage.value = isOfflineMode.value
          ? 'No data available. Please sync with internet connection.'
          : 'No failures found.';
    }
  }

  /// Junior Engineer lists (Inbox / Joint Inspection): syncs the changes (also
  /// done at login), then shows the local copy of jeInboxFailureList.
  Future<void> _fetchJeFailures() async {
    final synced = await Get.find<MasterDataSyncService>().syncFailureTransactions();
    if (!synced) {
      debugPrint('_fetchJeFailures: server not reached, using local copy');
      isOfflineMode.value = true;
    }

    final userId = int.tryParse(await AuthManager().getUserId() ?? '') ?? 0;
    final deptId = _sessionController.selectedDepartment.value?.deptId ?? 0;
    final jiTab = selectedJETab.value == JEFailureListTab.jointInspection;

    final items = <FailureItem>[];
    for (final row in await _dbService.getJeFailureCache()) {
      try {
        final record = row['record'] as Map<String, dynamic>;
        final je = Map<String, dynamic>.from(record['jeFailure'] as Map);
        final notificationId = _toInt(je['notificationId']);
        if (notificationId == null) continue;

        final assigned = _toInt(je['assignedUserId']) ?? 0;
        final assignedJi = _toInt(je['assignedUserId_JI']) ?? 0;
        if (jiTab) {
          if (assignedJi != userId) continue;
        } else if (assigned != 0 && assigned != userId) {
          continue;
        }
        final itemDept = _toInt(je['mainDeptId']) ?? 0;
        if (deptId > 0 && itemDept > 0 && itemDept != deptId) continue;

        // Status and dates are not always filled in jeFailure: the history has them.
        final history = record['correctiveNotificationActionUserHistory'];
        final latest = history is List ? FailureService.latestHistory(history) : null;
        String? created;
        if (history is List) {
          for (final h in history) {
            if (h is Map && h['statusId']?.toString() == '1') {
              created = h['actionOn']?.toString();
            }
          }
        }
        String text(dynamic v) => v?.toString().trim() ?? '';
        final status = text(je['statusName']).isNotEmpty
            ? text(je['statusName'])
            : text(latest?['statusName']);
        final occurred = text(je['failureOccuranceDateTime']).isNotEmpty
            ? text(je['failureOccuranceDateTime'])
            : (created ?? '');
        final token = encryptedIdFromSiFailure(je, notificationId);
        final pendingAction = row['pendingAction']?.toString();
        items.add(FailureItem(
          id: notificationId,
          // The encrypted id (jobCardNo) opens the details online; the local
          // copy is found by the numeric id / code.
          failureNo: token ?? notificationId.toString(),
          notificationCode: je['notificationCode']?.toString(),
          jobCardId: token ?? notificationId.toString(),
          failureDescription: je['failureDescription']?.toString(),
          functionLocationId: _toInt(je['functionLocationId']),
          equipmentId: _toInt(je['equipmentId']),
          functionalLocation: je['functionalLocation']?.toString(),
          equipmentDescription: je['equipmentDescription']?.toString(),
          statusName: status,
          statusId: _toInt(latest?['statusId']),
          failureOccuranceDateTime: occurred,
          assignedUserId: assigned > 0 ? assigned : null,
          occRequestStatus: je['occRequestStatus']?.toString(),
          otherRequestFrom: je['otherRequestFrom']?.toString(),
          locationName: je['locationName']?.toString(),
          remarks: je['remarks']?.toString(),
          creationType: je['creationType']?.toString(),
          system: je['systems']?.toString(),
          subSystems: je['subSystems']?.toString(),
          freq: _toInt(je['freq']),
          syncStatus: pendingAction == null ? 'synced' : 'offline',
          pendingAction: pendingAction,
        ));
      } catch (e) {
        debugPrint('_fetchJeFailures: skipped bad row: $e');
      }
    }

    final shown = items.where((item) => _matchesFailureType(item)).toList();
    _sortJeFailures(shown);
    failures.assignAll(shown);
    if (failures.isEmpty) {
      errorMessage.value = isOfflineMode.value
          ? 'No data available. Please sync with internet connection.'
          : 'No failures found.';
    }
  }

  /// FMC inbox: online first, cached copy when offline.
  Future<void> _fetchFmcFailures() async {
    const cacheKey = 'FMC_list';
    try {
      final rows = await _failureService.getOccFailureInbox();
      final items = <FailureItem>[];
      for (final r in rows) {
        try {
          items.add(_fmcItemFromRow(r));
        } catch (e) {
          debugPrint('_fetchFmcFailures: skipped bad row: $e');
        }
      }
      items.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      failures.assignAll(items);
      await _dbService.clearFailureList(cacheKey);
      if (items.isNotEmpty) {
        await _dbService.insertFailureList(
            items.map((e) => e.toJson()).toList(), cacheKey);
      } else {
        errorMessage.value = 'No failures found.';
      }
    } catch (e) {
      debugPrint('_fetchFmcFailures: API failed, using local copy: $e');
      isOfflineMode.value = true;
      final local = await _dbService.getFailureList(cacheKey);
      if (local.isNotEmpty) {
        failures.assignAll(local.map((e) => FailureItem.fromJson(e)).toList());
      } else {
        errorMessage.value =
        'No data available. Please check your internet connection.';
      }
    }
  }

  /// GetAllFailuresTransactionData station row -> the shape FailureItem reads
  /// for station list items. That API sends no encrypted failure id, so the
  /// numeric id stands in for it (the details screen then uses the row).
  Map<String, dynamic> _stationRowFromTransaction(Map<String, dynamic> record,
      {Map<String, String> categoryNames = const {},
      Map<String, dynamic>? overlay}) {
    final f = Map<String, dynamic>.from(record['failure'] as Map);
    String? date(dynamic v) {
      final d = DateTime.tryParse(v?.toString() ?? '');
      return d == null ? v?.toString() : DateFormat('dd-MM-yyyy HH:mm').format(d);
    }

    int? asInt(dynamic v) =>
        v is bool ? (v ? 1 : 0) : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));

    // The server sends yes/no flags as true/false or as "Yes"/"No" text, and
    // some counts only as true/false: a flag is never a count.
    bool? flag(dynamic v, dynamic text) =>
        v is bool ? v : (text == 'Yes' ? true : (text == 'No' ? false : null));
    int? count(dynamic v) => v is bool ? null : asInt(v);

    final row = {
      'id': asInt(f['id']),
      'syncStatus': 'synced',
      'failureId': f['notificationCode']?.toString(),
      'failureCreationId': f['failureCreationId']?.toString() ?? f['id']?.toString(),
      'failureDescription': f['failureDescription'],
      'funcationLocation': f['functionalLocation'],
      'location': f['location'],
      'subLocation': f['subLocation'],
      'departmentName': f['departmentName'],
      'priority': f['priority'],
      'lineName': f['lineName'],
      'statusName': f['statusName'],
      'statusId': asInt(f['statusId']),
      'occRequestStatusId': asInt(f['occRequestStatusId']),
      'occRequestStatusName': f['occRequestStatusName'],
      'actualFailureOccuranceDate': date(f['actualFailureOccuranceDate']),
      'actualFailureCompletedDateTime': date(f['actualFailureCompletedDateTime']),
      'createdDate': date(f['createdDate']),
      'failureReportedby': f['failureReportedBy'],
      'failureCategoryTypeText': f['failureCategoryTypeText'],
      'failureRectificationDetails': f['failureRectificationDetails'],
      'carriedOutRemarks': f['carriedOutRemarks'],
      'trainId': f['trainId']?.toString(),
      'system': f['system'],
      'isTripAffected': flag(f['isTripAffected'], f['tripAffected']),
      'tripDelayUpline': asInt(f['tripDelayUpline']),
      'tripDelayDownline': asInt(f['tripDelayDownline']),
      'tripCancel': count(f['tripCancel']),
      'isTrainReplace': f['isTrainReplace'] is bool ? f['isTrainReplace'] : null,
      'trainReplace': asInt(f['trainReplace']),
      'isTrainDeboarded': f['isTrainDeboarded'] is bool ? f['isTrainDeboarded'] : null,
      'trainDeboarded': count(f['trainDeboarded']),
      'isPassengerAffected': flag(f['isPassengerAffected'], f['passengerAffected']),
      'numberOfPassengerAffected': asInt(f['numberOfPassengerAffected']),
      'trappedDuration': asInt(f['trappedDuration']),
      'rescusedDuration': asInt(f['rescusedDuration']),
      'trainDelayInMin': asInt(f['trainDelayInMin']),
      'noOfTranWithdrawal': asInt(f['noOfTranWithdrawal']),
      'departmentId_1': asInt(f['departmentId']),
      'locationId': asInt(f['locationId']),
      'funcationLocationId': asInt(f['functionalLocationId']),
    };

    // Category: the server sends the id; the name is in the local master data.
    if ('${row['failureCategoryTypeText'] ?? ''}'.trim().isEmpty) {
      final name = categoryNames['${f['failureCategoryTypeId'] ?? ''}'];
      if (name != null) row['failureCategoryTypeText'] = name;
    }
    // What the user typed when creating it fills what the server did not send.
    overlay?.forEach((k, v) {
      final cur = row[k];
      if (v != null && (cur == null || (cur is String && cur.trim().isEmpty))) {
        row[k] = v;
      }
    });
    return row;
  }

  /// Station Controller list (mobileAppAPI/GetAllFailuresTransactionData).
  /// The first sync (or a forced refresh) downloads everything; later syncs
  /// send the last sync date and merge only the changes. The list always shows
  /// the local copy, so it also works offline. Failures saved offline and not
  /// sent yet are listed too (orange dot); synced ones show a green dot.
  Future<void> _fetchStationControllerFailures({bool forceAll = false}) async {
    // Download / merge the station failures into the local copy (also done at
    // login); the list below always shows the local copy.
    final synced = await Get.find<MasterDataSyncService>()
        .syncFailureTransactions(forceAll: forceAll);
    if (!synced) {
      debugPrint('_fetchStationControllerFailures: server not reached, using local copy');
      isOfflineMode.value = true;
    }

    final overlays = await StationOverlay.loadAll();
    final categoryNames = <String, String>{};
    try {
      for (final c in await _dbService.getFailureCategoryTypeOptions()) {
        categoryNames['${c['ID']}'] = '${c['FailureCategoryType']}'.trim();
      }
    } catch (_) {}

    final items = <FailureItem>[];
    for (final r in await _dbService.getStationFailureCache()) {
      try {
        final code = (r['failure'] as Map)['notificationCode']?.toString() ?? '';
        items.add(FailureItem.fromJson(_stationRowFromTransaction(r,
            categoryNames: categoryNames, overlay: overlays[code])));
      } catch (e) {
        debugPrint('_fetchStationControllerFailures: skipped bad row: $e');
      }
    }
    items.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    // Created offline and not sent yet: kept in FailureList until synced.
    final pending = <FailureItem>[];
    for (final r in await _dbService.getFailureList(failureType)) {
      // 'failed' = the server refused it: stays visible with Retry / Discard.
      if (r['syncStatus'] == 'offline' || r['syncStatus'] == 'failed') {
        try {
          pending.add(FailureItem.fromJson(r));
        } catch (_) {}
      }
    }
    // Newest submission first; its departments in the order they were picked.
    // Offline ids are -(submissionId * 10 + index) (older ones: the plain id).
    ({int sid, int idx}) offlineKey(FailureItem f) {
      final id = f.id ?? 0;
      return id < 0 ? (sid: (-id) ~/ 10, idx: (-id) % 10) : (sid: id, idx: 0);
    }

    pending.sort((a, b) {
      final ka = offlineKey(a), kb = offlineKey(b);
      return ka.sid != kb.sid ? kb.sid.compareTo(ka.sid) : ka.idx.compareTo(kb.idx);
    });
    failures.assignAll([...pending, ...items]);
    if (failures.isEmpty) {
      errorMessage.value = isOfflineMode.value
          ? 'No data available. Please sync with internet connection.'
          : 'No failures found.';
    }
  }

  // Queue id of an offline Station entry: -(submissionId * 10 + index), older
  // entries use the plain submission id.
  int _submissionIdOf(FailureItem f) {
    final id = f.id ?? 0;
    return id < 0 ? (-id) ~/ 10 : id;
  }

  /// Retry of a Station failure the server refused.
  Future<void> retryOfflineFailure(FailureItem f) async {
    final sid = _submissionIdOf(f);
    if (sid <= 0) return;
    await _dbService.resetSubmissionAttempts(sid);
    await _dbService.markStationOfflineEntries(sid, failed: false);
    await fetchFailures();
    await Get.find<MasterDataSyncService>().syncPendingSubmissions(force: true);
  }

  /// Removes an offline Station failure (and what is waiting to be sent).
  Future<void> discardOfflineFailure(FailureItem f) async {
    final sid = _submissionIdOf(f);
    if (sid <= 0) return;
    await _dbService.deletePendingSubmission(sid);
    await _dbService.deleteStationOfflineEntries(sid);
    await fetchFailures();
  }

  /// Retry of a Section Incharge failure or action the server refused: an
  /// offline-created failure has a negative id (-queue id); an action waits
  /// for the failure with that notification id.
  Future<void> retrySiFailure(FailureItem f) async {
    final id = f.id ?? 0;
    final ids = id < 0 ? [-id] : await _dbService.getSiSubmissionIds(id);
    for (final sid in ids) {
      await _dbService.resetSubmissionAttempts(sid);
    }
    if (id < 0) {
      await _dbService.markSiCreateEntry(-id, failed: false);
    } else if (id > 0) {
      await _dbService.setSiPendingError(id, null);
    }
    await fetchFailures();
    await Get.find<MasterDataSyncService>().syncPendingSubmissions(force: true);
  }

  /// Drops a failure (or the waiting action) the server refused. For an action
  /// the failure is reloaded from the server, so its local change goes away.
  Future<void> discardSiFailure(FailureItem f) async {
    final id = f.id ?? 0;
    if (id < 0) {
      await _dbService.deletePendingSubmission(-id);
      await _dbService.deleteSiCreateEntry(-id);
    } else if (id > 0) {
      for (final sid in await _dbService.getSiSubmissionIds(id)) {
        await _dbService.deletePendingSubmission(sid);
      }
      await _dbService.clearSiFailurePending(id);
      await Get.find<MasterDataSyncService>().syncFailureTransactions(forceAll: true);
    }
    await fetchFailures();
  }

  /// OCC role list (OCCMaintainance/getFailureList, action FailureList):
  /// online first, cached copy when offline.
  Future<void> _fetchOccRoleFailures() async {
    const cacheKey = 'OCC_role_list';
    try {
      final rows = await _failureService.getOccFailureInbox(action: 'FailureList');
      final items = <FailureItem>[];
      for (final r in rows) {
        try {
          items.add(_fmcItemFromRow(r));
        } catch (e) {
          debugPrint('_fetchOccRoleFailures: skipped bad row: $e');
        }
      }
      items.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      failures.assignAll(items);
      await _dbService.clearFailureList(cacheKey);
      if (items.isNotEmpty) {
        await _dbService.insertFailureList(
            items.map((e) => e.toJson()).toList(), cacheKey);
      } else {
        errorMessage.value = 'No failures found.';
      }
    } catch (e) {
      debugPrint('_fetchOccRoleFailures: API failed, using local copy: $e');
      isOfflineMode.value = true;
      final local = await _dbService.getFailureList(cacheKey);
      if (local.isNotEmpty) {
        failures.assignAll(local.map((e) => FailureItem.fromJson(e)).toList());
      } else {
        errorMessage.value =
        'No data available. Please check your internet connection.';
      }
    }
  }

  /// DCC depot failures for the selected depot: online first, cached copy
  /// (per depot) when offline.
  Future<void> _fetchDepotFailures() async {
    final depotId = int.tryParse(_sessionController.selectedDepotId.value ?? '') ?? 0;
    if (depotId == 0) {
      failures.clear();
      errorMessage.value = 'Please select a depot first';
      return;
    }
    final cacheKey = 'Depot_list_$depotId';
    try {
      final rows = await _failureService.getDepotFailureList(depotId);
      final items = <FailureItem>[];
      for (final r in rows) {
        try {
          items.add(_fmcItemFromRow(r, creationType: 'Depot'));
        } catch (e) {
          debugPrint('_fetchDepotFailures: skipped bad row: $e');
        }
      }
      items.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      failures.assignAll(items);
      await _dbService.clearFailureList(cacheKey);
      if (items.isNotEmpty) {
        await _dbService.insertFailureList(
            items.map((e) => e.toJson()).toList(), cacheKey);
      } else {
        errorMessage.value = 'No failures found.';
      }
    } catch (e) {
      debugPrint('_fetchDepotFailures: API failed, using local copy: $e');
      isOfflineMode.value = true;
      final local = await _dbService.getFailureList(cacheKey);
      if (local.isNotEmpty) {
        failures.assignAll(local.map((e) => FailureItem.fromJson(e)).toList());
      } else {
        errorMessage.value =
        'No data available. Please check your internet connection.';
      }
    }
  }

  /// Maps one inbox row without strict casts (the row shape is not fixed).
  FailureItem _fmcItemFromRow(Map<String, dynamic> m, {String creationType = 'OCC'}) {
    String? s(String k) {
      final v = m[k]?.toString().trim();
      return (v == null || v.isEmpty || v == 'null') ? null : v;
    }

    int? i(String k) => int.tryParse(m[k]?.toString() ?? '');

    String? first(List<String> keys) {
      for (final k in keys) {
        final v = s(k);
        if (v != null) return v;
      }
      return null;
    }

    return FailureItem(
      id: i('id'),
      // failureCreationId is the encrypted id getFailureCreationById expects.
      failureNo: first(['failureCreationId', 'id']),
      notificationCode: first(['failureId', 'notificationCode', 'failureNo']),
      failureDescription: first(['failureDescription', 'description']),
      functionalLocation: first(['funcationLocation', 'functionalLocation']),
      statusName: first(['statusName', 'mainStatusName', 'status']),
      statusDescription: first(['statusDescription', 'statusName']),
      failureOccuranceDateTime: first([
        'actualFailureOccuranceDate',
        'actualFailureOccuranceDatetime',
        'failureOccuranceDateTime'
      ]),
      locationName: first(['locationName', 'location']),
      creationType: creationType,
      priority: s('priority'),
      departmentName: first(['departmentName', 'failureDeptName']),
      subLocation: s('subLocation'),
      trainId: s('trainId'),
      system: first(['system', 'systems']),
      createdDate: first(['createdDate', 'createdSystemDate']),
      lineName: s('lineName'),
      statusId: i('statusId'),
      occRequestStatusName:
      creationType == 'Depot' ? first(['occRequestStatusName']) : null,
      createdByName: s('createdByName'),
      currentlyWith: s('currentlyWith'),
      syncStatus: 'online',
      lastSyncedAt: DateTime.now().toIso8601String(),
    );
  }

  /// Creation order of a failure. The failure number is department / MM-YYYY /
  /// sequence (e.g. SIG/10-2026/0015), so month-year then sequence tells which
  /// is newer; JE inbox rows often have no usable `id`, so the id is only the
  /// fallback.
  int _recencyKey(FailureItem item) {
    final no = item.notificationCode ?? item.failureNo ?? '';
    final m = RegExp(r'(\d{1,2})-(\d{4})/(\d+)').firstMatch(no);
    if (m != null) {
      final month = int.parse(m.group(1)!);
      final year = int.parse(m.group(2)!);
      final seq = int.parse(m.group(3)!);
      return (year * 100 + month) * 1000000 + seq;
    }
    return item.id ?? 0;
  }

  /// JE lists are ordered purely by recency (not grouped by creation type, or
  /// a new OCC failure would always sit below older Manual / Station / Depot
  /// ones): JE Inbox newest first, Joint Inspection Inbox oldest first.
  void _sortJeFailures(List<FailureItem> items) {
    final oldestFirst =
        selectedJETab.value == JEFailureListTab.jointInspection;
    items.sort((a, b) {
      final byRecency = _recencyKey(a).compareTo(_recencyKey(b));
      return oldestFirst ? byRecency : -byRecency;
    });
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
      
      // JE users use their respective endpoints. (The Section Incharge list no
      // longer uses NotificationListSI: it comes from the local copy synced from
      // GetAllFailuresTransactionData, see _fetchSectionInchargeFailures.)
      final String apiUrl = selectedJETab.value == JEFailureListTab.jointInspection
          ? AppUrls.jeJointInboxList
          : AppUrls.jeInboxList;
      final Map<String, dynamic> body = {
        "assignedUserId": userId,
        "deptId": deptId,
      };
      debugPrint("_fetchFromApi: Calling JE API: $apiUrl for tab: ${selectedJETab.value}");

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
            
            _sortJeFailures(filteredItems);

            failures.assignAll(filteredItems);
            debugPrint("_fetchFromApi: Loaded ${filteredItems.length} failures from API (sorted by creationType)");

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

  /// DCC depot list: Re-open / Close (web: updateDepotAcknowledgeStatus).
  Future<void> reOpenDepotFailure(int id, String remark, {String? failureNo}) =>
      _updateDepotStatus(id, 'UPDATE_REOPEN_OCC_DEPOT', remark,
          successMessage: 'Failure No.${failureNo ?? id} re-open successfully.');

  Future<void> closeDepotFailure(int id, {String? failureNo}) =>
      _updateDepotStatus(id, 'UPDATE_CLOSED_OCC_DEPOT', 'Closed Request',
          successMessage: 'Failure No.${failureNo ?? id} closed successfully.');

  Future<void> _updateDepotStatus(int id, String action, String description,
      {required String successMessage, int statusId = 202}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final response = await _failureService.updateDepotStatus(
        id: id,
        action: action,
        description: description,
        statusId: statusId,
      );
      final ok = response['responseCode'] == 200 ||
          response['responseMessage']?.toString().toLowerCase() == 'success';
      if (ok) {
        Get.snackbar('Success', successMessage,
            backgroundColor: AppColors.green, colorText: AppColors.white1);
        await fetchFailures();
      } else {
        Get.snackbar('Error',
            response['responseMessage']?.toString() ?? 'Failed to perform action',
            backgroundColor: AppColors.red, colorText: AppColors.white1);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          backgroundColor: AppColors.red, colorText: AppColors.white1);
    } finally {
      isLoading.value = false;
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


  Future<void> acknowledgeFailure(int id, String remark, String submitStatus, {String? failureNo}) async {
    await _updateStationAcknowledgeStatus(id, "UPDATE_Acknowledge_OCC_Station", remark, submitStatus: submitStatus, failureNo: failureNo);
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
      isOfflineMode.value = false;
      await _fetchStationControllerFailures(forceAll: true);
      Get.snackbar(
        isOfflineMode.value ? 'Offline' : 'Sync Complete',
        isOfflineMode.value
            ? 'No connection - showing the saved station failures'
            : 'Successfully synced ${failures.length} station failures',
        backgroundColor: isOfflineMode.value ? AppColors.orangeColor : AppColors.green,
        colorText: AppColors.white1,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateStationAcknowledgeStatus(
    int id,
    String action,
    String description, {
    String? submitStatus,
    String? failureNo,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;
      final String userName =
          (await AuthManager().getFullName()) ?? _sessionController.userName.value;

      final int statusId = submitStatus == "deny"
          ? 198
          : submitStatus == "accept"
              ? 197
              : 202;

      final response = await _failureService.updateStationAcknowledgeStatus(
        id: id,
        action: action,
        description: description,
        statusId: statusId,
        createdBy: userId,
        createdByName: userName,
      );

      if (response['responseCode'] == 200 ||
          response['responseMessage'] == "Success" ||
          response['responseMessage'] == "success") {
        final String notifCode = failureNo ?? id.toString();
        String successMsg =
            response['responseMessage'] ?? "Action completed successfully.";
        if (submitStatus == "accept") {
          successMsg =
              "Failure No.$notifCode acknowledge accepted successfully.";
        } else if (submitStatus == "deny") {
          successMsg =
              "Failure No.$notifCode acknowledge denied successfully.";
        }
        Get.snackbar(
          "Success",
          successMsg,
          backgroundColor: AppColors.green,
          colorText: AppColors.white1,
        );
        fetchFailures(); // Refresh list
      } else {
        errorMessage.value =
            response['responseMessage'] ?? "Failed to perform action";
        Get.snackbar(
          "Error",
          errorMessage.value,
          backgroundColor: AppColors.red,
          colorText: AppColors.white1,
        );
      }
    } catch (e) {
      errorMessage.value = "Error: $e";
      Get.snackbar(
        "Error",
        errorMessage.value,
        backgroundColor: AppColors.red,
        colorText: AppColors.white1,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
