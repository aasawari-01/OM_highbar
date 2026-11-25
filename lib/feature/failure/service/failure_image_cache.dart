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

  static Future<Directory> _dir() async {
    final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'failure_images'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _safeName(String text) {
    final name = text.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return name.length > 150 ? name.substring(name.length - 150) : name;
  }

  /// One name for the same picture however its address was written: with a
  /// space or %20, with one or two slashes after the host, with spaces around.
  /// (The prefetch and the screens build the address in slightly different
  /// ways, which made a saved picture look missing.)
  static String _canonical(String url) {
    var u = url.trim();
    try {
      u = Uri.decodeFull(u);
    } catch (_) {}
    return u.replaceAll(RegExp(r'(?<!:)/{2,}'), '/');
  }

  static Future<File> _file(String url) async =>
      File(p.join((await _dir()).path, _safeName(_canonical(url))));

  /// The same picture as saved by the earlier version of the app (name made
  /// from the address exactly as written).
  static Future<File> _legacyFile(String url) async =>
      File(p.join((await _dir()).path, _safeName(url)));

  /// A real picture: starts with the signature of JPEG, PNG, GIF, BMP or WEBP.
  /// An error page or a half-written file is not.
  static Future<bool> _isImage(File f) async {
    RandomAccessFile? raf;
    try {
      raf = await f.open();
      final b = await raf.read(12);
      if (b.length < 4) return false;
      final jpeg = b[0] == 0xFF && b[1] == 0xD8;
      final png = b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;
      final gif = b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46;
      final bmp = b[0] == 0x42 && b[1] == 0x4D;
      final webp = b.length >= 12 &&
          b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
          b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50;
      return jpeg || png || gif || bmp || webp;
    } catch (_) {
      return false;
    } finally {
      await raf?.close();
    }
  }

  /// The saved picture, or null when it was never downloaded. A saved file
  /// that is not a picture (broken download) is removed, so it is downloaded
  /// again instead of showing a broken image.
  static Future<File?> cached(String url) async {
    try {
      for (final f in [await _file(url), await _legacyFile(url)]) {
        if (await f.exists() && await f.length() > 0) {
          if (await _isImage(f)) return f;
          try {
            await f.delete();
          } catch (_) {}
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// The saved picture; downloaded and saved first when it is not there yet.
  /// null when it cannot be had (offline and never saved).
  static Future<File?> ensure(String url) {
    final key = _canonical(url);
    return _running[key] ??= _download(url).whenComplete(() => _running.remove(key));
  }

  static Future<File?> _download(String url) async {
    final saved = await cached(url);
    if (saved != null) return saved;
    // A few tries: one slow or dropped request must not leave the picture
    // missing for the offline use.
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final res = await http.get(Uri.parse(url.trim())).timeout(const Duration(seconds: 30));
        if (res.statusCode == 404 || res.statusCode == 403) return null;
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          final f = await _file(url);
          // Written aside and renamed: a download that is cut half way never
          // leaves a broken picture under the real name.
          final tmp = File('${f.path}.part');
          await tmp.writeAsBytes(res.bodyBytes, flush: true);
          if (!await _isImage(tmp)) {
            try {
              await tmp.delete();
            } catch (_) {}
            return null;
          }
          await tmp.rename(f.path);
          return f;
        }
        failureLog('FailureImageCache: status ${res.statusCode}, try $attempt ($url)');
      } catch (e) {
        failureLog('FailureImageCache: not downloaded, try $attempt ($e)');
      }
      await Future.delayed(Duration(milliseconds: 500 * attempt));
    }
    return null;
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

  /// Saves the pictures in the background, four at a time (a failed one is
  /// skipped). Returns the addresses that could not be saved, so they can be
  /// tried again at the next sync.
  static Future<List<String>> prefetch(Iterable<String> urls) async {
    final list = urls.where((u) => u.trim().isNotEmpty).toSet().toList();
    final failed = <String>[];
    var next = 0;
    Future<void> worker() async {
      while (true) {
        final i = next++;
        if (i >= list.length) return;
        if (await ensure(list[i]) == null) failed.add(list[i]);
      }
    }

    await Future.wait(List.generate(4, (_) => worker()));
    return failed;
  }
}
