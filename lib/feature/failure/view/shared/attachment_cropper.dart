import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;

import '../../../../constants/colors.dart';
import '../../service/failure_log.dart';

/// Crop step of the failure attachments (camera photos and picked images).
/// Cropping is optional: when the user leaves the crop screen, or the file is
/// not an image (pdf, doc...), the original file is used as it is.
class AttachmentCropper {
  AttachmentCropper._();

  static const _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

  static bool isImage(String path) =>
      _imageExtensions.contains(p.extension(path).toLowerCase());

  /// Returns the path to attach: the cropped copy, or [path] when nothing was
  /// cropped.
  static Future<String> crop(String path) async {
    if (!isImage(path)) return path;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: path,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: AppColors.appBarColor,
            toolbarWidgetColor: AppColors.white1,
            activeControlsWidgetColor: AppColors.orangeColor,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Photo'),
        ],
      );
      return cropped?.path ?? path;
    } catch (e) {
      failureLog('AttachmentCropper: crop failed, using the original: $e');
      return path;
    }
  }
}
