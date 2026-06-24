import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:om_mobile/constants/colors.dart';
import 'feature/auth_login/view/login_view.dart';
import 'feature/tabs/view/home_screen.dart';

import 'service/auth_manager.dart';
import 'service/session_controller.dart';

void configLoading() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.circle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 40.0
    ..radius = 10.0
    ..progressColor = AppColors.orangeColor
    ..backgroundColor = Colors.white
    ..indicatorColor = AppColors.orangeColor
    ..textColor = AppColors.orangeColor
    ..maskColor = Colors.black.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final bool isLoggedIn = await AuthManager().isLoggedIn();
  final bool isRememberMe = await AuthManager().isRememberMe();
  
  Widget initialRoute = LoginView();
  
  if (isLoggedIn && isRememberMe) {
    Get.put(SessionController());
    await Get.find<SessionController>().loadSessionData();
    initialRoute = const  HomeScreen();
  }
  
  configLoading();
  
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final Widget initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'O & M Dashboard',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.white1
      ),
      home: initialRoute,
      builder: EasyLoading.init(),
    );
  }
}