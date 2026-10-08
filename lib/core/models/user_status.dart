class UserStatus {
  final int? statusId;
  final String? statusName;
  final String? statusDescr;

  UserStatus({
    this.statusId,
    this.statusName,
    this.statusDescr,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      statusId: json['StatusId'] != null ? int.tryParse(json['StatusId'].toString()) : json['statusId'] as int?,
      statusName: json['StatusName']?.toString() ?? json['statusName']?.toString(),
      statusDescr: json['StatusDescr']?.toString() ?? json['statusDescr']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'statusId': statusId,
    'statusName': statusName,
    'statusDescr': statusDescr,
  };
}
