import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
import '../controller/rst_failure_controller.dart';
import 'sic_checklist_screen.dart';

class RstFailureScreen extends StatefulWidget {
  const RstFailureScreen({Key? key}) : super(key: key);

  @override
  State<RstFailureScreen> createState() => _RstFailureScreenState();
}

class _RstFailureScreenState extends State<RstFailureScreen> {
  late final RstFailureController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<RstFailureController>()) {
      Get.delete<RstFailureController>();
    }
    controller = Get.put(RstFailureController());
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
    Get.bottomSheet(
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustText.sectionHeader("Select Source"),
            const SizedBox(height: AppConstants.elementSpacing),
            ListTile(
              leading: const Icon(TablerIcons.camera, color: AppColors.orangeColor),
              title: const Text('Camera'),
              onTap: () async {
                Get.back();
                final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                if (picked != null) {
                  targetList.add({"type": "file", "path": picked.path, "name": picked.name});
                }
              },
            ),
            ListTile(
              leading: const Icon(TablerIcons.photo, color: AppColors.orangeColor),
              title: const Text('Gallery'),
              onTap: () async {
                Get.back();
                final picked = await FilePicker.platform.pickFiles(allowMultiple: true);
                if (picked != null) {
                  for (var file in picked.files) {
                    if (file.path != null) {
                      targetList.add({"type": "file", "path": file.path, "name": file.name});
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(List<Map<String, dynamic>> targetList) {
    return CustButton(
      name: "Upload",
      size: 100,
      color1: AppColors.orangeColor,
      color2: AppColors.orangeColor,
      textColor: Colors.white,
      onSelected: (_) => _showUploadPopup(targetList),
    );
  }

  Widget _buildAttachmentsSection() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustText.sectionHeader("Attachments", color: Colors.blue.shade700),
            CustText.body(controller.afterFiles.length.toString(), fontWeightName: FontWeight.bold),
          ],
        ),
        const SizedBox(height: AppConstants.elementSpacing),
        Row(
          children: [
            CustText.body("After", fontWeightName: FontWeight.bold),
            const SizedBox(width: AppConstants.elementSpacing),
            _buildUploadButton(controller.afterFiles),
          ],
        ),
        const SizedBox(height: AppConstants.elementSpacing),
        if (controller.afterFiles.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: controller.afterFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              final fileName = file['name']?.toString() ?? 'Unknown';
              return Container(
                width: MediaQuery.of(context).size.width * 0.4,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fileName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          const Text("6.230 kb", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => controller.afterFiles.removeAt(index),
                      child: const Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    ));
  }

  Widget _buildToggleSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustText.body(title, color: AppColors.orangeColor, fontWeightName: FontWeight.w500),
          YesNoToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildPartA() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Part A", 
          "Completed", 
          controller.isPartAExpanded.value, 
          () => controller.isPartAExpanded.toggle()
        ),
        if (controller.isPartAExpanded.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.body("Failure Creation By PPIO/RSC", color: Colors.blue.shade700, fontWeightName: FontWeight.bold),
          const SizedBox(height: AppConstants.elementSpacing),
          Row(
            children: [
              Expanded(
                child: CustDropdown(
                  label: "Priority",
                  hint: "Select",
                  items: controller.dummyPriorityList,
                  selectedValue: controller.selectedPriority.value,
                  onChanged: (v) => controller.selectedPriority.value = v,
                ),
              ),
              const SizedBox(width: AppConstants.elementSpacing),
              Expanded(
                child: CustDropdown(
                  label: "Department",
                  hint: "Select",
                  items: controller.dummyDepartmentList,
                  selectedValue: controller.selectedDepartment.value,
                  onChanged: (v) => controller.selectedDepartment.value = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Failure Type",
            hint: "Select",
            items: controller.dummyFailureTypeList,
            selectedValue: controller.selectedFailureType.value,
            onChanged: (v) => controller.selectedFailureType.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustomTextField(
            label: "Failure Description",
            hintText: "Enter description",
            controller: controller.failureDescriptionController,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustomTextField(
            label: "Search by Superior Functional Location or Asset Tag",
            hintText: "Asset Tag",
            controller: controller.searchLocationController,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Line",
            hint: "Select",
            items: controller.dummyLineList,
            selectedValue: controller.selectedLine.value,
            onChanged: (v) => controller.selectedLine.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Train Set No",
            hint: "Select",
            items: controller.dummyTrainSetList,
            selectedValue: controller.selectedTrainSetNo.value,
            onChanged: (v) => controller.selectedTrainSetNo.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Room",
            hint: "Select",
            items: controller.dummyRoomList,
            selectedValue: controller.selectedRoom.value,
            onChanged: (v) => controller.selectedRoom.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "System",
            hint: "Select",
            items: controller.dummySystemList,
            selectedValue: controller.selectedSystem.value,
            onChanged: (v) => controller.selectedSystem.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Functional Location",
            hint: "Select",
            items: controller.dummyFunctionalLocationList,
            selectedValue: controller.selectedFunctionalLocation.value,
            onChanged: (v) => controller.selectedFunctionalLocation.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Equipment Name",
            hint: "Select",
            items: controller.dummyEquipmentList,
            selectedValue: controller.selectedEquipmentName.value,
            onChanged: (v) => controller.selectedEquipmentName.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Nature of Work",
            hint: "Select",
            items: controller.dummyNatureOfWorkList,
            selectedValue: controller.selectedNatureOfWork.value,
            onChanged: (v) => controller.selectedNatureOfWork.value = v,
          ),
          const SizedBox(height: AppConstants.sectionSpacing),
          _buildAttachmentsSection(),
          const SizedBox(height: AppConstants.sectionSpacing),
          CustDropdown(
            label: "Do not Report",
            hint: "Select",
            items: controller.dummyDoNotReportList,
            selectedValue: controller.selectedDoNotReport.value,
            onChanged: (v) => controller.selectedDoNotReport.value = v,
          ),
        ]
      ],
    ));
  }

  Widget _buildPartB() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Part B", 
          "Completed", 
          controller.isPartBExpanded.value, 
          () => controller.isPartBExpanded.toggle()
        ),
        if (controller.isPartBExpanded.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.body("Failure Assignment By PPIO", color: Colors.blue.shade700, fontWeightName: FontWeight.bold),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Responsible Person",
            hint: "Select",
            items: controller.dummyFailureTypeList,
            selectedValue: controller.selectedResponsiblePerson.value,
            onChanged: (v) => controller.selectedResponsiblePerson.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustomTextField(
            label: "Train Running KM",
            hintText: "Enter KM",
            controller: controller.trainRunningKmController,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildToggleSwitch("SIC Type", controller.isSicType.value, (val) => controller.isSicType.value = val),
          if (controller.isSicType.value) ...[
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: "SIC Type",
              hint: "Select",
              items: controller.dummyFailureTypeList,
              selectedValue: controller.selectedSicType.value,
              onChanged: (v) => controller.selectedSicType.value = v,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: "Responsible Person",
              hint: "Select",
              items: controller.dummyFailureTypeList,
              selectedValue: controller.selectedSicResponsiblePerson.value,
              onChanged: (v) => controller.selectedSicResponsiblePerson.value = v,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            Align(
              alignment: Alignment.centerRight,
              child: CustButton(
                name: "Add",
                size: 100,
                color1: AppColors.orangeColor,
                color2: AppColors.orangeColor,
                textColor: Colors.white,
                onSelected: (_) => controller.addSicType(),
              ),
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            if (controller.sicTypeList.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ...controller.sicTypeList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustText.body("SIC Type:\n${item['sicType']}", fontWeightName: FontWeight.w500),
                                const SizedBox(height: 4),
                                CustText.body("Responsible Person:\n${item['responsiblePerson']}", color: Colors.black87),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(TablerIcons.pencil, color: AppColors.orangeColor), onPressed: () {}),
                          IconButton(icon: const Icon(TablerIcons.trash, color: Colors.grey), onPressed: () => controller.removeSicType(index)),
                        ],
                      );
                    }).toList(),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.keyboard_arrow_left, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("1", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.keyboard_arrow_right, color: AppColors.orangeColor),
                      ],
                    )
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppConstants.elementSpacing),
          _buildToggleSwitch("Joint Inspection Required", controller.isJointInspection.value, (val) => controller.isJointInspection.value = val),
          if (controller.isJointInspection.value) ...[
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: "Joint Inspection Department",
              hint: "Select",
              items: controller.dummyDepartmentList,
              selectedValue: controller.selectedJointInspectionDept.value,
              onChanged: (v) => controller.selectedJointInspectionDept.value = v,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: "Responsible Person",
              hint: "Select",
              items: controller.dummyFailureTypeList,
              selectedValue: controller.selectedJointInspectionResponsiblePerson.value,
              onChanged: (v) => controller.selectedJointInspectionResponsiblePerson.value = v,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustomTextField(
              label: "Remarks",
              hintText: "Remarks",
              controller: controller.jointInspectionRemarksController,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            Align(
              alignment: Alignment.centerRight,
              child: CustButton(
                name: "Add",
                size: 100,
                color1: AppColors.orangeColor,
                color2: AppColors.orangeColor,
                textColor: Colors.white,
                onSelected: (_) => controller.addJointInspection(),
              ),
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            if (controller.jointInspectionList.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ...controller.jointInspectionList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustText.body("Joint Inspection Department:\n${item['department']}", fontWeightName: FontWeight.w500),
                                const SizedBox(height: 4),
                                CustText.body("Responsible Person:\n${item['responsiblePerson']}", color: Colors.black87),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(TablerIcons.pencil, color: AppColors.orangeColor), onPressed: () {}),
                          IconButton(icon: const Icon(TablerIcons.trash, color: Colors.grey), onPressed: () => controller.removeJointInspection(index)),
                        ],
                      );
                    }).toList(),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.keyboard_arrow_left, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("1", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.keyboard_arrow_right, color: AppColors.orangeColor),
                      ],
                    )
                  ],
                ),
              ),
          ]
        ]
      ],
    ));
  }

  Widget _buildPartC() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Part C", 
          "Inprocess", 
          controller.isPartCExpanded.value, 
          () => controller.isPartCExpanded.toggle(),
          isCompleted: false,
        ),
        if (controller.isPartCExpanded.value) ...[
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
          _buildToggleSwitch("Power Block Required", controller.isPowerBlockRequired.value, (val) => controller.isPowerBlockRequired.value = val),
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.body("Allotment of Work to Maintainer", fontWeightName: FontWeight.w600),
          const SizedBox(height: AppConstants.elementSpacing),
          Row(
            children: [
              Expanded(
                child: CustDropdown(
                  label: "Name *",
                  hint: "Select",
                  items: controller.dummyFailureTypeList,
                  selectedValue: controller.selectedMaintainerName.value,
                  onChanged: (v) => controller.selectedMaintainerName.value = v,
                ),
              ),
              const SizedBox(width: AppConstants.elementSpacing),
              Expanded(
                child: CustomTextField(
                  label: "Work Alloted *",
                  hintText: "Enter work",
                  controller: controller.workAllotedController,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: "Add",
            size: 100,
            color1: Colors.blue.shade600,
            color2: Colors.blue.shade600,
            textColor: Colors.white,
            onSelected: (_) {},
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: "Submit",
            size: 100,
            color1: AppColors.orangeColor,
            color2: AppColors.orangeColor,
            textColor: Colors.white,
            onSelected: (_) {},
          ),
        ]
      ],
    ));
  }

  Widget _buildPartD() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Part D", 
          "Inprocess", 
          controller.isPartDExpanded.value, 
          () => controller.isPartDExpanded.toggle(),
          isCompleted: false,
        ),
        if (controller.isPartDExpanded.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Failure Type *",
            hint: "Select",
            items: controller.dummyFailureTypeList,
            selectedValue: controller.selectedPartDFailureType.value,
            onChanged: (v) => controller.selectedPartDFailureType.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildToggleSwitch("Failure Rectification Details: *", controller.isFailureRectification.value, (val) => controller.isFailureRectification.value = val),
          if (controller.isFailureRectification.value) ...[
            const SizedBox(height: AppConstants.elementSpacing),
            Row(
              children: [
                Expanded(
                  child: CustDropdown(
                    label: "Object Part:",
                    hint: "Select Object",
                    items: controller.dummyFailureTypeList,
                    selectedValue: controller.selectedObjectPart.value,
                    onChanged: (v) => controller.selectedObjectPart.value = v,
                  ),
                ),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(
                  child: CustDropdown(
                    label: "Fault:",
                    hint: "Select Fault",
                    items: controller.dummyFailureTypeList,
                    selectedValue: controller.selectedFault.value,
                    onChanged: (v) => controller.selectedFault.value = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustButton(
              name: "Add",
              size: 100,
              color1: AppColors.orangeColor,
              color2: AppColors.orangeColor,
              textColor: Colors.white,
              onSelected: (_) => controller.addFault(),
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            if (controller.faultList.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ...controller.faultList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustText.body("Object Part: ${item['objectPart']}", fontWeightName: FontWeight.w500),
                                const SizedBox(height: 4),
                                CustText.body("Fault: ${item['fault']}", color: Colors.black87),
                              ],
                            ),
                          ),
                          CustButton(
                            name: "Add RCA",
                            size: 80,
                            color1: Colors.blue.shade600,
                            color2: Colors.blue.shade600,
                            textColor: Colors.white,
                            onSelected: (_) {},
                          ),
                          const SizedBox(width: 8),
                          IconButton(icon: const Icon(TablerIcons.trash, color: Colors.red), onPressed: () => controller.removeFault(index)),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustomTextField(
              label: "Details of activity Carried Out",
              hintText: "Enter details",
              controller: controller.activityCarriedOutController,
            ),
          ],
          const SizedBox(height: AppConstants.elementSpacing),
          _buildToggleSwitch("Material Required", controller.isMaterialRequired.value, (val) => controller.isMaterialRequired.value = val),
          if (controller.isMaterialRequired.value) ...[
            const SizedBox(height: AppConstants.elementSpacing),
            Row(
              children: [
                Expanded(
                  child: CustDropdown(
                    label: "Material Code & Description: *",
                    hint: "Select...",
                    items: controller.dummyFailureTypeList,
                    selectedValue: controller.selectedMaterialCode.value,
                    onChanged: (v) => controller.selectedMaterialCode.value = v,
                  ),
                ),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustText.body("Unit of Measurement:", fontWeightName: FontWeight.w500, size: 12),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: const Text("Unit of Measurement", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    ],
                  )
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
                    items: controller.dummyFailureTypeList,
                    selectedValue: controller.selectedStoreLocation.value,
                    onChanged: (v) => controller.selectedStoreLocation.value = v,
                  ),
                ),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustText.body("Balance Quantity:", fontWeightName: FontWeight.w500, size: 12),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: const Text("Balance Quantity", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    ],
                  )
                ),
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustomTextField(
              label: "Required Quantity: *",
              hintText: "Enter Required Quantity",
              controller: controller.requiredQuantityController,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustButton(
              name: "Add Material",
              size: 130,
              color1: AppColors.orangeColor,
              color2: AppColors.orangeColor,
              textColor: Colors.white,
              onSelected: (_) {},
            ),
          ],
          const SizedBox(height: AppConstants.elementSpacing),
          _buildToggleSwitch("Material Dismantle: *", controller.isMaterialDismantle.value, (val) => controller.isMaterialDismantle.value = val),
          if (controller.isMaterialDismantle.value) ...[
            const SizedBox(height: AppConstants.elementSpacing),
            CustDropdown(
              label: "Material Code & Description: *",
              hint: "Select...",
              items: controller.dummyFailureTypeList,
              selectedValue: controller.selectedDismantleMaterialCode.value,
              onChanged: (v) => controller.selectedDismantleMaterialCode.value = v,
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: "Old Serial Number: *",
                    hintText: "Enter Old Series Number",
                    controller: controller.oldSerialNumberController,
                  ),
                ),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustText.body("Old Serial No Dismantle Date: *", fontWeightName: FontWeight.w500, size: 12),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            controller.oldSerialDismantleDate.value = "${date.day}/${date.month}/${date.year}";
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(controller.oldSerialDismantleDate.value ?? "DD/MM/YYYY", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              const Icon(TablerIcons.calendar, color: AppColors.orangeColor, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: "New Serial Number: *",
                    hintText: "Enter New Series Number",
                    controller: controller.newSerialNumberController,
                  ),
                ),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustText.body("New Serial No Installation Date: *", fontWeightName: FontWeight.w500, size: 12),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            controller.newSerialInstallationDate.value = "${date.day}/${date.month}/${date.year}";
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(controller.newSerialInstallationDate.value ?? "DD/MM/YYYY", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              const Icon(TablerIcons.calendar, color: AppColors.orangeColor, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            CustButton(
              name: "Add",
              size: 100,
              color1: Colors.blue.shade600,
              color2: Colors.blue.shade600,
              textColor: Colors.white,
              onSelected: (_) {},
            ),
          ],
          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: "Submit",
            size: 100,
            color1: AppColors.orangeColor,
            color2: AppColors.orangeColor,
            textColor: Colors.white,
            onSelected: (_) {},
          ),
        ]
      ],
    ));
  }

  Widget _buildPartE() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Part E", 
          "Inprocess", 
          controller.isPartEExpanded.value, 
          () => controller.isPartEExpanded.toggle(),
          isCompleted: false,
        ),
        if (controller.isPartEExpanded.value) ...[
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
                  child: CustText.body("I Hereby declare, that all persons have beeen withdrawn and all the equipement affected as detailed in Part A above have been restored to normal.", size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustText.body("Actual Work Start *", fontWeightName: FontWeight.w500, size: 12),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if (date != null) {
                          controller.actualWorkStart.value = "${date.day}/${date.month}/${date.year} 11:35"; // Time mocked for now
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(controller.actualWorkStart.value ?? "DD/MM/YYYY hh:mm", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const Icon(TablerIcons.calendar, color: AppColors.orangeColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.elementSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustText.body("Actual Work Complete *", fontWeightName: FontWeight.w500, size: 12),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if (date != null) {
                          controller.actualWorkComplete.value = "${date.day}/${date.month}/${date.year} 12:09";
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(controller.actualWorkComplete.value ?? "DD/MM/YYYY hh:mm", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const Icon(TablerIcons.calendar, color: AppColors.orangeColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: "Train Status *",
            hint: "Select",
            items: const ['CFIT', 'OUT OF SERVICE'], // Mock
            selectedValue: controller.selectedTrainStatus.value,
            onChanged: (v) => controller.selectedTrainStatus.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          // Attachments Section
          CustText.sectionHeader("Attachments: (Max File Size 1MB)", color: Colors.red),
          const SizedBox(height: AppConstants.elementSpacing),
          Row(
            children: [
              CustText.body("After:", size: 12),
              const SizedBox(width: AppConstants.elementSpacing),
              _buildUploadButton(controller.afterFiles),
            ],
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          Row(
            children: [
              CustText.body("Upload RCA:", size: 12),
              const SizedBox(width: AppConstants.elementSpacing),
              _buildUploadButton(controller.uploadRcaFiles),
            ],
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: "Submit",
            size: 100,
            color1: AppColors.orangeColor,
            color2: AppColors.orangeColor,
            textColor: Colors.white,
            onSelected: (_) {},
          ),
        ]
      ],
    ));
  }

  Widget _buildPartF() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Part F", 
          "Inprocess", 
          controller.isPartFExpanded.value, 
          () => controller.isPartFExpanded.toggle(),
          isCompleted: false,
        ),
        if (controller.isPartFExpanded.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.body("Need to Display SIC Checklist which is selected by earlier", fontWeightName: FontWeight.w600),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDataCard(
            items: [
              DataCardItem(label: "SIC Type", value: "Battery Box"),
              DataCardItem(label: "Responsible", value: "Mr.Virat Kohli"),
              DataCardItem(
                label: "Status",
                value: "Assigned",
                valueWidget: CustText(name: "Assigned", color: Colors.orange, size: 14, fontWeightName: FontWeight.bold),
              ),
            ],
            bottomAction: Align(
              alignment: Alignment.centerRight,
              child: CustButton(
                name: "Checksheet",
                size: 100,
                color1: Colors.blue.shade500,
                color2: Colors.blue.shade500,
                textColor: Colors.white,
                onSelected: (_) => Get.to(() => const SicChecklistScreen()),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: controller.isSicPerformed.value,
                onChanged: (val) => controller.isSicPerformed.value = val ?? false,
                activeColor: AppColors.orangeColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: CustText.body("I Hereby declare, that SIC has been performed on concerned equipement.", size: 12),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: controller.isFollowUpActionCompleted.value,
                onChanged: (val) => controller.isFollowUpActionCompleted.value = val ?? false,
                activeColor: AppColors.orangeColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: CustText.body("I Hereby declare, that All the necessary follow up action as described in Part F above and final Inspection, including SIC(if any), have been completed.", size: 12),
                ),
              ),
            ],
          ),
        ]
      ],
    ));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: const CustomAppBar(
        title: 'Create Failure',
      ),
      body: Container(
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
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPartB(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPartC(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPartD(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPartE(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPartF(),
                const SizedBox(height: AppConstants.sectionSpacing * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

