import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/catalog/data/models/catalog_book_model.dart';
import 'package:plumora_app/features/reading/data/models/reading_progress_model.dart';
import 'package:plumora_app/features/reading/data/models/review_model.dart';
import 'package:plumora_app/features/reading/data/repositories/reading_repository.dart';
import 'package:plumora_app/features/reading/data/repositories/review_repository.dart';
import 'package:plumora_app/features/reading/data/services/reading_api_service.dart';
import 'package:plumora_app/features/reading/data/services/review_api_service.dart';
import 'package:plumora_app/features/reading/presentation/reading_screen.dart';

void main() {
  testWidgets('the reader removes Gutenberg boilerplate and tracks scrolling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_readerApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader_paper')), findsOneWidget);
    expect(find.text('CHAPTER I'), findsOneWidget);
    expect(find.textContaining('licence technique'), findsNothing);
    expect(find.textContaining('END OF THE PROJECT'), findsNothing);

    final before = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(before.value, 0);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();

    final after = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(after.value, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the reader stays usable on a narrow screen with larger text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_readerApp(textScale: 1.3));
    await tester.pumpAndSettle();

    expect(find.text('Retour'), findsOneWidget);
    expect(find.text('Précédent'), findsOneWidget);
    expect(find.text('Terminer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Confort de lecture'));
    await tester.pumpAndSettle();
    expect(find.text('Confort de lecture'), findsOneWidget);
    expect(find.text('Grand'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finishing a book returns to its detail page', (tester) async {
    final repository = _FakeReadingRepository();
    final router = GoRouter(
      initialLocation: '/books/book-reader/read',
      routes: [
        GoRoute(
          path: '/books/:bookId/read',
          builder: (context, state) =>
              ReadingScreen(bookId: state.pathParameters['bookId']!),
        ),
        ShellRoute(
          builder: (context, state, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: '/catalog/books/:bookId',
              builder: (context, state) =>
                  Text('Détail ${state.pathParameters['bookId']}'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readableBookProvider.overrideWith(
            (ref, id) async => const CatalogBookDetailModel(
              id: 'book-reader',
              title: 'Carmen',
              description: '',
              authorName: 'Prosper Mérimée',
              chapters: [
                CatalogChapterModel(
                  id: 'chapter-reader',
                  title: 'Texte intégral',
                  content: 'Une histoire complète.',
                  order: 1,
                ),
              ],
            ),
          ),
          readingProgressProvider.overrideWith((ref, id) async => null),
          readingRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          theme: PlumoraTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();

    expect(repository.finishedBookId, 'book-reader');
    expect(find.text('Détail book-reader'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the review star publishes an opinion and keeps reading open', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeReviewRepository();

    await tester.pumpWidget(_readerApp(reviewRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Donner mon avis'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Une lecture vraiment captivante.',
    );
    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();

    expect(repository.createdForBookId, 'book-reader');
    expect(repository.createdRequest?.rating, 5);
    expect(
      repository.createdRequest?.comment,
      'Une lecture vraiment captivante.',
    );
    expect(find.text('CHAPTER I'), findsOneWidget);
    expect(find.text('Avis publié.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _readerApp({double textScale = 1, ReviewRepository? reviewRepository}) {
  final content = [
    'The Project Gutenberg eBook of Carmen',
    '',
    'Cette licence technique ne doit pas apparaître.',
    '',
    '*** START OF THE PROJECT GUTENBERG EBOOK CARMEN ***',
    '',
    'CHAPTER I',
    '',
    for (var index = 0; index < 45; index++)
      'La nuit enveloppait doucement la ville tandis que les personnages '
          'avançaient dans les rues silencieuses. Ce paragraphe offre une '
          'longueur réaliste pour vérifier le confort de lecture et le '
          'défilement de la page.',
    '',
    '*** END OF THE PROJECT GUTENBERG EBOOK CARMEN ***',
    '',
    'Texte technique final.',
  ].join('\n');

  final book = CatalogBookDetailModel(
    id: 'book-reader',
    title: 'Carmen',
    description: '',
    authorName: 'Prosper Mérimée',
    chapters: [
      CatalogChapterModel(
        id: 'chapter-reader',
        title: 'Texte intégral',
        content: content,
        order: 1,
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      readableBookProvider.overrideWith((ref, id) async => book),
      readingProgressProvider.overrideWith((ref, id) async => null),
      if (reviewRepository != null)
        reviewRepositoryProvider.overrideWithValue(reviewRepository),
    ],
    child: MaterialApp(
      theme: PlumoraTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const ReadingScreen(bookId: 'book-reader'),
    ),
  );
}

class _FakeReadingRepository extends ReadingRepository {
  _FakeReadingRepository() : super(ReadingApiService(Dio()));

  String? finishedBookId;

  @override
  Future<ReadingProgressModel> finishProgress(String bookId) async {
    finishedBookId = bookId;
    return ReadingProgressModel(bookId: bookId, progress: 1, finished: true);
  }
}

class _FakeReviewRepository extends ReviewRepository {
  _FakeReviewRepository() : super(ReviewApiService(Dio()));

  String? createdForBookId;
  ReviewUpsertRequest? createdRequest;

  @override
  Future<ReviewModel> createReview(
    String bookId,
    ReviewUpsertRequest request,
  ) async {
    createdForBookId = bookId;
    createdRequest = request;
    return ReviewModel(
      id: 'review-reader',
      bookId: bookId,
      userId: 'reader-1',
      userName: 'Lecteur',
      rating: request.rating,
      comment: request.comment,
    );
  }
}
