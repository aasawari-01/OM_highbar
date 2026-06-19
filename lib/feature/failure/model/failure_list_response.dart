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
  });

  factory FailureItem.fromJson(Map<String, dynamic> json) {
    final isStationListItem = json.containsKey('failureId') || json.containsKey('failureCreationId');

    if (isStationListItem) {
      return FailureItem(
        id: json['id'] as int?,
        failureNo: json['failureCreationId'] as String? ?? json['id']?.toString(),
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
    );
  }
}
