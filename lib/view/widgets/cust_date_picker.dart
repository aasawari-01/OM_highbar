import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../constants/colors.dart';
import '../../utils/size_config.dart';
import 'cust_text.dart';
import 'cust_textfield.dart';
import 'package:intl/intl.dart';

class CustDatePicker extends StatelessWidget {
  final String label;
  final String hint;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;
  final DateFormat dateFormat;
  final DateTime firstDate;
  final DateTime lastDate;
  final VoidCallback? onTap;

  CustDatePicker({
    Key? key,
    required this.label,
    required this.hint,
    this.selectedDate,
    required this.onDateSelected,
    DateFormat? dateFormat,
    DateTime? firstDate,
    DateTime? lastDate,
    this.onTap,
  })  : dateFormat = dateFormat ?? DateFormat('dd/MM/yyyy'),
        firstDate = firstDate ?? DateTime(2000),
        lastDate = lastDate ?? DateTime(2100),
        super(key: key);

  static Future<DateTime?> showThemedDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.textColor3,
              onPrimary: Colors.white,
              onSurface: AppColors.textColor,
              secondary: AppColors.textColor3,
              onSecondary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayDate = selectedDate != null
        ? dateFormat.format(selectedDate!)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: label,
          size: 1.8,
          fontWeightName: FontWeight.w500,
        ),
        SizedBox(height: 1 * SizeConfig.heightMultiplier),
        InkWell(
          onTap: onTap ?? () async {
            final picked = await CustDatePicker.showThemedDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: firstDate,
              lastDate: lastDate,
            );
            if (picked != null) onDateSelected(picked);
          },
          child: AbsorbPointer(
            child:  CustomTextField(
              controller: TextEditingController(
                text: displayDate,
              ),
              hintText: hint,
              suffixIcon: const Icon(TablerIcons.calendar,size: 24,color: AppColors.textColor4,),
            ),
          ),
        ),
      ],
    );
  }
}