import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Login-access status for one student (managed by Head Master / IT Admin).
class StudentLoginStatus {
  const StudentLoginStatus({
    required this.hasLogin,
    required this.loginEnabled,
    required this.suggestedUsername,
    this.username,
  });

  final bool hasLogin;
  final bool loginEnabled;
  final String suggestedUsername;
  final String? username;

  factory StudentLoginStatus.fromJson(Map<String, dynamic> j) => StudentLoginStatus(
        hasLogin: j['hasLogin'] == true,
        loginEnabled: j['loginEnabled'] == true,
        suggestedUsername: (j['suggestedUsername'] ?? '').toString(),
        username: j['username'] as String?,
      );
}

final studentLoginRepositoryProvider =
    Provider<StudentLoginRepository>((ref) => StudentLoginRepository(ref.watch(dioProvider)));

class StudentLoginRepository {
  StudentLoginRepository(this._dio);
  final Dio _dio;

  Future<StudentLoginStatus> getStatus(String studentId) async {
    final r = await _dio.get('/students/$studentId/login');
    return StudentLoginStatus.fromJson(Map<String, dynamic>.from(r.data));
  }

  /// Create the login (needs a password), update the username, or reset the
  /// password. Pass enabled:false to block login without deleting the account.
  Future<StudentLoginStatus> setLogin(
    String studentId, {
    String? username,
    String? password,
    bool enabled = true,
  }) async {
    try {
      final r = await _dio.post('/students/$studentId/login', data: {
        if (username != null && username.isNotEmpty) 'username': username,
        if (password != null && password.isNotEmpty) 'password': password,
        'enabled': enabled,
      });
      return StudentLoginStatus.fromJson(Map<String, dynamic>.from(r.data));
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map ? (e.response?.data['message'] ?? 'Failed to save login') : 'Failed to save login');
    }
  }

  Future<void> removeLogin(String studentId) async {
    await _dio.delete('/students/$studentId/login');
  }
}
