import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../models/ai_models.dart';
import '../services/ai_api_service.dart';

final aiApiServiceProvider = Provider<AiApiService>((ref) {
  return AiApiService(ref.watch(dioProvider));
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.watch(aiApiServiceProvider));
});

final aiRecommendationRequestsProvider =
    FutureProvider<List<AiRecommendationRequestModel>>((ref) {
      return ref.watch(aiRepositoryProvider).myRecommendationRequests();
    });

class AiRepository {
  const AiRepository(this._apiService);

  final AiApiService _apiService;

  Future<AiWritingSuggestionModel> requestWritingSuggestion(
    AiWritingSuggestionRequest request,
  ) {
    return _apiService.requestWritingSuggestion(request);
  }

  Future<AiWritingSuggestionModel> acceptSuggestion(String suggestionId) {
    return _apiService.acceptSuggestion(suggestionId);
  }

  Future<AiWritingSuggestionModel> modifySuggestion(
    String suggestionId,
    String modifiedText,
  ) {
    return _apiService.modifySuggestion(suggestionId, modifiedText);
  }

  Future<AiWritingSuggestionModel> ignoreSuggestion(String suggestionId) {
    return _apiService.ignoreSuggestion(suggestionId);
  }

  Future<List<AiRecommendedBookModel>> recommendBooks(
    AiRecommendationRequest request,
  ) {
    return _apiService.recommendBooks(request);
  }

  Future<List<AiRecommendationRequestModel>> myRecommendationRequests() {
    return _apiService.myRecommendationRequests();
  }
}
