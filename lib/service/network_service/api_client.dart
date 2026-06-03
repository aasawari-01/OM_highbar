import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_urls.dart';

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

  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    print("endpoint==${_buildUri(endpoint)} body==$body");
    final uri = _buildUri(endpoint);
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'accept': '*/*',
      if (headers != null) ...headers,
    };
    print("endpoint==${_buildUri(endpoint)} body==$body");
    final encodedBody = body == null ? null : jsonEncode(body);

    final response = await _client
        .post(uri, headers: mergedHeaders, body: encodedBody)
        .timeout(const Duration(seconds: 30));
    print("response status===${response.statusCode}");
    print("response body===${response.body}");
    return response;
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'accept': '*/*',
      if (headers != null) ...headers,
    };
    print("endpoint==$uri");
    final response = await _client
        .get(uri, headers: mergedHeaders)
        .timeout(const Duration(seconds: 30));
    print("response status===${response.statusCode}");
    print("response body===${response.body}");
    return response;
  }

  Future<http.Response> postMultipart(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final uri = _buildUri(endpoint);
    final request = http.MultipartRequest('POST', uri);
    
    if (headers != null) request.headers.addAll(headers);
    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);

    final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);
    print("response status===${response.statusCode}");
    print("response body===${response.body}");
    return response;
  }
}

