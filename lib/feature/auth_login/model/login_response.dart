class LoginResponse {
  final int? id;
  final int? userId;
  final String? userName;
  final String? password;
  final String? uid;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? photo;
  final String? doj;
  final String? dob;
  final int? departmentId;
  final String? departmentName;
  final int? designationId;
  final String? designationName;
  final String? message;
  final int? messageCode;
  final String? token;
  final int? businessArea;
  final String? empCode;
  final bool? isDefault;
  final String? userNo;
  final bool? isONM;
  final String? subtype;
  final String? pageUrl;
  final String? employeeType;
  final String? employeeSubGroupName;
  final String? itDeclrationMsg;
  final String? itDeclrationPopup;
  final String? itDeclrationSubmit;
  final String? ipAddress;
  final int? isNewMenuVisible;

  final List<DeptMaster> deptMaster;
  final List<RoleMaster> roleMaster;
  final List<RoleAndDeptMaster> roleAndDeptMasters;

  LoginResponse({
    this.id,
    this.userId,
    this.userName,
    this.password,
    this.uid,
    this.firstName,
    this.lastName,
    this.fullName,
    this.photo,
    this.doj,
    this.dob,
    this.departmentId,
    this.departmentName,
    this.designationId,
    this.designationName,
    this.message,
    this.messageCode,
    this.token,
    this.businessArea,
    this.empCode,
    this.isDefault,
    this.userNo,
    this.isONM,
    this.subtype,
    this.pageUrl,
    this.employeeType,
    this.employeeSubGroupName,
    this.itDeclrationMsg,
    this.itDeclrationPopup,
    this.itDeclrationSubmit,
    this.ipAddress,
    this.isNewMenuVisible,
    this.deptMaster = const [],
    this.roleMaster = const [],
    this.roleAndDeptMasters = const [],
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      password: json['password'],
      uid: json['uid'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      fullName: json['fullName'],
      photo: json['photo'],
      doj: json['doj'],
      dob: json['dob'],
      departmentId: json['departmentId'],
      departmentName: json['departmentName'],
      designationId: json['designationId'],
      designationName: json['designationName'],
      message: json['message'],
      messageCode: json['messageCode'],
      token: json['token'],
      businessArea: json['businessArea'] is int
          ? json['businessArea']
          : int.tryParse(json['businessArea']?.toString() ?? ''),
      empCode: json['empCode'],
      isDefault: json['isDefault'],
      userNo: json['userNo'],
      isONM: json['isONM'],
      subtype: json['subtype'],
      pageUrl: json['pageUrl'],
      employeeType: json['employeeType'],
      employeeSubGroupName: json['employeeSubGroupName'],
      itDeclrationMsg: json['itDeclrationMsg'],
      itDeclrationPopup: json['itDeclrationPopup'],
      itDeclrationSubmit: json['itDeclrationSubmit'],
      ipAddress: json['ipAddress'],
      isNewMenuVisible: json['isNewMenuVisible'],
      deptMaster: (json['deptMaster'] as List<dynamic>?)
          ?.map((e) => DeptMaster.fromJson(e))
          .toList() ??
          [],
      roleMaster: (json['roleMaster'] as List<dynamic>?)
          ?.map((e) => RoleMaster.fromJson(e))
          .toList() ??
          [],
      roleAndDeptMasters: (json['roleAndDeptMasters'] as List<dynamic>?)
          ?.map((e) => RoleAndDeptMaster.fromJson(e))
          .toList() ??
          [],
    );
  }
}
class DeptMaster {
  final int? deptId;
  final String? deptName;
  final String? deptCode;

  DeptMaster({this.deptId, this.deptName, this.deptCode});

  factory DeptMaster.fromJson(Map<String, dynamic> json) {
    return DeptMaster(
      deptId: json['deptId'] as int?,
      deptName: json['deptName'] as String?,
      deptCode: json['deptCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'deptId': deptId,
    'deptName': deptName,
    'deptCode': deptCode,
  };
}

class RoleMaster {
  final int? roleId;
  final String? roleDescr;

  RoleMaster({this.roleId, this.roleDescr});

  factory RoleMaster.fromJson(Map<String, dynamic> json) {
    return RoleMaster(
      roleId: json['roleId'] as int?,
      roleDescr: json['roleDescr'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'roleId': roleId,
    'roleDescr': roleDescr,
  };
}



class RoleAndDeptMaster {
  final int? deptId;
  final String? deptName;
  final String? deptCode;
  final int? roleId;
  final String? roleDescr;

  RoleAndDeptMaster({
    this.deptId,
    this.deptName,
    this.deptCode,
    this.roleId,
    this.roleDescr,
  });

  factory RoleAndDeptMaster.fromJson(Map<String, dynamic> json) {
    return RoleAndDeptMaster(
      deptId: json['deptId'],
      deptName: json['deptName'],
      deptCode: json['deptCode'],
      roleId: json['roleId'],
      roleDescr: json['roleDescr'],
    );
  }

  Map<String, dynamic> toJson() => {
    'deptId': deptId,
    'deptName': deptName,
    'deptCode': deptCode,
    'roleId': roleId,
    'roleDescr': roleDescr,
  };
}