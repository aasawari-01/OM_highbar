import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';

enum FailureToastType { success, error, warning, info }

/// One look for every message shown in the failure flows (snackbar): same
/// position, shape, icon and colours per kind. Only one is visible at a time
/// and the same message is not stacked when it is raised twice in a row.
///
/// [show] takes the same first two arguments as `Get.snackbar`, so the kind is
/// picked from the colour/title the caller already passes.
class FailureToast {
  FailureToast._();

  static const int _maxLength = 160;
  static String? _lastKey;
  static DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  static void success(String message, {String title = 'Success'}) =>
      _display(FailureToastType.success, title, message);

  static void error(Object message, {String title = 'Error'}) =>
      _display(FailureToastType.error, title, message);

  static void warning(String message, {String title = 'Warning'}) =>
      _display(FailureToastType.warning, title, message);

  static void info(String message, {String title = 'Info'}) =>
      _display(FailureToastType.info, title, message);

  /// Drop-in for `Get.snackbar(title, message, backgroundColor: ...)`.
  static void show(
    String title,
    String message, {
    Color? backgroundColor,
    Color? colorText,
    SnackPosition? snackPosition,
    Duration? duration,
  }) {
    _display(_kindOf(title, backgroundColor), title, message,
        duration: duration);
  }

  static FailureToastType _kindOf(String title, Color? background) {
    if (background != null) {
      final rgb = background.toARGB32() & 0xFFFFFF;
      if (rgb == (AppColors.green.toARGB32() & 0xFFFFFF)) {
        return FailureToastType.success;
      }
      if (rgb == (AppColors.red.toARGB32() & 0xFFFFFF)) {
        return FailureToastType.error;
      }
      if (rgb == (AppColors.orangeColor.toARGB32() & 0xFFFFFF)) {
        return FailureToastType.warning;
      }
    }
    final t = title.toLowerCase();
    if (t.contains('success') || t.contains('saved') || t.contains('done')) {
      return FailureToastType.success;
    }
    if (t.contains('error') ||
        t.contains('fail') ||
        t.contains('invalid') ||
        t.contains('validation') ||
        t.contains('required')) {
      return FailureToastType.error;
    }
    if (t.contains('offline') || t.contains('warning') || t.contains('wait')) {
      return FailureToastType.warning;
    }
    return FailureToastType.info;
  }

  /// A message that is safe to show: no exception class names, no raw server
  /// bodies, no stack-like text.
  static String clean(Object? raw) {
    var text = '${raw ?? ''}'.trim();
    final lower = text.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('connection refused') ||
        lower.contains('connection closed')) {
      return 'No internet connection. Please try again.';
    }
    if (lower.contains('timeoutexception') || lower.contains('timed out')) {
      return 'The server took too long to respond. Please try again.';
    }
    text = text
        .replaceFirst(RegExp(r'^(Exception|Error):\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return 'Something went wrong. Please try again.';
    // Keep the readable part when the server body is appended after a colon.
    final brace = text.indexOf(RegExp(r'[{\[]\s*["{]'));
    if (brace > 0 && text.substring(0, brace).trim().isNotEmpty) {
      text = text.substring(0, brace).trim().replaceFirst(RegExp(r':$'), '');
    }
    if (text.length > _maxLength) text = '${text.substring(0, _maxLength)}...';
    return text;
  }

  static void _display(
    FailureToastType type,
    String title,
    Object message, {
    Duration? duration,
  }) {
    final text = type == FailureToastType.error
        ? clean(message)
        : '$message'.trim().isEmpty
            ? ''
            : '$message'.trim();
    if (text.isEmpty) return;

    final key = '${type.name}|$text';
    final now = DateTime.now();
    if (key == _lastKey &&
        now.difference(_lastAt) < const Duration(milliseconds: 1500)) {
      return;
    }
    _lastKey = key;
    _lastAt = now;

    final (Color color, IconData icon) = switch (type) {
      FailureToastType.success => (AppColors.green, Icons.check_circle_outline),
      FailureToastType.error => (AppColors.red, Icons.error_outline),
      FailureToastType.warning =>
        (AppColors.orangeColor, Icons.cloud_off_outlined),
      FailureToastType.info => (const Color(0xFF3B82F6), Icons.info_outline),
    };

    try {
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      Get.snackbar(
        title.trim().isEmpty ? _defaultTitle(type) : title,
        text,
        backgroundColor: color.withValues(alpha: 0.95),
        colorText: Colors.white,
        icon: Icon(icon, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        duration: duration ??
            Duration(seconds: type == FailureToastType.error ? 4 : 3),
      );
    } catch (_) {
      // No overlay yet (e.g. very early): a message must never crash a flow.
    }
  }

  static String _defaultTitle(FailureToastType type) => switch (type) {
        FailureToastType.success => 'Success',
        FailureToastType.error => 'Error',
        FailureToastType.warning => 'Warning',
        FailureToastType.info => 'Info',
      };
}
