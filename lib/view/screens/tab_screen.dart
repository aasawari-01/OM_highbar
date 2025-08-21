import 'dart:io';

import 'package:flutter/material.dart';
import 'package:om_mobile/analysis_screen.dart';
import 'package:om_mobile/home_screen.dart';
import 'package:om_mobile/widgets/custom_bottom_nav.dart';
import 'package:om_mobile/widgets/custom_drawer.dart';
import 'task_screen.dart';
import 'notification_screen.dart';

class TabScreen extends StatefulWidget {
  final int index;
  const TabScreen({Key? key, required this.index}) : super(key: key);

  @override
  State<TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {
  late int _currentIndex;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    print("INIT index: $_currentIndex");
  }

  @override
  void didUpdateWidget(covariant TabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      setState(() {
        _currentIndex = widget.index;
        print("UPDATED index: $_currentIndex");
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 1:
        return const TaskScreen();
      case 2:
        return const NotificationScreen();
      case 3:
        return AnalysisScreen();
      default:
        return const HomeScreen();
    }
  }

  String? _getSelectedMenu(int index) {
    switch (index) {
      case 0:
        return null;
      case 1:
        return null;
      case 2:
        return null;
      case 3:
        return null;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        } else {
         exit(0);
         return true;
        }
      },
      child: Scaffold(
        extendBody: true,
        drawer: CustomDrawer(selectedMenu: _getSelectedMenu(_currentIndex)),
        body: _getScreen(_currentIndex),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
