import 'package:get/get.dart';
import '../feature/auth_login/model/login_response.dart';
import '../service/auth_manager.dart';

class SessionController extends GetxController {
  final RxList<DeptMaster> departments = <DeptMaster>[].obs;
  final RxList<RoleMaster> roles = <RoleMaster>[].obs;
  
  final Rxn<DeptMaster> selectedDepartment = Rxn<DeptMaster>();
  final Rxn<RoleMaster> selectedRole = Rxn<RoleMaster>();
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
    final List<RoleMaster> rs = await AuthManager().getRoleMaster();
    
    departments.assignAll(depts);
    roles.assignAll(rs);
    
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
      selectedRole.value = roles.firstWhere(
        (e) => e.roleId == selectedRoleId, 
        orElse: () => roles.first
      );
    } else if (roles.isNotEmpty) {
      selectedRole.value = roles.first;
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
