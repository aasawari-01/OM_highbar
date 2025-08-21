import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/divyang_form.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/custom_bottom_sheet.dart';

class DivyangListScreen extends StatelessWidget {
  const DivyangListScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> divyangList = const [
    {
      'divyangId': 'DIV001',
      'station': 'Khapri',
      'name': 'Amit Kumar',
      'reportingTime': '10:00 AM',
      'contactNo': '9876543210',
      'disabilityType': 'Divyang',
      'wheelchairProvided': 'Yes',
      'journey': 'Khapri - Airport',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: 'Divyang List',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {
              // Optional: Implement filter logic
            },
          ),
        ],
      ),
      body: divyangList.isEmpty
          ? Center(
        child: CustText(
          name: 'No data available in table',
          size: 1.6,
          color: AppColors.textColor4,
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: divyangList.length,
        itemBuilder: (context, index) {
          final divyang = divyangList[index];
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
                            CustText(name: 'Divyang Id:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: divyang['divyangId'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Station:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: divyang['station'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Passenger Name:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: divyang['name'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Reporting Time:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: divyang['reportingTime'] ?? '',
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
                            CustText(name: 'Contact No.:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: divyang['contactNo'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Disability Type:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: divyang['disabilityType'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Wheelchair Provided:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: divyang['wheelchairProvided'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Journey Start - End:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: divyang['journey'] ?? '',
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
                        title: "Divyang Id : ${divyang['divyangId'] ?? ''}",
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
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
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
                MaterialPageRoute(builder: (context) => DivyangForm()));
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
