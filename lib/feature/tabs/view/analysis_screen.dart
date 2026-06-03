import 'dart:math';

import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/responsive_helper.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/custom_app_bar.dart';


class PieChartData {
  final String category;
  final int value;
  final Color color;

  PieChartData(this.category, this.value, this.color);
}

// Data class for Failure Maintenance Chart
class FailureMaintenanceData {
  final String category;
  final String line; // "Line-1" or "Line-2"
  final int pending;
  final int closed;

  FailureMaintenanceData(this.category, this.line, this.pending, this.closed);
}

// Data class for Scheduled Maintenance Chart
class ScheduledMaintenanceData {
  final String label;
  final int value;
  final Color color;

  ScheduledMaintenanceData(this.label, this.value, this.color);
}

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  // Sample data for the pie chart
  List<PieChartData> get _pieChartData => [
    PieChartData('Rolling Stock', 9, Color(0xffA084E8)),
    PieChartData('Telecom', 4, Color(0xffFFA07A)),
    PieChartData('Signaling', 7, Color(0xff20B2AA)),
    PieChartData('Power supply', 18, Color(0xffFFA500)),
    PieChartData('Overhead Equipment', 5, Color(0xff6495ED)),
    PieChartData('Electrical & Mechanical', 22, Color(0xff90EE90)),
    PieChartData('AFC', 30, Color(0xff00CED1)),
    PieChartData('Civil', 20, Color(0xff87CEFA)),
    PieChartData('Security Surveillance System', 7, Color(0xff4682B4)),
    PieChartData('Depot Equipment', 40, Color(0xffFFDB58)),
  ];

  // Sample data for the charts (replace with your actual data)
  List<FailureMaintenanceData> get _failureMaintenanceData => [
    FailureMaintenanceData('Blank', 'Line-1', 5, 4),
    FailureMaintenanceData('Blank', 'Line-2', 6, 5),
    FailureMaintenanceData('Interlocking System', 'Line-1', 7, 8),
    FailureMaintenanceData('Interlocking System', 'Line-2', 8, 9),
    FailureMaintenanceData('Point Machine', 'Line-1', 4, 5),
    FailureMaintenanceData('Point Machine', 'Line-2', 6, 3),
  ];

  List<ScheduledMaintenanceData> get _scheduledMaintenanceData => [
    ScheduledMaintenanceData('Blank', 15, AppColors.barColor1),
    ScheduledMaintenanceData('Interlocking System', 70, AppColors.barColor4),
    ScheduledMaintenanceData('Point Machine', 35, AppColors.barColor5),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomAppBar(
      title: 'Analysis',
      showDrawer: true,
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.notifications_none, color: AppColors.white1),
      //     onPressed: () {},
      //   ),
      //   IconButton(
      //     icon: const Icon(Icons.filter_list, color: AppColors.white1),
      //     onPressed: () {},
      //   ),
      // ],
            ),
          const SizedBox(height: AppConstants.elementSpacing),
            // Pie Chart Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: CustText.sectionHeader('Department wise Service Affecting Failure', color: AppColors.textColor3),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xff0089BA), size: 16),
                          const SizedBox(width: 4),
                          CustText(
                            name: 'Last 30 days',
                            size: 12,
                            color: AppColors.textColor4,
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: AppColors.textColor4, size: 18),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: AppColors.white1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.cardRadius)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.cardPadding),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 250,
                              child: _buildPieChart(),
                            ),
                            const SizedBox(height: 8),
                            _buildPieChartLegend(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.sectionSpacing),
                  // Failure Maintenance Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustText.sectionHeader('Failure Maintenance', color: AppColors.textColor3),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xff0089BA), size: 16),
                          const SizedBox(width: 4),
                          CustText(
                            name: 'Last 30 days',
                            size: 12,
                            color: AppColors.textColor4,
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: AppColors.textColor4, size: 18),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Card(
                    color: AppColors.white1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.cardRadius)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.cardPadding),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: _buildFailureMaintenanceChart(),
                          ),
                          const SizedBox(height: 8),
                          Legend(
                            legends: const [
                              LegendItem('Line-1 Line-2 - Pending', AppColors.barColor1),
                              LegendItem('Line-1 Line-2 - Closed', AppColors.barColor4),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                   SizedBox(height: ResponsiveHelper.spacing(context, 8)),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildFailureMaintenanceChart() {
    return StackedColumnChart(
      data: _failureMaintenanceData,
      maxY: 25,
      gridInterval: 5,
      minorTicksPerInterval: 1,
      verticalMinorTicksPerInterval: 1,
    );
  }

  Widget _buildPieChart() {
    return AspectRatio(
      aspectRatio: 1.0,
      child: CustomPaint(
        painter: _PieChartPainter(data: _pieChartData),
      ),
    );
  }

  Widget _buildPieChartLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12.0,
      runSpacing: 8.0,
      children: _pieChartData.map((item) {
        return _buildPieChartLegendItem(item.category, item.color);
      }).toList(),
    );
  }

  Widget _buildPieChartLegendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          CustText(
            name: text,
            size: 12,
            color: AppColors.textColor4,
          ),
        ],
      ),
    );
  }
}
class Legend extends StatelessWidget {
  final List<LegendItem> legends;

  const Legend({Key? key, required this.legends}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12.0,
      runSpacing: 8.0,
      children: legends.map((legend) {
        return _buildLegendItem(legend.text, legend.color, context);
      }).toList(),
    );
  }

  Widget _buildLegendItem(String text, Color color, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          CustText(
            name: text,
            size: Theme.of(context).textTheme.bodySmall!.fontSize! / 10, // Adjust size based on bodySmall
            color: Theme.of(context).textTheme.bodySmall!.color,
          ),
        ],
      ),
    );
  }
}

class LegendItem {
  final String text;
  final Color color;

  const LegendItem(this.text, this.color);
}

class StackedColumnChart extends StatelessWidget {
  final List<FailureMaintenanceData> data;
  final double maxY;
  final double gridInterval;
  final int minorTicksPerInterval;
  final int verticalMinorTicksPerInterval;

  const StackedColumnChart({
    Key? key,
    required this.data,
    this.maxY = 25,
    this.gridInterval = 5,
    this.minorTicksPerInterval = 1,
    this.verticalMinorTicksPerInterval = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.3,
      child: CustomPaint(
        painter: _StackedColumnChartPainter(
          data: data,
          maxY: maxY,
          gridInterval: gridInterval,
          minorTicksPerInterval: minorTicksPerInterval,
          verticalMinorTicksPerInterval: verticalMinorTicksPerInterval,
        ),
      ),
    );
  }
}

class _StackedColumnChartPainter extends CustomPainter {
  final List<FailureMaintenanceData> data;
  final double maxY;
  final double gridInterval;
  final int minorTicksPerInterval;
  final int verticalMinorTicksPerInterval;

  _StackedColumnChartPainter({
    required this.data,
    required this.maxY,
    required this.gridInterval,
    required this.minorTicksPerInterval,
    required this.verticalMinorTicksPerInterval,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = 40;
    final double rightPadding = 16;
    final double topPadding = 24;
    final double bottomPadding = 36;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double y = 0; y <= maxY; y += gridInterval) {
      final double yPos = topPadding + chartHeight * (1 - y / maxY);
      _drawDashedLine(
        canvas,
        Offset(leftPadding, yPos),
        Offset(leftPadding + chartWidth, yPos),
        gridPaint,
        dashArray: [3, 3],
      );
      final label = y == 0
          ? '0'
          : (y < 10 ? '0${y.toInt()}' : y.toInt().toString());
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: leftPadding - 4);
      tp.paint(canvas, Offset(leftPadding - tp.width - 4, yPos - tp.height / 2));
    }

    final int n = data.length;
    final double cellWidth = chartWidth / n;
    for (int i = 0; i <= n; i++) {
      final double x = leftPadding + i * cellWidth;
      _drawDashedLine(
        canvas,
        Offset(x, topPadding),
        Offset(x, topPadding + chartHeight),
        gridPaint,
        dashArray: [3, 3],
      );
    }

    if (verticalMinorTicksPerInterval > 0 && n > 1) {
      for (int i = 0; i < n; i++) {
        double xStart = leftPadding + i * cellWidth;
        double xEnd = leftPadding + (i + 1) * cellWidth;
        double interval = (xEnd - xStart) / (verticalMinorTicksPerInterval + 1);
        for (int t = 1; t <= verticalMinorTicksPerInterval; t++) {
          double minorX = xStart + t * interval;
          _drawDashedLine(
            canvas,
            Offset(minorX, topPadding),
            Offset(minorX, topPadding + chartHeight),
            Paint()
              ..color = Colors.grey.shade300
              ..strokeWidth = 1
              ..style = PaintingStyle.stroke,
            dashArray: [3, 3],
          );
        }
      }
    }

    final double barWidth = cellWidth * 0.6; // 60% of cell width
    final Map<String, List<int>> categoryBarIndices = {};
    for (int i = 0; i < data.length; i++) {
      final cat = data[i].category;
      categoryBarIndices.putIfAbsent(cat, () => []).add(i);
    }
    for (int i = 0; i < n; i++) {
      final FailureMaintenanceData d = data[i];
      final double xCenter = leftPadding + (i + 0.5) * cellWidth;

      final double pendingHeight = chartHeight * (d.pending / maxY);
      final double closedHeight = chartHeight * (d.closed / maxY);

      final double barBottom = topPadding + chartHeight;
      final double barTopPending = barBottom - pendingHeight;
      final double barTopClosed = barTopPending - closedHeight;

      final pendingRect = Rect.fromLTWH(
        xCenter - barWidth / 2,
        barTopPending,
        barWidth,
        pendingHeight,
      );
      final pendingPaint = Paint()..color = AppColors.barColor4;
      canvas.drawRect(pendingRect, pendingPaint);

      final closedRect = Rect.fromLTWH(
        xCenter - barWidth / 2,
        barTopClosed,
        barWidth,
        closedHeight,
      );
      final closedPaint = Paint()..color =  AppColors.barColor1;
      canvas.drawRect(closedRect, closedPaint);
    }
    int categoryCount = 0;
    categoryBarIndices.forEach((cat, indices) {
      if (indices.length == 2) {
        double x1 = leftPadding + (indices[0] + 0.5) * cellWidth;
        double x2 = leftPadding + (indices[1] + 0.5) * cellWidth;
        double labelCenter = (x1 + x2) / 2;
        final textSpan = TextSpan(
          text: cat,
          style: const TextStyle(color: Colors.black, fontSize: 12),
        );
        final tp = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: cellWidth * 2);
        tp.paint(
          canvas,
          Offset(
            labelCenter - tp.width / 2,
            topPadding + chartHeight + 4,
          ),
        );
        categoryCount++;
      }
    });
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      {List<double> dashArray = const [5, 5]}) {
    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double distance = sqrt(dx * dx + dy * dy);
    double dashLength = dashArray[0];
    double gapLength = dashArray[1];
    double progress = 0.0;

    while (progress < distance) {
      final double x1 = start.dx + (dx * progress / distance);
      final double y1 = start.dy + (dy * progress / distance);
      progress += dashLength;
      if (progress > distance) progress = distance;
      final double x2 = start.dx + (dx * progress / distance);
      final double y2 = start.dy + (dy * progress / distance);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      progress += gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class _PieChartPainter extends CustomPainter {
  final List<PieChartData> data;

  _PieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double outerRadius = min(centerX, centerY) * 0.8;
    final double innerRadius = outerRadius * 0.6;
    final double strokeWidth = outerRadius - innerRadius;

    // Calculate the total value for percentage calculation
    final int totalValue = data.fold(0, (sum, item) => sum + item.value);

    double startAngle = -pi / 2; // Start from the top (12 o'clock)

    for (int i = 0; i < data.length; i++) {
      final PieChartData item = data[i];
      if (item.value > 0) { // Only draw segments with values > 0
        final double sweepAngle = (item.value / totalValue) * 2 * pi;

        final Paint paint = Paint()
          ..color = item.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

        canvas.drawArc(
          Rect.fromCircle(center: Offset(centerX, centerY), radius: outerRadius - strokeWidth / 2),
          startAngle,
          sweepAngle,
          false,
          paint,
        );

        final double labelAngle = startAngle + sweepAngle / 2;
        final double labelRadius = outerRadius + 20;
        final double labelX = centerX + labelRadius * cos(labelAngle);
        final double labelY = centerY + labelRadius * sin(labelAngle);

        final textSpan = TextSpan(
          text: item.value.toString(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
        );

        startAngle += sweepAngle;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}