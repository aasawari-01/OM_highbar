import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'inspection_detail_screen.dart';
import 'inspection_screen.dart';

class InspectionListScreen extends StatelessWidget {
  const InspectionListScreen({Key? key}) : super(key: key);

  // Dummy data for demonstration
  final List<Map<String, String>> inspections = const [
    {
      'inspectionType': 'Daily',
      'plan': 'Scheduled',
      'department': 'Department A',
      'scheduledDate': '18-10-2024',
      'status': 'Open',
      'createdOn': '17-10-2024 10:00',
    },
    {
      'inspectionType': 'Weekly',
      'plan': 'Unscheduled',
      'department': 'Department B',
      'scheduledDate': '16-10-2024',
      'status': 'Closed',
      'createdOn': '16-10-2024 09:30',
    },
    {
      'inspectionType': 'Monthly',
      'plan': 'Scheduled',
      'department': 'Department C',
      'scheduledDate': '15-10-2024',
      'status': 'Pending',
      'createdOn': '15-10-2024 14:20',
    },
    {
      'inspectionType': 'Yearly',
      'plan': 'Scheduled',
      'department': 'Department A',
      'scheduledDate': '14-10-2024',
      'status': 'Open',
      'createdOn': '14-10-2024 11:45',
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
        title: 'Inspection List',
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
        itemCount: inspections.length,
        itemBuilder: (context, index) {
          final inspection = inspections[index];
          return GestureDetector(
            onTap: () =>  Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InspectionDetailScreen()),
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
                  children: [
                    // First column: Type, Plan, Scheduled Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustText(name: 'Type:', size: 1.3, color: AppColors.textColor4),
                          CustText(
                            name: inspection['inspectionType'] ?? '',
                            size: 1.4,
                            color: AppColors.textColor3,
                            fontWeightName: FontWeight.w600,
                          ),
                          SizedBox(height: 4),
                          CustText(name: 'Plan:', size: 1.3, color: AppColors.textColor4),
                          CustText(
                            name: inspection['plan'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w600,
                          ),
                          SizedBox(height: 4),
                          CustText(name: 'Scheduled Date:', size: 1.3, color: AppColors.textColor4),
                          CustText(
                            name: inspection['scheduledDate'] ?? '',
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
                              color: _statusColor(inspection['status'] ?? '').withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CustText(
                              name: inspection['status'] ?? '',
                              size: 1.3,
                              color: _statusColor(inspection['status'] ?? ''),
                            ),
                          ),
                          SizedBox(height: 4),
                          CustText(name: 'Department:', size: 1.3, color: AppColors.textColor4),
                          CustText(
                            name: inspection['department'] ?? '',
                            size: 1.4,
                            color: AppColors.black,
                            fontWeightName: FontWeight.w600,
                          ),
                          SizedBox(height: 4),
                          CustText(name: 'Created On:', size: 1.3, color: AppColors.textColor4),
                          CustText(
                            name: inspection['createdOn'] ?? '',
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
              MaterialPageRoute(builder: (context) => InspectionScreen()),
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