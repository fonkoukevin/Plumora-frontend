import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../book/data/models/chapter_model.dart';
import '../../../book/data/repositories/chapter_repository.dart';
import '../../../book/data/services/chapter_api_service.dart';
import '../models/catalog_book_model.dart';
import '../services/catalog_api_service.dart';

final catalogApiServiceProvider = Provider<CatalogApiService>((ref) {
  return CatalogApiService(ref.watch(dioProvider));
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(
    ref.watch(catalogApiServiceProvider),
    ref.watch(chapterApiServiceProvider),
  );
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
      final language = _normalizeLanguage(query.language);
      final books = search.isEmpty
          ? await repository.books(
              genre: genre.isEmpty ? null : genre,
              language: language.isEmpty ? null : language,
            )
          : await repository.search(
              search,
              genre: genre.isEmpty ? null : genre,
              language: language.isEmpty ? null : language,
            );

      return books.where((book) {
        if (!book.isPlumoraOriginal) {
          return false;
        }

        if (genre.isNotEmpty &&
            (book.genre ?? '').trim().toLowerCase() != genre.toLowerCase()) {
          return false;
        }

        if (language.isNotEmpty &&
            _normalizeLanguage(book.language ?? 'fr') != language) {
          return false;
        }

        return true;
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
  const PlumoraCatalogQuery({
    this.search = '',
    this.genre = '',
    this.language = '',
  });

  final String search;
  final String genre;
  final String language;

  @override
  bool operator ==(Object other) {
    return other is PlumoraCatalogQuery &&
        other.search == search &&
        other.genre == genre &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hash(search, genre, language);
}

class CatalogRepository {
  const CatalogRepository(this._apiService, this._chapterApiService);

  final CatalogApiService _apiService;
  final ChapterApiService _chapterApiService;

  Future<List<CatalogBookModel>> books({String? genre, String? language}) {
    return _apiService.books(genre: genre, language: language);
  }

  Future<List<CatalogBookModel>> latest() {
    return _apiService.latest();
  }

  Future<List<CatalogBookModel>> popular() {
    return _apiService.popular();
  }

  Future<List<CatalogBookModel>> search(
    String query, {
    String? genre,
    String? language,
  }) {
    return _apiService.search(query, genre: genre, language: language);
  }

  Future<CatalogBookDetailModel> bookDetail(String bookId) async {
    final book = await _apiService.bookDetail(bookId);
    if (book.chapters.isNotEmpty) {
      return book;
    }

    try {
      final chapters = await _chapterApiService.chaptersForBook(bookId);
      if (chapters.isNotEmpty) {
        return book.copyWith(
          chapterCount: chapters.length,
          chapters: chapters.map(_toCatalogChapter).toList(growable: false),
        );
      }
    } on Object {
      // La liste détaillée est optionnelle pour le catalogue public. La fiche
      // reste utilisable si l'endpoint protégé des chapitres est indisponible.
    }

    final fallbackCount = book.chapterCount > 0 ? book.chapterCount : 1;
    return book.copyWith(
      chapterCount: fallbackCount,
      chapters: List.generate(
        fallbackCount,
        (index) => CatalogChapterModel(
          id: '',
          title: book.isExternalImport && fallbackCount == 1
              ? 'Texte intégral'
              : 'Chapitre ${index + 1}',
          content: '',
          order: index + 1,
        ),
        growable: false,
      ),
    );
  }
}

CatalogChapterModel _toCatalogChapter(ChapterModel chapter) {
  return CatalogChapterModel(
    id: chapter.id,
    title: chapter.title,
    content: chapter.content,
    order: chapter.order,
  );
}

String _normalizeLanguage(String? language) {
  final value = language?.trim().toLowerCase() ?? '';
  if (value == 'français' || value == 'francais' || value == 'french') {
    return 'fr';
  }
  if (value == 'anglais' || value == 'english') {
    return 'en';
  }
  if (value.startsWith('fr-')) {
    return 'fr';
  }
  if (value.startsWith('en-')) {
    return 'en';
  }
  return value;
}
