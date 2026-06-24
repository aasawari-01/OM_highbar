import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../feature/tabs/view/home_screen.dart';
import 'cust_popup.dart';

class CustomDialog extends StatelessWidget {
  final String msg;
  
  const CustomDialog(this.msg, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustPopup(
      title: msg,
      confirmText: "Ok",
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      onConfirm: () {
        Get.offAll(() => const HomeScreen());
      },
    );
  }
}