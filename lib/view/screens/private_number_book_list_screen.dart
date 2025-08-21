import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/private_number_book_form.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/custom_bottom_sheet.dart';

class PrivateNumberBookListScreen extends StatelessWidget {
  const PrivateNumberBookListScreen({Key? key}) : super(key: key);
  
  final List<Map<String, String>> privateNumberList = const [
    {
      'privateNumber': 'PN123456',
      'dateTime': '08/02/2025 14:00',
      'pnExchange': 'John Doe',
      'pnReceived': 'Jane Smith',
      'purpose': 'Emergency communication',
      'signature': 'SC1234',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: 'Private Number Book List',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: privateNumberList.isEmpty
          ? Center(
              child: CustText(
                name: 'No data available in table',
                size: 1.6,
                color: AppColors.textColor4,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: privateNumberList.length,
              itemBuilder: (context, index) {
                final item = privateNumberList[index];
                
                void _showBottomSheet() {
                  CustomBottomSheet.show(
                    context: context,
                    title: "Private Number: ${item['privateNumber'] ?? ''}",
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
                                  CustText(name: 'Private Number:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['privateNumber'] ?? '',
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
                                  CustText(name: 'PN Exchange:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['pnExchange'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'PN Received:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['pnReceived'] ?? '',
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
                                  CustText(name: 'Purpose for which utilized:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['purpose'] ?? '',
                                    size: 1.4,
                                    color: AppColors.black,
                                    fontWeightName: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustText(name: 'Signature Of SC With Emp No:', size: 1.3, color: AppColors.textColor4),
                                  CustText(
                                    name: item['signature'] ?? '',
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
                MaterialPageRoute(builder: (context) => PrivateNumberBookForm()));
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}