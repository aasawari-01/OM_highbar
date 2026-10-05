import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Development-only API logging. Every method is a no-op outside debug mode,
/// so nothing is built, decoded or printed in a release APK.
class ApiLogger {
  ApiLogger._();

  static const int _maxBody = 3000;
  static const int _maxString = 160;
  static const _secretKeys = {
    'password',
    'token',
    'authorization',
    'accesstoken',
    'refreshtoken',
  };

  static void request(String method, Uri uri, {Object? body, String? note}) {
    if (!kDebugMode) return;
    final buf = StringBuffer('┌─ ➜ $method $uri');
    if (note != null) buf.write('\n│ $note');
    if (body != null) buf.write('\n│ body: ${_compact(body)}');
    _print(buf.toString());
  }

  static void response(
      String method, Uri uri, int status, String body, Duration took) {
    if (!kDebugMode) return;
    final ok = status >= 200 && status < 300;
    final buf = StringBuffer(
        '${ok ? '└─ ✔' : '└─ ✘'} $status $method $uri  (${took.inMilliseconds} ms)');
    buf.write('\n   ${_compactBody(body)}');
    _print(buf.toString());
  }

  static void failure(String method, Uri uri, Object error, Duration took) {
    if (!kDebugMode) return;
    _print('└─ ✘ ERROR $method $uri  (${took.inMilliseconds} ms)\n   $error');
  }

  static String _compactBody(String body) {
    if (body.isEmpty) return '<empty body>';
    try {
      return _compact(jsonDecode(body));
    } catch (_) {
      return _truncate(body);
    }
  }

  static String _compact(Object value) {
    try {
      return _truncate(jsonEncode(_scrub(value)));
    } catch (_) {
      return _truncate(value.toString());
    }
  }

  /// Hides secrets and collapses very long strings (images, base64 blobs).
  static Object? _scrub(Object? v, [String key = '']) {
    if (v is Map) {
      return v.map((k, val) => MapEntry(k, _scrub(val, k.toString())));
    }
    if (v is List) return v.map((e) => _scrub(e, key)).toList();
    if (v is String) {
      if (_secretKeys.contains(key.toLowerCase())) return '***';
      if (v.length > _maxString) return '<${v.length} chars>';
    }
    return v;
  }

  static String _truncate(String s) =>
      s.length <= _maxBody ? s : '${s.substring(0, _maxBody)}… (+${s.length - _maxBody} chars)';

  static void _print(String text) => debugPrint(text, wrapWidth: 1024);
}
