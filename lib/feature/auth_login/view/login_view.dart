import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/app_images.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/constants/strings.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';

import '../../../utils/responsive_helper.dart';
import '../controller/login_controller.dart';
import 'forgot_password_view.dart';


class LoginView extends StatelessWidget {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final bool obscureText = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.put(LoginController());

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Full Screen Background Image
          Positioned.fill(
            child: Image.asset(
              AppAssets.metroImage,
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.3),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.screenPadding * 1.5),
                decoration: BoxDecoration(
                  color: AppColors.white1.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(AppAssets.nagpurMetroLogo, height: 50),
                          const SizedBox(width: 15),
                          Image.asset(AppAssets.puneMetroLogo, height: 50),
                          const SizedBox(width: 15),
                          Image.asset(AppAssets.thaneMetroLogo, height: 50),
                        ],
                      ),
                      const SizedBox(height: AppConstants.headerSpacing),

                      // Title
                      CustText.sectionHeader(AppStrings.signIn, color: AppColors.backgroundColor),
                      const SizedBox(height: 4),
                      CustText.body(AppStrings.enterCredentials, color: AppColors.textDarkSecondary,),
                      const SizedBox(height: AppConstants.sectionSpacing),
                      CustText(name: AppStrings.emailId,color: AppColors.black, size: AppConstants.formLabelSize,fontWeightName: FontWeight.w700),
                      const SizedBox(height: AppConstants.labelSpacing,),
                      CustomTextField(
                        controller: userNameController,
                        hintText: AppStrings.enterEmailId,
                        prefixIcon: const Icon(TablerIcons.user, size: AppConstants.iconSize, color: AppColors.hintTextColor),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.elementSpacing),
                      CustText(name: AppStrings.password,color: AppColors.black, size: AppConstants.formLabelSize,fontWeightName: FontWeight.w700),
                      const SizedBox(height: AppConstants.labelSpacing,),
                      // Password Field
                      Obx(() => CustomTextField(
                        controller: passwordController,
                        hintText: AppStrings.enterPassword,
                        obscureText: !loginController.isPasswordVisible.value,
                        prefixIcon: const Icon(TablerIcons.lock, size: AppConstants.iconSize, color: AppColors.hintTextColor),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                        suffixIcon: GestureDetector(
                          onTap: () {
                            loginController.isPasswordVisible.value = !loginController.isPasswordVisible.value;
                          },
                          child: Icon(
                            loginController.isPasswordVisible.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: AppConstants.iconSize,
                            color: AppColors.orangeColor,
                          ),
                        ),
                      )),
                      const SizedBox(height: AppConstants.elementSpacing),

                      // Remember Me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Obx(() => Checkbox(
                                  value: loginController.rememberMe.value,
                                  onChanged: (value) {
                                    loginController.rememberMe.value = value ?? false;
                                  },
                                  activeColor: AppColors.orangeColor,
                                  side: const BorderSide(color: AppColors.orangeColor, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                )),
                              ),
                              const SizedBox(width: 8),
                              CustText.body(AppStrings.rememberMe, color: AppColors.black, fontWeightName: FontWeight.bold),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ForgotPasswordView()),
                              );
                            },
                            child: CustText.body(
                              AppStrings.forgotPassword,
                              color: AppColors.orangeColor,
                              size: 15,
                              fontWeightName: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.headerSpacing),

                      // Login Button
                      Obx(() => CustButton(
                        name: loginController.isLoading.value ? AppStrings.loggingIn : AppStrings.login,
                        size: double.infinity,
                        sHeight: 40,
                        color1: AppColors.orangeColor,
                        color2: AppColors.orangeColor,
                        onSelected: (bool) {
                          if (_formKey.currentState!.validate()) {
                            loginController.login(
                              email: userNameController.text.trim(),
                              password: passwordController.text.trim(),
                            );
                          }
                        },
                      )),

                      const SizedBox(height: AppConstants.sectionSpacing),

                      // Copyright
                      Center(
                        child: CustText.body(
                          "${AppStrings.copyright}${DateTime.now().year}${AppStrings.allRightsReserved}",
                          size: 11,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}