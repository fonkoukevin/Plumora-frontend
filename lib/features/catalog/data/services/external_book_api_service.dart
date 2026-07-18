import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../../../book/data/models/book_model.dart';
import '../models/external_book_model.dart';

class ExternalBookApiService {
  const ExternalBookApiService(this._dio);

  final Dio _dio;

  Future<ExternalBookPage> searchExternalBooks({
    String? search,
    String? language,
    String? topic,
    int page = 0,
  }) async {
    final response = await _dio.get(
      '/external-books',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (language != null && language.trim().isNotEmpty)
          'language': language.trim(),
        if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
        'page': page < 0 ? 0 : page,
      },
    );

    return ExternalBookPage.fromJson(response.data);
  }

  Future<ExternalBook> getExternalBook(String gutendexId) async {
    final id = gutendexId.trim();
    if (id.isEmpty) {
      throw const AppException('Livre externe introuvable.');
    }

    final response = await _dio.get(
      '/external-books/${Uri.encodeComponent(id)}',
    );
    return ExternalBook.fromJson(_readPayloadMap(response.data));
  }

  Future<ExternalBook> getExternalBookDetails(String externalId) {
    return getExternalBook(externalId);
  }

  Future<BookModel> importGutendexBook(String gutendexId) async {
    final id = gutendexId.trim();
    if (id.isEmpty) {
      throw const AppException('Livre externe introuvable.');
    }

    final response = await _dio.post(
      '/books/import/gutendex/${Uri.encodeComponent(id)}',
    );

    final book = BookModel.fromJson(_readPayloadMap(response.data));
    if (book.id.isEmpty) {
      throw const AppException('Le livre importé est invalide.');
    }

    return book;
  }

  Map<String, dynamic> _readPayloadMap(Object? data) {
    final payload = _unwrap(data);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const AppException('La réponse du catalogue externe est invalide.');
  }

  Object? _unwrap(Object? data) {
    if (data is Map) {
      for (final key in ['data', 'result', 'payload', 'book', 'item']) {
        final value = data[key];
        if (value != null) {
          return _unwrap(value);
        }
      }
    }

    return data;
  }
}
