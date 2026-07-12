import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';

/// Maps a Plumo IA call failure to one of the four user-facing messages the
/// product wants for this feature specifically -- separate from the generic
/// [AppError] mapping used elsewhere in the app, because these backend
/// errors (usage limiter, Gemini unavailable, ownership check) need their
/// own wording.
String plumoAiErrorMessage(Object error) {
  if (error is AppException) {
    return error.message;
  }

  if (error is! DioException) {
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  final statusCode = error.response?.statusCode;
  switch (statusCode) {
    case 403:
      return "Vous n'avez pas l'autorisation d'utiliser Plumo sur ce contenu.";
    case 400:
      return 'Le texte est trop long pour être analysé.';
    case 503:
      return 'Plumo est momentanément indisponible.';
    default:
      return 'Une erreur est survenue. Veuillez réessayer.';
  }
}
