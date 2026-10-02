import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/settings/domain/permission_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';

part 'permission_controller.g.dart';

class PermissionRepository {
  final Dio _dio;
  PermissionRepository(this._dio);

  Future<List<PermissionModel>> getPermissions() async {
    final response = await _dio.get('/permissions');
    final List<dynamic> data = response.data;
    return data.map((json) => PermissionModel.fromJson(json)).toList();
  }

  Future<PermissionModel> updatePermissions(String role, List<String> permissions) async {
    final response = await _dio.put('/permissions/$role', data: {
      'permissions': permissions,
    });
    return PermissionModel.fromJson(response.data);
  }
}

@riverpod
PermissionRepository permissionRepository(Ref ref) {
  return PermissionRepository(ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
class PermissionController extends _$PermissionController {
  @override
  FutureOr<List<PermissionModel>> build() async {
    return _fetchPermissions();
  }

  Future<List<PermissionModel>> _fetchPermissions() async {
    try {
      return await ref.read(permissionRepositoryProvider).getPermissions();
    } catch (_) {
      return [];
    }
  }

  /// Re-fetches permissions from the server with the active bearer token.
  Future<List<PermissionModel>> refresh() async {
    state = const AsyncValue.loading();
    try {
      final list = await ref.read(permissionRepositoryProvider).getPermissions();
      state = AsyncValue.data(list);
      return list;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  Future<void> updatePermissions(String role, List<String> permissions) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await ref.read(permissionRepositoryProvider).updatePermissions(role, permissions);
      // Refresh list
      state = AsyncValue.data(await _fetchPermissions());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // Revert on error
      if (previousState.hasValue) {
        state = previousState;
      }
      rethrow;
    }
  }

  /// Helper to get permissions as a set of strings for a specific role.
  /// Falls back to [kDefaultRolePermissions] if the server has not yet returned
  /// or if the role has not been customized.
  Set<String> getPermissionsForRole(String role) {
    final defaults = kDefaultRolePermissions[role] ?? {};
    if (!state.hasValue) return defaults;
    final permissions = state.value!;
    try {
      final model = permissions.firstWhere((p) => p.role == role);
      final set = model.permissions.toSet();
      return set.isNotEmpty ? set : defaults;
    } catch (e) {
      return defaults;
    }
  }
}
