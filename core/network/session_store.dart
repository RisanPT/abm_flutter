import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reliable session persistence backed by SharedPreferences.
///
/// The app previously used flutter_secure_storage 4.2.1, whose legacy Android
/// backend intermittently loses the token across app restarts — which logged
/// users out on resume. SharedPreferences persists reliably in app-private
/// storage. Every read/write is guarded so a storage hiccup never crashes or
/// wipes the session on its own.
class SessionStore {
  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> readToken() async {
    try {
      return (await _prefs).getString(_kToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      await (await _prefs).setString(_kToken, token);
    } catch (_) {}
  }

  Future<String?> readUser() async {
    try {
      return (await _prefs).getString(_kUser);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(String userJson) async {
    try {
      await (await _prefs).setString(_kUser, userJson);
    } catch (_) {}
  }

  /// Clear the whole session (used only on explicit logout or a confirmed 401).
  Future<void> clear() async {
    try {
      final p = await _prefs;
      await p.remove(_kToken);
      await p.remove(_kUser);
    } catch (_) {}
  }
}

final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());
