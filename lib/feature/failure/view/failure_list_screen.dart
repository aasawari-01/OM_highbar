import 'package:flutter/material.dart';
import '../../../constants/colors.dart';

import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../../../constants/app_constants.dart';
import 'create_failure_screen.dart';
import 'view_detail_screen.dart';

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

class _FailureListScreenState extends State<FailureListScreen> {
  late final FailureListController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FailureListController(), tag: widget.failureType);
    controller.setFailureType(widget.failureType);
    controller.fetchFailures();
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
        child: Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
          child: controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : controller.errorMessage.isNotEmpty
                  ? Center(child: CustText(name: controller.errorMessage.value, size: 14))
                  : controller.failures.isEmpty
                      ? const Center(
                          child: Text(
                            'No failures found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
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
        )),
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


  Widget _buildFailureCard(FailureItem failure) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateFailureScreen(failureNo: failure.failureNo,notificationCode:failure.notificationCode, failureType: widget.failureType)),
      ),
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
                      _priorityChip('High'), // Defaulting to High as priority is not in API
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
}
