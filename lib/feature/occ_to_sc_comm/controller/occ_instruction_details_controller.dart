import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../service/auth_manager.dart';
import '../model/occ_instruction_detail_model.dart';
import '../service/occ_to_sc_service.dart';

class InstructionDetailsController extends GetxController {
  InstructionDetailsController({
    required this.instructionId,
    required this.isOcc,
    this.stationId = 0,
    OccToScService? occToScService,
  }) : _occToScService = occToScService ?? OccToScService();

  final int instructionId;
  final bool isOcc;
  final int stationId;

  final OccToScService _occToScService;

  final RxBool isLoading = false.obs;

  final Rx<OccInstructionDetail?> instruction =
  Rx<OccInstructionDetail?>(null);

  // Replace with actual login user id
  int get currentUserId => 1;

  String get role => isOcc ? 'OCC' : 'SC';

  // Only Station Controllers acknowledge instructions.
  bool get canAcknowledge => !isOcc;

  // ================================================================
  // Acknowledge form
  // ================================================================

  final TextEditingController remarkController = TextEditingController();

  final RxBool isSubmittingAcknowledgement = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInstructionDetails();
  }

  @override
  void onClose() {
    remarkController.dispose();
    super.onClose();
  }

  Future<void> fetchInstructionDetails() async {
    isLoading.value = true;

    final prefs = await SharedPreferences.getInstance();

    String stationId =
        prefs.getString('selectedStationID') ?? '';
    final String? userId= await AuthManager().getUserId();
    print("station id is $stationId--$userId---$role---$instructionId");

    try {
      final response = await _occToScService.getInstructionById(
        userId: userId??'',
        role: role,
        instructionId: instructionId,
        stationId: stationId,
      );

      if (!response.success) {
        throw OccToScException(
          response.message.isNotEmpty
              ? response.message
              : 'Unable to fetch instruction details.',
        );
      }

      instruction.value = response.data;
    } catch (e, stackTrace) {
      debugPrint('fetchInstructionDetails error: $e');
      debugPrint(stackTrace.toString());

      Get.snackbar(
        'Error',
        e is OccToScException
            ? e.message
            : 'Unable to load instruction details.',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> acknowledgeInstruction() async {
    if (remarkController.text.trim().isEmpty) {
      Get.snackbar(
        'Remark Required',
        'Please add a remark before acknowledging.',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    isSubmittingAcknowledgement.value = true;

    try {
      final response = await _occToScService.acknowledgeInstruction(
        userId: currentUserId,
        role: role,
        instructionId: instructionId,
        stationId: stationId,
        remark: remarkController.text.trim(),
      );

      if (!response.success) {
        throw OccToScException(
          response.message.isNotEmpty
              ? response.message
              : 'Unable to submit acknowledgement.',
        );
      }

      Get.snackbar(
        'Success',
        'Instruction acknowledged successfully.',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      remarkController.clear();

      // Refresh so the details screen reflects the new acknowledged state.
      await fetchInstructionDetails();
    } catch (e, stackTrace) {
      debugPrint('acknowledgeInstruction error: $e');
      debugPrint(stackTrace.toString());

      Get.snackbar(
        'Error',
        e is OccToScException
            ? e.message
            : 'Unable to submit acknowledgement.',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmittingAcknowledgement.value = false;
    }
  }
}