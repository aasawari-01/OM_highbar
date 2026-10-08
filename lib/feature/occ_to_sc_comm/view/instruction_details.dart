import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:om_mobile/constants/colors.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';

import '../../../utils/widgets/pdf_viewer.dart';
import '../controller/occ_instruction_details_controller.dart';
import '../model/occ_instruction_detail_model.dart';

class InstructionDetailsScreen extends StatefulWidget {
  const InstructionDetailsScreen({
    Key? key,
    required this.instructionId,
    required this.isOcc,
    this.stationId = 0,
  }) : super(key: key);

  final int instructionId;
  final bool isOcc;
  final int stationId;

  @override
  State<InstructionDetailsScreen> createState() => _InstructionDetailsScreenState();
}

class _InstructionDetailsScreenState extends State<InstructionDetailsScreen> {
  // Created once in initState — previously this was done in build(),
  // which meant every rebuild wiped the controller, re-fetched the
  // details from the API, and discarded any remark the user had typed.
  late final InstructionDetailsController controller;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<InstructionDetailsController>()) {
      Get.delete<InstructionDetailsController>(force: true);
    }

    controller = Get.put(
      InstructionDetailsController(
        instructionId: widget.instructionId,
        isOcc: widget.isOcc,
        stationId: widget.stationId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'View Instruction Details',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color:  Color(0xFFF5F6F8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final instruction = controller.instruction.value;

          if (instruction == null) {
            return const Center(
              child: CustText(
                name: 'Unable to load instruction details.',
                size: 12,
                color: Colors.black45,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionHeader(instruction),
                const SizedBox(height: 16),
                _buildBasicDetails(instruction),
                const SizedBox(height: 16),
                _buildLocationSection(instruction),
                if (instruction.technicalSystems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildTechnicalDetailsSection(instruction),
                ],
                const SizedBox(height: 16),
                _buildDescriptionSection(instruction),
                const SizedBox(height: 16),
                _buildAttachmentsSection(instruction),
                const SizedBox(height: 16),
                if (widget.isOcc) _buildAcknowledgementSection(instruction),
                if (controller.canAcknowledge) ...[
                  const SizedBox(height: 16),
                  _buildAcknowledgeAction(controller, instruction),
                ],
                const SizedBox(height: 30),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAcknowledgeAction(
      InstructionDetailsController controller,
      OccInstructionDetail instruction,
      ) {
    final bool alreadyAcknowledged = instruction.isAcknowledgedByCurrentUser == true;

    if (alreadyAcknowledged) {
      return _sectionContainer(
        title: 'Your Acknowledgement',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(TablerIcons.check, size: 15, color: Colors.green),
                const SizedBox(width: 6),
                CustText(
                  name: instruction.myAcknowledgementDateTime == null
                      ? 'Acknowledged'
                      : 'Acknowledged on ${DateFormat('dd MMM yyyy, hh:mm a').format(instruction.myAcknowledgementDateTime!)}',
                  size: 11,
                  fontWeightName: FontWeight.w600,
                  color: Colors.black87,
                ),
              ],
            ),
            if ((instruction.myAcknowledgementRemark ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              CustText(
                name: instruction.myAcknowledgementRemark!,
                size: 11,
                color: Colors.black54,
              ),
            ],
          ],
        ),
      );
    }

    return _sectionContainer(
      title: 'Acknowledge Instruction',
      child: Obx(
            () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // TextField(
            //   controller: controller.remarkController,
            //   maxLines: 3,
            //   style: const TextStyle(fontSize: 12),
            //   decoration: InputDecoration(
            //     hintText: 'Add a remark before acknowledging',
            //     hintStyle: const TextStyle(fontSize: 11, color: Colors.black38),
            //     contentPadding: const EdgeInsets.all(11),
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(11),
            //       borderSide: BorderSide(color: Colors.grey.shade300),
            //     ),
            //   ),
            // ),
            CustomTextField(
              label: "Remark ",
              controller: controller.remarkController,
              hintText: "Add a remark before acknowledging",
              maxLines: 3,

            ),
            const SizedBox(height: 14),
            Row(
              children: [


                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: controller.isSubmittingAcknowledgement.value
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const CustText(
                        name: 'Cancel',
                        size: 13,
                        fontWeightName: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: controller.isSubmittingAcknowledgement.value
                          ? null
                          : controller.acknowledgeInstruction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangeColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: controller.isSubmittingAcknowledgement.value
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const CustText(
                        name: 'Acknowledgement',
                        size: 13,
                        fontWeightName: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------

  Widget _buildInstructionHeader(OccInstructionDetail instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: CustText(
        name: instruction.instructionNumber,
        size: 20,
        fontWeightName: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }

  // -------------------------------------------------------------------
  // Basic details
  // -------------------------------------------------------------------

  Widget _buildBasicDetails(OccInstructionDetail instruction) {
    return _sectionContainer(
      title: 'Instruction Information',
      child: Column(
        children: [
          _gridRow(
            'Instruction By',
            instruction.instructionByName.isEmpty ? '-' : instruction.instructionByName,
            'Instruction Type',
            instruction.instructionTypeName.isEmpty ? '-' : instruction.instructionTypeName,
          ),
          const SizedBox(height: 16),
          _gridRow(
            'Date',
            instruction.issueDate == null
                ? '-'
                : DateFormat('dd MMM yyyy').format(instruction.issueDate!),
            'Validity Upto',
            instruction.validityUpto == null
                ? '-'
                : DateFormat('dd MMM yyyy').format(instruction.validityUpto!),
          ),
          const SizedBox(height: 16),
          _gridRow(
            'Time',
            instruction.createdDateTime == null
                ? '-'
                : DateFormat('hh:mm a').format(instruction.createdDateTime!),
            'Status',
            instruction.instructionStatus.isEmpty ? '-' : instruction.instructionStatus,
          ),
          if ((instruction.emergencyTypeName ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [Expanded(child: _gridSingle('Emergency Type', instruction.emergencyTypeName!))],
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Location
  // -------------------------------------------------------------------

  Widget _buildLocationSection(OccInstructionDetail instruction) {
    final stations = instruction.stations;

    return _sectionContainer(
      title: 'Stations',
      child: stations.isEmpty
          ? const CustText(
        name: 'No station information available.',
        size: 11,
        color: Colors.black38,
      )
          : _buildStationTagGroup(stations),
    );
  }

  Widget _buildStationTagGroup(List<InstructionStation> stations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: stations.map((station) {
            final bool acknowledged = station.isAcknowledged == true;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustText(
                    name: station.stationName ??
                        (station.stationId != null ? 'Station #${station.stationId}' : '-'),
                    size: 13,
                    fontWeightName: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTechnicalDetailsSection(OccInstructionDetail instruction) {
    final Map<String, List<String>> grouped = {};

    for (final system in instruction.technicalSystems) {
      final String dept = (system.deptName?.isNotEmpty ?? false) ? system.deptName! : 'Department';

      grouped.putIfAbsent(dept, () => []);

      if ((system.systemName ?? '').isNotEmpty) {
        grouped[dept]!.add(system.systemName!);
      }
    }

    return _sectionContainer(
      title: 'Department and Systems',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTagGroup(title: entry.key, values: entry.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTagGroup({required String title, required List<String> values}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: title,
          size: 14,
          color: Colors.black45,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: values.map((value) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
              child: CustText(name: value, size: 13, fontWeightName: FontWeight.w500),
            );
          }).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Description
  // -------------------------------------------------------------------

  Widget _buildDescriptionSection(OccInstructionDetail instruction) {
    return _sectionContainer(
      title: 'Description',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText(
            name: instruction.instructionContent,
            size: 13,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Attachments
  // -------------------------------------------------------------------

  Widget _buildAttachmentsSection(OccInstructionDetail instruction) {
    final attachments = instruction.attachments;

    return _sectionContainer(
      title: 'Attachments (${attachments.length})',
      child: attachments.isEmpty
          ? const CustText(
        name: 'No attachments added.',
        size: 11,
        color: Colors.black38,
      )
          : Column(children: attachments.map((file) => _buildAttachmentTile(file)).toList()),
    );
  }

  Widget _buildAttachmentTile(InstructionAttachment file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          if (file.isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.network(
                file.fullUrl,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildAttachmentIcon(file),
              ),
            )
          else
            _buildAttachmentIcon(file),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(
                  name: file.fileName.isEmpty ? '-' : file.fileName,
                  size: 11,
                  fontWeightName: FontWeight.w500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                CustText(
                  name: _formatFileSize(file.fileSize),
                  size: 9,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _openAttachment(file),
            child: const Icon(TablerIcons.eye, size: 17, color: AppColors.textMutedLight),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentIcon(InstructionAttachment file) {
    IconData icon;
    Color color;

    if (file.isPdf) {
      icon = TablerIcons.file_text;
      color = Colors.red;
    } else if (file.isImage) {
      icon = TablerIcons.photo;
      color = Colors.blue;
    } else {
      icon = TablerIcons.file;
      color = Colors.blueGrey;
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 17, color: color),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Opens attachments in-app instead of handing off to an external
  // browser/app. Images get a native zoomable viewer; everything else
  // (PDF, Word, Excel, etc.) is rendered through Google's Docs Viewer
  // inside a WebView — this needs `fullUrl` to be publicly reachable.
  void _openAttachment(InstructionAttachment file) {
    if (file.isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ImageAttachmentViewer(
            imageUrl: file.fullUrl,
            fileName: file.fileName,
          ),
        ),
      );
    } else if (file.isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfAttachmentViewer(
            fileUrl: file.fullUrl,
            fileName: file.fileName,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _DocumentAttachmentViewer(
            fileUrl: file.fullUrl,
            fileName: file.fileName,
          ),
        ),
      );
    }
  }

  // -------------------------------------------------------------------
  // Acknowledgements
  // -------------------------------------------------------------------

  Widget _buildAcknowledgementSection(
      OccInstructionDetail instruction,
      ) {
    final acknowledgements = instruction.acknowledgements;

    return _sectionContainer(
      title: 'Acknowledgements (${acknowledgements.length})',
      child: acknowledgements.isEmpty
          ? const CustText(
        name: 'No acknowledgements yet.',
        size: 11,
        color: Colors.black38,
      )
          : Column(
        children: List.generate(
          acknowledgements.length,
              (index) => _buildAcknowledgementCard(
            acknowledgements[index],
            isLast: index == acknowledgements.length - 1,
          ),
        ),
      ),
    );
  }

  Widget _buildAcknowledgementCard(
      InstructionAcknowledgement ack, {
        required bool isLast,
      }) {
    final bool acknowledged = ack.acknowledgementStatus == true;

    final Color statusColor =
    acknowledged ? Colors.green : Colors.orange.shade700;

    final String userName =
    (ack.userName ?? '').trim().isEmpty
        ? 'Unknown User'
        : ack.userName!;

    final String stationName =
    (ack.stationName ?? '').trim().isEmpty
        ? (ack.stationId != null
        ? 'Station #${ack.stationId}'
        : 'Unknown Station')
        : ack.stationName!;

    final String date = ack.acknowledgementDateTime == null
        ? '-'
        : DateFormat(
      'dd MMM yyyy',
    ).format(ack.acknowledgementDateTime!);

    final String time = ack.acknowledgementDateTime == null
        ? '-'
        : DateFormat(
      'hh:mm a',
    ).format(ack.acknowledgementDateTime!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -------------------------------------------------------------
        // Timeline icon
        // -------------------------------------------------------------
        Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                acknowledged
                    ? TablerIcons.check
                    : TablerIcons.clock,
                size: 18,
                color: statusColor,
              ),
            ),

            if (!isLast)
              Container(
                width: 1,
                height: 105,
                color: Colors.grey.shade300,
              ),
          ],
        ),

        const SizedBox(width: 11),

        // -------------------------------------------------------------
        // Acknowledgement information
        // -------------------------------------------------------------
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 13),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -----------------------------------------------------
                // User
                // -----------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: CustText(
                        name: userName,
                        size: 12,
                        fontWeightName: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustText(
                        name: acknowledged
                            ? 'Acknowledged'
                            : 'Pending',
                        size: 9,
                        fontWeightName: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // -----------------------------------------------------
                // Station
                // -----------------------------------------------------
                Row(
                  children: [
                    const Icon(
                      TablerIcons.building,
                      size: 13,
                      color: Colors.black38,
                    ),
                    const SizedBox(width: 5),
                    CustText(
                      name: stationName,
                      size: 10,
                      color: Colors.black54,
                      fontWeightName: FontWeight.w500,
                    ),
                  ],
                ),

                // -----------------------------------------------------
                // Remark
                // -----------------------------------------------------
                if ((ack.acknowledgementRemark ?? '')
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 8),

                  CustText(
                    name: ack.acknowledgementRemark!,
                    size: 11,
                    color: Colors.black54,
                  ),
                ],

                const SizedBox(height: 8),

                // -----------------------------------------------------
                // Date / Time
                // -----------------------------------------------------
                Row(
                  children: [
                    const Icon(
                      TablerIcons.clock,
                      size: 13,
                      color: Colors.black38,
                    ),
                    const SizedBox(width: 4),
                    CustText(
                      name: '$date • $time',
                      size: 9,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Common section container (title + thin divider, no icon badge —
  // matches the flat card style from the reference UI)
  // -------------------------------------------------------------------

  Widget _sectionContainer({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        // border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustText(
            name: title,
            size: 15,
            fontWeightName: FontWeight.w700,
            color: Colors.black87,
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 1, color: AppColors.lightBlueColor),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Label-over-value grid pair (two per row), matching the reference UI
  // -------------------------------------------------------------------

  Widget _gridRow(String label1, String value1, String label2, String value2) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _gridSingle(label1, value1)),
        const SizedBox(width: 12),
        Expanded(child: _gridSingle(label2, value2)),
      ],
    );
  }

  Widget _gridSingle(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(name: label, size: 14, color: Colors.black45),
        const SizedBox(height: 4),
        CustText(
          name: value,
          size: 14,
          fontWeightName: FontWeight.w700,
          color: Colors.black87,
        ),
      ],
    );
  }
}

// =========================================================================
// In-app image viewer — full-screen, pinch-to-zoom, no external navigation.
// =========================================================================

class _ImageAttachmentViewer extends StatelessWidget {
  const _ImageAttachmentViewer({required this.imageUrl, required this.fileName});

  final String imageUrl;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: CustText(
          name: fileName.isEmpty ? 'Image' : fileName,
          size: 13,
          color: Colors.white,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (context, error, stackTrace) => const CustText(
              name: 'Unable to load image.',
              size: 12,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// In-app document viewer — PDFs, Word, Excel, etc. rendered through
// Google's Docs Viewer inside a WebView (needs a publicly reachable URL).
// =========================================================================

class _DocumentAttachmentViewer extends StatefulWidget {
  const _DocumentAttachmentViewer({required this.fileUrl, required this.fileName});

  final String fileUrl;
  final String fileName;

  @override
  State<_DocumentAttachmentViewer> createState() => _DocumentAttachmentViewerState();
}

class _DocumentAttachmentViewerState extends State<_DocumentAttachmentViewer> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final String viewerUrl =
        'https://docs.google.com/viewer?embedded=true&url=${Uri.encodeComponent(widget.fileUrl)}';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: widget.fileName.isEmpty ? 'Document' : widget.fileName,
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}