import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/book/data/models/book_model.dart';
import 'package:plumora_app/features/book/data/models/chapter_model.dart';
import 'package:plumora_app/features/book/data/repositories/book_repository.dart';
import 'package:plumora_app/features/book/data/repositories/chapter_repository.dart';
import 'package:plumora_app/features/writing/presentation/chapter_editor_screen.dart';

void main() {
  testWidgets('desktop editor omits the secondary book navigation block', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authorBookProvider.overrideWith(
            (ref, id) async => const BookModel(
              id: 'book-1',
              title: 'Mon livre',
              description: '',
              status: BookStatus.draft,
              genre: 'Fantasy',
              chapterCount: 1,
            ),
          ),
          bookChaptersProvider.overrideWith(
            (ref, id) async => const [
              ChapterModel(
                id: 'chapter-1',
                bookId: 'book-1',
                title: 'Chapitre 1',
                content: 'Le début de mon histoire.',
                order: 1,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          home: const ChapterEditorScreen(bookId: 'book-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chapitres'), findsOneWidget);
    expect(find.text("Vue d'ensemble"), findsNothing);
    expect(find.text('Éditeur'), findsNothing);
    expect(find.text('Retours bêta'), findsNothing);
    expect(find.text('Bêta-test'), findsNothing);
    expect(find.text('Royalties'), findsNothing);
    expect(find.text('Paramètres'), findsNothing);
    expect(find.text('Vue mobile'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
