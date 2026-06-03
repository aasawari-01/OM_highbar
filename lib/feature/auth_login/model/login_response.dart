class LoginResponse {
  final int? id;
  final int? userId;
  final String? userName;
  final String? fullName;
  final String? photo;
  final String? doj;
  final String? dob;
  final int? departmentId;
  final String? departmentName;
  final String? designationName;
  final String? message;
  final int? messageCode;
  final String? token;
  final List<DeptMaster> deptMaster;
  final List<RoleMaster> roleMaster;

  LoginResponse({
    this.id,
    this.userId,
    this.userName,
    this.fullName,
    this.photo,
    this.doj,
    this.dob,
    this.departmentId,
    this.departmentName,
    this.designationName,
    this.message,
    this.messageCode,
    this.token,
    this.deptMaster = const [],
    this.roleMaster = const [],
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      userName: json['userName'] as String?,
      fullName: json['fullName'] as String?,
      photo: json['photo'] as String?,
      doj: json['doj'] as String?,
      dob: json['dob'] as String?,
      departmentId: json['departmentId'] as int?,
      departmentName: json['departmentName'] as String?,
      designationName: json['designationName'] as String?,
      message: json['message'] as String?,
      messageCode: json['messageCode'] as int?,
      token: json['token'] as String?,
      deptMaster: (json['deptMaster'] as List<dynamic>?)
              ?.map((e) => DeptMaster.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      roleMaster: (json['roleMaster'] as List<dynamic>?)
              ?.map((e) => RoleMaster.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
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
