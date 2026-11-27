import 'package:flutter/material.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';

import '../../model/dashboard_models.dart';
import 'dashboard_card.dart';

/// Total / In progress / Closed (and Joint inspection for a Junior Engineer),
/// plus what waits to be sent. Tapping a tile opens the failure list.
class DashboardStatTiles extends StatelessWidget {
  const DashboardStatTiles({
    super.key,
    required this.summary,
    required this.waiting,
    required this.onOpenList,
  });

  final DashboardSummary summary;
  final int waiting;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(
        title: 'Total',
        count: summary.total,
        gradient: DashboardGradients.blue,
        onTap: onOpenList,
      ),
      _StatTile(
        title: 'In progress',
        count: summary.open,
        gradient: DashboardGradients.orange,
        onTap: onOpenList,
      ),
      _StatTile(
        title: 'Closed',
        count: summary.closed,
        gradient: DashboardGradients.green,
        onTap: onOpenList,
      ),
      if (summary.jointInspection != null)
        _StatTile(
          title: 'Joint inspection',
          count: summary.jointInspection!,
          gradient: DashboardGradients.purple,
          onTap: onOpenList,
        )
      else
        _StatTile(
          title: 'To be sent',
          count: waiting,
          gradient: DashboardGradients.purple,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.elementSpacing),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.1,
        children: tiles,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.count,
    required this.gradient,
    this.onTap,
  });

  final String title;
  final int count;
  final List<Color> gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      shadowColor: AppColors.black.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 14,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustText(
                      name: title,
                      size: AppConstants.detailLabelSize,
                      color: AppColors.textDarkSecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    CustText(
                      name: '$count',
                      size: AppConstants.sectionHeaderValue,
                      color: AppColors.textDarkPrimary,
                      fontWeightName: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
