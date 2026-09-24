import '../../../service/network_service/app_urls.dart';

class OccInstructionDetailResponse {
  OccInstructionDetailResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final OccInstructionDetail data;

  factory OccInstructionDetailResponse.fromJson(Map<String, dynamic> json) {
    return OccInstructionDetailResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: OccInstructionDetail.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class OccInstructionDetail {
  OccInstructionDetail({
    required this.instructionId,
    required this.instructionNumber,
    this.issueDate,
    this.validityUpto,
    required this.instructionTypeId,
    required this.instructionTypeName,
    required this.instructionById,
    required this.instructionByName,
    required this.instructionContent,
    required this.remarks,
    this.emergencyTypeId,
    this.emergencyTypeName,
    required this.instructionStatus,
    this.createdDateTime,
    required this.technicalSystems,
    required this.stations,
    required this.attachments,
    required this.acknowledgements,
    this.isReadByCurrentUser,
    this.readDateTime,
    this.isAcknowledgedByCurrentUser,
    this.myAcknowledgementRemark,
    this.myAcknowledgementDateTime,
  });

  final int instructionId;
  final String instructionNumber;
  final DateTime? issueDate;
  final DateTime? validityUpto;
  final int instructionTypeId;
  final String instructionTypeName;
  final int instructionById;
  final String instructionByName;
  final String instructionContent;
  final String remarks;
  final int? emergencyTypeId;
  final String? emergencyTypeName;
  final String instructionStatus;
  final DateTime? createdDateTime;
  final List<InstructionTechnicalSystem> technicalSystems;
  final List<InstructionStation> stations;
  final List<InstructionAttachment> attachments;
  final List<InstructionAcknowledgement> acknowledgements;
  final bool? isReadByCurrentUser;
  final DateTime? readDateTime;
  final bool? isAcknowledgedByCurrentUser;
  final String? myAcknowledgementRemark;
  final DateTime? myAcknowledgementDateTime;

  factory OccInstructionDetail.fromJson(Map<String, dynamic> json) {
    return OccInstructionDetail(
      instructionId: json['instructionId'] ?? 0,
      instructionNumber: json['instructionNumber']?.toString() ?? '',
      issueDate: _parseDate(json['issueDate']),
      validityUpto: _parseDate(json['validityUpto']),
      instructionTypeId: json['instructionTypeId'] ?? 0,
      instructionTypeName: json['instructionTypeName']?.toString() ?? '',
      instructionById: json['instructionById'] ?? 0,
      instructionByName: json['instructionByName']?.toString() ?? '',
      instructionContent: json['instructionContent']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      emergencyTypeId: json['emergencyTypeId'],
      emergencyTypeName: json['emergencyTypeName']?.toString(),
      instructionStatus: json['instructionStatus']?.toString() ?? '',
      createdDateTime: _parseDate(json['createdDateTime']),
      technicalSystems: ((json['technicalSystems'] as List?) ?? [])
          .map((e) => InstructionTechnicalSystem.fromJson(
        (e as Map<String, dynamic>?) ?? const {},
      ))
          .toList(),
      stations: ((json['stations'] as List?) ?? [])
          .map((e) => InstructionStation.fromJson(
        (e as Map<String, dynamic>?) ?? const {},
      ))
          .toList(),
      attachments: ((json['attachments'] as List?) ?? [])
          .map((e) => InstructionAttachment.fromJson(
        (e as Map<String, dynamic>?) ?? const {},
      ))
          .toList(),
      acknowledgements: ((json['acknowledgements'] as List?) ?? [])
          .map((e) => InstructionAcknowledgement.fromJson(
        (e as Map<String, dynamic>?) ?? const {},
      ))
          .toList(),
      isReadByCurrentUser: json['isReadByCurrentUser'],
      readDateTime: _parseDate(json['readDateTime']),
      isAcknowledgedByCurrentUser: json['isAcknowledgedByCurrentUser'],
      myAcknowledgementRemark: json['myAcknowledgementRemark']?.toString(),
      myAcknowledgementDateTime:
      _parseDate(json['myAcknowledgementDateTime']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class InstructionTechnicalSystem {
  InstructionTechnicalSystem({
    this.departmentId,
    this.deptName,
    this.systemName,
  });

  final int? departmentId;
  final String? deptName;
  final String? systemName;

  factory InstructionTechnicalSystem.fromJson(Map<String, dynamic> json) {
    return InstructionTechnicalSystem(
      departmentId: json['departmentId'],
      deptName: json['deptName']?.toString(),
      systemName: json['systemName']?.toString(),
    );
  }
}

class InstructionStation {
  InstructionStation({
    this.stationId,
    this.stationName,
    this.isAcknowledged,
  });

  final int? stationId;
  final String? stationName;
  final bool? isAcknowledged;

  factory InstructionStation.fromJson(Map<String, dynamic> json) {
    return InstructionStation(
      stationId: json['stationId'],
      stationName: json['stationName']?.toString(),
      isAcknowledged: json['isAcknowledged'],
    );
  }
}

class InstructionAttachment {
  InstructionAttachment({
    required this.attachmentId,
    required this.fileName,
    required this.filePath,
    required this.fileExtension,
    required this.fileSize,
    this.uploadedDateTime,
  });

  final int attachmentId;
  final String fileName;
  final String filePath;
  final String fileExtension;
  final int fileSize;
  final DateTime? uploadedDateTime;

  factory InstructionAttachment.fromJson(Map<String, dynamic> json) {
    return InstructionAttachment(
      attachmentId: json['attachmentId'] ?? 0,
      fileName: json['fileName']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      fileExtension: json['fileExtension']?.toString() ?? '',
      fileSize: json['fileSize'] ?? 0,
      uploadedDateTime:
      OccInstructionDetail._parseDate(json['uploadedDateTime']),
    );
  }

  bool get isImage => const [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  ].contains(fileExtension.toLowerCase());

  bool get isPdf => fileExtension.toLowerCase() == '.pdf';

  // TODO: confirm `AppUrls.baseUrl` is the actual constant name in your
  // app_urls.dart — swap it if it's named differently.
  String get fullUrl => '${AppUrls.imageUrl}$filePath';
}

// TODO: shape unconfirmed — acknowledgements was empty in the sample
// response, so these field names are a best guess based on how the
// dummy data in InstructionDetailsScreen was structured (name/status/
// remark/date/time). Share a populated sample and I'll match it exactly.




class InstructionAcknowledgement {
  InstructionAcknowledgement({
    this.stationId,
    this.stationName,
    this.userId,
    this.userName,
    this.readStatus,
    this.readDateTime,
    this.acknowledgementStatus,
    this.acknowledgementRemark,
    this.acknowledgementDateTime,
  });

  final int? stationId;
  final String? stationName;

  final int? userId;
  final String? userName;

  final bool? readStatus;
  final DateTime? readDateTime;

  final bool? acknowledgementStatus;
  final String? acknowledgementRemark;
  final DateTime? acknowledgementDateTime;

  factory InstructionAcknowledgement.fromJson(
      Map<String, dynamic> json,
      ) {
    return InstructionAcknowledgement(
      stationId: json['stationId'] is int
          ? json['stationId']
          : int.tryParse(json['stationId']?.toString() ?? ''),

      stationName: json['stationName']?.toString(),

      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? ''),

      userName: json['userName']?.toString(),

      readStatus: json['readStatus'],

      readDateTime:
      OccInstructionDetail._parseDate(json['readDateTime']),

      acknowledgementStatus:
      json['acknowledgementStatus'],

      acknowledgementRemark:
      json['acknowledgementRemark']?.toString(),

      acknowledgementDateTime:
      OccInstructionDetail._parseDate(
        json['acknowledgementDateTime'],
      ),
    );
  }
}