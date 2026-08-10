/// Non-web fallback: no browser to download into. Callers branch on `kIsWeb`
/// and use a native save path (e.g. FilePicker.saveFile) on these platforms.
void triggerBrowserDownload(List<int> bytes, String filename, String mimeType) {
  // Intentionally empty — see web_download_web.dart for the real implementation.
}
