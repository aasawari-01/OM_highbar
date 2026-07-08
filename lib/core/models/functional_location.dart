class FunctionalLocationModel {
  final int? funcLocId;
  final String funcLocation;
  final String funcDescription;
  final String funcLocationName;
  final String location;
  final String planningPlant;
  final String workCenter;
  final String objectNumber;

  FunctionalLocationModel({
    this.funcLocId,
    required this.funcLocation,
    required this.funcDescription,
    required this.funcLocationName,
    required this.location,
    required this.planningPlant,
    required this.workCenter,
    required this.objectNumber,
  });

  factory FunctionalLocationModel.fromJson(Map<String, dynamic> json) {
    return FunctionalLocationModel(
      funcLocId: json['funcLocId'] as int?,
      funcLocation: json['funcLocation']?.toString() ?? '',
      funcDescription: json['funcDescription']?.toString() ?? '',
      funcLocationName: json['funcLocationName']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      planningPlant: json['planningPlant']?.toString() ?? '',
      workCenter: json['workCenter']?.toString() ?? '',
      objectNumber: json['objectNumber']?.toString() ?? '',
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
  };
}
