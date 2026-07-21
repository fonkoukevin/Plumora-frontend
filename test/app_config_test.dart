import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/config/app_config.dart';
import 'package:plumora_app/core/network/dio_client.dart';

void main() {
  group('DioClient — calls the configured API', () {
    test('defaults its base URL to AppConfig.apiBaseUrl', () {
      final client = DioClient();
      expect(client.dio.options.baseUrl, AppConfig.apiBaseUrl);
    });

    test('an explicit baseUrl still overrides it (used by tests)', () {
      final client = DioClient(baseUrl: 'https://fake.test/api/v1');
      expect(client.dio.options.baseUrl, 'https://fake.test/api/v1');
    });

    test('uses AppConfig timeouts', () {
      final client = DioClient();
      expect(client.dio.options.connectTimeout, AppConfig.connectTimeout);
      expect(client.dio.options.receiveTimeout, AppConfig.receiveTimeout);
    });
  });

  group('AppEnvironment.fromName', () {
    test('parses each known environment name', () {
      expect(AppEnvironment.fromName('production'), AppEnvironment.production);
      expect(AppEnvironment.fromName('prod'), AppEnvironment.production);
      expect(AppEnvironment.fromName('staging'), AppEnvironment.staging);
      expect(
        AppEnvironment.fromName('development'),
        AppEnvironment.development,
      );
    });

    test('falls back to development for an unknown/empty value', () {
      expect(AppEnvironment.fromName(''), AppEnvironment.development);
      expect(AppEnvironment.fromName('bogus'), AppEnvironment.development);
    });
  });

  group('AppConfig.resolveApiBaseUrl', () {
    test('development defaults to the local backend', () {
      expect(
        AppConfig.resolveApiBaseUrl(AppEnvironment.development, ''),
        'http://localhost:8080/api/v1',
      );
    });

    test('staging defaults to the staging API origin', () {
      expect(
        AppConfig.resolveApiBaseUrl(AppEnvironment.staging, ''),
        'https://staging-api.plumora-books.fr/api/v1',
      );
    });

    test('production defaults to the production API origin', () {
      expect(
        AppConfig.resolveApiBaseUrl(AppEnvironment.production, ''),
        'https://api.plumora-books.fr/api/v1',
      );
    });

    test('an explicit API_BASE_URL override always wins', () {
      expect(
        AppConfig.resolveApiBaseUrl(
          AppEnvironment.production,
          'https://custom.example.com/api/v1',
        ),
        'https://custom.example.com/api/v1',
      );
    });
  });

  group('AppConfig.resolveWebBaseUrl', () {
    test('resolves the public web origin per environment', () {
      expect(
        AppConfig.resolveWebBaseUrl(AppEnvironment.production, ''),
        'https://app.plumora-books.fr',
      );
      expect(
        AppConfig.resolveWebBaseUrl(AppEnvironment.staging, ''),
        'https://staging-app.plumora-books.fr',
      );
    });

    test('an explicit WEB_BASE_URL override always wins', () {
      expect(
        AppConfig.resolveWebBaseUrl(
          AppEnvironment.development,
          'http://192.168.1.20:5000',
        ),
        'http://192.168.1.20:5000',
      );
    });
  });

  group('AppConfig.isLocalUrl — no local URL in production', () {
    test('flags localhost, loopback and private network hosts', () {
      expect(AppConfig.isLocalUrl('http://localhost:8080/api/v1'), isTrue);
      expect(AppConfig.isLocalUrl('http://127.0.0.1:8080/api/v1'), isTrue);
      expect(AppConfig.isLocalUrl('http://192.168.1.5:8080/api/v1'), isTrue);
      expect(AppConfig.isLocalUrl('http://10.0.2.2:8080/api/v1'), isTrue);
      expect(AppConfig.isLocalUrl('http://172.20.0.4:8080/api/v1'), isTrue);
      expect(AppConfig.isLocalUrl('http://backend.local/api/v1'), isTrue);
      expect(AppConfig.isLocalUrl('not a url'), isTrue);
    });

    test('does not flag the real production/staging origins', () {
      expect(
        AppConfig.isLocalUrl('https://api.plumora-books.fr/api/v1'),
        isFalse,
      );
      expect(
        AppConfig.isLocalUrl('https://staging-api.plumora-books.fr/api/v1'),
        isFalse,
      );
    });

    test('a production build resolved against a local URL is detectable', () {
      final misconfigured = AppConfig.resolveApiBaseUrl(
        AppEnvironment.production,
        'http://localhost:8080/api/v1',
      );

      expect(AppConfig.isLocalUrl(misconfigured), isTrue);
    });

    test('the default production API URL is never local', () {
      final url = AppConfig.resolveApiBaseUrl(AppEnvironment.production, '');
      expect(AppConfig.isLocalUrl(url), isFalse);
    });
  });
}
