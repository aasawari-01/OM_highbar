import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/widgets/cust_button.dart';
import '../../../../utils/widgets/cust_popup.dart';
import '../../../../utils/widgets/cust_text.dart';
import '../../../../utils/widgets/success_popup.dart';
import '../../model/checklist_rules.dart';

/// Confirmation popup, same look as the failure screens. Resolves to true when confirmed.
Future<bool> showInspectionConfirm(
  String title,
  String message, {
  String confirmText = 'Yes',
  String cancelText = 'No',
  IconData icon = Icons.warning_amber_outlined,
  Color iconColor = AppColors.orangeColor,
}) async {
  final result = await Get.dialog<bool>(
    CustPopup(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      iconColor: iconColor,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    ),
    barrierDismissible: false,
  );
  return result ?? false;
}

/// "Unsaved Changes" popup used when leaving a form. Resolves to true to leave.
Future<bool> showUnsavedChangesConfirm() => showInspectionConfirm(
      'Unsaved Changes',
      'Changes you made may not be saved. Do you want to continue?',
    );

/// Blocking error popup with a single OK button.
Future<void> showInspectionErrorPopup(String message,
    {String title = 'Error'}) {
  return showResultPopup(
    title: title,
    message: message,
    icon: Icons.cancel_outlined,
    iconColor: AppColors.red,
  );
}

/// Success popup, shown on top of the current screen.
Future<void> showInspectionSuccess(String message) =>
    showResultPopup(message: message);

/// Bottom snack bar, red for errors and green otherwise (same as the failure forms).
void showInspectionSnack(String message, {bool isError = true, String? title}) {
  Get.snackbar(
    title ?? (isError ? 'Error' : 'Success'),
    message,
    backgroundColor:
        (isError ? AppColors.red : AppColors.green).withValues(alpha: 0.9),
    colorText: AppColors.white1,
    snackPosition: SnackPosition.BOTTOM,
    duration: AppConstants.snackbarDuration,
  );
}

/// Outcome of the Not Okay review popup.
class ObservationReview {
  final bool addToObservation;
  final String remark;

  const ObservationReview(
      {required this.addToObservation, required this.remark});
}

/// "Not Okay - Review Item" popup. Resolves to null only if dismissed without a choice.
Future<ObservationReview?> showNotOkayReview({
  required List<MapEntry<String, String>> details,
  required String initialRemark,
}) {
  var remark = initialRemark;
  var showError = false;

  return Get.dialog<ObservationReview>(
    StatefulBuilder(
      builder: (ctx, setDialogState) {
        void close({required bool add}) => Get.back(
            result: ObservationReview(
                addToObservation: add, remark: remark.trim()));

        return CustPopup(
          showIcon: false,
          onCancel: () => close(add: false),
          customContent: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.65),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CustText(
                      name: 'Not Okay-Review Item',
                      size: AppConstants.headerSize,
                      color: AppColors.black,
                      fontWeightName: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.containerColor2,
                      borderRadius:
                          BorderRadius.circular(AppConstants.inputRadius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final d in details)
                          _DetailRow(label: d.key, value: d.value),
                        const SizedBox(height: AppConstants.subElementSpacing),
                        CustText.formLabel('Remark *'),
                        const SizedBox(height: AppConstants.labelSpacing),
                        TextFormField(
                          initialValue: remark,
                          maxLines: 4,
                          maxLength: remarkMaxLength,
                          keyboardType: TextInputType.multiline,
                          onChanged: (v) {
                            remark = v;
                            if (showError) {
                              setDialogState(() => showError = false);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter remark',
                            filled: true,
                            fillColor: AppColors.white1,
                            errorText: showError ? 'Remark is required' : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.inputRadius),
                              borderSide:
                                  BorderSide(color: AppColors.textFieldColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.elementSpacing),
                        CustText(
                          name: 'Do you want to add this item to Observations?',
                          size: AppConstants.formLabelSize,
                          fontWeightName: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        const SizedBox(height: 4),
                        CustText(
                          name:
                              'This will log it as an observation record for follow up and reporting.',
                          size: AppConstants.detailLabelSize,
                          color: AppColors.textDarkSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.elementSpacing),
                  Row(children: [
                    Expanded(
                      child: CustOutlineButton(
                        name: 'No, Skip',
                        size: double.infinity,
                        sHeight: 38,
                        onSelected: (_) => close(add: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CustButton(
                        name: 'Yes, Add to Observation',
                        size: double.infinity,
                        sHeight: 38,
                        fontSize: 14,
                        onSelected: (_) {
                          if (remark.trim().isEmpty) {
                            setDialogState(() => showError = true);
                            return;
                          }
                          close(add: true);
                        },
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    ),
    barrierDismissible: false,
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: CustText(
              name: label,
              size: AppConstants.detailLabelSize,
              color: AppColors.textDarkSecondary,
            ),
          ),
          Expanded(
              child: CustText(
                  name: value, size: 14, fontWeightName: FontWeight.bold)),
        ],
      ),
    );
  }
}
