class PriorityModel {
  final int? priorityId;
  final String? priorityDesc;

  PriorityModel({
    this.priorityId,
    this.priorityDesc,
  });

  factory PriorityModel.fromJson(Map<String, dynamic> json) {
    return PriorityModel(
      priorityId: json['PriorityId'] ?? json['priorityId'] as int?,
      priorityDesc: json['PriorityDesc']?.toString() ?? json['priorityDesc']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'priorityId': priorityId,
    'priorityDesc': priorityDesc,
  };
}
