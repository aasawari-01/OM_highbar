class ActionTakenModel {
  final int? id;
  final String actionTaken;
  final String? description;
  final String? systemGroup;
  final String? actionCode;
  final String? actionDescr;
  final String? createdOn;
  final String? updatedOn;

  ActionTakenModel({
    this.id,
    required this.actionTaken,
    this.description,
    this.systemGroup,
    this.actionCode,
    this.actionDescr,
    this.createdOn,
    this.updatedOn,
  });

  factory ActionTakenModel.fromJson(Map<String, dynamic> json) {
    return ActionTakenModel(
      id: json['Id'] as int? ?? json['id'] as int? ?? json['ID'] as int?,
      actionTaken: json['ActionTaken']?.toString() ?? json['actionTaken']?.toString() ?? json['ActionCode']?.toString() ?? '',
      description: json['Description']?.toString() ?? json['description']?.toString() ?? json['ActionDescr']?.toString(),
      systemGroup: json['SystemGroup']?.toString(),
      actionCode: json['ActionCode']?.toString(),
      actionDescr: json['ActionDescr']?.toString(),
      createdOn: json['CreatedOn']?.toString() ?? json['createdOn']?.toString(),
      updatedOn: json['UpdatedOn']?.toString() ?? json['updatedOn']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'actionTaken': actionTaken,
    'description': description,
    'systemGroup': systemGroup,
    'actionCode': actionCode,
    'actionDescr': actionDescr,
    'createdOn': createdOn,
    'updatedOn': updatedOn,
  };
}
