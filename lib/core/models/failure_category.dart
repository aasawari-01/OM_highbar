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
      id: json['id'] as int?,
      failureCategoryType: json['failureCategoryType']?.toString(),
      orderNo: json['orderNo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'failureCategoryType': failureCategoryType,
    'orderNo': orderNo,
  };
}
