import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/je_inspection_item.dart';
import '../service/inspection_service.dart';

/// Inspection types the JE list can open, keyed by the API `url`.
enum InspectionKind { commonChecklist, bms, dgLog, loadDetails, cabPetrolling, bufferStop, pilotTrain, weld, creep, foot, omsAction, temperature, toeLoad }

/// State and filtering of the JE inspection list screen.
class JEInspectionListController extends GetxController {
  static const allTab = 'All';

  final _service = InspectionService();

  final items = <JEInspectionItem>[].obs;
  final loading = true.obs;
  final statusFilter = allTab.obs;
  final searching = false.obs;
  final query = ''.obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    items.assignAll(await _service.getJEInspectionList());
    loading.value = false;
  }

  String _route(JEInspectionItem e) =>
      e.url.trim().replaceFirst(RegExp(r'^/+'), '').toLowerCase();

  InspectionKind? kindOf(JEInspectionItem e) {
    switch (_route(e)) {
      case 'commoninsepectionchecklist':
        return InspectionKind.commonChecklist;
      case 'bms':
        return InspectionKind.bms;
      case 'loaddetails':
        return InspectionKind.loadDetails;
      case 'cabpetrollingaction':
        return InspectionKind.cabPetrolling;
      case 'bufferstop':
        return InspectionKind.bufferStop;
      case 'dglogbook':
        return InspectionKind.dgLog;
      case 'pilottraininspection':
        return InspectionKind.pilotTrain;
      case 'weldinspection':
        return InspectionKind.weld;
      case 'creeprequest':
        return InspectionKind.creep;
      case 'footinspection':
        return InspectionKind.foot;
      case 'omsaction':
        return InspectionKind.omsAction;
      case 'temperaturemonitoring':
        return InspectionKind.temperature;
      case 'toeloadtesting':
        return InspectionKind.toeLoad;
      default:
        return null;
    }
  }

  List<JEInspectionItem> get _supported =>
      items.where((e) => kindOf(e) != null).toList();

  List<String> get statusTabs {
    final unique = _supported
        .map((e) => e.statusText)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return [allTab, ...unique];
  }

  List<JEInspectionItem> get filtered {
    final q = query.value.trim().toLowerCase();
    return _supported.where((e) {
      if (statusFilter.value != allTab && e.statusText != statusFilter.value) {
        return false;
      }
      if (q.isEmpty) return true;
      return [
        e.inspectionNo,
        e.inspectionName,
        e.createdName,
        e.inspectionType,
        e.deptName,
        e.inspectionScheduledDate,
        e.statusText,
      ].any((v) => v.toLowerCase().contains(q));
    }).toList();
  }

  void toggleSearch() {
    searching.value = !searching.value;
    if (!searching.value) {
      searchController.clear();
      query.value = '';
    }
  }

  /// Skips [item] with [remark]; reloads the list on success.
  Future<bool> skip(JEInspectionItem item, String remark) async {
    loading.value = true;
    final ok = await _service.skipInspection(id: item.id, remark: remark);
    if (ok) {
      await load();
    } else {
      loading.value = false;
    }
    return ok;
  }
}
