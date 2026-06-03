import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/cust_toggle.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../../../utils/widgets/cust_data_card.dart';

class CommonInspectionChecklistScreen extends StatefulWidget {
  const CommonInspectionChecklistScreen({super.key});

  @override
  State<CommonInspectionChecklistScreen> createState() => _CommonInspectionChecklistScreenState();
}

class _CommonInspectionChecklistScreenState extends State<CommonInspectionChecklistScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // State for the list items
  final List<Map<String, dynamic>> _checklistItems = [
    {'status': false, 'remarks': ''},
    {'status': false, 'remarks': ''},
    {'status': false, 'remarks': ''},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submit() {
    // Submit action
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'Common Inspection Checklist',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          _buildProfileAction(),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: CustomTextField(controller: _searchController,
               hintText: 'Search by system',
                suffixIcon:  Icon(TablerIcons.search, color: AppColors.black),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                itemCount: _checklistItems.length,
                itemBuilder: (context, index) {
                  return _buildChecklistCard(index);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.screenPadding,
                AppConstants.elementSpacing,
                AppConstants.screenPadding,
                AppConstants.screenPadding,
              ),
              child: CustButton(
                name: 'Save As Draft',
                size: double.infinity,
                sHeight: AppConstants.buttonHeight,
                onSelected: (_) => _submit(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard(int index) {
    return CustDataCard(
      items: [
        DataCardItem(
          label: 'System',
          isFullWidth: true,
          valueWidget: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustText(name: 'Indoor status', size: 16, fontWeightName: FontWeight.bold),
              YesNoToggle(
                value: _checklistItems[index]['status'],
                onChanged: (val) {
                  setState(() {
                    _checklistItems[index]['status'] = val;
                  });
                },
              ),
            ],
          ),
        ),
        DataCardItem(
          label: 'Subsystem:',
          isFullWidth: true,
          valueWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustText(name: 'Logbooks record, BOC & Other Registers Cleaning status', size: 16, fontWeightName: FontWeight.bold),
            ],
          ),
        ),
        DataCardItem(
          label: 'Remarks',
          isFullWidth: true,
          valueWidget: CustomTextField(
            hintText: 'Enter Remarks',
            controller: TextEditingController(text: _checklistItems[index]['remarks']),
            onChanged: (val) {
              _checklistItems[index]['remarks'] = val;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAction() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.white1,
        ),
        Positioned(
          right: 0,
          bottom: 2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white1, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
