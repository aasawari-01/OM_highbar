import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../model/login_response.dart';

class AuthService {
  AuthService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    debugPrint("login");
    final http.Response response = await _apiClient.post(
      AppUrls.login,
      body: <String, dynamic>{
        'userName': email,
        'password': password,
      },
    );
    Map<String, dynamic> jsonBody = {};
    debugPrint("response==${jsonDecode(response.body)}");
    try {
      jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw AuthException('Invalid response from server. (${response.statusCode})');
    }

    if (response.statusCode == 200) {
      debugPrint("login response===${jsonBody}");
      return LoginResponse.fromJson(jsonBody);
    }
     debugPrint("error==${response.statusCode}");
    // 422 and other errors – server returns a standard error shape.
    final message = jsonBody['message']?.toString() ??
        jsonBody['detail']?.toString() ??
        'Unable to login. (${response.statusCode})';
    throw AuthException(message);
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

