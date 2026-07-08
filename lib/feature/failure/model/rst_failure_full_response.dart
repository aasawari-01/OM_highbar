class RstFailureFullResponse {
  final NotificationHistory notificationHistory;
  final RstFetchData rstFetchData;
  final List<dynamic> documents;
  final List<dynamic> sicUsers;
  final List<JointInspection> jointInspections;
  final List<WorkAllotedUser> workAllotedUsers;
  final List<RectificationDetail> rectificationDetails;
  final List<Action> actions;
  final List<RootCause> rootCauses;
  final List<dynamic> materials;
  final List<AssignmentHistory> assignmentHistory;
  final List<dynamic> materialSerialNumbers;
  final List<dynamic> sicCheckList;
  final List<dynamic> materialSwapped;

  RstFailureFullResponse({
    required this.notificationHistory,
    required this.rstFetchData,
    required this.documents,
    required this.sicUsers,
    required this.jointInspections,
    required this.workAllotedUsers,
    required this.rectificationDetails,
    required this.actions,
    required this.rootCauses,
    required this.materials,
    required this.assignmentHistory,
    required this.sicCheckList,
    required this.materialSerialNumbers,
    required this.materialSwapped,
  });

  factory RstFailureFullResponse.fromJson(Map<String, dynamic> json) {
    return RstFailureFullResponse(
      notificationHistory: NotificationHistory.fromJson(json['notificationHistory'] as Map<String, dynamic>),
      rstFetchData: RstFetchData.fromJson(json['rstFetchData'] as Map<String, dynamic>),
      documents: json['documents'] as List? ?? [],
      sicUsers: json['sicUsers'] as List? ?? [],
      jointInspections: (json['jointInspections'] as List? ?? [])
          .map((e) => JointInspection.fromJson(e as Map<String, dynamic>))
          .toList(),
      workAllotedUsers: (json['workAllotedUsers'] as List? ?? [])
          .map((e) => WorkAllotedUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      rectificationDetails: (json['rectificationDetails'] as List? ?? [])
          .map((e) => RectificationDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      actions: (json['actions'] as List? ?? [])
          .map((e) => Action.fromJson(e as Map<String, dynamic>))
          .toList(),
      rootCauses: (json['rootCauses'] as List? ?? [])
          .map((e) => RootCause.fromJson(e as Map<String, dynamic>))
          .toList(),
      materials: json['materials'] as List? ?? [],
      assignmentHistory: (json['assignmentHistory'] as List? ?? [])
          .map((e) => AssignmentHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      sicCheckList: json['sicCheckList'] as List? ?? [],
      materialSerialNumbers: json['materialSerialNumbers'] as List? ?? [],
      materialSwapped: json['materialSwapped'] as List? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationHistory': notificationHistory.toJson(),
      'rstFetchData': rstFetchData.toJson(),
      'documents': documents,
      'sicUsers': sicUsers,
      'jointInspections': jointInspections.map((e) => e.toJson()).toList(),
      'workAllotedUsers': workAllotedUsers.map((e) => e.toJson()).toList(),
      'rectificationDetails': rectificationDetails.map((e) => e.toJson()).toList(),
      'actions': actions.map((e) => e.toJson()).toList(),
      'rootCauses': rootCauses.map((e) => e.toJson()).toList(),
      'materials': materials,
      'assignmentHistory': assignmentHistory.map((e) => e.toJson()).toList(),
      'sicCheckList': sicCheckList,
      'materialSerialNumbers': materialSerialNumbers,
      'materialSwapped': materialSwapped,
    };
  }
}

class NotificationHistory {
  final int historyId;
  final String description;
  final String createdBy;
  final String createdOn;

  NotificationHistory({
    required this.historyId,
    required this.description,
    required this.createdBy,
    required this.createdOn,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      historyId: json['historyId'] as int,
      description: json['description'] as String,
      createdBy: json['createdBy'] as String,
      createdOn: json['createdOn'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'historyId': historyId,
      'description': description,
      'createdBy': createdBy,
      'createdOn': createdOn,
    };
  }
}

class RstFetchData {
  final int? notificationId;
  final String? notificationCode;
  final String? notificationEncryptId;
  final String? description;
  final String? failureDescription;
  final int? deptId;
  final String? deptName;
  final int? natureOfWorkId;
  final String? workName;
  final int? trainRunningKM;
  final int? notificationTypeId;
  final String? notificationType;
  final int? functionLocationId;
  final String? functionLocationName;
  final String? functionLocationNumber;
  final int? equipmentId;
  final String? equipmentName;
  final String? equipmentNumber;
  final String? actualFailureOccuranceOn;
  final int? assignedUserId;
  final bool? isServiceAffected;
  final int? trainDelayInMin;
  final int? noOfTrainReplace;
  final int? trainDelayInMin_;
  final String? trainSetNo;
  final int? trainDelayInNo;
  final int? noOfTranCancel;
  final bool? isPassengerDeboarding;
  final int? noofTrainDeboarded;
  final int? noOfTranWithdrawal;
  final bool? isOHEReq;
  final bool? isJointInspectionReq;
  final bool? isIntimationOfWorkReq;
  final bool? isHardwareReplaced;
  final bool? isSICReq;
  final bool? isPTWReq;
  final bool? powerBlockRequired;
  final bool? sicRequired;
  final bool? ptwRequired;
  final int? assignUserId_SIC;
  final String? failureTypeId;
  final String? ptwNo;
  final String? intimationWorkNo;
  final int? assignedUserId_JI;
  final int? deptId_JI;
  final int? functionLocation_JI;
  final int? equipmentId_JI;
  final String? sicResponsiblePerson;
  final String? remark_JE;
  final String? imagesPaths;
  final String? imagesPathsAfter;
  final String? imagesPathsRCA;
  final String? sicFailureType;
  final String? createdBy;
  final String? createdOn;
  final String? failureAttendedDate;
  final String? actualFailureRectifiedDate;
  final String? failureType;
  final bool? isFailureRectifiDetails;
  final String? userStatus;
  final int? id;
  final bool? isPassengerAffected;
  final int? noOfPassengerAffected;
  final int? trappedDuration;
  final int? rescuedDuration;
  final int? locationTypeId;
  final int? systemDowntime;
  final String? measurementPointIds;
  final String? funcDescription;
  final String? assignedUseeName;
  final String? emailId;
  final int? priorityId;
  final int? statusId;
  final int? statusId_IBL;
  final String? priorityType;
  final String? doNotReport;
  final String? locationFailure;
  final String? mainLineActionTakenBy;
  final String? trainOperatorName;
  final String? mainLineActionTaken;
  final String? statusName;
  final bool? isWorkAllotedAccept;
  final bool? isWorkCompletion;
  final bool? isSICWorkCompletion;
  final String? createdByName;
  final int? iblId;
  final String? iblEncryptId;
  final bool? isTrainReplace;
  final String? updatedByName;
  final String? updatedDateTime;
  final String? plantName;
  final String? carriedOutRemarks;
  final String? departmentName;
  final String? failureTypeName;
  final String? natureOfWorkName;
  final bool? isDeleted;
  final String? occLocation;
  final String? occTrainSetName;
  final String? occLocationText;
  final String? occSubLocation;
  final String? occSystemName;
  final int? occTrainId;
  final String? occRequestStatus;
  final String? otherRequestFrom;
  final bool? isMaterialSwapped;
  final int? sicLocationId;
  final String? trainSetName;
  final String? sicFillDate;

  RstFetchData({
    this.notificationId,
    this.notificationCode,
    this.notificationEncryptId,
    this.description,
    this.failureDescription,
    this.deptId,
    this.deptName,
    this.natureOfWorkId,
    this.workName,
    this.trainRunningKM,
    this.notificationTypeId,
    this.notificationType,
    this.functionLocationId,
    this.functionLocationName,
    this.functionLocationNumber,
    this.equipmentId,
    this.equipmentName,
    this.equipmentNumber,
    this.actualFailureOccuranceOn,
    this.assignedUserId,
    this.isServiceAffected,
    this.trainDelayInMin,
    this.noOfTrainReplace,
    this.trainDelayInMin_,
    this.trainSetNo,
    this.trainDelayInNo,
    this.noOfTranCancel,
    this.isPassengerDeboarding,
    this.noofTrainDeboarded,
    this.noOfTranWithdrawal,
    this.isOHEReq,
    this.isJointInspectionReq,
    this.isIntimationOfWorkReq,
    this.isHardwareReplaced,
    this.isSICReq,
    this.isPTWReq,
    this.powerBlockRequired,
    this.sicRequired,
    this.ptwRequired,
    this.assignUserId_SIC,
    this.failureTypeId,
    this.ptwNo,
    this.intimationWorkNo,
    this.assignedUserId_JI,
    this.deptId_JI,
    this.functionLocation_JI,
    this.equipmentId_JI,
    this.sicResponsiblePerson,
    this.remark_JE,
    this.imagesPaths,
    this.imagesPathsAfter,
    this.imagesPathsRCA,
    this.sicFailureType,
    this.createdBy,
    this.createdOn,
    this.failureAttendedDate,
    this.actualFailureRectifiedDate,
    this.failureType,
    this.isFailureRectifiDetails,
    this.userStatus,
    this.id,
    this.isPassengerAffected,
    this.noOfPassengerAffected,
    this.trappedDuration,
    this.rescuedDuration,
    this.locationTypeId,
    this.systemDowntime,
    this.measurementPointIds,
    this.funcDescription,
    this.assignedUseeName,
    this.emailId,
    this.priorityId,
    this.statusId,
    this.statusId_IBL,
    this.priorityType,
    this.doNotReport,
    this.locationFailure,
    this.mainLineActionTakenBy,
    this.trainOperatorName,
    this.mainLineActionTaken,
    this.statusName,
    this.isWorkAllotedAccept,
    this.isWorkCompletion,
    this.isSICWorkCompletion,
    this.createdByName,
    this.iblId,
    this.iblEncryptId,
    this.isTrainReplace,
    this.updatedByName,
    this.updatedDateTime,
    this.plantName,
    this.carriedOutRemarks,
    this.departmentName,
    this.failureTypeName,
    this.natureOfWorkName,
    this.isDeleted,
    this.occLocation,
    this.occTrainSetName,
    this.occLocationText,
    this.occSubLocation,
    this.occSystemName,
    this.occTrainId,
    this.occRequestStatus,
    this.otherRequestFrom,
    this.isMaterialSwapped,
    this.sicLocationId,
    this.trainSetName,
    this.sicFillDate,
  });

  factory RstFetchData.fromJson(Map<String, dynamic> json) {
    return RstFetchData(
      notificationId: json['notificationId'] as int?,
      notificationCode: json['notificationCode'] as String?,
      notificationEncryptId: json['notificationEncryptId'] as String?,
      description: json['description'] as String?,
      failureDescription: json['failureDescription'] as String?,
      deptId: json['deptId'] as int?,
      deptId_JI:json['deptId_JI'] as int?,
      deptName: json['deptName'] as String?,
      natureOfWorkId: json['natureOfWorkId'] as int?,
      workName: json["workName"],
      trainRunningKM: json['trainRunningKM'] as int?,
      notificationTypeId: json['notificationTypeId'] as int?,
      notificationType: json['notificationType'] as String?,
      functionLocationId: json['functionLocationId'] as int?,
      functionLocationName: json['functionLocationName'] as String?,
      functionLocationNumber: json['functionLocationNumber'] as String?,
      equipmentId: json['equipmentId'] as int?,
      equipmentName: json['equipmentName'] as String?,
      equipmentNumber: json['equipmentNumber'] as String?,
      actualFailureOccuranceOn: json['actualFailureOccuranceOn'] as String?,
      assignedUserId: json['assignedUserId'] as int?,
      isServiceAffected: json['isServiceAffected'] as bool?,
      trainDelayInMin: json['trainDelayInMin'] as int?,
      noOfTrainReplace: json['noOfTrainReplace'] as int?,
      trainDelayInMin_: json['trainDelayInMin_'] as int?,
      trainSetNo: json['trainSetNo'] as String?,
      trainDelayInNo: json['trainDelayInNo'] as int?,
      noOfTranCancel: json['noOfTranCancel'] as int?,
      isPassengerDeboarding: json['isPassengerDeboarding'] as bool?,
      noofTrainDeboarded: json['noofTrainDeboarded'] as int?,
      noOfTranWithdrawal: json['noOfTranWithdrawal'] as int?,
      isOHEReq: json['isOHEReq'] as bool?,
      isJointInspectionReq: json['isJointInspectionReq'] as bool?,
      isIntimationOfWorkReq: json['isIntimationOfWorkReq'] as bool?,
      isHardwareReplaced: json['isHardwareReplaced'] as bool?,
      isSICReq: json['isSICReq'] as bool?,
      isPTWReq: json['isPTWReq'] as bool?,
      powerBlockRequired: json['powerBlockRequired'] as bool?,
      sicRequired: json['sicRequired'] as bool?,
      ptwRequired: json['ptwRequired'] as bool?,
      assignUserId_SIC: json['assignUserId_SIC'] as int?,
      failureTypeId: json['failureTypeId'] != null ? json['failureTypeId'].toString() : null,
      ptwNo: json['ptwNo'] as String?,
      intimationWorkNo: json['intimationWorkNo'] as String?,
      assignedUserId_JI: json['assignedUserId_JI'] as int?,
      functionLocation_JI: json['functionLocation_JI'] as int?,
      equipmentId_JI: json['equipmentId_JI'] as int?,
      sicResponsiblePerson: json['sicResponsiblePerson'] as String?,
      remark_JE: json['remark_JE'] as String?,
      imagesPaths: json['imagesPaths'] as String?,
      imagesPathsAfter: json['imagesPathsAfter'] as String?,
      imagesPathsRCA: json['imagesPathsRCA'] as String?,
      sicFailureType: json['sicFailureType'] as String?,
      createdBy: json['createdBy'] as String?,
      createdOn: json['createdOn'] as String?,
      failureAttendedDate: json['failureAttendedDate'] as String?,
      actualFailureRectifiedDate: json['actualFailureRectifiedDate'] as String?,
      failureType: json['failureType'] as String?,
      isFailureRectifiDetails: json['isFailureRectifiDetails'] as bool?,
      userStatus: json['userStatus'] != null ? json['userStatus'].toString() : null,
      id: json['id'] as int?,
      isPassengerAffected: json['isPassengerAffected'] as bool?,
      noOfPassengerAffected: json['noOfPassengerAffected'] as int?,
      trappedDuration: json['trappedDuration'] as int?,
      rescuedDuration: json['rescuedDuration'] as int?,
      locationTypeId: json['locationTypeId'] as int?,
      systemDowntime: json['systemDowntime'] as int?,
      measurementPointIds: json['measurementPointIds'] as String?,
      funcDescription: json['funcDescription'] as String?,
      assignedUseeName: json['assignedUseeName'] as String?,
      emailId: json['emailId'] as String?,
      priorityId: json['priorityId'] as int?,
      statusId: json['statusId'] as int?,
      statusId_IBL: json['statusId_IBL'] as int?,
      priorityType: json['priorityType'] as String?,
      doNotReport: json['doNotReport'] as String?,
      locationFailure: json['locationFailure'] as String?,
      mainLineActionTakenBy: json['mainLineActionTakenBy'] as String?,
      trainOperatorName: json['trainOperatorName'] as String?,
      mainLineActionTaken: json['mainLineActionTaken'] as String?,
      statusName: json['statusName'] as String?,
      isWorkAllotedAccept: json['isWorkAllotedAccept'] as bool?,
      isWorkCompletion: json['isWorkCompletion'] as bool?,
      isSICWorkCompletion: json['isSICWorkCompletion'] as bool?,
      createdByName: json['createdByName'] as String?,
      iblId: json['iblId'] as int?,
      iblEncryptId: json['iblEncryptId'] as String?,
      isTrainReplace: json['isTrainReplace'] as bool?,
      updatedByName: json['updatedByName'] as String?,
      updatedDateTime: json['updatedDateTime'] as String?,
      plantName: json['plantName'] as String?,
      carriedOutRemarks: json['carriedOutRemarks'] as String?,
      departmentName: json['departmentName'] as String?,
      failureTypeName: json['failureTypeName'] as String?,
      natureOfWorkName: json['natureOfWorkName'] as String?,
      isDeleted: json['isDeleted'] as bool?,
      occLocation: json['occLocation'] as String?,
      occTrainSetName: json['occTrainSetName'] as String?,
      occLocationText: json['occLocationText'] as String?,
      occSubLocation: json['occSubLocation'] as String?,
      occSystemName: json['occSystemName'] as String?,
      occTrainId: json['occTrainId'] as int?,
      occRequestStatus: json['occRequestStatus'] as String?,
      otherRequestFrom: json['otherRequestFrom'] as String?,
      isMaterialSwapped: json['isMaterialSwapped'] as bool?,
      sicLocationId: json['sicLocationId'] as int?,
      trainSetName: json['trainSetName'] as String?,
      sicFillDate: json['sicFillDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'notificationCode': notificationCode,
      'notificationEncryptId': notificationEncryptId,
      'description': description,
      'failureDescription': failureDescription,
      'deptId': deptId,
      'deptName': deptName,
      'natureOfWorkId': natureOfWorkId,
      'workName':workName,
      'trainRunningKM': trainRunningKM,
      'notificationTypeId': notificationTypeId,
      'notificationType':notificationType,
      'functionLocationId': functionLocationId,
      'functionLocationName': functionLocationName,
      'functionLocationNumber': functionLocationNumber,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'equipmentNumber': equipmentNumber,
      'actualFailureOccuranceOn': actualFailureOccuranceOn,
      'assignedUserId': assignedUserId,
      'isServiceAffected': isServiceAffected,
      'trainDelayInMin': trainDelayInMin,
      'noOfTrainReplace': noOfTrainReplace,
      'trainDelayInMin_': trainDelayInMin_,
      'trainSetNo': trainSetNo,
      'trainDelayInNo': trainDelayInNo,
      'noOfTranCancel': noOfTranCancel,
      'isPassengerDeboarding': isPassengerDeboarding,
      'noofTrainDeboarded': noofTrainDeboarded,
      'noOfTranWithdrawal': noOfTranWithdrawal,
      'isOHEReq': isOHEReq,
      'isJointInspectionReq': isJointInspectionReq,
      'isIntimationOfWorkReq': isIntimationOfWorkReq,
      'isHardwareReplaced': isHardwareReplaced,
      'isSICReq': isSICReq,
      'isPTWReq': isPTWReq,
      'powerBlockRequired': powerBlockRequired,
      'sicRequired': sicRequired,
      'ptwRequired': ptwRequired,
      'assignUserId_SIC': assignUserId_SIC,
      'failureTypeId': failureTypeId,
      'ptwNo': ptwNo,
      'intimationWorkNo': intimationWorkNo,
      'assignedUserId_JI': assignedUserId_JI,
      'deptId_JI': deptId_JI,
      'functionLocation_JI': functionLocation_JI,
      'equipmentId_JI': equipmentId_JI,
      'sicResponsiblePerson': sicResponsiblePerson,
      'remark_JE': remark_JE,
      'imagesPaths': imagesPaths,
      'imagesPathsAfter': imagesPathsAfter,
      'imagesPathsRCA': imagesPathsRCA,
      'sicFailureType': sicFailureType,
      'createdBy': createdBy,
      'createdOn': createdOn,
      'failureAttendedDate': failureAttendedDate,
      'actualFailureRectifiedDate': actualFailureRectifiedDate,
      'failureType': failureType,
      'isFailureRectifiDetails': isFailureRectifiDetails,
      'userStatus': userStatus,
      'id': id,
      'isPassengerAffected': isPassengerAffected,
      'noOfPassengerAffected': noOfPassengerAffected,
      'trappedDuration': trappedDuration,
      'rescuedDuration': rescuedDuration,
      'locationTypeId': locationTypeId,
      'systemDowntime': systemDowntime,
      'measurementPointIds': measurementPointIds,
      'funcDescription': funcDescription,
      'assignedUseeName': assignedUseeName,
      'emailId': emailId,
      'priorityId': priorityId,
      'statusId': statusId,
      'statusId_IBL': statusId_IBL,
      'priorityType': priorityType,
      'doNotReport': doNotReport,
      'locationFailure': locationFailure,
      'mainLineActionTakenBy': mainLineActionTakenBy,
      'trainOperatorName': trainOperatorName,
      'mainLineActionTaken': mainLineActionTaken,
      'statusName': statusName,
      'isWorkAllotedAccept': isWorkAllotedAccept,
      'isWorkCompletion': isWorkCompletion,
      'isSICWorkCompletion': isSICWorkCompletion,
      'createdByName': createdByName,
      'iblId': iblId,
      'iblEncryptId': iblEncryptId,
      'isTrainReplace': isTrainReplace,
      'updatedByName': updatedByName,
      'updatedDateTime': updatedDateTime,
      'plantName': plantName,
      'carriedOutRemarks': carriedOutRemarks,
      'departmentName': departmentName,
      'failureTypeName': failureTypeName,
      'natureOfWorkName': natureOfWorkName,
      'isDeleted': isDeleted,
      'occLocation': occLocation,
      'occTrainSetName': occTrainSetName,
      'occLocationText': occLocationText,
      'occSubLocation': occSubLocation,
      'occSystemName': occSystemName,
      'occTrainId': occTrainId,
      'occRequestStatus': occRequestStatus,
      'otherRequestFrom': otherRequestFrom,
      'isMaterialSwapped': isMaterialSwapped,
      'sicLocationId': sicLocationId,
      'trainSetName': trainSetName,
      'sicFillDate': sicFillDate,
    };
  }
}

class JointInspection {
  final int id;
  final int jI_Dept_Id;
  final String jI_Dept_Name;
  final int jI_ResponsiblePersonId;
  final String jI_ResponsiblePerson;
  final String? jI_Remark;
  final bool isDeleted;
  final String? jI_FunctionalLocation;
  final String? jI_EquipementName;
  final String jI_Status;
  final num jI_StatusId;
  final String? jI_UserRemark;

  JointInspection({
    required this.id,
    required this.jI_Dept_Id,
    required this.jI_Dept_Name,
    required this.jI_ResponsiblePersonId,
    required this.jI_ResponsiblePerson,
    required this.jI_Remark,
    required this.isDeleted,
    this.jI_FunctionalLocation,
    this.jI_EquipementName,
    required this.jI_Status,
    required this.jI_StatusId,
    this.jI_UserRemark,
  });

  factory JointInspection.fromJson(Map<String, dynamic> json) {
    return JointInspection(
      id: json['id'] as int,
      jI_Dept_Id: json['jI_Dept_Id'] as int,
      jI_Dept_Name: json['jI_Dept_Name'] as String,
      jI_ResponsiblePersonId: json['jI_ResponsiblePersonId'] as int,
      jI_ResponsiblePerson: json['jI_ResponsiblePerson'] as String,
      jI_Remark: json['jI_Remark'] as String? ?? '',
      isDeleted: json['isDeleted'] as bool,
      jI_FunctionalLocation: json['jI_FunctionalLocation'] as String?,
      jI_EquipementName: json['jI_EquipementName'] as String?,
      jI_Status: json['jI_Status'] as String,
      jI_StatusId: json['jI_StatusId'] as num,
      jI_UserRemark: json['jI_UserRemark'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jI_Dept_Id': jI_Dept_Id,
      'jI_Dept_Name': jI_Dept_Name,
      'jI_ResponsiblePersonId': jI_ResponsiblePersonId,
      'jI_ResponsiblePerson': jI_ResponsiblePerson,
      'jI_Remark': jI_Remark,
      'isDeleted': isDeleted,
      'jI_FunctionalLocation': jI_FunctionalLocation,
      'jI_EquipementName': jI_EquipementName,
      'jI_Status': jI_Status,
      'jI_StatusId': jI_StatusId,
      'jI_UserRemark': jI_UserRemark,
    };
  }
}

class WorkAllotedUser {
  final int id;
  final int workAllotedId;
  final int maintainerUserId;
  final String maintainerUserName;
  final String workAllotedName;
  final int isDeleted;

  WorkAllotedUser({
    required this.id,
    required this.workAllotedId,
    required this.maintainerUserId,
    required this.maintainerUserName,
    required this.workAllotedName,
    required this.isDeleted,
  });

  factory WorkAllotedUser.fromJson(Map<String, dynamic> json) {
    return WorkAllotedUser(
      id: json['id'] as int,
      workAllotedId: json['workAllotedId'] as int,
      maintainerUserId: json['maintainerUserId'] as int,
      maintainerUserName: json['maintainerUserName'] as String,
      workAllotedName: json['workAllotedName'] as String,
      isDeleted: json['isDeleted'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workAllotedId': workAllotedId,
      'maintainerUserId': maintainerUserId,
      'maintainerUserName': maintainerUserName,
      'workAllotedName': workAllotedName,
      'isDeleted': isDeleted,
    };
  }
}

class RectificationDetail {
  final int rectId;
  final int notificationId;
  final int objectPartId;
  final String? objectPartText;
  final String? objectName;
  final int faultId;
  final String? faultText;
  final String? faultName;

  RectificationDetail({
    required this.rectId,
    required this.notificationId,
    required this.objectPartId,
    this.objectPartText,
    this.objectName,
    required this.faultId,
    this.faultText,
    this.faultName,
  });

  factory RectificationDetail.fromJson(Map<String, dynamic> json) {
    return RectificationDetail(
      rectId: json['rectId'] as int? ?? 0,
      notificationId: json['notificationId'] as int? ?? 0,
      objectPartId: json['objectPartId'] as int? ?? 0,
      objectPartText: json['objectPartText'] as String?,
      objectName: json['objectName'] as String?,
      faultId: json['faultId'] as int? ?? 0,
      faultText: json['faultText'] as String?,
      faultName: json['faultName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rectId': rectId,
      'notificationId': notificationId,
      'objectPartId': objectPartId,
      'objectPartText': objectPartText,
      'objectName': objectName,
      'faultId': faultId,
      'faultText': faultText,
      'faultName': faultName,
    };
  }
}

class Action {
  final int rectId;
  final int faultId;
  final int objectPartId;
  final int actionId;
  final String actionText;
  final String actionName;

  Action({
    required this.rectId,
    required this.faultId,
    required this.objectPartId,
    required this.actionId,
    required this.actionText,
    required this.actionName,
  });

  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      rectId: json['rectId'] as int? ?? 0,
      faultId: json['faultId'] as int? ?? 0,
      objectPartId: json['objectPartId'] as int? ?? 0,
      actionId: json['actionId'] as int? ?? 0,
      actionText: json['actionText'] as String? ?? '',
      actionName: json['actionName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rectId': rectId,
      'faultId': faultId,
      'objectPartId': objectPartId,
      'actionId': actionId,
      'actionText': actionText,
      'actionName': actionName,
    };
  }
}

class RootCause {
  final int rectId;
  final int faultId;
  final int objectPartId;
  final int rcaId;
  final String rcaText;
  final String rootCasueName;

  RootCause({
    required this.rectId,
    required this.faultId,
    required this.objectPartId,
    required this.rcaId,
    required this.rcaText,
    required this.rootCasueName,
  });

  factory RootCause.fromJson(Map<String, dynamic> json) {
    return RootCause(
      rectId: json['rectId'] as int? ?? 0,
      faultId: json['faultId'] as int? ?? 0,
      objectPartId: json['objectPartId'] as int? ?? 0,
      rcaId: json['rcaId'] as int? ?? 0,
      rcaText: json['rcaText'] as String? ?? '',
      rootCasueName: json['rootCasueName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rectId': rectId,
      'faultId': faultId,
      'objectPartId': objectPartId,
      'rcaId': rcaId,
      'rcaText': rcaText,
      'rootCasueName': rootCasueName,
    };
  }
}

class AssignmentHistory {
  final int assignId;
  final String statusName;
  final String assgineUserName;
  final String createdOn;
  final String createdUserName;
  final int statusId;

  AssignmentHistory({
    required this.assignId,
    required this.statusName,
    required this.assgineUserName,
    required this.createdOn,
    required this.createdUserName,
    required this.statusId,
  });

  factory AssignmentHistory.fromJson(Map<String, dynamic> json) {
    return AssignmentHistory(
      assignId: json['assignId'] as int,
      statusName: json['statusName'] as String,
      assgineUserName: json['assgineUserName'] as String,
      createdOn: json['createdOn'] as String,
      createdUserName: json['createdUserName'] as String,
      statusId: json['statusId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignId': assignId,
      'statusName': statusName,
      'assgineUserName': assgineUserName,
      'createdOn': createdOn,
      'createdUserName': createdUserName,
      'statusId': statusId,
    };
  }
}
