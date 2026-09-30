import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import 'cust_popup.dart';

class CustomDialog extends StatelessWidget {
  final String msg;
  
  const CustomDialog(this.msg, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustPopup(
      title: msg,
      confirmText: "Ok",
      icon: Icons.check_circle_outline,
      iconColor: AppColors.green,
      onConfirm: () {
        Get.back();
      },
    );
  }
}