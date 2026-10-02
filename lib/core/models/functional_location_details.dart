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

class FunctionalLocationDetailsResponse {
  final FunctionalLocationDetails? details;
  final String? errorMessage;

  FunctionalLocationDetailsResponse({
    this.details,
    this.errorMessage,
  });

  factory FunctionalLocationDetailsResponse.fromJson(Map<String, dynamic> json) {
    return FunctionalLocationDetailsResponse(
      details: json['responseOutput'] != null
          ? FunctionalLocationDetails.fromJson(json['responseOutput'] as Map<String, dynamic>)
          : null,
      errorMessage: json['responseMessage']?.toString(),
    );
  }
}

class SubsystemsResponse {
  final List<LabelValue>? subsystems;
  final String? errorMessage;

  SubsystemsResponse({
    this.subsystems,
    this.errorMessage,
  });

  factory SubsystemsResponse.fromJson(Map<String, dynamic> json) {
    // Handle both direct subsystems list and nested structure from JE API
    List<LabelValue>? subsystemList;
    
    if (json['responseOutput'] is List) {
      subsystemList = (json['responseOutput'] as List?)
          ?.map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['responseOutput'] is Map) {
      final output = json['responseOutput'] as Map<String, dynamic>?;
      final createVMModel = output?['getCreateVMModel'] as Map<String, dynamic>?;
      final subSystems = createVMModel?['subSystems'] as List?;
      subsystemList = subSystems
          ?.map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return SubsystemsResponse(
      subsystems: subsystemList,
      errorMessage: json['responseMessage']?.toString(),
    );
  }
}

class PersonResponsibleResponse {
  final List<LabelValue>? users;
  final String? errorMessage;

  PersonResponsibleResponse({
    this.users,
    this.errorMessage,
  });

  factory PersonResponsibleResponse.fromJson(Map<String, dynamic> json) {
    // Handle both direct users list and nested structure
    List<LabelValue>? userList;
    
    if (json['responseOutput'] is List) {
      userList = (json['responseOutput'] as List?)
          ?.map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['responseOutput'] is Map) {
      final output = json['responseOutput'] as Map<String, dynamic>?;
      // Different endpoints name the list differently.
      final users = (output?['users'] ??
          output?['getUserList'] ??
          output?['getAssgineUserList']) as List?;
      userList = users
          ?.map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return PersonResponsibleResponse(
      users: userList,
      errorMessage: json['responseMessage']?.toString(),
    );
  }
}

class NatureOfWorkResponse {
  final List<LabelValue>? natureOfWorkList;
  final List<LabelValue>? failureTypeList;
  final String? errorMessage;

  NatureOfWorkResponse({
    this.natureOfWorkList,
    this.failureTypeList,
    this.errorMessage,
  });

  factory NatureOfWorkResponse.fromJson(Map<String, dynamic> json) {
    final output = json['responseOutput'] as Map<String, dynamic>?;
    return NatureOfWorkResponse(
      natureOfWorkList: (output?['natureOfWorkList'] as List?)
          ?.map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
          .toList(),
      failureTypeList: (output?['failureTypeList'] as List?)
          ?.map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
          .toList(),
      errorMessage: json['responseMessage']?.toString(),
    );
  }
}