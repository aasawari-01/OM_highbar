import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'complaint_feedback_detail_screen.dart';
import 'complaint_feedback_screen.dart';

class ComplaintFeedbackListScreen extends StatelessWidget {
  const ComplaintFeedbackListScreen({Key? key}) : super(key: key);

  // Dummy data for demonstration
  final List<Map<String, String>> complaints = const [
    {
      'type': 'Complaint',
      'status': 'Open',
      'complaintNo': 'CMP/10-2024/0001',
      'createdOn': '17-10-2024 10:00',
      'category': 'Staff Complaints',
    },
    {
      'type': 'Feedback',
      'status': 'Closed',
      'complaintNo': 'FDB/10-2024/0002',
      'createdOn': '16-10-2024 09:30',
      'category': 'Suggestions',
    },
    {
      'type': 'Complaint',
      'status': 'Pending',
      'complaintNo': 'CMP/10-2024/0003',
      'createdOn': '15-10-2024 14:20',
      'category': 'Security/Safety',
    },
    {
      'type': 'Feedback',
      'status': 'Open',
      'complaintNo': 'FDB/10-2024/0004',
      'createdOn': '14-10-2024 11:45',
      'category': 'Appreciation',
    },
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
        title: 'Complaint & Feedback List',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.search, color: Colors.white),
          //   onPressed: () {},
          // ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: complaints.length,
        itemBuilder: (context, index) {
          final complaint = complaints[index];
          return GestureDetector(
            onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ComplaintFeedbackDetailScreen()),
          ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white1,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustText(name: 'Type:', size: 1.3, color: AppColors.textColor4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.textColor3.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CustText(
                              name: complaint['type'] ?? '',
                              size: 1.3,
                              color: AppColors.textColor3,
                            ),
                          ),
                          SizedBox(height: 4),
                          CustText(name: 'Complaint No:', size: 1.3, color: AppColors.textColor4),
                          CustText(
                            name: complaint['complaintNo'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w600,
                          ),
                          SizedBox(height: 4),
                          CustText(name: 'Category:', size: 1.3, color: AppColors.textColor4),
                          CustText(
                            name: complaint['category'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustText(name: 'Status:', size: 1.3, color: AppColors.textColor4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor(complaint['status'] ?? '').withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CustText(
                              name: complaint['status'] ?? '',
                              size: 1.3,
                              color: _statusColor(complaint['status'] ?? ''),
                            ),
                          ),
                          SizedBox(height: 4),
                          CustText(name: 'Created On:', size: 1.3, color: AppColors.textColor4),
                          CustText(
                            name: complaint['createdOn'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientStart.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ComplaintFeedbackScreen()),
            );
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
