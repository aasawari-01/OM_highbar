


import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:om_mobile/constants/colors.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../core/controller/session_controller.dart';
import '../../../core/models/label_value.dart';
import '../../../feature/failure/service/failure_service.dart';
import '../../../service/auth_manager.dart';

import '../controller/occ_sc_inbox_controller.dart';
import '../model/occ_sc_list_model.dart';
import 'create_occ_instruction.dart';
import 'instruction_details.dart';

class OccScInboxScreen extends StatefulWidget {
  const OccScInboxScreen({Key? key, required this.isOcc}) : super(key: key);

  final bool isOcc;

  @override
  State<OccScInboxScreen> createState() => _OccScInboxScreenState();
}

class _OccScInboxScreenState extends State<OccScInboxScreen> {
  // Controller is created ONCE here (initState), not in build().
  // Creating it in build() would delete/recreate it on every rebuild
  // (e.g. MediaQuery or ancestor changes), re-triggering the initial
  // fetch and dropping any in-progress state.
  late final OccScInboxController controller;
  final session = Get.find<SessionController>();
  final FailureService _failureService = FailureService();
  final RxList<LabelValue> popupStationList = <LabelValue>[].obs;
  final RxBool isPopupStationLoading = false.obs;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<OccScInboxController>()) {
      Get.delete<OccScInboxController>(force: true);
    }

    controller = Get.put(OccScInboxController(isOcc: widget.isOcc));

    // Load stations from local database
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final stations = await _failureService.getStationNames();
        if (stations.isNotEmpty) {
          popupStationList.assignAll(stations);
          debugPrint("Loaded ${stations.length} stations from local DB");
        }
      } catch (e) {
        debugPrint("Error loading stations from local DB: $e");
      }

      await _showStationSelectionPopup();
    });
  }

  Future<void> _showStationSelectionPopup() async {
    isPopupStationLoading.value = true;

    // Try to fetch stations
    try {
      final stations = await _failureService.getStationNames();
      if (stations.isNotEmpty) {
        popupStationList.assignAll(stations);
      }
    } catch (e) {
      debugPrint("Error fetching stations: $e");
    } finally {
      isPopupStationLoading.value = false;
    }

    Get.dialog(
      PopScope(
        canPop: true,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
                    Text("Fetching stations...", style: TextStyle(color: Colors.grey.shade600)),
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
                      },
                      child: const Icon(Icons.close, color: Colors.black87, size: 24),
                    ),
                  ),
                  CustText(name: "Select Station", size: 18, color: Colors.black, fontWeightName: FontWeight.w600),
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
                          name: "Skip",
                          size: double.infinity,
                          sHeight: 35,
                          onSelected: (_) {
                            // Allow user to skip station selection
                            session.selectedStationId.value = null;
                            session.selectedStationName.value = null;
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
                              final stationId = session.selectedStationId.value ?? '0';
                              await AuthManager().saveSelectedStationID(stationId);
                              
                              Get.back();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'Inbox',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6F8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildTopSection(controller),
              if (controller.isOcc) _buildCategoryTabs(controller),
              _buildDateFilter(context, controller),
              const SizedBox(height: 4),
              Expanded(
                child: controller.filteredInstructions.isEmpty
                    ? _buildEmptyState(controller)
                    : RefreshIndicator(
                  onRefresh: () =>
                      controller.fetchInstructions(showLoader: false),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.screenPadding,
                      4,
                      AppConstants.screenPadding,
                      24,
                    ),
                    itemCount: controller.filteredInstructions.length,
                    itemBuilder: (context, index) {
                      final item = controller.filteredInstructions[index];
                      return _buildInstructionCard(context, item, controller);
                    },
                  ),
                ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton:




      controller.isOcc
          ? FloatingActionButton(
        backgroundColor: AppColors.orangeColor,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateOccScCommunicationScreen()),
          );
        },
      )
          : null,
    );
  }

  // ================================================================
  // TOP SECTION
  // ================================================================

  Widget _buildTopSection(OccScInboxController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPadding,
        16,
        AppConstants.screenPadding,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: 'Instructions', size: 19, color: Colors.black87),
                const SizedBox(height: 3),
                !controller.isOcc ?CustText(
                  name: 'Instructions received from OCC',
                  size: 11,
                  color: AppColors.textMutedLight,
                ):Container(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.appBarColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  TablerIcons.inbox,
                  size: 15,
                  color: AppColors.textMutedLight,
                ),
                const SizedBox(width: 5),
                CustText(
                  name: '${controller.filteredInstructions.length}',
                  size: 11,
                  fontWeightName: FontWeight.w700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CATEGORY TABS
  // ================================================================

  Widget _buildCategoryTabs(OccScInboxController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              controller: controller,
              title: 'Active',
              count: controller.activeCount,
              index: 0,
            ),
          ),
          Expanded(
            child: _buildTab(
              controller: controller,
              title: 'Upcoming',
              count: controller.upcomingCount,
              index: 1,
            ),
          ),
          Expanded(
            child: _buildTab(
              controller: controller,
              title: 'Expired',
              count: controller.expiredCount,
              index: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required OccScInboxController controller,
    required String title,
    required int count,
    required int index,
  }) {
    final bool isSelected = controller.selectedTab.value == index;

    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orangeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustText(
              name: title,
              size: 12,
              fontWeightName: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DATE FILTER
  // ================================================================

  Widget _buildDateFilter(BuildContext context, OccScInboxController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPadding,
        10,
        AppConstants.screenPadding,
        6,
      ),
      child: GestureDetector(
        onTap: () => _selectDateRange(context, controller),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              // Container(
              //   width: 32,
              //   height: 32,
              //   decoration: BoxDecoration(
              //     color: AppColors.appBarColor.withOpacity(0.08),
              //     borderRadius: BorderRadius.circular(9),
              //   ),
              //   child:
              // ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustText(
                      name: controller.selectedDateRange.value == null
                          ? 'Date'
                          : 'Selected date range',
                      size: 9,
                      color: Colors.black45,
                    ),
                    const SizedBox(height: 2),
                    CustText(
                      name: _getDateFilterText(controller),
                      size: 12,
                      fontWeightName: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
              if (controller.selectedDateRange.value != null)
                GestureDetector(
                  onTap: controller.clearDateRange,
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(TablerIcons.x, size: 16, color: Colors.black45),
                  ),
                ),

              const Icon(
                TablerIcons.calendar,
                size: 30,
                color: AppColors.orangeColor,
              ),
              const SizedBox(width: 3),
              const Icon(TablerIcons.chevron_down, size: 25, color: AppColors.orangeColor),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateFilterText(OccScInboxController controller) {
    final range = controller.selectedDateRange.value;
    if (range == null) return 'All dates';

    final start = DateFormat('dd MMM yyyy').format(range.start);
    final end = DateFormat('dd MMM yyyy').format(range.end);
    return '$start - $end';
  }

  Future<void> _selectDateRange(
      BuildContext context,
      OccScInboxController controller,
      ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: controller.selectedDateRange.value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.orangeColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor:
              AppColors.orangeColor.withOpacity(0.20),

              rangePickerHeaderBackgroundColor:
              AppColors.appBarColor,

              rangePickerHeaderForegroundColor:
              Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setDateRange(picked);
    }
  }





  // ================================================================
  // INSTRUCTION CARD
  // ================================================================
  Widget _buildInstructionCard(
      BuildContext context,
      OccInstructionListItem item,
      OccScInboxController controller,
      ) {
    final String instructionType = item.instructionTypeName;
    final String status = item.acknowledgementStatus;
    final bool acknowledgedByMe = item.isAcknowledgedByCurrentUser == true;

    final String date = item.issueDate == null
        ? '-'
        : DateFormat('dd-MM-yyyy').format(item.issueDate!);
    final String validityDate =
    item.validityUpto == null
        ? '-'
        : DateFormat('dd-MM-yyyy').format(item.validityUpto!);

    final bool showFooter =
        acknowledgedByMe || item.instructionStatus.toLowerCase() == 'expired';

    return GestureDetector(
      onTap: () {
        Get.to(
              () => InstructionDetailsScreen(
            instructionId: item.instructionId,
            isOcc: controller.isOcc,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row — same OCC vs SC logic as before, just restyled.
            !controller.isOcc? Row(
              children: [
                const CustText(
                  name: 'Status ',
                  size: 13,
                  color: Colors.black45,
                ),
                _buildStatusChip(
                  acknowledgedByMe ? 'Acknowledged' : 'Pending',
                ),
              ],
            ):
            Row(
              children: [
                const CustText(
                  name: 'Instruction Type : ',
                  size: 13,
                  color: Colors.black45,
                ),
                CustText(
                  name: item.instructionTypeName,
                  size: 13,
                  fontWeightName: FontWeight.w600,
                  color: getInstructionTypeColor(
                    item.instructionTypeName,
                  ),
                ),
              ],
            )
            ,
            const SizedBox(height: 12),
            Divider(color: AppColors.lightBlueColor, height: 1),
            const SizedBox(height: 14),

            // Row 1 — ID / Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildGridItem(
                    'Instruction ID:',
                    item.instructionNumber,
                  ),
                ),
                Expanded(
                  child: _buildGridItem('Instruction Date:', date),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Row 2 — Type / By
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildGridItem('Valid Upto: ', validityDate),
                ),
                !controller.isOcc?Expanded(
                  child: _buildGridItem(
                    'Instruction Type:',
                    item.instructionTypeName,
                  ),
                ):Expanded(
                  child: _buildGridItem(
                    'Instruction By:',
                    item.instructionByName,
                  ),
                ),
              ],
            ),

            // Recipients / acknowledged count — OCC only, same as before.
            if (controller.isOcc) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildGridItem(
                      'Recipients:',
                      item.recipientSummary,
                    ),
                  ),
                  Expanded(
                    child: _buildGridItem(
                      'Acknowledged:',
                      '${item.acknowledgedStations}',
                    ),
                  ),
                ],
              ),
            ],

            // Footer — acknowledged badge + re-create, same conditions as before.
            if (showFooter) ...[
              // const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 10),
                // decoration: BoxDecoration(
                //   border: Border(top: BorderSide(color: Colors.red.shade200)),
                // ),
                child: Row(
                  children: [
                    // if (acknowledgedByMe) ...[
                    //   Icon(TablerIcons.circle_check,
                    //       size: 13, color: Colors.green.shade600),
                    //   const SizedBox(width: 4),
                    //   Text(
                    //     'Acknowledged',
                    //     style: TextStyle(
                    //       fontSize: 9,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.green.shade600,
                    //     ),
                    //   ),
                    // ],
                    const Spacer(),
                    if (item.instructionStatus.toLowerCase() == 'expired')
                      GestureDetector(
                        onTap: () {
                          controller.recreateInstruction(item.instructionId);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.appBarColor.withOpacity(0.10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                TablerIcons.copy,
                                size: 14,
                                color: AppColors.appBarColor,
                              ),
                              const SizedBox(width: 5),
                              CustText(
                                name: 'Re-create',
                                size: 10,
                                fontWeightName: FontWeight.w600,
                                color: AppColors.appBarColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color getInstructionTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'general':
        return Colors.blue;
      case 'technical':
        return Colors.orange;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.black45;
    }
  }

// ================================================================
// GRID ITEM (label above value — used for ID/Date/Type/By rows)
// ================================================================

  Widget _buildGridItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: label,
          size: 11.5,
          color: Colors.black45,
        ),
        const SizedBox(height: 4),
        CustText(
          name: value.isEmpty ? '-' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          size: 13.5,
          fontWeightName: FontWeight.w700,
          color: Colors.black87,
        ),
      ],
    );
  }


  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color background;
    Color iconColor;

    switch (type) {
      case 'Emergency':
        icon = TablerIcons.alert_triangle;
        background = Colors.red.withOpacity(0.09);
        iconColor = Colors.red.shade600;
        break;
      case 'Technical':
        icon = TablerIcons.settings;
        background = Colors.orange.withOpacity(0.10);
        iconColor = Colors.orange.shade800;
        break;
      default:
        icon = TablerIcons.file_text;
        background = Colors.blue.withOpacity(0.09);
        iconColor = Colors.blue.shade700;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(11)),
      child: Icon(icon, size: 19, color: iconColor),
    );
  }

  // ================================================================
  // STATUS
  // ================================================================

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;

    switch (status) {
      case 'Acknowledged':
        chipColor = Colors.green.withOpacity(0.09);
        textColor = Colors.green.shade700;
        break;
      case 'Partially Acknowledged':
        chipColor = Colors.orange.withOpacity(0.09);
        textColor = Colors.orange.shade800;
        break;
      case 'Pending':
        chipColor = Colors.blue.withOpacity(0.09);
        textColor = Colors.blue.shade700;
        break;
      default:
        chipColor = Colors.grey.withOpacity(0.10);
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(11)),
      child: CustText(
        name: status == 'Partially Acknowledged'
            ? 'Partial'
            : status.isEmpty
            ? '-'
            : status,
        size: 8.5,
        fontWeightName: FontWeight.w700,
        color: textColor,
      ),
    );
  }

  // ================================================================
  // EMPTY
  // ================================================================

  Widget _buildEmptyState(OccScInboxController controller) {
    final String title;

    switch (controller.selectedTab.value) {
      case 0:
        title = 'No active instructions';
        break;
      case 1:
        title = 'No upcoming instructions';
        break;
      case 2:
        title = controller.selectedDateRange.value != null
            ? 'No expired instructions for selected date'
            : 'No expired instructions';
        break;
      default:
        title = 'No instructions';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.appBarColor.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(TablerIcons.inbox, size: 28, color: AppColors.textMutedLight),
            ),
            const SizedBox(height: 14),
            CustText(
              name: title,
              textAlign: TextAlign.center,
              size: 14,
              fontWeightName: FontWeight.w600,
              color: Colors.black87,
            ),
            const SizedBox(height: 5),
            CustText(
              name: controller.selectedTab.value == 0
                  ? 'No active instructions available.'
                  : controller.selectedTab.value == 1
                  ? 'No upcoming instructions available.'
                  : 'No expired instructions available.',
              textAlign: TextAlign.center,
              size: 11,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }
}