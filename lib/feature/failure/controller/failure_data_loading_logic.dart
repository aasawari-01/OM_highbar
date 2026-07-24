import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_constants.dart';
import '../../../core/models/label_value.dart';
import '../../../service/auth_manager.dart';
import '../../../service/local_database_service.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../service/master_data_sync_service.dart';
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
  bool _isLoadingMasterData = false;

  Future<void> loadDepartments() async {
    debugPrint("_loadDepartments: Starting to load departments");
    final depts = (await LocalDatabaseService().getDepartments()).map((e) => e.toJson()).toList();
    masterDepartments.assignAll(depts);
    debugPrint("_loadDepartments: Loaded ${depts.length} departments from local DB to masterDepartments");
    debugPrint("_loadDepartments: departmentList will have ${depts.length + 1} items (including Select)");
    
    // If masterDepartments is empty, try to fetch departments from API
    if (masterDepartments.isEmpty) {
      debugPrint("_loadDepartments: masterDepartments empty, fetching from API");
      try {
        final apiClient = ApiClient();
        final userId = int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;
        final response = await apiClient.post(
          AppUrls.getMasterData,
          body: {
            "userId": userId,
            "action": "GetDeptMasterData"
          }
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonBody = jsonDecode(response.body);
          if (jsonBody['success'] == true && jsonBody['data'] != null) {
            List<dynamic> apiDepts = jsonBody['data']['departments'] ?? [];
            if (apiDepts.isNotEmpty) {
              final mappedDepts = apiDepts.map((e) => {
                'deptId': e['deptId']?.toString(),
                'deptName': e['deptName']?.toString(),
                'workCenter': e['workCenter']?.toString() ?? '',
              }).toList();
              masterDepartments.assignAll(mappedDepts);
              debugPrint("_loadDepartments: Loaded ${mappedDepts.length} departments from API");
              // Update depts to use API data for departmentList
              depts.clear();
              depts.addAll(mappedDepts);
            }
          }
        }
      } catch (e) {
        debugPrint("_loadDepartments: Error fetching departments from API: $e");
      }
    }

    departmentList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...depts.map((e) => LabelValue(
        label: e['deptName']?.toString() ?? '',
        value: e['deptId']?.toString() ?? '',
      )),
    ]);
    debugPrint("_loadDepartments: departmentList populated with ${departmentList.length} items");
  }

  Future<void> loadMasterDataFromDb() async {
    // Prevent concurrent calls
    if (_isLoadingMasterData) {
      debugPrint('_loadMasterDataFromDb: Already loading, skipping duplicate call');
      return;
    }
    
    _isLoadingMasterData = true;
    try {
      final dbService = LocalDatabaseService();
      final db = await dbService.database;

      masterLocations.assignAll((await dbService.getLocations()).map((e) => e.toJson()).toList());
      masterFunctionalLocations.assignAll((await dbService.getFunctionalLocations()).map((e) => e.toJson()).toList());
      masterEquipments.assignAll((await dbService.getEquipments()).map((e) => e.toJson()).toList());

      final priorityData = await db.query('PriorityTypes');
      priorityTypeList.assignAll(priorityData.map((e) => LabelValue(
        label: e['priorityName']?.toString() ?? '',
        value: e['priorityId']?.toString() ?? '',
      )));

      final locationTypeData = await db.query('LocationTypes');
      locationTypeList.assignAll(locationTypeData.map((e) => LabelValue(
        label: e['locationTypeName']?.toString() ?? '',
        value: e['locationTypeId']?.toString() ?? '',
      )));

      final storageLocationData = await db.query('StorageLocations');
      storageLocationList.assignAll(storageLocationData.map((e) => LabelValue(
        label: e['storageLocationName']?.toString() ?? '',
        value: e['storageLocationId']?.toString() ?? '',
      )));

      final reasonForDelayData = await db.query('ReasonForDelay');
      reasonForDelayList.assignAll(reasonForDelayData.map((e) => LabelValue(
        label: e['reasonName']?.toString() ?? '',
        value: e['reasonId']?.toString() ?? '',
      )));

      final faultTypeData = await db.query('FaultTypes');
      faultTypeList.assignAll(faultTypeData.map((e) => LabelValue(
        label: e['faultName']?.toString() ?? '',
        value: e['faultId']?.toString() ?? '',
      )));

      final objectData = await db.query('ObjectParts');
      objectDataList.assignAll(objectData.map((e) => LabelValue(
        label: e['objectPartName']?.toString() ?? '',
        value: e['objectPartId']?.toString() ?? '',
      )));

      final rootCauseData = await db.query('RootCauses');
      rootCauseList.assignAll(rootCauseData.map((e) => LabelValue(
        label: e['rootCauseName']?.toString() ?? '',
        value: e['rootCauseId']?.toString() ?? '',
      )));

      final actionTakenData = await db.query('ActionTakens');
      actionTakenList.assignAll(actionTakenData.map((e) => LabelValue(
        label: e['actionTakenName']?.toString() ?? '',
        value: e['actionTakenId']?.toString() ?? '',
      )));

      final notificationTypeData = await db.query('NotificationTypes');
      notificationTypeList.assignAll(notificationTypeData.map((e) => LabelValue(
        label: e['notificationTypeName']?.toString() ?? '',
        value: e['notificationTypeId']?.toString() ?? '',
      )));

      final natureOfWorkData = await db.query('NatureOfWork');
      natureOfWorkList.assignAll(natureOfWorkData.map((e) => LabelValue(
        label: e['natureOfWorkName']?.toString() ?? '',
        value: e['natureOfWorkId']?.toString() ?? '',
      )));

      final userStatusData = await db.query('UserStatus');
      userStatusList.assignAll(userStatusData.map((e) => LabelValue(
        label: e['statusName']?.toString() ?? '',
        value: e['statusId']?.toString() ?? '',
      )));

      final corrNotificationTypeData = await db.query('CorrNotificationTypes');
      corrNotificationTypeList.assignAll(corrNotificationTypeData.map((e) => LabelValue(
        label: e['corrNotificationTypeName']?.toString() ?? '',
        value: e['corrNotificationTypeId']?.toString() ?? '',
      )));

      final materialData = await db.query('Materials');
      materialDataList.assignAll(materialData.map((e) => LabelValue(
        label: e['materialName']?.toString() ?? '',
        value: e['materialId']?.toString() ?? '',
      )));

      debugPrint('_loadMasterDataFromDb: Loaded all master data from local DB');
    } catch (e) {
      debugPrint('_loadMasterDataFromDb: Error loading master data: $e');
    } finally {
      _isLoadingMasterData = false;
    }
  }

  Future<void> loadMasterDropdownsFromDb({bool refreshIfEmpty = false}) async {
    final dbService = LocalDatabaseService();

    if (refreshIfEmpty) {
      try {
        final priorities = (await dbService.getPriorities()).map((e) => e.toJson()).toList();
        final categories = (await dbService.getFailureCategories()).map((e) => e.toJson()).toList();
        final users = (await dbService.getMasterUsers()).map((e) => e.toJson()).toList();
        if (priorities.isEmpty || categories.isEmpty || users.isEmpty) {
          await MasterDataSyncService().syncStationFailureDropdownMasterData();
        }
      } catch (e) {
        debugPrint('_loadMasterDropdownsFromDb sync error: $e');
        await MasterDataSyncService().syncStationFailureDropdownMasterData();
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
    corrNotificationTypeList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...categories
          .where((e) => (e['failureCategoryType']?.toString() ?? '').isNotEmpty && (e['failureCategoryType']?.toString().toLowerCase() != 'select'))
          .map((e) => LabelValue(
        label: e['failureCategoryType']?.toString() ?? '',
        value: e['id']?.toString() ?? '',
      )),
    ]);

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
}
