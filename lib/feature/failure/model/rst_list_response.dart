class RstListResponse {
  final int? responseCode;
  final String? responseMessage;
  final List<RstItem> responseOutput;

  RstListResponse({
    this.responseCode,
    this.responseMessage,
    this.responseOutput = const [],
  });

  factory RstListResponse.fromJson(Map<String, dynamic> json) {
    return RstListResponse(
      responseCode: json['responseCode'] as int?,
      responseMessage: json['responseMessage'] as String?,
      responseOutput: (json['responseOutput'] as List<dynamic>?)
              ?.map((e) => RstItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class RstItem {
  final int? notificationId;
  final String? notificationCode;
  final String? notificationEncryptId;
  final String? failureDescription;
  final int? functionLocationId;
  final String? functionLocationName;
  final String? functionLocationNumber;
  final int? equipmentId;
  final String? equipmentName;
  final String? equipmentNumber;
  final String? actualFailureOccuranceOn;
  final String? trainSetNo;
  final String? funcDescription;
  final int? statusId;
  final String? statusName;
  final int? iblId;
  final String? iblEncryptId;
  final bool? powerBlockRequired;
  final String? plantName;
  final String? failureTypeName;
  final String? natureOfWorkName;
  final String? id;

  RstItem({
    this.notificationId,
    this.notificationCode,
    this.notificationEncryptId,
    this.failureDescription,
    this.functionLocationId,
    this.functionLocationName,
    this.functionLocationNumber,
    this.equipmentId,
    this.equipmentName,
    this.equipmentNumber,
    this.actualFailureOccuranceOn,
    this.trainSetNo,
    this.funcDescription,
    this.statusId,
    this.statusName,
    this.iblId,
    this.iblEncryptId,
    this.powerBlockRequired,
    this.plantName,
    this.failureTypeName,
    this.natureOfWorkName,
    this.id,
  });

  factory RstItem.fromJson(Map<String, dynamic> json) {
    return RstItem(
      notificationId: json['notificationId'] as int?,
      notificationCode: json['notificationCode'] as String?,
      notificationEncryptId: json['notificationEncryptId'] as String?,
      failureDescription: json['failureDescription'] as String?,
      functionLocationId: json['functionLocationId'] as int?,
      functionLocationName: json['functionLocationName'] as String?,
      functionLocationNumber: json['functionLocationNumber'] as String?,
      equipmentId: json['equipmentId'] as int?,
      equipmentName: json['equipmentName'] as String?,
      equipmentNumber: json['equipmentNumber'] as String?,
      actualFailureOccuranceOn: json['actualFailureOccuranceOn'] as String?,
      trainSetNo: json['trainSetNo'] as String?,
      funcDescription: json['funcDescription'] as String?,
      statusId: json['statusId'] as int?,
      statusName: json['statusName'] as String?,
      iblId: json['iblId'] as int?,
      iblEncryptId: json['iblEncryptId'] as String?,
      powerBlockRequired: json['powerBlockRequired'] as bool?,
      plantName: json['plantName'] as String?,
      failureTypeName: json['failureTypeName'] as String?,
      natureOfWorkName: json['natureOfWorkName'] as String?,
      id: json['id'] as String?,
    );
  }
}
