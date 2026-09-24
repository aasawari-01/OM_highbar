class FailureCategoryModel {
  final int? id;
  final String? failureCategoryType;
  final String? orderNo;

  FailureCategoryModel({
    this.id,
    this.failureCategoryType,
    this.orderNo,
  });

  factory FailureCategoryModel.fromJson(Map<String, dynamic> json) {
    return FailureCategoryModel(
      id: json['ID'] as int? ?? json['id'] as int?,
      failureCategoryType: json['FailureCategoryType']?.toString() ?? json['failureCategoryType']?.toString(),
      orderNo: json['OrderNo']?.toString() ?? json['orderNo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'failureCategoryType': failureCategoryType,
    'orderNo': orderNo,
  };
}
