// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
// import 'package:get/get.dart';
//
// import 'package:om_mobile/constants/colors.dart';
//
// import '../../../constants/app_constants.dart';
// import '../../../utils/widgets/cust_button.dart';
// import '../../../utils/widgets/cust_date_time_picker.dart';
// import '../../../utils/widgets/cust_dropdown.dart';
// import '../../../utils/widgets/cust_loader.dart';
// import '../../../utils/widgets/cust_multi_dropdown.dart';
// import '../../../utils/widgets/cust_text.dart';
// import '../../../utils/widgets/cust_textfield.dart';
// import '../../../utils/widgets/custom_app_bar.dart';
//
// import '../controller/occ_to_sc_comm_controller.dart';
//
// class CreateOccScCommunicationScreen
//     extends StatefulWidget {
//   const CreateOccScCommunicationScreen({
//     Key? key,
//   }) : super(key: key);
//
//   @override
//   State<CreateOccScCommunicationScreen>
//   createState() =>
//       _CreateOccScCommunicationScreenState();
// }
//
// class _CreateOccScCommunicationScreenState
//     extends State<CreateOccScCommunicationScreen> {
//   late final OccScCommunicationController
//   controller;
//
//   @override
//   void initState() {
//     super.initState();
//
//     if (Get.isRegistered<
//         OccScCommunicationController>()) {
//       Get.delete<
//           OccScCommunicationController>();
//     }
//
//     controller =
//         Get.put(
//           OccScCommunicationController(),
//         );
//   }
//
//   @override
//   Widget build(
//       BuildContext context,
//       ) {
//     return Scaffold(
//       backgroundColor:
//       AppColors.appBarColor,
//
//       appBar: CustomAppBar(
//         title:
//         'OCC to SC Communication',
//         showDrawer: false,
//         onLeadingPressed: () =>
//             Navigator.pop(context),
//       ),
//
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//
//         decoration:
//         const BoxDecoration(
//           color: AppColors.white1,
//           borderRadius:
//           BorderRadius.only(
//             topLeft:
//             Radius.circular(20),
//             topRight:
//             Radius.circular(20),
//           ),
//         ),
//
//         child: Obx(() {
//           if (controller
//               .isLoading.value) {
//             return const CustLoader();
//           }
//
//           return _buildForm(context);
//         }),
//       ),
//     );
//   }
//
//   Widget _buildForm(
//       BuildContext context,
//       ) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding:
//         const EdgeInsets.all(
//           AppConstants.screenPadding,
//         ),
//
//         child: Form(
//           key: controller.formKey,
//
//           child: Column(
//             crossAxisAlignment:
//             CrossAxisAlignment.start,
//
//             children: [
//               // ---------------------------------------------------------
//               // Instructed By
//               // ---------------------------------------------------------
//               Obx(
//                     () => CustDropdown(
//                   label:
//                   "Instructed By *",
//                   hint: "Select",
//
//                   items: controller
//                       .instructedByList
//                       .map(
//                         (e) => e.name,
//                   )
//                       .toList(),
//
//                   selectedValue:
//                   controller
//                       .selectedInstructedBy
//                       .value,
//
//                   onChanged: (value) {
//                     controller
//                         .selectedInstructedBy
//                         .value =
//                         value;
//                   },
//
//                   validator: (value) =>
//                       controller
//                           .requiredDropdown(
//                         value,
//                         "Instructed By",
//                       ),
//                 ),
//               ),
//
//               const SizedBox(
//                 height:
//                 AppConstants
//                     .elementSpacing,
//               ),
//
//               // ---------------------------------------------------------
//               // Instruction Type
//               // ---------------------------------------------------------
//               Obx(
//                     () => CustDropdown(
//                   label:
//                   "Instruction Type *",
//                   hint: "Select",
//
//                   items: controller
//                       .instructionTypeList
//                       .map(
//                         (e) => e.name,
//                   )
//                       .toList(),
//
//                   selectedValue:
//                   controller
//                       .selectedInstructionType
//                       .value,
//
//                   onChanged: controller
//                       .onInstructionTypeChanged,
//
//                   validator: (value) =>
//                       controller
//                           .requiredDropdown(
//                         value,
//                         "Instruction Type",
//                       ),
//                 ),
//               ),
//
//               const SizedBox(
//                 height:
//                 AppConstants
//                     .elementSpacing,
//               ),
//
//
//               const SizedBox(
//                 height: AppConstants.elementSpacing,
//               ),
//
// // ---------------------------------------------------------
// // Issue Date & Valid Upto
// // ---------------------------------------------------------
//               Obx(
//                     () => Row(
//                   children: [
//                     Expanded(
//                       child: CustDateTimePicker(
//                         label: "Issue Date *",
//                         hint: "Select Issue Date",
//                         selectedDateTime: controller.issueDate.value,
//                         pickerType: PickerType.date,
//
//                         // Today or future
//                         firstDate: controller.today,
//                         lastDate: DateTime(2100),
//
//                         onDateTimeSelected:
//                         controller.setIssueDate,
//
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty) {
//                             return "Issue Date is required";
//                           }
//
//                           return null;
//                         },
//                       ),
//                     ),
//
//                     const SizedBox(
//                       width: AppConstants.elementSpacing,
//                     ),
//
//                     Expanded(
//                       child: CustDateTimePicker(
//                         label: "Valid Upto *",
//                         hint: "Select Valid Upto",
//                         selectedDateTime:
//                         controller.validUptoDate.value,
//                         pickerType: PickerType.date,
//
//                         // Cannot be before Issue Date
//                         firstDate: controller.issueDate.value,
//                         lastDate: DateTime(2100),
//
//                         onDateTimeSelected:
//                         controller.setValidUptoDate,
//
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty) {
//                             return "Valid Upto is required";
//                           }
//
//                           return null;
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(
//                 height: AppConstants.elementSpacing,
//               ),
//
// // ---------------------------------------------------------
// // Line
// // ---------------------------------------------------------
//               Obx(
//                     () => CustMultiDropdown(
//                   label: "Line *",
//                   hint: "Select",
//
//                   items: controller.lineList
//                       .map((e) => e.name)
//                       .toList(),
//
//                   selectedValues:
//                   controller.selectedLines,
//
//                   onChanged:
//                   controller.setSelectedLines,
//
//                   validator: (value) =>
//                       controller.requiredMultiSelect(
//                         value,
//                         "Line",
//                       ),
//                 ),
//               ),
//
//               const SizedBox(
//                 height: AppConstants.elementSpacing,
//               ),
//               // // ---------------------------------------------------------
//               // // Station
//               // // ---------------------------------------------------------
//               // Obx(
//               //       () => CustMultiDropdown(
//               //     label: "Station *",
//               //
//               //     hint: controller
//               //         .selectedLines
//               //         .isEmpty
//               //         ? "Select Line first"
//               //         : "Select",
//               //
//               //     items: controller
//               //         .stationList
//               //         .map(
//               //           (e) => e.name,
//               //     )
//               //         .toList(),
//               //
//               //     selectedValues:
//               //     controller
//               //         .selectedStations,
//               //
//               //     enabled: controller
//               //         .selectedLines
//               //         .isNotEmpty,
//               //
//               //     onChanged: controller
//               //         .setSelectedStations,
//               //
//               //     validator: (value) =>
//               //         controller
//               //             .requiredMultiSelect(
//               //           value,
//               //           "Station",
//               //         ),
//               //   ),
//               // ),
//               //
//               // const SizedBox(
//               //   height:
//               //   AppConstants
//               //       .elementSpacing,
//               // ),
//
// // ---------------------------------------------------------
// // Station Type
// // ---------------------------------------------------------
//               Obx(() {
//                 if (controller.selectedLines.isEmpty) {
//                   return const SizedBox.shrink();
//                 }
//
//                 return CustMultiDropdown(
//                   label: "Station Type *",
//
//                   hint: controller.selectedLines.isEmpty
//                       ? "Select Line first"
//                       : "Select",
//
//                   items: controller.stationTypeList
//                       .map(
//                         (type) =>
//                         controller.getStationTypeLabel(type),
//                   )
//                       .toList(),
//
//                   selectedValues:
//                   controller.selectedStationTypes
//                       .map(
//                         (type) =>
//                         controller.getStationTypeLabel(type),
//                   )
//                       .toList(),
//
//                   onChanged: (values) {
//                     final List<String> codes = values.map((value) {
//                       return value == "Under Ground"
//                           ? "U"
//                           : "A";
//                     }).toList();
//
//                     controller.setSelectedStationTypes(codes);
//                   },
//
//                   validator: (value) =>
//                       controller.requiredMultiSelect(
//                         value,
//                         "Station Type",
//                       ),
//                 );
//               }),
//
//               const SizedBox(
//                 height:
//                 AppConstants
//                     .elementSpacing,
//               ),
//
//               // ---------------------------------------------------------
// // Station
// // ---------------------------------------------------------
//               Obx(
//                     () => CustMultiDropdown(
//                   label: "Station *",
//
//                   hint: controller.selectedLines.isEmpty
//                       ? "Select Line first"
//                       : controller.selectedStationTypes.isEmpty
//                       ? "Select Station Type first"
//                       : "Select",
//
//                   items: controller.stationList
//                       .map((e) => e.name)
//                       .toList(),
//
//                   selectedValues:
//                   controller.selectedStations,
//
//                   enabled:
//                   controller.selectedLines.isNotEmpty &&
//                       controller.selectedStationTypes.isNotEmpty,
//
//                   onChanged:
//                   controller.setSelectedStations,
//
//                   validator: (value) =>
//                       controller.requiredMultiSelect(
//                         value,
//                         "Station",
//                       ),
//                 ),
//               ),
//
//               const SizedBox(
//                 height:
//                 AppConstants
//                     .elementSpacing,
//               ),
//
//               // ---------------------------------------------------------
//               // Technical section
//               // ---------------------------------------------------------
//               Obx(() {
//                 if (!controller
//                     .isTechnical) {
//                   return const SizedBox
//                       .shrink();
//                 }
//
//                 return Column(
//                   crossAxisAlignment:
//                   CrossAxisAlignment
//                       .start,
//
//                   children: [
//                     Obx(
//                           () =>
//                           CustMultiDropdown(
//                             label:
//                             "Department *",
//
//                             hint: "Select",
//
//                             items: controller
//                                 .departmentList
//                                 .map(
//                                   (e) => e.name,
//                             )
//                                 .toList(),
//
//                             selectedValues:
//                             controller
//                                 .selectedDepartments,
//
//                             onChanged:
//                             controller
//                                 .setSelectedDepartments,
//
//                             validator:
//                                 (value) =>
//                                 controller
//                                     .requiredMultiSelect(
//                                   value,
//                                   "Department",
//                                 ),
//                           ),
//                     ),
//
//                     const SizedBox(
//                       height:
//                       AppConstants
//                           .elementSpacing,
//                     ),
//
//                     Obx(
//                           () =>
//                           CustMultiDropdown(
//                             label:
//                             "System *",
//
//                             hint: controller
//                                 .selectedDepartments
//                                 .isEmpty
//                                 ? "Select Department first"
//                                 : "Select",
//
//                             items: controller
//                                 .systemList
//                                 .map(
//                                   (e) => e.name,
//                             )
//                                 .toList(),
//
//                             selectedValues:
//                             controller
//                                 .selectedSystems,
//
//                             enabled: controller
//                                 .selectedDepartments
//                                 .isNotEmpty,
//
//                             onChanged:
//                             controller
//                                 .setSelectedSystems,
//
//                             validator:
//                                 (value) =>
//                                 controller
//                                     .requiredMultiSelect(
//                                   value,
//                                   "System",
//                                 ),
//                           ),
//                     ),
//
//                     const SizedBox(
//                       height:
//                       AppConstants
//                           .elementSpacing,
//                     ),
//                   ],
//                 );
//               }),
//
//               // ---------------------------------------------------------
//               // Emergency section
//               // ---------------------------------------------------------
//               Obx(() {
//                 if (!controller
//                     .isEmergency) {
//                   return const SizedBox
//                       .shrink();
//                 }
//
//                 return Column(
//                   crossAxisAlignment:
//                   CrossAxisAlignment
//                       .start,
//
//                   children: [
//                     Obx(
//                           () =>
//                           CustMultiDropdown(
//                             label:
//                             "Emergency Type *",
//
//                             hint: "Select",
//
//                             items: controller
//                                 .emergencyTypeList
//                                 .map(
//                                   (e) => e.name,
//                             )
//                                 .toList(),
//
//                             selectedValues:
//                             controller
//                                 .selectedEmergencyTypes,
//
//                             onChanged:
//                             controller
//                                 .setSelectedEmergencyTypes,
//
//                             validator:
//                                 (value) =>
//                                 controller
//                                     .requiredMultiSelect(
//                                   value,
//                                   "Emergency Type",
//                                 ),
//                           ),
//                     ),
//
//                     const SizedBox(
//                       height:
//                       AppConstants
//                           .elementSpacing,
//                     ),
//                   ],
//                 );
//               }),
//
//               // ---------------------------------------------------------
//               // Description
//               // ---------------------------------------------------------
//               CustomTextField(
//                 label:
//                 "Description *",
//
//                 controller: controller
//                     .descriptionController,
//
//                 hintText:
//                 "Describe issue details",
//
//                 maxLines: 3,
//
//                 validator: (value) {
//                   if (value == null ||
//                       value.trim().isEmpty) {
//                     return "Description is required";
//                   }
//
//                   return null;
//                 },
//               ),
//
//               const SizedBox(
//                 height:
//                 AppConstants
//                     .sectionSpacing,
//               ),
//
//               // ---------------------------------------------------------
//               // Files
//               // ---------------------------------------------------------
//               CustText.body(
//                 "Uploaded Files (Optional - Maximum 3)",
//                 fontWeightName: FontWeight.w600,
//               ),
//
//               const SizedBox(
//                 height:
//                 AppConstants
//                     .elementSpacing,
//               ),
//
//               _buildUploadArea(),
//
//               Obx(
//                     () => controller
//                     .fileError
//                     .value ==
//                     null
//                     ? const SizedBox
//                     .shrink()
//                     : Padding(
//                   padding:
//                   const EdgeInsets.only(
//                     top: 6,
//                   ),
//                   child: Text(
//                     controller
//                         .fileError
//                         .value!,
//                     style:
//                     const TextStyle(
//                       color:
//                       Colors.red,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(
//                 height:
//                 AppConstants
//                     .sectionSpacing,
//               ),
//
//               // ---------------------------------------------------------
//               // Buttons
//               // ---------------------------------------------------------
//               Obx(
//                     () => Row(
//                   children: [
//                     Expanded(
//                       child: CustButton(
//                         name:
//                         "Report Issue",
//
//                         size:
//                         double.infinity,
//
//                         sHeight:
//                         AppConstants
//                             .buttonHeight,
//
//                         onSelected: controller
//                             .isSubmitting
//                             .value
//                             ? null
//                             : (_) => controller
//                             .submitReportIssue(),
//                       ),
//                     ),
//
//                     const SizedBox(
//                       width:
//                       AppConstants
//                           .elementSpacing,
//                     ),
//
//                     Expanded(
//                       child:
//                       CustOutlineButton(
//                         name: "Cancel",
//
//                         size:
//                         double.infinity,
//
//                         sHeight:
//                         AppConstants
//                             .buttonHeight,
//
//                         onSelected: (_) =>
//                             Navigator.pop(
//                               context,
//                             ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(
//                 height: 32,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------
//   // Upload
//   // -------------------------------------------------------------------
//   Widget _buildUploadArea() {
//     return Row(
//       crossAxisAlignment:
//       CrossAxisAlignment.start,
//       children: [
//         GestureDetector(
//           onTap: _pickFiles,
//
//           child: CustomPaint(
//             painter:
//             DashedBorderPainter(
//               color:
//               Colors.grey.shade400,
//               strokeWidth: 1,
//               dashWidth: 4,
//               dashSpace: 4,
//             ),
//
//             child: Container(
//               width: 90,
//               height: 90,
//
//               alignment:
//               Alignment.center,
//
//               child: Column(
//                 mainAxisAlignment:
//                 MainAxisAlignment.center,
//
//                 children: [
//                   Icon(
//                     TablerIcons
//                         .cloud_upload,
//                     color:
//                     Colors.grey.shade500,
//                     size: 28,
//                   ),
//
//                   const SizedBox(
//                     height: 6,
//                   ),
//
//                   Text(
//                     "Upload Files",
//                     textAlign:
//                     TextAlign.center,
//
//                     style:
//                     TextStyle(
//                       fontSize: 10,
//                       color: Colors
//                           .grey
//                           .shade600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//
//         const SizedBox(
//           width: 12,
//         ),
//
//         Expanded(
//           child: Obx(
//                 () => Wrap(
//               spacing: 12,
//               runSpacing: 12,
//
//               children: controller
//                   .uploadedFiles
//                   .map<Widget>(
//                     (file) =>
//                     _buildAttachmentItem(
//                       file,
//                     ),
//               )
//                   .toList(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickFiles() async {
//     try {
//       final result =
//       await FilePicker.platform
//           .pickFiles(
//         allowMultiple: true,
//         type: FileType.any,
//       );
//
//       if (result == null) {
//         return;
//       }
//
//       for (final file
//       in result.files) {
//         final double sizeInKb =
//             file.size / 1024;
//
//         controller
//             .addUploadedFile({
//           'name': file.name,
//           'size':
//           '${sizeInKb.toStringAsFixed(1)} kb',
//           'path': file.path,
//         });
//       }
//     } catch (e) {
//       debugPrint(
//         "Error picking file: $e",
//       );
//
//       Get.snackbar(
//         "Error",
//         "Could not pick file.",
//         backgroundColor:
//         AppColors.red,
//         colorText:
//         AppColors.white1,
//       );
//     }
//   }
//
//   Widget _buildAttachmentItem(
//       Map<String, dynamic> file,
//       ) {
//     return Container(
//       width: 180,
//
//       padding:
//       const EdgeInsets.all(10),
//
//       decoration:
//       BoxDecoration(
//         color:
//         const Color(0xFFF7F7F7),
//
//         borderRadius:
//         BorderRadius.circular(12),
//       ),
//
//       child: Row(
//         children: [
//           Container(
//             height: 28,
//             width: 28,
//
//             decoration:
//             BoxDecoration(
//               color:
//               const Color(0xFFE2E8F7),
//
//               borderRadius:
//               BorderRadius.circular(6),
//             ),
//
//             child: const Icon(
//               TablerIcons.file,
//               color:
//               AppColors
//                   .textMutedLight,
//               size: 16,
//             ),
//           ),
//
//           const SizedBox(
//             width: 8,
//           ),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//               CrossAxisAlignment
//                   .start,
//
//               children: [
//                 CustText(
//                   name:
//                   file['name'] ??
//                       '',
//                   size: 12,
//                   color:
//                   Colors.black87,
//                   maxLines: 1,
//                 ),
//
//                 CustText(
//                   name:
//                   file['size'] ??
//                       '',
//                   size: 10,
//                   color:
//                   Colors.black54,
//                 ),
//               ],
//             ),
//           ),
//
//           GestureDetector(
//             onTap: () => controller
//                 .removeUploadedFile(
//               file,
//             ),
//
//             child: const Icon(
//               TablerIcons.trash,
//               size: 18,
//               color:
//               Colors.black54,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // -----------------------------------------------------------------------
// // Dashed Border Painter
// // -----------------------------------------------------------------------
// class DashedBorderPainter
//     extends CustomPainter {
//   final Color color;
//   final double strokeWidth;
//   final double dashWidth;
//   final double dashSpace;
//
//   DashedBorderPainter({
//     required this.color,
//     required this.strokeWidth,
//     required this.dashWidth,
//     required this.dashSpace,
//   });
//
//   @override
//   void paint(
//       Canvas canvas,
//       Size size,
//       ) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = strokeWidth
//       ..style =
//           PaintingStyle.stroke;
//
//     final dashPath = Path();
//
//     final dashCount =
//     (size.width /
//         (dashWidth +
//             dashSpace))
//         .floor();
//
//     final dashCountVertical =
//     (size.height /
//         (dashWidth +
//             dashSpace))
//         .floor();
//
//     for (int i = 0;
//     i < dashCount;
//     i++) {
//       final startX =
//           i *
//               (dashWidth +
//                   dashSpace);
//
//       dashPath.moveTo(
//         startX,
//         0,
//       );
//
//       dashPath.lineTo(
//         startX + dashWidth,
//         0,
//       );
//
//       dashPath.moveTo(
//         startX,
//         size.height,
//       );
//
//       dashPath.lineTo(
//         startX + dashWidth,
//         size.height,
//       );
//     }
//
//     for (int i = 0;
//     i < dashCountVertical;
//     i++) {
//       final startY =
//           i *
//               (dashWidth +
//                   dashSpace);
//
//       dashPath.moveTo(
//         0,
//         startY,
//       );
//
//       dashPath.lineTo(
//         0,
//         startY + dashWidth,
//       );
//
//       dashPath.moveTo(
//         size.width,
//         startY,
//       );
//
//       dashPath.lineTo(
//         size.width,
//         startY + dashWidth,
//       );
//     }
//
//     canvas.drawPath(
//       dashPath,
//       paint,
//     );
//   }
//
//   @override
//   bool shouldRepaint(
//       CustomPainter oldDelegate,
//       ) =>
//       false;
// }
//
//


import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';

import 'package:om_mobile/constants/colors.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/widgets/cust_button.dart';
import '../../../utils/widgets/cust_date_time_picker.dart';
import '../../../utils/widgets/cust_dropdown.dart';
import '../../../utils/widgets/cust_grouped_multi_dropdown.dart';
import '../../../utils/widgets/cust_loader.dart';
import '../../../utils/widgets/cust_multi_dropdown.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/cust_textfield.dart';
import '../../../utils/widgets/custom_app_bar.dart';

import '../controller/occ_to_sc_comm_controller.dart';
import '../model/occ_instruction_detail_model.dart';

class CreateOccScCommunicationScreen extends StatefulWidget {
  const CreateOccScCommunicationScreen({Key? key,this.recreateInstruction}) : super(key: key);
  final OccInstructionDetail? recreateInstruction;
  @override
  State<CreateOccScCommunicationScreen> createState() =>
      _CreateOccScCommunicationScreenState();
}

class _CreateOccScCommunicationScreenState
    extends State<CreateOccScCommunicationScreen> {
  late final OccScCommunicationController controller;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<OccScCommunicationController>()) {
      Get.delete<OccScCommunicationController>(force: true);
    }

    // controller = Get.put(OccScCommunicationController());

    controller = Get.put(
      OccScCommunicationController(
        recreateInstruction: widget.recreateInstruction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: CustomAppBar(
        title: widget.recreateInstruction != null
            ? 'Re-create Instruction'
            : 'OCC to SC Communication',
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
            return const CustLoader();
          }
          return _buildForm(context);
        }),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------
              // Instructed By
              // ---------------------------------------------------------
              Obx(
                    () => CustDropdown(
                  label: "Instructed By *",
                  hint: "Select",
                  items: controller.instructedByList.map((e) => e.name).toList(),
                  selectedValue: controller.selectedInstructedBy.value,
                  onChanged: (value) {
                    controller.selectedInstructedBy.value = value;
                  },
                  validator: (value) =>
                      controller.requiredDropdown(value, "Instructed By"),
                ),
              ),

              const SizedBox(height: AppConstants.elementSpacing),

              // ---------------------------------------------------------
              // Instruction Type
              // ---------------------------------------------------------
              Obx(
                    () => CustDropdown(
                  label: "Instruction Type *",
                  hint: "Select",
                  items: controller.instructionTypeList.map((e) => e.name).toList(),
                  selectedValue: controller.selectedInstructionType.value,
                  onChanged: controller.onInstructionTypeChanged,
                  validator: (value) =>
                      controller.requiredDropdown(value, "Instruction Type"),
                ),
              ),

              const SizedBox(height: AppConstants.elementSpacing),

              // ---------------------------------------------------------
              // Issue Date & Valid Upto
              // ---------------------------------------------------------
              Obx(
                    () => Row(
                  children: [
                    Expanded(
                      child: CustDateTimePicker(
                        label: "Issue Date *",
                        hint: "Select Issue Date",
                        selectedDateTime: controller.issueDate.value,
                        pickerType: PickerType.date,
                        // Today or future
                        firstDate: controller.today,
                        lastDate: DateTime(2100),
                        onDateTimeSelected: controller.setIssueDate,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Issue Date is required";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.elementSpacing),
                    Expanded(
                      child: CustDateTimePicker(
                        label: "Valid Upto (Optional)",
                        hint: "Select Valid Upto",
                        selectedDateTime: controller.validUptoDate.value,
                        pickerType: PickerType.date,
                        // Cannot be before Issue Date
                        firstDate: controller.issueDate.value,
                        lastDate: DateTime(2100),
                        onDateTimeSelected: controller.setValidUptoDate,
                        validator: null
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.elementSpacing),

              // ---------------------------------------------------------
              // Line
              // ---------------------------------------------------------
              Obx(
                    () => CustMultiDropdown(
                  label: "Line *",
                  hint: "Select",
                  items: controller.lineList.map((e) => e.name).toList(),
                  selectedValues: controller.selectedLines,
                  onChanged: controller.setSelectedLines,
                  validator: (value) =>
                      controller.requiredMultiSelect(value, "Line"),
                ),
              ),

              const SizedBox(height: AppConstants.elementSpacing),

              // ---------------------------------------------------------
              // Station Type (only shown once a Line is selected)
              // ---------------------------------------------------------
              Obx(() {
                if (controller.selectedLines.isEmpty) {
                  return const SizedBox.shrink();
                }

                return CustMultiDropdown(
                  label: "Station Type *",
                  hint: controller.selectedLines.isEmpty
                      ? "Select Line first"
                      : "Select",
                  items: controller.stationTypeList
                      .map((type) => controller.getStationTypeLabel(type))
                      .toList(),
                  selectedValues: controller.selectedStationTypes
                      .map((type) => controller.getStationTypeLabel(type))
                      .toList(),
                  onChanged: (values) {
                    final List<String> codes = values.map((value) {
                      return value == "Under Ground" ? "U" : "A";
                    }).toList();

                    controller.setSelectedStationTypes(codes);
                  },
                  validator: (value) =>
                      controller.requiredMultiSelect(value, "Station Type"),
                );
              }),

              const SizedBox(height: AppConstants.elementSpacing),

              // ---------------------------------------------------------
              // Station
              // ---------------------------------------------------------
              // Obx(
              //       () => CustMultiDropdown(
              //     label: "Station *",
              //     hint: controller.selectedLines.isEmpty
              //         ? "Select Line first"
              //         : controller.selectedStationTypes.isEmpty
              //         ? "Select Station Type first"
              //         : "Select",
              //     items: controller.stationList.map((e) => e.name).toList(),
              //     selectedValues: controller.selectedStations,
              //     enabled: controller.selectedLines.isNotEmpty &&
              //         controller.selectedStationTypes.isNotEmpty,
              //     onChanged: controller.setSelectedStations,
              //     validator: (value) =>
              //         controller.requiredMultiSelect(value, "Station"),
              //   ),
              // ),

              Obx(
                    () => CustGroupedMultiDropdown(
                  label: "Station *",
                  hint: controller.selectedLines.isEmpty
                      ? "Select Line first"
                      : controller.selectedStationTypes.isEmpty
                      ? "Select Station Type first"
                      : "Select",
                  sections: controller.stationSections,
                  selectedValues: controller.selectedStations,
                  enabled: controller.selectedLines.isNotEmpty &&
                      controller.selectedStationTypes.isNotEmpty,
                  onChanged: controller.setSelectedStations,
                  validator: (value) =>
                      controller.requiredMultiSelect(value, "Station"),
                ),
              ),

              const SizedBox(height: AppConstants.elementSpacing),

              // ---------------------------------------------------------
              // Technical section
              // ---------------------------------------------------------
              Obx(() {
                if (!controller.isTechnical) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                          () => CustMultiDropdown(
                        label: "Department *",
                        hint: "Select",
                        items: controller.departmentList.map((e) => e.name).toList(),
                        selectedValues: controller.selectedDepartments,
                        onChanged: controller.setSelectedDepartments,
                        validator: (value) =>
                            controller.requiredMultiSelect(value, "Department"),
                      ),
                    ),
                    const SizedBox(height: AppConstants.elementSpacing),
                    // Obx(
                    //       () => CustMultiDropdown(
                    //     label: "System *",
                    //     hint: controller.selectedDepartments.isEmpty
                    //         ? "Select Department first"
                    //         : "Select",
                    //     items: controller.systemList.map((e) => e.name).toList(),
                    //     selectedValues: controller.selectedSystems,
                    //     enabled: controller.selectedDepartments.isNotEmpty,
                    //     onChanged: controller.setSelectedSystems,
                    //     validator: (value) =>
                    //         controller.requiredMultiSelect(value, "System"),
                    //   ),
                    // ),

                    Obx(
                          () => CustGroupedMultiDropdown(
                        label: "System *",
                        hint: controller.selectedDepartments.isEmpty
                            ? "Select Department first"
                            : "Select",
                        sections: controller.systemSections,
                        selectedValues: controller.selectedSystems,
                        enabled: controller.selectedDepartments.isNotEmpty,
                        onChanged: controller.setSelectedSystems,
                        validator: (value) =>
                            controller.requiredMultiSelect(value, "System"),
                      ),
                    ),
                    const SizedBox(height: AppConstants.elementSpacing),
                  ],
                );
              }),

              // ---------------------------------------------------------
              // Emergency section
              // ---------------------------------------------------------
              Obx(() {
                if (!controller.isEmergency) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                          () => CustDropdown(
                            label: "Emergency Type *",
                            hint: "Select",
                            items: controller.emergencyTypeList
                                .map((e) => e.name)
                                .toList(),
                            selectedValue: controller.selectedEmergencyType.value,
                            onChanged: controller.setSelectedEmergencyType,
                            validator: (value) =>
                                controller.requiredDropdown(value, "Emergency Type"),
                          ),
                    ),
                    const SizedBox(height: AppConstants.elementSpacing),
                  ],
                );
              }),

              // ---------------------------------------------------------
              // Description
              // ---------------------------------------------------------
              CustomTextField(
                label: "Description *",
                controller: controller.descriptionController,
                hintText: "Describe issue details",
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Description is required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.sectionSpacing),

              // ---------------------------------------------------------
              // Files
              // ---------------------------------------------------------
              // CustText.body(
              //   "Uploaded Files (Optional - Maximum 3)",
              //   fontWeightName: FontWeight.w600,
              // ),
              //
              // const SizedBox(height: AppConstants.elementSpacing),
              //
              // _buildUploadArea(),
              //
              // Obx(
              //       () => controller.fileError.value == null
              //       ? const SizedBox.shrink()
              //       : Padding(
              //     padding: const EdgeInsets.only(top: 6),
              //     child: Text(
              //       controller.fileError.value!,
              //       style: const TextStyle(color: Colors.red, fontSize: 12),
              //     ),
              //   ),
              // ),
              //
              // const SizedBox(height: AppConstants.sectionSpacing),

              // ---------------------------------------------------------
              // Attachments
              // ---------------------------------------------------------
              CustText.body(
                "Attachments  (Optional - Maximum 3)",
                fontWeightName: FontWeight.w600,
              ),

              const SizedBox(height: 4),

              Text(
                "Supported: Images, PDF • Max 5 MB per file • Up to 3 files",
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: AppConstants.elementSpacing),

              _buildUploadArea(),

              Obx(
                    () => controller.fileError.value == null
                    ? const SizedBox.shrink()
                    : Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    controller.fileError.value!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.sectionSpacing),

              // ---------------------------------------------------------
              // Buttons
              // ---------------------------------------------------------
              Obx(
                    () => Row(
                  children: [

                    Expanded(
                      child: CustOutlineButton(
                        name: "Cancel",
                        size: double.infinity,
                        sHeight: AppConstants.buttonHeight,
                        onSelected: (_) => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppConstants.elementSpacing),
                    Expanded(
                      child: CustButton(
                        name: "Create Instruction",
                        size: double.infinity,
                        sHeight: AppConstants.buttonHeight,
                        onSelected: controller.isSubmitting.value
                            ? null
                            : (_) => controller.submitReportIssue(),
                      ),
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Upload
  // -------------------------------------------------------------------
  Widget _buildUploadArea() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickFiles,
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: Colors.grey.shade400,
              strokeWidth: 1,
              dashWidth: 4,
              dashSpace: 4,
            ),
            child: Container(
              width: 90,
              height: 90,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(TablerIcons.cloud_upload, color: Colors.grey.shade500, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    "Upload Files",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(
                () => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: controller.uploadedFiles
                  .map<Widget>((file) => _buildAttachmentItem(file))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Future<void> _pickFiles() async {
  //   try {
  //     final result = await FilePicker.platform.pickFiles(
  //       allowMultiple: true,
  //       type: FileType.any,
  //     );
  //
  //     if (result == null) return;
  //
  //     for (final file in result.files) {
  //       final double sizeInKb = file.size / 1024;
  //
  //       controller.addUploadedFile({
  //         'name': file.name,
  //         'size': '${sizeInKb.toStringAsFixed(1)} kb',
  //         'path': file.path,
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint("Error picking file: $e");
  //
  //     Get.snackbar(
  //       "Error",
  //       "Could not pick file.",
  //       backgroundColor: AppColors.red,
  //       colorText: AppColors.white1,
  //     );
  //   }
  // }

  static const List<String> _allowedExtensions = [
    'jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx',
  ];
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int _maxFiles = 3;

  Future<void> _pickFiles() async {
    try {
      if (controller.uploadedFiles.length >= _maxFiles) {
        controller.fileError.value = "You can upload a maximum of $_maxFiles files.";
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );

      if (result == null) return;

      String? rejectionReason;
      int remainingSlots = _maxFiles - controller.uploadedFiles.length;

      for (final file in result.files) {
        if (remainingSlots <= 0) {
          rejectionReason = "Only $_maxFiles files are allowed in total.";
          break;
        }

        if (file.size > _maxFileSizeBytes) {
          rejectionReason = "${file.name} exceeds the 5 MB limit.";
          continue;
        }

        final double sizeInKb = file.size / 1024;

        controller.addUploadedFile({
          'name': file.name,
          'size': '${sizeInKb.toStringAsFixed(1)} kb',
          'path': file.path,
        });

        remainingSlots--;
      }

      controller.fileError.value = rejectionReason;
    } catch (e) {
      debugPrint("Error picking file: $e");

      Get.snackbar(
        "Error",
        "Could not pick file.",
        backgroundColor: AppColors.red,
        colorText: AppColors.white1,
      );
    }
  }

  Widget _buildAttachmentItem(Map<String, dynamic> file) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(TablerIcons.file, color: AppColors.textMutedLight, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: file['name'] ?? '', size: 12, color: Colors.black87, maxLines: 1),
                CustText(name: file['size'] ?? '', size: 10, color: Colors.black54),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => controller.removeUploadedFile(file),
            child: const Icon(TablerIcons.trash, size: 18, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Dashed Border Painter
// -----------------------------------------------------------------------
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

    for (int i = 0; i < dashCount; i++) {
      final startX = i * (dashWidth + dashSpace);
      dashPath.moveTo(startX, 0);
      dashPath.lineTo(startX + dashWidth, 0);
      dashPath.moveTo(startX, size.height);
      dashPath.lineTo(startX + dashWidth, size.height);
    }

    for (int i = 0; i < dashCountVertical; i++) {
      final startY = i * (dashWidth + dashSpace);
      dashPath.moveTo(0, startY);
      dashPath.lineTo(0, startY + dashWidth);
      dashPath.moveTo(size.width, startY);
      dashPath.lineTo(size.width, startY + dashWidth);
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}