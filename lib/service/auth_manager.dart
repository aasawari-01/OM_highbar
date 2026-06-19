import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../feature/auth_login/model/login_response.dart';

class AuthManager {
  // Singleton instance
  static final AuthManager _instance = AuthManager._internal();

  factory AuthManager() {
    return _instance;
  }

  AuthManager._internal();

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyToken = 'token';
  static const String _keyUserName = 'user_name';
  static const String _keyFullName = 'full_name';
  static const String _keyDeptMaster = 'dept_master';
  static const String _keyRoleMaster = 'role_master';
  static const String _keySelectedDeptId = 'selected_dept_id';
  static const String _keySelectedRoleId = 'selected_role_id';

  static const String _keyRememberMe = 'remember_me';

  // Save login data
  Future<void> login(LoginResponse response, {bool rememberMe = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setBool(_keyRememberMe, rememberMe);
    await prefs.setString(_keyUserId, response.userId?.toString() ?? '');
    await prefs.setString(_keyToken, response.token ?? '');
    await prefs.setString(_keyUserName, response.userName ?? '');
    await prefs.setString(_keyFullName, response.fullName ?? '');
    
    // Store lists as JSON strings
    await prefs.setString(_keyDeptMaster, jsonEncode(response.deptMaster.map((e) => e.toJson()).toList()));
    await prefs.setString(_keyRoleMaster, jsonEncode(response.roleMaster.map((e) => e.toJson()).toList()));
    
    // Default selected to first in list if available
    if (response.deptMaster.isNotEmpty) {
       await prefs.setInt(_keySelectedDeptId, response.deptMaster.first.deptId ?? 0);
    }
    if (response.roleMaster.isNotEmpty) {
       await prefs.setInt(_keySelectedRoleId, response.roleMaster.first.roleId ?? 0);
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Check if user selected remember me
  Future<bool> isRememberMe() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  // Get user ID
  Future<String?> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // Get user name
  Future<String?> getUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  // Get token
  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<String?> getFullName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFullName);
  }

  Future<List<DeptMaster>> getDeptMaster() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_keyDeptMaster);
    if (json == null) return [];
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((e) => DeptMaster.fromJson(e)).toList();
  }

  Future<List<RoleMaster>> getRoleMaster() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_keyRoleMaster);
    if (json == null) return [];
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((e) => RoleMaster.fromJson(e)).toList();
  }

  Future<void> setSelectedDept(int deptId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySelectedDeptId, deptId);
  }

  Future<int?> getSelectedDeptId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySelectedDeptId);
  }

  Future<void> setSelectedRole(int roleId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySelectedRoleId, roleId);
  }

  Future<int?> getSelectedRoleId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySelectedRoleId);
  }

  // Logout and clear data
  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
