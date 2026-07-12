import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../models/plumo_ai_models.dart';
import '../services/plumo_ai_api_service.dart';

final plumoAiApiServiceProvider = Provider<PlumoAiApiService>((ref) {
  return PlumoAiApiService(ref.watch(dioProvider));
});

final plumoAiRepositoryProvider = Provider<PlumoAiRepository>((ref) {
  return PlumoAiRepository(ref.watch(plumoAiApiServiceProvider));
});

/// Personalized "Pour vous" book picks for the Discover screen.
final plumoBookRecommendationsProvider =
    FutureProvider<List<BookRecommendationItem>>((ref) async {
      final response = await ref
          .watch(plumoAiRepositoryProvider)
          .recommendBooks(const BookRecommendationRequest());
      return response.recommendations;
    });

class PlumoAiRepository {
  const PlumoAiRepository(this._apiService);

  final PlumoAiApiService _apiService;

  Future<AiWritingResponse> rewriteText(AiWritingRequest request) {
    _checkText(request.text);
    return _apiService.rewriteText(request);
  }

  Future<AiWritingResponse> summarizeText(AiWritingRequest request) {
    _checkText(request.text);
    return _apiService.summarizeText(request);
  }

  Future<AiWritingResponse> continueText(AiWritingRequest request) {
    _checkText(request.text);
    return _apiService.continueText(request);
  }

  Future<AiTitleResponse> suggestTitles(AiWritingRequest request) {
    _checkText(request.text);
    return _apiService.suggestTitles(request);
  }

  Future<BetaReadingAnalysisResponse> analyzeForBetaReading(
    BetaReadingAnalysisRequest request,
  ) {
    _checkText(request.text);
    return _apiService.analyzeForBetaReading(request);
  }

  Future<BookRecommendationResponse> recommendBooks(
    BookRecommendationRequest request,
  ) {
    return _apiService.recommendBooks(request);
  }

  void _checkText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const AppException('Ajoute un texte avant de demander à Plumo.');
    }
    if (trimmed.length > plumoAiMaxInputChars) {
      throw const AppException('Le texte est trop long pour être analysé.');
    }
  }
}
