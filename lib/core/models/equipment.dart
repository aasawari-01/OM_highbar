class EquipmentModel {
  final int? equipId;
  final String equipNo;
  final String equipDesc;
  final String equipmentName;
  final String functionalLocation;
  final String location;
  final String planningPlant;

  EquipmentModel({
    this.equipId,
    required this.equipNo,
    required this.equipDesc,
    required this.equipmentName,
    required this.functionalLocation,
    required this.location,
    required this.planningPlant,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      equipId: json['equipId'] as int?,
      equipNo: json['equipNo']?.toString() ?? '',
      equipDesc: json['equipDesc']?.toString() ?? '',
      equipmentName: json['equipmentName']?.toString() ?? '',
      functionalLocation: json['functionalLocation']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      planningPlant: json['planningPlant']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'equipId': equipId,
    'equipNo': equipNo,
    'equipDesc': equipDesc,
    'equipmentName': equipmentName,
    'functionalLocation': functionalLocation,
    'location': location,
    'planningPlant': planningPlant,
  };
}
