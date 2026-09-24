class RcaFailureCategoryModel {
  final int? failureCategoryId;
  final String? systems;
  final String? failureCategory;
  final String? workCenter;
  final int? businessArea;
  final String? createdOn;
  final int? createdBy;
  final int? isActive;

  RcaFailureCategoryModel({
    this.failureCategoryId,
    this.systems,
    this.failureCategory,
    this.workCenter,
    this.businessArea,
    this.createdOn,
    this.createdBy,
    this.isActive,
  });

  factory RcaFailureCategoryModel.fromJson(Map<String, dynamic> json) {
    final result = RcaFailureCategoryModel(
      failureCategoryId: int.tryParse(json['failureCategoryId']?.toString() ?? '') ??
          int.tryParse(json['FailureCategoryId']?.toString() ?? '') ??
          int.tryParse(json['ID']?.toString() ?? '') ??
          int.tryParse(json['id']?.toString() ?? '') ??
          int.tryParse(json['FailureCategoryID']?.toString() ?? ''),
      systems: json['systems']?.toString() ??
          json['Systems']?.toString() ??
          json['System']?.toString() ??
          json['system']?.toString(),
      failureCategory: json['failureCategory']?.toString() ??
          json['FailureCategory']?.toString() ??
          json['FailureCategoryName']?.toString() ??
          json['failureCategoryName']?.toString(),
      workCenter: json['workCenter']?.toString() ??
          json['WorkCenter']?.toString() ??
          json['workcenter']?.toString(),
      businessArea: int.tryParse(json['businessArea']?.toString() ?? '') ??
                    int.tryParse(json['BusinessArea']?.toString() ?? '') ??
                    int.tryParse(json['businessarea']?.toString() ?? ''),
      createdOn: json['createdOn']?.toString() ??
          json['CreatedOn']?.toString() ??
          json['createdon']?.toString(),
      createdBy: int.tryParse(json['createdBy']?.toString() ?? '') ??
                 int.tryParse(json['CreatedBy']?.toString() ?? '') ??
                 int.tryParse(json['createdby']?.toString() ?? ''),
      isActive: int.tryParse(json['isActive']?.toString() ?? '') ??
                int.tryParse(json['IsActive']?.toString() ?? '') ??
                int.tryParse(json['isactive']?.toString() ?? ''),
    );
    return result;
  }

  Map<String, dynamic> toJson() => {
    'failureCategoryId': failureCategoryId,
    'systems': systems,
    'failureCategory': failureCategory,
    'workCenter': workCenter,
    'businessArea': businessArea,
    'createdOn': createdOn,
    'createdBy': createdBy,
    'isActive': isActive,
  };
}
