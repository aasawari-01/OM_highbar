import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import 'cust_popup.dart';

/// The one "failure created" popup used for every failure type, so the
/// wording is identical. [type] e.g. Station, Maintenance, OCC, Depot.
Future<void> showFailureCreatedPopup({
  required String type,
  String? failureNo,
  bool closed = false,
}) {
  final no = (failureNo ?? '').trim();
  return showResultPopup(
    message: '$type failure created${closed ? ' and closed' : ''} successfully.'
        '${no.isNotEmpty ? '\nFailure No: $no' : ''}',
  );
}

/// Result popup with a single OK button (used after a failure is created).
/// Shown on top of whatever screen is current, so call it after navigating.
Future<void> showResultPopup({
  required String message,
  String title = 'Success',
  IconData icon = Icons.check_circle_outline,
  Color? iconColor,
}) async {
  await Get.dialog(
    CustPopup(
      title: title,
      message: message,
      icon: icon,
      iconColor: iconColor ?? AppColors.green,
      confirmText: 'OK',
      onConfirm: () => Get.back(),
      onCancel: () => Get.back(),
    ),
    barrierDismissible: false,
  );
}
