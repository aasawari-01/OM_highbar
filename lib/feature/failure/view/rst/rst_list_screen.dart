import 'package:flutter/material.dart';
import 'package:om_mobile/feature/failure/view/rst/rst_failure_screen.dart';
import '../../../../constants/app_constants.dart';
import '../../../../constants/colors.dart';
import '../../../../utils/widgets/cust_button.dart';
import '../../../../utils/widgets/cust_loader.dart';
import '../../../../utils/widgets/cust_text.dart';
import '../../../../utils/widgets/cust_textfield.dart';
import '../../../../utils/widgets/custom_app_bar.dart';
import '../../../../utils/widgets/sync_icon_button.dart';
import 'package:get/get.dart';
import '../../controller/rst_list_controller.dart';
import '../../model/rst_list_response.dart';
import '../../../../service/master_data_sync_service.dart';

class RstListScreen extends StatefulWidget {
  const RstListScreen({Key? key}) : super(key: key);

  @override
  State<RstListScreen> createState() => _RstListScreenState();
}

class _RstListScreenState extends State<RstListScreen> {
  late final RstListController controller;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(RstListController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchRstList();
    });
  }

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
        title: 'RST List',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  controller.searchQuery.value = "";
                }
              });
            },
          ),
          const SizedBox(width: 4),
          const SyncIconButton(),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: 8),
                child: CustomTextField(
                  controller: _searchController,
                  hintText: "Search by failure no, plant, train set, status...",
                  onChanged: (val) => controller.searchQuery.value = val,
                  prefixIcon: const Icon(Icons.search, color: AppColors.textDarkSecondary, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      controller.searchQuery.value = '';
                      setState(() => _isSearching = false);
                    },
                    child: const Icon(Icons.close, color: AppColors.textDarkSecondary, size: 20),
                  ),
                  autofocus: true,
                ),
              ),
            Expanded(child: _buildRstListContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildRstListContent() {
    return Obx(() {
      final syncService = Get.find<MasterDataSyncService>();
      if (syncService.isSyncing.value) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CustLoader(),
            const SizedBox(height: 16),
            CustText(
              name: syncService.syncStatus.value,
              size: 14,
              color: AppColors.orangeColor,
            ),
          ],
        );
      }
      if (controller.isLoading.value) {
        return const CustLoader();
      }
      if (controller.errorMessage.isNotEmpty) {
        return Center(child: CustText(name: controller.errorMessage.value, size: 14));
      }
      if (controller.filteredRstItems.isEmpty) {
        return const Center(
          child: Text(
            'No RST items found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => controller.fetchRstList(),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: AppConstants.elementSpacing),
          itemCount: controller.filteredRstItems.length,
          itemBuilder: (context, index) {
            final rstItem = controller.filteredRstItems[index];
            return _buildRstCard(rstItem);
          },
        ),
      );
    });
  }

  Widget _buildRstCard(RstItem rstItem) {
    return GestureDetector(
      onTap: () {
        Get.to(() => RstFailureScreen(
          notificationId: rstItem.notificationId,
        ));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppConstants.elementSpacing, AppConstants.elementSpacing, AppConstants.elementSpacing, 0),
        decoration: BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustText(
                    name: 'Status:',
                    size: 13,
                    color: AppColors.textDarkSecondary,
                  ),
                  const SizedBox(width: 6),
                  _statusChip(rstItem.statusName ?? ''),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.dividerColor3, height: 1),
              const SizedBox(height: 8),
              _buildLabelValue('Failure No:', rstItem.notificationCode ?? ''),
              const SizedBox(height: 12),
              _buildLabelValue('Plant:', rstItem.plantName ?? ''),
              const SizedBox(height: 12),
              _buildLabelValue('Train Set No:', rstItem.trainSetNo ?? ''),
              const SizedBox(height: 12),
              _buildLabelValue('IBL Process:', rstItem.powerBlockRequired == true ? '' : 'N/A'),
              if (rstItem.powerBlockRequired == true && rstItem.iblId == 0)
                _buildIblButton('IBL Process Request', rstItem),
              if (rstItem.iblId != null && rstItem.iblId != 0)
                _buildIblButton('IBL Process View', rstItem),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText.detailLabel(label),
        const SizedBox(height: 2),
        CustText.detailValue(value),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return AppColors.textDarkSecondary;
    if (status.contains('Pending')) return AppColors.red;
    if (status.contains('Complete')) return AppColors.green;
    if (status.contains('INPROCESS')) return AppColors.orangeColor;
    return AppColors.textDarkSecondary;
  }

  Widget _statusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustText(
        name: status,
        size: 13,
        color: color,
      ),
    );
  }


  Widget _buildIblButton(String buttonText, RstItem rstItem) {
    return CustOutlineButton(
      name: buttonText,
      onSelected: (isSelected) {
        // Handle button tap
        debugPrint('IBL button tapped: $buttonText for item ${rstItem.notificationCode}');
      },
      borderColor: AppColors.orangeColor,
      textDarkPrimary: AppColors.orangeColor,
      size: double.infinity,
    );
  }
}
