import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../constants/app_constants.dart';
import 'api_logger.dart';
import 'app_urls.dart';

/// HTTP client wrapper that handles JSON, multipart requests and auth headers.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.baseUrl = AppUrls.baseUrl,
  }) : _client = httpClient ?? _sharedClient;

  /// One connection pool for the whole app (every `ApiClient()` reuses it).
  static final http.Client _sharedClient = http.Client();

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
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'accept': '*/*',
      if (headers != null) ...headers,
    };
    final encodedBody = body == null ? null : jsonEncode(body);
    ApiLogger.request('POST', uri, body: body);
    final watch = Stopwatch()..start();
    try {
      final response = await _client
          .post(uri, headers: mergedHeaders, body: encodedBody)
          .timeout(AppConstants.apiTimeout);
      ApiLogger.response(
          'POST', uri, response.statusCode, response.body, watch.elapsed);
      return response;
    } catch (e) {
      ApiLogger.failure('POST', uri, e, watch.elapsed);
      rethrow;
    }
  }

  /// Sends a JSON GET request.
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
    ApiLogger.request('GET', uri);
    final watch = Stopwatch()..start();
    try {
      final response = await _client
          .get(uri, headers: mergedHeaders)
          .timeout(AppConstants.apiTimeout);
      ApiLogger.response(
          'GET', uri, response.statusCode, response.body, watch.elapsed);
      return response;
    } catch (e) {
      ApiLogger.failure('GET', uri, e, watch.elapsed);
      rethrow;
    }
  }

  /// Sends a multipart POST request (for file uploads and form fields).
  Future<http.Response> postMultipart(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final uri = _buildUri(endpoint);
    final request = http.MultipartRequest('POST', uri);
    request.headers['accept'] = 'application/json';
    if (headers != null) request.headers.addAll(headers);
    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);
    ApiLogger.request('MULTIPART', uri,
        body: fields,
        note: 'files: ${files?.map((f) => '${f.field}(${f.length} B)').join(', ') ?? 'none'}');
    final watch = Stopwatch()..start();
    try {
      final streamedResponse =
          await request.send().timeout(AppConstants.apiMultipartTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      ApiLogger.response(
          'MULTIPART', uri, response.statusCode, response.body, watch.elapsed);
      return response;
    } catch (e) {
      ApiLogger.failure('MULTIPART', uri, e, watch.elapsed);
      rethrow;
    }
  }
}
