import '../model/rst_failure_full_response.dart';
import '../model/rst_list_response.dart';

/// Turns one record of GetRstFailureTrasactionDetails
/// ({failure, documents, history, sicDetails, joinInspectionDetails,
/// workAllotedDetails, objectANDFault..., materialReqDetails, ...}) into the
/// models the RST list and detail screens already read, so the screens work
/// from the local copy (offline) with the same code as from the server.
class RstRecordMapper {
  RstRecordMapper._();

  static const _intKeys = [
    'notificationId', 'deptId', 'natureOfWorkId', 'trainRunningKM',
    'notificationTypeId', 'functionLocationId', 'equipmentId', 'assignedUserId',
    'trainDelayInMin', 'noOfTrainReplace', 'trainDelayInMin_', 'trainDelayInNo',
    'noOfTranCancel', 'noofTrainDeboarded', 'noOfTranWithdrawal',
    'assignUserId_SIC', 'assignedUserId_JI', 'deptId_JI', 'functionLocation_JI',
    'equipmentId_JI', 'noOfPassengerAffected', 'trappedDuration',
    'rescuedDuration', 'locationTypeId', 'systemDowntime', 'priorityId',
    'statusId', 'statusId_IBL', 'iblId', 'occTrainId', 'sicLocationId', 'id',
  ];

  static const _boolKeys = [
    'isServiceAffected', 'isPassengerDeboarding', 'isOHEReq',
    'isJointInspectionReq', 'isIntimationOfWorkReq', 'isHardwareReplaced',
    'isSICReq', 'isPTWReq', 'powerBlockRequired', 'sicRequired', 'ptwRequired',
    'isFailureRectifiDetails', 'isPassengerAffected', 'isWorkAllotedAccept',
    'isWorkCompletion', 'isSICWorkCompletion', 'isTrainReplace', 'isDeleted',
    'isMaterialSwapped',
  ];

  static const _stringKeys = [
    'notificationCode', 'notificationEncryptId', 'description',
    'failureDescription', 'functionLocationName', 'functionLocationNumber',
    'equipmentName', 'equipmentNumber', 'actualFailureOccuranceOn',
    'trainSetNo', 'ptwNo', 'intimationWorkNo', 'sicResponsiblePerson',
    'remark_JE', 'imagesPaths', 'imagesPathsAfter', 'imagesPathsRCA',
    'sicFailureType', 'createdBy', 'createdOn', 'failureAttendedDate',
    'actualFailureRectifiedDate', 'failureType', 'measurementPointIds',
    'funcDescription', 'assignedUseeName', 'emailId', 'priorityType',
    'doNotReport', 'locationFailure', 'mainLineActionTakenBy',
    'trainOperatorName', 'mainLineActionTaken', 'statusName', 'createdByName',
    'iblEncryptId', 'updatedByName', 'updatedDateTime', 'plantName',
    'carriedOutRemarks', 'departmentName', 'failureTypeName',
    'natureOfWorkName', 'occLocation', 'occTrainSetName', 'occLocationText',
    'occSubLocation', 'occSystemName', 'occRequestStatus', 'otherRequestFrom',
    'sicFillDate', 'trainSetName', 'userStatus', 'failureTypeId',
  ];

  static int? asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v'.trim());
  }

  static bool? asBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final t = '$v'.trim().toLowerCase();
    if (t == 'true' || t == 'yes' || t == '1') return true;
    if (t == 'false' || t == 'no' || t == '0') return false;
    return null;
  }

  static String? asString(dynamic v) => v == null ? null : '$v';

  static List<Map<String, dynamic>> _list(dynamic v) {
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  /// The "failure" map with every field in the type RstFetchData reads.
  static Map<String, dynamic> fetchData(Map<String, dynamic> record) {
    final src = record['failure'] is Map
        ? Map<String, dynamic>.from(record['failure'] as Map)
        : <String, dynamic>{};
    final out = <String, dynamic>{};
    for (final k in _intKeys) {
      out[k] = asInt(src[k]);
    }
    for (final k in _boolKeys) {
      out[k] = asBool(src[k]);
    }
    for (final k in _stringKeys) {
      out[k] = asString(src[k]);
    }
    // Names the old details response had under other keys.
    out['deptName'] = asString(src['departmentName']);
    out['workName'] = asString(src['natureOfWorkName']);
    out['notificationType'] = asString(src['failureTypeName']);
    return out;
  }

  static Map<String, dynamic> _notificationHistory(Map<String, dynamic> record) {
    final list = _list(record['notificationHistory']);
    final fallback = _list(record['history']);
    final m = list.isNotEmpty
        ? list.first
        : (fallback.isNotEmpty ? fallback.first : const <String, dynamic>{});
    return {
      'historyId': asInt(m['historyId']) ?? 0,
      'description': asString(m['description']) ?? '',
      'createdBy': asString(m['createdBy']) ?? '',
      'createdOn': asString(m['createdOn']) ?? '',
      // The failure's descriptions (web: the list above the Description box).
      'descriptionItems': [
        for (final e in fallback)
          {
            'description': asString(e['description']) ?? '',
            'createdBy': asString(e['createdBy']) ?? '',
            'createdOn': asString(e['createdOn']) ?? '',
          }
      ],
    };
  }

  static Map<String, dynamic> _joint(Map<String, dynamic> m) {
    String s(List<String> keys) {
      for (final k in keys) {
        if (m[k] != null) return '${m[k]}';
      }
      return '';
    }

    int n(List<String> keys) {
      for (final k in keys) {
        final v = asInt(m[k]);
        if (v != null) return v;
      }
      return 0;
    }

    return {
      'id': n(['id']),
      'jI_Dept_Id': n(['jI_Dept_Id', 'jiDeptId', 'deptId']),
      'jI_Dept_Name': s(['jI_Dept_Name', 'jiDeptName', 'deptName', 'departmentName']),
      'jI_ResponsiblePersonId':
          n(['jI_ResponsiblePersonId', 'jiResponsiblePersonId', 'responsiblePersonId']),
      'jI_ResponsiblePerson':
          s(['jI_ResponsiblePerson', 'jiResponsiblePerson', 'responsiblePerson']),
      'jI_Remark': s(['jI_Remark', 'jiRemark', 'remark']),
      'isDeleted': asBool(m['isDeleted']) ?? false,
      'jI_FunctionalLocation': s(['jI_FunctionalLocation', 'jiFunctionalLocation']),
      'jI_EquipementName': s(['jI_EquipementName', 'jiEquipementName']),
      'jI_Status': s(['jI_Status', 'jiStatus', 'statusName']),
      'jI_StatusId': n(['jI_StatusId', 'jiStatusId', 'statusId']),
      'jI_UserRemark': s(['jI_UserRemark', 'jiUserRemark', 'userRemark']),
    };
  }

  static Map<String, dynamic> _workAlloted(Map<String, dynamic> m) => {
        'id': asInt(m['id']) ?? 0,
        'workAllotedId': asInt(m['workAllotedId']) ?? 0,
        'maintainerUserId': asInt(m['maintainerUserId']) ?? 0,
        'maintainerUserName': asString(m['maintainerUserName']) ?? '',
        'workAllotedName': asString(m['workAllotedName']) ?? '',
        'isDeleted': asInt(m['isDeleted']) ?? 0,
      };

  static Map<String, dynamic> _assignment(Map<String, dynamic> m) => {
        'assignId': asInt(m['historyId']) ?? asInt(m['assignId']) ?? 0,
        'statusName': asString(m['statusName']) ?? '',
        'assgineUserName': asString(m['assgineUserName']) ?? '',
        'createdOn': asString(m['createdOn']) ?? '',
        'createdUserName': asString(m['createdUserName']) ?? '',
        'statusId': asInt(m['statusId']) ?? 0,
      };

  /// The details response the RST detail controller reads, from a record.
  static RstFailureFullResponse toFullResponse(Map<String, dynamic> record) {
    final json = <String, dynamic>{
      'notificationHistory': _notificationHistory(record),
      'rstFetchData': fetchData(record),
      'documents': _list(record['documents']),
      'sicUsers': _list(record['sicDetails']),
      'jointInspections': [
        for (final e in _list(record['joinInspectionDetails'])) _joint(e),
      ],
      'workAllotedUsers': [
        for (final e in _list(record['workAllotedDetails'])) _workAlloted(e),
      ],
      'rectificationDetails': _list(record['objectANDFaultDetails']),
      'actions': _list(record['objectANDFaultActionDetails']),
      'rootCauses': _list(record['objectANDFaultRootCauseDetails']),
      // The material rows name the id "materialid"; the screen reads "materialId".
      'materials': [
        for (final e in _list(record['materialReqDetails']))
          {...e, 'materialId': e['materialId'] ?? e['materialid']},
      ],
      'assignmentHistory': [
        for (final e in _list(record['jiAssgineNotificationHistory'])) _assignment(e),
      ],
      'sicCheckList': _list(record['rstsicCheckListDetails']),
      'materialSerialNumbers': _list(record['corrMaterialReqSerialNumber']),
      'materialSwapped': _list(record['corrMaterialSwapped']),
    };
    return RstFailureFullResponse.fromJson(json);
  }

  /// A list row from a record.
  static RstItem toListItem(Map<String, dynamic> record,
      {String? pendingAction, String? pendingError}) {
    final f = fetchData(record);
    return RstItem(
      notificationId: f['notificationId'] as int?,
      notificationCode: f['notificationCode'] as String?,
      notificationEncryptId: f['notificationEncryptId'] as String?,
      failureDescription: f['failureDescription'] as String?,
      functionLocationId: f['functionLocationId'] as int?,
      functionLocationName: f['functionLocationName'] as String?,
      functionLocationNumber: f['functionLocationNumber'] as String?,
      equipmentId: f['equipmentId'] as int?,
      equipmentName: f['equipmentName'] as String?,
      equipmentNumber: f['equipmentNumber'] as String?,
      actualFailureOccuranceOn: f['actualFailureOccuranceOn'] as String?,
      trainSetNo: f['trainSetNo'] as String?,
      funcDescription: f['funcDescription'] as String?,
      statusId: f['statusId'] as int?,
      statusName: f['statusName'] as String?,
      iblId: f['iblId'] as int?,
      iblEncryptId: f['iblEncryptId'] as String?,
      powerBlockRequired: f['powerBlockRequired'] as bool?,
      plantName: f['plantName'] as String?,
      failureTypeName: f['failureTypeName'] as String?,
      natureOfWorkName: f['natureOfWorkName'] as String?,
      id: (f['id'] ?? f['notificationId'])?.toString(),
      pendingAction: pendingAction,
      pendingError: pendingError,
    );
  }
}
