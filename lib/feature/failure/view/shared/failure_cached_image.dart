import 'dart:io';

import 'package:flutter/material.dart';
import 'package:om_mobile/feature/failure/service/failure_image_cache.dart';

/// A failure attachment thumbnail: a file on this device (failure not sent yet)
/// or a server address. A server picture is saved on the device the first time
/// it loads, so it shows again without internet.
class FailureCachedImage extends StatefulWidget {
  const FailureCachedImage(this.source, {super.key, this.size = 100});

  final String source;
  final double size;

  @override
  State<FailureCachedImage> createState() => _FailureCachedImageState();
}

class _FailureCachedImageState extends State<FailureCachedImage> {
  // Started once per address: a rebuild of the parent must not restart it
  // (that kept the loader on screen).
  Future<File?>? _file;

  bool get _isUrl => widget.source.startsWith('http');

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(FailureCachedImage old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source) _start();
  }

  // Only looks for a saved copy (never waits for a download): without one the
  // picture loads from the server as usual, and is saved in the background.
  void _start() {
    if (!_isUrl) {
      _file = null;
      return;
    }
    _file = FailureImageCache.cached(widget.source)
        .timeout(const Duration(seconds: 3), onTimeout: () => null);
    FailureImageCache.ensure(widget.source).catchError((Object _) => null);
  }

  Widget _broken() => Container(
        width: widget.size,
        height: widget.size,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );

  Widget _fromFile(File f) => Image.file(f,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _broken());

  /// The picture straight from the server when it could not be saved.
  Widget _fromNetwork() => Image.network(widget.source,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _broken());

  @override
  Widget build(BuildContext context) {
    final Widget child = !_isUrl
        ? _fromFile(File(widget.source))
        : FutureBuilder<File?>(
            future: _file,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: const Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                );
              }
              final file = snap.data;
              return file == null ? _fromNetwork() : _fromFile(file);
            },
          );
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: child);
  }
}
