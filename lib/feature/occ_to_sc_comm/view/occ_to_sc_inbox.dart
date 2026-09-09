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
// import '../controller/occ_sc_inbox_controller.dart';
// import '../model/occ_sc_list_model.dart';
// import 'instruction_details.dart';
//
// class OccScInboxScreen extends StatelessWidget {
//   const OccScInboxScreen({Key? key, required this.isOcc}) : super(key: key);
//
//   final bool isOcc;
//
//
//   @override
//   Widget build(BuildContext context) {
//
//     Get.delete<OccScInboxController>(force: true);
//     final OccScInboxController controller = Get.put(
//       OccScInboxController(isOcc: isOcc),
//     );
//
//     print("isocc is $isOcc");
//
//     return Scaffold(
//       backgroundColor: AppColors.appBarColor,
//       appBar: CustomAppBar(
//         title: 'Inbox',
//         showDrawer: false,
//         onLeadingPressed: () =>
//             Navigator.pop(context),
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
//             return Column(
//               children: [
//                 _buildTopSection(controller),
//
//                 if (controller.isOcc) _buildCategoryTabs(controller),
//
//                 _buildDateFilter(context, controller),
//
//                 const SizedBox(height: 4)
//
//                ,
//
//                 Expanded(
//                   child: controller
//                       .filteredInstructions
//                       .isEmpty
//                       ? _buildEmptyState(
//                     controller,
//                   )
//                       : RefreshIndicator(
//                     onRefresh: () =>
//                         controller.fetchInstructions(
//                           showLoader: false,
//                         ),
//                     child:
//                     ListView.builder(
//                       padding:
//                       const EdgeInsets
//                           .fromLTRB(
//                         AppConstants
//                             .screenPadding,
//                         4,
//                         AppConstants
//                             .screenPadding,
//                         24,
//                       ),
//                       itemCount: controller
//                           .filteredInstructions
//                           .length,
//                       itemBuilder:
//                           (context, index) {
//                         final item =
//                         controller
//                             .filteredInstructions[
//                         index
//                         ];
//
//                         return _buildInstructionCard(
//                           context,
//                           item,
//                             controller
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   // ================================================================
//   // TOP SECTION
//   // ================================================================
//
//   Widget _buildTopSection(
//       OccScInboxController controller,
//       ) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(
//         AppConstants.screenPadding,
//         16,
//         AppConstants.screenPadding,
//         10,
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//               CrossAxisAlignment.start,
//               children: [
//                 CustText(
//                   name: 'Instructions',
//                   size: 19,
//                   color: Colors.black87,
//                 ),
//                 const SizedBox(height: 3),
//                 CustText(
//                   name:
//                   'Instructions received from OCC',
//                   size: 11,
//                   color:
//                   AppColors.textMutedLight,
//                 ),
//               ],
//             ),
//           ),
//
//           Container(
//             padding:
//             const EdgeInsets.symmetric(
//               horizontal: 10,
//               vertical: 7,
//             ),
//             decoration: BoxDecoration(
//               color: AppColors.appBarColor
//                   .withOpacity(0.10),
//               borderRadius:
//               BorderRadius.circular(18),
//             ),
//             child: Row(
//               mainAxisSize:
//               MainAxisSize.min,
//               children: [
//                 const Icon(
//                   TablerIcons.inbox,
//                   size: 15,
//                   color:
//                   AppColors.textMutedLight,
//                 ),
//                 const SizedBox(width: 5),
//                 Text(
//                   '${controller.expiredCount}',
//                   style:
//                   const TextStyle(
//                     fontSize: 11,
//                     fontWeight:
//                     FontWeight.w700,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================================================================
//   // CATEGORY TABS
//   // ================================================================
//
//   Widget _buildCategoryTabs(
//       OccScInboxController controller,
//       ) {
//     return Container(
//       margin: const EdgeInsets.symmetric(
//         horizontal:
//         AppConstants.screenPadding,
//       ),
//       padding:
//       const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius:
//         BorderRadius.circular(14),
//         border: Border.all(
//           color: Colors.grey.shade200,
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: _buildTab(
//               controller: controller,
//               title: 'Active',
//               count:
//               controller.activeCount,
//               index: 0,
//             ),
//           ),
//
//           Expanded(
//             child: _buildTab(
//               controller: controller,
//               title: 'Upcoming',
//               count:
//               controller.upcomingCount,
//               index: 1,
//             ),
//           ),
//
//           Expanded(
//             child: _buildTab(
//               controller: controller,
//               title: 'Expired',
//               count:
//               controller.expiredCount,
//               index: 2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTab({
//     required OccScInboxController controller,
//     required String title,
//     required int count,
//     required int index,
//   }) {
//     final bool isSelected =
//         controller.selectedTab.value == index;
//
//     return GestureDetector(
//       onTap: () {
//         controller.changeTab(index);
//       },
//       child: AnimatedContainer(
//         duration:
//         const Duration(milliseconds: 180),
//         padding:
//         const EdgeInsets.symmetric(
//           vertical: 10,
//           horizontal: 5,
//         ),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? AppColors.appBarColor
//               : Colors.transparent,
//           borderRadius:
//           BorderRadius.circular(11),
//           boxShadow: isSelected
//               ? [
//             BoxShadow(
//               color: Colors.black
//                   .withOpacity(0.08),
//               blurRadius: 5,
//               offset:
//               const Offset(0, 2),
//             ),
//           ]
//               : null,
//         ),
//         child: Row(
//           mainAxisAlignment:
//           MainAxisAlignment.center,
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: isSelected
//                     ? FontWeight.w700
//                     : FontWeight.w500,
//                 color: isSelected
//                     ? Colors.white
//                     : Colors.black54,
//               ),
//             ),
//
//             const SizedBox(width: 5),
//
//             // Container(
//             //   padding:
//             //   const EdgeInsets.symmetric(
//             //     horizontal: 6,
//             //     vertical: 2,
//             //   ),
//             //   decoration: BoxDecoration(
//             //     color: isSelected
//             //         ? Colors.white
//             //         .withOpacity(0.18)
//             //         : Colors.grey.shade200,
//             //     borderRadius:
//             //     BorderRadius.circular(10),
//             //   ),
//             //   child: Text(
//             //     '$count',
//             //     style: TextStyle(
//             //       fontSize: 9,
//             //       fontWeight:
//             //       FontWeight.w700,
//             //       color: isSelected
//             //           ? Colors.white
//             //           : Colors.black54,
//             //     ),
//             //   ),
//             // ),
//           ],
//         ),
//       ),
//     );
//   }
//   // ================================================================
//   // DATE FILTER
//   // ================================================================
//
//   Widget _buildDateFilter(
//       BuildContext context,
//       OccScInboxController controller,
//       ) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(
//         AppConstants.screenPadding,
//         10,
//         AppConstants.screenPadding,
//         6,
//       ),
//       child: GestureDetector(
//         onTap: () =>
//             _selectDateRange(
//               context,
//               controller,
//             ),
//         child: Container(
//           height: 48,
//           padding:
//           const EdgeInsets.symmetric(
//             horizontal: 13,
//           ),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius:
//             BorderRadius.circular(13),
//             border: Border.all(
//               color: Colors.grey.shade200,
//             ),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 32,
//                 height: 32,
//                 decoration: BoxDecoration(
//                   color: AppColors
//                       .appBarColor
//                       .withOpacity(0.08),
//                   borderRadius:
//                   BorderRadius.circular(9),
//                 ),
//                 child: const Icon(
//                   TablerIcons.calendar,
//                   size: 17,
//                   color:
//                   AppColors.appBarColor,
//                 ),
//               ),
//               const SizedBox(width: 10),
//
//               Expanded(
//                 child: Column(
//                   mainAxisAlignment:
//                   MainAxisAlignment.center,
//                   crossAxisAlignment:
//                   CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       controller
//                           .selectedDateRange
//                           .value ==
//                           null
//                           ? 'Date'
//                           : 'Selected date range',
//                       style:
//                       const TextStyle(
//                         fontSize: 9,
//                         color:
//                         Colors.black45,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       _getDateFilterText(
//                         controller,
//                       ),
//                       style:
//                       const TextStyle(
//                         fontSize: 11,
//                         fontWeight:
//                         FontWeight.w600,
//                         color:
//                         Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               if (controller
//                   .selectedDateRange
//                   .value !=
//                   null)
//                 GestureDetector(
//                   onTap: controller
//                       .clearDateRange,
//                   child: const Padding(
//                     padding:
//                     EdgeInsets.all(5),
//                     child: Icon(
//                       TablerIcons.x,
//                       size: 16,
//                       color:
//                       Colors.black45,
//                     ),
//                   ),
//                 ),
//
//               const SizedBox(width: 3),
//
//               const Icon(
//                 TablerIcons.chevron_down,
//                 size: 17,
//                 color: Colors.black45,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _getDateFilterText(
//       OccScInboxController controller,
//       ) {
//     final range =
//         controller.selectedDateRange.value;
//
//     if (range == null) {
//       return 'All dates';
//     }
//
//     final start = DateFormat(
//       'dd MMM yyyy',
//     ).format(range.start);
//
//     final end = DateFormat(
//       'dd MMM yyyy',
//     ).format(range.end);
//
//     return '$start - $end';
//   }
//
//   Future<void> _selectDateRange(
//       BuildContext context,
//       OccScInboxController controller,
//       ) async {
//     final DateTimeRange? picked =
//     await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2025),
//       lastDate: DateTime(2030),
//       initialDateRange:
//       controller.selectedDateRange.value,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme:
//             ColorScheme.light(
//               primary:
//               AppColors.appBarColor,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null) {
//       controller.setDateRange(
//         picked,
//       );
//     }
//   }
//
//   // ================================================================
//   // INSTRUCTION CARD
//   // ================================================================
//
//   Widget _buildInstructionCard(
//       BuildContext context,
//       OccInstructionListItem item,
//       OccScInboxController controller,
//       ) {
//     final String instructionType = item.instructionTypeName;
//     final String status = item.acknowledgementStatus;
//     final bool acknowledgedByMe = item.isAcknowledgedByCurrentUser == true;
//
//     final String date = item.issueDate == null
//         ? '-'
//         : DateFormat('dd MMM yyyy').format(item.issueDate!);
//
//     return GestureDetector(
//       onTap: () {
//         Get.to(
//               () => InstructionDetailsScreen(
//             instructionId: item.instructionId,
//             isOcc: controller.isOcc, // NOTE: see below re: context
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 10),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: acknowledgedByMe ? Colors.grey.shade50 : Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: acknowledgedByMe
//                 ? Colors.grey.shade200
//                 : AppColors.appBarColor.withOpacity(0.4),
//             width: acknowledgedByMe ? 1 : 1.3,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: acknowledgedByMe
//                   ? Colors.black.withOpacity(0.02)
//                   : AppColors.appBarColor.withOpacity(0.10),
//               blurRadius: acknowledgedByMe ? 6 : 10,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildTypeIcon(instructionType),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         item.instructionNumber,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color:
//                           acknowledgedByMe ? Colors.black54 : Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 3),
//                       Text(
//                         'By ${item.instructionByName}',
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style:
//                         const TextStyle(fontSize: 10, color: Colors.black45),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 7),
//                 acknowledgedByMe
//                     ? _buildStatusChip(status)
//                     : _buildActionNeededChip(),
//               ],
//             ),
//
//             const SizedBox(height: 10),
//
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 item.instructionContent,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: acknowledgedByMe ? Colors.black54 : Colors.black87,
//                   height: 1.35,
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 10),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildCompactInfo(
//                     icon: TablerIcons.map_pin,
//                     value: item.recipientSummary,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: _buildCompactInfo(
//                     icon: TablerIcons.check,
//                     value:
//                     '${item.acknowledgedStations}/${item.totalStations} acknowledged',
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 10),
//
//             Container(
//               padding: const EdgeInsets.only(top: 9),
//               decoration: BoxDecoration(
//                 border: Border(top: BorderSide(color: Colors.grey.shade200)),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(TablerIcons.calendar,
//                       size: 13, color: AppColors.textMutedLight),
//                   const SizedBox(width: 5),
//                   Text(
//                     date,
//                     style: const TextStyle(
//                       fontSize: 10,
//                       color: Colors.black54,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   const Icon(TablerIcons.clock,
//                       size: 13, color: AppColors.textMutedLight),
//                   const SizedBox(width: 4),
//                   Text(
//                     item.createdDateTime == null
//                         ? '-'
//                         : DateFormat('hh:mm a').format(item.createdDateTime!),
//                     style: const TextStyle(
//                       fontSize: 10,
//                       color: Colors.black54,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const Spacer(),
//                   if (acknowledgedByMe) ...[
//                     Icon(TablerIcons.circle_check,
//                         size: 13, color: Colors.green.shade600),
//                     const SizedBox(width: 4),
//                     Text(
//                       'Acknowledged',
//                       style: TextStyle(
//                         fontSize: 9,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.green.shade600,
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                   ],
//                   const Icon(TablerIcons.chevron_right,
//                       size: 17, color: Colors.black38),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionNeededChip() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
//       decoration: BoxDecoration(
//         color: AppColors.appBarColor.withOpacity(0.12),
//         borderRadius: BorderRadius.circular(11),
//       ),
//       child: Text(
//         'Action Needed',
//         style: TextStyle(
//           fontSize: 8.5,
//           fontWeight: FontWeight.w700,
//           color: AppColors.appBarColor,
//         ),
//       ),
//     );
//   }
//
//   // ================================================================
//   // COMPACT INFO
//   // ================================================================
//
//   Widget _buildCompactInfo({
//     required IconData icon,
//     required String value,
//   }) {
//     return Row(
//       children: [
//         Icon(
//           icon,
//           size: 14,
//           color:
//           AppColors.textMutedLight,
//         ),
//         const SizedBox(width: 5),
//         Expanded(
//           child: Text(
//             value,
//             maxLines: 1,
//             overflow:
//             TextOverflow.ellipsis,
//             style:
//             const TextStyle(
//               fontSize: 10.5,
//               fontWeight:
//               FontWeight.w600,
//               color:
//               Colors.black87,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ================================================================
//   // TYPE ICON
//   // ================================================================
//
//   Widget _buildTypeIcon(String type) {
//     IconData icon;
//     Color background;
//     Color iconColor;
//
//     switch (type) {
//       case 'Emergency':
//         icon =
//             TablerIcons.alert_triangle;
//         background =
//             Colors.red.withOpacity(0.09);
//         iconColor =
//             Colors.red.shade600;
//         break;
//
//       case 'Technical':
//         icon = TablerIcons.settings;
//         background =
//             Colors.orange.withOpacity(0.10);
//         iconColor =
//             Colors.orange.shade800;
//         break;
//
//       default:
//         icon = TablerIcons.file_text;
//         background =
//             Colors.blue.withOpacity(0.09);
//         iconColor =
//             Colors.blue.shade700;
//     }
//
//     return Container(
//       width: 40,
//       height: 40,
//       decoration: BoxDecoration(
//         color: background,
//         borderRadius:
//         BorderRadius.circular(11),
//       ),
//       child: Icon(
//         icon,
//         size: 19,
//         color: iconColor,
//       ),
//     );
//   }
//
//   // ================================================================
//   // STATUS
//   // ================================================================
//
//   Widget _buildStatusChip(String status) {
//     Color chipColor;
//     Color textColor;
//
//     switch (status) {
//       case 'Acknowledged':
//         chipColor =
//             Colors.green.withOpacity(0.09);
//         textColor =
//             Colors.green.shade700;
//         break;
//
//       case 'Partially Acknowledged':
//         chipColor =
//             Colors.orange.withOpacity(0.09);
//         textColor =
//             Colors.orange.shade800;
//         break;
//
//       case 'Pending':
//         chipColor =
//             Colors.blue.withOpacity(0.09);
//         textColor =
//             Colors.blue.shade700;
//         break;
//
//       default:
//         chipColor =
//             Colors.grey.withOpacity(0.10);
//         textColor =
//             Colors.grey.shade700;
//     }
//
//     return Container(
//       padding:
//       const EdgeInsets.symmetric(
//         horizontal: 7,
//         vertical: 4,
//       ),
//       decoration: BoxDecoration(
//         color: chipColor,
//         borderRadius:
//         BorderRadius.circular(11),
//       ),
//       child: Text(
//         status == 'Partially Acknowledged'
//             ? 'Partial'
//             : status.isEmpty
//             ? '-'
//             : status,
//         style: TextStyle(
//           fontSize: 8.5,
//           fontWeight:
//           FontWeight.w700,
//           color: textColor,
//         ),
//       ),
//     );
//   }
//
//   // ================================================================
//   // EMPTY
//   // ================================================================
//
//   Widget _buildEmptyState(
//       OccScInboxController controller,
//       ) {
//     final String title;
//
//     switch (controller.selectedTab.value) {
//       case 0:
//         title = 'No active instructions';
//         break;
//
//       case 1:
//         title = 'No upcoming instructions';
//         break;
//
//       case 2:
//         title = controller
//             .selectedDateRange
//             .value !=
//             null
//             ? 'No expired instructions for selected date'
//             : 'No expired instructions';
//         break;
//
//       default:
//         title = 'No instructions';
//     }
//
//     return Center(
//       child: Padding(
//         padding:
//         const EdgeInsets.all(30),
//         child: Column(
//           mainAxisAlignment:
//           MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 64,
//               height: 64,
//               decoration: BoxDecoration(
//                 color: AppColors
//                     .appBarColor
//                     .withOpacity(0.07),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 TablerIcons.inbox,
//                 size: 28,
//                 color:
//                 AppColors.textMutedLight,
//               ),
//             ),
//
//             const SizedBox(height: 14),
//
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style:
//               const TextStyle(
//                 fontSize: 14,
//                 fontWeight:
//                 FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//
//             const SizedBox(height: 5),
//
//             Text(
//               controller.selectedTab.value == 0
//                   ? 'No active instructions available.'
//                   : controller.selectedTab.value == 1
//                   ? 'No upcoming instructions available.'
//                   : 'No expired instructions available.',
//               textAlign: TextAlign.center,
//               style:
//               const TextStyle(
//                 fontSize: 11,
//                 color: Colors.black45,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ================================================================
//   // DETAILS MAP
//   // ================================================================
//
//   Map<String, dynamic> _convertToDetailsMap(
//       OccInstructionListItem item,
//       ) {
//     return {
//       'id': item.instructionNumber,
//       'instructionId':
//       item.instructionId,
//
//       'instructionType':
//       item.instructionTypeName,
//
//       'instructionTypeId':
//       item.instructionTypeId,
//
//       'sentBy': 'OCC',
//
//       'instructionBy':
//       item.instructionByName,
//
//       'instructionById':
//       item.instructionById,
//
//       'date': item.issueDate == null
//           ? ''
//           : DateFormat(
//         'dd MMM yyyy',
//       ).format(
//         item.issueDate!,
//       ),
//
//       'dateTime':
//       item.createdDateTime,
//
//       'time':
//       item.createdDateTime == null
//           ? ''
//           : DateFormat(
//         'hh:mm a',
//       ).format(
//         item.createdDateTime!,
//       ),
//
//       'subject':
//       item.instructionNumber,
//
//       'description':
//       item.instructionContent,
//
//       'recipientSummary':
//       item.recipientSummary,
//
//       'totalStations':
//       item.totalStations,
//
//       'acknowledgedStations':
//       item.acknowledgedStations,
//
//       'pendingStations':
//       item.pendingStations,
//
//       'status':
//       item.acknowledgementStatus,
//
//       'instructionStatus':
//       item.instructionStatus,
//
//       'validityUpto':
//       item.validityUpto,
//
//       'isAcknowledgedByCurrentUser':
//       item.isAcknowledgedByCurrentUser,
//
//       'myAcknowledgementDateTime':
//       item.myAcknowledgementDateTime,
//
//       // API currently only returns recipientSummary,
//       // not actual line/station names.
//       'lines': <String>[],
//
//       'stations': <String>[
//         item.recipientSummary,
//       ],
//     };
//   }
// }

//
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
// import '../controller/occ_sc_inbox_controller.dart';
// import '../model/occ_sc_list_model.dart';
// import 'create_occ_instruction.dart';
// import 'instruction_details.dart';
//
// class OccScInboxScreen extends StatefulWidget {
//   const OccScInboxScreen({Key? key, required this.isOcc}) : super(key: key);
//
//   final bool isOcc;
//
//   @override
//   State<OccScInboxScreen> createState() => _OccScInboxScreenState();
// }
//
// class _OccScInboxScreenState extends State<OccScInboxScreen> {
//   // Controller is created ONCE here (initState), not in build().
//   // Creating it in build() would delete/recreate it on every rebuild
//   // (e.g. MediaQuery or ancestor changes), re-triggering the initial
//   // fetch and dropping any in-progress state.
//   late final OccScInboxController controller;
//
//   @override
//   void initState() {
//     super.initState();
//
//     if (Get.isRegistered<OccScInboxController>()) {
//       Get.delete<OccScInboxController>(force: true);
//     }
//
//     controller = Get.put(OccScInboxController(isOcc: widget.isOcc));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.appBarColor,
//       appBar: CustomAppBar(
//         title: 'Inbox',
//         showDrawer: false,
//         onLeadingPressed: () => Navigator.pop(context),
//       ),
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           color: Color(0xFFF5F6F8),
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//         ),
//         child: Obx(() {
//           if (controller.isLoading.value) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           return Column(
//             children: [
//               _buildTopSection(controller),
//               if (controller.isOcc) _buildCategoryTabs(controller),
//               _buildDateFilter(context, controller),
//               const SizedBox(height: 4),
//               Expanded(
//                 child: controller.filteredInstructions.isEmpty
//                     ? _buildEmptyState(controller)
//                     : RefreshIndicator(
//                   onRefresh: () =>
//                       controller.fetchInstructions(showLoader: false),
//                   child: ListView.builder(
//                     padding: const EdgeInsets.fromLTRB(
//                       AppConstants.screenPadding,
//                       4,
//                       AppConstants.screenPadding,
//                       24,
//                     ),
//                     itemCount: controller.filteredInstructions.length,
//                     itemBuilder: (context, index) {
//                       final item = controller.filteredInstructions[index];
//                       return _buildInstructionCard(context, item, controller);
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           );
//         }),
//       ),
//       floatingActionButton:
//
//
//
//
//       controller.isOcc
//     ? FloatingActionButton(
//     backgroundColor: AppColors.orangeColor,
//       shape: const CircleBorder(),
//       elevation: 4,
//       child: const Icon(Icons.add, color: Colors.white),
//       onPressed: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => CreateOccScCommunicationScreen()),
//         );
//       },
//     )
//         : null,
//     );
//   }
//
//   // ================================================================
//   // TOP SECTION
//   // ================================================================
//
//   Widget _buildTopSection(OccScInboxController controller) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(
//         AppConstants.screenPadding,
//         16,
//         AppConstants.screenPadding,
//         10,
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CustText(name: 'Instructions', size: 19, color: Colors.black87),
//                 const SizedBox(height: 3),
//                 !controller.isOcc ?CustText(
//                   name: 'Instructions received from OCC',
//                   size: 11,
//                   color: AppColors.textMutedLight,
//                 ):Container(),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//             decoration: BoxDecoration(
//               color: AppColors.appBarColor.withOpacity(0.10),
//               borderRadius: BorderRadius.circular(18),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(
//                   TablerIcons.inbox,
//                   size: 15,
//                   color: AppColors.textMutedLight,
//                 ),
//                 const SizedBox(width: 5),
//                 Text(
//                   '${controller.filteredInstructions.length}',
//                   style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================================================================
//   // CATEGORY TABS
//   // ================================================================
//
//   Widget _buildCategoryTabs(OccScInboxController controller) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: _buildTab(
//               controller: controller,
//               title: 'Active',
//               count: controller.activeCount,
//               index: 0,
//             ),
//           ),
//           Expanded(
//             child: _buildTab(
//               controller: controller,
//               title: 'Upcoming',
//               count: controller.upcomingCount,
//               index: 1,
//             ),
//           ),
//           Expanded(
//             child: _buildTab(
//               controller: controller,
//               title: 'Expired',
//               count: controller.expiredCount,
//               index: 2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTab({
//     required OccScInboxController controller,
//     required String title,
//     required int count,
//     required int index,
//   }) {
//     final bool isSelected = controller.selectedTab.value == index;
//
//     return GestureDetector(
//       onTap: () => controller.changeTab(index),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
//         decoration: BoxDecoration(
//           color: isSelected ? AppColors.orangeColor : Colors.transparent,
//           borderRadius: BorderRadius.circular(11),
//           boxShadow: isSelected
//               ? [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 5,
//               offset: const Offset(0, 2),
//             ),
//           ]
//               : null,
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
//                 color: isSelected ? Colors.white : Colors.black54,
//               ),
//             ),
//             const SizedBox(width: 5),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ================================================================
//   // DATE FILTER
//   // ================================================================
//
//   Widget _buildDateFilter(BuildContext context, OccScInboxController controller) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(
//         AppConstants.screenPadding,
//         10,
//         AppConstants.screenPadding,
//         6,
//       ),
//       child: GestureDetector(
//         onTap: () => _selectDateRange(context, controller),
//         child: Container(
//           height: 48,
//           padding: const EdgeInsets.symmetric(horizontal: 13),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(13),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 32,
//                 height: 32,
//                 decoration: BoxDecoration(
//                   color: AppColors.appBarColor.withOpacity(0.08),
//                   borderRadius: BorderRadius.circular(9),
//                 ),
//                 child: const Icon(
//                   TablerIcons.calendar,
//                   size: 17,
//                   color: AppColors.appBarColor,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       controller.selectedDateRange.value == null
//                           ? 'Date'
//                           : 'Selected date range',
//                       style: const TextStyle(fontSize: 9, color: Colors.black45),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       _getDateFilterText(controller),
//                       style: const TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               if (controller.selectedDateRange.value != null)
//                 GestureDetector(
//                   onTap: controller.clearDateRange,
//                   child: const Padding(
//                     padding: EdgeInsets.all(5),
//                     child: Icon(TablerIcons.x, size: 16, color: Colors.black45),
//                   ),
//                 ),
//               const SizedBox(width: 3),
//               const Icon(TablerIcons.chevron_down, size: 17, color: Colors.black45),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _getDateFilterText(OccScInboxController controller) {
//     final range = controller.selectedDateRange.value;
//     if (range == null) return 'All dates';
//
//     final start = DateFormat('dd MMM yyyy').format(range.start);
//     final end = DateFormat('dd MMM yyyy').format(range.end);
//     return '$start - $end';
//   }
//
//   Future<void> _selectDateRange(
//       BuildContext context,
//       OccScInboxController controller,
//       ) async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2025),
//       lastDate: DateTime(2030),
//       initialDateRange: controller.selectedDateRange.value,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(primary: AppColors.appBarColor),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null) {
//       controller.setDateRange(picked);
//     }
//   }
//
//   // ================================================================
//   // INSTRUCTION CARD
//   // ================================================================
//   Widget _buildInstructionCard(
//       BuildContext context,
//       OccInstructionListItem item,
//       OccScInboxController controller,
//       ) {
//     final String instructionType = item.instructionTypeName;
//     final String status = item.acknowledgementStatus;
//     final bool acknowledgedByMe = item.isAcknowledgedByCurrentUser == true;
//
//     final String date = item.issueDate == null
//         ? '-'
//         : DateFormat('dd-MM-yyyy').format(item.issueDate!);
//     final String validityDate =
//     item.validityUpto == null
//         ? '-'
//         : DateFormat('dd-MM-yyyy').format(item.validityUpto!);
//
//     final bool showFooter =
//         acknowledgedByMe || item.instructionStatus.toLowerCase() == 'expired';
//
//     return GestureDetector(
//       onTap: () {
//         Get.to(
//               () => InstructionDetailsScreen(
//             instructionId: item.instructionId,
//             isOcc: controller.isOcc,
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.black.withOpacity(0.2),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Status row — same OCC vs SC logic as before, just restyled.
//             !controller.isOcc? Row(
//               children: [
//                 const Text(
//                   'Status ',
//                   style: TextStyle(fontSize: 13, color: Colors.black45),
//                 ),
//                  _buildStatusChip(
//                   acknowledgedByMe ? 'Acknowledged' : 'Pending',
//                 ),
//               ],
//             ):
//             Row(
//               children: [
//                 const Text(
//                   'Instruction Type : ',
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.black45,
//                   ),
//                 ),
//                 Text(
//                   item.instructionTypeName,
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: getInstructionTypeColor(
//                       item.instructionTypeName,
//                     ),
//                   ),
//                 ),
//               ],
//             )
// ,
//             const SizedBox(height: 12),
//             Divider(color: AppColors.lightBlueColor, height: 1),
//             const SizedBox(height: 14),
//
//             // Row 1 — ID / Date
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: _buildGridItem(
//                     'Instruction ID:',
//                     item.instructionNumber,
//                   ),
//                 ),
//                 Expanded(
//                   child: _buildGridItem('Instruction Date:', date),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 16),
//
//             // Row 2 — Type / By
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: _buildGridItem('Valid Upto: ', validityDate),
//                 ),
//                 !controller.isOcc?Expanded(
//                   child: _buildGridItem(
//                     'Instruction Type:',
//                     item.instructionTypeName,
//                   ),
//                 ):Expanded(
//                   child: _buildGridItem(
//                     'Instruction By:',
//                     item.instructionByName,
//                   ),
//                 ),
//               ],
//             ),
//
//             // Recipients / acknowledged count — OCC only, same as before.
//             if (controller.isOcc) ...[
//               const SizedBox(height: 16),
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: _buildGridItem(
//                       'Recipients:',
//                       item.recipientSummary,
//                     ),
//                   ),
//                   Expanded(
//                     child: _buildGridItem(
//                       'Acknowledged:',
//                       '${item.acknowledgedStations}',
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//
//             // Footer — acknowledged badge + re-create, same conditions as before.
//             if (showFooter) ...[
//               // const SizedBox(height: 14),
//               Container(
//                 padding: const EdgeInsets.only(top: 10),
//                 // decoration: BoxDecoration(
//                 //   border: Border(top: BorderSide(color: Colors.red.shade200)),
//                 // ),
//                 child: Row(
//                   children: [
//                     // if (acknowledgedByMe) ...[
//                     //   Icon(TablerIcons.circle_check,
//                     //       size: 13, color: Colors.green.shade600),
//                     //   const SizedBox(width: 4),
//                     //   Text(
//                     //     'Acknowledged',
//                     //     style: TextStyle(
//                     //       fontSize: 9,
//                     //       fontWeight: FontWeight.w600,
//                     //       color: Colors.green.shade600,
//                     //     ),
//                     //   ),
//                     // ],
//                     const Spacer(),
//                     if (item.instructionStatus.toLowerCase() == 'expired')
//                       GestureDetector(
//                         onTap: () {
//                           controller.recreateInstruction(item.instructionId);
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8),
//                             color: AppColors.appBarColor.withOpacity(0.10),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               const Icon(
//                                 TablerIcons.copy,
//                                 size: 14,
//                                 color: AppColors.appBarColor,
//                               ),
//                               const SizedBox(width: 5),
//                               Text(
//                                 'Re-create',
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.w600,
//                                   color: AppColors.appBarColor,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Color getInstructionTypeColor(String type) {
//     switch (type.toLowerCase()) {
//       case 'general':
//         return Colors.blue;
//       case 'technical':
//         return Colors.orange;
//       case 'emergency':
//         return Colors.red;
//       default:
//         return Colors.black45;
//     }
//   }
//
// // ================================================================
// // GRID ITEM (label above value — used for ID/Date/Type/By rows)
// // ================================================================
//
//   Widget _buildGridItem(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 11.5, color: Colors.black45),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value.isEmpty ? '-' : value,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(
//             fontSize: 13.5,
//             fontWeight: FontWeight.w700,
//             color: Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }
//
//
//   Widget _buildTypeIcon(String type) {
//     IconData icon;
//     Color background;
//     Color iconColor;
//
//     switch (type) {
//       case 'Emergency':
//         icon = TablerIcons.alert_triangle;
//         background = Colors.red.withOpacity(0.09);
//         iconColor = Colors.red.shade600;
//         break;
//       case 'Technical':
//         icon = TablerIcons.settings;
//         background = Colors.orange.withOpacity(0.10);
//         iconColor = Colors.orange.shade800;
//         break;
//       default:
//         icon = TablerIcons.file_text;
//         background = Colors.blue.withOpacity(0.09);
//         iconColor = Colors.blue.shade700;
//     }
//
//     return Container(
//       width: 40,
//       height: 40,
//       decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(11)),
//       child: Icon(icon, size: 19, color: iconColor),
//     );
//   }
//
//   // ================================================================
//   // STATUS
//   // ================================================================
//
//   Widget _buildStatusChip(String status) {
//     Color chipColor;
//     Color textColor;
//
//     switch (status) {
//       case 'Acknowledged':
//         chipColor = Colors.green.withOpacity(0.09);
//         textColor = Colors.green.shade700;
//         break;
//       case 'Partially Acknowledged':
//         chipColor = Colors.orange.withOpacity(0.09);
//         textColor = Colors.orange.shade800;
//         break;
//       case 'Pending':
//         chipColor = Colors.blue.withOpacity(0.09);
//         textColor = Colors.blue.shade700;
//         break;
//       default:
//         chipColor = Colors.grey.withOpacity(0.10);
//         textColor = Colors.grey.shade700;
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
//       decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(11)),
//       child: Text(
//         status == 'Partially Acknowledged'
//             ? 'Partial'
//             : status.isEmpty
//             ? '-'
//             : status,
//         style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: textColor),
//       ),
//     );
//   }
//
//   // ================================================================
//   // EMPTY
//   // ================================================================
//
//   Widget _buildEmptyState(OccScInboxController controller) {
//     final String title;
//
//     switch (controller.selectedTab.value) {
//       case 0:
//         title = 'No active instructions';
//         break;
//       case 1:
//         title = 'No upcoming instructions';
//         break;
//       case 2:
//         title = controller.selectedDateRange.value != null
//             ? 'No expired instructions for selected date'
//             : 'No expired instructions';
//         break;
//       default:
//         title = 'No instructions';
//     }
//
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(30),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 64,
//               height: 64,
//               decoration: BoxDecoration(
//                 color: AppColors.appBarColor.withOpacity(0.07),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(TablerIcons.inbox, size: 28, color: AppColors.textMutedLight),
//             ),
//             const SizedBox(height: 14),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 5),
//             Text(
//               controller.selectedTab.value == 0
//                   ? 'No active instructions available.'
//                   : controller.selectedTab.value == 1
//                   ? 'No upcoming instructions available.'
//                   : 'No expired instructions available.',
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 11, color: Colors.black45),
//             ),
//           ],
//         ),
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

import '../controller/occ_sc_inbox_controller.dart';
import '../model/occ_sc_list_model.dart';
import 'create_occ_instruction.dart';
import 'instruction_details.dart';

class OccScInboxScreen extends StatefulWidget {
  const OccScInboxScreen({Key? key, required this.isOcc}) : super(key: key);

  final bool isOcc;

  @override
  State<OccScInboxScreen> createState() => _OccScInboxScreenState();
}

class _OccScInboxScreenState extends State<OccScInboxScreen> {
  // Controller is created ONCE here (initState), not in build().
  // Creating it in build() would delete/recreate it on every rebuild
  // (e.g. MediaQuery or ancestor changes), re-triggering the initial
  // fetch and dropping any in-progress state.
  late final OccScInboxController controller;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<OccScInboxController>()) {
      Get.delete<OccScInboxController>(force: true);
    }

    controller = Get.put(OccScInboxController(isOcc: widget.isOcc));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: 'Inbox',
        showDrawer: false,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6F8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildTopSection(controller),
              if (controller.isOcc) _buildCategoryTabs(controller),
              _buildDateFilter(context, controller),
              const SizedBox(height: 4),
              Expanded(
                child: controller.filteredInstructions.isEmpty
                    ? _buildEmptyState(controller)
                    : RefreshIndicator(
                  onRefresh: () =>
                      controller.fetchInstructions(showLoader: false),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.screenPadding,
                      4,
                      AppConstants.screenPadding,
                      24,
                    ),
                    itemCount: controller.filteredInstructions.length,
                    itemBuilder: (context, index) {
                      final item = controller.filteredInstructions[index];
                      return _buildInstructionCard(context, item, controller);
                    },
                  ),
                ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton:




      controller.isOcc
          ? FloatingActionButton(
        backgroundColor: AppColors.orangeColor,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateOccScCommunicationScreen()),
          );
        },
      )
          : null,
    );
  }

  // ================================================================
  // TOP SECTION
  // ================================================================

  Widget _buildTopSection(OccScInboxController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPadding,
        16,
        AppConstants.screenPadding,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: 'Instructions', size: 19, color: Colors.black87),
                const SizedBox(height: 3),
                !controller.isOcc ?CustText(
                  name: 'Instructions received from OCC',
                  size: 11,
                  color: AppColors.textMutedLight,
                ):Container(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.appBarColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  TablerIcons.inbox,
                  size: 15,
                  color: AppColors.textMutedLight,
                ),
                const SizedBox(width: 5),
                CustText(
                  name: '${controller.filteredInstructions.length}',
                  size: 11,
                  fontWeightName: FontWeight.w700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CATEGORY TABS
  // ================================================================

  Widget _buildCategoryTabs(OccScInboxController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              controller: controller,
              title: 'Active',
              count: controller.activeCount,
              index: 0,
            ),
          ),
          Expanded(
            child: _buildTab(
              controller: controller,
              title: 'Upcoming',
              count: controller.upcomingCount,
              index: 1,
            ),
          ),
          Expanded(
            child: _buildTab(
              controller: controller,
              title: 'Expired',
              count: controller.expiredCount,
              index: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required OccScInboxController controller,
    required String title,
    required int count,
    required int index,
  }) {
    final bool isSelected = controller.selectedTab.value == index;

    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orangeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustText(
              name: title,
              size: 12,
              fontWeightName: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DATE FILTER
  // ================================================================

  Widget _buildDateFilter(BuildContext context, OccScInboxController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPadding,
        10,
        AppConstants.screenPadding,
        6,
      ),
      child: GestureDetector(
        onTap: () => _selectDateRange(context, controller),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              // Container(
              //   width: 32,
              //   height: 32,
              //   decoration: BoxDecoration(
              //     color: AppColors.appBarColor.withOpacity(0.08),
              //     borderRadius: BorderRadius.circular(9),
              //   ),
              //   child:
              // ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustText(
                      name: controller.selectedDateRange.value == null
                          ? 'Date'
                          : 'Selected date range',
                      size: 9,
                      color: Colors.black45,
                    ),
                    const SizedBox(height: 2),
                    CustText(
                      name: _getDateFilterText(controller),
                      size: 12,
                      fontWeightName: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
              if (controller.selectedDateRange.value != null)
                GestureDetector(
                  onTap: controller.clearDateRange,
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(TablerIcons.x, size: 16, color: Colors.black45),
                  ),
                ),

              const Icon(
                TablerIcons.calendar,
                size: 30,
                color: AppColors.orangeColor,
              ),
              const SizedBox(width: 3),
              const Icon(TablerIcons.chevron_down, size: 25, color: AppColors.orangeColor),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateFilterText(OccScInboxController controller) {
    final range = controller.selectedDateRange.value;
    if (range == null) return 'All dates';

    final start = DateFormat('dd MMM yyyy').format(range.start);
    final end = DateFormat('dd MMM yyyy').format(range.end);
    return '$start - $end';
  }

  Future<void> _selectDateRange(
      BuildContext context,
      OccScInboxController controller,
      ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: controller.selectedDateRange.value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.appBarColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setDateRange(picked);
    }
  }

  // ================================================================
  // INSTRUCTION CARD
  // ================================================================
  Widget _buildInstructionCard(
      BuildContext context,
      OccInstructionListItem item,
      OccScInboxController controller,
      ) {
    final String instructionType = item.instructionTypeName;
    final String status = item.acknowledgementStatus;
    final bool acknowledgedByMe = item.isAcknowledgedByCurrentUser == true;

    final String date = item.issueDate == null
        ? '-'
        : DateFormat('dd-MM-yyyy').format(item.issueDate!);
    final String validityDate =
    item.validityUpto == null
        ? '-'
        : DateFormat('dd-MM-yyyy').format(item.validityUpto!);

    final bool showFooter =
        acknowledgedByMe || item.instructionStatus.toLowerCase() == 'expired';

    return GestureDetector(
      onTap: () {
        Get.to(
              () => InstructionDetailsScreen(
            instructionId: item.instructionId,
            isOcc: controller.isOcc,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row — same OCC vs SC logic as before, just restyled.
            !controller.isOcc? Row(
              children: [
                const CustText(
                  name: 'Status ',
                  size: 13,
                  color: Colors.black45,
                ),
                _buildStatusChip(
                  acknowledgedByMe ? 'Acknowledged' : 'Pending',
                ),
              ],
            ):
            Row(
              children: [
                const CustText(
                  name: 'Instruction Type : ',
                  size: 13,
                  color: Colors.black45,
                ),
                CustText(
                  name: item.instructionTypeName,
                  size: 13,
                  fontWeightName: FontWeight.w600,
                  color: getInstructionTypeColor(
                    item.instructionTypeName,
                  ),
                ),
              ],
            )
            ,
            const SizedBox(height: 12),
            Divider(color: AppColors.lightBlueColor, height: 1),
            const SizedBox(height: 14),

            // Row 1 — ID / Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildGridItem(
                    'Instruction ID:',
                    item.instructionNumber,
                  ),
                ),
                Expanded(
                  child: _buildGridItem('Instruction Date:', date),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Row 2 — Type / By
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildGridItem('Valid Upto: ', validityDate),
                ),
                !controller.isOcc?Expanded(
                  child: _buildGridItem(
                    'Instruction Type:',
                    item.instructionTypeName,
                  ),
                ):Expanded(
                  child: _buildGridItem(
                    'Instruction By:',
                    item.instructionByName,
                  ),
                ),
              ],
            ),

            // Recipients / acknowledged count — OCC only, same as before.
            if (controller.isOcc) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildGridItem(
                      'Recipients:',
                      item.recipientSummary,
                    ),
                  ),
                  Expanded(
                    child: _buildGridItem(
                      'Acknowledged:',
                      '${item.acknowledgedStations}',
                    ),
                  ),
                ],
              ),
            ],

            // Footer — acknowledged badge + re-create, same conditions as before.
            if (showFooter) ...[
              // const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 10),
                // decoration: BoxDecoration(
                //   border: Border(top: BorderSide(color: Colors.red.shade200)),
                // ),
                child: Row(
                  children: [
                    // if (acknowledgedByMe) ...[
                    //   Icon(TablerIcons.circle_check,
                    //       size: 13, color: Colors.green.shade600),
                    //   const SizedBox(width: 4),
                    //   Text(
                    //     'Acknowledged',
                    //     style: TextStyle(
                    //       fontSize: 9,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.green.shade600,
                    //     ),
                    //   ),
                    // ],
                    const Spacer(),
                    if (item.instructionStatus.toLowerCase() == 'expired')
                      GestureDetector(
                        onTap: () {
                          controller.recreateInstruction(item.instructionId);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.appBarColor.withOpacity(0.10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                TablerIcons.copy,
                                size: 14,
                                color: AppColors.appBarColor,
                              ),
                              const SizedBox(width: 5),
                              CustText(
                                name: 'Re-create',
                                size: 10,
                                fontWeightName: FontWeight.w600,
                                color: AppColors.appBarColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color getInstructionTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'general':
        return Colors.blue;
      case 'technical':
        return Colors.orange;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.black45;
    }
  }

// ================================================================
// GRID ITEM (label above value — used for ID/Date/Type/By rows)
// ================================================================

  Widget _buildGridItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: label,
          size: 11.5,
          color: Colors.black45,
        ),
        const SizedBox(height: 4),
        CustText(
          name: value.isEmpty ? '-' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          size: 13.5,
          fontWeightName: FontWeight.w700,
          color: Colors.black87,
        ),
      ],
    );
  }


  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color background;
    Color iconColor;

    switch (type) {
      case 'Emergency':
        icon = TablerIcons.alert_triangle;
        background = Colors.red.withOpacity(0.09);
        iconColor = Colors.red.shade600;
        break;
      case 'Technical':
        icon = TablerIcons.settings;
        background = Colors.orange.withOpacity(0.10);
        iconColor = Colors.orange.shade800;
        break;
      default:
        icon = TablerIcons.file_text;
        background = Colors.blue.withOpacity(0.09);
        iconColor = Colors.blue.shade700;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(11)),
      child: Icon(icon, size: 19, color: iconColor),
    );
  }

  // ================================================================
  // STATUS
  // ================================================================

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;

    switch (status) {
      case 'Acknowledged':
        chipColor = Colors.green.withOpacity(0.09);
        textColor = Colors.green.shade700;
        break;
      case 'Partially Acknowledged':
        chipColor = Colors.orange.withOpacity(0.09);
        textColor = Colors.orange.shade800;
        break;
      case 'Pending':
        chipColor = Colors.blue.withOpacity(0.09);
        textColor = Colors.blue.shade700;
        break;
      default:
        chipColor = Colors.grey.withOpacity(0.10);
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(11)),
      child: CustText(
        name: status == 'Partially Acknowledged'
            ? 'Partial'
            : status.isEmpty
            ? '-'
            : status,
        size: 8.5,
        fontWeightName: FontWeight.w700,
        color: textColor,
      ),
    );
  }

  // ================================================================
  // EMPTY
  // ================================================================

  Widget _buildEmptyState(OccScInboxController controller) {
    final String title;

    switch (controller.selectedTab.value) {
      case 0:
        title = 'No active instructions';
        break;
      case 1:
        title = 'No upcoming instructions';
        break;
      case 2:
        title = controller.selectedDateRange.value != null
            ? 'No expired instructions for selected date'
            : 'No expired instructions';
        break;
      default:
        title = 'No instructions';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.appBarColor.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(TablerIcons.inbox, size: 28, color: AppColors.textMutedLight),
            ),
            const SizedBox(height: 14),
            CustText(
              name: title,
              textAlign: TextAlign.center,
              size: 14,
              fontWeightName: FontWeight.w600,
              color: Colors.black87,
            ),
            const SizedBox(height: 5),
            CustText(
              name: controller.selectedTab.value == 0
                  ? 'No active instructions available.'
                  : controller.selectedTab.value == 1
                  ? 'No upcoming instructions available.'
                  : 'No expired instructions available.',
              textAlign: TextAlign.center,
              size: 11,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }
}