class JointInspectionHistory {
  final int? jiId;
  final int? notificationId;
  final int? deptId;
  final int? equipmentId;
  final String? functionLocationId;
  final int? jiStatus;
  final int? assignedTo;
  final String? functionalLocation;
  final String? equipmentDescription;
  final String? statusName;
  final String? remark;
  final String? assginedUser;
  final String? deptName;
  final String? userRemark;
  final String? assginedOn;
  final String? type;
  final int? createdBy;
  final String? createdByName;

  JointInspectionHistory({
    this.jiId,
    this.notificationId,
    this.deptId,
    this.equipmentId,
    this.functionLocationId,
    this.jiStatus,
    this.assignedTo,
    this.functionalLocation,
    this.equipmentDescription,
    this.statusName,
    this.remark,
    this.assginedUser,
    this.deptName,
    this.userRemark,
    this.assginedOn,
    this.type,
    this.createdBy,
    this.createdByName,
  });

  factory JointInspectionHistory.fromJson(Map<String, dynamic> json) {
    return JointInspectionHistory(
      jiId: json['jiId'] as int?,
      notificationId: json['notificationId'] as int?,
      deptId: json['deptId'] as int?,
      equipmentId: json['equipmentId'] as int?,
      functionLocationId: json['functionLocationId']?.toString(),
      jiStatus: json['jiStatus'] as int?,
      assignedTo: json['assignedTo'] as int?,
      functionalLocation: json['functionalLocation']?.toString(),
      equipmentDescription: json['equipmentDescription']?.toString(),
      statusName: json['statusName']?.toString(),
      remark: json['remark']?.toString(),
      assginedUser: json['assginedUser']?.toString(),
      deptName: json['deptName']?.toString(),
      userRemark: json['userRemark']?.toString(),
      assginedOn: json['assginedOn']?.toString(),
      type: json['type']?.toString(),
      createdBy: json['createdBy'] as int?,
      createdByName: json['createdByName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jiId': jiId,
      'notificationId': notificationId,
      'deptId': deptId,
      'equipmentId': equipmentId,
      'functionLocationId': functionLocationId,
      'jiStatus': jiStatus,
      'assignedTo': assignedTo,
      'functionalLocation': functionalLocation,
      'equipmentDescription': equipmentDescription,
      'statusName': statusName,
      'remark': remark,
      'assginedUser': assginedUser,
      'deptName': deptName,
      'userRemark': userRemark,
      'assginedOn': assginedOn,
      'type': type,
      'createdBy': createdBy,
      'createdByName': createdByName,
    };
  }

  // Helper getters for display
  String get assignedUserName => assginedUser ?? assignedTo?.toString() ?? '';
  String get assignedDateTime => assginedOn ?? '';
  String get status => statusName ?? '';
  String get department => deptName ?? '';
}
