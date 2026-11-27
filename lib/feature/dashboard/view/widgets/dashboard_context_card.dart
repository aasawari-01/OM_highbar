import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/core/controller/session_controller.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';

import 'dashboard_card.dart';

/// Who is logged in, and the role / department (and station / depot) the
/// dashboard is showing. It follows the drawer's selection.
class DashboardContextCard extends StatelessWidget {
  const DashboardContextCard({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final name = session.userName.value.trim();
      final designation = session.designationName.value.trim();
      final role = session.selectedRole.value?.roleDescr?.trim() ?? '';
      final dept = session.selectedDepartment.value?.deptName?.trim() ?? '';
      final station = session.selectedStationName.value?.trim() ?? '';
      final depot = session.selectedDepotName.value?.trim() ?? '';

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppConstants.elementSpacing),
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFF2A15C), AppColors.orangeColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.white1.withValues(alpha: 0.2),
                  child: CustText(
                    name: session.userInitials,
                    size: AppConstants.textSize,
                    color: AppColors.white1,
                    fontWeightName: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustText(
                        name: name.isEmpty ? 'Welcome' : 'Hello, $name',
                        size: AppConstants.textSize,
                        color: AppColors.white1,
                        fontWeightName: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (designation.isNotEmpty)
                        CustText(
                          name: designation,
                          size: AppConstants.subtitleSize,
                          color: AppColors.white1.withValues(alpha: 0.85),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing - 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (role.isNotEmpty)
                  _onDark(TablerIcons.user_shield, role),
                if (dept.isNotEmpty) _onDark(TablerIcons.building, dept),
                if (station.isNotEmpty)
                  _onDark(TablerIcons.map_pin, station),
                if (depot.isNotEmpty) _onDark(TablerIcons.building_warehouse, depot),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _onDark(IconData icon, String label) => DashboardChip(
        label: label,
        icon: icon,
        color: AppColors.textDarkPrimary,
      );
}
