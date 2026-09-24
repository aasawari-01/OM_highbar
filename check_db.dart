import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await openDatabase('assets/UserMaster.db');

  // Get table names
  final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  print('Tables: ${tables.map((t) => t['name']).toList()}');

  // Get columns from UserMaster table
  final columns = await db.rawQuery("PRAGMA table_info(UserMaster)");
  print('\nColumns in UserMaster:');
  for (var col in columns) {
    print('  ${col['name']} (${col['type']})');
  }

  // Get sample data
  final sampleData = await db.query('UserMaster', limit: 5);
  print('\nSample data (first 5 rows):');
  for (var row in sampleData) {
    print(row);
  }

  // Check DeptId values
  final deptIdQuery = await db.rawQuery("SELECT DISTINCT DeptId FROM UserMaster WHERE DeptId IS NOT NULL LIMIT 10");
  print('\nDistinct DeptId values (first 10):');
  for (var row in deptIdQuery) {
    print('  DeptId: ${row['DeptId']}');
  }

  // Count users per department
  final deptCount = await db.rawQuery("SELECT DeptId, COUNT(*) as count FROM UserMaster WHERE DeptId IS NOT NULL GROUP BY DeptId LIMIT 10");
  print('\nUser count per department (first 10):');
  for (var row in deptCount) {
    print('  DeptId ${row['DeptId']}: ${row['count']} users');
  }

  await db.close();
}
