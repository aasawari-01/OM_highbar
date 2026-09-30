class MaterialMaster {
  final int? materialRowId;
  final String? material;
  final String? type;
  final String? description;

  MaterialMaster({
    this.materialRowId,
    this.material,
    this.type,
    this.description,
  });

  factory MaterialMaster.fromJson(Map<String, dynamic> json) {
    // Handle both API format (combined material field) and database format (separate fields)
    int? rowId;
    String? materialCode;
    String? materialDesc;
    
    // Try database schema first (MaterialId, MaterialName, Material columns)
    if (json['MaterialId'] != null) {
      rowId = json['MaterialId'] as int?;
      materialCode = json['Material']?.toString();
      // MaterialName already contains "CODE - Description", so use it as description only
      materialDesc = json['MaterialName']?.toString();
    } else if (json['materialRowId'] != null) {
      rowId = json['materialRowId'] as int?;
      // Handle combined material field (format: "CODE - Description")
      if (json['material'] != null) {
        final materialStr = json['material'].toString();
        if (materialStr.contains(' - ')) {
          final parts = materialStr.split(' - ');
          materialCode = parts[0].trim();
          materialDesc = parts.sublist(1).join(' - ').trim();
        } else {
          materialCode = materialStr;
          materialDesc = json['description']?.toString();
        }
      } else {
        materialCode = json['material']?.toString();
        materialDesc = json['description']?.toString();
      }
    } else {
      rowId = json['materialRowId'] as int?;
      materialCode = json['material']?.toString();
      materialDesc = json['description']?.toString();
    }
    
    return MaterialMaster(
      materialRowId: rowId,
      material: materialCode,
      type: json['type']?.toString(),
      description: materialDesc,
    );
  }

  Map<String, dynamic> toJson() => {
    'materialRowId': materialRowId,
    'material': material,
    'type': type,
    'description': description,
  };
}
