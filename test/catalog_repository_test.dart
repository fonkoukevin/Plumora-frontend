import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/features/catalog/data/models/catalog_book_model.dart';
import 'package:plumora_app/features/catalog/data/models/external_book_model.dart';
import 'package:plumora_app/features/catalog/data/repositories/catalog_repository.dart';
import 'package:plumora_app/features/catalog/data/repositories/external_book_repository.dart';
import 'package:plumora_app/features/catalog/data/services/catalog_api_service.dart';
import 'package:plumora_app/features/catalog/data/services/external_book_api_service.dart';
import 'package:plumora_app/features/book/data/models/chapter_model.dart';
import 'package:plumora_app/features/book/data/services/chapter_api_service.dart';

void main() {
  test(
    'Plumora catalog applies the genre filter to mixed API results',
    () async {
      final repository = _FakeCatalogRepository(const [
        CatalogBookModel(
          id: 'fantasy',
          title: 'Fantasy Plumora',
          description: '',
          authorName: 'Auteur',
          genre: 'Fantasy',
        ),
        CatalogBookModel(
          id: 'romance',
          title: 'Romance Plumora',
          description: '',
          authorName: 'Auteur',
          genre: 'Romance',
        ),
        CatalogBookModel(
          id: 'external-fantasy',
          title: 'Fantasy externe',
          description: '',
          authorName: 'Auteur',
          genre: 'Fantasy',
          externalSource: 'gutendex',
        ),
      ]);
      final container = ProviderContainer(
        overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final books = await container.read(
        plumoraCatalogBooksProvider(
          const PlumoraCatalogQuery(genre: 'Fantasy'),
        ).future,
      );

      expect(repository.requestedGenre, 'Fantasy');
      expect(books.map((book) => book.id), ['fantasy']);
    },
  );

  test('Plumora catalog applies FR and EN filters', () async {
    final repository = _FakeCatalogRepository(const [
      CatalogBookModel(
        id: 'book-fr',
        title: 'Livre français',
        description: '',
        authorName: 'Auteur',
        language: 'fr',
      ),
      CatalogBookModel(
        id: 'book-en',
        title: 'English book',
        description: '',
        authorName: 'Author',
        language: 'en',
      ),
    ]);
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final frenchBooks = await container.read(
      plumoraCatalogBooksProvider(
        const PlumoraCatalogQuery(language: 'fr'),
      ).future,
    );
    final englishBooks = await container.read(
      plumoraCatalogBooksProvider(
        const PlumoraCatalogQuery(language: 'en'),
      ).future,
    );

    expect(frenchBooks.map((book) => book.id), ['book-fr']);
    expect(englishBooks.map((book) => book.id), ['book-en']);
    expect(repository.requestedLanguages, ['fr', 'en']);
  });

  test('External catalog applies FR and EN filters', () async {
    final repository = _FakeExternalBookRepository(
      const ExternalBookPage(
        content: [
          ExternalBook(
            externalId: 'external-fr',
            source: 'GUTENDEX',
            title: 'Livre français',
            languages: ['fr'],
          ),
          ExternalBook(
            externalId: 'external-en',
            source: 'GUTENDEX',
            title: 'English book',
            languages: ['en'],
          ),
        ],
        page: 0,
        size: 2,
        totalElements: 2,
        totalPages: 1,
        first: true,
        last: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [externalBookRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final frenchPage = await container.read(
      externalBookSearchProvider(
        const ExternalBookSearchQuery(language: 'fr'),
      ).future,
    );
    final englishPage = await container.read(
      externalBookSearchProvider(
        const ExternalBookSearchQuery(language: 'en'),
      ).future,
    );

    expect(frenchPage.content.map((book) => book.externalId), ['external-fr']);
    expect(englishPage.content.map((book) => book.externalId), ['external-en']);
    expect(repository.requestedLanguages, ['fr', 'en']);
  });

  test(
    'book detail loads the chapter list when the catalog only returns its count',
    () async {
      final repository = CatalogRepository(
        _BookDetailCatalogApiService(),
        _SingleChapterApiService(),
      );

      final book = await repository.bookDetail('book-1');

      expect(book.chapterCount, 1);
      expect(book.chapters, hasLength(1));
      expect(book.chapters.single.id, 'chapter-1');
      expect(book.chapters.single.title, 'L’unique chapitre');
    },
  );

  test(
    'book detail loads its only chapter when the catalog omits the count',
    () async {
      final repository = CatalogRepository(
        _BookDetailCatalogApiService(chapterCount: 0),
        _SingleChapterApiService(),
      );

      final book = await repository.bookDetail('book-1');

      expect(book.chapterCount, 1);
      expect(book.chapters, hasLength(1));
      expect(book.chapters.single.id, 'chapter-1');
      expect(book.chapters.single.title, 'L’unique chapitre');
    },
  );

  test(
    'book detail keeps visible chapter rows when the API list is empty',
    () async {
      final repository = CatalogRepository(
        _BookDetailCatalogApiService(chapterCount: 2),
        _EmptyChapterApiService(),
      );

      final book = await repository.bookDetail('book-1');

      expect(book.chapterCount, 2);
      expect(book.chapters, hasLength(2));
      expect(book.chapters.map((chapter) => chapter.title), [
        'Chapitre 1',
        'Chapitre 2',
      ]);
    },
  );
}

class _FakeCatalogRepository extends CatalogRepository {
  _FakeCatalogRepository(this.results)
    : super(CatalogApiService(Dio()), ChapterApiService(Dio()));

  final List<CatalogBookModel> results;
  String? requestedGenre;
  final List<String?> requestedLanguages = [];

  @override
  Future<List<CatalogBookModel>> books({
    String? genre,
    String? language,
  }) async {
    requestedGenre = genre;
    requestedLanguages.add(language);
    return results;
  }
}

class _BookDetailCatalogApiService extends CatalogApiService {
  _BookDetailCatalogApiService({this.chapterCount = 1}) : super(Dio());

  final int chapterCount;

  @override
  Future<CatalogBookDetailModel> bookDetail(String bookId) async {
    return CatalogBookDetailModel(
      id: 'book-1',
      title: 'Livre à chapitre unique',
      description: '',
      authorName: 'Autrice',
      chapterCount: chapterCount,
    );
  }
}

class _SingleChapterApiService extends ChapterApiService {
  _SingleChapterApiService() : super(Dio());

  @override
  Future<List<ChapterModel>> chaptersForBook(String bookId) async {
    return const [
      ChapterModel(
        id: 'chapter-1',
        bookId: 'book-1',
        title: 'L’unique chapitre',
        content: 'Il était une fois.',
        order: 1,
      ),
    ];
  }
}

class _EmptyChapterApiService extends ChapterApiService {
  _EmptyChapterApiService() : super(Dio());

  @override
  Future<List<ChapterModel>> chaptersForBook(String bookId) async => const [];
}

class _FakeExternalBookRepository extends ExternalBookRepository {
  _FakeExternalBookRepository(this.result)
    : super(ExternalBookApiService(Dio()));

  final ExternalBookPage result;
  final List<String?> requestedLanguages = [];

  @override
  Future<ExternalBookPage> searchExternalBooks({
    String? search,
    String? language,
    String? topic,
    int page = 0,
  }) async {
    requestedLanguages.add(language);
    return result;
  }
}
