import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/widgets/cust_button.dart';
import 'package:om_mobile/utils/widgets/cust_date_time_picker.dart';
import 'package:om_mobile/utils/widgets/cust_dropdown.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';
import 'package:om_mobile/utils/widgets/cust_textfield.dart';
import 'package:om_mobile/utils/widgets/custom_app_bar.dart';
import 'package:om_mobile/utils/widgets/custom_dialog.dart';
import 'package:om_mobile/utils/widgets/sync_icon_button.dart';
import '../controller/ibl_controller.dart';

class IblScreen extends StatefulWidget {
  const IblScreen({super.key});

  @override
  State<IblScreen> createState() => _IblScreenState();
}

class _IblScreenState extends State<IblScreen> {
  late final IblController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<IblController>()) {
      Get.delete<IblController>();
    }
    controller = Get.put(IblController());
  }

  Widget _buildSectionHeader({
    required String title,
    required IblPartStatus status,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    final statusColor = switch (status) {
      IblPartStatus.completed => AppColors.green,
      IblPartStatus.inProcess => AppColors.orangeColor,
      IblPartStatus.pending => AppColors.red,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: CustText.sectionHeader(title, color: AppColors.orangeColor),
            ),
            CustText.body(
              controller.statusLabel(status),
              color: statusColor,
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

  Widget _buildDeclarationCheckbox({
    required bool value,
    required String text,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.orangeColor,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CustText.body(text, size: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklist(List<String> items, RxList<bool> checks) {
    return Obx(() => Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final label = String.fromCharCode(65 + index);
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.subElementSpacing),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustText.body('$label. ${entry.value}', size: 12),
              ),
              Checkbox(
                value: checks[index],
                onChanged: (v) => checks[index] = v ?? false,
                activeColor: AppColors.orangeColor,
              ),
            ],
          ),
        );
      }).toList(),
    ));
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText.formLabel(label),
        const SizedBox(height: AppConstants.labelSpacing),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.containerColor2,
            borderRadius: BorderRadius.circular(AppConstants.inputRadius),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: CustText.body(value, size: 13),
        ),
      ],
    );
  }

  Widget _buildPartA() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Part A',
          status: IblPartStatus.inProcess,
          isExpanded: controller.isPartAExpanded.value,
          onTap: () => controller.isPartAExpanded.toggle(),
        ),
        if (controller.isPartAExpanded.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.body(
            'IBL/HIC Power Block Request Form Filled by applicant',
            color: AppColors.textMutedLight,
            fontWeightName: FontWeight.w600,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustomTextField(
            label: 'Purpose of Work',
            hintText: 'Purpose of Work',
            controller: controller.purposeOfWorkController,
            maxLines: 4,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: 'Depot',
            hint: 'Select',
            items: controller.depotList,
            selectedValue: controller.selectedDepot.value,
            onChanged: (v) => controller.selectedDepot.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: 'IBL/HIC Line No',
            hint: 'Select',
            items: controller.iblLineList,
            selectedValue: controller.selectedIblLineNo.value,
            onChanged: (v) => controller.selectedIblLineNo.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: 'Trainset',
            hint: 'Select',
            items: controller.trainsetList,
            selectedValue: controller.selectedTrainset.value,
            onChanged: (v) => controller.selectedTrainset.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDateTimePicker(
            label: 'From Date Time',
            hint: 'DD/MM/YYYY hh:mm',
            selectedDateTime: controller.fromDateTime.value,
            onDateTimeSelected: (dt) => controller.fromDateTime.value = dt,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDateTimePicker(
            label: 'To Date Time',
            hint: 'DD/MM/YYYY hh:mm',
            selectedDateTime: controller.toDateTime.value,
            onDateTimeSelected: (dt) => controller.toDateTime.value = dt,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDateTimePicker(
            label: 'Extension Date & Time',
            hint: 'DD/MM/YYYY hh:mm',
            selectedDateTime: controller.extensionDateTime.value,
            onDateTimeSelected: (dt) => controller.extensionDateTime.value = dt,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: 'Request',
            size: 120,
            color1: AppColors.orangeColor,
            color2: AppColors.orangeColor,
            textDarkPrimary: Colors.white,
            onSelected: (_) => Get.dialog(CustomDialog('Request submitted successfully.')),
          ),
        ],
      ],
    ));
  }

  Widget _buildPartA1() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Part A.1',
          status: IblPartStatus.inProcess,
          isExpanded: controller.isPartA1Expanded.value,
          onTap: () => controller.isPartA1Expanded.toggle(),
        ),
        if (controller.isPartA1Expanded.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.body(
            'IBL/HIC Power Block Request approved by PPIO',
            color: AppColors.textMutedLight,
            fontWeightName: FontWeight.w600,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildReadOnlyField('Extension Date & Time', '05-06-2024 12:58'),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: 'Assign to IIC for discharging',
            hint: 'Select',
            items: controller.iicList,
            selectedValue: controller.selectedAssignIicDischarging.value,
            onChanged: (v) => controller.selectedAssignIicDischarging.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustomTextField(
            label: 'Remark',
            hintText: 'Assign IIC',
            controller: controller.assignIicRemarkController,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          Row(
            children: [
              Expanded(
                child: CustButton(
                  name: 'Approve',
                  size: double.infinity,
                  color1: AppColors.orangeColor,
                  color2: AppColors.orangeColor,
                  textDarkPrimary: Colors.white,
                  onSelected: (_) => Get.dialog(CustomDialog('Approved successfully.')),
                ),
              ),
              const SizedBox(width: AppConstants.elementSpacing),
              Expanded(
                child: CustButton(
                  name: 'Reject',
                  size: double.infinity,
                  color1: AppColors.orangeColor,
                  color2: AppColors.orangeColor,
                  textDarkPrimary: Colors.white,
                  onSelected: (_) => Get.dialog(CustomDialog('Request rejected.')),
                ),
              ),
            ],
          ),
        ],
      ],
    ));
  }

  Widget _buildPartB() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Part B',
          status: IblPartStatus.inProcess,
          isExpanded: controller.isPartBExpanded.value,
          onTap: () => controller.isPartBExpanded.toggle(),
        ),
        if (controller.isPartBExpanded.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.body(
            'Safety Instruction for isolation of OHE/confirmation of power block',
            color: AppColors.textMutedLight,
            fontWeightName: FontWeight.w600,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.formLabel('Safety Instruction'),
          const SizedBox(height: AppConstants.labelSpacing),
          _buildChecklist(IblController.partBInstructions, controller.partBChecks),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildDeclarationCheckbox(
            value: controller.isDeclarationPartB.value,
            text: IblController.partBDeclaration,
            onChanged: (v) => controller.isDeclarationPartB.value = v ?? false,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildReadOnlyField('Name of IIC', 'Mr. Yashwantrao Hajare - 00000844'),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildReadOnlyField('Date & time', '05-06-2026 15:22'),
          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: 'Submit',
            size: 120,
            color1: AppColors.orangeColor,
            color2: AppColors.orangeColor,
            textDarkPrimary: Colors.white,
            onSelected: (_) => Get.dialog(CustomDialog('Part B submitted successfully.')),
          ),
        ],
      ],
    ));
  }

  Widget _buildPartC() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Part C',
          status: IblPartStatus.inProcess,
          isExpanded: controller.isPartCExpanded.value,
          onTap: () => controller.isPartCExpanded.toggle(),
        ),
        if (controller.isPartCExpanded.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.body('Receipt (Filled by primary applicant)', color: AppColors.textMutedLight, fontWeightName: FontWeight.w600),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildDeclarationCheckbox(
            value: controller.isDeclarationPartC.value,
            text: IblController.partCDeclaration,
            onChanged: (v) => controller.isDeclarationPartC.value = v ?? false,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildReadOnlyField('Name of Primary applicant', 'Mr. Moreshwar Jambhulkar'),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildReadOnlyField('Date & time', '05-06-2026 13:00'),
          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: 'Submit',
            size: 120,
            color1: AppColors.orangeColor,
            color2: AppColors.orangeColor,
            textDarkPrimary: Colors.white,
            onSelected: (_) => Get.dialog(CustomDialog('Part C submitted successfully.')),
          ),
        ],
      ],
    ));
  }

  Widget _buildPartD() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Part D',
          status: IblPartStatus.inProcess,
          isExpanded: controller.isPartDExpanded.value,
          onTap: () => controller.isPartDExpanded.toggle(),
        ),
        if (controller.isPartDExpanded.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.body(
            'Clearance certificate for cancellation of power block (Primary applicant)',
            color: AppColors.textMutedLight,
            fontWeightName: FontWeight.w600,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          _buildDeclarationCheckbox(
            value: controller.isDeclarationPartD.value,
            text: IblController.partDDeclaration,
            onChanged: (v) => controller.isDeclarationPartD.value = v ?? false,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: 'Submit',
            size: 120,
            color1: AppColors.orangeColor,
            color2: AppColors.orangeColor,
            textDarkPrimary: Colors.white,
            onSelected: (_) => Get.dialog(CustomDialog('Part D submitted successfully.')),
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.detailLabel('Clearance given by :'),
          const SizedBox(height: AppConstants.labelSpacing),
          CustText.detailLabel('Date And Time Of Clearance :'),
        ],
      ],
    ));
  }

  Widget _buildPartD1() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Part D.1',
          status: IblPartStatus.inProcess,
          isExpanded: controller.isPartD1Expanded.value,
          onTap: () => controller.isPartD1Expanded.toggle(),
        ),
        if (controller.isPartD1Expanded.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.body('Assignment for charging by PPIO', color: AppColors.textMutedLight, fontWeightName: FontWeight.w600),
          const SizedBox(height: AppConstants.elementSpacing),
          CustDropdown(
            label: 'Assign to IIC for charging',
            hint: 'Select',
            items: controller.iicList,
            selectedValue: controller.selectedAssignIicCharging.value,
            onChanged: (v) => controller.selectedAssignIicCharging.value = v,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: 'Submit',
            size: 120,
            color1: AppColors.orangeColor,
            color2: AppColors.orangeColor,
            textDarkPrimary: Colors.white,
            onSelected: (_) => Get.dialog(CustomDialog('Part D.1 submitted successfully.')),
          ),
        ],
      ],
    ));
  }

  Widget _buildPartE() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Part E',
          status: IblPartStatus.inProcess,
          isExpanded: controller.isPartEExpanded.value,
          onTap: () => controller.isPartEExpanded.toggle(),
        ),
        if (controller.isPartEExpanded.value) ...[
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.body(
            'Cancellation of power block (Checklist to be fill by IIC)',
            color: AppColors.textMutedLight,
            fontWeightName: FontWeight.w600,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.formLabel('Safety instruction for OHE energisation'),
          const SizedBox(height: AppConstants.labelSpacing),
          _buildChecklist(IblController.partEInstructions, controller.partEChecks),
          const SizedBox(height: AppConstants.elementSpacing),
          CustButton(
            name: 'Submit',
            size: 120,
            color1: AppColors.orangeColor,
            color2: AppColors.orangeColor,
            textDarkPrimary: Colors.white,
            onSelected: (_) => Get.dialog(CustomDialog('Part E submitted successfully.')),
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          CustText.detailLabel('Charged By :-'),
          const SizedBox(height: AppConstants.labelSpacing),
          CustText.detailLabel('Date And Time Of Charging :-'),
        ],
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'IBL/HIC Request',
        showDrawer: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: const SyncIconButton(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
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
                CustText.sectionHeader('Create IBL/HIC Request Form', color: AppColors.orangeColor),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPartA(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPartA1(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPartB(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPartC(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPartD(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPartD1(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildPartE(),
                const SizedBox(height: AppConstants.sectionSpacing * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
