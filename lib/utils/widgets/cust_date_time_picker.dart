import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../constants/app_constants.dart';
import '../../utils/responsive_helper.dart';
import 'cust_text.dart';
import 'cust_textfield.dart';

enum PickerType { date, time, dateTime }

class CustDateTimePicker extends StatelessWidget {
  final String label;
  final String hint;
  final DateTime? selectedDateTime;
  final ValueChanged<DateTime?> onDateTimeSelected;
  final PickerType pickerType;
  final DateFormat? dateFormat;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final String? Function(String?)? validator;

  const CustDateTimePicker({
    Key? key,
    required this.label,
    required this.hint,
    this.selectedDateTime,
    required this.onDateTimeSelected,
    this.pickerType = PickerType.dateTime,
    this.dateFormat,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.validator,
  }) : super(key: key);

  ThemeData _pickerTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.orangeColor,
        onPrimary: Colors.white,
        onSurface: AppColors.textDarkPrimary,
        surface: Colors.white,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.orangeColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    if (pickerType == PickerType.time) {
      // Time only
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
        builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
      );
      if (picked != null) {
        final base = selectedDateTime ?? DateTime.now();
        onDateTimeSelected(
            DateTime(base.year, base.month, base.day, picked.hour, picked.minute));
      }
    } else if (pickerType == PickerType.date) {
      // Date only
      DateTime initial = selectedDateTime ?? DateTime.now();
      if (firstDate != null && initial.isBefore(firstDate!)) initial = firstDate!;
      if (lastDate != null && initial.isAfter(lastDate!)) initial = lastDate!;
      
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: firstDate ?? DateTime(2000),
        lastDate: lastDate ?? DateTime(2100),
        builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
      );
      if (picked != null) onDateTimeSelected(picked);
    } else {
      // Date first → then Time
      DateTime initial = selectedDateTime ?? DateTime.now();
      if (firstDate != null && initial.isBefore(firstDate!)) initial = firstDate!;
      if (lastDate != null && initial.isAfter(lastDate!)) initial = lastDate!;

      final pickedDate = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: firstDate ?? DateTime(2000),
        lastDate: lastDate ?? DateTime(2100),
        builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
      );
      if (pickedDate == null) return;

      // ignore: use_build_context_synchronously
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
        builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
      );

      final time = pickedTime ?? const TimeOfDay(hour: 0, minute: 0);
      onDateTimeSelected(DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayText = '';
    if (selectedDateTime != null) {
      if (pickerType == PickerType.date) {
        displayText = dateFormat?.format(selectedDateTime!) ??
            DateFormat('dd/MM/yyyy').format(selectedDateTime!);
      } else if (pickerType == PickerType.time) {
        displayText = DateFormat('hh:mm a').format(selectedDateTime!);
      } else {
        displayText =
            DateFormat('dd/MM/yyyy hh:mm a').format(selectedDateTime!);
      }
    }

    final IconData suffixIcon =
        pickerType == PickerType.time ? TablerIcons.clock : TablerIcons.calendar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildRequiredLabel(context, label),
        SizedBox(height: ResponsiveHelper.spacing(context, AppConstants.labelSpacing)),
        InkWell(
          onTap: enabled ? () => _pickDateTime(context) : null,
          child: AbsorbPointer(
            child: CustomTextField(
              controller: TextEditingController(text: displayText),
              hintText: hint,
              enabled: enabled,
              readOnly: true,
              validator: validator,
              suffixIcon: Icon(suffixIcon,
                  size: 20,
                  color: enabled ? AppColors.iconColor : Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}

