import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/string_utils.dart';
import 'cust_text.dart';

class CustDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> items;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Color? fillColor;
  final bool enabled;
  final bool Function(String)? disabledItemFn;

  const CustDropdown({
    Key? key,
    required this.label,
    required this.hint,
    required this.items,
    this.selectedValue,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    this.fillColor,
    this.enabled = true,
    this.disabledItemFn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText.formLabel(label),
          SizedBox(height: ResponsiveHelper.spacing(context, AppConstants.labelSpacing)),
          SizedBox(
            height: AppConstants.inputHeight,
            child: DropdownSearch<String>(
              enabled: enabled,
              selectedItem: selectedValue,
              onChanged: onChanged,
              validator: validator,
              items: (filter, loadProps) => items,
              popupProps: PopupProps.modalBottomSheet(
                showSearchBox: true,
                fit: FlexFit.loose,
                disabledItemFn: disabledItemFn,
                modalBottomSheetProps: const ModalBottomSheetProps(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: CustText.sectionHeader(label),
                ),
                containerBuilder: (ctx, popupWidget) {
                  return MediaQuery(
                    data: MediaQuery.of(ctx).copyWith(
                      textScaler: const TextScaler.linear(1.0),
                    ),
                    child: popupWidget,
                  );
                },
                itemBuilder: (context, item, isDisabled, isSelected) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: CustText(
                      name: item,
                      color: isSelected 
                          ? AppColors.appBarColor 
                          : (isDisabled ? Colors.grey.shade400 : AppColors.textColor4),
                      size: AppConstants.bodySize,
                      fontWeightName: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                },
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
                    prefix: const SizedBox(width: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, AppConstants.inputRadius)),
                      borderSide: BorderSide(color: AppColors.textFieldColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, AppConstants.inputRadius)),
                      borderSide: const BorderSide(color: AppColors.appBarColor, width: 1.5),
                    ),
                    hintText: 'Search...',
                    hintStyle: GoogleFonts.lato(
                      color: AppColors.hintTextColor,
                      fontSize: ResponsiveHelper.fontSize(context, AppConstants.bodySize),
                    ),
                  ),
                  style: GoogleFonts.lato(
                    fontSize: ResponsiveHelper.fontSize(context, AppConstants.bodySize),
                    color: AppColors.textColor,
                  ),
                ),
              ),
              suffixProps: const DropdownSuffixProps(
                dropdownButtonProps: DropdownButtonProps(isVisible: false),
                clearButtonProps: ClearButtonProps(isVisible: false),
              ),
              decoratorProps: DropDownDecoratorProps(
                baseStyle: GoogleFonts.lato(
                  color: AppColors.textColor4,
                  fontSize: ResponsiveHelper.fontSize(context, AppConstants.bodySize),
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.lato(
                    color: AppColors.hintTextColor,
                    fontSize: ResponsiveHelper.fontSize(context, AppConstants.bodySize),
                  ),
                  isDense: true,
                  filled: true,
                  fillColor:enabled ?Colors.white : AppColors.containerColor2,
                  prefixIcon: prefixIcon,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, AppConstants.inputRadius)),
                    borderSide: BorderSide(color: AppColors.textFieldColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, AppConstants.inputRadius)),
                    borderSide: BorderSide(color: AppColors.textFieldColor),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, AppConstants.inputRadius)),
                    borderSide: BorderSide(color: AppColors.textFieldColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.spacing(context, AppConstants.inputRadius)),
                    borderSide: const BorderSide(color: AppColors.textColor),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
                  prefix: const SizedBox(width: 10),
                  errorStyle: GoogleFonts.lato(
                    fontSize: ResponsiveHelper.fontSize(context, 10),
                    height: 1.0,
                  ),
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: Icon(TablerIcons.chevron_down, size: 16.0, color: AppColors.iconColor),
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minHeight: 24,
                    minWidth: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
