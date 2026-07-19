import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/text/plumora_document_codec.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/book/data/models/chapter_model.dart';
import 'package:plumora_app/features/book/data/repositories/chapter_repository.dart';
import 'package:plumora_app/features/book/data/services/chapter_api_service.dart';
import 'package:plumora_app/features/writing/presentation/chapter_detail_author_screen.dart';

void main() {
  testWidgets('renaming a rich chapter preserves its encoded document', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final document = Document.fromJson(<Map<String, dynamic>>[
      <String, dynamic>{
        'insert': 'Un début important',
        'attributes': <String, dynamic>{'bold': true},
      },
      <String, dynamic>{'insert': '\n'},
    ]);
    final encodedContent = PlumoraDocumentCodec.encodeDocument(document);
    final chapter = ChapterModel(
      id: 'chapter-rich',
      bookId: 'book-1',
      title: 'Ancien titre',
      content: encodedContent,
      order: 2,
    );
    final repository = _FakeChapterRepository(chapter);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chapterProvider.overrideWith((ref, id) async => chapter),
          chapterRepositoryProvider.overrideWithValue(repository),
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
          home: const Scaffold(
            body: ChapterDetailAuthorScreen(
              chapterId: 'chapter-rich',
              bookId: 'book-1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('rich_chapter_content_preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('legacy_chapter_content_field')),
      findsNothing,
    );
    expect(find.text('Un début important', findRichText: true), findsWidgets);
    expect(find.textContaining('18 caractères'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Nouveau titre');
    await tester.tap(
      find.byKey(const ValueKey<String>('save_chapter_details')),
    );
    await tester.pumpAndSettle();

    expect(repository.lastRequest?.title, 'Nouveau titre');
    expect(repository.lastRequest?.content, encodedContent);
    expect(
      PlumoraDocumentCodec.decodeDocument(
        repository.lastRequest!.content,
      ).toDelta().toJson().first['attributes'],
      containsPair('bold', true),
    );
    expect(tester.takeException(), isNull);
  });
}

class _FakeChapterRepository extends ChapterRepository {
  _FakeChapterRepository(this.chapter) : super(ChapterApiService(Dio()));

  final ChapterModel chapter;
  ChapterUpsertRequest? lastRequest;

  @override
  Future<ChapterModel> updateChapter(
    String chapterId,
    ChapterUpsertRequest request,
  ) async {
    lastRequest = request;
    return chapter.copyWith(title: request.title, content: request.content);
  }
}
