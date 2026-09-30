class DepartmentModel {
  final int? deptId;
  final String deptName;
  final String workCenter;

  DepartmentModel({
    this.deptId,
    required this.deptName,
    required this.workCenter,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      deptId: json['DeptId'] ?? json['deptId'] as int?,
      deptName: json['DeptName']?.toString() ?? json['deptName']?.toString() ?? '',
      workCenter: json['WorkCenter']?.toString() ?? json['workCenter']?.toString() ?? json['DeptCode']?.toString() ?? json['deptCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'deptId': deptId,
    'deptName': deptName,
    'workCenter': workCenter,
  };
}
