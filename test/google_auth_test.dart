import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/errors/app_error.dart';
import 'package:plumora_app/core/network/google_auth_config.dart';
import 'package:plumora_app/features/auth/data/services/google_auth_service.dart';

void main() {
  group('Google sign-in configuration', () {
    test('is not configured when no client id/secret is provided', () {
      expect(GoogleAuthConfig.webClientId, isEmpty);
      expect(GoogleAuthConfig.desktopClientId, isEmpty);
      expect(GoogleAuthConfig.desktopClientSecret, isEmpty);
      expect(GoogleAuthConfig.isConfigured, isFalse);
    });

    test('signInAndGetIdToken fails fast with a clear message instead of '
        'launching a sign-in flow with empty credentials', () async {
      final service = GoogleAuthService();

      await expectLater(
        service.signInAndGetIdToken(),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            contains('configurée'),
          ),
        ),
      );
    });
  });
}
