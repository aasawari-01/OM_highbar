class CauseOfFailureModel {
  final int? causeOfFailureId;
  final String cause;
  final int? failureCategoryId;
  final String? systems;
  final String? workCenter;
  final int? businessArea;
  final String? createdOn;
  final int? createdBy;
  final int? isActive;

  CauseOfFailureModel({
    this.causeOfFailureId,
    required this.cause,
    this.failureCategoryId,
    this.systems,
    this.workCenter,
    this.businessArea,
    this.createdOn,
    this.createdBy,
    this.isActive,
  });

  factory CauseOfFailureModel.fromJson(Map<String, dynamic> json) {
    return CauseOfFailureModel(
      // Handle both camelCase (from toJson/local cache) and PascalCase (from API)
      causeOfFailureId: int.tryParse(json['causeOfFailureId']?.toString() ?? '')
          ?? int.tryParse(json['CauseOfFailureId']?.toString() ?? ''),
      cause: json['cause']?.toString()
          ?? json['Cause']?.toString()
          ?? '',
      failureCategoryId: int.tryParse(json['failureCategoryId']?.toString() ?? '')
          ?? int.tryParse(json['FailureCategoryId']?.toString() ?? ''),
      systems: json['systems']?.toString()
          ?? json['Systems']?.toString(),
      workCenter: json['workCenter']?.toString()
          ?? json['WorkCenter']?.toString(),
      businessArea: int.tryParse(json['businessArea']?.toString() ?? '')
          ?? int.tryParse(json['BusinessArea']?.toString() ?? ''),
      createdOn: json['createdOn']?.toString()
          ?? json['CreatedOn']?.toString(),
      createdBy: int.tryParse(json['createdBy']?.toString() ?? '')
          ?? int.tryParse(json['CreatedBy']?.toString() ?? ''),
      isActive: int.tryParse(json['isActive']?.toString() ?? '')
          ?? int.tryParse(json['IsActive']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'CauseOfFailureId': causeOfFailureId,
    'Cause': cause,
    'FailureCategoryId': failureCategoryId,
    'Systems': systems,
    'WorkCenter': workCenter,
    'BusinessArea': businessArea,
    'CreatedOn': createdOn,
    'CreatedBy': createdBy,
    'IsActive': isActive,
  };
}
