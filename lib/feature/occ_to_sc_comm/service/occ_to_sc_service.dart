import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';

import '../model/occ_to_sc_model.dart';

class OccToScService {
  OccToScService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<OccToScMasterDataResponse> getOccToScMasterData({
    required int userId,
  }) async {
    debugPrint("getOccToScMasterData");

    final http.Response response = await _apiClient.post(
      AppUrls.occTOscMasterData,
      body: <String, dynamic>{
        'userId': userId,
      },
    );

    debugPrint(
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
}

class OccToScException implements Exception {
  OccToScException(this.message);

  final String message;

  @override
  String toString() => 'OccToScException: $message';
}