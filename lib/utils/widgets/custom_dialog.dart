import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../constants/colors.dart';
import '../../feature/tabs/view/home_screen.dart';
import '../../utils/responsive_helper.dart';

import 'cust_button.dart';
import 'cust_text.dart';

class CustomDialog extends StatelessWidget {
  String msg = "";
  CustomDialog(msg){
    this.msg = msg;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  Widget dialogContent(BuildContext context) {
    return  Container(
    margin: EdgeInsets.only(top: ResponsiveHelper.height(context, 16),right: ResponsiveHelper.width(context, 15)),
      decoration:  BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color:AppColors.white1
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(height: ResponsiveHelper.spacing(context, 16)),
          Center(
              child: Padding(
                padding:  EdgeInsets.all(4),
                child:  CustText(name: msg, size: 18, color: AppColors.textColor,
                    textAlign:TextAlign.center,fontWeightName:FontWeight.w500),
              )//
          ),
          SizedBox(height:ResponsiveHelper.fontSize(context, 16)),
          Center(
            child: CustButton(name: "Ok", size: 100, color1: AppColors.darkBlue,color2:AppColors.darkBlue,
                onSelected:  (flag) async {
                  Get.offAll(() =>  HomeScreen());
            }),
          ),
          SizedBox(height: ResponsiveHelper.fontSize(context, 16)),
        ],
      ),
    );
  }
}