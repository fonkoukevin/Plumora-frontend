import 'package:dio/dio.dart';

class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class AppError {
  static String messageFor(Object error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is DioException) {
      return _dioMessage(error);
    }

    return 'Une erreur inattendue est survenue.';
  }

  static String _dioMessage(DioException error) {
    final responseMessage = _responseMessage(error.response?.data);
    if (responseMessage != null &&
        responseMessage.isNotEmpty &&
        !_isGenericServerError(responseMessage)) {
      return responseMessage;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Le serveur ne répond pas. Réessaie dans un instant.';
      case DioExceptionType.connectionError:
        return 'Impossible de joindre le serveur Plumora.';
      case DioExceptionType.badResponse:
        return _statusMessage(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'La requête a été annulée.';
      case DioExceptionType.badCertificate:
        return 'Le certificat du serveur est invalide.';
      case DioExceptionType.unknown:
        return 'Erreur réseau inattendue.';
    }
  }

  static String _statusMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Les informations envoyées sont invalides.';
      case 401:
        return 'Email ou mot de passe incorrect.';
      case 403:
        return "Tu n'as pas les droits pour effectuer cette action.";
      case 404:
        return 'La ressource demandée est introuvable.';
      case 409:
        return 'Un compte existe déjà avec ces informations.';
      case 500:
      case 502:
      case 503:
        return 'Le serveur Plumora rencontre un problème.';
      default:
        return 'La requête a échoué.';
    }
  }

  static String? _responseMessage(Object? data) {
    if (data is Map) {
      for (final key in ['message', 'error', 'detail']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return null;
  }

  static bool _isGenericServerError(String message) {
    final normalized = message.trim().toLowerCase();
    return normalized == 'unexpected server error' ||
        normalized == 'internal server error';
  }
}
