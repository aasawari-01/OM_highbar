import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../controller/rst_failure_controller.dart';
import 'package:om_mobile/utils/widgets/custom_app_bar.dart';
import 'package:om_mobile/utils/widgets/sync_icon_button.dart';

/// The SIC check list of one SIC row of an RST failure (Part F). Same design as
/// before: header card, orange collapsible section, one card per check item
/// (DMR / TC / TMB and remark) with a pager, the two declarations and the
/// remark. The data is real now: the sections come from SICHeaderMaster.db and
/// the items from SICItemMaster.db (offline). It is read-only, as on the web.
class SicChecklistScreen extends StatefulWidget {
  const SicChecklistScreen({super.key});

  @override
  State<SicChecklistScreen> createState() => _SicChecklistScreenState();
}

class _SicChecklistScreenState extends State<SicChecklistScreen> {
  static const int _pageSize = 1; // one item card per page, as in the design
  final Map<String, int> _page = {}; // headerId -> current page (0-based)
  final Set<String> _collapsed = {}; // sections start expanded

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RstFailureController>();

    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'SIC check list',
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: SyncIconButton(),
          ),
        ],
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.screenPadding),
                  child: Obx(() {
                    final data = controller.rstFailureData.value;
                    final sic = controller.openSicCheck.value ?? const <String, String>{};
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _headerCard(data?.notificationCode ?? '', data?.createdOn ?? '',
                            data?.trainSetNo ?? '', sic['sicType'] ?? ''),
                        const SizedBox(height: 20),
                        if (controller.sheetLoading.value)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (controller.sheetUnavailable.value)
                          const Text('No check list is set up for this SIC type.',
                              style: TextStyle(color: Colors.grey))
                        else
                          for (final h in controller.sheetHeaders) ..._section(controller, h),
                        const SizedBox(height: 4),
                        _declaration(
                            'I Hereby declare, that SIC has been performed on concerned equipment.',
                            (sic['checkSIC1'] ?? '').toLowerCase() == 'true' ||
                                controller.isSicWorkCompleted.value),
                        _declaration(
                            'I Hereby declare, that All the necessary follow up action as described in Part F above and final Inspection, including SIC(if any), have been completed.',
                            (sic['checkSIC2'] ?? '').toLowerCase() == 'true' ||
                                controller.isSicWorkCompleted.value),
                        const SizedBox(height: 16),
                        const Text('Remark', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        _remarkBox(sic['remark'] ?? ''),
                        const SizedBox(height: 24),
                      ],
                    );
                  }),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangeColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Submit',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard(String failureNo, String createdOn, String trainSet, String sicType) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _labelValue('Failure No:', failureNo)),
              Expanded(child: _labelValue('Created On:', createdOn)),
            ],
          ),
          const Divider(height: 24),
          _labelValue('Train Set :', trainSet),
        ],
      ),
    );
  }

  Widget _labelValue(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2),
        ],
      );

  /// One collapsible section (orange title) with its item cards and pager.
  List<Widget> _section(RstFailureController c, Map<String, dynamic> h) {
    final id = '${h['headerId']}';
    final open = !_collapsed.contains(id);
    final items = [
      for (final l in c.sheetLines)
        if ('${l['headerId']}' == id) l
    ];
    final pages = (items.length / _pageSize).ceil().clamp(1, 1000000);
    final page = (_page[id] ?? 0).clamp(0, pages - 1);
    final shown = items.skip(page * _pageSize).take(_pageSize).toList();

    return [
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => open ? _collapsed.add(id) : _collapsed.remove(id)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('${h['description'] ?? ''}',
                  style: const TextStyle(
                      color: AppColors.orangeColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (open) ...[
        for (final l in shown) ...[
          _itemCard(l),
          const SizedBox(height: 12),
        ],
        _pager(id, page, pages),
      ],
      const SizedBox(height: 16),
    ];
  }

  Widget _itemCard(Map<String, dynamic> l) {
    final dmr = l['hasDMR'] == true;
    final tc = l['hasTC'] == true;
    final dmb = l['hasDMB'] == true;
    final none = !dmr && !tc && !dmb; // none flagged: show all three
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l['description'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              if (dmr || none) _tick('DMR'),
              if (tc || none) _tick('TC'),
              if (dmb || none) _tick('TMB'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Remark', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          _remarkBox(''),
        ],
      ),
    );
  }

  Widget _tick(String label) => Container(
      width: 64,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          const SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(value: false, onChanged: null, activeColor: AppColors.orangeColor),
          ),
        ],
      ));

  Widget _remarkBox(String text) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
        child: Text(text.isEmpty ? '' : text, style: const TextStyle(fontSize: 13)),
      );

  Widget _pager(String id, int page, int pages) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: page > 0 ? () => setState(() => _page[id] = page - 1) : null,
            child: Icon(Icons.keyboard_arrow_left,
                color: page > 0 ? AppColors.orangeColor : Colors.grey),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('${page + 1}/$pages', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: page < pages - 1 ? () => setState(() => _page[id] = page + 1) : null,
            child: Icon(Icons.keyboard_arrow_right,
                color: page < pages - 1 ? AppColors.orangeColor : Colors.grey),
          ),
        ],
      );

  Widget _declaration(String text, bool checked) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: checked, onChanged: null, activeColor: AppColors.orangeColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(text,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      );
}
