import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  final assetFiles = [
    'assets/dept.db',
    'assets/fun_loc.db',
    'assets/equipment.db',
  ];

  for (var asset in assetFiles) {
    try {
      print("Reading $asset");
      final db = await databaseFactory.openDatabase(asset);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      print("Tables: $tables");
      
      for (var t in tables) {
        final tableName = t['name'] as String;
        final columns = await db.rawQuery("PRAGMA table_info('$tableName')");
        print("Table $tableName columns: ${columns.map((c) => c['name']).toList()}");
        final rows = await db.query(tableName, limit: 1);
        print("First row: $rows");
      }
      await db.close();
    } catch (e) {
      print("Error on $asset: $e");
    }
  }
}
