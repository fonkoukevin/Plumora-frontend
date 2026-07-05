import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../models/review_model.dart';

class ReviewApiService {
  const ReviewApiService(this._dio);

  final Dio _dio;

  Future<ReviewModel> createReview(
    String bookId,
    ReviewUpsertRequest request,
  ) async {
    final response = await _dio.post(
      '/books/$bookId/reviews',
      data: request.toJson(),
    );
    return ReviewModel.fromJson(_readPayloadMap(response.data));
  }

  Future<List<ReviewModel>> reviewsForBook(String bookId) async {
    final response = await _dio.get('/books/$bookId/reviews');
    return _readPayloadList(response.data)
        .map(ReviewModel.fromJson)
        .map((review) {
          return review.bookId.isEmpty
              ? review.copyWith(bookId: bookId)
              : review;
        })
        .where((review) => review.id.isNotEmpty)
        .toList();
  }

  Future<ReviewModel> createExternalBookReview(
    String gutendexId,
    ReviewUpsertRequest request,
  ) async {
    final id = _requiredExternalId(gutendexId);
    final response = await _dio.post(
      '/external-books/${Uri.encodeComponent(id)}/reviews',
      data: request.toJson(),
    );
    final review = ReviewModel.fromJson(_readPayloadMap(response.data));
    return review.bookId.isEmpty ? review.copyWith(bookId: id) : review;
  }

  Future<List<ReviewModel>> reviewsForExternalBook(String gutendexId) async {
    final id = _requiredExternalId(gutendexId);
    final response = await _dio.get(
      '/external-books/${Uri.encodeComponent(id)}/reviews',
    );
    return _readPayloadList(response.data)
        .map(ReviewModel.fromJson)
        .map((review) {
          return review.bookId.isEmpty ? review.copyWith(bookId: id) : review;
        })
        .where((review) => review.id.isNotEmpty)
        .toList();
  }

  Future<List<ReviewModel>> myReviews() async {
    final response = await _dio.get('/reviews/my');
    return _readPayloadList(response.data)
        .map(ReviewModel.fromJson)
        .where((review) => review.id.isNotEmpty)
        .toList();
  }

  Future<ReviewModel> updateReview(
    String reviewId,
    ReviewUpsertRequest request,
  ) async {
    final response = await _dio.put(
      '/reviews/$reviewId',
      data: request.toJson(),
    );
    return ReviewModel.fromJson(_readPayloadMap(response.data));
  }

  Future<void> deleteReview(String reviewId) async {
    await _dio.delete('/reviews/$reviewId');
  }

  Map<String, dynamic> _readPayloadMap(Object? data) {
    final payload = _unwrap(data);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const AppException("La réponse d'avis est invalide.");
  }

  List<Object?> _readPayloadList(Object? data) {
    final payload = _unwrap(data);
    if (payload is List) {
      return payload;
    }

    if (payload is Map) {
      for (final key in [
        'content',
        'items',
        'reviews',
        'bookReviews',
        'comments',
        'commentaires',
        'data',
      ]) {
        final nested = payload[key];
        if (nested is List) {
          return nested;
        }
      }
    }

    throw const AppException("La liste d'avis est invalide.");
  }

  Object? _unwrap(Object? data) {
    if (data is Map) {
      for (final key in [
        'data',
        'result',
        'payload',
        'review',
        'bookReview',
        'externalReview',
      ]) {
        final value = data[key];
        if (value != null) {
          return _unwrap(value);
        }
      }
    }

    return data;
  }

  String _requiredExternalId(String gutendexId) {
    final id = gutendexId.trim();
    if (id.isEmpty) {
      throw const AppException('Identifiant Gutendex manquant.');
    }
    return id;
  }
}
