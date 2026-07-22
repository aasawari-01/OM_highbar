import 'dart:developer';

import 'package:get/get.dart';
import '../feature/auth_login/model/login_response.dart';
import '../service/auth_manager.dart';
import '../service/local_database_service.dart';
import '../core/models/master_user.dart';

class SessionController extends GetxController {
  final RxList<DeptMaster> departments = <DeptMaster>[].obs;
  final RxList<RoleMaster> roles = <RoleMaster>[].obs;
  
  final Rxn<DeptMaster> selectedDepartment = Rxn<DeptMaster>();
  final Rxn<RoleMaster> selectedRole = Rxn<RoleMaster>();
  final RxList<MasterUserModel> userMappings = <MasterUserModel>[].obs;

  // after
  final RxList<RoleAndDeptMaster> roleDeptMappings = <RoleAndDeptMaster>[].obs;

  final RxString userName = "".obs;
  final RxString designationName = "".obs;
  final selectedStationId = Rxn<String>();
  final selectedStationName = Rxn<String>();
  final selectedStationCode = Rxn<String>();

  String get userInitials {
    if (userName.value.isEmpty) return "??";
    List<String> names = userName.value.trim().split(" ");
    if (names.length >= 2) {
      return (names[0][0] + names[1][0]).toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return "??";
  }

  @override
  void onInit() {
    super.onInit();
    loadSessionData();
  }

  final allowedMobileRoles = [
    "Technician",
    "Junior Engineer",
    "Station Controller",
    "OCC Controller",
    "Chief Engineer"
  ];

  bool isRoleAllowed(String roleName) {
    return allowedMobileRoles.any((allowed) => 
      roleName.trim().toLowerCase() == allowed.trim().toLowerCase()
    );
  }
  Future<void> loadSessionData() async {
    userName.value = await AuthManager().getFullName() ?? "";
    designationName.value = await AuthManager().getDesignationName() ?? "";

    final String? currentUserId = await AuthManager().getUserId();
    final List<DeptMaster> depts = await AuthManager().getDeptMaster();
    final List<RoleMaster> roles=await AuthManager().getRoleMaster();
    final List<RoleAndDeptMaster> rolDepts = await AuthManager().getRoleAndDeptMaster();

    log(" list of role master $rolDepts----$depts------$roles");



    final List<MasterUserModel> dbUsers = await LocalDatabaseService().getMasterUsers();

    // after — sourced from roleAndDeptMasters (rolDepts), no local DB, no userId filtering needed
    roleDeptMappings.assignAll(
      rolDepts.where((rd) => isRoleAllowed(rd.roleDescr ?? '')).toList(),
    );

// 1. Resolve departments first
    if (roleDeptMappings.isNotEmpty) {
      final mappedDepts = <DeptMaster>[];
      for (var rd in roleDeptMappings) {
        final deptId = rd.deptId;
        final deptName = rd.deptName;
        if (deptId != null && !mappedDepts.any((d) => d.deptId == deptId)) {
          mappedDepts.add(DeptMaster(deptId: deptId, deptName: deptName));
        }
      }

      departments.assignAll(mappedDepts.isNotEmpty ? mappedDepts : depts);
      log("deparment is $departments");
    } else {
      departments.assignAll(depts);
      log("deparment is $departments");
    }

    // 1. Resolve departments first (unchanged)
    // if (userMappings.isNotEmpty) {
    //   final mappedDepts = <DeptMaster>[];
    //   for (var u in userMappings) {
    //     final deptId = u.deptId;
    //     final deptName = u.deptName;
    //     if (deptId != null && !mappedDepts.any((d) => d.deptId == deptId)) {
    //       mappedDepts.add(DeptMaster(deptId: deptId, deptName: deptName));
    //     }
    //   }
    //
    //   for (final dept in departments) {
    //     log("Dept ID: ${dept.deptId}, Dept Name: ${dept.deptName}");
    //   }
    //
    //   departments.assignAll(mappedDepts.isNotEmpty ? mappedDepts : depts);
    //   log("deparment is ${departments}");
    // } else {
    //   departments.assignAll(depts);
    //   log("deparment is $departments");
    // }



    // 2. Resolve selectedDepartment BEFORE touching roles
    final int? selectedDeptId = await AuthManager().getSelectedDeptId();
    if (selectedDeptId != null && departments.isNotEmpty) {
      selectedDepartment.value = departments.firstWhere(
            (e) => e.deptId == selectedDeptId,
        orElse: () => departments.first,
      );
    } else if (departments.isNotEmpty) {
      selectedDepartment.value = departments.first;
    }

    // 3. NOW derive roles scoped to that department
    _refreshRolesForDept(selectedDepartment.value?.deptId);

    // 4. Resolve selectedRole from the already-scoped roles list
    final int? selectedRoleId = await AuthManager().getSelectedRoleId();

    print("data getting from $selectedDeptId---$selectedRoleId");
    if (selectedRoleId != null && roles.isNotEmpty) {
      selectedRole.value = roles.firstWhere(
            (e) => e.roleId == selectedRoleId,
        orElse: () => roles.first,
      );
    } else if (roles.isNotEmpty) {
      selectedRole.value = roles.first;
      await AuthManager().setSelectedRole(roles.first.roleId ?? 0);
    } else {
      selectedRole.value = null;
    }
  }

// after
  void _refreshRolesForDept(int? deptId) {
    if (deptId == null) {
      roles.clear();
      return;
    }
    final filtered = roleDeptMappings
        .where((rd) => rd.deptId == deptId)
        .map((rd) => RoleMaster(roleId: rd.roleId, roleDescr: rd.roleDescr))
        .toList();
    final deduped = <RoleMaster>[];
    for (var r in filtered) {
      if (!deduped.any((d) => d.roleId == r.roleId)) deduped.add(r);
    }
    roles.assignAll(deduped);
  }
  // Future<void> loadSessionData() async {
  //   userName.value = await AuthManager().getFullName() ?? "";
  //   designationName.value=await AuthManager().getDesignationName()??"";
  //
  //   final String? currentUserId = await AuthManager().getUserId();
  //   final List<DeptMaster> depts = await AuthManager().getDeptMaster();
  //   final List<RoleMaster> allRoles = await AuthManager().getRoleMaster();
  //
  //   // Load mappings from DB
  //   final List<MasterUserModel> dbUsers = await LocalDatabaseService().getMasterUsers();
  //
  //   // Filter mappings to only allowed roles AND logged-in user's userId
  //   userMappings.assignAll(dbUsers.where((u) {
  //     final roleDesc = u.roleDescr ?? '';
  //     final userId = u.userId?.toString();
  //     return isRoleAllowed(roleDesc) && (currentUserId == null || userId == currentUserId);
  //   }).toList());
  //
  //   if (userMappings.isNotEmpty) {
  //     final mappedDepts = <DeptMaster>[];
  //     final mappedRoles = <RoleMaster>[];
  //     for (var u in userMappings) {
  //       final deptId = u.deptId;
  //       final deptName = u.deptName;
  //       final roleId = u.roleId;
  //       final roleDescr = u.roleDescr;
  //
  //       if (deptId != null && !mappedDepts.any((d) => d.deptId == deptId)) {
  //         mappedDepts.add(DeptMaster(deptId: deptId, deptName: deptName));
  //       }
  //       if (roleId != null && !mappedRoles.any((r) => r.roleId == roleId)) {
  //         mappedRoles.add(RoleMaster(roleId: roleId, roleDescr: roleDescr));
  //       }
  //     }
  //     departments.assignAll(mappedDepts.isNotEmpty ? mappedDepts : depts);
  //     roles.assignAll(mappedRoles.isNotEmpty ? mappedRoles : allRoles.where((r) => isRoleAllowed(r.roleDescr ?? '')).toList());
  //   } else {
  //     departments.assignAll(depts);
  //     // Only expose allowed mobile roles to the UI
  //     roles.assignAll(allRoles.where((r) => isRoleAllowed(r.roleDescr ?? '')).toList());
  //   }
  //
  //   final int? selectedDeptId = await AuthManager().getSelectedDeptId();
  //   final int? selectedRoleId = await AuthManager().getSelectedRoleId();
  //
  //   if (selectedDeptId != null && departments.isNotEmpty) {
  //     selectedDepartment.value = departments.firstWhere(
  //       (e) => e.deptId == selectedDeptId,
  //       orElse: () => departments.first
  //     );
  //   } else if (departments.isNotEmpty) {
  //     selectedDepartment.value = departments.first;
  //   }
  //
  //   if (selectedRoleId != null && roles.isNotEmpty) {
  //     // Try to find the saved role among ALLOWED roles; if not found, pick first allowed
  //     selectedRole.value = roles.firstWhere(
  //       (e) => e.roleId == selectedRoleId,
  //       orElse: () => roles.first
  //     );
  //   } else if (roles.isNotEmpty) {
  //     // First time / no saved role — pick first allowed mobile role
  //     selectedRole.value = roles.first;
  //     // Persist this default so it's stable on next load
  //     await AuthManager().setSelectedRole(roles.first.roleId ?? 0);
  //   } else {
  //     selectedRole.value = null; // No allowed roles found
  //   }
  // }

  // Future<void> changeDepartment(DeptMaster dept) async {
  //   selectedDepartment.value = dept;
  //   await AuthManager().setSelectedDept(dept.deptId ?? 0);
  // }

  Future<void> changeDepartment(DeptMaster dept) async {
    selectedDepartment.value = dept;
    await AuthManager().setSelectedDept(dept.deptId ?? 0);
    _refreshRolesForDept(dept.deptId);
    selectedRole.value = null;
  }

  Future<void> changeRole(RoleMaster role) async {
    selectedRole.value = role;
    await AuthManager().setSelectedRole(role.roleId ?? 0);
  }
}
