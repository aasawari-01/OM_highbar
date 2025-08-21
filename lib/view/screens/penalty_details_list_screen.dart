import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/penalty_register_form.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/custom_bottom_sheet.dart';

class PenaltyDetailsListScreen extends StatelessWidget {
  const PenaltyDetailsListScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> penaltyList = const [
    {
      'station': 'Khapri',
      'date': '08/02/2025',
      'time': '14:00',
      'section': 'Section 12',
      'description': 'Penalty for ticketless travel',
      'passengerName': 'Amit Kumar',
      'passengerAddress': '123 Main St',
      'amount': '500',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: 'Penalty Details List',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: penaltyList.isEmpty
          ? Center(
              child: CustText(
                name: 'No data available in table',
                size: 1.6,
                color: AppColors.textColor4,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: penaltyList.length,
              itemBuilder: (context, index) {
                final item = penaltyList[index];
                
                void _showBottomSheet() {
                  CustomBottomSheet.show(
                    context: context,
                    title: "Penalty Details",
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
                }

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
                                  CustText(name: 'Date:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['date'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Time:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['time'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Section of Penalty:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['section'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Penalty Description:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['description'] ?? '',
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
                                  CustText(name: 'Name of Passenger:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['passengerName'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Address of Passenger:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['passengerAddress'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Amount:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['amount'] ?? '',
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
                        top: 12,
                        right: 14,
                        child: IconButton(
                          icon: const Icon(Icons.more_vert, color: AppColors.textColor4),
                          onPressed: _showBottomSheet,
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
              offset: const Offset(0, 4),
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
                MaterialPageRoute(builder: (context) => PenaltyRegisterForm()));
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}