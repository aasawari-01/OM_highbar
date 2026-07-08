import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../model/rst_list_response.dart';
import '../service/failure_service.dart';

class RstListController extends GetxController {
  final FailureService _failureService = FailureService();

  final RxList<RstItem> rstItems = <RstItem>[].obs;
  final RxString searchQuery = "".obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = "".obs;

  List<RstItem> get filteredRstItems {
    if (searchQuery.value.trim().isEmpty) return rstItems;
    final q = searchQuery.value.trim().toLowerCase();
    return rstItems.where((item) {
      final code = (item.notificationCode ?? '').toLowerCase();
      final plant = (item.plantName ?? '').toLowerCase();
      final trainSet = (item.trainSetNo ?? '').toLowerCase();
      final status = (item.statusName ?? '').toLowerCase();
      return code.contains(q) || plant.contains(q) || trainSet.contains(q) || status.contains(q);
    }).toList();
  }

  Future<void> fetchRstList() async {
    isLoading.value = true;
    errorMessage.value = "";

    try {
      final response = await _failureService.getRstList();
      final rstResponse = RstListResponse.fromJson(response);
      print("rstResponse===$rstResponse");
      if (rstResponse.responseCode == 200) {
        rstItems.assignAll(rstResponse.responseOutput);
      } else {
        errorMessage.value = rstResponse.responseMessage ?? "Failed to fetch RST list";
      }
    } catch (e) {
      errorMessage.value = "Error: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }
}
