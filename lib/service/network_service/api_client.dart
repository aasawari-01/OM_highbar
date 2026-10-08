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
    // Log the raw body: decoding it here threw on an empty / non-JSON reply
    // (FormatException: Unexpected end of input) before the response was returned.
    debugPrint('[POST] ${response.statusCode} — $uri $encodedBody ${_logBody(response.body)}');
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

  /// Sends a GET request that carries a JSON body (some endpoints, e.g.
  /// GetAllFailuresTransactionData, are GET with {userId, syncType, ...}).
  Future<http.Response> getWithBody(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(endpoint);
    debugPrint('[GET+BODY] $uri');
    final request = http.Request('GET', uri);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'accept': '*/*',
      if (headers != null) ...headers,
    });
    final encodedBody = body == null ? null : jsonEncode(body);
    if (encodedBody != null) request.body = encodedBody;
    final streamed = await _client.send(request).timeout(AppConstants.apiTimeout);
    final response = await http.Response.fromStream(streamed);
    debugPrint('[GET+BODY] ${response.statusCode} — $uri $encodedBody ${_logBody(response.body)}');
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
    debugPrint('[MULTIPART POST] ${response.statusCode} — $uri -$fields  ${_logBody(response.body)}');
    return response;
  }

  /// Response body for the log: never throws, empty replies are shown as such,
  /// and very large bodies are cut.
  String _logBody(String body) {
    if (body.isEmpty) return '<empty body>';
    return body.length > 1500 ? '${body.substring(0, 1500)}…(${body.length} chars)' : body;
  }
}
