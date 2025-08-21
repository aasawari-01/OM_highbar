import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../constants/colors.dart';
import '../../utils/size_config.dart';
import '../screens/tab_screen.dart';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4 * SizeConfig.widthMultiplier)),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  Widget dialogContent(BuildContext context) {
    return  Container(
    margin: EdgeInsets.only(top: 3.5 * SizeConfig.widthMultiplier,right: 2 * SizeConfig.widthMultiplier),
      decoration:  BoxDecoration(
          borderRadius: BorderRadius.circular(4 * SizeConfig.widthMultiplier),
          color:AppColors.white1
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(height: 5 * SizeConfig.heightMultiplier),
          Center(
              child: Padding(
                padding:  EdgeInsets.all(2.5 * SizeConfig.widthMultiplier),
                child:  CustText(name: msg, size: 1.8, color: AppColors.textColor,
                    textAlign:TextAlign.center,fontWeightName:FontWeight.w500),
              )//
          ),
          SizedBox(height: 5 * SizeConfig.heightMultiplier),
          Center(
            child: CustButton(name: "Ok", size: 25, color1: AppColors.darkBlue,color2:AppColors.darkBlue, sHeight:4.5 * SizeConfig.heightMultiplier,
                onSelected:  (flag) async {
                  Get.offAll(() => TabScreen(index: 0));                }),
          ),
          SizedBox(height: 6 * SizeConfig.heightMultiplier),
        ],
      ),
    );
  }
}