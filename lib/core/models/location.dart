class LocationModel {
  final int? locationTypeId;
  final String locationTypeCode;
  final String locationTypeName;
  final String locationName;
  final int? plantId;

  LocationModel({
    this.locationTypeId,
    required this.locationTypeCode,
    required this.locationTypeName,
    required this.locationName,
    this.plantId,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      locationTypeId: json['locationTypeId'] as int?,
      locationTypeCode: json['locationTypeCode']?.toString() ?? '',
      locationTypeName: json['locationTypeName']?.toString() ?? '',
      locationName: json['locationName']?.toString() ?? '',
      plantId: json['plantId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'locationTypeId': locationTypeId,
    'locationTypeCode': locationTypeCode,
    'locationTypeName': locationTypeName,
    'locationName': locationName,
    'plantId': plantId,
  };
}
