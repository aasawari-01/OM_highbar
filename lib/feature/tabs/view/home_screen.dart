import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:om_mobile/feature/failure/view/create_failure_screen.dart';
import 'package:om_mobile/feature/failure/view/failure_list_screen.dart';
import '../../../constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../service/session_controller.dart';
import '../../../utils/responsive_helper.dart';
import '../../../utils/widgets/cust_text.dart';
import '../controller/home_controller.dart';



import '../../../utils/widgets/custom_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _homeController = Get.put(HomeController());
  final SessionController sessionController = Get.find<SessionController>();

  final PageController _pageController = PageController(viewportFraction: 0.5,  initialPage: 0,
  );
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: AppColors.appBarColor),
            child: Column(
              children: [
                SizedBox(height: ResponsiveHelper.height(context, 40)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Builder(
                        builder: (context) => GestureDetector(
                          child: Icon(
                            TablerIcons.menu_2,
                            color: AppColors.white1,
                            size: ResponsiveHelper.height(context, 30),
                          ),
                          onTap: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.width(context, 15)),
                      CustText(
                        name: "Dashboard",
                        size: AppConstants.sectionHeaderSize,
                        color: AppColors.white1,
                        fontWeightName: FontWeight.w400,
                      ),
                      const Spacer(),
                      Icon(
                        TablerIcons.bell,
                        color: AppColors.white1,
                        size: ResponsiveHelper.height(context, 30),
                      ),
                      SizedBox(width: ResponsiveHelper.width(context, 15)),
                       Icon(
                        Icons.filter_list,
                        color: AppColors.white2,
                        size: ResponsiveHelper.height(context, 30),
                      ),
                      SizedBox(width: ResponsiveHelper.width(context, 15)),
                      Stack(
                        children: [
                           CircleAvatar(
                            backgroundColor: AppColors.white1,
                            radius: ResponsiveHelper.height(context, 18),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: ResponsiveHelper.width(context, 12),
                              height: ResponsiveHelper.height(context, 12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveHelper.height(context, 20)),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Obx(() {
                      final isJE = sessionController.selectedRole.value?.roleDescr?.contains("Junior Engineer") == true;
                      final isTechnician = sessionController.selectedRole.value?.roleDescr?.contains("Technician") == true;
                      
                      final List<Map<String, dynamic>> headerCards = (isJE || isTechnician) ? const [
                        {
                          "title": "RST",
                          "count": 10,
                          "gradient": [Color(0xFF9FD5FF), Color(0xFF6AA9FF)],
                        },
                        {
                          "title": "Depot",
                          "count": 5,
                          "gradient": [Color(0xFFD3B2FF), Color(0xFF9B6BFF)],
                        },
                      ] : const [
                        {
                          "title": "Failure",
                          "count": 10,
                          "gradient": [Color(0xFF9FD5FF), Color(0xFF6AA9FF)],
                        },
                        {
                          "title": "Inspection",
                          "count": 5,
                          "gradient": [Color(0xFFD3B2FF), Color(0xFF9B6BFF)],
                        },
                      ];

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(AppConstants.screenPadding, AppConstants.sectionSpacing, AppConstants.screenPadding, 70),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: ResponsiveHelper.spacing(context, 110),
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: headerCards.length,
                                  padEnds: false,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    final data = headerCards[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: AppConstants.elementSpacing),
                                      child: _headerSummaryCard(
                                        title: data["title"] as String,
                                        count: data["count"] as int,
                                        gradient: (data["gradient"] as List<Color>),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.height(context, 12)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  headerCards.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: _currentPage == index ? 6 : 6,
                                    height: _currentPage == index ? 6 : 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentPage == index
                                          ? AppColors.orangeColor
                                          : Colors.grey[300],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.height(context, AppConstants.elementSpacing)),
                              
                              if (isJE) ..._buildJuniorEngineerTasks() 
                              else if (isTechnician) ..._buildTechnicianTasks()
                              else ..._buildStationControllerTasks(),
                              
                              SizedBox(height: ResponsiveHelper.height(context, 8)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _headerSummaryCard({
    required String title,
    required int count,
    required List<Color> gradient,
  }) {
    return Container(
      width: ResponsiveHelper.width(context, 150),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveHelper.width(context, 20),
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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustText(
                    name: title,
                    size: 18,
                    color: AppColors.textColor,
                    fontWeightName: FontWeight.w400,
                    maxLines: 1,
                  ),
                  CustText(
                    name: "$count",
                    size: AppConstants.sectionHeadervalue,
                    color: AppColors.textColor,
                    fontWeightName: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionBlock({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppConstants.cardPadding, AppConstants.cardPadding, AppConstants.cardPadding, 6),
      margin: const EdgeInsets.only(bottom: AppConstants.elementSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText(
            name: title,
            size: AppConstants.HeaderSize,
            color: AppColors.orangeColor,
            fontWeightName: FontWeight.w500,
          ),
          const SizedBox(height: AppConstants.elementSpacing),
          ...children,
        ],
      ),
    );
  }

  Widget _taskCard({
    required String title,
    String? subtitle,
    required String time,
    String? status,
    Color? badgeBgColor,
    Color? badgeTextColor,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 10.0 : 30.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(
                  name: title,
                  size: AppConstants.bodySize,
                  color: AppColors.textColor5,
                  fontWeightName: FontWeight.w400,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: ResponsiveHelper.height(context, 4)),
                  CustText(
                    name: subtitle,
                    size: AppConstants.subtitles,
                    color: AppColors.textColor,
                  ),
                ],
                SizedBox(height: ResponsiveHelper.height(context, 4)),
                CustText(
                  name: time,
                  size: AppConstants.subtitles,
                  color: AppColors.textColor4,
                ),
              ],
            ),
          ),
          if (status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBgColor ?? AppColors.textFieldColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustText(
                name: status,
                size: 11,
                color: badgeTextColor ?? AppColors.orangeColor,
                fontWeightName: FontWeight.w500,
              ),
            ),
        ],
      ),
      ),
    );
  }



  Widget failureStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Failure Maintenance Status",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColor,
                ),
              ),
              Icon(TablerIcons.calendar, size: 20, color:AppColors.textColor4),
            ],
          ),

          const SizedBox(height: 16),

          /// CHART
          SizedBox(
            height: ResponsiveHelper.height(context, 230),
            child: BarChart(
              BarChartData(
                maxY: 50,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color:AppColors.borderColor,
                    width: 1,
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(x: 0.5, color: Colors.grey.shade300, strokeWidth: 1, dashArray: [6, 4]),
                    VerticalLine(x: 1.5, color: Colors.grey.shade300, strokeWidth: 1, dashArray: [6, 4]),
                  ],
                ),

                /// dotted grid
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 10,
                  drawVerticalLine:false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
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
                        const labels = [
                          "ATS (CATs &\nLATs)",
                          "DATA COMM\nSystem",
                          "Interlocking\nSystem"
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: CustText(
                            name: labels[value.toInt()],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            size: 12,
                            color: AppColors.textColor,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),

                /// bars with background
                barGroups: [
                  _bar(0, 38, 10),
                  _bar(1, 16, 18),
                  _bar(2, 41, 8),
                ],
              ),
            ),
          ),

          SizedBox(height:  ResponsiveHelper.height(context, 16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem( AppColors.barColor6, "Line 1 Pending"),
              const SizedBox(width: 20),
              _legendItem(AppColors.barColor7, "Line 1 Closed"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF4A5568),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// helper for bars
  BarChartGroupData _bar(int x, double closed, double pending) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: closed + pending,
          width: 12,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(2),
          ),
          rodStackItems: [
            BarChartRodStackItem(0, closed, AppColors.barColor7),
            BarChartRodStackItem(closed, closed + pending, AppColors.barColor6),
          ],
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 50,
            color: const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStationControllerTasks() {
    return [
      // Pending Tasks
      _buildSectionBlock(
        title: "Pending Tasks",
        children: [
          _taskCard(
            title: "Inspection Checklist",
            subtitle: "Checklist",
            time: "18/06/2025 10:00 AM",
            status: "Pending",
            badgeBgColor: AppColors.buttonColor2,
            badgeTextColor: Colors.black87,
          ),
          _taskCard(
            title: "Station Failure",
            subtitle: "Failure in Station 1",
            time: "18/06/2025 10:05 AM",
            status: "Pending",
            badgeBgColor: AppColors.buttonColor2,
            badgeTextColor: Colors.black87,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateFailureScreen(failureType: "Station")));
            },
          ),
          _taskCard(
            title: "Safety Security Checklist",
            subtitle: "Checklist",
            time: "18/06/2025 11:00 AM",
            status: "Pending",
            badgeBgColor: AppColors.buttonColor2,
            badgeTextColor: Colors.black87,
            isLast: true,
          ),
        ],
      ),

      // Today's Tasks
      _buildSectionBlock(
        title: "Today's Tasks",
        children: [
          _taskCard(
            title: "PTW",
            subtitle: "Approval Task",
            time: "18/06/2025 10:00 AM",
            status: "Approval",
            badgeBgColor: const Color(0xFFD6F2CB),
            badgeTextColor: Colors.black87,
          ),
          _taskCard(
            title: "Station Failure",
            subtitle: "Failure in Station 1",
            time: "18/06/2025 10:05 AM",
            status: "Create Failure",
            badgeBgColor: Colors.grey[200],
            badgeTextColor: Colors.black87,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateFailureScreen(failureType: "Station")));
            },
          ),
          _taskCard(
            title: "Safety Security Checklist",
            subtitle: "Checklist",
            time: "18/06/2025 11:00 AM",
            status: "Approval",
            badgeBgColor: const Color(0xFFD6F2CB),
            badgeTextColor: Colors.black87,
            isLast: true,
          ),
        ],
      ),

      // OCC Instructions
      _buildSectionBlock(
        title: "Instruction from OCC",
        children: [
          _taskCard(
            title: "Power Supply",
            subtitle: "Approval Task",
            time: "18/06/2025 10:00 AM",
            status: "Acknowledge",
            badgeBgColor: AppColors.orangeColor,
            badgeTextColor: Colors.white,
          ),
          _taskCard(
            title: "Station Failure",
            subtitle: "Failure in Station 1",
            time: "18/06/2025 10:05 AM",
            status: "Approve",
            badgeBgColor: AppColors.orangeColor,
            badgeTextColor: Colors.white,
            isLast: true,
          ),
        ],
      ),
      
      const SizedBox(height: 16),
      failureStatusCard(),
    ];
  }

  List<Widget> _buildJuniorEngineerTasks() {
    return [
      // Pending Tasks
      _buildSectionBlock(
        title: "Pending Tasks",
        children: [
          _taskCard(
            title: "Inspection Checklist",
            subtitle: "Checklist",
            time: "18/06/2025 10:00 AM",
            status: "Pending",
            badgeBgColor: AppColors.buttonColor2,
            badgeTextColor: Colors.black87,
          ),
          _taskCard(
            title: "RST Failure",
            subtitle: "Part D",
            time: "18/06/2025 10:05 AM",
            status: "Pending",
            badgeBgColor: AppColors.buttonColor2,
            badgeTextColor: Colors.black87,
          ),
          _taskCard(
            title: "Maintenance Failure",
            subtitle: "Checklist",
            time: "18/06/2025 11:00 AM",
            status: "Pending",
            badgeBgColor: AppColors.buttonColor2,
            badgeTextColor: Colors.black87,
            isLast: true,
            onTap: () => Get.to(FailureListScreen()),
          ),
        ],
      ),

      // Today's Tasks
      _buildSectionBlock(
        title: "Today's Tasks",
        children: [
          _taskCard(
            title: "Failure No.: SIG/11-2025-004",
            time: "18/06/2025 10:00 AM",
          ),
          _taskCard(
            title: "Unscheduled Inspection",
            time: "18/06/2025 10:05 AM",
          ),
          _taskCard(
            title: "Safety Security Checklist",
            subtitle: "Checklist",
            time: "18/06/2025 11:00 AM",
          ),
          _taskCard(
            title: "RST Failure",
            time: "18/06/2025 10:05 AM",
            isLast: true,
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildTechnicianTasks() {
    return [
      // Pending Tasks
      _buildSectionBlock(
        title: "Pending Tasks",
        children: [
          _taskCard(
            title: "Inspection Checklist",
            subtitle: "Checklist",
            time: "18/06/2025 10:00 AM",
            status: "Pending",
            badgeBgColor: AppColors.buttonColor2,
            badgeTextColor: Colors.black87,
          ),
          _taskCard(
            title: "Station Failure",
            subtitle: "Failure in Station 1",
            time: "18/06/2025 10:05 AM",
            status: "Pending",
            badgeBgColor: AppColors.buttonColor2,
            badgeTextColor: Colors.black87,
          ),
          _taskCard(
            title: "Maintenance Failure",
            subtitle: "Checklist",
            time: "18/06/2025 11:00 AM",
            status: "Pending",
            badgeBgColor: AppColors.buttonColor2,
            badgeTextColor: Colors.black87,
            isLast: true,
          ),
        ],
      ),

      // Today's Tasks
      _buildSectionBlock(
        title: "Today's Tasks",
        children: [
          _taskCard(
            title: "Failure No.: SIG/11-2025-004",
            time: "18/06/2025 10:00 AM",
          ),
          _taskCard(
            title: "Unscheduled Inspection",
            time: "18/06/2025 10:05 AM",
          ),
          _taskCard(
            title: "Safety Security Checklist",
            subtitle: "Checklist",
            time: "18/06/2025 11:00 AM",
          ),
          _taskCard(
            title: "RST Failure",
            time: "18/06/2025 10:05 AM",
            isLast: true,
          ),
        ],
      ),
    ];
  }

}