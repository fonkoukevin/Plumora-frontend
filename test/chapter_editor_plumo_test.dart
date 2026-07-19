import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/text/plumora_document_codec.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/ai/data/models/plumo_ai_models.dart';
import 'package:plumora_app/features/ai/data/repositories/plumo_ai_repository.dart';
import 'package:plumora_app/features/ai/data/services/plumo_ai_api_service.dart';
import 'package:plumora_app/features/book/data/models/book_model.dart';
import 'package:plumora_app/features/book/data/models/chapter_model.dart';
import 'package:plumora_app/features/book/data/repositories/book_repository.dart';
import 'package:plumora_app/features/book/data/repositories/chapter_repository.dart';
import 'package:plumora_app/features/writing/presentation/chapter_editor_screen.dart';
import 'package:plumora_app/features/writing/presentation/widgets/plumora_document_editor.dart';

void main() {
  testWidgets(
    'desktop Plumo guides the author and skips AI without a selection',
    (tester) async {
      final repository = _RecordingPlumoAiRepository();
      await _pumpEditor(tester, repository: repository);

      await _openPlumo(tester);

      expect(find.text('Surligne un passage pour commencer'), findsOneWidget);

      for (final action in <String>[
        'Reformuler',
        'Améliorer le style',
        'Résumer',
        'Continuer l’histoire',
        'Proposer des titres',
      ]) {
        await tester.tap(find.text(action));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(repository.rewriteRequests, isEmpty);
      expect(repository.otherRequestCount, 0);
      expect(
        find.text(
          'Commence par surligner le passage que tu veux retravailler.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('desktop Plumo rewrites and replaces only the selected passage', (
    tester,
  ) async {
    const chapterText =
        'Le vent était glacial. La porte tremblait sous les rafales.';
    const selectedPassage = 'Le vent était glacial.';
    const suggestion = 'Une bise glaciale fouettait la maison.';
    final repository = _RecordingPlumoAiRepository(
      rewriteSuggestion: suggestion,
    );
    await _pumpEditor(
      tester,
      repository: repository,
      chapterContent: chapterText,
    );

    await _openPlumo(tester);

    final editor = tester.widget<PlumoraDocumentEditor>(
      find.byType(PlumoraDocumentEditor),
    );
    final selectionStart = chapterText.indexOf(selectedPassage);
    editor.controller.updateSelection(
      TextSelection(
        baseOffset: selectionStart,
        // Include the following space: Plumo should trim it for the request
        // and preserve it when replacing the selected range.
        extentOffset: selectionStart + selectedPassage.length + 1,
      ),
      ChangeSource.local,
    );
    await tester.pump();

    expect(find.textContaining('4 mots sélectionnés'), findsOneWidget);

    await tester.tap(find.text('Reformuler'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.rewriteRequests, hasLength(1));
    expect(repository.rewriteRequests.single.text, selectedPassage);
    expect(find.text('Passage original'), findsOneWidget);
    expect(find.text(suggestion), findsOneWidget);
    expect(
      PlumoraDocumentCodec.plainTextFromDocument(editor.controller.document),
      chapterText,
      reason: 'Plumo ne doit jamais appliquer sa suggestion automatiquement.',
    );

    await tester.tap(find.text('Remplacer la sélection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      PlumoraDocumentCodec.plainTextFromDocument(editor.controller.document),
      '$suggestion La porte tremblait sous les rafales.',
    );
    expect(
      find.text('Passage remplacé par la proposition de Plumo.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Annuler'));
    await tester.pump();
    expect(
      PlumoraDocumentCodec.plainTextFromDocument(editor.controller.document),
      chapterText,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('mobile Plumo keeps the selection coach and actions usable', (
    tester,
  ) async {
    final repository = _RecordingPlumoAiRepository();
    await _pumpEditor(
      tester,
      repository: repository,
      surfaceSize: const Size(390, 844),
    );

    await _openPlumo(tester);

    expect(find.text('Surligne un passage pour commencer'), findsOneWidget);
    expect(find.text('Reformuler'), findsOneWidget);
    expect(find.text('Proposer des titres'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required _RecordingPlumoAiRepository repository,
  String chapterContent = 'Un chapitre déjà écrit, prêt à être retravaillé.',
  Size surfaceSize = const Size(1440, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        plumoAiRepositoryProvider.overrideWithValue(repository),
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
          (ref, id) async => [
            ChapterModel(
              id: 'chapter-1',
              bookId: 'book-1',
              title: 'Chapitre 1 - Le départ',
              content: chapterContent,
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
}

Future<void> _openPlumo(WidgetTester tester) async {
  await tester.tap(find.text('Plumo'));
  await tester.pumpAndSettle();
}

class _RecordingPlumoAiRepository extends PlumoAiRepository {
  _RecordingPlumoAiRepository({
    this.rewriteSuggestion = 'Le passage reformulé par Plumo.',
  }) : super(PlumoAiApiService(Dio()));

  final String rewriteSuggestion;
  final List<AiWritingRequest> rewriteRequests = [];
  int otherRequestCount = 0;

  @override
  Future<AiWritingResponse> rewriteText(AiWritingRequest request) async {
    rewriteRequests.add(request);
    return AiWritingResponse(
      suggestion: rewriteSuggestion,
      explanation: 'Le passage est plus fluide et conserve son intention.',
    );
  }

  @override
  Future<AiWritingResponse> summarizeText(AiWritingRequest request) async {
    otherRequestCount += 1;
    return const AiWritingResponse(suggestion: 'Résumé');
  }

  @override
  Future<AiWritingResponse> continueText(AiWritingRequest request) async {
    otherRequestCount += 1;
    return const AiWritingResponse(suggestion: 'Suite');
  }

  @override
  Future<AiTitleResponse> suggestTitles(AiWritingRequest request) async {
    otherRequestCount += 1;
    return const AiTitleResponse(titles: ['Titre']);
  }
}
