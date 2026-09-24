import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  var dbPath = p.join(Directory.current.path, 'assets', 'rca.db');
  var db = await databaseFactory.openDatabase(dbPath);
  
  var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  print("Tables in rca.db: ${tables}");
  
  if (tables.isNotEmpty) {
    for (var table in tables) {
      String tableName = table['name'] as String;
      if (tableName == 'sqlite_sequence' || tableName == 'android_metadata') continue;
      var result = await db.rawQuery('PRAGMA table_info("$tableName")');
      print("Columns in $tableName:");
      for (var col in result) {
        print("  ${col['name']}");
      }
    }
  }
  
  await db.close();
}
