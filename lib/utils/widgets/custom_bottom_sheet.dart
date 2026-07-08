import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';

import 'cust_text.dart';

class CustomBottomSheetOption {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final double size;
  final FontWeight? fontWeight;
  final Color? textDarkPrimary;

  CustomBottomSheetOption({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.onTap,
    this.size = 1.6,
    this.fontWeight = FontWeight.w500,
    this.textDarkPrimary = AppColors.textDarkPrimary,
  });
}

class CustomBottomSheet {
  static void show({
    required BuildContext context,
    required String title,
    required List<CustomBottomSheetOption> options,
    Color? titleColor = AppColors.black,
    FontWeight? titleFontWeight = FontWeight.w600,
    double titleSize = 1.6,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustText(
              name: title,
              size: titleSize,
              color: titleColor,
              fontWeightName: titleFontWeight,
            ),
            const SizedBox(height: 16),
            ...options.map((option) => ListTile(
              leading: Icon(
                option.icon,
                color: option.iconColor ?? AppColors.gradientEnd,
              ),
              title: CustText(
                name: option.title,
                size: option.size,
                fontWeightName: option.fontWeight,
                color: option.textDarkPrimary,
              ),
              dense: true,
              onTap: () {
                Navigator.pop(context);
                option.onTap();
              },
            )).toList(),
          ],
        ),
      ),
    );
  }
}
