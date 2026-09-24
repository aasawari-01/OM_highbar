import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/constants/strings.dart';
import 'package:om_mobile/core/models/label_value.dart';
import 'package:om_mobile/core/controller/session_controller.dart';
import 'package:om_mobile/core/controller/global_master_data_controller.dart';
import '../service/failure_service.dart';

class CreateMaintenanceController extends GetxController {
  final FailureService _failureService = FailureService();
  final ImagePicker _imagePicker = ImagePicker();

  // Master data from local database (same as JE view)
  final RxList<Map<String, dynamic>> masterFunctionalLocations = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> masterLocations = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> masterDepartments = <Map<String, dynamic>>[].obs;

  // Basic Information
  final RxList<LabelValue> priorityList = <LabelValue>[].obs;
  final RxList<LabelValue> departmentList = <LabelValue>[].obs;
  final RxList<LabelValue> functionalLocationList = <LabelValue>[].obs;
  final RxList<LabelValue> systemList = <LabelValue>[].obs;
  final RxList<LabelValue> subsystemList = <LabelValue>[].obs;
  final RxList<LabelValue> equipmentList = <LabelValue>[].obs;
  final RxList<LabelValue> notificationTypeList = <LabelValue>[].obs;
  final RxList<LabelValue> personResponsibleList = <LabelValue>[].obs;
  final RxList<LabelValue> locationList = <LabelValue>[].obs;

  final RxString selectedPriority = ''.obs;
  final RxString selectedDepartment = ''.obs;
  final RxString selectedFunctionalLocation = ''.obs;
  final RxString selectedSystem = ''.obs;
  final RxString selectedSubsystem = ''.obs;
  final RxString selectedEquipmentNumber = ''.obs;
  final RxString selectedNotificationType = ''.obs;
  final RxString selectedPersonResponsible = ''.obs;
  final RxString selectedLocation = ''.obs;

  final RxInt departmentId = 0.obs;
  final RxBool isFunctionalLocationLoading = false.obs;
  final RxBool isEquipmentLoading = false.obs;

  // Text Controllers
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController failureDescriptionController = TextEditingController();
  final TextEditingController subLocationController = TextEditingController();
  final TextEditingController systemController = TextEditingController();
  final TextEditingController subsystemController = TextEditingController();

  // Date Time
  final Rx<DateTime?> selectedFailureOccurrenceDate = Rx<DateTime?>(null);

  // Nature of Work (Department ID 3)
  final RxList<LabelValue> natureOfWorkList = <LabelValue>[].obs;
  final RxList<LabelValue> failureTypeList = <LabelValue>[].obs;
  final RxString selectedNatureOfWork = ''.obs;
  final RxString selectedFailureType = ''.obs;
  final TextEditingController trainRunningKmController = TextEditingController();

  // Service Affected
  final RxBool isServiceAffected = false.obs;
  final TextEditingController trainDelayMinController = TextEditingController();
  final TextEditingController trainDelayNosController = TextEditingController();
  final TextEditingController trainCancelNosController = TextEditingController();
  final TextEditingController trainWithdrawalNosController = TextEditingController();
  final TextEditingController trainReplaceNosController = TextEditingController();
  final Rx<DateTime?> selectedSystemDowntime = Rx<DateTime?>(null);

  // Passenger Deboarding
  final RxBool isPassengerDeboarding = false.obs;
  final TextEditingController trainDeboardedNosController = TextEditingController();

  // OHE & SIC (Department ID 3)
  final RxBool isOheRequired = false.obs;
  final RxBool isSicRequired = false.obs;

  // Passenger Affected (Departments 4,5,6,8,9,10)
  final RxBool isPassengerAffected = false.obs;
  final TextEditingController numberOfPassengerAffectedController = TextEditingController();
  final TextEditingController trappedDurationController = TextEditingController();
  final TextEditingController rescuedDurationController = TextEditingController();

  // Joint Inspection
  final RxBool showJointInspection = false.obs;
  final RxBool isJointInspectionEnabled = false.obs;
  final RxList<LabelValue> jointInspectionDepartmentList = <LabelValue>[].obs;
  final RxList<LabelValue> jointInspectionUserList = <LabelValue>[].obs;
  final RxString selectedJointInspectionDepartment = ''.obs;
  final RxString selectedJointInspectionUser = ''.obs;
  final TextEditingController jointInspectionRemarkController = TextEditingController();

  // Measurement Reading
  final RxBool showMeasurementButton = false.obs;
  final RxList<Map<String, dynamic>> measurementPoints = <Map<String, dynamic>>[].obs;

  // Attachments
  final RxList<File> attachmentFiles = <File>[].obs;

  // Maintenance History
  final RxList<Map<String, dynamic>> maintenanceHistoryList = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> maintenanceHistoryListPrev = <Map<String, dynamic>>[].obs;
  final RxString selectedHistoryTab = 'current'.obs;

  // Observation Detail
  final RxMap<String, dynamic> inspectionObservation = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    _loadMasterDataFromDb();
    _checkInspectionFlow();
  }

  Future<void> _loadMasterDataFromDb() async {
    try {
      final globalData = Get.find<GlobalMasterDataController>();
      masterFunctionalLocations.assignAll(globalData.masterFunctionalLocations);
      masterLocations.assignAll(globalData.masterLocations);
      masterDepartments.assignAll(globalData.masterDepartments);
      
      print('Loaded master data: ${masterFunctionalLocations.length} functional locations, ${masterLocations.length} locations');
    } catch (e) {
      print('Error loading master data from DB: $e');
    }
  }

  @override
  void onClose() {
    _disposeControllers();
    super.onClose();
  }

  void _disposeControllers() {
    frequencyController.dispose();
    failureDescriptionController.dispose();
    subLocationController.dispose();
    systemController.dispose();
    subsystemController.dispose();
    trainRunningKmController.dispose();
    trainDelayMinController.dispose();
    trainDelayNosController.dispose();
    trainCancelNosController.dispose();
    trainWithdrawalNosController.dispose();
    trainReplaceNosController.dispose();
    trainDeboardedNosController.dispose();
    numberOfPassengerAffectedController.dispose();
    trappedDurationController.dispose();
    rescuedDurationController.dispose();
    jointInspectionRemarkController.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final session = Get.find<SessionController>();
      final globalMasterData = Get.find<GlobalMasterDataController>();

      // Load Priority
      priorityList.value = globalMasterData.priorityTypeList;

      // Load Department
      departmentList.value = session.departments.map((dept) => 
        LabelValue(label: dept.deptName, value: dept.deptId.toString())
      ).toList();

      // Load Notification Types
      notificationTypeList.value = globalMasterData.notificationTypeList;

      // Set default department if available
      if (session.selectedDepartment.value != null) {
        selectedDepartment.value = session.selectedDepartment.value!.deptName ?? '';
        departmentId.value = session.selectedDepartment.value!.deptId ?? 0;
        await onDepartmentChanged(selectedDepartment.value);
      }
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  void _checkInspectionFlow() {
    try {
      final inspectionData = Get.arguments as Map<String, dynamic>?;
      if (inspectionData != null) {
        inspectionObservation.value = inspectionData;
      }
    } catch (e) {
      print('Error checking inspection flow: $e');
    }
  }

  // Department Change - Cascade Reset
  Future<void> onDepartmentChanged(String? value) async {
    if (value == null || value.isEmpty) return;

    try {
      final session = Get.find<SessionController>();
      final selectedDept = session.departments.firstWhere(
        (dept) => dept.deptName == value,
        orElse: () => session.departments.first,
      );

      departmentId.value = selectedDept.deptId ?? 0;

      // Cascade reset: location, functional location, FMECA, equipment, responsible person
      _resetCascadedFields();

      // Load location if departmentId > 0 (filter from master locations)
      if (departmentId.value > 0) {
        _filterLocationsByDepartment();
      }

      // Load person responsible for department
      await _loadPersonResponsible();

      // Load nature of work data for department ID 3
      if (departmentId.value == 3) {
        await _loadNatureOfWorkData();
      }

    } catch (e) {
      print('Error on department change: $e');
    }
  }

  void _resetCascadedFields() {
    selectedLocation.value = '';
    selectedFunctionalLocation.value = '';
    selectedSystem.value = '';
    selectedSubsystem.value = '';
    selectedEquipmentNumber.value = '';
    selectedPersonResponsible.value = '';
    
    systemController.clear();
    subsystemController.clear();
    
    functionalLocationList.clear();
    systemList.clear();
    subsystemList.clear();
    equipmentList.clear();
    locationList.clear();
    personResponsibleList.clear();
    
    // Reset conditional fields
    selectedNatureOfWork.value = '';
    selectedFailureType.value = '';
    trainRunningKmController.clear();
    
    isServiceAffected.value = false;
    _resetServiceAffectedFields();
    
    isPassengerAffected.value = false;
    _resetPassengerAffectedFields();
    
    isOheRequired.value = false;
    isSicRequired.value = false;
    
    maintenanceHistoryList.clear();
    maintenanceHistoryListPrev.clear();
    showMeasurementButton.value = false;
    measurementPoints.clear();
  }

  // Filter locations from master data based on department (same as JE view)
  void _filterLocationsByDepartment() {
    try {
      // Filter locations from master data based on department
      final deptLocations = masterLocations.where((loc) {
        final locDeptId = loc['deptId']?.toString();
        return locDeptId == departmentId.value.toString();
      }).toList();

      locationList.value = deptLocations.map((loc) => 
        LabelValue(label: loc['label']?.toString() ?? '', value: loc['value']?.toString() ?? '')
      ).toList();

      print('Filtered ${locationList.length} locations for department $departmentId');
    } catch (e) {
      print('Error filtering locations: $e');
    }
  }

  void _resetServiceAffectedFields() {
    trainDelayMinController.clear();
    trainDelayNosController.clear();
    trainCancelNosController.clear();
    trainWithdrawalNosController.clear();
    trainReplaceNosController.clear();
    selectedSystemDowntime.value = null;
    isPassengerDeboarding.value = false;
    trainDeboardedNosController.clear();
  }

  void _resetPassengerAffectedFields() {
    numberOfPassengerAffectedController.clear();
    trappedDurationController.clear();
    rescuedDurationController.clear();
  }

  Future<void> _loadPersonResponsible() async {
    try {
      final response = await _failureService.getPersonResponsible(departmentId.value);
      if (response.users != null) {
        personResponsibleList.value = response.users!;
      } else {
        print('Error loading person responsible: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error loading person responsible: $e');
    }
  }

  // Location Change - Triggers Functional Location reload
  Future<void> onLocationChanged(String? value) async {
    if (value == null || value.isEmpty) return;

    // Reset functional location and dependent fields
    selectedFunctionalLocation.value = '';
    selectedSystem.value = '';
    selectedSubsystem.value = '';
    selectedEquipmentNumber.value = '';
    
    systemController.clear();
    subsystemController.clear();
    
    functionalLocationList.clear();
    systemList.clear();
    subsystemList.clear();
    equipmentList.clear();
    maintenanceHistoryList.clear();
    maintenanceHistoryListPrev.clear();
    showMeasurementButton.value = false;
    measurementPoints.clear();

    // Filter functional locations from local database (same as JE view)
    _filterFunctionalLocations();
  }

  void _filterFunctionalLocations() {
    try {
      // Get location code from selected location
      final locCode = _getLocationCode(selectedLocation.value);
      final workCenter = _getWorkCenterFromDepartment();

      print('Filtering functional locations: locCode=$locCode, workCenter=$workCenter');

      final filteredFuncs = masterFunctionalLocations.where((e) {
        bool match = true;

        if (locCode != null && locCode.isNotEmpty) {
          final funcLoc = e['location']?.toString().trim().toUpperCase();
          if (funcLoc != null && funcLoc.isNotEmpty) {
            match = match && (funcLoc == locCode.trim().toUpperCase());
          }
        }

        if (workCenter != null && workCenter.isNotEmpty) {
          final funcWorkCenter = e['workCenter']?.toString().trim().toUpperCase();
          if (funcWorkCenter != null && funcWorkCenter.isNotEmpty) {
            match = match && (funcWorkCenter == workCenter.trim().toUpperCase());
          }
        }

        return match;
      }).toList();

      functionalLocationList.value = filteredFuncs.map((func) => 
        LabelValue(
          label: func['funcLocationName']?.toString() ?? func['funcLocation']?.toString() ?? '',
          value: func['funcLocId']?.toString() ?? ''
        )
      ).toList();

      print('Filtered ${functionalLocationList.length} functional locations');
    } catch (e) {
      print('Error filtering functional locations: $e');
    }
  }

  String? _getLocationCode(String? locationLabel) {
    if (locationLabel == null || locationLabel.isEmpty || locationLabel == 'Select') {
      return null;
    }
    final loc = masterLocations.firstWhere(
      (e) => e['label']?.toString() == locationLabel,
      orElse: () => <String, dynamic>{},
    );
    return loc['value']?.toString() ?? loc['locationCode']?.toString();
  }

  String? _getWorkCenterFromDepartment() {
    try {
      final dept = masterDepartments.firstWhere(
        (e) => e['deptName']?.toString() == selectedDepartment.value,
        orElse: () => <String, dynamic>{},
      );
      return dept['workCenter']?.toString() ?? dept['uniqueId']?.toString();
    } catch (e) {
      print('Error getting work center: $e');
      return null;
    }
  }

  // Functional Location Change - Loads System, Subsystem, Frequency, Equipment, History, Measurement Points
  Future<void> onFunctionalLocationChanged(String? value) async {
    if (value == null || value.isEmpty) return;

    try {
      // Reset dependent fields
      selectedSystem.value = '';
      selectedSubsystem.value = '';
      selectedEquipmentNumber.value = '';
      
      systemController.clear();
      subsystemController.clear();
      
      systemList.clear();
      subsystemList.clear();
      equipmentList.clear();

      // Load functional location details
      final response = await _failureService.getFunctionalLocationDetails(value);
      
      if (response.details != null) {
        final data = response.details!;
        
        // Set Frequency (read-only, auto-calculated)
        frequencyController.text = data.frequency ?? '';
        
        // Load System (FMECA)
        systemList.value = data.systemList ?? [];
        
        // Auto-select if only one system
        if (systemList.length == 1) {
          selectedSystem.value = systemList.first.label ?? '';
          systemController.text = systemList.first.label ?? '';
          await onSystemChanged(selectedSystem.value);
        }
        
        // Load Equipment
        equipmentList.value = data.equipmentList ?? [];
        
        // Load Maintenance History
        maintenanceHistoryList.value = data.maintenanceHistory?.map((hist) => 
          {'description': hist.description, 'date': hist.date}
        ).toList() ?? [];
        
        maintenanceHistoryListPrev.value = data.maintenanceHistoryPrev?.map((hist) => 
          {'description': hist.description, 'date': hist.date}
        ).toList() ?? [];
        
        // Load Measurement Points
        final measurementData = data.measurementPoints ?? [];
        if (measurementData.isNotEmpty) {
          measurementPoints.value = measurementData.map((point) => {
            'measurementPoint': point.measurementPoint,
            'description': point.description,
            'unit': point.unit,
            'isReadingRequired': false,
          }).toList();
          showMeasurementButton.value = true;
        } else {
          showMeasurementButton.value = false;
        }
      } else {
        print('Error loading functional location details: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error loading functional location details: $e');
    }
  }

  // System Change - Filters Subsystem
  Future<void> onSystemChanged(String? value) async {
    if (value == null || value.isEmpty) return;

    try {
      selectedSubsystem.value = '';
      subsystemController.clear();
      subsystemList.clear();

      // Load subsystems filtered by selected system
      final response = await _failureService.getSubsystems(value);
      
      if (response.subsystems != null) {
        subsystemList.value = response.subsystems!;
        
        // Auto-select if only one subsystem
        if (subsystemList.length == 1) {
          selectedSubsystem.value = subsystemList.first.label ?? '';
          subsystemController.text = subsystemList.first.label ?? '';
        }
      } else {
        print('Error loading subsystems: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error loading subsystems: $e');
    }
  }

  // Service Affected Toggle
  void onServiceAffectedChanged(bool value) {
    isServiceAffected.value = value;
    
    if (!value) {
      _resetServiceAffectedFields();
    }
  }

  // Passenger Deboarding Toggle
  void onPassengerDeboardingChanged(bool value) {
    isPassengerDeboarding.value = value;
    
    if (!value) {
      trainDeboardedNosController.clear();
    }
  }

  // Passenger Affected Toggle
  void onPassengerAffectedChanged(bool value) {
    isPassengerAffected.value = value;
    
    if (!value) {
      _resetPassengerAffectedFields();
    }
  }

  // Load Nature of Work and Failure Type for Department ID 3
  Future<void> _loadNatureOfWorkData() async {
    try {
      final response = await _failureService.getNatureOfWorkData(departmentId.value);
      
      if (response.natureOfWorkList != null) {
        natureOfWorkList.value = response.natureOfWorkList!;
      }
      
      if (response.failureTypeList != null) {
        failureTypeList.value = response.failureTypeList!;
      }
    } catch (e) {
      print('Error loading nature of work data: $e');
    }
  }

  // Measurement Popup
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
                Get.snackbar(
                  AppStrings.success,
                  'Measurement readings saved successfully',
                  backgroundColor: AppColors.green,
                  colorText: AppColors.white1,
                );
              } else {
                Get.snackbar(
                  AppStrings.error,
                  'Please select at least one measurement point',
                  backgroundColor: AppColors.red,
                  colorText: AppColors.white1,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // File Attachment
  Future<void> pickFiles() async {
    if (attachmentFiles.length >= 5) {
      _showError('Maximum 5 files allowed');
      return;
    }

    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      for (var pickedFile in pickedFiles) {
        if (attachmentFiles.length >= 5) break;

        final file = File(pickedFile.path);
        final fileSize = file.lengthSync();

        if (fileSize > 1000 * 1024) { // 1MB
          _showError('File size must be less than 1MB');
          continue;
        }

        final extension = pickedFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          _showError('Only JPG, JPEG, PNG files allowed');
          continue;
        }

        attachmentFiles.add(file);
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }

  void removeAttachment(int index) {
    attachmentFiles.removeAt(index);
  }

  void _showError(String message) {
    Get.snackbar(
      AppStrings.error,
      message,
      backgroundColor: AppColors.red,
      colorText: AppColors.white1,
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      AppStrings.success,
      message,
      backgroundColor: AppColors.green,
      colorText: AppColors.white1,
    );
  }

  // Submit Form
  Future<void> submitForm() async {
    // Priority validation
    if (selectedPriority.value.isEmpty) {
      _showError('Please select priority');
      return;
    }

    // Failure Description validation
    if (failureDescriptionController.text.isEmpty) {
      _showError('Please enter failure description');
      return;
    }

    // Department validation
    if (departmentId.value == 0) {
      _showError('Please select department');
      return;
    }

    // Location validation
    if (selectedLocation.value.isEmpty) {
      _showError('Please select location');
      return;
    }

    // Functional Location validation
    if (selectedFunctionalLocation.value.isEmpty) {
      _showError('Please select functional location');
      return;
    }

    // Failure Occurrence Date validation
    if (selectedFailureOccurrenceDate.value == null) {
      _showError('Please select actual failure occurrence date');
      return;
    }

    // Notification Type validation
    if (selectedNotificationType.value.isEmpty) {
      _showError('Please select notification type');
      return;
    }

    // System validation
    if (selectedSystem.value.isEmpty) {
      _showError('Please select system');
      return;
    }

    // Subsystem validation
    if (selectedSubsystem.value.isEmpty) {
      _showError('Please select subsystem');
      return;
    }

    // Department ID 3 specific validations
    if (departmentId.value == 3) {
      if (selectedNatureOfWork.value.isEmpty) {
        _showError('Please select nature of work');
        return;
      }
      if (selectedFailureType.value.isEmpty) {
        _showError('Please select failure type');
        return;
      }
      if (trainRunningKmController.text.isEmpty) {
        _showError('Please enter train running KM');
        return;
      }
    }

    // Service Affected validations
    if (isServiceAffected.value) {
      if (trainDelayMinController.text.isEmpty) {
        _showError('Please enter train delay in minutes');
        return;
      }
      if (trainDelayNosController.text.isEmpty) {
        _showError('Please enter train delay (NOS)');
        return;
      }
      if (trainCancelNosController.text.isEmpty) {
        _showError('Please enter train cancel (NOS)');
        return;
      }
      if (trainWithdrawalNosController.text.isEmpty) {
        _showError('Please enter train withdrawal (NOS)');
        return;
      }
      if (trainReplaceNosController.text.isEmpty) {
        _showError('Please enter train replace (NOS)');
        return;
      }
      
      // System Downtime validation for departments 16 and 13
      if ((departmentId.value == 16 || departmentId.value == 13) && 
          selectedSystemDowntime.value == null) {
        _showError('Please select system downtime');
        return;
      }
    }

    // Passenger Deboarding validation
    if (isPassengerDeboarding.value) {
      if (trainDeboardedNosController.text.isEmpty) {
        _showError('Please enter train deboarded (NOS)');
        return;
      }
    }

    // Passenger Affected validations
    if (isPassengerAffected.value) {
      if (numberOfPassengerAffectedController.text.isEmpty) {
        _showError('Please enter number of passenger affected');
        return;
      }
      if (trappedDurationController.text.isEmpty) {
        _showError('Please enter trapped duration');
        return;
      }
      if (rescuedDurationController.text.isEmpty) {
        _showError('Please enter rescued duration');
        return;
      }
    }

    // All validations passed - prepare form data
    final formData = {
      'priority': selectedPriority.value,
      'departmentId': departmentId.value,
      'department': selectedDepartment.value,
      'location': selectedLocation.value,
      'functionalLocation': selectedFunctionalLocation.value,
      'system': selectedSystem.value,
      'subsystem': selectedSubsystem.value,
      'equipmentNumber': selectedEquipmentNumber.value,
      'failureOccurrenceDate': selectedFailureOccurrenceDate.value?.toIso8601String(),
      'frequency': frequencyController.text,
      'failureDescription': failureDescriptionController.text,
      'notificationType': selectedNotificationType.value,
      'personResponsible': selectedPersonResponsible.value,
      'subLocation': subLocationController.text,
      'natureOfWork': selectedNatureOfWork.value,
      'failureType': selectedFailureType.value,
      'trainRunningKm': trainRunningKmController.text,
      'isServiceAffected': isServiceAffected.value,
      'trainDelayMin': trainDelayMinController.text,
      'trainDelayNos': trainDelayNosController.text,
      'trainCancelNos': trainCancelNosController.text,
      'trainWithdrawalNos': trainWithdrawalNosController.text,
      'trainReplaceNos': trainReplaceNosController.text,
      'systemDowntime': selectedSystemDowntime.value?.toIso8601String(),
      'isPassengerDeboarding': isPassengerDeboarding.value,
      'trainDeboardedNos': trainDeboardedNosController.text,
      'isOheRequired': isOheRequired.value,
      'isSicRequired': isSicRequired.value,
      'isPassengerAffected': isPassengerAffected.value,
      'numberOfPassengerAffected': numberOfPassengerAffectedController.text,
      'trappedDuration': trappedDurationController.text,
      'rescuedDuration': rescuedDurationController.text,
      'isJointInspectionEnabled': isJointInspectionEnabled.value,
      'jointInspectionDepartment': selectedJointInspectionDepartment.value,
      'jointInspectionUser': selectedJointInspectionUser.value,
      'jointInspectionRemark': jointInspectionRemarkController.text,
    };

    try {
      // Call submit API
      final response = await _failureService.submitMaintenanceForm(formData);
      
      if (response.success) {
        _showSuccess('Maintenance form submitted successfully');
        Get.back();
      } else {
        _showError(response.errorMessage ?? 'Failed to submit form');
      }
    } catch (e) {
      print('Error submitting form: $e');
      _showError('Failed to submit form: $e');
    }
  }
}
