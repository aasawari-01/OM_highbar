class NatureOfWorkModel {
  final int? natureOfWorkId;
  final String? natureOfWorkName;
  final String? description;
  final String? createdOn;
  final String? updatedOn;

  NatureOfWorkModel({
    this.natureOfWorkId,
    this.natureOfWorkName,
    this.description,
    this.createdOn,
    this.updatedOn,
  });

  factory NatureOfWorkModel.fromJson(Map<String, dynamic> json) {
    return NatureOfWorkModel(
      natureOfWorkId: json['natureOfWorkId'] as int? ?? json['NatureOfWorkId'] as int?,
      natureOfWorkName: json['natureOfWorkName']?.toString() ?? json['NatureOfWorkName']?.toString(),
      description: json['description']?.toString() ?? json['Description']?.toString(),
      createdOn: json['createdOn']?.toString() ?? json['CreatedOn']?.toString(),
      updatedOn: json['updatedOn']?.toString() ?? json['UpdatedOn']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'natureOfWorkId': natureOfWorkId,
    'natureOfWorkName': natureOfWorkName,
    'description': description,
    'createdOn': createdOn,
    'updatedOn': updatedOn,
  };
}
