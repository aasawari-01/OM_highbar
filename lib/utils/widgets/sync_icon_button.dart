import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_constants.dart';
import '../../../service/master_data_sync_service.dart';
import '../../../constants/colors.dart';
import 'cust_popup.dart';

class SyncIconButton extends StatelessWidget {
  final String? failureType;

  const SyncIconButton({Key? key, this.failureType}) : super(key: key);

  void _showSyncPopup(BuildContext context) {
    final title = failureType != null ? "Sync $failureType Failures" : "Sync Master Data";
    final message = failureType != null 
        ? "This will sync the $failureType failure list from the server. Continue?"
        : "This will sync all master data from the server. Continue?";

    Get.dialog(
      CustPopup(
        icon: TablerIcons.cloud_upload,
        iconColor: AppColors.orangeColor,
        title: title,
        message: message,
        cancelText: "Cancel",
        confirmText: "Sync",
        onCancel: () => Get.back(),
        onConfirm: () {
          Get.back();
          final syncService = MasterDataSyncService();
          if (failureType != null) {
            syncService.syncFailureList(failureType!);
          } else {
            syncService.syncMasterData();
          }
          // Also sync pending submissions
          syncService.syncPendingSubmissions();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final syncService = Get.find<MasterDataSyncService>();
      final isSyncing = syncService.isSyncing.value;
      
      return GestureDetector(
        onTap: isSyncing ? null : () => _showSyncPopup(context),
        child: Stack(
          children: [
            Icon(
              TablerIcons.cloud_upload,
              size: AppConstants.iconSize,
              color: isSyncing ? AppColors.green : AppColors.white1,
            ),
          ],
        ),
      );
    });
  }
}
