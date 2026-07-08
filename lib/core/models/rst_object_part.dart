class RstObjectPart {
  final int? id;
  final String? objectCodeDesc;

  RstObjectPart({
    this.id,
    this.objectCodeDesc,
  });

  factory RstObjectPart.fromJson(Map<String, dynamic> json) {
    return RstObjectPart(
      id: json['id'] as int?,
      objectCodeDesc: json['objectCodeDesc']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'objectCodeDesc': objectCodeDesc,
  };
}
