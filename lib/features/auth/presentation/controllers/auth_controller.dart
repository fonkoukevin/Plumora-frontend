import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/login_request.dart';
import '../../data/models/register_request.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_cache_invalidator.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession> {
  @override
  Future<AuthSession> build() {
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> login(LoginRequest request) async {
    invalidateUserScopedCaches(ref);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).login(request);
    });
    if (state.hasValue) {
      invalidateUserScopedCaches(ref);
    }
  }

  Future<void> register(RegisterRequest request) async {
    invalidateUserScopedCaches(ref);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).register(request);
    });
    if (state.hasValue) {
      invalidateUserScopedCaches(ref);
    }
  }

  Future<void> updateRoles(List<String> roleNames) async {
    final currentSession =
        state.valueOrNull ?? const AuthSession.unauthenticated();

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final roles = await ref
          .read(authRepositoryProvider)
          .updateRoles(roleNames);
      return currentSession.copyWith(roles: roles);
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await ref.read(authRepositoryProvider).logout();
    invalidateUserScopedCaches(ref);
    state = const AsyncData(AuthSession.unauthenticated());
  }
}
