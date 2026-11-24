import 'package:flutter/material.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';

/// Gradients of the stat tiles (the app's existing dashboard colours).
class DashboardGradients {
  DashboardGradients._();

  static const List<Color> blue = [Color(0xFF9FD5FF), Color(0xFF6AA9FF)];
  static const List<Color> purple = [Color(0xFFD3B2FF), Color(0xFF9B6BFF)];
  static const List<Color> orange = [Color(0xFFF8D895), AppColors.orangeColor];
  static const List<Color> green = [AppColors.barColor7, AppColors.green];
}

/// The colour a failure status is shown in.
Color dashboardStatusColor(String status) {
  final s = status.toLowerCase();
  if (s.contains('close')) return AppColors.green1;
  if (s.contains('reject') || s.contains('deny') || s.contains('fail')) {
    return AppColors.red;
  }
  if (s.contains('pending') || s.contains('open') || s.contains('created')) {
    return AppColors.orangeColor;
  }
  return AppColors.darkBlue;
}

/// White rounded block with an orange title, as on the rest of the app.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.onTap,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppConstants.elementSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustText(
                        name: title,
                        size: AppConstants.textSize,
                        color: AppColors.orangeColor,
                        fontWeightName: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: AppConstants.subElementSpacing + 4),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small rounded label (role, department, status, queue kind ...).
class DashboardChip extends StatelessWidget {
  const DashboardChip({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.textDarkSecondary,
    this.filled = false,
  });

  final String label;
  final IconData? icon;
  final Color color;

  /// Filled chips have a tinted background, otherwise only a border.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.12) : AppColors.grey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: CustText(
              name: label,
              size: AppConstants.subtitleSize,
              color: color,
              fontWeightName: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
