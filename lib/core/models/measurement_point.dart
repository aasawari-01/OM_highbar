class MeasurementPointModel {
  final int? measId;
  final String measPoint;
  final String measPointDesc;
  final String measRangeUnit;
  final String internalCharNo;
  final String targetValue;
  final String objectNo;
  final String? createdOn;
  final String? updatedOn;

  MeasurementPointModel({
    this.measId,
    required this.measPoint,
    required this.measPointDesc,
    required this.measRangeUnit,
    required this.internalCharNo,
    required this.targetValue,
    required this.objectNo,
    this.createdOn,
    this.updatedOn,
  });

  factory MeasurementPointModel.fromJson(Map<String, dynamic> json) {
    return MeasurementPointModel(
      measId: json['measId'] as int? ?? json['MeasId'] as int?,
      measPoint: json['measPoint']?.toString() ?? json['MeasPoint']?.toString() ?? '',
      measPointDesc: json['measPointDesc']?.toString() ?? json['MeasPointDesc']?.toString() ?? '',
      measRangeUnit: json['measRangeUnit']?.toString() ?? json['MeasRangeUnit']?.toString() ?? '',
      internalCharNo: json['internalCharNo']?.toString() ?? json['InternalCharNo']?.toString() ?? '',
      targetValue: json['targetValue']?.toString() ?? json['TargetValue']?.toString() ?? '',
      objectNo: json['objectNo']?.toString() ?? json['ObjectNo']?.toString() ?? '',
      createdOn: json['createdOn']?.toString() ?? json['CreatedOn']?.toString(),
      updatedOn: json['updatedOn']?.toString() ?? json['UpdatedOn']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'measId': measId,
    'measPoint': measPoint,
    'measPointDesc': measPointDesc,
    'measRangeUnit': measRangeUnit,
    'internalCharNo': internalCharNo,
    'targetValue': targetValue,
    'objectNo': objectNo,
    'createdOn': createdOn,
    'updatedOn': updatedOn,
  };
}
