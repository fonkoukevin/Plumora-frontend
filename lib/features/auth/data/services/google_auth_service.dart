import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/network/google_auth_config.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

class GoogleAuthService {
  GoogleAuthService()
    : _googleSignIn = GoogleSignIn(
        params: GoogleSignInParams(
          clientId: GoogleAuthConfig.isDesktopOAuthFlow
              ? GoogleAuthConfig.desktopClientId
              : GoogleAuthConfig.webClientId,
          clientSecret: GoogleAuthConfig.isDesktopOAuthFlow
              ? GoogleAuthConfig.desktopClientSecret
              : null,
          scopes: const [
            'https://www.googleapis.com/auth/userinfo.profile',
            'https://www.googleapis.com/auth/userinfo.email',
          ],
        ),
      );

  final GoogleSignIn _googleSignIn;

  /// Runs the Google sign-in flow and returns a Google ID token the backend
  /// can verify. Throws an [AppException] with a French, user-facing message
  /// if Google auth isn't configured, or if the user cancels/it fails.
  Future<String> signInAndGetIdToken() async {
    if (!GoogleAuthConfig.isConfigured) {
      throw const AppException(
        "La connexion avec Google n'est pas encore configurée sur cette "
        'application.',
      );
    }

    final GoogleSignInCredentials? credentials;
    try {
      credentials = await _googleSignIn.signIn();
    } catch (_) {
      throw const AppException(
        'La connexion Google a été annulée ou a échoué.',
      );
    }

    final idToken = credentials?.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AppException(
        "Google n'a pas renvoyé de jeton d'identité valide.",
      );
    }

    return idToken;
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
