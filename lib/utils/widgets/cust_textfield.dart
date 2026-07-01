import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../utils/responsive_helper.dart';
import 'cust_text.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final String? label;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool readOnly;
  final int? maxLength;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final Color? fillColor;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign? textAlign;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
    this.maxLength,
    this.maxLines,
    this.validator,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.fillColor,
    this.inputFormatters,
    this.textAlign,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    int effectiveMaxLines = obscureText ? 1 : maxLines ?? 1;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            buildRequiredLabel(context, label!),
            SizedBox(height: ResponsiveHelper.spacing(context, AppConstants.labelSpacing)),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: effectiveMaxLines == 1 ? AppConstants.inputHeight : 0,
            ),
            child: TextFormField(
              enabled: enabled,
              style: GoogleFonts.lato(
                color: AppColors.black,
                fontSize: ResponsiveHelper.fontSize(context, AppConstants.bodySize),
              ),
              onTapOutside: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              cursorColor: AppColors.textColor,
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onChanged: onChanged,
              onFieldSubmitted: onSubmitted,
              readOnly: readOnly,
              maxLength: maxLength,
              validator: validator,
              focusNode: focusNode,
              autofocus: autofocus,
              maxLines: effectiveMaxLines,
              textCapitalization: textCapitalization,
              onTap: onTap,
              inputFormatters: inputFormatters,
              textAlign: textAlign ?? TextAlign.start,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.lato(
                  color: AppColors.hintTextColor,
                  fontSize: ResponsiveHelper.fontSize(context, AppConstants.bodySize),
                ),
                filled: true,
                fillColor: enabled ?Colors.white : AppColors.containerColor2,
                counterText: "",
                errorStyle: GoogleFonts.lato(
                  fontSize: ResponsiveHelper.fontSize(context, 10),
                  height: 1.0,
                ),
                suffixIcon: suffixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: suffixIcon,
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minHeight: 24,
                  minWidth: 24,
                ),
                prefixIcon: prefixIcon,
                isDense: true,
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
                  borderSide: const BorderSide(color: AppColors.orangeColor,),
                ),
                contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}