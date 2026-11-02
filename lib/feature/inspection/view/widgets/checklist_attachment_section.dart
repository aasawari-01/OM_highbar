import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../../../constants/app_constants.dart';
import '../../../../utils/widgets/cust_button.dart';
import '../../../../utils/widgets/cust_text.dart';
import '../../model/checklist_attachment.dart';

/// Attachment block of the checklist: already-uploaded files plus one new file.
class ChecklistAttachmentSection extends StatelessWidget {
  final bool isViewMode;
  final List<ChecklistAttachment> existingAttachments;
  final File? newAttachment;
  final VoidCallback onAdd;
  final ValueChanged<ChecklistAttachment> onRemoveExisting;
  final VoidCallback onRemoveNew;

  const ChecklistAttachmentSection({
    super.key,
    required this.isViewMode,
    required this.existingAttachments,
    required this.newAttachment,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    final file = newAttachment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: 'Attachment (Only PNG, JPEG, JPG – max 1MB)',
          size: AppConstants.detailLabelSize,
          color: AppColors.textDarkSecondary,
        ),
        const SizedBox(height: AppConstants.labelSpacing),
        if (!isViewMode)
          CustButton(
            name: 'Add File',
            size: 100,
            sHeight: 36,
            fontSize: 14,
            onSelected: (_) => onAdd(),
          ),
        for (final att in existingAttachments) ...[
          const SizedBox(height: AppConstants.labelSpacing),
          _ExistingAttachmentTile(
            att: att,
            isViewMode: isViewMode,
            onRemove: () => onRemoveExisting(att),
          ),
        ],
        if (file != null) ...[
          const SizedBox(height: AppConstants.labelSpacing),
          _attachmentRow(
            context,
            thumbnail:
                Image.file(file, width: 48, height: 48, fit: BoxFit.cover),
            name: file.path.split(RegExp(r'[\\/]')).last,
            image: FileImage(file),
            onRemove: isViewMode ? null : onRemoveNew,
          ),
        ],
      ],
    );
  }
}

class _ExistingAttachmentTile extends StatelessWidget {
  final ChecklistAttachment att;
  final bool isViewMode;
  final VoidCallback onRemove;

  const _ExistingAttachmentTile({
    required this.att,
    required this.isViewMode,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final canPreview = att.canPreview;
    final url = att.url;

    return _attachmentRow(
      context,
      thumbnail: canPreview
          ? Image.network(
              url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(TablerIcons.photo, size: 32),
            )
          : null,
      name: att.name,
      image: canPreview ? NetworkImage(url) : null,
      onRemove: isViewMode ? null : onRemove,
    );
  }
}

/// One attachment line: optional thumbnail, file name, optional remove icon.
/// Tapping the thumbnail or name previews [image] when it is not null.
Widget _attachmentRow(
  BuildContext context, {
  required Widget? thumbnail,
  required String name,
  required ImageProvider? image,
  required VoidCallback? onRemove,
}) {
  void preview() => _previewImage(context, image!, name);
  return Row(children: [
    if (thumbnail != null)
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: image == null ? null : preview,
          child: ClipRRect(
              borderRadius: BorderRadius.circular(6), child: thumbnail),
        ),
      ),
    Expanded(
      child: GestureDetector(
        onTap: image == null ? null : preview,
        child: CustText(name: name, size: AppConstants.detailValueSize),
      ),
    ),
    if (onRemove != null)
      GestureDetector(
          onTap: onRemove, child: const Icon(TablerIcons.x, size: 18)),
  ]);
}

void _previewImage(BuildContext context, ImageProvider image, String title) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: AppColors.white1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(
                child: CustText(
                  name: title,
                  size: AppConstants.formLabelSize,
                  fontWeightName: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const Icon(TablerIcons.x, size: 24),
              ),
            ]),
            const SizedBox(height: AppConstants.elementSpacing),
            Flexible(
              child: InteractiveViewer(
                child: Image(
                  image: image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Unable to load image'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
