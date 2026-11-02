import 'package:url_launcher/url_launcher.dart';

/// Opens WhatsApp (app or web) to a number with a prefilled message, via wa.me
/// click-to-chat. No API/cost — the staff member taps Send.
class WhatsAppService {
  /// Normalize a phone to wa.me format: digits only, with country code, no '+'.
  /// Saudi default: a bare 9-digit mobile (5XXXXXXXX) becomes 9665XXXXXXXX.
  static String? normalize(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return null;
    if (d.startsWith('00')) d = d.substring(2);
    if (d.startsWith('966')) return d; // already has Saudi country code
    if (d.startsWith('0')) d = d.replaceFirst(RegExp(r'^0+'), '');
    if (d.length == 9 && d.startsWith('5')) return '966$d'; // Saudi mobile
    return d; // best effort (already international, or another country)
  }

  /// Returns false if the number is unusable or WhatsApp couldn't be opened.
  static Future<bool> send(String phone, String message) async {
    final n = normalize(phone);
    if (n == null || n.length < 8) return false;
    final uri = Uri.parse('https://wa.me/$n?text=${Uri.encodeComponent(message)}');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
