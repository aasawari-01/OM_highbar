import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../../../utils/widgets/sync_icon_button.dart';
import '../model/je_inspection_item.dart';
import '../service/inspection_service.dart';
import 'common_inspection_checklist_screen.dart';

/// JE inspection list (web: JEInspectionList / JEInspectionHubTable).
class JEInspectionListScreen extends StatefulWidget {
  const JEInspectionListScreen({super.key});

  @override
  State<JEInspectionListScreen> createState() => _JEInspectionListScreenState();
}

class _JEInspectionListScreenState extends State<JEInspectionListScreen> {
  final _service = InspectionService();
  List<JEInspectionItem> _items = [];
  bool _loading = true;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _service.getJEInspectionList();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  List<String> get _statusTabs {
    final unique = _items.map((e) => e.statusText).where((s) => s.isNotEmpty).toSet().toList()
      ..sort();
    return ['All', ...unique];
  }

  List<JEInspectionItem> get _filtered => _statusFilter == 'All'
      ? _items
      : _items.where((e) => e.statusText == _statusFilter).toList();

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _openChecklist(JEInspectionItem item, {bool view = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommonInspectionChecklistScreen(inspectionId: item.jeInspectionId, isView: view)),
    );
  }

  Future<void> _skip(JEInspectionItem item) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white1,
        title: CustText(name: 'Skip Inspection', size: AppConstants.headerSize, fontWeightName: FontWeight.w600),
        content: Form(
          key: formKey,
          child: CustomTextField(
            label: 'Remark *',
            hintText: 'Enter remark',
            controller: controller,
            maxLines: 4,
            maxLength: 200,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please add remark' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) Navigator.pop(ctx, true);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    final remark = controller.text.trim();
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final ok = await _service.skipInspection(id: item.id, remark: remark);
    if (!mounted) return;
    if (ok) {
      _snack('Success');
      await _load();
    } else {
      setState(() => _loading = false);
      _snack('Error in saved data');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'JE Inspection List',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: const [SyncIconButton(), SizedBox(width: 16)],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.orangeColor))
            : Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.screenPadding, vertical: 8),
                      children: [for (final t in _statusTabs) _tab(t)],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: rows.isEmpty
                          ? ListView(children: const [
                              SizedBox(height: 120),
                              Center(child: Text('No inspections found')),
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppConstants.screenPadding),
                              itemCount: rows.length,
                              itemBuilder: (_, i) => _card(rows[i]),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _tab(String label) {
    final selected = _statusFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _statusFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.orangeColor : AppColors.white1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.orangeColor : AppColors.textFieldColor),
          ),
          child: CustText(
            name: label,
            size: 13,
            color: selected ? AppColors.white1 : AppColors.textDarkPrimary,
          ),
        ),
      ),
    );
  }

  Widget _card(JEInspectionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.elementSpacing),
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.white1,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustText.detailLabel('Status:'),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustText(
                  name: item.statusText.isEmpty ? '—' : item.statusText,
                  size: AppConstants.detailValueSize,
                  color: _statusColor(item.status),
                  fontWeightName: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.subElementSpacing),
          const Divider(color: AppColors.dividerColor3, height: 1),
          const SizedBox(height: AppConstants.subElementSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelValue('Inspection No:', item.inspectionNo),
                    const SizedBox(height: AppConstants.elementSpacing),
                    _labelValue('Inspection Name:', item.inspectionName),
                    const SizedBox(height: AppConstants.elementSpacing),
                    _labelValue('Created By:', item.createdName),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelValue('Inspection Date:', item.inspectionScheduledDate),
                    const SizedBox(height: AppConstants.elementSpacing),
                    _labelValue('Inspection Type:', item.inspectionType),
                    const SizedBox(height: AppConstants.elementSpacing),
                    _labelValue('Department:', item.deptName),
                  ],
                ),
              ),
            ],
          ),
          ..._actions(item),
        ],
      ),
    );
  }

  List<Widget> _actions(JEInspectionItem item) {
    final buttons = <Widget>[];
    if (item.canFill) {
      buttons.add(_actionButton('Fill Checklist', () => _openChecklist(item)));
    } else if (item.canFillObservation) {
      buttons.add(_actionButton('Fill Checklist Observation', () => _openChecklist(item), width: 200));
    } else if (item.canView) {
      buttons.add(_actionButton('View', () => _openChecklist(item, view: true), width: 80));
    }
    if (item.canSkip) {
      buttons.add(CustOutlineButton(
        name: 'Skip',
        size: 80,
        sHeight: 30,
        borderColor: AppColors.red,
        textDarkPrimary: AppColors.red,
        fontSize: AppConstants.buttonFontSize,
        onSelected: (_) => _skip(item),
      ));
    }
    if (item.pendingSkipAck) {
      buttons.add(CustText(
        name: 'Pending By SE For Acknowledgement',
        size: AppConstants.detailValueSize,
        color: AppColors.orangeColor,
      ));
    }
    if (buttons.isEmpty) return const [];
    return [
      const SizedBox(height: AppConstants.elementSpacing),
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: buttons),
    ];
  }

  Widget _actionButton(String name, VoidCallback onTap, {double width = 120}) => CustButton(
        name: name,
        size: width,
        sHeight: 30,
        fontSize: AppConstants.buttonFontSize,
        borderRadius: AppConstants.inputRadius,
        onSelected: (_) => onTap(),
      );

  Widget _labelValue(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText.detailLabel(label),
          const SizedBox(height: AppConstants.labelSpacing),
          CustText.detailValue(value.isEmpty ? '—' : value),
        ],
      );

  Color _statusColor(String status) {
    switch (status) {
      case '157':
      case '158':
        return AppColors.green1;
      case '156':
      case '194':
        return AppColors.red;
      default:
        return AppColors.orangeColor;
    }
  }
}
