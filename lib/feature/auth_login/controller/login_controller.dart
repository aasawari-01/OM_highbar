import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../utils/widgets/cust_popup.dart';
import '../../tabs/view/home_screen.dart';
import '../../failure/service/failure_service.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_loader.dart';

import '../service/auth_service.dart';
import '../model/login_response.dart';
import '../../../service/auth_manager.dart';
import '../../../service/session_controller.dart';
import '../../../service/master_data_sync_service.dart';
import '../../../core/models/label_value.dart';
import '../../../constants/app_constants.dart';
import '../../../constants/colors.dart';

class LoginController extends GetxController {
  LoginController({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;
  final FailureService _failureService = FailureService();

  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool rememberMe = false.obs;
  final RxList<LabelValue> popupStationList = <LabelValue>[].obs;
  final RxBool isPopupStationLoading = false.obs;

  Future<void> _showStationSelectionPopup() async {
    isPopupStationLoading.value = true;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white1,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDarkSecondary,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(15),
            child: Obx(() {
              if (isPopupStationLoading.value) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CustLoader(),
                    const SizedBox(height: 16),
                    Text("Fetching stations...", style: TextStyle(color: AppColors.textDarkSecondary)),
                  ],
                );
              }

              final session = Get.find<SessionController>();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.back();
                      },
                      child: const Icon(Icons.close, color: AppColors.textDarkPrimary, size: 24),
                    ),
                  ),
                  CustText(name: "Select Station", size: AppConstants.headerSize, color: AppColors.black, fontWeightName: FontWeight.w600),
                  const SizedBox(height: 16),
                  CustDropdown(
                    label: "Station",
                    hint: "Select Station",
                    items: popupStationList
                        .map((e) => e.label ?? '')
                        .toList(),
                    selectedValue: session.selectedStationName.value,
                    onChanged: (val) {
                      session.selectedStationName.value = val;
                      session.selectedStationId.value = popupStationList
                          .firstWhere((e) => e.label == val,
                          orElse: () => LabelValue(value: "0"))
                          .value;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: CustOutlineButton(
                          name: "Cancel",
                          size: double.infinity,
                          sHeight: 35,
                          onSelected: (_) {
                            Get.back();
                            Get.back();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustButton(
                          name: "OK",
                          size: double.infinity,
                          sHeight: 35,
                          onSelected: (_) async {
                            if (session.selectedStationName.value != null && session.selectedStationName.value!.isNotEmpty) {
                              final stationId = int.tryParse(session.selectedStationId.value ?? '0') ?? 0;
                              final stationName = session.selectedStationName.value ?? '';
                              
                              EasyLoading.show(status: 'Saving station...');
                              final success = await _failureService.saveUserStationDetails(stationId, stationName);
                              EasyLoading.dismiss();
                              
                              if (success) {
                                Get.back();
                                // Navigate to home screen
                                Get.offAll(() => const HomeScreen());
                                // Start master data sync in background
                                Future.microtask(() async {
                                  try {
                                    await _startMasterDataSync();
                                  } catch (e) {
                                    debugPrint("Error syncing data after login: $e");
                                  }
                                });
                              } else {
                                Get.snackbar("Error", "Failed to save station details");
                              }
                            } else {
                              Get.snackbar("Error", "Please select a station",
                                backgroundColor: Colors.red.withOpacity(0.9),
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final stations = await _failureService.getStationNames();
      popupStationList.assignAll(stations);
    } catch (e) {
      debugPrint('Error fetching stations: $e');
    } finally {
      isPopupStationLoading.value = false;
    }
  }

  Future<void> _startMasterDataSync() async {
    if (Get.isRegistered<MasterDataSyncService>()) {
      final syncService = Get.find<MasterDataSyncService>();
      try {
        await syncService.syncMasterData();
        await syncService.syncFailureList('Station');
        await syncService.syncFailureList('Maintenance');
        await syncService.syncPendingSubmissions();
      } catch (e) {
        debugPrint("Error syncing data after login: $e");
      }
    }
  }

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
        // Show station selection popup before syncing
        await _showStationSelectionPopup();

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

