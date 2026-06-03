import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import '../controller/rst_failure_controller.dart';
import 'package:om_mobile/utils/widgets/custom_app_bar.dart';

class SicChecklistScreen extends StatelessWidget {
  const SicChecklistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Find the existing controller
    final controller = Get.find<RstFailureController>();

    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: const CustomAppBar(
        title: 'SIC check list',
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.screenPadding),
                  child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Failure No:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    const Text("RST/10-2024/0024", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Created On:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    const Text("17-10-2024 14:00", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            const Text("Train Set :", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            const Text("Line 01, Mihan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Collapsible Section
                      GestureDetector(
                        onTap: () => controller.isEquipmentLockingExpanded.toggle(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(child: Text("Underframe Equipment locking/ Tightness", style: TextStyle(color: AppColors.orangeColor, fontWeight: FontWeight.bold, fontSize: 16))),
                            Icon(controller.isEquipmentLockingExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (controller.isEquipmentLockingExpanded.value)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
                            ]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("WFL Control box cover", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text("DMR", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 24, width: 24,
                                        child: Checkbox(value: controller.isDmrChecked.value, onChanged: (v) => controller.isDmrChecked.value = v ?? false, activeColor: AppColors.orangeColor),
                                      )
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text("TC", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 24, width: 24,
                                        child: Checkbox(value: controller.isTcChecked.value, onChanged: (v) => controller.isTcChecked.value = v ?? false, activeColor: AppColors.orangeColor),
                                      )
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text("TMB", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 24, width: 24,
                                        child: Checkbox(value: controller.isTmbChecked.value, onChanged: (v) => controller.isTmbChecked.value = v ?? false, activeColor: AppColors.orangeColor),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text("Remark", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Container(
                                height: 40,
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                child: TextField(
                                  controller: controller.checklistRemarkController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Text here",
                                    hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.keyboard_arrow_left, color: Colors.grey),
                          SizedBox(width: 8),
                          Text("1", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.keyboard_arrow_right, color: AppColors.orangeColor),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: controller.isSicPerformed.value,
                            onChanged: (val) => controller.isSicPerformed.value = val ?? false,
                            activeColor: AppColors.orangeColor,
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 10.0),
                              child: Text("I Hereby declare, that SIC has been performed on concerned equipment.", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
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
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 10.0),
                              child: Text("I Hereby declare, that All the necessary follow up action as described in Part F above and final Inspection, including SIC(if any), have been completed.", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text("Remark", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                        child: TextField(
                          controller: controller.sicChecklistRemarkController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Text here",
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  )),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  child: const Text("Submit", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
