import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/colors.dart';

import '../../utils/size_config.dart';
import 'cust_text.dart';


class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 9.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all( // Add this to explicitly remove any border
            color: Colors.transparent,
            width: 0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(TablerIcons.smart_home, TablerIcons.smart_home, 'Home', 0),
            _buildNavItem(TablerIcons.clipboard_list,TablerIcons.clipboard_list, 'Task', 1),
            _buildNavItem(TablerIcons.bell,TablerIcons.bell, 'Notification', 2),
            _buildNavItem(TablerIcons.chart_donut, TablerIcons.chart_donut, "Analysis", 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData selectedIcon, String label, int index) {
    final isSelected = index == currentIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected?selectedIcon:icon,
              color: isSelected ? AppColors.textColor3 : AppColors.textColor4,
              size: 2.5* SizeConfig.heightMultiplier,
            ),
            SizedBox(height: 0.3 * SizeConfig.heightMultiplier,),
            CustText(
              name: label,
                size: 1.4,
                fontWeightName: FontWeight.w500,
                color: isSelected ? AppColors.textColor3 : AppColors.textColor4,
              ),
          ],
        ),
      ),
    );
  }
}