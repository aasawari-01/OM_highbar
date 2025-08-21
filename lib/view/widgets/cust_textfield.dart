import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

import '../../constants/colors.dart';
import '../../utils/size_config.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
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

  const CustomTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
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
  });

  @override
  Widget build(BuildContext context) {
    // Set maxLines to 1 if obscureText is true, otherwise use provided maxLines or default to 1
    int effectiveMaxLines = obscureText ? 1 : maxLines ?? 1;

    return SizedBox(
      // height: obscureText ? 5.0 * SizeConfig.heightMultiplier : effectiveMaxLines * 5.0 * SizeConfig.heightMultiplier,
      child: TextFormField(
        enabled: enabled,
        style: GoogleFonts.workSans(color: AppColors.textColor4, fontSize: 1.6 * SizeConfig.textMultiplier),
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
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        inputFormatters: inputFormatters,
        textAlign: textAlign ?? TextAlign.start,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.workSans(color: AppColors.textColor4, fontSize: 1.6 * SizeConfig.textMultiplier),
          filled: true,
          fillColor: fillColor ?? Colors.white,
          counterText: "",
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child:suffixIcon,
          ),
          suffixIconConstraints: BoxConstraints(
            minHeight: 30,
            minWidth: 30,
          ),
          prefixIcon: prefixIcon,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
            borderSide: BorderSide(color: AppColors.textFieldColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
            borderSide: BorderSide(color: AppColors.textFieldColor),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
            borderSide: BorderSide(color: AppColors.textFieldColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
            borderSide: BorderSide(color: AppColors.textFieldColor),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 12.0,
          ),
        ),
      ),
    );
  }
}