import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/size_config.dart';

class InputStyles {
  static final double borderRadius = 2.5;
  static const double borderWidth = 1.0;
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 12.0,
  );

  static OutlineInputBorder get outlineInputBorder {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius * SizeConfig.widthMultiplier),
      borderSide: const BorderSide(
        color: AppColors.textFieldColor,
        width: borderWidth,
      ),
    );
  }

  static InputDecoration get baseDecoration {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      counterText: "",
      isDense: true,
      contentPadding: contentPadding,
      border: outlineInputBorder,
      enabledBorder: outlineInputBorder,
      disabledBorder: outlineInputBorder,
      focusedBorder: outlineInputBorder,
    );
  }

  static TextStyle get textStyle {
    return GoogleFonts.workSans(
      color: AppColors.textColor,
      fontSize: 1.6 * SizeConfig.textMultiplier,
    );
  }

  static TextStyle get hintStyle {
    return GoogleFonts.workSans(
      color: AppColors.textColor4,
      fontSize: 1.6 * SizeConfig.textMultiplier,
    );
  }
}
