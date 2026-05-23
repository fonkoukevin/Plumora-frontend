import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../catalog/data/models/catalog_book_model.dart';
import '../models/reading_progress_model.dart';
import '../services/reading_api_service.dart';

final readingApiServiceProvider = Provider<ReadingApiService>((ref) {
  return ReadingApiService(ref.watch(dioProvider));
});

final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  return ReadingRepository(ref.watch(readingApiServiceProvider));
});

final readableBookProvider =
    FutureProvider.family<CatalogBookDetailModel, String>((ref, bookId) {
      return ref.watch(readingRepositoryProvider).readBook(bookId);
    });

final readingProgressProvider =
    FutureProvider.family<ReadingProgressModel?, String>((ref, bookId) {
      return ref.watch(readingRepositoryProvider).progress(bookId);
    });

final myReadingProgressProvider = FutureProvider<List<ReadingProgressModel>>((
  ref,
) {
  return ref.watch(readingRepositoryProvider).myProgress();
});

class ReadingRepository {
  const ReadingRepository(this._apiService);

  final ReadingApiService _apiService;

  Future<CatalogBookDetailModel> readBook(String bookId) {
    return _apiService.readBook(bookId);
  }

  Future<List<ReadingProgressModel>> myProgress() {
    return _apiService.myProgress();
  }

  Future<ReadingProgressModel?> progress(String bookId) async {
    try {
      return await _apiService.progress(bookId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<ReadingProgressModel> saveProgress(
    String bookId,
    ReadingProgressUpdateRequest request,
  ) async {
    try {
      return await _apiService.updateProgress(bookId, request);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return _apiService.createProgress(bookId, request);
      }
      rethrow;
    }
  }

  Future<ReadingProgressModel> finishProgress(String bookId) {
    return _apiService.finishProgress(bookId);
  }
}
