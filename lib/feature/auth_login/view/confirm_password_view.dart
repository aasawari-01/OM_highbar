import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/app_images.dart';
import 'package:om_mobile/constants/colors.dart';

import '../../../constants/strings.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../controller/forgot_password_controller.dart';

class ResetPasswordView extends GetView<ForgotPasswordController> {
  ResetPasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
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
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPadding),
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
                child: Obx(
                      () => Form(
                    key: controller.resetFormKey,
                    autovalidateMode: controller.resetAutovalidateMode.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 16),
                        CustText.sectionHeader("Reset Password",
                            color: AppColors.backgroundColor),
                        const SizedBox(height: 4),
                        CustText.body(
                          "Enter the passcode sent to your email and set a new password",
                          color: AppColors.textDarkSecondary,
                        ),
                        const SizedBox(height: AppConstants.sectionSpacing),

                        CustText(
                            name: "Email Id",
                            color: AppColors.black,
                            size: AppConstants.formLabelSize,
                            fontWeightName: FontWeight.w700),
                        const SizedBox(height: AppConstants.labelSpacing),
                        CustomTextField(
                          controller: controller.resetEmailController,
                          hintText: "Enter your email",
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true,
                          prefixIcon: const Icon(TablerIcons.mail,
                              size: AppConstants.iconSize,
                              color: AppColors.hintTextColor),
                          validator: (val) {
                            if ((val == null || val.trim().isEmpty)) {
                              return "Email is required";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppConstants.headerSpacing),

                        CustText(
                            name: "Passcode",
                            color: AppColors.black,
                            size: AppConstants.formLabelSize,
                            fontWeightName: FontWeight.w700),
                        const SizedBox(height: AppConstants.labelSpacing),
                        CustomTextField(
                          controller: controller.passcodeController,
                          hintText: "Enter passcode",
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(TablerIcons.shield_lock,
                              size: AppConstants.iconSize,
                              color: AppColors.hintTextColor),
                          validator: (val) {
                            if ((val == null || val.trim().isEmpty)) {
                              return "Passcode is required";
                            }
                            if (val.trim().length < 4) {
                              return "Enter a valid passcode";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppConstants.headerSpacing),

                        CustText(
                            name: "New Password",
                            color: AppColors.black,
                            size: AppConstants.formLabelSize,
                            fontWeightName: FontWeight.w700),
                        const SizedBox(height: AppConstants.labelSpacing),
                        Obx(
                              () => CustomTextField(
                            controller: controller.newPasswordController,
                            hintText: "Enter new password",
                            obscureText: controller.obscurePassword.value,
                            prefixIcon: const Icon(TablerIcons.lock,
                                size: AppConstants.iconSize,
                                color: AppColors.hintTextColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.obscurePassword.value
                                    ? TablerIcons.eye_off
                                    : TablerIcons.eye,
                                size: AppConstants.iconSize,
                                color: AppColors.hintTextColor,
                              ),
                              onPressed: controller.toggleObscurePassword,
                            ),
                            validator: (val) {
                              if ((val == null || val.trim().isEmpty)) {
                                return "New password is required";
                              }
                              if (val.trim().length < 6) {
                                return "Password must be at least 6 characters";
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppConstants.headerSpacing),

                        CustButton(
                          name: "Password Confirm",
                          size: double.infinity,
                          sHeight: 40,
                          color1: AppColors.orangeColor,
                          color2: AppColors.orangeColor,
                          onSelected: (bool) => controller.updatePassword(),
                        ),
                        const SizedBox(height: AppConstants.sectionSpacing),

                        Center(
                          child: CustText.body(
                            "${AppStrings.copyright}${DateTime.now().year}${AppStrings.allRightsReserved}",
                            size: 11,
                            color: AppColors.black,
                          ),
                        )
                      ],
                    ),
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