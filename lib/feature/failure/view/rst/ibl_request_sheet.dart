import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../constants/app_constants.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/strings.dart';
import '../../../../core/models/label_value.dart';
import '../../../../utils/widgets/cust_date_time_picker.dart';
import '../../../../utils/widgets/cust_dropdown.dart';
import '../../../../utils/widgets/cust_text.dart';
import '../../../../utils/widgets/cust_textfield.dart';
import '../../service/failure_service.dart';
import '../shared/failure_toast.dart';

/// "IBL process request" popup of the RST list (web: RSTCorrectiveJEInbox).
/// Purpose of work, IBL line, train set, from / to date time. Needs internet to
/// send, like the web. Returns true when the request was created.
Future<bool> showIblRequestSheet(BuildContext context, int notificationId) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _IblRequestSheet(notificationId: notificationId),
  );
  return done == true;
}

class _IblRequestSheet extends StatefulWidget {
  final int notificationId;
  const _IblRequestSheet({required this.notificationId});

  @override
  State<_IblRequestSheet> createState() => _IblRequestSheetState();
}

class _IblRequestSheetState extends State<_IblRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _service = FailureService();
  final _purpose = TextEditingController();
  List<LabelValue> _lines = [];
  List<LabelValue> _trainSets = [];
  String? _line;
  String? _trainSet;
  DateTime? _from;
  DateTime? _to;
  bool _loading = true;
  bool _saving = false;
  bool _submitted = false; // show date errors only after Request is pressed

  static final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await _service.getIblLookups();
    if (!mounted) return;
    setState(() {
      _lines = r.lines;
      _trainSets = r.trainSets;
      _loading = false;
    });
  }

  String? _valueOf(List<LabelValue> list, String? label) =>
      list.firstWhereOrNull((e) => e.label == label)?.value;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk || _from == null || _to == null) return;
    if (_to!.isBefore(_from!)) {
      FailureToast.show(AppStrings.error, 'To date time cannot be before from date time.');
      return;
    }
    final yes = await Get.defaultDialog<bool>(
      title: 'Confirm',
      middleText: 'Do you want to create IBL Request?',
      textConfirm: 'Yes',
      textCancel: 'No',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.orangeColor,
      onConfirm: () => Get.back(result: true),
      onCancel: () {},
    );
    if (yes != true) return;

    setState(() => _saving = true);
    try {
      final userId = await _service.getUserId();
      final msg = await _service.insertIblRequest({
        'NotificationId': widget.notificationId,
        'PurposeOfWork': _purpose.text.trim(),
        'IBLLine': _valueOf(_lines, _line),
        'TrainSetId': _valueOf(_trainSets, _trainSet),
        'FromDateTime': _fmt.format(_from!),
        'ToDateTime': _fmt.format(_to!),
        'ExtentionDateTime': '',
        'IsCorr_Prev_Request': 1,
        'CreatedBy': userId,
      });
      if (msg == 'Success') {
        FailureToast.show(AppStrings.success, 'IBL Request Created Successfully.');
        if (mounted) Navigator.pop(context, true);
      } else if (msg == 'Line Busy') {
        FailureToast.show(AppStrings.error, 'IBL request already created for this line.');
      } else {
        FailureToast.show(AppStrings.error, 'Error in saved data');
      }
    } catch (e) {
      FailureToast.show(AppStrings.error,
          'Could not send the IBL request. Check the internet and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _error(String text) => Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text(text, style: const TextStyle(color: AppColors.red, fontSize: 12)),
      );

  @override
  Widget build(BuildContext context) {
    final gap = const SizedBox(height: AppConstants.elementSpacing);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustText.sectionHeader('IBL process request'),
                    gap,
                    CustomTextField(
                      label: 'Purpose of Work *',
                      controller: _purpose,
                      hintText: 'Purpose of Work',
                      maxLines: 3,
                      maxLength: 500,
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Please enter purpose of work' : null,
                    ),
                    gap,
                    CustDropdown(
                      label: 'IBL Line No *',
                      hint: 'Select',
                      items: [for (final e in _lines) e.label ?? ''],
                      selectedValue: _line,
                      onChanged: (v) => setState(() => _line = v),
                      validator: (v) => (v ?? '').isEmpty ? 'Please select IBL Line No' : null,
                    ),
                    gap,
                    CustDropdown(
                      label: 'Trainset *',
                      hint: 'Select',
                      items: [for (final e in _trainSets) e.label ?? ''],
                      selectedValue: _trainSet,
                      onChanged: (v) => setState(() => _trainSet = v),
                      validator: (v) => (v ?? '').isEmpty ? 'Please select Train set' : null,
                    ),
                    gap,
                    CustDateTimePicker(
                      label: 'From Date Time *',
                      hint: 'DD/MM/YYYY hh:mm',
                      selectedDateTime: _from,
                      use24Hour: true,
                      firstDate: DateTime.now(),
                      onDateTimeSelected: (d) => setState(() {
                        _from = d;
                        // The web clears the to date when from changes.
                        _to = null;
                      }),
                    ),
                    if (_submitted && _from == null) _error('Please select from date and time'),
                    gap,
                    CustDateTimePicker(
                      label: 'To Date Time *',
                      hint: 'DD/MM/YYYY hh:mm',
                      selectedDateTime: _to,
                      use24Hour: true,
                      firstDate: _from ?? DateTime.now(),
                      onDateTimeSelected: (d) => setState(() => _to = d),
                    ),
                    if (_submitted && _to == null) _error('Please select to date and time'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orangeColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Request',
                                style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
      ),
    );
  }
}
