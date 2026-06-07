import 'package:abm_madrasa/features/user_admin/data/admin_service.dart';
import 'package:abm_madrasa/features/user_admin/domain/admin_user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminControllerProvider = AsyncNotifierProvider<AdminController, List<AdminUser>>(
  AdminController.new,
);

final rolesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return service.getRoles();
});

class AdminController extends AsyncNotifier<List<AdminUser>> {
  late AdminService _adminService;

  @override
  Future<List<AdminUser>> build() async {
    _adminService = ref.watch(adminServiceProvider);
    return _fetchUsers();
  }

  Future<List<AdminUser>> _fetchUsers() async {
    return await _adminService.getUsers();
  }

  Future<void> createUser({
    required String username,
    required String password,
    required String role,
    String? instituteId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _adminService.createUser(
        username: username,
        password: password,
        role: role,
        instituteId: instituteId,
      );
      final users = await _fetchUsers();
      state = AsyncValue.data(users);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateUser({
    required String id,
    String? username,
    String? password,
    String? role,
    String? instituteId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _adminService.updateUser(
        id: id,
        username: username,
        password: password,
        role: role,
        instituteId: instituteId,
      );
      final users = await _fetchUsers();
      state = AsyncValue.data(users);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    state = const AsyncValue.loading();
    try {
      await _adminService.deleteUser(id);
      final users = await _fetchUsers();
      state = AsyncValue.data(users);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final users = await _fetchUsers();
      state = AsyncValue.data(users);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
