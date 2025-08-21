import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'utils/size_config.dart';
import 'widgets/cust_text.dart';
import 'widgets/custom_app_bar.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 12),
          child: CustText(
            name: "Today's Tasks",
            size: 2,
            color: AppColors.textColor3,
            fontWeightName: FontWeight.w500,
          ),
        ),
         SizedBox(height: 2 * SizeConfig.heightMultiplier),
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
              color: AppColors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustText(
              name: status,
              size: 1.4,
              color: AppColors.orange,
              fontWeightName: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
} 