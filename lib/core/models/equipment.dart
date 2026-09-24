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
      equipId: (json['equipId'] ?? json['EquipId']) as int?,
      equipNo: (json['equipNo'] ?? json['EquipNo'])?.toString() ?? '',
      equipDesc: (json['equipDesc'] ?? json['EquipDesc'])?.toString() ?? '',
      equipmentName: (json['equipmentName'] ?? json['EquipmentName'] ?? json['EquipDesc'] ?? json['equipDesc'])?.toString() ?? '',
      functionalLocation: (json['functionalLocation'] ?? json['FunctionalLocation'])?.toString() ?? '',
      location: (json['location'] ?? json['Location'])?.toString() ?? '',
      planningPlant: (json['planningPlant'] ?? json['PlanningPlant'])?.toString() ?? '',
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
