import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:om_mobile/constants/colors.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/custom_app_bar.dart';

class InstructionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> instruction;

  const InstructionDetailsScreen({
    Key? key,
    required this.instruction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final acknowledgements = [
      {
        'name': 'SC - Electrical',
        'status': 'Acknowledged',
        'remark':
        'Instruction received. Team has been informed and action initiated.',
        'date': '27 Aug 2026',
        'time': '10:48 AM',
      },
      {
        'name': 'SC - AFC',
        'status': 'Acknowledged',
        'remark':
        'AFC team has checked the equipment. Further inspection is in progress.',
        'date': '27 Aug 2026',
        'time': '11:02 AM',
      },
      {
        'name': 'SC - Operations',
        'status': 'Pending',
        'remark': '',
        'date': '-',
        'time': '-',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'Instruction Details',
        showDrawer: false,
        onLeadingPressed: () =>
            Navigator.pop(context),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            AppConstants.screenPadding,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildInstructionHeader(),

              const SizedBox(height: 16),

              _buildBasicDetails(),

              const SizedBox(height: 16),

              _buildLocationSection(),

              const SizedBox(height: 16),

              _buildDescriptionSection(),

              const SizedBox(height: 16),

              _buildAttachmentsSection(),

              const SizedBox(height: 20),

              _buildAcknowledgementSection(
                acknowledgements,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------

  Widget _buildInstructionHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              TablerIcons.file_text,
              color: Colors.blue,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                CustText(
                  name: instruction['subject'] ?? '',
                  size: 16,
                  color: Colors.black87,

                  maxLines: 2,
                ),
                const SizedBox(height: 5),
                CustText(
                  name: instruction['id'] ?? '',
                  size: 11,
                  color:
                  AppColors.textMutedLight,
                ),
              ],
            ),
          ),
          _buildInstructionTypeBadge(
            instruction['instructionType'] ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionTypeBadge(
      String value,
      ) {
    Color color;

    switch (value) {
      case 'Emergency':
        color = Colors.red;
        break;
      case 'Technical':
        color = Colors.orange.shade800;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Basic details
  // -------------------------------------------------------------------

  Widget _buildBasicDetails() {
    return _sectionContainer(
      title: 'Instruction Information',
      icon: TablerIcons.info_circle,
      child: Column(
        children: [
          _detailRow(
            'Sent By',
            instruction['sentBy'] ?? 'OCC',
          ),
          _detailRow(
            'Date',
            instruction['date'] ?? '-',
          ),
          _detailRow(
            'Time',
            instruction['time'] ?? '-',
          ),
          _detailRow(
            'Status',
            instruction['status'] ?? '-',
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Location
  // -------------------------------------------------------------------

  Widget _buildLocationSection() {
    final lines =
        (instruction['lines'] as List?) ?? [];

    final stations =
        (instruction['stations'] as List?) ?? [];

    return _sectionContainer(
      title: 'Location',
      icon: TablerIcons.map_pin,
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildTagGroup(
            title: 'Lines',
            values: lines,
            icon: TablerIcons.route,
          ),
          const SizedBox(height: 14),
          _buildTagGroup(
            title: 'Stations',
            values: stations,
            icon: TablerIcons.map_pin,
          ),
        ],
      ),
    );
  }

  Widget _buildTagGroup({
    required String title,
    required List values,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: AppColors.textMutedLight,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: values.map(
                (value) {
              return Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Description
  // -------------------------------------------------------------------

  Widget _buildDescriptionSection() {
    return _sectionContainer(
      title: 'Description',
      icon: TablerIcons.align_left,
      child: Text(
        instruction['description'] ?? '',
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Attachments
  // -------------------------------------------------------------------

  Widget _buildAttachmentsSection() {
    final files = [
      'inspection_report.pdf',
      'equipment_photo.jpg',
      'maintenance_note.docx',
    ];

    return _sectionContainer(
      title: 'Attachments',
      icon: TablerIcons.paperclip,
      child: Column(
        children: files.map(
              (file) {
            return Container(
              margin:
              const EdgeInsets.only(
                bottom: 8,
              ),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                BorderRadius.circular(11),
                border: Border.all(
                  color:
                  Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.blue
                          .withOpacity(
                        0.08,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        9,
                      ),
                    ),
                    child: const Icon(
                      TablerIcons.file,
                      size: 17,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      file,
                      style:
                      const TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    TablerIcons.eye,
                    size: 17,
                    color:
                    AppColors
                        .textMutedLight,
                  ),
                ],
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Acknowledgements
  // -------------------------------------------------------------------

  Widget _buildAcknowledgementSection(
      List<Map<String, dynamic>>
      acknowledgements,
      ) {
    return _sectionContainer(
      title:
      'Acknowledgements (${acknowledgements.length})',
      icon: TablerIcons.users,
      child: Column(
        children: List.generate(
          acknowledgements.length,
              (index) {
            final ack =
            acknowledgements[index];

            return _buildAcknowledgementCard(
              ack,
              isLast:
              index ==
                  acknowledgements.length -
                      1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildAcknowledgementCard(
      Map<String, dynamic> ack, {
        required bool isLast,
      }) {
    final bool acknowledged =
        ack['status'] ==
            'Acknowledged';

    final Color statusColor =
    acknowledged
        ? Colors.green
        : Colors.orange.shade700;

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                statusColor
                    .withOpacity(0.10),
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
                height: 70,
                color: Colors.grey.shade300,
              ),
          ],
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Container(
            margin:
            const EdgeInsets.only(
              bottom: 13,
            ),
            padding:
            const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
              BorderRadius.circular(13),
              border: Border.all(
                color:
                Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ack['name'] ?? '',
                        style:
                        const TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration:
                      BoxDecoration(
                        color: statusColor
                            .withOpacity(
                          0.10,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                      ),
                      child: Text(
                        ack['status'] ?? '',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                if ((ack['remark'] ?? '')
                    .toString()
                    .isNotEmpty)
                  Text(
                    ack['remark'] ?? '',
                    style:
                    const TextStyle(
                      fontSize: 11,
                      color:
                      Colors.black54,
                      height: 1.4,
                    ),
                  )
                else
                  const Text(
                    'No acknowledgement remark added.',
                    style:
                    TextStyle(
                      fontSize: 11,
                      color:
                      Colors.black38,
                      fontStyle:
                      FontStyle.italic,
                    ),
                  ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      TablerIcons.clock,
                      size: 13,
                      color: Colors.black38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ack['date']} • ${ack['time']}',
                      style:
                      const TextStyle(
                        fontSize: 9,
                        color:
                        Colors.black45,
                      ),
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
  // Common section container
  // -------------------------------------------------------------------

  Widget _sectionContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors
                      .appBarColor
                      .withOpacity(0.10),
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color:
                  AppColors.textMutedLight,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}