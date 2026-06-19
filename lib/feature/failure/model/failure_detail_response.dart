class FailureDetailResponse {
  final int? responseCode;
  final String? responseMessage;
  final FailureDetailOutput? responseOutput;

  FailureDetailResponse({
    this.responseCode,
    this.responseMessage,
    this.responseOutput,
  });

  factory FailureDetailResponse.fromJson(Map<String, dynamic> json) {
    return FailureDetailResponse(
      responseCode: json['responseCode'] as int?,
      responseMessage: json['responseMessage'] as String?,
      responseOutput: json['responseOutput'] != null
          ? FailureDetailOutput.fromJson(json['responseOutput'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FailureDetailOutput {
  final List<LabelValue>? getNotificationTypeList;
  final List<LabelValue>? getNatureOfWorkList;
  final List<LabelValue>? getDepartmentList;
  final List<LabelValue>? getUserList;
  final List<LabelValue>? getEquipmentList;
  final List<LabelValue>? getObjectData;
  final List<LabelValue>? getMaterialData;
  final List<LabelValue>? getUserStatus;
  final List<LabelValue>? getLocationTypeList;
  final List<LabelValue>? getStorageLocation;
  final List<LabelValue>? getPriorityType;
  final List<LabelValue>? getCorrNotificationTypeList;
  final List<LabelValue>? getFaultData;
  final List<NotificationActionHistory>? getNotificationActionUserHistory;
  final List<LabelValue>? getFunctionalLocationList;
  final List<LabelValue>? getEquipmentDetails;
  final List<LabelValue>? getRootCausetData;
  final List<LabelValue>? getActionData;
  final List<Map<String, dynamic>>? measurementPoint;
  final CreateVMModel? getCreateVMModel;
  final List<Map<String, dynamic>>? getObjectANDFaultList;
  final List<Map<String, dynamic>>? getObjectANDFaultActionList;
  final List<Map<String, dynamic>>? getObjectANDFaultRootCauseList;
  final List<Map<String, dynamic>>? getMaterialReqDetails;
  final List<Map<String, dynamic>>? getMaterialDismantleDetails;
  final List<Map<String, dynamic>>? getImageBefor;

  FailureDetailOutput({
    this.getNotificationTypeList,
    this.getNatureOfWorkList,
    this.getDepartmentList,
    this.getUserList,
    this.getEquipmentList,
    this.getObjectData,
    this.getMaterialData,
    this.getUserStatus,
    this.getLocationTypeList,
    this.getStorageLocation,
    this.getPriorityType,
    this.getCorrNotificationTypeList,
    this.getFaultData,
    this.getNotificationActionUserHistory,
    this.getFunctionalLocationList,
    this.getEquipmentDetails,
    this.getRootCausetData,
    this.getActionData,
    this.measurementPoint,
    this.getCreateVMModel,
    this.getObjectANDFaultList,
    this.getObjectANDFaultActionList,
    this.getObjectANDFaultRootCauseList,
    this.getMaterialReqDetails,
    this.getMaterialDismantleDetails,
    this.getImageBefor,
  });

  factory FailureDetailOutput.fromJson(Map<String, dynamic> json) {
    return FailureDetailOutput(
      getNotificationTypeList: _mapList(json['getNotificationTypeList']),
      getNatureOfWorkList: _mapList(json['getNatureOfWorkList']),
      getDepartmentList: _mapList(json['getDepartmentList'] ?? json['department']),
      getUserList: _mapList(json['getUserList'] ?? json['getAssgineUserList'] ?? json['personResponsible']),
      getEquipmentList: _mapList(json['getEquipmentList'] ?? json['getEquipmentNoList'] ?? json['equipment']),
      getObjectData: _mapList(json['getObjectData'] ?? json['objectPart']),
      getMaterialData: _mapList(json['getMaterialData'] ?? json['materialCode']),
      getUserStatus: _mapList(json['getUserStatus'] ?? json['status']),
      getLocationTypeList: _mapList(json['getLocationTypeList']),
      getStorageLocation: _mapList(json['getStorageLocation']),
      getPriorityType: _mapList(json['getPriorityType']),
      getCorrNotificationTypeList: _mapList(json['getCorrNotificationTypeList']),
      getFaultData: _mapList(json['getFaultData']),
      getRootCausetData: _mapList(json['getRootCausetData']),
      getActionData: _mapList(json['getActionData']),
      getFunctionalLocationList: _mapList(json['getFunctionalLocationList'] ?? json['getFunctionLocList'] ?? json['functionalLocation']),
      getEquipmentDetails: _mapList(json['getEquipmentDetails']),
      measurementPoint: json['measurementPoint'] != null
          ? (json['measurementPoint'] as List).map((e) => e as Map<String, dynamic>).toList()
          : null,
      getNotificationActionUserHistory: (json['getNotificationActionUserHistory'] ?? json['getNotificationHistory'] ?? json['notificationHistory']) != null
          ? ((json['getNotificationActionUserHistory'] ?? json['getNotificationHistory'] ?? json['notificationHistory']) as List)
              .map((e) => NotificationActionHistory.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      getCreateVMModel: json['getCreateVMModel'] != null
          ? CreateVMModel.fromJson(json['getCreateVMModel'] as Map<String, dynamic>)
          : null,
      getObjectANDFaultList: (json['getObjectANDFaultList'] ?? json['failureRectificationDetails']) != null
          ? List<Map<String, dynamic>>.from(json['getObjectANDFaultList'] ?? json['failureRectificationDetails'])
          : null,
      getObjectANDFaultActionList: (json['getObjectANDFaultActionList'] ?? json['failureActionDetails']) != null
          ? List<Map<String, dynamic>>.from(json['getObjectANDFaultActionList'] ?? json['failureActionDetails'])
          : null,
      getObjectANDFaultRootCauseList: (json['getObjectANDFaultRootCauseList'] ?? json['failureRootCauseDetails']) != null
          ? List<Map<String, dynamic>>.from(json['getObjectANDFaultRootCauseList'] ?? json['failureRootCauseDetails'])
          : null,
      getMaterialReqDetails: json['getMaterialReqDetails'] != null
          ? (json['getMaterialReqDetails'] as List).map((e) => e as Map<String, dynamic>).toList()
          : null,
      getMaterialDismantleDetails: json['getMaterialDismantleDetails'] != null
          ? (json['getMaterialDismantleDetails'] as List).map((e) => e as Map<String, dynamic>).toList()
          : null,
      getImageBefor: json['getImageBefor'] != null
          ? List<Map<String, dynamic>>.from(json['getImageBefor'])
          : null,
    );
  }
}

class NotificationActionHistory {
  final int? notificationId;
  final int? assgineUserId;
  final int? statusId;
  final String? statusName;
  final String? remark;
  final String? actionBy;
  final String? actionOn;
  final String? assginedUserName;

  NotificationActionHistory({
    this.notificationId,
    this.assgineUserId,
    this.statusId,
    this.statusName,
    this.remark,
    this.actionBy,
    this.actionOn,
    this.assginedUserName,
  });

  factory NotificationActionHistory.fromJson(Map<String, dynamic> json) {
    return NotificationActionHistory(
      notificationId: json['notificationId'] as int?,
      assgineUserId: json['assgineUserId'] as int?,
      statusId: json['statusId'] as int?,
      statusName: json['statusName'] as String?,
      remark: (json['remark'] ?? json['description']) as String?,
      actionBy: (json['actionBy'] ?? json['createdBy']) as String?,
      actionOn: (json['actionOn'] ?? json['createdOn']) as String?,
      assginedUserName: json['assginedUserName'] as String?,
    );
  }

  @override
  String toString() {
    return 'NotificationActionHistory(notificationId: $notificationId, statusName: $statusName, remark: $remark, actionBy: $actionBy, actionOn: $actionOn)';
  }
}

List<LabelValue>? _mapList(dynamic list) {
  if (list == null) return null;
  return (list as List<dynamic>)
      .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
      .toList();
}

class LabelValue {
  final String? label;
  final String? value;
  final dynamic uniqueId;

  LabelValue({this.label, this.value, this.uniqueId});

  factory LabelValue.fromJson(Map<String, dynamic> json) {
    return LabelValue(
      label: json['label']?.toString(),
      value: json['value']?.toString(),
      uniqueId: json['uniqueId'],
    );
  }

  @override
  String toString() {
    return 'LabelValue(label: $label, value: $value, uniqueId: $uniqueId)';
  }
}

class CreateVMModel {
  final String? id;
  final int? notificationId;
  final String? notificationCode;
  final String? description;
  final int? natureOfWorkId;
  final int? notificationTypeId;
  final int? functionLocationId;
  final int? equipmentId;
  final String? actualFailureOccuranceOn;
  final int? assignedUserId;
  final bool? isServiceAffected;
  final bool? isOHEReq;
  final bool? isJointInspectionReq;
  final bool? isHardwareReplaced;
  final bool? isSICReq;
  final bool? isPTWReq;
  final int? failureTypeId;
  final int? deptId;
  final int? userStatus;
  final String? funcDescription;
  final int? priorityId;
  final int? statusId;
  final String? priorityType;
  final String? mainStatusName;
  final String? failureRectificationDetails;
  final int? reasonForDelayId;
  final String? category;
  final String? deptCode;
  final int? locationTypeId;
  final int? corr_NotificationTypeId;

  final List<Map<String, dynamic>>? getObjectANDFaultList;
  final List<Map<String, dynamic>>? getObjectANDFaultActionList;
  final List<Map<String, dynamic>>? getObjectANDFaultRootCauseList;

  final String? remark_JE;
  final String? imagesPaths;
  final String? imagesPathsAfter;
  final String? imagesPathsRCA;

  final String? ptwNo;
  final int? trainDelayInMin;
  final int? trainDelayInNo;
  final int? noOfTranCancel;
  final int? noOfTranWithdrawal;
  final int? noOfTrainReplace;
  final bool? isPassengerDeboarding;
  final int? noofTrainDeboarded;
  final bool? isPassengerAffected;
  final int? noOfPassengerAffected;
  final String? trappedDuration;
  final String? rescuedDuration;
  final String? locationFailure;
  final String? actualFailureRectifiedDate;
  final String? failureAttendedDate;
  final String? failureType;
  final String? assignedUseeName;
  final String? underObservationDate;

  CreateVMModel({
    this.id,
    this.notificationId,
    this.notificationCode,
    this.description,
    this.natureOfWorkId,
    this.notificationTypeId,
    this.functionLocationId,
    this.equipmentId,
    this.actualFailureOccuranceOn,
    this.assignedUserId,
    this.isServiceAffected,
    this.isOHEReq,
    this.isJointInspectionReq,
    this.isHardwareReplaced,
    this.isSICReq,
    this.isPTWReq,
    this.failureTypeId,
    this.deptId,
    this.userStatus,
    this.funcDescription,
    this.priorityId,
    this.statusId,
    this.priorityType,
    this.mainStatusName,
    this.failureRectificationDetails,
    this.reasonForDelayId,
    this.category,
    this.deptCode,
    this.remark_JE,
    this.imagesPaths,
    this.imagesPathsAfter,
    this.imagesPathsRCA,
    this.ptwNo,
    this.trainDelayInMin,
    this.trainDelayInNo,
    this.noOfTranCancel,
    this.noOfTranWithdrawal,
    this.noOfTrainReplace,
    this.isPassengerDeboarding,
    this.noofTrainDeboarded,
    this.isPassengerAffected,
    this.noOfPassengerAffected,
    this.trappedDuration,
    this.rescuedDuration,
    this.locationFailure,
    this.actualFailureRectifiedDate,
    this.failureAttendedDate,
    this.failureType,
    this.assignedUseeName,
    this.underObservationDate,
    this.locationTypeId,
    this.corr_NotificationTypeId,
    this.getObjectANDFaultList,
    this.getObjectANDFaultActionList,
    this.getObjectANDFaultRootCauseList,
  });

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      if (v == 'yes' || v == 'true') return true;
      if (v == 'no' || v == 'false') return false;
    }
    return null;
  }

  factory CreateVMModel.fromJson(Map<String, dynamic> json) {
    return CreateVMModel(
      id: json['Id'] as String?,
      notificationId: json['notificationId'] as int?,
      notificationCode: json['notificationCode'] as String?,
      description: json['description'] as String?,
      natureOfWorkId: json['natureOfWorkId'] as int?,
      notificationTypeId: json['notificationTypeId'] as int?,
      functionLocationId: json['functionLocationId'] as int?,
      equipmentId: json['equipmentId'] as int?,
      actualFailureOccuranceOn: json['actualFailureOccuranceOn'] as String?,
      assignedUserId: json['assignedUserId'] as int?,
      isServiceAffected: json['isServiceAffected'] as bool?,
      isOHEReq: json['isOHEReq'] as bool?,
      isJointInspectionReq: json['isJointInspectionReq'] as bool?,
      isHardwareReplaced: json['isHardwareReplaced'] as bool?,
      isSICReq: json['isSICReq'] as bool?,
      isPTWReq: json['isPTWReq'] as bool?,
      failureTypeId: json['failureTypeId'] as int?,
      deptId: json['deptId'] as int?,
      userStatus: json['userStatus'] as int?,
      funcDescription: json['funcDescription'] as String?,
      priorityId: json['priorityId'] as int?,
      statusId: json['statusId'] as int?,
      priorityType: json['priorityType'] as String?,
      mainStatusName: json['mainStatusName'] as String?,
      failureRectificationDetails: json['failureRectificationDetails'] as String?,
      reasonForDelayId: json['reasonForDelayId'] as int?,
      category: json['category'] as String?,
      deptCode: json['deptCode'] as String?,
      remark_JE: json['remark_JE'] as String?,
      imagesPaths: json['imagesPaths'] as String?,
      imagesPathsAfter: json['imagesPathsAfter'] as String?,
      imagesPathsRCA: json['imagesPathsRCA'] as String?,
      ptwNo: json['ptwNo'] as String?,
      trainDelayInMin: json['trainDelayInMin'] as int?,
      trainDelayInNo: json['trainDelayInNo'] as int?,
      noOfTranCancel: json['noOfTranCancel'] as int?,
      noOfTranWithdrawal: json['noOfTranWithdrawal'] as int?,
      noOfTrainReplace: json['noOfTrainReplace'] as int?,
      isPassengerDeboarding: json['isPassengerDeboarding'] as bool?,
      noofTrainDeboarded: _asInt(json['noofTrainDeboarded'] ?? json['NoofTrainDeboarded']),
      isPassengerAffected: _asBool(
        json['isPassengerAffected'] ?? json['IsPassengerAffected'] ?? json['passengerAffected'],
      ),
      noOfPassengerAffected: _asInt(
        json['noOfPassengerAffected'] ??
            json['NoOfPassengerAffected'] ??
            json['numberOfPassengerAffected'] ??
            json['NumberOfPassengerAffected'],
      ),
      trappedDuration: _asString(json['trappedDuration'] ?? json['TrappedDuration']),
      rescuedDuration: _asString(
        json['rescuedDuration'] ??
            json['RescuedDuration'] ??
            json['rescusedDuration'] ??
            json['RescusedDuration'],
      ),
      locationFailure: json['locationFailure'] as String?,
      actualFailureRectifiedDate: json['actualFailureRectifiedDate'] as String?,
      failureAttendedDate: json['failureAttendedDate'] as String?,
      failureType: json['failureType'] as String?,
      assignedUseeName: json['assignedUseeName'] as String?,
      underObservationDate: json['underObservationDate'] as String?,
      locationTypeId: json['locationTypeId'] as int?,
      corr_NotificationTypeId: json['corr_NotificationTypeId'] as int?,
      getObjectANDFaultList: json['getObjectANDFaultList'] != null
          ? (json['getObjectANDFaultList'] as List).map((e) => e as Map<String, dynamic>).toList()
          : null,
      getObjectANDFaultActionList: json['getObjectANDFaultActionList'] != null
          ? (json['getObjectANDFaultActionList'] as List).map((e) => e as Map<String, dynamic>).toList()
          : null,
      getObjectANDFaultRootCauseList: json['getObjectANDFaultRootCauseList'] != null
          ? (json['getObjectANDFaultRootCauseList'] as List).map((e) => e as Map<String, dynamic>).toList()
          : null,
    );
  }
}
