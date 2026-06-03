import 'package:flutter/material.dart';

import '../../../constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/responsive_helper.dart';
import '../../../utils/widgets/accordion_card.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/custom_app_bar.dart';


class InspectionDetailScreen extends StatefulWidget {
  const InspectionDetailScreen({Key? key}) : super(key: key);

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  bool inspectionDetailsExpanded = true;
  bool attachmentsExpanded = false;

  // Dummy data
  final Map<String, String> inspection = const {
    'inspectionType': 'Daily',
    'plan': 'Scheduled',
    'department': 'Department A',
    'scheduledDate': '18-10-2024',
    'status': 'Open',
    'createdOn': '17-10-2024 10:00',
    'frequency': 'Monthly',
    'designation': 'Account Holder',
    'inspectionBy': 'User 1',
  };
  final List<String> attachments = const [
    'InspectionReport.pdf',
    'Photo1.png',
  ];

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.orangeColor;
      case 'closed':
        return AppColors.green;
      case 'pending':
        return AppColors.red;
      default:
        return AppColors.textColor4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: inspection['inspectionType'] ?? 'Inspection Detail',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Summary Section
                    Container(
                      margin: const EdgeInsets.only(bottom: AppConstants.sectionSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustText.detailLabel('Type:'),
                                  CustText.detailValue(inspection['inspectionType'] ?? ''),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustText.detailLabel('Created On:'),
                                  CustText.detailValue(inspection['createdOn'] ?? ''),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          Row(
                            children: [
                              CustText.detailLabel('Plan:'),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.textColor3.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: CustText(
                                  name: inspection['plan'] ?? '',
                                  size: AppConstants.detailValueSize,
                                  color: AppColors.textColor3,
                                  fontWeightName: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              CustText.detailLabel('Status:'),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(inspection['status'] ?? '').withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: CustText(
                                  name: inspection['status'] ?? '',
                                  size: AppConstants.detailValueSize,
                                  color: _statusColor(inspection['status'] ?? ''),
                                  fontWeightName: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          CustText.detailLabel('Department:'),
                          CustText.detailValue(inspection['department'] ?? ''),
                          const SizedBox(height: AppConstants.elementSpacing),
                          Row(
                            children: [
                              CustText.detailLabel('Scheduled Date:'),
                              const SizedBox(width: 8),
                              CustText.detailValue(inspection['scheduledDate'] ?? ''),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.elementSpacing),
                    // Inspection Details Accordion
                    AccordionCard(
                      isExpanded: true,
                      title: 'Inspection Details',
                      expanded: inspectionDetailsExpanded,
                      onTap: () {
                        setState(() {
                          inspectionDetailsExpanded = !inspectionDetailsExpanded;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('Frequency', inspection['frequency'] ?? ''),
                          _detailRow('Designation', inspection['designation'] ?? ''),
                          _detailRow('Inspection By', inspection['inspectionBy'] ?? ''),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.elementSpacing),
                    // Attachments Accordion
                    AccordionCard(
                      isExpanded: true,
                      title: 'Attachments',
                      expanded: attachmentsExpanded,
                      onTap: () {
                        setState(() {
                          attachmentsExpanded = !attachmentsExpanded;
                        });
                      },
                      child: attachments.isEmpty
                        ? CustText(name: 'No attachments', size: 14, color: AppColors.textColor4)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustText(
                                name: '${attachments.length} File${attachments.length > 1 ? 's' : ''}',
                                size: 16,
                                color: AppColors.textColor,
                                fontWeightName: FontWeight.w500,
                              ),
                              const SizedBox(height: 8),
                              ...attachments.map((file) => _fileRow(file, '62.33 kB')).toList(),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText.detailLabel('$label:'),
          const SizedBox(width: 8),
          Expanded(
            child: CustText.detailValue(value),
          ),
        ],
      ),
    );
  }

  Widget _fileRow(String filename, String size) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.dividerColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Container(
            height: ResponsiveHelper.height(context, 20),
            width:  ResponsiveHelper.height(context, 20),
            decoration: BoxDecoration(color: AppColors.containerColor,borderRadius: BorderRadius.circular(5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: filename, size: 17,color: AppColors.black,),
                CustText(name: size, size: 14,color: Colors.black,),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey), // Remove icon
            onPressed: () {
              // TODO: Implement remove file logic
            },
          ),
        ],
      ),
    );
  }
} 