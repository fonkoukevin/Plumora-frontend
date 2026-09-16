import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../models/auth_response.dart';
import '../models/forgot_password_request.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/resend_verification_request.dart';
import '../models/reset_password_request.dart';
import '../models/role_model.dart';
import '../models/update_profile_request.dart';
import '../models/user_model.dart';
import '../models/verify_email_request.dart';

class AuthApiService {
  const AuthApiService(this._dio);

  final Dio _dio;

  /// The new account starts unverified and cannot sign in until the
  /// confirmation email is clicked — unlike login/google, this no longer
  /// returns a token, so the response body (`{ message, user }`) is
  /// intentionally not parsed here.
  Future<void> register(RegisterRequest request) async {
    await _dio.post('/auth/register', data: request.toJson());
  }

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post('/auth/login', data: request.toJson());
    return AuthResponse.fromJson(_readMap(response.data));
  }

  Future<AuthResponse> loginWithGoogle(String idToken) async {
    final response = await _dio.post(
      '/auth/google',
      data: {'idToken': idToken},
    );
    return AuthResponse.fromJson(_readMap(response.data));
  }

  /// Always resolves successfully regardless of whether [request.email]
  /// belongs to an account — the backend must not leak account existence
  /// through this endpoint (see docs/api-contract.md).
  Future<void> requestPasswordReset(ForgotPasswordRequest request) async {
    await _dio.post('/auth/forgot-password', data: request.toJson());
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    await _dio.post('/auth/reset-password', data: request.toJson());
  }

  Future<void> verifyEmail(VerifyEmailRequest request) async {
    await _dio.post('/auth/verify-email', data: request.toJson());
  }

  /// Always resolves successfully regardless of whether [request.email]
  /// belongs to an account or is already verified — same anti-enumeration
  /// contract as [requestPasswordReset].
  Future<void> resendVerification(ResendVerificationRequest request) async {
    await _dio.post('/auth/resend-verification', data: request.toJson());
  }

  Future<UserModel> authMe() async {
    final response = await _dio.get('/auth/me');
    return UserModel.fromJson(_readMap(response.data));
  }

  Future<UserModel> userMe() async {
    final response = await _dio.get('/users/me');
    return UserModel.fromJson(_readMap(response.data));
  }

  Future<UserModel> updateMe(UpdateProfileRequest request) async {
    final response = await _dio.put('/users/me', data: request.toJson());
    return UserModel.fromJson(_readMap(response.data));
  }

  Future<List<RoleModel>> myRoles() async {
    final response = await _dio.get('/users/me/roles');
    return _readRoles(response.data);
  }

  Future<List<RoleModel>> updateMyRoles(List<String> roleNames) async {
    final response = await _dio.put(
      '/users/me/roles',
      data: {'roles': roleNames},
    );
    return _readRoles(response.data);
  }

  Map<String, dynamic> _readMap(Object? data) {
    if (data is Map<String, dynamic>) {
      final nestedData = data['data'];
      if (nestedData is Map<String, dynamic>) {
        return nestedData;
      }

      return data;
    }

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const AppException('La réponse du serveur est invalide.');
  }

  List<RoleModel> _readRoles(Object? data) {
    final rolesPayload = data is Map ? data['roles'] ?? data['data'] : data;
    if (rolesPayload is List) {
      return rolesPayload
          .map(RoleModel.fromJson)
          .where((role) => role.name.isNotEmpty)
          .toList();
    }

    throw const AppException('La réponse des rôles est invalide.');
  }
}
