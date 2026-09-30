class CorrFailureType {
  final int? id;
  final String? failureType;

  CorrFailureType({
    this.id,
    this.failureType,
  });

  factory CorrFailureType.fromJson(Map<String, dynamic> json) {
    return CorrFailureType(
      id: json['ID'] != null ? int.tryParse(json['ID'].toString()) : json['id'] as int?,
      failureType: json['FailureType']?.toString() ?? json['failureType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'failureType': failureType,
  };
}
