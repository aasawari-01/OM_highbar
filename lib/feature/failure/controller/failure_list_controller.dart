import 'dart:convert';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../core/models/label_value.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../service/auth_manager.dart';
import '../../../service/session_controller.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_text.dart';
import '../model/failure_list_response.dart';
import '../service/failure_service.dart';

enum StationFailureListTab { active, closed }
enum JEFailureListTab { inbox, jointInspection }

class FailureListController extends GetxController {
  final FailureService _failureService = FailureService();
  final ApiClient _apiClient = ApiClient();
  final SessionController _sessionController = Get.find<SessionController>();

  final RxList<FailureItem> failures = <FailureItem>[].obs;
  final RxString searchQuery = "".obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = "".obs;

  List<FailureItem> get filteredFailures {
    if (searchQuery.value.trim().isEmpty) return failures;
    final q = searchQuery.value.trim().toLowerCase();
    return failures.where((item) {
      final code = (item.notificationCode ?? '').toLowerCase();
      final loc = (item.locationName ?? '').toLowerCase();
      final status = (item.statusName ?? '').toLowerCase();
      return code.contains(q) || loc.contains(q) || status.contains(q);
    }).toList();
  }
  final selectedStationTab = StationFailureListTab.active.obs;
  final selectedJETab = JEFailureListTab.inbox.obs;
  String failureType = 'Maintenance';

  void setFailureType(String type) {
    failureType = type;
  }

  @override
  void onInit() {
    super.onInit();
    // fetchFailures() is called by the view after setFailureType()
    // to avoid double-calls and ensure failureType is set first.
  }

  bool get _isJE {
    final role = _sessionController.selectedRole.value?.roleDescr ?? '';
    return role.contains('Junior Engineer');
  }

  bool get _isStationController {
    final role = _sessionController.selectedRole.value?.roleDescr ?? '';
    return role.contains('Station Controller');
  }

  bool get _useStationFailureListApi => failureType.toLowerCase() == 'station' && _isStationController;

  bool get showStationTabs => _useStationFailureListApi;
  bool get showJETabs => _isJE;

  void setStationTab(StationFailureListTab tab) {
    if (selectedStationTab.value == tab) return;
    selectedStationTab.value = tab;
    fetchFailures();
  }

  void setJETab(JEFailureListTab tab) {
    if (selectedJETab.value == tab) return;
    selectedJETab.value = tab;
    fetchFailures();
  }

  bool _matchesFailureType(FailureItem item) {
    if (_isJE && selectedJETab.value == JEFailureListTab.jointInspection) return true;
    
    final filter = failureType.trim().toLowerCase();
    if (filter.isEmpty) return true;

    if (_useStationFailureListApi) return true;

    final creation = (item.creationType ?? '').trim().toLowerCase();

    if (filter == 'maintenance' || filter == 'maintainance') {
      return creation == 'manual';
    }

    if (creation == filter || creation.contains(filter)) return true;

    final other = (item.otherRequestFrom ?? '').trim().toLowerCase();
    return other == filter || other.contains(filter);
  }

  String _messageFromResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['responseMessage']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    } catch (_) {
      // Fall back to the status code below when the server does not return JSON.
    }
    return "Server error: ${response.statusCode}";
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
                  Obx(() => CustDropdown(
                    label: "Station",
                    hint: "Select Station",
                    items: popupStationList
                        .map((e) => e.label ?? "")
                        .toList(),
                    selectedValue: session.selectedStationName.value,
                    onChanged: (val) {
                      session.selectedStationName.value = val;

                      session.selectedStationId.value =
                          popupStationList
                              .firstWhere(
                                (e) => e.label == val,
                            orElse: () => LabelValue(value: "0"),
                          )
                              .value;
                    },
                  )),
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
                              if (session.selectedStationId.value == null) {
                                Get.snackbar(
                                  "Error",
                                  "Please select a station",
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              Get.back();

                              await fetchFailures();
                            }
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

  Future<void> fetchFailures() async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;

      final http.Response response;

      if (_useStationFailureListApi) {
        final isClosedList = selectedStationTab.value == StationFailureListTab.closed;
        response = await _apiClient.post(
          isClosedList ? AppUrls.getStationFailureClosedList : AppUrls.getStationFailureList,
          body: {
              "LocationId":
              int.tryParse(session.selectedStationId.value ?? "0") ?? 0,
            "UserId": userId,
            "DepartmentIds": "",
            "Action": isClosedList ? "ClosedFailureList" : "",
          },
        );
      } else if (_isJE && selectedJETab.value == JEFailureListTab.jointInspection) {
        response = await _apiClient.post(
          AppUrls.jeJointInboxList,
          body: {
            "assignedUserId": userId,
            "jobCardId": null,
            "id": null,
            "deptId": null,
            "startDate": null,
            "endDate": null
          },
        );
      } else {
        final int deptId = _sessionController.selectedDepartment.value?.deptId ?? 0;
        response = await _apiClient.post(
          AppUrls.jeInboxList,
          body: {
            "assignedUserId": userId,
            "deptId": deptId,
          },
        );
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        debugPrint("jsonBody===$jsonBody");
        final result = FailureListResponse.fromJson(jsonBody);
        if (result.responseCode == 200) {
          final allItems = result.responseOutput;
          final filteredItems = allItems.where((item) => _matchesFailureType(item)).toList();
          // Reverse order for joint inspection inbox
          if (_isJE && selectedJETab.value == JEFailureListTab.jointInspection) {
            failures.assignAll(filteredItems.reversed.toList());
          } else {
            failures.assignAll(filteredItems);
          }
        } else {
          errorMessage.value = result.responseMessage ?? "Failed to load data";
        }
      } else {
        failures.clear();
        errorMessage.value = _messageFromResponse(response);
      }
    } catch (e) {
      errorMessage.value = "Error: $e";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reOpenFailure(int id, String remark) async {
    await _updateStationAcknowledgeStatus(id, "UPDATE_REOPEN_OCC_Station", remark);
  }

  Future<void> closeFailure(int id) async {
    await _updateStationAcknowledgeStatus(id, "UPDATE_CLOSED_OCC_Station", "Closed Request");
  }

  Future<void> _updateStationAcknowledgeStatus(int id, String action, String description) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;
      final String userName = _sessionController.userName.value;

      final Map<String, dynamic> payload = {
        "Id": id,
        "StatusId": 202,
        "Action": action,
        "CreatedBy": userId,
        "CreatedByName": userName,
        "Description": description,
      };

      final response = await _apiClient.post(
        AppUrls.updateStationAcknowledgeStatus,
        body: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        if (jsonBody['responseCode'] == 200) {
          Get.snackbar("Success", jsonBody['responseMessage'] ?? "Action completed successfully.", backgroundColor: Colors.green, colorText: Colors.white);
          fetchFailures(); // Refresh list
        } else {
          errorMessage.value = jsonBody['responseMessage'] ?? "Failed to perform action";
          Get.snackbar("Error", errorMessage.value, backgroundColor: AppColors.red, colorText: AppColors.white1);
        }
      } else {
        errorMessage.value = "Server error: ${response.statusCode}";
        Get.snackbar("Error", errorMessage.value, backgroundColor: AppColors.red, colorText: AppColors.white1);
      }
    } catch (e) {
      errorMessage.value = "Error: $e";
      Get.snackbar("Error", errorMessage.value, backgroundColor: AppColors.red, colorText: AppColors.white1);
    } finally {
      isLoading.value = false;
    }
  }
}
