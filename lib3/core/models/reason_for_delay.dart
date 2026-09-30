class ReasonForDelayModel {
  final int? reasonId;
  final String? reasonName;
  final String? description;
  final String? createdOn;
  final String? updatedOn;

  ReasonForDelayModel({
    this.reasonId,
    this.reasonName,
    this.description,
    this.createdOn,
    this.updatedOn,
  });

  factory ReasonForDelayModel.fromJson(Map<String, dynamic> json) {
    return ReasonForDelayModel(
      reasonId: json['reasonId'] as int? ?? json['ReasonId'] as int?,
      reasonName: json['reasonName']?.toString() ?? json['ReasonName']?.toString(),
      description: json['description']?.toString() ?? json['Description']?.toString(),
      createdOn: json['createdOn']?.toString() ?? json['CreatedOn']?.toString(),
      updatedOn: json['updatedOn']?.toString() ?? json['UpdatedOn']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'reasonId': reasonId,
    'reasonName': reasonName,
    'description': description,
    'createdOn': createdOn,
    'updatedOn': updatedOn,
  };
}
