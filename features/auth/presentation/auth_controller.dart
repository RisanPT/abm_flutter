import 'package:abm_madrasa/features/auth/data/auth_repository.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<UserModel?> build() async {
    return ref.watch(authRepositoryProvider).getCurrentUser();
  }

  Future<bool> login(
    String username,
    String password,
  ) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(
            username,
            password,
          ),
    );
    state = result;
    if (!result.hasError) {
      ref.invalidate(permissionControllerProvider);
      try {
        await ref.read(permissionControllerProvider.notifier).refresh();
      } catch (_) {}
    }
    return !result.hasError;
  }

  /// Passwordless parent sign-in with the mobile number only.
  Future<bool> parentLogin(String phone) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).parentPhoneLogin(phone),
    );
    state = result;
    if (!result.hasError) {
      ref.invalidate(permissionControllerProvider);
      try {
        await ref.read(permissionControllerProvider.notifier).refresh();
      } catch (_) {}
    }
    return !result.hasError;
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    // Guard so a failed logout never leaves the UI stuck in loading — the user
    // is always returned to the signed-out state.
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // best-effort: even if the server call fails, clear local session below.
    }
    ref.invalidate(permissionControllerProvider);
    state = const AsyncValue.data(null);
  }
}
