class RootCauseModel {
  final int? rootCauseId;
  final String rootCause;
  final int? causeOfFailureId;
  final int? failureCategoryId;
  final String? systems;
  final String? workCenter;
  final int? businessArea;
  final String? createdOn;
  final int? createdBy;
  final int? isActive;

  RootCauseModel({
    this.rootCauseId,
    required this.rootCause,
    this.causeOfFailureId,
    this.failureCategoryId,
    this.systems,
    this.workCenter,
    this.businessArea,
    this.createdOn,
    this.createdBy,
    this.isActive,
  });

  factory RootCauseModel.fromJson(Map<String, dynamic> json) {
    return RootCauseModel(
      rootCauseId: int.tryParse(json['rootCauseId']?.toString() ?? '') ?? 
          int.tryParse(json['RootCauseId']?.toString() ?? ''),
      rootCause: json['RootCause']?.toString() ?? json['rootCause']?.toString() ?? '',
      causeOfFailureId: int.tryParse(json['CauseOfFailureId']?.toString() ?? '') ?? 
                       int.tryParse(json['causeOfFailureId']?.toString() ?? ''),
      failureCategoryId: int.tryParse(json['FailureCategoryId']?.toString() ?? '') ??
                         int.tryParse(json['failureCategoryId']?.toString() ?? ''),
      systems: json['Systems']?.toString() ?? json['systems']?.toString(),
      workCenter: json['WorkCenter']?.toString() ?? json['workCenter']?.toString(),
      businessArea: int.tryParse(json['BusinessArea']?.toString() ?? '') ?? 
                    int.tryParse(json['businessArea']?.toString() ?? ''),
      createdOn: json['CreatedOn']?.toString() ?? json['createdOn']?.toString(),
      createdBy: int.tryParse(json['CreatedBy']?.toString() ?? '') ?? 
                 int.tryParse(json['createdBy']?.toString() ?? ''),
      isActive: int.tryParse(json['IsActive']?.toString() ?? '') ?? 
                int.tryParse(json['isActive']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'RootCauseId': rootCauseId,
    'RootCause': rootCause,
    'CauseOfFailureId': causeOfFailureId,
    'FailureCategoryId': failureCategoryId,
    'Systems': systems,
    'WorkCenter': workCenter,
    'BusinessArea': businessArea,
    'CreatedOn': createdOn,
    'CreatedBy': createdBy,
    'IsActive': isActive,
  };
}
