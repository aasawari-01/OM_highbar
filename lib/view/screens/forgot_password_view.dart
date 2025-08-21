import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import 'widgets/cust_button.dart';
import 'widgets/cust_text.dart';
import 'widgets/cust_textfield.dart';

class ForgotPasswordView extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(height: screenHeight, width: screenWidth),
          SizedBox(
            height: screenHeight * 0.6,
            width: double.infinity,
            child: Image.asset(
              "assets/images/metro.png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: screenHeight * 0.57 - 40,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.6,
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
                      name: "Forgot Password",
                      size: 2.2,
                      color: AppColors.white2,
                      fontWeightName: FontWeight.bold,
                    ),
                    const SizedBox(height: 6),
                    CustText(
                      name: "We'll send a reset link to your email",
                      size: 1.4,
                      color: AppColors.white2.withOpacity(0.7),
                    ),
                    const SizedBox(height: 24),
                    CustText(
                      name: "Email",
                      size: 1.6,
                      color: AppColors.white2,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: emailController,
                      hintText: "Enter your email",
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    CustButton(
                      name: "Send Reset Link",
                      size: double.infinity,
                      onSelected: (bool) {
                        // TODO: Implement send reset link logic
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: CustText(
                          name: "← Back to Login",
                          size: 1.4,
                          color: AppColors.white2.withOpacity(0.7),
                        ),
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