import 'label_value.dart';

class FunctionalLocationDetails {
  final String? frequency;
  final List<LabelValue>? systemList;
  final List<LabelValue>? equipmentList;
  final List<MaintenanceHistoryItem>? maintenanceHistory;
  final List<MaintenanceHistoryItem>? maintenanceHistoryPrev;
  final List<MeasurementPointData>? measurementPoints;

  FunctionalLocationDetails({
    this.frequency,
    this.systemList,
    this.equipmentList,
    this.maintenanceHistory,
    this.maintenanceHistoryPrev,
    this.measurementPoints,
  });

  factory FunctionalLocationDetails.fromJson(Map<String, dynamic> json) {
    return FunctionalLocationDetails(
      frequency: json['frequency']?.toString() ?? json['Frequency']?.toString(),
      systemList: (json['systemList'] as List?)
          ?.map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
          .toList(),
      equipmentList: (json['equipmentList'] as List?)
          ?.map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
          .toList(),
      maintenanceHistory: (json['maintenanceHistory'] as List?)
          ?.map((e) => MaintenanceHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      maintenanceHistoryPrev: (json['maintenanceHistoryPrev'] as List?)
          ?.map((e) => MaintenanceHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      measurementPoints: (json['measurementPoints'] as List?)
          ?.map((e) => MeasurementPointData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'frequency': frequency,
    'systemList': systemList?.map((e) => e.toJson()).toList(),
    'equipmentList': equipmentList?.map((e) => e.toJson()).toList(),
    'maintenanceHistory': maintenanceHistory?.map((e) => e.toJson()).toList(),
    'maintenanceHistoryPrev': maintenanceHistoryPrev?.map((e) => e.toJson()).toList(),
    'measurementPoints': measurementPoints?.map((e) => e.toJson()).toList(),
  };
}

class MaintenanceHistoryItem {
  final String? description;
  final String? date;

  MaintenanceHistoryItem({
    this.description,
    this.date,
  });

  factory MaintenanceHistoryItem.fromJson(Map<String, dynamic> json) {
    return MaintenanceHistoryItem(
      description: json['description']?.toString() ?? json['Description']?.toString(),
      date: json['date']?.toString() ?? json['Date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'date': date,
  };
}

class MeasurementPointData {
  final String? measurementPoint;
  final String? description;
  final String? unit;

  MeasurementPointData({
    this.measurementPoint,
    this.description,
    this.unit,
  });

  factory MeasurementPointData.fromJson(Map<String, dynamic> json) {
    return MeasurementPointData(
      measurementPoint: json['measurementPoint']?.toString() ?? 
                     json['measPoint']?.toString() ?? 
                     json['MeasurementPoint']?.toString(),
      description: json['description']?.toString() ?? 
                  json['measPointDesc']?.toString() ?? 
                  json['Description']?.toString(),
      unit: json['unit']?.toString() ?? 
           json['measRangeUnit']?.toString() ?? 
           json['Unit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'measurementPoint': measurementPoint,
    'description': description,
    'unit': unit,
  };
}