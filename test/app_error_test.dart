import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/errors/app_error.dart';

DioException _badResponse(int statusCode, {Object? data}) {
  final requestOptions = RequestOptions(path: '/api/v1/whatever');
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: data,
    ),
  );
}

void main() {
  group('AppError.messageFor — HTTP status handling', () {
    test('401 maps to an authentication message', () {
      expect(
        AppError.messageFor(_badResponse(401)),
        'Email ou mot de passe incorrect.',
      );
    });

    test('403 maps to a permission message', () {
      expect(
        AppError.messageFor(_badResponse(403)),
        "Tu n'as pas les droits pour effectuer cette action.",
      );
    });

    test('404 maps to a not-found message', () {
      expect(
        AppError.messageFor(_badResponse(404)),
        'La ressource demandée est introuvable.',
      );
    });

    test('a server-provided message takes priority over the generic one', () {
      final error = _badResponse(403, data: {'message': 'Rôle insuffisant.'});
      expect(AppError.messageFor(error), 'Rôle insuffisant.');
    });

    test('a generic server-side message is not surfaced verbatim', () {
      final error = _badResponse(500, data: {'error': 'Internal Server Error'});
      expect(
        AppError.messageFor(error),
        'Le serveur Plumora rencontre un problème.',
      );
    });
  });

  group('AppError.messageFor — network error handling', () {
    test('a connection error (server unreachable) is reported clearly', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/whatever'),
        type: DioExceptionType.connectionError,
      );
      expect(
        AppError.messageFor(error),
        'Impossible de joindre le serveur Plumora.',
      );
    });

    test('a timeout is reported clearly', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/v1/whatever'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        AppError.messageFor(error),
        'Le serveur ne répond pas. Réessaie dans un instant.',
      );
    });

    test('an unexpected (non-Dio, non-AppException) error gets a fallback', () {
      expect(
        AppError.messageFor(StateError('boom')),
        'Une erreur inattendue est survenue.',
      );
    });

    test('an AppException surfaces its own message', () {
      expect(
        AppError.messageFor(const AppException('Message métier précis.')),
        'Message métier précis.',
      );
    });
  });
}
