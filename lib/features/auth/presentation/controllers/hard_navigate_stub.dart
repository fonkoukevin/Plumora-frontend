/// No-op on non-web platforms. Logout there relies on in-app navigation
/// (`context.go`) instead, which is sufficient since there's no long-lived
/// browser page / JS SDK state to reset — see `hard_navigate_web.dart` for
/// why the web platform needs a real reload.
void hardNavigateTo(String path) {}
