import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../core/models/label_value.dart';
import '../core/models/location.dart';
import '../core/models/functional_location.dart';
import '../core/models/equipment.dart';
import '../core/models/measurement_point.dart';
import '../core/models/priority.dart';
import '../core/models/failure_category.dart';
import '../core/models/department.dart';
import '../core/models/master_user.dart';
import '../core/models/rst_failure_type.dart';
import '../core/models/rst_object_part.dart';
import '../core/models/rst_material.dart';
import '../core/models/rst_train_status.dart';
import '../core/models/notification_type.dart';
import '../core/models/root_cause.dart';
import '../core/models/action_taken.dart';
import '../core/models/cause_of_failure.dart';
import '../core/models/rca_failure_category.dart';
import '../core/models/corr_failure_type.dart';
import '../core/models/user_status.dart';
import '../core/models/material_master.dart';
import '../core/models/rst_fault_master.dart';
import '../core/models/rst_old_root_cause.dart';
import '../core/models/store_location.dart';
import '../core/models/reason_for_delay.dart';
import '../core/models/nature_of_work.dart';
import '../core/models/failure_category_type.dart';
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;
  Database? _deptDatabase;
  Database? _funLocDatabase;
  Database? _equipmentDatabase;
  Database? _locationDatabase;
  Database? _measurementDatabase;
  Database? _priorityDatabase;
  Database? _userDatabase;
  Database? _failureCategoryDatabase;
  Database? _notificationTypeDatabase;
  Database? _rootCauseDatabase;
  Database? _actionTakenDatabase;
  Database? _causeOfFailureDatabase;
  Database? _rcaFailureCategoryDatabase;
  Database? _corrFailureTypeDatabase;
  Database? _userStatusDatabase;
  Database? _materialMasterDatabase;
  Database? _rstObjectPartDatabase;
  Database? _rstFaultMasterDatabase;
  Database? _rstOldRootCauseDatabase;
  Database? _rstStoreLocationDatabase;
  Database? _reasonForDelayDatabase;
  Database? _natureOfWorkDatabase;
  Database? _failureCategoryTypeDatabase;
  Database? _plantDatabase;

  Future<Database> _openAssetDatabase(String dbName, Future<void> Function(String) copyMethod) async {
    final path = join(await getDatabasesPath(), dbName);
    if (!await File(path).exists()) {
      await copyMethod(path);
    }
    return await openDatabase(path);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> get deptDatabase async {
    if (_deptDatabase != null) return _deptDatabase!;
    _deptDatabase = await _openAssetDatabase('dept_data.db', _copyDeptDatabaseFromAssets);
    return _deptDatabase!;
  }

  Future<Database> get funLocDatabase async {
    if (_funLocDatabase != null) return _funLocDatabase!;
    final db = await _openAssetDatabase('fun_loc_data.db', _copyFunLocDatabaseFromAssets);
    await _ensureMasterIndexes(db, const [
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_fl_id ON {t}(FuncLocId)',
      'CREATE INDEX IF NOT EXISTS idx_fl_wc_loc ON {t}(WorkCenter, Location, PlanningPlant)',
      'CREATE INDEX IF NOT EXISTS idx_fl_loc ON {t}(Location, PlanningPlant)',
    ]);
    _funLocDatabase = db;
    return db;
  }

  Future<Database> get equipmentDatabase async {
    if (_equipmentDatabase != null) return _equipmentDatabase!;
    final db = await _openAssetDatabase('equipment_data.db', _copyEquipmentDatabaseFromAssets);
    await _ensureMasterIndexes(db, const [
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_eq_id ON {t}(EquipId)',
      'CREATE INDEX IF NOT EXISTS idx_eq_wc_loc ON {t}(WorkCenter, Location, PlanningPlant)',
      'CREATE INDEX IF NOT EXISTS idx_eq_loc ON {t}(Location, PlanningPlant)',
      'CREATE INDEX IF NOT EXISTS idx_eq_fl ON {t}(FunctionalLocation)',
    ]);
    _equipmentDatabase = db;
    return db;
  }

  Future<Database> get plantDatabase async {
    if (_plantDatabase != null) return _plantDatabase!;
    _plantDatabase = await _openAssetDatabase('plant_data.db', _copyPlantDatabaseFromAssets);
    return _plantDatabase!;
  }

  Future<void> _copyPlantDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/plant_id.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
    } catch (e) {
      debugPrint("_copyPlantDatabaseFromAssets: Error copying plant_id.db: $e");
    }
  }

  /// Indexes the big asset tables so the dropdown filters (work center,
  /// location, plant, functional location) do not scan every row. `{t}` is
  /// replaced by the quoted name of the database's table.
  Future<void> _ensureMasterIndexes(Database db, List<String> templates) async {
    try {
      final table = await _firstUserTable(db);
      if (table == null) return;
      for (final t in templates) {
        await db.execute(t.replaceAll('{t}', '"$table"'));
      }
    } catch (e) {
      debugPrint('_ensureMasterIndexes error: $e');
    }
  }

  Future<String?> _firstUserTable(Database db) async {
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT IN ('android_metadata','sqlite_sequence') ORDER BY name");
    return tables.isEmpty ? null : tables.first['name'] as String;
  }

  Future<Database> get locationDatabase async {
    if (_locationDatabase != null) return _locationDatabase!;
    _locationDatabase = await _openAssetDatabase('location_data.db', _copyLocationDatabaseFromAssets);
    return _locationDatabase!;
  }

  Future<Database> get measurementDatabase async {
    if (_measurementDatabase != null) return _measurementDatabase!;
    _measurementDatabase = await _openAssetDatabase('measurement_data.db', _copyMeasurementDatabaseFromAssets);
    return _measurementDatabase!;
  }

  Future<Database> get priorityDatabase async {
    if (_priorityDatabase != null) return _priorityDatabase!;
    _priorityDatabase = await _openAssetDatabase('priority_data.db', _copyPriorityDatabaseFromAssets);
    return _priorityDatabase!;
  }

  Future<Database> get userDatabase async {
    if (_userDatabase != null) return _userDatabase!;
    _userDatabase = await _openAssetDatabase('user_data.db', _copyUserDatabaseFromAssets);
    return _userDatabase!;
  }

  Future<Database> get failureCategoryDatabase async {
    if (_failureCategoryDatabase != null) return _failureCategoryDatabase!;
    _failureCategoryDatabase = await _openAssetDatabase('failure_category_data.db', _copyFailureCategoryDatabaseFromAssets);
    return _failureCategoryDatabase!;
  }

  Future<Database> get notificationTypeDatabase async {
    if (_notificationTypeDatabase != null) return _notificationTypeDatabase!;
    // Always refresh from assets/notificationType.db so a stale cached copy
    // on the device can never show wrong data.
    final ntPath = join(await getDatabasesPath(), 'notification_type_data.db');
    if (await File(ntPath).exists()) {
      await File(ntPath).delete();
    }
    await _copyNotificationTypeDatabaseFromAssets(ntPath);
    _notificationTypeDatabase = await openDatabase(ntPath);
    return _notificationTypeDatabase!;
  }

  Future<Database> get rootCauseDatabase async {
    if (_rootCauseDatabase != null) return _rootCauseDatabase!;
    _rootCauseDatabase = await _openAssetDatabase('root_cause_data.db', _copyRootCauseDatabaseFromAssets);
    return _rootCauseDatabase!;
  }

  Future<Database> get actionTakenDatabase async {
    if (_actionTakenDatabase != null) return _actionTakenDatabase!;
    _actionTakenDatabase = await _openAssetDatabase('action_taken_data.db', _copyActionTakenDatabaseFromAssets);
    return _actionTakenDatabase!;
  }

  Future<Database> get causeOfFailureDatabase async {
    if (_causeOfFailureDatabase != null) return _causeOfFailureDatabase!;
    _causeOfFailureDatabase = await _openAssetDatabase('cause_of_failure_data.db', _copyCauseOfFailureDatabaseFromAssets);
    return _causeOfFailureDatabase!;
  }

  Future<Database> get rcaFailureCategoryDatabase async {
    debugPrint("rcaFailureCategoryDatabase getter called");
    if (_rcaFailureCategoryDatabase != null) {
      debugPrint("rcaFailureCategoryDatabase: Returning cached database");
      return _rcaFailureCategoryDatabase!;
    }
    debugPrint("rcaFailureCategoryDatabase: Opening new database from assets");
    _rcaFailureCategoryDatabase = await _openAssetDatabase('rca_failurecategory_data.db', _copyRcaFailureCategoryDatabaseFromAssets);
    debugPrint("rcaFailureCategoryDatabase: Database opened successfully");
    return _rcaFailureCategoryDatabase!;
  }

  Future<Database> get corrFailureTypeDatabase async {
    if (_corrFailureTypeDatabase != null) return _corrFailureTypeDatabase!;
    _corrFailureTypeDatabase = await _openAssetDatabase('corrfailuretype_data.db', _copyCorrFailureTypeDatabaseFromAssets);
    return _corrFailureTypeDatabase!;
  }

  Future<Database> get userStatusDatabase async {
    if (_userStatusDatabase != null) return _userStatusDatabase!;
    _userStatusDatabase = await _openAssetDatabase('userstatus_data.db', _copyUserStatusDatabaseFromAssets);
    return _userStatusDatabase!;
  }

  Future<Database> get materialMasterDatabase async {
    if (_materialMasterDatabase != null) return _materialMasterDatabase!;
    _materialMasterDatabase = await _openAssetDatabase('materialMaster.db', _copyMaterialMasterDatabaseFromAssets);
    return _materialMasterDatabase!;
  }

  Future<Database> get rstObjectPartDatabase async {
    if (_rstObjectPartDatabase != null) return _rstObjectPartDatabase!;
    _rstObjectPartDatabase = await _openAssetDatabase('objectpart_data.db', _copyRstObjectPartDatabaseFromAssets);
    return _rstObjectPartDatabase!;
  }

  Future<Database> get rstFaultMasterDatabase async {
    if (_rstFaultMasterDatabase != null) return _rstFaultMasterDatabase!;
    _rstFaultMasterDatabase = await _openAssetDatabase('faultmaster_data.db', _copyRstFaultMasterDatabaseFromAssets);
    return _rstFaultMasterDatabase!;
  }

  Future<Database> get rstOldRootCauseDatabase async {
    if (_rstOldRootCauseDatabase != null) return _rstOldRootCauseDatabase!;
    _rstOldRootCauseDatabase = await _openAssetDatabase('oldrootcause_data.db', _copyRstOldRootCauseDatabaseFromAssets);
    return _rstOldRootCauseDatabase!;
  }

  Future<Database> get rstStoreLocationDatabase async {
    if (_rstStoreLocationDatabase != null) return _rstStoreLocationDatabase!;
    _rstStoreLocationDatabase = await _openAssetDatabase('storelocation_data.db', _copyRstStoreLocationDatabaseFromAssets);
    return _rstStoreLocationDatabase!;
  }

  Future<Database> get reasonForDelayDatabase async {
    if (_reasonForDelayDatabase != null) return _reasonForDelayDatabase!;
    _reasonForDelayDatabase = await _openAssetDatabase('reasonForDelay_data.db', _copyReasonForDelayDatabaseFromAssets);
    return _reasonForDelayDatabase!;
  }

  Future<Database> get natureOfWorkDatabase async {
    if (_natureOfWorkDatabase != null) return _natureOfWorkDatabase!;
    _natureOfWorkDatabase = await _openAssetDatabase('natureOfWork_data.db', _copyNatureOfWorkDatabaseFromAssets);
    return _natureOfWorkDatabase!;
  }

  Future<Database> get failureCategoryTypeDatabase async {
    if (_failureCategoryTypeDatabase != null) return _failureCategoryTypeDatabase!;
    _failureCategoryTypeDatabase = await _openAssetDatabase('failure_categorytype_data.db', _copyFailureCategoryTypeDatabaseFromAssets);
    return _failureCategoryTypeDatabase!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'master_data.db');

    return await openDatabase(
      path,
      version: 18,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }



  Future<void> _copyDeptDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/dept.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyDeptDatabaseFromAssets: Successfully copied dept.db from assets");

      // Print table structure
      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyDeptDatabaseFromAssets: Tables in dept.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyDeptDatabaseFromAssets: Error copying dept.db: $e");
    }
  }

  Future<void> _copyFunLocDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/fun_loc.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyFunLocDatabaseFromAssets: Successfully copied fun_loc.db from assets");
    } catch (e) {
      debugPrint("_copyFunLocDatabaseFromAssets: Error copying fun_loc.db: $e");
    }
  }

  Future<void> _copyEquipmentDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/equipment.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyEquipmentDatabaseFromAssets: Successfully copied equipment.db from asets");

      // Print table structure
      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyEquipmentDatabaseFromAssets: Tables in equipment.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyEquipmentDatabaseFromAssets: Error copying equipment.db: $e");
    }
  }

  Future<void> _copyLocationDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/location.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyLocationDatabaseFromAssets: Successfully copied location.db from assets");

      // Print table structure
      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyLocationDatabaseFromAssets: Tables in location.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyLocationDatabaseFromAssets: Error copying location.db: $e");
    }
  }

  Future<void> _copyMeasurementDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/measurementPointMaster.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyMeasurementDatabaseFromAssets: Successfully copied measurementPointMaster.db from assets");
    } catch (e) {
      debugPrint("_copyMeasurementDatabaseFromAssets: Error copying measurementPointMaster.db: $e");
    }
  }

  Future<void> _copyNotificationTypeDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/notificationType.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyNotificationTypeDatabaseFromAssets: Successfully copied notificationType.db from assets");
    } catch (e) {
      debugPrint("_copyNotificationTypeDatabaseFromAssets: Error copying notificationType.db: $e");
    }
  }

  Future<void> _copyRootCauseDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/rootCause.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyRootCauseDatabaseFromAssets: Successfully copied rootCause.db from assets");
    } catch (e) {
      debugPrint("_copyRootCauseDatabaseFromAssets: Error copying rootCause.db: $e");
    }
  }

  Future<void> _copyActionTakenDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/actiontaken.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyActionTakenDatabaseFromAssets: Successfully copied actiontaken.db from assets");
    } catch (e) {
      debugPrint("_copyActionTakenDatabaseFromAssets: Error copying actiontaken.db: $e");
    }
  }

  Future<void> _copyCauseOfFailureDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/causeOfFailure.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyCauseOfFailureDatabaseFromAssets: Successfully copied causeOfFailure.db from assets");
    } catch (e) {
      debugPrint("_copyCauseOfFailureDatabaseFromAssets: Error copying causeOfFailure.db: $e");
    }
  }

  Future<void> _copyRcaFailureCategoryDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/rca_failurecategory.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyRcaFailureCategoryDatabaseFromAssets: Successfully copied rca_failurecategory.db from assets");
    } catch (e) {
      debugPrint("_copyRcaFailureCategoryDatabaseFromAssets: Error copying rca_failurecategory.db: $e");
    }
  }

  Future<void> _copyPriorityDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/priority.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyPriorityDatabaseFromAssets: Successfully copied priority.db from assets");
    } catch (e) {
      debugPrint("_copyPriorityDatabaseFromAssets: Error copying priority.db: $e");
    }
  }

  Future<void> _copyUserDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/UserMaster.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyUserDatabaseFromAssets: Successfully copied UserMaster.db from assets");

      // Print table structure
      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyUserDatabaseFromAssets: Tables in UserMaster.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyUserDatabaseFromAssets: Error copying UserMaster.db: $e");
    }
  }

  Future<void> _copyCorrFailureTypeDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/CorrfailureCategory.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyCorrFailureTypeDatabaseFromAssets: Successfully copied CorrfailureCategory.db from assets");

      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyCorrFailureTypeDatabaseFromAssets: Tables in CorrfailureCategory.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyCorrFailureTypeDatabaseFromAssets: Error copying CorrfailureCategory.db: $e");
    }
  }

  Future<void> _copyUserStatusDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/userStatus.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyUserStatusDatabaseFromAssets: Successfully copied userStatus.db from assets");

      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyUserStatusDatabaseFromAssets: Tables in userStatus.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyUserStatusDatabaseFromAssets: Error copying userStatus.db: $e");
    }
  }

  Future<void> _copyMaterialMasterDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/materialMaster.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyMaterialMasterDatabaseFromAssets: Successfully copied materialMaster.db from assets");

      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyMaterialMasterDatabaseFromAssets: Tables in materialMaster.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyMaterialMasterDatabaseFromAssets: Error copying materialMaster.db: $e");
    }
  }

  Future<void> _copyRstObjectPartDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/objectPart.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyRstObjectPartDatabaseFromAssets: Successfully copied objectPart.db from assets");

      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyRstObjectPartDatabaseFromAssets: Tables in objectPart.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyRstObjectPartDatabaseFromAssets: Error copying objectPart.db: $e");
    }
  }

  Future<void> _copyRstFaultMasterDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/faultMaster.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyRstFaultMasterDatabaseFromAssets: Successfully copied faultMaster.db from assets");

      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyRstFaultMasterDatabaseFromAssets: Tables in faultMaster.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyRstFaultMasterDatabaseFromAssets: Error copying faultMaster.db: $e");
    }
  }

  Future<void> _copyRstOldRootCauseDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/OldRootCause.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyRstOldRootCauseDatabaseFromAssets: Successfully copied OldRootCause.db from assets");

      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyRstOldRootCauseDatabaseFromAssets: Tables in OldRootCause.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyRstOldRootCauseDatabaseFromAssets: Error copying OldRootCause.db: $e");
    }
  }

  Future<void> _copyRstStoreLocationDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/StoreLocation.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyRstStoreLocationDatabaseFromAssets: Successfully copied StoreLocation.db from assets");

      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyRstStoreLocationDatabaseFromAssets: Tables in StoreLocation.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyRstStoreLocationDatabaseFromAssets: Error copying StoreLocation.db: $e");
    }
  }

  Future<void> _copyFailureCategoryDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/failure_categorytype.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyFailureCategoryDatabaseFromAssets: Successfully copied failure_categorytype.db from assets");

      // Print table structure
      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyFailureCategoryDatabaseFromAssets: Tables in failure_categorytype.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyFailureCategoryDatabaseFromAssets: Error copying failure_categorytype.db: $e");
    }
  }

  Future<void> _copyReasonForDelayDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/reasonForDelay.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyReasonForDelayDatabaseFromAssets: Successfully copied reasonForDelay.db from assets");

      // Print table structure
      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyReasonForDelayDatabaseFromAssets: Tables in reasonForDelay.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyReasonForDelayDatabaseFromAssets: Error copying reasonForDelay.db: $e");
    }
  }

  Future<void> _copyNatureOfWorkDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/natureOfWork.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyNatureOfWorkDatabaseFromAssets: Successfully copied natureOfWork.db from assets");

      // Print table structure
      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyNatureOfWorkDatabaseFromAssets: Tables in natureOfWork.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyNatureOfWorkDatabaseFromAssets: Error copying natureOfWork.db: $e");
    }
  }

  Future<void> _copyFailureCategoryTypeDatabaseFromAssets(String targetPath) async {
    try {
      final byteData = await rootBundle.load('assets/failure_categorytype.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyFailureCategoryTypeDatabaseFromAssets: Successfully copied failure_categorytype.db from assets");

      // Print table structure
      final db = await openDatabase(targetPath);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("_copyFailureCategoryTypeDatabaseFromAssets: Tables in failure_categorytype.db: ${tables.map((t) => t['name']).toList()}");
      await db.close();
    } catch (e) {
      debugPrint("_copyFailureCategoryTypeDatabaseFromAssets: Error copying failure_categorytype.db: $e");
    }
  }




  /// Force re-import all databases from assets
  Future<void> forceImportFromAssets() async {
    try {
      // Close all existing database connections
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      if (_deptDatabase != null) {
        await _deptDatabase!.close();
        _deptDatabase = null;
      }
      if (_funLocDatabase != null) {
        await _funLocDatabase!.close();
        _funLocDatabase = null;
      }
      if (_equipmentDatabase != null) {
        await _equipmentDatabase!.close();
        _equipmentDatabase = null;
      }
      if (_locationDatabase != null) {
        await _locationDatabase!.close();
        _locationDatabase = null;
      }
      if (_measurementDatabase != null) {
        await _measurementDatabase!.close();
        _measurementDatabase = null;
      }
      if (_priorityDatabase != null) {
        await _priorityDatabase!.close();
        _priorityDatabase = null;
      }
      if (_userDatabase != null) {
        await _userDatabase!.close();
        _userDatabase = null;
      }
      if (_reasonForDelayDatabase != null) {
        await _reasonForDelayDatabase!.close();
        _reasonForDelayDatabase = null;
      }
      if (_natureOfWorkDatabase != null) {
        await _natureOfWorkDatabase!.close();
        _natureOfWorkDatabase = null;
      }
      if (_failureCategoryTypeDatabase != null) {
        await _failureCategoryTypeDatabase!.close();
        _failureCategoryTypeDatabase = null;
      }

      final deptPath = join(await getDatabasesPath(), 'dept_data.db');
      final deptFile = File(deptPath);
      if (await deptFile.exists()) {
        await deptFile.delete();
      }
      await _copyDeptDatabaseFromAssets(deptPath);

      final funLocPath = join(await getDatabasesPath(), 'fun_loc_data.db');
      final funLocFile = File(funLocPath);
      if (await funLocFile.exists()) {
        await funLocFile.delete();
      }
      await _copyFunLocDatabaseFromAssets(funLocPath);

      final equipPath = join(await getDatabasesPath(), 'equipment_data.db');
      final equipFile = File(equipPath);
      if (await equipFile.exists()) {
        await equipFile.delete();
      }
      await _copyEquipmentDatabaseFromAssets(equipPath);

      final locPath = join(await getDatabasesPath(), 'location_data.db');
      final locFile = File(locPath);
      if (await locFile.exists()) {
        await locFile.delete();
      }
      await _copyLocationDatabaseFromAssets(locPath);

      final measPath = join(await getDatabasesPath(), 'measurement_data.db');
      final measFile = File(measPath);
      if (await measFile.exists()) {
        await measFile.delete();
      }
      await _copyMeasurementDatabaseFromAssets(measPath);

      final priPath = join(await getDatabasesPath(), 'priority_data.db');
      final priFile = File(priPath);
      if (await priFile.exists()) {
        await priFile.delete();
      }
      await _copyPriorityDatabaseFromAssets(priPath);

      final userPath = join(await getDatabasesPath(), 'user_data.db');
      final userFile = File(userPath);
      if (await userFile.exists()) {
        await userFile.delete();
      }
      await _copyUserDatabaseFromAssets(userPath);

      final reasonForDelayPath = join(await getDatabasesPath(), 'reasonForDelay_data.db');
      final reasonForDelayFile = File(reasonForDelayPath);
      if (await reasonForDelayFile.exists()) {
        await reasonForDelayFile.delete();
      }
      await _copyReasonForDelayDatabaseFromAssets(reasonForDelayPath);

      final natureOfWorkPath = join(await getDatabasesPath(), 'natureOfWork_data.db');
      final natureOfWorkFile = File(natureOfWorkPath);
      if (await natureOfWorkFile.exists()) {
        await natureOfWorkFile.delete();
      }
      await _copyNatureOfWorkDatabaseFromAssets(natureOfWorkPath);

      final failureCategoryTypePath = join(await getDatabasesPath(), 'failure_categorytype_data.db');
      final failureCategoryTypeFile = File(failureCategoryTypePath);
      if (await failureCategoryTypeFile.exists()) {
        await failureCategoryTypeFile.delete();
      }
      await _copyFailureCategoryTypeDatabaseFromAssets(failureCategoryTypePath);

      debugPrint("forceImportFromAssets: All databases successfully re-imported from assets");
    } catch (e) {
      debugPrint("forceImportFromAssets: Error: $e");
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint("_onUpgrade: oldVersion=$oldVersion, newVersion=$newVersion");
    if (oldVersion < 2) {
      await _createLookupTables(db);
    }
    if (oldVersion < 5) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS Departments (
        deptId INTEGER PRIMARY KEY,
        deptName TEXT,
        workCenter TEXT
      )
    ''');
    }
    if (oldVersion < 6) {
      await _createRstTables(db);
    }
    if (oldVersion < 7) {
      // Ensure workCenter column exists even if Departments was created
      // earlier without it (or got corrupted to `deptCode` by the old bug).
      await _ensureDepartmentsSchema(db);
    }
    if (oldVersion < 8) {
      await _createFailureTables(db);
    }
    if (oldVersion < 9) {
      // Add createdDate column to FailureList
      try {
        await db.execute('ALTER TABLE FailureList ADD COLUMN createdDate TEXT');
      } catch (e) {
        debugPrint("Error adding createdDate column: $e");
      }
    }
    if (oldVersion < 10) {
      // Add new RCA-related tables
      debugPrint("_onUpgrade: Creating failure tables for version 10");
      await _createFailureTables(db);
    }
    if (oldVersion < 11) {
      // Add causeId column to RootCauses table
      try {
        await db.execute('ALTER TABLE RootCauses ADD COLUMN causeId INTEGER');
        debugPrint("_onUpgrade: Added causeId column to RootCauses table");
      } catch (e) {
        debugPrint("_onUpgrade: Error adding causeId column to RootCauses: $e");
      }
    }
    if (oldVersion < 12) {
      // Add systemGroup, actionCode, actionDescr columns to ActionTakens table
      try {
        await db.execute('ALTER TABLE ActionTakens ADD COLUMN systemGroup TEXT');
        await db.execute('ALTER TABLE ActionTakens ADD COLUMN actionCode TEXT');
        await db.execute('ALTER TABLE ActionTakens ADD COLUMN actionDescr TEXT');
        debugPrint("_onUpgrade: Added systemGroup, actionCode, actionDescr columns to ActionTakens table");
      } catch (e) {
        debugPrint("_onUpgrade: Error adding columns to ActionTakens: $e");
      }
    }
    if (oldVersion < 13) {
      // Add workCenter, businessArea columns to CauseOfFailures table
      try {
        await db.execute('ALTER TABLE CauseOfFailures ADD COLUMN workCenter TEXT');
        await db.execute('ALTER TABLE CauseOfFailures ADD COLUMN businessArea TEXT');
        debugPrint("_onUpgrade: Added workCenter, businessArea columns to CauseOfFailures table");
      } catch (e) {
        debugPrint("_onUpgrade: Error adding columns to CauseOfFailures: $e");
      }
    }
    if (oldVersion < 14) {
      // Add failureCategoryId column to CauseOfFailures table
      try {
        await db.execute('ALTER TABLE CauseOfFailures ADD COLUMN failureCategoryId INTEGER');
        debugPrint("_onUpgrade: Added failureCategoryId column to CauseOfFailures table");
      } catch (e) {
        debugPrint("_onUpgrade: Error adding failureCategoryId column to CauseOfFailures: $e");
      }
    }
    if (oldVersion < 15) {
      // Recreate RCA tables with correct schema to match database structure
      debugPrint("_onUpgrade: Recreating RCA tables for version 15");

      // Drop old tables
      try {
        await db.execute('DROP TABLE IF EXISTS RootCauses');
        await db.execute('DROP TABLE IF EXISTS CauseOfFailures');
        await db.execute('DROP TABLE IF EXISTS RcaFailureCategories');
        debugPrint("_onUpgrade: Dropped old RCA tables");
      } catch (e) {
        debugPrint("_onUpgrade: Error dropping old RCA tables: $e");
      }

      // Recreate with new schema
      await _createFailureTables(db);
      debugPrint("_onUpgrade: Recreated RCA tables with new schema");
    }
    if (oldVersion < 16) {
      // Add missing columns to FunctionalLocations table
      debugPrint("_onUpgrade: Adding missing columns to FunctionalLocations for version 16");
      try {
        await db.execute('ALTER TABLE FunctionalLocations ADD COLUMN techObjectType TEXT');
        await db.execute('ALTER TABLE FunctionalLocations ADD COLUMN objectKey TEXT');
        await db.execute('ALTER TABLE FunctionalLocations ADD COLUMN subSystem TEXT');
        debugPrint("_onUpgrade: Added techObjectType, objectKey, subSystem columns to FunctionalLocations");
      } catch (e) {
        debugPrint("_onUpgrade: Error adding columns to FunctionalLocations: $e");
      }
    }
    if (oldVersion < 17) {
      // Ensure Stations table exists for offline station list support
      debugPrint("_onUpgrade: Ensuring Stations table exists for version 17");
      await _createLookupTables(db);
    }
    if (oldVersion < 18) {
      // Add new tables for ReasonForDelay, NatureOfWork, and FailureCategoryType
      debugPrint("_onUpgrade: Creating new tables for version 18");
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ReasonForDelay (
          reasonId INTEGER PRIMARY KEY,
          reasonName TEXT,
          description TEXT,
          createdOn TEXT,
          updatedOn TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS NatureOfWork (
          natureOfWorkId INTEGER PRIMARY KEY,
          natureOfWorkName TEXT,
          description TEXT,
          createdOn TEXT,
          updatedOn TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS FailureCategoryType (
          failureCategoryTypeId INTEGER PRIMARY KEY,
          failureCategoryType TEXT,
          description TEXT,
          createdOn TEXT,
          updatedOn TEXT
        )
      ''');
    }
  }

  Future<void> _ensureDepartmentsSchema(Database db) async {
    try {
      final cols = await db.rawQuery("PRAGMA table_info(Departments)");
      final hasWorkCenter = cols.any((c) => c['name'] == 'workCenter');
      if (!hasWorkCenter) {
        debugPrint("_ensureDepartmentsSchema: workCenter column missing, migrating...");
        await db.execute('DROP TABLE IF EXISTS Departments');
        await db.execute('''
        CREATE TABLE Departments (
          deptId INTEGER PRIMARY KEY,
          deptName TEXT,
          workCenter TEXT
        )
      ''');
      }
    } catch (e) {
      debugPrint("_ensureDepartmentsSchema error: $e");
    }
  }

  Future<void> debugDumpDepartments() async {
    final db = await database;
    final cols = await db.rawQuery("PRAGMA table_info(Departments)");
    debugPrint("Departments columns: ${cols.map((c) => c['name']).toList()}");
    final rows = await db.query('Departments', limit: 5);
    debugPrint("Sample rows: $rows");
  }

  Future<void> _createLookupTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Priorities (
        priorityId INTEGER PRIMARY KEY,
        priorityDesc TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS FailureCategories (
        id INTEGER PRIMARY KEY,
        failureCategoryType TEXT,
        orderNo TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS MasterUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        userName TEXT,
        deptId INTEGER,
        deptName TEXT,
        roleId INTEGER,
        roleDescr TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Departments (
        deptId INTEGER PRIMARY KEY,
        deptName TEXT,
        workCenter TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Stations (
        stationId INTEGER PRIMARY KEY,
        stationLabel TEXT,
        stationValue TEXT
      )
    ''');
  }

  Future<void> _createRstTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS RstFailureTypes (
        id INTEGER PRIMARY KEY,
        failureType TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS RstObjectParts (
        id INTEGER PRIMARY KEY,
        objectCodeDesc TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS RstMaterials (
        materialRowId INTEGER PRIMARY KEY,
        material TEXT,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS RstStorageLocations (
        value TEXT PRIMARY KEY,
        label TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS RstTrainStatuses (
        statusId INTEGER PRIMARY KEY,
        statusDescr TEXT
      )
    ''');
  }

  Future<void> _createFailureTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS FailureList (
        id INTEGER PRIMARY KEY,
        failureNo TEXT,
        notificationCode TEXT,
        jobCardId TEXT,
        failureDescription TEXT,
        functionLocationId INTEGER,
        equipmentId INTEGER,
        functionalLocation TEXT,
        equipmentDescription TEXT,
        statusName TEXT,
        statusDescription TEXT,
        failureOccuranceDateTime TEXT,
        assignedUserId INTEGER,
        occRequestStatus TEXT,
        otherRequestFrom TEXT,
        locationName TEXT,
        remarks TEXT,
        creationType TEXT,
        priority TEXT,
        departmentName TEXT,
        subLocation TEXT,
        trainId TEXT,
        system TEXT,
        actualFailureCompletedDateTime TEXT,
        isTripAffected INTEGER,
        tripDelayUpline INTEGER,
        tripDelayDownline INTEGER,
        tripCancel INTEGER,
        isTrainReplace INTEGER,
        trainReplace INTEGER,
        isTrainDeboarded INTEGER,
        trainDeboarded INTEGER,
        numberOfPassengerAffected INTEGER,
        isPassengerAffected INTEGER,
        trappedDuration INTEGER,
        rescusedDuration INTEGER,
        trainDelayInMin INTEGER,
        noOfTranWithdrawal INTEGER,
        failureReportedby TEXT,
        failureCategoryTypeText TEXT,
        failureRectificationDetails TEXT,
        carriedOutRemarks TEXT,
        departmentId_1 INTEGER,
        locationId INTEGER,
        funcationLocationId INTEGER,
        syncStatus TEXT DEFAULT 'online',
        lastSyncedAt TEXT,
        failureType TEXT,
        getImageBefor TEXT,
        createdDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS PendingFailureSubmissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payload TEXT NOT NULL,
        failureType TEXT,
        createdAt TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        syncError TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS NotificationTypes (
        id INTEGER PRIMARY KEY,
        notificationType TEXT,
        description TEXT,
        createdOn TEXT,
        updatedOn TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS RootCauses (
        RootCauseId INTEGER PRIMARY KEY,
        RootCause TEXT,
        CauseOfFailureId INTEGER,
        FailureCategoryId INTEGER,
        Systems TEXT,
        WorkCenter TEXT,
        BusinessArea INTEGER,
        CreatedOn TEXT,
        CreatedBy INTEGER,
        IsActive INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ActionTakens (
        id INTEGER PRIMARY KEY,
        actionTaken TEXT,
        description TEXT,
        systemGroup TEXT,
        actionCode TEXT,
        actionDescr TEXT,
        createdOn TEXT,
        updatedOn TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS CauseOfFailures (
        CauseOfFailureId INTEGER PRIMARY KEY,
        Cause TEXT,
        FailureCategoryId INTEGER,
        Systems TEXT,
        WorkCenter TEXT,
        BusinessArea INTEGER,
        CreatedOn TEXT,
        CreatedBy INTEGER,
        IsActive INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS RcaFailureCategories (
        FailureCategoryId INTEGER PRIMARY KEY,
        Systems TEXT,
        FailureCategory TEXT,
        WorkCenter TEXT,
        BusinessArea INTEGER,
        CreatedOn TEXT,
        CreatedBy INTEGER,
        IsActive INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS MeasurementPoints (
        measId INTEGER PRIMARY KEY,
        measPoint TEXT,
        measPointDesc TEXT,
        measRangeUnit TEXT,
        internalCharNo TEXT,
        targetValue TEXT,
        objectNo TEXT,
        createdOn TEXT,
        updatedOn TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ReasonForDelay (
        reasonId INTEGER PRIMARY KEY,
        reasonName TEXT,
        description TEXT,
        createdOn TEXT,
        updatedOn TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS NatureOfWork (
        natureOfWorkId INTEGER PRIMARY KEY,
        natureOfWorkName TEXT,
        description TEXT,
        createdOn TEXT,
        updatedOn TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS FailureCategoryType (
        failureCategoryTypeId INTEGER PRIMARY KEY,
        failureCategoryType TEXT,
        description TEXT,
        createdOn TEXT,
        updatedOn TEXT
      )
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS SyncMeta (
        action TEXT PRIMARY KEY,
        lastCreatedOn TEXT,
        lastUpdatedOn TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Locations (
        locationTypeCode TEXT PRIMARY KEY,
        locationTypeId INTEGER,
        locationTypeName TEXT,
        locationName TEXT,
        plantId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS FunctionalLocations (
        funcLocation TEXT PRIMARY KEY,
        funcLocId INTEGER,
        funcDescription TEXT,
        funcLocationName TEXT,
        location TEXT,
        planningPlant TEXT,
        workCenter TEXT,
        objectNumber TEXT,
        techObjectType TEXT,
        objectKey TEXT,
        subSystem TEXT,
        createdOn TEXT,
        updatedOn TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS Equipments (
        equipId INTEGER PRIMARY KEY,
        equipNo TEXT,
        equipDesc TEXT,
        equipmentName TEXT,
        functionalLocation TEXT,
        location TEXT,
        planningPlant TEXT,
        createdOn TEXT,
        updatedOn TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS MeasurementPoints (
        measId INTEGER PRIMARY KEY,
        measPoint TEXT,
        measPointDesc TEXT,
        measRangeUnit TEXT,
        internalCharNo TEXT,
        targetValue TEXT,
        objectNo TEXT,
        createdOn TEXT,
        updatedOn TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS FailureList (
        id INTEGER PRIMARY KEY,
        failureNo TEXT,
        notificationCode TEXT,
        jobCardId TEXT,
        failureDescription TEXT,
        functionLocationId INTEGER,
        equipmentId INTEGER,
        functionalLocation TEXT,
        equipmentDescription TEXT,
        statusName TEXT,
        statusDescription TEXT,
        failureOccuranceDateTime TEXT,
        assignedUserId INTEGER,
        occRequestStatus TEXT,
        otherRequestFrom TEXT,
        locationName TEXT,
        remarks TEXT,
        creationType TEXT,
        priority TEXT,
        departmentName TEXT,
        subLocation TEXT,
        trainId TEXT,
        system TEXT,
        actualFailureCompletedDateTime TEXT,
        isTripAffected INTEGER,
        tripDelayUpline INTEGER,
        tripDelayDownline INTEGER,
        tripCancel INTEGER,
        isTrainReplace INTEGER,
        trainReplace INTEGER,
        isTrainDeboarded INTEGER,
        trainDeboarded INTEGER,
        numberOfPassengerAffected INTEGER,
        isPassengerAffected INTEGER,
        trappedDuration INTEGER,
        rescusedDuration INTEGER,
        trainDelayInMin INTEGER,
        noOfTranWithdrawal INTEGER,
        failureReportedby TEXT,
        failureCategoryTypeText TEXT,
        failureRectificationDetails TEXT,
        carriedOutRemarks TEXT,
        departmentId_1 INTEGER,
        locationId INTEGER,
        funcationLocationId INTEGER,
        syncStatus TEXT DEFAULT 'online',
        lastSyncedAt TEXT,
        failureType TEXT,
        getImageBefor TEXT,
        createdDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS PendingFailureSubmissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payload TEXT NOT NULL,
        failureType TEXT,
        createdAt TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        syncError TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS AppSettings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await _createLookupTables(db);
    await _createRstTables(db);
  }

  Future<void> clearAssetTables() async {
    final db = await database;
    await db.delete('Locations');
    await db.delete('FunctionalLocations');
    await db.delete('Equipments');
    await db.delete('MeasurementPoints');
    await db.delete('SyncMeta');
    debugPrint('clearAssetTables: Successfully cleared Locations, FunctionalLocations, Equipments, MeasurementPoints, and SyncMeta.');
  }

  // Insert Operations
  Future<void> insertLocations(List<LocationModel> locations) async {
    final db = await database;
    await db.delete('Locations');
    Batch batch = db.batch();
    for (var loc in locations) {
      batch.insert('Locations', loc.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertFunctionalLocations(List<FunctionalLocationModel> funcLocs) async {
    final db = await database;
    Batch batch = db.batch();
    for (var loc in funcLocs) {
      batch.insert('FunctionalLocations', loc.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertEquipments(List<EquipmentModel> equips) async {
    final db = await database;
    Batch batch = db.batch();
    for (var eq in equips) {
      batch.insert('Equipments', eq.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertMeasurementPoints(List<MeasurementPointModel> points) async {
    final db = await database;
    try {
      await db.delete('MeasurementPoints');
    } catch (e) {
      debugPrint("insertMeasurementPoints: Table might not exist, creating it: $e");
      await _createFailureTables(db);
    }
    Batch batch = db.batch();
    for (var pt in points) {
      batch.insert('MeasurementPoints', pt.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    debugPrint("insertMeasurementPoints: Inserted ${points.length} measurement points");
  }

  // Fetch Operations
  Future<List<LocationModel>> getLocations() async {
    try {
      final db = await locationDatabase;
      debugPrint("getLocations: Opening location database");

      // Check available tables
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("getLocations: Available tables: ${tables.map((t) => t['name']).toList()}");

      // Use locationMaster table from asset database
      String query = 'SELECT * FROM locationMaster';
      final results = await db.rawQuery(query);
      debugPrint("getLocations: Found ${results.length} locations");
      if (results.isNotEmpty) {
        debugPrint("getLocations: First row columns: ${results.first.keys.toList()}");
        debugPrint("getLocations: First location: ${results.first}");
      }
      return results.map((e) => LocationModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("getLocations error: $e");
      return [];
    }
  }

  Future<List<FunctionalLocationModel>> getFunctionalLocations() async {
    // Always use fun_loc database for functional locations
    return await getFunctionalLocationsFromFunLoc();
  }

  Future<List<FunctionalLocationModel>> getFunctionalLocationsFromFunLoc() async {
    try {
      final funLocDb = await funLocDatabase;
      const batchSize = 1000;
      final List<FunctionalLocationModel> allResults = [];

      // First, get the actual table names from the database
      final tables = await funLocDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      );
      debugPrint("getFunctionalLocationsFromFunLoc: Available tables: ${tables.map((t) => t['name']).toList()}");

      // Filter out system tables
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) {
        debugPrint("getFunctionalLocationsFromFunLoc: No tables found in fun_loc database");
        return [];
      }

      // Try each table
      for (var tableName in tableNames) {
        try {
          debugPrint("getFunctionalLocationsFromFunLoc: Trying table '$tableName'");

          // Use the exact table name with quotes to handle spaces and special characters
          String baseQuery = 'SELECT * FROM "$tableName"';
          int offset = 0;

          while (true) {
            final results = await funLocDb.rawQuery('$baseQuery LIMIT $batchSize OFFSET $offset');
            if (results.isEmpty) break;

            debugPrint("getFunctionalLocationsFromFunLoc: Found ${results.length} rows in '$tableName'");

            // Map the results to FunctionalLocationModel
            for (var row in results) {
              try {
                // Print first row to debug column names
                if (allResults.isEmpty) {
                  debugPrint("getFunctionalLocationsFromFunLoc: First row columns: ${row.keys.toList()}");
                  debugPrint("getFunctionalLocationsFromFunLoc: First row data: $row");
                }
                final model = FunctionalLocationModel.fromJson(row);
                allResults.add(model);
              } catch (e) {
                debugPrint("getFunctionalLocationsFromFunLoc: Error mapping row: $e");
              }
            }

            if (results.length < batchSize) break;
            offset += batchSize;
          }

          if (allResults.isNotEmpty) {
            debugPrint("getFunctionalLocationsFromFunLoc: Successfully loaded ${allResults.length} functional locations from table '$tableName'");
            break;
          }
        } catch (e) {
          debugPrint("getFunctionalLocationsFromFunLoc: Error querying table '$tableName': $e");
          continue;
        }
      }

      return allResults;
    } catch (e) {
      debugPrint("getFunctionalLocationsFromFunLoc: Error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredFunctionalLocations({String? locationCode, String? workCenter, String? searchTerm, int limit = 100, int offset = 0}) async {
    final db = await database;
    String query = 'SELECT funcLocation, funcLocId, funcLocationName, funcDescription, location, objectNumber, workCenter, planningPlant FROM FunctionalLocations WHERE 1=1';
    List<dynamic> args = [];
    if (locationCode != null && locationCode.isNotEmpty) {
      query += ' AND UPPER(location) = ?';
      args.add(locationCode.toUpperCase());
    }
    if (workCenter != null && workCenter.isNotEmpty) {
      query += ' AND UPPER(workCenter) = ?';
      args.add(workCenter.toUpperCase());
    }
    if (searchTerm != null && searchTerm.isNotEmpty) {
      query += ' AND (UPPER(funcLocation) LIKE ? OR UPPER(funcLocationName) LIKE ? OR UPPER(funcDescription) LIKE ?)';
      final searchPattern = '%${searchTerm.toUpperCase()}%';
      args.addAll([searchPattern, searchPattern, searchPattern]);
    }

    query += ' LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);

    final results = await db.rawQuery(query, args);
    return results;
  }

  Future<Map<String, dynamic>?> getFunctionalLocationById(int funcLocId) async {
    final db = await funLocDatabase;
    try {
      // Find the first user table dynamically
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => !name.startsWith('sqlite_') && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) {
        debugPrint("getFunctionalLocationById: No tables found in fun_loc database");
        return null;
      }

      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final results = await db.rawQuery(
          'SELECT * FROM $escapedTableName WHERE FuncLocId = ? LIMIT 1',
          [funcLocId]
      );

      if (results.isNotEmpty) {
        return results.first;
      }
      return null;
    } catch (e) {
      debugPrint('getFunctionalLocationById error: $e');
      return null;
    }
  }

  Future<List<EquipmentModel>> getEquipments() async {
    try {
      final db = await equipmentDatabase;
      debugPrint("getEquipments: Opening equipment database");

      // Check available tables
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("getEquipments: Available tables: ${tables.map((t) => t['name']).toList()}");

      const batchSize = 1000;
      // Use equipmentMaster table from asset database
      String baseQuery = 'SELECT * FROM equipmentMaster';
      List<dynamic> baseArgs = [];
      final List<Map<String, dynamic>> allRawResults = [];
      int offset = 0;
      while (true) {
        final results = await db.rawQuery('$baseQuery LIMIT $batchSize OFFSET $offset', baseArgs);
        if (results.isEmpty) break;
        allRawResults.addAll(results);
        if (results.length < batchSize) break;
        offset += batchSize;
      }

      debugPrint("getEquipments: Found ${allRawResults.length} equipments");
      if (allRawResults.isNotEmpty) {
        debugPrint("getEquipments: First row columns: ${allRawResults.first.keys.toList()}");
        debugPrint("getEquipments: First row data: ${allRawResults.first}");
      }

      // Map column names to match model expectations
      final List<EquipmentModel> allResults = allRawResults.map((row) {
        return EquipmentModel.fromJson({
          'equipId': row['EquipId'] ?? row['equipId'],
          'equipNo': row['EquipNo']?.toString() ?? row['equipNo']?.toString() ?? '',
          'equipDesc': row['EquipDesc']?.toString() ?? row['equipDesc']?.toString() ?? '',
          'equipmentName': row['EquipmentName']?.toString() ?? row['equipmentName']?.toString() ?? '',
          'functionalLocation': row['FunctionalLocation']?.toString() ?? row['functionalLocation']?.toString() ?? '',
          'location': row['Location']?.toString() ?? row['location']?.toString() ?? '',
          'planningPlant': row['PlanningPlant']?.toString() ?? row['planningPlant']?.toString() ?? '',
        });
      }).toList();

      if (allResults.isNotEmpty) {
        debugPrint("getEquipments: First mapped equipment: ${allResults.first.toJson()}");
      }

      return allResults;
    } catch (e) {
      debugPrint("getEquipments error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredEquipments({String? locationCode, String? funcLocCode, String? searchTerm, int limit = 100, int offset = 0}) async {
    final db = await database;
    String query = 'SELECT equipId, equipmentName, functionalLocation, location, equipNo, equipDesc, planningPlant FROM Equipments WHERE 1=1';
    List<dynamic> args = [];
    if (locationCode != null && locationCode.isNotEmpty) {
      query += ' AND UPPER(location) = ?';
      args.add(locationCode.toUpperCase());
    }
    if (funcLocCode != null && funcLocCode.isNotEmpty) {
      query += ' AND UPPER(functionalLocation) = ?';
      args.add(funcLocCode.toUpperCase());
    }
    if (searchTerm != null && searchTerm.isNotEmpty) {
      query += ' AND (UPPER(equipNo) LIKE ? OR UPPER(equipDesc) LIKE ? OR UPPER(equipmentName) LIKE ?)';
      final searchPattern = '%${searchTerm.toUpperCase()}%';
      args.addAll([searchPattern, searchPattern, searchPattern]);
    }

    query += ' LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);

    final results = await db.rawQuery(query, args);
    return results;
  }

  Future<List<MeasurementPointModel>> getMeasurementPoints() async {
    try {
      final db = await measurementDatabase;
      debugPrint("getMeasurementPoints: Opening measurement database");

      // Check available tables
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("getMeasurementPoints: Available tables: ${tables.map((t) => t['name']).toList()}");

      // Check table schema
      final tableInfo = await db.rawQuery("PRAGMA table_info(measurementPointMaster)");
      debugPrint("getMeasurementPoints: measurementPointMaster columns: ${tableInfo.map((t) => t['name']).toList()}");

      const batchSize = 1000;
      // Use measurementPointMaster table from asset database
      String baseQuery = 'SELECT * FROM measurementPointMaster';
      List<dynamic> baseArgs = [];
      final List<MeasurementPointModel> allResults = [];
      int offset = 0;
      while (true) {
        final results = await db.rawQuery('$baseQuery LIMIT $batchSize OFFSET $offset', baseArgs);
        if (results.isEmpty) break;
        if (results.isNotEmpty && allResults.isEmpty) {
          debugPrint("getMeasurementPoints: First row columns: ${results.first.keys.toList()}");
          debugPrint("getMeasurementPoints: First row data: ${results.first}");
        }
        allResults.addAll(results.map((e) => MeasurementPointModel.fromJson(e)));
        if (results.length < batchSize) break;
        offset += batchSize;
      }
      debugPrint("getMeasurementPoints: Found ${allResults.length} measurement points");
      if (allResults.isNotEmpty) {
        debugPrint("getMeasurementPoints: First measurement point: ${allResults.first.toJson()}");
        debugPrint("getMeasurementPoints: Sample objectNo values from assets: ${allResults.take(5).map((e) => e.objectNo).toList()}");
      }
      return allResults;
    } catch (e) {
      debugPrint("getMeasurementPoints error: $e");
      return [];
    }
  }

  Future<List<MeasurementPointModel>> getMeasurementPointsFromAssetsFiltered(String objectNumber) async {
    try {
      final db = await measurementDatabase;
      debugPrint("getMeasurementPointsFromAssetsFiltered: Querying assets database with filter: $objectNumber");

      // Check table schema
      final tableInfo = await db.rawQuery("PRAGMA table_info(measurementPointMaster)");
      debugPrint("getMeasurementPointsFromAssetsFiltered: measurementPointMaster columns: ${tableInfo.map((t) => t['name']).toList()}");

      // First, show sample ObjectNo values to understand the data
      final sampleResults = await db.rawQuery('SELECT ObjectNo FROM measurementPointMaster LIMIT 10');
      debugPrint("getMeasurementPointsFromAssetsFiltered: Sample ObjectNo values in assets: ${sampleResults.map((e) => e['ObjectNo']).toList()}");

      // Query with ObjectNo filter - try both ObjectNo and objectNo column names
      String query = 'SELECT * FROM measurementPointMaster WHERE ObjectNo = ?';
      List<dynamic> args = [objectNumber];

      final results = await db.rawQuery(query, args);
      debugPrint("getMeasurementPointsFromAssetsFiltered: Found ${results.length} measurement points from assets");

      if (results.isEmpty) {
        // Try with lowercase objectNo
        query = 'SELECT * FROM measurementPointMaster WHERE objectNo = ?';
        final results2 = await db.rawQuery(query, args);
        debugPrint("getMeasurementPointsFromAssetsFiltered: Found ${results2.length} measurement points with lowercase objectNo");
        if (results2.isNotEmpty) {
          debugPrint("getMeasurementPointsFromAssetsFiltered: First row data: ${results2.first}");
          return results2.map((e) => MeasurementPointModel.fromJson(e)).toList();
        }
      } else {
        debugPrint("getMeasurementPointsFromAssetsFiltered: First row data: ${results.first}");
      }

      return results.map((e) => MeasurementPointModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("getMeasurementPointsFromAssetsFiltered error: $e");
      return [];
    }
  }

  Future<List<MeasurementPointModel>> getMeasurementPointsFromLocal({String? objectNumber}) async {
    try {
      final db = await database;
      debugPrint("getMeasurementPointsFromLocal: Opening local database${objectNumber != null ? ' with filter: $objectNumber' : ''}");

      // Check table schema
      final tableInfo = await db.rawQuery("PRAGMA table_info(MeasurementPoints)");
      debugPrint("getMeasurementPointsFromLocal: MeasurementPoints columns: ${tableInfo.map((t) => t['name']).toList()}");

      String query = 'SELECT * FROM MeasurementPoints';
      List<dynamic> args = [];

      // If objectNumber is provided, filter directly in SQL
      if (objectNumber != null && objectNumber.isNotEmpty) {
        query += ' WHERE ObjectNo = ?';
        args.add(objectNumber);
      }

      final results = await db.rawQuery(query, args);
      debugPrint("getMeasurementPointsFromLocal: Found ${results.length} measurement points from local DB");
      if (results.isNotEmpty) {
        debugPrint("getMeasurementPointsFromLocal: First row columns: ${results.first.keys.toList()}");
        debugPrint("getMeasurementPointsFromLocal: First row data: ${results.first}");
        if (objectNumber == null) {
          debugPrint("getMeasurementPointsFromLocal: Sample objectNo values: ${results.take(5).map((e) => e['ObjectNo']).toList()}");
        }
      } else {
        // If no results with filter, show sample data to understand the values
        if (objectNumber != null) {
          final sampleResults = await db.rawQuery('SELECT ObjectNo FROM MeasurementPoints LIMIT 5');
          debugPrint("getMeasurementPointsFromLocal: No match for '$objectNumber'. Sample ObjectNo values in DB: ${sampleResults.map((e) => e['ObjectNo']).toList()}");
        }
      }

      return results.map((e) => MeasurementPointModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("getMeasurementPointsFromLocal error: $e");
      return [];
    }
  }

  Future<List<NotificationTypeModel>> getNotificationTypes() async {
    try {
      final db = await notificationTypeDatabase;
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT IN ('android_metadata','sqlite_sequence')");
      if (tables.isEmpty) return [];
      final tableName = tables.first['name'] as String; // "notificationType (1)"

      const batchSize = 1000;
      final List<NotificationTypeModel> allResults = [];
      int offset = 0;
      while (true) {
        // quotes are required because the name contains a space and parentheses
        final results = await db.rawQuery(
            'SELECT * FROM "$tableName" LIMIT $batchSize OFFSET $offset');
        if (results.isEmpty) break;
        if (offset == 0) debugPrint('getNotificationTypes: columns ${results.first.keys.toList()}');
        allResults.addAll(results.map((e) => NotificationTypeModel.fromJson(e)));
        if (results.length < batchSize) break;
        offset += batchSize;
      }
      return allResults;
    } catch (e) {
      debugPrint("getNotificationTypes error: $e");
      return [];
    }
  }
  Future<List<RootCauseModel>> getRootCauses() async {
    try {
      final db = await rootCauseDatabase;
      debugPrint("getRootCauses: Opening root cause database");

      // Check available tables
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("getRootCauses: Available tables: ${tables.map((t) => t['name']).toList()}");

      // Check table columns
      final columns = await db.rawQuery("PRAGMA table_info(rootCause)");
      debugPrint("getRootCauses: Table columns: ${columns.map((c) => c['name']).toList()}");

      const batchSize = 1000;
      String baseQuery = 'SELECT * FROM rootCause';
      List<dynamic> baseArgs = [];
      final List<RootCauseModel> allResults = [];
      int offset = 0;
      while (true) {
        final results = await db.rawQuery('$baseQuery LIMIT $batchSize OFFSET $offset', baseArgs);
        if (results.isEmpty) break;
        if (results.isNotEmpty) {
          debugPrint("getRootCauses: First row columns: ${results.first.keys.toList()}");
          debugPrint("getRootCauses: First row data: ${results.first}");
        }
        allResults.addAll(results.map((e) => RootCauseModel.fromJson(e)));
        if (results.length < batchSize) break;
        offset += batchSize;
      }
      debugPrint("getRootCauses: Found ${allResults.length} root causes");
      return allResults;
    } catch (e) {
      debugPrint("getRootCauses error: $e");
      return [];
    }
  }

  Future<List<ActionTakenModel>> getActionTakens() async {
    try {
      final db = await actionTakenDatabase;
      debugPrint("getActionTakens: Opening action taken database");

      // Check available tables
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("getActionTakens: Available tables: ${tables.map((t) => t['name']).toList()}");

      // Check table columns
      final columns = await db.rawQuery("PRAGMA table_info(actionTaken)");
      debugPrint("getActionTakens: Table columns: ${columns.map((c) => c['name']).toList()}");

      const batchSize = 1000;
      String baseQuery = 'SELECT * FROM actionTaken';
      List<dynamic> baseArgs = [];
      final List<ActionTakenModel> allResults = [];
      int offset = 0;
      while (true) {
        final results = await db.rawQuery('$baseQuery LIMIT $batchSize OFFSET $offset', baseArgs);
        if (results.isEmpty) break;
        if (results.isNotEmpty) {
          debugPrint("getActionTakens: First row columns: ${results.first.keys.toList()}");
          debugPrint("getActionTakens: First row data: ${results.first}");
        }
        allResults.addAll(results.map((e) => ActionTakenModel.fromJson(e)));
        if (results.length < batchSize) break;
        offset += batchSize;
      }
      debugPrint("getActionTakens: Found ${allResults.length} action takens");
      return allResults;
    } catch (e) {
      debugPrint("getActionTakens error: $e");
      return [];
    }
  }

  Future<List<CauseOfFailureModel>> getCauseOfFailures() async {
    try {
      final db = await causeOfFailureDatabase;
      debugPrint("getCauseOfFailures: Opening cause of failure database");

      // Check available tables
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("getCauseOfFailures: Available tables: ${tables.map((t) => t['name']).toList()}");

      // Check table columns
      final columns = await db.rawQuery("PRAGMA table_info(causeOfFailure)");
      debugPrint("getCauseOfFailures: Table columns: ${columns.map((c) => c['name']).toList()}");

      const batchSize = 1000;
      String baseQuery = 'SELECT * FROM causeOfFailure';
      List<dynamic> baseArgs = [];
      final List<CauseOfFailureModel> allResults = [];
      int offset = 0;
      while (true) {
        final results = await db.rawQuery('$baseQuery LIMIT $batchSize OFFSET $offset', baseArgs);
        if (results.isEmpty) break;
        if (results.isNotEmpty) {
          debugPrint("getCauseOfFailures: First row columns: ${results.first.keys.toList()}");
          debugPrint("getCauseOfFailures: First row data: ${results.first}");
        }
        allResults.addAll(results.map((e) => CauseOfFailureModel.fromJson(e)));
        if (results.length < batchSize) break;
        offset += batchSize;
      }
      debugPrint("getCauseOfFailures: Found ${allResults.length} cause of failures");
      return allResults;
    } catch (e) {
      debugPrint("getCauseOfFailures error: $e");
      return [];
    }
  }

  Future<List<RcaFailureCategoryModel>> getRcaFailureCategories() async {
    debugPrint("getRcaFailureCategories: STARTING");
    try {
      final db = await rcaFailureCategoryDatabase;
      debugPrint("getRcaFailureCategories: Opening RCA failure category database");

      // Check available tables
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("getRcaFailureCategories: Available tables: ${tables.map((t) => t['name']).toList()}");

      // Determine the correct table name
      String tableName = 'NewFailureCategory';
      final tableNames = tables.map((t) => t['name'].toString()).toList();
      if (!tableNames.contains(tableName)) {
        // Try alternative table names
        if (tableNames.contains('RcaFailureCategories')) {
          tableName = 'RcaFailureCategories';
        } else if (tableNames.contains('failureCategory')) {
          tableName = 'failureCategory';
        } else if (tableNames.contains('FailureCategory')) {
          tableName = 'FailureCategory';
        } else {
          debugPrint("getRcaFailureCategories: No suitable table found, returning empty list");
          return [];
        }
      }
      debugPrint("getRcaFailureCategories: Using table '$tableName'");

      // Check table columns
      final columns = await db.rawQuery("PRAGMA table_info($tableName)");
      debugPrint("getRcaFailureCategories: Table columns: ${columns.map((c) => c['name']).toList()}");

      const batchSize = 1000;
      String baseQuery = 'SELECT * FROM $tableName';
      List<dynamic> baseArgs = [];
      final List<RcaFailureCategoryModel> allResults = [];
      int offset = 0;
      while (true) {
        final results = await db.rawQuery('$baseQuery LIMIT $batchSize OFFSET $offset', baseArgs);
        if (results.isEmpty) break;
        if (results.isNotEmpty && offset == 0) {
          debugPrint("getRcaFailureCategories: First row columns: ${results.first.keys.toList()}");
          debugPrint("getRcaFailureCategories: First row data: ${results.first}");
        }
        allResults.addAll(results.map((e) => RcaFailureCategoryModel.fromJson(e)));
        if (results.length < batchSize) break;
        offset += batchSize;
      }
      debugPrint("getRcaFailureCategories: Found ${allResults.length} RCA failure categories");
      if (allResults.isNotEmpty) {
        debugPrint("getRcaFailureCategories: First mapped item: ${allResults.first.toJson()}");
      }
      return allResults;
    } catch (e) {
      debugPrint("getRcaFailureCategories error: $e");
      return [];
    }
  }

  Future<void> insertPriorities(List<PriorityModel> items) async {
    final db = await priorityDatabase;
    final batch = db.batch();
    await db.delete('Priorities');
    for (final item in items) {
      batch.insert('Priorities', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertFailureCategories(List<FailureCategoryModel> items) async {
    final db = await database;
    final batch = db.batch();
    await db.delete('FailureCategories');
    for (final item in items) {
      batch.insert('FailureCategories', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertNotificationTypes(List<NotificationTypeModel> items) async {
    final db = await database;
    final batch = db.batch();
    try {
      await db.delete('NotificationTypes');
    } catch (e) {
      debugPrint("insertNotificationTypes: Table might not exist, creating it: $e");
      await _createFailureTables(db);
    }
    for (final item in items) {
      batch.insert('NotificationTypes', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertRootCauses(List<RootCauseModel> items) async {
    final db = await database;
    final batch = db.batch();
    try {
      await db.delete('RootCauses');
    } catch (e) {
      debugPrint("insertRootCauses: Table might not exist, creating it: $e");
      await _createFailureTables(db);
    }
    for (final item in items) {
      batch.insert('RootCauses', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertActionTakens(List<ActionTakenModel> items) async {
    final db = await database;
    final batch = db.batch();
    try {
      await db.delete('ActionTakens');
    } catch (e) {
      debugPrint("insertActionTakens: Table might not exist, creating it: $e");
      await _createFailureTables(db);
    }
    for (final item in items) {
      batch.insert('ActionTakens', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertCauseOfFailures(List<CauseOfFailureModel> items) async {
    final db = await database;
    final batch = db.batch();
    try {
      await db.delete('CauseOfFailures');
    } catch (e) {
      debugPrint("insertCauseOfFailures: Table might not exist, creating it: $e");
      await _createFailureTables(db);
    }
    for (final item in items) {
      batch.insert('CauseOfFailures', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertRcaFailureCategories(List<RcaFailureCategoryModel> items) async {
    final db = await database;
    final batch = db.batch();
    try {
      await db.delete('RcaFailureCategories');
    } catch (e) {
      debugPrint("insertRcaFailureCategories: Table might not exist, creating it: $e");
      await _createFailureTables(db);
    }
    for (final item in items) {
      batch.insert('RcaFailureCategories', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertReasonsForDelay(List<ReasonForDelayModel> items) async {
    final db = await database;
    final batch = db.batch();
    try {
      await db.delete('ReasonForDelay');
    } catch (e) {
      debugPrint("insertReasonsForDelay: Table might not exist, creating it: $e");
      await _createFailureTables(db);
    }
    for (final item in items) {
      batch.insert('ReasonForDelay', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertNatureOfWorks(List<NatureOfWorkModel> items) async {
    final db = await database;
    final batch = db.batch();
    try {
      await db.delete('NatureOfWork');
    } catch (e) {
      debugPrint("insertNatureOfWorks: Table might not exist, creating it: $e");
      await _createFailureTables(db);
    }
    for (final item in items) {
      batch.insert('NatureOfWork', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertFailureCategoryTypes(List<FailureCategoryTypeModel> items) async {
    final db = await database;
    final batch = db.batch();
    try {
      await db.delete('FailureCategoryType');
    } catch (e) {
      debugPrint("insertFailureCategoryTypes: Table might not exist, creating it: $e");
      await _createFailureTables(db);
    }
    for (final item in items) {
      batch.insert('FailureCategoryType', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<RcaFailureCategoryModel>> getRcaFailureCategoriesFromLocal() async {
    final db = await database;
    try {
      debugPrint("getRcaFailureCategoriesFromLocal: Opening local database for RCA failure categories");

      // Check table schema
      final tableInfo = await db.rawQuery("PRAGMA table_info(RcaFailureCategories)");
      debugPrint("getRcaFailureCategoriesFromLocal: RcaFailureCategories columns: ${tableInfo.map((t) => t['name']).toList()}");

      final results = await db.query('RcaFailureCategories');
      debugPrint("getRcaFailureCategoriesFromLocal: Retrieved ${results.length} RCA failure categories from local DB");
      if (results.isNotEmpty) {
        debugPrint("getRcaFailureCategoriesFromLocal: First row columns: ${results.first.keys.toList()}");
        debugPrint("getRcaFailureCategoriesFromLocal: First row data: ${results.first}");
      }
      return results.map((e) => RcaFailureCategoryModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getRcaFailureCategoriesFromLocal error: $e');
      return [];
    }
  }

  Future<void> insertMasterUsers(List<MasterUserModel> items) async {
    final db = await userDatabase;
    final batch = db.batch();
    await db.delete('MasterUsers');
    for (final item in items) {
      batch.insert('MasterUsers', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertDepartments(List<DepartmentModel> items) async {
    final db = await database;
    try {
      final batch = db.batch();
      await db.delete('Departments');
      for (final item in items) {
        batch.insert('Departments', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      debugPrint("insertDepartments: Successfully inserted ${items.length} departments");
    } catch (e) {
      debugPrint("insertDepartments error: $e. Recreating Departments table with correct schema...");
      await db.execute('DROP TABLE IF EXISTS Departments');
      await db.execute('''
      CREATE TABLE Departments (
        deptId INTEGER PRIMARY KEY,
        deptName TEXT,
        workCenter TEXT
      )
    ''');

      final batch = db.batch();
      for (final item in items) {
        batch.insert('Departments', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      debugPrint("insertDepartments: Recovered and inserted ${items.length} departments");
    }
  }

  Future<List<PriorityModel>> getPriorities() async {
    final db = await priorityDatabase;
    try {
      // Check available tables
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("getPriorities: Available tables: ${tables.map((t) => t['name']).toList()}");

      // Use priorityMaster table from asset database
      final results = await db.query('priorityMaster');
      debugPrint("getPriorities: Found ${results.length} priorities");
      if (results.isNotEmpty) {
        debugPrint("getPriorities: First row columns: ${results.first.keys.toList()}");
        debugPrint("getPriorities: First row data: ${results.first}");
      }
      return results.map((e) => PriorityModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getPriorities error: $e');
      return [];
    }
  }

  Future<List<DepartmentModel>> getDepartments() async {
    final db = await deptDatabase;
    try {
      debugPrint("getDepartments: Opening department database (dept.db)");
      // Check available tables
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("getDepartments: Available tables: ${tables.map((t) => t['name']).toList()}");

      // Try to find department table - could be Departments, departmentMaster, or similar
      String tableName = 'deptMaster';
      if (!tables.any((t) => t['name'] == tableName)) {
        tableName = 'Departments';
      }
      if (!tables.any((t) => t['name'] == tableName)) {
        tableName = 'departmentMaster';
      }
      if (!tables.any((t) => t['name'] == tableName)) {
        tableName = 'Department';
      }

      // If still not found, try to find any table containing 'dept' in the name
      if (!tables.any((t) => t['name'] == tableName)) {
        for (var table in tables) {
          final tableNameStr = table['name']?.toString().toLowerCase() ?? '';
          if (tableNameStr.contains('dept')) {
            debugPrint("getDepartments: Found potential department table: ${table['name']}");
            tableName = table['name'].toString();
            break;
          }
        }
      }

      debugPrint("getDepartments: Using table '$tableName'");
      final results = await db.query(tableName);
      debugPrint("getDepartments: Retrieved ${results.length} departments from local storage");
      if (results.isNotEmpty) {
        debugPrint("getDepartments: First row columns: ${results.first.keys.toList()}");
        debugPrint("getDepartments: First row data: ${results.first}");

        // Log all department IDs
        final deptIds = results.map((r) => r['DeptId'] ?? r['deptId']).where((id) => id != null).toList();
        debugPrint("getDepartments: Available DeptId values: $deptIds");
      }
      return results.map((e) => DepartmentModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getDepartments error: $e');
      return [];
    }
  }

  Future<List<FailureCategoryModel>> getFailureCategories() async {
    // First try to load from the failure category asset database
    try {
      final db = await failureCategoryDatabase;
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("getFailureCategories: Available tables in failure_category_data.db: ${tables.map((t) => t['name']).toList()}");

      // Try common table names
      String tableName = 'failureCategory';
      if (!tables.any((t) => t['name'] == tableName)) {
        tableName = 'FailureCategoryType';
      }
      if (!tables.any((t) => t['name'] == tableName)) {
        tableName = 'FailureCategories';
      }
      if (!tables.any((t) => t['name'] == tableName)) {
        tableName = 'failureCategoryType';
      }
      if (!tables.any((t) => t['name'] == tableName)) {
        tableName = 'CorrfailureCategory';
      }

      debugPrint("getFailureCategories: Using table '$tableName'");
      final results = await db.query(tableName, orderBy: 'orderNo ASC');
      debugPrint("getFailureCategories: Retrieved ${results.length} categories from asset database");
      if (results.isNotEmpty) {
        debugPrint("getFailureCategories: First row columns: ${results.first.keys.toList()}");
        debugPrint("getFailureCategories: First row data: ${results.first}");
      }
      return results.map((e) => FailureCategoryModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getFailureCategories: Error loading from asset database: $e');

      // Fallback to main database
      final db = await database;
      try {
        final results = await db.query('FailureCategories', orderBy: 'orderNo ASC');
        debugPrint("getFailureCategories: Retrieved ${results.length} categories from main database");
        return results.map((e) => FailureCategoryModel.fromJson(e)).toList();
      } catch (e2) {
        debugPrint('getFailureCategories – creating lookup tables: $e2');
        await _createLookupTables(db);
        final results = await db.query('FailureCategories', orderBy: 'orderNo ASC');
        return results.map((e) => FailureCategoryModel.fromJson(e)).toList();
      }
    }
  }

  Future<List<MasterUserModel>> getMasterUsers() async {
    debugPrint("getMasterUsers: Opening user database (user_data.db)");
    final db = await userDatabase;
    try {
      // Check available tables
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint("getMasterUsers: Available tables: ${tables.map((t) => t['name']).toList()}");

      // Try to find user table - could be UserMaster, userMaster, MasterUsers, Users, or similar
      String tableName = 'UserMaster';
      if (!tables.any((t) => t['name'] == tableName)) {
        if (tables.any((t) => t['name'] == 'userMaster')) {
          tableName = 'userMaster';
        } else if (tables.any((t) => t['name'] == 'MasterUsers')) {
          tableName = 'MasterUsers';
        } else if (tables.any((t) => t['name'] == 'Users')) {
          tableName = 'Users';
        }
      }

      debugPrint("getMasterUsers: Using table '$tableName'");

      // Get column names to check what's available
      final columns = await db.rawQuery("PRAGMA table_info($tableName)");
      final columnNames = columns.map((c) => c['name']).toList();
      debugPrint("getMasterUsers: Table columns: $columnNames");

      // Print first 10 raw rows from database
      final rawRows = await db.rawQuery('SELECT * FROM $tableName LIMIT 10');
      debugPrint("getMasterUsers: First 10 raw rows from database:");
      for (int i = 0; i < rawRows.length; i++) {
        debugPrint("  [$i] ${rawRows[i]}");
      }

      // Build SELECT clause based on available columns
      final selectColumns = <String>[];
      if (columnNames.contains('UserId')) selectColumns.add('UserId');
      if (columnNames.contains('FirstName')) selectColumns.add('FirstName');
      if (columnNames.contains('LastName')) selectColumns.add('LastName');
      if (columnNames.contains('FullName')) selectColumns.add('FullName');
      if (columnNames.contains('UserName')) selectColumns.add('UserName');
      if (columnNames.contains('DeptId')) selectColumns.add('DeptId');
      if (columnNames.contains('DeptName')) selectColumns.add('DeptName');
      if (columnNames.contains('BusinessArea')) selectColumns.add('BusinessArea');
      if (columnNames.contains('RoleId')) selectColumns.add('RoleId');
      if (columnNames.contains('RoleDescr')) selectColumns.add('RoleDescr');
      if (columnNames.contains('DesignationID')) selectColumns.add('DesignationID');
      if (columnNames.contains('DesignationName')) selectColumns.add('DesignationName');
      if (columnNames.contains('Initial')) selectColumns.add('Initial');
      if (columnNames.contains('EmailId')) selectColumns.add('EmailId');
      if (columnNames.contains('EmpCode')) selectColumns.add('EmpCode');
      if (selectColumns.isEmpty) {
        debugPrint("getMasterUsers: No recognized columns found, selecting all");
        selectColumns.add('*');
      }

      // Load data in batches to avoid memory errors
      const batchSize = 500;
      final List<MasterUserModel> allResults = [];
      int offset = 0;

      while (true) {
        final results = await db.rawQuery('SELECT ${selectColumns.join(', ')} FROM $tableName LIMIT $batchSize OFFSET $offset');
        if (results.isEmpty) break;
        for (var row in results) {
          try {
            allResults.add(MasterUserModel.fromJson(row));
          } catch (e) {
            debugPrint("getMasterUsers: Error mapping row: $e");
          }
        }
        offset += batchSize;
        debugPrint("getMasterUsers: Loaded ${allResults.length} users so far...");
      }

      debugPrint("getMasterUsers: Found ${allResults.length} users");
      if (allResults.isNotEmpty) {
        debugPrint("getMasterUsers: First row columns: ${allResults.first.toJson().keys.toList()}");
        debugPrint("getMasterUsers: First row data: ${allResults.first.toJson()}");

        // Log distinct DeptId values
        final distinctDeptIds = allResults.map((u) => u.deptId).where((id) => id != null).toSet().toList();
        debugPrint("getMasterUsers: Distinct DeptId values found: $distinctDeptIds");

        // Log distinct BusinessArea values
        final distinctBusinessAreas = allResults.map((u) => u.businessArea).where((id) => id != null).toSet().toList();
        debugPrint("getMasterUsers: Distinct BusinessArea values found: $distinctBusinessAreas");

        // Log distinct RoleDescr values
        final distinctRoleDescrs = allResults.map((u) => u.roleDescr).where((r) => r != null && r!.isNotEmpty).toSet().toList();
        debugPrint("getMasterUsers: Distinct RoleDescr values found: $distinctRoleDescrs");

        // Count users with valid DeptId
        final usersWithDept = allResults.where((u) => u.deptId != null).length;
        debugPrint("getMasterUsers: Users with DeptId: $usersWithDept, Users without DeptId: ${allResults.length - usersWithDept}");
      }
      return allResults;
    } catch (e) {
      debugPrint('getMasterUsers error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers({String? searchTerm, int limit = 100, int offset = 0}) async {
    final db = await userDatabase;
    try {
      // Check available tables
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      String tableName = 'UserMaster';
      if (!tables.any((t) => t['name'] == tableName)) {
        if (tables.any((t) => t['name'] == 'userMaster')) {
          tableName = 'userMaster';
        } else if (tables.any((t) => t['name'] == 'MasterUsers')) {
          tableName = 'MasterUsers';
        } else if (tables.any((t) => t['name'] == 'Users')) {
          tableName = 'Users';
        }
      }

      String query = 'SELECT * FROM $tableName WHERE 1=1';
      List<dynamic> args = [];

      if (searchTerm != null && searchTerm.isNotEmpty) {
        query += ' AND (UPPER(userName) LIKE ? OR UPPER(fullName) LIKE ? OR UPPER(firstName) LIKE ? OR UPPER(lastName) LIKE ?)';
        final searchPattern = '%${searchTerm.toUpperCase()}%';
        args.addAll([searchPattern, searchPattern, searchPattern, searchPattern]);
      }

      query += ' LIMIT ? OFFSET ?';
      args.addAll([limit, offset]);

      final results = await db.rawQuery(query, args);
      return results;
    } catch (e) {
      debugPrint('searchUsers error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStations() async {
    final db = await database;
    try {
      final results = await db.query('Stations', orderBy: 'stationId ASC');
      debugPrint("getStations: Retrieved ${results.length} stations from local storage");
      if (results.isNotEmpty) {
        debugPrint("getStations: First station data: ${results.first}");
        debugPrint("getStations: Station columns: ${results.first.keys.toList()}");
      }
      return results;
    } catch (e) {
      debugPrint('getStations – creating lookup tables: $e');
      await _createLookupTables(db);
      // Try again after creating tables
      try {
        final results = await db.query('Stations', orderBy: 'stationId ASC');
        debugPrint("getStations: Retrieved ${results.length} stations after creating lookup tables");
        if (results.isNotEmpty) {
          debugPrint("getStations: First station data after table creation: ${results.first}");
        }
        return results;
      } catch (e2) {
        debugPrint("getStations: Still failed after creating tables: $e2");
        return [];
      }
    }
  }

  Future<void> insertStations(List<Map<String, dynamic>> stations) async {
    final db = await database;
    final batch = db.batch();
    for (final station in stations) {
      batch.insert(
        'Stations',
        {
          'stationId': int.tryParse(station['value']?.toString() ?? '0') ?? 0,
          'stationLabel': station['label']?.toString() ?? '',
          'stationValue': station['value']?.toString() ?? '',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint("insertStations: Inserted ${stations.length} stations");
  }

  Future<void> clearStations() async {
    final db = await database;
    await db.delete('Stations');
    debugPrint("clearStations: Cleared all stations");
  }

  // RST Master Data Operations
  Future<void> insertRstFailureTypes(List<RstFailureType> items) async {
    final db = await database;
    Batch batch = db.batch();
    for (var item in items) {
      batch.insert('RstFailureTypes', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    debugPrint("insertRstFailureTypes: Successfully inserted ${items.length} failure types");
  }

  Future<void> insertRstObjectParts(List<RstObjectPart> items) async {
    final db = await database;
    Batch batch = db.batch();
    for (var item in items) {
      batch.insert('RstObjectParts', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    debugPrint("insertRstObjectParts: Successfully inserted ${items.length} object parts");
  }

  Future<void> insertRstMaterials(List<RstMaterial> items) async {
    final db = await database;
    Batch batch = db.batch();
    for (var item in items) {
      batch.insert('RstMaterials', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    debugPrint("insertRstMaterials: Successfully inserted ${items.length} materials");
  }

  Future<void> insertRstStorageLocations(List<LabelValue> items) async {
    final db = await database;
    Batch batch = db.batch();
    for (var item in items) {
      batch.insert('RstStorageLocations', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    debugPrint("insertRstStorageLocations: Successfully inserted ${items.length} storage locations");
  }

  Future<void> insertRstTrainStatuses(List<RstTrainStatus> items) async {
    final db = await database;
    Batch batch = db.batch();
    for (var item in items) {
      batch.insert('RstTrainStatuses', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    debugPrint("insertRstTrainStatuses: Successfully inserted ${items.length} train statuses");
  }

  Future<List<RstFailureType>> getRstFailureTypes() async {
    final db = await database;
    try {
      final results = await db.query('RstFailureTypes', orderBy: 'id ASC');
      return results.map((e) => RstFailureType.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getRstFailureTypes – creating RST tables: $e');
      await _createRstTables(db);
      final results = await db.query('RstFailureTypes', orderBy: 'id ASC');
      return results.map((e) => RstFailureType.fromJson(e)).toList();
    }
  }

  Future<List<RstObjectPart>> getRstObjectParts() async {
    final db = await database;
    try {
      final results = await db.query('RstObjectParts', orderBy: 'id ASC');
      return results.map((e) => RstObjectPart.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getRstObjectParts – creating RST tables: $e');
      await _createRstTables(db);
      final results = await db.query('RstObjectParts', orderBy: 'id ASC');
      return results.map((e) => RstObjectPart.fromJson(e)).toList();
    }
  }

  Future<List<RstMaterial>> getRstMaterials() async {
    final db = await database;
    try {
      final results = await db.query('RstMaterials', orderBy: 'materialRowId ASC');
      return results.map((e) => RstMaterial.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getRstMaterials – creating RST tables: $e');
      await _createRstTables(db);
      final results = await db.query('RstMaterials', orderBy: 'materialRowId ASC');
      return results.map((e) => RstMaterial.fromJson(e)).toList();
    }
  }

  Future<List<RstTrainStatus>> getRstTrainStatuses() async {
    final db = await database;
    try {
      final results = await db.query('RstTrainStatuses', orderBy: 'statusId ASC');
      return results.map((e) => RstTrainStatus.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getRstTrainStatuses – creating RST tables: $e');
      await _createRstTables(db);
      final results = await db.query('RstTrainStatuses', orderBy: 'statusId ASC');
      return results.map((e) => RstTrainStatus.fromJson(e)).toList();
    }
  }

  Future<List<LabelValue>> getRstStorageLocations() async {
    final db = await database;
    try {
      final results = await db.query('RstStorageLocations', orderBy: 'value ASC');
      return results.map((e) => LabelValue.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getRstStorageLocations – creating RST tables: $e');
      await _createRstTables(db);
      final results = await db.query('RstStorageLocations', orderBy: 'value ASC');
      return results.map((e) => LabelValue.fromJson(e)).toList();
    }
  }

  // Failure List Operations
  Future<void> insertFailureList(List<Map<String, dynamic>> failures, String failureType) async {
    final db = await database;
    final batch = db.batch();

    // Define allowed columns based on database schema
    final allowedColumns = {
      'id', 'failureNo', 'notificationCode', 'jobCardId', 'failureDescription',
      'functionLocationId', 'equipmentId', 'functionalLocation', 'equipmentDescription',
      'statusName', 'statusDescription', 'failureOccuranceDateTime', 'assignedUserId',
      'occRequestStatus', 'otherRequestFrom', 'locationName', 'remarks', 'creationType',
      'priority', 'departmentName', 'subLocation', 'trainId', 'system',
      'actualFailureCompletedDateTime', 'isTripAffected', 'tripDelayUpline',
      'tripDelayDownline', 'tripCancel', 'isTrainReplace', 'trainReplace',
      'isTrainDeboarded', 'trainDeboarded', 'numberOfPassengerAffected',
      'isPassengerAffected', 'trappedDuration', 'rescusedDuration', 'trainDelayInMin',
      'noOfTranWithdrawal', 'failureReportedby', 'failureCategoryTypeText',
      'failureRectificationDetails', 'carriedOutRemarks', 'departmentId_1',
      'locationId', 'funcationLocationId', 'syncStatus', 'lastSyncedAt',
      'failureType', 'getImageBefor', 'createdDate'
    };

    for (var failure in failures) {
      final data = Map<String, dynamic>.from(failure);
      data['syncStatus'] = 'online';
      data['lastSyncedAt'] = DateTime.now().toIso8601String();
      data['failureType'] = failureType;

      // Map API field names to database column names
      if (data.containsKey('failureId') && !data.containsKey('failureNo')) {
        data['failureNo'] = data['failureId'];
        data.remove('failureId');
      }

      // Map location to locationName
      if (data.containsKey('location') && !data.containsKey('locationName')) {
        // If we have locationId, try to get full location name from locationTypeList
        if (data.containsKey('locationId')) {
          // This will be handled by the caller with access to locationTypeList
          // For now, just use the API value
          data['locationName'] = data['location'];
        } else {
          data['locationName'] = data['location'];
        }
        data.remove('location');
      }

      // Map API's funcationLocation (typo) to database's functionalLocation
      if (data.containsKey('funcationLocation') && !data.containsKey('functionalLocation')) {
        data['functionalLocation'] = data['funcationLocation'];
        data.remove('funcationLocation');
      }

      // Map API date fields to database's failureOccuranceDateTime
      if (!data.containsKey('failureOccuranceDateTime') || (data['failureOccuranceDateTime'] == null || data['failureOccuranceDateTime'].toString().trim().isEmpty)) {
        final dateVal = data['actualFailureOccuranceDate'] ??
            data['actualFailureOccuranceDatetime'] ??
            data['actualFailureOccuranceOn'];
        if (dateVal != null && dateVal.toString().trim().isNotEmpty) {
          data['failureOccuranceDateTime'] = dateVal.toString();
        }
      }

      // Map API status fields to database's statusName
      if (!data.containsKey('statusName') || (data['statusName'] == null || data['statusName'].toString().trim().isEmpty)) {
        final statusVal = data['mainStatusName'] ?? data['status'] ?? data['statusDescription'];
        if (statusVal != null && statusVal.toString().trim().isNotEmpty) {
          data['statusName'] = statusVal.toString();
        }
      }

      // Convert all boolean values to integer for SQLite
      data.forEach((key, value) {
        if (value is bool) {
          data[key] = value ? 1 : 0;
        }
      });

      // Convert list to JSON string
      if (data['getImageBefor'] is List) {
        data['getImageBefor'] = jsonEncode(data['getImageBefor']);
      }

      // Filter to only include allowed columns
      final filteredData = Map<String, dynamic>.fromEntries(
          data.entries.where((entry) => allowedColumns.contains(entry.key))
      );

      batch.insert('FailureList', filteredData, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    debugPrint("insertFailureList: Inserted ${failures.length} failures for type $failureType");
  }

  Future<List<Map<String, dynamic>>> getFailureList(String failureType) async {
    final db = await database;
    try {
      final results = await db.query(
        'FailureList',
        where: 'failureType = ?',
        whereArgs: [failureType],
        orderBy: 'id DESC',
      );
      // Convert back boolean values and parse JSON
      return results.map((e) {
        final data = Map<String, dynamic>.from(e);
        if (data['isTripAffected'] is int) {
          data['isTripAffected'] = data['isTripAffected'] == 1;
        }
        if (data['isTrainReplace'] is int) {
          data['isTrainReplace'] = data['isTrainReplace'] == 1;
        }
        if (data['isTrainDeboarded'] is int) {
          data['isTrainDeboarded'] = data['isTrainDeboarded'] == 1;
        }
        if (data['isPassengerAffected'] is int) {
          data['isPassengerAffected'] = data['isPassengerAffected'] == 1;
        }
        if (data['getImageBefor'] is String && data['getImageBefor'].isNotEmpty) {
          try {
            data['getImageBefor'] = jsonDecode(data['getImageBefor']);
          } catch (e) {
            data['getImageBefor'] = null;
          }
        }
        // Map funcationLocation to functionalLocation for model compatibility
        if (data.containsKey('funcationLocation') && !data.containsKey('functionalLocation')) {
          data['functionalLocation'] = data['funcationLocation'];
        }
        return data;
      }).toList();
    } catch (e) {
      debugPrint('getFailureList error: $e');
      await _createFailureTables(db);
      return [];
    }
  }

  Future<void> clearFailureList(String failureType) async {
    final db = await database;
    await db.delete('FailureList', where: 'failureType = ?', whereArgs: [failureType]);
    debugPrint("clearFailureList: Cleared failures for type $failureType");
  }

  Future<void> updateFailureSyncStatus(int id, String syncStatus) async {
    final db = await database;
    await db.update(
      'FailureList',
      {
        'syncStatus': syncStatus,
        'lastSyncedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Pending Failure Submissions Operations
  Future<int> insertPendingSubmission(Map<String, dynamic> payload, String failureType) async {
    final db = await database;
    final result = await db.insert('PendingFailureSubmissions', {
      'payload': jsonEncode(payload),
      'failureType': failureType,
      'createdAt': DateTime.now().toIso8601String(),
      'synced': 0,
    });
    debugPrint("insertPendingSubmission: Added pending submission with id $result");
    return result;
  }

  Future<List<Map<String, dynamic>>> getPendingSubmissions() async {
    final db = await database;
    try {
      final results = await db.query(
        'PendingFailureSubmissions',
        where: 'synced = 0',
        orderBy: 'createdAt ASC',
      );
      return results.map((e) {
        final data = Map<String, dynamic>.from(e);
        if (data['payload'] is String) {
          try {
            data['payload'] = jsonDecode(data['payload']);
          } catch (e) {
            debugPrint('Error decoding payload: $e');
          }
        }
        return data;
      }).toList();
    } catch (e) {
      debugPrint('getPendingSubmissions error: $e');
      return [];
    }
  }

  /// Update functional locations from API sync
  Future<void> updateFunctionalLocationsFromAPI(List<dynamic> funcLocs) async {
    final db = await database;
    final batch = db.batch();

    for (var loc in funcLocs) {
      batch.insert(
        'FunctionalLocations',
        {
          'funcLocId': loc['funcLocId'],
          'funcLocation': loc['funcLocation'],
          'funcLocationName': loc['funcLocationName'],
          'funcDescription': loc['funcDescription'],
          'location': loc['location'],
          'planningPlant': loc['planningPlant'],
          'workCenter': loc['workCenter'],
          'objectNumber': loc['objectNumber'],
          'techObjectType': loc['techObjectType'] ?? '',
          'objectKey': loc['objectKey'] ?? loc['funcLocation'],
          'subSystem': loc['subSystem'] ?? '',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Update measurement points from API sync
  Future<void> updateMeasurementPointsFromAPI(List<dynamic> measPoints) async {
    final db = await database;
    final batch = db.batch();

    for (var point in measPoints) {
      batch.insert(
        'MeasurementPoints',
        {
          'measId': point['measId'],
          'measPoint': point['measPoint'],
          'measPointDesc': point['measPointDesc'],
          'measRangeUnit': point['measRangeUnit'],
          'internalCharNo': point['internalCharNo'],
          'targetValue': point['targetValue'],
          'objectNo': point['objectNo'],
          'createdOn': point['createdOn'],
          'updatedOn': point['updatedOn'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Update locations from API sync
  Future<void> updateLocationsFromAPI(List<dynamic> locations) async {
    final db = await database;
    final batch = db.batch();

    for (var loc in locations) {
      batch.insert(
        'Locations',
        {
          'locationTypeId': loc['locationTypeId'],
          'locationTypeCode': loc['locationTypeCode'],
          'locationName': loc['locationName'],
          'plantId': loc['plantId'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Update users from API sync
  Future<void> updateUsersFromAPI(List<dynamic> users) async {
    final db = await database;
    final batch = db.batch();

    for (var user in users) {
      batch.insert(
        'MasterUsers',
        {
          'userId': user['userId'],
          'userName': user['userName'],
          'firstName': user['firstName'],
          'lastName': user['lastName'],
          'emailId': user['emailId'],
          'empCode': user['empCode'],
          'deptId': user['deptId'],
          'deptName': user['deptName'],
          'roleId': user['roleId'],
          'roleDescr': user['roleDescr'],
          'businessArea': user['businessArea'],
          'designationID': user['designationID'],
          'designationName': user['designationName'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Update materials from API sync
  Future<void> updateMaterialsFromAPI(List<dynamic> materials) async {
    final db = await database;

    // Ensure RstMaterials table exists
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS RstMaterials (
          materialRowId INTEGER PRIMARY KEY,
          material TEXT,
          type TEXT
        )
      ''');
    } catch (e) {
      debugPrint('updateMaterialsFromAPI: Error creating RstMaterials table: $e');
    }

    final batch = db.batch();

    for (var material in materials) {
      batch.insert(
        'RstMaterials',
        {
          'materialRowId': material['materialRowId'],
          'material': material['material'],
          'type': material['type'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Update priorities from API sync
  Future<void> updatePrioritiesFromAPI(List<dynamic> priorities) async {
    final db = await database;
    final batch = db.batch();

    for (var priority in priorities) {
      batch.insert(
        'Priorities',
        {
          'priorityId': priority['priorityId'],
          'priorityDesc': priority['priorityDesc'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> updateSubmissionSynced(int id, bool synced, {String? error}) async {
    final db = await database;
    await db.update(
      'PendingFailureSubmissions',
      {
        'synced': synced ? 1 : 0,
        'syncError': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePendingSubmission(int id) async {
    final db = await database;
    await db.delete('PendingFailureSubmissions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearPendingSubmissions() async {
    final db = await database;
    await db.delete('PendingFailureSubmissions');
    debugPrint("clearPendingSubmissions: Cleared all pending submissions");
  }

  Future<List<LocationModel>> getLocationsByBusinessArea(int businessArea) async {
    final db = await locationDatabase;
    try {
      // Find the first user table dynamically
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      // Get column names from location table
      final columns = await db.rawQuery("PRAGMA table_info($escapedTableName)");
      final columnNames = columns.map((c) => c['name']).toList();
      debugPrint("getLocationsByBusinessArea: $tableName columns: $columnNames");

      // Use BusinessLocation column for filtering
      String? businessAreaColumn;
      final candidates = ['BusinessLocation', 'businessLocation', 'BUSINESSLOCATION', 'BusinessArea', 'businessArea', 'BUSINESSAREA', 'MaintenancePlant', 'Maintenanceplant', 'MAINTENANCEPLANT'];
      for (var candidate in candidates) {
        if (columnNames.contains(candidate)) {
          businessAreaColumn = candidate;
          break;
        }
      }
      debugPrint("getLocationsByBusinessArea: Using business location column '$businessAreaColumn'");

      // If BusinessLocation column doesn't exist, return a limited subset of locations to avoid OOM
      if (businessAreaColumn == null) {
        debugPrint("getLocationsByBusinessArea: BusinessLocation column not found, returning all locations");
        final results = await db.rawQuery('SELECT * FROM $escapedTableName');
        debugPrint("getLocationsByBusinessArea: Retrieved ${results.length} locations (all)");
        return results.map((e) => LocationModel.fromJson(e)).toList();
      }

      final results = await db.rawQuery(
        'SELECT * FROM $escapedTableName WHERE "$businessAreaColumn" = ?',
        [businessArea],
      );
      debugPrint("getLocationsByBusinessArea: Retrieved ${results.length} locations for business area $businessArea");
      return results.map((e) => LocationModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getLocationsByBusinessArea error: $e');
      return [];
    }
  }

  // ON-DEMAND: Load functional locations with SQL filtering (no batch loading of all data)
  Future<List<FunctionalLocationModel>> getFunctionalLocationsFiltered({
    int? businessArea,
    String? workCenter,
    String? location,
    int? limit, // No default limit - load all filtered results
  }) async {
    final db = await funLocDatabase;
    try {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final columns = await db.rawQuery("PRAGMA table_info($escapedTableName)");
      final columnNames = columns.map((c) => c['name']).toList();

      // Build WHERE clause with multiple filters
      final where = <String>[];
      final args = <dynamic>[];

      if (businessArea != null) {
        final baCol = columnNames.firstWhere(
              (c) => ['BusinessArea', 'businessArea', 'BUSINESSAREA'].contains(c),
          orElse: () => 'BusinessArea',
        );
        where.add('"$baCol" = ?');
        args.add(businessArea);
      }

      if (workCenter != null && workCenter.isNotEmpty) {
        final wcCol = columnNames.firstWhere(
              (c) => ['WorkCenter', 'workCenter', 'WORKCENTER'].contains(c),
          orElse: () => 'WorkCenter',
        );
        where.add('"$wcCol" = ?');
        args.add(workCenter);
      }

      if (location != null && location.isNotEmpty) {
        final locCol = columnNames.firstWhere(
              (c) => ['Location', 'location', 'LOCATION'].contains(c),
          orElse: () => 'Location',
        );
        where.add('"$locCol" = ?');
        args.add(location);
      }

      // Build SELECT clause
      final selectColumns = <String>[];
      if (columnNames.contains('FuncLocId')) selectColumns.add('FuncLocId');
      if (columnNames.contains('FuncLocation')) selectColumns.add('FuncLocation');
      if (columnNames.contains('FuncLocationName')) selectColumns.add('FuncLocationName');
      if (columnNames.contains('FuncDescription')) selectColumns.add('FuncDescription');
      if (columnNames.contains('TechObjectType')) selectColumns.add('TechObjectType');
      if (columnNames.contains('ObjectKey')) selectColumns.add('ObjectKey');
      if (columnNames.contains('ObjectNumber')) selectColumns.add('ObjectNumber');
      if (columnNames.contains('SubSystem')) selectColumns.add('SubSystem');
      if (columnNames.contains('Systems')) selectColumns.add('Systems');
      // Add filtering columns for client-side filtering
      if (columnNames.contains('Location')) selectColumns.add('Location');
      if (columnNames.contains('WorkCenter')) selectColumns.add('WorkCenter');
      if (columnNames.contains('BusinessArea')) selectColumns.add('BusinessArea');
      if (selectColumns.isEmpty) selectColumns.add('*');

      // Execute filtered query with optional limit
      String query = 'SELECT ${selectColumns.join(', ')} FROM $escapedTableName'
          '${where.isNotEmpty ? ' WHERE ${where.join(' AND ')}' : ''}';
      if (limit != null) {
        query += ' LIMIT $limit';
      }

      debugPrint("getFunctionalLocationsFiltered: Query = $query, args = $args");
      final results = await db.rawQuery(query, args);

      debugPrint("getFunctionalLocationsFiltered: Retrieved ${results.length} functional locations");
      return results.map((row) => FunctionalLocationModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('getFunctionalLocationsFiltered error: $e');
      return [];
    }
  }

  // LEGACY: Keep for backward compatibility (but this loads ALL data - avoid using)
  Future<List<FunctionalLocationModel>> getFunctionalLocationsByBusinessArea(int businessArea) async {
    final db = await funLocDatabase;
    try {
      // Find the first user table dynamically
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      debugPrint("getFunctionalLocationsByBusinessArea: Using table '$tableName'");

      final columns = await db.rawQuery("PRAGMA table_info($escapedTableName)");
      final columnNames = columns.map((c) => c['name']).toList();
      debugPrint("getFunctionalLocationsByBusinessArea: Table columns: $columnNames");

      // Use BusinessArea column for filtering (fun_loc.db has 'BusinessArea' column)
      String? businessAreaColumn;
      final candidates = ['BusinessArea', 'businessArea', 'BUSINESSAREA', 'BusinessLocation', 'businessLocation', 'BUSINESSLOCATION', 'MaintenancePlant', 'Maintenanceplant', 'MAINTENANCEPLANT'];
      for (var candidate in candidates) {
        if (columnNames.contains(candidate)) {
          businessAreaColumn = candidate;
          break;
        }
      }
      debugPrint("getFunctionalLocationsByBusinessArea: Using business location column '$businessAreaColumn'");

      // Build SELECT clause based on available columns - include system/subsystem fields
      final selectColumns = <String>[];
      if (columnNames.contains('FuncLocId')) selectColumns.add('FuncLocId');
      if (columnNames.contains('FuncLocation')) selectColumns.add('FuncLocation');
      if (columnNames.contains('FuncLocationName')) selectColumns.add('FuncLocationName');
      if (columnNames.contains('FuncDescription')) selectColumns.add('FuncDescription');
      if (columnNames.contains('TechObjectType')) selectColumns.add('TechObjectType');
      if (columnNames.contains('ObjectKey')) selectColumns.add('ObjectKey');
      if (columnNames.contains('SubSystem')) selectColumns.add('SubSystem');
      if (columnNames.contains('Systems')) selectColumns.add('Systems');
      if (selectColumns.isEmpty) {
        debugPrint("getFunctionalLocationsByBusinessArea: No recognized columns found, selecting all");
        selectColumns.add('*');
      }

      // Load data in batches to avoid memory errors
      const batchSize = 500;
      final List<FunctionalLocationModel> allResults = [];
      int offset = 0;

      if (businessAreaColumn == null) {
        debugPrint("getFunctionalLocationsByBusinessArea: BusinessLocation column not found, loading ALL functional locations in batches");
        while (true) {
          final results = await db.rawQuery('SELECT ${selectColumns.join(', ')} FROM $escapedTableName LIMIT $batchSize OFFSET $offset');
          if (results.isEmpty) break;
          for (var row in results) {
            try {
              allResults.add(FunctionalLocationModel.fromJson(row));
            } catch (e) {
              debugPrint("getFunctionalLocationsByBusinessArea: Error mapping row: $e");
            }
          }
          offset += batchSize;
          debugPrint("getFunctionalLocationsByBusinessArea: Loaded ${allResults.length} functional locations so far...");
        }
        debugPrint("getFunctionalLocationsByBusinessArea: Retrieved ${allResults.length} functional locations (all in batches)");
        return allResults;
      }

      // Load filtered data in batches
      while (true) {
        final results = await db.rawQuery(
          'SELECT ${selectColumns.join(', ')} FROM $escapedTableName WHERE "$businessAreaColumn" = ? LIMIT $batchSize OFFSET $offset',
          [businessArea],
        );
        if (results.isEmpty) break;
        for (var row in results) {
          try {
            allResults.add(FunctionalLocationModel.fromJson(row));
          } catch (e) {
            debugPrint("getFunctionalLocationsByBusinessArea: Error mapping row: $e");
          }
        }
        offset += batchSize;
        debugPrint("getFunctionalLocationsByBusinessArea: Loaded ${allResults.length} functional locations so far...");
      }

      // If no results found with business area filter, load ALL records as fallback in batches
      if (allResults.isEmpty) {
        debugPrint("getFunctionalLocationsByBusinessArea: No records for business area $businessArea, loading ALL functional locations as fallback in batches");
        offset = 0;
        while (true) {
          final results = await db.rawQuery('SELECT ${selectColumns.join(', ')} FROM $escapedTableName LIMIT $batchSize OFFSET $offset');
          if (results.isEmpty) break;
          for (var row in results) {
            try {
              allResults.add(FunctionalLocationModel.fromJson(row));
            } catch (e) {
              debugPrint("getFunctionalLocationsByBusinessArea: Error mapping row: $e");
            }
          }
          offset += batchSize;
        }
      }

      debugPrint("getFunctionalLocationsByBusinessArea: Retrieved ${allResults.length} functional locations for business area $businessArea");
      return allResults;
    } catch (e) {
      debugPrint('getFunctionalLocationsByBusinessArea error: $e');
      return [];
    }
  }

  // ON-DEMAND: Load equipment with SQL filtering (no batch loading of all data)
  Future<List<EquipmentModel>> getEquipmentsFiltered({
    int? businessArea,
    String? functionalLocationId,
    String? workCenter,
    int? limit, // No default limit - load all filtered results
  }) async {
    final db = await equipmentDatabase;
    try {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final columns = await db.rawQuery("PRAGMA table_info($escapedTableName)");
      final columnNames = columns.map((c) => c['name']).toList();

      final flCol = columnNames.firstWhere(
            (c) => ['FunctionalLocation', 'functionalLocation', 'FUNCTIONALLOCATION'].contains(c),
        orElse: () => 'FunctionalLocation',
      );

      // If functionalLocationId is provided, query by it first (most specific filter)
      if (functionalLocationId != null && functionalLocationId.trim().isNotEmpty) {
        final raw = functionalLocationId.trim();
        final cleanCode = raw.contains(' - ') ? raw.split(' - ').first.trim() : raw;

        String flQuery = 'SELECT * FROM $escapedTableName WHERE TRIM(UPPER("$flCol")) = UPPER(?) OR TRIM(UPPER("$flCol")) = UPPER(?)';
        List<dynamic> flArgs = [cleanCode, raw];
        if (limit != null) flQuery += ' LIMIT $limit';

        debugPrint("getEquipmentsFiltered: FL exact query = $flQuery, args = $flArgs");
        var results = await db.rawQuery(flQuery, flArgs);

        if (results.isEmpty && cleanCode.isNotEmpty) {
          String likeQuery = 'SELECT * FROM $escapedTableName WHERE "$flCol" LIKE ?';
          if (limit != null) likeQuery += ' LIMIT $limit';
          debugPrint("getEquipmentsFiltered: FL LIKE query = $likeQuery, args = [%$cleanCode%]");
          results = await db.rawQuery(likeQuery, ['%$cleanCode%']);
        }

        if (results.isNotEmpty) {
          debugPrint("getEquipmentsFiltered: Retrieved ${results.length} equipments for functionalLocation: $cleanCode");
          return results.map((row) => EquipmentModel.fromJson(row)).toList();
        }
      }

      // Build WHERE clause with businessArea and workCenter filters
      final where = <String>[];
      final args = <dynamic>[];

      if (businessArea != null) {
        final baCol = columnNames.firstWhere(
              (c) => ['PlanningPlant', 'MaintenancePlant', 'BusinessArea', 'businessArea'].contains(c),
          orElse: () => 'PlanningPlant',
        );
        where.add('"$baCol" = ?');
        args.add(businessArea);
      }

      if (workCenter != null && workCenter.isNotEmpty) {
        final wcCol = columnNames.firstWhere(
              (c) => ['WorkCenter', 'workCenter', 'WORKCENTER'].contains(c),
          orElse: () => 'WorkCenter',
        );
        where.add('"$wcCol" = ?');
        args.add(workCenter);
      }

      // Execute filtered query with optional limit
      String query = 'SELECT * FROM $escapedTableName'
          '${where.isNotEmpty ? ' WHERE ${where.join(' AND ')}' : ''}';
      if (limit != null) {
        query += ' LIMIT $limit';
      }

      debugPrint("getEquipmentsFiltered fallback: Query = $query, args = $args");
      final results = await db.rawQuery(query, args);

      debugPrint("getEquipmentsFiltered fallback: Retrieved ${results.length} equipments");
      return results.map((row) => EquipmentModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('getEquipmentsFiltered error: $e');
      return [];
    }
  }

  // LEGACY: Keep for backward compatibility (but this loads ALL data - avoid using)
  Future<List<EquipmentModel>> getEquipmentsByBusinessArea(int businessArea) async {
    final db = await equipmentDatabase;
    try {
      // Find the first user table dynamically
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      // Get column names from equipment table
      final columns = await db.rawQuery("PRAGMA table_info($escapedTableName)");
      final columnNames = columns.map((c) => c['name']).toList();
      debugPrint("getEquipmentsByBusinessArea: $tableName columns: $columnNames");

      // Load data in batches to avoid memory errors
      const batchSize = 1000;
      final List<EquipmentModel> allResults = [];
      int offset = 0;

      // Cascading filter: business area -> PlanningPlant -> MaintenancePlant
      String? filterColumn;
      if (columnNames.contains('PlanningPlant')) {
        filterColumn = 'PlanningPlant';
        debugPrint("getEquipmentsByBusinessArea: Using PlanningPlant filter");
      } else if (columnNames.contains('MaintenancePlant')) {
        filterColumn = 'MaintenancePlant';
        debugPrint("getEquipmentsByBusinessArea: Using MaintenancePlant filter");
      } else {
        final baColumn = ['BusinessArea', 'businessArea', 'BUSINESSAREA']
            .firstWhere((c) => columnNames.contains(c), orElse: () => '');
        if (baColumn.isNotEmpty) {
          filterColumn = baColumn;
          debugPrint("getEquipmentsByBusinessArea: Using $baColumn filter");
        }
      }

      if (filterColumn != null) {
        // Load filtered data in batches
        while (true) {
          final results = await db.rawQuery(
            'SELECT * FROM $escapedTableName WHERE "$filterColumn" = ? LIMIT $batchSize OFFSET $offset',
            [businessArea],
          );
          if (results.isEmpty) break;
          for (var row in results) {
            try {
              allResults.add(EquipmentModel.fromJson(row));
            } catch (e) {
              debugPrint("getEquipmentsByBusinessArea: Error mapping row: $e");
            }
          }
          offset += batchSize;
          debugPrint("getEquipmentsByBusinessArea: Loaded ${allResults.length} equipments so far...");
        }
      }

      // If no results found with filter, load ALL records as fallback in batches
      if (allResults.isEmpty) {
        debugPrint("getEquipmentsByBusinessArea: No match found, loading ALL equipments in batches");
        offset = 0;
        while (true) {
          final results = await db.rawQuery('SELECT * FROM $escapedTableName LIMIT $batchSize OFFSET $offset');
          if (results.isEmpty) break;
          for (var row in results) {
            try {
              allResults.add(EquipmentModel.fromJson(row));
            } catch (e) {
              debugPrint("getEquipmentsByBusinessArea: Error mapping row: $e");
            }
          }
          offset += batchSize;
        }
      }

      debugPrint("getEquipmentsByBusinessArea: Total retrieved ${allResults.length} equipments for business area $businessArea");
      return allResults;
    } catch (e) {
      debugPrint('getEquipmentsByBusinessArea error: $e');
      return [];
    }
  }

  // NEW: JE View Databases
  Future<List<CorrFailureType>> getCorrFailureTypes() async {
    try {
      final db = await corrFailureTypeDatabase;
      debugPrint("getCorrFailureTypes: Opening corr failure type database");

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final results = await db.rawQuery('SELECT * FROM $escapedTableName');
      debugPrint("getCorrFailureTypes: Found ${results.length} corr failure types");
      if (results.isNotEmpty) {
        debugPrint("getCorrFailureTypes: First row columns: ${results.first.keys.toList()}");
        debugPrint("getCorrFailureTypes: First row data: ${results.first}");
      }

      return results.map((row) => CorrFailureType.fromJson(row)).toList();
    } catch (e) {
      debugPrint('getCorrFailureTypes error: $e');
      return [];
    }
  }

  Future<List<UserStatus>> getUserStatuses() async {
    try {
      final db = await userStatusDatabase;
      debugPrint("getUserStatuses: Opening user status database");

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final results = await db.rawQuery('SELECT * FROM $escapedTableName');
      debugPrint("getUserStatuses: Found ${results.length} user statuses");
      if (results.isNotEmpty) {
        debugPrint("getUserStatuses: First row columns: ${results.first.keys.toList()}");
        debugPrint("getUserStatuses: First row data: ${results.first}");
      }

      return results.map((row) => UserStatus.fromJson(row)).toList();
    } catch (e) {
      debugPrint('getUserStatuses error: $e');
      return [];
    }
  }

  Future<List<MaterialMaster>> getMaterialMasters() async {
    try {
      final db = await materialMasterDatabase;
      debugPrint("getMaterialMasters: Opening material master database");

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final results = await db.rawQuery('SELECT * FROM $escapedTableName');
      debugPrint("getMaterialMasters: Found ${results.length} material masters");

      if (results.isNotEmpty) {
        debugPrint("getMaterialMasters: First row columns: ${results.first.keys.toList()}");
        debugPrint("getMaterialMasters: First row data: ${results.first}");
      }

      return results.map((row) => MaterialMaster.fromJson(row)).toList();
    } catch (e) {
      debugPrint('getMaterialMasters error: $e');
      return [];
    }
  }

  // NEW: RST View Databases
  Future<List<RstObjectPart>> getRstObjectPartsFromDb() async {
    try {
      final db = await rstObjectPartDatabase;
      debugPrint("getRstObjectPartsFromDb: Opening RST object part database");

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final results = await db.rawQuery('SELECT * FROM $escapedTableName');
      debugPrint("getRstObjectPartsFromDb: Found ${results.length} RST object parts");

      return results.map((row) => RstObjectPart.fromJson(row)).toList();
    } catch (e) {
      debugPrint('getRstObjectPartsFromDb error: $e');
      return [];
    }
  }

  Future<List<RstFaultMaster>> getRstFaultMasters() async {
    try {
      final db = await rstFaultMasterDatabase;
      debugPrint("getRstFaultMasters: Opening RST fault master database");

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final results = await db.rawQuery('SELECT * FROM $escapedTableName');
      debugPrint("getRstFaultMasters: Found ${results.length} RST fault masters");

      return results.map((row) => RstFaultMaster.fromJson(row)).toList();
    } catch (e) {
      debugPrint('getRstFaultMasters error: $e');
      return [];
    }
  }

  Future<List<RstOldRootCause>> getRstOldRootCauses() async {
    try {
      final db = await rstOldRootCauseDatabase;
      debugPrint("getRstOldRootCauses: Opening RST old root cause database");

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final results = await db.rawQuery('SELECT * FROM $escapedTableName');
      debugPrint("getRstOldRootCauses: Found ${results.length} RST old root causes");

      return results.map((row) => RstOldRootCause.fromJson(row)).toList();
    } catch (e) {
      debugPrint('getRstOldRootCauses error: $e');
      return [];
    }
  }

  Future<List<StoreLocation>> getStoreLocations() async {
    try {
      final db = await rstStoreLocationDatabase;
      debugPrint("getStoreLocations: Opening store location database");

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final results = await db.rawQuery('SELECT * FROM $escapedTableName');
      debugPrint("getStoreLocations: Found ${results.length} store locations");

      if (results.isNotEmpty) {
        debugPrint("getStoreLocations: First row columns: ${results.first.keys.toList()}");
        debugPrint("getStoreLocations: First row data: ${results.first}");
      }

      return results.map((row) => StoreLocation.fromJson(row)).toList();
    } catch (e) {
      debugPrint('getStoreLocations error: $e');
      return [];
    }
  }

  Future<List<ReasonForDelayModel>> getReasonsForDelay() async {
    try {
      final db = await reasonForDelayDatabase;
      debugPrint("getReasonsForDelay: Opening reason for delay database");

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final results = await db.rawQuery('SELECT * FROM $escapedTableName');
      debugPrint("getReasonsForDelay: Found ${results.length} reasons for delay");

      if (results.isNotEmpty) {
        debugPrint("getReasonsForDelay: First row columns: ${results.first.keys.toList()}");
        debugPrint("getReasonsForDelay: First row data: ${results.first}");
      }

      return results.map((row) => ReasonForDelayModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('getReasonsForDelay error: $e');
      return [];
    }
  }

  Future<List<NatureOfWorkModel>> getNatureOfWorks() async {
    try {
      final db = await natureOfWorkDatabase;
      debugPrint("getNatureOfWorks: Opening nature of work database");

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final results = await db.rawQuery('SELECT * FROM $escapedTableName');
      debugPrint("getNatureOfWorks: Found ${results.length} nature of work entries");

      if (results.isNotEmpty) {
        debugPrint("getNatureOfWorks: First row columns: ${results.first.keys.toList()}");
        debugPrint("getNatureOfWorks: First row data: ${results.first}");
      }

      return results.map((row) => NatureOfWorkModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('getNatureOfWorks error: $e');
      return [];
    }
  }

  Future<List<FailureCategoryTypeModel>> getFailureCategoryTypes() async {
    try {
      final db = await failureCategoryTypeDatabase;
      debugPrint("getFailureCategoryTypes: Opening failure category type database");

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables
          .map((t) => t['name'] as String)
          .where((name) => name != 'sqlite_sequence' && name != 'android_metadata')
          .toList();

      if (tableNames.isEmpty) return [];
      String tableName = tableNames.first;
      final escapedTableName = '"$tableName"';

      final results = await db.rawQuery('SELECT * FROM $escapedTableName');
      debugPrint("getFailureCategoryTypes: Found ${results.length} failure category types");

      if (results.isNotEmpty) {
        debugPrint("getFailureCategoryTypes: First row columns: ${results.first.keys.toList()}");
        debugPrint("getFailureCategoryTypes: First row data: ${results.first}");
      }

      return results.map((row) => FailureCategoryTypeModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('getFailureCategoryTypes error: $e');
      return [];
    }
  }

  // ===========================================================================
  // FAILURE FORM DROPDOWNS (offline) - functional location / equipment
  // Mirrors the online stored procedure (GetFunctionLocEquipmentNo...):
  //   dept + location  : WorkCenter, Location, Plant
  //   dept only        : WorkCenter, Plant
  //   location only    : Location, Plant, WorkCenter in the user's departments
  //   neither          : Plant, WorkCenter in the user's departments
  // Functional location also needs Status != 'Deletion Flag', and for business
  // area 1200 with work center SIG / AFC only 29 character codes are listed.
  // ===========================================================================

  final Map<int, List<int>> _plantsByBusinessArea = {};

  Future<List<int>> _plantsFor(int businessArea) async {
    final cached = _plantsByBusinessArea[businessArea];
    if (cached != null) return cached;
    var plants = <int>[];
    try {
      final db = await plantDatabase;
      final rows = await db.rawQuery(
          'SELECT DISTINCT Plant FROM plantMAster WHERE BusinessArea = ?',
          [businessArea]);
      plants = rows
          .map((r) => int.tryParse('${r['Plant']}') ?? 0)
          .where((p) => p > 0)
          .toList();
    } catch (e) {
      debugPrint('_plantsFor: plant table unavailable: $e');
    }
    if (plants.isEmpty) {
      // Fallback: the plants used by that business area's functional locations.
      try {
        final db = await funLocDatabase;
        final t = await _firstUserTable(db);
        if (t != null) {
          final rows = await db.rawQuery(
              'SELECT DISTINCT PlanningPlant AS p FROM "$t" WHERE BusinessArea = ?',
              [businessArea]);
          plants = rows
              .map((r) => int.tryParse('${r['p']}') ?? 0)
              .where((p) => p > 0)
              .toList();
        }
      } catch (e) {
        debugPrint('_plantsFor fallback error: $e');
      }
    }
    if (plants.isNotEmpty) _plantsByBusinessArea[businessArea] = plants;
    return plants;
  }

  Future<String?> getDeptCodeById(int deptId) async {
    try {
      final db = await deptDatabase;
      final rows = await db.rawQuery(
          'SELECT DeptCode FROM deptMaster WHERE DeptId = ? LIMIT 1', [deptId]);
      return rows.isEmpty ? null : rows.first['DeptCode']?.toString();
    } catch (e) {
      debugPrint('getDeptCodeById error: $e');
      return null;
    }
  }

  Future<List<String>> getDeptCodesByIds(Iterable<int> deptIds) async {
    final codes = <String>{};
    for (final id in deptIds) {
      final c = await getDeptCodeById(id);
      if (c != null && c.trim().isNotEmpty) codes.add(c.trim());
    }
    return codes.toList();
  }

  Future<String?> getLocationCodeById(int locationTypeId) async {
    try {
      final db = await locationDatabase;
      final rows = await db.rawQuery(
          'SELECT LocationTypeCode FROM locationMaster WHERE LocationTypeId = ? LIMIT 1',
          [locationTypeId]);
      return rows.isEmpty ? null : rows.first['LocationTypeCode']?.toString();
    } catch (e) {
      debugPrint('getLocationCodeById error: $e');
      return null;
    }
  }

  String _inList(Iterable<Object> values, List<Object?> args) {
    final list = values.toList();
    args.addAll(list);
    return '(${List.filled(list.length, '?').join(',')})';
  }

  /// Functional locations for the failure form.
  /// Rows: FuncLocId, FuncLocation, FuncDescription, TechObjectType (system),
  /// SubSystem, WorkCenter, Location.
  Future<List<Map<String, dynamic>>> queryFailureFunctionalLocations({
    required int businessArea,
    String? workCenter,
    String? locationCode,
    List<String> userWorkCenters = const [],
  }) async {
    try {
      final db = await funLocDatabase;
      final t = await _firstUserTable(db);
      if (t == null) return [];
      final plants = await _plantsFor(businessArea);
      if (plants.isEmpty) return [];

      final wc = (workCenter ?? '').trim();
      final loc = (locationCode ?? '').trim();
      final args = <Object?>[];
      final where = <String>[
        "Status NOT IN ('Deletion Flag')",
        'PlanningPlant IN ${_inList(plants, args)}',
      ];

      if (wc.isNotEmpty) {
        where.add('WorkCenter = ?');
        args.add(wc);
        if (loc.isNotEmpty) {
          where.add('Location = ?');
          args.add(loc);
        }
        final upper = wc.toUpperCase();
        if (businessArea == 1200 && (upper == 'SIG' || upper == 'AFC')) {
          where.add('length(FuncLocation) = 29');
        }
      } else {
        if (userWorkCenters.isEmpty) return [];
        where.add('WorkCenter IN ${_inList(userWorkCenters, args)}');
        if (loc.isNotEmpty) {
          where.add('Location = ?');
          args.add(loc);
        } else if (businessArea == 1200) {
          // Neither department nor location chosen: apply the code length rule.
          where.add(
              "(WorkCenter NOT IN ('SIG','AFC') OR length(FuncLocation) = 29)");
        }
      }

      return await db.rawQuery(
          'SELECT FuncLocId, FuncLocation, FuncDescription, TechObjectType, '
          'SubSystem, WorkCenter, Location FROM "$t" '
          'WHERE ${where.join(' AND ')} ORDER BY FuncLocation',
          args);
    } catch (e) {
      debugPrint('queryFailureFunctionalLocations error: $e');
      return [];
    }
  }

  /// One functional location (system / sub system come from this row).
  Future<Map<String, dynamic>?> getFailureFunctionalLocationRow(
      int funcLocId) async {
    try {
      final db = await funLocDatabase;
      final t = await _firstUserTable(db);
      if (t == null) return null;
      final rows = await db.rawQuery(
          'SELECT FuncLocId, FuncLocation, FuncDescription, TechObjectType, '
          'SubSystem, WorkCenter, Location FROM "$t" WHERE FuncLocId = ? LIMIT 1',
          [funcLocId]);
      return rows.isEmpty ? null : rows.first;
    } catch (e) {
      debugPrint('getFailureFunctionalLocationRow error: $e');
      return null;
    }
  }

  /// Equipment for the failure form. With [funcLocCode] the list is that
  /// functional location's equipment; otherwise it follows the same
  /// department / location rules as the functional location list.
  /// Rows: EquipId, EquipNo, EquipDesc, FunctionalLocation.
  Future<List<Map<String, dynamic>>> queryFailureEquipments({
    required int businessArea,
    String? funcLocCode,
    String? workCenter,
    String? locationCode,
    List<String> userWorkCenters = const [],
  }) async {
    try {
      final db = await equipmentDatabase;
      final t = await _firstUserTable(db);
      if (t == null) return [];
      final args = <Object?>[];
      final where = <String>[];

      final fl = (funcLocCode ?? '').trim();
      if (fl.isNotEmpty) {
        where.add('FunctionalLocation = ?');
        args.add(fl);
      } else {
        final plants = await _plantsFor(businessArea);
        if (plants.isEmpty) return [];
        where.add('PlanningPlant IN ${_inList(plants, args)}');
        final wc = (workCenter ?? '').trim();
        final loc = (locationCode ?? '').trim();
        if (wc.isNotEmpty) {
          where.add('WorkCenter = ?');
          args.add(wc);
          if (loc.isNotEmpty) {
            where.add('Location = ?');
            args.add(loc);
          }
        } else {
          if (userWorkCenters.isEmpty) return [];
          where.add('WorkCenter IN ${_inList(userWorkCenters, args)}');
          if (loc.isNotEmpty) {
            where.add('Location = ?');
            args.add(loc);
          }
        }
      }

      return await db.rawQuery(
          'SELECT EquipId, EquipNo, EquipDesc, FunctionalLocation FROM "$t" '
          'WHERE ${where.join(' AND ')} ORDER BY EquipNo',
          args);
    } catch (e) {
      debugPrint('queryFailureEquipments error: $e');
      return [];
    }
  }

  /// System -> sub systems for a department (OCC role picks them freely).
  /// Same row shape as the API: [{system, subSystem: [..]}].
  Future<List<Map<String, dynamic>>> getFailureSystemSubsystems({
    required int businessArea,
    String? workCenter,
  }) async {
    try {
      final db = await funLocDatabase;
      final t = await _firstUserTable(db);
      if (t == null) return [];
      final plants = await _plantsFor(businessArea);
      if (plants.isEmpty) return [];
      final args = <Object?>[];
      final where = <String>[
        "Status NOT IN ('Deletion Flag')",
        'PlanningPlant IN ${_inList(plants, args)}',
        "TechObjectType IS NOT NULL AND TechObjectType <> ''",
      ];
      final wc = (workCenter ?? '').trim();
      if (wc.isNotEmpty) {
        where.add('WorkCenter = ?');
        args.add(wc);
      }
      final rows = await db.rawQuery(
          'SELECT DISTINCT TechObjectType AS system, SubSystem AS sub FROM "$t" '
          'WHERE ${where.join(' AND ')} ORDER BY 1, 2',
          args);
      final grouped = <String, List<String>>{};
      for (final r in rows) {
        final sys = r['system']?.toString().trim() ?? '';
        if (sys.isEmpty) continue;
        final list = grouped.putIfAbsent(sys, () => <String>[]);
        final sub = r['sub']?.toString().trim() ?? '';
        if (sub.isNotEmpty) list.add(sub);
      }
      return grouped.entries
          .map((e) => <String, dynamic>{'system': e.key, 'subSystem': e.value})
          .toList();
    } catch (e) {
      debugPrint('getFailureSystemSubsystems error: $e');
      return [];
    }
  }

  /// Date of the data that shipped in the asset databases (older of the two
  /// newest UpdatedOn values, minus a day). The first delta sync starts from
  /// here so nothing changed after the export is missed.
  Future<String?> getMasterBaselineDate() async {
    try {
      final dates = <String>[];
      for (final db in [await funLocDatabase, await equipmentDatabase]) {
        final t = await _firstUserTable(db);
        if (t == null) continue;
        final rows = await db.rawQuery(
            "SELECT MAX(UpdatedOn) AS m FROM \"$t\" WHERE UpdatedOn LIKE '20__-__-__%'");
        final m = rows.isEmpty ? null : rows.first['m']?.toString();
        if (m != null && m.length >= 10) dates.add(m.substring(0, 10));
      }
      if (dates.isEmpty) return null;
      dates.sort();
      final oldest = DateTime.tryParse(dates.first);
      if (oldest == null) return null;
      final d = oldest.subtract(const Duration(days: 1));
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('getMasterBaselineDate error: $e');
      return null;
    }
  }

  /// Upserts functional locations from the API sync into the same table the
  /// dropdowns read. A missing status is stored as 'Created' (a NULL status
  /// would be filtered out by the Deletion Flag check).
  Future<void> upsertFunctionalLocationsToMaster(List<dynamic> rows) async {
    final db = await funLocDatabase;
    final t = await _firstUserTable(db);
    if (t == null) return;
    final batch = db.batch();
    for (final r in rows) {
      if (r is! Map) continue;
      final code = r['funcLocation']?.toString() ?? '';
      final desc = r['funcDescription']?.toString() ?? '';
      batch.insert(
        t,
        {
          'FuncLocId': r['funcLocId'],
          'FuncLocation': code,
          'FuncDescription': desc,
          'FuncLocationName':
              r['funcLocationName'] ?? (desc.isEmpty ? code : '$code - $desc'),
          'ObjectNumber': r['objectNumber'],
          'PlanningPlant': r['planningPlant'],
          'MaintenancePlant': r['maintenancePlant'] ?? r['planningPlant'],
          'Room': r['room'],
          'TechObjectType': r['techObjectType'] ?? r['system'],
          'ObjectKey': r['objectKey'] ?? code,
          'SubSystem': r['subSystem'],
          'BusinessArea': r['businessArea'],
          'WorkCenter': r['workCenter'],
          'Location': r['location'],
          'CreatedOn': r['createdOn'],
          'UpdatedOn': r['updatedOn'] ?? DateTime.now().toIso8601String(),
          'Status': (r['status']?.toString().trim().isNotEmpty ?? false)
              ? r['status']
              : 'Created',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Upserts equipment from the API sync into the equipment dropdown table.
  Future<void> upsertEquipmentsToMaster(List<dynamic> rows) async {
    final db = await equipmentDatabase;
    final t = await _firstUserTable(db);
    if (t == null) return;
    final batch = db.batch();
    for (final r in rows) {
      if (r is! Map) continue;
      batch.insert(
        t,
        {
          'EquipId': r['equipId'],
          'EquipNo': r['equipNo'],
          'EquipDesc': r['equipDesc'],
          'ObjectNo': r['objectNo'],
          'EquipStatus': r['equipStatus'],
          'PlanningPlant': r['planningPlant'],
          'WorkCenter': r['workCenter'],
          'MaintenancePlant': r['maintenancePlant'] ?? r['planningPlant'],
          'Location': r['location'],
          'FunctionalLocation': r['functionalLocation'],
          'Room': r['room'],
          'Status': r['status'],
          'CreatedOn': r['createdOn'],
          'UpdatedOn': r['updatedOn'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
