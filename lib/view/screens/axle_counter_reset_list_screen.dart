import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/custom_bottom_sheet.dart';

import 'axle_counter_reset_form.dart';

class AxleCounterResetListScreen extends StatelessWidget {
  const AxleCounterResetListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    const axleCounterList = [
      {
        'axleCounterNo': 'ACR001',
        'station': 'Khapri',
        'dateTime': '08/02/2025 14:00',
        'sddNo': 'SDD12',
        'location': 'Platform 1',
        'counterAfterReset': '100',
        'scEmployeeNo': 'SC123',
        'occPvtNo': '12',
        'stationPvtNo': '1234567890',
        'purpose': 'Routine check',
      },
      {
        'axleCounterNo': 'ACR002',
        'station': 'Airport',
        'dateTime': '09/02/2025 10:30',
        'sddNo': 'SDD15',
        'location': 'Platform 2',
        'counterAfterReset': '200',
        'scEmployeeNo': 'SC456',
        'occPvtNo': '15',
        'stationPvtNo': '9876543210',
        'purpose': 'Maintenance',
      },
      {
        'axleCounterNo': 'ACR003',
        'station': 'Zero Mile',
        'dateTime': '10/02/2025 09:00',
        'sddNo': 'SDD18',
        'location': 'Platform 3',
        'counterAfterReset': '150',
        'scEmployeeNo': 'SC789',
        'occPvtNo': '18',
        'stationPvtNo': '1122334455',
        'purpose': 'Emergency reset',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: 'Axle Counter Reset Register List',
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
            ],
          ),
        ],
      ),
      body: axleCounterList.isEmpty
          ? Center(
              child: CustText(
                name: 'No data available in table',
                size: 1.6,
                color: AppColors.textColor4,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: axleCounterList.length,
              itemBuilder: (context, index) {
                final item = axleCounterList[index];
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
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustText(name: 'Axle Counter No:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['axleCounterNo'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
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
                                  const SizedBox(height: 4),
                                  CustText(name: 'SDD No:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['sddNo'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Location:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['location'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Counter No. After Reset:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['counterAfterReset'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustText(name: 'SC Employee No:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['scEmployeeNo'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'OCC PVT No:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['occPvtNo'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Station PVT No:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['stationPvtNo'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Purpose:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['purpose'] ?? '',
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
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.more_vert, color: AppColors.textColor4),
                          onPressed: () {
                            CustomBottomSheet.show(
                              context: context,
                              title: "Axle Counter No : ${item['axleCounterNo'] ?? ''}",
                              options: [
                                CustomBottomSheetOption(
                                  title: 'Edit',
                                  icon: Icons.edit,
                                  iconColor: AppColors.gradientEnd,
                                  onTap: () {
                                    // TODO: Implement edit logic
                                  },
                                ),
                                CustomBottomSheetOption(
                                  title: 'Delete',
                                  icon: Icons.delete,
                                  iconColor: Colors.red,
                                  onTap: () {
                                    // TODO: Implement delete logic
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
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
              MaterialPageRoute(builder: (context) => const AxleCounterResetForm()),
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