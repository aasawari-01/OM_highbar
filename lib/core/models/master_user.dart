class MasterUserModel {
  final int? userId;
  final String userName;
  final int? deptId;
  final String? deptName;
  final int? roleId;
  final String? roleDescr;

  MasterUserModel({
    this.userId,
    required this.userName,
    this.deptId,
    this.deptName,
    this.roleId,
    this.roleDescr,
  });

  factory MasterUserModel.fromJson(Map<String, dynamic> json) {
    return MasterUserModel(
      userId: json['userId'] as int?,
      userName: json['userName']?.toString() ?? '',
      deptId: json['deptId'] as int?,
      deptName: json['deptName']?.toString(),
      roleId: json['roleId'] as int?,
      roleDescr: json['roleDescr']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'deptId': deptId,
    'deptName': deptName,
    'roleId': roleId,
    'roleDescr': roleDescr,
  };
}
