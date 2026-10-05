import 'package:flutter/material.dart';
import 'package:om_mobile/utils/widgets/app_snackbar.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../constants/colors.dart';

import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/cust_popup.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../../../utils/widgets/sync_icon_button.dart';
import '../../../constants/app_constants.dart';
import 'forms/create_failure_screen.dart';

import 'package:get/get.dart';
import '../controller/failure_list_controller.dart';
import '../model/failure_list_response.dart';
import '../../../core/controller/session_controller.dart';
import '../../../service/master_data_sync_service.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../filter/view/filter.dart';
import '../service/failure_service.dart';
import 'shared/depot_selection_popup.dart';

class FailureListScreen extends StatefulWidget {
  final String failureType;
  const FailureListScreen({super.key, this.failureType = "Maintenance"});

  @override
  State<FailureListScreen> createState() => _FailureListScreenState();
}

class _FailureListScreenState extends State<FailureListScreen> with SingleTickerProviderStateMixin {
  late final FailureListController controller;
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final session = Get.find<SessionController>();
  final FailureService _failureService = FailureService();

  bool get _showJETabs {
    final role = Get.find<SessionController>().selectedRole.value?.roleDescr ?? '';
    return role.contains('Junior Engineer');
  }

  bool get _isStationController {
    final role = Get.find<SessionController>().selectedRole.value?.roleDescr ?? '';
    return role.contains('Station Controller');
  }

  bool get _isSectionIncharge {
    final role = Get.find<SessionController>().selectedRole.value?.roleDescr ?? '';
    return role.contains('Section Incharge');
  }

  @override
  void initState() {
    super.initState();

    controller = Get.put(
      FailureListController(),
      tag: widget.failureType,
    );

    controller.setFailureType(widget.failureType);

    if (_showJETabs) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(_onTabChanged);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // DCC depot list: pick a depot (saved via API) before loading the list.
      if (widget.failureType == 'Depot' && controller.isDcc) {
        final selected = await showDepotSelectionPopup();
        if (!selected) {
          if (mounted) Navigator.pop(context);
          return;
        }
      }
      controller.fetchFailures();
    });
  }

  void _onTabChanged() {
    if (_tabController == null || _tabController!.indexIsChanging) return;
    if (_showJETabs) {
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
        // Section Incharge's list shows all failures, so it is just "Failure List".
        title: _isSectionIncharge && widget.failureType == 'Maintenance'
            ? 'Failure List'
            : '${widget.failureType} Failure List',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  controller.searchQuery.value = "";
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 28),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: FilterPopup(
                    initialStatuses: controller.selectedStatusFilter.value.isEmpty 
                      ? {} 
                      : {controller.selectedStatusFilter.value},
                    onApply: (statuses) {
                      if (statuses.isNotEmpty) {
                        controller.selectedStatusFilter.value = statuses.first;
                      } else {
                        controller.selectedStatusFilter.value = "";
                      }
                      // UI updates automatically because filteredFailures uses selectedStatusFilter.value
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          SyncIconButton(failureType: widget.failureType),
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
            if (_showJETabs) ...[
              TabBar(
                controller: _tabController,
                labelColor: AppColors.orangeColor,
                unselectedLabelColor: AppColors.textDarkSecondary,
                indicatorColor: AppColors.orangeColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                tabs: const [
                      Tab(text: 'JE Inbox'),
                      Tab(text: 'Joint Inspection Inbox'),
                    ],
              ),
              const Divider(height: 1, color: AppColors.dividerColor2),
            ],
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: 8),
                child: CustomTextField(
                  controller: _searchController,
                  hintText: "Search by failure no, location, status...",
                  onChanged: (val) => controller.searchQuery.value = val,
                  prefixIcon: const Icon(Icons.search, color: AppColors.textDarkSecondary, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      controller.searchQuery.value = '';
                      setState(() => _isSearching = false);
                    },
                    child: const Icon(Icons.close, color: AppColors.textDarkSecondary, size: 20),
                  ),
                  autofocus: true,
                ),
              ),
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
        final isSectionIncharge = role.contains("Section Incharge");

        if (isJE || isTechnician || SessionController.isOccDelegateRole(role)) {
          return const SizedBox.shrink();
        }

        // DCC can only create depot failures.
        if (role.toUpperCase().contains("DCC") && widget.failureType != 'Depot') {
          return const SizedBox.shrink();
        }

        if (isStationController && widget.failureType != 'Station') {
          return const SizedBox.shrink();
        }

        // Section Incharge can only create maintenance failures
        if (isSectionIncharge && widget.failureType != 'Maintenance') {
          return const SizedBox.shrink();
        }

        // Section Incharge and other users can create failures
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
    return Obx(() {
      final syncService = Get.find<MasterDataSyncService>();
      if (syncService.isSyncing.value) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CustLoader(),
            const SizedBox(height: 16),
            CustText(
              name: syncService.syncStatus.value,
              size: 14,
              color: AppColors.orangeColor,
            ),
          ],
        );
      }
      if (controller.isLoading.value) {
        return const CustLoader();
      }
      if (controller.errorMessage.isNotEmpty) {
        return Center(child: CustText(name: controller.errorMessage.value, size: 14));
      }
      if (controller.filteredFailures.isEmpty) {
        return Center(
          child: Text(
            'No failures found',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => controller.fetchFailures(),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: AppConstants.elementSpacing),
          itemCount: controller.filteredFailures.length,
          itemBuilder: (context, index) {
            final failure = controller.filteredFailures[index];
            return _buildFailureCard(failure);
          },
        ),
      );
    });
  }

  Widget _buildFailureCard(FailureItem failure) {
    return GestureDetector(
      onTap: () async{
        final isJI = _showJETabs &&
            controller.selectedJETab.value == JEFailureListTab.jointInspection;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateFailureScreen(
            failureNo: failure.failureNo,
            notificationCode: failure.notificationCode, 
            failureType: widget.failureType,
            isFromJointInspection: isJI,
            failureItem: failure,
          )),
        );
        if (result == true) {
          controller.fetchFailures();
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppConstants.elementSpacing,AppConstants.elementSpacing,AppConstants.elementSpacing,0),
        decoration: BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.2),
              blurRadius: 8,
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
                children: [
                  CustText(
                    name: 'Status:',
                    size: 13,
                    color: AppColors.textDarkSecondary,
                  ),
                  const SizedBox(width: 6),
                  _statusChip(failure.statusName ?? ''),
                  if (_isDccDepot &&
                      (failure.occRequestStatusName ?? '').trim().isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _statusChip(failure.occRequestStatusName!.trim()),
                  ],
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
                        _buildLabelValue('Failure No:', failure.notificationCode ?? failure.failureNo!),
                        const SizedBox(height: 12),
                        _buildLabelValue('Failure description:', failure.failureDescription ?? ''),
                       ],
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: _getStatusDotColor(failure.syncStatus),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusDotColor(failure.syncStatus).withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if ((failure.statusName ?? '').toLowerCase().contains('confirm') && _isStationController) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.dividerColor3, height: 1),
                const SizedBox(height: 12),
                ActionChip(
                  label: const Text('Acknowledge', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onPressed: () => _showAcknowledgePopup(failure),
                  backgroundColor: AppColors.white1,
                  labelStyle: const TextStyle(color: AppColors.green),
                  side: const BorderSide(color: AppColors.green),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ],
              if ((failure.statusName ?? '').contains('Reject') && _isStationController) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.dividerColor3, height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Update', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                      backgroundColor: AppColors.white1,
                      labelStyle: const TextStyle(color: AppColors.orangeColor),
                      side: const BorderSide(color: AppColors.orangeColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    ActionChip(
                      label: const Text('Close', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      onPressed: () => _showCloseConfirmation(failure.id ?? 0),
                      backgroundColor: AppColors.white1,
                      labelStyle: const TextStyle(color: AppColors.red),
                      side: const BorderSide(color: AppColors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    ActionChip(
                      label: const Text('Re-open', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      onPressed: () => _showReopenPopup(failure.id ?? 0),
                      backgroundColor: AppColors.white1,
                      labelStyle: const TextStyle(color: AppColors.green),
                      side: const BorderSide(color: AppColors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ],
                ),
              ],
              // DCC depot failure buttons (same rules as the web depot list)
              if (_isDccDepot && _depotHasActions(failure)) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.dividerColor3, height: 1),
                const SizedBox(height: 12),
                _buildDepotActions(failure),
              ],
              // Section Incharge specific buttons
              if (_isSectionIncharge) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.dividerColor3, height: 1),
                const SizedBox(height: 12),
                _buildSectionInchargeActions(failure),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── DCC depot failure actions ─────────────────────────────────────────────

  bool get _isDccDepot =>
      widget.failureType == 'Depot' && controller.isDcc;

  /// Web: Acknowledge when status is "Work Complete"; Re-Open / Close when
  /// statusId is 195 or 175.
  bool _isDepotWorkComplete(FailureItem f) =>
      (f.statusName ?? '').trim() == 'Work Complete';

  bool _depotCanReopenClose(FailureItem f) =>
      f.statusId == 195 || f.statusId == 175;

  bool _depotHasActions(FailureItem f) =>
      _isDepotWorkComplete(f) || _depotCanReopenClose(f);

  Widget _depotChip(String label, Color color, VoidCallback onTap) {
    return ActionChip(
      label: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      onPressed: onTap,
      backgroundColor: AppColors.white1,
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildDepotActions(FailureItem failure) {
    final id = failure.id ?? 0;
    final code = failure.notificationCode ?? failure.failureNo;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_isDepotWorkComplete(failure))
          _depotChip('Acknowledge', AppColors.green,
                  () => _showDepotAcknowledgePopup(failure)),
        if (_depotCanReopenClose(failure)) ...[
          _depotChip('Re-Open', AppColors.green,
                  () => _showDepotReopenPopup(id, code)),
          _depotChip('Close', AppColors.red,
                  () => _showDepotCloseConfirmation(id, code)),
        ],
      ],
    );
  }

  void _showDepotCloseConfirmation(int id, String? code) {
    Get.dialog(
      CustPopup(
        title: "Close Failure",
        message: "Do you want close failure?",
        icon: TablerIcons.alert_circle,
        iconColor: AppColors.red,
        confirmText: "Yes",
        cancelText: "Cancel",
        onCancel: () => Get.back(),
        onConfirm: () {
          Get.back();
          controller.closeDepotFailure(id, failureNo: code);
        },
      ),
    );
  }

  void _showDepotReopenPopup(int id, String? code) {
    final remarkController = TextEditingController();
    String? error;
    Get.dialog(
      CustPopup(
        title: "Send For Re-open Failure",
        showIcon: true,
        icon: TablerIcons.refresh,
        iconColor: AppColors.green,
        onCancel: () => Get.back(),
        customContent: StatefulBuilder(
          builder: (context, setPopupState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: CustText(
                    name: "Send For Re-open Failure",
                    size: AppConstants.headerSize,
                    color: AppColors.textMutedLight,
                    fontWeightName: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              CustText(
                  name: "Remark *",
                  size: AppConstants.formLabelSize,
                  fontWeightName: FontWeight.w500),
              const SizedBox(height: 8),
              CustomTextField(
                controller: remarkController,
                hintText: "Enter remark (max 250 characters)",
                maxLines: 3,
                maxLength: 250,
                onChanged: (v) {
                  if (error != null && v.trim().isNotEmpty) {
                    setPopupState(() => error = null);
                  }
                },
              ),
              if (error != null)
                Text(error!,
                    style: const TextStyle(color: AppColors.red, fontSize: 12)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustOutlineButton(
                      name: "Close",
                      size: double.infinity,
                      sHeight: 35,
                      onSelected: (_) => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustButton(
                      name: "Submit",
                      size: double.infinity,
                      sHeight: 35,
                      onSelected: (_) {
                        final remark = remarkController.text.trim();
                        if (remark.isEmpty) {
                          setPopupState(() => error = "Please enter remark.");
                          return;
                        }
                        Get.back();
                        Get.dialog(
                          CustPopup(
                            title: "Confirm",
                            message: "Do you want reopen failure?",
                            icon: TablerIcons.alert_triangle,
                            iconColor: AppColors.orangeColor,
                            confirmText: "Yes",
                            cancelText: "Cancel",
                            onCancel: () => Get.back(),
                            onConfirm: () {
                              Get.back();
                              controller.reOpenDepotFailure(id, remark,
                                  failureNo: code);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDepotAcknowledge(FailureItem failure, String remark,
      {required bool accept}) {
    Get.dialog(
      CustPopup(
        title: "Confirm",
        message: accept
            ? "Do you want acknowledge accept failure?"
            : "Do you want acknowledge deny failure?",
        icon: accept ? TablerIcons.circle_check : TablerIcons.alert_triangle,
        iconColor: accept ? AppColors.green : AppColors.orangeColor,
        confirmText: "Yes",
        cancelText: "Cancel",
        onCancel: () => Get.back(),
        onConfirm: () async {
          Get.back(); // confirm dialog
          Get.back(); // acknowledge popup
          await controller.acknowledgeDepotFailure(
            failure.id ?? 0,
            remark,
            accept: accept,
            failureNo: failure.notificationCode ?? failure.failureNo,
          );
        },
      ),
    );
  }

  void _showDepotAcknowledgePopup(FailureItem failure) {
    final remarkController = TextEditingController();
    final code = failure.notificationCode ?? failure.failureNo ?? '';
    String? error;
    Get.dialog(
      CustPopup(
        title: "Acknowledge For Failure",
        showIcon: true,
        icon: TablerIcons.circle_check,
        iconColor: AppColors.green,
        onCancel: () => Get.back(),
        customContent: StatefulBuilder(
          builder: (context, setPopupState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: CustText(
                    name: "Acknowledge For Failure",
                    size: AppConstants.headerSize,
                    color: AppColors.textMutedLight,
                    fontWeightName: FontWeight.w600),
              ),
              if (code.isNotEmpty) ...[
                const SizedBox(height: 6),
                Center(
                  child: CustText(
                      name: "Failure No: $code",
                      size: 13,
                      color: AppColors.orangeColor,
                      fontWeightName: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 16),
              CustText(
                  name: "Remark *",
                  size: AppConstants.formLabelSize,
                  fontWeightName: FontWeight.w500),
              const SizedBox(height: 8),
              CustomTextField(
                controller: remarkController,
                hintText: "Enter remark (max 250 characters)",
                maxLines: 3,
                maxLength: 250,
                onChanged: (v) {
                  if (error != null && v.trim().isNotEmpty) {
                    setPopupState(() => error = null);
                  }
                },
              ),
              if (error != null)
                Text(error!,
                    style: const TextStyle(color: AppColors.red, fontSize: 12)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustOutlineButton(
                      name: "Close",
                      size: double.infinity,
                      sHeight: 36,
                      fontSize: 14,
                      onSelected: (_) => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustButton(
                      name: "Deny",
                      size: double.infinity,
                      sHeight: 36,
                      fontSize: 14,
                      color1: AppColors.red,
                      color2: AppColors.red,
                      onSelected: (_) {
                        final remark = remarkController.text.trim();
                        if (remark.isEmpty) {
                          setPopupState(() => error = "Please enter remark.");
                          return;
                        }
                        _confirmDepotAcknowledge(failure, remark, accept: false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustButton(
                      name: "Accept",
                      size: double.infinity,
                      sHeight: 36,
                      fontSize: 14,
                      color1: AppColors.green,
                      color2: AppColors.green,
                      onSelected: (_) => _confirmDepotAcknowledge(
                          failure, remarkController.text.trim(),
                          accept: true),
                    ),
                  ),
                ],
              ),
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
    if (status == null) return AppColors.textDarkSecondary;
    if (status.contains('Reject')) return AppColors.red;
    if (status.contains('Pending')) return AppColors.red;
    if (status.contains('Complete')) return AppColors.green;
    if (status == 'Assigned' || status == 'Reassigned') return AppColors.orangeColor;
    return AppColors.textDarkSecondary;
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
        // Default to green (online) if syncStatus is null
        return AppColors.green;
    }
  }

  void _showCloseConfirmation(int failureId) {
    Get.dialog(
      CustPopup(
        title: "Close Failure",
        message: "Are you sure you want to close this failure? This action cannot be undone.",
        icon: TablerIcons.alert_circle,
        iconColor: AppColors.red,
        confirmText: "Close",
        cancelText: "Cancel",
        onCancel: () => Get.back(),
        onConfirm: () {
          controller.closeFailure(failureId);
        },
      ),
    );
  }

  void _showReopenPopup(int failureId) {
    final TextEditingController remarkController = TextEditingController();
    Get.dialog(
      CustPopup(
        title: "Re-open Failure",
        message: "Please provide a reason for re-opening this failure:",
        icon: TablerIcons.refresh,
        iconColor: AppColors.green,
        onCancel:() =>  Get.back() ,
        // confirmText: "Submit",
        // cancelText: "Cancel",
        customContent: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustText(name: "Re-open Failure", size: AppConstants.headerSize, color: AppColors.textMutedLight, fontWeightName: FontWeight.w600),
            const SizedBox(height: 12),
            CustText(name: "Please provide a reason for re-opening:", size: AppConstants.formLabelSize),
            const SizedBox(height: 12),
            CustomTextField(
              controller: remarkController,
              hintText: "Enter remark...",
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustOutlineButton(
                    name: "Cancel",
                    size: double.infinity,
                    sHeight: 35,
                    onSelected: (_) => Get.back(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustButton(
                    name: "Submit",
                    size: double.infinity,
                    sHeight: 35,
                    onSelected: (_) {
                      final remark = remarkController.text.trim();
                      if (remark.isEmpty) {
                        appSnackbar("Required", "Please enter a remark to re-open.", backgroundColor: AppColors.red, colorText: AppColors.white1);
                        return;
                      }
                      Get.back();
                      _showReopenConfirmation(failureId, remark);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReopenConfirmation(int failureId, String remark) {
    Get.dialog(
      CustPopup(
        title: "Confirm Re-open",
        message: "Are you sure you want to re-open this failure with the provided remark?",
        icon: TablerIcons.alert_triangle,
        iconColor: AppColors.orangeColor,
        confirmText: "Confirm",
        cancelText: "Cancel",
        onConfirm: () {
          controller.reOpenFailure(failureId, remark);
        },
      ),
    );
  }

  void _showAcknowledgePopup(FailureItem failure) {
    final TextEditingController remarkController = TextEditingController();
    final notifCode = failure.notificationCode ?? failure.failureNo ?? failure.id.toString();
    final failureId = failure.id ?? 0;
    String? remarkError;

    Get.dialog(
      CustPopup(
        title: "Acknowledge For Failure",
        showIcon: true,
        icon: TablerIcons.circle_check,
        iconColor: AppColors.green,
        onCancel: () => Get.back(),
        customContent: StatefulBuilder(
          builder: (context, setPopupState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: CustText(
                    name: "Acknowledge For Failure",
                    size: AppConstants.headerSize,
                    color: AppColors.textMutedLight,
                    fontWeightName: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: CustText(
                    name: "Please enter remark to continue.",
                    size: 13,
                    color: AppColors.textDarkSecondary,
                  ),
                ),
                if (notifCode.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: CustText(
                      name: "Failure No: $notifCode",
                      size: 13,
                      color: AppColors.orangeColor,
                      fontWeightName: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CustText(
                  name: "Remark *",
                  size: AppConstants.formLabelSize,
                  fontWeightName: FontWeight.w500,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: remarkController,
                  hintText: "Enter remark",
                  maxLines: 3,
                  maxLength: 250,
                  onChanged: (val) {
                    if (remarkError != null && val.trim().isNotEmpty) {
                      setPopupState(() {
                        remarkError = null;
                      });
                    }
                  },
                ),
                if (remarkError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    remarkError!,
                    style: const TextStyle(color: AppColors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustOutlineButton(
                        name: "Close",
                        size: double.infinity,
                        sHeight: 36,
                        fontSize: 14,
                        onSelected: (_) => Get.back(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustButton(
                        name: "Deny",
                        size: double.infinity,
                        sHeight: 36,
                        fontSize: 14,
                        color1: AppColors.red,
                        color2: AppColors.red,
                        onSelected: (_) {
                          final remark = remarkController.text.trim();
                          if (remark.isEmpty) {
                            setPopupState(() {
                              remarkError = "Please enter remark.";
                            });
                            return;
                          }
                          _confirmAndSubmitAcknowledge(
                            failureId: failureId,
                            notificationCode: notifCode,
                            remark: remark,
                            submitStatus: "deny",
                            confirmMessage: "Do you want acknowledge deny failure?",
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustButton(
                        name: "Accept",
                        size: double.infinity,
                        sHeight: 36,
                        fontSize: 14,
                        color1: AppColors.green,
                        color2: AppColors.green,
                        onSelected: (_) {
                          final remark = remarkController.text.trim();
                          _confirmAndSubmitAcknowledge(
                            failureId: failureId,
                            notificationCode: notifCode,
                            remark: remark,
                            submitStatus: "accept",
                            confirmMessage: "Do you want acknowledge accept failure?",
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _confirmAndSubmitAcknowledge({
    required int failureId,
    required String notificationCode,
    required String remark,
    required String submitStatus,
    required String confirmMessage,
  }) {
    Get.dialog(
      CustPopup(
        title: "Confirm",
        message: confirmMessage,
        icon: submitStatus == "accept" ? TablerIcons.circle_check : TablerIcons.alert_triangle,
        iconColor: submitStatus == "accept" ? AppColors.green : AppColors.orangeColor,
        confirmText: submitStatus == "accept" ? "Accept" : "Deny",
        cancelText: "Cancel",
        onCancel: () => Get.back(),
        onConfirm: () async {
          Get.back(); // close confirm dialog
          Get.back(); // close acknowledge popup
          await controller.acknowledgeFailure(
            failureId,
            remark,
            submitStatus,
            failureNo: notificationCode,
          );
        },
      ),
    );
  }

  /// Web rule for the Section Incharge Close button: status 4 and not a train
  /// set failure; for failures raised by a Station / Depot request it only
  /// appears once the Station Controller has acknowledged the request
  /// (occRequestStatusId 197 or 176).
  bool _sectionInchargeCanClose(FailureItem failure) {
    if (failure.statusId != 4 || failure.isTrainSetFailure != false) {
      return false;
    }
    final from = (failure.otherRequestFrom ?? '').trim();
    if (from == 'Station Request' || from == 'Depot Request') {
      final ack = failure.occRequestStatusId;
      return ack == 197 || ack == 176;
    }
    return true;
  }

  // Section Incharge specific action buttons
  Widget _buildSectionInchargeActions(FailureItem failure) {
    final statusId = failure.statusId ?? 0;
    final occRequestStatus = failure.occRequestStatus ?? '';

    List<Widget> chips = [];

    // Assign button for statusId 1, 178, 202
    if (statusId == 1 || statusId == 178 || statusId == 202) {
      chips.add(
        ActionChip(
          label: const Text('Assign', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          onPressed: () => _showAssignPopup(failure),
          backgroundColor: AppColors.white1,
          labelStyle: const TextStyle(color: AppColors.orangeColor),
          side: const BorderSide(color: AppColors.orangeColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // Reassign button for statusId 2, 41, 4, 44, 166
    if (statusId == 2 || statusId == 41 || statusId == 4 || statusId == 44 || statusId == 166) {
      chips.add(
        ActionChip(
          label: const Text('Reassign', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          onPressed: () => _showAssignPopup(failure),
          backgroundColor: AppColors.white1,
          labelStyle: const TextStyle(color: AppColors.orangeColor),
          side: const BorderSide(color: AppColors.orangeColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // Close button (same rule as the web list)
    if (_sectionInchargeCanClose(failure)) {
      chips.add(
        ActionChip(
          label: const Text('Close', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            onPressed: () => _showSectionInchargeCloseConfirmation(failure),
          backgroundColor: AppColors.white1,
          labelStyle: const TextStyle(color: AppColors.red),
          side: const BorderSide(color: AppColors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // Send For Correction for statusId 4
    if (statusId == 4) {
      chips.add(
        ActionChip(
          label: const Text('Send For Correction', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          onPressed: () => _showCorrectionPopup(failure),
          backgroundColor: AppColors.white1,
          labelStyle: const TextStyle(color: AppColors.orangeColor),
          side: const BorderSide(color: AppColors.orangeColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // Reject For Duplicate when occRequestStatus == "Yes"
    if (occRequestStatus == "Yes") {
      chips.add(
        ActionChip(
          label: const Text('Reject For Duplicate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          onPressed: () => _showRejectPopup(failure),
          backgroundColor: AppColors.white1,
          labelStyle: const TextStyle(color: AppColors.orangeColor),
          side: const BorderSide(color: AppColors.orangeColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // Delete when occRequestStatus == "No"
    if (occRequestStatus == "No") {
      chips.add(
        ActionChip(
          label: const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          onPressed: () => _showDeletePopup(failure),
          backgroundColor: AppColors.white1,
          labelStyle: const TextStyle(color: AppColors.red),
          side: const BorderSide(color: AppColors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  void _showSectionInchargeCloseConfirmation(FailureItem failure) {
    Get.dialog(
      CustPopup(
        title: "Close Failure",
        message: "Do you want close failure?",
        icon: TablerIcons.alert_circle,
        iconColor: AppColors.red,
        confirmText: "Yes",
        cancelText: "Cancel",
        onCancel: () => Get.back(),
        onConfirm: () async {
          Get.back();
          await _handleSectionInchargeClose(failure);
          if (Get.isDialogOpen ?? false) Get.back();
        },
      ),
    );
  }

  Future<void> _handleSectionInchargeClose(FailureItem failure) async {
    final jobCardNo = failure.failureNo;

    if (jobCardNo == null || jobCardNo.isEmpty) {
      if (mounted) {
        appSnackbarMessage("Invalid Job Card No — cannot close");
      }
      return;
    }

    try {
      final success = await _failureService.closeNotification(
        jobCardNo: jobCardNo,
        assignedUserId: failure.assignedUserId ?? 0,
      );

      if (mounted) {
        if (success) {
          appSnackbarMessage("Failure closed successfully");
          controller.fetchFailures();
        } else {
          appSnackbarMessage("Operation failed");
        }
      }
    } catch (e) {
      if (mounted) {
        appSnackbarMessage("Error: $e");
      }
    }
  }

  void _showAssignPopup(FailureItem failure) {
    final statusId = failure.statusId ?? 0;
    final isAssign = statusId == 1 || statusId == 178 || statusId == 202;
    final actionText = isAssign ? 'Assign' : 'Reassign';

    // First show user selection popup
    _showAssignUserSelectionPopup(failure, actionText);
  }

  void _showAssignUserSelectionPopup(FailureItem failure, String actionText) {
    final failureController = Get.find<FailureListController>(tag: widget.failureType);

    // Get filtered users from the controller
    final filteredUsers = failureController.staffList.where((user) {
      // Filter by failure department
      final failureDeptCode = failure.deptCode ?? failure.deptId;
      final userDeptId = user.deptID;

      // Match department
      if (failureDeptCode != null && userDeptId != null) {
        if (int.tryParse(failureDeptCode.toString()) == userDeptId) {
          return true;
        }
      }

      // Also check if user dept matches failure dept name
      if (failure.departmentName != null && user.deptName != null) {
        if (failure.departmentName!.toLowerCase().contains(user.deptName!.toLowerCase()) ||
            user.deptName!.toLowerCase().contains(failure.departmentName!.toLowerCase())) {
          return true;
        }
      }

      return false;
    }).toList();

    // Show popup with custom dropdown using StatefulBuilder for dynamic updates
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return CustPopup(
            title: "$actionText User",
            message: "Select a user to ${actionText.toLowerCase()} this failure",
            icon: TablerIcons.user,
            iconColor: AppColors.orangeColor,
            cancelText: "Cancel",
            confirmText: actionText,
            onCancel: () => Get.back(),
            onConfirm: failure.assignedUserId != null && failure.assignedUserId! > 0
                ? () {
                    Get.back();
                    _showAssignConfirmationPopup(failure, actionText);
                  }
                : null,
            customContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: "Select User Name", size: AppConstants.formLabelSize),
                const SizedBox(height: 8),
                CustDropdown(
                  label: "User",
                  hint: "Select User Name",
                  items: filteredUsers.map((e) => e.userName ?? '').toList(),
                  selectedValue: failure.assignedUserId != null && failure.assignedUserId! > 0
                      ? failure.assignedUseeName
                      : null,
                  onChanged: (val) {
                    if (val != null) {
                      final selectedUser = filteredUsers.firstWhere(
                        (u) => u.userName == val,
                        orElse: () => StaffItem(),
                      );
                      setState(() {
                        failure.assignedUserId = selectedUser.userId;
                        failure.assignedUseeName = selectedUser.userName;
                      });
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAssignConfirmationPopup(FailureItem failure, String actionText) {
    Get.dialog(
      CustPopup(
        title: "$actionText User",
        message: "Are you sure you want to ${actionText.toLowerCase()} this failure to ${failure.assignedUseeName}?",
        icon: TablerIcons.user,
        iconColor: AppColors.orangeColor,
        cancelText: "Cancel",
        confirmText: actionText,
        onCancel: () => Get.back(),
        onConfirm: () {
          Get.back();
          _handleAssignAction(failure, actionText);
        },
      ),
    );
  }

  void _handleAssignAction(FailureItem failure, String actionText) async {
    final notificationId = failure.id;

    if (notificationId == null || notificationId == 0) {
      if (mounted) {
        appSnackbarMessage("Invalid Notification ID — cannot assign");
      }
      return;
    }

    if (failure.assignedUserId == null || failure.assignedUserId == 0) {
      if (mounted) {
        appSnackbarMessage("Please select a user before assigning");
      }
      return;
    }

    try {
      final success = await _failureService.assignUserNotification(
        notificationId: failure.failureNo!,
        assignedUserId: failure.assignedUserId ?? 0,
        description: actionText.toLowerCase(), // "assign" or "reassign"
      );

      if (mounted) {
        if (success) {
          appSnackbarMessage("$actionText successful");
          controller.fetchFailures();
        } else {
          appSnackbarMessage("Operation failed — please try again");
        }
      }
    } catch (e) {
      debugPrint("_handleAssignAction error: $e");
      if (mounted) {
        appSnackbarMessage("Error: $e");
      }
    }
  }
  void _showCorrectionPopup(FailureItem failure) {
    // First show detail popup (user selection + remark)
    _showCorrectionDetailPopup(failure);
  }

  void _showCorrectionDetailPopup(FailureItem failure) {
    final failureController = Get.find<FailureListController>(tag: widget.failureType);

    // Get filtered users from the controller
    final filteredUsers = failureController.staffList.where((user) {
      final failureDeptCode = failure.deptCode ?? failure.deptId;
      final userDeptId = user.deptID;

      if (failureDeptCode != null && userDeptId != null) {
        if (int.tryParse(failureDeptCode.toString()) == userDeptId) {
          return true;
        }
      }

      if (failure.departmentName != null && user.deptName != null) {
        if (failure.departmentName!.toLowerCase().contains(user.deptName!.toLowerCase()) ||
            user.deptName!.toLowerCase().contains(failure.departmentName!.toLowerCase())) {
          return true;
        }
      }

      return false;
    }).toList();

    final TextEditingController remarkController = TextEditingController();
    String? selectedUserName;
    int? selectedUserId;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return CustPopup(
            title: "Send For Correction",
            message: "Select user and provide reason for correction",
            icon: TablerIcons.alert_triangle,
            iconColor: AppColors.orangeColor,
            cancelText: "Cancel",
            confirmText: "Submit",
            onCancel: () => Get.back(),
            onConfirm: (selectedUserId ?? 0) > 0 && remarkController.text.trim().isNotEmpty
                ? () {
                    Get.back();
                    _showCorrectionConfirmationPopup(failure, selectedUserName, selectedUserId ?? 0, remarkController.text.trim());
                  }
                : null,
            customContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: "Select User", size: AppConstants.formLabelSize),
                const SizedBox(height: 8),
                CustDropdown(
                  label: "User",
                  hint: "Select User",
                  items: filteredUsers.map((e) => e.userName ?? '').toList(),
                  selectedValue: selectedUserName,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedUserName = val;
                        selectedUserId = filteredUsers.firstWhere(
                          (u) => u.userName == val,
                          orElse: () => StaffItem(),
                        ).userId;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                CustText(name: "Remark", size: AppConstants.formLabelSize),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: remarkController,
                  hintText: "Enter remark...",
                  maxLines: 3,
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCorrectionConfirmationPopup(FailureItem failure, String? selectedUserName, int selectedUserId, String description) {
    Get.dialog(
      CustPopup(
        title: "Send For Correction",
        message: "Are you sure you want to send this failure for correction to $selectedUserName?",
        icon: TablerIcons.alert_triangle,
        iconColor: AppColors.orangeColor,
        cancelText: "Cancel",
        confirmText: "Submit",
        onCancel: () => Get.back(),
        onConfirm: () async {
          Get.back();
          await _handleSendForCorrection(failure, selectedUserId, description);
        },
      ),
    );
  }

  Future<void> _handleSendForCorrection(FailureItem failure, int selectedUserId, String description) async {
    final notificationId = failure.id;

    if (notificationId == null || notificationId == 0) {
      if (mounted) {
        appSnackbarMessage("Invalid Notification ID");
      }
      return;
    }

    try {
      final success = await _failureService.sendForCorrection(
        notificationId: notificationId,
        assignedUserId: selectedUserId,
        description: description,
      );

      if (mounted) {
        if (success) {
          appSnackbarMessage("Send for correction successful");
          controller.fetchFailures();
        } else {
          appSnackbarMessage("Operation failed");
        }
      }
    } catch (e) {
      if (mounted) {
        appSnackbarMessage("Error: $e");
      }
    }
  }

  void _showRejectPopup(FailureItem failure) {
    // First show remark popup
    _showRejectRemarkPopup(failure);
  }

  void _showRejectRemarkPopup(FailureItem failure) {
    final TextEditingController remarkController = TextEditingController();

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return CustPopup(
            title: "Reject For Duplicate",
            message: "Please provide a reason for rejection",
            icon: TablerIcons.alert_circle,
            iconColor: AppColors.orangeColor,
            cancelText: "Cancel",
            confirmText: "Reject",
            onCancel: () => Get.back(),
            onConfirm: remarkController.text.trim().isNotEmpty
                ? () {
                    Get.back();
                    _showRejectConfirmationPopup(failure, remarkController.text.trim());
                  }
                : null,
            customContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: "Remark", size: AppConstants.formLabelSize),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: remarkController,
                  hintText: "Enter remark...",
                  maxLines: 3,
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRejectConfirmationPopup(FailureItem failure, String description) {
    Get.dialog(
      CustPopup(
        title: "Reject For Duplicate",
        message: "Are you sure you want to reject this failure as duplicate?",
        icon: TablerIcons.alert_circle,
        iconColor: AppColors.orangeColor,
        cancelText: "Cancel",
        confirmText: "Reject",
        onCancel: () => Get.back(),
        onConfirm: () async {
          Get.back();
          await _handleReject(failure, description);
        },
      ),
    );
  }

  Future<void> _handleReject(FailureItem failure, String description) async {
    final notificationId = failure.id;

    if (notificationId == null || notificationId == 0) {
      if (mounted) {
        appSnackbarMessage("Invalid Notification ID");
      }
      return;
    }

    try {
      final success = await _failureService.rejectNotification(
        notificationId: notificationId,
        description: description,
      );

      if (mounted) {
        if (success) {
          appSnackbarMessage("Reject successful");
          controller.fetchFailures();
        } else {
          appSnackbarMessage("Operation failed");
        }
      }
    } catch (e) {
      if (mounted) {
        appSnackbarMessage("Error: $e");
      }
    }
  }

  void _showDeletePopup(FailureItem failure) {
    // First show remark popup
    _showDeleteRemarkPopup(failure);
  }

  void _showDeleteRemarkPopup(FailureItem failure) {
    final TextEditingController remarkController = TextEditingController();

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return CustPopup(
            title: "Delete Notification",
            message: "Please provide a reason for deletion",
            icon: Icons.delete,
            iconColor: AppColors.red,
            cancelText: "Cancel",
            confirmText: "Delete",
            onCancel: () => Get.back(),
            onConfirm: remarkController.text.trim().isNotEmpty
                ? () {
                    Get.back();
                    _showDeleteConfirmationPopup(failure, remarkController.text.trim());
                  }
                : null,
            customContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: "Remark", size: AppConstants.formLabelSize),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: remarkController,
                  hintText: "Enter remark...",
                  maxLines: 3,
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationPopup(FailureItem failure, String description) {
    Get.dialog(
      CustPopup(
        title: "Delete Notification",
        message: "Are you sure you want to delete this failure? This action cannot be undone.",
        icon: Icons.delete,
        iconColor: AppColors.red,
        cancelText: "Cancel",
        confirmText: "Delete",
        onCancel: () => Get.back(),
        onConfirm: () async {
          Get.back();
          await _handleDelete(failure, description);
        },
      ),
    );
  }

  Future<void> _handleDelete(FailureItem failure, String description) async {
    final notificationId = failure.id;

    if (notificationId == null || notificationId == 0) {
      if (mounted) {
        appSnackbarMessage("Invalid Notification ID");
      }
      return;
    }

    try {
      final success = await _failureService.deleteNotification(
        notificationId: notificationId,
        description: description,
      );

      if (mounted) {
        if (success) {
          appSnackbarMessage("Delete successful");
          controller.fetchFailures();
        } else {
          appSnackbarMessage("Operation failed");
        }
      }
    } catch (e) {
      if (mounted) {
        appSnackbarMessage("Error: $e");
      }
    }
  }
}
