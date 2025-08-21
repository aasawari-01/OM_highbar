import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'constants/colors.dart';
import 'widgets/cust_text.dart';
import 'widgets/custom_drawer.dart';
import 'station_diary_screen.dart';
import 'create_failure_screen.dart';
import 'station_failure_screen.dart';
import 'inspection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.appBarColor,
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(30)),
          ),
          child: Column(
            children: [
              SizedBox(height: 4 * SizeConfig.heightMultiplier),
              Row(
                children: [
                  Builder(
                    builder: (context) => GestureDetector(
                      child: const Icon(TablerIcons.menu_2, color: AppColors.white2),
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  SizedBox(width: 2 * SizeConfig.widthMultiplier),
                  CustText(
                    name: "Welcome, Rohan Sharma!",
                    size: 2.2,
                    color: AppColors.white2,
                    fontWeightName: FontWeight.w400,
                  ),
                  Spacer(),
                  const Icon(TablerIcons.user_circle, color: AppColors.white2),
                ],
              ),
              SizedBox(height: 3 * SizeConfig.heightMultiplier),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _registerCard(
                      title: "Complaint Register",
                      newCount: "4",
                      pendingCount: "10",
                      closedCount: "2",
                    ),
                    SizedBox(width: 12),
                    _registerCard(
                      title: "OCC Failure Register",
                      newCount: "15",
                      pendingCount: "20",
                      closedCount: "3",
                    ),
                    SizedBox(width: 12),
                    _registerCard(
                      title: "Station Failure Register",
                      newCount: "12",
                      pendingCount: "10",
                      closedCount: "6",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustText(
                    name: "Quick Actions",
                    size: 2.1,
                    color: AppColors.textColor3,
                    fontWeightName: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1 * SizeConfig.heightMultiplier),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    color: AppColors.white1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _quickAction("assets/images/home_image/img1.png", "Shift\nDiary"),
                          _quickAction("assets/images/home_image/img2.png", "Create\nFailure"),
                          _quickAction("assets/images/home_image/img3.png", "Station\nFailure"),
                          _quickAction("assets/images/home_image/img4.png", "Inspection"),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustText(
                    name: "Today's Tasks",
                    size: 2,
                    color: AppColors.textColor3,
                    fontWeightName: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _taskCard(
                  title: "Inspection Checklist",
                  subtitle: "Checklist",
                  time: "18/06/2025 10:00 AM",
                  status: "Pending",
                ),
                _taskCard(
                  title: "TSR/18-2025/0025",
                  subtitle: "TSR Request",
                  time: "18/06/2025 10:05 AM",
                  status: "Pending",
                ),
                _taskCard(
                  title: "Safety Security Checklist",
                  subtitle: "Checklist",
                  time: "18/06/2025 11:00 AM",
                  status: "Pending",
                ),
                SizedBox(height: 10 * SizeConfig.heightMultiplier),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: iconBg,
            radius: 15,
            child: Icon(icon, color: iconColor, size: 20),
          ),
           SizedBox(width: 2 * SizeConfig.widthMultiplier),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustText(
                  name: title,
                  size: 1.3,
                  color: AppColors.textColor,
                  fontWeightName: FontWeight.w500,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5 * SizeConfig.heightMultiplier),
                CustText(
                  name: value,
                  size: 2.0,
                  color: AppColors.textColor,
                  fontWeightName: FontWeight.bold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCardHorizontal({
    required String title,
    required String newCount,
    required String pendingCount,
    required String closedCount,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText(
            name: title,
            size: 1.3,
            color: AppColors.textColor,
            fontWeightName: FontWeight.w500,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5 * SizeConfig.heightMultiplier),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  icon: TablerIcons.file_plus,
                  iconBg: AppColors.red.withOpacity(0.1),
                  iconColor: AppColors.red,
                  title: "New",
                  value: newCount,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  icon: TablerIcons.exclamation_circle,
                  iconBg: AppColors.yellow.withOpacity(0.1),
                  iconColor: AppColors.yellow,
                  title: "Pending",
                  value: pendingCount,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  icon: TablerIcons.circle_check,
                  iconBg: AppColors.green.withOpacity(0.1),
                  iconColor: AppColors.green,
                  title: "Closed",
                  value: closedCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(String image, String label) {
    return Builder(
      builder: (context) {
        void _onTap() {
          if (label == "Shift\nDiary") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StationDiaryScreen()));
          } else if (label == "Create\nFailure") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateFailureScreen()));
          } else if (label == "Station\nFailure") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StationFailureScreen()));
          } else if (label == "Inspection") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionScreen()));
          }
        }
        return GestureDetector(
          onTap: _onTap,
          child: Column(
            children: [
              Image.asset(image, height: 8 * SizeConfig.imageSizeMultiplier,),
              const SizedBox(height: 6),
              CustText(
                name: label,
                size: 1.6,
                color: AppColors.textColor,
                fontWeightName: FontWeight.w500,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _taskCard({required String title, required String subtitle, required String time, required String status}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Card(
        color: AppColors.white1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          title: CustText(
            name: title,
            size: 1.8,
            color: AppColors.textColor5,
            fontWeightName: FontWeight.w600,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustText(
                name: subtitle,
                size: 1.6,
                color: AppColors.textColor,
              ),
              CustText(
                name: time,
                size: 1.6,
                color: AppColors.hintTextColor,
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color:AppColors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustText(
              name: status,
              size: 1.4,
              color:AppColors.orange,
              fontWeightName: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _registerCard({
    required String title,
    required String newCount,
    required String pendingCount,
    required String closedCount,
  }) {
    return Builder(
      builder: (context) => Container(
        width: MediaQuery.of(context).size.width * 0.75,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustText(
             name: title,
              size: 1.6,
              fontWeightName: FontWeight.w600,
              color: AppColors.black,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statusIndicator(
                  count: newCount,
                  label: "New",
                  backgroundColor: AppColors.red.withOpacity(0.1),
                  color: AppColors.red,
                ),
                Container(
                  height: 6 *  SizeConfig.heightMultiplier,
                  width: 1.5,
                  color: AppColors.textFieldFillColor,
                ),
                _statusIndicator(
                  count: pendingCount,
                  label: "Pending",
                  backgroundColor: AppColors.orange.withOpacity(0.1),
                  color: AppColors.orange,
                ),
                Container(
                  height: 6 *  SizeConfig.heightMultiplier,
                  width: 1.5,
                  color: AppColors.textFieldFillColor,
                ),
                _statusIndicator(
                  count: closedCount,
                  label: "Closed",
                  backgroundColor: AppColors.green.withOpacity(0.1),
                  color: AppColors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIndicator({
    required String count,
    required String label,
    required Color backgroundColor,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustText(name: count, size: 1.8, color: AppColors.textColor, fontWeightName: FontWeight.w600),
        // SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: CustText(
            name: label,
             size: 1.4,
              color: color,
              fontWeightName: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}