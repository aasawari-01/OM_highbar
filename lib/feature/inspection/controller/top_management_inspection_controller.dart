import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum InspectionEndChoice { addMore, endInspection }

class ObservationEntry {
  String? observation;
  String? department;
  String? category;
  final List<File> files = [];

  ObservationEntry();
}

class TopManagementInspectionController extends GetxController {
  final selectedDate = RxnString();
  final selectedDepartment = RxnString();
  final selectedOfficer = RxnString();
  final selectedInspectionType = RxnString('Default Account Holder Designation');
  final selectedLocation = 'Line-1'.obs;
  final locationFromController = TextEditingController();
  final locationToController = TextEditingController();

  final observations = <ObservationEntry>[ObservationEntry()].obs;
  final endChoice = InspectionEndChoice.endInspection.obs;

  static const dateOptions = ['06/01/2026', '07/01/2026', '08/01/2026'];
  static const departmentOptions = ['Signalling', 'Rolling Stock', 'Track', 'Civil', 'Information Technology'];
  static const officerOptions = ['Dharmesh Solanki', 'Rahul Mehta', 'Priya Shah'];
  static const inspectionTypeOptions = ['Default Account Holder Designation', 'General Inspection', 'Routine Inspection'];
  static const locationOptions = ['Line-1', 'Line-2', 'RHD', 'HVPCD', 'OCC', 'BOCC', 'Other'];
  static const observationOptions = ['Observation 1', 'Observation 2', 'Observation 3'];
  static const observationDeptOptions = ['Signalling', 'Rolling Stock', 'Track'];
  static const categoryOptions = ['Deficiency', 'Anomaly', 'Issue'];

  void addObservation() {
    observations.add(ObservationEntry());
  }

  void resetForm() {
    selectedDate.value = null;
    selectedDepartment.value = null;
    selectedOfficer.value = null;
    selectedInspectionType.value = 'Default Account Holder Designation';
    selectedLocation.value = 'Line-1';
    locationFromController.clear();
    locationToController.clear();
    observations.assignAll([ObservationEntry()]);
    endChoice.value = InspectionEndChoice.endInspection;
  }

  @override
  void onClose() {
    locationFromController.dispose();
    locationToController.dispose();
    super.onClose();
  }
}
