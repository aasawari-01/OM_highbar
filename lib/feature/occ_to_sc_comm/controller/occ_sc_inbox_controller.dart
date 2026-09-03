// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../model/occ_sc_list_model.dart';
// import '../model/occ_to_sc_model.dart';
// import '../service/occ_to_sc_service.dart';
//
// class OccScInboxController extends GetxController {
//   OccScInboxController({
//     OccToScService? occToScService,
//   }) : _occToScService =
//       occToScService ?? OccToScService();
//
//   final OccToScService _occToScService;
//
//   // ================================================================
//   // Loading
//   // ================================================================
//
//   final RxBool isLoading = false.obs;
//
//   final RxBool isLoadingMore = false.obs;
//
//   // ================================================================
//   // Data
//   // ================================================================
//
//   final RxList<OccInstructionListItem> instructions =
//       <OccInstructionListItem>[].obs;
//
//   // ================================================================
//   // Tab
//   //
//   // 0 = Active
//   // 1 = Upcoming
//   // 2 = Expired
//   // ================================================================
//
//   final RxInt selectedTab = 0.obs;
//
//   // ================================================================
//   // Date filter
//   // ================================================================
//
//   final Rx<DateTimeRange?> selectedDateRange =
//   Rx<DateTimeRange?>(null);
//
//   // ================================================================
//   // Pagination
//   // ================================================================
//
//   int currentPage = 1;
//
//   final int pageSize = 20;
//
//   int totalRecords = 0;
//
//   int totalPages = 0;
//
//   // ================================================================
//   // Current user
//   // ================================================================
//
//   int get currentUserId {
//     // Replace with actual login user id
//     //
//     // final dynamic storedUserId =
//     //     ApiClient.box.read('userId');
//
//     return 1;
//   }
//
//   String get role => 'OCC';
//
//   // ================================================================
//   // Lifecycle
//   // ================================================================
//
//   @override
//   void onInit() {
//     super.onInit();
//
//     // Default tab = Active
//     selectedTab.value = 0;
//
//     fetchInstructions();
//   }
//
//   // ================================================================
//   // STATUS
//   // ================================================================
//
//   String get selectedStatus {
//     switch (selectedTab.value) {
//       case 0:
//         return 'Active';
//
//       case 1:
//         return 'Upcoming';
//
//       case 2:
//         return 'Expired';
//
//       default:
//         return 'Active';
//     }
//   }
//
//   // ================================================================
//   // FETCH
//   // ================================================================
//
//   Future<void> fetchInstructions({
//     bool showLoader = true,
//   }) async {
//     if (showLoader) {
//       isLoading.value = true;
//     }
//
//     try {
//       currentPage = 1;
//
//       final String status = selectedStatus;
//
//       debugPrint(
//         'Fetching instructions...',
//       );
//
//       debugPrint(
//         'Status: $status',
//       );
//
//       final response =
//       await _occToScService.getInstructionList(
//         userId: currentUserId,
//         role: role,
//         pageNumber: currentPage,
//         pageSize: pageSize,
//         instructionStatus: status,
//       );
//
//
//
//       if (!response.success) {
//         throw OccToScException(
//           response.message.isNotEmpty
//               ? response.message
//               : 'Unable to fetch instructions.',
//         );
//       }
//
//       instructions.assignAll(
//         response.data.items,
//       );
//
//       totalRecords =
//           response.data.totalRecords;
//
//       totalPages =
//           response.data.totalPages;
//
//       debugPrint(
//         '$status instructions loaded: '
//             '${instructions.length}',
//       );
//     } catch (e, stackTrace) {
//       debugPrint(
//         'fetchInstructions error: $e',
//       );
//
//       debugPrint(
//         stackTrace.toString(),
//       );
//
//       Get.snackbar(
//         'Error',
//         e is OccToScException
//             ? e.message
//             : 'Unable to load instructions.',
//         backgroundColor:
//         Colors.red.withOpacity(0.9),
//         colorText: Colors.white,
//         snackPosition:
//         SnackPosition.BOTTOM,
//       );
//     } finally {
//       if (showLoader) {
//         isLoading.value = false;
//       }
//     }
//   }
//
//   // ================================================================
//   // TAB CHANGE
//   // ================================================================
//
//   Future<void> changeTab(int index) async {
//     if (selectedTab.value == index) {
//       return;
//     }
//
//     selectedTab.value = index;
//
//     // Clear date filter when changing status
//     selectedDateRange.value = null;
//
//     // Fetch API according to selected status
//     await fetchInstructions();
//   }
//
//   // ================================================================
//   // DATE FILTER
//   // ================================================================
//
//   void setDateRange(
//       DateTimeRange? range) {
//     selectedDateRange.value = range;
//   }
//
//   void clearDateRange() {
//     selectedDateRange.value = null;
//   }
//
//   // ================================================================
//   // COUNTS
//   // ================================================================
//
//   /*
//    * Since API is being called separately for each status,
//    * totalRecords represents the count of the CURRENT status.
//    *
//    * If your backend later sends separate counts for
//    * Active / Upcoming / Expired, use those values instead.
//    */
//
//   int get activeCount {
//     return selectedTab.value == 0
//         ? totalRecords
//         : 0;
//   }
//
//   int get upcomingCount {
//     return selectedTab.value == 1
//         ? totalRecords
//         : 0;
//   }
//
//   int get expiredCount {
//     return selectedTab.value == 2
//         ? totalRecords
//         : 0;
//   }
//
//   // ================================================================
//   // FILTERED DATA
//   // ================================================================
//
//   List<OccInstructionListItem>
//   get filteredInstructions {
//     List<OccInstructionListItem> result =
//     instructions.toList();
//
//     final DateTimeRange? range =
//         selectedDateRange.value;
//
//     if (range == null) {
//       return result;
//     }
//
//     final DateTime start = DateTime(
//       range.start.year,
//       range.start.month,
//       range.start.day,
//     );
//
//     final DateTime end = DateTime(
//       range.end.year,
//       range.end.month,
//       range.end.day,
//       23,
//       59,
//       59,
//       999,
//     );
//
//     result = result.where((item) {
//       final DateTime? issueDate =
//           item.issueDate;
//
//       if (issueDate == null) {
//         return false;
//       }
//
//       return !issueDate.isBefore(start) &&
//           !issueDate.isAfter(end);
//     }).toList();
//
//     return result;
//   }
//
//   // ================================================================
//   // TAB TITLE
//   // ================================================================
//
//   String get selectedTabTitle {
//     switch (selectedTab.value) {
//       case 0:
//         return 'Active';
//
//       case 1:
//         return 'Upcoming';
//
//       case 2:
//         return 'Expired';
//
//       default:
//         return 'Active';
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../service/auth_manager.dart';
import '../model/occ_sc_list_model.dart';
import '../model/occ_to_sc_model.dart';
import '../service/occ_to_sc_service.dart';

class OccScInboxController extends GetxController {
  OccScInboxController({
    required this.isOcc,

    OccToScService? occToScService,

  }) : _occToScService = occToScService ?? OccToScService();

  // ================================================================
  // Role
  // ================================================================

  final bool isOcc;

  String? stationId;


  // TODO: confirm this is the exact role string the list API expects
  // for Station Controller — swap 'SC' if it's actually something else
  // (e.g. 'Station Controller').
  String get role => isOcc ? 'OCC' : 'SC';

  final OccToScService _occToScService;

  // ================================================================
  // Loading
  // ================================================================

  final RxBool isLoading = false.obs;

  final RxBool isLoadingMore = false.obs;

  // ================================================================
  // Data
  // ================================================================

  final RxList<OccInstructionListItem> instructions =
      <OccInstructionListItem>[].obs;

  // ================================================================
  // Tab
  //
  // 0 = Active
  // 1 = Upcoming
  // 2 = Expired
  //
  // Station Controllers only ever see Active — tabs 1/2 are hidden in
  // the UI and changeTab() below refuses to switch away from 0 for them.
  // ================================================================

  final RxInt selectedTab = 0.obs;

  // ================================================================
  // Date filter
  // ================================================================

  final Rx<DateTimeRange?> selectedDateRange =
  Rx<DateTimeRange?>(null);

  // ================================================================
  // Pagination
  // ================================================================

  int currentPage = 1;

  final int pageSize = 20;

  int totalRecords = 0;

  int totalPages = 0;

  // ================================================================
  // Current user
  // ================================================================

  Future<int> get currentUserId async {
    // Replace with actual login user id
    //
    // final dynamic storedUserId =
    //     ApiClient.box.read('userId');
    final String? userId= await AuthManager().getUserId();

    return int.parse(userId??'0');
  }

  // TODO: for Station Controller, the list/acknowledgement logic likely
  // needs the current user's own stationId. Wire this up to wherever
  // that's stored (session/login response) once available.
  int get currentStationId => 0;

  // ================================================================
  // Lifecycle
  // ================================================================

  @override
  void onInit() {
    super.onInit();

    // Default tab = Active (also the only tab SC ever sees)
    selectedTab.value = 0;
    initializeData();
  }

  Future<void> initializeData() async {
    await loadSelectedStationId();
    await fetchInstructions();
  }


  Future<void> loadSelectedStationId() async {
    final prefs = await SharedPreferences.getInstance();

    stationId =
        prefs.getString('selectedStationID') ?? '';

    print("Station ID loaded from SharedPreferences: ${stationId}");
  }

  // ================================================================
  // STATUS
  // ================================================================

  String get selectedStatus {
    // Station Controllers only ever fetch Active instructions.
    if (!isOcc) {
      return 'Active';
    }

    switch (selectedTab.value) {
      case 0:
        return 'Active';

      case 1:
        return 'Upcoming';

      case 2:
        return 'Expired';

      default:
        return 'Active';
    }
  }

  // ================================================================
  // FETCH
  // ================================================================

  Future<void> fetchInstructions({
    bool showLoader = true,
  }) async {
    if (showLoader) {
      isLoading.value = true;
    }

    try {
      currentPage = 1;

      final String status = selectedStatus;

      debugPrint(
        'Fetching instructions...',
      );

      debugPrint(
        'Role: $role Status: $status',
      );

      final response =
      await _occToScService.getInstructionList(
        userId: await currentUserId,
        role: role,
        pageNumber: currentPage,
        pageSize: pageSize,
        instructionStatus: status,
        stationId: isOcc ? '0' : (stationId ?? '0'),

      );



      if (!response.success) {
        throw OccToScException(
          response.message.isNotEmpty
              ? response.message
              : 'Unable to fetch instructions.',
        );
      }

      instructions.assignAll(
        response.data.items,
      );

      totalRecords =
          response.data.totalRecords;

      totalPages =
          response.data.totalPages;

      debugPrint(
        '$status instructions loaded: '
            '${instructions.length}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'fetchInstructions error: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      Get.snackbar(
        'Error',
        e is OccToScException
            ? e.message
            : 'Unable to load instructions.',
        backgroundColor:
        Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition:
        SnackPosition.BOTTOM,
      );
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
    }
  }

  // ================================================================
  // TAB CHANGE
  // ================================================================

  Future<void> changeTab(int index) async {
    // Station Controllers only see Active — tabs aren't rendered for
    // them, but guard here too in case this is ever called directly.
    if (!isOcc) {
      return;
    }

    if (selectedTab.value == index) {
      return;
    }

    selectedTab.value = index;

    // Clear date filter when changing status
    selectedDateRange.value = null;

    // Fetch API according to selected status
    await fetchInstructions();
  }

  // ================================================================
  // DATE FILTER
  // ================================================================

  void setDateRange(
      DateTimeRange? range) {
    selectedDateRange.value = range;
  }

  void clearDateRange() {
    selectedDateRange.value = null;
  }

  // ================================================================
  // COUNTS
  // ================================================================

  int get activeCount {
    return selectedTab.value == 0
        ? totalRecords
        : 0;
  }

  int get upcomingCount {
    return selectedTab.value == 1
        ? totalRecords
        : 0;
  }

  int get expiredCount {
    return selectedTab.value == 2
        ? totalRecords
        : 0;
  }

  // ================================================================
  // FILTERED DATA
  // ================================================================

  List<OccInstructionListItem>
  get filteredInstructions {
    List<OccInstructionListItem> result =
    instructions.toList();

    final DateTimeRange? range =
        selectedDateRange.value;

    if (range == null) {
      return result;
    }

    final DateTime start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );

    final DateTime end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );

    result = result.where((item) {
      final DateTime? issueDate =
          item.issueDate;

      if (issueDate == null) {
        return false;
      }

      return !issueDate.isBefore(start) &&
          !issueDate.isAfter(end);
    }).toList();

    return result;
  }

  // ================================================================
  // TAB TITLE
  // ================================================================

  String get selectedTabTitle {
    if (!isOcc) {
      return 'Active';
    }

    switch (selectedTab.value) {
      case 0:
        return 'Active';

      case 1:
        return 'Upcoming';

      case 2:
        return 'Expired';

      default:
        return 'Active';
    }
  }
}