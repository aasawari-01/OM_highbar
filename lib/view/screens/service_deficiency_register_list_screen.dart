import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';

class ServiceDeficiencyRegisterListScreen extends StatelessWidget {
  const ServiceDeficiencyRegisterListScreen({Key? key}) : super(key: key);

  // Dummy data for demonstration
  final List<Map<String, String>> deficiencyList = const [
    // Example entry
    // {
    //   'station': 'Khapri',
    //   'dateTime': '08/02/2025 14:00',
    //   'staffName': 'Amit Kumar',
    //   'description': 'Late cleaning',
    //   'status': 'Open',
    //   'shift': 'Morning',
    //   'penaltyClause': 'Man',
    //   'proposedBy': 'Supervisor',
    // },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: 'Service Deficiency Register List',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textColor4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  // TODO: Implement clear all logic
                },
                child: const Text('Clear All', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textColor4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Back', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: deficiencyList.isEmpty
          ? Center(
              child: CustText(
                name: 'No data available in table',
                size: 1.6,
                color: AppColors.textColor4,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: deficiencyList.length,
              itemBuilder: (context, index) {
                final item = deficiencyList[index];
                return Container(
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
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustText(name: 'Station:', size: 1.3, color: AppColors.textColor4),
                              CustText(
                                name: item['station'] ?? '',
                                size: 1.4,
                                color: AppColors.black,
                                fontWeightName: FontWeight.w600,
                              ),
                              const SizedBox(height: 4),
                              CustText(name: 'Date & Time:', size: 1.3, color: AppColors.textColor4),
                              CustText(
                                name: item['dateTime'] ?? '',
                                size: 1.4,
                                color: AppColors.black,
                                fontWeightName: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustText(name: 'Name of Staff:', size: 1.3, color: AppColors.textColor4),
                              CustText(
                                name: item['staffName'] ?? '',
                                size: 1.4,
                                color: AppColors.black,
                                fontWeightName: FontWeight.w600,
                              ),
                              const SizedBox(height: 4),
                              CustText(name: 'Description of Service Deficiencies:', size: 1.3, color: AppColors.textColor4),
                              CustText(
                                name: item['description'] ?? '',
                                size: 1.4,
                                color: AppColors.black,
                                fontWeightName: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustText(name: 'Status:', size: 1.3, color: AppColors.textColor4),
                              CustText(
                                name: item['status'] ?? '',
                                size: 1.4,
                                color: AppColors.black,
                                fontWeightName: FontWeight.w600,
                              ),
                              const SizedBox(height: 4),
                              CustText(name: 'Shift:', size: 1.3, color: AppColors.textColor4),
                              CustText(
                                name: item['shift'] ?? '',
                                size: 1.4,
                                color: AppColors.black,
                                fontWeightName: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustText(name: 'Penalty Clause:', size: 1.3, color: AppColors.textColor4),
                              CustText(
                                name: item['penaltyClause'] ?? '',
                                size: 1.4,
                                color: AppColors.black,
                                fontWeightName: FontWeight.w600,
                              ),
                              const SizedBox(height: 4),
                              CustText(name: 'Deficiency Proposed By:', size: 1.3, color: AppColors.textColor4),
                              CustText(
                                name: item['proposedBy'] ?? '',
                                size: 1.4,
                                color: AppColors.black,
                                fontWeightName: FontWeight.w600,
                              ),
                              const SizedBox(height: 4),
                              CustText(name: 'Action:', size: 1.3, color: AppColors.textColor4),
                              Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gradientStart,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    ),
                                    onPressed: () {},
                                    child: const Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.textColor4,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    ),
                                    onPressed: () {},
                                    child: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 