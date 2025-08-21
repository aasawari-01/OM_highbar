import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
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
      leading: showDrawer
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: onLeadingPressed ?? () => Navigator.of(context).pop(),
            ),
      title: CustText(
        name: title,
        size: 2.0,
        color: Colors.white,
        fontWeightName: FontWeight.w500,
        textAlign: TextAlign.center,
      ),
      actions: actions,
    );
      return PreferredSize(
        preferredSize: preferredSize,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(30),
          ),
          child: appBarWidget,
        ),
      );
    }
  }