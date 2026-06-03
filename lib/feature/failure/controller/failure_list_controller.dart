import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../service/auth_manager.dart';
import '../../../service/session_controller.dart';
import '../model/failure_list_response.dart';

class FailureListController extends GetxController {
  final ApiClient _apiClient = ApiClient();
  final SessionController _sessionController = Get.find<SessionController>();

  final RxList<FailureItem> failures = <FailureItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = "".obs;
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

  bool _matchesFailureType(FailureItem item) {
    final filter = failureType.trim().toLowerCase();
    if (filter.isEmpty) return true;
    final creation = (item.creationType ?? '').trim().toLowerCase();
    if (creation == filter || creation.contains(filter)) return true;
    final other = (item.otherRequestFrom ?? '').trim().toLowerCase();
    return other == filter || other.contains(filter);
  }

  Future<void> fetchFailures() async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final String? userIdStr = await AuthManager().getUserId();
      final int userId = int.tryParse(userIdStr ?? "0") ?? 0;
      final int deptId = _sessionController.selectedDepartment.value?.deptId ?? 0;

      final response = await _apiClient.post(
        AppUrls.jeInboxList,
        body: {
          "assignedUserId": userId,
          "deptId": deptId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        print("jsonBody==$jsonBody");
        final result = FailureListResponse.fromJson(jsonBody);
          print("result===$result");
        if (result.responseCode == 200) {
          failures.assignAll(result.responseOutput);
        } else {
          errorMessage.value = result.responseMessage ?? "Failed to load data";
          print("error==${result.responseMessage ?? "Failed to load data"}");
        }
      } else {
        errorMessage.value = "Server error: ${response.statusCode}";
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      errorMessage.value = "Error: $e";
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
