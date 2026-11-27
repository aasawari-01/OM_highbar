import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:om_mobile/feature/dashboard/controller/dashboard_controller.dart';
import 'package:om_mobile/feature/dashboard/view/dashboard_body.dart';
import '../../../constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../core/controller/session_controller.dart';
import '../../../utils/responsive_helper.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/sync_icon_button.dart';
import '../controller/home_controller.dart';

import '../../../utils/widgets/custom_drawer.dart';

/// Dashboard: header (menu, title, sync) and the live failure summary.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SessionController sessionController = Get.find<SessionController>();
  late final DashboardController _dashboard;

  @override
  void initState() {
    super.initState();
    Get.put(HomeController());
    _dashboard = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      drawer: const CustomDrawer(),
      body: Container(
        decoration: const BoxDecoration(color: AppColors.appBarColor),
        child: Column(
          children: [
            SizedBox(height: ResponsiveHelper.height(context, 40)),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(
                    builder: (context) => GestureDetector(
                      child: Icon(
                        TablerIcons.menu_2,
                        color: AppColors.white1,
                        size: ResponsiveHelper.height(context, 30),
                      ),
                      onTap: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.width(context, 15)),
                  CustText(
                    name: "Dashboard",
                    size: AppConstants.sectionHeaderSize,
                    color: AppColors.white1,
                    fontWeightName: FontWeight.w400,
                  ),
                  const Spacer(),
                  Icon(
                    TablerIcons.bell,
                    color: AppColors.white1,
                    size: ResponsiveHelper.height(context, 30),
                  ),
                  SizedBox(width: ResponsiveHelper.width(context, 15)),
                  Icon(
                    Icons.filter_list,
                    color: AppColors.white2,
                    size: ResponsiveHelper.height(context, 30),
                  ),
                  SizedBox(width: ResponsiveHelper.width(context, 15)),
                  const SyncIconButton(),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.height(context, 20)),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: DashboardBody(
                  controller: _dashboard,
                  session: sessionController,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
