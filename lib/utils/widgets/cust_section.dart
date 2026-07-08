import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/app_constants.dart';
import 'cust_text.dart';

class CustSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool isVisible;

  const CustSection({
    Key? key,
    required this.title,
    required this.child,
    this.trailing,
    this.isVisible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.sectionSpacing),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppConstants.verticalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustText(
                   name: title,
                    size: AppConstants.textSize,
                    fontWeightName: FontWeight.w600,
                    color: AppColors.orangeColor,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (isVisible) ...[
              const SizedBox(height: AppConstants.elementSpacing),
              child,
            ],
          ],
        ),
      ),
    );
  }
}
