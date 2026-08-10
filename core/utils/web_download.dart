// Cross-platform file "download". On web this triggers a browser download;
// on other platforms it's a no-op (callers use a native save dialog instead).
// The conditional export keeps `dart:html` out of mobile/desktop builds.
export 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart';
