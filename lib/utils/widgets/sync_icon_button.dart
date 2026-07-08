import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_constants.dart';
import '../../../service/master_data_sync_service.dart';
import '../../../constants/colors.dart';
import '../../../utils/responsive_helper.dart';
import 'cust_text.dart';
import 'cust_popup.dart';

class SyncIconButton extends StatelessWidget {
  const SyncIconButton({Key? key}) : super(key: key);

  void _showSyncPopup(BuildContext context) {
    Get.dialog(
      CustPopup(
        icon: TablerIcons.cloud_upload,
        iconColor: AppColors.orangeColor,
        title: "Sync Master Data",
        message: "This will sync all master data from the server. Continue?",
        cancelText: "Cancel",
        confirmText: "Sync",
        onCancel: () => Get.back(),
        onConfirm: () {
          Get.back();
          MasterDataSyncService().syncMasterData();
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
