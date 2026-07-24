import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:om_mobile/constants/colors.dart';
import '../../utils/responsive_helper.dart';
import 'cust_text.dart';

class FileUploadSection extends StatefulWidget {
  final List<File> files;
  final Function(List<File>) onFilesChanged;

  const FileUploadSection({
    Key? key,
    required this.files,
    required this.onFilesChanged,
  }) : super(key: key);

  @override
  State<FileUploadSection> createState() => _FileUploadSectionState();
}

class _FileUploadSectionState extends State<FileUploadSection> {
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        List<File> newFiles = result.paths.map((path) => File(path!)).toList();
        widget.onFilesChanged([...widget.files, ...newFiles]);
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }

  void _removeFile(int index) {
    List<File> updatedFiles = List.from(widget.files);
    updatedFiles.removeAt(index);
    widget.onFilesChanged(updatedFiles);
  }

  String _getFileSize(File file) {
    int bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: GestureDetector(
              onTap: _pickFiles,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: DashedBorderPainter(
                      color: Colors.black,
                      strokeWidth: 1.0,
                      dashWidth: 5.0,
                      dashSpace: 5.0,
                    ),
                  ),
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.textDarkTertiary),
                        const SizedBox(height: 8),
                        CustText(
                          name: 'Choose file to upload',
                          size: 18,
                          fontWeightName: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.files.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.spacing(context, 15)),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.spacing(context, 15),
              horizontal: ResponsiveHelper.width(context, 16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(
                  name: '${widget.files.length} Files',
                  size: 22,
                ),
                SizedBox(height: ResponsiveHelper.spacing(context, 8)),
                ...widget.files.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return _buildFileListItem(
                    file.path.split('/').last,
                    _getFileSize(file),
                    () => _removeFile(index),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileListItem(String fileName, String fileSize, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.dividerColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Container(
            height: ResponsiveHelper.fontSize(context, 20),
            width: ResponsiveHelper.fontSize(context,20),
            decoration: BoxDecoration(
              color: AppColors.containerColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(
                  name: fileName,
                  size: 17,
                  fontWeightName: FontWeight.w500,
                  color: Colors.black,
                ),
                CustText(
                  name: fileSize,
                  size: 14,
                  color: Colors.black,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;


    final dashPath = Path();
    final dashCount = (size.width / (dashWidth + dashSpace)).floor();
    final dashCountVertical = (size.height / (dashWidth + dashSpace)).floor();

    // Draw horizontal dashes
    for (int i = 0; i < dashCount; i++) {
      final startX = i * (dashWidth + dashSpace);
      dashPath.moveTo(startX, 0);
      dashPath.lineTo(startX + dashWidth, 0);
    }

    // Draw vertical dashes
    for (int i = 0; i < dashCountVertical; i++) {
      final startY = i * (dashWidth + dashSpace);
      dashPath.moveTo(size.width, startY);
      dashPath.lineTo(size.width, startY + dashWidth);
    }

    // Draw bottom horizontal dashes
    for (int i = 0; i < dashCount; i++) {
      final startX = i * (dashWidth + dashSpace);
      dashPath.moveTo(startX, size.height);
      dashPath.lineTo(startX + dashWidth, size.height);
    }

    // Draw left vertical dashes
    for (int i = 0; i < dashCountVertical; i++) {
      final startY = i * (dashWidth + dashSpace);
      dashPath.moveTo(0, startY);
      dashPath.lineTo(0, startY + dashWidth);
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 