import 'package:flutter/material.dart';
import 'package:om_mobile/tab_screen.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'constants/colors.dart';
import 'widgets/cust_button.dart';
import 'widgets/cust_text.dart';
import 'widgets/cust_textfield.dart';
import 'forgot_password_view.dart';

class LoginView extends StatelessWidget {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(height:screenHeight ,
          width: screenWidth,),
          SizedBox(
            height: screenHeight * 0.6,
            width: double.infinity,
            child: Image.asset(
              "assets/images/metro.png",
               fit: BoxFit.cover,
            ),
          ),
          // Bottom: Login form, overlapping the image
          Positioned(
            top: screenHeight * 0.56 - 40,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: BoxDecoration(
                color: AppColors.appBarColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustText(
                      name: "Welcome To\nOperation & Management !",
                      size: 2.2, // Adjust as needed for your scale
                      color: AppColors.white2,
                      fontWeightName: FontWeight.bold,
                    ),
                     SizedBox(height: 0.5 * SizeConfig.heightMultiplier),
                    CustText(
                      name: "Please enter username and password to sign in",
                      size: 1.4,
                      color: AppColors.white2.withOpacity(0.7),
                    ),
                    SizedBox(height: 1.5 * SizeConfig.heightMultiplier),
                    CustText(
                      name: "Email",
                      size: 1.6,
                      color: AppColors.white2,
                    ),
                    SizedBox(height: 0.5 * SizeConfig.heightMultiplier),
                    CustomTextField(
                      controller: userNameController,
                      hintText: "Enter Email",
                    ),
                    SizedBox(height: 1.5 * SizeConfig.heightMultiplier),
                    CustText(
                      name: "Password",
                      size: 1.6,
                      color: AppColors.white2,
                    ),
                    SizedBox(height: 0.5 * SizeConfig.heightMultiplier),
                    CustomTextField(
                      controller: passwordController,
                      hintText: "Enter Password",
                      obscureText: obscureText,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.go,
                    ),
                    SizedBox(height: 1 * SizeConfig.heightMultiplier),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ForgotPasswordView()),
                          );
                        },
                        child: CustText(
                          name: "Forgot password?",
                          size: 1.4,
                          color: AppColors.white2,
                        ),
                      ),
                    ),
                    SizedBox(height: 2 * SizeConfig.heightMultiplier),
                    CustButton(
                      name: "Log In",
                      size: double.infinity,
                      onSelected: (bool) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TabScreen(index: 0,)),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: CustText(
                        name: "© Copyright ${DateTime.now().year}, All rights reserved",
                        size: 1.4,
                        color: AppColors.white2.withOpacity(0.7),
                      ),
                    ),
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}