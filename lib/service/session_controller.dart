import 'package:get/get.dart';
import '../feature/auth_login/model/login_response.dart';
import '../service/auth_manager.dart';
import '../service/local_database_service.dart';

class SessionController extends GetxController {
  final RxList<DeptMaster> departments = <DeptMaster>[].obs;
  final RxList<RoleMaster> roles = <RoleMaster>[].obs;
  
  final Rxn<DeptMaster> selectedDepartment = Rxn<DeptMaster>();
  final Rxn<RoleMaster> selectedRole = Rxn<RoleMaster>();
  final RxList<Map<String, dynamic>> userMappings = <Map<String, dynamic>>[].obs;
  final RxString userName = "".obs;

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
    final List<DeptMaster> depts = await AuthManager().getDeptMaster();
    final List<RoleMaster> allRoles = await AuthManager().getRoleMaster();
    
    // Load mappings from DB
    final List<Map<String, dynamic>> dbUsers = await LocalDatabaseService().getMasterUsers();
    
    // Filter mappings to only allowed roles
    userMappings.assignAll(dbUsers.where((u) {
      final roleDesc = u['roleDescr']?.toString() ?? '';
      return isRoleAllowed(roleDesc);
    }).toList());
    
    if (userMappings.isNotEmpty) {
      final mappedDepts = <DeptMaster>[];
      final mappedRoles = <RoleMaster>[];
      for (var u in userMappings) {
        final deptId = u['deptId'] as int?;
        final deptName = u['deptName']?.toString();
        final roleId = u['roleId'] as int?;
        final roleDescr = u['roleDescr']?.toString();
        
        if (deptId != null && !mappedDepts.any((d) => d.deptId == deptId)) {
          mappedDepts.add(DeptMaster(deptId: deptId, deptName: deptName));
        }
        if (roleId != null && !mappedRoles.any((r) => r.roleId == roleId)) {
          mappedRoles.add(RoleMaster(roleId: roleId, roleDescr: roleDescr));
        }
      }
      departments.assignAll(mappedDepts.isNotEmpty ? mappedDepts : depts);
      roles.assignAll(mappedRoles.isNotEmpty ? mappedRoles : allRoles.where((r) => isRoleAllowed(r.roleDescr ?? '')).toList());
    } else {
      departments.assignAll(depts);
      // Only expose allowed mobile roles to the UI
      roles.assignAll(allRoles.where((r) => isRoleAllowed(r.roleDescr ?? '')).toList());
    }
    
    final int? selectedDeptId = await AuthManager().getSelectedDeptId();
    final int? selectedRoleId = await AuthManager().getSelectedRoleId();
    
    if (selectedDeptId != null && departments.isNotEmpty) {
      selectedDepartment.value = departments.firstWhere(
        (e) => e.deptId == selectedDeptId, 
        orElse: () => departments.first
      );
    } else if (departments.isNotEmpty) {
      selectedDepartment.value = departments.first;
    }

    if (selectedRoleId != null && roles.isNotEmpty) {
      // Try to find the saved role among ALLOWED roles; if not found, pick first allowed
      selectedRole.value = roles.firstWhere(
        (e) => e.roleId == selectedRoleId, 
        orElse: () => roles.first
      );
    } else if (roles.isNotEmpty) {
      // First time / no saved role — pick first allowed mobile role
      selectedRole.value = roles.first;
      // Persist this default so it's stable on next load
      await AuthManager().setSelectedRole(roles.first.roleId ?? 0);
    } else {
      selectedRole.value = null; // No allowed roles found
    }
  }

  Future<void> changeDepartment(DeptMaster dept) async {
    selectedDepartment.value = dept;
    await AuthManager().setSelectedDept(dept.deptId ?? 0);
  }

  Future<void> changeRole(RoleMaster role) async {
    selectedRole.value = role;
    await AuthManager().setSelectedRole(role.roleId ?? 0);
  }
}
