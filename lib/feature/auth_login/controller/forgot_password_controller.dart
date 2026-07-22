import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../utils/widgets/cust_popup.dart';
import '../service/auth_service.dart';

import '../view/confirm_password_view.dart';
import '../view/login_view.dart';

class ForgotPasswordController extends GetxController {
  ForgotPasswordController({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  // ----- Forgot Password screen state -----
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> forgotFormKey = GlobalKey<FormState>();
  final Rx<AutovalidateMode> forgotAutovalidateMode =
      AutovalidateMode.disabled.obs;

  // ----- Reset Password screen state -----
  final TextEditingController resetEmailController = TextEditingController();
  final TextEditingController passcodeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();
  final Rx<AutovalidateMode> resetAutovalidateMode =
      AutovalidateMode.disabled.obs;
  final RxBool obscurePassword = true.obs;

  final RxBool isLoading = false.obs;

  void toggleObscurePassword() => obscurePassword.value = !obscurePassword.value;

  /// Step 1: Send passcode to email
  Future<void> forgotPassword() async {
    forgotAutovalidateMode.value = AutovalidateMode.onUserInteraction;
    if (!(forgotFormKey.currentState?.validate() ?? false)) return;

    try {
      isLoading.value = true;
      EasyLoading.show(status: 'Sending reset code...');

      final email = emailController.text.trim();
      await _authService.forgotPassword(email: email);

      EasyLoading.dismiss();

      resetEmailController.text = email; // carry email over to next screen
      Get.to(() => ResetPasswordView());
    } catch (e) {
      EasyLoading.dismiss();
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Step 2: Confirm passcode + set new password
  Future<void> updatePassword() async {
    resetAutovalidateMode.value = AutovalidateMode.onUserInteraction;
    if (!(resetFormKey.currentState?.validate() ?? false)) return;

    try {
      isLoading.value = true;
      EasyLoading.show(status: 'Updating password...');

      await _authService.updatePassword(
        email: resetEmailController.text.trim(),
        userCode: passcodeController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );

      EasyLoading.dismiss();

      Get.dialog(
        CustPopup(
          title: "Success",
          message: "Your password has been updated successfully.",
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          confirmText: "OK",
          onConfirm: () {
            Get.back();
            Get.offAll(() => LoginView());
          },
        ),
      );
    } catch (e) {
      EasyLoading.dismiss();
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(Object e) {
    Get.dialog(
      CustPopup(
        title: "Failed",
        message: e.toString().replaceFirst('AuthException: ', ''),
        icon: Icons.error_outline,
        iconColor: Colors.red,
        confirmText: "OK",
        onConfirm: () => Get.back(),
      ),
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    resetEmailController.dispose();
    passcodeController.dispose();
    newPasswordController.dispose();
    super.onClose();
  }
}