import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/widgets/cust_button.dart';
import 'package:om_mobile/utils/widgets/cust_dropdown.dart';
import 'package:om_mobile/utils/widgets/cust_radio.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';
import 'package:om_mobile/utils/widgets/custom_app_bar.dart';
import 'package:om_mobile/utils/widgets/custom_dialog.dart';
import 'package:om_mobile/utils/widgets/sync_icon_button.dart';
import '../../controller/top_management_inspection_controller.dart';

class TopManagementInspectionObservationScreen extends StatefulWidget {
  const TopManagementInspectionObservationScreen({super.key});

  @override
  State<TopManagementInspectionObservationScreen> createState() => _TopManagementInspectionObservationScreenState();
}

class _TopManagementInspectionObservationScreenState extends State<TopManagementInspectionObservationScreen> {
  late final TopManagementInspectionController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<TopManagementInspectionController>();
  }

  Future<void> _pickFile(ObservationEntry entry) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      setState(() {
        entry.files
          ..clear()
          ..add(File(result.files.single.path!));
      });
    }
  }

  void _submit() {
    if (controller.endChoice.value == InspectionEndChoice.addMore) {
      controller.addObservation();
      controller.endChoice.value = InspectionEndChoice.endInspection;
      setState(() {});
      return;
    }
    Get.dialog(CustomDialog('Inspection submitted successfully.'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'Create Inspection',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          const SyncIconButton(),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Obx(() => ListView.builder(
                padding: const EdgeInsets.all(AppConstants.screenPadding),
                itemCount: controller.observations.length,
                itemBuilder: (context, index) => _buildObservationBlock(index),
              )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.screenPadding,
                AppConstants.elementSpacing,
                AppConstants.screenPadding,
                AppConstants.screenPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustOutlineButton(
                      name: 'Back',
                      size: double.infinity,
                      sHeight: AppConstants.buttonHeight,
                      borderColor: AppColors.borderColor,
                      textDarkPrimary: AppColors.textMuted,
                      onSelected: (_) => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppConstants.elementSpacing),
                  Expanded(
                    child: CustButton(
                      name: 'Submit',
                      size: double.infinity,
                      sHeight: AppConstants.buttonHeight,
                      onSelected: (_) => _submit(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationBlock(int index) {
    final entry = controller.observations[index];
    final no = (index + 1).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) const SizedBox(height: AppConstants.sectionSpacing),
        CustText.sectionHeader('Observation No. $no', color: AppColors.orangeColor),
        const SizedBox(height: AppConstants.subElementSpacing),
        CustText.body(
          'Record your observations in this section. Recording of anomalies, issues, deficiencies only is suggested',
          size: 12,
          color: AppColors.textDarkSecondary,
        ),
        const SizedBox(height: AppConstants.elementSpacing),
        CustDropdown(
          label: 'Observation No. $no',
          hint: 'Select',
          items: TopManagementInspectionController.observationOptions,
          selectedValue: entry.observation,
          onChanged: (v) => setState(() => entry.observation = v),
        ),
        const SizedBox(height: AppConstants.elementSpacing),
        CustDropdown(
          label: 'Dept. Pertains For Observation No. $no',
          hint: 'Select',
          items: TopManagementInspectionController.observationDeptOptions,
          selectedValue: entry.department,
          onChanged: (v) => setState(() => entry.department = v),
        ),
        const SizedBox(height: AppConstants.elementSpacing),
        CustDropdown(
          label: 'Category For Observation No. $no',
          hint: 'Select',
          items: TopManagementInspectionController.categoryOptions,
          selectedValue: entry.category,
          onChanged: (v) => setState(() => entry.category = v),
        ),
        const SizedBox(height: AppConstants.elementSpacing),
        CustText.formLabel('File Upload for Observation No. $no'),
        const SizedBox(height: AppConstants.labelSpacing),
        CustText.body(
          '(Photo, Video, Audio, Documents) Upload 1 supported file. Max 10 MB.',
          size: 11,
          color: AppColors.textDarkSecondary,
        ),
        const SizedBox(height: AppConstants.subElementSpacing),
        CustButton(
          name: 'Add File',
          size: 100,
          sHeight: 34,
          onSelected: (_) => _pickFile(entry),
        ),
        if (entry.files.isNotEmpty) ...[
          const SizedBox(height: AppConstants.subElementSpacing),
          CustText.body(entry.files.first.path.split(Platform.pathSeparator).last, size: 12),
        ],
        if (index == controller.observations.length - 1) ...[
          const SizedBox(height: AppConstants.sectionSpacing),
          CustText.body(
            'Do you want to Add More Observations or End Your Inspection?',
            fontWeightName: FontWeight.w600,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          Obx(() => Column(
            children: [
              CustRadio<InspectionEndChoice>(
                value: InspectionEndChoice.addMore,
                groupValue: controller.endChoice.value,
                label: 'Add Observation',
                onChanged: (v) {
                  if (v != null) controller.endChoice.value = v;
                },
              ),
              const SizedBox(height: AppConstants.subElementSpacing),
              CustRadio<InspectionEndChoice>(
                value: InspectionEndChoice.endInspection,
                groupValue: controller.endChoice.value,
                label: 'End Of Inspection',
                onChanged: (v) {
                  if (v != null) controller.endChoice.value = v;
                },
              ),
            ],
          )),
        ],
      ],
    );
  }

  Widget _buildProfileAction() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const CircleAvatar(radius: 16, backgroundColor: AppColors.white1),
        Positioned(
          right: 0,
          bottom: 2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white1, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
