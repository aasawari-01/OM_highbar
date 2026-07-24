part of 'create_failure_screen.dart';

extension JeChangeNotificationFormExt on _CreateFailureScreenState {
  Widget _buildJeChangeNotificationForm(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustText.sectionHeader(
                  _isJeChangeNotification
                      ? "Failure Details"
                      : "Failure Details",
                  color: AppColors.orangeColor,
                ),
                Spacer(),
                GestureDetector(
                  onTap: _showActionByDialog,
                  child: Icon(TablerIcons.hand_click,
                      size: 24, color: AppColors.orangeColor),
                ),
                SizedBox(width: 10),
                GestureDetector(
                    onTap: () => Get.to(() => MaintenanceHistoryScreen()),
                    child: Icon(TablerIcons.history,
                        size: 24, color: AppColors.orangeColor))
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            Obx(() => CustText.body(
                  "Failure No.: ${(controller.notificationCode.value.isNotEmpty ? controller.notificationCode.value : widget.notificationCode) ?? ""} ${controller.mainStatusName.value == null ? "" : "(${controller.mainStatusName.value ?? ''})"}",
                  size: 18,
                  color: AppColors.black,
                  fontWeightName: FontWeight.w600,
                )),
            const SizedBox(height: AppConstants.sectionSpacing),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustSection(
                    title: "Basic Information",
                    trailing: Obx(() => YesNoToggle(
                          value: controller.isBasicInfoVisible.value,
                          onChanged: (val) =>
                              controller.isBasicInfoVisible.value = val,
                        )),
                    isVisible: controller.isBasicInfoVisible.value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isJointInspectionFlow) ...[
                          Row(
                            children: [
                              Expanded(
                                  child: CustomTextField(
                                      label: "Priority",
                                      controller:
                                          controller.priorityDisplayController,
                                      enabled: false)),
                              const SizedBox(
                                  width: AppConstants.elementSpacing),
                              Expanded(
                                  child: CustomTextField(
                                      label: "Department",
                                      controller: controller
                                          .departmentDisplayController,
                                      enabled: false)),
                            ],
                          ),
                        ] else
                          Obx(() => Row(
                                children: [
                                  Expanded(
                                      child: CustDropdown(
                                    label: "Priority",
                                    hint: "Priority",
                                    items: controller.priorityTypeList
                                        .map((e) => e.label ?? '')
                                        .toList(),
                                    selectedValue:
                                        controller.selectedPriority.value,
                                    onChanged: (value) => controller
                                        .selectedPriority.value = value,
                                    enabled: false,
                                  )),
                                  const SizedBox(
                                      width: AppConstants.elementSpacing),
                                  Expanded(
                                      child: CustDropdown(
                                    label: "Department",
                                    hint: "Department",
                                    items: controller.departmentList
                                            .map((e) => e.label ?? '')
                                            .toList()
                                            .isNotEmpty
                                        ? controller.departmentList
                                            .map((e) => e.label ?? '')
                                            .toList()
                                        : Get.find<SessionController>()
                                            .departments
                                            .map((e) => e.deptName ?? '')
                                            .toList(),
                                    selectedValue:
                                        controller.selectedDepartment.value ??
                                            Get.find<SessionController>()
                                                .selectedDepartment
                                                .value
                                                ?.deptName,
                                    onChanged: (value) {
                                      controller.onDepartmentChanged(value);
                                    },
                                    enabled: false,
                                  )),
                                ],
                              )),
                        const SizedBox(height: AppConstants.elementSpacing),
                        CustText.formLabel("Failure Description:"),
                        Obx(() {
                          if (controller.notificationDescriptionHistoryList.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    height: ResponsiveHelper.spacing(
                                        context, AppConstants.labelSpacing)),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                    Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemCount: controller
                                        .notificationDescriptionHistoryList.length,
                                    separatorBuilder: (context, index) =>
                                        Divider(
                                          height: 1,
                                          color: Colors.grey.shade200,
                                        ),
                                    itemBuilder: (context, index) {
                                      final item = controller
                                          .notificationDescriptionHistoryList[index];
                                      return Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            CustText(
                                              name: item.description ?? "",
                                              size: 13,
                                              color: AppColors.textDarkPrimary,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: CustText(
                                                    name: item.createdBy ??
                                                        "Unknown User",
                                                    size: 11,
                                                    color: AppColors.textDarkSecondary,
                                                    overflow:
                                                    TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                CustText(
                                                  name: item.createdOn ?? "",
                                                  size: 11,
                                                  color: AppColors.textDarkSecondary,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        if (!_isJointInspectionFlow) ...[
                          const SizedBox(height: AppConstants.labelSpacing),
                          CustomTextField(
                            controller: controller.failureDescriptionController,
                            hintText: "Enter description",
                            maxLines: 4,
                            enabled:
                                controller.isJE && !_isJointInspectionFlow ||
                                    controller.isTechnician,
                          ),
                        ],
                        const SizedBox(height: AppConstants.elementSpacing),
                        if (_isJointInspectionFlow) ...[
                          CustomTextField(
                            label: "Location",
                            controller: controller.locationDisplayController,
                            enabled: false,
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          CustomTextField(
                            label: "Functional Location",
                            controller:
                                controller.functionalLocationDisplayController,
                            enabled: false,
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          CustomTextField(
                            label: "Equipment Number",
                            controller: controller.equipmentDisplayController,
                            enabled: false,
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          CustomTextField(
                            label: "Person Responsible",
                            controller:
                                controller.personResponsibleDisplayController,
                            enabled: false,
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          Obx(() => CustDateTimePicker(
                              label: "Actual Failure Occurrence",
                              hint: "Actual Failure Occurrence",
                              selectedDateTime: controller
                                  .selectedFailureOccurrenceDate.value,
                              enabled: false,
                              onDateTimeSelected: (_) {})),
                          const SizedBox(height: AppConstants.elementSpacing),
                          Obx(() => CustDateTimePicker(
                              label: "Failure Attended",
                              hint: "Failure Attended",
                              selectedDateTime: controller
                                  .selectedFailureAttendedDate.value,
                              enabled: false,
                              onDateTimeSelected: (date) =>
                                  controller.onFailureAttendedDateSelected(date))),
                          const SizedBox(height: AppConstants.elementSpacing),
                          Obx(() => CustDateTimePicker(
                              label: "Actual Failure Rectified*",
                              hint: "Actual Failure Rectified",
                              selectedDateTime: controller
                                  .selectedActualFailureRectifiedDate.value,
                              enabled: false,
                              onDateTimeSelected: (date) =>
                                  controller.selectedActualFailureRectifiedDate.value = date)),
                          const SizedBox(height: AppConstants.elementSpacing),
                        ] else
                          Obx(() => Column(
                                children: [
                                  CustDropdown(
                                      label: 'Location *',
                                      hint: 'Select location',
                                      items: controller.locationTypeList
                                          .map((e) => e.label ?? '')
                                          .toList(),
                                      selectedValue:
                                          controller.selectedLocation.value,
                                      enabled: controller.isJE &&
                                          !_isJointInspectionFlow,
                                      onChanged: (value) {
                                        controller.onLocationChanged(value);
                                      },
                                    validator: (val) {
                                    if (val == null ||
                                        val.trim().isEmpty ||
                                        val == "Select") {
                                      return "Location is required";
                                    }
                                    return null;
                                  },
                                 ),
                                  const SizedBox(
                                      height: AppConstants.elementSpacing),
                                  CustDropdown(
                                      label: 'Functional Location *',
                                      hint: 'Select functional location',
                                      items: controller.functionalLocationList
                                          .map((e) => e.label ?? '')
                                          .toList(),
                                      selectedValue: controller
                                          .selectedFunctionalLocation.value,
                                      enabled: controller.isJE &&
                                          !_isJointInspectionFlow,
                                      onChanged: (value) {
                                        controller
                                            .onFunctionalLocationChanged(value);
                                      },
                                    validator: (val) {
                                      if (val == null ||
                                          val.trim().isEmpty ||
                                          val == "Select") {
                                        return "Functional Location is required";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(
                                      height: AppConstants.elementSpacing),
                                  CustDropdown(
                                    label: 'Equipment Number *',
                                    hint: controller.isEquipmentLoading.value
                                        ? 'Loading...'
                                        : 'Select equipment number',
                                    items: controller.equipmentList
                                        .map((e) => e.label ?? '')
                                        .toList(),
                                    selectedValue: controller
                                        .selectedEquipmentNumber.value,
                                    enabled: controller.isJE &&
                                        !_isJointInspectionFlow &&
                                        !controller.isEquipmentLoading.value,
                                    onChanged: (value) =>
                                        controller.onEquipmentChanged(value),
                                    // validator: (val) {
                                    //   if (val == null ||
                                    //       val.trim().isEmpty ||
                                    //       val == "Select") {
                                    //     return "Equipment Number is required";
                                    //   }
                                    //   return null;
                                    // },
                                  ),
                                  const SizedBox(
                                      height: AppConstants.elementSpacing),
                                  CustDateTimePicker(
                                    label: "Actual Failure Occurrence",
                                    hint: "Actual Failure Occurrence",
                                    selectedDateTime: controller
                                        .selectedFailureOccurrenceDate.value,
                                    enabled: false,
                                    onDateTimeSelected: (value) => controller
                                        .selectedFailureOccurrenceDate
                                        .value = value,
                                  ),
                                ],
                              )),
                        if (!_isJointInspectionFlow) ...[
                          const SizedBox(height: AppConstants.elementSpacing),
                          Obx(() => CustDropdown(
                              label: 'Notification Type *',
                              hint: 'Select Type',
                              items: controller.notificationTypeList
                                  .map((e) => e.label ?? '')
                                  .toList(),
                              selectedValue:
                                  controller.selectedNotificationType.value,
                              enabled:
                                  controller.isJE && !_isJointInspectionFlow,
                              validator: (v) => controller.isJE &&
                                      !_isJointInspectionFlow
                                  ? _requiredDropdown(
                                      controller.selectedNotificationType.value,
                                      'Notification Type')
                                  : null,
                              onChanged: (v) => controller
                                  .selectedNotificationType.value = v)),
                          const SizedBox(height: AppConstants.elementSpacing),
                          CustomTextField(
                            controller: controller.subLocationController,
                            label: "Sub Location",
                            enabled: controller.isJE && !_isJointInspectionFlow,
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                        ],
                      ],
                    ),
                  ),
                  CustSection(
                    title: "Service Affected *",
                    trailing: Obx(() => YesNoToggle(
                          value: controller.isServiceAffected.value,
                          onChanged: (val) {
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
                          enabled: controller.isJE && !_isJointInspectionFlow,
                        )),
                    isVisible: controller.isServiceAffected.value,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: CustomTextField(
                              label: "Train Delay In Min. *",
                              controller: controller.trainDelayMinController,
                              keyboardType: TextInputType.number,
                              enabled:
                                  controller.isJE && !_isJointInspectionFlow,
                              validator: (val) => controller
                                      .isServiceAffected.value
                                  ? _requiredText(val, 'Train Delay In Min.')
                                  : null,
                            )),
                            const SizedBox(width: AppConstants.elementSpacing),
                            Expanded(
                                child: CustomTextField(
                              label: "Train Delay (NOS) *",
                              controller: controller.trainDelayNosController,
                              keyboardType: TextInputType.number,
                              enabled:
                                  controller.isJE && !_isJointInspectionFlow,
                              validator: (val) =>
                                  controller.isServiceAffected.value
                                      ? _requiredText(val, 'Train Delay (NOS)')
                                      : null,
                            )),
                          ],
                        ),
                        const SizedBox(height: AppConstants.elementSpacing),
                        Row(
                          children: [
                            Expanded(
                                child: CustomTextField(
                              label: "Train Cancel (NOS) *",
                              controller: controller.trainCancelNosController,
                              keyboardType: TextInputType.number,
                              enabled:
                                  controller.isJE && !_isJointInspectionFlow,
                              validator: (val) =>
                                  controller.isServiceAffected.value
                                      ? _requiredText(val, 'Train Cancel (NOS)')
                                      : null,
                            )),
                            const SizedBox(width: AppConstants.elementSpacing),
                            Expanded(
                                child: CustomTextField(
                              label: "Train Withdrawal (NOS) *",
                              controller:
                                  controller.trainWithdrawalNosController,
                              keyboardType: TextInputType.number,
                              enabled:
                                  controller.isJE && !_isJointInspectionFlow,
                              validator: (val) => controller
                                      .isServiceAffected.value
                                  ? _requiredText(val, 'Train Withdrawal (NOS)')
                                  : null,
                            )),
                          ],
                        ),
                        const SizedBox(height: AppConstants.elementSpacing),
                        CustomTextField(
                          label: "Train Replace (NOS) *",
                          controller: controller.trainReplaceNosController,
                          keyboardType: TextInputType.number,
                          enabled: controller.isJE && !_isJointInspectionFlow,
                          validator: (val) => controller.isServiceAffected.value
                              ? _requiredText(val, 'Train Replace (NOS)')
                              : null,
                        ),
                        const SizedBox(height: AppConstants.elementSpacing),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustText(
                              name: "Passenger Deboarded",
                              size: AppConstants.textSize,
                              fontWeightName: FontWeight.w600,
                              color: AppColors.orangeColor,
                            ),
                            Obx(() => YesNoToggle(
                              value: controller.isPassengerDeboarding.value,
                              onChanged: (val) {
                                controller.trainDeboardedNosController.clear();
                                controller.isPassengerDeboarding.value = val;
                              },
                              enabled: controller.isJE && !_isJointInspectionFlow,
                            )),
                        ],),
                        Obx(() {
                          if (!controller.isPassengerDeboarding.value)
                            return const SizedBox.shrink();
                          return CustomTextField(
                            label: "Train Deboarded (NOS) *",
                            controller: controller.trainDeboardedNosController,
                            keyboardType: TextInputType.number,
                            enabled: controller.isJE && !_isJointInspectionFlow,
                            validator: (val) =>
                                controller.isPassengerDeboarding.value
                                    ? _requiredText(val, 'Train Deboarded (NOS)')
                                    : null,
                          );
                        }),
                      ],
                    ),
                  ),
                  if (widget.failureType != "Maintenance")
                    CustSection(
                      title: "Passenger Affected *",
                      trailing: Obx(() => YesNoToggle(
                            value: controller.isPassengerAffected.value,
                            onChanged: (val) {
                              if (val == false) {
                                controller.passengersAffectedCountController.clear();
                                controller.trappedDurationController.clear();
                                controller.rescuedDurationController.clear();
                              } else if (val == true) {
                                controller.passengersAffectedCountController.clear();
                                controller.trappedDurationController.clear();
                                controller.rescuedDurationController.clear();
                              }
                              controller.isPassengerAffected.value = val;
                            },
                            enabled: controller.isJE && !_isJointInspectionFlow,
                          )),
                      isVisible: controller.isPassengerAffected.value,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: "Number Of Passenger Affected *",
                            controller:
                                controller.passengersAffectedCountController,
                            keyboardType: TextInputType.number,
                            enabled: controller.isJE && !_isJointInspectionFlow,
                            hintText: "Enter number of Passenger Affected",
                            validator: (val) =>
                                controller.isPassengerAffected.value
                                    ? _requiredText(
                                        val, 'Number Of Passenger Affected')
                                    : null,
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: "Trapped Duration (In Min)",
                                  controller:
                                      controller.trappedDurationController,
                                  keyboardType: TextInputType.number,
                                  enabled: controller.isJE &&
                                      !_isJointInspectionFlow,
                                  hintText: "Enter Trapped Duration",
                                ),
                              ),
                              const SizedBox(
                                  width: AppConstants.elementSpacing),
                              Expanded(
                                child: CustomTextField(
                                  label: "Rescued Duration (In Min)",
                                  controller:
                                      controller.rescuedDurationController,
                                  keyboardType: TextInputType.number,
                                  enabled: controller.isJE &&
                                      !_isJointInspectionFlow,
                                  hintText: "Enter Rescued Duration",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  CustSection(
                    title: "PTW Required? *",
                    trailing: Obx(() => YesNoToggle(
                      enabled:  !_isJointInspectionFlow,
                      value: controller.isPtwRequired.value,
                      onChanged: (val) {
                        if (val == false) {
                          controller.ptwNumberController.clear();
                        } else if (val == true) {
                          controller.ptwNumberController.clear();
                        }
                        controller.isPtwRequired.value = val;
                      },
                    )),
                    isVisible: controller.isPtwRequired.value,
                    child: Column(
                      children: [
                        CustomTextField(
                            controller: controller.ptwNumberController,
                            label: "PTW Number *",
                            keyboardType: TextInputType.number,
                            hintText: "Enter PTW Number",
                            validator: (val) {
                              if (controller.isPtwRequired.value && (val == null || val.trim().isEmpty)) {
                                return "PTW Number is required";
                              }
                              return null;
                            }),
                      ],
                    ),
                  ),
                ],
              ),
            CustSection(
              title: "Failure Rectification Details (RCA)",
              child: Column(
                children: [
                  if (!_isJointInspectionFlow)
                    Form(
                      key: _rcaFormKey,
                      child: Column(
                        children: [
                          Obx(() => CustDropdown(
                                label: 'Object Part *',
                                hint: 'Object Part',
                                items: controller.objectDataList
                                    .map((e) => e.label ?? '')
                                    .toList(),
                                selectedValue:
                                    controller.selectedObjectPart.value,
                                enabled: controller.isJE &&
                                        !_isJointInspectionFlow ||
                                    controller.isTechnician,
                                validator: (v) => _requiredDropdown(
                                  controller.selectedObjectPart.value,
                                  'Object Part',
                                ),
                                onChanged: (v) {
                                  final trimmedV =
                                      v?.toString().trim().toLowerCase();
                                  controller.selectedObjectPart.value = v;
                                  controller.selectedFault.value = null;
                                  final obj =
                                      controller.objectDataList.firstWhere(
                                    (e) =>
                                        e.label?.trim().toLowerCase() ==
                                        trimmedV,
                                    orElse: () => LabelValue(value: "0"),
                                  );
                                  if (obj.value != "0") {
                                    controller.fetchFaults(obj.value!);
                                  } else {
                                    controller.faultTypeList.clear();
                                  }
                                },
                              )),
                          const SizedBox(height: AppConstants.elementSpacing),
                          Obx(() => controller.selectedObjectPart.value != null
                              ? Column(
                                  children: [
                                    CustomTextField(
                                      controller:
                                          controller.objectPartTextController,
                                      label: "Object Part Text *",
                                      enabled: controller.isJE &&
                                              !_isJointInspectionFlow ||
                                          controller.isTechnician,
                                      validator: (val) => _requiredText(
                                          val, 'Object Part Text'),
                                    ),
                                    const SizedBox(
                                        height: AppConstants.elementSpacing),
                                  ],
                                )
                              : const SizedBox.shrink()),
                          Obx(() => CustDropdown(
                                label: 'Fault *',
                                hint: controller.isFaultLoading.value
                                    ? 'Loading...'
                                    : 'Fault',
                                items: controller.isFaultLoading.value
                                    ? []
                                    : controller.faultTypeList
                                        .map((e) => e.label ?? '')
                                        .toList(),
                                selectedValue: controller.selectedFault.value,
                                enabled: (controller.isJE ||
                                        controller.isTechnician) &&
                                    !controller.isFaultLoading.value,
                                validator: (v) => _requiredDropdown(
                                  controller.selectedFault.value,
                                  'Fault',
                                ),
                                onChanged: (v) =>
                                    controller.selectedFault.value = v,
                              )),
                          const SizedBox(height: AppConstants.elementSpacing),
                          Obx(() => controller.selectedFault.value != null
                              ? Column(
                                  children: [
                                    CustomTextField(
                                      controller:
                                          controller.faultTextController,
                                      label: "Fault Text *",
                                      enabled: controller.isJE &&
                                              !_isJointInspectionFlow ||
                                          controller.isTechnician,
                                      validator: (val) =>
                                          _requiredText(val, 'Fault Text'),
                                    ),
                                    const SizedBox(
                                        height: AppConstants.elementSpacing),
                                  ],
                                )
                              : const SizedBox.shrink()),
                          Obx(() => controller.selectedFault.value != null
                              ? const SizedBox(
                                  height: AppConstants.elementSpacing)
                              : const SizedBox.shrink()),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: CustButton(
                              name: "Add",
                              size: 100,
                              fontSize: AppConstants.buttonFontSize,
                              onSelected:
                                  (controller.isJE || controller.isTechnician)
                                      ? (_) {
                                          if (_validateForm(_rcaFormKey)) {
                                            controller.addRcaDetail();
                                            _rcaFormKey.currentState?.reset();
                                          }
                                        }
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => Column(
                        children: controller.rcaDetailsList
                            .asMap()
                            .entries
                            .map((entry) =>
                                _buildRcaDetailCard(entry.value, entry.key))
                            .toList(),
                      )),
                  const SizedBox(height: AppConstants.elementSpacing),
                ],
              ),
            ),
            Obx(() => CustSection(
                  title: "Failure Type",
                  child: Column(
                    children: [
                      CustDropdown(
                        label: "Failure Type *",
                        hint: "Select Failure Type",
                        items: controller.materialTypeList,
                        selectedValue: controller.selectedMaterialType.value,
                        enabled: controller.isJE || controller.isTechnician,
                        validator: (value) {
                          if (value == null || value.isEmpty || value == 'Select Failure Type') {
                            return 'Please select failure type';
                          }
                          return null;
                        },
                        onChanged: (v) {
                          controller.selectedMaterialType.value = v!;
                        },
                      ),
                if (controller.selectedMaterialType.value == "Other") ...[
                const SizedBox(height: 16),
                  CustomTextField(
                      label: "Remark",
                      controller: controller.failureTypeController,
                      enabled: controller.isJE || controller.isTechnician),
            ]
                    ],
                  ),
                )),
            Obx(() {
              if (controller.selectedMaterialType.value != "Hardware") {
                return const SizedBox.shrink();
              }

              return CustSection(
                title: "Spare Part Replace",
                trailing: YesNoToggle(
                  value: controller.isSparePartReplaced.value,
                  onChanged: (val) {
                    if (val == false) {
                      controller.replacedMaterialsList.clear();
                    } else if (val == true) {
                      controller.replacedMaterialsList.clear();
                    }
                    controller.isSparePartReplaced.value = val;
                  },
                  enabled: controller.isJE && controller.replacedMaterialsList.isEmpty,
                ),
                isVisible: controller.isSparePartReplaced.value,
                child: controller.isSparePartReplaced.value
                    ? _buildSparePartReplaceSection(
                        enabled: controller.isJE || controller.isTechnician,
                      )
                    : const SizedBox.shrink(),
              );
            }),
            Obx(() {
              if (controller.selectedMaterialType.value != "Hardware"&&controller.replacedMaterialsList.isEmpty) {
                return const SizedBox.shrink();
              }

              return CustSection(
                title: "Material Dismantle",
                isVisible:  controller.isMaterialDismantle.value,
                trailing: YesNoToggle(
                  value: controller.isMaterialDismantle.value,
                  onChanged: (val) {
                    if (val == false) {
                      controller.dismantleMaterialsList.clear();
                    } else if (val == true) {
                      controller.dismantleMaterialsList.clear();
                    }
                    controller.isMaterialDismantle.value = val;
                  },
                  enabled: (controller.isJE || controller.isTechnician) && controller.dismantleMaterialsList.isEmpty,
                ),
                child: _buildMaterialDismantleSection(
                  enabled: controller.isJE || controller.isTechnician,
                ),
              );
            }),
            if (!_isJointInspectionFlow)
              CustSection(
                title: "Joint Inspection *",
                trailing: Obx(() => YesNoToggle(
                      value: controller.isJointInspection.value,
                      onChanged: (val) =>
                          controller.isJointInspection.value = val,
                      enabled: controller.isJE && controller.jointInspectionHistoryList.isEmpty,
                    )),
                isVisible: controller.isJointInspection.value,
                child: Obx(
                  () => _buildJointInspectionSection(
                    enabled: controller.isJE,
                  ),
                ),
              ),
            Obx(
              () => controller.showMeasurementButton.value
                  ? CustSection(
                      title: "Measurement Reading",
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: CustButton(
                          name: "Measurement Reading",
                          fontSize: AppConstants.buttonFontSize,
                          size: 200,
                          onSelected: (_) => _showMeasurementDialog(),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Form(
              key: _formBottomKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustSection(
                    title: "Attachments",
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CustText.body("After ",
                                fontWeightName: FontWeight.w500),
                            const Text("(Max File Size 1MB)",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const SizedBox(width: AppConstants.sectionSpacing),
                            if (!_isJointInspectionFlow)
                              _buildUploadButton(controller.afterFiles,
                                  enabled: controller.isJE &&
                                          !_isJointInspectionFlow ||
                                      controller.isTechnician),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Obx(() => Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: controller.afterFiles
                                  .map<Widget>((file) => _buildAttachmentItem(
                                      file['name']!,
                                      file['size']!,
                                      controller.afterFiles,
                                      file))
                                  .toList(),
                            )),
                        const SizedBox(height: AppConstants.sectionSpacing),
                        Row(
                          children: [
                            CustText.body("Upload RCA ",
                                fontWeightName: FontWeight.w500),
                            const Text("(Max File Size 1MB)",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const SizedBox(width: AppConstants.sectionSpacing),
                            if (!_isJointInspectionFlow)
                              _buildUploadButton(controller.rcaFiles,
                                  enabled: controller.isJE &&
                                          !_isJointInspectionFlow ||
                                      controller.isTechnician),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Obx(() => Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: controller.rcaFiles
                                  .map<Widget>((file) => _buildAttachmentItem(
                                      file['name']!,
                                      file['size']!,
                                      controller.rcaFiles,
                                      file))
                                  .toList(),
                            )),
                        const SizedBox(height: AppConstants.sectionSpacing),
                        Obx(() {
                          final hasImages =
                              controller.beforeImagesList.isNotEmpty ||
                                  controller.afterImagesList.isNotEmpty ||
                                  controller.rcaImagesList.isNotEmpty;
                          if (!hasImages) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const SizedBox(
                                  height: AppConstants.sectionSpacing),
                              CustText(name: "Display Uploaded Images:", color: AppColors.textDarkSecondary,fontWeightName: FontWeight.w500,size: AppConstants.textSize,),
                              const SizedBox(height: AppConstants.labelSpacing),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustText.body("Before:"),
                                        const SizedBox(height: 8),
                                        Obx(() => Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: controller
                                                  .beforeImagesList
                                                  .map<Widget>((file) =>
                                                      _buildUploadedImagePreview(
                                                          file['path']!))
                                                  .toList(),
                                            )),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustText.body("After:"),
                                        const SizedBox(height: 8),
                                        Obx(() => Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: controller
                                                  .afterImagesList
                                                  .map<Widget>((file) =>
                                                      _buildUploadedImagePreview(
                                                          file['path']!))
                                                  .toList(),
                                            )),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustText.body("RCA:"),
                                        const SizedBox(height: 8),
                                        Obx(() => Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: controller.rcaImagesList
                                                  .map<Widget>((file) =>
                                                      _buildUploadedImagePreview(
                                                          file['path']!))
                                                  .toList(),
                                            )),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  if (!_isJointInspectionFlow)
                    CustSection(
                      title: "Failure Rectification Details",
                      child: Column(
                        children: [
                          CustomTextField(
                            label: "Failure Rectification Details *",
                            controller: controller
                                .failureRectificationDetailsController,
                            focusNode: controller.failureRectificationFocusNode,
                            hintText: "Enter Rectification Details",
                            enabled: controller.isJE && !_isJointInspectionFlow,
                            maxLines: 4,
                            autofocus: false,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "Failure Rectification Details is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          CustDropdown(
                            label: "User Status *",
                            hint: "Select",
                            items: controller.userStatusList
                                .map((e) => e.label ?? '')
                                .toList(),
                            selectedValue: controller.selectedUserStatus.value,
                            enabled: controller.isJE && !_isJointInspectionFlow,
                            disabledItemFn: controller.isCloseUserStatusBlocked
                                ? (item) => item.trim().toLowerCase() == 'close'
                                : null,
                              onChanged: (v) {
                                print("Selected User Status = $v");
                                print("Main Status = ${controller.mainStatusName.value}");
                                print("Blocked = ${controller.isCloseUserStatusBlocked}");

                                if (controller.isCloseUserStatusBlocked &&
                                    v?.trim().toLowerCase() == 'closed') {
                                  controller.showPendingJointInspectionPopup();
                                  return;
                                }

                                controller.selectedUserStatus.value = v;
                                // Unfocus the failure rectification details field
                                controller.failureRectificationFocusNode.unfocus();
                              },
                            validator: (value) {
                              if (controller.selectedUserStatus.value == null ||
                                  controller.selectedUserStatus.value!.trim().isEmpty||controller.selectedUserStatus.value=="Select User Status") {
                                return "User Status is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          if (controller.selectedUserStatus.value ==
                              "Under Observation") ...[
                            CustDateTimePicker(
                              label: "Under Observation Date *",
                              hint: "DD/MM/YYYY hh:mm",
                              selectedDateTime:
                                  controller.selectedUnderObservationDate.value,
                              enabled:
                                  controller.isJE && !_isJointInspectionFlow,
                              firstDate: DateTime.now(),
                              validator: (val) {
                                if (controller.selectedUserStatus.value ==
                                        "Under Observation" &&
                                    controller.selectedUnderObservationDate
                                            .value ==
                                        null) {
                                  return "Under Observation Date is required";
                                }
                                return null;
                              },
                              onDateTimeSelected: (dt) {
                                controller.selectedUnderObservationDate.value = dt;
                                controller.failureRectificationFocusNode.unfocus();
                              },
                            ),
                            const SizedBox(height: AppConstants.elementSpacing),
                          ],
                          CustDateTimePicker(
                            label: "Failure Attended *",
                            hint: "DD/MM/YYYY hh:mm",
                            selectedDateTime:
                                controller.selectedFailureAttendedDate.value,
                            enabled: controller.isJE && !_isJointInspectionFlow,
                            firstDate: controller.selectedFailureOccurrenceDate.value,
                            lastDate: DateTime.now(),
                            onDateTimeSelected: (dateTime) {
                              controller.onFailureAttendedDateSelected(dateTime);
                              controller.failureRectificationFocusNode.unfocus();
                            },
                            validator: (value) {
                              if (controller.selectedFailureAttendedDate.value == null) {
                                return "Failure Attended is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          CustDateTimePicker(
                            label: "Actual Failure Rectified *",
                            hint: "DD/MM/YYYY hh:mm",
                            selectedDateTime: controller
                                    .selectedActualFailureRectifiedDate.value,
                            enabled: controller.isJE && !_isJointInspectionFlow,
                            firstDate: controller.selectedFailureAttendedDate.value ??
                                controller.selectedFailureOccurrenceDate.value,
                            lastDate: DateTime.now(),
                            onDateTimeSelected: (dateTime) {
                              controller.onActualFailureRectifiedDateSelected(dateTime);
                              controller.failureRectificationFocusNode.unfocus();
                            },
                            validator: (value) {
                              if (controller.selectedActualFailureRectifiedDate.value == null) {
                                return "Actual Failure Rectified is required";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  if (_isJointInspectionFlow) ...[
                    const SizedBox(height: AppConstants.sectionSpacing),
                    _buildJointInspectionActionFields(),
                    const SizedBox(height: AppConstants.sectionSpacing),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: CustOutlineButton(
                          name: "Cancel",
                          size: double.infinity,
                          sHeight: AppConstants.buttonHeight,
                          onSelected: (_) => _handleCancel(),
                        ),
                      ),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                        child: CustButton(
                          name: "Submit",
                          sHeight: AppConstants.buttonHeight,
                          size: double.infinity,
                          onSelected: (_) => _isJointInspectionFlow
                              ? _submitJointInspectionForm()
                              : _submitForm(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
