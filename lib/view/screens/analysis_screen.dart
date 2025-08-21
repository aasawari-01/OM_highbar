import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/size_config.dart';

import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/custom_drawer.dart';

// Data class for Pie Chart
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
          const SizedBox(height: 18),
            // Pie Chart Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: CustText(
                          name: 'Department wise Service Affecting Failure',
                          size: 2.0,
                          maxLines: 2,
                          color: AppColors.textColor3,
                          fontWeightName: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xff0089BA), size: 16),
                          const SizedBox(width: 4),
                          CustText(
                            name: 'Last 30 days',
                            size: 1.2,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
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
                  const SizedBox(height: 18),
                  // Failure Maintenance Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustText(
                        name: 'Failure Maintenance',
                        size: 2.0,
                        color: AppColors.textColor3,
                        fontWeightName: FontWeight.w600,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xff0089BA), size: 16),
                          const SizedBox(width: 4),
                          CustText(
                            name: 'Last 30 days',
                            size: 1.2,
                            color: AppColors.textColor4,
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: AppColors.textColor4, size: 18),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.white1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
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
                   SizedBox(height: 8 * SizeConfig.heightMultiplier),
                  // Scheduled Maintenance Section
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     CustText(
                  //       name: 'Scheduled Maintenance',
                  //       size: 2.0,
                  //       color: AppColors.textColor3,
                  //       fontWeightName: FontWeight.w600,
                  //     ),
                  //     Row(
                  //       children: [
                  //         const Icon(Icons.calendar_today, color: Color(0xffEF7E01), size: 16),
                  //         const SizedBox(width: 4),
                  //         CustText(
                  //           name: 'Last 30 days',
                  //           size: 1.2,
                  //           color: AppColors.textColor4,
                  //         ),
                  //         const Icon(Icons.keyboard_arrow_down, color: AppColors.textColor4, size: 18),
                  //       ],
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 8),
                  // Card(
                  //   color: AppColors.white1,
                  //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  //   elevation: 1,
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(12.0),
                  //     child: Column(
                  //       children: [
                  //         SizedBox(
                  //           height: 180,
                  //           child: _buildScheduledMaintenanceChart(),
                  //         ),
                  //         const SizedBox(height: 8),
                  //         Legend(
                  //           legends: const [
                  //             LegendItem('Completed', AppColors.barColor1),
                  //             LegendItem('Ongoing', AppColors.barColor4),
                  //             LegendItem('Overdue', AppColors.barColor5),
                  //           ],
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String count, Gradient gradient) {
    return Card(
      color: Color(0xffFBFBFB),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right:16,),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 40, // Adjust height as needed
              decoration: BoxDecoration(
                gradient: gradient, // Use the gradient here
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10),bottomLeft: Radius.circular(10)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: CustText(
                name: title,
                size: 1.4, // Corresponds to fontSize: 14
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: CustText(
                name: count,
                size: 2.4, // Corresponds to fontSize: 24
                color: Colors.black,
              ),
            ),
            Expanded(
              flex: 1,
              child: const Icon(
                TablerIcons.circle_dashed_check,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, String title, Widget chartWidget, Widget legendWidget) {
    return Card(
      color: AppColors.white1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustText(
                    name: title,
                    size: 1.4, // Corresponds to fontSize: 14
                    fontWeightName: FontWeight.w700,
                    color: Colors.black,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today, color:AppColors.barColor1,size: 16), // Calendar icon from image
                const SizedBox(width: 4),
                CustText(
                  name: 'Last 30 days', // Text from image
                  size: Theme.of(context).textTheme.bodySmall!.fontSize! / 10, // Assuming bodySmall fontSize is around 12-14
                  color: Theme.of(context).textTheme.bodySmall!.color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180, // Decrease this value for a shorter chart
              child: chartWidget,
            ),
            const SizedBox(height: 8),
            legendWidget, // Add the legend widget here
          ],
        ),
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

  Widget _buildScheduledMaintenanceChart() {
    return AspectRatio(
      aspectRatio: 2.3,
      child: CustomPaint(
        painter: _ScheduledMaintenanceSingleBarChartPainter(
          data: _scheduledMaintenanceData,
          maxY: 100,
          gridInterval: 25,
        ),
      ),
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
            size: 1.2,
            color: AppColors.textColor4,
          ),
        ],
      ),
    );
  }
}

// Helper widget for displaying legend items
class Legend extends StatelessWidget {
  final List<LegendItem> legends;

  const Legend({Key? key, required this.legends}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center, // Optional: Centers the items if they wrap
      spacing: 12.0, // Horizontal space between items
      runSpacing: 8.0, // Vertical space between lines if they wrap
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
          // Using bodySmall as a likely alternative to deprecated bodyText2
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
      aspectRatio: 2.3, // Adjust for a more square grid
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
    // Adjust these paddings to match your image
    final double leftPadding = 40;
    final double rightPadding = 16;
    final double topPadding = 24;
    final double bottomPadding = 36;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    // Y grid lines (major)
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
      // Y labels
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

    // X grid lines (major)
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

    // X grid lines (minor)
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

    // Draw bars
    final double barWidth = cellWidth * 0.6; // 60% of cell width
    // Group bars by category
    final Map<String, List<int>> categoryBarIndices = {};
    for (int i = 0; i < data.length; i++) {
      final cat = data[i].category;
      categoryBarIndices.putIfAbsent(cat, () => []).add(i);
    }
    for (int i = 0; i < n; i++) {
      final FailureMaintenanceData d = data[i];
      final double xCenter = leftPadding + (i + 0.5) * cellWidth;

      // Pending (bottom)
      final double pendingHeight = chartHeight * (d.pending / maxY);
      final double closedHeight = chartHeight * (d.closed / maxY);

      final double barBottom = topPadding + chartHeight;
      final double barTopPending = barBottom - pendingHeight;
      final double barTopClosed = barTopPending - closedHeight;

      // Pending rectangle (no border radius)
      final pendingRect = Rect.fromLTWH(
        xCenter - barWidth / 2,
        barTopPending,
        barWidth,
        pendingHeight,
      );
      final pendingPaint = Paint()..color = AppColors.barColor4;
      canvas.drawRect(pendingRect, pendingPaint);

      // Closed rectangle (no border radius)
      final closedRect = Rect.fromLTWH(
        xCenter - barWidth / 2,
        barTopClosed,
        barWidth,
        closedHeight,
      );
      final closedPaint = Paint()..color =  AppColors.barColor1;
      canvas.drawRect(closedRect, closedPaint);

      // (no label here)
    }
    // Draw category labels (one per pair)
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

class _ScheduledMaintenanceSingleBarChartPainter extends CustomPainter {
  final List<ScheduledMaintenanceData> data;
  final double maxY;
  final double gridInterval;

  _ScheduledMaintenanceSingleBarChartPainter({
    required this.data,
    required this.maxY,
    required this.gridInterval,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = 40;
    final double rightPadding = 16;
    final double topPadding = 24;
    final double bottomPadding = 36;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    // Draw horizontal grid lines (major)
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
      // Draw Y labels
      final label = y == 0
          ? '0'
          : y.toInt().toString();
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

    // Draw vertical dashed lines between bars
    final int n = data.length;
    final double barSpaceWidth = chartWidth / n; // Total horizontal space allocated for each bar + its surrounding gaps

    // Draw vertical dashed lines between the bar spaces (n-1 lines)
    for (int i = 0; i < n - 1; i++) { // Draw lines AFTER each bar space, except the last one
      final double x = leftPadding + (i + 1) * barSpaceWidth;
      _drawDashedLine(
        canvas,
        Offset(x, topPadding),
        Offset(x, topPadding + chartHeight),
        gridPaint,
        dashArray: [3, 3],
      );
    }

    // Draw bars
    // Calculate bar width as a percentage of the allocated space, leaving small margins for centering
    // Adjust this percentage (e.g., 0.6 to 0.8) to control bar thickness and the gap around it
    final double barWidth = barSpaceWidth * 0.7; // Using 70% of the allocated space for the bar
    final double barOffset = (barSpaceWidth - barWidth) / 2; // This calculates the gap on each side of the bar

    for (int i = 0; i < n; i++) {
      final ScheduledMaintenanceData d = data[i];
      // Position the bar centered within its allocated space (barSpaceWidth)
      final double barStartX = leftPadding + i * barSpaceWidth + barOffset;

      _drawBar(
        canvas,
        barStartX,
        d.value.toDouble(),
        chartHeight,
        topPadding,
        maxY,
        barWidth,
        d.color,
      );

      // Draw label below the bar
       final textSpan = TextSpan(
        text: d.label,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: barSpaceWidth); // Ensure label doesn't exceed the bar's allocated space
      tp.paint(
        canvas,
        Offset(
          // Center the label horizontally within its allocated barSpaceWidth
          leftPadding + i * barSpaceWidth + (barSpaceWidth - tp.width) / 2,
          topPadding + chartHeight + 4, // Position below the chart area
        ),
      );
    }

    // Draw dashed border around the chart area
    final borderRect = Rect.fromLTWH(
      leftPadding,
      topPadding,
      chartWidth,
      chartHeight,
    );
    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _drawDashedRect(canvas, borderRect, borderPaint, dashArray: [3, 3]);
  }

  void _drawBar(Canvas canvas, double x, double value, double chartHeight, double topPadding, double maxY, double barWidth, Color color) {
    final double barBottom = topPadding + chartHeight;
    final double barTop = barBottom - chartHeight * (value / maxY);
    final barRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(
        x,
        barTop, // Ensure barTop is not below topPadding
        barWidth,
        barBottom - barTop, // Ensure height is not negative
      ),
      topLeft: Radius.circular(4),
      topRight: Radius.circular(4),
      bottomLeft: Radius.circular(0),
      bottomRight: Radius.circular(0),
    );
    final paint = Paint()..color = color;
    canvas.drawRRect(barRect, paint);
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

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint, {List<double> dashArray = const [5, 5]}) {
    // Top
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint, dashArray: dashArray);
    // Right
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint, dashArray: dashArray);
    // Bottom
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint, dashArray: dashArray);
    // Left
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint, dashArray: dashArray);
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

    // Draw the donut segments
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

        // Draw segment labels
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

    // Draw the center total
    final centerTextSpan = TextSpan(
      text: totalValue.toString(),
      style: const TextStyle(
        color: Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
    // final centerTextPainter = TextPainter(
    //   // text: centerTextSpan,
    //   textAlign: TextAlign.center,
    //   textDirection: TextDirection.ltr,
    // )..layout();

    // centerTextPainter.paint(
    //   canvas,
    //   Offset(centerX - centerTextPainter.width / 2, centerY - centerTextPainter.height / 2),
    // );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}