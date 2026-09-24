import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  var dbPath = p.join(Directory.current.path, 'assets', 'fun_loc.db');
  var db = await databaseFactory.openDatabase(dbPath);
  
  var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  
  if (tables.isNotEmpty) {
    String tableName = tables[0]['name'] as String;
    // Check row number of 47865
    var result = await db.rawQuery('SELECT count(*) as cnt FROM "$tableName" WHERE rowid <= (SELECT rowid FROM "$tableName" WHERE FuncLocId = 47865)');
    print("Row number of 47865: ${result.first['cnt']}");
    var count = await db.rawQuery('SELECT count(*) as total FROM "$tableName" WHERE BusinessArea = 1200');
    print("Total for 1200: ${count.first['total']}");
  }
  
  await db.close();
}
