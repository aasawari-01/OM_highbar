class RstTrainStatus {
  final int? statusId;
  final String? statusDescr;

  RstTrainStatus({
    this.statusId,
    this.statusDescr,
  });

  factory RstTrainStatus.fromJson(Map<String, dynamic> json) {
    return RstTrainStatus(
      statusId: json['statusId'] as int?,
      statusDescr: json['statusDescr']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'statusId': statusId,
    'statusDescr': statusDescr,
  };
}
