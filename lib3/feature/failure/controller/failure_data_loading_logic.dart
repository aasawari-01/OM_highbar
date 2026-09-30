import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/controller/global_master_data_controller.dart';
import '../../../core/controller/session_controller.dart';
import '../../../core/models/label_value.dart';
import '../../../service/auth_manager.dart';
import '../../../service/local_database_service.dart';
import 'failure_form_state.dart';
import '../service/failure_service.dart';

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
    
    // Load departments and locations directly instead of copying from global to avoid null values
    final dbService = LocalDatabaseService();
    final departments = await dbService.getDepartments();
    masterDepartments.assignAll(departments.map((e) => e.toJson()).toList());
    departmentList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...departments.map((e) => LabelValue(
        label: e.deptName,
        value: e.deptId?.toString() ?? '',
        uniqueId: e.workCenter,
      )),
    ]);
    
    // Load locations directly
    final locations = await dbService.getLocations();
    masterLocations.assignAll(locations.map((e) => e.toJson()).toList());
    locationTypeList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...locations.map((e) => LabelValue(
        label: e.locationName,
        value: e.locationTypeId?.toString() ?? '',
      )),
    ]);
    
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
    // locationTypeList and departmentList already loaded above
    rcaFailureCategoryList.assignAll(g.rcaFailureCategoryList);
    
    // Initialize locationList from locationTypeList
    locationList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...locationTypeList.where((loc) => loc.label != 'Select'),
    ]);

    storageLocationList.assignAll(g.storageLocationList);
    reasonForDelayList.assignAll(g.reasonForDelayList);
    faultTypeList.assignAll(g.faultTypeList);
    objectDataList.assignAll(g.objectDataList);
    rootCauseList.assignAll(g.rootCauseList);
    actionTakenList.assignAll(g.actionTakenList);
    causeList.assignAll(g.causeList);

    actionList.assignAll(g.actionTakenList);
    // Load notificationTypeList from notificationType.db data
    if (g.notificationTypeList.isNotEmpty) {
      notificationTypeList.assignAll(g.notificationTypeList);
    } else {
      final notifTypes = await LocalDatabaseService().getNotificationTypes();
      notificationTypeList.assignAll([
        LabelValue(label: 'Select', value: ''),
        ...notifTypes.map((e) => LabelValue(
              label: e.notificationType ?? '',
              value: e.id?.toString() ?? '',
            )),
      ]);
    }
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

  // Maintenance form specific methods for Section Incharge
  Future<void> onMaintenanceDepartmentChanged(String? value) async {
    if (value == null || value.isEmpty) return;

    try {
      final session = Get.find<SessionController>();
      final selectedDept = session.departments.firstWhere(
        (dept) => dept.deptName == value,
        orElse: () => session.departments.first,
      );

      departmentId.value = selectedDept.deptId ?? 0;

      // Reset dependent fields
      selectedLocation.value = '';
      selectedFunctionalLocation.value = '';
      selectedFmecaSystem.value = '';
      selectedFmecaSubsystem.value = '';
      selectedEquipmentNumber.value = '';
      selectedPersonResponsible.value = '';

      fmecaSystemController.clear();
      fmecaSubsystemController.clear();

      functionalLocationList.clear();
      fmecaSystemList.clear();
      fmecaSubsystemList.clear();
      equipmentList.clear();
      locationList.clear();
      userList.clear();

      // Reset conditional fields
      selectedNatureOfWork.value = '';
      trainRunningKmController.clear();
      isServiceAffected.value = false;
      _resetServiceAffectedFields();
      isPassengerAffected.value = false;
      _resetPassengerAffectedFields();
      isOheRequired.value = false;
      isSicRequired.value = false;

      // Load location if departmentId > 0
      if ((departmentId.value ?? 0) > 0) {
        _filterLocationsByDepartment();
      }

      // Filter functional locations by work center when department changes
      // This should show all functional locations for the department's work center
      _filterFunctionalLocationsByWorkCenter();

      // Load person responsible for department
      await _loadPersonResponsible();

      // Load nature of work data for department ID 3
      if (departmentId.value == 3) {
        await _loadNatureOfWorkData();
      }

      debugPrint('onMaintenanceDepartmentChanged: functionalLocationList count = ${functionalLocationList.length}');

    } catch (e) {
      debugPrint('Error on department change: $e');
    }
  }

  void _filterLocationsByDepartment() {
    try {
      // Filter from locationTypeList if available, otherwise from masterLocations
      if (locationTypeList.length > 1) {
        final deptLocations = locationTypeList.where((loc) {
          // For now, include all locations since we don't have department mapping
          return loc.label != 'Select';
        }).toList();
        locationList.assignAll(deptLocations);
      } else {
        final deptLocations = masterLocations.where((loc) {
          final locDeptId = loc['deptId']?.toString();
          return locDeptId == departmentId.value.toString();
        }).toList();

        locationList.assignAll([
          LabelValue(label: 'Select', value: ''),
          ...deptLocations.map((loc) =>
            LabelValue(label: loc['label']?.toString() ?? '', value: loc['value']?.toString() ?? '')
          ),
        ]);
      }

      debugPrint('Filtered ${locationList.length} locations for department $departmentId');
    } catch (e) {
      debugPrint('Error filtering locations: $e');
    }
  }

  void _resetServiceAffectedFields() {
    trainDelayMinController.clear();
    trainDelayNosController.clear();
    trainCancelNosController.clear();
    trainWithdrawalNosController.clear();
    trainReplaceNosController.clear();
    selectedSystemDowntime.value = null;
    isPassengerDeboarding.value = false;
    trainDeboardedNosController.clear();
  }

  void _resetPassengerAffectedFields() {
    numberOfPassengerAffectedController.clear();
    trappedDurationController.clear();
    rescuedDurationController.clear();
  }

  Future<void> _loadPersonResponsible() async {
    try {
      final failureService = FailureService();
      final userId = await AuthManager().getUserId();
      final response = await failureService.getUsersByDepartmentId(departmentId.value ?? 0, userId ?? '0');
      if (response.users != null) {
        userList.assignAll([
          LabelValue(label: 'Select', value: ''),
          ...response.users!,
        ]);
      }
    } catch (e) {
      debugPrint('Error loading person responsible: $e');
    }
  }

  Future<void> _loadNatureOfWorkData() async {
    try {
      // For now, use existing natureOfWorkList or load from API if needed
      // This can be updated when the specific API is available
      if (natureOfWorkList.isEmpty) {
        natureOfWorkList.assignAll([
          LabelValue(label: 'Select', value: ''),
          LabelValue(label: 'Routine Maintenance', value: '1'),
          LabelValue(label: 'Breakdown Maintenance', value: '2'),
          LabelValue(label: 'Preventive Maintenance', value: '3'),
        ]);
      }
    } catch (e) {
      debugPrint('Error loading nature of work data: $e');
    }
  }

  Future<void> onMaintenanceLocationChanged(String? value) async {
    if (value == null || value.isEmpty) return;

    // Reset functional location and dependent fields
    selectedFunctionalLocation.value = '';
    selectedFmecaSystem.value = '';
    selectedFmecaSubsystem.value = '';
    selectedEquipmentNumber.value = '';

    fmecaSystemController.clear();
    fmecaSubsystemController.clear();

    functionalLocationList.clear();
    fmecaSystemList.clear();
    fmecaSubsystemList.clear();
    equipmentList.clear();

    // Filter functional locations from local database
    _filterFunctionalLocations();
  }

  void _filterFunctionalLocations() {
    try {
      final locCode = _getLocationCode(selectedLocation.value);
      final workCenter = getCurrentWorkCenterFromDept();

      debugPrint('Filtering functional locations: locCode=$locCode, workCenter=$workCenter');

      final filteredFuncs = masterFunctionalLocations.where((e) {
        bool match = true;

        if (locCode != null && locCode.isNotEmpty) {
          final funcLoc = e['location']?.toString().trim().toUpperCase();
          if (funcLoc != null && funcLoc.isNotEmpty) {
            match = match && (funcLoc == locCode.trim().toUpperCase());
          }
        }

        if (workCenter != null && workCenter.isNotEmpty) {
          final funcWorkCenter = e['workCenter']?.toString().trim().toUpperCase();
          if (funcWorkCenter != null && funcWorkCenter.isNotEmpty) {
            match = match && (funcWorkCenter == workCenter.trim().toUpperCase());
          }
        }

        return match;
      }).toList();

      functionalLocationList.assignAll([
        LabelValue(label: 'Select', value: ''),
        ...filteredFuncs.map((func) =>
          LabelValue(
            label: func['funcLocationName']?.toString() ?? func['funcLocation']?.toString() ?? '',
            value: func['funcLocId']?.toString() ?? ''
          )
        ),
      ]);

      debugPrint('Filtered ${functionalLocationList.length} functional locations');
    } catch (e) {
      debugPrint('Error filtering functional locations: $e');
    }
  }

  void _filterFunctionalLocationsByWorkCenter() {
    try {
      final workCenter = getCurrentWorkCenterFromDept();

      debugPrint('Filtering functional locations by work center: workCenter=$workCenter');
      debugPrint('masterFunctionalLocations count: ${masterFunctionalLocations.length}');

      // Show sample data for debugging
      if (masterFunctionalLocations.isNotEmpty) {
        debugPrint('Sample masterFunctionalLocations data:');
        for (int i = 0; i < masterFunctionalLocations.length && i < 3; i++) {
          final func = masterFunctionalLocations[i];
          debugPrint('  [$i] funcLocationName: ${func['funcLocationName']}, workCenter: ${func['workCenter']}, location: ${func['location']}');
        }
      }

      final filteredFuncs = masterFunctionalLocations.where((e) {
        bool match = true;

        if (workCenter != null && workCenter.isNotEmpty) {
          final funcWorkCenter = e['workCenter']?.toString().trim().toUpperCase();
          // Only filter if funcWorkCenter is not empty - allow empty workCenter values
          if (funcWorkCenter != null && funcWorkCenter.isNotEmpty) {
            match = match && (funcWorkCenter == workCenter.trim().toUpperCase());
          }
        }

        return match;
      }).toList();

      functionalLocationList.assignAll([
        LabelValue(label: 'Select', value: ''),
        ...filteredFuncs.map((func) =>
          LabelValue(
            label: func['funcLocationName']?.toString() ?? func['funcLocation']?.toString() ?? '',
            value: func['funcLocId']?.toString() ?? ''
          )
        ),
      ]);

      debugPrint('Filtered ${functionalLocationList.length} functional locations by work center');
    } catch (e) {
      debugPrint('Error filtering functional locations by work center: $e');
    }
  }



  String? _getLocationCode(String? locationLabel) {
    if (locationLabel == null || locationLabel.isEmpty || locationLabel == 'Select') {
      return null;
    }
    final loc = masterLocations.firstWhere(
      (e) => e['label']?.toString() == locationLabel,
      orElse: () => <String, dynamic>{},
    );
    return loc['value']?.toString() ?? loc['locationCode']?.toString();
  }

  Future<void> onMaintenanceFunctionalLocationChanged(String? value) async {
    if (value == null || value.isEmpty) return;

    try {
      // Reset dependent fields
      selectedFmecaSystem.value = '';
      selectedFmecaSubsystem.value = '';
      selectedEquipmentNumber.value = '';

      fmecaSystemController.clear();
      fmecaSubsystemController.clear();

      fmecaSystemList.clear();
      fmecaSubsystemList.clear();
      equipmentList.clear();

      // Load functional location details from API for other data
      final failureService = FailureService();
      final response = await failureService.getFunctionalLocationDetails(value);

      if (response.details != null) {
        final data = response.details!;

        // Set Frequency (read-only, auto-calculated)
        fmecaFrequency.value = data.frequency as int?;
        fmecaFrequencyController.text = data.frequency?.toString() ?? '';

        // Load System (FMECA) from API
        fmecaSystemList.assignAll([
          LabelValue(label: 'Select', value: ''),
          ...data.systemList ?? [],
        ]);

        // Auto-select if only one system
        if (fmecaSystemList.length == 2) { // Select + one system
          selectedFmecaSystem.value = fmecaSystemList[1].label ?? '';
          fmecaSystemController.text = fmecaSystemList[1].label ?? '';
          await onMaintenanceFmecaSystemChanged(selectedFmecaSystem.value);
        }

        // Load Equipment from API
        equipmentList.assignAll([
          LabelValue(label: 'Select', value: ''),
          ...data.equipmentList ?? [],
        ]);

        // Load Maintenance History
        maintenanceHistoryList.assignAll(data.maintenanceHistory?.map((hist) =>
          {'description': hist.description, 'date': hist.date}
        ).toList() ?? []);

        maintenanceHistoryListPrev.assignAll(data.maintenanceHistoryPrev?.map((hist) =>
          {'description': hist.description, 'date': hist.date}
        ).toList() ?? []);

        // Load Measurement Points
        final measurementData = data.measurementPoints ?? [];
        if (measurementData.isNotEmpty) {
          measurementPoints.assignAll(measurementData.map((point) => {
            'measurementPoint': point.measurementPoint,
            'description': point.description,
            'unit': point.unit,
            'isReadingRequired': false,
          }).toList());
          showMeasurementButton.value = true;
        } else {
          showMeasurementButton.value = false;
        }
      }
    } catch (e) {
      debugPrint('Error loading functional location details: $e');
    }
  }

  Future<void> onMaintenanceFmecaSystemChanged(String? value) async {
    if (value == null || value.isEmpty) return;

    try {
      selectedFmecaSubsystem.value = '';
      fmecaSubsystemController.clear();
      fmecaSubsystemList.clear();

      // For now, use existing subsystem loading logic from functional location details
      // The subsystems are typically loaded when functional location is selected
      // This can be enhanced to call a specific subsystem API if needed

      // Use existing fmecaSubsystemList if already populated
      if (fmecaSubsystemList.isEmpty) {
        // Load some default subsystems or wait for functional location selection
        fmecaSubsystemList.assignAll([
          LabelValue(label: 'Select', value: ''),
          LabelValue(label: 'Subsystem 1', value: '1'),
          LabelValue(label: 'Subsystem 2', value: '2'),
        ]);
      }

      // Auto-select if only one subsystem
      if (fmecaSubsystemList.length == 2) { // Select + one subsystem
        selectedFmecaSubsystem.value = fmecaSubsystemList[1].label ?? '';
        fmecaSubsystemController.text = fmecaSubsystemList[1].label ?? '';
      }
    } catch (e) {
      debugPrint('Error loading subsystems: $e');
    }
  }

  Future<void> onEquipmentChanged(String? value) async {
    selectedEquipmentNumber.value = value ?? '';
  }

  Future<void> onJointInspectionDepartmentChanged(String? value) async {
    if (value == null || value.isEmpty) return;

    selectedJointDept.value = value;
    selectedJointAssignTo.value = '';
    jointUserList.clear();

    // Load users for the selected department
    await _loadJointInspectionUsers(value);
  }

  Future<void> _loadJointInspectionUsers(String department) async {
    try {
      final failureService = FailureService();
      final response = await failureService.getPersonResponsible(departmentId.value!);
      if (response.users != null) {
        jointUserList.assignAll([
          LabelValue(label: 'Select', value: ''),
          ...response.users!,
        ]);
      }
    } catch (e) {
      debugPrint('Error loading joint inspection users: $e');
    }
  }
}
