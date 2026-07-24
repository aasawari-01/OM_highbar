part of 'create_failure_screen.dart';

extension StationCreateFormExt on _CreateFailureScreenState {
  Widget _buildStationCreateForm(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustText.sectionHeader(
                  "Failure Details",
                  color: AppColors.orangeColor,
                ),
                Spacer(),
                GestureDetector(
                  onTap: _showActionByDialog,
                  child: Icon(TablerIcons.hand_click,
                      size: 24, color: AppColors.orangeColor),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            Obx(() => CustText.body(
              "Failure No.: ${controller.notificationCode.value} ${controller.mainStatusName.value == null ? "" : "(${controller.mainStatusName.value ?? ''})"}",
              size: 18,
              color: AppColors.black,
              fontWeightName: FontWeight.w600,
            )),
            const SizedBox(height: AppConstants.sectionSpacing),
            Obx(() => CustSection(
                  title: "Station Selection",
                  child: CustDropdown(
                    label: "Selected Station",
                    hint: "Select Station",
                    items: controller.popupStationList.map((e) => e.label ?? '').toList(),
                    selectedValue: session.selectedStationName.value,
                    onChanged: (val) {
                      session.selectedStationName.value = val;
                      session.selectedStationId.value = controller.popupStationList
                          .firstWhere((e) => e.label == val, orElse: () => LabelValue(value: '0'))
                          .value ?? '0';
                    },
                  ),
                )),
            CustSection(
              title: "Basic Information",
              trailing: Obx(() => YesNoToggle(
                value: controller.isBasicInfoVisible.value,
                onChanged: (val) =>
                controller.isBasicInfoVisible.value = val,
              )),
              isVisible: controller.isBasicInfoVisible.value,
              child: Column(
                children: [
                  Obx(() => CustDropdown(
                        label: "Functional Location *",
                        hint: "Select...",
                        items: controller.functionalLocationList
                            .map((e) => e.label ?? '')
                            .toList(),
                        selectedValue:
                            controller.selectedFunctionalLocation.value,
                        onChanged: (v) =>
                            controller.onFunctionalLocationChanged(v),
                        validator: (val) => _requiredDropdown(val, "Functional Location"),
                      )),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => Row(
                        children: [
                          Expanded(
                            child: CustDropdown(
                              label: "Priority *",
                              hint: "Select...",
                              items: controller.priorityTypeList
                                  .map((e) => e.label ?? '')
                                  .toList(),
                              selectedValue: controller.selectedPriority.value,
                              onChanged: (v) =>
                                  controller.selectedPriority.value = v,
                              validator: (val) => _requiredDropdown(val, "Priority"),
                            ),
                          ),
                          const SizedBox(width: AppConstants.elementSpacing),
                          Expanded(
                            child: CustDropdown(
                              label: "Department *",
                              hint: "Select...",
                              items: controller.departmentList
                                      .map((e) => e.label ?? '')
                                      .toList(),
                              selectedValue:
                                  controller.selectedDepartment.value,
                              onChanged: (v) =>
                                  controller.onDepartmentChanged(v),
                              validator: (val) => _requiredDropdown(val, "Department"),
                            ),
                          ),
                        ],
                      )),
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustomTextField(
                    label: "Failure Description",
                    controller: controller.failureDescriptionController,
                    hintText: "Enter failure description",
                    maxLines: 4,
                    maxLength: 500,
                    enabled: controller.isStationController,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Failure Description is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => CustDropdown(
                        label: "Location *",
                        hint: "Select...",
                        items: controller.locationTypeList
                            .map((e) => e.label ?? '')
                            .toList(),
                        selectedValue: controller.selectedLocation.value,
                        onChanged: (value) {
                          controller.onLocationChanged(value);
                        },
                        validator: (val) => _requiredDropdown(val, "Location"),
                      )),
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustomTextField(
                    label: "Sub Location",
                    controller: controller.subLocationController,
                    hintText: "Enter Sub Location",
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: "System",
                          controller: controller.systemController,
                          hintText: "Enter System",
                        ),
                      ),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                        child: CustomTextField(
                          label: "Train Id",
                          controller: controller.trainIdController,
                          hintText: "Enter Train Id",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustDateTimePicker(
                    label: "Actual Failure Occurrence",
                    hint: "DD/MM/YYYY hh:mm",
                    selectedDateTime:
                        controller.selectedFailureOccurrenceDate.value,
                    onDateTimeSelected: (dt) =>
                        controller.selectedFailureOccurrenceDate.value = dt,
                    validator: (val) {
                      if (controller.selectedFailureOccurrenceDate.value == null) {
                        return "Actual Failure Occurrence is required";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => CustDropdown(
                    label: "Failure Reported by",
                    hint: "Select...",
                    items: controller.userList.map((e) => e.label ?? '').toList(),
                    selectedValue: controller.selectedFailureReportedBy.value,
                    onChanged: (v) => controller.selectedFailureReportedBy.value = v,
                  )),
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustDateTimePicker(
                    label: "Actual Failure Completed Date & Time",
                    hint: "DD/MM/YYYY hh:mm",
                    selectedDateTime:
                        controller.selectedFailureCompletedDate.value,
                    enabled: false,
                    onDateTimeSelected: (dt) =>
                        controller.selectedFailureCompletedDate.value = dt,
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => CustDropdown(
                        label: "Failure Category Type",
                        hint: "Select...",
                        items: controller.corrNotificationTypeList
                            .map((e) => e.label ?? '')
                            .toList(),
                        selectedValue:
                            controller.selectedFailureCategoryType.value,
                        onChanged: (v) =>
                            controller.selectedFailureCategoryType.value = v,
                        validator: (val) => _requiredDropdown(val, "Failure Category Type"),
                      )),
                ],
              ),
            ),
            CustSection(
              title: "Trip Affected",
              trailing: Obx(() => YesNoToggle(
                    value: controller.isServiceAffected.value,
                    onChanged: (val) {
                      if (val == false) {
                        controller.tripDelayUplineController.clear();
                        controller.trainCancelNosController.clear();
                        controller.tripDelayDownlineController.clear();
                        controller.trainDelayMinController.clear();
                        controller.trainWithdrawalNosController.clear();
                        controller.trainReplaceNosController.clear();
                        controller.trainDeboardedNosController.clear();
                        controller.isPassengerDeboarding.value = false;
                      }
                      controller.isServiceAffected.value = val;
                    },
                  )),
              isVisible: controller.isServiceAffected.value,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: CustomTextField(
                              label: "Trip Delay Upline (NOS) *",
                              controller: controller.tripDelayUplineController,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Trip Delay Upline",
                              validator: (val) {
                                if (controller.isServiceAffected.value && (val == null || val.trim().isEmpty)) {
                                  return "Trip Delay Upline is required";
                                }
                                return null;
                              })),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                          child: CustomTextField(
                              label: "Trip Cancel (NOS) *",
                              controller: controller.trainCancelNosController,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Trip Cancel",
                              validator: (val) {
                                if (controller.isServiceAffected.value && (val == null || val.trim().isEmpty)) {
                                  return "Trip Cancel is required";
                                }
                                return null;
                              })),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                          child: CustomTextField(
                              label: "Trip Delay Downline (NOS) *",
                              controller:
                                  controller.tripDelayDownlineController,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Trip Delay Downline",
                              validator: (val) {
                                if (controller.isServiceAffected.value && (val == null || val.trim().isEmpty)) {
                                  return "Trip Delay Downline is required";
                                }
                                return null;
                              })),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                          child: CustomTextField(
                              label: "Trip Delay in Min. *",
                              controller: controller.trainDelayMinController,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Trains Delayed In Min",
                              validator: (val) {
                                if (controller.isServiceAffected.value && (val == null || val.trim().isEmpty)) {
                                  return "Trip Delay in Min is required";
                                }
                                return null;
                              })),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                          child: CustomTextField(
                              label: "Trip Withdrawal (NOS) *",
                              controller:
                                  controller.trainWithdrawalNosController,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Train Withdrawal",
                              validator: (val) {
                                if (controller.isServiceAffected.value && (val == null || val.trim().isEmpty)) {
                                  return "Trip Withdrawal is required";
                                }
                                return null;
                              })),
                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                          child: CustomTextField(
                              label: "Train Replace (NOS) *",
                              controller: controller.trainReplaceNosController,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Train Replace",
                              validator: (val) {
                                if (controller.isServiceAffected.value && (val == null || val.trim().isEmpty)) {
                                  return "Train Replace is required";
                                }
                                return null;
                              })),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Obx(() => controller.isServiceAffected.value
                      ? _buildToggleItem(
                          "Passenger Deboarded *",
                          controller.isPassengerDeboarding.value,
                          (val) => controller.isPassengerDeboarding.value = val)
                      : const SizedBox.shrink()),
                  Obx(() {
                    if (!controller.isPassengerDeboarding.value || !controller.isServiceAffected.value)
                      return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.elementSpacing),
                      child: CustomTextField(
                          label: "Train Deboarded (NOS) *",
                          controller: controller.trainDeboardedNosController,
                          keyboardType: TextInputType.number,
                          hintText: "Enter Number Of Train Deboarded",
                          validator: (val) {
                                if (controller.isPassengerDeboarding.value && (val == null || val.trim().isEmpty)) {
                                  return "Train Deboarded is required";
                                }
                                return null;
                              }),
                    );
                  }),
                ],
              ),
            ),
            CustSection(
              title: "Passenger Affected *",
              trailing: Obx(() => YesNoToggle(
                    value: controller.isPassengerAffected.value,
                    onChanged: (val) {
                      if (val == false) {
                        controller.passengersAffectedCountController.clear();
                        controller.trappedDurationController.clear();
                        controller.rescuedDurationController.clear();
                      }
                      controller.isPassengerAffected.value = val;
                    },
                  )),
              isVisible: controller.isPassengerAffected.value,
              child: Column(
                children: [
                  CustomTextField(
                      label: "Number Of Passenger Affected *",
                      controller: controller.passengersAffectedCountController,
                      keyboardType: TextInputType.number,
                      hintText: "Enter number of Passenger Affected",
                      validator: (val) {
                        if (controller.isPassengerAffected.value && (val == null || val.trim().isEmpty)) {
                          return "Number Of Passenger Affected is required";
                        }
                        return null;
                      }),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(
                    children: [
                      Expanded(
                          child: CustomTextField(
                              label: "Trapped Duration *",
                              controller: controller.trappedDurationController,
                              hintText: "Enter Trapped Duration",
                              validator: (val) {
                              if (controller.isPassengerAffected.value && (val == null || val.trim().isEmpty)) {
                              return "Trapped Duration is required";
                              }
                              return null;
                              }
                          )),

                      const SizedBox(width: AppConstants.elementSpacing),
                      Expanded(
                          child: CustomTextField(
                              label: "Rescued Duration *",
                              controller: controller.rescuedDurationController,
                              hintText: "Enter Rescued Duration",
                              validator: (val) {
                                if (controller.isPassengerAffected.value &&
                                    (val == null || val
                                        .trim()
                                        .isEmpty)) {
                                  return "Number Of Passenger Affected is required";
                                }
                                return null;
                              }
                              )),
                    ],
                  ),
                ],
              ),
            ),
            CustSection(
              title: "Attachments",
              child: Column(
                children: [
                  Row(
                    children: [
                      CustText.body("Before ", fontWeightName: FontWeight.w500),
                      const Text("(Max File Size 1MB)",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: AppConstants.sectionSpacing),
                      _buildUploadButton(controller.beforeFiles, enabled: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: controller.beforeFiles
                            .map<Widget>((file) => _buildAttachmentItem(
                                file['name']!,
                                file['size']!,
                                controller.beforeFiles,
                                file))
                            .toList(),
                      )),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.sectionSpacing),
            Row(
              children: [
                Expanded(
                  child: CustOutlineButton(
                    name: "Cancel",
                    size: double.infinity,
                    sHeight: AppConstants.buttonHeight,
                    borderRadius: AppConstants.inputRadius,
                    onSelected: (_) => _handleCancel(),
                  ),
                ),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(
                  child: CustButton(
                    name: "Save",
                    size: double.infinity,
                    sHeight: AppConstants.buttonHeight,
                    borderRadius: AppConstants.inputRadius,
                    onSelected: (_) => _submitForm(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

}
