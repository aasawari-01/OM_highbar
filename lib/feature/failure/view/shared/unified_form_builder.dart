import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_constants.dart';
import '../../../../utils/widgets/cust_button.dart';
import '../../controller/create_failure_controller.dart';
import 'form_field_config.dart';
import 'form_field_widgets.dart';
import 'form_validators.dart';
import 'shared_form_sections.dart';

class UnifiedFormBuilder {
  static Widget buildForm({
    required UserRole userRole,
    required CreateFailureController controller,
    required GlobalKey<FormState> formKey,
    required VoidCallback onSubmit,
    required VoidCallback onCancel,
    bool isFormDisabled = false,
    // Failure Details header + Failure No. row, same as _buildStationControllerView
    // renders. Pass it from CreateFailureScreen so JE, Station and Section Incharge
    // all show the identical header above their first CustSection.
    Widget? header,
  }) {
    final fieldConfigs = FormFieldConfigs.getFieldsForRole(userRole);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (header != null) ...[
                header,
                const SizedBox(height: AppConstants.sectionSpacing),
              ],
              _buildBasicInfoSection(fieldConfigs, controller, userRole, isFormDisabled),
              const SizedBox(height: AppConstants.sectionSpacing),
              _buildServiceAffectedSection(fieldConfigs, controller, userRole, isFormDisabled),
              if (fieldConfigs.any((c) => c.type == FieldType.passengerDeboarding)) ...[
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPassengerDeboardingSection(fieldConfigs, controller, userRole, isFormDisabled),
              ],
              if (fieldConfigs.any((c) => c.type == FieldType.passengerAffected)) ...[
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPassengerAffectedSection(fieldConfigs, controller, userRole, isFormDisabled),
              ],
              const SizedBox(height: AppConstants.sectionSpacing),
              _buildActionButtons(onSubmit, onCancel),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildBasicInfoSection(
      List<FormFieldConfig> fieldConfigs,
      CreateFailureController controller,
      UserRole userRole,
      bool isFormDisabled,
      ) {
    final basicFields = fieldConfigs.where((config) => [
      FieldType.priority,
      FieldType.department,
      FieldType.location,
      FieldType.functionalLocation,
      FieldType.system,
      FieldType.subsystem,
      FieldType.frequency,
      FieldType.equipmentNumber,
      FieldType.actualFailureOccurrence,
      FieldType.failureDescription,
      FieldType.notificationType,
      FieldType.subLocation,
      FieldType.personResponsible,
      FieldType.natureOfWork,
      FieldType.failureType,
      FieldType.trainRunningKm,
    ].contains(config.type)).toList();

    return SharedFormSections.buildBasicInfoSection(
      title: "Failure Information",
      isExpanded: controller.isBasicInfoVisible.value,
      onExpandCollapse: () => controller.isBasicInfoVisible.value = !controller.isBasicInfoVisible.value,
      children: [
        const SizedBox(height: 16),
        ..._buildFieldRows(basicFields, controller, userRole, isFormDisabled),
      ],
    );
  }

  static Widget _buildServiceAffectedSection(
      List<FormFieldConfig> fieldConfigs,
      CreateFailureController controller,
      UserRole userRole,
      bool isFormDisabled,
      ) {
    final serviceFields = fieldConfigs.where((config) => [
      FieldType.trainDelayMin,
      FieldType.trainDelayNos,
      FieldType.trainCancelNos,
      FieldType.trainWithdrawalNos,
      FieldType.trainReplaceNos,
    ].contains(config.type)).toList();

    return SharedFormSections.buildServiceAffectedSection(
      isServiceAffected: controller.isServiceAffected.value,
      onToggle: isFormDisabled
          ? (_) {}
          : (val) {
        controller.trainDelayNosController.clear();
        controller.tripDelayUplineController.clear();
        controller.trainCancelNosController.clear();
        controller.tripDelayDownlineController.clear();
        controller.trainDelayMinController.clear();
        controller.trainWithdrawalNosController.clear();
        controller.trainReplaceNosController.clear();
        controller.isPassengerDeboarding.value = false;
        controller.isServiceAffected.value = val;
      },
      enabled: !isFormDisabled,
      children: [
        const SizedBox(height: 16),
        ..._buildFieldRows(serviceFields, controller, userRole, isFormDisabled),
      ],
    );
  }

  static Widget _buildPassengerDeboardingSection(
      List<FormFieldConfig> fieldConfigs,
      CreateFailureController controller,
      UserRole userRole,
      bool isFormDisabled,
      ) {
    final deboardingFields = fieldConfigs.where((config) => [
      FieldType.trainDeboardedNos,
    ].contains(config.type)).toList();

    return Obx(() => SharedFormSections.buildPassengerDeboardingSection(
      isPassengerDeboarding: controller.isPassengerDeboarding.value,
      onToggle: isFormDisabled
          ? (_) {}
          : (val) => controller.isPassengerDeboarding.value = val,
      enabled: !isFormDisabled,
      children: [
        const SizedBox(height: 16),
        ..._buildFieldRows(deboardingFields, controller, userRole, isFormDisabled),
      ],
    ));
  }

  static Widget _buildPassengerAffectedSection(
      List<FormFieldConfig> fieldConfigs,
      CreateFailureController controller,
      UserRole userRole,
      bool isFormDisabled,
      ) {
    final passengerAffectedFields = fieldConfigs.where((config) => [
      FieldType.numberOfPassengerAffected,
      FieldType.trappedDuration,
      FieldType.rescuedDuration,
    ].contains(config.type)).toList();

    return SharedFormSections.buildPassengerAffectedSection(
      isPassengerAffected: controller.isPassengerAffected.value,
      onToggle: isFormDisabled
          ? (_) {}
          : (val) => controller.isPassengerAffected.value = val,
      enabled: !isFormDisabled,
      children: [
        const SizedBox(height: 16),
        ..._buildFieldRows(passengerAffectedFields, controller, userRole, isFormDisabled),
      ],
    );
  }

  static List<Widget> _buildFieldRows(
      List<FormFieldConfig> fieldConfigs,
      CreateFailureController controller,
      UserRole userRole,
      bool isFormDisabled,
      ) {
    final widgets = <Widget>[];

    for (final config in fieldConfigs) {
      if (!config.isVisibleForRole(userRole)) continue;

      final fieldWidget = _buildSingleField(config, controller, userRole, isFormDisabled);
      if (fieldWidget != null) {
        widgets.add(fieldWidget);
        widgets.add(const SizedBox(height: AppConstants.elementSpacing));
      }
    }

    return widgets;
  }

  static Widget? _buildSingleField(
      FormFieldConfig config,
      CreateFailureController controller,
      UserRole userRole,
      bool isFormDisabled,
      ) {
    switch (config.type) {
      case FieldType.priority:
        return Obx(() => Row(
          children: [
            Expanded(
              child: FormFieldWidgets.buildDropdown(
                config: config,
                items: controller.priorityTypeList.map((e) => e.label ?? '').toList(),
                selectedValue: controller.selectedPriority.value,
                onChanged: (value) => controller.selectedPriority.value = value,
                enabled: !isFormDisabled,
                currentUserRole: userRole,
                validator: (val) => FormValidators.requiredDropdown(controller.selectedPriority.value, 'Priority'),
              ),
            ),
          ],
        ));

      case FieldType.department:
        return Obx(() => Row(
          children: [
            Expanded(
              child: FormFieldWidgets.buildDropdown(
                config: config,
                items: controller.departmentList.map((e) => e.label ?? '').toList(),
                selectedValue: controller.selectedDepartment.value,
                onChanged: (value) async {
                  await controller.onDepartmentChanged(value);
                },
                enabled: !isFormDisabled,
                currentUserRole: userRole,
                validator: (val) => FormValidators.requiredDropdown(controller.selectedDepartment.value, 'Department'),
              ),
            ),
          ],
        ));

      case FieldType.location:
        return Obx(() => FormFieldWidgets.buildDropdown(
          config: config,
          items: controller.locationTypeList.map((e) => e.label ?? '').toList(),
          selectedValue: controller.selectedLocation.value,
          onChanged: (value) {
            controller.onLocationChanged(value);
          },
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (val) => FormValidators.requiredDropdown(controller.selectedLocation.value, 'Location'),
        ));

      case FieldType.functionalLocation:
        return Obx(() {
          if (controller.isFunctionalLocationLoading.value) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Loading functional locations...', style: TextStyle(fontSize: 12)),
                ],
              ),
            );
          }
          return FormFieldWidgets.buildDropdown(
            config: config,
            items: controller.functionalLocationList.map((e) => e.label ?? '').toList(),
            selectedValue: controller.selectedFunctionalLocation.value,
            onChanged: (value) {
              controller.onFunctionalLocationChanged(value);
            },
            enabled: !isFormDisabled,
            currentUserRole: userRole,
            validator: (val) => FormValidators.requiredDropdown(controller.selectedFunctionalLocation.value, 'Functional Location'),
          );
        });

      case FieldType.system:
        if (userRole == UserRole.sectionIncharge) {
          return Obx(() {
            if (controller.fmecaSystemReadOnly.value) {
              return FormFieldWidgets.buildTextField(
                config: config,
                controller: controller.fmecaSystemController,
                enabled: false,
                currentUserRole: userRole,
              );
            } else {
              return FormFieldWidgets.buildDropdown(
                config: config,
                items: controller.fmecaSystemList.map((e) => e.label ?? '').toList(),
                selectedValue: controller.selectedFmecaSystem.value,
                onChanged: (value) {
                  controller.selectedFmecaSystem.value = value;
                  controller.onFmecaSystemChanged(value);
                },
                enabled: !isFormDisabled,
                currentUserRole: userRole,
                validator: (val) => FormValidators.requiredDropdown(controller.selectedFmecaSystem.value, 'System'),
              );
            }
          });
        }
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.systemController,
          enabled: false,
          currentUserRole: userRole,
        );

      case FieldType.subsystem:
        if (userRole == UserRole.sectionIncharge) {
          return Obx(() {
            if (controller.fmecaSubsystemReadOnly.value) {
              return FormFieldWidgets.buildTextField(
                config: config,
                controller: controller.fmecaSubsystemController,
                enabled: false,
                currentUserRole: userRole,
              );
            } else {
              return FormFieldWidgets.buildDropdown(
                config: config,
                items: controller.fmecaSubsystemList.map((e) => e.label ?? '').toList(),
                selectedValue: controller.selectedFmecaSubsystem.value,
                onChanged: (value) {
                  controller.selectedFmecaSubsystem.value = value;
                },
                enabled: !isFormDisabled,
                currentUserRole: userRole,
                validator: (val) => FormValidators.requiredDropdown(controller.selectedFmecaSubsystem.value, 'Subsystem'),
              );
            }
          });
        }
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.subsystemController,
          enabled: false,
          currentUserRole: userRole,
        );

      case FieldType.frequency:
        return Obx(() => FormFieldWidgets.buildTextField(
          config: config,
          controller: TextEditingController(text: controller.fmecaFrequency.value.toString()),
          enabled: false,
          currentUserRole: userRole,
        ));

      case FieldType.equipmentNumber:
        return Obx(() {
          if (controller.isEquipmentLoading.value) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Loading equipment numbers...', style: TextStyle(fontSize: 12)),
                ],
              ),
            );
          }
          return FormFieldWidgets.buildDropdown(
            config: config,
            items: controller.equipmentList.map((e) => e.label ?? '').toList(),
            selectedValue: controller.selectedEquipmentNumber.value,
            onChanged: (value) {
              if (isFormDisabled) return;
              controller.onEquipmentChanged(value);
            },
            enabled: !isFormDisabled && !controller.isEquipmentLoading.value,
            currentUserRole: userRole,
          );
        });

      case FieldType.actualFailureOccurrence:
        return Obx(() => FormFieldWidgets.buildDateTimePicker(
          config: config,
          selectedDateTime: controller.selectedFailureOccurrenceDate.value,
          onDateTimeSelected: (value) {
            controller.selectedFailureOccurrenceDate.value = value;
          },
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (val) {
            if (val == null) {
              return "Actual Failure Occurrence is required";
            }
            return null;
          },
        ));

      case FieldType.failureDescription:
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.failureDescriptionController,
          hintText: "Enter description",
          maxLines: 4,
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (val) => FormValidators.requiredText(val, 'Failure Description'),
        );

      case FieldType.notificationType:
        return Obx(() => FormFieldWidgets.buildDropdown(
          config: config,
          items: controller.corrNotificationTypeList.map((e) => e.label ?? '').toList(),
          selectedValue: controller.selectedNotificationType.value,
          onChanged: (v) {
            if (isFormDisabled) return;
            controller.selectedNotificationType.value = v;
          },
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (v) => FormValidators.requiredDropdown(controller.selectedNotificationType.value, 'Notification Type'),
        ));

      case FieldType.subLocation:
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.subLocationController,
          enabled: !isFormDisabled,
          currentUserRole: userRole,
        );

      case FieldType.personResponsible:
        return Obx(() => FormFieldWidgets.buildDropdown(
          config: config,
          items: controller.userList.map((e) => e.label ?? '').toList(),
          selectedValue: controller.selectedPersonResponsible.value,
          onChanged: (v) {
            if (isFormDisabled) return;
            controller.selectedPersonResponsible.value = v;
          },
          enabled: !isFormDisabled,
          currentUserRole: userRole,
        ));

      case FieldType.trainDelayMin:
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.trainDelayMinController,
          keyboardType: TextInputType.number,
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (val) => controller.isServiceAffected.value
              ? FormValidators.requiredText(val, 'Train Delay In Min.')
              : null,
        );

      case FieldType.trainDelayNos:
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.trainDelayNosController,
          keyboardType: TextInputType.number,
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (val) => controller.isServiceAffected.value
              ? FormValidators.requiredText(val, 'Train Delay (NOS)')
              : null,
        );

      case FieldType.trainCancelNos:
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.trainCancelNosController,
          keyboardType: TextInputType.number,
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (val) => controller.isServiceAffected.value
              ? FormValidators.requiredText(val, 'Train Cancel (NOS)')
              : null,
        );

      case FieldType.trainWithdrawalNos:
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.trainWithdrawalNosController,
          keyboardType: TextInputType.number,
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (val) => controller.isServiceAffected.value
              ? FormValidators.requiredText(val, 'Train Withdrawal (NOS)')
              : null,
        );

      case FieldType.trainReplaceNos:
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.trainReplaceNosController,
          keyboardType: TextInputType.number,
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (val) => controller.isServiceAffected.value
              ? FormValidators.requiredText(val, 'Train Replace (NOS)')
              : null,
        );

      case FieldType.trainDeboardedNos:
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.trainDeboardedNosController,
          keyboardType: TextInputType.number,
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (val) => controller.isPassengerDeboarding.value
              ? FormValidators.requiredText(val, 'Train Deboarded (NOS)')
              : null,
        );

      case FieldType.numberOfPassengerAffected:
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.numberOfPassengerAffectedController,
          keyboardType: TextInputType.number,
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (val) => controller.isPassengerAffected.value
              ? FormValidators.requiredText(val, 'Number Of Passenger Affected')
              : null,
        );

      case FieldType.trappedDuration:
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.trappedDurationController,
          keyboardType: TextInputType.number,
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (val) => controller.isPassengerAffected.value
              ? FormValidators.requiredText(val, 'Trapped Duration (In Min)')
              : null,
        );

      case FieldType.rescuedDuration:
        return FormFieldWidgets.buildTextField(
          config: config,
          controller: controller.rescuedDurationController,
          keyboardType: TextInputType.number,
          enabled: !isFormDisabled,
          currentUserRole: userRole,
          validator: (val) => controller.isPassengerAffected.value
              ? FormValidators.requiredText(val, 'Rescued Duration (In Min)')
              : null,
        );

      default:
        return null;
    }
  }

  static Widget _buildActionButtons(VoidCallback onSubmit, VoidCallback onCancel) {
    return Row(
      children: [
        Expanded(
          child: CustOutlineButton(
            name: "Cancel",
            size: double.infinity,
            sHeight: 35,
            onSelected: (_) => onCancel(),
          ),
        ),
        const SizedBox(width: AppConstants.elementSpacing),
        Expanded(
          child: CustButton(
            name: "Submit",
            size: double.infinity,
            sHeight: 35,
            onSelected: (_) => onSubmit(),
          ),
        ),
      ],
    );
  }
}