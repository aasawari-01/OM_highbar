import 'package:dart_des/dart_des.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../constants/app_constants.dart';
import '../../../constants/colors.dart';
import '../../../constants/strings.dart';
import '../../../core/models/label_value.dart';
import '../../../service/auth_manager.dart';
import '../../../service/local_database_service.dart';
import '../../../service/master_data_sync_service.dart';
import '../../../service/session_controller.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_popup.dart';
import '../../../utils/network_utils.dart';
import '../../auth_login/model/login_response.dart';
import '../model/failure_detail_response.dart';
import '../model/joint_inspection_history.dart';
import '../model/failure_list_response.dart';
import 'failure_list_controller.dart';
import '../../../core/models/functional_location.dart';
import '../../../core/models/equipment.dart';
import '../service/failure_service.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import 'failure_form_state.dart';
import 'failure_rca_logic.dart';
import 'failure_material_logic.dart';
import 'failure_submit_logic.dart';
import 'failure_joint_inspection_logic.dart';
import 'failure_data_loading_logic.dart';
import 'failure_ui_helper_logic.dart';

class CreateFailureController extends GetxController with FailureFormState, FailureRcaLogic, FailureMaterialLogic, FailureSubmitLogic, FailureJointInspectionLogic, FailureDataLoadingLogic, FailureUIHelperLogic {
  final FailureService _failureService = FailureService();
  final ApiClient _apiClient = ApiClient();
  late final MasterDataSyncService _syncService;

  /// Shows a validation error snackbar with the first error.
  void _showErrorDialog(String message) {
    final lines = message.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;
    Get.snackbar(
      'Validation Error',
      lines.first,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void showErrorDialog(String message) {
    _showErrorDialog(message);
  }

  void showPendingJointInspectionPopup() {
    Get.dialog(
      CustPopup(
        title: 'Joint Inspection Pending',
        message: 'Joint inspection is pending. Please close this first.',
        showIcon: true,
        icon: Icons.error_outline,
        iconColor: AppColors.darkRed,
        confirmText: 'OK',
        onCancel: () {
          selectedUserStatus.value="Select User status";
          Get.back();
        },
        onConfirm: () {
          selectedUserStatus.value="Select User status";
          Get.back();
        },
      ),
      barrierDismissible: false,
    );
  }

  /// Refreshes the appropriate failure list controller based on user role and failure type
  void _refreshFailureListAfterSubmission(bool isStation) {
    final session = Get.find<SessionController>();
    final role = session.selectedRole.value?.roleDescr ?? '';
    final isJE = role.contains('Junior Engineer');
    final isStationController = role.contains('Station Controller');
    
    if (isStationController) {
      // For Station Controller, sync Station failures to local DB and refresh
      if (Get.isRegistered<MasterDataSyncService>()) {
        Future.microtask(() async {
          try {
            await Get.find<MasterDataSyncService>().syncFailureList('Station');
          } catch (e) {
            debugPrint("Error syncing failure list after creation: $e");
          }
        });
      }
    } else if (isJE) {
      // For JE users, refresh the appropriate controller based on failure type
      final controllerTag = isStation ? 'Station' : 'Maintenance';
      if (Get.isRegistered<FailureListController>(tag: controllerTag)) {
        Future.microtask(() async {
          try {
            await Get.find<FailureListController>(tag: controllerTag).fetchFailures();
          } catch (e) {
            debugPrint("Error refreshing JE failure list: $e");
          }
        });
      }
    }
  }

  void onFailureAttendedDateSelected(DateTime? date) {
    selectedFailureAttendedDate.value = date;
    if (selectedActualFailureRectifiedDate.value != null && date != null) {
      if (selectedActualFailureRectifiedDate.value!.isBefore(date)) {
        selectedActualFailureRectifiedDate.value = null;
      }
    }
  }

  void onActualFailureRectifiedDateSelected(DateTime? date) {
    selectedActualFailureRectifiedDate.value = date;
    if (date == null || selectedFailureOccurrenceDate.value == null) {
      showReasonForDelayPopup.value = false;
      reasonForDelayId.value = 0;
      selectedReasonForDelay.value = null;
      return;
    }

    final duration = date.difference(selectedFailureOccurrenceDate.value!);
    final isCritical = selectedPriority.value?.toLowerCase() == "critical";

    if (isCritical) {
      if (duration.inHours >= 3) {
        if (reasonForDelayId.value == 0) {
          showReasonForDelayPopupDialog();
        }
      } else {
        reasonForDelayId.value = 0;
        selectedReasonForDelay.value = null;
      }
    } else {
      if (duration.inDays >= 1) {
        if (reasonForDelayId.value == 0) {
          showReasonForDelayPopupDialog();
        }
      } else {
        reasonForDelayId.value = 0;
        selectedReasonForDelay.value = null;
      }
    }
  }

  void showReasonForDelayPopupDialog() {
    Get.dialog(
      CustPopup(
        title: "Reason For Delay",
        showIcon: true,
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.orangeColor,
        customContent: Obx(
              () => CustDropdown(
            label: "Reason For Delay *",
            hint: "Select Reason For Delay",
            items: reasonForDelayList.map((e) => e.label ?? "").toList(),
            selectedValue: selectedReasonForDelay.value,
            onChanged: (value) {
              selectedReasonForDelay.value = value;

              final match = reasonForDelayList.firstWhere(
                    (e) => e.label == value,
                orElse: () => LabelValue(value: "0"),
              );

              reasonForDelayId.value =
                  int.tryParse(match.value ?? "0") ?? 0;
            },
          ),
        ),

        confirmText: "Save",
        cancelText: "Cancel",

        onConfirm: () {
          Get.back();
        },

        onCancel: () {
          selectedActualFailureRectifiedDate.value = null;
          Get.back();
        },
      ),
      barrierDismissible: false,
    );
  }




  @override
  void onInit() {
    super.onInit();
    _syncService = Get.find<MasterDataSyncService>();
    _initializeAllData();
  }

  Future<void> _initializeAllData() async {
    pushLoading();
    try {
      await Future.wait([
        fetchMasterJointInspectionDepartments(),
        loadMasterDataFromDb(),
        loadMasterDropdownsFromDb(refreshIfEmpty: true),
        loadDepartments(),
      ]);
    } catch (e) {
      debugPrint("Error in _initializeAllData: $e");
    } finally {
      popLoading();
    }
  }

  @override
  void onClose() {
    dispose();
    super.onClose();
  }

  int resolveNotificationId() {
    if (notificationId.value > 0) return notificationId.value;
    return int.tryParse(encryptedId.value) ?? 0;
  }

  final popupStationList = <LabelValue>[].obs;
  final isPopupStationLoading = false.obs;
  final session = Get.find<SessionController>();


  Future<void> fetchAndShowStationPopup() async {
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
                    const Text("Fetching stations...", style: TextStyle(color: AppColors.textDarkSecondary)),
                  ],
                );
              }

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
                      child: const Icon(TablerIcons.x, color: AppColors.textDarkPrimary, size: 24),
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
                          onSelected: (_) {
                            if (session.selectedStationName.value != null && session.selectedStationName.value!.isNotEmpty) {
                              Get.back();
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

  Future<void> loadJointInspectionDetails(String failureNo) async {
    encryptedId.value = failureNo;
    notificationId.value = 0;
    jointInspectionFailureNo.value = "";
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;

      final apiClient = ApiClient();
      final response = await apiClient.get(
        '${AppUrls.getJointInspectionJEScreenDetails}?notificationID=$failureNo&userId=$userId',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final responseOutput = jsonBody['responseOutput'];

        debugPrint("GetJointInspectionJEScreenDetails responseCode: ${jsonBody['responseCode']}");
        debugPrint("GetJointInspectionJEScreenDetails responseOutput keys: ${responseOutput?.keys.toList()}");

        if (jsonBody['responseCode'] == 200 && responseOutput != null) {
          final List<dynamic>? deptListJson =
          responseOutput['department'] as List?;
          if (deptListJson != null) {
            departmentList.assignAll(deptListJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .toList());
            debugPrint("JI departmentList populated with ${departmentList.length} items");
            debugPrint("JI departmentList first 3: ${departmentList.take(3).toList()}");
          }
          final List<dynamic>? userListJson =
          responseOutput['personResponsible'] as List?;
          if (userListJson != null) {
            userList.assignAll(userListJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .toList());
            debugPrint("JI userList populated with ${userList.length} items");
            debugPrint("JI userList first 3: ${userList.take(3).toList()}");
          }
          final List<dynamic>? funcLocJson =
          responseOutput['functionalLocation'] as List?;
          if (funcLocJson != null) {
            final filtered = funcLocJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .where((e) => e.label?.toLowerCase() != 'select')
                .map((e) => LabelValue(label: e.label ?? '', value: e.value ?? ''))
                .toList();
            functionalLocationList.assignAll(filtered);
            debugPrint("JI functionalLocationList populated with ${functionalLocationList.length} items");
          }
          final List<dynamic>? equipJson = responseOutput['equipment'] as List?;
          if (equipJson != null) {
            final filtered = equipJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .where((e) => e.label?.toLowerCase() != 'select')
                .map((e) => LabelValue(label: e.label ?? '', value: e.value ?? ''))
                .toList();
            equipmentList.assignAll(filtered);
            debugPrint("JI equipmentList populated with ${equipmentList.length} items");
          }
          final List<dynamic>? objPartJson =
          responseOutput['objectPart'] as List?;
          if (objPartJson != null) {
            objectDataList.assignAll(objPartJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .toList());
          }
          final List<dynamic>? matCodeJson =
          responseOutput['materialCode'] as List?;
          if (matCodeJson != null) {
            materialDataList.assignAll(matCodeJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .toList());
          }
          final List<dynamic>? statusJson = responseOutput['status'] as List?;
          if (statusJson != null) {
            userStatusList.assignAll((statusJson
                .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
                .toList())
                .where((status) {
              final val = int.tryParse(status.value ?? "999") ?? 999;
              return val == 0 || val <= 29;
            }).toList());
          }

          final List<dynamic>? historyJson =
          responseOutput['notificationHistory'] as List?;
          if (historyJson != null) {
            notificationDescriptionHistoryList.assignAll(historyJson
                .map((e) => NotificationHistory.fromJson(
                e as Map<String, dynamic>))
                .toList());
          }

          final List<dynamic>? actionHistoryJson =
              responseOutput['notificationActionHistory'] as List? ??
                  responseOutput['getNotificationActionUserHistory'] as List?;
          if (actionHistoryJson != null) {
            notificationHistoryList.assignAll(actionHistoryJson
                .map((e) => NotificationActionHistory.fromJson(
                e as Map<String, dynamic>))
                .toList());
            debugPrint("JI notificationHistoryList populated with ${notificationHistoryList.length} items");
          }

          final Map<String, dynamic>? je = responseOutput['jeScreenDetails'];
          debugPrint("GetJointInspectionJEScreenDetails jeScreenDetails: $je");
          if (je == null) {
            debugPrint("ERROR: jeScreenDetails is null in API response");
            errorMessage.value = "jeScreenDetails is null in API response";
          } else {
            debugPrint("jeScreenDetails keys: ${je.keys.toList()}");
            debugPrint("jeScreenDetails deptId_JI: ${je['deptId_JI']}");
            debugPrint("jeScreenDetails assignedUserId_JI: ${je['assignedUserId_JI']}");
            debugPrint("jeScreenDetails functionLocation_JI: ${je['functionLocation_JI']}");
            debugPrint("jeScreenDetails equipmentId_JI: ${je['equipmentId_JI']}");
          }
          if (je != null) {
            final detailFailureNo = je['Id']?.toString().trim();
            final detailNotificationId =
            je['notificationId']?.toString().trim();
            notificationId.value =
                int.tryParse(detailNotificationId ?? "") ?? 0;
            jointInspectionFailureNo.value =
            je['failureNo']?.toString().trim().isNotEmpty == true
                ? je['failureNo'].toString().trim()
                : detailFailureNo?.isNotEmpty == true
                ? detailFailureNo!
                : detailNotificationId?.isNotEmpty == true
                ? detailNotificationId!
                : "";
            notificationCode.value = je['notificationCode'] ?? "";
            mainStatusName.value = je['status'];
            selectedPriority.value = je['priorityType'];
            priorityDisplayController.text = je['priorityType']?.toString() ?? "";
            failureDescriptionController.text = je['failureDescriptions'] ?? "";

            selectedDepartment.value = departmentList
                .firstWhere((e) => e.value == je['deptId']?.toString(),
                orElse: () => LabelValue(label: ""))
                .label;
            departmentDisplayController.text =
                selectedDepartment.value ?? je['deptId']?.toString() ?? "";

            debugPrint("JE: selectedDepartment.value=${selectedDepartment.value}");
            debugPrint("JE: departmentList sample: ${departmentList.take(3).map((e) => {'label': e.label, 'value': e.value, 'uniqueId': e.uniqueId}).toList()}");
            
            // Filter functional locations based on department's workCenter
            _updateFunctionalLocationAndEquipmentOptions();

            selectedLocation.value = je['locationTypeName']?.toString();
            final funcLocName = (textOrNull(je['functionalLocationName']) ??
                labelForValue(functionalLocationList, je['functionLocationId']));
            selectedFunctionalLocation.value = funcLocName;
            final equipName = (textOrNull(je['equipmentName']) ??
                labelForValue(equipmentList, je['equipmentId']));
            selectedEquipmentNumber.value = equipName;
            locationDisplayController.text = selectedLocation.value ?? "";
            functionalLocationDisplayController.text =
                selectedFunctionalLocation.value ?? "";
            equipmentDisplayController.text = selectedEquipmentNumber.value ?? "";

            debugPrint('Joint Inspection: actualFailureOccuranceOn from API = ${je['actualFailureOccuranceOn']}');
            selectedFailureOccurrenceDate.value =
            je['actualFailureOccuranceOn'] != null
                ? _parseDate(je['actualFailureOccuranceOn']!)
                : null;
            debugPrint('Joint Inspection: selectedFailureOccurrenceDate = ${selectedFailureOccurrenceDate.value}');

            selectedPersonResponsible.value =
                labelForValue(userList, je['personResponsible']);
            personResponsibleDisplayController.text =
                selectedPersonResponsible.value ??
                    je['personResponsible']?.toString() ??
                    "";

            isPtwRequired.value = je['isPTWReq'] ?? false;
            if (isPtwRequired.value) {
              ptwNumberController.text = je['ptwNo'] ?? "";
            }

            selectedFailureAttendedDate.value = je['failureAttendedOn'] != null
                ? _parseDate(je['failureAttendedOn']!)
                : null;
            selectedActualFailureRectifiedDate.value =
            je['actualFailureRectifiedOn'] != null
                ? _parseDate(je['actualFailureRectifiedOn']!)
                : null;

            isServiceAffected.value = je['isServiceAffected'] ?? false;
            if (isServiceAffected.value) {
              trainDelayMinController.text =
                  je['trainDelayInMin']?.toString() ?? "0";
              trainDelayNosController.text =
                  je['trainDelayInNo']?.toString() ?? "0";
              trainCancelNosController.text =
                  je['noOfTranCancel']?.toString() ?? "0";
              trainWithdrawalNosController.text =
                  je['noOfTranWithdrawal']?.toString() ?? "0";
              trainReplaceNosController.text =
                  je['noOfTrainReplace']?.toString() ?? "0";
            }

            isPassengerDeboarding.value = je['isPassengerDeboarding'] ?? false;
            if (isPassengerDeboarding.value) {
              trainDeboardedNosController.text =
                  je['noofTrainDeboarded']?.toString() ?? "0";
            }

            isJointInspection.value = je['isJointInspectionReq'] ?? false;
            isSparePartReplaced.value = je['isHardwareReplaced'] ?? false;
            isSicRequired.value = je['isSICReq'] ?? false;

            isPassengerAffected.value = je['isPassengerAffected'] ?? false;
            if (isPassengerAffected.value) {
              passengersAffectedCountController.text =
                  je['noOfPassengerAffected']?.toString() ?? "";
              trappedDurationController.text =
                  je['trappedDuration']?.toString() ?? "";
              rescuedDurationController.text =
                  je['rescuedDuration']?.toString() ?? "";
            }

            debugPrint("JI deptId_JI: ${je['deptId_JI']}, assignedUserId_JI: ${je['assignedUserId_JI']}");
            debugPrint("JI departmentList length: ${departmentList.length}, userList length: ${userList.length}");
            jiDepartment.value = labelForValue(departmentList, je['deptId_JI']);
            jiAssignTo.value =
                labelForValue(userList, je['assignedUserId_JI']);
            debugPrint("JI jiDepartment.value: ${jiDepartment.value}, jiAssignTo.value: ${jiAssignTo.value}");
            if (jiDepartment.value == null || jiDepartment.value!.isEmpty) {
              jiDepartment.value = je['deptId_JI']?.toString() ?? je['DeptId_JI']?.toString() ?? je['departmentName_JI']?.toString();
              debugPrint("JI jiDepartment fallback: ${jiDepartment.value}");
            }
            if (jiAssignTo.value == null || jiAssignTo.value!.isEmpty) {
              jiAssignTo.value = je['assignedUserId_JI']?.toString() ?? je['AssignedUserId_JI']?.toString() ?? je['assignedUserName_JI']?.toString();
              debugPrint("JI jiAssignTo fallback: ${jiAssignTo.value}");
            }
            jiDepartmentDisplayController.text = jiDepartment.value ?? "";
            jiAssignToDisplayController.text = jiAssignTo.value ?? "";
            
            // Filter functional locations based on JI department's workCenter
            _filterJiFunctionalLocations();
            
            jiFunctionalLocation.value =
                textOrNull(je['functionalLocationName_JI']) ??
                    labelForValue(
                        functionalLocationList, je['functionLocation_JI']);
            jiRemark.value = je['remark_JI']?.toString();
            jiRemarkDisplayController.text = jiRemark.value ?? "";
            jiEquipmentId.value = je['equipmentId_JI'] is int
                ? je['equipmentId_JI']
                : int.tryParse(je['equipmentId_JI']?.toString() ?? "0");
            jiFunctionalLocationId.value =
                je['functionLocation_JI']?.toString();
            selectedJiFunctionalLocation.value = jiFunctionalLocation.value;
            jiEquipmentNumber.value =
                labelForValue(equipmentList, je['equipmentId_JI']);
            selectedJiEquipmentNumber.value = jiEquipmentNumber.value;
          }

          final List<dynamic>? rcaJson =
          responseOutput['failureRectificationDetails'] as List?;
          if (rcaJson != null && rcaJson.isNotEmpty) {
            rcaDetailsList.clear();
            for (var fault in rcaJson) {
              final rectId = fault['RectId'];

              final List<Map<String, dynamic>> matchedRootCauses = [];
              final List<dynamic>? rootCauseJson =
              responseOutput['failureRootCauseDetails'] as List?;
              if (rootCauseJson != null) {
                for (var rc
                in rootCauseJson.where((r) => r['RectId'] == rectId)) {
                  matchedRootCauses.add({
                    'rootCauseId': rc['RectId']?.toString() ?? "0",
                    'rootCause': rc['RCADescs'] ?? "N/A",
                    'rootCauseText': rc['RCAText'] ?? "",
                    'imagePath': null,
                  });
                }
              }

              final List<Map<String, dynamic>> matchedActions = [];
              final List<dynamic>? actionJson =
              responseOutput['failureActionDetails'] as List?;
              if (actionJson != null) {
                for (var ac in actionJson.where((a) => a['RectId'] == rectId)) {
                  matchedActions.add({
                    'actionTakenId': ac['RectId']?.toString() ?? "0",
                    'actionTaken': ac['ActionDescs'] ?? "N/A",
                    'actionTakenText': ac['ActionText'] ?? "",
                    'imagePath': null,
                  });
                }
              }

              rcaDetailsList.add({
                'ObjectPartId': "0",
                'objectPart': fault['ObjectPart'] ?? "",
                'objectPartText': fault['ObjectPartText'] ?? "",
                'FaultId': "0",
                'fault': fault['Fault'] ?? "",
                'faultText': fault['FaultText'] ?? "",
                'rootCauses': matchedRootCauses,
                'actionTakens': matchedActions,
              });
            }
          }

          beforeImagesList.clear();
          afterImagesList.clear();
          rcaImagesList.clear();
          final List<dynamic>? beforeImgs =
          responseOutput['beforeImageDetails'] as List?;
          if (beforeImgs != null) {
            for (var img in beforeImgs) {
              final fileName = img['FileName']?.toString() ?? '';
              if (fileName.isNotEmpty) {
                beforeImagesList.add({
                  'name': fileName.split('/').last,
                  'path': fileName,
                  'isNetwork': true
                });
              }
            }
          }
          final List<dynamic>? afterImgs =
          responseOutput['afterImageDetails'] as List?;
          if (afterImgs != null) {
            for (var img in afterImgs) {
              final fileName = img['FileName']?.toString() ?? '';
              if (fileName.isNotEmpty) {
                afterImagesList.add({
                  'name': fileName.split('/').last,
                  'path': fileName,
                  'isNetwork': true
                });
              }
            }
          }
          final List<dynamic>? rcaImgs =
          responseOutput['rcaImageDetails'] as List?;
          if (rcaImgs != null) {
            for (var img in rcaImgs) {
              final fileName = img['FileName']?.toString() ?? '';
              if (fileName.isNotEmpty) {
                rcaImagesList.add({
                  'name': fileName.split('/').last,
                  'path': fileName,
                  'isNetwork': true
                });
              }
            }
          }
        } else {
          errorMessage.value =
              jsonBody['responseMessage'] ?? "Failed to load details";
        }
      } else {
        errorMessage.value =
        "Failed to load data. Status code: ${response.statusCode}";
      }
    } catch (e) {
      errorMessage.value = "An error occurred: $e";
      debugPrint("loadJointInspectionDetails error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitJointInspection() async {
    if (selectedJiFunctionalLocation.value == null || selectedJiFunctionalLocation.value!.isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Please select Functional Location.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (jiUserRemarkController.text.trim().isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Please enter User's Remark.",
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      EasyLoading.show(status: 'Submitting...');
      final String? userIdStr = await AuthManager().getUserId();
      final String? userName = await AuthManager().getUserName();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;
      final failureNo = jointInspectionFailureNo.value.trim();
      if (failureNo.isEmpty) {
        EasyLoading.dismiss();
        Get.snackbar(
          "Validation Error",
          "Unable to resolve Failure No. Please reload the details and try again.",
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final payload = {
        "FailureNo": failureNo,
        "FunctionLocation_JI": jiFunctionalLocationId.value ?? "",
        "EquipmentId_JI": jiEquipmentId.value ?? 0,
        "UserRemark_JI": jiUserRemarkController.text.trim(),
        "CreatedBy": userId,
        "CreatedByName": userName ?? ""
      };

      final message = await _failureService.submitJIScreenData(payload);
      Get.back(result: true);
      Get.snackbar(AppStrings.success, message,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(AppStrings.error, e.toString());
    } finally {
      EasyLoading.dismiss();
    }
  }
  List<JointInspectionHistory> _newestFirst(List<JointInspectionHistory> list) {
    final sorted = List<JointInspectionHistory>.from(list);
    sorted.sort((a, b) => (b.jiId ?? 0).compareTo(a.jiId ?? 0));
    return sorted;
  }

  Future<void> loadFailureDetails(String failureNo) async {
    encryptedId.value = failureNo;
    notificationId.value = 0;
    jointInspectionHistoryList.clear();
    pushLoading();
    try {
      isLoading.value = true;
      errorMessage.value = "";
      locationTypeList.clear();
      functionalLocationList.clear();
      equipmentList.clear();
      await loadMasterDataFromDb();

      final result = await _failureService.getFailureDetails(failureNo);

      if (result.responseCode == 200 && result.responseOutput != null) {
        final output = result.responseOutput!;

        notificationTypeList
            .assignAll(output.getCorrNotificationTypeList ?? []);
        natureOfWorkList.assignAll(output.getNatureOfWorkList ?? []);
        departmentList.assignAll(output.getDepartmentList ?? []);
        userList.assignAll(output.getUserList ?? []);
        objectDataList.assignAll(output.getObjectData ?? []);
        materialDataList.assignAll(output.getMaterialData ?? []);
        reasonForDelayList.assignAll(output.getReasonForDelayList ?? []);
        final statuses = output.getUserStatus ?? [];
        userStatusList.assignAll(statuses.where((status) {
          final val = int.tryParse(status.value ?? "999") ?? 999;
          return val == 0 || val <= 29;
        }).toList());
        storageLocationList.assignAll(output.getStorageLocation ?? []);
        faultTypeList.assignAll(output.getFaultData ?? []);
        _mergeLocationDropdownsFromOutput(output);

        notificationHistoryList.assignAll(
            output.getNotificationActionUserHistory ?? []);

        notificationDescriptionHistoryList.assignAll(
            output.getNotificationHistory ?? []);

        if (output.getJoinInspectionHistory != null) {
          jointInspectionHistoryList.assignAll(
              output.getJoinInspectionHistory!
                  .map((item) => JointInspectionHistory.fromJson(item))
                  .toList()
          );
        }

        if (output.getCreateVMModel != null) {
          final model = output.getCreateVMModel!;
          encryptedId.value = (model.id != null && model.id!.isNotEmpty)
              ? model.id!
              : failureNo;
          notificationId.value = model.notificationId ?? 0;
          notificationCode.value = model.notificationCode ?? "";
          if (model.category != null && model.category!.trim().isNotEmpty) {
            failureCategory.value = model.category!.trim();
          }

          _applyLocationSelectionsFromModel(model, output: output);
          selectedDepartment.value = departmentList
              .firstWhere(
                  (e) =>
              e.value == model.deptId?.toString() ||
                  e.label == model.deptCode,
              orElse: () => LabelValue(label: model.deptCode))
              .label;

          debugPrint("Main Failure: selectedDepartment.value=${selectedDepartment.value}");
          debugPrint("Main Failure: departmentList sample: ${departmentList.take(3).map((e) => {'label': e.label, 'value': e.value, 'uniqueId': e.uniqueId}).toList()}");

          _refilterFunctionalLocationForCurrentSelections();
          _refilterEquipmentForCurrentSelections();
          final funcLocEntry = masterFunctionalLocations.firstWhere(
                (e) =>
            e['funcLocId']?.toString() == model.functionLocationId?.toString() ||
                e['funcLocation']?.toString() == model.funcLocation?.toString(),
            orElse: () => <String, dynamic>{},
          );
          if (funcLocEntry.isNotEmpty) {
            await _checkMeasurementPoints(funcLocEntry['objectNumber']?.toString());
          } else {
            debugPrint(
              "Measurement check: no masterFunctionalLocations entry found for "
                  "functionLocationId=${model.functionLocationId}, funcLocation=${model.funcLocation}",
            );
          }
          subLocationController.text = model.locationFailure ?? "";

          selectedPriority.value = model.priorityType;
          selectedDepartment.value = departmentList
              .firstWhere(
                  (e) =>
              e.value == model.deptId?.toString() ||
                  e.label == model.deptCode,
              orElse: () => LabelValue(label: model.deptCode))
              .label;

          selectedNotificationType.value = notificationTypeList
              .firstWhere(
                  (e) => e.value == model.corr_NotificationTypeId.toString(),
              orElse: () => LabelValue(label: null))
              .label;

          mainStatusName.value = model.mainStatusName;
          final matchedUserStatus = output.getUserStatus?.firstWhere(
                  (e) => e.value == model.userStatus.toString(),
              orElse: () => LabelValue(label: null));
          selectedUserStatus.value = matchedUserStatus?.label;

          if (model.assignedUserId != null) {
            final matchedUser = userList.firstWhere(
                    (e) =>
                e.value?.toString().trim() ==
                    model.assignedUserId.toString().trim(),
                orElse: () => LabelValue(label: null));
            selectedPersonResponsible.value = matchedUser.label;
            debugPrint(
                "personnnn matched====${selectedPersonResponsible.value} for ID: ${model.assignedUserId}");
          } else {
            selectedPersonResponsible.value = null;
          }
          if (output.getObjectANDFaultList != null) {
            rcaDetailsList.clear();
            for (var fault in output.getObjectANDFaultList!) {
              final rectId = fault['rectId'];

              final List<Map<String, dynamic>> matchedRootCauses = [];
              if (output.getObjectANDFaultRootCauseList != null) {
                for (var rc in output.getObjectANDFaultRootCauseList!
                    .where((r) => r['rectId'] == rectId)) {
                  matchedRootCauses.add({
                    'rootCauseId': rc['rcaId'].toString(),
                    'rootCause': rc['rootCasueName'] ?? "N/A",
                    'rootCauseText': rc['rcaText'] ?? "",
                    'imagePath': null
                  });
                }
              }

              final List<Map<String, dynamic>> matchedActions = [];
              if (output.getObjectANDFaultActionList != null) {
                for (var ac in output.getObjectANDFaultActionList!
                    .where((a) => a['rectId'] == rectId)) {
                  matchedActions.add({
                    'actionTakenId': ac['actionId'].toString(),
                    'actionTaken': ac['actionName'] ?? "N/A",
                    'actionTakenText': ac['actionText'] ?? "",
                    'imagePath': null
                  });
                }
              }

              rcaDetailsList.add({
                'ObjectPartId': fault['objectPartId']?.toString() ?? "0",
                'objectPart': fault['objectName'] ?? "",
                'objectPartText': fault['objectPartText'] ?? "",
                'FaultId': fault['faultId']?.toString() ?? "0",
                'fault': fault['faultName'] ?? "",
                'faultText': fault['faultText'] ?? "",
                'rootCauses': matchedRootCauses,
                'actionTakens': matchedActions,
              });
            }
          }

          if (output.getMaterialReqDetails != null) {
            replacedMaterialsList.clear();
            for (var mat in output.getMaterialReqDetails!) {
              replacedMaterialsList.add({
                'id': mat['id'] ??
                    mat['Id'] ??
                    mat['materialReqId'] ??
                    mat['MaterialReqId'] ??
                    0,
                'Materialid': mat['materialid'] ??
                    mat['materialId'] ??
                    mat['Materialid'],
                'materialCode': mat['materialValue'] ?? "",
                'requiredQty': mat['quantity']?.toString() ?? "0",
                'uom': mat['unitOfMeasurement'] ?? "",
                'issuedQty': mat['issuedQty']?.toString() ?? "0",
                'usedQty': mat['usedQty']?.toString() ?? "0",
                'balanceQty': mat['balanceQty']?.toString() ?? "0",
                'RemainingBalanceQTY': mat['remainingBalanceQTY'] ?? 0,
                'StorageLocation': mat['storageLocation'],
                'storeLocation': mat['storageLocationValue'] ?? "",
              });
            }
          }

          if (output.getMaterialDismantleDetails != null) {
            dismantleMaterialsList.clear();
            deletedDismantleMaterialsList.clear();
            for (var dis in output.getMaterialDismantleDetails!) {
              dismantleMaterialsList.add({
                'id': dis['id'],
                'materialId': dis['materialId'],
                'materialCode': dis['materialValue'] ?? "",
                'oldSerialNumber': dis['oldSerialNumber'] ?? "",
                'newSerialNumber': dis['newSerialNumber'] ?? "",
                'oldSerialDismantleDate': dis['oldSerialNoDismantleDate'],
                'newSerialInstallationDate': dis['newSerialNoInstallationDate'],
              });
            }
          }

          if (replacedMaterialsList.isNotEmpty) {
            isSparePartReplaced.value = true;
          }
          if (dismantleMaterialsList.isNotEmpty) {
            isMaterialDismantle.value = true;
          }

          if (output.getImageBefor != null) {
            beforeImagesList.clear();
            afterImagesList.clear();
            rcaImagesList.clear();
            for (var img in output.getImageBefor!) {
              final fileName = img['fileName']?.toString() ?? '';
              final docType = img['documentType']?.toString() ?? '';
              if (fileName.isNotEmpty) {
                final imgMap = {
                  'name': fileName.split('/').last,
                  'path': fileName,
                  'isNetwork': true
                };
                if (docType == 'BEFORE_NOT') {
                  beforeImagesList.add(imgMap);
                } else if (docType == 'AFTER_NOT') {
                  afterImagesList.add(imgMap);
                } else if (docType == 'RCA_NOT') {
                  rcaImagesList.add(imgMap);
                } else {
                  beforeImagesList.add(imgMap);
                }
              }
            }
          }
          selectedMaterialType.value = mapFailureTypeIdToMaterialType(model.failureTypeId);
          isServiceAffected.value = model.isServiceAffected ?? false;
          isJointInspection.value = model.isJointInspectionReq ?? false;
          isSparePartReplaced.value = model.isHardwareReplaced ?? false;
          isPtwRequired.value = model.isPTWReq ?? false;
          ptwNumberController.text = model.ptwNo ?? "";

          trainDelayMinController.text =
              model.trainDelayInMin?.toString() ?? "";
          trainDelayNosController.text =
              model.trainDelayInNo?.toString() ?? "";
          trainCancelNosController.text =
              model.noOfTranCancel?.toString() ?? "";
          trainWithdrawalNosController.text =
              model.noOfTranWithdrawal?.toString() ?? "";
          trainReplaceNosController.text =
              model.noOfTrainReplace?.toString() ?? "";
          isPassengerDeboarding.value = model.isPassengerDeboarding ?? false;
          trainDeboardedNosController.text =
              model.noofTrainDeboarded?.toString() ?? "";
          _applyPassengerAffectedFromModel(model);

          selectedFailureOccurrenceDate.value =
          model.actualFailureOccuranceOn != null
              ? _parseDate(model.actualFailureOccuranceOn!)
              : null;
          selectedActualFailureRectifiedDate.value =
          model.actualFailureRectifiedDate != null
              ? _parseDate(model.actualFailureRectifiedDate!)
              : null;
          selectedFailureAttendedDate.value =
          model.failureAttendedDate != null
              ? _parseDate(model.failureAttendedDate!)
              : null;
          selectedUnderObservationDate.value =
          (model.underObservationDate != null &&
              model.underObservationDate!.isNotEmpty)
              ? _parseDate(model.underObservationDate!)
              : null;

          if (model.getObjectANDFaultList != null &&
              model.getObjectANDFaultList!.isNotEmpty) {
            rcaDetailsList.clear();
            for (var objFault in model.getObjectANDFaultList!) {
              final rcaId = objFault['rectId'];
              final objectPartId = objFault['objectPartId']?.toString();
              final faultId = objFault['faultId']?.toString();

              final rootCauses = (model.getObjectANDFaultRootCauseList ?? [])
                  .where((rc) =>
              rc['rectId'] == rcaId &&
                  rc['objectPartId'] == objFault['objectPartId'] &&
                  rc['faultId'] == objFault['faultId'])
                  .map((rc) => {
                'rootCauseId': rc['rcaId']?.toString() ?? "0",
                'rootCause': rc['rootCasueName'] ?? "N/A",
                'rootCauseText': rc['rcaText'] ?? "",
                'imagePath': null,
              })
                  .toList();

              final actions = (model.getObjectANDFaultActionList ?? [])
                  .where((act) =>
              act['rectId'] == rcaId &&
                  act['objectPartId'] == objFault['objectPartId'] &&
                  act['faultId'] == objFault['faultId'])
                  .map((act) => {
                'actionTakenId': act['actionId']?.toString() ?? "0",
                'actionTaken': act['actionName'] ?? "N/A",
                'actionTakenText': act['actionText'] ?? "",
                'imagePath': null,
              })
                  .toList();

              rcaDetailsList.add({
                'ObjectPartId': objFault['objectPartId']?.toString() ?? "0",
                'objectPart': objFault['objectName'] ?? "",
                'objectPartText': objFault['objectPartText'] ?? "",
                'FaultId': objFault['faultId']?.toString() ?? "0",
                'fault': objFault['faultName'] ?? "",
                'faultText': objFault['faultText'] ?? "",
                'rootCauses': rootCauses,
                'actionTakens': actions,
              });
            }
          }

          debugPrint("RCA DETAILS LIST LENGTH: ${rcaDetailsList.length}");
          if (rcaDetailsList.isNotEmpty) {
            debugPrint("FIRST RCA ITEM: ${rcaDetailsList.first}");
          }

          selectedActualFailureRectified.value = model.failureType;
          failureRectificationDetailsController.text =
              model.failureRectificationDetails ?? "";

          beforeFiles.clear();
          afterFiles.clear();
          if (model.imagesPaths != null && model.imagesPaths!.isNotEmpty) {
            final images = model.imagesPaths!.split(',');
            for (var img in images) {
              beforeFiles.add({
                'name': img.split('/').last,
                'size': 'N/A',
                'path': img,
              });
            }
          }
          if (model.imagesPathsAfter != null &&
              model.imagesPathsAfter!.isNotEmpty) {
            final images = model.imagesPathsAfter!.split(',');
            for (var img in images) {
              afterFiles.add({
                'name': img.split('/').last,
                'size': 'N/A',
                'path': img,
              });
            }
          }
          if (model.imagesPathsRCA != null &&
              model.imagesPathsRCA!.isNotEmpty) {
            final images = model.imagesPathsRCA!.split(',');
            for (var img in images) {
              afterFiles.add({
                'name': 'RCA_${img.split('/').last}',
                'size': 'N/A',
                'path': img,
              });
            }
          }
        }

      } else {
        errorMessage.value = result.responseMessage ?? 'Failed to load details';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      popLoading();
    }
  }

  Future<void> loadStationFailureDetails(String id) async {
    encryptedId.value = id;
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final output = await _failureService.getStationFailureDetails(id);

      if (output['getFailureCreationDetails'] != null) {
        final details = output['getFailureCreationDetails'];
        originalFailureId.value = details['id'];
        notificationCode.value = details['failureId'] ?? '';
        selectedPriority.value = details['priority'];
        mainStatusName.value = details['statusName'];
        failureDescriptionController.text = details['failureDescription'] ?? '';
        selectedDepartment.value = details['departmentName'];
        originalDepartmentId.value =
            details['departmentId_1'] ?? details['departmentId'];
        selectedLocation.value = details['location'];
        originalLocationId.value = details['locationId'];
        selectedFunctionalLocation.value = details['funcationLocation'];
        subLocationController.text = details['subLocation'] ?? '';
        systemController.text = details['system'] ?? '';
        trainIdController.text = details['trainId'] ?? '';

        if (details['actualFailureOccuranceDate'] != null) {
          selectedFailureOccurrenceDate.value = DateFormat('dd-MM-yyyy HH:mm')
              .parse(details['actualFailureOccuranceDate']);
        }
        if (details['actualFailureCompletedDateTime'] != null) {
          selectedFailureCompletedDate.value = DateFormat('dd-MM-yyyy HH:mm')
              .parse(details['actualFailureCompletedDateTime']);
        }

        selectedFailureReportedBy.value = details['failureReportedby'];
        selectedFailureCategoryType.value = details['failureCategoryTypeText'];
        failureRectificationDetailsController.text =
            details['failureRectificationDetails'] ?? '';

        isTripAffected.value = details['isTripAffected'] ?? false;
        tripDelayUplineController.text =
            details['tripDelayUpline']?.toString() ?? '';
        trainCancelNosController.text =
            details['tripCancel']?.toString() ?? '';
        tripDelayDownlineController.text =
            details['tripDelayDownline']?.toString() ?? '';
        trainDelayMinController.text =
            details['trainDelayInMin']?.toString() ?? '';
        trainWithdrawalNosController.text =
            details['noOfTranWithdrawal']?.toString() ?? '';
        trainReplaceNosController.text =
            details['trainReplace']?.toString() ?? '';

        isPassengerDeboarding.value = details['isTrainDeboarded'] ?? false;
        trainDeboardedNosController.text =
            details['trainDeboarded']?.toString() ?? '';

        isPassengerAffected.value = details['isPassengerAffected'] ?? false;
        passengersAffectedCountController.text =
            details['numberOfPassengerAffected']?.toString() ?? '';
        trappedDurationController.text =
            details['trappedDuration']?.toString() ?? '';
        rescuedDurationController.text =
            details['rescusedDuration']?.toString() ?? '';

        if (output['getImageBefor'] != null) {
          final List<dynamic> images = output['getImageBefor'];
          beforeImagesList.clear();
          for (var img in images) {
            final fileName = img['fileName']?.toString() ?? '';
            if (fileName.isNotEmpty) {
              beforeImagesList.add({
                'name': fileName.split('/').last,
                'path': fileName,
                'isNetwork': true,
              });
            }
          }
        }
      }

      final historyListJson =
      output['getNotificationActionUserHistory'] as List?;
      if (historyListJson != null) {
        notificationHistoryList.assignAll(historyListJson
            .map((e) =>
            NotificationActionHistory.fromJson(e as Map<String, dynamic>))
            .toList());
      }

      final descHistoryJson = output['getNotificationHistory'] as List?;
      if (descHistoryJson != null) {
        notificationDescriptionHistoryList.assignAll(descHistoryJson
            .map((e) => NotificationHistory.fromJson(e as Map<String, dynamic>))
            .toList());
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }


  String? _departmentCodeForLabel(String? label) {
    if (label == null || label.isEmpty) return null;
    final departments = Get.find<SessionController>().departments;
    final match = departments.firstWhere((e) => e.deptName == label,
        orElse: () => DeptMaster());
    return match.deptId?.toString();
  }

  Future<void> updateStationFailureDetails(String id) async {
    try {
      List<String> errors = [];


      if (selectedPriority.value == null || selectedPriority.value!.isEmpty || selectedPriority.value == 'Select') {
        errors.add("Priority is required.");
      }
      if (selectedDepartment.value == null || selectedDepartment.value!.isEmpty || selectedDepartment.value == 'Select') {
        errors.add("Department is required.");
      }
      final description = failureDescriptionController.text.trim();
      if (description.isEmpty) errors.add("Failure Description is required.");

      if (selectedLocation.value == null || selectedLocation.value!.isEmpty || selectedLocation.value == 'Select') {
        errors.add("Location is required.");
      }
      if (selectedFunctionalLocation.value == null || selectedFunctionalLocation.value!.isEmpty || selectedFunctionalLocation.value == 'Select') {
        errors.add("Functional Location is required.");
      }
      if (selectedFailureOccurrenceDate.value == null) {
        errors.add("Actual Failure Occurrence is required.");
      }
      if (selectedFailureCategoryType.value == null || selectedFailureCategoryType.value!.isEmpty || selectedFailureCategoryType.value == 'Select') {
        errors.add("Failure Category Type is required.");
      }

      if (isServiceAffected.value) {
        if (tripDelayUplineController.text.trim().isEmpty) errors.add("Trip Delay Upline is required.");
        if (tripDelayDownlineController.text.trim().isEmpty) errors.add("Trip Delay Downline is required.");
        if (trainCancelNosController.text.trim().isEmpty) errors.add("Train Cancel Nos is required.");
        if (trainDelayMinController.text.trim().isEmpty) errors.add("Train Delay (Min) is required.");
        if (trainWithdrawalNosController.text.trim().isEmpty) errors.add("Train Withdrawal Nos is required.");
        if (trainReplaceNosController.text.trim().isEmpty) errors.add("Train Replace Nos is required.");
      }

      if (isPassengerDeboarding.value) {
        if (trainDeboardedNosController.text.trim().isEmpty) errors.add("Train Deboarded Nos is required.");
      }

      if (isPtwRequired.value) {
        if (ptwNumberController.text.trim().isEmpty) errors.add("PTW Number is required.");
      }

      if (errors.isNotEmpty) {
        Get.snackbar(
          'Validation Error',
          errors.first,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      isLoading.value = true;
      errorMessage.value = "";

      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;

      final int finalLocationId =
          int.tryParse(locationCodeForLabel(selectedLocation.value) ?? "0") ??
              originalLocationId.value ??
              0;
      final int finalDeptId = int.tryParse(
          _departmentCodeForLabel(selectedDepartment.value) ?? "0") ??
          originalDepartmentId.value ??
          0;

      final Map<String, dynamic> payload = {
        "Id": originalFailureId.value ?? 0,
        "PriorityId": 1, // Defaulting as it's not strictly mapped
        "DepartmentIds": finalDeptId.toString(),
        "DepartmentId_1": finalDeptId,
        "DepartmentId_2": 0,
        "DepartmentId_3": 0,
        "FailureDescription": failureDescriptionController.text,
        "LocationId": finalLocationId,
        "SubLocation": subLocationController.text,
        "System": systemController.text,
        "FuncationLocationIds": "",
        "FuncationLocationId_1": 0,
        "FuncationLocationId_2": 0,
        "FuncationLocationId_3": 0,
        "TrainId": trainIdController.text,
        "ActualFailureOccuranceDate":
        selectedFailureOccurrenceDate.value != null
            ? DateFormat("dd-MM-yyyy HH:mm")
            .format(selectedFailureOccurrenceDate.value!)
            : "",
        "FailureReportedbyId": 0,
        "ActualFailureCompletedDateTime":
        selectedFailureCompletedDate.value != null
            ? DateFormat("dd-MM-yyyy HH:mm")
            .format(selectedFailureCompletedDate.value!)
            : null,
        "IsTripAffected": isTripAffected.value,
        "TripDelayUpline": tripDelayUplineController.text.isNotEmpty
            ? int.tryParse(tripDelayUplineController.text)
            : null,
        "TripDelayDownline": tripDelayDownlineController.text.isNotEmpty
            ? int.tryParse(tripDelayDownlineController.text)
            : null,
        "TripCancel": trainCancelNosController.text.isNotEmpty
            ? int.tryParse(trainCancelNosController.text)
            : null,
        "TrainDelayInMin": trainDelayMinController.text.isNotEmpty
            ? int.tryParse(trainDelayMinController.text)
            : null,
        "NoOfTranWithdrawal": trainWithdrawalNosController.text.isNotEmpty
            ? int.tryParse(trainWithdrawalNosController.text)
            : null,
        "IsTrainReplace": trainReplaceNosController.text.isNotEmpty &&
            int.tryParse(trainReplaceNosController.text) != null &&
            int.parse(trainReplaceNosController.text) > 0,
        "TrainReplace": trainReplaceNosController.text.isNotEmpty
            ? int.tryParse(trainReplaceNosController.text)
            : null,
        "IsTrainDeboarded": isPassengerDeboarding.value,
        "TrainDeboarded": trainDeboardedNosController.text.isNotEmpty
            ? int.tryParse(trainDeboardedNosController.text)
            : null,
        "IsPassengerAffected": isPassengerAffected.value,
        "NumberOfPassengerAffected":
        passengersAffectedCountController.text.isNotEmpty
            ? int.tryParse(passengersAffectedCountController.text)
            : null,
        "TrappedDuration": trappedDurationController.text.isNotEmpty
            ? int.tryParse(trappedDurationController.text)
            : null,
        "RescusedDuration": rescuedDurationController.text.isNotEmpty
            ? int.tryParse(rescuedDurationController.text)
            : null,
        "CreatedBy": userId
      };

      try {
        await _failureService.updateStationFailure(payload);
        debugPrint("steppppp");
        Get.back(result: true);
        Get.snackbar(AppStrings.success, AppStrings.failureUpdated,
            backgroundColor: Colors.green, colorText: Colors.white);

      } catch (e, s) {
        debugPrint("UPDATE ERROR: $e");
        debugPrint(s.toString());
        errorMessage.value = e.toString();
        Get.snackbar(AppStrings.error, errorMessage.value,
            backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        isLoading.value = false;
      }
    } catch (e, s) {
      debugPrint("UPDATE ERROR: $e");
      debugPrint(s.toString());
      errorMessage.value = 'Error: $e';
      Get.snackbar(AppStrings.error, errorMessage.value,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> fetchJointInspectionUsers(String deptId) async {
    try {
      isJointUserLoading.value = true;
      jointUserList.clear();
      selectedJointAssignTo.value = null;
      final users = await _failureService.getJIUsers(deptId);
      jointUserList.assignAll(users);
    } catch (e) {
      debugPrint('fetchJointInspectionUsers error: $e');
    } finally {
      isJointUserLoading.value = false;
    }
  }

  void _mergeLocationDropdownsFromOutput(FailureDetailOutput output) {
    final locs = output.getLocationTypeList;
    if (locs != null && locs.isNotEmpty) {
      final filtered = locs.where((e) => e.label?.trim().isNotEmpty == true && e.label?.toLowerCase() != 'select').toList();
      if (filtered.isNotEmpty) {
        for (var item in filtered) {
          if (!locationTypeList.any((e) => e.label == item.label)) {
            locationTypeList.add(item);
          }
        }
      }
    }

    final funcs = output.getFunctionalLocationList;
    if (funcs != null && funcs.isNotEmpty) {
      final filtered = funcs.where((e) => e.value?.trim().isNotEmpty == true && e.value?.toLowerCase() != 'select' && e.label?.toLowerCase() != 'select functional location').toList();
      if (filtered.isNotEmpty) {
        for (var item in filtered) {
          final labelValue = LabelValue(
            label: item.label ?? '',
            value: item.value ?? '',
          );
          if (!functionalLocationList.any((e) => e.label == labelValue.label)) {
            functionalLocationList.add(labelValue);
          }
          if (!masterFunctionalLocations.any((e) => e['funcLocId']?.toString() == item.value)) {
            masterFunctionalLocations.add({
              'funcLocId': item.value,
              'funcLocationName': item.label,
              'location': null,
              'workCenter': null,
              'fromApi': true,
            });
          }
        }
      }
    }

    final equips = output.getEquipmentList ?? output.getEquipmentDetails;
    if (equips != null && equips.isNotEmpty) {
      final filtered = equips.where((e) => e.label?.trim().isNotEmpty == true && e.label?.toLowerCase() != 'select').toList();
      if (filtered.isNotEmpty) {
        for (var item in filtered) {
          if (!equipmentList.any((e) => e.label == item.label)) {
            equipmentList.add(item);
          }
        }
      }
    }
  }

  String? _labelFromValueList(List<LabelValue>? list, int? id) {
    if (list == null || id == null) return null;
    for (final item in list) {
      if (item.value?.toString() == id.toString()) {
        return item.label;
      }
    }
    return null;
  }

  String? _masterLocationName(int? locationTypeId) {
    if (locationTypeId == null) return null;
    final idText = locationTypeId.toString();

    for (final item in locationTypeList) {
      if (item.value == idText) {
        return item.label;
      }
    }

    for (final item in masterLocations) {
      if (item['locationTypeId']?.toString() == idText) {
        return item['locationName']?.toString();
      }
    }
    return null;
  }

  String? _masterFunctionalLocationName(int? functionLocationId) {
    if (functionLocationId == null) return null;
    debugPrint('_masterFunctionalLocationName: Looking for functionLocationId=$functionLocationId');
    debugPrint('_masterFunctionalLocationName: masterFunctionalLocations count=${masterFunctionalLocations.length}');
    debugPrint('_masterFunctionalLocationName: functionalLocationList count=${functionalLocationList.length}');

    // First try to find in functionalLocationList (from JE change notification API)
    for (final item in functionalLocationList) {
      if (item.value == functionLocationId.toString()) {
        debugPrint('_masterFunctionalLocationName: Found match in functionalLocationList - label=${item.label}, value=${item.value}');
        return item.label;
      }
    }

    // Then try masterFunctionalLocations (from DB)
    if (masterFunctionalLocations.isNotEmpty) {
      debugPrint('_masterFunctionalLocationName: First item funcLocId=${masterFunctionalLocations.first['funcLocId']}, funcLocationName=${masterFunctionalLocations.first['funcLocationName']}');
    }
    for (final item in masterFunctionalLocations) {
      final idText = functionLocationId.toString();
      if (item['funcLocId']?.toString() == idText ||
          item['functionLocationId']?.toString() == idText) {
        final name = item['funcLocationName']?.toString();
        debugPrint('_masterFunctionalLocationName: Found match in masterFunctionalLocations - funcLocId=${item['funcLocId']}, funcLocationName=$name');
        return name;
      }
    }
    debugPrint('_masterFunctionalLocationName: No match found for functionLocationId=$functionLocationId');
    return null;
  }

  String? _masterEquipmentName(int? equipmentId) {
    if (equipmentId == null) return null;
    final idText = equipmentId.toString();

    // First try equipmentList (merged from API response)
    for (final item in equipmentList) {
      if (item.value == idText) {
        return item.label;
      }
    }

    // Then try masterEquipments (from local DB)
    for (final item in masterEquipments) {
      if (item['equipId']?.toString() == idText ||
          item['equipmentId']?.toString() == idText) {
        return item['equipmentName']?.toString();
      }
    }
    return null;
  }

  void _applyLocationSelectionsFromModel(
      CreateVMModel model, {
        FailureDetailOutput? output,
      }) {
    String? locationName = model.locationName?.trim();
    locationName ??= _masterLocationName(model.locationTypeId);   // ADD THIS LINE

    String? funcLocation = model.funcLocation?.trim();
    funcLocation ??= _masterFunctionalLocationName(model.functionLocationId);
    String? equipmentName = model.equipmentName?.trim();

    equipmentName ??= _labelFromValueList(equipmentList, model.equipmentId);
    equipmentName ??= _masterEquipmentName(model.equipmentId);

    if (locationName != null && locationName.isNotEmpty) {
      ensureDropdownOption(
        locationTypeList,
        locationName,
        model.locationTypeId?.toString() ?? '',
      );
      selectedLocation.value = locationName;
      locationDisplayController.text = locationName;
    }

    if (funcLocation != null && funcLocation.isNotEmpty) {
      ensureDropdownOption(
        functionalLocationList,
        funcLocation,
        model.functionLocationId?.toString() ?? '',
      );
      selectedFunctionalLocation.value = funcLocation;
      functionalLocationDisplayController.text = funcLocation;
    }

    if (equipmentName != null && equipmentName.isNotEmpty) {
      ensureDropdownOption(
        equipmentList,
        equipmentName,
        model.equipmentId?.toString() ?? '',
      );
      selectedEquipmentNumber.value = equipmentName;
      equipmentDisplayController.text = equipmentName;
    }
  }

  final masterDepartments = <Map<String, dynamic>>[].obs;

  Future<void> _reloadEquipmentsFromDb() async {
    final dbService = LocalDatabaseService();
    final equips = (await dbService.getEquipments()).map((e) => e.toJson()).toList();
    
    final uniqueEquips = {
      for (var e in equips) e['equipmentName']?.toString() ?? '': e
    }
        .values
        .where((e) => (e['equipmentName']?.toString() ?? '').isNotEmpty && (e['equipmentName']?.toString().toLowerCase() != 'select'))
        .toList();
    
    masterEquipments.assignAll(uniqueEquips);
    debugPrint("_reloadEquipmentsFromDb: Reloaded ${masterEquipments.length} equipment from DB");
  }

  /// Returns the raw `funcLocation` code (not funcLocId) for a given funcLocationName label.
  /// Needed because equipment.functionalLocation stores the funcLocation CODE, not the id or display name.
  String? _funcLocationCodeForLabel(String? funcLocationLabel) {
    if (funcLocationLabel == null || funcLocationLabel.isEmpty || funcLocationLabel == 'Select') {
      return null;
    }
    final func = masterFunctionalLocations.firstWhere(
          (e) => e['funcLocationName']?.toString() == funcLocationLabel,
      orElse: () => <String, dynamic>{},
    );
    final code = func['funcLocation']?.toString();
    debugPrint("_funcLocationCodeForLabel: label=$funcLocationLabel, code=$code");
    return (code != null && code.isNotEmpty) ? code : null;
  }

  /// Direct filter: equipment.location == Location.locationTypeCode (if provided)
  /// AND equipment.functionalLocation == FunctionalLocation.funcLocation (if provided).
  List<Map<String, dynamic>> _filterEquipments({String? locCode, String? funcLocCode}) {
    debugPrint("_filterEquipments: locCode=$locCode, funcLocCode=$funcLocCode, total=${masterEquipments.length}");

    Iterable<Map<String, dynamic>> filtered = masterEquipments;

    if (locCode != null && locCode.isNotEmpty) {
      filtered = filtered.where((eq) =>
      (eq['location']?.toString().trim().toUpperCase() ?? '') ==
          locCode.trim().toUpperCase());
    }

    if (funcLocCode != null && funcLocCode.isNotEmpty) {
      filtered = filtered.where((eq) =>
      (eq['functionalLocation']?.toString().trim().toUpperCase() ?? '') ==
          funcLocCode.trim().toUpperCase());
    }

    final result = filtered.toList();
    debugPrint("_filterEquipments: Filtered to ${result.length} equipment");
    return result;
  }
  void onDepartmentChanged(String? departmentLabel) {
    selectedDepartment.value = (departmentLabel == null || departmentLabel == 'Select') ? null : departmentLabel;
    resetFunctionalAndEquipmentSelections();
    _updateFunctionalLocationAndEquipmentOptions();
  }

  void onLocationChanged(String? locationLabel) {
    debugPrint("onLocationChanged: locationLabel=$locationLabel");
    selectedLocation.value = (locationLabel == null || locationLabel == 'Select') ? null : locationLabel;
    resetFunctionalAndEquipmentSelections();
    _updateFunctionalLocationAndEquipmentOptions();
  }

  void _updateFunctionalLocationAndEquipmentOptions() async {
    debugPrint("_updateFunctionalLocationAndEquipmentOptions: Called, masterEquipments.length=${masterEquipments.length}");
    
    // Reload equipment from DB if empty (sync may have completed after controller init)
    if (masterEquipments.isEmpty) {
      debugPrint("_updateFunctionalLocationAndEquipmentOptions: masterEquipments empty, reloading from DB");
      await _reloadEquipmentsFromDb();
    } else {
      debugPrint("_updateFunctionalLocationAndEquipmentOptions: masterEquipments not empty, skipping reload");
    }

    // Safety check: if masterFunctionalLocations is empty, don't crash
    if (masterFunctionalLocations.isEmpty) {
      debugPrint("_updateFunctionalLocationAndEquipmentOptions: masterFunctionalLocations is empty, skipping filter");
      return;
    }

    final hasLocation = selectedLocation.value != null && selectedLocation.value != 'Select';
    final hasDept = selectedDepartment.value != null && selectedDepartment.value != 'Select';

    String? locCode;
    if (hasLocation) {
      locCode = locationCodeForLabel(selectedLocation.value);
    }

    String? workCenter;
    if (hasDept) {
      final dept = departmentList.firstWhere(
            (e) => e.label == selectedDepartment.value,
        orElse: () => LabelValue(),
      );
      debugPrint("_updateFunctionalLocationAndEquipmentOptions: Selected department label=${selectedDepartment.value}, deptId=${dept.value}");
      debugPrint("_updateFunctionalLocationAndEquipmentOptions: departmentList sample: ${departmentList.take(3).map((e) => {'label': e.label, 'value': e.value, 'uniqueId': e.uniqueId}).toList()}");
      
      // Use workCenter from departmentList uniqueId if available (from API)
      // Otherwise fall back to looking up in masterDepartments
      if (dept.uniqueId != null && dept.uniqueId.toString().trim().isNotEmpty) {
        workCenter = dept.uniqueId.toString();
        debugPrint("_updateFunctionalLocationAndEquipmentOptions: Using workCenter from departmentList uniqueId: $workCenter");
      } else {
        workCenter = getWorkCenterForDept(dept.value, deptLabel: selectedDepartment.value);
        debugPrint("_updateFunctionalLocationAndEquipmentOptions: Using workCenter from masterDepartments lookup: $workCenter");
      }
    }
    
    debugPrint("_updateFunctionalLocationAndEquipmentOptions: Filtering params - hasLocation=$hasLocation, locCode=$locCode, hasDept=$hasDept, workCenter=$workCenter");
    
    // Check if functional locations have workCenter populated
    final funcLocsWithWorkCenter = masterFunctionalLocations.where((e) => e['workCenter']?.toString().trim().isNotEmpty == true).toList();
    debugPrint("_updateFunctionalLocationAndEquipmentOptions: Functional locations with workCenter populated: ${funcLocsWithWorkCenter.length}/${masterFunctionalLocations.length}");
    if (funcLocsWithWorkCenter.isNotEmpty) {
      final uniqueWorkCenters = funcLocsWithWorkCenter.map((e) => e['workCenter']?.toString().trim()).toSet().toList();
      debugPrint("_updateFunctionalLocationAndEquipmentOptions: Unique workCenter values in functional locations: $uniqueWorkCenters");
    }

    final filteredFuncs = masterFunctionalLocations.where((e) {
      bool match = true;

      if (hasLocation && locCode != null && locCode.isNotEmpty) {
        match = match && (e['location']?.toString().trim().toUpperCase() == locCode.trim().toUpperCase());
      }

      if (hasDept && workCenter != null && workCenter.isNotEmpty) {
        final funcWorkCenter = e['workCenter']?.toString().trim().toUpperCase();
        match = match && (funcWorkCenter == workCenter.trim().toUpperCase());
        // debugPrint("Filtering funcLoc: workCenter filter - funcWorkCenter=$funcWorkCenter, filterWorkCenter=$workCenter, match=$match");
      }

      return match;
    }).toList();
    
    debugPrint("_updateFunctionalLocationAndEquipmentOptions: Filtered ${masterFunctionalLocations.length} funcLocs to ${filteredFuncs.length} (hasLocation=$hasLocation, locCode=$locCode, hasDept=$hasDept, workCenter=$workCenter)");

    setFunctionalLocationOptions(filteredFuncs);

    // Equipment is only populated once a Functional Location is selected.
    // Location alone should narrow Functional Location choices, not Equipment.
    final hasFuncLoc = selectedFunctionalLocation.value != null &&
        selectedFunctionalLocation.value != 'Select';
    if (hasFuncLoc) {
      final funcLocCode = _funcLocationCodeForLabel(selectedFunctionalLocation.value);
      final filteredEquipments = _filterEquipments(locCode: locCode, funcLocCode: funcLocCode);
      setEquipmentOptions(filteredEquipments);
    } else {
      // No functional location selected — clear equipment list entirely.
      setEquipmentOptions([]);
    }
  }

  void onJiFunctionalLocationChanged(String? label) {
    debugPrint("onJiFunctionalLocationChanged: label=$label");
    selectedJiFunctionalLocation.value = label;
    if (label == null || label.isEmpty) {
      jiFunctionalLocationId.value = null;
      jiFunctionalLocation.value = null;
      return;
    }
    final matched = functionalLocationList.firstWhere(
          (e) => e.label == label,
      orElse: () => LabelValue(value: "0"),
    );
    jiFunctionalLocationId.value = matched.value;
    jiFunctionalLocation.value = label;
  }

  /// Filter functional locations for Joint Inspection based on JI department's workCenter
  void _filterJiFunctionalLocations() {
    debugPrint("=== _filterJiFunctionalLocations START ===");
    debugPrint("jiDepartment.value: ${jiDepartment.value}");
    
    if (jiDepartment.value == null || jiDepartment.value == 'Select') {
      // No department selected, show all functional locations
      debugPrint("No department selected, showing all functional locations");
      setFunctionalLocationOptions(masterFunctionalLocations);
      return;
    }

    debugPrint("departmentList: ${departmentList.map((e) => {'label': e.label, 'value': e.value, 'uniqueId': e.uniqueId}).toList()}");
    
    final dept = departmentList.firstWhere(
          (e) => e.label == jiDepartment.value,
        orElse: () => LabelValue(),
    );
    
    debugPrint("Matched dept: label=${dept.label}, value=${dept.value}, uniqueId=${dept.uniqueId}");

    String? workCenter;
    if (dept.uniqueId != null && dept.uniqueId.toString().trim().isNotEmpty) {
      workCenter = dept.uniqueId.toString();
      debugPrint("_filterJiFunctionalLocations: Using workCenter from departmentList uniqueId: $workCenter");
    } else {
      workCenter = getWorkCenterForDept(dept.value, deptLabel: jiDepartment.value);
      debugPrint("_filterJiFunctionalLocations: Using workCenter from masterDepartments lookup: $workCenter");
    }

    if (workCenter == null || workCenter.isEmpty) {
      debugPrint("_filterJiFunctionalLocations: No workCenter found for department ${jiDepartment.value}, showing all functional locations");
      setFunctionalLocationOptions(masterFunctionalLocations);
      return;
    }

    debugPrint("Filtering functional locations by workCenter: $workCenter");
    debugPrint("Sample functional locations (first 5): ${masterFunctionalLocations.take(5).map((e) => {'funcLocation': e['funcLocation'], 'workCenter': e['workCenter']}).toList()}");
    
    final filteredFuncs = masterFunctionalLocations.where((e) {
      final funcWorkCenter = e['workCenter']?.toString().trim().toUpperCase();
      final match = funcWorkCenter == workCenter?.trim().toUpperCase();
      if (match) {
        debugPrint("MATCH: funcLocation=${e['funcLocation']}, funcWorkCenter=$funcWorkCenter");
      }
      return match;
    }).toList();

    debugPrint("_filterJiFunctionalLocations: Filtered ${masterFunctionalLocations.length} funcLocs to ${filteredFuncs.length} for workCenter=$workCenter");
    setFunctionalLocationOptions(filteredFuncs);
    debugPrint("=== _filterJiFunctionalLocations END ===");
  }

  void onJiEquipmentChanged(String? label) {
    selectedJiEquipmentNumber.value = label;
    if (label == null || label.isEmpty) {
      jiEquipmentId.value = null;
      jiEquipmentNumber.value = null;
      return;
    }
    final matched = equipmentList.firstWhere(
          (e) => e.label == label,
      orElse: () => LabelValue(value: "0"),
    );
    jiEquipmentId.value = int.tryParse(matched.value ?? "0");
    jiEquipmentNumber.value = label;
  }

  void onFunctionalLocationChanged(String? funcLabel) async {
    debugPrint("=== onFunctionalLocationChanged START ===");
    debugPrint("funcLabel: $funcLabel");
    if (masterEquipments.isEmpty) {
      debugPrint("onFunctionalLocationChanged: masterEquipments empty, reloading from DB");
      await _reloadEquipmentsFromDb();
    }

    if (funcLabel == null || funcLabel == 'Select') {
      selectedFunctionalLocation.value = funcLabel == 'Select' ? 'Select' : null;
      selectedEquipmentNumber.value = 'Select';
      showMeasurementButton.value = false;

      // Functional Location cleared — equipment must be empty until it's picked again.
      setEquipmentOptions([]);
      return;
    }

    selectedFunctionalLocation.value = funcLabel;
    selectedEquipmentNumber.value = 'Select';

    final func = masterFunctionalLocations.firstWhere(
          (e) => e['funcLocationName']?.toString() == funcLabel,
      orElse: () => <String, dynamic>{},
    );
    debugPrint("Found functional location: ${func['funcLocationName']}, location: ${func['location']}, workCenter: ${func['workCenter']}");

    // Auto-select location based on functional location
    final funcLocationCode = func['location']?.toString();
    debugPrint("Auto-select location: funcLocationCode=$funcLocationCode");
    debugPrint("Auto-select location: locationTypeList count=${locationTypeList.length}");
    debugPrint("Auto-select location: locationTypeList sample=${locationTypeList.take(5).map((e) => {'label': e.label, 'value': e.value, 'uniqueId': e.uniqueId}).toList()}");
    
    if (funcLocationCode != null && funcLocationCode.isNotEmpty) {
      // First try to match by uniqueId (location code) - since we now store location code in uniqueId
      final locationMatch = locationTypeList.firstWhere(
        (e) => e.uniqueId == funcLocationCode,
        orElse: () => LabelValue(),
      );
      debugPrint("Auto-select location: First attempt by uniqueId - locationMatch.label=${locationMatch.label}, locationMatch.uniqueId=${locationMatch.uniqueId}");
      
      // If not found by uniqueId, try to match by label (location name)
      if (locationMatch.label?.isEmpty == true) {
        final locationMatchByName = locationTypeList.firstWhere(
          (e) => e.label == funcLocationCode,
          orElse: () => LabelValue(),
        );
        debugPrint("Auto-select location: Second attempt by label - locationMatchByName.label=${locationMatchByName.label}, locationMatchByName.value=${locationMatchByName.value}");
        
        if (locationMatchByName.label?.isNotEmpty == true) {
          selectedLocation.value = locationMatchByName.label;
          locationDisplayController.text = locationMatchByName.label ?? '';
          debugPrint("Auto-selected location (by label): ${locationMatchByName.label}");
        } else {
          debugPrint("Auto-select location: No match found for funcLocationCode=$funcLocationCode (tried both uniqueId and label)");
        }
      } else {
        selectedLocation.value = locationMatch.label;
        locationDisplayController.text = locationMatch.label ?? '';
        debugPrint("Auto-selected location (by uniqueId): ${locationMatch.label}");
      }
    }

    // Auto-select department based on functional location's workCenter
    final funcWorkCenter = func['workCenter']?.toString();
    if (funcWorkCenter != null && funcWorkCenter.isNotEmpty) {
      LabelValue? deptMatch;
      // Try matching by workCenter in uniqueId
      for (var dept in departmentList) {
        if (dept.uniqueId?.toString() == funcWorkCenter) {
          deptMatch = dept;
          break;
        }
      }
      // If not found, try matching by workCenter lookup
      if (deptMatch == null) {
        for (var dept in departmentList) {
          final wc = getWorkCenterForDept(dept.value, deptLabel: dept.label);
          if (wc == funcWorkCenter) {
            deptMatch = dept;
            break;
          }
        }
      }
      if (deptMatch != null && deptMatch.label?.isNotEmpty == true) {
        selectedDepartment.value = deptMatch.label;
        departmentDisplayController.text = deptMatch.label ?? '';
        debugPrint("Auto-selected department: ${deptMatch.label}");
      }
    }

    // Re-filter functional locations based on newly selected department/location
    _updateFunctionalLocationAndEquipmentOptions();

    // Ensure the selected functional location remains in the list after filtering
    ensureDropdownOption(
      functionalLocationList,
      funcLabel,
      func['funcLocId']?.toString() ?? func['funcLocation']?.toString() ?? '',
    );
    selectedFunctionalLocation.value = funcLabel;

    final locCode = (selectedLocation.value != null && selectedLocation.value != 'Select')
        ? locationCodeForLabel(selectedLocation.value)
        : null;

    final funcCode = func['funcLocation']?.toString();
    debugPrint("onFunctionalLocationChanged: funcCode=$funcCode, objectNumber=${func['objectNumber']}");
    if (funcCode != null && funcCode.isNotEmpty) {
      final filteredEquipments = _filterEquipments(locCode: locCode, funcLocCode: funcCode);
      setEquipmentOptions(filteredEquipments);
      _checkMeasurementPoints(func['objectNumber']?.toString());
    }
  }

  /// Re-filters equipmentList to match the currently selected Location/Functional Location.
  /// Call this after loading an existing failure's details, since those flows set the
  /// selections directly without going through the normal filter path.
  void _refilterEquipmentForCurrentSelections() {
    final hasLocation = selectedLocation.value != null && selectedLocation.value != 'Select';
    final hasFuncLoc = selectedFunctionalLocation.value != null && selectedFunctionalLocation.value != 'Select';

    if (!hasFuncLoc) {
      // No functional location resolved — nothing to filter equipment by; leave as-is
      // (or clear, matching the "equipment only shows once func loc chosen" rule).
      return;
    }

    final locCode = hasLocation ? locationCodeForLabel(selectedLocation.value) : null;
    final funcLocCode = _funcLocationCodeForLabel(selectedFunctionalLocation.value);

    final filtered = _filterEquipments(locCode: locCode, funcLocCode: funcLocCode);
    setEquipmentOptions(filtered);
  }

  /// Re-filters functionalLocationList to match the currently selected Department
  /// (via workCenter) and Location. Preserves the currently selected functional
  /// location even if it falls outside the filter, so server-loaded data doesn't disappear.
  void _refilterFunctionalLocationForCurrentSelections() {

    
    final hasLocation = selectedLocation.value != null && selectedLocation.value != 'Select';
    final hasDept = selectedDepartment.value != null && selectedDepartment.value != 'Select';

    String? locCode;
    if (hasLocation) {
      locCode = locationCodeForLabel(selectedLocation.value);
    }

    String? workCenter;
    if (hasDept) {
      final dept = departmentList.firstWhere(
            (e) => e.label == selectedDepartment.value,
        orElse: () => LabelValue(),
      );
      // Use workCenter from departmentList uniqueId if available (from API)
      // Otherwise fall back to looking up in masterDepartments
      if (dept.uniqueId != null && dept.uniqueId.toString().trim().isNotEmpty) {
        workCenter = dept.uniqueId.toString();
      } else {
        workCenter = getWorkCenterForDept(dept.value, deptLabel: selectedDepartment.value);
      }
    }

    final filteredFuncs = masterFunctionalLocations.where((e) {
      bool match = true;
      if (hasLocation && locCode != null && locCode.isNotEmpty) {
        match = match && (e['location']?.toString().trim().toUpperCase() == locCode.trim().toUpperCase());
      }
      if (hasDept && workCenter != null && workCenter.isNotEmpty) {
        final funcWorkCenter = e['workCenter']?.toString().trim().toUpperCase();
        match = match && (funcWorkCenter == workCenter.trim().toUpperCase());
      }
      return match;
    }).toList();
    

    setFunctionalLocationOptions(filteredFuncs);

    // Preserve currently selected value if it fell outside the filtered set.
    final currentFuncLoc = selectedFunctionalLocation.value;
    if (currentFuncLoc != null && currentFuncLoc.isNotEmpty && currentFuncLoc != 'Select') {
      ensureDropdownOption(functionalLocationList, currentFuncLoc, '');
    }
  }

  void onEquipmentChanged(String? equipLabel) {
    if (equipLabel == null || equipLabel == 'Select') {
      selectedEquipmentNumber.value = equipLabel == 'Select' ? 'Select' : null;
      return;
    }

    selectedEquipmentNumber.value = equipLabel;

    final eq = masterEquipments.firstWhere(
            (e) => e['equipmentName'] == equipLabel,
        orElse: () => <String, dynamic>{});

    // Auto-select location based on equipment
    final locCode = eq['location']?.toString();
    if (locCode != null && locCode.isNotEmpty) {
      final loc = masterLocations.firstWhere(
            (e) => e['locationTypeCode']?.toString() == locCode ||
            e['locationTypeId']?.toString() == locCode,
        orElse: () => <String, dynamic>{},
      );
      if (loc.isNotEmpty) {
        final locName = loc['locationName']?.toString();
        if (locName != null && locName.isNotEmpty) {
          selectedLocation.value = locName;
          locationDisplayController.text = locName;
        }
      }
    }

    final funcCode = eq['functionalLocation']?.toString();
    if (funcCode != null && funcCode.isNotEmpty) {
      final func = masterFunctionalLocations.firstWhere(
              (e) => e['funcLocation'] == funcCode,
          orElse: () => <String, dynamic>{});

      if (func.isNotEmpty) {
        // Display funcLocation CODE as the selected value (matching the dropdown label)
        selectedFunctionalLocation.value = funcCode;
        functionalLocationDisplayController.text = funcCode;
        // Also ensure the dropdown list includes this func loc
        ensureDropdownOption(
          functionalLocationList,
          funcCode,
          func['funcLocId']?.toString() ?? '',
        );
        _checkMeasurementPoints(func['objectNumber']?.toString());
      }
    }
  }

  Future<void> _checkMeasurementPoints(String? objectNumber) async {
    debugPrint("=== _checkMeasurementPoints START ===");
    debugPrint("Checking Measurement Points for objectNumber: $objectNumber");
    if (objectNumber == null || objectNumber.isEmpty) {
      debugPrint("objectNumber is null or empty, hiding button");
      showMeasurementButton.value = false;
      measurementPointsList.clear();
      return;
    }

    try {
      final dbService = LocalDatabaseService();
      debugPrint("Calling getMeasurementPoints...");
      List<Map<String, dynamic>> allMeasurements =
      (await dbService.getMeasurementPoints()).map((e) => e.toJson()).toList();
      debugPrint("Total Measurement Points in DB: ${allMeasurements.length}");

      if (allMeasurements.isEmpty) {
        debugPrint("Measurement Points empty in local DB - sync should have happened at login");
        measurementPointsList.clear();
        showMeasurementButton.value = false;
        return;
      }

      debugPrint("First 3 measurement points for debugging:");
      for (int i = 0; i < (allMeasurements.length > 3 ? 3 : allMeasurements.length); i++) {
        debugPrint("  [$i] objectNo: '${allMeasurements[i]['objectNo']}', measPoint: '${allMeasurements[i]['measPoint']}'");
      }

      final matchingMeasurements = allMeasurements
          .where((m) =>
      m['objectNo']?.toString().trim() == objectNumber.toString().trim())
          .toList();
      debugPrint(
          "Matching Measurement Points found: ${matchingMeasurements.length}");
      debugPrint("Looking for objectNo: '${objectNumber.toString().trim()}'");
      if (allMeasurements.isNotEmpty) {
        debugPrint("Sample measurement objectNo: '${allMeasurements.first['objectNo']}'");
      }

    if (matchingMeasurements.isNotEmpty) {
      measurementPointsList.assignAll(matchingMeasurements
          .map((m) => {
        "measPoint": m['measPoint'],
        "measPointDesc": m['measPointDesc'],
        "measRangeUnit": m['measRangeUnit'],
        "internalCharNo": m['internalCharNo'],
        "targetValue": m['targetValue'],
        "measId": m['measId'],
        "reading": "",
        "readingDescr": "",
        "uom": m['measRangeUnit'],
        "UnitMeasurement": m['measRangeUnit']
      })
          .toList());
      debugPrint("Setting showMeasurementButton to true");
      showMeasurementButton.value = true;
    } else {
      debugPrint("No matching measurements, hiding button");
      measurementPointsList.clear();
      showMeasurementButton.value = false;
    }
    } catch (e) {
      debugPrint("Error in _checkMeasurementPoints: $e");
      measurementPointsList.clear();
      showMeasurementButton.value = false;
    }
  }

  Future<void> fetchFaults(String objectPartId) async {
    try {
      isFaultLoading.value = true;
      faultTypeList.clear();
      final faults = await _failureService.getFaults(objectPartId);
      faultTypeList.assignAll(faults);
    } catch (e) {
      debugPrint('fetchFaults error: $e');
    } finally {
      isFaultLoading.value = false;
    }
  }

  Future<void> fetchRootCauseAndAction(
      String objectCodeId, String faultCodeId) async {
    try {
      EasyLoading.show(status: 'Loading RCA options...');
      final data =
      await _failureService.getRootCauseAndAction(objectCodeId, faultCodeId);
      EasyLoading.dismiss();
      rootCauseList.assignAll(data.rootCauses);
      actionTakenList.assignAll(data.actionTaken);
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(AppStrings.error, e.toString());
    }
  }

  Future<void> _autoSelectFailureReportedBy() async {
    // Don't overwrite if already set (e.g. re-entrant call)
    if (selectedFailureReportedBy.value != null &&
        selectedFailureReportedBy.value!.isNotEmpty) {
      return;
    }
    final currentUserId = await AuthManager().getUserId();
    if (currentUserId == null || currentUserId.isEmpty) return;

    final matched = userList.firstWhere(
          (e) => e.value == currentUserId,
      orElse: () => LabelValue(label: null),
    );
    if (matched.label != null && matched.label!.isNotEmpty) {
      selectedFailureReportedBy.value = matched.label;
    }
  }


  Future<void> loadStationCreateDropdowns() async {
    try {
      isLoading.value = true;
      debugPrint("loadStationCreateDropdowns: loading from local DB");

      await loadMasterDropdownsFromDb();

      // Now load everything from local DB into reactive lists
      await loadMasterDataFromDb();
      await _autoSelectFailureReportedBy();

      debugPrint("loadStationCreateDropdowns: isStationController = $isStationController");
      debugPrint("loadStationCreateDropdowns: masterFunctionalLocations count = ${masterFunctionalLocations.length}");

      // Always reload departments from local storage after sync
      await loadDepartments();
      
      // Station is already selected in SessionController from login popup
      final session = Get.find<SessionController>();
      debugPrint("loadStationCreateDropdowns: Station from session: ${session.selectedStationName.value}");
    } catch (e) {
      debugPrint("loadStationCreateDropdowns error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _applyPassengerAffectedFromModel(CreateVMModel model) {
    final count = model.noOfPassengerAffected;
    final trapped = model.trappedDuration;
    final rescued = model.rescuedDuration;

    final hasPassengerData = model.isPassengerAffected == true ||
        (count != null && count > 0) ||
        (trapped != null && trapped.isNotEmpty) ||
        (rescued != null && rescued.isNotEmpty);

    isPassengerAffected.value = hasPassengerData;
    passengersAffectedCountController.text = count?.toString() ?? '';
    trappedDurationController.text = trapped ?? '';
    rescuedDurationController.text = rescued ?? '';
  }

  String _lookupValue(List<LabelValue> list, String? label,
      {String fallback = "0"}) {
    if (label == null || label.isEmpty || label == 'Select') return fallback;
    return list
        .firstWhere((e) => e.label == label,
        orElse: () => LabelValue(value: fallback))
        .value ??
        fallback;
  }

  String _lookupLocationId(List<LabelValue> list, String? label,
      {String fallback = "0"}) {
    if (label == null || label.isEmpty || label == 'Select') return fallback;
    // Now locationTypeId is stored in value field
    return list
        .firstWhere((e) => e.label == label,
        orElse: () => LabelValue(value: fallback))
        .value ??
        fallback;
  }


  void updateMeasurementReading(int index, String field, String value) {
    var list = List<Map<String, dynamic>>.from(measurementPointsList);
    list[index][field] = value;
    measurementPointsList.assignAll(list);
  }

  DateTime? _parseDate(String dateStr) {
    try {
      try {
        return DateFormat('MM/dd/yyyy HH:mm:ss').parse(dateStr);
      } catch (e) {
        return DateFormat('dd/MM/yyyy HH:mm').parse(dateStr);
      }
    } catch (e) {
      debugPrint('Error parsing date: $dateStr — $e');
      return null;
    }
  }

  Future<void> handleScannedQR(String url) async {
    try {
      debugPrint('QR Scan: Raw URL: $url');
      final uri = Uri.tryParse(url);
      if (uri == null || uri.pathSegments.isEmpty) {
         Get.snackbar('Error', 'Invalid QR Code URL', backgroundColor: Colors.red, colorText: Colors.white);
         return;
      }
      final encryptedIdBase64 = uri.pathSegments.last;
      debugPrint('QR Scan: Encrypted ID from URL: $encryptedIdBase64');
      final decryptedId = await _decryptQRId(encryptedIdBase64);
      debugPrint('QR Scan: Decrypted ID: $decryptedId');
      
      // Check internet connectivity
      final hasInternet = await NetworkUtils.checkConnectivity();
      debugPrint('QR Scan: Internet available: $hasInternet');
      
      if (hasInternet) {
        // Online mode: Call API to get data with encrypted ID
        await _populateDataFromApi(encryptedIdBase64);
      } else {
        // Offline mode: Use local DB lookup with decrypted ID
        await _populateDataFromScannedId(decryptedId);
      }
    } catch (e) {
      debugPrint('QR Scan Error: $e');
      Get.snackbar('Error', 'Failed to process QR Code: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<String> _decryptQRId(String encryptedId) async {
    try {
      final bytes = base64Decode(encryptedId);
      final innerBase64Str = String.fromCharCodes(bytes.where((b) => b != 0));
      final innerBytes = base64Decode(innerBase64Str);
      final str = "H3#@*iLvcL!k31q4l1ncL#@.^.";
      final keyBytes = utf8.encode(str.substring(0, 8));
      final msIv = [0x12, 0x34, 0x56, 0x78, 0x90, 0xAB, 0xCD, 0xEF];
      final des = DES(key: keyBytes, mode: DESMode.CBC, paddingType: DESPaddingType.PKCS7, iv: msIv);
      final decrypted = des.decrypt(innerBytes);
      final decodedStr = utf8.decode(decrypted);
      return decodedStr.replaceAll(RegExp(r'\x00'), '').trim();
    } catch (e) {
      debugPrint("QR Decryption Error: $e");
      return encryptedId;
    }
  }

  Future<void> _populateDataFromApi(String decryptedId) async {
    try {
      EasyLoading.show(status: 'Fetching data from server...');
      
      final userId = await AuthManager().getUserId() ?? 1;
      final apiUrl = 'http://192.168.24.158:8080/api/Common/GetAllDataByFuncLocId';
      
      final requestBody = {
        "CreatedBy": userId,
        "FuncLocId": decryptedId,
        "IsSearchFilter": 0
      };
      
      debugPrint('QR Scan API: Calling $apiUrl with body: $requestBody ');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('QR Scan API: Response status: ${response.statusCode}');
      debugPrint('QR Scan API: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['responseCode'] == 200 && responseData['responseOutput'] != null) {
          final output = responseData['responseOutput'];
          debugPrint('QR Scan API: Successfully parsed response output');
          
          // Populate form fields from API response
          await _populateFormFromApiResponse(output);
          
          EasyLoading.dismiss();
          Get.snackbar('Success', 'Asset data populated from server',
              backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          EasyLoading.dismiss();
          debugPrint('QR Scan API: Invalid response code or missing data');
          Get.snackbar('Error', 'Invalid response from server',
              backgroundColor: Colors.red, colorText: Colors.white);
          // Fallback to offline mode
          await _populateDataFromScannedId(decryptedId);
        }
      } else {
        EasyLoading.dismiss();
        debugPrint('QR Scan API: Non-200 status code');
        Get.snackbar('Error', 'Server error: ${response.statusCode}',
            backgroundColor: Colors.red, colorText: Colors.white);
        // Fallback to offline mode
        await _populateDataFromScannedId(decryptedId);
      }
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('QR Scan API Error: $e');
      Get.snackbar('Error', 'Failed to fetch data from server: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
      // Fallback to offline mode
      await _populateDataFromScannedId(decryptedId);
    }
  }

  Future<void> _populateFormFromApiResponse(Map<String, dynamic> output) async {
    // Make sure master caches are populated
    if (masterFunctionalLocations.isEmpty || masterLocations.isEmpty) {
      await loadMasterDataFromDb();
    }
    
    // Populate functional location using funcLocId to lookup from master data
    final funcLocId = output['funcLocId']?.toString();
    final funcLocation = output['funcLocation']?.toString();
    final funcLocationDesc = output['description']?.toString();
    
    String? selectedFuncLocName;
    
    if (funcLocId != null && funcLocId.isNotEmpty) {
      // Try to find the functional location in master data by funcLocId
      final match = masterFunctionalLocations.firstWhere(
        (e) => e['funcLocId']?.toString() == funcLocId,
        orElse: () => <String, dynamic>{},
      );
      
      if (match.isNotEmpty) {
        // Use the name from master data (funcLocationName)
        final masterFuncLocName = match['funcLocationName']?.toString();
        if (masterFuncLocName != null && masterFuncLocName.isNotEmpty) {
          ensureDropdownOption(
            functionalLocationList,
            masterFuncLocName,
            funcLocId,
          );
          selectedFunctionalLocation.value = masterFuncLocName;
          functionalLocationDisplayController.text = masterFuncLocName;
          selectedFuncLocName = masterFuncLocName;
          debugPrint('QR Scan API: Populated functional location from master data: $masterFuncLocName (funcLocId: $funcLocId)');
        } else {
          // Fallback to funcLocation if master data name is empty
          if (funcLocation != null && funcLocation.isNotEmpty) {
            ensureDropdownOption(
              functionalLocationList,
              funcLocation,
              funcLocId,
            );
            selectedFunctionalLocation.value = funcLocation;
            functionalLocationDisplayController.text = funcLocation;
            selectedFuncLocName = funcLocation;
            debugPrint('QR Scan API: Populated functional location from API funcLocation: $funcLocation (funcLocId: $funcLocId)');
          }
        }
      } else {
        // Fallback to using funcLocation from API response (the actual functional location code)
        if (funcLocation != null && funcLocation.isNotEmpty) {
          ensureDropdownOption(
            functionalLocationList,
            funcLocation,
            funcLocId,
          );
          selectedFunctionalLocation.value = funcLocation;
          functionalLocationDisplayController.text = funcLocation;
          selectedFuncLocName = funcLocation;
          debugPrint('QR Scan API: Populated functional location from API funcLocation: $funcLocation (funcLocId: $funcLocId)');
        } else if (funcLocationDesc != null && funcLocationDesc.isNotEmpty) {
          // Last fallback to description
          ensureDropdownOption(
            functionalLocationList,
            funcLocationDesc,
            funcLocId,
          );
          selectedFunctionalLocation.value = funcLocationDesc;
          functionalLocationDisplayController.text = funcLocationDesc;
          selectedFuncLocName = funcLocationDesc;
          debugPrint('QR Scan API: Populated functional location from API description: $funcLocationDesc (funcLocId: $funcLocId)');
        }
      }
    } else if (funcLocation != null && funcLocation.isNotEmpty) {
      // Fallback if funcLocId is not available, use funcLocation
      ensureDropdownOption(
        functionalLocationList,
        funcLocation,
        funcLocation,
      );
      selectedFunctionalLocation.value = funcLocation;
      functionalLocationDisplayController.text = funcLocation;
      selectedFuncLocName = funcLocation;
      debugPrint('QR Scan API: Populated functional location without funcLocId: $funcLocation');
    }
    
    // Refresh dependent dropdowns
    _updateFunctionalLocationAndEquipmentOptions();
    
    // Ensure the selected functional location remains in the list after filtering
    if (selectedFuncLocName != null && selectedFuncLocName.isNotEmpty) {
      ensureDropdownOption(
        functionalLocationList,
        selectedFuncLocName,
        funcLocId ?? funcLocation ?? '',
      );
      selectedFunctionalLocation.value = selectedFuncLocName;
    }
    
    // Populate department
    final department = output['department']?.toString();
    final deptId = output['deptId']?.toString();
    
    if (department != null && department.isNotEmpty) {
      ensureDropdownOption(departmentList, department, deptId ?? '');
      selectedDepartment.value = department;
      departmentDisplayController.text = department;
      debugPrint('QR Scan API: Populated department: $department');
    }
    
    // Populate location (if available in response)
    final location = output['location']?.toString();
    if (location != null && location.isNotEmpty) {
      // Try to find location by code in locationTypeList
      final locationMatch = locationTypeList.firstWhere(
        (e) => e.value == location,
        orElse: () => LabelValue(),
      );
      
      if (locationMatch.label?.isNotEmpty == true) {
        selectedLocation.value = locationMatch.label;
        locationDisplayController.text = locationMatch.label ?? '';
        debugPrint('QR Scan API: Populated location: ${locationMatch.label}');
      } else {
        // Try to match by label
        final locationMatchByName = locationTypeList.firstWhere(
          (e) => e.label == location,
          orElse: () => LabelValue(),
        );
        if (locationMatchByName.label?.isNotEmpty == true) {
          selectedLocation.value = locationMatchByName.label;
          locationDisplayController.text = locationMatchByName.label ?? '';
          debugPrint('QR Scan API: Populated location by name: ${locationMatchByName.label}');
        }
      }
    }
    
    // Populate system and subsystem
    final system = output['system']?.toString();
    final subSystem = output['subSystem']?.toString();
    
    if (system != null && system.isNotEmpty) {
      systemController.text = system;
      debugPrint('QR Scan API: Populated system: $system');
    }
    
    if (subSystem != null && subSystem.isNotEmpty) {
      // Note: subSystemController not found, using subLocationController instead
      subLocationController.text = subSystem;
      debugPrint('QR Scan API: Populated subsystem: $subSystem');
    }
    
    // Populate equipment if available
    final apiEquipmentList = output['lstEquipmentsDetails'] as List?;
    if (apiEquipmentList != null && apiEquipmentList.isNotEmpty) {
      final equipment = apiEquipmentList.first as Map<String, dynamic>;
      final equipmentName = equipment['equipmentName']?.toString();
      final equipmentDesc = equipment['equipmentDescriptions']?.toString();
      final equipmentId = equipment['equipmentId']?.toString();
      
      if (equipmentName != null && equipmentName.isNotEmpty) {
        ensureDropdownOption(
          equipmentList, // This is the controller's RxList<LabelValue>
          equipmentDesc ?? equipmentName,
          equipmentId ?? equipmentName,
        );
        selectedEquipmentNumber.value = equipmentDesc ?? equipmentName;
        equipmentDisplayController.text = equipmentDesc ?? equipmentName;
        debugPrint('QR Scan API: Populated equipment: ${equipmentDesc ?? equipmentName}');
      }
    }
    
    // Refresh dependent dropdowns
    _updateFunctionalLocationAndEquipmentOptions();
  }

  Future<void> _populateDataFromScannedId(String scannedId) async {
    final dbService = LocalDatabaseService();
    final db = await dbService.database;
    final cleanId = scannedId.trim();
    final intId = int.tryParse(cleanId);

    debugPrint('QR Scan: Looking for functional location with ID: $cleanId (parsed as int: $intId)');

    List<Map<String, Object?>> funcResults = [];

    // First try by funcLocId if it's an integer
    if (intId != null) {
      funcResults = await db.rawQuery(
        'SELECT funcLocation, funcLocId, funcLocationName, location, objectNumber, workCenter FROM FunctionalLocations WHERE funcLocId = ? LIMIT 1',
        [intId],
      );
      debugPrint('QR Scan: Query by funcLocId=$intId returned ${funcResults.length} results');
    }

    // If no results by ID, try by funcLocation code (string)
    if (funcResults.isEmpty) {
      funcResults = await db.rawQuery(
        'SELECT funcLocation, funcLocId, funcLocationName, location, objectNumber, workCenter FROM FunctionalLocations WHERE funcLocation = ? LIMIT 1',
        [cleanId],
      );
      debugPrint('QR Scan: Query by funcLocation="$cleanId" returned ${funcResults.length} results');
    }

    // If still no results, try a LIKE search for partial matches
    if (funcResults.isEmpty) {
      funcResults = await db.rawQuery(
        'SELECT funcLocation, funcLocId, funcLocationName, location, objectNumber, workCenter FROM FunctionalLocations WHERE funcLocation LIKE ? LIMIT 1',
        ['%$cleanId%'],
      );
      debugPrint('QR Scan: Query by funcLocation LIKE "%$cleanId%" returned ${funcResults.length} results');
    }

    // If no results, try a broader search to see what's in the table
    if (funcResults.isEmpty) {
      final allFuncLocs = await db.rawQuery('SELECT funcLocId, funcLocation, funcLocationName FROM FunctionalLocations LIMIT 10');
      debugPrint('QR Scan: Sample functional locations in DB (first 10): $allFuncLocs');
      final totalCount = await db.rawQuery('SELECT COUNT(*) as cnt FROM FunctionalLocations');
      debugPrint('QR Scan: Total functional locations in DB: ${totalCount.first['cnt']}');
      
      // Also check if ID 90225 specifically exists
      final check90225 = await db.rawQuery('SELECT funcLocId, funcLocation, funcLocationName FROM FunctionalLocations WHERE funcLocId = 90225');
      debugPrint('QR Scan: Check for ID 90225: ${check90225.isNotEmpty ? "FOUND" : "NOT FOUND"}');
      if (check90225.isNotEmpty) {
        debugPrint('QR Scan: ID 90225 details: $check90225');
      }
      
      Get.snackbar('Not Found',
          'Functional location not found in master data for ID: $cleanId. Total in DB: ${totalCount.first['cnt']}',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final match = FunctionalLocationModel.fromJson(funcResults.first);

    // Make sure master caches are actually populated before we try to match against them
    if (masterFunctionalLocations.isEmpty || masterLocations.isEmpty) {
      await loadMasterDataFromDb();
    }
    if (masterDepartments.isEmpty || departmentList.isEmpty) {
      await loadDepartments();
    }
    
    debugPrint('QR Scan Offline: masterDepartments count=${masterDepartments.length}');
    debugPrint('QR Scan Offline: departmentList count=${departmentList.length}');
    debugPrint('QR Scan Offline: departmentList sample=${departmentList.take(5).map((e) => {'label': e.label, 'value': e.value, 'uniqueId': e.uniqueId}).toList()}');

    final existsInMaster = masterFunctionalLocations.any((e) =>
    e['funcLocId']?.toString() == match.funcLocId?.toString() ||
        e['funcLocation'] == match.funcLocation);

    if (!existsInMaster) {
      masterFunctionalLocations.add(match.toJson());
    }
    ensureDropdownOption(
      functionalLocationList,
      match.funcLocationName ?? '',
      match.funcLocId?.toString() ?? match.funcLocation ?? '',
    );

    selectedFunctionalLocation.value = match.funcLocationName;
    functionalLocationDisplayController.text = match.funcLocationName ?? '';

    // --- Resolve Location NAME from the raw location CODE on the func loc ---
    String? locName;
    final locCode = match.location?.toString();
    if (locCode != null && locCode.isNotEmpty) {
      final loc = masterLocations.firstWhere(
            (e) =>
        e['locationTypeCode']?.toString() == locCode ||
            e['locationTypeId']?.toString() == locCode,
        orElse: () => <String, dynamic>{},
      );
      locName = loc['locationName']?.toString();
    }
    if (locName != null && locName.isNotEmpty) {
      ensureDropdownOption(locationTypeList, locName, locCode ?? '');
      selectedLocation.value = locName;
      locationDisplayController.text = locName;
    } else {
      debugPrint('QR scan: could not resolve location name for code=$locCode');
    }

    // --- Resolve Department via workCenter, same fallback order used elsewhere ---
    String? deptName;
    final workCenter = match.workCenter?.toString().trim();
    if (workCenter != null && workCenter.isNotEmpty) {
      final deptFromList = departmentList.firstWhere(
            (e) =>
        (e.uniqueId?.toString().trim().toUpperCase() ?? '') ==
            workCenter.toUpperCase(),
        orElse: () => LabelValue(),
      );
      deptName = deptFromList.label;

      deptName ??= masterDepartments.firstWhere(
            (d) =>
        (d['workCenter']?.toString().trim().toUpperCase() ?? '') ==
            workCenter.toUpperCase(),
        orElse: () => <String, dynamic>{},
      )['deptName']?.toString();
    }
    if (deptName != null && deptName.isNotEmpty) {
      selectedDepartment.value = deptName;
      departmentDisplayController.text = deptName;
    } else {
      debugPrint(
          'QR scan: could not resolve department for workCenter=$workCenter');
    }

    // --- Refresh dependent dropdowns (this filters func-loc/equipment lists) ---
    _updateFunctionalLocationAndEquipmentOptions();

    // The filter step above rebuilds functionalLocationList from scratch and may
    // drop our scanned entry if it doesn't match the resolved dept/location — re-add it.
    ensureDropdownOption(
      functionalLocationList,
      match.funcLocationName ?? '',
      match.funcLocId?.toString() ?? match.funcLocation ?? '',
    );
    selectedFunctionalLocation.value = match.funcLocationName;

    // --- Equipment for this functional location ---
    final equipResults = await db.rawQuery(
      'SELECT equipId, equipmentName, functionalLocation, location, equipNo, equipDesc FROM Equipments WHERE functionalLocation = ? LIMIT 1',
      [match.funcLocation],
    );

    if (equipResults.isNotEmpty) {
      final equipMatch = EquipmentModel.fromJson(equipResults.first);
      ensureDropdownOption(
        equipmentList,
        equipMatch.equipmentName ?? '',
        equipMatch.equipId?.toString() ?? equipMatch.equipNo ?? '',
      );
      selectedEquipmentNumber.value = equipMatch.equipmentName;
      equipmentDisplayController.text = equipMatch.equipmentName ?? '';
    }

    await _checkMeasurementPoints(match.objectNumber?.toString());

    Get.snackbar('Success', 'Asset data populated successfully',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  Future<void> loadStationFailureDetailsFromData(FailureItem failureItem) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Populate form fields from FailureItem
      originalFailureId.value = failureItem.id;
      notificationCode.value = failureItem.notificationCode ?? failureItem.failureNo ?? '';
      selectedPriority.value = failureItem.priority;
      mainStatusName.value = failureItem.statusName;
      failureDescriptionController.text = failureItem.failureDescription ?? '';
      selectedDepartment.value = failureItem.departmentName;
      originalDepartmentId.value = failureItem.departmentId_1;
      selectedLocation.value = failureItem.locationName;
      originalLocationId.value = failureItem.locationId;
      selectedFunctionalLocation.value = failureItem.functionalLocation;
      subLocationController.text = failureItem.subLocation ?? '';
      systemController.text = failureItem.system ?? '';
      trainIdController.text = failureItem.trainId ?? '';

      if (failureItem.failureOccuranceDateTime != null) {
        selectedFailureOccurrenceDate.value = _parseDate(failureItem.failureOccuranceDateTime!);
      }
      if (failureItem.actualFailureCompletedDateTime != null) {
        selectedFailureCompletedDate.value = _parseDate(failureItem.actualFailureCompletedDateTime!);
      }

      selectedFailureReportedBy.value = failureItem.failureReportedby;
      selectedFailureCategoryType.value = failureItem.failureCategoryTypeText;
      failureRectificationDetailsController.text = failureItem.failureRectificationDetails ?? '';

      isTripAffected.value = failureItem.isTripAffected ?? false;
      tripDelayUplineController.text = failureItem.tripDelayUpline?.toString() ?? '';
      trainCancelNosController.text = failureItem.tripCancel?.toString() ?? '';
      tripDelayDownlineController.text = failureItem.tripDelayDownline?.toString() ?? '';
      trainDelayMinController.text = failureItem.trainDelayInMin?.toString() ?? '';
      trainWithdrawalNosController.text = failureItem.noOfTranWithdrawal?.toString() ?? '';

      if (failureItem.getImageBefor != null) {
        beforeImagesList.clear();
        for (var img in failureItem.getImageBefor!) {
          final fileName = img['fileName']?.toString() ?? '';
          if (fileName.isNotEmpty) {
            beforeImagesList.add({
              'name': fileName.split('/').last,
              'path': fileName,
              'isNetwork': true,
            });
          }
        }
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      debugPrint('Error in loadStationFailureDetailsFromData: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
