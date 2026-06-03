import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import 'package:get/get.dart';
import '../../../service/session_controller.dart';
import 'inspection_detail_screen.dart';
import 'inspection_screen.dart';
import 'common_inspection_checklist_screen.dart';

class InspectionListScreen extends StatelessWidget {
  const InspectionListScreen({super.key});

  static const List<Map<String, String>> _inspections = [
    {
      'inspectionNo': 'SIG/10-2024/0024',
      'inspectionType': 'Scheduled',
      'inspectionDate': '17-10-2024',
      'reassignTo': 'Dharmesh Solanki',
      'action': 'Active',
      'status': 'Reassign',
    },
    {
      'inspectionNo': 'SIG/10-2024/0023',
      'inspectionType': 'Unscheduled',
      'inspectionDate': '16-10-2024',
      'reassignTo': 'Rahul Mehta',
      'action': 'Active',
      'status': 'Reassign',
    },
    {
      'inspectionNo': 'SIG/10-2024/0022',
      'inspectionType': 'Scheduled',
      'inspectionDate': '15-10-2024',
      'reassignTo': 'Priya Shah',
      'action': 'Active',
      'status': 'Open',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'Inspection',
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
          _buildProfileAction(),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          itemCount: _inspections.length,
          itemBuilder: (context, index) => _InspectionCard(
            data: _inspections[index],
            onTap: () {
              final roleName = Get.find<SessionController>().selectedRole.value?.roleDescr ?? '';
              if (roleName.toLowerCase() == 'junior engineer') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InspectionScreen(isJEInspectionView: true)),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InspectionDetailScreen()),
                );
              }
            },
            onFillChecklist: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CommonInspectionChecklistScreen()),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orangeColor,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InspectionScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileAction() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.white1,
        ),
        Positioned(
          right: 0,
          bottom: 2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white1, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _InspectionCard extends StatelessWidget {
  final Map<String, String> data;
  final VoidCallback onFillChecklist;
  final VoidCallback onTap;

  const _InspectionCard({
    required this.data,
    required this.onFillChecklist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              children: [
                Expanded(child: _badgeRow('Action:', data['action'] ?? '', _actionColor(data['action']))),
                const SizedBox(width: AppConstants.elementSpacing),
                Expanded(child: _badgeRow('Status:', data['status'] ?? '', _statusColor(data['status']))),
              ],
            ),
            const SizedBox(height: AppConstants.subElementSpacing),
            const Divider(color: AppColors.dividerColor3, height: 1),
            const SizedBox(height: AppConstants.subElementSpacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _labelValue('Inspection No:', data['inspectionNo'] ?? ''),
                      const SizedBox(height: AppConstants.elementSpacing),
                      _labelValue('Inspection Type:', data['inspectionType'] ?? ''),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _labelValue('Inspection Date:', data['inspectionDate'] ?? ''),
                      const SizedBox(height: AppConstants.elementSpacing),
                      _labelValue('Reassign To:', data['reassignTo'] ?? ''),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.elementSpacing),
            Align(
              alignment: Alignment.centerLeft,
              child: CustButton(
                name: 'Fill Checklist',
                size: 120,
                sHeight: 30,
                borderRadius: AppConstants.inputRadius,
                onSelected: (_) => onFillChecklist(),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _badgeRow(String label, String value, Color color) {
    return Row(
      children: [
        CustText(name: label, size: AppConstants.detailLabelSize, color: AppColors.textColor4),
        const SizedBox(width: 6),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustText(
              name: value,
              size: AppConstants.detailValueSize,
              color: color,
              fontWeightName: FontWeight.w600,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText.detailLabel(label),
        const SizedBox(height: AppConstants.labelSpacing),
        CustText.detailValue(value),
      ],
    );
  }

  Color _actionColor(String? action) {
    if (action?.toLowerCase() == 'active') return AppColors.orangeColor;
    return AppColors.textColor4;
  }

  Color _statusColor(String? status) {
    if (status?.toLowerCase() == 'reassign') return AppColors.red;
    if (status?.toLowerCase() == 'open') return AppColors.orangeColor;
    return AppColors.textColor4;
  }
}
