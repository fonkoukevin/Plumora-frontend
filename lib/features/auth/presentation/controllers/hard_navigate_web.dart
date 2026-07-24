import 'dart:js_interop';

/// A real browser navigation (full page reload), not an SPA route change.
///
/// Google's web SDK (`google_sign_in`) can only be initialized once per real
/// page load — after signing in and out with Google, retrying Google
/// sign-in within the same SPA session silently breaks until a full reload
/// happens. This forces that reload on logout instead of requiring the user
/// to notice and refresh manually.
@JS('window.location.assign')
external void _assign(String url);

void hardNavigateTo(String path) => _assign(path);
