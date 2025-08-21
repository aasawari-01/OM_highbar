import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/manual_ticket_details_form.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/custom_bottom_sheet.dart';

class ManualTicketDetailsListScreen extends StatelessWidget {
  const ManualTicketDetailsListScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> manualTicketList = const [
    {
      'manualTicketNo': 'MT001',
      'station': 'Khapri',
      'date': '08/02/2025',
      'time': '14:00',
      'operatorName': 'Amit Kumar',
      'sourceStation': 'Khapri',
      'destinationStation': 'Airport',
      'fareAmount': '50',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: 'Manual Ticket List',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {
              // Optional: Filter logic
            },
          ),
        ],
      ),
      body: manualTicketList.isEmpty
          ? Center(
        child: CustText(
          name: 'No data available in table',
          size: 1.6,
          color: AppColors.textColor4,
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: manualTicketList.length,
        itemBuilder: (context, index) {
          final item = manualTicketList[index];
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
                            CustText(name: 'Manual Ticket No:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: item['manualTicketNo'] ?? '',
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustText(name: 'Operator Name:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: item['operatorName'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Source Station:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: item['sourceStation'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Destination Station:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: item['destinationStation'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Fare Amount:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: '₹${item['fareAmount'] ?? ''}',
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
                        title: "Manual Ticket No : ${item['manualTicketNo'] ?? ''}",
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
                MaterialPageRoute(builder: (context) => ManualTicketDetailsForm()));
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
