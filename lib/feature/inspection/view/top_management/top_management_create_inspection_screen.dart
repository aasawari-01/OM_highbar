import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/widgets/cust_button.dart';
import 'package:om_mobile/utils/widgets/cust_dropdown.dart';
import 'package:om_mobile/utils/widgets/cust_radio.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';
import 'package:om_mobile/utils/widgets/cust_textfield.dart';
import 'package:om_mobile/utils/widgets/custom_app_bar.dart';
import 'package:om_mobile/utils/widgets/sync_icon_button.dart';
import '../../controller/top_management_inspection_controller.dart';
import 'top_management_inspection_observation_screen.dart';

class TopManagementCreateInspectionScreen extends StatefulWidget {
  const TopManagementCreateInspectionScreen({super.key});

  @override
  State<TopManagementCreateInspectionScreen> createState() => _TopManagementCreateInspectionScreenState();
}

class _TopManagementCreateInspectionScreenState extends State<TopManagementCreateInspectionScreen> {
  late final TopManagementInspectionController controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<TopManagementInspectionController>()) {
      controller = Get.find<TopManagementInspectionController>();
    } else {
      controller = Get.put(TopManagementInspectionController());
    }
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustText.sectionHeader('Inspection Details', color: AppColors.orangeColor),
                      const SizedBox(height: AppConstants.elementSpacing),
                      Obx(() => CustDropdown(
                        label: 'Date of Inspection',
                        hint: 'Select',
                        items: TopManagementInspectionController.dateOptions,
                        selectedValue: controller.selectedDate.value,
                        onChanged: (v) => controller.selectedDate.value = v,
                      )),
                      const SizedBox(height: AppConstants.elementSpacing),
                      Obx(() => CustDropdown(
                        label: 'Inspector Department',
                        hint: 'Select',
                        items: TopManagementInspectionController.departmentOptions,
                        selectedValue: controller.selectedDepartment.value,
                        onChanged: (v) => controller.selectedDepartment.value = v,
                      )),
                      const SizedBox(height: AppConstants.elementSpacing),
                      Obx(() => CustDropdown(
                        label: 'Inspecting Officer',
                        hint: 'Select',
                        items: TopManagementInspectionController.officerOptions,
                        selectedValue: controller.selectedOfficer.value,
                        onChanged: (v) => controller.selectedOfficer.value = v,
                      )),
                      const SizedBox(height: AppConstants.elementSpacing),
                      Obx(() => CustDropdown(
                        label: 'Type of Inspection',
                        hint: 'Select',
                        items: TopManagementInspectionController.inspectionTypeOptions,
                        selectedValue: controller.selectedInspectionType.value,
                        onChanged: (v) => controller.selectedInspectionType.value = v,
                      )),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustText.formLabel('Inspection Location'),
                      const SizedBox(height: AppConstants.labelSpacing),
                      Obx(() => Wrap(
                        spacing: AppConstants.elementSpacing,
                        runSpacing: AppConstants.subElementSpacing,
                        children: TopManagementInspectionController.locationOptions.map((loc) {
                          return CustRadio<String>(
                            value: loc,
                            groupValue: controller.selectedLocation.value,
                            label: loc,
                            onChanged: (v) {
                              if (v != null) controller.selectedLocation.value = v;
                            },
                          );
                        }).toList(),
                      )),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustomTextField(
                        label: 'Location From',
                        hintText: 'Select frequency',
                        controller: controller.locationFromController,
                        suffixIcon: const Icon(Icons.location_on, color: AppColors.orangeColor),
                      ),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustomTextField(
                        label: 'Location To',
                        hintText: 'Select date',
                        controller: controller.locationToController,
                        suffixIcon: const Icon(Icons.location_on, color: AppColors.orangeColor),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.screenPadding,
                  AppConstants.elementSpacing,
                  AppConstants.screenPadding,
                  AppConstants.screenPadding,
                ),
                child: CustButton(
                  name: 'Next',
                  size: double.infinity,
                  sHeight: AppConstants.buttonHeight,
                  onSelected: (_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TopManagementInspectionObservationScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
