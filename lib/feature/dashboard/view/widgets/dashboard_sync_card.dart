import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';

import '../../controller/dashboard_controller.dart';
import 'dashboard_card.dart';

/// Online / offline state, what waits in the offline queue, and the sync
/// button.
class DashboardSyncCard extends StatelessWidget {
  const DashboardSyncCard({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final online = controller.isOnline.value;
      final syncing = controller.isSyncing.value;
      final queue = controller.queue.value;
      final updated = controller.lastUpdated.value;

      final Color stateColor =
          syncing ? AppColors.darkBlue : (online ? AppColors.green1 : AppColors.red);
      final String stateText =
          syncing ? 'Syncing...' : (online ? 'Online' : 'Offline');

      return DashboardCard(
        title: 'Sync status',
        trailing: DashboardChip(
          label: stateText,
          icon: syncing
              ? TablerIcons.refresh
              : (online ? TablerIcons.wifi : TablerIcons.wifi_off),
          color: stateColor,
          filled: true,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustText(
                  name: '${queue.total}',
                  size: AppConstants.sectionHeaderValue + 8,
                  color: queue.total == 0
                      ? AppColors.green1
                      : AppColors.orangeColor,
                  fontWeightName: FontWeight.w700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: CustText(
                      name: queue.total == 0
                          ? 'Everything is synced'
                          : (queue.total == 1
                              ? 'item waiting to sync'
                              : 'items waiting to sync'),
                      size: AppConstants.bodySize,
                      color: AppColors.textDarkSecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            if (queue.byType.isNotEmpty) ...[
              const SizedBox(height: AppConstants.subElementSpacing),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in queue.byType.entries)
                    DashboardChip(
                      label: '${e.key}: ${e.value}',
                      color: AppColors.orangeColor,
                      filled: true,
                    ),
                ],
              ),
            ],
            if (queue.failed > 0) ...[
              const SizedBox(height: AppConstants.subElementSpacing),
              Row(
                children: [
                  const Icon(TablerIcons.alert_circle,
                      size: 16, color: AppColors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: CustText(
                      name: '${queue.failed} could not be sent. Open the list '
                          'to retry or discard.',
                      size: AppConstants.subtitleSize,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
            ],
            if (!online && queue.total > 0) ...[
              const SizedBox(height: AppConstants.subElementSpacing),
              CustText(
                name: 'They will be sent automatically when internet returns.',
                size: AppConstants.subtitleSize,
                color: AppColors.textMuted,
              ),
            ],
            const SizedBox(height: AppConstants.elementSpacing - 4),
            Row(
              children: [
                Expanded(
                  child: CustText(
                    name: updated == null
                        ? ''
                        : 'Updated ${DateFormat('dd MMM, HH:mm').format(updated)}',
                    size: AppConstants.subtitleSize,
                    color: AppColors.textMuted,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: (online && !syncing) ? controller.syncNow : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orangeColor,
                    side: BorderSide(
                      color: (online && !syncing)
                          ? AppColors.orangeColor
                          : AppColors.buttonOutlineColor,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: syncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(TablerIcons.cloud_upload, size: 16),
                  label: const Text('Sync now'),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
