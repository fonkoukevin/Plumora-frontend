import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../../../catalog/data/models/catalog_book_model.dart';
import '../models/reading_progress_model.dart';

class ReadingApiService {
  const ReadingApiService(this._dio);

  final Dio _dio;

  Future<CatalogBookDetailModel> readBook(String bookId) async {
    final response = await _dio.get('/books/$bookId/read');
    return CatalogBookDetailModel.fromJson(_readPayloadMap(response.data));
  }

  Future<List<ReadingProgressModel>> myProgress() async {
    final response = await _dio.get('/reading-progress/my');
    return _readPayloadList(response.data)
        .map(ReadingProgressModel.fromJson)
        .where((progress) => progress.bookId.isNotEmpty)
        .toList();
  }

  Future<ReadingProgressModel> progress(String bookId) async {
    final response = await _dio.get('/books/$bookId/reading-progress');
    return ReadingProgressModel.fromJson(_readPayloadMap(response.data));
  }

  Future<ReadingProgressModel> createProgress(
    String bookId,
    ReadingProgressUpdateRequest request,
  ) async {
    final response = await _dio.post(
      '/books/$bookId/reading-progress',
      data: request.toJson(),
    );
    return ReadingProgressModel.fromJson(_readPayloadMap(response.data));
  }

  Future<ReadingProgressModel> updateProgress(
    String bookId,
    ReadingProgressUpdateRequest request,
  ) async {
    final response = await _dio.put(
      '/books/$bookId/reading-progress',
      data: request.toJson(),
    );
    return ReadingProgressModel.fromJson(_readPayloadMap(response.data));
  }

  Future<ReadingProgressModel> finishProgress(String bookId) async {
    final response = await _dio.patch('/books/$bookId/reading-progress/finish');
    return ReadingProgressModel.fromJson(_readPayloadMap(response.data));
  }

  Map<String, dynamic> _readPayloadMap(Object? data) {
    final payload = _unwrap(data);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const AppException('La réponse de lecture est invalide.');
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
        'progress',
        'readingProgress',
        'data',
      ]) {
        final nested = payload[key];
        if (nested is List) {
          return nested;
        }
      }
    }

    throw const AppException('La liste de lectures est invalide.');
  }

  Object? _unwrap(Object? data) {
    if (data is Map) {
      for (final key in ['data', 'result', 'payload']) {
        final value = data[key];
        if (value != null) {
          return _unwrap(value);
        }
      }
      final progress = data['progress'];
      if (data.length == 1 && (progress is Map || progress is List)) {
        return _unwrap(progress);
      }
    }

    return data;
  }
}
