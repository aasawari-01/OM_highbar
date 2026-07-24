class FailureListResponse {
  final int? responseCode;
  final String? responseMessage;
  final List<FailureItem> responseOutput;

  FailureListResponse({
    this.responseCode,
    this.responseMessage,
    this.responseOutput = const [],
  });

  factory FailureListResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('success')) {
      return FailureListResponse(
        responseCode: json['success'] == true ? 200 : 400,
        responseMessage: json['message'] as String?,
        responseOutput: (json['data']?['stationFailureList'] as List<dynamic>?)
                ?.map((e) => FailureItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
    }
    return FailureListResponse(
      responseCode: json['responseCode'] as int?,
      responseMessage: json['responseMessage'] as String?,
      responseOutput: (json['responseOutput'] as List<dynamic>?)
              ?.map((e) => FailureItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class FailureItem {
  final int? id;
  final String? failureNo;
  final String? notificationCode;
  final String? jobCardId;
  final String? failureDescription;
  final int? functionLocationId;
  final int? equipmentId;
  final String? functionalLocation;
  final String? equipmentDescription;
  final String? statusName;
  final String? statusDescription;
  final String? failureOccuranceDateTime;
  final int? assignedUserId;
  final String? occRequestStatus;
  final String? otherRequestFrom;
  final String? locationName;
  final String? remarks;
  final String? creationType;
  final String? priority;
  final String? departmentName;
  final String? subLocation;
  final String? trainId;
  final String? system;
  final String? actualFailureCompletedDateTime;
  final bool? isTripAffected;
  final int? tripDelayUpline;
  final int? tripDelayDownline;
  final int? tripCancel;
  final bool? isTrainReplace;
  final int? trainReplace;
  final bool? isTrainDeboarded;
  final int? trainDeboarded;
  final int? numberOfPassengerAffected;
  final bool? isPassengerAffected;
  final int? trappedDuration;
  final int? rescusedDuration;
  final int? trainDelayInMin;
  final int? noOfTranWithdrawal;
  final String? failureReportedby;
  final String? failureCategoryTypeText;
  final String? failureRectificationDetails;
  final String? carriedOutRemarks;
  final int? departmentId_1;
  final int? locationId;
  final int? funcationLocationId;
  final List<dynamic>? getImageBefor;
  final String? syncStatus;
  final String? lastSyncedAt;

  FailureItem({
    this.id,
    this.failureNo,
    this.notificationCode,
    this.jobCardId,
    this.failureDescription,
    this.functionLocationId,
    this.equipmentId,
    this.functionalLocation,
    this.equipmentDescription,
    this.statusName,
    this.statusDescription,
    this.failureOccuranceDateTime,
    this.assignedUserId,
    this.occRequestStatus,
    this.otherRequestFrom,
    this.locationName,
    this.remarks,
    this.creationType,
    this.priority,
    this.departmentName,
    this.subLocation,
    this.trainId,
    this.system,
    this.actualFailureCompletedDateTime,
    this.isTripAffected,
    this.tripDelayUpline,
    this.tripDelayDownline,
    this.tripCancel,
    this.isTrainReplace,
    this.trainReplace,
    this.isTrainDeboarded,
    this.trainDeboarded,
    this.numberOfPassengerAffected,
    this.isPassengerAffected,
    this.trappedDuration,
    this.rescusedDuration,
    this.trainDelayInMin,
    this.noOfTranWithdrawal,
    this.failureReportedby,
    this.failureCategoryTypeText,
    this.failureRectificationDetails,
    this.carriedOutRemarks,
    this.departmentId_1,
    this.locationId,
    this.funcationLocationId,
    this.getImageBefor,
    this.syncStatus,
    this.lastSyncedAt,
  });

  factory FailureItem.fromJson(Map<String, dynamic> json) {
    final isStationListItem = json.containsKey('failureId') || json.containsKey('failureCreationId');

    if (isStationListItem) {
      return FailureItem(
        id: json['id'] as int?,
        failureNo: json['failureCreationId'] as String? ?? json['failureId'] as String? ?? json['id']?.toString(),
        notificationCode: json['failureId'] as String?,
        failureDescription: json['failureDescription'] as String?,
        functionalLocation: json['funcationLocation'] as String?,
        statusName: json['statusName'] as String?,
        failureOccuranceDateTime: json['actualFailureOccuranceDate'] as String?,
        occRequestStatus: json['occRequestStatusName'] as String?,
        locationName: json['location'] as String?,
        creationType: 'station',
        priority: json['priority'] as String?,
        departmentName: json['departmentName'] as String?,
        remarks: json['failureRectificationDetails'] as String?,
        subLocation: json['subLocation'] as String?,
        trainId: json['trainId']?.toString(),
        system: json['system'] as String?,
        actualFailureCompletedDateTime: json['actualFailureCompletedDateTime'] as String?,
        isTripAffected: json['isTripAffected'] as bool?,
        tripDelayUpline: json['tripDelayUpline'] as int?,
        tripDelayDownline: json['tripDelayDownline'] as int?,
        tripCancel: json['tripCancel'] as int?,
        isTrainReplace: json['isTrainReplace'] as bool?,
        trainReplace: json['trainReplace'] as int?,
        isTrainDeboarded: json['isTrainDeboarded'] as bool?,
        trainDeboarded: json['trainDeboarded'] as int?,
        numberOfPassengerAffected: json['numberOfPassengerAffected'] as int?,
        isPassengerAffected: json['isPassengerAffected'] as bool?,
        trappedDuration: json['trappedDuration'] as int?,
        rescusedDuration: json['rescusedDuration'] as int?,
        trainDelayInMin: json['trainDelayInMin'] as int?,
        noOfTranWithdrawal: json['noOfTranWithdrawal'] as int?,
        failureReportedby: json['failureReportedby'] as String?,
        failureCategoryTypeText: json['failureCategoryTypeText'] as String?,
        failureRectificationDetails: json['failureRectificationDetails'] as String?,
        carriedOutRemarks: json['carriedOutRemarks'] as String?,
        departmentId_1: json['departmentId_1'] as int?,
        locationId: json['locationId'] as int?,
        funcationLocationId: json['funcationLocationId'] as int?,
        getImageBefor: json['getImageBefor'] as List<dynamic>?,
        syncStatus: json['syncStatus'] as String?,
        lastSyncedAt: json['lastSyncedAt'] as String?,
      );
    }

    return FailureItem(
      id: json['id'] as int?,
      failureNo: json['failureNo'] as String?,
      notificationCode: json['notificationCode'] as String?,
      jobCardId: json['jobCardId'] as String?,
      failureDescription: json['failureDescription'] as String?,
      functionLocationId: json['functionLocationId'] as int?,
      equipmentId: json['equipmentId'] as int?,
      functionalLocation: json['functionalLocation'] as String?,
      equipmentDescription: json['equipmentDescription'] as String?,
      statusName: json['statusName'] as String?,
      statusDescription: json['statusDescription'] as String?,
      failureOccuranceDateTime: json['failureOccuranceDateTime'] as String?,
      assignedUserId: json['assignedUserId'] as int?,
      occRequestStatus: json['occRequestStatus'] as String?,
      otherRequestFrom: json['otherRequestFrom'] as String?,
      locationName: json['locationName'] as String?,
      remarks: json['remarks'] as String?,
      creationType: json['creationType'] as String?,
      priority: json['priority'] as String?,
      departmentName: json['departmentName'] as String?,
      syncStatus: json['syncStatus'] as String?,
      lastSyncedAt: json['lastSyncedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'failureNo': failureNo,
      'notificationCode': notificationCode,
      'jobCardId': jobCardId,
      'failureDescription': failureDescription,
      'functionLocationId': functionLocationId,
      'equipmentId': equipmentId,
      'functionalLocation': functionalLocation,
      'equipmentDescription': equipmentDescription,
      'statusName': statusName,
      'statusDescription': statusDescription,
      'failureOccuranceDateTime': failureOccuranceDateTime,
      'assignedUserId': assignedUserId,
      'occRequestStatus': occRequestStatus,
      'otherRequestFrom': otherRequestFrom,
      'locationName': locationName,
      'remarks': remarks,
      'creationType': creationType,
      'priority': priority,
      'departmentName': departmentName,
      'subLocation': subLocation,
      'trainId': trainId,
      'system': system,
      'actualFailureCompletedDateTime': actualFailureCompletedDateTime,
      'isTripAffected': isTripAffected,
      'tripDelayUpline': tripDelayUpline,
      'tripDelayDownline': tripDelayDownline,
      'tripCancel': tripCancel,
      'isTrainReplace': isTrainReplace,
      'trainReplace': trainReplace,
      'isTrainDeboarded': isTrainDeboarded,
      'trainDeboarded': trainDeboarded,
      'numberOfPassengerAffected': numberOfPassengerAffected,
      'isPassengerAffected': isPassengerAffected,
      'trappedDuration': trappedDuration,
      'rescusedDuration': rescusedDuration,
      'trainDelayInMin': trainDelayInMin,
      'noOfTranWithdrawal': noOfTranWithdrawal,
      'failureReportedby': failureReportedby,
      'failureCategoryTypeText': failureCategoryTypeText,
      'failureRectificationDetails': failureRectificationDetails,
      'carriedOutRemarks': carriedOutRemarks,
      'departmentId_1': departmentId_1,
      'locationId': locationId,
      'funcationLocationId': funcationLocationId,
      'getImageBefor': getImageBefor,
      'syncStatus': syncStatus,
      'lastSyncedAt': lastSyncedAt,
    };
  }
}
