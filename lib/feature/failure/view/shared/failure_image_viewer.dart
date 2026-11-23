import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:om_mobile/feature/failure/service/failure_image_cache.dart';

/// Full-screen view of a failure picture: pinch to zoom, drag to move, close
/// button at the top. [source] is a server address (http...) or a file on this
/// device.
class FailureImageViewer {
  FailureImageViewer._();

  static void show(String source) {
    if (source.trim().isEmpty) return;
    Get.dialog(
      _ViewerPage(source: source),
      barrierColor: Colors.black,
      useSafeArea: false,
    );
  }
}

class _ViewerPage extends StatelessWidget {
  const _ViewerPage({required this.source});

  final String source;

  Widget _broken() => const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
      );

  Widget _image() {
    if (!source.startsWith('http')) {
      return Image.file(File(source),
          fit: BoxFit.contain, errorBuilder: (_, __, ___) => _broken());
    }
    // The copy kept on the device first (works offline), else the server.
    return FutureBuilder<File?>(
      future: FailureImageCache.cached(source),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final file = snap.data;
        if (file != null) {
          return Image.file(file,
              fit: BoxFit.contain, errorBuilder: (_, __, ___) => _broken());
        }
        return Image.network(
          source,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator(color: Colors.white)),
          errorBuilder: (_, __, ___) => _broken(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(child: _image()),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Get.back(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
