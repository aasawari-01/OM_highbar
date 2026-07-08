class DepartmentModel {
  final int? deptId;
  final String deptName;
  final String deptCode;

  DepartmentModel({
    this.deptId,
    required this.deptName,
    required this.deptCode,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      deptId: json['deptId'] as int?,
      deptName: json['deptName']?.toString() ?? '',
      deptCode: json['deptCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'deptId': deptId,
    'deptName': deptName,
    'deptCode': deptCode,
  };
}
