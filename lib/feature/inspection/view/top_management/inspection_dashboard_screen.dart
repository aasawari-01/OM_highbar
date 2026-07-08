import 'package:flutter/material.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/widgets/cust_button.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';
import 'package:om_mobile/utils/widgets/custom_app_bar.dart';
import 'package:om_mobile/utils/widgets/sync_icon_button.dart';
import 'top_management_create_inspection_screen.dart';

class InspectionDashboardScreen extends StatelessWidget {
  const InspectionDashboardScreen({super.key});

  static const _categories = [
    _DashboardCategory(
      title: 'Scheduled Inspection',
      accentColor: Color(0xFF5D7FF5),
      pending: 10,
      completed: 5,
      overdue: 10,
    ),
    _DashboardCategory(
      title: 'Unscheduled Inspection',
      accentColor: Color(0xFF4CAC39),
      pending: 10,
      completed: 5,
      overdue: 10,
    ),
    _DashboardCategory(
      title: 'Joint Dept. Scheduled Inspection',
      accentColor: Color(0xFFFF8C1A),
      pending: 10,
      completed: 5,
      overdue: 10,
    ),
    _DashboardCategory(
      title: 'Joint Dept. Unscheduled Inspection',
      accentColor: Color(0xFFE8A0BF),
      pending: 10,
      completed: 5,
      overdue: 10,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'Inspection Dashboard',
        showDrawer: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: const SyncIconButton(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppConstants.screenPadding),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppConstants.elementSpacing),
                itemBuilder: (context, index) => _DashboardCard(category: _categories[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.screenPadding,
                AppConstants.elementSpacing,
                AppConstants.screenPadding,
                AppConstants.screenPadding,
              ),
              child: CustButton(
                name: 'Create Inspection',
                size: double.infinity,
                sHeight: AppConstants.buttonHeight,
                onSelected: (_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TopManagementCreateInspectionScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCategory {
  final String title;
  final Color accentColor;
  final int pending;
  final int completed;
  final int overdue;

  const _DashboardCategory({
    required this.title,
    required this.accentColor,
    required this.pending,
    required this.completed,
    required this.overdue,
  });
}

class _DashboardCard extends StatelessWidget {
  final _DashboardCategory category;

  const _DashboardCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white1,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: category.accentColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppConstants.cardRadius)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustText(
                      name: category.title,
                      size: AppConstants.formLabelSize,
                      fontWeightName: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppConstants.elementSpacing),
                    Row(
                      children: [
                        Expanded(child: _statItem('Pending', category.pending)),
                        Expanded(child: _statItem('Completed', category.completed)),
                        Expanded(child: _statItem('Overdue', category.overdue)),
                      ],
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

  Widget _statItem(String label, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: '$count',
          size: AppConstants.sectionHeaderSize,
          fontWeightName: FontWeight.w700,
          color: AppColors.orangeColor,
        ),
        const SizedBox(height: AppConstants.labelSpacing),
        CustText(
          name: label,
          size: AppConstants.detailLabelSize,
          color: AppColors.textDarkSecondary,
        ),
      ],
    );
  }
}
