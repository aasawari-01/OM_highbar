import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../tabs/view/home_screen.dart';

import '../service/auth_service.dart';
import '../model/login_response.dart';
import '../../../service/auth_manager.dart';
import '../../../service/session_controller.dart';

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
      final LoginResponse result =
          await _authService.login(email: email, password: password);
      if (result.message == "Success" || result.messageCode == 200) {
        await AuthManager().login(result, rememberMe: rememberMe.value);
        if (Get.isRegistered<SessionController>()) {
          await Get.find<SessionController>().loadSessionData();
        } else {
          Get.put(SessionController());
        }
        Get.offAll(() => const HomeScreen());
      } else {
        Get.snackbar(
          'Login failed',
          result.message ?? 'Invalid credentials',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Login failed',
        e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }
}

