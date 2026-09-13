import 'dart:convert';

import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/network/session_store.dart';
import 'package:dio/dio.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  final store = ref.watch(sessionStoreProvider);
  return AuthRepository(dio, store);
}

class AuthRepository {
  final Dio _dio;
  final SessionStore _store;

  AuthRepository(this._dio, this._store);

  Future<UserModel> login(
    String username,
    String password,
  ) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      final String token = response.data['token'];
      final userData = Map<String, dynamic>.from(response.data['user'] as Map);

      // Persist BOTH the token and the user so the session survives restarts
      // even with no network on the next launch.
      await _store.saveToken(token);
      await _store.saveUser(jsonEncode(userData));

      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid username or password');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Network connection error. Please check your internet connection.');
      }
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to login');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Clear local session even if the backend request fails.
    } finally {
      await _store.clear();
    }
  }

  /// Restore the session on app start / resume.
  ///
  /// Critically, this NEVER clears the token on a transient failure. It only
  /// signs the user out on a confirmed 401 (token invalid/expired). On any
  /// other error (no network, timeout, 5xx) it falls back to the cached user so
  /// the app stays logged in — the previous version wiped the token on ANY
  /// error, which caused the auto-logout on resume.
  Future<UserModel?> getCurrentUser() async {
    final token = await _store.readToken();
    if (token == null || token.isEmpty) return null;

    // Optimistic session from the cached user (works offline).
    UserModel? cached;
    final cachedJson = await _store.readUser();
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        cached = UserModel.fromJson(Map<String, dynamic>.from(jsonDecode(cachedJson) as Map));
      } catch (_) {
        cached = null;
      }
    }

    try {
      final response = await _dio.get('/auth/me');
      final data = Map<String, dynamic>.from(response.data as Map);
      await _store.saveUser(jsonEncode(data));
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      // Only a real 401 means the token is no longer valid → sign out.
      if (e.response?.statusCode == 401) {
        await _store.clear();
        return null;
      }
      // Network / server error → keep the session, use the cached user.
      return cached;
    } catch (_) {
      return cached;
    }
  }
}
