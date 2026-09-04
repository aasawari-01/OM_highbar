// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:om_mobile/service/auth_manager.dart';
//
// import '../../../service/network_service/api_client.dart';
//
// import '../model/occ_to_sc_model.dart';
// import '../service/occ_to_sc_service.dart';
//
// class OccScCommunicationController extends GetxController {
//   OccScCommunicationController({
//     OccToScService? occToScService,
//   }) : _occToScService = occToScService ?? OccToScService();
//
//   final OccToScService _occToScService;
//
//   // ---------------------------------------------------------------------
//   // Form
//   // ---------------------------------------------------------------------
//   final formKey = GlobalKey<FormState>();
//
//   // ---------------------------------------------------------------------
//   // Loading
//   // ---------------------------------------------------------------------
//   final RxBool isLoading = false.obs;
//   final RxBool isSubmitting = false.obs;
//
//   // ---------------------------------------------------------------------
//   // Instruction type constants
//   // ---------------------------------------------------------------------
//   static const String kTechnicalType = 'Technical';
//   static const String kEmergencyType = 'Emergency';
//
//   // ---------------------------------------------------------------------
//   // Master data
//   // ---------------------------------------------------------------------
//   final RxList<MasterDataItem> instructionTypeList =
//       <MasterDataItem>[].obs;
//
//   final RxList<MasterDataItem> instructedByList =
//       <MasterDataItem>[].obs;
//
//   final RxList<DepartmentModel> departmentList =
//       <DepartmentModel>[].obs;
//
//   final RxList<MasterDataItem> emergencyTypeList =
//       <MasterDataItem>[].obs;
//
//   final RxList<LineModel> lineList =
//       <LineModel>[].obs;
//
//   // ---------------------------------------------------------------------
//   // Derived lists
//   // ---------------------------------------------------------------------
//   final RxList<SystemModel> systemList =
//       <SystemModel>[].obs;
//
//   final RxList<StationModel> stationList =
//       <StationModel>[].obs;
//
//   // ---------------------------------------------------------------------
//   // Single select
//   // ---------------------------------------------------------------------
//   final Rx<String?> selectedInstructionType =
//   Rx<String?>(null);
//
//   final Rx<String?> selectedInstructedBy =
//   Rx<String?>(null);
//
//   // ---------------------------------------------------------------------
//   // Station type
//   //
//   // U = Under Ground
//   // A = Elevated
//   // ---------------------------------------------------------------------
//   final RxList<String> selectedStationTypes =
//       <String>[].obs;
//
//   final List<String> stationTypeList = const [
//     'U',
//     'A',
//   ];
//
//   String getStationTypeLabel(String value) {
//     switch (value) {
//       case 'U':
//         return 'Under Ground';
//       case 'A':
//         return 'Elevated';
//       default:
//         return value;
//     }
//   }
//
//   // ---------------------------------------------------------------------
//   // Multi select
//   // ---------------------------------------------------------------------
//   final RxList<String> selectedLines =
//       <String>[].obs;
//
//   final RxList<String> selectedStations =
//       <String>[].obs;
//
//   final RxList<String> selectedDepartments =
//       <String>[].obs;
//
//   final RxList<String> selectedSystems =
//       <String>[].obs;
//
//   final RxList<String> selectedEmergencyTypes =
//       <String>[].obs;
//
//   // ---------------------------------------------------------------------
//   // Description
//   // ---------------------------------------------------------------------
//   final TextEditingController descriptionController =
//   TextEditingController();
//
//   // ---------------------------------------------------------------------
//   // Files
//   // ---------------------------------------------------------------------
//   static const int kMaxFiles = 3;
//
//   final Rx<String?> fileError = Rx<String?>(null);
//
//   final RxList<Map<String, dynamic>> uploadedFiles =
//       <Map<String, dynamic>>[].obs;
//
//
//
//   // ---------------------------------------------------------------------
//   // Conditional helpers
//   // ---------------------------------------------------------------------
//   bool get isTechnical =>
//       selectedInstructionType.value == kTechnicalType;
//
//   bool get isEmergency =>
//       selectedInstructionType.value == kEmergencyType;
//
//
//
//
//   // ---------------------------------------------------------------------
// // Date fields
// // ---------------------------------------------------------------------
//
//   final Rx<DateTime> issueDate = DateTime.now().obs;
//
//   final Rx<DateTime?> validUptoDate = Rx<DateTime?>(null);
//
//   DateTime get today {
//     final now = DateTime.now();
//
//     return DateTime(
//       now.year,
//       now.month,
//       now.day,
//     );
//   }
//
//   void setIssueDate(DateTime? date) {
//     if (date == null) return;
//
//     final selected = DateTime(
//       date.year,
//       date.month,
//       date.day,
//     );
//
//     issueDate.value = selected;
//
//     // If Valid Upto was already selected and
//     // becomes invalid, clear it.
//     if (validUptoDate.value != null &&
//         validUptoDate.value!.isBefore(selected)) {
//       validUptoDate.value = null;
//     }
//   }
//
//   void setValidUptoDate(DateTime? date) {
//     if (date == null) return;
//
//     validUptoDate.value = DateTime(
//       date.year,
//       date.month,
//       date.day,
//     );
//   }
//   // ---------------------------------------------------------------------
//   // Lifecycle
//   // ---------------------------------------------------------------------
//   @override
//   void onInit() {
//     super.onInit();
//     fetchMasterData();
//   }
//
//   @override
//   void onClose() {
//     descriptionController.dispose();
//     super.onClose();
//   }
//
//   // ---------------------------------------------------------------------
//   // Fetch master data
//   // ---------------------------------------------------------------------
//   Future<void> fetchMasterData() async {
//     isLoading.value = true;
//
//     try {
//       // final dynamic storedUserId =
//       // ApiClient.box.read('userId');
//
//       final String? userId= await AuthManager().getUserId();
//
//       // final dynamic storedUserId =
//       // 1;
//       //
//       // final int userId =
//       // storedUserId is int
//       //     ? storedUserId
//       //     : int.tryParse(
//       //   storedUserId?.toString() ?? '0',
//       // ) ??
//       //     0;
//
//       debugPrint(
//         'Fetching OCC to SC master data. userId = $userId',
//       );
//
//       final response =
//       await _occToScService.getOccToScMasterData(
//         userId: userId??'',
//       );
//
//       if (!response.success) {
//         throw OccToScException(
//           response.message.isNotEmpty
//               ? response.message
//               : 'Unable to fetch master data.',
//         );
//       }
//
//       final data = response.data;
//
//       instructionTypeList.assignAll(
//         data.instructionTypes,
//       );
//
//       instructedByList.assignAll(
//         data.instructionBy,
//       );
//
//       departmentList.assignAll(
//         data.departments,
//       );
//
//       emergencyTypeList.assignAll(
//         data.emergencyTypes,
//       );
//
//       lineList.assignAll(
//         data.lines,
//       );
//
//       debugPrint(
//         'Master data loaded successfully',
//       );
//     } catch (e,stacktrace) {
//       debugPrint(
//         'Master data error: $e--- $stacktrace',
//       );
//
//       Get.snackbar(
//         'Error',
//         e is OccToScException
//             ? e.message
//             : 'Unable to load master data.',
//         backgroundColor:
//         Colors.red.withOpacity(0.9),
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   // ---------------------------------------------------------------------
//   // Instruction type
//   // ---------------------------------------------------------------------
//   void onInstructionTypeChanged(String? value) {
//     selectedInstructionType.value = value;
//
//     if (!isTechnical) {
//       selectedDepartments.clear();
//       selectedSystems.clear();
//       systemList.clear();
//     }
//
//     if (!isEmergency) {
//       selectedEmergencyTypes.clear();
//     }
//   }
//
//   // ---------------------------------------------------------------------
//   // Department -> System
//   // ---------------------------------------------------------------------
//   void setSelectedDepartments(
//       List<String> values,
//       ) {
//     selectedDepartments.assignAll(values);
//
//     _refreshSystemOptions();
//   }
//
//   DepartmentModel? _findDepartment(
//       String name,
//       ) {
//     for (final department in departmentList) {
//       if (department.name == name) {
//         return department;
//       }
//     }
//
//     return null;
//   }
//
//   void _refreshSystemOptions() {
//     final Set<String> seen = <String>{};
//
//     final List<SystemModel> combined =
//     <SystemModel>[];
//
//     for (final departmentName
//     in selectedDepartments) {
//       final department =
//       _findDepartment(departmentName);
//
//       if (department == null) {
//         continue;
//       }
//
//       for (final system
//       in department.systems) {
//         if (seen.add(system.name)) {
//           combined.add(system);
//         }
//       }
//     }
//
//     systemList.assignAll(combined);
//
//     final validSystems =
//     combined.map((e) => e.name).toSet();
//
//     selectedSystems.removeWhere(
//           (system) =>
//       !validSystems.contains(system),
//     );
//   }
//
//   void setSelectedSystems(
//       List<String> values,
//       ) {
//     selectedSystems.assignAll(values);
//   }
//
//   // ---------------------------------------------------------------------
//   // Line -> Station
//   // ---------------------------------------------------------------------
// // ---------------------------------------------------------------------
// // Line -> Station Type -> Station
// // ---------------------------------------------------------------------
//
//   void setSelectedLines(List<String> values) {
//     selectedLines.assignAll(values);
//
//     // Rebuild station options using the current
//     // selected lines + selected station types.
//     _refreshStationOptions();
//
//     // Remove invalid selected stations.
//     final validStations =
//     stationList.map((e) => e.name).toSet();
//
//     selectedStations.removeWhere(
//           (station) => !validStations.contains(station),
//     );
//   }
//
//   LineModel? _findLine(String name) {
//     for (final line in lineList) {
//       if (line.name == name) {
//         return line;
//       }
//     }
//
//     return null;
//   }
//
//   void setSelectedStationTypes(List<String> values) {
//     selectedStationTypes.assignAll(values);
//
//     // Rebuild stations whenever station type changes.
//     _refreshStationOptions();
//
//     // Remove stations that are no longer valid.
//     final validStations =
//     stationList.map((e) => e.name).toSet();
//
//     selectedStations.removeWhere(
//           (station) => !validStations.contains(station),
//     );
//   }
//
//   void _refreshStationOptions() {
//     final Set<String> seen = <String>{};
//     final List<StationModel> combined =
//     <StationModel>[];
//
//     // Line is required before we can show stations.
//     if (selectedLines.isEmpty) {
//       stationList.clear();
//       return;
//     }
//
//     // Station Type is also required.
//     if (selectedStationTypes.isEmpty) {
//       stationList.clear();
//       return;
//     }
//
//     for (final lineName in selectedLines) {
//       final line = _findLine(lineName);
//
//       if (line == null) {
//         continue;
//       }
//
//       for (final station in line.stations) {
//         final stationType =
//         normalizeStationType(
//           station.stationType,
//         );
//
//         // Station must match ANY selected type.
//         if (selectedStationTypes.contains(
//           stationType,
//         )) {
//           if (seen.add(station.name)) {
//             combined.add(station);
//           }
//         }
//       }
//     }
//
//     stationList.assignAll(combined);
//   }
//
//   void setSelectedStations(List<String> values) {
//     selectedStations.assignAll(values);
//   }
//
// // ---------------------------------------------------------------------
// // Station Type
// // ---------------------------------------------------------------------
//
//
//
//   String normalizeStationType(String stationType) {
//     final String value =
//     stationType.trim().toUpperCase();
//
//     // Your API currently returns E for elevated.
//     // UI uses A for Elevated.
//     if (value == 'E') {
//       return 'A';
//     }
//
//     if (value == 'U') {
//       return 'U';
//     }
//
//     if (value == 'A') {
//       return 'A';
//     }
//
//     return value;
//   }
//
//
//
//
//
//
//
//   // ---------------------------------------------------------------------
//   // Emergency type
//   // ---------------------------------------------------------------------
//   void setSelectedEmergencyTypes(
//       List<String> values,
//       ) {
//     selectedEmergencyTypes.assignAll(values);
//   }
//
//   // ---------------------------------------------------------------------
//   // Files
//   // ---------------------------------------------------------------------
//   void addUploadedFile(Map<String, dynamic> file) {
//     // Maximum 3 files are allowed.
//     if (uploadedFiles.length >= kMaxFiles) {
//       fileError.value =
//       'You can upload maximum $kMaxFiles files';
//
//       return;
//     }
//
//     uploadedFiles.add(file);
//     fileError.value = null;
//   }
//
//   void removeUploadedFile(
//       Map<String, dynamic> file,
//       ) {
//     uploadedFiles.remove(file);
//
//     if (uploadedFiles.length < kMaxFiles) {
//       fileError.value = null;
//     }
//   }
//   // bool _validateFiles() {
//   //   if (uploadedFiles.length < kMinFiles) {
//   //     fileError.value =
//   //     'Please upload at least $kMinFiles files';
//   //
//   //     return false;
//   //   }
//   //
//   //   fileError.value = null;
//   //
//   //   return true;
//   // }
//
//   // ---------------------------------------------------------------------
//   // Validation
//   // ---------------------------------------------------------------------
//   String? requiredDropdown(
//       String? value,
//       String label,
//       ) {
//     if (value == null ||
//         value.trim().isEmpty) {
//       return '$label is required';
//     }
//
//     return null;
//   }
//
//   String? requiredMultiSelect(
//       List<String>? values,
//       String label,
//       ) {
//     if (values == null ||
//         values.isEmpty) {
//       return '$label is required';
//     }
//
//     return null;
//   }
//
//   bool validateForm() {
//     final bool formValid =
//         formKey.currentState?.validate() ??
//             false;
//
//     // final bool filesValid =
//     // _validateFiles();
//
//     bool conditionalValid = true;
//
//     if (isTechnical) {
//       conditionalValid =
//           selectedDepartments.isNotEmpty &&
//               selectedSystems.isNotEmpty;
//     }
//
//     if (isEmergency) {
//       conditionalValid =
//           conditionalValid &&
//               selectedEmergencyTypes.isNotEmpty;
//     }
//
//     final bool stationTypeValid =
//         selectedStationTypes.isNotEmpty;
//
//     return formValid &&
//
//         conditionalValid &&
//         selectedLines.isNotEmpty &&
//         selectedStations.isNotEmpty &&
//         stationTypeValid;
//   }
//
//   // ---------------------------------------------------------------------
//   // Submit
//   // ---------------------------------------------------------------------
//   // Future<void> submitReportIssue() async {
//   //   if (!validateForm()) {
//   //     Get.snackbar(
//   //       'Validation Error',
//   //       'Please fill all compulsory fields marked with *',
//   //       backgroundColor:
//   //       Colors.red.withOpacity(0.9),
//   //       colorText: Colors.white,
//   //       snackPosition: SnackPosition.BOTTOM,
//   //     );
//   //
//   //     return;
//   //   }
//   //
//   //   isSubmitting.value = true;
//   //
//   //   try {
//   //     final Map<String, dynamic> payload = {
//   //       'instructedBy':
//   //       selectedInstructedBy.value,
//   //
//   //       'instructionType':
//   //       selectedInstructionType.value,
//   //
//   //       'stationType':
//   //       selectedStationTypes.toList(),
//   //
//   //       'lines':
//   //       selectedLines.toList(),
//   //
//   //       'issueDate': issueDate.value.toIso8601String(),
//   //       'validUpto': validUptoDate.value?.toIso8601String(),
//   //
//   //       'stations':
//   //       selectedStations.toList(),
//   //
//   //
//   //       if (isTechnical)
//   //         'departments':
//   //         selectedDepartments.toList(),
//   //
//   //       if (isTechnical)
//   //         'systems':
//   //         selectedSystems.toList(),
//   //
//   //       if (isEmergency)
//   //         'emergencyTypes':
//   //         selectedEmergencyTypes.toList(),
//   //
//   //       'description':
//   //       descriptionController.text.trim(),
//   //
//   //       'files': uploadedFiles
//   //           .map(
//   //             (file) => file['path'],
//   //       )
//   //           .where(
//   //             (path) => path != null,
//   //       )
//   //           .toList(),
//   //     };
//   //
//   //     debugPrint(
//   //       'OCC to SC payload: $payload',
//   //     );
//   //
//   //     // TODO:
//   //     // Call your actual OCC -> SC submit API here.
//   //     //
//   //     // final response = await _occToScService.submit(...);
//   //
//   //     Get.back();
//   //
//   //     Get.snackbar(
//   //       'Success',
//   //       'Issue reported successfully.',
//   //       backgroundColor:
//   //       Colors.green.withOpacity(0.9),
//   //       colorText: Colors.white,
//   //       snackPosition: SnackPosition.BOTTOM,
//   //     );
//   //   } catch (e) {
//   //     Get.snackbar(
//   //       'Error',
//   //       'Unable to report issue.',
//   //       backgroundColor:
//   //       Colors.red.withOpacity(0.9),
//   //       colorText: Colors.white,
//   //       snackPosition: SnackPosition.BOTTOM,
//   //     );
//   //   } finally {
//   //     isSubmitting.value = false;
//   //   }
//   // }
//
//   Future<void> submitReportIssue() async {
//     if (!validateForm()) {
//       Get.snackbar(
//         'Validation Error',
//         'Please fill all compulsory fields marked with *',
//         backgroundColor: Colors.red.withOpacity(0.9),
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//
//       return;
//     }
//
//     final int? instructionTypeId =
//     _idForName(instructionTypeList, selectedInstructionType.value);
//
//     final int? instructionById =
//     _idForName(instructedByList, selectedInstructedBy.value);
//
//     if (instructionTypeId == null || instructionById == null) {
//       Get.snackbar(
//         'Error',
//         'Invalid Instruction Type / Instructed By selection.',
//         backgroundColor: Colors.red.withOpacity(0.9),
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//
//       return;
//     }
//
//     List<Map<String, dynamic>>? technicalDetails;
//
//     if (isTechnical) {
//       technicalDetails = _buildTechnicalDetails();
//     }
//
//     int? emergencyTypeId;
//
//     if (isEmergency) {
//       emergencyTypeId = _selectedEmergencyTypeId();
//
//       if (emergencyTypeId == null) {
//         Get.snackbar(
//           'Error',
//           'Please select a valid Emergency Type.',
//           backgroundColor: Colors.red.withOpacity(0.9),
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//         );
//
//         return;
//       }
//     }
//
//     isSubmitting.value = true;
//
//     try {
//       final response = await _occToScService.createOccInstruction(
//         issueDate: issueDate.value,
//         validityUpto: validUptoDate.value ?? issueDate.value,
//         instructionTypeId: instructionTypeId,
//         instructionById: instructionById,
//         emergencyTypeId: emergencyTypeId,
//         instructionContent: descriptionController.text.trim(),
//         stationIds: _selectedStationIds(),
//         technicalDetails: technicalDetails,
//         createdBy: await _currentUserId(),
//         files: uploadedFiles,
//       );
//
//       if (!response.success) {
//         throw OccToScException(
//           response.message.isNotEmpty
//               ? response.message
//               : 'Unable to submit instruction.',
//         );
//       }
//
//       Get.back();
//
//       Get.snackbar(
//         'Success',
//         'Issue reported successfully.',
//         backgroundColor: Colors.green.withOpacity(0.9),
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } catch (e,stacktrace) {
//
//       print("stack trace is $stacktrace");
//       Get.snackbar(
//         'Error',
//         e is OccToScException ? e.message : 'Unable to report issue.',
//         backgroundColor: Colors.red.withOpacity(0.9),
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } finally {
//       isSubmitting.value = false;
//     }
//   }
//
//   // ---------------------------------------------------------------------
//   // Reset
//   // ---------------------------------------------------------------------
//   void resetForm() {
//     selectedInstructionType.value =
//     null;
//
//     selectedInstructedBy.value =
//     null;
//
//     selectedStationTypes.clear();
//
//     selectedLines.clear();
//     selectedStations.clear();
//
//     selectedDepartments.clear();
//     selectedSystems.clear();
//
//     selectedEmergencyTypes.clear();
//
//     stationList.clear();
//     systemList.clear();
//
//     descriptionController.clear();
//
//     uploadedFiles.clear();
//
//     fileError.value = null;
//
//     issueDate.value = DateTime.now();
//     validUptoDate.value = null;
//   }
//
//   Future<void> pickIssueDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: issueDate.value,
//       firstDate: today,
//       lastDate: DateTime(2100),
//     );
//
//     if (picked != null) {
//       setIssueDate(picked);
//     }
//   }
//
//
//
//
//   // ---------------------------------------------------------------------
// // Id lookup helpers (UI stores names, API wants ids)
// // ---------------------------------------------------------------------
//   int? _idForName(List<MasterDataItem> list, String? name) {
//     if (name == null) return null;
//
//     for (final item in list) {
//       if (item.name == name) {
//         return item.id;
//       }
//     }
//
//     return null;
//   }
//
//   List<int> _selectedStationIds() {
//     final List<int> ids = [];
//
//     for (final name in selectedStations) {
//       for (final station in stationList) {
//         if (station.name == name) {
//           ids.add(station.id);
//           break;
//         }
//       }
//     }
//
//     return ids;
//   }
//
// // departmentId + systems (by name) per selected department.
// // Skips a department if none of its systems are currently selected.
//   List<Map<String, dynamic>> _buildTechnicalDetails() {
//     final List<Map<String, dynamic>> details = [];
//
//     for (final deptName in selectedDepartments) {
//       final department = _findDepartment(deptName);
//
//       if (department == null) continue;
//
//       final List<String> systemsForDept = department.systems
//           .map((s) => s.name)
//           .where((name) => selectedSystems.contains(name))
//           .toList();
//
//       if (systemsForDept.isEmpty) continue;
//
//       details.add({
//         'DepartmentId': department.id,
//         'Systems': systemsForDept,
//       });
//     }
//
//     return details;
//   }
//
// // Emergency Type is single-valued in the API. Using the first
// // selection until/unless this becomes a single-select field.
//   int? _selectedEmergencyTypeId() {
//     final String? name =
//     selectedEmergencyTypes.isNotEmpty ? selectedEmergencyTypes.first : null;
//
//     return _idForName(emergencyTypeList, name);
//   }
//
//   Future<String?> _currentUserId() async {
//     // Mirrors the same lookup used in fetchMasterData().
//     final String? userId= await AuthManager().getUserId();
//
//     return userId;
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/service/auth_manager.dart';

import '../model/occ_instruction_detail_model.dart';
import '../model/occ_to_sc_model.dart';
import '../service/occ_to_sc_service.dart';

class OccScCommunicationController extends GetxController {
  OccScCommunicationController({
    OccToScService? occToScService,
    this.recreateInstruction,
  }) : _occToScService = occToScService ?? OccToScService();

  final OccToScService _occToScService;

  final OccInstructionDetail? recreateInstruction;

  // ---------------------------------------------------------------------
  // Form
  // ---------------------------------------------------------------------
  final formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  // ---------------------------------------------------------------------
  // Instruction type constants
  // ---------------------------------------------------------------------
  static const String kTechnicalType = 'Technical';
  static const String kEmergencyType = 'Emergency';

  // ---------------------------------------------------------------------
  // Master data
  // ---------------------------------------------------------------------
  final RxList<MasterDataItem> instructionTypeList = <MasterDataItem>[].obs;
  final RxList<MasterDataItem> instructedByList = <MasterDataItem>[].obs;
  final RxList<DepartmentModel> departmentList = <DepartmentModel>[].obs;
  final RxList<MasterDataItem> emergencyTypeList = <MasterDataItem>[].obs;
  final RxList<LineModel> lineList = <LineModel>[].obs;

  // ---------------------------------------------------------------------
  // Derived lists
  // ---------------------------------------------------------------------
  final RxList<SystemModel> systemList = <SystemModel>[].obs;
  final RxList<StationModel> stationList = <StationModel>[].obs;

  // ---------------------------------------------------------------------
  // Single select
  // ---------------------------------------------------------------------
  final Rx<String?> selectedInstructionType = Rx<String?>(null);
  final Rx<String?> selectedInstructedBy = Rx<String?>(null);

  // ---------------------------------------------------------------------
  // Station type
  //
  // U = Under Ground
  // A = Elevated
  // ---------------------------------------------------------------------
  final RxList<String> selectedStationTypes = <String>[].obs;

  final List<String> stationTypeList = const ['U', 'A'];

  String getStationTypeLabel(String value) {
    switch (value) {
      case 'U':
        return 'Under Ground';
      case 'A':
        return 'Elevated';
      default:
        return value;
    }
  }

  // ---------------------------------------------------------------------
  // Multi select
  // ---------------------------------------------------------------------
  final RxList<String> selectedLines = <String>[].obs;
  final RxList<String> selectedStations = <String>[].obs;
  final RxList<String> selectedDepartments = <String>[].obs;
  final RxList<String> selectedSystems = <String>[].obs;
  final RxList<String> selectedEmergencyTypes = <String>[].obs;

  // ---------------------------------------------------------------------
  // Description
  // ---------------------------------------------------------------------
  final TextEditingController descriptionController = TextEditingController();

  // ---------------------------------------------------------------------
  // Files
  // ---------------------------------------------------------------------
  static const int kMaxFiles = 3;

  final Rx<String?> fileError = Rx<String?>(null);
  final RxList<Map<String, dynamic>> uploadedFiles = <Map<String, dynamic>>[].obs;

  // ---------------------------------------------------------------------
  // Conditional helpers
  // ---------------------------------------------------------------------
  bool get isTechnical => selectedInstructionType.value == kTechnicalType;

  bool get isEmergency => selectedInstructionType.value == kEmergencyType;

  // ---------------------------------------------------------------------
  // Date fields
  // ---------------------------------------------------------------------
  final Rx<DateTime> issueDate = DateTime.now().obs;
  final Rx<DateTime?> validUptoDate = Rx<DateTime?>(null);

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setIssueDate(DateTime? date) {
    if (date == null) return;

    final selected = DateTime(date.year, date.month, date.day);
    issueDate.value = selected;

    // If Valid Upto was already selected and becomes invalid, clear it.
    if (validUptoDate.value != null && validUptoDate.value!.isBefore(selected)) {
      validUptoDate.value = null;
    }
  }

  void setValidUptoDate(DateTime? date) {
    if (date == null) return;
    validUptoDate.value = DateTime(date.year, date.month, date.day);
  }

  // ---------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();
    fetchMasterData();
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------
  // Fetch master data
  // ---------------------------------------------------------------------
  Future<void> fetchMasterData() async {
    isLoading.value = true;

    try {
      final String? userId = await AuthManager().getUserId();

      debugPrint('Fetching OCC to SC master data. userId = $userId');

      final response = await _occToScService.getOccToScMasterData(userId: userId ?? '');

      if (!response.success) {
        throw OccToScException(
          response.message.isNotEmpty
              ? response.message
              : 'Unable to fetch master data.',
        );
      }

      final data = response.data;

      // instructionTypeList.assignAll(data.instructionTypes);
      // instructedByList.assignAll(data.instructionBy);
      // departmentList.assignAll(data.departments);
      // emergencyTypeList.assignAll(data.emergencyTypes);
      // lineList.assignAll(data.lines);

      instructionTypeList.assignAll(data.instructionTypes);
      instructedByList.assignAll(data.instructionBy);
      departmentList.assignAll(data.departments);
      emergencyTypeList.assignAll(data.emergencyTypes);
      lineList.assignAll(data.lines);

      debugPrint('Master data loaded successfully');

      if (recreateInstruction != null) {
        _prefillFromInstruction(recreateInstruction!);
      }

      debugPrint('Master data loaded successfully');
    } catch (e, stacktrace) {
      debugPrint('Master data error: $e--- $stacktrace');

      Get.snackbar(
        'Error',
        e is OccToScException ? e.message : 'Unable to load master data.',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _prefillFromInstruction(OccInstructionDetail instruction) {
    debugPrint(
      'Prefilling create screen from expired instruction '
          '${instruction.instructionNumber}',
    );

    // ---------------------------------------------------------------
    // Instruction Type
    // ---------------------------------------------------------------
    selectedInstructionType.value = instruction.instructionTypeName;

    // ---------------------------------------------------------------
    // Instructed By
    // ---------------------------------------------------------------
    selectedInstructedBy.value = instruction.instructionByName;

    // ---------------------------------------------------------------
    // Description
    // ---------------------------------------------------------------
    descriptionController.text = instruction.instructionContent;

    // ---------------------------------------------------------------
    // DATE
    //
    // IMPORTANT:
    // Do NOT copy old dates.
    // Re-created instruction starts with fresh dates.
    // ---------------------------------------------------------------
    issueDate.value = today;
    validUptoDate.value = null;

    // ---------------------------------------------------------------
    // Stations
    // ---------------------------------------------------------------
    final List<String> stationNames = instruction.stations
        .map((station) => station.stationName)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList();

    selectedStations.assignAll(stationNames);

    // ---------------------------------------------------------------
    // Lines
    //
    // Derive line selection from selected stations.
    // ---------------------------------------------------------------
    final Set<String> lines = <String>{};

    for (final line in lineList) {
      final bool hasSelectedStation = line.stations.any(
            (station) => stationNames.contains(station.name),
      );

      if (hasSelectedStation) {
        lines.add(line.name);
      }
    }

    selectedLines.assignAll(lines.toList());

    // ---------------------------------------------------------------
    // Station Types
    // ---------------------------------------------------------------
    final Set<String> stationTypes = <String>{};

    for (final lineName in selectedLines) {
      final line = _findLine(lineName);

      if (line == null) continue;

      for (final station in line.stations) {
        if (!stationNames.contains(station.name)) continue;

        stationTypes.add(
          normalizeStationType(station.stationType),
        );
      }
    }

    selectedStationTypes.assignAll(stationTypes.toList());

    // Rebuild station options.
    _refreshStationOptions();

    // Keep only stations that are valid for selected
    // line + station type.
    final validStations = stationList.map((e) => e.name).toSet();

    selectedStations.removeWhere(
          (station) => !validStations.contains(station),
    );

    // ---------------------------------------------------------------
    // Technical details
    // ---------------------------------------------------------------
    if (instruction.technicalSystems.isNotEmpty) {
      final Set<String> departments = <String>{};
      final Set<String> systems = <String>{};

      for (final technical in instruction.technicalSystems) {
        final String? departmentName = technical.deptName;
        final String? systemName = technical.systemName;

        if (departmentName != null &&
            departmentName.trim().isNotEmpty) {
          departments.add(departmentName);
        }

        if (systemName != null &&
            systemName.trim().isNotEmpty) {
          systems.add(systemName);
        }
      }

      selectedDepartments.assignAll(departments.toList());

      _refreshSystemOptions();

      final validSystems = systemList.map((e) => e.name).toSet();

      selectedSystems.assignAll(
        systems.where(validSystems.contains).toList(),
      );
    }

    // ---------------------------------------------------------------
    // Emergency
    // ---------------------------------------------------------------
    if ((instruction.emergencyTypeName ?? '').trim().isNotEmpty) {
      selectedEmergencyTypes.assignAll([
        instruction.emergencyTypeName!,
      ]);
    }

    // ---------------------------------------------------------------
    // IMPORTANT:
    // Do NOT copy attachments.
    //
    // uploadedFiles remains empty.
    // ---------------------------------------------------------------
    uploadedFiles.clear();
    fileError.value = null;

    debugPrint('Create screen prefill completed.');
  }

  // ---------------------------------------------------------------------
  // Instruction type
  // ---------------------------------------------------------------------
  void onInstructionTypeChanged(String? value) {
    selectedInstructionType.value = value;

    if (!isTechnical) {
      selectedDepartments.clear();
      selectedSystems.clear();
      systemList.clear();
    }

    if (!isEmergency) {
      selectedEmergencyTypes.clear();
    }
  }

  // ---------------------------------------------------------------------
  // Department -> System
  // ---------------------------------------------------------------------
  void setSelectedDepartments(List<String> values) {
    selectedDepartments.assignAll(values);
    _refreshSystemOptions();
  }

  DepartmentModel? _findDepartment(String name) {
    for (final department in departmentList) {
      if (department.name == name) return department;
    }
    return null;
  }

  void _refreshSystemOptions() {
    final Set<String> seen = <String>{};
    final List<SystemModel> combined = <SystemModel>[];

    for (final departmentName in selectedDepartments) {
      final department = _findDepartment(departmentName);
      if (department == null) continue;

      for (final system in department.systems) {
        if (seen.add(system.name)) {
          combined.add(system);
        }
      }
    }

    systemList.assignAll(combined);

    final validSystems = combined.map((e) => e.name).toSet();
    selectedSystems.removeWhere((system) => !validSystems.contains(system));
  }

  void setSelectedSystems(List<String> values) {
    selectedSystems.assignAll(values);
  }

  // ---------------------------------------------------------------------
  // Line -> Station Type -> Station
  // ---------------------------------------------------------------------
  void setSelectedLines(List<String> values) {
    selectedLines.assignAll(values);

    // Rebuild station options using the current selected lines + station types.
    _refreshStationOptions();

    // Remove invalid selected stations.
    final validStations = stationList.map((e) => e.name).toSet();
    selectedStations.removeWhere((station) => !validStations.contains(station));
  }

  LineModel? _findLine(String name) {
    for (final line in lineList) {
      if (line.name == name) return line;
    }
    return null;
  }

  void setSelectedStationTypes(List<String> values) {
    selectedStationTypes.assignAll(values);

    // Rebuild stations whenever station type changes.
    _refreshStationOptions();

    // Remove stations that are no longer valid.
    final validStations = stationList.map((e) => e.name).toSet();
    selectedStations.removeWhere((station) => !validStations.contains(station));
  }

  void _refreshStationOptions() {
    final Set<String> seen = <String>{};
    final List<StationModel> combined = <StationModel>[];

    // Line is required before we can show stations.
    if (selectedLines.isEmpty) {
      stationList.clear();
      return;
    }

    // Station Type is also required.
    if (selectedStationTypes.isEmpty) {
      stationList.clear();
      return;
    }

    for (final lineName in selectedLines) {
      final line = _findLine(lineName);
      if (line == null) continue;

      for (final station in line.stations) {
        final stationType = normalizeStationType(station.stationType);

        // Station must match ANY selected type.
        if (selectedStationTypes.contains(stationType)) {
          if (seen.add(station.name)) {
            combined.add(station);
          }
        }
      }
    }

    stationList.assignAll(combined);
  }

  void setSelectedStations(List<String> values) {
    selectedStations.assignAll(values);
  }

  // ---------------------------------------------------------------------
  // Station Type normalization
  // ---------------------------------------------------------------------
  String normalizeStationType(String stationType) {
    final String value = stationType.trim().toUpperCase();

    // Your API currently returns E for elevated.
    // UI uses A for Elevated.
    if (value == 'E') return 'A';
    if (value == 'U') return 'U';
    if (value == 'A') return 'A';

    return value;
  }

  // ---------------------------------------------------------------------
  // Emergency type
  // ---------------------------------------------------------------------
  void setSelectedEmergencyTypes(List<String> values) {
    selectedEmergencyTypes.assignAll(values);
  }

  // ---------------------------------------------------------------------
  // Files
  // ---------------------------------------------------------------------
  void addUploadedFile(Map<String, dynamic> file) {
    // Maximum 3 files are allowed.
    if (uploadedFiles.length >= kMaxFiles) {
      fileError.value = 'You can upload maximum $kMaxFiles files';
      return;
    }

    uploadedFiles.add(file);
    fileError.value = null;
  }

  void removeUploadedFile(Map<String, dynamic> file) {
    uploadedFiles.remove(file);

    if (uploadedFiles.length < kMaxFiles) {
      fileError.value = null;
    }
  }

  // ---------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------
  String? requiredDropdown(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? requiredMultiSelect(List<String>? values, String label) {
    if (values == null || values.isEmpty) {
      return '$label is required';
    }
    return null;
  }

  bool validateForm() {
    final bool formValid = formKey.currentState?.validate() ?? false;

    bool conditionalValid = true;

    if (isTechnical) {
      conditionalValid = selectedDepartments.isNotEmpty && selectedSystems.isNotEmpty;
    }

    if (isEmergency) {
      conditionalValid = conditionalValid && selectedEmergencyTypes.isNotEmpty;
    }

    final bool stationTypeValid = selectedStationTypes.isNotEmpty;

    return formValid &&
        conditionalValid &&
        selectedLines.isNotEmpty &&
        selectedStations.isNotEmpty &&
        stationTypeValid;
  }

  // ---------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------
  Future<void> submitReportIssue() async {
    if (!validateForm()) {
      Get.snackbar(
        'Validation Error',
        'Please fill all compulsory fields marked with *',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    final int? instructionTypeId =
    _idForName(instructionTypeList, selectedInstructionType.value);

    final int? instructionById = _idForName(instructedByList, selectedInstructedBy.value);

    if (instructionTypeId == null || instructionById == null) {
      Get.snackbar(
        'Error',
        'Invalid Instruction Type / Instructed By selection.',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    List<Map<String, dynamic>>? technicalDetails;

    if (isTechnical) {
      technicalDetails = _buildTechnicalDetails();
    }

    int? emergencyTypeId;

    if (isEmergency) {
      emergencyTypeId = _selectedEmergencyTypeId();

      if (emergencyTypeId == null) {
        Get.snackbar(
          'Error',
          'Please select a valid Emergency Type.',
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        return;
      }
    }

    isSubmitting.value = true;

    try {
      final response = await _occToScService.createOccInstruction(
        issueDate: issueDate.value,
        validityUpto: validUptoDate.value ?? issueDate.value,
        instructionTypeId: instructionTypeId,
        instructionById: instructionById,
        emergencyTypeId: emergencyTypeId,
        instructionContent: descriptionController.text.trim(),
        stationIds: _selectedStationIds(),
        technicalDetails: technicalDetails,
        createdBy: await _currentUserId(),
        files: uploadedFiles,
      );

      if (!response.success) {
        throw OccToScException(
          response.message.isNotEmpty
              ? response.message
              : 'Unable to submit instruction.',
        );
      }

      Get.back();

      Get.snackbar(
        'Success',
        'Issue reported successfully.',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stacktrace) {
      debugPrint('submitReportIssue error: $e\n$stacktrace');

      Get.snackbar(
        'Error',
        e is OccToScException ? e.message : 'Unable to report issue.',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // ---------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------
  void resetForm() {
    selectedInstructionType.value = null;
    selectedInstructedBy.value = null;

    selectedStationTypes.clear();
    selectedLines.clear();
    selectedStations.clear();
    selectedDepartments.clear();
    selectedSystems.clear();
    selectedEmergencyTypes.clear();

    stationList.clear();
    systemList.clear();

    descriptionController.clear();
    uploadedFiles.clear();
    fileError.value = null;

    issueDate.value = DateTime.now();
    validUptoDate.value = null;
  }

  Future<void> pickIssueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: issueDate.value,
      firstDate: today,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setIssueDate(picked);
    }
  }

  // ---------------------------------------------------------------------
  // Id lookup helpers (UI stores names, API wants ids)
  // ---------------------------------------------------------------------
  int? _idForName(List<MasterDataItem> list, String? name) {
    if (name == null) return null;

    for (final item in list) {
      if (item.name == name) return item.id;
    }

    return null;
  }

  List<int> _selectedStationIds() {
    final List<int> ids = [];

    for (final name in selectedStations) {
      for (final station in stationList) {
        if (station.name == name) {
          ids.add(station.id);
          break;
        }
      }
    }

    return ids;
  }

  // departmentId + systems (by name) per selected department.
  // Skips a department if none of its systems are currently selected.
  List<Map<String, dynamic>> _buildTechnicalDetails() {
    final List<Map<String, dynamic>> details = [];

    for (final deptName in selectedDepartments) {
      final department = _findDepartment(deptName);
      if (department == null) continue;

      final List<String> systemsForDept = department.systems
          .map((s) => s.name)
          .where((name) => selectedSystems.contains(name))
          .toList();

      if (systemsForDept.isEmpty) continue;

      details.add({
        'DepartmentId': department.id,
        'Systems': systemsForDept,
      });
    }

    return details;
  }

  // Emergency Type is single-valued in the API. Using the first
  // selection until/unless this becomes a single-select field.
  int? _selectedEmergencyTypeId() {
    final String? name =
    selectedEmergencyTypes.isNotEmpty ? selectedEmergencyTypes.first : null;

    return _idForName(emergencyTypeList, name);
  }

  Future<String?> _currentUserId() async {
    // Mirrors the same lookup used in fetchMasterData().
    final String? userId = await AuthManager().getUserId();
    return userId;
  }
}