import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../models/ai_models.dart';

class AiApiService {
  const AiApiService(this._dio);

  final Dio _dio;

  Future<AiWritingSuggestionModel> requestWritingSuggestion(
    AiWritingSuggestionRequest request,
  ) async {
    final response = await _dio.post(
      '/ai/writing/suggestions',
      data: request.toJson(),
    );
    return AiWritingSuggestionModel.fromJson(_readPayloadMap(response.data));
  }

  Future<AiWritingSuggestionModel> acceptSuggestion(String suggestionId) {
    return _patchSuggestion(
      suggestionId,
      'accept',
      AiSuggestionStatus.accepted,
    );
  }

  Future<AiWritingSuggestionModel> modifySuggestion(
    String suggestionId,
    String modifiedText,
  ) {
    return _patchSuggestion(
      suggestionId,
      'modify',
      AiSuggestionStatus.modified,
      data: {
        'suggestionText': modifiedText.trim(),
        'modifiedText': modifiedText.trim(),
      },
    );
  }

  Future<AiWritingSuggestionModel> ignoreSuggestion(String suggestionId) {
    return _patchSuggestion(suggestionId, 'ignore', AiSuggestionStatus.ignored);
  }

  Future<List<AiRecommendedBookModel>> recommendBooks(
    AiRecommendationRequest request,
  ) async {
    final response = await _dio.post(
      '/ai/recommendations/books',
      data: request.toJson(),
    );
    return _readPayloadList(response.data, const [
      'recommendations',
      'results',
      'books',
      'items',
      'content',
      'data',
    ]).map(AiRecommendedBookModel.fromJson).where((recommendation) {
      return recommendation.book.id.isNotEmpty;
    }).toList();
  }

  Future<List<AiRecommendationRequestModel>> myRecommendationRequests() async {
    final response = await _dio.get('/ai/recommendations/my-requests');
    return _readPayloadList(response.data, const [
      'requests',
      'items',
      'content',
      'data',
    ]).map(AiRecommendationRequestModel.fromJson).where((request) {
      return request.id.isNotEmpty || request.queryText.isNotEmpty;
    }).toList();
  }

  Future<AiWritingSuggestionModel> _patchSuggestion(
    String suggestionId,
    String action,
    AiSuggestionStatus fallbackStatus, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.patch(
      '/ai/writing/suggestions/$suggestionId/$action',
      data: data,
    );
    final payload = _tryReadPayloadMap(response.data);
    if (payload == null) {
      return AiWritingSuggestionModel(
        id: suggestionId,
        suggestionText: data?['suggestionText']?.toString() ?? '',
        status: fallbackStatus,
      );
    }

    return AiWritingSuggestionModel.fromJson(
      payload,
    ).copyWith(status: fallbackStatus);
  }

  Map<String, dynamic> _readPayloadMap(Object? data) {
    final payload = _tryReadPayloadMap(data);
    if (payload != null) {
      return payload;
    }

    throw const AppException('La réponse IA est invalide.');
  }

  Map<String, dynamic>? _tryReadPayloadMap(Object? data) {
    if (data == null || data == '') {
      return null;
    }

    final payload = _unwrap(data);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  List<Object?> _readPayloadList(Object? data, List<String> listKeys) {
    final payload = _unwrap(data);
    if (payload is List) {
      return payload;
    }

    if (payload is Map) {
      for (final key in listKeys) {
        final nested = payload[key];
        if (nested is List) {
          return nested;
        }
      }
    }

    throw const AppException('La liste IA est invalide.');
  }

  Object? _unwrap(Object? data) {
    if (data is Map) {
      for (final key in [
        'data',
        'result',
        'payload',
        'suggestion',
        'recommendation',
        'request',
      ]) {
        final value = data[key];
        if (value != null) {
          return _unwrap(value);
        }
      }
    }

    return data;
  }
}
