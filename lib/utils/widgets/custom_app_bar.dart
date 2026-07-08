import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import '../responsive_helper.dart';
import 'cust_text.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onLeadingPressed;
  final List<Widget>? actions;
  final bool showDrawer;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onLeadingPressed,
    this.actions,
    this.showDrawer = false,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final appBarWidget = AppBar(
      backgroundColor: AppColors.appBarColor,
      elevation: 0,
      titleSpacing: 0,
      centerTitle: false,
      leading: showDrawer
          ? Builder(
              builder: (context) => IconButton(
                icon:  Icon( TablerIcons.menu_2,
                  color: AppColors.white1,
                  size: ResponsiveHelper.height(context, 30),),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            )
          : IconButton(
              icon: Icon(TablerIcons.arrow_left, color: AppColors.white1,
                size: ResponsiveHelper.height(context, 30),),
              onPressed: onLeadingPressed ?? () => Navigator.of(context).pop(),
            ),
      title: CustText(
        name: title,
        size: AppConstants.appBarTextSize,
        color: Colors.white,
        fontWeightName: FontWeight.w500,
        textAlign: TextAlign.start,
      ),
      actions: actions,
    );
    return appBarWidget;
  }
}