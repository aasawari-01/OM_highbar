import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../service/auth_manager.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../model/je_inspection_item.dart';

class InspectionService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthManager().getToken();
    return {
      'accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<int> _userId() async =>
      int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;

  Future<List<JEInspectionItem>> getJEInspectionList({
    String source = 'JEInspectionList',
  }) async {
    try {
      final userId = await _userId();
      final response = await _apiClient.post(
        '${AppUrls.getJEInspectionList}?UserId=$userId&source=$source',
        headers: await _authHeaders(),
      );
      if (response.statusCode != 200) return [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final output = body['responseOutput'];
      final rows = output is Map
          ? output.values.toList()
          : (output is List ? output : const []);
      return rows
          .whereType<Map>()
          .map((e) => JEInspectionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error loading JE inspection list: $e');
      return [];
    }
  }

  Future<bool> skipInspection({required int id, required String remark}) async {
    try {
      final response = await _apiClient.post(
        AppUrls.skipInspectionById,
        headers: await _authHeaders(),
        body: {'Id': id, 'Remark': remark, 'CreatedBy': await _userId()},
      );
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['responseMessage'] == 'Success';
    } catch (e) {
      debugPrint('Error skipping inspection: $e');
      return false;
    }
  }
}
