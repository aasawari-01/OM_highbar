import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'failure_log.dart';

/// Failure attachments kept on the device, so a failure's pictures can be seen
/// without internet. A picture is saved the first time it is downloaded (when
/// the failure is opened, or in the background after a list sync).
class FailureImageCache {
  FailureImageCache._();

  static final Map<String, Future<File?>> _running = {};

  static Future<File> _file(String url) async {
    final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'failure_images'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final name = url.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return File(p.join(dir.path, name.length > 150 ? name.substring(name.length - 150) : name));
  }

  /// The saved picture, or null when it was never downloaded.
  static Future<File?> cached(String url) async {
    try {
      final f = await _file(url);
      return await f.exists() && await f.length() > 0 ? f : null;
    } catch (_) {
      return null;
    }
  }

  /// The saved picture; downloaded and saved first when it is not there yet.
  /// null when it cannot be had (offline and never saved).
  static Future<File?> ensure(String url) {
    return _running[url] ??= _download(url).whenComplete(() => _running.remove(url));
  }

  static Future<File?> _download(String url) async {
    final saved = await cached(url);
    if (saved != null) return saved;
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
      final f = await _file(url);
      await f.writeAsBytes(res.bodyBytes, flush: true);
      return f;
    } catch (e) {
      failureLog('FailureImageCache: not downloaded ($e)');
      return null;
    }
  }

  /// Removes every saved picture (the failures belong to the user who logs out).
  static Future<void> clear() async {
    try {
      final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'failure_images'));
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      failureLog('FailureImageCache: clear failed ($e)');
    }
  }

  /// Saves the pictures one by one in the background (a failed one is skipped).
  static Future<void> prefetch(Iterable<String> urls) async {
    for (final u in urls.toSet()) {
      if (u.isEmpty) continue;
      await ensure(u);
    }
  }
}
