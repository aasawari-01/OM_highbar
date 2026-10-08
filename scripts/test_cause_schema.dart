import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  var dbPath = p.join(Directory.current.path, 'om_mobile.db');
  var db = await databaseFactory.openDatabase(dbPath);
  
  var result = await db.rawQuery('PRAGMA table_info("CauseOfFailures")');
  print("Columns in CauseOfFailures:");
  for (var col in result) {
    print("  ${col['name']}");
  }
  
  var sample = await db.rawQuery('SELECT * FROM "CauseOfFailures" LIMIT 1');
  print("Sample: $sample");
  
  await db.close();
}
