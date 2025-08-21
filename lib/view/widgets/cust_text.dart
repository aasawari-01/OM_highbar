import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/colors.dart';
import '../../utils/size_config.dart';


class CustText extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final FontWeight? fontWeightName;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const CustText({
    super.key,
    required this.name,
    required this.size,
    this.color,
    this.fontWeightName,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: GoogleFonts.workSans(
        color: color ?? AppColors.textColor,
        fontWeight: fontWeightName ?? FontWeight.w400,
        fontSize:size * SizeConfig.textMultiplier,
      ),
    );
  }
}










// import 'package:google_fonts/google_fonts.dart';
//
// import '../utils/SizeConfig.dart';
//
// class CustText extends StatelessWidget {
//
//   final String name;
//   final double size;
//   final Color colors;
//   final TextAlign textAlign;
//   final FontWeight fontWeightName;
//   final int maxLine;
//
//   const CustText({
//     super.key,
//     required this.name,
//     required this.size,
//     required this.colors,
//     required this.textAlign,
//     required this.fontWeightName,
//     required this.maxLine,
//   });
//   @override
//   Widget build(BuildContext context) {
//     final mediaQueryData = MediaQuery.of(context);
//     final scale = mediaQueryData.textScaler.clamp(
//       minScaleFactor: 1.0, // Minimum scale factor allowed.
//       maxScaleFactor: 1.3, // Maximum scale factor allowed.
//     );
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return MediaQuery(
//           data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
//           child: Text(
//               name,
//               textAlign: textAlign,
//               maxLines: maxLine,
//               style: GoogleFonts.cabin(
//                 textStyle: TextStyle(
//                   color: colors,
//                   fontWeight: fontWeightName,
//                   fontSize: size * SizeConfig.textMultiplier,
//                 )
//               ),
//             ),
//         );
//       },
//     );
//   }
// }
//
// class HeadingText extends StatelessWidget{
//
//   final String name;
//   final double size;
//   final Color colors;
//   final TextAlign textAlign;
//   final FontWeight fontWeightName;
//   final int maxLine;
//
//   const HeadingText({
//     super.key,
//     required this.name,
//     required this.size,
//     required this.colors,
//     required this.textAlign,
//     required this.fontWeightName,
//     required this.maxLine,
//   });
//   @override
//   Widget build(BuildContext context) {
//     final mediaQueryData = MediaQuery.of(context);
//     final scale = mediaQueryData.textScaler.clamp(
//       minScaleFactor: 1.0, // Minimum scale factor allowed.
//       maxScaleFactor: 1.3, // Maximum scale factor allowed.
//     );
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return MediaQuery(
//           data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
//           child: Text(
//               name,
//               textAlign: textAlign,
//               maxLines: maxLine,
//               style: GoogleFonts.inter(
//                 textStyle: TextStyle(
//                   color: colors,
//                   fontWeight: fontWeightName,
//                   fontSize: size * SizeConfig.textMultiplier,
//                 )
//               ),
//             ),
//         );
//       },
//     );
//   }
// }
//
// class SubHeadingText extends StatelessWidget{
//
//   final String name;
//   final double size;
//   final Color colors;
//   final TextAlign textAlign;
//   final FontWeight fontWeightName;
//   final int maxLine;
//
//   const SubHeadingText({
//     super.key,
//     required this.name,
//     required this.size,
//     required this.colors,
//     required this.textAlign,
//     required this.fontWeightName,
//     required this.maxLine,
//   });
//   @override
//   Widget build(BuildContext context) {
//     final mediaQueryData = MediaQuery.of(context);
//     final scale = mediaQueryData.textScaler.clamp(
//       minScaleFactor: 1.0, // Minimum scale factor allowed.
//       maxScaleFactor: 1.3, // Maximum scale factor allowed.
//     );
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return MediaQuery(
//           data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
//           child: Text(
//               name,
//               textAlign: textAlign,
//               maxLines: maxLine,
//               style: GoogleFonts.inter(
//                 textStyle: TextStyle(
//                   color: colors,
//                   fontWeight: fontWeightName,
//                   fontSize: size * SizeConfig.textMultiplier,
//                 )
//               ),
//             ),
//         );
//       },
//     );
//   }
// }
