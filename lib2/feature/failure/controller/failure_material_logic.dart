import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/label_value.dart';
import 'failure_form_state.dart';

mixin FailureMaterialLogic on GetxController, FailureFormState {

  final isExpandedReplaced = <int, bool>{}.obs;
  final isExpandedDismantle = <int, bool>{}.obs;
  final replacedMaterialsList = <Map<String, dynamic>>[].obs;
  final usedQtyControllers = <int, TextEditingController>{}.obs;
  final usedQtyFocusNodes = <int, FocusNode>{}.obs;
  final dismantleMaterialsList = <Map<String, dynamic>>[].obs;
  final deletedDismantleMaterialsList = <Map<String, dynamic>>[].obs;
  final selectedMaterialCode = RxnString();
  final selectedStoreLocation = RxnString();
  final selectedDismantleMaterialCode = RxnString();
  final editingReplacedMaterialIndex = (-1).obs;
  final editingDismantleMaterialIndex = (-1).obs;
  final measurementPointsList = <Map<String, dynamic>>[].obs;

  void toggleReplacedExpansion(int index) {
    isExpandedReplaced[index] = !(isExpandedReplaced[index] ?? false);
  }

  void toggleDismantleExpansion(int index) {
    isExpandedDismantle[index] = !(isExpandedDismantle[index] ?? false);
  }

  int materialRecordId(Map<String, dynamic> item) {
    final raw = item['id'] ??
        item['Id'] ??
        item['materialReqId'] ??
        item['MaterialReqId'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  int resolveMaterialId(Map<String, dynamic> item) {
    final fromItem =
        item['Materialid'] ?? item['MaterialId'] ?? item['materialid'];
    if (fromItem != null) {
      if (fromItem is int) return fromItem;
      final parsed = int.tryParse(fromItem.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    final code =
        (item['MaterialName'] ?? item['materialCode'])?.toString().trim() ?? '';
    if (code.isEmpty) return 0;
    final match = materialDataList.firstWhere(
          (m) => m.label?.trim() == code,
      orElse: () => LabelValue(value: "0"),
    );
    return int.tryParse(match.value ?? '0') ?? 0;
  }

  int resolveStorageLocationId(Map<String, dynamic> item) {
    final fromItem = item['StorageLocation'] ?? item['storageLocation'];
    if (fromItem is int && fromItem > 0) return fromItem;
    final parsed = int.tryParse(fromItem?.toString() ?? '');
    if (parsed != null && parsed > 0) return parsed;
    final label = (item['storeLocation'] ?? item['storageLocationValue'])
        ?.toString()
        .trim() ??
        '';
    if (label.isEmpty) return 0;
    final match = storageLocationList.firstWhere(
          (s) => s.label?.trim() == label,
      orElse: () => LabelValue(value: "0"),
    );
    return int.tryParse(match.value ?? '0') ?? 0;
  }

  List<Map<String, dynamic>> materialsForSubmit() {
    final seenIds = <int>{};
    final result = <Map<String, dynamic>>[];
    for (final item in replacedMaterialsList) {
      final code = item['materialCode']?.toString().trim() ?? '';
      if (code.isEmpty) continue;
      final recordId = materialRecordId(item);
      if (recordId > 0) {
        if (seenIds.contains(recordId)) continue;
        seenIds.add(recordId);
      }
      result.add(item);
    }
    return result;
  }

  Map<String, dynamic> buildMaterialPayload(Map<String, dynamic> e) {
    final recordId = materialRecordId(e);
    final isExisting = recordId > 0;
    final statusId = isExisting ? 2 : 1;
    return {
      "Materialid": resolveMaterialId(e),
      "MaterialValue": e['MaterialName'] ?? e['materialCode'] ?? "",
      "Quantity": int.tryParse(e['requiredQty']?.toString() ??
          e['Quantity']?.toString() ??
          "0") ??
          0,
      "UnitMeasurement": e['uom'] ?? e['UnitMeasurement'] ?? "",
      "IssuedQty": int.tryParse(e['issuedQty']?.toString() ?? "0") ?? 0,
      "UsedQty": int.tryParse(
          e['usedQty']?.toString() ?? e['UsedQty']?.toString() ?? "0") ??
          0,
      "BalanceQty": int.tryParse(e['balanceQty']?.toString() ??
          e['BalanceQty']?.toString() ??
          "0") ??
          0,
      "RemainingBalanceQTY": e['RemainingBalanceQTY'] ?? 0,
      "StorageLocation": resolveStorageLocationId(e),
      "InsertUpdateStatusId": statusId,
      "CurrentInsertUpdateStatusId": statusId,
      "Id": recordId,
    };
  }

  void addReplacedMaterial() {
    if (selectedMaterialCode.value != null) {
      if (editingReplacedMaterialIndex.value >= 0) {
        final existing =
        replacedMaterialsList[editingReplacedMaterialIndex.value];
        existing['materialCode'] = selectedMaterialCode.value;
        existing['uom'] = uomController.text;
        existing['storeLocation'] = selectedStoreLocation.value;
        existing['balanceQty'] = balanceQtyController.text;
        existing['requiredQty'] = requiredQtyController.text;
        replacedMaterialsList.refresh();
        editingReplacedMaterialIndex.value = -1;
      } else {
        // Shift existing expansion-state keys up by 1 so they still point at the right rows
        final shifted = <int, bool>{};
        isExpandedReplaced.forEach((key, value) {
          shifted[key + 1] = value;
        });
        isExpandedReplaced
          ..clear()
          ..addAll(shifted);

        replacedMaterialsList.insert(0, {
          'materialCode': selectedMaterialCode.value,
          'uom': uomController.text,
          'storeLocation': selectedStoreLocation.value,
          'balanceQty': balanceQtyController.text,
          'requiredQty': requiredQtyController.text,
          'issuedQty': "0",
          'usedQty': "",
        });
        isExpandedReplaced[0] = true;
      }

      selectedMaterialCode.value = null;
      selectedStoreLocation.value = null;
      uomController.clear();
      balanceQtyController.clear();
      requiredQtyController.clear();
    }
  }

  void removeReplacedMaterial(int index) {
    if (index >= 0 && index < replacedMaterialsList.length) {
      replacedMaterialsList.removeAt(index);
      if (editingReplacedMaterialIndex.value == index) {
        editingReplacedMaterialIndex.value = -1;
        selectedMaterialCode.value = null;
        uomController.clear();
        selectedStoreLocation.value = null;
        balanceQtyController.clear();
        requiredQtyController.clear();
      }
    }
  }

  void editReplacedMaterial(int index) {
    final item = replacedMaterialsList[index];
    selectedMaterialCode.value = item['materialCode']?.toString();
    selectedStoreLocation.value = item['storeLocation']?.toString();
    uomController.text = item['uom']?.toString() ?? '';
    balanceQtyController.text = item['balanceQty']?.toString() ?? '';
    requiredQtyController.text = item['requiredQty']?.toString() ?? '';
    editingReplacedMaterialIndex.value = index;
    isExpandedReplaced[index] = true;
  }

  void addDismantleMaterial() {
    if (selectedDismantleMaterialCode.value != null) {
      final selectedMaterial = replacedMaterialsList.firstWhere(
            (m) => m['materialCode'] == selectedDismantleMaterialCode.value,
        orElse: () => <String, dynamic>{},
      );
      final materialId = selectedMaterial['Materialid'] ??
          selectedMaterial['materialId'] ??
          selectedMaterial['materialid'];

      if (editingDismantleMaterialIndex.value >= 0) {
        final existing =
        dismantleMaterialsList[editingDismantleMaterialIndex.value];
        existing['materialCode'] = selectedDismantleMaterialCode.value;
        existing['materialId'] = materialId;
        existing['oldSerialNumber'] = oldSerialNumberController.text;
        existing['oldSerialDismantleDate'] =
            oldSerialDismantleDate.value?.toIso8601String();
        existing['newSerialNumber'] = newSerialNumberController.text;
        existing['newSerialInstallationDate'] =
            newSerialInstallationDate.value?.toIso8601String();
        dismantleMaterialsList.refresh();
        editingDismantleMaterialIndex.value = -1;
      } else {
        // Shift existing expansion-state keys up by 1
        final shifted = <int, bool>{};
        isExpandedDismantle.forEach((key, value) {
          shifted[key + 1] = value;
        });
        isExpandedDismantle
          ..clear()
          ..addAll(shifted);

        dismantleMaterialsList.insert(0, {
          'materialCode': selectedDismantleMaterialCode.value,
          'materialId': materialId,
          'oldSerialNumber': oldSerialNumberController.text,
          'oldSerialDismantleDate':
          oldSerialDismantleDate.value?.toIso8601String(),
          'newSerialNumber': newSerialNumberController.text,
          'newSerialInstallationDate':
          newSerialInstallationDate.value?.toIso8601String(),
        });
        isExpandedDismantle[0] = true;
      }

      selectedDismantleMaterialCode.value = null;
      oldSerialNumberController.clear();
      oldSerialDismantleDate.value = null;
      newSerialNumberController.clear();
      newSerialInstallationDate.value = null;
    }
  }

  void removeDismantleMaterial(int index) {
    if (index >= 0 && index < dismantleMaterialsList.length) {
      final item = dismantleMaterialsList[index];
      final recordId = materialRecordId(item);
      
      // If this is an existing record (has an ID), track it for deletion
      if (recordId > 0) {
        deletedDismantleMaterialsList.add({
          'id': recordId,
          'materialId': item['materialId'],
          'materialCode': item['materialCode'],
          'oldSerialNumber': item['oldSerialNumber'],
          'newSerialNumber': item['newSerialNumber'],
          'oldSerialDismantleDate': item['oldSerialDismantleDate'],
          'newSerialInstallationDate': item['newSerialInstallationDate'],
        });
      }
      
      dismantleMaterialsList.removeAt(index);
      if (editingDismantleMaterialIndex.value == index) {
        editingDismantleMaterialIndex.value = -1;
        selectedDismantleMaterialCode.value = null;
        oldSerialNumberController.clear();
        oldSerialDismantleDate.value = null;
        newSerialNumberController.clear();
        newSerialInstallationDate.value = null;
      }
    }
  }

  void editDismantleMaterial(int index) {
    final item = dismantleMaterialsList[index];
    selectedDismantleMaterialCode.value = item['materialCode']?.toString();
    oldSerialNumberController.text = item['oldSerialNumber']?.toString() ?? '';
    newSerialNumberController.text = item['newSerialNumber']?.toString() ?? '';

    if (item['oldSerialDismantleDate'] != null) {
      oldSerialDismantleDate.value =
          DateTime.tryParse(item['oldSerialDismantleDate']);
    } else {
      oldSerialDismantleDate.value = null;
    }

    if (item['newSerialInstallationDate'] != null) {
      newSerialInstallationDate.value =
          DateTime.tryParse(item['newSerialInstallationDate']);
    } else {
      newSerialInstallationDate.value = null;
    }

    editingDismantleMaterialIndex.value = index;
    isExpandedDismantle[index] = true;
  }
}
