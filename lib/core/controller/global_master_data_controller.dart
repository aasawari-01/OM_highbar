import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:om_mobile/core/models/label_value.dart';
import 'package:om_mobile/service/local_database_service.dart';
import 'package:om_mobile/service/auth_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalMasterDataController extends GetxController {
  static GlobalMasterDataController get to => Get.find();

  // Master data lists
  final RxList<LabelValue> priorityTypeList = <LabelValue>[].obs;
  final RxList<LabelValue> locationTypeList = <LabelValue>[].obs;
  final RxList<LabelValue> functionalLocationList = <LabelValue>[].obs;
  final RxList<LabelValue> equipmentList = <LabelValue>[].obs;
  final RxList<LabelValue> departmentList = <LabelValue>[].obs;
  final RxList<LabelValue> userList = <LabelValue>[].obs;
  final RxList<LabelValue> corrNotificationTypeList = <LabelValue>[].obs;
  final RxList<LabelValue> storageLocationList = <LabelValue>[].obs;
  final RxList<LabelValue> reasonForDelayList = <LabelValue>[].obs;
  final RxList<LabelValue> faultTypeList = <LabelValue>[].obs;
  final RxList<LabelValue> objectDataList = <LabelValue>[].obs;
  final RxList<LabelValue> rootCauseList = <LabelValue>[].obs;
  final RxList<LabelValue> causeList = <LabelValue>[].obs;
  final RxList<LabelValue> actionList = <LabelValue>[].obs;
  final RxList<LabelValue> rcaFailureCategoryList = <LabelValue>[].obs;
  final RxList<LabelValue> rstFailureTypeList = <LabelValue>[].obs;
  final RxList<LabelValue> rstObjectPartList = <LabelValue>[].obs;
  final RxList<LabelValue> rstMaterialList = <LabelValue>[].obs;
  final RxList<LabelValue> rstTrainStatusList = <LabelValue>[].obs;
  final RxList<LabelValue> rstStorageLocationList = <LabelValue>[].obs;
  final RxList<LabelValue> roleList = <LabelValue>[].obs;

  // Additional tables from FailureDataLoadingLogic
  final RxList<LabelValue> notificationTypeList = <LabelValue>[].obs;
  final RxList<LabelValue> natureOfWorkList = <LabelValue>[].obs;
  final RxList<LabelValue> userStatusList = <LabelValue>[].obs;
  final RxList<LabelValue> materialDataList = <LabelValue>[].obs;
  final RxList<LabelValue> actionTakenList = <LabelValue>[].obs;

  // NEW: JE View databases
  final RxList<LabelValue> corrFailureTypeList = <LabelValue>[].obs;
  final RxList<LabelValue> userStatusJeList = <LabelValue>[].obs;
  final RxList<LabelValue> materialMasterList = <LabelValue>[].obs;

  // NEW: RST View databases
  final RxList<LabelValue> rstFaultMasterList = <LabelValue>[].obs;
  final RxList<LabelValue> rstOldRootCauseList = <LabelValue>[].obs;
  final RxList<LabelValue> rstStoreLocationList = <LabelValue>[].obs;

  // Master data for reference
  final RxList<Map<String, dynamic>> masterLocations = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> masterFunctionalLocations = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> masterEquipments = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> masterDepartments = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> masterUsers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> masterMeasurementPoints = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> masterNotificationTypes = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> masterRootCauses = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> masterActionTakens = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> masterCauseOfFailures = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> masterRcaFailureCategories = <Map<String, dynamic>>[].obs;

  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;


  Future<void>? _loadFuture;

  static const _kDataLoadedKey = 'master_data_loaded';

  Future<bool> _isDataAlreadyLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDataLoadedKey) ?? false;
  }

  Future<void> _markDataLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDataLoadedKey, true);
  }

  Future<void> initOnLogin() async {
    if (_isLoaded) {
      debugPrint('GlobalMasterDataController: Data already loaded, skipping');
      return;
    }

    if (_loadFuture != null) {
      debugPrint('GlobalMasterDataController: Already loading, waiting for it to finish');
      return _loadFuture;
    }

    _loadFuture = _loadAllDataParallel();
    await _loadFuture;
  }

  // Backwards compatibility for existing calls
  Future<void> loadMasterData() async => initOnLogin();
  Future<void> loadBasicMasterData() async => initOnLogin();
  Future<void> loadRcaMasterData() async => initOnLogin();

  Future<void> _loadAllDataParallel() async {
    _isLoading = true;
    try {
      debugPrint('GlobalMasterDataController: Loading small master data only (large tables loaded on-demand)');
      final dbService = LocalDatabaseService();
      final businessArea = await AuthManager().getBusinessArea();
      
      final isStaticDataInserted = await _isDataAlreadyLoaded();

      // Load only SMALL master data globally
      // Large tables (Functional Locations 84k, Equipment 64k, Users, Measurement Points 569k) loaded on-demand
      await Future.wait([
        _loadPriorities(dbService),
        _loadDepartments(dbService),
        _loadFailureCategories(dbService),
        // Measurement points (569k records) - loaded on-demand to avoid memory crash
        _loadNotificationTypes(dbService, isStaticDataInserted),
        _loadRcaData(dbService, isStaticDataInserted),
        _loadRstData(dbService),
        _loadJeData(dbService),
        // Locations loaded if count is reasonable (check in _loadLocations)
        _loadLocations(dbService, businessArea),
      ]);

      if (!isStaticDataInserted) {
        await _markDataLoaded();
      }

      _isLoaded = true;
      debugPrint('GlobalMasterDataController: Small master data loaded successfully');
      debugPrint('GlobalMasterDataController: Large tables (Functional Locations, Equipment, Users) will be loaded on-demand');
    } catch (e) {
      debugPrint('GlobalMasterDataController: Error loading master data: $e');
    } finally {
      _isLoading = false;
      _loadFuture = null;
    }
  }

  Future<void> _loadLocations(LocalDatabaseService dbService, int? businessArea) async {
    final locations = businessArea != null
        ? await dbService.getLocationsByBusinessArea(businessArea)
        : await dbService.getLocations();
    masterLocations.assignAll(locations.map((e) => e.toJson()).toList());
    locationTypeList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...locations.map((e) => LabelValue(
        label: e.locationName,
        value: e.locationTypeId?.toString() ?? '',
        uniqueId: e.locationTypeCode,
      )),
    ]);
  }

  Future<void> _loadPriorities(LocalDatabaseService dbService) async {
    final priorities = await dbService.getPriorities();
    priorityTypeList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...priorities.map((e) => LabelValue(
        label: e.priorityDesc ?? '',
        value: e.priorityId?.toString() ?? '',
      )),
    ]);
  }

  Future<void> _loadDepartments(LocalDatabaseService dbService) async {
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
  }

  Future<void> _loadFailureCategories(LocalDatabaseService dbService) async {
    final categories = await dbService.getFailureCategories();
    corrNotificationTypeList.assignAll([
      LabelValue(label: 'Select', value: ''),
      ...categories.map((e) => LabelValue(
        label: e.failureCategoryType ?? '',
        value: e.id?.toString() ?? '',
      )),
    ]);
  }

  Future<void> _loadNotificationTypes(LocalDatabaseService dbService, bool isInserted) async {
    final types = await dbService.getNotificationTypes();
    if (!isInserted) await dbService.insertNotificationTypes(types);
    masterNotificationTypes.assignAll(types.map((e) => e.toJson()).toList());
  }

  Future<void> _loadRcaData(LocalDatabaseService dbService, bool isInserted) async {
    debugPrint("_loadRcaData: STARTING - isInserted=$isInserted");
    // Root Causes
    debugPrint("_loadRcaData: Calling getRootCauses");
    final rootCauses = await dbService.getRootCauses();
    debugPrint("_loadRcaData: Got ${rootCauses.length} root causes");
    if (!isInserted) {
      debugPrint("_loadRcaData: Inserting root causes");
      await dbService.insertRootCauses(rootCauses);
      debugPrint("_loadRcaData: Root causes inserted");
    }
    masterRootCauses.assignAll(rootCauses.map((e) => e.toJson()).toList());
    rootCauseList.assignAll(rootCauses.map((e) => LabelValue(label: e.rootCause, value: e.rootCauseId?.toString() ?? '')));

    // Action Takens
    debugPrint("_loadRcaData: Calling getActionTakens");
    final actions = await dbService.getActionTakens();
    debugPrint("_loadRcaData: Got ${actions.length} action takens");
    if (!isInserted) await dbService.insertActionTakens(actions);
    masterActionTakens.assignAll(actions.map((e) => e.toJson()).toList());
    actionList.assignAll(actions.map((e) => LabelValue(label: '${e.systemGroup ?? ''}-${e.actionCode ?? ''}-${e.actionDescr ?? e.actionTaken}', value: e.id?.toString() ?? '')));

    // Cause Of Failures
    debugPrint("_loadRcaData: Calling getCauseOfFailures");
    final causes = await dbService.getCauseOfFailures();
    debugPrint("_loadRcaData: Got ${causes.length} cause of failures");
    if (!isInserted) await dbService.insertCauseOfFailures(causes);
    masterCauseOfFailures.assignAll(causes.map((e) => e.toJson()).toList());
    causeList.assignAll(causes.map((e) => LabelValue(label: e.cause, value: e.causeOfFailureId?.toString() ?? '')));

    // RCA Failure Categories
    debugPrint("_loadRcaData: Calling getRcaFailureCategories");
    final rcaCats = await dbService.getRcaFailureCategories();
    debugPrint("_loadRcaData: Got ${rcaCats.length} RCA failure categories from asset DB");
    if (!isInserted) {
      debugPrint("_loadRcaData: Inserting RCA failure categories into local DB");
      await dbService.insertRcaFailureCategories(rcaCats);
    }
    masterRcaFailureCategories.assignAll(rcaCats.map((e) => e.toJson()).toList());
    rcaFailureCategoryList.assignAll(rcaCats.map((e) => LabelValue(label: e.failureCategory ?? '', value: e.failureCategoryId?.toString() ?? '')));
    debugPrint("_loadRcaData: COMPLETED - rcaFailureCategoryList has ${rcaFailureCategoryList.length} items");
  }

  Future<void> _loadRstData(LocalDatabaseService dbService) async {
    final db = await dbService.database;

    try {
      final storeLocations = await dbService.getStoreLocations();
      debugPrint("_loadRstData: Got ${storeLocations.length} store locations");
      if (storeLocations.isNotEmpty) {
        debugPrint("_loadRstData: First store location: storeLocation=${storeLocations.first.storeLocation}, storeLocationDesc=${storeLocations.first.storeLocationDesc}, storeLocationId=${storeLocations.first.storeLocationId}");
      }
      storageLocationList.assignAll(storeLocations.map((e) => LabelValue(label: e.storeLocationDesc ?? e.storeLocation ?? '', value: e.storeLocationId?.toString() ?? '')));
      debugPrint("_loadRstData: storageLocationList has ${storageLocationList.length} items");
      if (storageLocationList.isNotEmpty) {
        debugPrint("_loadRstData: First storageLocationList item: label=${storageLocationList.first.label}, value=${storageLocationList.first.value}");
      }
    } catch (e) {
      debugPrint("_loadRstData: Error loading store locations: $e");
    }

    try {
      final reasonForDelayData = await db.query('ReasonForDelay');
      reasonForDelayList.assignAll(reasonForDelayData.map((e) => LabelValue(label: e['reasonName']?.toString() ?? '', value: e['reasonId']?.toString() ?? '')));
    } catch (_) {}

    try {
      final faultTypeData = await db.query('FaultTypes');
      faultTypeList.assignAll(faultTypeData.map((e) => LabelValue(label: e['faultName']?.toString() ?? '', value: e['faultId']?.toString() ?? '')));
    } catch (_) {}

    try {
      final objectData = await db.query('ObjectParts');
      objectDataList.assignAll(objectData.map((e) => LabelValue(label: e['objectPartName']?.toString() ?? '', value: e['objectPartId']?.toString() ?? '')));
    } catch (_) {}

    try {
      final notifData = await db.query('NotificationTypes');
      notificationTypeList.assignAll(notifData.map((e) => LabelValue(label: e['notificationTypeName']?.toString() ?? '', value: e['notificationTypeId']?.toString() ?? '')));
    } catch (_) {}

    try {
      final natureData = await db.query('NatureOfWork');
      natureOfWorkList.assignAll(natureData.map((e) => LabelValue(label: e['natureOfWorkName']?.toString() ?? '', value: e['natureOfWorkId']?.toString() ?? '')));
    } catch (_) {}

    try {
      final statusData = await db.query('UserStatus');
      userStatusList.assignAll(statusData.map((e) => LabelValue(label: e['statusName']?.toString() ?? '', value: e['statusId']?.toString() ?? '')));
    } catch (_) {}

    try {
      final matData = await db.query('Materials');
      materialDataList.assignAll(matData.map((e) => LabelValue(label: e['materialName']?.toString() ?? '', value: e['materialId']?.toString() ?? '')));
    } catch (_) {}

    try {
      final actionTakenData = await db.query('ActionTakens');
      actionTakenList.assignAll(actionTakenData.map((e) => LabelValue(
        label: '${e['SystemGroup']?.toString() ?? ''}-${e['ActionCode']?.toString() ?? ''}-${e['ActionDescr']?.toString() ?? ''}',
        value: e['ID']?.toString() ?? '',
      )));
    } catch (_) {}

    // NEW: Load RST data from new databases
    try {
      final objectParts = await dbService.getRstObjectPartsFromDb();
      rstObjectPartList.assignAll(objectParts.map((e) => LabelValue(label: e.objectCodeDesc ?? '', value: e.id?.toString() ?? '')));
    } catch (_) {}

    try {
      final faultMasters = await dbService.getRstFaultMasters();
      rstFaultMasterList.assignAll(faultMasters.map((e) => LabelValue(label: e.faultText ?? e.fault ?? '', value: e.faultId?.toString() ?? '')));
    } catch (_) {}

    try {
      final oldRootCauses = await dbService.getRstOldRootCauses();
      rstOldRootCauseList.assignAll(oldRootCauses.map((e) => LabelValue(label: e.rootCauseText ?? e.rootCause ?? '', value: e.rootCauseId?.toString() ?? '')));
    } catch (_) {}

    try {
      final storeLocations = await dbService.getStoreLocations();
      rstStoreLocationList.assignAll(storeLocations.map((e) => LabelValue(label: e.storeLocationDesc ?? e.storeLocation ?? '', value: e.storeLocationId?.toString() ?? '')));
    } catch (_) {}
  }

  Future<void> _loadJeData(LocalDatabaseService dbService) async {
    // Load JE view data from new databases
    try {
      final corrFailureTypes = await dbService.getCorrFailureTypes();
      corrFailureTypeList.assignAll(corrFailureTypes.map((e) => LabelValue(label: e.failureType ?? '', value: e.id?.toString() ?? '')));
    } catch (_) {}

    try {
      final userStatuses = await dbService.getUserStatuses();
      // First 4 records for JE view user status dropdown
      userStatusJeList.assignAll(userStatuses.take(4).map((e) => LabelValue(label: e.statusName ?? e.statusDescr ?? '', value: e.statusId?.toString() ?? '')));
    } catch (_) {}

    try {
      final materialMasters = await dbService.getMaterialMasters();
      debugPrint("_loadJeData: Got ${materialMasters.length} material masters");
      if (materialMasters.isNotEmpty) {
        debugPrint("_loadJeData: First material master: material=${materialMasters.first.material}, description=${materialMasters.first.description}, materialRowId=${materialMasters.first.materialRowId}");
      }
      materialMasterList.assignAll(materialMasters.map((e) {
        // If description already contains the material code (format: "CODE - Description"), use it directly
        // Otherwise, concatenate material and description
        String label;
        if (e.description != null && e.description!.isNotEmpty) {
          if (e.description!.contains(' - ')) {
            // Description already has the format "CODE - Description", use it as is
            label = e.description!;
          } else {
            // Concatenate material and description
            label = '${e.material ?? ''} - ${e.description!}';
          }
        } else {
          label = e.material ?? '';
        }
        return LabelValue(label: label, value: e.materialRowId?.toString() ?? '');
      }));
      debugPrint("_loadJeData: materialMasterList has ${materialMasterList.length} items");
      if (materialMasterList.isNotEmpty) {
        debugPrint("_loadJeData: First materialMasterList item: label=${materialMasterList.first.label}, value=${materialMasterList.first.value}");
      }
    } catch (e) {
      debugPrint("_loadJeData: Error loading material masters: $e");
    }
  }

  Future<void> reloadMasterData() async {
    _isLoaded = false;
    await initOnLogin();
  }

  void clearData() {
    _isLoaded = false;
    _loadFuture = null;
    SharedPreferences.getInstance().then((prefs) => prefs.remove(_kDataLoadedKey));
    priorityTypeList.clear();
    locationTypeList.clear();
    functionalLocationList.clear();
    equipmentList.clear();
    departmentList.clear();
    userList.clear();
    corrNotificationTypeList.clear();
    storageLocationList.clear();
    reasonForDelayList.clear();
    faultTypeList.clear();
    objectDataList.clear();
    rootCauseList.clear();
    rstFailureTypeList.clear();
    rstObjectPartList.clear();
    rstMaterialList.clear();
    rstTrainStatusList.clear();
    rstStorageLocationList.clear();
    roleList.clear();
    masterLocations.clear();
    masterFunctionalLocations.clear();
    masterEquipments.clear();
    masterDepartments.clear();
  }
}
