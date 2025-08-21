import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/size_config.dart';

import '../screens/assets_list_screen.dart';
import '../screens/assurance_register_list_screen.dart';
import '../screens/axle_counter_reset_list_screen.dart';
import '../screens/cash_check_details_register_list_screen.dart';
import '../screens/complaint_feedback_list_screen.dart';
import '../screens/deep_cleaning_list_screen.dart';
import '../screens/divyang_list_screen.dart';
import '../screens/failure_list_screen.dart';
import '../screens/first_aid_register_list_screen.dart';
import '../screens/gate_pass_detail_list.dart';
import '../screens/inspection_list_screen.dart';
import '../screens/login_view.dart';
import '../screens/manual_ticket_details_list_screen.dart';
import '../screens/occ_failure_screen.dart';
import '../screens/penalty_details_list_screen.dart';
import '../screens/private_number_book_list_screen.dart';
import '../screens/ptw_form_screen.dart';
import '../screens/service_deficiency_register_form.dart';
import '../screens/shift_abstract_register_list_screen.dart';
import '../screens/station_diary_screen.dart';
import '../screens/station_failure_list_screen.dart';
import '../screens/station_instruction_register_list_screen.dart';
import '../screens/tom_shift_login_list_screen.dart';
import '../screens/tsr_details_screen.dart';
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
  Set<String> _openSections = {}; // Track open sections
  Set<String> _openSubSections = {}; // Track open subsections

  void _handleSectionExpansion(String sectionKey, bool isSubSection) {
    setState(() {
      if (isSubSection) {
        // For subsections
        if (_expandedSubSectionKey == sectionKey) {
          // If same subsection is clicked, close it
          _expandedSubSectionKey = null;
          _openSubSections.remove(sectionKey);
        } else {
          // Close other subsections and open this one
          _expandedSubSectionKey = sectionKey;
          _openSubSections.clear();
          _openSubSections.add(sectionKey);
        }
      } else {
        // For sections
        if (_expandedSectionKey == sectionKey) {
          // If same section is clicked, close it
          _expandedSectionKey = null;
          _openSections.remove(sectionKey);
        } else {
          // Close other sections and open this one
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
      width: 70 * SizeConfig.widthMultiplier,
      backgroundColor: AppColors.bgColor,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.appBarColor,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: SafeArea(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/images/O_&_M_Logo.png'),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustText(
                          name: 'Rohan Sharma',
                          size: 1.8,
                          color: Colors.white,
                          fontWeightName: FontWeight.w600,
                        ),
                        SizedBox(height: 4),
                        CustText(
                          name: 'Station In-charge',
                          size: 1.3,
                          color: Colors.white.withOpacity(0.8),
                          fontWeightName: FontWeight.w400,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Maintenance
                _drawerSection(
                  title: 'Maintenance',
                  sectionKey: 'maintenance',
                  children: [
                    _drawerItem('Inspection', 'inspection', const InspectionListScreen()),
                     _drawerItem('Report', 'report', null),
                    _drawerItem('Failure List', 'failure_list', FailureListScreen()),
                  ],
                ),
                _drawerSection(
                  title: 'TSR',
                  sectionKey: 'tsr',
                  children: [
                    _drawerItem('TSR details', 'tsr_details', const TSRDetailsScreen()),
                    _drawerItem('PTW Request details', 'ptw_details', const PTWFormScreen()),
                  ],
                ),
                // Operations
                _drawerSection(
                  title: 'Operations',
                  sectionKey: 'operations',
                  children: [
                    _drawerSection(
                      title: 'Station Operation',
                      sectionKey: 'station_operation',
                      isSubSection: true,
                      children: [
                        _drawerItem('Asset Register', 'asset_register', const AssetsListScreen()),
                        _drawerItem('Assurance Register', 'assurance_register', const AssuranceRegisterListScreen()),
                        _drawerItem('Axle Counter Reset Register', 'axle_counter_reset', const AxleCounterResetListScreen()),
                        _drawerItem('Cash Check Details Register', 'cash_check_details', const CashCheckDetailsRegisterListScreen()),
                        _drawerItem('Deep Cleaning Register', 'deep_cleaning', const DeepCleaningListScreen()),
                        _drawerItem('Divyang List', 'divyang_list', const DivyangListScreen()),
                        _drawerItem('First Aid', 'first_aid', const FirstAidRegisterListScreen()),
                        _drawerItem('Gate Pass Details', 'gate_pass_details', const GatePassDetailsList()),
                        _drawerItem('Manual Ticket Details', 'manual_ticket_details', const ManualTicketDetailsListScreen()),
                        _drawerItem('Penalty Details', 'penalty_details', const PenaltyDetailsListScreen()),
                        _drawerItem('Private Number Book', 'private_number_book', const PrivateNumberBookListScreen()),
                        _drawerItem('Service Deficiency Register Form', 'service_deficiency_register_form', const ServiceDeficiencyRegisterForm()),
                        _drawerItem('Shift Abstract Register Inbox', 'shift_abstract_inbox', const ShiftAbstractRegisterListScreen()),
                        _drawerItem('Station Diary', 'station_diary', StationDiaryScreen()),
                        _drawerItem('Station Failure', 'station_failure', StationFailureListScreen()),
                        _drawerItem('Station Instruction Register', 'station_instruction', const StationInstructionRegisterListScreen()),
                        _drawerItem('TOM Shift Login', 'tom_shift_login', const TomShiftLoginListScreen()),
                      ],
                    ),
                    _drawerSection(
                      title: 'CRM',
                      sectionKey: 'crm',
                      isSubSection: true,
                      children: [
                        _drawerItem('CRM Complaint & Feedback Register', 'crm_complaint_feedback', ComplaintFeedbackListScreen()),
                      ],
                    ),
                    // OCC
                    _drawerSection(
                      title: 'OCC',
                      sectionKey: 'occ',
                      isSubSection: true,
                      children: [
                        // _drawerItem('TSR Register', 'tsr_register', const ViewDetailScreen()),
                        _drawerItem('OCC Failure', 'occ_failure', const OCCFailureScreen()),
                      ],
                    ),
                    // CMS
                    _drawerSection(
                      title: 'CMS',
                      sectionKey: 'cms',
                      isSubSection: true,
                      children: [
                        _drawerItem('Quality Checklist', 'quality_checklist', null),
                      ],
                    ),
                  ],
                ),
                // Inventory
                _drawerSection(
                  title: 'Inventory',
                  sectionKey: 'inventory',
                  children: [
                    _drawerItem('Inventory List', 'inventory_list', null),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: CustButton(
              name: 'LogOut',
              size: 36,
              onSelected: (_) => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginView())),
              color1: AppColors.textColor3,
              textColor: Colors.white,
            ),
          ),
          Padding(
            padding:EdgeInsets.only(bottom: 16,left: 16,right: 16),
            child: CustText(
              name: 'Version 1.0.0',
              size: 1.2,
              color: AppColors.textColor,
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
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.only(left: isSubSection ? 32 : 16, right: 16),
        title: CustText(
          name: title,
          size: isSubSection ? 1.6 : 1.8,
          color: AppColors.textColor,
          fontWeightName: isSubSection ? FontWeight.w600 : FontWeight.w700,
        ),
        initiallyExpanded: 
          isSubSection ? _openSubSections.contains(sectionKey) : 
          _openSections.contains(sectionKey),
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
        iconColor: AppColors.textColor,
        collapsedIconColor: AppColors.textColor,
      ),
    );
  }

  Widget _drawerItem(String name, String key, Widget? screen) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      title: CustText(
        name: name,
        size: 1.5,
        color: _selectedMenu == key ? AppColors.textColor3 : AppColors.textColor,
        fontWeightName: _selectedMenu == key ? FontWeight.w600 : FontWeight.w400,
      ),
      onTap: () {
        if(screen==""||screen==null){
          Navigator.pop(context);
        }else {
          _onMenuTap(key, screen!);
        }
        },
      selected: _selectedMenu == key,
      selectedTileColor: AppColors.textFieldFillColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}