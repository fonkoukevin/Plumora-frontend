import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/beta_reading/data/models/beta_comment_model.dart';
import 'package:plumora_app/features/beta_reading/data/repositories/beta_reading_repository.dart';
import 'package:plumora_app/features/beta_reading/presentation/author_beta_comments_screen.dart';
import 'package:plumora_app/features/book/data/models/book_model.dart';
import 'package:plumora_app/features/book/data/repositories/book_repository.dart';

void main() {
  testWidgets('beta feedback uses two columns only on wide screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const comments = [
      BetaCommentModel(
        id: 'comment-1',
        bookId: 'book-1',
        campaignId: 'campaign-1',
        chapterId: 'chapter-1',
        chapterTitle: 'Chapitre 1',
        content: 'Premier retour très précis',
        type: BetaCommentType.plot,
        status: BetaCommentStatus.open,
      ),
      BetaCommentModel(
        id: 'comment-2',
        bookId: 'book-1',
        campaignId: 'campaign-1',
        chapterId: 'chapter-2',
        chapterTitle: 'Chapitre 2',
        content: 'Deuxième retour très précis',
        type: BetaCommentType.style,
        status: BetaCommentStatus.open,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myBooksProvider.overrideWith(
            (ref) async => const [
              BookModel(
                id: 'book-1',
                title: 'Le manuscrit',
                description: '',
                status: BookStatus.inBetaReading,
              ),
            ],
          ),
          betaCommentsForBookProvider.overrideWith(
            (ref, bookId) async => comments,
          ),
        ],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          home: const Scaffold(body: AuthorBetaCommentsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final first = find.text('Premier retour très précis');
    final second = find.text('Deuxième retour très précis');
    expect(
      tester.getTopLeft(second).dy,
      closeTo(tester.getTopLeft(first).dy, 0.1),
    );
    expect(
      tester.getTopLeft(second).dx,
      greaterThan(tester.getTopRight(first).dx),
    );
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(second).dy,
      greaterThan(tester.getBottomLeft(first).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
