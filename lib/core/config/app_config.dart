/// Typed environment for the app, resolved once at build/run time from the
/// `APP_ENV` dart-define (see docs/deployment-frontend.md for the full list
/// of build commands per platform).
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromName(String name) {
    switch (name.trim().toLowerCase()) {
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.development;
    }
  }
}

/// Centralized, typed runtime configuration for Plumora.
///
/// Every environment-specific value (API origin, web origin, ...) is
/// resolved here, from `--dart-define` flags, so screens and services never
/// hardcode a URL. Never add secrets here (API keys, JWT signing secret,
/// database password): only public, client-side values belong in this file.
abstract final class AppConfig {
  static const String apiPath = '/api/v1';

  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const String _webBaseUrlOverride = String.fromEnvironment(
    'WEB_BASE_URL',
  );

  static final AppEnvironment environment = AppEnvironment.fromName(_envName);

  /// Full API origin + `/api/v1`, e.g. `https://api.plumora-books.fr/api/v1`.
  static final String apiBaseUrl = () {
    final url = resolveApiBaseUrl(environment, _apiBaseUrlOverride);
    assert(
      !(environment == AppEnvironment.production && isLocalUrl(url)),
      'Production build is pointing at a local/non-routable API URL: $url. '
      'Pass --dart-define=API_BASE_URL=https://api.plumora-books.fr/api/v1',
    );
    return url;
  }();

  /// Public web origin used for cross-platform deep links (e.g. the
  /// "Continuer sur le web" card in the mobile author space).
  static final String webBaseUrl = resolveWebBaseUrl(
    environment,
    _webBaseUrlOverride,
  );

  static bool get isProduction => environment == AppEnvironment.production;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Pure resolution logic, kept separate from the compile-time consts above
  /// so it can be unit-tested without relying on `--dart-define` at test
  /// time (see test/app_config_test.dart).
  static String resolveApiBaseUrl(AppEnvironment env, String override) {
    final trimmed = override.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    switch (env) {
      case AppEnvironment.production:
        return 'https://api.plumora-books.fr$apiPath';
      // Not a provisioned environment yet — best-guess naming, update once
      // a real staging backend exists.
      case AppEnvironment.staging:
        return 'https://staging-api.plumora-books.fr$apiPath';
      case AppEnvironment.development:
        return 'http://localhost:8080$apiPath';
    }
  }

  static String resolveWebBaseUrl(AppEnvironment env, String override) {
    final trimmed = override.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    switch (env) {
      case AppEnvironment.production:
        return 'https://app.plumora-books.fr';
      // Same caveat as resolveApiBaseUrl's staging case above.
      case AppEnvironment.staging:
        return 'https://staging-app.plumora-books.fr';
      case AppEnvironment.development:
        return 'http://localhost:5000';
    }
  }

  /// True when [url] resolves to localhost/a private network address — used
  /// to guard against shipping a production build pointed at a dev backend.
  static bool isLocalUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return true;
    }
    if (host.startsWith('192.168.') || host.startsWith('10.')) {
      return true;
    }
    if (host.startsWith('172.')) {
      final parts = host.split('.');
      final secondOctet = parts.length > 1 ? int.tryParse(parts[1]) : null;
      if (secondOctet != null && secondOctet >= 16 && secondOctet <= 31) {
        return true;
      }
    }
    return host.endsWith('.local');
  }
}
