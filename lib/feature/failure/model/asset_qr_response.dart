class AssetQrResponse {
  final int responseCode;
  final String responseMessage;
  final AssetQrData? responseOutput;
  final dynamic data;

  AssetQrResponse({
    required this.responseCode,
    required this.responseMessage,
    this.responseOutput,
    this.data,
  });

  factory AssetQrResponse.fromJson(Map<String, dynamic> json) {
    return AssetQrResponse(
      responseCode: json['responseCode'] ?? 0,
      responseMessage: json['responseMessage'] ?? '',
      responseOutput: json['responseOutput'] != null 
          ? AssetQrData.fromJson(json['responseOutput'] as Map<String, dynamic>)
          : null,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'responseCode': responseCode,
      'responseMessage': responseMessage,
      'responseOutput': responseOutput?.toJson(),
      'data': data,
    };
  }
}

class AssetQrData {
  final dynamic createdBy;
  final String? funcLocId;
  final String? description;
  final String? department;
  final String? system;
  final String? subSystem;
  final String? modelNo;
  final String? oem;
  final String? warranty;
  final dynamic isSearchFilter;
  final String? funcLocation;
  final int? deptId;
  final String? redirectPageNameCreateFailure;
  final String? superiorFunLocation;
  final String? superiorFuncLocId;
  final String? superiorFunLocationDescription;
  final String? location;
  final String? encryptFuncLocId;
  final List<FailureMaintenanceHistory> lstFailureMaintenanceHistory;
  final List<PreventiveMaintenanceHistory> lstPreventiveMaintenanceHistory;
  final List<dynamic> lstEquipmentsDetails;
  final List<dynamic> lstChildFunctionalLocationLists;

  AssetQrData({
    this.createdBy,
    this.funcLocId,
    this.description,
    this.department,
    this.system,
    this.subSystem,
    this.modelNo,
    this.oem,
    this.warranty,
    this.isSearchFilter,
    this.funcLocation,
    this.deptId,
    this.redirectPageNameCreateFailure,
    this.superiorFunLocation,
    this.superiorFuncLocId,
    this.superiorFunLocationDescription,
    this.location,
    this.encryptFuncLocId,
    required this.lstFailureMaintenanceHistory,
    required this.lstPreventiveMaintenanceHistory,
    required this.lstEquipmentsDetails,
    required this.lstChildFunctionalLocationLists,
  });

  factory AssetQrData.fromJson(Map<String, dynamic> json) {
    return AssetQrData(
      createdBy: json['createdBy'],
      funcLocId: json['funcLocId']?.toString(),
      description: json['description']?.toString(),
      department: json['department']?.toString(),
      system: json['system']?.toString(),
      subSystem: json['subSystem']?.toString(),
      modelNo: json['modelNo']?.toString(),
      oem: json['oem']?.toString(),
      warranty: json['warranty']?.toString(),
      isSearchFilter: json['isSearchFilter'],
      funcLocation: json['funcLocation']?.toString(),
      deptId: json['deptId'] is int ? json['deptId'] : int.tryParse(json['deptId']?.toString() ?? '0'),
      redirectPageNameCreateFailure: json['redirectPageNameCreateFailure']?.toString(),
      superiorFunLocation: json['superiorFunLocation']?.toString(),
      superiorFuncLocId: json['superiorFuncLocId']?.toString(),
      superiorFunLocationDescription: json['superiorFunLocationDescription']?.toString(),
      location: json['location']?.toString(),
      encryptFuncLocId: json['encryptFuncLocId']?.toString(),
      lstFailureMaintenanceHistory: (json['lstFailureMaintenanceHistory'] as List?)
              ?.map((e) => FailureMaintenanceHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lstPreventiveMaintenanceHistory: (json['lstPreventiveMaintenanceHistory'] as List?)
              ?.map((e) => PreventiveMaintenanceHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lstEquipmentsDetails: json['lstEquipmentsDetails'] as List? ?? [],
      lstChildFunctionalLocationLists: json['lstChildFunctionalLocationLists'] as List? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdBy': createdBy,
      'funcLocId': funcLocId,
      'description': description,
      'department': department,
      'system': system,
      'subSystem': subSystem,
      'modelNo': modelNo,
      'oem': oem,
      'warranty': warranty,
      'isSearchFilter': isSearchFilter,
      'funcLocation': funcLocation,
      'deptId': deptId,
      'redirectPageNameCreateFailure': redirectPageNameCreateFailure,
      'superiorFunLocation': superiorFunLocation,
      'superiorFuncLocId': superiorFuncLocId,
      'superiorFunLocationDescription': superiorFunLocationDescription,
      'location': location,
      'encryptFuncLocId': encryptFuncLocId,
      'lstFailureMaintenanceHistory': lstFailureMaintenanceHistory.map((e) => e.toJson()).toList(),
      'lstPreventiveMaintenanceHistory': lstPreventiveMaintenanceHistory.map((e) => e.toJson()).toList(),
      'lstEquipmentsDetails': lstEquipmentsDetails,
      'lstChildFunctionalLocationLists': lstChildFunctionalLocationLists,
    };
  }
}

class FailureMaintenanceHistory {
  final String? failureNo;
  final String? functionalLocation;
  final String? description;
  final String? status;
  final String? failureDate;
  final int? deptId;
  final String? deptName;
  final String? encryptNotificationId;
  final String? redirectPageName;

  FailureMaintenanceHistory({
    this.failureNo,
    this.functionalLocation,
    this.description,
    this.status,
    this.failureDate,
    this.deptId,
    this.deptName,
    this.encryptNotificationId,
    this.redirectPageName,
  });

  factory FailureMaintenanceHistory.fromJson(Map<String, dynamic> json) {
    return FailureMaintenanceHistory(
      failureNo: json['failureNo']?.toString(),
      functionalLocation: json['functionalLocation']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      failureDate: json['failureDate']?.toString(),
      deptId: json['deptId'] is int ? json['deptId'] : int.tryParse(json['deptId']?.toString() ?? '0'),
      deptName: json['deptName']?.toString(),
      encryptNotificationId: json['encryptNotificationId']?.toString(),
      redirectPageName: json['redirectPageName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'failureNo': failureNo,
      'functionalLocation': functionalLocation,
      'description': description,
      'status': status,
      'failureDate': failureDate,
      'deptId': deptId,
      'deptName': deptName,
      'encryptNotificationId': encryptNotificationId,
      'redirectPageName': redirectPageName,
    };
  }
}

class PreventiveMaintenanceHistory {
  final String? orderNo;
  final String? functionalLocation;
  final String? description;
  final String? status;
  final String? plannedDate;
  final String? encryptJobCardId;
  final String? redirectPageName;

  PreventiveMaintenanceHistory({
    this.orderNo,
    this.functionalLocation,
    this.description,
    this.status,
    this.plannedDate,
    this.encryptJobCardId,
    this.redirectPageName,
  });

  factory PreventiveMaintenanceHistory.fromJson(Map<String, dynamic> json) {
    return PreventiveMaintenanceHistory(
      orderNo: json['orderNo']?.toString(),
      functionalLocation: json['functionalLocation']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      plannedDate: json['plannedDate']?.toString(),
      encryptJobCardId: json['encryptJobCardId']?.toString(),
      redirectPageName: json['redirectPageName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderNo': orderNo,
      'functionalLocation': functionalLocation,
      'description': description,
      'status': status,
      'plannedDate': plannedDate,
      'encryptJobCardId': encryptJobCardId,
      'redirectPageName': redirectPageName,
    };
  }
}
