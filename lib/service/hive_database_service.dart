import 'package:get/get.dart';

import 'package:hive_flutter/adapters.dart';

class HiveService extends GetxService {
  final Map<String, Box> _openBoxes = {};

  Future<HiveService> init() async {
    await Hive.initFlutter();
    return this;
  }

  Future<Box> _getBox(String boxName) async {
    if (_openBoxes.containsKey(boxName)) return _openBoxes[boxName]!;
    final box = await Hive.openBox(boxName);
    _openBoxes[boxName] = box;
    return box;
  }

  // upsert single record
  Future<void> put(String boxName, String key, Map<String, dynamic> value) async {
    final box = await _getBox(boxName);
    await box.put(key, value);
  }

  // upsert many at once (bulk sync)
  Future<void> putAll(String boxName, Map<String, Map<String, dynamic>> entries) async {
    final box = await _getBox(boxName);
    await box.putAll(entries);
  }

  Map<String, dynamic>? get(String boxName, String key) {
    final box = _openBoxes[boxName];
    return box?.get(key)?.cast<String, dynamic>();
  }

  List<Map<String, dynamic>> getAll(String boxName) {
    final box = _openBoxes[boxName];
    if (box == null) return [];
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> delete(String boxName, String key) async {
    final box = await _getBox(boxName);
    await box.delete(key);
  }

  Future<void> deleteKeys(String boxName, List<String> keys) async {
    final box = await _getBox(boxName);
    await box.deleteAll(keys);
  }

  Future<void> clearBox(String boxName) async {
    final box = await _getBox(boxName);
    await box.clear();
  }

  Future<void> ensureBoxOpen(String boxName) async => _getBox(boxName);
}