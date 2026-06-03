import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../utils/responsive_helper.dart';
import 'cust_text.dart';

class CustDataCard extends StatelessWidget {
  final List<DataCardItem> items;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final Widget? bottomAction;

  const CustDataCard({
    Key? key,
    required this.items,
    this.onDelete,
    this.onEdit,
    this.bottomAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white1,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.textFieldFillColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  runSpacing: 10,
                  spacing: 10,
                  children: items.map((item) {
                    final double width = item.isFullWidth
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 10) / 2;

                    return SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustText(
                            name: item.label,
                            size: 12,
                            color: Colors.grey.shade500,
                            fontWeightName: FontWeight.w400,
                          ),
                          const SizedBox(height: 2),
                          if (item.valueWidget != null)
                            item.valueWidget!
                          else
                            CustText(
                              name: item.value,
                              size: 14,
                              fontWeightName: FontWeight.bold,
                              color: Colors.black,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (onEdit != null || onDelete != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(TablerIcons.pencil, color: AppColors.orangeColor, size: 20),
                          onPressed: onEdit,
                          padding: const EdgeInsets.only(right: 12),
                          constraints: const BoxConstraints(),
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(TablerIcons.trash, color: Colors.grey, size: 20),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
                if (bottomAction != null) ...[
                  const SizedBox(height: AppConstants.elementSpacing),
                  bottomAction!,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class DataCardItem {
  final String label;
  final String value;
  final Widget? valueWidget;
  final bool isFullWidth;

  DataCardItem({
    required this.label,
    this.value = '',
    this.valueWidget,
    this.isFullWidth = false,
  });
}
