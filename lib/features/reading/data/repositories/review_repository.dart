import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../models/review_model.dart';
import '../services/review_api_service.dart';

final reviewApiServiceProvider = Provider<ReviewApiService>((ref) {
  return ReviewApiService(ref.watch(dioProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(reviewApiServiceProvider));
});

final bookReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((
  ref,
  bookId,
) {
  return ref.watch(reviewRepositoryProvider).reviewsForBook(bookId);
});

final myReviewsProvider = FutureProvider<List<ReviewModel>>((ref) {
  return ref.watch(reviewRepositoryProvider).myReviews();
});

final myReviewForBookProvider = FutureProvider.family<ReviewModel?, String>((
  ref,
  bookId,
) async {
  final reviews = await ref.watch(reviewRepositoryProvider).myReviews();
  return reviews.cast<ReviewModel?>().firstWhere(
    (review) => review?.bookId == bookId || review?.book?.id == bookId,
    orElse: () => null,
  );
});

class ReviewRepository {
  const ReviewRepository(this._apiService);

  final ReviewApiService _apiService;

  Future<ReviewModel> createReview(String bookId, ReviewUpsertRequest request) {
    return _apiService.createReview(bookId, request);
  }

  Future<List<ReviewModel>> reviewsForBook(String bookId) {
    return _apiService.reviewsForBook(bookId);
  }

  Future<List<ReviewModel>> myReviews() {
    return _apiService.myReviews();
  }

  Future<ReviewModel> updateReview(
    String reviewId,
    ReviewUpsertRequest request,
  ) {
    return _apiService.updateReview(reviewId, request);
  }

  Future<void> deleteReview(String reviewId) {
    return _apiService.deleteReview(reviewId);
  }
}
