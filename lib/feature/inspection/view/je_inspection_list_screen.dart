import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_popup.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';
import '../controller/je_inspection_list_controller.dart';
import '../model/je_inspection_item.dart';
import 'bms_inspection_screen.dart';
import 'buffer_stop_screen.dart';
import 'cab_petrolling_screen.dart';
import 'common_inspection_checklist_screen.dart';
import 'creep_request_screen.dart';
import 'dg_log_book_screen.dart';
import 'foot_inspection_screen.dart';
import 'load_details_screen.dart';
import 'oms_action_screen.dart';
import 'pilot_train_screen.dart';
import 'temperature_monitoring_screen.dart';
import 'toe_load_screen.dart';
import 'weld_inspection_screen.dart';
import 'widgets/inspection_dialogs.dart';

/// JE inspection list (web: JEInspectionList / JEInspectionHubTable).
class JEInspectionListScreen extends StatefulWidget {
  const JEInspectionListScreen({super.key});

  @override
  State<JEInspectionListScreen> createState() => _JEInspectionListScreenState();
}

class _JEInspectionListScreenState extends State<JEInspectionListScreen> {
  late final JEInspectionListController c;

  @override
  void initState() {
    super.initState();
    Get.delete<JEInspectionListController>();
    c = Get.put(JEInspectionListController());
  }

  @override
  void dispose() {
    Get.delete<JEInspectionListController>();
    super.dispose();
  }

  Future<void> _openChecklist(JEInspectionItem item,
      {bool view = false}) async {
    final id = item.jeInspectionId;
    final Widget screen;
    switch (c.kindOf(item)) {
      case InspectionKind.bms:
        screen = BmsInspectionScreen(inspectionId: id, isView: view);
      case InspectionKind.loadDetails:
        screen = LoadDetailsScreen(inspectionId: id);
      case InspectionKind.cabPetrolling:
        screen = CabPetrollingScreen(inspectionId: id);
      case InspectionKind.bufferStop:
        screen = BufferStopScreen(inspectionId: id);
      case InspectionKind.dgLog:
        screen = DgLogBookScreen(inspectionId: id);
      case InspectionKind.pilotTrain:
        screen = PilotTrainScreen(inspectionId: id);
      case InspectionKind.weld:
        screen = WeldInspectionScreen(inspectionId: id);
      case InspectionKind.creep:
        screen = CreepRequestScreen(inspectionId: id);
      case InspectionKind.foot:
        screen = FootInspectionScreen(inspectionId: id);
      case InspectionKind.omsAction:
        screen = OmsActionScreen(inspectionId: id);
      case InspectionKind.temperature:
        screen = TemperatureMonitoringScreen(inspectionId: id);
      case InspectionKind.toeLoad:
        screen = ToeLoadScreen(inspectionId: id);
      case InspectionKind.commonChecklist:
      case null:
        screen =
            CommonInspectionChecklistScreen(inspectionId: id, isView: view);
    }
    final saved = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => screen));
    if (saved == true && mounted) c.load();
  }

  Future<void> _skip(JEInspectionItem item) async {
    final remarkController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await Get.dialog<bool>(
      CustPopup(
        icon: TablerIcons.player_track_next,
        iconColor: AppColors.orangeColor,
        confirmText: 'Submit',
        cancelText: 'Cancel',
        onCancel: () => Get.back(result: false),
        onConfirm: () {
          if (formKey.currentState?.validate() ?? false) Get.back(result: true);
        },
        customContent: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CustText(
                  name: 'Skip Inspection',
                  size: AppConstants.headerSize,
                  color: AppColors.black,
                  fontWeightName: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.elementSpacing),
              CustomTextField(
                label: 'Remark *',
                hintText: 'Enter remark',
                controller: remarkController,
                maxLines: 4,
                maxLength: 200,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please add remark'
                    : null,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
    final remark = remarkController.text.trim();
    remarkController.dispose();
    if (confirmed != true) return;

    final ok = await c.skip(item, remark);
    showInspectionSnack(
        ok ? 'Inspection skipped successfully.' : 'Error in saving data',
        isError: !ok);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'JE Inspection List',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          Obx(() => IconButton(
                icon: Icon(c.searching.value ? Icons.close : Icons.search,
                    color: Colors.white, size: 26),
                onPressed: c.toggleSearch,
              )),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() {
          if (c.loading.value) {
            return const CustLoader();
          }
          final rows = c.filtered;
          return Column(
            children: [
              if (c.searching.value)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppConstants.screenPadding,
                      8, AppConstants.screenPadding, 0),
                  child: CustomTextField(
                    controller: c.searchController,
                    hintText: 'Search inspections',
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textDarkSecondary, size: 20),
                    suffixIcon: GestureDetector(
                      onTap: c.toggleSearch,
                      child: const Icon(Icons.close,
                          color: AppColors.textDarkSecondary, size: 20),
                    ),
                    onChanged: (v) => c.query.value = v,
                  ),
                ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.screenPadding, vertical: 8),
                  children: [for (final t in c.statusTabs) _tab(t)],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: c.load,
                  child: rows.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text('No inspections found',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey)),
                          ),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              bottom: AppConstants.elementSpacing),
                          itemCount: rows.length,
                          itemBuilder: (_, i) => _card(rows[i]),
                        ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _tab(String label) {
    final selected = c.statusFilter.value == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => c.statusFilter.value = label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.orangeColor : AppColors.white1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? AppColors.orangeColor
                    : AppColors.textFieldColor),
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
      margin: const EdgeInsets.fromLTRB(
        AppConstants.elementSpacing,
        AppConstants.elementSpacing,
        AppConstants.elementSpacing,
        0,
      ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustText(
                  name: item.statusText.isEmpty ? '—' : item.statusText,
                  size: 13,
                  color: _statusColor(item.status),
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
                    _labelValue(
                        'Inspection Date:', item.inspectionScheduledDate),
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
      buttons.add(_actionButton(
          'Fill Checklist Observation', () => _openChecklist(item),
          width: 200));
    } else if (item.canUpdate) {
      buttons.add(_actionButton('Update Checklist', () => _openChecklist(item),
          width: 150));
    } else if (item.canView) {
      buttons.add(_actionButton('View', () => _openChecklist(item, view: true),
          width: 80));
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
      Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: buttons),
    ];
  }

  Widget _actionButton(String name, VoidCallback onTap, {double width = 120}) =>
      CustButton(
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
          const SizedBox(height: 2),
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
