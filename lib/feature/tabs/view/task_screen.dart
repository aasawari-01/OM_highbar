import 'package:flutter/material.dart';

import '../../../constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/responsive_helper.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/custom_app_bar.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomAppBar(
          title: "Today's Tasks",
          showDrawer: true,
          onLeadingPressed: () => Navigator.pop(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: AppConstants.elementSpacing),
          child: CustText.sectionHeader("Today's Tasks", color: AppColors.textColor3),
        ),
        const SizedBox(height: AppConstants.elementSpacing),
        _taskCard(
          title: "Inspection Checklist",
          subtitle: "Checklist",
          time: "18/06/2025 11:00 AM",
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
          time: "18/06/2025 10:00 AM",
          status: "Pending",
        ),
        const Spacer(),
      ],
    );
  }

  Widget _taskCard({required String title, required String subtitle, required String time, required String status}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: 4),
      child: Card(
        color: AppColors.white1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.cardRadius)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppConstants.cardPadding, vertical: 8),
          title: CustText(
            name: title,
            size: AppConstants.bodySize,
            color: AppColors.textColor5,
            fontWeightName: FontWeight.bold,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustText(
                name: subtitle,
                size: 16,
                color: AppColors.textColor,
              ),
              CustText(
                name: time,
                size: 16,
                color: AppColors.hintTextColor,
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.orangeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustText(
              name: status,
              size: 14,
              color: AppColors.orangeColor,
              fontWeightName: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
} 