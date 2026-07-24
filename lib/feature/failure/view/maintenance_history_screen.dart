import 'package:flutter/material.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';
import 'package:om_mobile/utils/widgets/cust_textfield.dart';
import 'package:om_mobile/utils/widgets/custom_app_bar.dart';
import 'package:om_mobile/utils/widgets/sync_icon_button.dart';
import 'package:get/get.dart';
import '../../../constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../model/asset_qr_response.dart';
import '../service/failure_service.dart';

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
  final FailureService _failureService = FailureService();

  AssetQrData? _assetData;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, String>> _failureHistory = [];
  final List<Map<String, String>> _scheduleHistory = [];

  @override
  void initState() {
    super.initState();
    if (widget.showAssetQR) {
      _fetchAssetData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAssetData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final funcLocId = Get.arguments as String? ?? '';
      final response = await _failureService.getAssetDataByFuncLocId(funcLocId);
      
      if (response.responseCode == 200 && response.responseOutput != null) {
        setState(() {
          _assetData = response.responseOutput;
          _failureHistory.clear();
          _scheduleHistory.clear();
          
          for (var item in _assetData!.lstFailureMaintenanceHistory) {
            _failureHistory.add({
              'failureNo': item.failureNo ?? '',
              'dateTime': item.failureDate ?? '',
              'description': item.description ?? '',
              'status': item.status ?? '',
            });
          }
          
          for (var item in _assetData!.lstPreventiveMaintenanceHistory) {
            _scheduleHistory.add({
              'orderNo': item.orderNo ?? '',
              'plannedDate': item.plannedDate ?? '',
              'description': item.description ?? '',
              'status': item.status ?? '',
            });
          }
        });
      } else {
        setState(() {
          _errorMessage = response.responseMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load asset data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              const SyncIconButton(),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchAssetData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_assetData == null) {
      return const Center(child: Text('No asset data available'));
    }

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
              Expanded(child: _detailItem('Department:', _assetData?.department ?? '')),
              Expanded(child: _detailItem('Model No:', _assetData?.modelNo ?? '')),
            ],
          ),
          _divider(),
          Row(
            children: [
              Expanded(child: _detailItem('System:', _assetData?.system ?? '')),
              Expanded(child: _detailItem('Sub system:', _assetData?.subSystem ?? '')),
            ],
          ),
          _divider(),
          _detailItem('Location:', _assetData?.location ?? ''),
          _divider(),
          Row(
            children: [
              Expanded(child: _detailItem('OEM:', _assetData?.oem ?? '')),
              Expanded(child: _detailItem('Warranty:', _assetData?.warranty ?? '')),
            ],
          ),
          SizedBox(height: AppConstants.subElementSpacing,),
          _detailItem('Functional Location:', _assetData?.funcLocation ?? ''),
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
          CustText(name: label, size: 14,color: AppColors.textDarkSecondary,fontWeightName: FontWeight.w600,),
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
        _fieldBlock('Superior Asset:', _assetData?.superiorFunLocation ?? ''),
        _divider(),
        _fieldBlock('Current Asset ID:', _assetData?.funcLocation ?? ''),
        _divider(),
        _fieldBlock('Description:', _assetData?.description ?? ''),
        _divider(),
        _fieldBlock('Superior Description:', _assetData?.superiorFunLocationDescription ?? ''),
      ],
    );
  }

  Widget _buildEquipmentContent() {
    if (_assetData?.lstEquipmentsDetails == null || _assetData!.lstEquipmentsDetails.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No equipment details available'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldBlock('Equipment Count:', '${_assetData!.lstEquipmentsDetails.length}'),
        _divider(),
        ..._assetData!.lstEquipmentsDetails.map((equip) {
          final equipMap = equip as Map<String, dynamic>;
          return Column(
            children: [
              _fieldBlock('Equipment Name:', equipMap['equipmentName']?.toString() ?? ''),
              _divider(),
              _fieldBlock('Equipment Description:', equipMap['equipmentDescriptions']?.toString() ?? ''),
              _divider(),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFailureHistoryContent() {
    if (_failureHistory.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No failure history available'),
        ),
      );
    }

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
    if (_scheduleHistory.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No preventive maintenance history available'),
        ),
      );
    }

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
                  ? AppColors.textDarkPrimary
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
                  ? AppColors.textDarkPrimary
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
          onPressed: () {
            if (_assetData != null) {
              // Navigate to Create Failure screen with asset data
              Get.toNamed('/CreateNotification', arguments: {
                'funcLocId': _assetData!.funcLocId,
                'funcLocation': _assetData!.funcLocation,
                'description': _assetData!.description,
                'department': _assetData!.department,
                'deptId': _assetData!.deptId,
                'location': _assetData!.location,
              });
            }
          },
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
