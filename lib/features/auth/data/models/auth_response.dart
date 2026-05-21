import '../../../../core/errors/app_error.dart';
import 'user_model.dart';

class AuthResponse {
  const AuthResponse({required this.accessToken, this.user});

  final String accessToken;
  final UserModel? user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final source = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final accessToken = _readString(source, [
      'accessToken',
      'access_token',
      'token',
      'jwt',
    ]);
    final userPayload = source['user'] ?? source['currentUser'];

    return AuthResponse(
      accessToken: accessToken,
      user: userPayload is Map<String, dynamic>
          ? UserModel.fromJson(userPayload)
          : null,
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    throw const AppException('Le serveur n a pas renvoyé de token.');
  }
}
