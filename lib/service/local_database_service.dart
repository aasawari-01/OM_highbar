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
    
    // Check if database exists, if not copy from assets
    final dbFile = File(path);
    if (!await dbFile.exists()) {
      debugPrint("_initDatabase: Database does not exist, copying from assets");
      await _copyDatabaseFromAssets(path);
    }
    
    return await openDatabase(
      path,
      version: 8, // bumped from 7 for failure list tables
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _copyDatabaseFromAssets(String targetPath) async {
    try {
      // Load the database from assets
      final byteData = await rootBundle.load('assets/master.db');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      
      // Write to the target path
      await File(targetPath).writeAsBytes(bytes, flush: true);
      debugPrint("_copyDatabaseFromAssets: Successfully copied database from assets to $targetPath");
      
      // Print sample data from database
      await _printSampleData(targetPath);
    } catch (e) {
      debugPrint("_copyDatabaseFromAssets: Error copying database from assets: $e");
      // If copy fails, create a new database
      final db = await openDatabase(
        targetPath,
        version: 8,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      await db.close();
    }
  }

  Future<void> _printSampleData(String dbPath) async {
    try {
      final db = await openDatabase(dbPath);
      
      // Get list of tables
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      );
      debugPrint("_printSampleData: Tables in database: ${tables.map((t) => t['name']).toList()}");
      
      // Print sample data from each table
      for (var table in tables) {
        final tableName = table['name'] as String;
        if (tableName == 'sqlite_sequence') continue; // Skip internal table
        
        final rows = await db.query(tableName, limit: 5);
        if (rows.isNotEmpty) {
          debugPrint("_printSampleData: Table '$tableName' - First ${rows.length} rows:");
          for (var row in rows) {
            debugPrint("  $row");
          }
        } else {
          debugPrint("_printSampleData: Table '$tableName' is empty");
        }
      }
      
      await db.close();
    } catch (e) {
      debugPrint("_printSampleData: Error: $e");
    }
  }

  /// Force re-import database from assets (useful for testing or data refresh)
  Future<void> forceImportFromAssets() async {
    try {
      // Close existing database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Delete existing database file
      final path = join(await getDatabasesPath(), 'master_data.db');
      final dbFile = File(path);
      if (await dbFile.exists()) {
        await dbFile.delete();
        debugPrint("forceImportFromAssets: Deleted existing database");
      }
      
      // Copy from assets
      await _copyDatabaseFromAssets(path);
      debugPrint("forceImportFromAssets: Database successfully re-imported from assets");
    } catch (e) {
      debugPrint("forceImportFromAssets: Error: $e");
    }
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
    if (oldVersion < 8) {
      await _createFailureTables(db);
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
        getImageBefor TEXT
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

    await db.execute('''
      CREATE TABLE FailureList (
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
        getImageBefor TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE PendingFailureSubmissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payload TEXT NOT NULL,
        failureType TEXT,
        createdAt TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        syncError TEXT
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
    Batch batch = db.batch();
    for (var pt in points) {
      batch.insert('MeasurementPoints', pt.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // Fetch Operations
  Future<List<LocationModel>> getLocations() async {
    final db = await database;
    String query = 'SELECT * FROM Locations';
    final results = await db.rawQuery(query);
    return results.map((e) => LocationModel.fromJson(e)).toList();
  }

  Future<List<FunctionalLocationModel>> getFunctionalLocations() async {
    final db = await database;
    const batchSize = 5000;
    String baseQuery = 'SELECT funcLocation, funcLocId, funcLocationName, location, objectNumber, workCenter, planningPlant FROM FunctionalLocations';
    List<dynamic> baseArgs = [];
    // Paginate to avoid CursorWindow OOM on large datasets
    final List<FunctionalLocationModel> allResults = [];
    int offset = 0;
    while (true) {
      final results = await db.rawQuery('$baseQuery LIMIT $batchSize OFFSET $offset', baseArgs);
      if (results.isEmpty) break;
      allResults.addAll(results.map((e) => FunctionalLocationModel.fromJson(e)));
      if (results.length < batchSize) break;
      offset += batchSize;
    }
    return allResults;
  }

  Future<List<Map<String, dynamic>>> getFilteredFunctionalLocations({String? locationCode, String? workCenter}) async {
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
    
    // Protect against loading all records if no filters are applied
    if (args.isEmpty) {
      query += ' LIMIT 100';
    }
    
    final results = await db.rawQuery(query, args);
    return results;
  }

  Future<List<EquipmentModel>> getEquipments() async {
    final db = await database;
    const batchSize = 5000;
    String baseQuery = 'SELECT equipId, equipmentName, functionalLocation, location, equipNo, equipDesc, planningPlant FROM Equipments';
    List<dynamic> baseArgs = [];
    // Paginate to avoid CursorWindow OOM on large datasets
    final List<EquipmentModel> allResults = [];
    int offset = 0;
    while (true) {
      final results = await db.rawQuery('$baseQuery LIMIT $batchSize OFFSET $offset', baseArgs);
      if (results.isEmpty) break;
      allResults.addAll(results.map((e) => EquipmentModel.fromJson(e)));
      if (results.length < batchSize) break;
      offset += batchSize;
    }
    return allResults;
  }

  Future<List<Map<String, dynamic>>> getFilteredEquipments({String? locationCode, String? funcLocCode}) async {
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
    
    // Protect against loading all records if no filters are applied
    if (args.isEmpty) {
      query += ' LIMIT 100';
    }
    
    final results = await db.rawQuery(query, args);
    return results;
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

  Future<List<Map<String, dynamic>>> getStations() async {
    final db = await database;
    try {
      final results = await db.query('Stations', orderBy: 'stationId ASC');
      debugPrint("getStations: Retrieved ${results.length} stations from local storage");
      return results;
    } catch (e) {
      debugPrint('getStations – creating lookup tables: $e');
      await _createLookupTables(db);
      final results = await db.query('Stations', orderBy: 'stationId ASC');
      debugPrint("getStations: Retrieved ${results.length} stations after creating lookup tables");
      return results;
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
    for (var failure in failures) {
      final data = Map<String, dynamic>.from(failure);
      data['syncStatus'] = 'online';
      data['lastSyncedAt'] = DateTime.now().toIso8601String();
      data['failureType'] = failureType;
      // Convert boolean to integer for SQLite
      if (data['isTripAffected'] is bool) {
        data['isTripAffected'] = data['isTripAffected'] ? 1 : 0;
      }
      if (data['isTrainReplace'] is bool) {
        data['isTrainReplace'] = data['isTrainReplace'] ? 1 : 0;
      }
      if (data['isTrainDeboarded'] is bool) {
        data['isTrainDeboarded'] = data['isTrainDeboarded'] ? 1 : 0;
      }
      if (data['isPassengerAffected'] is bool) {
        data['isPassengerAffected'] = data['isPassengerAffected'] ? 1 : 0;
      }
      // Convert list to JSON string
      if (data['getImageBefor'] is List) {
        data['getImageBefor'] = jsonEncode(data['getImageBefor']);
      }
      batch.insert('FailureList', data, conflictAlgorithm: ConflictAlgorithm.replace);
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
      await _createFailureTables(db);
      return [];
    }
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
}
