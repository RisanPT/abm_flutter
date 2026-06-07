import 'package:abm_madrasa/features/auth/data/auth_repository.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
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
    return !result.hasError;
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}
