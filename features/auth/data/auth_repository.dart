import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:dio/dio.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(dio, storage);
}

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<UserModel> login(
    String username,
    String password, {
    required String selectedRole,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      final String token = response.data['token'];
      final userData = response.data['user'];

      await _storage.write(key: 'auth_token', value: token);

      final user = UserModel.fromJson(userData);
      if (user.role != selectedRole) {
        throw Exception(
          'This account is ${user.role.label}. Please select the correct role.',
        );
      }
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid username or password');
      }
      throw Exception(e.response?.data['message'] ?? 'Failed to login');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Clear local session even if the backend request fails.
    } finally {
      await _storage.delete(key: 'auth_token');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return null;

    try {
      // The backend needs a route to get current user info OR we decode token
      // For now, let's assume /auth/me exists as per common patterns
      final response = await _dio.get('/auth/me'); 
      return UserModel.fromJson(response.data);
    } catch (_) {
      await logout();
      return null;
    }
  }
}
