import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/role_model.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiService: ref.watch(authApiServiceProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
  );
});

class AuthRepository {
  const AuthRepository({
    required AuthApiService apiService,
    required SecureTokenStorage tokenStorage,
  }) : this._(apiService, tokenStorage);

  const AuthRepository._(this._apiService, this._tokenStorage);

  final AuthApiService _apiService;
  final SecureTokenStorage _tokenStorage;

  Future<AuthSession> restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      return const AuthSession.unauthenticated();
    }

    try {
      final user = await _loadCurrentUser();
      final roles = await _loadRolesSafely();
      return AuthSession(user: user, roles: roles);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await _tokenStorage.clearAccessToken();
        return const AuthSession.unauthenticated();
      }

      rethrow;
    }
  }

  Future<AuthSession> register(RegisterRequest request) async {
    await _tokenStorage.clearAccessToken();
    final response = await _apiService.register(request);
    await _tokenStorage.saveAccessToken(response.accessToken);

    final user = await _loadCurrentUser(response.user);
    final roles = await _loadRolesSafely();
    return AuthSession(user: user, roles: roles);
  }

  Future<AuthSession> login(LoginRequest request) async {
    await _tokenStorage.clearAccessToken();
    final response = await _apiService.login(request);
    await _tokenStorage.saveAccessToken(response.accessToken);

    final user = await _loadCurrentUser(response.user);
    final roles = await _loadRolesSafely();
    return AuthSession(user: user, roles: roles);
  }

  Future<List<RoleModel>> updateRoles(List<String> roleNames) async {
    if (roleNames.isEmpty) {
      throw const AppException('Sélectionne au moins un rôle.');
    }

    return _apiService.updateMyRoles(roleNames);
  }

  Future<void> logout() {
    return _tokenStorage.clearAccessToken();
  }

  Future<UserModel> _loadCurrentUser([UserModel? fallback]) async {
    try {
      final user = await _apiService.authMe();
      _assertSameLoginUser(user, fallback);
      return user;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        final user = await _apiService.userMe();
        _assertSameLoginUser(user, fallback);
        return user;
      }

      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await _tokenStorage.clearAccessToken();
      }

      if (fallback != null && error.response == null) {
        return fallback;
      }

      rethrow;
    }
  }

  void _assertSameLoginUser(UserModel currentUser, UserModel? loginUser) {
    if (loginUser == null || loginUser.id.isEmpty || currentUser.id.isEmpty) {
      return;
    }

    if (loginUser.id != currentUser.id) {
      throw const AppException(
        'Session utilisateur incohérente. Reconnecte-toi.',
      );
    }
  }

  Future<List<RoleModel>> _loadRolesSafely() async {
    try {
      return await _apiService.myRoles();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const [];
      }

      rethrow;
    }
  }
}

class AuthSession {
  const AuthSession({this.user, this.roles = const []});

  const AuthSession.unauthenticated() : user = null, roles = const [];

  final UserModel? user;
  final List<RoleModel> roles;

  bool get isAuthenticated => user != null;

  AuthSession copyWith({UserModel? user, List<RoleModel>? roles}) {
    return AuthSession(user: user ?? this.user, roles: roles ?? this.roles);
  }
}
