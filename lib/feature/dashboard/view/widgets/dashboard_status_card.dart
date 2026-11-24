import 'package:flutter/material.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';

import '../../model/dashboard_models.dart';
import 'dashboard_card.dart';

/// Failures per status as horizontal bars.
class DashboardStatusCard extends StatelessWidget {
  const DashboardStatusCard({super.key, required this.statuses});

  final List<DashboardStatusCount> statuses;

  @override
  Widget build(BuildContext context) {
    final max = statuses.fold<int>(1, (m, s) => s.count > m ? s.count : m);
    return DashboardCard(
      title: 'Failures by status',
      child: Column(
        children: [
          for (final s in statuses)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: CustText(
                      name: s.name,
                      size: AppConstants.subtitleSize + 1,
                      color: AppColors.textDarkPrimary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.count / max,
                        minHeight: 10,
                        backgroundColor: AppColors.textFieldColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            dashboardStatusColor(s.name)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 30,
                    child: CustText(
                      name: '${s.count}',
                      size: AppConstants.detailLabelSize,
                      color: AppColors.textDarkPrimary,
                      fontWeightName: FontWeight.w600,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
