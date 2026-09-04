// import 'package:flutter/material.dart';
// import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
//
// import 'package:om_mobile/constants/colors.dart';
//
// import '../../../constants/app_constants.dart';
// import '../../../utils/widgets/cust_text.dart';
// import '../../../utils/widgets/custom_app_bar.dart';
//
// import '../controller/occ_instruction_details_controller.dart';
// import '../model/occ_instruction_detail_model.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class InstructionDetailsScreen extends StatelessWidget {
//   const InstructionDetailsScreen({
//     Key? key,
//     required this.instructionId,
//     required this.isOcc,
//     this.stationId = 0,
//   }) : super(key: key);
//
//   final int instructionId;
//   final bool isOcc;
//   final int stationId;
//
//   @override
//   Widget build(BuildContext context) {
//     Get.delete<InstructionDetailsController>(force: true);
//     final InstructionDetailsController controller = Get.put(
//       InstructionDetailsController(
//         instructionId: instructionId,
//         isOcc: isOcc,
//         stationId: stationId,
//       ),
//     );
//
//     return Scaffold(
//       backgroundColor: AppColors.appBarColor,
//       appBar: CustomAppBar(
//         title: 'Instruction Details',
//         showDrawer: false,
//         onLeadingPressed: () => Navigator.pop(context),
//       ),
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           color: AppColors.white1,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//         ),
//         child: Obx(
//               () {
//             if (controller.isLoading.value) {
//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//             }
//
//             final instruction = controller.instruction.value;
//
//             if (instruction == null) {
//               return const Center(
//                 child: CustText(
//                   name: 'Unable to load instruction details.',
//                   size: 12,
//                   color: Colors.black45,
//                 ),
//               );
//             }
//
//             return SingleChildScrollView(
//               padding: const EdgeInsets.all(
//                 AppConstants.screenPadding,
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildInstructionHeader(instruction),
//                   const SizedBox(height: 16),
//                   _buildBasicDetails(instruction),
//                   const SizedBox(height: 16),
//                   _buildLocationSection(instruction),
//                   if (instruction.technicalSystems.isNotEmpty) ...[
//                     const SizedBox(height: 16),
//                     _buildTechnicalDetailsSection(instruction),
//                   ],
//                   const SizedBox(height: 16),
//                   _buildDescriptionSection(instruction),
//                   const SizedBox(height: 16),
//                   _buildAttachmentsSection(instruction),
//                   const SizedBox(height: 20),
//                   isOcc?_buildAcknowledgementSection(instruction):Container(),
//                   if (controller.canAcknowledge) ...[
//                     const SizedBox(height: 16),
//                     _buildAcknowledgeAction(controller, instruction),
//                   ],
//                   const SizedBox(height: 30),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//
//
//   Widget _buildAcknowledgeAction(
//       InstructionDetailsController controller,
//       OccInstructionDetail instruction,
//       ) {
//     final bool alreadyAcknowledged =
//         instruction.isAcknowledgedByCurrentUser == true;
//
//     if (alreadyAcknowledged) {
//       return _sectionContainer(
//         title: 'Your Acknowledgement',
//         icon: TablerIcons.circle_check,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(TablerIcons.check, size: 15, color: Colors.green),
//                 const SizedBox(width: 6),
//                 Text(
//                   instruction.myAcknowledgementDateTime == null
//                       ? 'Acknowledged'
//                       : 'Acknowledged on ${DateFormat('dd MMM yyyy, hh:mm a').format(instruction.myAcknowledgementDateTime!)}',
//                   style: const TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ],
//             ),
//             if ((instruction.myAcknowledgementRemark ?? '').isNotEmpty) ...[
//               const SizedBox(height: 8),
//               Text(
//                 instruction.myAcknowledgementRemark!,
//                 style: const TextStyle(
//                   fontSize: 11,
//                   color: Colors.black54,
//                   height: 1.4,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       );
//     }
//
//     return _sectionContainer(
//       title: 'Acknowledge Instruction',
//       icon: TablerIcons.circle_check,
//       child: Obx(
//             () => Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: controller.remarkController,
//               maxLines: 3,
//               style: const TextStyle(fontSize: 12),
//               decoration: InputDecoration(
//                 hintText: 'Add a remark before acknowledging',
//                 hintStyle: const TextStyle(fontSize: 11, color: Colors.black38),
//                 contentPadding: const EdgeInsets.all(11),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(11),
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: controller.isSubmittingAcknowledgement.value
//                     ? null
//                     : controller.acknowledgeInstruction,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.appBarColor,
//                   padding: const EdgeInsets.symmetric(vertical: 13),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: controller.isSubmittingAcknowledgement.value
//                     ? const SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//                     : const Text(
//                   'Acknowledge',
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------
//   // Header
//   // -------------------------------------------------------------------
//
//   Widget _buildInstructionHeader(OccInstructionDetail instruction) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(17),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.035),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: Colors.blue.withOpacity(0.10),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: const Icon(
//               TablerIcons.file_text,
//               color: Colors.blue,
//               size: 23,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CustText(
//                   name: instruction.instructionNumber,
//                   size: 16,
//                   color: Colors.black87,
//                   maxLines: 2,
//                 ),
//                 const SizedBox(height: 5),
//                 CustText(
//                   name: instruction.issueDate == null
//                       ? '-'
//                       : DateFormat('dd MMM yyyy')
//                       .format(instruction.issueDate!),
//                   size: 11,
//                   color: AppColors.textMutedLight,
//                 ),
//               ],
//             ),
//           ),
//           _buildInstructionTypeBadge(instruction.instructionTypeName),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInstructionTypeBadge(String value) {
//     Color color;
//
//     switch (value) {
//       case 'Emergency':
//         color = Colors.red;
//         break;
//       case 'Technical':
//         color = Colors.orange.shade800;
//         break;
//       default:
//         color = Colors.blue;
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.10),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         value.isEmpty ? '-' : value,
//         style: TextStyle(
//           fontSize: 10,
//           fontWeight: FontWeight.w700,
//           color: color,
//         ),
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------
//   // Basic details
//   // -------------------------------------------------------------------
//
//   Widget _buildBasicDetails(OccInstructionDetail instruction) {
//     return _sectionContainer(
//       title: 'Instruction Information',
//       icon: TablerIcons.info_circle,
//       child: Column(
//         children: [
//           _detailRow(
//             'Sent By',
//             instruction.instructionByName.isEmpty
//                 ? '-'
//                 : instruction.instructionByName,
//           ),
//           _detailRow(
//             'Date',
//             instruction.issueDate == null
//                 ? '-'
//                 : DateFormat('dd MMM yyyy').format(instruction.issueDate!),
//           ),
//           _detailRow(
//             'Valid Upto',
//             instruction.validityUpto == null
//                 ? '-'
//                 : DateFormat('dd MMM yyyy')
//                 .format(instruction.validityUpto!),
//           ),
//           _detailRow(
//             'Time',
//             instruction.createdDateTime == null
//                 ? '-'
//                 : DateFormat('hh:mm a').format(instruction.createdDateTime!),
//           ),
//           _detailRow(
//             'Status',
//             instruction.instructionStatus.isEmpty
//                 ? '-'
//                 : instruction.instructionStatus,
//           ),
//           if ((instruction.emergencyTypeName ?? '').isNotEmpty)
//             _detailRow('Emergency Type', instruction.emergencyTypeName!),
//         ],
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------
//   // Location
//   // -------------------------------------------------------------------
//
//   Widget _buildLocationSection(OccInstructionDetail instruction) {
//     final stations = instruction.stations;
//
//     return _sectionContainer(
//       title: 'Location',
//       icon: TablerIcons.map_pin,
//       child: stations.isEmpty
//           ? const Text(
//         'No station information available.',
//         style: TextStyle(
//           fontSize: 11,
//           color: Colors.black38,
//           fontStyle: FontStyle.italic,
//         ),
//       )
//           : _buildStationTagGroup(stations),
//     );
//   }
//
//   Widget _buildStationTagGroup(List<InstructionStation> stations) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(TablerIcons.map_pin, size: 15, color: AppColors.textMutedLight),
//             const SizedBox(width: 6),
//             const Text(
//               'Stations',
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black54,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Wrap(
//           spacing: 7,
//           runSpacing: 7,
//           children: stations.map((station) {
//             final bool acknowledged = station.isAcknowledged == true;
//
//             return Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//               decoration: BoxDecoration(
//                 color: acknowledged
//                     ? Colors.green.withOpacity(0.08)
//                     : Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(10),
//                 border: acknowledged
//                     ? Border.all(color: Colors.green.withOpacity(0.3))
//                     : null,
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (acknowledged)
//                     const Padding(
//                       padding: EdgeInsets.only(right: 5),
//                       child: Icon(TablerIcons.check, size: 12, color: Colors.green),
//                     ),
//                   Text(
//                     station.stationName ??
//                         (station.stationId != null
//                             ? 'Station #${station.stationId}'
//                             : '-'),
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w500,
//                       color: acknowledged ? Colors.green.shade800 : Colors.black87,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTechnicalDetailsSection(OccInstructionDetail instruction) {
//     final Map<String, List<String>> grouped = {};
//
//     for (final system in instruction.technicalSystems) {
//       final String dept = (system.deptName?.isNotEmpty ?? false)
//           ? system.deptName!
//           : 'Department';
//
//       grouped.putIfAbsent(dept, () => []);
//
//       if ((system.systemName ?? '').isNotEmpty) {
//         grouped[dept]!.add(system.systemName!);
//       }
//     }
//
//     return _sectionContainer(
//       title: 'Technical Details',
//       icon: TablerIcons.settings,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: grouped.entries.map((entry) {
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 12),
//             child: _buildTagGroup(
//               title: entry.key,
//               values: entry.value,
//               icon: TablerIcons.building,
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _buildTagGroup({
//     required String title,
//     required List<String> values,
//     required IconData icon,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, size: 15, color: AppColors.textMutedLight),
//             const SizedBox(width: 6),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black54,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Wrap(
//           spacing: 7,
//           runSpacing: 7,
//           children: values.map((value) {
//             return Container(
//               padding:
//               const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Text(
//                 value,
//                 style:
//                 const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }
//
//   // -------------------------------------------------------------------
//   // Description
//   // -------------------------------------------------------------------
//
//   Widget _buildDescriptionSection(OccInstructionDetail instruction) {
//     return _sectionContainer(
//       title: 'Description',
//       icon: TablerIcons.align_left,
//       child: Text(
//         instruction.instructionContent,
//         style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------
//   // Attachments
//   // -------------------------------------------------------------------
//
//   Widget _buildAttachmentsSection(OccInstructionDetail instruction) {
//     final attachments = instruction.attachments;
//
//     return _sectionContainer(
//       title: 'Attachments (${attachments.length})',
//       icon: TablerIcons.paperclip,
//       child: attachments.isEmpty
//           ? const Text(
//         'No attachments added.',
//         style: TextStyle(
//           fontSize: 11,
//           color: Colors.black38,
//           fontStyle: FontStyle.italic,
//         ),
//       )
//           : Column(
//         children:
//         attachments.map((file) => _buildAttachmentTile(file)).toList(),
//       ),
//     );
//   }
//
//   Widget _buildAttachmentTile(InstructionAttachment file) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(9),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(11),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Row(
//         children: [
//           if (file.isImage)
//             ClipRRect(
//               borderRadius: BorderRadius.circular(9),
//               child: Image.network(
//                 file.fullUrl,
//                 width: 34,
//                 height: 34,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) =>
//                     _buildAttachmentIcon(file),
//               ),
//             )
//           else
//             _buildAttachmentIcon(file),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   file.fileName.isEmpty ? '-' : file.fileName,
//                   style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   _formatFileSize(file.fileSize),
//                   style: const TextStyle(fontSize: 9, color: Colors.black45),
//                 ),
//               ],
//             ),
//           ),
//           GestureDetector(
//             onTap: () => _openAttachment(file),
//             child: const Icon(
//               TablerIcons.eye,
//               size: 17,
//               color: AppColors.textMutedLight,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAttachmentIcon(InstructionAttachment file) {
//     IconData icon;
//     Color color;
//
//     if (file.isPdf) {
//       icon = TablerIcons.file_text;
//       color = Colors.red;
//     } else if (file.isImage) {
//       icon = TablerIcons.photo;
//       color = Colors.blue;
//     } else {
//       icon = TablerIcons.file;
//       color = Colors.blueGrey;
//     }
//
//     return Container(
//       width: 34,
//       height: 34,
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(9),
//       ),
//       child: Icon(icon, size: 17, color: color),
//     );
//   }
//
//   String _formatFileSize(int bytes) {
//     if (bytes <= 0) return '-';
//     if (bytes < 1024) return '$bytes B';
//     if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
//     return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
//   }
//
//   Future<void> _openAttachment(InstructionAttachment file) async {
//     debugPrint('Opening attachment: ${file.fileName} -> ${file.fullUrl}');
//
//     final Uri uri = Uri.parse(file.fullUrl);
//
//     final bool launched = await launchUrl(
//       uri,
//       mode: LaunchMode.externalApplication,
//     );
//
//     if (!launched) {
//       Get.snackbar(
//         'Error',
//         'Unable to open ${file.fileName}.',
//         backgroundColor: Colors.red.withOpacity(0.9),
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }
//
//   // -------------------------------------------------------------------
//   // Acknowledgements
//   // -------------------------------------------------------------------
//
//   Widget _buildAcknowledgementSection(OccInstructionDetail instruction) {
//     final acknowledgements = instruction.acknowledgements;
//
//     return _sectionContainer(
//       title: 'Acknowledgements (${acknowledgements.length})',
//       icon: TablerIcons.users,
//       child: acknowledgements.isEmpty
//           ? const Text(
//         'No acknowledgements yet.',
//         style: TextStyle(
//           fontSize: 11,
//           color: Colors.black38,
//           fontStyle: FontStyle.italic,
//         ),
//       )
//           : Column(
//         children: List.generate(
//           acknowledgements.length,
//               (index) => _buildAcknowledgementCard(
//             acknowledgements[index],
//             isLast: index == acknowledgements.length - 1,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAcknowledgementCard(
//       InstructionAcknowledgement ack, {
//         required bool isLast,
//       }) {
//     final bool acknowledged =
//         (ack.status ?? '').toLowerCase() == 'acknowledged';
//
//     final Color statusColor =
//     acknowledged ? Colors.green : Colors.orange.shade700;
//
//     final String date = ack.acknowledgedDateTime == null
//         ? '-'
//         : DateFormat('dd MMM yyyy').format(ack.acknowledgedDateTime!);
//
//     final String time = ack.acknowledgedDateTime == null
//         ? '-'
//         : DateFormat('hh:mm a').format(ack.acknowledgedDateTime!);
//
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Column(
//           children: [
//             Container(
//               width: 38,
//               height: 38,
//               decoration: BoxDecoration(
//                 color: statusColor.withOpacity(0.10),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 acknowledged ? TablerIcons.check : TablerIcons.clock,
//                 size: 18,
//                 color: statusColor,
//               ),
//             ),
//             if (!isLast)
//               Container(width: 1, height: 70, color: Colors.grey.shade300),
//           ],
//         ),
//         const SizedBox(width: 11),
//         Expanded(
//           child: Container(
//             margin: const EdgeInsets.only(bottom: 13),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade50,
//               borderRadius: BorderRadius.circular(13),
//               border: Border.all(color: Colors.grey.shade200),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         ack.stationName ?? ack.acknowledgedByName ?? '-',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: statusColor.withOpacity(0.10),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         ack.status ?? '-',
//                         style: TextStyle(
//                           fontSize: 9,
//                           fontWeight: FontWeight.w700,
//                           color: statusColor,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 if ((ack.remark ?? '').isNotEmpty)
//                   Text(
//                     ack.remark!,
//                     style: const TextStyle(
//                       fontSize: 11,
//                       color: Colors.black54,
//                       height: 1.4,
//                     ),
//                   )
//                 else
//                   const Text(
//                     'No acknowledgement remark added.',
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.black38,
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     const Icon(TablerIcons.clock, size: 13, color: Colors.black38),
//                     const SizedBox(width: 4),
//                     Text(
//                       '$date • $time',
//                       style: const TextStyle(fontSize: 9, color: Colors.black45),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // -------------------------------------------------------------------
//   // Common section container
//   // -------------------------------------------------------------------
//
//   Widget _sectionContainer({
//     required String title,
//     required IconData icon,
//     required Widget child,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 30,
//                 height: 30,
//                 decoration: BoxDecoration(
//                   color: AppColors.appBarColor.withOpacity(0.10),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(icon, size: 16, color: AppColors.textMutedLight),
//               ),
//               const SizedBox(width: 9),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 13),
//           child,
//         ],
//       ),
//     );
//   }
//
//   Widget _detailRow(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 11),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 95,
//             child: Text(
//               title,
//               style: const TextStyle(fontSize: 11, color: Colors.black45),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:om_mobile/constants/colors.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/custom_app_bar.dart';

import '../controller/occ_instruction_details_controller.dart';
import '../model/occ_instruction_detail_model.dart';
import 'package:url_launcher/url_launcher.dart';

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
        title: 'Instruction Details',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
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
                const SizedBox(height: 20),
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
        icon: TablerIcons.circle_check,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(TablerIcons.check, size: 15, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  instruction.myAcknowledgementDateTime == null
                      ? 'Acknowledged'
                      : 'Acknowledged on ${DateFormat('dd MMM yyyy, hh:mm a').format(instruction.myAcknowledgementDateTime!)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            if ((instruction.myAcknowledgementRemark ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                instruction.myAcknowledgementRemark!,
                style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
              ),
            ],
          ],
        ),
      );
    }

    return _sectionContainer(
      title: 'Acknowledge Instruction',
      icon: TablerIcons.circle_check,
      child: Obx(
            () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller.remarkController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Add a remark before acknowledging',
                hintStyle: const TextStyle(fontSize: 11, color: Colors.black38),
                contentPadding: const EdgeInsets.all(11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isSubmittingAcknowledgement.value
                    ? null
                    : controller.acknowledgeInstruction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appBarColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: controller.isSubmittingAcknowledgement.value
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text(
                  'Acknowledge',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
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
            child: const Icon(TablerIcons.file_text, color: Colors.blue, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: instruction.instructionNumber, size: 16, color: Colors.black87, maxLines: 2),
                const SizedBox(height: 5),
                CustText(
                  name: instruction.issueDate == null
                      ? '-'
                      : DateFormat('dd MMM yyyy').format(instruction.issueDate!),
                  size: 11,
                  color: AppColors.textMutedLight,
                ),
              ],
            ),
          ),
          _buildInstructionTypeBadge(instruction.instructionTypeName),
        ],
      ),
    );
  }

  Widget _buildInstructionTypeBadge(String value) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
      child: Text(
        value.isEmpty ? '-' : value,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Basic details
  // -------------------------------------------------------------------

  Widget _buildBasicDetails(OccInstructionDetail instruction) {
    return _sectionContainer(
      title: 'Instruction Information',
      icon: TablerIcons.info_circle,
      child: Column(
        children: [
          _detailRow(
            'Sent By',
            instruction.instructionByName.isEmpty ? '-' : instruction.instructionByName,
          ),
          _detailRow(
            'Date',
            instruction.issueDate == null
                ? '-'
                : DateFormat('dd MMM yyyy').format(instruction.issueDate!),
          ),
          _detailRow(
            'Valid Upto',
            instruction.validityUpto == null
                ? '-'
                : DateFormat('dd MMM yyyy').format(instruction.validityUpto!),
          ),
          _detailRow(
            'Time',
            instruction.createdDateTime == null
                ? '-'
                : DateFormat('hh:mm a').format(instruction.createdDateTime!),
          ),
          _detailRow(
            'Status',
            instruction.instructionStatus.isEmpty ? '-' : instruction.instructionStatus,
          ),
          if ((instruction.emergencyTypeName ?? '').isNotEmpty)
            _detailRow('Emergency Type', instruction.emergencyTypeName!),
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
      title: 'Location',
      icon: TablerIcons.map_pin,
      child: stations.isEmpty
          ? const Text(
        'No station information available.',
        style: TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
      )
          : _buildStationTagGroup(stations),
    );
  }

  Widget _buildStationTagGroup(List<InstructionStation> stations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(TablerIcons.map_pin, size: 15, color: AppColors.textMutedLight),
            const SizedBox(width: 6),
            const Text(
              'Stations',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: stations.map((station) {
            final bool acknowledged = station.isAcknowledged == true;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: acknowledged ? Colors.green.withOpacity(0.08) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: acknowledged ? Border.all(color: Colors.green.withOpacity(0.3)) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (acknowledged)
                    const Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Icon(TablerIcons.check, size: 12, color: Colors.green),
                    ),
                  Text(
                    station.stationName ??
                        (station.stationId != null ? 'Station #${station.stationId}' : '-'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: acknowledged ? Colors.green.shade800 : Colors.black87,
                    ),
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
      title: 'Technical Details',
      icon: TablerIcons.settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTagGroup(title: entry.key, values: entry.value, icon: TablerIcons.building),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTagGroup({required String title, required List<String> values, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textMutedLight),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: values.map((value) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
              child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
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
      icon: TablerIcons.align_left,
      child: Text(
        instruction.instructionContent,
        style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
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
      icon: TablerIcons.paperclip,
      child: attachments.isEmpty
          ? const Text(
        'No attachments added.',
        style: TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
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
        border: Border.all(color: Colors.grey.shade200),
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
                Text(
                  file.fileName.isEmpty ? '-' : file.fileName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatFileSize(file.fileSize),
                  style: const TextStyle(fontSize: 9, color: Colors.black45),
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

  Future<void> _openAttachment(InstructionAttachment file) async {
    debugPrint('Opening attachment: ${file.fileName} -> ${file.fullUrl}');

    final Uri uri = Uri.parse(file.fullUrl);

    final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched) {
      Get.snackbar(
        'Error',
        'Unable to open ${file.fileName}.',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
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
      icon: TablerIcons.users,
      child: acknowledgements.isEmpty
          ? const Text(
        'No acknowledgements yet.',
        style: TextStyle(
          fontSize: 11,
          color: Colors.black38,
          fontStyle: FontStyle.italic,
        ),
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
              border: Border.all(
                color: Colors.grey.shade200,
              ),
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
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
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
                      child: Text(
                        acknowledged
                            ? 'Acknowledged'
                            : 'Pending',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
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
                    Text(
                      stationName,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
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

                  Text(
                    ack.acknowledgementRemark!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      height: 1.4,
                    ),
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
                    Text(
                      '$date • $time',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black45,
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

  Widget _sectionContainer({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.appBarColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.textMutedLight),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(title, style: const TextStyle(fontSize: 11, color: Colors.black45)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}