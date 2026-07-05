import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../models/catalog_book_model.dart';
import '../services/catalog_api_service.dart';

final catalogApiServiceProvider = Provider<CatalogApiService>((ref) {
  return CatalogApiService(ref.watch(dioProvider));
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(catalogApiServiceProvider));
});

final catalogBooksProvider =
    FutureProvider.family<List<CatalogBookModel>, String>((ref, genre) {
      return ref
          .watch(catalogRepositoryProvider)
          .books(genre: genre.trim().isEmpty ? null : genre);
    });

final plumoraCatalogBooksProvider =
    FutureProvider.family<List<CatalogBookModel>, PlumoraCatalogQuery>((
      ref,
      query,
    ) async {
      final repository = ref.watch(catalogRepositoryProvider);
      final search = query.search.trim();
      final genre = query.genre.trim();
      final books = search.isEmpty
          ? await repository.books(genre: genre.isEmpty ? null : genre)
          : await repository.search(search);

      return books.where((book) {
        if (!book.isPlumoraOriginal) {
          return false;
        }

        if (genre.isEmpty || search.isEmpty) {
          return true;
        }

        return (book.genre ?? '').trim().toLowerCase() == genre.toLowerCase();
      }).toList();
    });

final latestCatalogBooksProvider = FutureProvider<List<CatalogBookModel>>((
  ref,
) {
  return ref.watch(catalogRepositoryProvider).latest();
});

final popularCatalogBooksProvider = FutureProvider<List<CatalogBookModel>>((
  ref,
) {
  return ref.watch(catalogRepositoryProvider).popular();
});

final catalogSearchProvider =
    FutureProvider.family<List<CatalogBookModel>, String>((ref, query) {
      final normalized = query.trim();
      if (normalized.isEmpty) {
        return ref.watch(catalogRepositoryProvider).books();
      }

      return ref.watch(catalogRepositoryProvider).search(normalized);
    });

final catalogBookDetailProvider =
    FutureProvider.family<CatalogBookDetailModel, String>((ref, bookId) {
      return ref.watch(catalogRepositoryProvider).bookDetail(bookId);
    });

class PlumoraCatalogQuery {
  const PlumoraCatalogQuery({this.search = '', this.genre = ''});

  final String search;
  final String genre;

  @override
  bool operator ==(Object other) {
    return other is PlumoraCatalogQuery &&
        other.search == search &&
        other.genre == genre;
  }

  @override
  int get hashCode => Object.hash(search, genre);
}

class CatalogRepository {
  const CatalogRepository(this._apiService);

  final CatalogApiService _apiService;

  Future<List<CatalogBookModel>> books({String? genre}) {
    return _apiService.books(genre: genre);
  }

  Future<List<CatalogBookModel>> latest() {
    return _apiService.latest();
  }

  Future<List<CatalogBookModel>> popular() {
    return _apiService.popular();
  }

  Future<List<CatalogBookModel>> search(String query) {
    return _apiService.search(query);
  }

  Future<CatalogBookDetailModel> bookDetail(String bookId) {
    return _apiService.bookDetail(bookId);
  }
}
