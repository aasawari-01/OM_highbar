import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../constants/app_constants.dart';
import 'app_urls.dart';

/// HTTP client wrapper that handles JSON, multipart requests and auth headers.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.baseUrl = AppUrls.baseUrl,
  }) : _client = httpClient ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _buildUri(String endpoint) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse('$normalizedBase$endpoint');
  }

  /// Sends a JSON POST request.
  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(endpoint);
    debugPrint('[POST] $uri');
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'accept': '*/*',
      if (headers != null) ...headers,
    };
    final encodedBody = body == null ? null : jsonEncode(body);
    final response = await _client
        .post(uri, headers: mergedHeaders, body: encodedBody)
        .timeout(AppConstants.apiTimeout);
    debugPrint('[POST] ${response.statusCode} — $uri');
    return response;
  }

  /// Sends a JSON GET request.
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    debugPrint('[GET] $uri');
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'accept': '*/*',
      if (headers != null) ...headers,
    };
    final response = await _client
        .get(uri, headers: mergedHeaders)
        .timeout(AppConstants.apiTimeout);
    debugPrint('[GET] ${response.statusCode} — $uri');
    return response;
  }

  /// Sends a multipart POST request (for file uploads and form fields).
  Future<http.Response> postMultipart(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final uri = _buildUri(endpoint);
    debugPrint('[MULTIPART POST] $uri  fields=${fields?.keys.toList()}');
    final request = http.MultipartRequest('POST', uri);
    request.headers['accept'] = 'application/json';
    if (headers != null) request.headers.addAll(headers);
    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);
    final streamedResponse =
        await request.send().timeout(AppConstants.apiMultipartTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    debugPrint('[MULTIPART POST] ${response.statusCode} — $uri');
    return response;
  }
}
