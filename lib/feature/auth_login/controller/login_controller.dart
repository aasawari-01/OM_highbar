import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../utils/widgets/cust_popup.dart';
import '../../tabs/view/home_screen.dart';

import '../service/auth_service.dart';
import '../model/login_response.dart';
import '../../../service/auth_manager.dart';
import '../../../service/session_controller.dart';
import '../../../service/master_data_sync_service.dart';

class LoginController extends GetxController {
  LoginController({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool rememberMe = false.obs;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      EasyLoading.show(status: 'Logging in...');
      final LoginResponse result =
          await _authService.login(email: email, password: password);
      if (result.message == "Success" || result.messageCode == 200) {
        debugPrint("Login successful. Received Business Area: ${result.businessArea}");
        await AuthManager().login(result, rememberMe: rememberMe.value);


        if (Get.isRegistered<SessionController>()) {
          await Get.find<SessionController>().loadSessionData();
        } else {
          Get.put(SessionController());
        }
        
        EasyLoading.dismiss();
        // Navigate to home screen first
        Get.offAll(() => const HomeScreen());
        
        // Check if this is first-time login to show initial sync on home screen
        final isFirstTimeLogin = await AuthManager().isFirstTimeLogin();
        if (isFirstTimeLogin) {
          // Sync master data on first-time login (will show loader on home screen)
          await MasterDataSyncService().syncMasterData();
          await AuthManager().setFirstTimeLoginComplete();
        }

      } else {
        EasyLoading.dismiss();
        Get.dialog(
          CustPopup(
            title: "Login Failed",
            message: (result.message == null || result.message!.trim().isEmpty)
                ? "Invalid credentials."
                : result.message!.toLowerCase() == "password"||result.message!.toLowerCase() == "email"
                ? "The ${result.message} you entered is incorrect. Please try again."
                : result.message!,
            icon: Icons.error_outline,
            iconColor: Colors.red,
            confirmText: "OK",
            onConfirm: () => Get.back(),
          ),
        );
        // Get.snackbar(
        //   'Login failed',
        //   "Invalid ${result.message}" ?? 'Invalid credentials',
        // );
      }
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Login failed',
        e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }
}

