import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'utils/size_config.dart';
import 'widgets/cust_text.dart';
import 'widgets/custom_app_bar.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomAppBar(
          title: 'Notifications',
          showDrawer: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 12),
          child: CustText(
            name: "Recent Notifications",
            size: 2,
            color: AppColors.textColor3,
            fontWeightName: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2 * SizeConfig.heightMultiplier),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 0),
            children: [
              _notificationCard(
                title: "System Update",
                message: "The app will be updated tonight at 2:00 AM.",
                time: "Just now",
              ),
              _notificationCard(
                title: "New Task Assigned",
                message: "You have been assigned a new inspection task.",
                time: "10 min ago",
              ),
              _notificationCard(
                title: "Feedback Received",
                message: "A new feedback has been submitted by a user.",
                time: "1 hour ago",
              ),
              _notificationCard(
                title: "Maintenance Alert",
                message: "Scheduled maintenance on 20/06/2025.",
                time: "Yesterday",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _notificationCard({required String title, required String message, required String time}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        color: AppColors.white1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          title: CustText(
            name: title,
            size: 1.7,
            color: AppColors.textColor5,
            fontWeightName: FontWeight.w600,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustText(
                name: message,
                size: 1.5,
                color: AppColors.textColor,
              ),
              const SizedBox(height: 4),
              CustText(
                name: time,
                size: 1.3,
                color: AppColors.hintTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 