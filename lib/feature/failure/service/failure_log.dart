import 'package:flutter/foundation.dart';

/// Debug-only log for the failure flows. Nothing is printed in a release
/// build (no data in the device log, no cost while the app runs), and tokens
/// or passwords that end up in a logged request are hidden.
void failureLog(Object? message, {int? wrapWidth}) {
  if (!kDebugMode) return;
  debugPrint(_redact('$message'), wrapWidth: wrapWidth);
}

final RegExp _bearer = RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false);
final RegExp _secretPair = RegExp(
    r'''(authorization|token|password|passwd|secret|cookie)(["']?\s*[:=]\s*["']?)[^,"'}\s]+''',
    caseSensitive: false);

String _redact(String text) => text
    .replaceAll(_bearer, 'Bearer ***')
    .replaceAllMapped(_secretPair, (m) => '${m[1]}${m[2]}***');
