import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/strings.dart';
import 'package:om_mobile/service/session_controller.dart';
import '../../feature/auth_login/view/login_view.dart';
import '../../feature/failure/view/failure_list_screen.dart';
import '../../feature/failure/view/rst/rst_list_screen.dart';
import '../../feature/inspection/view/inspection_list_screen.dart';
import '../../feature/inspection/view/top_management/inspection_dashboard_screen.dart';
import '../../feature/inspection/view/top_management/top_management_create_inspection_screen.dart';
import '../../feature/failure/view/rst/rst_failure_screen.dart';
import '../../feature/ibl/view/ibl_screen.dart';
import '../../service/auth_manager.dart';
import 'cust_dropdown.dart';
import 'cust_button.dart';
import 'cust_text.dart';

class CustomDrawer extends StatefulWidget {
  final String? selectedMenu;
  const CustomDrawer({Key? key, this.selectedMenu}) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? _selectedMenu;
  String? _expandedSectionKey;
  String? _expandedSubSectionKey;
  Set<String> _openSections = {};
  Set<String> _openSubSections = {};
  
  final SessionController sessionController = Get.find<SessionController>();

  void _handleSectionExpansion(String sectionKey, bool isSubSection) {
    setState(() {
      if (isSubSection) {
        if (_expandedSubSectionKey == sectionKey) {
          _expandedSubSectionKey = null;
          _openSubSections.remove(sectionKey);
        } else {
          _expandedSubSectionKey = sectionKey;
          _openSubSections.clear();
          _openSubSections.add(sectionKey);
        }
      } else {
        if (_expandedSectionKey == sectionKey) {
          _expandedSectionKey = null;
          _openSections.remove(sectionKey);
        } else {
          _expandedSectionKey = sectionKey;
          _openSections.clear();
          _openSections.add(sectionKey);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedMenu = widget.selectedMenu;
    _expandedSectionKey = null;
    _expandedSubSectionKey = null;
    _openSections.clear();
    _openSubSections.clear();
  }

  void _onMenuTap(String menu, Widget screen) {
    setState(() {
      _selectedMenu = menu;
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width / 1.3,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.only(top: 40, bottom: 24, left: AppConstants.screenPadding, right: AppConstants.screenPadding),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                   Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: AppColors.textDarkTertiary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Obx(() => CustText(
                      name: sessionController.userInitials,
                      size: 20,
                      color: Colors.white,
                      fontWeightName: FontWeight.w600,
                    )),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustText(
                          name: sessionController.userName.value,
                          size: 16,
                          color: AppColors.textDarkPrimary,
                          fontWeightName: FontWeight.w600,
                        ),
                        const SizedBox(height: 2),
                        CustText(
                          name: sessionController.designationName.value ?? 'No Role Selected',
                          size: 12,
                          color: AppColors.textDarkSecondary,
                          fontWeightName: FontWeight.w400,
                        ),
                        // const SizedBox(height: 2),
                        // CustText(
                        //   name: sessionController.selectedDepartment.value?.deptName ?? 'No Dept Selected',
                        //   size: 12,
                        //   color: AppColors.textDarkSecondary,
                        //   fontWeightName: FontWeight.w400,
                        // ),
                      ],
                    )),
                  ),
                  GestureDetector(
                    onTap: () => _showEditPopup(context),
                    child: const Icon(TablerIcons.pencil, color: AppColors.orangeColor, size: 22),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.elementSpacing),
              children: [
                _drawerItem('ESS', 'ess', null, leadingIcon: TablerIcons.users),
                divider(),
                _drawerItem('Dashboard', 'dashboard', null, leadingIcon: TablerIcons.layout),
                divider(),
                // Failures
                _drawerSection(
                  title: 'Failures',
                  sectionKey: 'failures',
                  icon: TablerIcons.server,
                  children: [
                    Obx(() {
                      final role = sessionController.selectedRole.value?.roleDescr ?? '';
                      final isStationController = role.contains('Station Controller');
                      if (isStationController) {
                        return const SizedBox.shrink();
                      }
                      return _drawerItem('Maintenance JE Inbox', 'maintenance_failure', const FailureListScreen(failureType: 'Maintenance'));
                    }),
                    Obx(() {
                      final role = sessionController.selectedRole.value?.roleDescr ?? '';
                      final canAccessStationFailure =
                          role.contains('Station Controller') || role.contains('Junior Engineer');
                      if (!canAccessStationFailure) {
                        return const SizedBox.shrink();
                      }
                      return _drawerItem( role.contains('Station Controller')?'Station Failure': "Station JE Inbox", 'station_failure', const FailureListScreen(failureType: 'Station'));
                    }),
                    Obx(() {
                      final role = sessionController.selectedRole.value?.roleDescr ?? '';
                      final isStationController = role.contains('Station Controller');
                      if (isStationController) {
                        return const SizedBox.shrink();
                      }
                      return _drawerItem('OCC JE Inbox', 'occ_failure', const FailureListScreen(failureType: 'OCC'));
                    }),
                    Obx(() {
                      final role = sessionController.selectedRole.value?.roleDescr ?? '';
                      final isStationController = role.contains('Station Controller');
                      if (isStationController) {
                        return const SizedBox.shrink();
                      }
                      return _drawerItem('Depot JE Inbox', 'depot_failure', const FailureListScreen(failureType: 'Depot'));
                    }),
                    Obx(() {
                      final role = sessionController.selectedRole.value?.roleDescr ?? '';
                      final isStationController = role.contains('Station Controller');
                      if (isStationController) {
                        return const SizedBox.shrink();
                      }
                      return _drawerItem('RST JE Inbox', 'rst_failure', const RstListScreen());
                    }),
                  ],
                ),
                divider(),
                // Maintenance
                _drawerSection(
                  title: 'Maintenance',
                  sectionKey: 'maintenance',
                  icon: TablerIcons.circle_check,
                  children: [
                    _drawerItem('IBL', 'ibl', const IblScreen()),
                    _drawerItem('PTW', 'ptw', null),
                    _drawerItem('Preventive', 'ptw', null),
                  ],
                ),
                divider(),
                // Operations
                _drawerSection(
                  title: 'Operations',
                  sectionKey: 'operations',
                  icon: TablerIcons.train,
                  children: [
                  ],
                ),
                divider(),
                // Inspection
                _drawerSection(
                  title: 'Inspection',
                  sectionKey: 'inspection_top',
                  icon: TablerIcons.clipboard_list,
                  children: [
                    _drawerItem('Inspection', 'inspection_layout', const InspectionListScreen()),
                    _drawerItem('Join Inspection', 'inspection_join', const InspectionListScreen()),
                  ],
                ),
                divider(),
                // Inspection (Top Management)
                _drawerSection(
                  title: 'Inspection (Top Management)',
                  sectionKey: 'inspection_top_mgmt',
                  icon: TablerIcons.clipboard_check,
                  children: [
                    _drawerItem('Dashboard', 'inspection_tm_dashboard', const InspectionDashboardScreen()),
                    _drawerItem('Create Inspection', 'inspection_tm_create', const TopManagementCreateInspectionScreen()),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.dividerColor2),

          IconButton(
            onPressed: () async {
              await AuthManager().logout();
              Get.offAll(() =>  LoginView());
            },
            icon: const Icon(TablerIcons.logout, size: 30, color: AppColors.orangeColor),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.elementSpacing, left: AppConstants.screenPadding, right: AppConstants.screenPadding),
            child: CustText(
              name: 'Version 1.0.0',
              size: 12,
              color: AppColors.textDarkSecondary,
              fontWeightName: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSection({
    required String sectionKey,
    required String title,
    required List<Widget> children,
    bool isSubSection = false,
    IconData? icon,
  }) {
    bool isExpanded = isSubSection ? _openSubSections.contains(sectionKey) : _openSections.contains(sectionKey);
    
    return Stack(
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.only(left: isSubSection ? 32 : 12, right: 16,),
            leading: isSubSection ? null : Icon(icon ?? Icons.folder_outlined, color: isExpanded?AppColors.orangeColor:AppColors.textDarkSecondary, size: 22),
            title: CustText(
              name: title,
              size: isSubSection ? 14 : 16,
              color:isExpanded?AppColors.orangeColor: AppColors.black,
              fontWeightName: isExpanded?FontWeight.w600:isSubSection ? FontWeight.w400 : FontWeight.w600,
            ),
            initiallyExpanded: isExpanded,
            dense: true,
            visualDensity: const VisualDensity(
              vertical: -2,
              ),
              onExpansionChanged: (expanded) {
              if (expanded) {
                _handleSectionExpansion(sectionKey, isSubSection);
              } else {
                setState(() {
                  if (isSubSection) {
                    _expandedSubSectionKey = null;
                    _openSubSections.remove(sectionKey);
                  } else {
                    _expandedSectionKey = null;
                    _openSections.remove(sectionKey);
                  }
                });
              }
            },
            children: children,
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.orangeColor,
            ),
          ),
        ),
        if (!isSubSection && isExpanded)
          Positioned(
            left: 0,
            top: 8,
            child: Container(
              width: 4,
              height: 40,
              color: AppColors.orangeColor,
            ),
          ),
      ],
    );
  }

  Widget _drawerItem(String name, String key, Widget? screen, {IconData? leadingIcon}) {
    bool isSelected = _selectedMenu == key;
    return Container(
      child: ListTile(
        contentPadding: EdgeInsets.only(left: leadingIcon != null ? 12 : 54, right: 16),
        leading: leadingIcon != null ? Icon(leadingIcon, color: AppColors.textDarkSecondary, size: 22) : null,
        title: CustText(
          name: name,
          size: 16,
          color: isSelected ? Colors.black : Colors.black87,
          fontWeightName: isSelected ? FontWeight.w600 : leadingIcon != null ? FontWeight.w600:FontWeight.w400,
        ),
        // trailing: leadingIcon == null ? const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20) : null, // Matching down arrows for sub-items
        minLeadingWidth: 20,
        dense: true,
        visualDensity: const VisualDensity(
          vertical: -2,
        ),
        onTap: () {
          if (screen == null) {
            Navigator.pop(context);
          } else {
            _onMenuTap(key, screen);
          }
        },
        selected: isSelected,
        selectedTileColor: Colors.transparent,
      ),
    );
  }
  void _showEditPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: AlignmentGeometry.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(TablerIcons.x, size: 24, color: Colors.black87),
                  ),
                ),
                SizedBox(height: AppConstants.elementSpacing,),
                CustText(
                  name: AppStrings.editRoleDeptLine,
                  size: AppConstants.sectionHeaderSize,
                  fontWeightName: FontWeight.w600,
                  color:AppColors.black,
                ),
                const SizedBox(height: AppConstants.labelSpacing),
                CustText(
                  name: AppStrings.editRoleSubtitle,
                  size: AppConstants.bodySize,
                  fontWeightName: FontWeight.w400,
                  color: AppColors.textDarkSecondary,
                ),
                // const SizedBox(height: AppConstants.headerSpacing),
                // CustDropdown(
                //   label: AppStrings.selectLine,
                //   hint: AppStrings.selectYourLine,
                //   items: const ['Line 1', 'Line 2'],
                //   onChanged: (val) {},
                // ),
                const SizedBox(height: AppConstants.elementSpacing),
                Obx(() => CustDropdown(
                  label: AppStrings.selectDepartment,
                  hint: AppStrings.chooseYourDepartment,
                  items: sessionController.departments.map((e) => e.deptName ?? '').toList(),
                  selectedValue: sessionController.selectedDepartment.value?.deptName,
                  onChanged: (val) {
                    final dept = sessionController.departments.firstWhere((e) => e.deptName == val);
                    sessionController.changeDepartment(dept);
                  },
                )),
                const SizedBox(height: AppConstants.elementSpacing),
                // Obx(() => CustDropdown(
                //   label: AppStrings.selectRole,
                //   hint: AppStrings.chooseYourRole,
                //   items: sessionController.roles.map((e) => e.roleDescr ?? '').toList(),
                //   selectedValue: sessionController.selectedRole.value?.roleDescr,
                //   onChanged: (val) {
                //     if (val != null) {
                //       final role = sessionController.roles.firstWhere((e) => e.roleDescr == val);
                //       sessionController.changeRole(role);
                //     }
                //   },
                // )),
                Obx(() => CustDropdown(
                  label: AppStrings.selectRole,
                  hint: sessionController.selectedDepartment.value == null
                      ? AppStrings.selectDepartmentFirst   // new string, or reuse an existing one
                      : AppStrings.chooseYourRole,
                  items: sessionController.selectedDepartment.value == null
                      ? const []
                      : sessionController.roles.map((e) => e.roleDescr ?? '').toList(),
                  selectedValue: sessionController.selectedRole.value?.roleDescr,
                  onChanged: sessionController.selectedDepartment.value == null
                      ? (_) {}
                      : (val) {
                    if (val != null) {
                      final role = sessionController.roles.firstWhere((e) => e.roleDescr == val);
                      sessionController.changeRole(role);
                    }
                  },
                )),
                const SizedBox(height: AppConstants.headerSpacing),
                Row(
                  children: [
                    Expanded(
                      child: CustOutlineButton(
                        name: AppStrings.cancel,
                        size: 150,
                        borderColor: Colors.black26,
                        textDarkPrimary: Colors.black87,
                        onSelected: (_) => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppConstants.elementSpacing),
                    Expanded(
                      child: CustButton(
                        name: AppStrings.saveAndContinue,
                        size: 150,
                        color1: AppColors.orangeColor,
                        color2: AppColors.orangeColor,
                        textDarkPrimary: Colors.white,
                        onSelected: (_) async {
                          final dept = sessionController.selectedDepartment.value;
                          final role = sessionController.selectedRole.value;
                          if (dept?.deptId != null) {
                            await AuthManager().setSelectedDept(dept!.deptId!);
                          }
                          if (role?.roleId != null) {
                            await AuthManager().setSelectedRole(role!.roleId!);
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget divider(){
    return Divider(color: AppColors.textFieldColor,);
  }
}