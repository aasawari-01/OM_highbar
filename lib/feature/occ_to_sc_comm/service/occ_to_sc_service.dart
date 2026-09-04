import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';

import '../model/occ_instruction_detail_model.dart';
import '../model/occ_sc_list_model.dart';
import '../model/occ_to_sc_model.dart';

class OccToScService {
  OccToScService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<OccToScMasterDataResponse> getOccToScMasterData({
    required String userId,
  }) async {
    debugPrint("getOccToScMasterData");

    final http.Response response = await _apiClient.post(
      AppUrls.occTOscMasterData,
      body: <String, dynamic>{
        'userId': userId,
      },
    );

    log(
      "getOccToScMasterData response == "
          "${response.body} ---- ${response.statusCode}",
    );

    Map<String, dynamic> jsonBody = {};

    try {
      jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("JSON parsing error: $e");

      throw OccToScException(
        'Invalid response from server. (${response.statusCode})',
      );
    }

    if (response.statusCode == 200) {
      debugPrint(
        "getOccToScMasterData success === $jsonBody",
      );

      final result = OccToScMasterDataResponse.fromJson(jsonBody);

      if (result.success) {
        return result;
      }

      throw OccToScException(
        result.message.isNotEmpty
            ? result.message
            : 'Unable to fetch OCC to SC master data.',
      );
    }

    debugPrint(
      "getOccToScMasterData error == ${response.statusCode}",
    );

    final message =
        jsonBody['message']?.toString() ??
            jsonBody['detail']?.toString() ??
            'Unable to fetch OCC to SC master data. '
                '(${response.statusCode})';

    throw OccToScException(message);
  }




  Future<OccInstructionListResponse> getInstructionList({
    required int userId,
    required String role,
    required int pageNumber,
    required int pageSize,
    required String instructionStatus,
    required String stationId,
  }) async {
    debugPrint(
      'getInstructionList '
          'userId=$userId '
          'role=$role '
          'pageNumber=$pageNumber '
          'pageSize=$pageSize '
          'instructionStatus=$instructionStatus',

    );

    final http.Response response = await _apiClient.post(
      AppUrls.getInstructionList,
      body: <String, dynamic>{
        'userId': userId,
        'role': role,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        'instructionStatus': instructionStatus,
        "StationId":stationId
      },
    );

    log(
      'getInstructionList response == '
          '${response.body} ---- ${response.statusCode}',
    );

    Map<String, dynamic> jsonBody = {};

    try {
      jsonBody =
      jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint(
        'getInstructionList JSON parsing error: $e',
      );

      throw OccToScException(
        'Invalid response from server. (${response.statusCode})',
      );
    }

    if (response.statusCode == 200) {
      final result =
      OccInstructionListResponse.fromJson(
        jsonBody,
      );

      if (result.success) {
        return result;
      }

      throw OccToScException(
        result.message.isNotEmpty
            ? result.message
            : 'Unable to fetch instruction list.',
      );
    }

    final message =
        jsonBody['message']?.toString() ??
            jsonBody['detail']?.toString() ??
            'Unable to fetch instruction list. '
                '(${response.statusCode})';

    throw OccToScException(message);
  }




  Future<OccInstructionSubmitResponse> createOccInstruction({
    required DateTime issueDate,
    required DateTime validityUpto,
    required int instructionTypeId,
    required int instructionById,
    int? emergencyTypeId,
    required String instructionContent,

    required List<int> stationIds,
    List<Map<String, dynamic>>? technicalDetails,
    required String? createdBy,
    required List<Map<String, dynamic>> files,
  }) async {
    final Map<String, String> fields = <String, String>{
      'IssueDate': _formatDate(issueDate),
      'ValidityUpto': _formatDate(validityUpto),
      'InstructionTypeId': instructionTypeId.toString(),
      'InstructionById': instructionById.toString(),
      'InstructionContent': instructionContent,

      'CreatedBy': createdBy.toString(),
    };

    if (emergencyTypeId != null) {
      fields['EmergencyTypeId'] = emergencyTypeId.toString();
    }

    if (technicalDetails != null && technicalDetails.isNotEmpty) {
      fields['TechnicalDetails'] = jsonEncode(technicalDetails);
    }

    final List<http.MultipartFile> multipartFiles = <http.MultipartFile>[];

    // Repeated field -> can't use `fields` (Map, one value per key),
    // so each StationId is sent as its own string part with the same name.
    for (final int id in stationIds) {
      multipartFiles.add(
        http.MultipartFile.fromString('StationIds', id.toString()),
      );
    }

    for (final Map<String, dynamic> file in files) {
      final String? path = file['path'] as String?;

      if (path == null || path.isEmpty) {
        continue;
      }

      multipartFiles.add(
        await http.MultipartFile.fromPath('Files', path),
      );
    }

    // -----------------------------------------------------------------
    // Full payload dump — everything actually going over the wire.
    // -----------------------------------------------------------------
    final StringBuffer payloadLog = StringBuffer()
      ..writeln('===== createOccInstruction PAYLOAD =====')
      ..writeln('Fields:');

    fields.forEach((key, value) {
      payloadLog.writeln('  $key = $value');
    });

    payloadLog.writeln('StationIds (${stationIds.length}): $stationIds');

    payloadLog.writeln('Files (${multipartFiles.length}):');
    for (final http.MultipartFile f in multipartFiles) {
      payloadLog.writeln(
        '  field="${f.field}" filename="${f.filename}" '
            'length=${f.length} contentType=${f.contentType}',
      );
    }

    payloadLog.writeln('=========================================');

    log(payloadLog.toString());

    final http.Response response = await _apiClient.postMultipart(
      AppUrls.createOccInstruction,
      fields: fields,
      files: multipartFiles,
    );

    debugPrint(
      "createOccInstruction response == "
          "${response.body} ---- ${response.statusCode}",
    );

    Map<String, dynamic> jsonBody = {};

    try {
      jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("JSON parsing error: $e");

      throw OccToScException(
        'Invalid response from server. (${response.statusCode})',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final result = OccInstructionSubmitResponse.fromJson(jsonBody);

      if (result.success) {
        return result;
      }

      throw OccToScException(
        result.message.isNotEmpty
            ? result.message
            : 'Unable to submit instruction.',
      );
    }

    final message = jsonBody['message']?.toString() ??
        jsonBody['detail']?.toString() ??
        'Unable to submit instruction. (${response.statusCode})';

    throw OccToScException(message);
  }

  String _formatDate(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }




  Future<OccInstructionDetailResponse> getInstructionById({
    required String userId,
    required String role,
    required int instructionId,
    String stationId = '',
  }) async {
    debugPrint(
      'getInstructionById '
          'userId=$userId role=$role instructionId=$instructionId '
          'stationId=$stationId',
    );

    final http.Response response = await _apiClient.post(
      AppUrls.getInstructionById,
      body: <String, dynamic>{
        'userId': userId,
        'role': role,
        'instructionId': instructionId,
        'stationId': stationId,
      },
    );

    log(
      'getInstructionById response == '
          '${response.body} ---- ${response.statusCode}',
    );

    Map<String, dynamic> jsonBody = {};

    try {
      jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getInstructionById JSON parsing error: $e');

      throw OccToScException(
        'Invalid response from server. (${response.statusCode})',
      );
    }

    if (response.statusCode == 200) {
      final result = OccInstructionDetailResponse.fromJson(jsonBody);

      if (result.success) {
        return result;
      }

      throw OccToScException(
        result.message.isNotEmpty
            ? result.message
            : 'Unable to fetch instruction details.',
      );
    }

    final message = jsonBody['message']?.toString() ??
        jsonBody['detail']?.toString() ??
        'Unable to fetch instruction details. (${response.statusCode})';

    throw OccToScException(message);
  }

  // TODO: this endpoint path and payload shape are a best guess following
// the same convention as GetInstructionById / GetInstructionList —
// share the actual curl + response for AcknowledgeInstruction (like you
// did for GetInstructionById) and I'll line this up exactly.
  Future<OccInstructionAcknowledgeResponse> acknowledgeInstruction({
    required int userId,
    required String role,
    required int instructionId,
    required int stationId,
    required String remark,
  }) async {
    debugPrint(
      'acknowledgeInstruction '
          'userId=$userId role=$role instructionId=$instructionId '
          'stationId=$stationId remark=$remark',
    );

    final http.Response response = await _apiClient.post(
      AppUrls.acknowledgeSc, // TODO: add this constant / confirm path
      body: <String, dynamic>{
        'userId': userId,
        'role': role,
        'instructionId': instructionId,
        'stationId': stationId,
        'acknowledgementRemark': remark,
      },
    );

    log(
      'acknowledgeInstruction response == '
          '${response.body} ---- ${response.statusCode}',
    );

    Map<String, dynamic> jsonBody = {};

    try {
      jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('acknowledgeInstruction JSON parsing error: $e');

      throw OccToScException(
        'Invalid response from server. (${response.statusCode})',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final result = OccInstructionAcknowledgeResponse.fromJson(jsonBody);

      if (result.success) {
        return result;
      }

      throw OccToScException(
        result.message.isNotEmpty
            ? result.message
            : 'Unable to submit acknowledgement.',
      );
    }

    final message = jsonBody['message']?.toString() ??
        jsonBody['detail']?.toString() ??
        'Unable to submit acknowledgement. (${response.statusCode})';

    throw OccToScException(message);
  }
}

class OccToScException implements Exception {
  OccToScException(this.message);

  final String message;

  @override
  String toString() => 'OccToScException: $message';
}

