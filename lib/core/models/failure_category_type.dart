class FailureCategoryTypeModel {
  final int? failureCategoryTypeId;
  final String? failureCategoryType;
  final String? description;
  final String? createdOn;
  final String? updatedOn;

  FailureCategoryTypeModel({
    this.failureCategoryTypeId,
    this.failureCategoryType,
    this.description,
    this.createdOn,
    this.updatedOn,
  });

  factory FailureCategoryTypeModel.fromJson(Map<String, dynamic> json) {
    return FailureCategoryTypeModel(
      failureCategoryTypeId: json['failureCategoryTypeId'] as int? ?? json['FailureCategoryTypeId'] as int?,
      failureCategoryType: json['failureCategoryType']?.toString() ?? json['FailureCategoryType']?.toString(),
      description: json['description']?.toString() ?? json['Description']?.toString(),
      createdOn: json['createdOn']?.toString() ?? json['CreatedOn']?.toString(),
      updatedOn: json['updatedOn']?.toString() ?? json['UpdatedOn']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'failureCategoryTypeId': failureCategoryTypeId,
    'failureCategoryType': failureCategoryType,
    'description': description,
    'createdOn': createdOn,
    'updatedOn': updatedOn,
  };
}
