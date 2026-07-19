import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/text/plumora_document_codec.dart';

void main() {
  group('PlumoraDocumentCodec', () {
    test('decodes legacy plain text and exposes useful statistics', () {
      const content = 'Un ancien chapitre\navec cinq mots.';

      final document = PlumoraDocumentCodec.decodeDocument(content);

      expect(PlumoraDocumentCodec.plainTextFromDocument(document), content);
      expect(PlumoraDocumentCodec.plainText(content), content);
      expect(PlumoraDocumentCodec.isRichText(content), isFalse);
      expect(PlumoraDocumentCodec.hasMeaningfulContent(content), isTrue);
      expect(PlumoraDocumentCodec.wordCount(content), 6);
      expect(PlumoraDocumentCodec.characterCount(content), content.length);
    });

    test('encodes Delta styles in a versioned envelope', () {
      final document = Document.fromJson(<Map<String, Object>>[
        <String, Object>{
          'insert': 'Texte gras',
          'attributes': <String, Object>{'bold': true},
        },
        <String, Object>{'insert': ' et normal\n'},
      ]);

      final encoded = PlumoraDocumentCodec.encodeDocument(document);
      final envelope =
          jsonDecode(
                encoded.substring(PlumoraDocumentCodec.storagePrefix.length),
              )
              as Map<String, dynamic>;

      expect(encoded, startsWith(PlumoraDocumentCodec.storagePrefix));
      expect(PlumoraDocumentCodec.isRichText(encoded), isTrue);
      expect(envelope['format'], 'plumora-delta');
      expect(envelope['version'], 1);
      expect(envelope['ops'], <Object>[
        <String, Object>{
          'insert': 'Texte gras',
          'attributes': <String, Object>{'bold': true},
        },
        <String, Object>{'insert': ' et normal\n'},
      ]);
    });

    test('round trip preserves rich text operations', () {
      final source = Document.fromJson(<Map<String, Object>>[
        <String, Object>{
          'insert': 'Une histoire',
          'attributes': <String, Object>{'italic': true},
        },
        <String, Object>{'insert': '\n'},
        <String, Object>{'insert': 'Premier point'},
        <String, Object>{
          'insert': '\n',
          'attributes': <String, Object>{'list': 'bullet'},
        },
      ]);

      final encoded = PlumoraDocumentCodec.encodeDocument(source);
      final decoded = PlumoraDocumentCodec.decodeDocument(encoded);

      expect(decoded.toDelta().toJson(), source.toDelta().toJson());
      expect(
        PlumoraDocumentCodec.plainText(encoded),
        'Une histoire\nPremier point',
      );
      expect(PlumoraDocumentCodec.wordCount(encoded), 4);
    });

    test('handles empty and whitespace-only chapters', () {
      expect(PlumoraDocumentCodec.plainText(''), isEmpty);
      expect(PlumoraDocumentCodec.hasMeaningfulContent(''), isFalse);
      expect(PlumoraDocumentCodec.wordCount(''), 0);
      expect(PlumoraDocumentCodec.characterCount(''), 0);
      expect(PlumoraDocumentCodec.hasMeaningfulContent('  \n\t'), isFalse);

      final encodedEmpty = PlumoraDocumentCodec.encodeDocument(Document());
      expect(PlumoraDocumentCodec.plainText(encodedEmpty), isEmpty);
      expect(PlumoraDocumentCodec.hasMeaningfulContent(encodedEmpty), isFalse);
    });

    test('invalid JSON never throws and keeps its payload as text', () {
      const payload = 'Ce texte {n est pas du JSON';
      const stored = '${PlumoraDocumentCodec.storagePrefix}$payload';

      expect(
        () => PlumoraDocumentCodec.decodeDocument(stored),
        returnsNormally,
      );
      expect(PlumoraDocumentCodec.plainText(stored), payload);
      expect(PlumoraDocumentCodec.hasMeaningfulContent(stored), isTrue);
    });
  });
}
