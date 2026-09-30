import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';

import '../../../../constants/app_constants.dart';
import '../../../../core/controller/session_controller.dart';
import '../../../../core/models/label_value.dart';
import '../../../../utils/widgets/cust_button.dart';
import '../../../../utils/widgets/cust_dropdown.dart';
import '../../../../utils/widgets/cust_loader.dart';
import '../../../../utils/widgets/cust_text.dart';
import '../../service/failure_service.dart';

/// Depot picker for the DCC role. Loads depots from the lookup API, saves the
/// choice with the insert API on OK and stores it in [SessionController].
/// Returns true when a depot was selected and saved.
Future<bool> showDepotSelectionPopup() async {
  final session = Get.find<SessionController>();
  final service = FailureService();
  final depots = <LabelValue>[];
  final isLoading = true.obs;
  final isSaving = false.obs;
  final selectedName = Rxn<String>(session.selectedDepotName.value);
  final selectedId = Rxn<String>(session.selectedDepotId.value);

  service.getDepotNames().then((list) {
    depots.assignAll(list);
  }).catchError((e) {
    debugPrint('showDepotSelectionPopup: error fetching depots: $e');
  }).whenComplete(() => isLoading.value = false);

  final result = await Get.dialog<bool>(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDarkSecondary,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(15),
        child: Obx(() {
          if (isLoading.value || isSaving.value) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustLoader(),
                const SizedBox(height: 16),
                Text(isSaving.value ? 'Saving depot...' : 'Fetching depots...',
                    style: const TextStyle(color: AppColors.textDarkSecondary)),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Get.back(result: false),
                  child: const Icon(TablerIcons.x,
                      color: AppColors.textDarkPrimary, size: 24),
                ),
              ),
              CustText(
                  name: 'Select Depot',
                  size: AppConstants.headerSize,
                  color: AppColors.black,
                  fontWeightName: FontWeight.w600),
              const SizedBox(height: 16),
              CustDropdown(
                label: 'Depot',
                hint: 'Select Depot',
                items: depots.map((e) => e.label ?? '').toList(),
                selectedValue: selectedName.value,
                onChanged: (val) {
                  selectedName.value = val;
                  selectedId.value = depots
                      .firstWhere((e) => e.label == val,
                      orElse: () => LabelValue(value: '0'))
                      .value;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustOutlineButton(
                      name: 'Cancel',
                      size: double.infinity,
                      sHeight: 35,
                      onSelected: (_) => Get.back(result: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustButton(
                      name: 'OK',
                      size: double.infinity,
                      sHeight: 35,
                      onSelected: (_) async {
                        final depotId = int.tryParse(selectedId.value ?? '') ?? 0;
                        if (depotId == 0) {
                          Get.snackbar(
                            'Error',
                            'Please select a depot',
                            backgroundColor: AppColors.red.withValues(alpha: 0.9),
                            colorText: AppColors.white1,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }
                        isSaving.value = true;
                        bool saved = false;
                        try {
                          saved = await service.saveUserDepot(depotId);
                        } catch (e) {
                          debugPrint('showDepotSelectionPopup: save failed: $e');
                        }
                        isSaving.value = false;
                        if (!saved) {
                          Get.snackbar(
                            'Error',
                            'Failed to save depot. Please try again.',
                            backgroundColor: AppColors.red.withValues(alpha: 0.9),
                            colorText: AppColors.white1,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }
                        session.selectedDepotId.value = selectedId.value;
                        session.selectedDepotName.value = selectedName.value;
                        Get.back(result: true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    ),
    barrierDismissible: false,
  );
  return result ?? false;
}
