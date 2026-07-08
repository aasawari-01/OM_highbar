import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:om_mobile/constants/app_constants.dart';

import '../../constants/colors.dart';

class CustRadio<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String label;
  final ValueChanged<T?> onChanged;

  const CustRadio({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          selected?
          Icon(TablerIcons.circle_check_filled,color: AppColors.orangeColor,):Icon(TablerIcons.circle,color: AppColors.grey,),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.lato(
              color: AppColors.textDarkPrimary,
              fontSize: AppConstants.formLabelSize,
              // fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 