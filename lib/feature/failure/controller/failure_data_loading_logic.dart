import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/controller/global_master_data_controller.dart';
import '../../../core/models/label_value.dart';
import '../../../service/auth_manager.dart';
import '../../../service/local_database_service.dart';
import 'failure_form_state.dart';

// Function to process users in isolate
List<Map<String, dynamic>> _processUsersInIsolate(List<Map<String, dynamic>> users) {
  final uniqueUsers = <String, Map<String, dynamic>>{};
  for (final user in users) {
    final userId = user['userId']?.toString() ?? '';
    if (userId.isNotEmpty && (user['userName']?.toString() ?? '').isNotEmpty) {
      uniqueUsers.putIfAbsent(userId, () => user);
    }
  }
  return uniqueUsers.values.toList();
}

mixin FailureDataLoadingLogic on GetxController, FailureFormState {
  bool _isMasterDataLoaded = false;
  bool _isLoadingDropdowns = false;

  // Future<void> loadDepartments() async {
  //   debugPrint("_loadDepartments: Starting to load departments");
  //   final depts = (await LocalDatabaseService().getDepartments()).map((e) => e.toJson()).toList();
  //   masterDepartments.assignAll(depts);
  //   debugPrint("_loadDepartments: Loaded ${depts.length} departments from local DB to masterDepartments");
  //   debugPrint("_loadDepartments: departmentList will have ${depts.length + 1} items (including Select)");
  //
  //   // If masterDepartments is empty, try to fetch departments from API
  //   if (masterDepartments.isEmpty) {
  //     debugPrint("_loadDepartments: masterDepartments empty, fetching from API");
  //     try {
  //       final apiClient = ApiClient();
  //       final userId = int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;
  //       final response = await apiClient.post(
  //         AppUrls.getMasterData,
  //         body: {
  //           "userId": userId,
  //           "action": "GetDeptMasterData"
  //         }
  //       );
  //       if (response.statusCode == 200) {
  //         final Map<String, dynamic> jsonBody = jsonDecode(response.body);
  //         if (jsonBody['success'] == true && jsonBody['data'] != null) {
  //           List<dynamic> apiDepts = jsonBody['data']['departments'] ?? [];
  //           if (apiDepts.isNotEmpty) {
  //             final mappedDepts = apiDepts.map((e) => {
  //               'deptId': e['deptId']?.toString(),
  //               'deptName': e['deptName']?.toString(),
  //               'workCenter': e['workCenter']?.toString() ?? '',
  //             }).toList();
  //             masterDepartments.assignAll(mappedDepts);
  //             debugPrint("_loadDepartments: Loaded ${mappedDepts.length} departments from API");
  //             // Update depts to use API data for departmentList
  //             depts.clear();
  //             depts.addAll(mappedDepts);
  //           }
  //         }
  //       }
  //     } catch (e) {
  //       debugPrint("_loadDepartments: Error fetching departments from API: $e");
  //     }
  //   }
  //
  //   departmentList.assignAll([
  //     LabelValue(label: 'Select', value: ''),
  //     ...depts.map((e) => LabelValue(
  //       label: e['deptName']?.toString() ?? '',
  //       value: e['deptId']?.toString() ?? '',
  //     )),
  //   ]);
  //   debugPrint("_loadDepartments: departmentList populated with ${departmentList.length} items");
  // }

  bool _isFunctionalLocationsLoaded = false;

  Future<void> loadMasterDataFromDb() async {
    debugPrint('_loadMasterDataFromDb: Syncing small master data from global cache (large tables loaded on-demand)');
    if (_isMasterDataLoaded) return;

    final g = GlobalMasterDataController.to;

    // Ensure global data is loaded
    if (!g.isLoaded) {
      await g.initOnLogin();
    }

    // Copy only SMALL master data from global cache
    // Large tables (functional locations, equipment, users) loaded on-demand with SQL filtering
    masterLocations.assignAll(g.masterLocations);
    masterDepartments.assignAll(g.masterDepartments);
    masterRcaFailureCategories.assignAll(g.masterRcaFailureCategories);

    // Large tables - DO NOT copy from global, load on-demand
    masterFunctionalLocations.clear();
    masterEquipments.clear();
    
    // Load master users on-demand ONLY when needed (e.g., for joint inspection filtering)
    // Do NOT load on every screen open - it blocks UI with 36,873 users
    // await _loadMasterUsersOnDemand(); 

    // Dropdown lists - copy small ones, clear large ones
    functionalLocationList.clear(); // Will load on-demand
    equipmentList.clear(); // Will load on-demand
    priorityTypeList.assignAll(g.priorityTypeList);
    locationTypeList.assignAll(g.locationTypeList);
    departmentList.assignAll(g.departmentList);
    rcaFailureCategoryList.assignAll(g.rcaFailureCategoryList);

    storageLocationList.assignAll(g.storageLocationList);
    reasonForDelayList.assignAll(g.reasonForDelayList);
    faultTypeList.assignAll(g.faultTypeList);
    objectDataList.assignAll(g.objectDataList);
    rootCauseList.assignAll(g.rootCauseList);
    actionTakenList.assignAll(g.actionTakenList);
    causeList.assignAll(g.causeList);

    actionList.assignAll(g.actionTakenList);
    // Use corrNotificationTypeList from local DB instead of API-based notificationTypeList
    notificationTypeList.assignAll(g.corrNotificationTypeList);
    natureOfWorkList.assignAll(g.natureOfWorkList);
    userStatusList.assignAll(g.userStatusList);
    corrNotificationTypeList.assignAll(g.corrNotificationTypeList);
    materialDataList.assignAll(g.materialMasterList);

    // Load functional locations on-demand for form initialization (only if not already loaded)
    if (!_isFunctionalLocationsLoaded) {
      await _loadFunctionalLocationsOnDemand();
    }

    await filterRcaFailureCategoriesBySystem();

    _isMasterDataLoaded = true;
    debugPrint('_loadMasterDataFromDb: Small master data synced. Large tables will load on-demand.');
  }

  Future<void> _loadFunctionalLocationsOnDemand({bool forceReload = false}) async {
    if (!forceReload && _isFunctionalLocationsLoaded && masterFunctionalLocations.isNotEmpty) {
      debugPrint('_loadFunctionalLocationsOnDemand: Already loaded, skipping');
      return;
    }

    debugPrint('_loadFunctionalLocationsOnDemand: Loading functional locations from SQLite');
    final dbService = LocalDatabaseService();
    final businessArea = await AuthManager().getBusinessArea();
    final funcLocs = await dbService.getFunctionalLocationsFiltered(
      businessArea: businessArea,
      // No limit - load all filtered results
    );

    masterFunctionalLocations.assignAll(funcLocs.map((e) => e.toJson()).toList());
    functionalLocationList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...funcLocs.map((e) => LabelValue(
        label: e.funcLocationName.isNotEmpty ? e.funcLocationName : e.funcLocation,
        value: e.funcLocId?.toString() ?? '',
      )),
    ]);
    _isFunctionalLocationsLoaded = true;
    debugPrint('_loadFunctionalLocationsOnDemand: Loaded ${funcLocs.length} functional locations');
    debugPrint('_loadFunctionalLocationsOnDemand: functionalLocationList count = ${functionalLocationList.length}');
    
    // Force UI update
    functionalLocationList.refresh();
  }

  Future<void> filterRcaFailureCategoriesBySystem() async {
    final currentSystem = systemController.text.trim();
    debugPrint('_filterRcaFailureCategoriesBySystem: Current system = "$currentSystem"');
    
    // Get work center from selected department
    final currentWorkCenter = getCurrentWorkCenterFromDept();
    debugPrint('_filterRcaFailureCategoriesBySystem: Current workCenter = "$currentWorkCenter"');
    
    // Get business area from user session (not from department)
    final currentBusinessArea = await getCurrentBusinessArea();
    debugPrint('_filterRcaFailureCategoriesBySystem: User business area from session = "$currentBusinessArea"');
    debugPrint('_filterRcaFailureCategoriesBySystem: Current businessArea = "$currentBusinessArea"');
    
    // Log sample data from masterRcaFailureCategories
    if (masterRcaFailureCategories.isNotEmpty) {
      debugPrint('_filterRcaFailureCategoriesBySystem: Sample RCA category data:');
      for (int i = 0; i < masterRcaFailureCategories.length && i < 3; i++) {
        final cat = masterRcaFailureCategories[i];
        debugPrint('  [$i] failureCategory: ${cat['failureCategory']}, system: ${cat['system']}, workCenter: ${cat['workCenter']}, businessArea: ${cat['businessArea']}');
      }
    } else {
      debugPrint('_filterRcaFailureCategoriesBySystem: masterRcaFailureCategories is EMPTY!');
    }
    
    if (currentSystem.isEmpty && currentWorkCenter == null && currentBusinessArea == null) {
      // If no filters selected, show all categories
      debugPrint('_filterRcaFailureCategoriesBySystem: No filters set, showing all categories');
      rcaFailureCategoryList.assignAll([
        LabelValue(label: 'Select', value: ''),
        ...masterRcaFailureCategories
            .where((e) => (e['failureCategory']?.toString() ?? '').isNotEmpty && (e['failureCategory']?.toString().toLowerCase() != 'select'))
            .map((e) => LabelValue(
          label: e['failureCategory']?.toString() ?? '',
          value: (e['failureCategoryId'] ?? e['FailureCategoryId'] ?? e['id'])?.toString() ?? '',
        )),
      ]);
    } else {
      // Filter by system, work center, and business area
      debugPrint('_filterRcaFailureCategoriesBySystem: Applying filters');
      rcaFailureCategoryList.assignAll([
        LabelValue(label: 'Select', value: ''),
        ...masterRcaFailureCategories
            .where((e) {
              final categorySystem = e['system']?.toString() ?? '';
              final categoryWorkCenter = e['workCenter']?.toString() ?? '';
              final categoryBusinessArea = e['businessArea']?.toString() ?? '';
              final failureCategory = e['failureCategory']?.toString() ?? '';
              
              bool matchesSystem = currentSystem.isEmpty;
              if (currentSystem.isNotEmpty) {
                matchesSystem = categorySystem.toLowerCase() == currentSystem.toLowerCase() || 
                               categorySystem.toLowerCase().contains(currentSystem.toLowerCase()) ||
                               currentSystem.toLowerCase().contains(categorySystem.toLowerCase());
              }
              
              bool matchesWorkCenter = currentWorkCenter == null || currentWorkCenter.isEmpty;
              if (currentWorkCenter != null && currentWorkCenter.isNotEmpty) {
                matchesWorkCenter = categoryWorkCenter.toLowerCase() == currentWorkCenter.toLowerCase() || 
                                   categoryWorkCenter.toLowerCase().contains(currentWorkCenter.toLowerCase()) ||
                                   currentWorkCenter.toLowerCase().contains(categoryWorkCenter.toLowerCase());
              }
              
              bool matchesBusinessArea = currentBusinessArea == null || currentBusinessArea.isEmpty;
              if (currentBusinessArea != null && currentBusinessArea.isNotEmpty) {
                matchesBusinessArea = categoryBusinessArea.toLowerCase() == currentBusinessArea.toLowerCase() || 
                                     categoryBusinessArea.toLowerCase().contains(currentBusinessArea.toLowerCase()) ||
                                     currentBusinessArea.toLowerCase().contains(categoryBusinessArea.toLowerCase());
              }
              
              final isValidCategory = failureCategory.isNotEmpty && failureCategory.toLowerCase() != 'select';
              debugPrint('_filterRcaFailureCategoriesBySystem: Category: "$failureCategory", System: "$categorySystem", WorkCenter: "$categoryWorkCenter", BusinessArea: "$categoryBusinessArea", Matches: $matchesSystem && $matchesWorkCenter && $matchesBusinessArea');
              return matchesSystem && matchesWorkCenter && matchesBusinessArea && isValidCategory;
            })
            .map((e) => LabelValue(
          label: e['failureCategory']?.toString() ?? '',
          value: (e['failureCategoryId'] ?? e['FailureCategoryId'] ?? e['id'])?.toString() ?? '',
        )),
      ]);
    }
    debugPrint('_filterRcaFailureCategoriesBySystem: Filtered to ${rcaFailureCategoryList.length} categories');
  }

  Future<void> forceReloadMasterData() async {
    _isMasterDataLoaded = false;
    await loadMasterDataFromDb();
  }

  Future<void> loadMasterDropdownsFromDb({bool refreshIfEmpty = false}) async {
    // Skip loading if dropdowns are already populated (check for more than just "Select")
    if (!refreshIfEmpty && priorityTypeList.length > 1 && corrNotificationTypeList.length > 1 && userList.length > 1) {
      debugPrint('_loadMasterDropdownsFromDb: Dropdowns already populated, skipping');
      return;
    }
    
    // Prevent concurrent calls
    if (_isLoadingDropdowns) {
      debugPrint('_loadMasterDropdownsFromDb: Already loading dropdowns, skipping');
      return;
    }
    
    _isLoadingDropdowns = true;
    final dbService = LocalDatabaseService();

    if (refreshIfEmpty) {
      try {
        final priorities = (await dbService.getPriorities()).map((e) => e.toJson()).toList();
        final categories = (await dbService.getFailureCategories()).map((e) => e.toJson()).toList();
        final users = (await dbService.getMasterUsers()).map((e) => e.toJson()).toList();
        if (priorities.isEmpty || categories.isEmpty || users.isEmpty) {
          await forceReloadMasterData();
        }
      } catch (e) {
        debugPrint('_loadMasterDropdownsFromDb sync error: $e');
        await forceReloadMasterData();
      }
    }

    final priorities = (await dbService.getPriorities()).map((e) => e.toJson()).toList();
    priorityTypeList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...priorities
          .where((e) => (e['priorityDesc']?.toString() ?? '').isNotEmpty && (e['priorityDesc']?.toString().toLowerCase() != 'select'))
          .map((e) => LabelValue(
        label: e['priorityDesc']?.toString() ?? '',
        value: e['priorityId']?.toString() ?? '',
      )),
    ]);

    final categories = (await dbService.getFailureCategories()).map((e) => e.toJson()).toList();
    debugPrint('loadMasterDropdownsFromDb: Raw categories count = ${categories.length}');
    debugPrint('loadMasterDropdownsFromDb: Raw categories sample: ${categories.take(3).toList()}');

    final filteredCategories = categories
        .where((e) {
          final categoryType = e['failureCategoryType']?.toString() ?? '';
          final isNotEmpty = categoryType.isNotEmpty;
          final isNotSelect = categoryType.toLowerCase() != 'select';
          debugPrint('loadMasterDropdownsFromDb: Filtering category - type="$categoryType", isNotEmpty=$isNotEmpty, isNotSelect=$isNotSelect');
          return isNotEmpty && isNotSelect;
        })
        .map((e) => LabelValue(
          label: e['failureCategoryType']?.toString() ?? '',
          value: e['id']?.toString() ?? '',
        ))
        .toList();

    debugPrint('loadMasterDropdownsFromDb: Filtered categories count = ${filteredCategories.length}');

    corrNotificationTypeList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...filteredCategories,
    ]);
    debugPrint('loadMasterDropdownsFromDb: corrNotificationTypeList populated with ${corrNotificationTypeList.length} items');
    debugPrint('loadMasterDropdownsFromDb: corrNotificationTypeList items: ${corrNotificationTypeList.map((e) => e.label).toList()}');

    // Load RCA failure categories from local database
    debugPrint('loadMasterDataFromDb: Loading RCA failure categories');
    final rcaCategories = (await dbService.getRcaFailureCategoriesFromLocal()).map((e) => e.toJson()).toList();
    debugPrint('loadMasterDataFromDb: Retrieved ${rcaCategories.length} RCA failure categories from local DB');
    rcaFailureCategoryList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...rcaCategories
          .where((e) => (e['FailureCategory']?.toString() ?? '').isNotEmpty && (e['FailureCategory']?.toString().toLowerCase() != 'select'))
          .map((e) => LabelValue(
        label: e['FailureCategory']?.toString() ?? '',
        value: e['FailureCategoryId']?.toString() ?? '',
      )),
    ]);
    debugPrint('loadMasterDataFromDb: rcaFailureCategoryList populated with ${rcaFailureCategoryList.length} items');

    final users = (await dbService.getMasterUsers()).map((e) => e.toJson()).toList();
    debugPrint('loadMasterDataFromDb: Total users from DB = ${users.length}');
    
    // Process users in background isolate to prevent UI blocking
    final uniqueUsersList = await compute(_processUsersInIsolate, users);
    debugPrint('loadMasterDataFromDb: userList count after deduplication = ${uniqueUsersList.length}');
    
    // Clear and add "Select" first
    userList.clear();
    userList.add(LabelValue(label: 'Select', value: ''));
    
    // Convert to LabelValue and add in batches
    final userEntries = uniqueUsersList
        .where((e) => (e['userName']?.toString() ?? '').isNotEmpty && (e['userName']?.toString().toLowerCase() != 'select'))
        .map((e) => LabelValue(
          label: e['userName']?.toString() ?? '',
          value: e['userId']?.toString() ?? '',
        ))
        .toList();
    
    // Add in batches of 50 with await to allow UI updates
    const batchSize = 50;
    for (int i = 0; i < userEntries.length; i += batchSize) {
      final end = (i + batchSize < userEntries.length) ? i + batchSize : userEntries.length;
      userList.addAll(userEntries.sublist(i, end));
      userList.refresh();
      await Future.delayed(const Duration(milliseconds: 10));
    }
    
    debugPrint('loadMasterDataFromDb: Final userList count = ${userList.length}');

    priorityTypeList.refresh();
    corrNotificationTypeList.refresh();
    userList.refresh();
    
    _isLoadingDropdowns = false;
    debugPrint('loadMasterDropdownsFromDb: Completed loading dropdowns');
    debugPrint('loadMasterDropdownsFromDb: corrNotificationTypeList final count = ${corrNotificationTypeList.length}');
  }

  String? getWorkCenterForDept(String? deptId, {String? deptLabel}) {
    debugPrint("_getWorkCenterForDept: deptId=$deptId, deptLabel=$deptLabel");
    debugPrint("_getWorkCenterForDept: masterDepartments count=${masterDepartments.length}");
    
    Map<String, dynamic> dept = <String, dynamic>{};

    // 1) Try matching by ID
    if (deptId != null && deptId.isNotEmpty) {
      dept = masterDepartments.firstWhere(
            (e) => e['deptId']?.toString() == deptId,
        orElse: () => <String, dynamic>{},
      );
    }

    // 2) Fall back to matching by name (handles ID-scheme mismatch between
    // the failure-details API's departmentList and the locally-synced masterDepartments)
    if (dept.isEmpty && deptLabel != null && deptLabel.trim().isNotEmpty) {
      dept = masterDepartments.firstWhere(
            (e) => (e['deptName']?.toString().trim().toLowerCase() ?? '') ==
            deptLabel.trim().toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      if (dept.isNotEmpty) {
        debugPrint("_getWorkCenterForDept: matched by NAME fallback -> $dept");
      }
    }

    debugPrint("_getWorkCenterForDept: Matched Department = $dept");
    debugPrint("_getWorkCenterForDept: WorkCenter = ${dept['workCenter']}");

    return dept['workCenter']?.toString();
  }

  String? getCurrentWorkCenterFromDept() {
    if (selectedDepartment.value == null || selectedDepartment.value!.isEmpty) {
      return null;
    }

    final dept = departmentList.firstWhere(
      (e) => e.label == selectedDepartment.value,
      orElse: () => LabelValue(),
    );

    // Use workCenter from departmentList uniqueId if available (from API)
    // Otherwise fall back to looking up in masterDepartments
    if (dept.uniqueId != null && dept.uniqueId.toString().trim().isNotEmpty) {
      return dept.uniqueId.toString();
    }

    return getWorkCenterForDept(dept.value, deptLabel: selectedDepartment.value);
  }

  Future<String?> getCurrentBusinessArea() async {
    try {
      final businessAreaInt = await AuthManager().getBusinessArea();
      return businessAreaInt?.toString();
    } catch (e) {
      debugPrint("getCurrentBusinessArea: Error getting business area: $e");
      return null;
    }
  }
}
