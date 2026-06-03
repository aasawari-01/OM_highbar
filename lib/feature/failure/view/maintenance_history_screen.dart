import 'package:flutter/material.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';
import 'package:om_mobile/utils/widgets/cust_textfield.dart';
import 'package:om_mobile/utils/widgets/custom_app_bar.dart';
import '../../../constants/colors.dart';
import '../../../constants/app_constants.dart';

class MaintenanceHistoryScreen extends StatefulWidget {
  final bool showAssetQR;
  const MaintenanceHistoryScreen({Key? key, this.showAssetQR = false})
      : super(key: key);

  @override
  State<MaintenanceHistoryScreen> createState() =>
      _MaintenanceHistoryScreenState();
}

class _MaintenanceHistoryScreenState extends State<MaintenanceHistoryScreen> {
  bool _assetHierarchyExpanded = true;
  bool _equipmentExpanded = true;
  bool _failureHistoryExpanded = true;
  bool _scheduleHistoryExpanded = true;

  int _failurePage = 1;
  int _schedulePage = 1;

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _failureHistory = [
    {
      'failureNo': 'SIG/04-2026/0068',
      'dateTime': '18-10-2025  16:00',
      'description': 'DER',
      'status': 'Completed',
    },
    {
      'failureNo': 'SIG/05-2026/0070',
      'dateTime': '22-11-2025  10:30',
      'description': 'Fault in wiring',
      'status': 'Open',
    },
  ];

  final List<Map<String, String>> _scheduleHistory = [
    {
      'orderNo': 'SIG/04-2026/0068',
      'plannedDate': '18-12-2025',
      'description': 'DER',
      'status': 'Completed',
    },
    {
      'orderNo': 'SIG/05-2026/0071',
      'plannedDate': '25-01-2026',
      'description': 'Routine check',
      'status': 'Planned',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: widget.showAssetQR ? 'Asset QR View' : 'Maintenance History',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: widget.showAssetQR
              ? [
              IconButton(
              icon: const Icon(Icons.cloud_upload_outlined,
                  color: Colors.white),
              onPressed: () {},
            ),
            Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            child: const Icon(Icons.person,
            color: Colors.white, size: 18),
            ),
            ),
            ]
        : []
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: widget.showAssetQR
              ? _buildAssetQrView()
              : _buildMaintenanceSection(),
        ),
      ),
    );
  }


  Widget _buildAssetQrView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16,0),
                  child: _buildSearchField(),
                ),
                _buildAssetDetailsCard(),
                const SizedBox(height: 8),
                _buildAccordion(
                  title: 'Asset Hierarchy',
                  isExpanded: _assetHierarchyExpanded,
                  onTap: () => setState(
                      () => _assetHierarchyExpanded = !_assetHierarchyExpanded),
                  child: _buildAssetHierarchyContent(),
                ),
                _buildAccordion(
                  title: 'Equipment Details',
                  isExpanded: _equipmentExpanded,
                  onTap: () =>
                      setState(() => _equipmentExpanded = !_equipmentExpanded),
                  child: _buildEquipmentContent(),
                ),
                _buildAccordion(
                  title: 'Failure Maintenance History',
                  isExpanded: _failureHistoryExpanded,
                  onTap: () => setState(
                      () => _failureHistoryExpanded = !_failureHistoryExpanded),
                  child: _buildFailureHistoryContent(),
                ),
                _buildAccordion(
                  title: 'Schedule Maintenance History',
                  isExpanded: _scheduleHistoryExpanded,
                  onTap: () => setState(() =>
                      _scheduleHistoryExpanded = !_scheduleHistoryExpanded),
                  child: _buildScheduleHistoryContent(),
                ),
              ],
            ),
          ),
        ),
        _buildCreateFailureButton(),
      ],
    );
  }

  Widget _buildSearchField() {
    return CustomTextField(controller: _searchController,
    label: "Search Asset ID",
    hintText: "Search here",);
  }


  Widget _buildAssetDetailsCard() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _detailItem('Department:', 'MEP')),
              Expanded(child: _detailItem('Model No:', '17-10-2025 14:00')),
            ],
          ),
          _divider(),
          Row(
            children: [
              Expanded(child: _detailItem('System:', 'System')),
              Expanded(child: _detailItem('Sub system:', 'Sub System')),
            ],
          ),
          _divider(),
          _detailItem('Location:', 'LAD Chowk'),
          _divider(),
          Row(
            children: [
              Expanded(child: _detailItem('OEM:', 'OEM')),
              Expanded(child: _detailItem('Warranty:', '10/07/2026')),
            ],
          ),
          SizedBox(height: AppConstants.subElementSpacing,),
          _detailItem('DLP:', 'DLP'),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText(name: label, size: 14,color: AppColors.textColor4,fontWeightName: FontWeight.w600,),
          const SizedBox(height: 3),
          CustText(name: value, size: 14,color: AppColors.black,fontWeightName: FontWeight.w600,),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 20, thickness: 0.8, color: AppColors.dividerColor3);

  Widget _buildAccordion({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orangeColor)),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.orangeColor,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              margin: const EdgeInsets.only(right: 16,left: 16,bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssetHierarchyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldBlock('Superior Asset:', 'MEP-FPS-FEX-00003'),
        _divider(),
        _fieldBlock('Current Asset ID:', 'MEP-FPS-FEX-00003'),
        _divider(),
        _fieldBlock('Sub Asset ID:', 'DER'),
      ],
    );
  }

  Widget _buildEquipmentContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldBlock('Equipment', 'MEP-FPS-FEX-00003'),
        _divider(),
        _fieldBlock('Equipment Description', 'MEP-FPS-FEX-00003'),
      ],
    );
  }

  Widget _buildFailureHistoryContent() {
    final item =
        _failureHistory[(_failurePage - 1).clamp(0, _failureHistory.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldBlock('Failure No.', item['failureNo'] ?? ''),
        _divider(),
        _fieldBlock(
            'Actual Failure Completed Date & Time', item['dateTime'] ?? ''),
        _divider(),
        _fieldBlock('Description', item['description'] ?? ''),
        _divider(),
        _fieldBlock('Status', item['status'] ?? ''),
        const SizedBox(height: 12),
        _buildPagination(
          currentPage: _failurePage,
          totalPages: _failureHistory.length,
          onPrev: () {
            if (_failurePage > 1) setState(() => _failurePage--);
          },
          onNext: () {
            if (_failurePage < _failureHistory.length)
              setState(() => _failurePage++);
          },
        ),
      ],
    );
  }

  Widget _buildScheduleHistoryContent() {
    final item = _scheduleHistory[
        (_schedulePage - 1).clamp(0, _scheduleHistory.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldBlock('Order No.', item['orderNo'] ?? ''),
        _divider(),
        _fieldBlock('Planned Date', item['plannedDate'] ?? ''),
        _divider(),
        _fieldBlock('Description', item['description'] ?? ''),
        _divider(),
        _fieldBlock('Status', item['status'] ?? ''),
        const SizedBox(height: 12),
        _buildPagination(
          currentPage: _schedulePage,
          totalPages: _scheduleHistory.length,
          onPrev: () {
            if (_schedulePage > 1) setState(() => _schedulePage--);
          },
          onNext: () {
            if (_schedulePage < _scheduleHistory.length)
              setState(() => _schedulePage++);
          },
        ),
      ],
    );
  }

  Widget _fieldBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ],
    );
  }

  Widget _buildPagination({
    required int currentPage,
    required int totalPages,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: currentPage > 1 ? onPrev : null,
          child: Icon(Icons.chevron_left,
              size: 22,
              color: currentPage > 1
                  ? AppColors.textColor
                  : Colors.grey.shade300),
        ),
        const SizedBox(width: 20),
        Text('$currentPage',
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: currentPage < totalPages ? onNext : null,
          child: Icon(Icons.chevron_right,
              size: 22,
              color: currentPage < totalPages
                  ? AppColors.textColor
                  : Colors.grey.shade300),
        ),
      ],
    );
  }

  Widget _buildCreateFailureButton() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orangeColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text(
            'Create Failure',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAccordion(
            title: 'Failure Maintenance History',
            isExpanded: _failureHistoryExpanded,
            onTap: () => setState(
                () => _failureHistoryExpanded = !_failureHistoryExpanded),
            child: _buildFailureHistoryContent(),
          ),
          const SizedBox(height: 8),
          _buildAccordion(
            title: 'Schedule Maintenance History',
            isExpanded: _scheduleHistoryExpanded,
            onTap: () => setState(
                () => _scheduleHistoryExpanded = !_scheduleHistoryExpanded),
            child: _buildScheduleHistoryContent(),
          ),
        ],
      ),
    );
  }


  // Widget _divider() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 12),
  //     child: Divider(
  //         height: 1,
  //         thickness: 1,
  //         color: AppColors.dividerColor3
  //     ),
  //   );
  // }
}
