import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:om_mobile/widgets/custom_bottom_sheet.dart';
import 'asset_register_form.dart';

class AssetsListScreen extends StatelessWidget {
  const AssetsListScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> assets = const [
    {
      'assetNo': 'A-001',
      'description': 'Escalator',
      'quantity': '2',
      'modelNo': 'ESC-2022',
      'station': 'Khapri',
      'assetIdFI': 'FI-1001',
      'assetId': 'AST-0001',
      'modification': 'None',
      'modRemarks': '-',
      'date': '01-01-2024',
    },
    {
      'assetNo': 'A-002',
      'description': 'Lift',
      'quantity': '1',
      'modelNo': 'LFT-2021',
      'station': 'Airport',
      'assetIdFI': 'FI-1002',
      'assetId': 'AST-0002',
      'modification': 'Replaced',
      'modRemarks': 'Replaced motor',
      'date': '15-02-2024',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        title: 'Asset Register List',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: assets.isEmpty
          ? Center(
        child: CustText(
          name: 'No data available in table',
          size: 1.6,
          color: AppColors.textColor4,
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final asset = assets[index];

          void _showBottomSheet() {
            CustomBottomSheet.show(
              context: context,
              title: "Asset No : ${asset['assetNo'] ?? ''}",
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
                            CustText(name: 'Asset No:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: asset['assetNo'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Model No:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: asset['modelNo'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Asset Id:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: asset['assetId'] ?? '',
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
                            CustText(name: 'Station:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: asset['station'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Asset Id created by FI:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: asset['assetIdFI'] ?? '',
                              size: 1.4,
                              color: AppColors.black,
                              fontWeightName: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustText(name: 'Date:', size: 1.3, color: AppColors.textColor4),
                            CustText(
                              name: asset['date'] ?? '',
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
              MaterialPageRoute(builder: (context) => const AssetRegisterForm()),
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