import 'package:flutter/material.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../../utils/widgets/cust_dropdown.dart';
import '../../../../utils/widgets/cust_textfield.dart';
import '../../../../utils/widgets/cust_date_time_picker.dart';
import '../../../../utils/widgets/cust_toggle.dart';
import 'form_field_config.dart';

class FormFieldWidgets {
  static Widget buildDropdown({
    required FormFieldConfig config,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    bool enabled = true,
    String hint = 'Select...',
    UserRole? currentUserRole,
  }) {
    final isEditable = !config.readOnly && 
        (currentUserRole == null || config.isEditableForRole(currentUserRole));
    
    return CustDropdown(
      label: '${config.label}${config.required ? ' *' : ''}',
      hint: hint,
      items: items,
      selectedValue: selectedValue,
      enabled: enabled && isEditable,
      onChanged: onChanged,
      validator: validator,
    );
  }

  static Widget buildTextField({
    required FormFieldConfig config,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool enabled = true,
    String? hintText,
    int? maxLines,
    TextInputType? keyboardType,
    UserRole? currentUserRole,
  }) {
    final isEditable = !config.readOnly && 
        (currentUserRole == null || config.isEditableForRole(currentUserRole));
    
    return CustomTextField(
      controller: controller,
      label: '${config.label}${config.required ? ' *' : ''}',
      hintText: hintText,
      maxLines: maxLines ?? 1,
      enabled: enabled && isEditable,
      validator: validator,
      keyboardType: keyboardType ?? config.keyboardType ?? TextInputType.text,
      maxLength: config.maxLength,
    );
  }

  static Widget buildDateTimePicker({
    required FormFieldConfig config,
    required DateTime? selectedDateTime,
    required ValueChanged<DateTime?> onDateTimeSelected,
    String? Function(DateTime?)? validator,
    bool enabled = true,
    String hint = 'Select date/time',
    UserRole? currentUserRole,
  }) {
    final isEditable = !config.readOnly && 
        (currentUserRole == null || config.isEditableForRole(currentUserRole));
    
    // Convert DateTime validator to String validator for CustDateTimePicker
    String? Function(String?)? stringValidator;
    if (validator != null) {
      stringValidator = (String? value) {
        return validator(selectedDateTime);
      };
    }
    
    return CustDateTimePicker(
      label: '${config.label}${config.required ? ' *' : ''}',
      hint: hint,
      selectedDateTime: selectedDateTime,
      enabled: enabled && isEditable,
      onDateTimeSelected: onDateTimeSelected,
      validator: stringValidator,
    );
  }

  static Widget buildToggle({
    required FormFieldConfig config,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    UserRole? currentUserRole,
  }) {
    final isEditable = !config.readOnly && 
        (currentUserRole == null || config.isEditableForRole(currentUserRole));
    
    return buildToggleItem(
      config.label,
      value,
      onChanged,
      enabled: enabled && isEditable,
    );
  }

  static Widget buildToggleItem(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.elementSpacing,
        vertical: AppConstants.labelSpacing,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.textFieldFillColor),
        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: enabled ? Colors.black87 : Colors.grey,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          YesNoToggle(value: value, onChanged: onChanged, enabled: enabled),
        ],
      ),
    );
  }


}