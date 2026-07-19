import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/text/plumora_document_codec.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/book/data/models/book_model.dart';
import 'package:plumora_app/features/book/data/models/chapter_model.dart';
import 'package:plumora_app/features/book/data/repositories/book_repository.dart';
import 'package:plumora_app/features/book/data/repositories/chapter_repository.dart';
import 'package:plumora_app/features/book/data/services/chapter_api_service.dart';
import 'package:plumora_app/features/writing/presentation/chapter_editor_screen.dart';
import 'package:plumora_app/features/writing/presentation/widgets/plumora_document_editor.dart';

void main() {
  testWidgets('an existing chapter is saved automatically after typing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _RecordingChapterRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chapterRepositoryProvider.overrideWithValue(repository),
          authorBookProvider.overrideWith(
            (ref, id) async => const BookModel(
              id: 'book-1',
              title: 'Mon roman',
              description: '',
              status: BookStatus.draft,
              genre: 'Roman',
              chapterCount: 1,
            ),
          ),
          bookChaptersProvider.overrideWith(
            (ref, id) async => const [
              ChapterModel(
                id: 'chapter-1',
                bookId: 'book-1',
                title: 'Chapitre 1 - Le départ',
                content: 'Il était une fois.',
                order: 1,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: PlumoraTheme.light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: FlutterQuillLocalizations.supportedLocales,
          home: const ChapterEditorScreen(bookId: 'book-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final editor = tester.widget<PlumoraDocumentEditor>(
      find.byType(PlumoraDocumentEditor),
    );
    editor.controller.replaceText(
      0,
      0,
      'Enfin, ',
      const TextSelection.collapsed(offset: 7),
    );
    await tester.pump();
    expect(repository.updateCount, 0);

    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Modifications non sauvegardées'), findsOneWidget);
    expect(
      find.text('Souhaites-tu enregistrer ce chapitre avant de continuer ?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Rester'));
    await tester.pumpAndSettle();
    expect(repository.updateCount, 0);

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(repository.updateCount, 1);
    final request = repository.lastUpdate;
    expect(request, isNotNull);
    expect(PlumoraDocumentCodec.isRichText(request!.content), isTrue);
    expect(
      PlumoraDocumentCodec.plainText(request.content),
      'Enfin, Il était une fois.',
    );
  });
}

class _RecordingChapterRepository extends ChapterRepository {
  _RecordingChapterRepository() : super(ChapterApiService(Dio()));

  int updateCount = 0;
  ChapterUpsertRequest? lastUpdate;

  @override
  Future<ChapterModel> updateChapter(
    String chapterId,
    ChapterUpsertRequest request,
  ) async {
    updateCount += 1;
    lastUpdate = request;
    return ChapterModel(
      id: chapterId,
      bookId: 'book-1',
      title: request.title,
      content: request.content,
      order: request.order ?? 1,
    );
  }
}
