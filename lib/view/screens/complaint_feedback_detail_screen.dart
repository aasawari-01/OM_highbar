import 'package:flutter/material.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/file_upload_section.dart';
import 'utils/size_config.dart';

class ComplaintFeedbackDetailScreen extends StatefulWidget {
  const ComplaintFeedbackDetailScreen({Key? key}) : super(key: key);

  @override
  State<ComplaintFeedbackDetailScreen> createState() => _ComplaintFeedbackDetailScreenState();
}

class _ComplaintFeedbackDetailScreenState extends State<ComplaintFeedbackDetailScreen> {
  bool complaintDetailsExpanded = true;
  bool complainantDetailsExpanded = false;
  bool remarkExpanded = false;
  bool attachmentsExpanded = false;

  // Dummy data
  final Map<String, String> complaint = const {
    'type': 'Complaint',
    'status': 'Open',
    'complaintNo': 'CMP/10-2024/0001',
    'createdOn': '17-10-2024 10:00',
    'category': 'Staff Complaints',
    'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam euismod, urna eu tincidunt consectetur, nisi nisl aliquam nunc, eget aliquam massa nisi eu velit.',
    'complainantName': 'John Doe',
    'complainantMobile': '9876543210',
    'complainantEmail': 'john.doe@email.com',
    'complainantCategory': 'Category X',
    'complainantLocation': 'Location 1',
    'source': 'Email',
    'userAssign': 'User 1',
    'stationRemark': 'Handled by station controller.',
  };
  final List<String> attachments = const [
    'Document1.pdf',
    'Screenshot.png',
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
        title: complaint['complaintNo'] ?? 'Complaint Detail',
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
                                    name: 'Complaint No:',
                                    size: 1.4,
                                    color: AppColors.textColor4,
                                  ),
                                  CustText(
                                    name: complaint['complaintNo'] ?? '',
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
                                    name: complaint['createdOn'] ?? '',
                                    size: 1.6,
                                    fontWeightName: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 1 * SizeConfig.heightMultiplier),
                          CustText(
                            name: 'Category:',
                            size: 1.4,
                            color: AppColors.textColor4,
                          ),
                          CustText(
                            name: complaint['category'] ?? '',
                            size: 1.6,
                            fontWeightName: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          SizedBox(height: 1 * SizeConfig.heightMultiplier),
                          Row(
                            children: [
                              CustText(
                                name: 'Type:',
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
                                  name: complaint['type'] ?? '',
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
                                  color: _statusColor(complaint['status'] ?? '').withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: CustText(
                                  name: complaint['status'] ?? '',
                                  size: 1.4,
                                  color: _statusColor(complaint['status'] ?? ''),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1 * SizeConfig.heightMultiplier),
                    // Complaint Details Accordion
                    AccordionCard(
                      isExpanded: true,
                      title: 'Complaint Details',
                      expanded: complaintDetailsExpanded,
                      onTap: () {
                        setState(() {
                          complaintDetailsExpanded = !complaintDetailsExpanded;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustText(
                            name: 'Complaint Type',
                            size: 1.4,
                            color: AppColors.textColor4,
                          ),
                          CustText(
                            name: complaint['type'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w500,
                          ),
                          SizedBox(height: 8),
                          CustText(
                            name: 'Complaint Category',
                            size: 1.4,
                            color: AppColors.textColor4,
                          ),
                          CustText(
                            name: complaint['category'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w500,
                          ),
                          SizedBox(height: 8),
                          CustText(
                            name: 'Incident Location',
                            size: 1.4,
                            color: AppColors.textColor4,
                          ),
                          CustText(
                            name: 'Location 1',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w500,
                          ),
                          SizedBox(height: 8),
                          CustText(
                            name: 'Description',
                            size: 1.4,
                            color: AppColors.textColor4,
                          ),
                          CustText(
                            name: complaint['description'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    // Complainant Details Accordion
                    AccordionCard(
                      isExpanded: true,
                      title: 'Complainant Details',
                      expanded: complainantDetailsExpanded,
                      onTap: () {
                        setState(() {
                          complainantDetailsExpanded = !complainantDetailsExpanded;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustText(
                            name: 'Complainant Name',
                            size: 1.4,
                            color: AppColors.textColor4,
                            textAlign: TextAlign.left,
                          ),
                          CustText(
                            name: complaint['complainantName'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w500,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(height: 8),
                          CustText(
                            name: 'Complainant Mobile Number',
                            size: 1.4,
                            color: AppColors.textColor4,
                            textAlign: TextAlign.left,
                          ),
                          CustText(
                            name: complaint['complainantMobile'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w500,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(height: 8),
                          CustText(
                            name: 'Complainant Email Address',
                            size: 1.4,
                            color: AppColors.textColor4,
                            textAlign: TextAlign.left,
                          ),
                          CustText(
                            name: complaint['complainantEmail'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w500,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(height: 8),
                          CustText(
                            name: 'Complaint Category',
                            size: 1.4,
                            color: AppColors.textColor4,
                            textAlign: TextAlign.left,
                          ),
                          CustText(
                            name: complaint['complainantCategory'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w500,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(height: 8),
                          CustText(
                            name: 'Incident Location',
                            size: 1.4,
                            color: AppColors.textColor4,
                            textAlign: TextAlign.left,
                          ),
                          CustText(
                            name: complaint['complainantLocation'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w500,
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    // Remark Accordion
                    AccordionCard(
                      isExpanded: true,
                      title: 'Remark',
                      expanded: remarkExpanded,
                      onTap: () {
                        setState(() {
                          remarkExpanded = !remarkExpanded;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustText(
                            name: 'Source',
                            size: 1.4,
                            color: AppColors.textColor4,
                            textAlign: TextAlign.left,
                          ),
                          CustText(
                            name: complaint['source'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w500,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(height: 8),
                          CustText(
                            name: 'User Assign',
                            size: 1.4,
                            color: AppColors.textColor4,
                            textAlign: TextAlign.left,
                          ),
                          CustText(
                            name: complaint['userAssign'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w500,
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(height: 8),
                          CustText(
                            name: 'Station Controller Remark',
                            size: 1.4,
                            color: AppColors.textColor4,
                            textAlign: TextAlign.left,
                          ),
                          CustText(
                            name: complaint['stationRemark'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w500,
                            textAlign: TextAlign.left,
                          ),
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