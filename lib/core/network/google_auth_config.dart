import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    show isDesktop;

/// Google OAuth client credentials, supplied at build/run time via
/// `--dart-define` so no secret is ever committed to the repository:
///
/// flutter run \
///   --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com \
///   --dart-define=GOOGLE_DESKTOP_CLIENT_ID=xxxx.apps.googleusercontent.com \
///   --dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=xxxx
///
/// The web client id is also used as the mobile "server client id" (the
/// audience the backend checks the Google ID token against). The desktop
/// client id/secret are a separate "Desktop app" OAuth client, only used for
/// the system-browser flow on Windows/Linux/macOS — see
/// docs/api-contract.md for the backend contract this unlocks.
abstract final class GoogleAuthConfig {
  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  static const String desktopClientId = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_ID',
  );

  static const String desktopClientSecret = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_SECRET',
  );

  /// The `google_sign_in_all_platforms` package uses a browser-based OAuth
  /// flow (needing its own "Desktop app" client id/secret) on Windows, Linux
  /// and macOS ([isDesktop], resolved by the package itself via conditional
  /// compilation), and delegates to the official `google_sign_in` plugin
  /// (native account picker on Android/iOS, Google Identity Services on web)
  /// everywhere else.
  static bool get isDesktopOAuthFlow => isDesktop;

  static bool get isConfigured {
    if (isDesktopOAuthFlow) {
      return desktopClientId.isNotEmpty && desktopClientSecret.isNotEmpty;
    }

    return webClientId.isNotEmpty;
  }
}
