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
      deptId: json['deptId'] as int?,
      deptName: json['deptName']?.toString() ?? '',
      workCenter: json['workCenter']?.toString() ?? json['deptCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'deptId': deptId,
    'deptName': deptName,
    'workCenter': workCenter,
  };
}