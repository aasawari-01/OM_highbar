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




  Future<void> forgotPassword({
    required String email,
  }) async {
    debugPrint("forgotPassword");
    final http.Response response = await _apiClient.get(
      AppUrls.forgotPassword,
      queryParams: <String, dynamic>{
        'emailId': email,
      },
    );

    debugPrint("forgotPassword response==${response.body}----${response.statusCode}");

    if (response.statusCode == 200&&response.body=="Found") {
      // Body is a plain string like "Found", not JSON — nothing to parse.
      return;
    }

    // Only try to parse JSON for error responses.
    String message = 'Unable to send reset code. (${response.statusCode})';
    try {
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      message = jsonBody['message']?.toString() ??
          jsonBody['detail']?.toString() ??
          message;
    } catch (_) {
      // Error body wasn't JSON either — fall back to response.body if it's non-empty.
      if (response.body.trim().isNotEmpty) {
        message = response.body.trim();
      }
    }
    throw AuthException(message);
  }

  // Future<void> forgotPassword({
  //   required String email,
  // }) async {
  //   debugPrint("forgotPassword");
  //   final http.Response response = await _apiClient.get(
  //     AppUrls.forgotPassword,
  //     queryParams: <String, dynamic>{
  //       'emailId': email,
  //     },
  //   );
  //
  //   Map<String, dynamic> jsonBody = {};
  //   debugPrint("forgotPassword response==${response.body}----${response.statusCode}");
  //   try {
  //     jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
  //   } catch (e) {
  //     throw AuthException('Invalid response from server. (${response.statusCode})');
  //   }
  //
  //   if (response.statusCode == 200) {
  //     debugPrint("forgotPassword response===${jsonBody}");
  //     return;
  //   }
  //   debugPrint("error==${response.statusCode}");
  //   final message = jsonBody['message']?.toString() ??
  //       jsonBody['detail']?.toString() ??
  //       'Unable to send reset code. (${response.statusCode})';
  //   throw AuthException(message);
  // }

  Future<void> updatePassword({
    required String email,
    required String userCode,
    required String newPassword,
  }) async {
    debugPrint("updatePassword");
    final http.Response response = await _apiClient.get(
      AppUrls.updatePassword,
      queryParams: <String, dynamic>{
        'emailId': email,
        'UserCode': userCode,
        'NewPassword': newPassword,
      },
    );

    Map<String, dynamic> jsonBody = {};
    debugPrint("updatePassword response==${response.body}");
    try {
      jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw AuthException('Invalid response from server. (${response.statusCode})');
    }

    if (response.statusCode == 200) {
      debugPrint("updatePassword response===${jsonBody}");
      return;
    }
    debugPrint("error==${response.statusCode}");
    final message = jsonBody['message']?.toString() ??
        jsonBody['detail']?.toString() ??
        'Unable to update password. (${response.statusCode})';
    throw AuthException(message);
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

