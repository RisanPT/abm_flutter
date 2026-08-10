// This file is only ever compiled for Flutter web (via the conditional export
// in web_download.dart), so the web-only library lints are expected here.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a browser download of [bytes] as [filename] with the given MIME type.
void triggerBrowserDownload(List<int> bytes, String filename, String mimeType) {
  final blob = html.Blob(<Object>[Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
