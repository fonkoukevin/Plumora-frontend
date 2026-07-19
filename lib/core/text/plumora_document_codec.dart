import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

/// Converts chapter contents between Plumora's persisted representation and a
/// Quill [Document].
///
/// Chapters written before rich text was introduced are stored as plain text.
/// They remain valid inputs and are transparently converted to Quill documents.
abstract final class PlumoraDocumentCodec {
  /// Marker used to distinguish a versioned Delta payload from legacy text.
  static const String storagePrefix = '@plumora:delta:v1\n';

  static const String _format = 'plumora-delta';
  static const int _version = 1;

  /// Decodes either a versioned Delta payload or a legacy plain-text chapter.
  ///
  /// A corrupt versioned payload is treated as plain text, without its
  /// technical prefix. This keeps the author's data visible and never lets a
  /// persistence error prevent the editor from opening.
  static Document decodeDocument(String content) {
    if (!content.startsWith(storagePrefix)) {
      return _documentFromPlainText(content);
    }

    final payload = content.substring(storagePrefix.length);
    try {
      final envelope = jsonDecode(payload);
      if (envelope is! Map<String, dynamic> ||
          envelope['format'] != _format ||
          envelope['version'] != _version ||
          envelope['ops'] is! List) {
        return _documentFromPlainText(payload);
      }

      return Document.fromJson(envelope['ops'] as List<dynamic>);
    } on Object {
      return _documentFromPlainText(payload);
    }
  }

  /// Encodes a Quill document in Plumora's versioned storage envelope.
  static String encodeDocument(Document document) {
    final envelope = <String, Object>{
      'format': _format,
      'version': _version,
      'ops': document.toDelta().toJson(),
    };
    return '$storagePrefix${jsonEncode(envelope)}';
  }

  /// Whether [content] uses Plumora's versioned rich-text representation.
  static bool isRichText(String content) => content.startsWith(storagePrefix);

  /// Returns displayable plain text from either supported storage format.
  static String plainText(String content) =>
      plainTextFromDocument(decodeDocument(content));

  /// Returns a document's text without Quill's required terminal newline.
  static String plainTextFromDocument(Document document) {
    final text = document.toPlainText();
    return text.endsWith('\n') ? text.substring(0, text.length - 1) : text;
  }

  /// Whether a stored chapter contains something other than whitespace.
  static bool hasMeaningfulContent(String content) =>
      plainText(content).trim().isNotEmpty;

  /// Counts whitespace-separated words in a stored chapter.
  static int wordCount(String content) {
    final text = plainText(content).trim();
    return text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
  }

  /// Counts text characters, including spaces and author-entered line breaks.
  static int characterCount(String content) => plainText(content).length;

  static Document _documentFromPlainText(String text) {
    if (text.isEmpty) {
      return Document();
    }

    final normalizedText = text.endsWith('\n') ? text : '$text\n';
    return Document.fromJson(<Map<String, Object>>[
      <String, Object>{'insert': normalizedText},
    ]);
  }
}
