import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../models/forgot_password_request.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/reset_password_request.dart';
import '../models/role_model.dart';
import '../models/update_profile_request.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';
import '../services/google_auth_service.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiService: ref.watch(authApiServiceProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
    googleAuthService: ref.watch(googleAuthServiceProvider),
  );
});

class AuthRepository {
  const AuthRepository({
    required AuthApiService apiService,
    required SecureTokenStorage tokenStorage,
    required GoogleAuthService googleAuthService,
  }) : this._(apiService, tokenStorage, googleAuthService);

  const AuthRepository._(
    this._apiService,
    this._tokenStorage,
    this._googleAuthService,
  );

  final AuthApiService _apiService;
  final SecureTokenStorage _tokenStorage;
  final GoogleAuthService _googleAuthService;

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

  /// Native/desktop flow: obtains the Google ID token itself via
  /// [GoogleAuthService.signInAndGetIdToken] (not supported on web — see
  /// [loginWithGoogleIdToken]).
  Future<AuthSession> loginWithGoogle() async {
    final idToken = await _googleAuthService.signInAndGetIdToken();
    return loginWithGoogleIdToken(idToken);
  }

  /// Web flow: the ID token was already obtained by Google Identity
  /// Services' own rendered button (see
  /// `GoogleAuthService.webSignInButton`), so this only performs the
  /// Plumora-side exchange.
  Future<AuthSession> loginWithGoogleIdToken(String idToken) async {
    await _tokenStorage.clearAccessToken();
    final response = await _apiService.loginWithGoogle(idToken);
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

  Future<UserModel> updateProfile(UpdateProfileRequest request) async {
    if (request.firstname.trim().isEmpty || request.lastname.trim().isEmpty) {
      throw const AppException('Le prénom et le nom sont requis.');
    }
    if (request.username.trim().isEmpty) {
      throw const AppException("Le nom d'utilisateur est requis.");
    }

    return _apiService.updateMe(request);
  }

  Future<void> requestPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      throw const AppException('Adresse email requise.');
    }

    await _apiService.requestPasswordReset(ForgotPasswordRequest(email: email));
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (token.trim().isEmpty) {
      throw const AppException('Lien de réinitialisation invalide.');
    }
    if (newPassword.length < 8) {
      throw const AppException(
        'Le mot de passe doit contenir au moins 8 caractères.',
      );
    }

    await _apiService.resetPassword(
      ResetPasswordRequest(token: token, newPassword: newPassword),
    );
  }

  /// Also signs out of Google's own client-side SDK, not just the Plumora
  /// session: [GoogleAuthService] configures Google Identity Services with
  /// `auto_select: true`, so without this, a user who logs out of Plumora
  /// after signing in with Google still has an active Google session in the
  /// browser — the SDK then silently tries to auto-select that same account
  /// on the next Google sign-in attempt, which conflicts with a fresh manual
  /// click and breaks it. Best-effort: Google's sign-out failing (e.g. no
  /// active Google session, or Google auth not configured) must not block
  /// clearing the Plumora session itself.
  Future<void> logout() async {
    await _tokenStorage.clearAccessToken();
    try {
      await _googleAuthService.signOut();
    } catch (_) {
      // See doc comment above.
    }
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
