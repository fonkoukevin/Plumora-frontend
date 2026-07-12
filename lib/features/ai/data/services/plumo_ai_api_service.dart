import 'package:dio/dio.dart';

import '../models/plumo_ai_models.dart';

/// Calls the stateless "Plumo IA" backend endpoints (Gemini-backed, but the
/// Flutter app never talks to Gemini directly -- every request goes through
/// the Plumora API, which holds the Gemini API key server-side).
class PlumoAiApiService {
  const PlumoAiApiService(this._dio);

  final Dio _dio;

  Future<AiWritingResponse> rewriteText(AiWritingRequest request) async {
    final response = await _dio.post(
      '/ai/writing/rewrite',
      data: request.toJson(),
    );
    return AiWritingResponse.fromJson(_unwrap(response.data));
  }

  Future<AiWritingResponse> summarizeText(AiWritingRequest request) async {
    final response = await _dio.post(
      '/ai/writing/summarize',
      data: request.toJson(),
    );
    return AiWritingResponse.fromJson(_unwrap(response.data));
  }

  Future<AiWritingResponse> continueText(AiWritingRequest request) async {
    final response = await _dio.post(
      '/ai/writing/continue',
      data: request.toJson(),
    );
    return AiWritingResponse.fromJson(_unwrap(response.data));
  }

  Future<AiTitleResponse> suggestTitles(AiWritingRequest request) async {
    final response = await _dio.post(
      '/ai/writing/titles',
      data: request.toJson(),
    );
    return AiTitleResponse.fromJson(_unwrap(response.data));
  }

  Future<BetaReadingAnalysisResponse> analyzeForBetaReading(
    BetaReadingAnalysisRequest request,
  ) async {
    final response = await _dio.post(
      '/ai/beta-reading/analyze',
      data: request.toJson(),
    );
    return BetaReadingAnalysisResponse.fromJson(_unwrap(response.data));
  }

  Future<BookRecommendationResponse> recommendBooks(
    BookRecommendationRequest request,
  ) async {
    final response = await _dio.post(
      '/ai/books/recommend',
      data: request.toJson(),
    );
    return BookRecommendationResponse.fromJson(_unwrap(response.data));
  }

  Object? _unwrap(Object? data) {
    if (data is Map) {
      final nested = data['data'] ?? data['result'] ?? data['payload'];
      if (nested != null) {
        return _unwrap(nested);
      }
    }

    return data;
  }
}
