import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../constants/colors.dart';
import '../../constants/app_constants.dart';
import 'cust_button.dart';
import 'cust_text.dart';

class CustPopup extends StatelessWidget {
  final String? title;
  final String? message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Widget? customContent;
  final bool showIcon;
  final IconData? icon;
  final Color? iconColor;

  const CustPopup({
    Key? key,
    this.title,
    this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.customContent,
    this.showIcon = true,
    this.icon = Icons.cloud_upload_outlined,
    this.iconColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDarkSecondary,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => onCancel?.call(),
                child: const Icon(TablerIcons.x, color: AppColors.textDarkPrimary, size: 24),
              ),
            ),
            if (showIcon) ...[
              const SizedBox(height: 16),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(icon ?? Icons.cloud_upload_outlined, color: iconColor ?? AppColors.black, size: 25),
                ),
              ),
              const SizedBox(height: 15),
            ],
            if (customContent != null)
              customContent!
            else ...[
              if (title != null && title!.isNotEmpty) ...[
                CustText(name: title!, textAlign:TextAlign.center, size: AppConstants.headerSize,color: AppColors.black,fontWeightName: FontWeight.w600),
                const SizedBox(height: 12),
              ],
              if (message != null && message!.isNotEmpty) ...[
                CustText(name: message!, textAlign:TextAlign.center,size: AppConstants.formLabelSize),
                 const SizedBox(height: 24),
              ],
            ],
            SizedBox(height: AppConstants.elementSpacing,),
            if (onConfirm != null || onCancel != null || confirmText != null || cancelText != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (cancelText != null) ...[
                    if (confirmText != null)
                      Expanded(
                        child: CustOutlineButton(
                          name: cancelText!,
                          size: double.infinity,
                          sHeight: 35,
                          onSelected: (_) {
                            onCancel?.call();
                          },
                        ),
                      )
                    else
                      CustOutlineButton(
                        name: cancelText!,
                        size: 150,
                        sHeight: 35,
                        onSelected: (_) {
                          onCancel?.call();
                        },
                      ),
                  ],
                  if (cancelText != null && confirmText != null)
                    const SizedBox(width: 12),
                  if (confirmText != null) ...[
                    if (cancelText != null)
                      Expanded(
                        child: CustButton(
                          name: confirmText!,
                          size: double.infinity,
                          sHeight: 35,
                          onSelected: (_) {
                            onConfirm?.call();
                          },
                        ),
                      )
                    else
                      CustButton(
                        name: confirmText!,
                        size: 150,
                        sHeight: 35,
                        onSelected: (_) {
                          onConfirm?.call();
                        },
                      ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

