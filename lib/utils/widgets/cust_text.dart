import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/colors.dart';
import '../../constants/app_constants.dart';
import '../../utils/responsive_helper.dart';

/// Renders a label with an optional asterisk (*) shown in AppColors.darkRed.
/// If [name] ends with " *" or contains " *", the asterisk portion is colored.
Widget buildRequiredLabel(BuildContext context, String name, {Color? color, FontWeight? fontWeight, double? fontSize}) {
  final effectiveColor = color ?? AppColors.black;
  final effectiveFontSize = fontSize ?? AppConstants.formLabelSize;
  final effectiveFontWeight =  FontWeight.w600;

  if (name.contains(' *') || name.endsWith('*')) {
    // Split at the asterisk
    final idx = name.lastIndexOf('*');
    final beforeAsterisk = name.substring(0, idx);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: beforeAsterisk,
            style: GoogleFonts.lato(
              color: effectiveColor,
              fontWeight: effectiveFontWeight,
              fontSize: ResponsiveHelper.fontSize(context, effectiveFontSize),
            ),
          ),
          TextSpan(
            text: '*',
            style: GoogleFonts.lato(
              color: AppColors.darkRed,
              fontWeight: effectiveFontWeight,
              fontSize: ResponsiveHelper.fontSize(context, effectiveFontSize),
            ),
          ),
        ],
      ),
    );
  }
  return Text(
    name,
    style: GoogleFonts.lato(
      color: effectiveColor,
      fontWeight: effectiveFontWeight,
      fontSize: ResponsiveHelper.fontSize(context, effectiveFontSize),
    ),
  );
}

class CustText extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final FontWeight? fontWeightName;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const CustText({
    super.key,
    required this.name,
    required this.size,
    this.color,
    this.fontWeightName,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// Standard Section Header (e.g. "Personal Details")
  static CustText sectionHeader(String name, {Color? color, TextAlign? textAlign}) {
    return CustText(
      name: name,
      size: AppConstants.sectionHeaderSize,
      fontWeightName: FontWeight.w700,
      color: color ?? AppColors.textDarkPrimary,
      textAlign: textAlign,
    );
  }

  /// Standard Form/Input Label (e.g. "First Name")
  static CustText formLabel(String name, {Color? color, TextAlign? textAlign}) {
    return CustText(
      name: name,
      size: AppConstants.formLabelSize,
      fontWeightName: FontWeight.w600,
      color: color ?? AppColors.black,
      textAlign: textAlign,
    );
  }

  /// Standard Detail View Label (e.g. "Station:")
  static CustText detailLabel(String name, {Color? color, TextAlign? textAlign}) {
    return CustText(
      name: name,
      size: AppConstants.detailLabelSize,
      fontWeightName: FontWeight.w400,
      color: color ?? AppColors.textDarkSecondary,
      textAlign: textAlign,
    );
  }

  /// Standard Detail View Value (e.g. "Mumbai")
  static CustText detailValue(String name, {Color? color, TextAlign? textAlign, TextOverflow? overflow}) {
    return CustText(
      name: name,
      size: AppConstants.detailValueSize,
      fontWeightName: FontWeight.bold,
      color: color ?? AppColors.black,
      textAlign: textAlign,
      overflow: overflow,
    );
  }

  /// Standard Body Text
  static CustText body(String name, {Color? color, TextAlign? textAlign, double? size, FontWeight? fontWeightName}) {
    return CustText(
      name: name,
      size: size ?? AppConstants.bodySize,
      fontWeightName: fontWeightName ?? FontWeight.w400,
      color: color ?? AppColors.textDarkPrimary,
      textAlign: textAlign,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: Text(
        name,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: GoogleFonts.lato(
          color: color ?? AppColors.textDarkPrimary,
          fontWeight: fontWeightName ?? FontWeight.w400,
          fontSize: ResponsiveHelper.fontSize(context, size),
        ),
      ),
    );
  }
}
