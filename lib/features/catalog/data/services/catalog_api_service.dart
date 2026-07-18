import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../models/catalog_book_model.dart';

class CatalogApiService {
  const CatalogApiService(this._dio);

  final Dio _dio;

  Future<List<CatalogBookModel>> books({
    String? genre,
    String? language,
  }) async {
    final response = await _dio.get(
      '/catalog/books',
      queryParameters: {
        if (genre != null && genre.trim().isNotEmpty) 'genre': genre.trim(),
        if (language != null && language.trim().isNotEmpty)
          'language': language.trim().toLowerCase(),
      },
    );
    return _readPayloadList(response.data)
        .map(CatalogBookModel.fromJson)
        .where((book) => book.id.isNotEmpty)
        .toList();
  }

  Future<List<CatalogBookModel>> latest() async {
    final response = await _dio.get('/catalog/books/latest');
    return _readPayloadList(response.data)
        .map(CatalogBookModel.fromJson)
        .where((book) => book.id.isNotEmpty)
        .toList();
  }

  Future<List<CatalogBookModel>> popular() async {
    final response = await _dio.get('/catalog/books/popular');
    return _readPayloadList(response.data)
        .map(CatalogBookModel.fromJson)
        .where((book) => book.id.isNotEmpty)
        .toList();
  }

  Future<List<CatalogBookModel>> search(
    String query, {
    String? genre,
    String? language,
  }) async {
    final response = await _dio.get(
      '/catalog/books/search',
      queryParameters: {
        'q': query.trim(),
        'query': query.trim(),
        if (genre != null && genre.trim().isNotEmpty) 'genre': genre.trim(),
        if (language != null && language.trim().isNotEmpty)
          'language': language.trim().toLowerCase(),
      },
    );
    return _readPayloadList(response.data)
        .map(CatalogBookModel.fromJson)
        .where((book) => book.id.isNotEmpty)
        .toList();
  }

  Future<CatalogBookDetailModel> bookDetail(String bookId) async {
    final response = await _dio.get('/catalog/books/$bookId');
    return CatalogBookDetailModel.fromJson(_readPayloadMap(response.data));
  }

  Map<String, dynamic> _readPayloadMap(Object? data) {
    final payload = _unwrap(data);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const AppException('La réponse catalogue est invalide.');
  }

  List<Object?> _readPayloadList(Object? data) {
    final payload = _unwrap(data);
    if (payload is List) {
      return payload;
    }

    if (payload is Map) {
      for (final key in ['content', 'items', 'books', 'results', 'data']) {
        final nested = payload[key];
        if (nested is List) {
          return nested;
        }
      }
    }

    throw const AppException('La liste du catalogue est invalide.');
  }

  Object? _unwrap(Object? data) {
    if (data is Map) {
      for (final key in ['data', 'result', 'payload']) {
        final value = data[key];
        if (value != null) {
          return _unwrap(value);
        }
      }
    }

    return data;
  }
}
