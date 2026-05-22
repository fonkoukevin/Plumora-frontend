import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../models/book_model.dart';

class BookApiService {
  const BookApiService(this._dio);

  final Dio _dio;

  Future<BookModel> createBook(BookUpsertRequest request) async {
    final response = await _dio.post('/books', data: request.toJson());
    final payload = _tryReadPayloadMap(response.data);
    if (payload != null) {
      final book = BookModel.fromJson(payload);
      if (book.id.isNotEmpty) {
        return book;
      }
    }

    return _findCreatedBook(request);
  }

  Future<List<BookModel>> myBooks() async {
    final response = await _dio.get('/books/my-books');
    return _readPayloadList(
      response.data,
    ).map(BookModel.fromJson).where((book) => book.id.isNotEmpty).toList();
  }

  Future<BookModel> bookById(String bookId) async {
    try {
      final response = await _dio.get('/books/$bookId');
      final book = BookModel.fromJson(_readPayloadMap(response.data));
      if (book.id.isNotEmpty) {
        return book;
      }
    } catch (_) {
      final fallback = await _findBookInMyBooks(bookId);
      if (fallback != null) {
        return fallback;
      }
      rethrow;
    }

    final fallback = await _findBookInMyBooks(bookId);
    if (fallback != null) {
      return fallback;
    }

    throw const AppException('Livre introuvable.');
  }

  Future<BookModel> updateBook(String bookId, BookUpsertRequest request) async {
    final response = await _dio.put('/books/$bookId', data: request.toJson());
    final payload = _tryReadPayloadMap(response.data);
    if (payload == null) {
      return bookById(bookId);
    }

    return BookModel.fromJson(payload);
  }

  Future<BookModel> publishBook(String bookId) async {
    final response = await _dio.patch('/books/$bookId/publish');
    final payload = _tryReadPayloadMap(response.data);
    if (payload == null) {
      return bookById(bookId);
    }

    return BookModel.fromJson(payload);
  }

  Future<BookModel> archiveBook(String bookId) async {
    final response = await _dio.patch('/books/$bookId/archive');
    final payload = _tryReadPayloadMap(response.data);
    if (payload == null) {
      return bookById(bookId);
    }

    return BookModel.fromJson(payload);
  }

  Future<BookModel> _findCreatedBook(BookUpsertRequest request) async {
    final title = request.title.trim();
    final books = await myBooks();
    final matches =
        books
            .where((book) => book.title.trim() == title)
            .toList(growable: false)
          ..sort((a, b) {
            final aDate = a.updatedAt ?? a.createdAt ?? DateTime(0);
            final bDate = b.updatedAt ?? b.createdAt ?? DateTime(0);
            return bDate.compareTo(aDate);
          });

    if (matches.isNotEmpty) {
      return matches.first;
    }

    throw const AppException(
      "Livre créé, mais impossible de retrouver son identifiant.",
    );
  }

  Future<BookModel?> _findBookInMyBooks(String bookId) async {
    final normalizedId = bookId.trim();
    if (normalizedId.isEmpty) {
      return null;
    }

    try {
      final books = await myBooks();
      return books.cast<BookModel?>().firstWhere(
        (book) => book?.id == normalizedId,
        orElse: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _readPayloadMap(Object? data) {
    final payload = _tryReadPayloadMap(data);
    if (payload != null) {
      return payload;
    }

    throw const AppException('La réponse livre est invalide.');
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
      for (final key in ['content', 'items', 'books', 'data']) {
        final nested = payload[key];
        if (nested is List) {
          return nested;
        }
      }
    }

    throw const AppException('La liste de livres est invalide.');
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
