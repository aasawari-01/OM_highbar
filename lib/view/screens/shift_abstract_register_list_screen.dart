import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/shift_abstract_register_form.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/custom_bottom_sheet.dart';

class ShiftAbstractRegisterListScreen extends StatelessWidget {
  const ShiftAbstractRegisterListScreen({Key? key}) : super(key: key);

  // Dummy data for demonstration
  final List<Map<String, String>> shiftAbstractList = const [
    {
      'station': 'SAT- Airport South',
      'date': '08/02/2025',
      'tomOrEfo': 'TOM',
      'dutyStartTime': '14:00',
      'dutyEndTime': '15:00',
      'privateCash': 'Yes',
      'remarks': 'Tested And Verified',
    },
    {
      'station': 'AQS- Automotive Square',
      'date': '03/02/2025',
      'tomOrEfo': 'TOM',
      'dutyStartTime': '13:00',
      'dutyEndTime': '21:00',
      'privateCash': 'Yes',
      'remarks': 'Test@SAF',
    },
    {
      'station': 'NAO- Airport',
      'date': '27/07/2024',
      'tomOrEfo': 'TOM',
      'dutyStartTime': '12:00',
      'dutyEndTime': '12:00',
      'privateCash': 'Yes',
      'remarks': '5465',
    },
    {
      'station': 'CSS- Congress Nagar',
      'date': '08/07/2024',
      'tomOrEfo': 'TOM',
      'dutyStartTime': '05:30',
      'dutyEndTime': '13:30',
      'privateCash': 'No',
      'remarks': 'vbcv',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: 'Shift Abstract Register Inbox',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: shiftAbstractList.isEmpty
          ? Center(
              child: CustText(
                name: 'No data available in table',
                size: 1.6,
                color: AppColors.textColor4,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: shiftAbstractList.length,
              itemBuilder: (context, index) {
                final item = shiftAbstractList[index];

                void _showBottomSheet() {
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
                                  CustText(name: 'Tom OR Efo:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['tomOrEfo'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Duty Start Time:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['dutyStartTime'] ?? '',
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
                                  CustText(name: 'Duty End Time:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['dutyEndTime'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Private Cash:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['privateCash'] ?? '',
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
              MaterialPageRoute(builder: (context) => const ShiftAbstractRegisterForm()),
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