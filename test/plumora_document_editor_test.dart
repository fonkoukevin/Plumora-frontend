import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/text/plumora_document_fonts.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/writing/presentation/widgets/plumora_document_editor.dart';

void main() {
  testWidgets('the writing toolbar applies and persists rich text styles', (
    tester,
  ) async {
    final controller = QuillController(
      document: Document.fromJson(<Map<String, Object>>[
        <String, Object>{'insert': 'Bonjour Plumora\n'},
      ]),
      selection: const TextSelection(baseOffset: 0, extentOffset: 7),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PlumoraTheme.light,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: FlutterQuillLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              PlumoraDocumentToolbar(controller: controller),
              Expanded(
                child: SingleChildScrollView(
                  child: PlumoraDocumentEditor(controller: controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.format_italic));
    await tester.pump();

    final firstOperation = controller.document.toDelta().toJson().first;
    expect(firstOperation['insert'], 'Bonjour');
    expect(firstOperation['attributes'], <String, Object>{
      'bold': true,
      'italic': true,
    });

    await tester.tap(find.byIcon(Icons.undo_outlined));
    await tester.pump();
    final afterUndo = controller.document.toDelta().toJson().first;
    // Quill regroupe les deux mises en forme successives dans une seule
    // opération d'historique, comme un traitement de texte classique.
    expect(afterUndo['attributes'], isNull);

    await tester.tap(find.byIcon(Icons.redo_outlined));
    await tester.pump();
    final afterRedo = controller.document.toDelta().toJson().first;
    expect(afterRedo['attributes'], <String, Object>{
      'bold': true,
      'italic': true,
    });

    controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 7),
      ChangeSource.local,
    );
    await tester.tap(find.text('Police'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roman'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Taille'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24'));
    await tester.pumpAndSettle();

    final afterTypography = controller.document.toDelta().toJson().first;
    expect(afterTypography['attributes'], containsPair('font', 'Lora'));
    expect(afterTypography['attributes'], containsPair('size', 24.0));
  });

  testWidgets(
    'a font choice changes the current paragraph and its rendered style',
    (tester) async {
      final controller = QuillController(
        document: Document.fromJson(<Map<String, Object>>[
          <String, Object>{'insert': 'Bonjour Plumora\nDeuxième ligne\n'},
        ]),
        selection: const TextSelection.collapsed(offset: 4),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_editorApp(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Police'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Roman'));
      await tester.pumpAndSettle();

      final operations = controller.document.toDelta().toJson();
      expect(operations.first['insert'], 'Bonjour Plumora');
      expect(operations.first['attributes'], containsPair('font', 'Lora'));
      expect(operations[1]['insert'], '\nDeuxième ligne\n');

      final renderedParagraphs = tester
          .widgetList<RichText>(find.byType(RichText))
          .where(
            (widget) => widget.text.toPlainText().contains('Bonjour Plumora'),
          );
      final renderedFamilies = renderedParagraphs
          .expand((widget) => _fontFamilies(widget.text))
          .toSet();
      final loraFamily = PlumoraDocumentFonts.styleForAttribute(
        Attribute.fromKeyValue(Attribute.font.key, 'Lora')!,
      ).fontFamily;
      expect(loraFamily, isNotNull);
      expect(renderedFamilies, contains(loraFamily));
    },
  );
}

Widget _editorApp(QuillController controller) {
  return MaterialApp(
    theme: PlumoraTheme.light,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
    ],
    supportedLocales: FlutterQuillLocalizations.supportedLocales,
    home: Scaffold(
      body: Column(
        children: [
          PlumoraDocumentToolbar(controller: controller),
          Expanded(
            child: SingleChildScrollView(
              child: PlumoraDocumentEditor(controller: controller),
            ),
          ),
        ],
      ),
    ),
  );
}

Iterable<String> _fontFamilies(InlineSpan span) sync* {
  final family = span.style?.fontFamily;
  if (family != null) {
    yield family;
  }
  if (span is TextSpan && span.children != null) {
    for (final child in span.children!) {
      yield* _fontFamilies(child);
    }
  }
}
