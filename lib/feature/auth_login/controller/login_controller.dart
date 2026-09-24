import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../constants/colors.dart';
import '../../../utils/widgets/cust_popup.dart';
import '../../tabs/view/home_screen.dart';

import '../service/auth_service.dart';
import '../model/login_response.dart';
import '../../../service/auth_manager.dart';
import '../../../core/controller/session_controller.dart';
import '../../../service/master_data_sync_service.dart';
import '../../../core/controller/global_master_data_controller.dart';
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
        // Navigate to home screen immediately
        Get.offAll(() => const HomeScreen());
        
        // Start master data sync in background after navigation
        // Use Future.microtask to ensure it runs after the current frame
        Future.microtask(() {
          _startMasterDataSync();
        });
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
            iconColor: AppColors.red,
            confirmText: "OK",
            onConfirm: () => Get.back(),
          ),
        );
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

  Future<void> _startMasterDataSync() async {
    try {
      debugPrint("_startMasterDataSync: Starting master data sync");
      final globalData = Get.find<GlobalMasterDataController>();
      await globalData.initOnLogin();

      debugPrint("_startMasterDataSync: Checking if MasterDataSyncService is registered");
      if (Get.isRegistered<MasterDataSyncService>()) {
        debugPrint("_startMasterDataSync: MasterDataSyncService is registered, starting sync");
        final syncService = Get.find<MasterDataSyncService>();
        // Sync master data from API first
        debugPrint("_startMasterDataSync: Calling syncMasterDataFromAPI");
        await syncService.syncMasterDataFromAPI();
        // Then sync failure lists with null lastSyncDate to get all data at login
        debugPrint("_startMasterDataSync: Calling syncFailureList for Station");
        await syncService.syncFailureList('Station', forceFullSync: true);
        debugPrint("_startMasterDataSync: Calling syncFailureList for Maintenance");
        await syncService.syncFailureList('Maintenance', forceFullSync: true);
        debugPrint("_startMasterDataSync: Calling syncPendingSubmissions");
        await syncService.syncPendingSubmissions();
        debugPrint("_startMasterDataSync: All syncs completed");
      } else {
        debugPrint("_startMasterDataSync: MasterDataSyncService is NOT registered");
      }
    } catch (e) {
      debugPrint("_startMasterDataSync: Error during sync - $e");
    }
  }
}
