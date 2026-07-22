// import 'package:flutter/cupertino.dart';
//
// /// A generic key-value model used across all dropdown and list APIs.
// class LabelValue {
//   final String? label;
//   final String? value;
//   final dynamic uniqueId;
//
//   LabelValue({this.label, this.value, this.uniqueId});
//
//   factory LabelValue.fromJson(Map<String, dynamic> json) {
//     // Try case-insensitive lookup for common field name variations
//     String? label;
//     String? value;
//     dynamic uniqueId;
//
//     for (var key in json.keys) {
//       final keyLower = key.toString().toLowerCase();
//       if (label == null && (keyLower == 'label' || keyLower == 'name' || keyLower == 'text' || keyLower == 'displayname' || keyLower == 'deptname')) {
//         label = json[key]?.toString();
//       }
//       if (value == null && (keyLower == 'value' || keyLower == 'id' || keyLower == 'code' || keyLower == 'deptid')) {
//         value = json[key]?.toString();
//       }
//       if (uniqueId == null && (keyLower == 'uniqueid' || keyLower == 'unique_id')) {
//         uniqueId = json[key];
//       }
//       // Store workCenter in uniqueId if present (for department filtering)
//       if (uniqueId == null && keyLower == 'workcenter') {
//         uniqueId = json[key]?.toString();
//       }
//     }
//
//     if (label == null && value == null) {
//       debugPrint("LabelValue.fromJson: Both label and value are null. JSON keys: ${json.keys.toList()}, JSON: $json");
//     }
//     return LabelValue(
//       label: label,
//       value: value,
//       uniqueId: uniqueId,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'label': label,
//       'value': value,
//       if (uniqueId != null) 'uniqueId': uniqueId,
//     };
//   }
//
//   @override
//   String toString() => 'LabelValue(label: $label, value: $value)';
// }


import 'package:flutter/cupertino.dart';

/// A generic key-value model used across all dropdown and list APIs.
class LabelValue {
  final String? label;
  final String? value;
  final dynamic uniqueId;
  final String? code;

  LabelValue({
    this.label,
    this.value,
    this.uniqueId,
    this.code,
  });

  factory LabelValue.fromJson(Map<String, dynamic> json) {
    String? label;
    String? value;
    dynamic uniqueId;
    String? code;

    for (var key in json.keys) {
      final keyLower = key.toString().toLowerCase();

      if (label == null &&
          (keyLower == 'label' ||
              keyLower == 'name' ||
              keyLower == 'text' ||
              keyLower == 'displayname' ||
              keyLower == 'deptname')) {
        label = json[key]?.toString();
      }

      if (value == null &&
          (keyLower == 'value' ||
              keyLower == 'id' ||
              keyLower == 'deptid')) {
        value = json[key]?.toString();
      }

      if (code == null && keyLower == 'code') {
        code = json[key]?.toString();
      }

      if (uniqueId == null &&
          (keyLower == 'uniqueid' || keyLower == 'unique_id')) {
        uniqueId = json[key];
      }

      // Store workCenter in uniqueId if present
      if (uniqueId == null && keyLower == 'workcenter') {
        uniqueId = json[key]?.toString();
      }
    }

    if (label == null && value == null) {
      debugPrint(
        "LabelValue.fromJson: Both label and value are null. JSON: $json",
      );
    }

    return LabelValue(
      label: label,
      value: value,
      uniqueId: uniqueId,
      code: code,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'uniqueId': uniqueId,
      'code': code,
    };
  }

  @override
  String toString() {
    return 'LabelValue(label: $label, value: $value, code: $code, uniqueId: $uniqueId)';
  }
}
