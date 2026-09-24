import 'package:flutter/material.dart';

enum UserRole {
  juniorEngineer,
  technician,
  stationController,
  sectionIncharge,
  general,
}

enum FieldType {
  priority,
  department,
  location,
  functionalLocation,
  system,
  subsystem,
  frequency,
  equipmentNumber,
  actualFailureOccurrence,
  failureDescription,
  notificationType,
  subLocation,
  personResponsible,
  serviceAffected,
  trainDelayMin,
  trainDelayNos,
  trainCancelNos,
  trainWithdrawalNos,
  trainReplaceNos,
  passengerDeboarding,
  trainDeboardedNos,
  oheRequired,
  sicRequired,
  jointInspection,
  natureOfWork,
  failureType,
  trainRunningKm,
  ptwRequired,
  ptwNumber,
  powerBlockRequired,
  sparePartReplaced,
  rcaRequired,
  passengerAffected,
  numberOfPassengerAffected,
  trappedDuration,
  rescuedDuration,
}

class FormFieldConfig {
  final FieldType type;
  final String label;
  final bool required;
  final bool readOnly;
  final List<UserRole> visibleForRoles;
  final List<UserRole> editableForRoles;
  final int? maxLength;
  final TextInputType? keyboardType;

  const FormFieldConfig({
    required this.type,
    required this.label,
    this.required = false,
    this.readOnly = false,
    this.visibleForRoles = const [],
    this.editableForRoles = const [],
    this.maxLength,
    this.keyboardType,
  });

  bool isVisibleForRole(UserRole role) {
    return visibleForRoles.isEmpty || visibleForRoles.contains(role);
  }

  bool isEditableForRole(UserRole role) {
    if (readOnly) return false;
    return editableForRoles.isEmpty || editableForRoles.contains(role);
  }
}

class FormFieldConfigs {
  static const priority = FormFieldConfig(
    type: FieldType.priority,
    label: "Priority",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.stationController, UserRole.sectionIncharge],
  );

  static const department = FormFieldConfig(
    type: FieldType.department,
    label: "Department",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.stationController, UserRole.sectionIncharge],
  );

  static const location = FormFieldConfig(
    type: FieldType.location,
    label: "Location",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.juniorEngineer, UserRole.sectionIncharge],
  );

  static const functionalLocation = FormFieldConfig(
    type: FieldType.functionalLocation,
    label: "Functional Location",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
  );

  static const system = FormFieldConfig(
    type: FieldType.system,
    label: "System",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.sectionIncharge],
    editableForRoles: [UserRole.sectionIncharge],
    readOnly: true,
  );

  static const subsystem = FormFieldConfig(
    type: FieldType.subsystem,
    label: "Subsystem",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.sectionIncharge],
    editableForRoles: [UserRole.sectionIncharge],
    readOnly: true,
  );

  static const frequency = FormFieldConfig(
    type: FieldType.frequency,
    label: "Frequency",
    required: true,
    visibleForRoles: [UserRole.sectionIncharge],
    readOnly: true,
  );

  static const equipmentNumber = FormFieldConfig(
    type: FieldType.equipmentNumber,
    label: "Equipment Number",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
  );

  static const actualFailureOccurrence = FormFieldConfig(
    type: FieldType.actualFailureOccurrence,
    label: "Actual Failure Occurrence",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.sectionIncharge],
  );

  static const failureDescription = FormFieldConfig(
    type: FieldType.failureDescription,
    label: "Failure Description",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.juniorEngineer, UserRole.sectionIncharge],
    maxLength: 500,
  );

  static const notificationType = FormFieldConfig(
    type: FieldType.notificationType,
    label: "Notification Type",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.sectionIncharge],
    editableForRoles: [UserRole.juniorEngineer, UserRole.sectionIncharge],
  );

  static const subLocation = FormFieldConfig(
    type: FieldType.subLocation,
    label: "Sub Location",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.juniorEngineer, UserRole.sectionIncharge],
    maxLength: 250,
  );

  static const personResponsible = FormFieldConfig(
    type: FieldType.personResponsible,
    label: "Person Responsible",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.stationController, UserRole.sectionIncharge],
  );

  static const serviceAffected = FormFieldConfig(
    type: FieldType.serviceAffected,
    label: "Service Affected",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.juniorEngineer, UserRole.sectionIncharge],
  );

  static const trainDelayMin = FormFieldConfig(
    type: FieldType.trainDelayMin,
    label: "Train Delay In Min.",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    keyboardType: TextInputType.number,
  );

  static const trainDelayNos = FormFieldConfig(
    type: FieldType.trainDelayNos,
    label: "Train Delay (NOS)",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    keyboardType: TextInputType.number,
  );

  static const trainCancelNos = FormFieldConfig(
    type: FieldType.trainCancelNos,
    label: "Train Cancel (NOS)",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    keyboardType: TextInputType.number,
  );

  static const trainWithdrawalNos = FormFieldConfig(
    type: FieldType.trainWithdrawalNos,
    label: "Train Withdrawal (NOS)",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    keyboardType: TextInputType.number,
  );

  static const trainReplaceNos = FormFieldConfig(
    type: FieldType.trainReplaceNos,
    label: "Train Replace (NOS)",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    keyboardType: TextInputType.number,
  );

  static const passengerDeboarding = FormFieldConfig(
    type: FieldType.passengerDeboarding,
    label: "Passenger Deboarding",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.juniorEngineer, UserRole.sectionIncharge],
  );

  static const trainDeboardedNos = FormFieldConfig(
    type: FieldType.trainDeboardedNos,
    label: "Train Deboarded (NOS)",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    keyboardType: TextInputType.number,
  );

  static const natureOfWork = FormFieldConfig(
    type: FieldType.natureOfWork,
    label: "Nature of Work",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer],
    editableForRoles: [UserRole.juniorEngineer],
  );

  static const failureType = FormFieldConfig(
    type: FieldType.failureType,
    label: "Failure Type",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer],
    editableForRoles: [UserRole.juniorEngineer],
  );

  static const trainRunningKm = FormFieldConfig(
    type: FieldType.trainRunningKm,
    label: "Train Running KM",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer],
    keyboardType: TextInputType.number,
  );

  static const oheRequired = FormFieldConfig(
    type: FieldType.oheRequired,
    label: "OHE Required",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer],
    editableForRoles: [UserRole.juniorEngineer],
  );

  static const sicRequired = FormFieldConfig(
    type: FieldType.sicRequired,
    label: "SIC Required",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer],
    editableForRoles: [UserRole.juniorEngineer],
  );

  static const jointInspection = FormFieldConfig(
    type: FieldType.jointInspection,
    label: "Joint Inspection",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
  );

  static const ptwRequired = FormFieldConfig(
    type: FieldType.ptwRequired,
    label: "PTW Required",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer],
    editableForRoles: [UserRole.juniorEngineer],
  );

  static const ptwNumber = FormFieldConfig(
    type: FieldType.ptwNumber,
    label: "PTW Number",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer],
  );

  static const powerBlockRequired = FormFieldConfig(
    type: FieldType.powerBlockRequired,
    label: "Power Block Required",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer],
    editableForRoles: [UserRole.juniorEngineer],
  );

  static const sparePartReplaced = FormFieldConfig(
    type: FieldType.sparePartReplaced,
    label: "Spare Part Replaced",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer],
    editableForRoles: [UserRole.juniorEngineer],
  );

  static const rcaRequired = FormFieldConfig(
    type: FieldType.rcaRequired,
    label: "RCA Required",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer],
    editableForRoles: [UserRole.juniorEngineer],
  );

  static const passengerAffected = FormFieldConfig(
    type: FieldType.passengerAffected,
    label: "Passenger Affected",
    required: false,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    editableForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
  );

  static const numberOfPassengerAffected = FormFieldConfig(
    type: FieldType.numberOfPassengerAffected,
    label: "Number Of Passenger Affected",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    keyboardType: TextInputType.number,
  );

  static const trappedDuration = FormFieldConfig(
    type: FieldType.trappedDuration,
    label: "Trapped Duration (In Min)",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    keyboardType: TextInputType.number,
  );

  static const rescuedDuration = FormFieldConfig(
    type: FieldType.rescuedDuration,
    label: "Rescued Duration (In Min)",
    required: true,
    visibleForRoles: [UserRole.juniorEngineer, UserRole.stationController, UserRole.sectionIncharge],
    keyboardType: TextInputType.number,
  );

  static List<FormFieldConfig> getFieldsForRole(UserRole role) {
    switch (role) {
      case UserRole.juniorEngineer:
        return [
          priority,
          department,
          location,
          functionalLocation,
          system,
          subsystem,
          equipmentNumber,
          actualFailureOccurrence,
          failureDescription,
          notificationType,
          subLocation,
          serviceAffected,
          trainDelayMin,
          trainDelayNos,
          trainCancelNos,
          trainWithdrawalNos,
          trainReplaceNos,
          passengerDeboarding,
          trainDeboardedNos,
          natureOfWork,
          failureType,
          trainRunningKm,
          oheRequired,
          sicRequired,
          jointInspection,
          ptwRequired,
          ptwNumber,
          powerBlockRequired,
          sparePartReplaced,
          rcaRequired,
          passengerAffected,
          numberOfPassengerAffected,
          trappedDuration,
          rescuedDuration,
        ];
      case UserRole.stationController:
        return [
          priority,
          department,
          functionalLocation,
          system,
          subsystem,
          equipmentNumber,
          actualFailureOccurrence,
          failureDescription,
          subLocation,
          serviceAffected,
          trainDelayMin,
          trainDelayNos,
          trainCancelNos,
          trainWithdrawalNos,
          trainReplaceNos,
          passengerDeboarding,
          trainDeboardedNos,
          jointInspection,
          passengerAffected,
          numberOfPassengerAffected,
          trappedDuration,
          rescuedDuration,
        ];
      case UserRole.sectionIncharge:
        return [
          priority,
          department,
          location,
          functionalLocation,
          system,
          subsystem,
          frequency,
          equipmentNumber,
          actualFailureOccurrence,
          failureDescription,
          notificationType,
          subLocation,
          personResponsible,
          serviceAffected,
          trainDelayMin,
          trainDelayNos,
          trainCancelNos,
          trainWithdrawalNos,
          trainReplaceNos,
          passengerDeboarding,
          trainDeboardedNos,
        ];
      default:
        return [];
    }
  }
}