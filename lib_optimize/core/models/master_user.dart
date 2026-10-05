class MasterUserModel {
  final int? userId;
  final String? firstName;
  final String? lastName;
  final String? emailId;
  final String? empCode;
  final int? businessArea;
  final int? deptId;
  final String? deptName;
  final int? roleId;
  final String? roleDescr;
  final int? designationID;
  final String? designationName;
  final String? initial;

  MasterUserModel({
    this.userId,
    this.firstName,
    this.lastName,
    this.emailId,
    this.empCode,
    this.businessArea,
    this.deptId,
    this.deptName,
    this.roleId,
    this.roleDescr,
    this.designationID,
    this.designationName,
    this.initial,
  });

  factory MasterUserModel.fromJson(Map<String, dynamic> json) {
    return MasterUserModel(
      userId: json['UserId'] != null ? int.tryParse(json['UserId'].toString()) : null,
      firstName: json['FirstName']?.toString(),
      lastName: json['LastName']?.toString(),
      emailId: json['EmailId']?.toString(),
      empCode: json['EmpCode']?.toString(),
      businessArea: json['BusinessArea'] != null ? int.tryParse(json['BusinessArea'].toString()) : null,
      deptId: json['DeptId'] != null ? int.tryParse(json['DeptId'].toString()) : null,
      deptName: json['DeptName']?.toString(),
      roleId: json['RoleId'] != null ? int.tryParse(json['RoleId'].toString()) : null,
      roleDescr: json['RoleDescr']?.toString(),
      designationID: json['DesignationID'] != null ? int.tryParse(json['DesignationID'].toString()) : null,
      designationName: json['DesignationName']?.toString(),
      initial: json['Initial']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'UserId': userId,
    'FirstName': firstName,
    'LastName': lastName,
    'EmailId': emailId,
    'EmpCode': empCode,
    'BusinessArea': businessArea,
    'DeptId': deptId,
    'DeptName': deptName,
    'RoleId': roleId,
    'RoleDescr': roleDescr,
    'DesignationID': designationID,
    'DesignationName': designationName,
    'Initial': initial,
    'userName': userName, // Add computed property for easier access
  };
  
  // Computed property for full name (with Initial)
  String get fullName {
    final init = initial != null && initial!.isNotEmpty ? '$initial ' : '';
    final first = firstName ?? '';
    final last = lastName ?? '';
    return '$init$first $last'.trim();
  }
  
  // Computed property for userName (for backward compatibility)
  String get userName => fullName;
}
