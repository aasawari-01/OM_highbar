import '../../../service/network_service/app_urls.dart';

/// An already-uploaded checklist attachment, read from the API's loose JSON.
class ChecklistAttachment {
  final Map raw; // original API map, kept so it can be sent back unchanged
  final String name;
  final String url;

  const ChecklistAttachment(
      {required this.raw, required this.name, required this.url});

  factory ChecklistAttachment.fromJson(Map json) {
    final name = (json['originalFileName'] ??
            json['OriginalFileName'] ??
            json['fileName'] ??
            'Attachment')
        .toString();
    final path = (json['filePath'] ?? json['FilePath'] ?? '').toString();
    final url = path.isEmpty
        ? ''
        : path.startsWith('http')
            ? path
            : '${AppUrls.imageUrl}${path.replaceFirst(RegExp(r'^/'), '')}';
    return ChecklistAttachment(raw: json, name: name, url: url);
  }

  bool get isImage =>
      RegExp(r'\.(png|jpe?g)$', caseSensitive: false).hasMatch(name);

  bool get canPreview => isImage && url.isNotEmpty;
}
