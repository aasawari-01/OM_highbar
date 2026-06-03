import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:om_mobile/constants/app_constants.dart';

import '../../constants/colors.dart';
import '../../utils/responsive_helper.dart';

class CustButton extends StatelessWidget {
  final String name;
  final double size;
  final Color? color1;
  final Color? color2;
  final double? sHeight;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontweight;
  final Color? borderColor;
  final double? borderRadius;
  final Function(bool)? onSelected;

  const CustButton({
    super.key,
    required this.name,
    required this.size,
    this.onSelected,
    this.color1,
    this.color2,
    this.sHeight,
    this.borderRadius,
    this.textColor,
    this.fontSize,
    this.fontweight,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected != null ? () => onSelected!(true) : null,
      child: Container(
        width: size == null ? MediaQuery.of(context).size.width / 2 - 20 : ResponsiveHelper.width(context, size!),
        height: sHeight ?? ResponsiveHelper.height(context, AppConstants.buttonHeight),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              (onSelected != null ? (color1 ?? AppColors.orangeColor) : Colors.grey.shade400),
              (onSelected != null ? (color2 ?? AppColors.orangeColor) : Colors.grey.shade400),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor?.withOpacity(0.5) ?? Colors.transparent,
              blurRadius: 1,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppConstants.inputRadius,
          ),
          border: Border.all(
            color: onSelected != null ? (borderColor ?? Colors.transparent) : Colors.grey.shade400,
            width: 1.5,
          ),
          shape: BoxShape.rectangle,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: Text(
                  name,
                  style: GoogleFonts.lato(
                    color: textColor ?? AppColors.white1,
                    fontWeight: fontweight ?? FontWeight.w400,
                    fontSize: ResponsiveHelper.fontSize(context, fontSize ?? 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class CustOutlineButton extends StatelessWidget {
  final String name;
  final double size;
  final Color? borderColor;
  final Color? textColor;
  final double? sHeight;
  final double? borderRadius;
  final double? fontSize;
  final FontWeight? fontweight;
  final Function(bool)? onSelected;

  const CustOutlineButton({
    super.key,
    required this.name,
    required this.size,
    this.onSelected,
    this.borderColor,
    this.textColor,
    this.sHeight,
    this.borderRadius,
    this.fontSize,
    this.fontweight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected != null ? () => onSelected!(true) : null,
      child: Container(
        width: size == null ? MediaQuery.of(context).size.width / 2 - 20 : ResponsiveHelper.width(context, size!),
        height: sHeight ?? ResponsiveHelper.height(context, AppConstants.buttonHeight),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppConstants.inputRadius,
          ),
          border: Border.all(
            color: onSelected != null ? (borderColor ?? AppColors.buttonOutlineColor) : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: Text(
                  name,
                  style: GoogleFonts.lato(
                    color: onSelected != null ? (textColor ?? AppColors.textColor) : Colors.grey.shade400,
                    fontWeight: fontweight ?? FontWeight.w400,
                    fontSize: ResponsiveHelper.fontSize(context, fontSize ?? 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}