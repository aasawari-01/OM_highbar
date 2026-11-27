import 'package:flutter/material.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';

import '../../model/dashboard_models.dart';
import 'dashboard_card.dart';

/// The newest failures of the list, with a link to the whole list.
class DashboardRecentCard extends StatelessWidget {
  const DashboardRecentCard({
    super.key,
    required this.recent,
    required this.onViewAll,
  });

  final List<DashboardRecentFailure> recent;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Recent failures',
      trailing: GestureDetector(
        onTap: onViewAll,
        child: CustText(
          name: 'View all',
          size: AppConstants.detailLabelSize,
          color: AppColors.darkBlue,
          fontWeightName: FontWeight.w600,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            if (i > 0) const Divider(color: AppColors.textFieldColor),
            _RecentRow(item: recent[i], onTap: onViewAll),
          ],
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.item, required this.onTap});

  final DashboardRecentFailure item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [item.location, item.date].where((e) => e.isNotEmpty).join('  |  ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustText(
                    name: item.code.isEmpty ? 'Failure' : item.code,
                    size: AppConstants.bodySize,
                    color: AppColors.black,
                    fontWeightName: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    CustText(
                      name: item.description,
                      size: AppConstants.subtitleSize + 1,
                      color: AppColors.textDarkPrimary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    CustText(
                      name: subtitle,
                      size: AppConstants.subtitleSize,
                      color: AppColors.textDarkSecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (item.status.isNotEmpty) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: DashboardChip(
                  label: item.status,
                  color: dashboardStatusColor(item.status),
                  filled: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
