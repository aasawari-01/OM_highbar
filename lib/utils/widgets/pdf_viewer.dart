import 'package:flutter/material.dart';
import 'package:internet_file/internet_file.dart';
import 'package:pdfx/pdfx.dart';

import 'custom_app_bar.dart';

class PdfAttachmentViewer extends StatefulWidget {
  const PdfAttachmentViewer({
    required this.fileUrl,
    required this.fileName,
  });

  final String fileUrl;
  final String fileName;

  @override
  State<PdfAttachmentViewer> createState() =>
      PdfAttachmentViewerState();
}

class PdfAttachmentViewerState
    extends State<PdfAttachmentViewer> {

  late final PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();

    _pdfController = PdfControllerPinch(
      document: PdfDocument.openData(
        InternetFile.get(widget.fileUrl),
      ),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: widget.fileName.isEmpty
            ? 'PDF'
            : widget.fileName,
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: PdfViewPinch(
        controller: _pdfController,
      ),
    );
  }
}