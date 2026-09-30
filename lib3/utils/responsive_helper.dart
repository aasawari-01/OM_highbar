import 'package:flutter/material.dart';

/// Simple responsive helper for mobile vs tablet sizing
class ResponsiveHelper {
  /// Check if device is tablet (width >= 600)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  /// Check if device is small screen (width < 350)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 400;
  }

  /// Get responsive font size: mobile size or tablet size (1.2x) or small screen (0.85x)
  static double fontSize(BuildContext context, double mobileSize) {
    if (isTablet(context)) {
      return mobileSize * 1.2;
    } else if (isSmallScreen(context)) {
      return mobileSize * 0.75;
    }
    return mobileSize;
  }

  /// Get responsive spacing: mobile size or tablet size (1.3x) or small screen (0.85x)
  static double spacing(BuildContext context, double mobileSize) {
    if (isTablet(context)) {
      return mobileSize * 1.3;
    } else if (isSmallScreen(context)) {
      return mobileSize * 0.75;
    }
    return mobileSize;
  }

  /// Get responsive width: mobile size or tablet size (1.2x) or small screen (0.85x)
  static double width(BuildContext context, double mobileSize) {
    if (isTablet(context)) {
      return mobileSize * 1.2;
    } else if (isSmallScreen(context)) {
      return mobileSize * 0.75;
    }
    return mobileSize;
  }

  /// Get responsive height: mobile size or tablet size (1.2x) or small screen (0.85x)
  static double height(BuildContext context, double mobileSize) {
    if (isTablet(context)) {
      return mobileSize * 1.3;
    } else if (isSmallScreen(context)) {
      return mobileSize * 0.75;
    }
    return mobileSize;
  }
}
