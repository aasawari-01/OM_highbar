import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/responsive_helper.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';

import '../../model/dashboard_models.dart';
import 'dashboard_card.dart';

/// Open and closed failures per system (same chart style as before, now fed
/// with the real data).
class DashboardSystemChart extends StatelessWidget {
  const DashboardSystemChart({super.key, required this.systems});

  final List<DashboardSystemStat> systems;

  @override
  Widget build(BuildContext context) {
    final peak = systems.fold<int>(0, (m, s) => s.total > m ? s.total : m);
    // Round the top of the axis up to a multiple of 5.
    final maxY = ((peak / 5).ceil() * 5).clamp(5, 100000).toDouble();
    final interval = (maxY / 5).ceilToDouble().clamp(1, 100000).toDouble();

    return DashboardCard(
      title: 'Failures by system',
      child: Column(
        children: [
          SizedBox(
            height: ResponsiveHelper.height(context, 220),
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.borderColor),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: interval,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) {
                      final s = systems[group.x];
                      return BarTooltipItem(
                        '${s.label}\nOpen ${s.open}  Closed ${s.closed}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= systems.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: CustText(
                            name: systems[i].label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            size: 10,
                            color: AppColors.textDarkPrimary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: [
                  for (var i = 0; i < systems.length; i++) _bar(i, systems[i], maxY),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(AppColors.barColor6, 'Open'),
              SizedBox(width: 20),
              _Legend(AppColors.barColor7, 'Closed'),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, DashboardSystemStat s, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: s.total.toDouble(),
          width: 14,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(2),
          ),
          rodStackItems: [
            BarChartRodStackItem(0, s.closed.toDouble(), AppColors.barColor7),
            BarChartRodStackItem(
                s.closed.toDouble(), s.total.toDouble(), AppColors.barColor6),
          ],
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        CustText(
          name: label,
          size: AppConstants.subtitleSize,
          color: AppColors.textDarkSecondary,
          fontWeightName: FontWeight.w500,
        ),
      ],
    );
  }
}
