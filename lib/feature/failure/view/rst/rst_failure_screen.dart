import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';
import 'package:om_mobile/utils/widgets/custom_app_bar.dart';
import 'package:om_mobile/utils/widgets/cust_dropdown.dart';
import 'package:om_mobile/utils/widgets/cust_textfield.dart';
import 'package:om_mobile/utils/widgets/cust_toggle.dart';
import 'package:om_mobile/utils/widgets/cust_button.dart';
import 'package:om_mobile/utils/widgets/cust_data_card.dart';
import 'package:om_mobile/utils/widgets/cust_section.dart';
import '../../../../service/network_service/app_urls.dart';
import '../../../../utils/widgets/cust_date_time_picker.dart';
import '../../../../utils/widgets/cust_loader.dart';
import '../../../../utils/widgets/horizontal_paginated_view.dart';
import '../../controller/rst_failure_controller.dart';
import 'sic_checklist_screen.dart';
import 'package:flutter/services.dart';
import '../../../../service/master_data_sync_service.dart';

class RstFailureScreen extends StatefulWidget {
  final int? notificationId;
  const RstFailureScreen({Key? key, this.notificationId}) : super(key: key);

  @override
  State<RstFailureScreen> createState() => _RstFailureScreenState();
}

class _RstFailureScreenState extends State<RstFailureScreen> {
  late final RstFailureController controller;
  final _matReqFormKeys = <int, GlobalKey<FormState>>{};
  final _partCFormKey = GlobalKey<FormState>();
  final _partDFormKey = GlobalKey<FormState>();
  final _partEFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    debugPrint("_RstFailureScreenState.initState: CALLED");
    debugPrint("_RstFailureScreenState.initState: notificationId=${widget.notificationId}");
    
    if (Get.isRegistered<RstFailureController>()) {
      debugPrint("_RstFailureScreenState.initState: Deleting existing controller");
      Get.delete<RstFailureController>();
    }
    controller = Get.put(RstFailureController());
    debugPrint("_RstFailureScreenState.initState: Controller created");

    if (widget.notificationId != null) {
      debugPrint("_RstFailureScreenState.initState: Scheduling fetchRstFailureData with id=${widget.notificationId}");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint("_RstFailureScreenState.initState: Calling fetchRstFailureData");
        controller.fetchRstFailureData(widget.notificationId!);
      });
    } else {
      debugPrint("_RstFailureScreenState.initState: notificationId is null, skipping fetch");
    }
  }

  Widget _buildSectionHeader(String title, String status, bool isExpanded, VoidCallback onTap, {bool isCompleted = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            CustText.sectionHeader(
              title,
              color: AppColors.orangeColor,
            ),
            const Spacer(),
            CustText.body(
              status,
              color: isCompleted ? Colors.green : AppColors.orangeColor,
              fontWeightName: FontWeight.w600,
              size: 13,
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadPopup(List<Map<String, dynamic>> targetList) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, color: Colors.black, size: 24),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _uploadPopupOption(
                    icon: TablerIcons.camera,
                    onTap: () async {
                      try {
                        Get.back();
                        final ImagePicker picker = ImagePicker();
                        final XFile? image =
                        await picker.pickImage(source: ImageSource.camera);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          final sizeInMb = bytes.length / (1024 * 1024);
                          targetList.add({
                            'name': image.name,
                            'size': '${sizeInMb.toStringAsFixed(1)} MB',
                            'path': image.path,
                            'url': '',
                            'isNetwork': false,
                          });
                        }
                      } catch (e) {
                        debugPrint("Error picking image: $e");
                        Get.snackbar("Error",
                            "Could not capture photo. Please check camera permissions.");
                      }
                    },
                  ),
                  const SizedBox(width: 30),
                  _uploadPopupOption(
                    icon: TablerIcons.paperclip,
                    onTap: () async {
                      try {
                        Get.back();
                        final FilePickerResult? result =
                        await FilePicker.platform.pickFiles();
                        if (result != null) {
                          for (var file in result.files) {
                            final sizeInMb = file.size / (1024 * 1024);
                            targetList.add({
                              'name': file.name,
                              'size': '${sizeInMb.toStringAsFixed(1)} MB',
                              'path': file.path,
                              'url': '',
                              'isNetwork': false,
                            });
                          }
                        }
                      } catch (e) {
                        debugPrint("Error picking file: $e");
                        Get.snackbar("Error", "Could not pick file.");
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustText.body(
                "Upload Files or Take Photos",
                size: 16,
                color: AppColors.textMutedLight,
                fontWeightName: FontWeight.w600,
              ),
              const SizedBox(height: AppConstants.labelSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadPopupOption({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.buttonOutlineColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(icon, color: Colors.black, size: 25),
        ),
      ),
    );
  }

  Widget _buildUploadButton(List<Map<String, dynamic>> targetList) {
    return CustOutlineButton(
      name: "Upload",
      size: 100,
      sHeight: 25,
      fontSize: AppConstants.buttonFontSize,
      borderColor: AppColors.orangeColor,
      textDarkPrimary: AppColors.orangeColor,
      onSelected: (_) => _showUploadPopup(targetList),
    );
  }
  Widget _buildAttachmentRow(String label, List<Map<String, dynamic>> targetList) {
    return Obx(() {
      final hasFiles = targetList.isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustText.body(label, size: 12),
              const SizedBox(width: AppConstants.elementSpacing),
              _buildUploadButton(targetList),
            ],
          ),
          if (hasFiles) ...[
            const SizedBox(height: AppConstants.elementSpacing),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: targetList
                  .map<Widget>((file) => _buildAttachmentItem(
                  file['name']?.toString() ?? 'Unknown',
                  file['size']?.toString() ?? '',
                  targetList,
                  file))
                  .toList(),
            ),
          ],
        ],
      );
    });
  }
  Widget _buildAttachmentItem(String name, String size,
      List<Map<String, dynamic>> targetList, Map<String, dynamic> file) {
    return GestureDetector(
      onTap: () => _showFilePreview(file),
      child: Container(
        width: (MediaQuery.of(context).size.width - 44) / 2,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(TablerIcons.photo,
                  color: AppColors.textMutedLight, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustText(name: name, size: 14, color: Colors.black87, maxLines: 1),
                  CustText(name: size, size: 12, color: Colors.black54),
                ],
              ),
            ),
            if (!controller.isViewOnly.value)
              GestureDetector(
                onTap: () => targetList.remove(file),
                child: const Icon(Icons.close, size: 20, color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilePreview(Map<String, dynamic> file) {
    final String path = file['path'] ?? '';
    final String url = file['url'] ?? '';
    final bool isNetwork = file['isNetwork'] == true;
    final String name = file['name'] ?? 'File Preview';
    final bool isImage = name.toLowerCase().endsWith('.jpg') ||
        name.toLowerCase().endsWith('.jpeg') ||
        name.toLowerCase().endsWith('.png');

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: CustText(
                    name: name, size: 16, color: Colors.black, fontWeightName: FontWeight.bold),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Get.back(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: isImage
                    ? (isNetwork == true
                    ? Image.network(
                  url,
                  fit: BoxFit.contain,
                )
                    : Image.file(
                  File(path),
                  fit: BoxFit.contain,
                ))
                    : Column(
                  children: [
                    const Icon(
                      TablerIcons.file_description,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    CustText(
                      name: "Preview not available for this file type",
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildToggleSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustText.body(title, color: AppColors.orangeColor, fontWeightName: FontWeight.w500),
          YesNoToggle(
            value: value,
            onChanged: onChanged,
            enabled: !controller.isViewOnly.value,
          ),
        ],
      ),
    );
  }

  Widget _buildPartA() {
    return Obx(() => CustSection(
      title: 'Part A',
      isVisible: controller.isPartAExpanded.value,
      trailing: GestureDetector(
        onTap: () => controller.isPartAExpanded.toggle(),
        child: Icon(
          controller.isPartAExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText.body("Failure Creation By PPIO/RSC", color: AppColors.textMutedLight, fontWeightName: FontWeight.bold),
          const SizedBox(height: AppConstants.elementSpacing),
          Row(
            children: [
              Expanded(
                child: CustDropdown(
                  label: "Priority",
                  hint: "Select",
                  items: controller.priorityStrings,
                  selectedValue: controller.selectedPriority.value,
                  onChanged: (v) => controller.selectedPriority.value = v,
                  enabled: !controller.isViewOnly.value,
                ),
              ),
              const SizedBox(width: AppConstants.elementSpacing),
              Expanded(
                child: CustDropdown(
                  label: "Department",
                  hint: "Select",
                  items: controller.departmentStrings,
                  selectedValue: controller.selectedDepartment.value,
                  onChanged: (v) {},
                  enabled: !controller.isViewOnly.value,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Failure Type",
            hint: "Select",
            items: [],
            selectedValue: controller.selectedFailureType.value,
            onChanged: (v) => controller.selectedFailureType.value = v,
            enabled: !controller.isViewOnly.value,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustomTextField(
            label: "Failure Description",
            hintText: "Enter description",
            controller: controller.failureDescriptionController,
            maxLines: 3,
            enabled: !controller.isViewOnly.value,
            readOnly: controller.isViewOnly.value,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Functional Location",
            hint: "Select",
            items: controller.functionalLocationStrings,
            selectedValue: controller.selectedFunctionalLocation.value,
            onChanged: (v) => controller.selectedFunctionalLocation.value = v,
            enabled: !controller.isViewOnly.value,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Equipment Name",
            hint: "Select",
            items: controller.equipmentStrings,
            selectedValue: controller.selectedEquipmentName.value,
            onChanged: (v) => controller.selectedEquipmentName.value = v,
            enabled: !controller.isViewOnly.value,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Nature of Work",
            hint: "Select",
            items: controller.natureOfWorkStrings,
            selectedValue: controller.selectedNatureOfWork.value,
            onChanged: (value) { },
            enabled: !controller.isViewOnly.value,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          // Main Line Fault Fields (shown when WorkNatureId == 10)
          Obx(() => controller.selectedNatureOfWorkId.value == '10' ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: "Location of Failure",
                hintText: "Enter location",
                controller: controller.locationOfFailureController,
                enabled: !controller.isViewOnly.value,
                readOnly: controller.isViewOnly.value,
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              CustomTextField(
                label: "Actual Failure Occurrence On",
                hintText: "Select date",
                controller: TextEditingController(text: controller.actualFailureOccuranceOn.value?.toString() ?? ''),
                enabled: !controller.isViewOnly.value,
                readOnly: controller.isViewOnly.value,
                onTap: controller.isViewOnly.value ? null : () async {
                  final date = await showDatePicker(
                    context: Get.context!,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    controller.actualFailureOccuranceOn.value = date;
                  }
                },
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              CustomTextField(
                label: "Main Line Action Taken By",
                hintText: "Enter name",
                controller: controller.mainLineActionTakenByController,
                enabled: !controller.isViewOnly.value,
                readOnly: controller.isViewOnly.value,
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              CustomTextField(
                label: "Train Operator Name",
                hintText: "Enter name",
                controller: controller.trainOperatorNameController,
                enabled: !controller.isViewOnly.value,
                readOnly: controller.isViewOnly.value,
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              CustomTextField(
                label: "Main Line Action Taken",
                hintText: "Enter action",
                controller: controller.mainLineActionController,
                maxLines: 3,
                enabled: !controller.isViewOnly.value,
                readOnly: controller.isViewOnly.value,
              ),
            ],
          ) : const SizedBox.shrink()),
          const SizedBox(height: AppConstants.elementSpacing),
          // Service Affected Toggle
          _buildToggleSwitch("Service Affected", controller.isServiceAffected.value, (val) => controller.isServiceAffected.value = val),
          Obx(() => controller.isServiceAffected.value ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.elementSpacing),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Train Delay In Min",
                      hintText: "Enter minutes",
                      controller: controller.trainDelayInMinController,
                      keyboardType: TextInputType.number,
                      enabled: !controller.isViewOnly.value,
                      readOnly: controller.isViewOnly.value,
                    ),
                  ),
                  const SizedBox(width: AppConstants.elementSpacing),
                  Expanded(
                    child: CustomTextField(
                      label: "Train Delay In No",
                      hintText: "Enter number",
                      controller: controller.trainDelayInNoController,
                      keyboardType: TextInputType.number,
                      enabled: !controller.isViewOnly.value,
                      readOnly: controller.isViewOnly.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "No Of Train Cancel",
                      hintText: "Enter number",
                      controller: controller.noOfTrainCancelController,
                      keyboardType: TextInputType.number,
                      enabled: !controller.isViewOnly.value,
                      readOnly: controller.isViewOnly.value,
                    ),
                  ),
                  const SizedBox(width: AppConstants.elementSpacing),
                  Expanded(
                    child: CustomTextField(
                      label: "Train Withdrawal(NOS)",
                      hintText: "Enter number",
                      controller: controller.noOfTrainWithdrawalController,
                      keyboardType: TextInputType.number,
                      enabled: !controller.isViewOnly.value,
                      readOnly: controller.isViewOnly.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              // Commented out as per user request
              // CustomTextField(
              //   label: "No Of Train Replace",
              //   hintText: "Enter number",
              //   controller: controller.noOfTrainReplaceController,
              //   keyboardType: TextInputType.number,
              //   enabled: !controller.isViewOnly.value,
              //   readOnly: controller.isViewOnly.value,
              // ),
            ],
          ) : const SizedBox.shrink()),
          // Train Replace Toggle
          _buildToggleSwitch("Train Replace", controller.isTrainReplace.value, (val) => controller.isTrainReplace.value = val),
          // Passenger Deboarding Toggle
          _buildToggleSwitch("Passenger Deboarding", controller.isPassengerDeboarding.value, (val) => controller.isPassengerDeboarding.value = val),
          Obx(() => controller.isPassengerDeboarding.value ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: "No of Train Deboarded",
                hintText: "Enter number",
                controller: controller.noOfTrainDeboardedController,
                keyboardType: TextInputType.number,
                enabled: !controller.isViewOnly.value,
                readOnly: controller.isViewOnly.value,
              ),
            ],
          ) : const SizedBox.shrink()),
          const SizedBox(height: AppConstants.sectionSpacing),
          CustText(
            name: "Attachments: ",
            size: AppConstants.textSize,
            fontWeightName: FontWeight.w500,
            color: AppColors.textMutedLight,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildViewOnlyImageRow(
            "Before",
            controller.beforeFiles,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Do not Report",
            hint: "Select",
            items: const ['Yes', 'No'],
            selectedValue: controller.selectedDoNotReport.value,
            onChanged: (v) => controller.selectedDoNotReport.value = v,
            enabled: !controller.isViewOnly.value,
          ),
        ],
      ),
    ));
  }

  Widget _buildPartB() {
    return Obx(() => CustSection(
      title: 'Part B',
      isVisible: controller.isPartBExpanded.value,
      trailing: GestureDetector(
        onTap: () => controller.isPartBExpanded.toggle(),
        child: Icon(
          controller.isPartBExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText.body("Failure Assignment By PPIO", color: AppColors.textMutedLight, fontWeightName: FontWeight.bold),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Responsible Person",
            hint: "Select",
            items: const [],
            selectedValue: controller.selectedResponsiblePerson.value,
            onChanged: (v) => controller.selectedResponsiblePerson.value = v,
            enabled: !controller.isViewOnly.value,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustomTextField(
            label: "Train Running KM",
            hintText: "Enter KM",
            controller: controller.trainRunningKmController,
            enabled: !controller.isViewOnly.value,
            readOnly: controller.isViewOnly.value,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildToggleSwitch("SIC Type", controller.isSicType.value, (val) => controller.isSicType.value = val),
          if (controller.isSicType.value) ...[
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: "SIC Type",
              hint: "Select",
              items: const [],
              selectedValue: controller.selectedSicType.value,
              onChanged: (v) => controller.selectedSicType.value = v,
              enabled: !controller.isViewOnly.value,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: "Responsible Person",
              hint: "Select",
              items: const [],
              selectedValue: controller.selectedSicResponsiblePerson.value,
              onChanged: (v) => controller.selectedSicResponsiblePerson.value = v,
              enabled: !controller.isViewOnly.value,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            Align(
              alignment: Alignment.centerRight,
              child: CustButton(
                name: "Add",
                size: 100,
                color1: AppColors.orangeColor,
                color2: AppColors.orangeColor,
                textDarkPrimary: Colors.white,
                onSelected: (_) => controller.addSicType(),
              ),
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            Obx(() => controller.sicTypeList.isNotEmpty
                ? Column(
              children: controller.sicTypeList.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return CustDataCard(
                  items: [
                    DataCardItem(label: 'SIC Type', value: item['sicType'] ?? ""),
                    DataCardItem(label: 'Responsible Person', value: item['responsiblePerson'] ?? "", isFullWidth: true),
                  ],
                  onEdit: () {},
                  onDelete: () => controller.removeSicType(index),
                );
              }).toList(),
            )
                : const SizedBox.shrink()),
          ],
          const SizedBox(height: AppConstants.elementSpacing),
          _buildToggleSwitch("Joint Inspection Required", controller.isJointInspection.value, (val) => controller.isJointInspection.value = val),
          if (controller.isJointInspection.value) ...[
            const SizedBox(height: AppConstants.elementSpacing),
            Obx(() => controller.jointInspectionList.isNotEmpty
                ? Column(
              children: controller.jointInspectionList.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return CustDataCard(
                  items: [
                    DataCardItem(label: 'Department', value: item['department'] ?? ""),
                    DataCardItem(label: 'Responsible Person', value: item['responsiblePerson'] ?? ""),
                    DataCardItem(label: 'Remark', value: item['remark'] ?? "", isFullWidth: true),
                    DataCardItem(label: 'Status', value: item['status'] ?? "", isFullWidth: true),
                  ],
                  onEdit: () {},
                  onDelete: () => controller.removeJointInspection(index),
                );
              }).toList(),
            )
                : const SizedBox.shrink()),
          ]
        ],
      ),
    ));
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return "";
    
    // If it's already a DateTime
    if (dateValue is DateTime) {
      return DateFormat('dd/MM/yyyy hh:mm a').format(dateValue);
    }
    
    // If it's a string, try to parse it
    if (dateValue is String) {
      try {
        // Try parsing with various formats
        try {
          final dt = DateTime.parse(dateValue); // ISO8601 format
          return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
        } catch (e) {
          try {
            final dt = DateFormat('dd-MM-yyyy HH:mm').parse(dateValue);
            return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
          } catch (e2) {
            try {
              final dt = DateFormat('dd/MM/yyyy HH:mm').parse(dateValue);
              return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
            } catch (e3) {
              try {
                final dt = DateFormat('dd/MM/yyyy hh:mm a').parse(dateValue);
                return dateValue; // Already in correct format
              } catch (e4) {
                try {
                  final dt = DateFormat('MM/dd/yyyy HH:mm:ss').parse(dateValue);
                  return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
                } catch (e5) {
                  // Return as-is if parsing fails
                  return dateValue;
                }
              }
            }
          }
        }
      } catch (e) {
        return dateValue;
      }
    }
    
    return "";
  }

  Widget _buildPartC() {
    return Obx(() => CustSection(
      title: 'Part C',
      isVisible: controller.isPartCExpanded.value,
      trailing: GestureDetector(
        onTap: () => controller.isPartCExpanded.toggle(),
        child: Icon(
          controller.isPartCExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
      ),
      child: Form(
        key: _partCFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustText.body("Acceptance of Failure (To Be Filled by Nominated Work Supervisor)", color: AppColors.textMutedLight, fontWeightName: FontWeight.bold),
            const SizedBox(height: AppConstants.elementSpacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: controller.isAcceptResponsibility.value,
                  onChanged: (val) => controller.isAcceptResponsibility.value = val ?? false,
                  activeColor: AppColors.orangeColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: CustText.body("I Hereby declare, that I accept the responsibility to carry out the work on the equipement detailed on this Job Card only, and no attempet shall be made by me or by any person under my control, to", size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustText.body("Power Block Required", color: AppColors.orangeColor, fontWeightName: FontWeight.w500),
                  YesNoToggle(value: controller.isPowerBlockRequired.value, onChanged: (val) => controller.isPowerBlockRequired.value = val, enabled: true),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustText.body("Allotment of Work to Maintainer", fontWeightName: FontWeight.w600),
            const SizedBox(height: AppConstants.elementSpacing),
            Row(
              children: [
                Expanded(
                  child: CustDropdown(
                    label: "Name *",
                    hint: "Select",
                    items: controller.maintainerUserStrings,
                    selectedValue: controller.selectedMaintainerName.value,
                    onChanged: (v) => controller.selectedMaintainerName.value = v,
                    enabled: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(
                  child: CustomTextField(
                    label: "Work Alloted *",
                    hintText: "Enter work",
                    controller: controller.workAllotedController,
                    enabled: true,
                    readOnly: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter work alloted';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            const SizedBox(height: AppConstants.elementSpacing),
            Obx(() => controller.editingWorkAllotedIndex.value >= 0
                ? Row(
              children: [
                Expanded(
                  child: CustButton(
                    name: "Save",
                    size: 100,
                    onSelected: (_) {
                      if (_partCFormKey.currentState?.validate() ?? false) {
                        controller.saveWorkAlloted();
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(
                  child: CustOutlineButton(
                    name: "Cancel",
                    size: 100,
                    onSelected: (_) => controller.cancelEditWorkAlloted(),
                  ),
                ),
              ],
            )
                : CustButton(
              name: "Add",
              size: 100,
              onSelected: (_) {
                if (_partCFormKey.currentState?.validate() ?? false) {
                  controller.saveWorkAlloted();
                }
              },
            )),
          const SizedBox(height: AppConstants.elementSpacing),
          Obx(() => controller.workAllotedList.isNotEmpty
              ? Column(
            children: controller.workAllotedList.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return CustDataCard(
                items: [
                  DataCardItem(label: 'Name', value: item['name'] ?? ""),
                  DataCardItem(label: 'Work Alloted', value: item['workAlloted'] ?? "", isFullWidth: true),
                ],
                onEdit: () => controller.startEditWorkAlloted(index),
                onDelete: () => controller.removeWorkAlloted(index),
              );
            }).toList(),
          )
              : const SizedBox.shrink()),
          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: "Submit",
            size: 100,
            color1: AppColors.orangeColor,
            color2: AppColors.orangeColor,
            textDarkPrimary: Colors.white,
            onSelected: (_) => controller.submitPartC(),
          ),
        ],
      ),
      ),
    ));
  }

  Widget _buildRcaDetailCard(Map<String, dynamic> item, int index) {
    return Obx(() {
      final bool isExpanded = controller.isExpandedRca[index] ?? false;
      final rcaItem = controller.rcaDetailsList.firstWhereOrNull(
            (r) => r['objectPart'] == item['objectPart'] && r['fault'] == item['fault'],
      );
      final List<Map<String, dynamic>> rootCauses =
          (rcaItem?['rootCauses'] as List<Map<String, dynamic>>?) ?? [];
      final List<Map<String, dynamic>> actionTakens =
          (rcaItem?['actionTakens'] as List<Map<String, dynamic>>?) ?? [];

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppColors.textFieldFillColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustText.detailLabel("Object Part"),
                        const SizedBox(height: AppConstants.labelSpacing),
                        CustText.detailValue(item['objectPart'] ?? ""),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(TablerIcons.trash, color: Colors.grey, size: 24),
                        onPressed: () => controller.removeFault(index),
                      ),
                      IconButton(
                        icon: Icon(
                          isExpanded ? TablerIcons.chevron_up : TablerIcons.chevron_down,
                          color: AppColors.orangeColor,
                        ),
                        onPressed: () => controller.toggleRcaExpansion(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((item['objectPartText'] ?? '').toString().isNotEmpty) ...[
                      CustText.detailLabel("Object Text"),
                      const SizedBox(height: AppConstants.labelSpacing),
                      CustText.detailValue(item['objectPartText']),
                      const SizedBox(height: AppConstants.elementSpacing),
                    ],
                    CustText.detailLabel("Fault"),
                    const SizedBox(height: AppConstants.labelSpacing),
                    CustText.detailValue(item['fault'] ?? ""),
                    if ((item['faultText'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustText.detailLabel("Fault Text"),
                      const SizedBox(height: AppConstants.labelSpacing),
                      CustText.detailValue(item['faultText']),
                    ],
                    if (rootCauses.isNotEmpty || actionTakens.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            TabBar(
                              labelColor: AppColors.orangeColor,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: AppColors.orangeColor,
                              indicatorSize: TabBarIndicatorSize.tab,
                              tabs: const [
                                Tab(text: "Root Cause"),
                                Tab(text: "Action Taken"),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Builder(
                              builder: (context) {
                                final tabController = DefaultTabController.of(context);
                                return AnimatedBuilder(
                                  animation: tabController,
                                  builder: (context, _) {
                                    final bool isRootCauseTab = tabController.index == 0;
                                    final currentList = isRootCauseTab ? rootCauses : actionTakens;
                                    final currentLabel = isRootCauseTab ? "Root Cause" : "Action Taken";

                                    return Column(
                                      children: currentList.asMap().entries.map((entry) => _buildRcaSubItem(
                                        label: currentLabel,
                                        value: entry.value[isRootCauseTab ? 'rootCause' : 'actionTaken'] ?? '',
                                        text: entry.value[isRootCauseTab ? 'rootCauseText' : 'actionTakenText'] ?? '',
                                        onDelete: () => isRootCauseTab
                                            ? controller.removeRootCauseFromRca(index, entry.key)
                                            : controller.removeActionTakenFromRca(index, entry.key),
                                      )).toList(),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustButton(
                name: "Add RCA",
                size: 100,
                fontSize: AppConstants.buttonFontSize,
                onSelected: (_) async {
                  final objectPartId = item['objectPartId'] ?? "0"; // ✅ from the entry itself
                  final faultId = item['faultId'] ?? "0";           // ✅ from the entry itself
                  await controller.fetchRootCauseAndAction(objectPartId, faultId);
                  _showAddRcaPopup(index);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRcaSubItem({
    required String label,
    required String value,
    required String text,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText.detailLabel(label),
                const SizedBox(height: AppConstants.labelSpacing),
                CustText.detailValue(value),
                if (text.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.elementSpacing),
                  CustText.detailLabel("$label Text"),
                  const SizedBox(height: AppConstants.labelSpacing),
                  CustText.detailValue(text),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(TablerIcons.trash, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPartD() {
    return Obx(() => CustSection(
      title: 'Part D',
      isVisible: controller.isPartDExpanded.value,
      trailing: GestureDetector(
        onTap: () => controller.isPartDExpanded.toggle(),
        child: Icon(
          controller.isPartDExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
      ),
      child: Form(
        key: _partDFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustText.body("Work Details & Work Completion Report to be filled by Work Supervisor", color: AppColors.textMutedLight, fontWeightName: FontWeight.bold),
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: "Failure Type *",
              hint: "Select",
              items: controller.rstFailureTypeStrings,
              selectedValue: controller.selectedPartDFailureTypeLabel,
              onChanged: (v) => controller.onPartDFailureTypeChanged(v),
              enabled: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select failure type';
                }
                return null;
              },
            ),
          const SizedBox(height: AppConstants.elementSpacing),
          // Notification History removed
          const SizedBox(height: AppConstants.elementSpacing),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustText.body("Failure Rectification Details: *", color: AppColors.orangeColor, fontWeightName: FontWeight.w500),
                YesNoToggle(value: controller.isFailureRectification.value, onChanged: (val) => controller.isFailureRectification.value = val, enabled: true),
              ],
            ),
          ),
          if (controller.isFailureRectification.value) ...[
            CustDropdown(
              label: "Object Part:",
              hint: "Select Object",
              items: [...controller.rstObjectPartStrings, "Other"],
              selectedValue: controller.selectedObjectPart.value,
              onChanged: (v) {
                controller.selectedObjectPart.value = v;
                controller.selectedFault.value = null;
                if (v != null && v != "Other") {
                  final objectPart = controller.rstObjectPartList.firstWhereOrNull((e) => e.label == v);
                  if (objectPart != null && objectPart.value != null) {
                    controller.fetchFaults(objectPart.value!);
                  }
                } else if (v == "Other") {
                  controller.faultDropdownList.clear();
                }
              },
              enabled: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select object part';
                }
                return null;
              },
            ),
            if (controller.selectedObjectPart.value == "Other") ...[
              const SizedBox(height: AppConstants.elementSpacing),
              CustomTextField(
                label: "Object Part Text:",
                hintText: "Enter Object Part",
                controller: controller.objectPartTextController,
                enabled: true,
                readOnly: false,
              ),
            ],
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: "Fault:",
              hint: "Select Fault",
              items: [...controller.faultStrings, "Other"],
              selectedValue: controller.selectedFault.value,
              onChanged: (v) {
                controller.selectedFault.value = v;
                if (v != null && v != "Other" && controller.selectedObjectPart.value != null && controller.selectedObjectPart.value != "Other") {
                  final objectPart = controller.rstObjectPartList.firstWhereOrNull((e) => e.label == controller.selectedObjectPart.value);
                  final fault = controller.faultDropdownList.firstWhereOrNull((e) => e.label == v);
                  if (objectPart != null && fault != null && objectPart.value != null && fault.value != null) {
                    controller.fetchRootCauseAndAction(objectPart.value!, fault.value!);
                  }
                }
              },
              enabled: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select fault';
                }
                return null;
              },
            ),
            if (controller.selectedFault.value == "Other") ...[
              const SizedBox(height: AppConstants.elementSpacing),
              CustomTextField(
                label: "Fault Text:",
                hintText: "Enter Fault",
                controller: controller.faultTextController,
                enabled: true,
                readOnly: false,
              ),
            ],
            const SizedBox(height: AppConstants.elementSpacing),
            CustButton(
              name: "Add",
              size: 100,
              color1: AppColors.orangeColor,
              color2: AppColors.orangeColor,
              textDarkPrimary: Colors.white,
              onSelected: (_) {
                if (_partDFormKey.currentState?.validate() ?? false) {
                  controller.addFault();
                }
              },
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            if (controller.faultList.isNotEmpty)
              Column(
                children: controller.faultList.asMap().entries
                    .map((entry) => _buildRcaDetailCard(entry.value, entry.key))
                    .toList(),
              ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustomTextField(
              label: "Details of activity Carried Out",
              hintText: "Enter details",
              controller: controller.activityCarriedOutController,
              maxLines: 3,
              enabled: true,
              readOnly: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter details of activity carried out';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: AppConstants.elementSpacing),

          // ── Material Required toggle ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustText.body("Material Required", color: AppColors.orangeColor, fontWeightName: FontWeight.w500),
                YesNoToggle(
                  value: controller.isMaterialRequired.value,
                  onChanged: (val) => controller.isMaterialRequired.value = val,
                  enabled: true,
                ),
              ],
            ),
          ),

          if (controller.isMaterialRequired.value) ...[
            const SizedBox(height: AppConstants.elementSpacing),
            Row(
              children: [
                Expanded(
                  child: CustDropdown(
                    label: "Material Code & Description: *",
                    hint: "Select...",
                    items: controller.rstMaterialStrings,
                    selectedValue: controller.selectedMaterialCode.value,
                    onChanged: (v) {
                      controller.selectedMaterialCode.value = v;
                      controller.selectedStoreLocation.value = null;
                      controller.requiredQuantityController.text = '';
                      controller.uomController.clear();
                      controller.balanceQtyController.clear();

                      if (v != null) {
                        final material = controller.rstMaterialList.firstWhereOrNull((e) => e.label == v);
                        if (material != null && material.value != null) {
                          final materialRowId = int.tryParse(material.value!) ?? 0;
                          if (materialRowId > 0) {
                            controller.fetchMCDRequiredQuantity(materialRowId, 0);
                          }
                        }
                      }
                    },
                    enabled: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select material code';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(
                  child: CustomTextField(
                    label: "Unit of Measurement:",
                    hintText: "Unit of Measurement",
                    controller: controller.uomController,
                    enabled: false,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            Row(
              children: [
                Expanded(
                  child: CustDropdown(
                    label: "Store Location: *",
                    hint: "Select...",
                    items: controller.storageLocationStrings,
                    selectedValue: controller.selectedStoreLocation.value,
                    onChanged: (v) {
                      controller.selectedStoreLocation.value = v;
                      controller.balanceQtyController.clear();
                      if (v != null && controller.selectedMaterialCode.value != null) {
                        final material = controller.rstMaterialList.firstWhereOrNull((e) => e.label == controller.selectedMaterialCode.value);
                        if (material != null && material.value != null) {
                          final materialId = int.tryParse(material.value!) ?? 0;
                          final storageLocation = controller.storageLocationList.firstWhereOrNull((e) => e.label == v);
                          if (storageLocation != null && storageLocation.value != null) {
                            final storageLocationId = int.tryParse(storageLocation.value!) ?? 0;
                            if (materialId > 0 && storageLocationId > 0) {
                              controller.fetchMaterialBalancedQty(materialId, storageLocationId);
                            }
                          }
                        }
                      }
                    },
                    enabled: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select store location';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(
                  child: CustomTextField(
                    label: "Balance Quantity:",
                    hintText: "Balance Quantity",
                    controller: controller.balanceQtyController,
                    enabled: false,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustomTextField(
              label: "Required Quantity: *",
              hintText: "Enter Required Quantity",
              controller: controller.requiredQuantityController,
              keyboardType: TextInputType.number,
              enabled: true,
              readOnly: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter required quantity';
                }
                final qty = int.tryParse(value);
                if (qty == null || qty <= 0) {
                  return 'Please enter a valid quantity';
                }
                final balanceQty = int.tryParse(controller.balanceQtyController.text) ?? 0;
                if (qty > balanceQty) {
                  return 'Required quantity must be less than or equal to balance quantity';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustButton(
              name: controller.editingMaterialRequiredIndex.value >= 0 ? "Update Material" : "Add Material",
              size: 150,
              color1: AppColors.orangeColor,
              color2: AppColors.orangeColor,
              textDarkPrimary: Colors.white,
              onSelected: (_) {
                if (_partDFormKey.currentState?.validate() ?? false) {
                  controller.addMaterialRequired();
                }
              },
            ),
            const SizedBox(height: AppConstants.elementSpacing),

            // ── Material Required list (same card design as CreateFailureScreen) ──
            if (controller.materialRequiredList.isNotEmpty)
              Column(
                children: controller.materialRequiredList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Obx(() {
                    final isExpanded = controller.isExpandedMaterial[index] ?? false;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.white1,
                        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                        border: Border.all(color: AppColors.textFieldFillColor.withOpacity(0.5)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustText.detailLabel("Material Description"),
                                      const SizedBox(height: AppConstants.labelSpacing),
                                      CustText.detailValue(item['materialCode'] ?? ""),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(TablerIcons.pencil, color: AppColors.orangeColor, size: 20),
                                      onPressed: () => controller.startEditMaterialRequired(index),
                                      padding: const EdgeInsets.only(right: 12),
                                      constraints: const BoxConstraints(),
                                    ),
                                    IconButton(
                                      icon: const Icon(TablerIcons.trash, color: Colors.grey, size: 20),
                                      onPressed: () => controller.removeMaterialRequired(index),
                                      padding: const EdgeInsets.only(right: 12),
                                      constraints: const BoxConstraints(),
                                    ),
                                    IconButton(
                                      icon: Icon(isExpanded ? TablerIcons.chevron_up : TablerIcons.chevron_down, color: AppColors.orangeColor, size: 20),
                                      onPressed: () => controller.toggleMaterialExpansion(index),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // ── Used Qty, wrapped in its own Form + validator, same pattern as CreateFailureScreen ──
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Form(
                              key: _matReqFormKeys.putIfAbsent(index, () => GlobalKey<FormState>()),
                              child: Builder(builder: (context) {
                                final ctrl = controller.usedQtyControllers.putIfAbsent(index, () => TextEditingController());
                                final focusNode = controller.usedQtyFocusNodes.putIfAbsent(index, () => FocusNode());
                                if (ctrl.text != (item['usedQty'] ?? '')) {
                                  ctrl.text = item['usedQty'] ?? '';
                                }
                                return CustomTextField(
                                  key: ValueKey('rst_used_qty_$index'),
                                  label: "Used Qty",
                                  hintText: "Enter Used Quantity",
                                  controller: ctrl,
                                  focusNode: focusNode,
                                  keyboardType: TextInputType.number,
                                  enabled: true,
                                  autofocus: false,
                                  onChanged: (val) {
                                    final usedQty = int.tryParse(val) ?? 0;
                                    final requiredQty = int.tryParse(item['requiredQty'] ?? '0') ?? 0;
                                    if (usedQty > requiredQty) {
                                      controller.materialRequiredList[index]['usedQty'] = "";
                                      ctrl.clear();
                                      Get.snackbar(
                                        'Invalid Quantity',
                                        'Used Quantity cannot be greater than Required Quantity.',
                                        backgroundColor: AppColors.darkRed,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                        duration: const Duration(seconds: 3),
                                      );
                                      return;
                                    }
                                    controller.materialRequiredList[index]['usedQty'] = val;
                                  },
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return "Used Quantity is required";
                                    }
                                    return null;
                                  },
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0).copyWith(bottom: 16),
                              child: LayoutBuilder(builder: (context, constraints) {
                                final double width = (constraints.maxWidth - 10) / 2;
                                Widget buildCol(String label, String value) => SizedBox(
                                  width: width,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustText.detailLabel(label),
                                      const SizedBox(height: 2),
                                      CustText.detailValue(value),
                                    ],
                                  ),
                                );
                                return Wrap(
                                  runSpacing: 10,
                                  spacing: 10,
                                  children: [
                                    buildCol("Store Location", item['storeLocation'] ?? ''),
                                    buildCol("Unit of Measurement", item['uom'] ?? ''),
                                    buildCol("Balance Quantity", item['balanceQty'] ?? ''),
                                    buildCol("Required Quantity", item['requiredQty'] ?? ''),
                                  ],
                                );
                              }),
                            ),
                        ],
                      ),
                    );
                  });
                }).toList(),
              ),
          ],

          const SizedBox(height: AppConstants.elementSpacing),

          // ── Material Dismantle toggle ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustText.body("Material Dismantle: *", color: AppColors.orangeColor, fontWeightName: FontWeight.w500),
                YesNoToggle(value: controller.isMaterialDismantle.value, onChanged: (val) => controller.isMaterialDismantle.value = val, enabled: true),
              ],
            ),
          ),

          if (controller.isMaterialDismantle.value) ...[
            const SizedBox(height: AppConstants.elementSpacing),
            Builder(builder: (context) {
              final sparePartItems = controller.materialRequiredList
                  .map((e) => e['materialCode'] as String? ?? '')
                  .where((e) => e.isNotEmpty)
                  .toList();
              return CustDropdown(
                label: "Material Code & Description: *",
                hint: "Select...",
                items: sparePartItems,
                selectedValue: controller.selectedDismantleMaterialCode.value,
                enabled: sparePartItems.isNotEmpty,
                onChanged: (v) => controller.selectedDismantleMaterialCode.value = v,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select material code';
                  }
                  return null;
                },
              );
            }),
            const SizedBox(height: AppConstants.elementSpacing),
            CustomTextField(
              label: "Old Serial Number: *",
              hintText: "Enter Old Series Number",
              controller: controller.oldSerialNumberController,
              enabled: true,
              readOnly: false,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            // ✅ CustDateTimePicker — matches CreateFailureScreen exactly
            Obx(() => CustDateTimePicker(
              label: "Old Serial No Dismantle Date: *",
              hint: "DD/MM/YYYY hh:mm",
              selectedDateTime: controller.oldSerialDismantleDate.value,
              enabled: true,
              lastDate: DateTime.now(),
              onDateTimeSelected: (dt) => controller.oldSerialDismantleDate.value = dt,
            )),
            const SizedBox(height: AppConstants.elementSpacing),
            CustomTextField(
              label: "New Serial Number: *",
              hintText: "Enter New Series Number",
              controller: controller.newSerialNumberController,
              enabled: true,
              readOnly: false,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            // ✅ CustDateTimePicker — matches CreateFailureScreen exactly
            Obx(() => CustDateTimePicker(
              label: "New Serial No Installation Date: *",
              hint: "DD/MM/YYYY hh:mm",
              selectedDateTime: controller.newSerialInstallationDate.value,
              enabled: true,
              lastDate: DateTime.now(),
              onDateTimeSelected: (dt) => controller.newSerialInstallationDate.value = dt,
            )),
            const SizedBox(height: AppConstants.elementSpacing),
            CustButton(
              name: controller.editingDismantleMaterialIndex.value >= 0 ? "Update" : "Add",
              size: 100,
              onSelected: (_) {
                if (_partDFormKey.currentState?.validate() ?? false) {
                  controller.addDismantleMaterial();
                }
              },
            ),
            const SizedBox(height: AppConstants.elementSpacing),

            // ── Material Dismantle list — same card design as CreateFailureScreen ──
            if (controller.dismantleMaterialList.isNotEmpty)
              Column(
                children: controller.dismantleMaterialList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Obx(() {
                    final isExpanded = controller.isExpandedDismantle[index] ?? false;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.white1,
                        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                        border: Border.all(color: AppColors.textFieldFillColor.withOpacity(0.5)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustText.detailLabel("Material Description"),
                                      const SizedBox(height: AppConstants.labelSpacing),
                                      CustText.detailValue(item['materialCode'] ?? ""),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(TablerIcons.pencil, color: AppColors.orangeColor, size: 20),
                                      onPressed: () => controller.startEditDismantleMaterial(index),
                                      padding: const EdgeInsets.only(right: 12),
                                      constraints: const BoxConstraints(),
                                    ),
                                    IconButton(
                                      icon: const Icon(TablerIcons.trash, color: Colors.grey, size: 20),
                                      onPressed: () => controller.removeDismantleMaterial(index),
                                      padding: const EdgeInsets.only(right: 12),
                                      constraints: const BoxConstraints(),
                                    ),
                                    IconButton(
                                      icon: Icon(isExpanded ? TablerIcons.chevron_up : TablerIcons.chevron_down, color: AppColors.orangeColor, size: 20),
                                      onPressed: () => controller.toggleDismantleExpansion(index),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                              child: LayoutBuilder(builder: (context, constraints) {
                                final double width = (constraints.maxWidth - 10) / 2;
                                Widget buildCol(String label, String value) => SizedBox(
                                  width: width,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustText.detailLabel(label),
                                      const SizedBox(height: 2),
                                      CustText.detailValue(value),
                                    ],
                                  ),
                                );
                                return Wrap(
                                  runSpacing: 10,
                                  spacing: 10,
                                  children: [
                                    buildCol("Old Serial Number", item['oldSerial'] ?? ""),
                                    buildCol("Dismantle Date", _formatDate(item['oldDismantleDate'])),
                                    buildCol("New Serial Number", item['newSerial'] ?? ""),
                                    buildCol("Installation Date", _formatDate(item['newInstallDate'])),
                                  ],
                                );
                              }),
                            ),
                        ],
                      ),
                    );
                  });
                }).toList(),
              ),
          ],

          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: "Submit",
            size: 100,
            color1: AppColors.orangeColor,
            color2: AppColors.orangeColor,
            textDarkPrimary: Colors.white,
            onSelected: (_) {
              if (_partDFormKey.currentState?.validate() ?? false) {
                // ✅ Validates every material's Used Qty (both live check + form validators)
                bool allValid = _matReqFormKeys.values.every((key) => key.currentState?.validate() ?? true);
                if (!allValid) return;
                if (!controller.validateMaterialRequiredUsedQty()) return;
                controller.submitPartD();
              }
            },
          ),
        ],
      ),
      ),
    ));
  }

  Widget _buildPartE() {
    return Obx(() => CustSection(
      title: 'Part E',
      isVisible: controller.isPartEExpanded.value,
      trailing: GestureDetector(
        onTap: () => controller.isPartEExpanded.toggle(),
        child: Icon(
          controller.isPartEExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
      ),
      child: Form(
        key: _partEFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustText.body("Work Completion Report(To be Filled by work Supervisor)", color: AppColors.textMutedLight, fontWeightName: FontWeight.bold),
            const SizedBox(height: AppConstants.elementSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: controller.isPersonsWithdrawn.value,
                onChanged: (val) => controller.isPersonsWithdrawn.value = val ?? false,
                activeColor: AppColors.orangeColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: CustText.body(
                    "I Hereby declare, that all persons have beeen withdrawn and all the equipement affected as detailed in Part A above have been restored to normal.",
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.elementSpacing),

          // ── Actual Work Start / Complete, stacked vertically ──
          CustDateTimePicker(
            label: "Actual Work Start *",
            hint: "DD/MM/YYYY hh:mm",
            selectedDateTime: controller.actualWorkStart.value,
            enabled: true,
            lastDate: DateTime.now(),
            onDateTimeSelected: (dt) => controller.actualWorkStart.value = dt,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDateTimePicker(
            label: "Actual Work Complete *",
            hint: "DD/MM/YYYY hh:mm",
            selectedDateTime: controller.actualWorkComplete.value,
            enabled: true,
            lastDate: DateTime.now(),
            onDateTimeSelected: (dt) => controller.actualWorkComplete.value = dt,
          ),
          const SizedBox(height: AppConstants.elementSpacing),

          CustDropdown(
            label: "Train Status *",
            hint: "Select",
            items: controller.rstTrainStatusStrings,
            selectedValue: controller.selectedTrainStatus.value,
            onChanged: (v) => controller.selectedTrainStatus.value = v,
            enabled: true,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustText(
            name: "Attachments: ",
            size: AppConstants.textSize,
            fontWeightName: FontWeight.w500,
            color: AppColors.black,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
            _buildAttachmentRow(
              "After Images",
              controller.afterFiles,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            _buildAttachmentRow(
              "RCA Images",
              controller.uploadRcaFiles,
            ),
            const SizedBox(height: AppConstants.sectionSpacing),

          // ── Handover Details — stacked cards, matches app's list pattern ──
          CustText.body("Handover Details", fontWeightName: FontWeight.w600),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildHandoverDetailsPaginated(),
          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: "Submit",
            size: 100,
            color1: AppColors.orangeColor,
            color2: AppColors.orangeColor,
            textDarkPrimary: Colors.white,
            onSelected: (_) {
              if (!controller.isPersonsWithdrawn.value) {
                Get.snackbar("Error", "Please accept the declaration",backgroundColor: AppColors.red,colorText: AppColors.white1);
                return;
              }
              if (_partEFormKey.currentState?.validate() ?? false) {
                controller.submitPartE();
              }
            },
          ),
        ],
      ),
      ),
    ));
  }
  Widget _buildHandoverDetailsPaginated() {
    return Obx(() {
      if (controller.assignmentHistoryList.isEmpty) {
        return const SizedBox.shrink();
      }
      final items = controller.assignmentHistoryList.map((item) {
        final status = item['statusName'] ?? '';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white1,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: AppColors.textFieldFillColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustText.detailLabel("HandOver Details"),
                        const SizedBox(height: AppConstants.labelSpacing),
                        CustText.detailValue(item['assgineUserName'] ?? ""),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (status == 'Assigned' ? AppColors.orangeColor : Colors.green).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'Assigned' ? AppColors.orangeColor : Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              CustText.detailLabel("Submission Date & Time"),
              const SizedBox(height: AppConstants.labelSpacing),
              CustText.detailValue(item['createdOn'] ?? ""),
            ],
          ),
        );
      }).toList();

      return HorizontalPaginatedView(items: items);
    });
  }

  Widget _buildPartF() {
    return Obx(() => CustSection(
      title: 'Part F',
      isVisible: controller.isPartFExpanded.value,
      trailing: GestureDetector(
        onTap: () => controller.isPartFExpanded.toggle(),
        child: Icon(
          controller.isPartFExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText.body("SIC Completion Report (to be filled by SIC Supervisor)", color: AppColors.textMutedLight, fontWeightName: FontWeight.bold),
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.body("Need to Display SIC Checklist which is selected by earlier", fontWeightName: FontWeight.w600),
          // const SizedBox(height: AppConstants.elementSpacing),
          // CustDataCard(
          //   items: [
          //     DataCardItem(label: "SIC Type", value: "Battery Box"),
          //     DataCardItem(label: "Responsible", value: "Mr.Virat Kohli"),
          //     DataCardItem(
          //       label: "Status",
          //       value: "Assigned",
          //       valueWidget: CustText(name: "Assigned", color: Colors.orange, size: 14, fontWeightName: FontWeight.bold),
          //     ),
          //   ],
          //   bottomAction: Align(
          //     alignment: Alignment.centerRight,
          //     child: CustButton(
          //       name: "Checksheet",
          //       size: 150,
          //       textDarkPrimary: Colors.white,
          //       onSelected: (_) {
          //         // Get.to(() => const SicChecklistScreen())
          //       },
          //     ),
          //   ),
          // ),
          // const SizedBox(height: AppConstants.elementSpacing),
          // Row(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     Checkbox(
          //       value: controller.isSicPerformed.value,
          //       onChanged: (val) => controller.isSicPerformed.value = val ?? false,
          //       activeColor: AppColors.orangeColor,
          //     ),
          //     Expanded(
          //       child: Padding(
          //         padding: const EdgeInsets.only(top: 10.0),
          //         child: CustText.body("I Hereby declare, that SIC has been performed on concerned equipement.", size: 12),
          //       ),
          //     ),
          //   ],
          // ),
          // Row(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     Checkbox(
          //       value: controller.isFollowUpActionCompleted.value,
          //       onChanged: (val) => controller.isFollowUpActionCompleted.value = val ?? false,
          //       activeColor: AppColors.orangeColor,
          //     ),
          //     Expanded(
          //       child: Padding(
          //         padding: const EdgeInsets.only(top: 10.0),
          //         child: CustText.body("I Hereby declare, that All the necessary follow up action as described in Part F above and final Inspection, including SIC(if any), have been completed.", size: 12),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    ));
  }

  Widget _buildViewOnlyImageRow(
      String label,
      List<Map<String,dynamic>> files,
      ) {
    return Obx(() {
      if (files.isEmpty) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          CustText.body(label),

          const SizedBox(height: 10),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: files.map((file) {

              return GestureDetector(
                onTap: () => _showFilePreview(file),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(file["url"]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );

            }).toList(),
          )
        ],
      );
    });
  }

  Widget _buildViewOnlyImageItem(Map<String, dynamic> file) {
    final String path = file['path']?.toString() ?? '';
    final String url = _buildFileUrl(path);
    debugPrint("Before image URL: $url"); // TEMP — confirm this looks right, then remove

    return GestureDetector(
      onTap: () => _showFilePreview(file),
      child: Container(
        width: 90,
        height: 90,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: url.isNotEmpty
            ? Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, error, ___) {
            debugPrint("Image load failed for $url — $error"); // TEMP
            return const Icon(TablerIcons.photo, color: AppColors.textMutedLight, size: 28);
          },
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        )
            : const Icon(TablerIcons.photo, color: AppColors.textMutedLight, size: 28),
      ),
    );
  }

  String _buildFileUrl(String path) {
    if (path.isEmpty) return '';
    final base = AppUrls.baseUrl.endsWith('/')
        ? AppUrls.baseUrl.substring(0, AppUrls.baseUrl.length - 1)
        : AppUrls.baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$base$cleanPath';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: const CustomAppBar(
        title: 'Create Failure',
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.white1,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPartA(),
                    _buildPartB(),
                    _buildPartC(),
                    _buildPartD(),
                    _buildPartE(),
                    _buildPartF(),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            final syncService = Get.find<MasterDataSyncService>();
            if (syncService.isSyncing.value) {
              return Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CustLoader(),
                      const SizedBox(height: 16),
                      CustText(
                        name: syncService.syncStatus.value,
                        size: 14,
                        color: AppColors.orangeColor,
                      ),
                    ],
                  ),
                ),
              );
            }
            if (controller.isLoading.value) {
              return Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CustLoader()),
              );
            }
            if (controller.errorMessage.value.isNotEmpty) {
              return Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustText.body(controller.errorMessage.value, color: Colors.white),
                        const SizedBox(height: 16),
                        CustButton(
                          name: "Retry",
                          size: 100,
                          color1: AppColors.orangeColor,
                          color2: AppColors.orangeColor,
                          textDarkPrimary: Colors.white,
                          onSelected: (_) {
                            if (widget.notificationId != null) {
                              controller.fetchRstFailureData(widget.notificationId!);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  void _showAddRcaPopup(int index) {
    Get.dialog(
      DefaultTabController(
        length: 2,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                        onPressed: () {
                          controller.clearPopupState();
                          Get.back();
                        },
                      ),
                    ],
                  ),
                ),
                TabBar(
                  labelColor: AppColors.orangeColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.orangeColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: "Root Cause"),
                    Tab(text: "Action Taken"),
                  ],
                ),
                Flexible(
                  child: TabBarView(
                    children: [
                      _buildPopupTab(
                        index: index,
                        isRootCause: true,
                        dropdownLabel: "Root Cause",
                        dropdownHint: "Select Root Cause",
                        items: controller.rootCauseList.map((e) => e.label ?? '').toList(),
                        controller: controller.popupRootCauseTextController,
                        files: controller.popupRootCauseFiles,
                        tempList: controller.tempPopupRootCauses,
                        onAddClick: () => controller.addToTempRootCauses(),
                        onSave: () {
                          controller.savePopupDataToRca(index);
                          Get.back();
                        },
                      ),
                      _buildPopupTab(
                        index: index,
                        isRootCause: false,
                        dropdownLabel: "Action Taken",
                        dropdownHint: "Select Action Taken",
                        items: controller.actionTakenList.map((e) => e.label ?? '').toList(),
                        controller: controller.popupActionTakenTextController,
                        files: controller.popupActionTakenFiles,
                        tempList: controller.tempPopupActionTakens,
                        onAddClick: () => controller.addToTempActionTakens(),
                        onSave: () {
                          controller.savePopupDataToRca(index);
                          Get.back();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupTab({
    required int index,
    required bool isRootCause,
    required String dropdownLabel,
    required String dropdownHint,
    required List<String> items,
    required TextEditingController controller,
    required RxList<Map<String, dynamic>> files,
    required RxList<Map<String, dynamic>> tempList,
    required VoidCallback onAddClick,
    required VoidCallback onSave,
  }) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => CustDropdown(
                  label: "$dropdownLabel *",
                  hint: dropdownHint,
                  items: items,
                  selectedValue: isRootCause
                      ? this.controller.selectedPopupRootCause.value
                      : this.controller.selectedPopupActionTaken.value,
                  onChanged: (v) {
                    if (isRootCause) {
                      this.controller.selectedPopupRootCause.value = v;
                    } else {
                      this.controller.selectedPopupActionTaken.value = v;
                    }
                  },
                )),
                Obx(() {
                  final selectedValue = isRootCause 
                      ? this.controller.selectedPopupRootCause.value 
                      : this.controller.selectedPopupActionTaken.value;
                  if (selectedValue?.toLowerCase() == "other") {
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: "$dropdownLabel Text *",
                          controller: controller,
                          hintText: "Enter $dropdownLabel Text",
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                  spacing: 8,
                  children: files
                      .map((file) => Chip(
                    label: Text(file['name'], style: const TextStyle(fontSize: 10)),
                    onDeleted: () => files.remove(file),
                  ))
                      .toList(),
                )),
                const SizedBox(height: 12),
                CustButton(
                  name: "Add",
                  size: 100,
                  sHeight: 30,
                  onSelected: (_) => onAddClick(),
                ),
                const SizedBox(height: 24),
                Obx(() => Column(
                  children: tempList.asMap().entries.map((entry) {
                    final mainValue = entry.value[isRootCause ? 'rootCause' : 'actionTaken'] ?? '';
                    final textValue = entry.value[isRootCause ? 'rootCauseText' : 'actionTakenText'] ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustText.body(dropdownLabel, size: 12, fontWeightName: FontWeight.w500),
                                const SizedBox(height: 4),
                                CustText.body(mainValue, size: 13),
                                if (textValue.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  CustText.body("$dropdownLabel Text", size: 12, fontWeightName: FontWeight.w500),
                                  const SizedBox(height: 4),
                                  CustText.body(textValue, size: 13),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => tempList.removeAt(entry.key),
                            child: const Icon(TablerIcons.trash, color: Colors.red, size: 20),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustButton(
            name: "Save",
            size: double.infinity,
            sHeight: 40,
            onSelected: (_) => onSave(),
          ),
        ),
      ],
    );
  }
}

