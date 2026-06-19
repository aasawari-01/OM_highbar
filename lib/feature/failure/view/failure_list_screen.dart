import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../constants/colors.dart';

import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../../../constants/app_constants.dart';
import 'create_failure_screen.dart';

import 'package:get/get.dart';
import '../controller/failure_list_controller.dart';
import '../model/failure_list_response.dart';
import '../../../service/session_controller.dart';

class FailureListScreen extends StatefulWidget {
  final String failureType;
  const FailureListScreen({Key? key, this.failureType = "Maintenance"}) : super(key: key);

  @override
  State<FailureListScreen> createState() => _FailureListScreenState();
}

class _FailureListScreenState extends State<FailureListScreen> with SingleTickerProviderStateMixin {
  late final FailureListController controller;
  TabController? _tabController;

  bool get _showStationTabs {
    final role = Get.find<SessionController>().selectedRole.value?.roleDescr ?? '';
    return widget.failureType == 'Station' && role.contains('Station Controller');
  }

  bool get _showJETabs {
    final role = Get.find<SessionController>().selectedRole.value?.roleDescr ?? '';
    return role.contains('Junior Engineer');
  }

  @override
  void initState() {
    super.initState();
    controller = Get.put(FailureListController(), tag: widget.failureType);
    controller.setFailureType(widget.failureType);

    if (_showStationTabs || _showJETabs) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(_onTabChanged);
    }

    controller.fetchFailures();
  }

  void _onTabChanged() {
    if (_tabController == null || _tabController!.indexIsChanging) return;
    if (_showStationTabs) {
      controller.setStationTab(
        _tabController!.index == 0 ? StationFailureListTab.active : StationFailureListTab.closed,
      );
    } else if (_showJETabs) {
      controller.setJETab(
        _tabController!.index == 0 ? JEFailureListTab.inbox : JEFailureListTab.jointInspection,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: '${widget.failureType} Failure List',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          Stack(
            alignment: Alignment.center,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.appBarColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            if (_showStationTabs || _showJETabs) ...[
              TabBar(
                controller: _tabController,
                labelColor: AppColors.orangeColor,
                unselectedLabelColor: AppColors.textColor4,
                indicatorColor: AppColors.orangeColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                tabs: _showStationTabs 
                  ? const [
                      Tab(text: 'Failure List'),
                      Tab(text: 'Closed List'),
                    ]
                  : const [
                      Tab(text: 'JE Inbox'),
                      Tab(text: 'Joint Inspection Inbox'),
                    ],
              ),
              const Divider(height: 1, color: AppColors.dividerColor2),
            ],
            Expanded(child: _buildFailureListContent()),
          ],
        ),
      ),
      floatingActionButton: Obx(() {
        final session = Get.find<SessionController>();
        final role = session.selectedRole.value?.roleDescr ?? "";
        final isJE = role.contains("Junior Engineer");
        final isTechnician = role.contains("Technician");
        final isStationController = role.contains("Station Controller");

        if (isJE || isTechnician) {
          return const SizedBox.shrink();
        }

        if (isStationController && widget.failureType != 'Station') {
          return const SizedBox.shrink();
        }

        if (isStationController && controller.selectedStationTab.value == StationFailureListTab.closed) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton(
          backgroundColor: AppColors.orangeColor,
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateFailureScreen(failureType: widget.failureType)),
            );
          },
        );
      }),
    );
  }

  Widget _buildFailureListContent() {
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
      child: controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : controller.errorMessage.isNotEmpty
              ? Center(child: CustText(name: controller.errorMessage.value, size: 14))
              : controller.failures.isEmpty
                  ? Center(
                      child: Text(
                        _showStationTabs && controller.selectedStationTab.value == StationFailureListTab.closed
                            ? 'No closed failures found'
                            : 'No failures found',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => controller.fetchFailures(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: AppConstants.elementSpacing),
                        itemCount: controller.failures.length,
                        itemBuilder: (context, index) {
                          final failure = controller.failures[index];
                          return _buildFailureCard(failure);
                        },
                      ),
                    ),
    ));
  }

  Widget _buildFailureCard(FailureItem failure) {
    return GestureDetector(
      onTap: () {
        final isJI = _showJETabs &&
            controller.selectedJETab.value == JEFailureListTab.jointInspection;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateFailureScreen(
            failureNo: failure.failureNo, 
            notificationCode: failure.notificationCode, 
            failureType: widget.failureType,
            isFromJointInspection: isJI,
          )),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.elementSpacing),
        decoration: BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CustText(
                        name: 'Priority:',
                        size: 13,
                        color: AppColors.textColor4,
                      ),
                      const SizedBox(width: 6),
                      _priorityChip(failure.priority?.trim().isNotEmpty == true ? failure.priority! : 'N/A'),
                    ],
                  ),
                  Row(
                    children: [
                      CustText(
                        name: 'Status:',
                        size: 13,
                        color: AppColors.textColor4,
                      ),
                      const SizedBox(width: 6),
                      _statusChip(failure.statusName ?? ''),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.dividerColor3, height: 1),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelValue('Failure No:', failure.notificationCode ?? ''),
                        const SizedBox(height: 12),
                        _buildLabelValue('Created On:', failure.failureOccuranceDateTime ?? ''),
                        const SizedBox(height: 12),
                        _buildLabelValue('Location:', failure.locationName ?? ''),
                      ],
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: _getStatusDotColor("online"),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusDotColor("online").withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if ((failure.statusName ?? '').contains('Reject')) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.dividerColor3, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final result = await Get.to(() => CreateFailureScreen(
                            failureNo: failure.failureNo, 
                            notificationCode: failure.notificationCode, 
                            failureType: widget.failureType,
                            isUpdate: true,
                          ));
                          if (result == true) {
                            controller.fetchFailures();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.orangeColor,
                          side: const BorderSide(color: AppColors.orangeColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Update', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showCloseConfirmation(failure.id ?? 0),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red,
                          side: const BorderSide(color: AppColors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Close', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showReopenPopup(failure.id ?? 0),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Re-open', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText.detailLabel(label),
        const SizedBox(height: 2),
        CustText.detailValue(value),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return AppColors.textColor4;
    if (status.contains('Reject')) return AppColors.red;
    if (status.contains('Pending')) return AppColors.red;
    if (status.contains('Complete')) return AppColors.green;
    if (status == 'Assigned' || status == 'Reassigned') return AppColors.orangeColor;
    return AppColors.textColor4;
  }

  Widget _priorityChip(String priority) {
    Color text;
    switch (priority) {
      case 'Low':
        text = AppColors.darkBlue;
        break;
      case 'Medium':
        text = AppColors.yellow;
        break;
      case 'High':
        text = AppColors.orangeColor;
        break;
      case 'N/A':
        text = AppColors.textColor4;
        break;
      default:
        text = AppColors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustText(
        name: priority,
        size: 13,
        color: text,
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustText(
        name: status,
        size: 13,
        color: color,
      ),
    );
  }

  Color _getStatusDotColor(String? status) {
    switch (status) {
      case 'online':
        return AppColors.green;
      case 'offline':
        return AppColors.orangeColor;
      default:
        return AppColors.textColor4;
    }
  }

  void _showCloseConfirmation(int failureId) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(TablerIcons.alert_circle, color: AppColors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Close Failure",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Are you sure you want to close this failure? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Get.back();
                      controller.closeFailure(failureId);
                    },
                    child: const Text("Close"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReopenPopup(int failureId) {
    final TextEditingController remarkController = TextEditingController();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(TablerIcons.refresh, color: AppColors.green, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Re-open Failure",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Please provide a reason for re-opening this failure:"),
              const SizedBox(height: 8),
              TextField(
                controller: remarkController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter remark...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.green),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final remark = remarkController.text.trim();
                      if (remark.isEmpty) {
                        Get.snackbar("Required", "Please enter a remark to re-open.", backgroundColor: Colors.red, colorText: Colors.white);
                        return;
                      }
                      Get.back();
                      _showReopenConfirmation(failureId, remark);
                    },
                    child: const Text("Submit"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReopenConfirmation(int failureId, String remark) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(TablerIcons.alert_triangle, color: AppColors.orangeColor, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Confirm Re-open",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Are you sure you want to re-open this failure with the provided remark?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Get.back();
                      controller.reOpenFailure(failureId, remark);
                    },
                    child: const Text("Confirm"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
