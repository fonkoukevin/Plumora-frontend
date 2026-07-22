import 'package:flutter/widgets.dart';
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
  ///
  /// Not supported on web: `google_sign_in_all_platforms`'s web
  /// implementation throws `UnimplementedError` from `signIn()` (Google
  /// Identity Services only allows starting the flow from its own rendered
  /// button, for popup-blocker reasons) — use [webSignInButton] there
  /// instead.
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
    } catch (error, stackTrace) {
      // Surfaced in the console on purpose: this used to be swallowed
      // entirely (bare `catch (_)`), which is exactly why the web
      // UnimplementedError above went unnoticed until live testing.
      debugPrint('GoogleAuthService.signInAndGetIdToken failed: $error');
      debugPrintStack(stackTrace: stackTrace);
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

  /// Web-only entry point: Google Identity Services requires its own
  /// rendered button as the actual click target (see [signInAndGetIdToken]),
  /// so instead of a `VoidCallback` this returns the button widget itself.
  /// [onSignIn] fires with credentials once the user completes the flow
  /// through it. Returns null if Google auth isn't configured (caller
  /// should fall back to the "not configured" messaging used elsewhere).
  Widget? webSignInButton({
    required void Function(GoogleSignInCredentials credentials) onSignIn,
  }) {
    if (!GoogleAuthConfig.isConfigured) {
      return null;
    }

    return _googleSignIn.signInButton(
      config: GSIAPButtonConfig(
        onSignIn: onSignIn,
        uiConfig: const GSIAPButtonUiConfig(
          type: GSIAPButtonType.standard,
          theme: GSIAPButtonTheme.outline,
          size: GSIAPButtonSize.large,
          text: GSIAPButtonText.continueWith,
          shape: GSIAPButtonShape.rectangular,
        ),
      ),
    );
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
