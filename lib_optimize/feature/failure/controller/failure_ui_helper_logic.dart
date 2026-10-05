import 'package:flutter/material.dart';
import 'package:om_mobile/utils/widgets/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/models/label_value.dart';
import '../../../constants/colors.dart';
import 'failure_form_state.dart';

mixin FailureUIHelperLogic on GetxController, FailureFormState {
  void showErrorDialog(String message);

  String? labelForValue(List<LabelValue> list, dynamic value) {
    final valueText = value?.toString().trim();
    if (valueText == null || valueText.isEmpty || valueText == "0") {
      return null;
    }
    final matched = list.firstWhere(
          (e) => e.value?.toString().trim() == valueText,
      orElse: () => LabelValue(label: null),
    );
    return matched.label?.toString().trim().isNotEmpty == true
        ? matched.label
        : valueText;
  }

  String? textOrNull(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String mapFailureTypeIdToMaterialType(int? failureTypeId) {
    switch (failureTypeId) {
      case 1:
        return "Software";
      case 2:
        return "Hardware";
      case 3:
        return "Communication";
      case 4:
        return "Other";
      default:
        return "";
    }
  }

  Map<String, dynamic> locationByName(String? locationLabel) {
    if (locationLabel == null || locationLabel == 'Select') return {};
    return masterLocations.firstWhere(
          (e) => e['locationName']?.toString() == locationLabel,
      orElse: () => <String, dynamic>{},
    );
  }

  // Maintenance form UI helper methods
  void showMeasurementPopup() {
    Get.dialog(
      AlertDialog(
        title: const Text('Measurement Reading'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select measurement points to take readings:'),
              const SizedBox(height: 16),
              ...measurementPoints.asMap().entries.map((entry) {
                final index = entry.key;
                final point = entry.value;
                return CheckboxListTile(
                  title: Text(point['measurementPoint'] ?? ''),
                  subtitle: Text('${point['description'] ?? ''} (${point['unit'] ?? ''})'),
                  value: point['isReadingRequired'] ?? false,
                  onChanged: (value) {
                    measurementPoints[index]['isReadingRequired'] = value;
                    measurementPoints.refresh();
                  },
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final hasReading = measurementPoints.any((p) => p['isReadingRequired'] == true);
              if (hasReading) {
                Get.back();
                appSnackbar(
                  'Success',
                  'Measurement readings saved successfully',
                  backgroundColor: const Color(0xFF4CAF50),
                  colorText: Colors.white,
                );
              } else {
                appSnackbar(
                  'Error',
                  'Please select at least one measurement point',
                  backgroundColor: const Color(0xFFF44336),
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void removeMeasurementPoint(int index) {
    measurementPoints.removeAt(index);
  }

  Future<void> pickBeforeFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        for (var file in result.files) {
          final sizeInMb = file.size / (1024 * 1024);
          if (sizeInMb > 1) {
            appSnackbar('Error', 'File size must be less than 1MB',
              backgroundColor: const Color(0xFFF44336),
              colorText: Colors.white,
            );
            continue;
          }
          beforeFiles.add({
            'name': file.name,
            'size': '${sizeInMb.toStringAsFixed(1)} MB',
            'path': file.path,
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
      appSnackbar('Error', 'Could not pick file',
        backgroundColor: const Color(0xFFF44336),
        colorText: Colors.white,
      );
    }
  }

  String? locationCodeForLabel(String? locationLabel) {
    final loc = locationByName(locationLabel);
    final code = loc['locationTypeCode']?.toString();
    debugPrint("_locationCodeForLabel: locationLabel=$locationLabel, locationTypeCode=$code");
    debugPrint("_locationCodeForLabel: full location data=$loc");
    debugPrint("_locationCodeForLabel: All location fields - locationTypeCode=${loc['locationTypeCode']}, locationTypeId=${loc['locationTypeId']}, locationTypeName=${loc['locationTypeName']}, plantId=${loc['plantId']}");
    return (code != null && code.isNotEmpty) ? code : null;
  }

  void resetFunctionalAndEquipmentSelections() {
    selectedFunctionalLocation.value = 'Select';
    selectedEquipmentNumber.value = 'Select';
    showMeasurementButton.value = false;
  }

  void resetLocationFunctionalAndEquipmentSelections() {
    selectedFunctionalLocation.value = 'Select';
    selectedEquipmentNumber.value = 'Select';
    showMeasurementButton.value = false;
  }

  void setLocationOptions(List<Map<String, dynamic>> locs) {
    locationTypeList.clear();
    locationTypeList.add(LabelValue(label: 'Select', value: ''));
    locationTypeList.addAll(
      locs
          .where((e) => (e['locationName']?.toString() ?? '').isNotEmpty && (e['locationName']?.toString() ?? '').toLowerCase() != 'select')
          .map((e) => LabelValue(
        label: e['locationName']?.toString() ?? '',
        value: e['locationTypeCode']?.toString() ?? '', // Use locationTypeCode instead of locationTypeId
      ))
          .toList(),
    );
  }

  void setFunctionalLocationOptions(List<Map<String, dynamic>> funcs) {
    functionalLocationList.clear();
    functionalLocationList.add(LabelValue(label: 'Select', value: ''));
    functionalLocationList.addAll(
      funcs
          .where((e) => (e['funcLocationName']?.toString() ?? '').isNotEmpty && (e['funcLocationName']?.toString() ?? '').toLowerCase() != 'select')
          .map((e) => LabelValue(
        // Display Functional Location Name as the label
        label: e['funcLocationName']?.toString() ?? '',
        value: e['funcLocId']?.toString() ?? '',
      ))
          .toList(),
    );
  }

  void setEquipmentOptions(List<Map<String, dynamic>> equips) {
    // If the currently selected equipment would disappear because it's not in
    // the newly filtered set (e.g. it came from an API response not yet synced
    // to local DB), keep that ONE entry so the field doesn't go blank.
    // Everything else from the previous list is dropped — that's the whole point of filtering.
    final currentSelectionLabel = selectedEquipmentNumber.value;
    LabelValue? preserved;
    if (currentSelectionLabel != null &&
        currentSelectionLabel.trim().isNotEmpty &&
        currentSelectionLabel != 'Select') {
      final alreadyInFiltered =
          equips.any((e) => (e['equipmentName']?.toString() ?? '') == currentSelectionLabel);
      if (!alreadyInFiltered) {
        preserved = equipmentList.firstWhere(
              (e) => e.label == currentSelectionLabel,
          orElse: () => LabelValue(label: null),
        );
      }
    }

    equipmentList.clear();
    equipmentList.add(LabelValue(label: 'Select', value: ''));
    equipmentList.addAll(
      equips
          .where((e) => (e['equipmentName']?.toString() ?? '').isNotEmpty && (e['equipmentName']?.toString().toLowerCase() != 'select'))
          .map((e) => LabelValue(
        label: e['equipmentName']?.toString() ?? '',
        value: e['equipId']?.toString() ?? '',
      ))
          .toList(),
    );

    // Restore the preserved selection if it was filtered out
    if (preserved != null && preserved.label != null) {
      if (!equipmentList.any((e) => e.label == preserved!.label)) {
        equipmentList.add(preserved);
      }
    }
  }

  void ensureDropdownOption(RxList<LabelValue> list, String label, String value) {
    if (label.trim().isEmpty) return;
    if (label.trim().toLowerCase() == 'select') return;
    if (!list.any((e) => e.label?.trim() == label.trim())) {
      list.add(LabelValue(label: label.trim(), value: value));
    }
  }
}
