import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// The official package, imported directly (not just transitively through
// google_sign_in_all_platforms) for its un-wrapped authenticationEvents
// stream -- see webSignInButton. Prefixed because both packages export an
// unrelated class literally named `GoogleSignIn`.
import 'package:google_sign_in/google_sign_in.dart' as official;
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
          // Deliberately empty: the backend only ever needs the ID token
          // (POST /auth/google), and the ID token already carries email +
          // name + picture as OpenID Connect claims -- no OAuth2 API scope
          // needed for any of that (docs/api-contract.md).
          //
          // This used to request userinfo.profile/email as OAuth2 scopes,
          // which broke sign-in on web: `google_sign_in_all_platforms_mobile`
          // (shared by the web implementation) unconditionally calls
          // `user.authorizationClient.authorizeScopes(scopes)` for ANY
          // non-empty scopes list inside `genCreds()`, itself invoked from
          // `authenticationEvents.listen(...).then(...)` -- an async
          // callback, not the original click. Browsers require window.open()
          // to be synchronous with a user gesture, so that popup is silently
          // blocked ("Maybe blocked by the browser?"), `genCreds()` then
          // returns null because its accessToken is null (even though the ID
          // token it already had was perfectly valid), and `onSignIn` never
          // fires. See the package's own comment on `authorizeScopes`: "this
          // may show a popup; ensure you call this from a user gesture".
          scopes: const [],
        ),
      );

  final GoogleSignIn _googleSignIn;
  StreamSubscription<official.GoogleSignInAuthenticationEvent>? _webAuthSub;

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
  ///
  /// Deliberately does NOT use `GSIAPButtonConfig.onSignIn`: that callback is
  /// fed by `google_sign_in_all_platforms`'s `genCreds()`, which
  /// unconditionally also calls `authorizationClient.authorizeScopes(...)`
  /// -- even with `scopes: const []` above, that still opens an OAuth2
  /// popup (`accounts.google.com/o/oauth2/v2/auth?...display=popup`) to
  /// mint an access token, and since it fires from
  /// `authenticationEvents.listen(...).then(...)` rather than the click
  /// itself, browsers block it as untrusted ("Maybe blocked by the
  /// browser?"). `genCreds()` then discards the perfectly valid ID token it
  /// already had, because its unrelated `accessToken` came back null, and
  /// `onSignIn` never fires. Confirmed live, twice, after removing the
  /// scopes wasn't enough on its own.
  ///
  /// Instead, this listens directly to the official `package:google_sign_in`
  /// singleton's own `authenticationEvents` -- already initialized by
  /// `google_sign_in_all_platforms` above, since both packages share the
  /// same `GoogleSignIn.instance` under the hood. That stream carries the ID
  /// token straight from the sign-in response, with no OAuth2 authorization
  /// step, and therefore no second popup, involved.
  Widget? webSignInButton({
    required void Function(GoogleSignInCredentials credentials) onSignIn,
  }) {
    if (!GoogleAuthConfig.isConfigured) {
      return null;
    }

    _webAuthSub ??= official.GoogleSignIn.instance.authenticationEvents.listen((
      event,
    ) {
      if (event is! official.GoogleSignInAuthenticationEventSignIn) {
        return;
      }
      final idToken = event.user.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return;
      }
      onSignIn(GoogleSignInCredentials(accessToken: '', idToken: idToken));
    });

    return _googleSignIn.signInButton(
      config: const GSIAPButtonConfig(
        uiConfig: GSIAPButtonUiConfig(
          type: GSIAPButtonType.standard,
          // Filled black reads as more deliberate/polished next to the
          // app's solid purple primary button than the default gray
          // outline, without competing with the purple brand color the
          // way Google's own filledBlue theme would.
          theme: GSIAPButtonTheme.filledBlack,
          size: GSIAPButtonSize.large,
          text: GSIAPButtonText.continueWith,
          shape: GSIAPButtonShape.rectangular,
          logoAlignment: GSIAPButtonLogoAlignment.center,
        ),
      ),
    );
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
