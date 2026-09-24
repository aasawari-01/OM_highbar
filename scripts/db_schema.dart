import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  var db = await databaseFactory.openDatabase('assets/fun_loc.db');
  var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  for (var table in tables) {
    var tableName = table['name'];
    print('Table: $tableName');
    var columns = await db.rawQuery('PRAGMA table_info("''$tableName''")');
    for (var col in columns) {
      print('  ${col['name']}');
    }
  }
  await db.close();
}
