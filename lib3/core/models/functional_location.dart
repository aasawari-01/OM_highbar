class FunctionalLocationModel {
  final int? funcLocId;
  final String funcLocation;
  final String funcDescription;
  final String funcLocationName;
  final String location;
  final String planningPlant;
  final String workCenter;
  final String objectNumber;
  final String techObjectType;
  final String objectKey;
  final String subSystem;

  FunctionalLocationModel({
    this.funcLocId,
    required this.funcLocation,
    required this.funcDescription,
    required this.funcLocationName,
    required this.location,
    required this.planningPlant,
    required this.workCenter,
    required this.objectNumber,
    required this.techObjectType,
    required this.objectKey,
    required this.subSystem,
  });

  factory FunctionalLocationModel.fromJson(Map<String, dynamic> json) {
    // Create a lowercase map for case-insensitive lookup
    final map = json.map((key, value) => MapEntry(key.toLowerCase(), value));

    // Try multiple possible column names
    final funcLoc = (map['funclocation'] ?? map['funcloc'] ?? map['functionallocation'])?.toString() ?? '';
    final funcDesc = (map['funcdescription'] ?? map['description'] ?? map['funcdesc'])?.toString() ?? '';

    String rawName = (map['funclocationname'] ?? map['functionallocationname'] ?? map['funclocname'])?.toString() ?? '';

    // If the name is missing or it was just mapped to description, construct the proper name
    if (rawName.isEmpty || rawName == funcDesc || rawName == funcLoc) {
      if (funcLoc.isNotEmpty && funcDesc.isNotEmpty) {
        rawName = '$funcLoc - $funcDesc';
      } else if (funcDesc.isNotEmpty) {
        rawName = funcDesc;
      } else if (funcLoc.isNotEmpty) {
        rawName = funcLoc;
      }
    }

    return FunctionalLocationModel(
      funcLocId: (map['funclocid'] ?? map['functionallocationid'] ?? map['id']) != null
          ? int.tryParse((map['funclocid'] ?? map['functionallocationid'] ?? map['id']).toString())
          : null,
      funcLocation: funcLoc,
      funcDescription: funcDesc,
      funcLocationName: rawName,
      location: (map['location'] ?? map['loc'])?.toString() ?? '',
      planningPlant: (map['planningplant'] ?? map['plant'])?.toString() ?? '',
      workCenter: (map['workcenter'] ?? map['workcentre'] ?? map['work_center'])?.toString() ?? '',
      objectNumber: (map['objectnumber'] ?? map['objectno'] ?? map['equipno'])?.toString() ?? '',
      techObjectType: (map['techobjecttype'] ?? map['techobject'] ?? map['techtype'])?.toString() ?? '',
      objectKey: (map['objectkey'] ?? map['objkey'])?.toString() ?? '',
      subSystem: (map['subsystem'] ?? map['sub_system'] ?? map['subsystem'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'funcLocId': funcLocId,
    'funcLocation': funcLocation,
    'funcDescription': funcDescription,
    'funcLocationName': funcLocationName,
    'location': location,
    'planningPlant': planningPlant,
    'workCenter': workCenter,
    'objectNumber': objectNumber,
    'techObjectType': techObjectType,
    'objectKey': objectKey,
    'subSystem': subSystem,
  };
}
