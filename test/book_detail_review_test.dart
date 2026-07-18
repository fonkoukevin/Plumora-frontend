import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/catalog/data/models/catalog_book_model.dart';
import 'package:plumora_app/features/catalog/data/repositories/catalog_repository.dart';
import 'package:plumora_app/features/catalog/presentation/book_detail_screen.dart';
import 'package:plumora_app/features/reading/data/models/review_model.dart';
import 'package:plumora_app/features/reading/data/repositories/favorite_repository.dart';
import 'package:plumora_app/features/reading/data/repositories/review_repository.dart';
import 'package:plumora_app/features/reading/data/services/review_api_service.dart';

void main() {
  testWidgets('the book detail always displays its only chapter', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1366, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogBookDetailProvider.overrideWith(
            (ref, id) async => const CatalogBookDetailModel(
              id: 'book-1',
              title: 'Livre à chapitre unique',
              description: 'Une histoire complète.',
              authorName: 'Autrice',
              chapterCount: 1,
            ),
          ),
          favoriteStatusProvider.overrideWith((ref, id) async => false),
          bookReviewsProvider.overrideWith((ref, id) async => []),
        ],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          home: const Scaffold(body: BookDetailScreen(bookId: 'book-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 chapitre'), findsOneWidget);
    expect(find.text('Chapitre 1'), findsOneWidget);
    expect(find.text('Aucun chapitre lisible pour le moment.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a reader can publish a review from the book detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1366, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeReviewRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogBookDetailProvider.overrideWith(
            (ref, id) async => const CatalogBookDetailModel(
              id: 'book-1',
              title: 'La Chambre 314',
              description: 'Un mystere.',
              authorName: 'Idriss Ndao',
            ),
          ),
          favoriteStatusProvider.overrideWith((ref, id) async => false),
          bookReviewsProvider.overrideWith((ref, id) async => []),
          reviewRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          home: const Scaffold(body: BookDetailScreen(bookId: 'book-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reviewButton = find.text('Donner mon avis');
    await tester.ensureVisible(reviewButton);
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Une lecture captivante.');
    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();

    expect(repository.createdForBookId, 'book-1');
    expect(repository.createdRequest?.rating, 5);
    expect(repository.createdRequest?.comment, 'Une lecture captivante.');
    expect(find.text('Avis publié.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
      id: 'review-1',
      bookId: bookId,
      userId: 'reader-1',
      userName: 'Lecteur',
      rating: request.rating,
      comment: request.comment,
    );
  }
}
