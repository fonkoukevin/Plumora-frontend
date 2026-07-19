import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/network/dio_client.dart';
import 'package:plumora_app/core/storage/secure_token_storage.dart';
import 'package:plumora_app/features/auth/data/repositories/auth_repository.dart';
import 'package:plumora_app/features/auth/data/services/auth_api_service.dart';
import 'package:plumora_app/features/auth/data/services/google_auth_service.dart';

/// A [HttpClientAdapter] that never touches the network: every request is
/// answered synchronously from [handler], so these tests exercise the real
/// [AuthRepository] + [AuthApiService] + [SecureTokenStorage] wiring without
/// ever calling the real backend.
class _FakeHttpAdapter implements HttpClientAdapter {
  _FakeHttpAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(int statusCode, Map<String, dynamic> data) {
  return ResponseBody.fromString(
    '{"firstname":"Ada","lastname":"Lovelace","id":"user-1","username":"ada",'
    '"email":"ada@example.com"}',
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

// GoogleSignIn asserts that its underlying platform params are only ever set
// once per process, so every test in this file shares a single instance
// instead of each building its own (restoreSession never calls into it, it
// only satisfies AuthRepository's constructor).
final _sharedGoogleAuthService = GoogleAuthService();

AuthRepository _buildRepository(
  ResponseBody Function(RequestOptions options) handler,
) {
  final tokenStorage = const SecureTokenStorage();
  final dioClient = DioClient(
    tokenStorage: tokenStorage,
    baseUrl: 'https://fake.test/api/v1',
  );
  dioClient.dio.httpClientAdapter = _FakeHttpAdapter(handler);

  return AuthRepository(
    apiService: AuthApiService(dioClient.dio),
    tokenStorage: tokenStorage,
    googleAuthService: _sharedGoogleAuthService,
  );
}

void main() {
  setUp(() {
    // Real SecureTokenStorage, backed by the package's official in-memory
    // test double instead of a real platform channel — no real backend and
    // no real OS keychain/keystore is ever touched.
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  group('AuthRepository.restoreSession — 401/403 (expired or invalid JWT)', () {
    test(
      'a 401 from /auth/me clears the token and signs the user out',
      () async {
        const storage = SecureTokenStorage();
        await storage.saveAccessToken('a-stale-jwt');

        final repository = _buildRepository(
          (options) => ResponseBody.fromString(
            '{"message":"Unauthorized"}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

        final session = await repository.restoreSession();

        expect(session.isAuthenticated, isFalse);
        expect(await storage.readAccessToken(), isNull);
      },
    );

    test(
      'a 403 from /auth/me also clears the token and signs the user out',
      () async {
        const storage = SecureTokenStorage();
        await storage.saveAccessToken('a-forbidden-jwt');

        final repository = _buildRepository(
          (options) => ResponseBody.fromString(
            '{"message":"Forbidden"}',
            403,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

        final session = await repository.restoreSession();

        expect(session.isAuthenticated, isFalse);
        expect(await storage.readAccessToken(), isNull);
      },
    );

    test(
      'no stored token short-circuits to unauthenticated without any call',
      () async {
        final repository = _buildRepository(
          (options) => throw StateError('the API must not be called'),
        );

        final session = await repository.restoreSession();

        expect(session.isAuthenticated, isFalse);
      },
    );
  });

  group('AuthRepository.restoreSession — network error handling', () {
    test('a connection error propagates (so the UI can show a retry) and '
        'keeps the token — the user is not logged out just because they are '
        'offline', () async {
      const storage = SecureTokenStorage();
      await storage.saveAccessToken('a-valid-jwt');

      final repository = _buildRepository(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'Connection refused',
        ),
      );

      await expectLater(
        repository.restoreSession(),
        throwsA(isA<DioException>()),
      );
      expect(await storage.readAccessToken(), 'a-valid-jwt');
    });
  });

  group('AuthRepository.restoreSession — happy path', () {
    test('a 200 from /auth/me restores an authenticated session', () async {
      const storage = SecureTokenStorage();
      await storage.saveAccessToken('a-valid-jwt');

      final repository = _buildRepository((options) {
        if (options.path == '/users/me/roles') {
          return ResponseBody.fromString(
            '{"roles":[]}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return _jsonResponse(200, const {});
      });

      final session = await repository.restoreSession();

      expect(session.isAuthenticated, isTrue);
      expect(await storage.readAccessToken(), 'a-valid-jwt');
    });
  });
}
