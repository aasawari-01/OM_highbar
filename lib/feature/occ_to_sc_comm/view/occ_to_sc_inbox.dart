import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';

import 'package:om_mobile/constants/colors.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import 'instruction_details.dart';


class OccScInboxScreen extends StatelessWidget {
  const OccScInboxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> instructions = [
      {
        'id': 'OCC-INS-2026-00124',
        'instructionType': 'Technical',
        'sentBy': 'OCC',
        'date': '27 Aug 2026',
        'time': '10:35 AM',
        'lines': ['Line 1'],
        'stations': [
          'Khapari',
          'New Airport',
        ],
        'subject': 'AFC Equipment Inspection',
        'description':
        'Please inspect the AFC equipment and confirm the current operating status.',
        'acknowledgementCount': 2,
        'status': 'Acknowledged',
      },
      {
        'id': 'OCC-INS-2026-00123',
        'instructionType': 'General',
        'sentBy': 'OCC',
        'date': '27 Aug 2026',
        'time': '09:15 AM',
        'lines': ['Line 1', 'Line 2'],
        'stations': [
          'Sitaburdi Interchange Station',
          'Lokmanya Nagar',
        ],
        'subject': 'Station Readiness Confirmation',
        'description':
        'Confirm station readiness for the upcoming operational activity.',
        'acknowledgementCount': 1,
        'status': 'Partially Acknowledged',
      },
      {
        'id': 'OCC-INS-2026-00122',
        'instructionType': 'Emergency',
        'sentBy': 'OCC',
        'date': '26 Aug 2026',
        'time': '06:42 PM',
        'lines': ['Line 2'],
        'stations': [
          'Prajapati Nagar',
        ],
        'subject': 'Emergency Response Instruction',
        'description':
        'Immediate action required at the concerned station.',
        'acknowledgementCount': 3,
        'status': 'Acknowledged',
      },
      {
        'id': 'OCC-INS-2026-00121',
        'instructionType': 'Technical',
        'sentBy': 'OCC',
        'date': '26 Aug 2026',
        'time': '03:20 PM',
        'lines': ['Line 1'],
        'stations': [
          'Nagpur Airport',
        ],
        'subject': 'Communication System Check',
        'description':
        'Verify the communication system and share the inspection remarks.',
        'acknowledgementCount': 0,
        'status': 'Pending',
      },
    ];

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
          color: AppColors.white1,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.screenPadding,
                  4,
                  AppConstants.screenPadding,
                  24,
                ),
                itemCount: instructions.length,
                itemBuilder: (context, index) {
                  final item = instructions[index];

                  return _buildInstructionCard(
                    context,
                    item,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPadding,
        18,
        AppConstants.screenPadding,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(
                  name: 'Instructions',
                  size: 20,
                  color: Colors.black87,

                ),
                const SizedBox(height: 4),
                CustText(
                  name: 'Instructions received from OCC',
                  size: 12,
                  color: AppColors.textMutedLight,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.appBarColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(
                  TablerIcons.inbox,
                  size: 16,
                  color: AppColors.textMutedLight,
                ),
                SizedBox(width: 6),
                Text(
                  '4',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard(
      BuildContext context,
      Map<String, dynamic> item,
      ) {
    final String status = item['status'] ?? '';
    final String instructionType =
        item['instructionType'] ?? '';

    return GestureDetector(
      onTap: () {
        Get.to(
              () => InstructionDetailsScreen(
            instruction: item,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------
            // Top row
            // -------------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeIcon(instructionType),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      CustText(
                        name: item['subject'] ?? '',
                        size: 15,
                        color: Colors.black87,

                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      CustText(
                        name: item['id'] ?? '',
                        size: 11,
                        color: AppColors.textMutedLight,
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),

            const SizedBox(height: 13),

            // -------------------------------------------------------
            // Description
            // -------------------------------------------------------
            Text(
              item['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 14),

            // -------------------------------------------------------
            // Line + station
            // -------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: TablerIcons.route,
                    title: 'Line',
                    value:
                    (item['lines'] as List)
                        .join(', '),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoItem(
                    icon: TablerIcons.map_pin,
                    title: 'Station',
                    value:
                    (item['stations'] as List)
                        .join(', '),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            const Divider(
              height: 1,
            ),

            const SizedBox(height: 12),

            // -------------------------------------------------------
            // Footer
            // -------------------------------------------------------
            Row(
              children: [
                const Icon(
                  TablerIcons.clock,
                  size: 15,
                  color: AppColors.textMutedLight,
                ),
                const SizedBox(width: 5),
                Text(
                  '${item['date']} • ${item['time']}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                const Spacer(),
                const Icon(
                  TablerIcons.users,
                  size: 15,
                  color: AppColors.textMutedLight,
                ),
                const SizedBox(width: 5),
                Text(
                  '${item['acknowledgementCount']} Acknowledgements',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 7),
                const Icon(
                  TablerIcons.chevron_right,
                  size: 18,
                  color: Colors.black38,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color background;
    Color iconColor;

    switch (type) {
      case 'Emergency':
        icon = TablerIcons.alert_triangle;
        background = Colors.red.withOpacity(0.10);
        iconColor = Colors.red;
        break;

      case 'Technical':
        icon = TablerIcons.settings;
        background = Colors.orange.withOpacity(0.10);
        iconColor = Colors.orange.shade800;
        break;

      default:
        icon = TablerIcons.file_text;
        background = Colors.blue.withOpacity(0.10);
        iconColor = Colors.blue;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 20,
        color: iconColor,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;

    switch (status) {
      case 'Acknowledged':
        chipColor = Colors.green.withOpacity(0.10);
        textColor = Colors.green.shade700;
        break;

      case 'Partially Acknowledged':
        chipColor = Colors.orange.withOpacity(0.10);
        textColor = Colors.orange.shade800;
        break;

      default:
        chipColor = Colors.grey.withOpacity(0.12);
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: AppColors.textMutedLight,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}