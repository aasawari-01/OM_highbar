class RstMaterial {
  final int? materialRowId;
  final String? material;
  final String? type;

  RstMaterial({
    this.materialRowId,
    this.material,
    this.type,
  });

  factory RstMaterial.fromJson(Map<String, dynamic> json) {
    return RstMaterial(
      materialRowId: json['materialRowId'] as int?,
      material: json['material']?.toString(),
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'materialRowId': materialRowId,
    'material': material,
    'type': type,
  };
}
