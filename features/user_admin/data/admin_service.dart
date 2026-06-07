import 'package:abm_madrasa/features/user_admin/domain/admin_user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abm_madrasa/core/network/dio_client.dart';

final adminServiceProvider = Provider((ref) {
  return AdminService(ref.watch(dioProvider));
});

class AdminService {
  final Dio _dio;

  AdminService(this._dio);

  Future<List<AdminUser>> getUsers() async {
    try {
      final response = await _dio.get('/admin/users');
      return (response.data as List)
          .map((user) => AdminUser.fromJson(user))
          .toList();
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  Future<List<String>> getRoles() async {
    try {
      final response = await _dio.get('/roles');
      return (response.data as List)
          .map((role) => role['name'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to load roles: $e');
    }
  }

  Future<String> createRole(String name) async {
    try {
      final response = await _dio.post('/roles', data: {'name': name});
      return response.data['name'];
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to create role');
      }
      throw Exception('Failed to create role: $e');
    }
  }

  Future<AdminUser> createUser({
    required String username,
    required String password,
    required String role,
    String? instituteId,
  }) async {
    try {
      final response = await _dio.post('/admin/users', data: {
        'username': username,
        'password': password,
        'role': role,
        if (instituteId != null) 'instituteId': instituteId,
      });
      return AdminUser.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to create user');
      }
      throw Exception('Failed to create user: $e');
    }
  }

  Future<AdminUser> updateUser({
    required String id,
    String? username,
    String? password,
    String? role,
    String? instituteId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (password != null && password.isNotEmpty) data['password'] = password;
      if (role != null) data['role'] = role;
      if (instituteId != null) data['instituteId'] = instituteId;

      final response = await _dio.put('/admin/users/$id', data: data);
      return AdminUser.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update user');
      }
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete('/admin/users/$id');
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete user');
      }
      throw Exception('Failed to delete user: $e');
    }
  }
}
