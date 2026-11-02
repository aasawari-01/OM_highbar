import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Result of [pickInspectionImage]: a [file], an [error] message, or neither when cancelled.
class PickedImage {
  final File? file;
  final String? error;

  const PickedImage({this.file, this.error});
}

const int maxInspectionImageBytes = 1024 * 1024;

/// Lets the user pick one PNG/JPG/JPEG of at most 1MB (the inspection attachment rule).
Future<PickedImage> pickInspectionImage() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
    );
    final path = result?.files.single.path;
    if (path == null) return const PickedImage();
    final file = File(path);
    if (file.lengthSync() > maxInspectionImageBytes) {
      return const PickedImage(error: 'File size must be 1MB or less');
    }
    return PickedImage(file: file);
  } catch (e) {
    debugPrint('Error picking attachment: $e');
    return const PickedImage();
  }
}
