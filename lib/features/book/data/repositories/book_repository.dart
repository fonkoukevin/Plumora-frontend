import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../models/book_model.dart';
import '../services/book_api_service.dart';

final bookApiServiceProvider = Provider<BookApiService>((ref) {
  return BookApiService(ref.watch(dioProvider));
});

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository(ref.watch(bookApiServiceProvider));
});

final myBooksProvider = FutureProvider<List<BookModel>>((ref) {
  return ref.watch(bookRepositoryProvider).myBooks();
});

final authorBookProvider = FutureProvider.family<BookModel, String>((
  ref,
  bookId,
) {
  return ref.watch(bookRepositoryProvider).bookById(bookId);
});

class BookRepository {
  const BookRepository(this._apiService);

  final BookApiService _apiService;

  Future<BookModel> createBook(BookUpsertRequest request) {
    return _apiService.createBook(request);
  }

  Future<List<BookModel>> myBooks() {
    return _apiService.myBooks();
  }

  Future<BookModel> bookById(String bookId) {
    return _apiService.bookById(bookId);
  }

  Future<BookModel> updateBook(String bookId, BookUpsertRequest request) {
    return _apiService.updateBook(bookId, request);
  }

  Future<BookModel> publishBook(String bookId) {
    return _apiService.publishBook(bookId);
  }

  Future<BookModel> archiveBook(String bookId) {
    return _apiService.archiveBook(bookId);
  }
}
