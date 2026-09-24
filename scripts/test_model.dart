import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

// Dummy model matching the actual model logic
class FunctionalLocationModel {
  final int? funcLocId;
  final String funcLocation;
  final String funcDescription;
  final String funcLocationName;
  final String techObjectType;
  final String subSystem;

  FunctionalLocationModel({
    this.funcLocId,
    required this.funcLocation,
    required this.funcDescription,
    required this.funcLocationName,
    required this.techObjectType,
    required this.subSystem,
  });

  factory FunctionalLocationModel.fromJson(Map<String, dynamic> json) {
    final map = json.map((key, value) => MapEntry(key.toLowerCase(), value));
    
    final funcLoc = (map['funclocation'] ?? map['funcloc'])?.toString() ?? '';
    final funcDesc = (map['funcdescription'] ?? map['description'])?.toString() ?? '';
    String rawName = map['funclocationname']?.toString() ?? '';
    if (rawName.isEmpty || rawName == funcDesc || rawName == funcLoc) {
      if (funcLoc.isNotEmpty && funcDesc.isNotEmpty) {
        rawName = '$funcLoc - $funcDesc';
      }
    }

    return FunctionalLocationModel(
      funcLocId: (map['funclocid'] ?? map['funclocid']) != null ? int.tryParse(map['funclocid'].toString()) : null,
      funcLocation: funcLoc,
      funcDescription: funcDesc,
      funcLocationName: rawName,
      techObjectType: map['techobjecttype']?.toString() ?? '',
      subSystem: map['subsystem']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'funcLocId': funcLocId,
    'funcLocation': funcLocation,
    'techObjectType': techObjectType,
    'subSystem': subSystem,
  };
}

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  var dbPath = p.join(Directory.current.path, 'assets', 'fun_loc.db');
  var db = await databaseFactory.openDatabase(dbPath);
  
  var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  if (tables.isNotEmpty) {
    String tableName = tables[0]['name'] as String;
    var result = await db.rawQuery('SELECT * FROM "$tableName" WHERE FuncLocId = 47865');
    if (result.isNotEmpty) {
      print("Raw DB Map: ${result.first}");
      var model = FunctionalLocationModel.fromJson(result.first);
      print("Model json output: ${model.toJson()}");
    }
  }
  
  await db.close();
}
