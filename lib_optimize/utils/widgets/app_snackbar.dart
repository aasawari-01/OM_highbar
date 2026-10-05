import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/colors.dart';

enum AppSnackType { success, error, warning, info }

/// The one snackbar used across the app, so every message looks the same.
///
/// Drop-in for `Get.snackbar(title, message, ...)`: the old colour arguments
/// are only used to work out the type (green = success, red = error,
/// orange = warning, otherwise info); the look comes from the type.
void appSnackbar(
  String title,
  String message, {
  AppSnackType? type,
  Color? backgroundColor,
  Color? colorText,
  SnackPosition? snackPosition,
  Duration? duration,
}) {
  final kind = type ?? _typeFor(title, backgroundColor);
  final accent = _accent(kind);

  // A new message replaces the one on screen instead of queueing behind it.
  if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

  Get.snackbar(
    title,
    message,
    titleText: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
      ),
    ),
    messageText: Text(
      message,
      style: const TextStyle(
        fontSize: 13,
        height: 1.3,
        color: Color(0xFF4B5563),
      ),
    ),
    icon: Icon(_icon(kind), color: accent, size: 26),
    shouldIconPulse: false,
    leftBarIndicatorColor: accent,
    backgroundColor: AppColors.white1,
    snackPosition: SnackPosition.TOP,
    snackStyle: SnackStyle.FLOATING,
    margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    borderRadius: 12,
    boxShadows: const [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 14,
        offset: Offset(0, 4),
      ),
    ],
    duration: duration ??
        (kind == AppSnackType.error
            ? const Duration(seconds: 4)
            : const Duration(seconds: 3)),
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
    animationDuration: const Duration(milliseconds: 300),
  );
}

/// For the places that only have a message: the type is read from the text.
void appSnackbarMessage(String message,
    {AppSnackType? type, Duration? duration}) {
  final kind = type ?? _typeFor('', null, message);
  appSnackbar(
    switch (kind) {
      AppSnackType.success => 'Success',
      AppSnackType.error => 'Error',
      AppSnackType.warning => 'Warning',
      AppSnackType.info => 'Info',
    },
    message,
    type: kind,
    duration: duration,
  );
}

AppSnackType _typeFor(String title, Color? bg, [String message = '']) {
  if (bg != null) {
    final hsv = HSVColor.fromColor(bg.withValues(alpha: 1));
    final h = hsv.hue;
    if (hsv.saturation > 0.25) {
      if (h < 15 || h >= 340) return AppSnackType.error;
      if (h < 50) return AppSnackType.warning;
      if (h >= 80 && h < 170) return AppSnackType.success;
    }
  }
  final text = '$title $message'.toLowerCase();
  if (RegExp(r'success|saved|created|updated|closed|synced|completed')
      .hasMatch(text) &&
      !RegExp(r'fail|error|not ').hasMatch(text)) {
    return AppSnackType.success;
  }
  if (RegExp(r'error|fail|invalid|denied|required|cannot|unable|wrong')
      .hasMatch(text)) {
    return AppSnackType.error;
  }
  if (RegExp(r'warning|please|select|no data|not found').hasMatch(text)) {
    return AppSnackType.warning;
  }
  return AppSnackType.info;
}

Color _accent(AppSnackType t) => switch (t) {
  AppSnackType.success => const Color(0xFF16A34A),
  AppSnackType.error => AppColors.red,
  AppSnackType.warning => AppColors.orangeColor,
  AppSnackType.info => const Color(0xFF2563EB),
};

IconData _icon(AppSnackType t) => switch (t) {
  AppSnackType.success => Icons.check_circle_rounded,
  AppSnackType.error => Icons.error_rounded,
  AppSnackType.warning => Icons.warning_amber_rounded,
  AppSnackType.info => Icons.info_rounded,
};
