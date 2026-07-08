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
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'master_data.db');
    return await openDatabase(
      path,
      version: 7, // bumped from 6
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
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

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE SyncMeta (
        action TEXT PRIMARY KEY,
        lastCreatedOn TEXT,
        lastUpdatedOn TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Locations (
        locationTypeCode TEXT PRIMARY KEY,
        locationTypeId INTEGER,
        locationTypeName TEXT,
        locationName TEXT,
        plantId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE FunctionalLocations (
        funcLocation TEXT PRIMARY KEY,
        funcLocId INTEGER,
        funcDescription TEXT,
        funcLocationName TEXT,
        location TEXT,
        planningPlant TEXT,
        workCenter TEXT,
        objectNumber TEXT,
        createdOn TEXT,
        updatedOn TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Equipments (
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
      CREATE TABLE MeasurementPoints (
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

    await _createLookupTables(db);
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
    Batch batch = db.batch();
    for (var pt in points) {
      batch.insert('MeasurementPoints', pt.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // Fetch Operations
  Future<List<LocationModel>> getLocations() async {
    final db = await database;
    final results = await db.rawQuery('SELECT * FROM Locations LIMIT 10000');
    return results.map((e) => LocationModel.fromJson(e)).toList();
  }

  Future<List<FunctionalLocationModel>> getFunctionalLocations() async {
    final db = await database;
    final results = await db.rawQuery('SELECT funcLocation, funcLocId, funcLocationName, location, objectNumber, workCenter FROM FunctionalLocations LIMIT 10000');
    return results.map((e) => FunctionalLocationModel.fromJson(e)).toList();
  }

  Future<List<EquipmentModel>> getEquipments() async {
    final db = await database;
    final results = await db.rawQuery('SELECT equipId, equipmentName, functionalLocation, location, equipNo, equipDesc FROM Equipments LIMIT 10000');
    return results.map((e) => EquipmentModel.fromJson(e)).toList();
  }

  Future<List<MeasurementPointModel>> getMeasurementPoints() async {
    final db = await database;
    final results = await db.query('MeasurementPoints');
    return results.map((e) => MeasurementPointModel.fromJson(e)).toList();
  }

  Future<void> insertPriorities(List<PriorityModel> items) async {
    final db = await database;
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

  Future<void> insertMasterUsers(List<MasterUserModel> items) async {
    final db = await database;
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
    final db = await database;
    try {
      final results = await db.query('Priorities', orderBy: 'priorityId ASC');
      return results.map((e) => PriorityModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getPriorities – creating lookup tables: $e');
      await _createLookupTables(db);
      final results = await db.query('Priorities', orderBy: 'priorityId ASC');
      return results.map((e) => PriorityModel.fromJson(e)).toList();
    }
  }

  Future<List<DepartmentModel>> getDepartments() async {
    final db = await database;
    try {
      final results = await db.query('Departments', orderBy: 'deptId ASC');
      debugPrint("getDepartments: Retrieved ${results.length} departments from local storage");
      return results.map((e) => DepartmentModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getDepartments – creating lookup tables: $e');
      await _createLookupTables(db);
      final results = await db.query('Departments', orderBy: 'deptId ASC');
      debugPrint("getDepartments: Retrieved ${results.length} departments after creating lookup tables");
      return results.map((e) => DepartmentModel.fromJson(e)).toList();
    }
  }

  Future<List<FailureCategoryModel>> getFailureCategories() async {
    final db = await database;
    try {
      final results = await db.query('FailureCategories', orderBy: 'orderNo ASC');
      return results.map((e) => FailureCategoryModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getFailureCategories – creating lookup tables: $e');
      await _createLookupTables(db);
      final results = await db.query('FailureCategories', orderBy: 'orderNo ASC');
      return results.map((e) => FailureCategoryModel.fromJson(e)).toList();
    }
  }

  Future<List<MasterUserModel>> getMasterUsers() async {
    final db = await database;
    try {
      final results = await db.query('MasterUsers', orderBy: 'userName ASC');
      return results.map((e) => MasterUserModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getMasterUsers – creating lookup tables: $e');
      await _createLookupTables(db);
      final results = await db.query('MasterUsers', orderBy: 'userName ASC');
      return results.map((e) => MasterUserModel.fromJson(e)).toList();
    }
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
}
