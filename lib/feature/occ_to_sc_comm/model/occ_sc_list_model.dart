import 'dart:convert';

class OccInstructionListResponse {
  final bool success;
  final String message;
  final OccInstructionListData data;

  OccInstructionListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OccInstructionListResponse.fromJson(
      Map<String, dynamic> json,
      ) {
    return OccInstructionListResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      data: OccInstructionListData.fromJson(
        json['data'] ?? {},
      ),
    );
  }
}


class OccInstructionAcknowledgeResponse {
  OccInstructionAcknowledgeResponse({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  factory OccInstructionAcknowledgeResponse.fromJson(
      Map<String, dynamic> json,
      ) {
    return OccInstructionAcknowledgeResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}

class OccInstructionListData {
  final List<OccInstructionListItem> items;
  final int pageNumber;
  final int pageSize;
  final int totalRecords;
  final int totalPages;

  OccInstructionListData({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
  });

  factory OccInstructionListData.fromJson(
      Map<String, dynamic> json,
      ) {
    return OccInstructionListData(
      items: (json['items'] as List<dynamic>? ?? [])
          .map(
            (e) => OccInstructionListItem.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList(),
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}

class OccInstructionListItem {
  final int instructionId;
  final String instructionNumber;
  final DateTime? issueDate;
  final DateTime? validityUpto;

  final int instructionTypeId;
  final String instructionTypeName;

  final int instructionById;
  final String instructionByName;

  final String instructionContent;

  final String recipientSummary;

  final int totalStations;
  final int acknowledgedStations;
  final int pendingStations;

  final String acknowledgementStatus;
  final String instructionStatus;

  final DateTime? createdDateTime;

  final bool? isAcknowledgedByCurrentUser;
  final DateTime? myAcknowledgementDateTime;

  OccInstructionListItem({
    required this.instructionId,
    required this.instructionNumber,
    required this.issueDate,
    required this.validityUpto,
    required this.instructionTypeId,
    required this.instructionTypeName,
    required this.instructionById,
    required this.instructionByName,
    required this.instructionContent,
    required this.recipientSummary,
    required this.totalStations,
    required this.acknowledgedStations,
    required this.pendingStations,
    required this.acknowledgementStatus,
    required this.instructionStatus,
    required this.createdDateTime,
    required this.isAcknowledgedByCurrentUser,
    required this.myAcknowledgementDateTime,
  });

  factory OccInstructionListItem.fromJson(
      Map<String, dynamic> json,
      ) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;

      return DateTime.tryParse(
        value.toString(),
      );
    }

    return OccInstructionListItem(
      instructionId: json['instructionId'] ?? 0,
      instructionNumber:
      json['instructionNumber']?.toString() ?? '',

      issueDate: parseDate(
        json['issueDate'],
      ),

      validityUpto: parseDate(
        json['validityUpto'],
      ),

      instructionTypeId:
      json['instructionTypeId'] ?? 0,

      instructionTypeName:
      json['instructionTypeName']?.toString() ?? '',

      instructionById:
      json['instructionById'] ?? 0,

      instructionByName:
      json['instructionByName']?.toString() ?? '',

      instructionContent:
      json['instructionContent']?.toString() ?? '',

      recipientSummary:
      json['recipientSummary']?.toString() ?? '',

      totalStations:
      json['totalStations'] ?? 0,

      acknowledgedStations:
      json['acknowledgedStations'] ?? 0,

      pendingStations:
      json['pendingStations'] ?? 0,

      acknowledgementStatus:
      json['acknowledgementStatus']?.toString() ?? '',

      instructionStatus:
      json['instructionStatus']?.toString() ?? '',

      createdDateTime:
      parseDate(
        json['createdDateTime'],
      ),

      isAcknowledgedByCurrentUser:
      json['isAcknowledgedByCurrentUser'],

      myAcknowledgementDateTime:
      parseDate(
        json['myAcknowledgementDateTime'],
      ),
    );
  }
}