import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/login_request.dart';
import '../../data/models/register_request.dart';
import '../../data/models/update_profile_request.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_cache_invalidator.dart';
// Conditional compilation, not just a runtime kIsWeb check: the real
// implementation uses dart:js_interop's @JS(), which doesn't exist on the
// VM backend at all (unlike dart:js_interop itself, which is importable
// everywhere but has a reduced API there) — every test target compiles
// through this file (it's imported almost everywhere), so a plain
// unconditional import broke test compilation project-wide.
import 'hard_navigate_stub.dart'
    if (dart.library.html) 'hard_navigate_web.dart';

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

  Future<void> loginWithGoogle() async {
    invalidateUserScopedCaches(ref);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).loginWithGoogle();
    });
    if (state.hasValue) {
      invalidateUserScopedCaches(ref);
    }
  }

  /// Web counterpart of [loginWithGoogle] — see
  /// `AuthRepository.loginWithGoogleIdToken`.
  Future<void> loginWithGoogleIdToken(String idToken) async {
    invalidateUserScopedCaches(ref);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).loginWithGoogleIdToken(idToken);
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

  Future<void> updateProfile(UpdateProfileRequest request) async {
    final currentSession =
        state.valueOrNull ?? const AuthSession.unauthenticated();

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .updateProfile(request);
      return currentSession.copyWith(user: user);
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await ref.read(authRepositoryProvider).logout();
    invalidateUserScopedCaches(ref);
    state = const AsyncData(AuthSession.unauthenticated());

    // No-op on non-web platforms (see hard_navigate_stub.dart). On web, a
    // full reload here is required — see hard_navigate_web.dart — so every
    // logout entry point (profile, main nav, admin) gets a guaranteed-clean
    // slate instead of requiring the user to notice and refresh manually.
    // All four call sites navigate to the same AppRoutes.landing ('/')
    // afterward anyway, so this subsumes their own context.go on web
    // without changing behavior elsewhere.
    hardNavigateTo('/');
  }
}
