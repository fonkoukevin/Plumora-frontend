import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../models/chapter_model.dart';

class ChapterApiService {
  const ChapterApiService(this._dio);

  final Dio _dio;

  Future<ChapterModel> createChapter(
    String bookId,
    ChapterUpsertRequest request,
  ) async {
    final response = await _dio.post(
      '/books/$bookId/chapters',
      data: request.toJson(),
    );
    final chapter = ChapterModel.fromJson(_readPayloadMap(response.data));
    return chapter.bookId.isEmpty ? chapter.copyWith(bookId: bookId) : chapter;
  }

  Future<List<ChapterModel>> chaptersForBook(String bookId) async {
    final response = await _dio.get('/books/$bookId/chapters');
    return _readPayloadList(response.data)
        .map(ChapterModel.fromJson)
        .map((chapter) {
          return chapter.bookId.isEmpty
              ? chapter.copyWith(bookId: bookId)
              : chapter;
        })
        .where((chapter) => chapter.id.isNotEmpty)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<ChapterModel> chapterById(String chapterId) async {
    final response = await _dio.get('/chapters/$chapterId');
    return ChapterModel.fromJson(_readPayloadMap(response.data));
  }

  Future<ChapterModel> updateChapter(
    String chapterId,
    ChapterUpsertRequest request,
  ) async {
    final response = await _dio.put(
      '/chapters/$chapterId',
      data: request.toJson(),
    );
    final payload = _tryReadPayloadMap(response.data);
    if (payload == null) {
      return chapterById(chapterId);
    }

    return ChapterModel.fromJson(payload);
  }

  Future<void> deleteChapter(String chapterId) async {
    await _dio.delete('/chapters/$chapterId');
  }

  Map<String, dynamic> _readPayloadMap(Object? data) {
    final payload = _tryReadPayloadMap(data);
    if (payload != null) {
      return payload;
    }

    throw const AppException('La réponse chapitre est invalide.');
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

  List<Object?> _readPayloadList(Object? data) {
    final payload = _unwrap(data);
    if (payload is List) {
      return payload;
    }

    if (payload is Map) {
      for (final key in ['content', 'items', 'chapters', 'data']) {
        final nested = payload[key];
        if (nested is List) {
          return nested;
        }
      }
    }

    throw const AppException('La liste de chapitres est invalide.');
  }

  Object? _unwrap(Object? data) {
    if (data is Map) {
      for (final key in ['data', 'result', 'payload', 'chapter', 'item']) {
        final value = data[key];
        if (value != null) {
          return _unwrap(value);
        }
      }
    }

    return data;
  }
}
