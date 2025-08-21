import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/custom_bottom_sheet.dart';
import 'cash_check_details_register_form.dart';

class CashCheckDetailsRegisterListScreen extends StatelessWidget {
  const CashCheckDetailsRegisterListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    const cashCheckList = [
      {
        'station': 'Khapri',
        'dateTime': '08/02/2025 14:00',
        'inspectingAuthority': 'Mr. Sharma',
        'operatorName': 'Amit Kumar',
        'eosNo': 'EOS123',
        'amountEOS': '5000',
        'amountCheck': '4800',
        'difference': '200',
        'actionTaken': 'Verified',
        'remarks': 'All ok',
      },
      {
        'station': 'Airport',
        'dateTime': '09/02/2025 10:30',
        'inspectingAuthority': 'Ms. Singh',
        'operatorName': 'Priya Verma',
        'eosNo': 'EOS456',
        'amountEOS': '6000',
        'amountCheck': '5900',
        'difference': '100',
        'actionTaken': 'Shortfall',
        'remarks': 'Short by 100',
      },
      {
        'station': 'Zero Mile',
        'dateTime': '10/02/2025 09:00',
        'inspectingAuthority': 'Mr. Patel',
        'operatorName': 'Rahul Joshi',
        'eosNo': 'EOS789',
        'amountEOS': '7000',
        'amountCheck': '7000',
        'difference': '0',
        'actionTaken': 'Matched',
        'remarks': 'Perfect match',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: 'Cash Check Details Register List',
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
      body: cashCheckList.isEmpty
          ? Center(
              child: CustText(
                name: 'No data available in table',
                size: 1.6,
                color: AppColors.textColor4,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: cashCheckList.length,
              itemBuilder: (context, index) {
                final item = cashCheckList[index];
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
                                  CustText(name: 'Name of Inspecting Authority:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['inspectingAuthority'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Name of Operator:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['operatorName'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'EOS No.:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['eosNo'] ?? '',
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
                                  CustText(name: 'Amount as per EOS:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['amountEOS'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Amount as per Check:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['amountCheck'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Difference:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['difference'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Action Taken:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['actionTaken'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Remarks:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['remarks'] ?? '',
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
                              title: "Station : ${item['station'] ?? ''}",
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
                MaterialPageRoute(builder: (context) => CashCheckDetailsRegisterForm()));
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}