import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/core/widgets/plumora_ui.dart';
import 'package:plumora_app/features/catalog/data/models/external_book_model.dart';
import 'package:plumora_app/features/catalog/data/repositories/external_book_repository.dart';
import 'package:plumora_app/features/catalog/presentation/external_book_detail_screen.dart';
import 'package:plumora_app/features/reading/data/repositories/review_repository.dart';

void main() {
  testWidgets('external books use the same wide detail layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1366, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          externalBookDetailProvider.overrideWith(
            (ref, id) async => const ExternalBook(
              externalId: '123',
              source: 'GUTENDEX',
              title: 'Les Miserables',
              authors: ['Victor Hugo'],
              summary: 'Un roman social.',
              subjects: ['Classique'],
              languages: ['fr'],
              downloadCount: 42,
            ),
          ),
          externalBookReviewsProvider.overrideWith((ref, id) async => []),
        ],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          home: const Scaffold(
            body: ExternalBookDetailScreen(gutendexId: '123'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final coverRect = tester.getRect(find.byType(PlumoraBookCover));
    final titleFinder = find.text('Les Miserables');
    final titleRect = tester.getRect(titleFinder);
    final title = tester.widget<Text>(titleFinder);

    expect(coverRect.width, closeTo(300, 0.1));
    expect(titleRect.left, greaterThan(coverRect.right));
    expect(title.style?.fontSize, 40);
    expect(find.text('Résumé'), findsOneWidget);
    expect(find.text("À propos de l'auteur"), findsOneWidget);
    expect(find.text('Chapitres'), findsOneWidget);
    expect(find.text('Avis des lecteurs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
