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
    var result = await db.rawQuery('SELECT * FROM "$tableName" WHERE FuncLocId = 47865 OR FuncLocId = "47865"');
    print("Result for 47865:");
    for (var row in result) {
      print(row);
    }
  }
  
  await db.close();
}
