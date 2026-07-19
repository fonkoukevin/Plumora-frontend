import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../text/plumora_document_codec.dart';
import '../text/plumora_document_fonts.dart';
import '../theme/plumora_colors.dart';

const List<String> _readerFontFallback = <String>[
  'Georgia',
  'Times New Roman',
  'Times',
  'serif',
];

/// Displays a persisted Plumora document without exposing editing controls.
///
/// The view deliberately delegates scrolling to its parent so it can be used
/// inside the reader's continuous paper layout. Text selection and copying
/// remain available in read-only mode.
class PlumoraRichTextView extends StatefulWidget {
  const PlumoraRichTextView({
    required this.content,
    this.fontScale = 1,
    this.compact = false,
    super.key,
  });

  final String content;
  final double fontScale;
  final bool compact;

  @override
  State<PlumoraRichTextView> createState() => _PlumoraRichTextViewState();
}

class _PlumoraRichTextViewState extends State<PlumoraRichTextView> {
  late QuillController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.content);
    _focusNode = FocusNode(debugLabel: 'Plumora rich text reader');
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant PlumoraRichTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content == widget.content) {
      return;
    }

    final previousController = _controller;
    _controller = _createController(widget.content);
    previousController.dispose();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuillEditor(
      key: const ValueKey<String>('plumora_rich_text_view'),
      controller: _controller,
      focusNode: _focusNode,
      scrollController: _scrollController,
      config: QuillEditorConfig(
        scrollable: false,
        padding: EdgeInsets.zero,
        showCursor: false,
        enableInteractiveSelection: true,
        enableSelectionToolbar: true,
        textSelectionThemeData: TextSelectionThemeData(
          cursorColor: context.colors.primary,
          selectionColor: context.colors.primary.withValues(alpha: 0.22),
          selectionHandleColor: context.colors.primary,
        ),
        customStyleBuilder: PlumoraDocumentFonts.styleForAttribute,
        customStyles: _readingStyles(context),
      ),
    );
  }

  QuillController _createController(String content) {
    return QuillController(
      document: PlumoraDocumentCodec.decodeDocument(content),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  DefaultStyles _readingStyles(BuildContext context) {
    const horizontalSpacing = HorizontalSpacing.zero;
    const lineSpacing = VerticalSpacing.zero;
    final bodySize = (widget.compact ? 18.0 : 19.5) * widget.fontScale;
    final bodyStyle = TextStyle(
      color: context.colors.textPrimary,
      fontFamily: 'Georgia',
      fontFamilyFallback: _readerFontFallback,
      fontSize: bodySize,
      fontWeight: FontWeight.w400,
      height: widget.compact ? 1.66 : 1.72,
      letterSpacing: 0.05,
      decoration: TextDecoration.none,
    );

    DefaultTextBlockStyle block(
      TextStyle style, {
      double top = 0,
      double bottom = 0,
      BoxDecoration? decoration,
    }) {
      return DefaultTextBlockStyle(
        style,
        horizontalSpacing,
        VerticalSpacing(top, bottom),
        lineSpacing,
        decoration,
      );
    }

    final quoteColor = context.colors.textSecondary;
    final codeBackground = context.colors.primary.withValues(alpha: 0.07);
    final codeStyle = bodyStyle.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const <String>['Consolas', 'Courier New'],
      fontSize: bodySize * 0.82,
      height: 1.5,
    );

    return DefaultStyles(
      paragraph: block(bodyStyle, bottom: 13),
      h1: block(
        bodyStyle.copyWith(
          fontSize: (widget.compact ? 28.0 : 34.0) * widget.fontScale,
          fontWeight: FontWeight.w700,
          height: 1.24,
          letterSpacing: -0.45,
        ),
        top: 14,
        bottom: 16,
      ),
      h2: block(
        bodyStyle.copyWith(
          fontSize: (widget.compact ? 24.0 : 28.0) * widget.fontScale,
          fontWeight: FontWeight.w700,
          height: 1.28,
          letterSpacing: -0.3,
        ),
        top: 12,
        bottom: 12,
      ),
      h3: block(
        bodyStyle.copyWith(
          fontSize: (widget.compact ? 21.0 : 23.0) * widget.fontScale,
          fontWeight: FontWeight.w700,
          height: 1.32,
          letterSpacing: -0.15,
        ),
        top: 10,
        bottom: 10,
      ),
      h4: block(
        bodyStyle.copyWith(
          fontSize: bodySize * 1.08,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        top: 8,
        bottom: 8,
      ),
      h5: block(
        bodyStyle.copyWith(fontWeight: FontWeight.w700),
        top: 6,
        bottom: 6,
      ),
      h6: block(
        bodyStyle.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
        ),
        top: 6,
        bottom: 6,
      ),
      lists: DefaultListBlockStyle(
        bodyStyle,
        horizontalSpacing,
        const VerticalSpacing(2, 4),
        const VerticalSpacing(0, 4),
        null,
        null,
      ),
      quote: block(
        bodyStyle.copyWith(color: quoteColor, fontStyle: FontStyle.italic),
        top: 8,
        bottom: 14,
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.045),
          border: Border(
            left: BorderSide(color: context.colors.primary, width: 3),
          ),
        ),
      ),
      code: block(
        codeStyle,
        top: 8,
        bottom: 14,
        decoration: BoxDecoration(
          color: codeBackground,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      indent: block(bodyStyle, bottom: 8),
      align: block(bodyStyle, bottom: 13),
      leading: block(bodyStyle, bottom: 13),
      bold: const TextStyle(fontWeight: FontWeight.w700),
      italic: const TextStyle(fontStyle: FontStyle.italic),
      underline: const TextStyle(decoration: TextDecoration.underline),
      strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
      link: TextStyle(
        color: context.colors.primary,
        decoration: TextDecoration.underline,
        decorationColor: context.colors.primary.withValues(alpha: 0.7),
      ),
      inlineCode: InlineCodeStyle(
        style: codeStyle,
        backgroundColor: codeBackground,
        radius: const Radius.circular(4),
      ),
      sizeSmall: TextStyle(fontSize: bodySize * 0.82),
      sizeLarge: TextStyle(fontSize: bodySize * 1.25),
      sizeHuge: TextStyle(fontSize: bodySize * 1.55),
    );
  }
}
