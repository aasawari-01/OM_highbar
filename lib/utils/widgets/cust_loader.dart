import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class CustLoader extends StatelessWidget {
  const CustLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.orangeColor),
        strokeWidth: 3,
      ),
    );
  }
}
