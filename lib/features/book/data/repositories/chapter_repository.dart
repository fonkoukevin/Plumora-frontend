import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../models/chapter_model.dart';
import '../services/chapter_api_service.dart';

final chapterApiServiceProvider = Provider<ChapterApiService>((ref) {
  return ChapterApiService(ref.watch(dioProvider));
});

final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  return ChapterRepository(ref.watch(chapterApiServiceProvider));
});

final bookChaptersProvider = FutureProvider.family<List<ChapterModel>, String>((
  ref,
  bookId,
) {
  return ref.watch(chapterRepositoryProvider).chaptersForBook(bookId);
});

final chapterProvider = FutureProvider.family<ChapterModel, String>((
  ref,
  chapterId,
) {
  return ref.watch(chapterRepositoryProvider).chapterById(chapterId);
});

class ChapterRepository {
  const ChapterRepository(this._apiService);

  final ChapterApiService _apiService;

  Future<ChapterModel> createChapter(
    String bookId,
    ChapterUpsertRequest request,
  ) {
    return _apiService.createChapter(bookId, request);
  }

  Future<List<ChapterModel>> chaptersForBook(String bookId) {
    return _apiService.chaptersForBook(bookId);
  }

  Future<ChapterModel> chapterById(String chapterId) {
    return _apiService.chapterById(chapterId);
  }

  Future<ChapterModel> updateChapter(
    String chapterId,
    ChapterUpsertRequest request,
  ) {
    return _apiService.updateChapter(chapterId, request);
  }

  Future<void> deleteChapter(String chapterId) {
    return _apiService.deleteChapter(chapterId);
  }
}
