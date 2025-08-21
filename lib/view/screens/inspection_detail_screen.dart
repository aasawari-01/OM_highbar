import 'package:flutter/material.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'utils/size_config.dart';

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
        return AppColors.orange;
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Summary Section
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustText(
                                    name: 'Type:',
                                    size: 1.4,
                                    color: AppColors.textColor4,
                                  ),
                                  CustText(
                                    name: inspection['inspectionType'] ?? '',
                                    size: 1.6,
                                    fontWeightName: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustText(
                                    name: 'Created On:',
                                    size: 1.4,
                                    color: AppColors.textColor4,
                                  ),
                                  CustText(
                                    name: inspection['createdOn'] ?? '',
                                    size: 1.6,
                                    fontWeightName: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 1 * SizeConfig.heightMultiplier),
                          Row(
                            children: [
                              CustText(
                                name: 'Plan:',
                                size: 1.4,
                                color: AppColors.textColor4,
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.textColor3.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: CustText(
                                  name: inspection['plan'] ?? '',
                                  size: 1.4,
                                  color: AppColors.textColor3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CustText(
                                name: 'Status:',
                                size: 1.4,
                                color: AppColors.textColor4,
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _statusColor(inspection['status'] ?? '').withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: CustText(
                                  name: inspection['status'] ?? '',
                                  size: 1.4,
                                  color: _statusColor(inspection['status'] ?? ''),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 1 * SizeConfig.heightMultiplier),
                          CustText(
                            name: 'Department:',
                            size: 1.4,
                            color: AppColors.textColor4,
                          ),
                          CustText(
                            name: inspection['department'] ?? '',
                            size: 1.6,
                            fontWeightName: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          SizedBox(height: 1 * SizeConfig.heightMultiplier),
                          Row(
                            children: [
                              CustText(
                                name: 'Scheduled Date:',
                                size: 1.4,
                                color: AppColors.textColor4,
                              ),
                              const SizedBox(width: 4),
                              CustText(
                                name: inspection['scheduledDate'] ?? '',
                                size: 1.4,
                                color: AppColors.black,
                                fontWeightName: FontWeight.w500,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1 * SizeConfig.heightMultiplier),
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
                    SizedBox(height: 12),
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
                        ? CustText(name: 'No attachments', size: 1.4, color: AppColors.textColor4)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustText(
                                name: '${attachments.length} File${attachments.length > 1 ? 's' : ''}',
                                size: 1.6,
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
          CustText(
            name: '$label:',
            size: 1.4,
            color: AppColors.textColor4,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustText(
              name: value,
              size: 1.4,
              color: AppColors.black,
              fontWeightName: FontWeight.w500,
            ),
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
            height: 5 * SizeConfig.heightMultiplier,
            width:  5 * SizeConfig.heightMultiplier,
            decoration: BoxDecoration(color: AppColors.containerColor,borderRadius: BorderRadius.circular(5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: filename, size: 1.7,color: AppColors.black,),
                CustText(name: size, size: 1.4,color: Colors.black,),
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