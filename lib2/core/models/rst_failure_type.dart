class RstFailureType {
  final int? id;
  final String? failureType;

  RstFailureType({
    this.id,
    this.failureType,
  });

  factory RstFailureType.fromJson(Map<String, dynamic> json) {
    return RstFailureType(
      id: json['id'] as int?,
      failureType: json['failureType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'failureType': failureType,
  };
}
