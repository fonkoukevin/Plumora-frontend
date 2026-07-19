import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../../../core/text/plumora_document_fonts.dart';
import '../../../../core/theme/plumora_colors.dart';

class PlumoraDocumentEditor extends StatefulWidget {
  const PlumoraDocumentEditor({
    required this.controller,
    this.readOnly = false,
    this.compact = false,
    this.autoFocus = false,
    this.placeholder = 'Commencez à écrire votre histoire…',
    super.key,
  });

  final quill.QuillController controller;
  final bool readOnly;
  final bool compact;
  final bool autoFocus;
  final String placeholder;

  @override
  State<PlumoraDocumentEditor> createState() => _PlumoraDocumentEditorState();
}

class _PlumoraDocumentEditorState extends State<PlumoraDocumentEditor> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'chapter-rich-editor');
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.readOnly = widget.readOnly;
  }

  @override
  void didUpdateWidget(covariant PlumoraDocumentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller.readOnly = widget.readOnly;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodySize = widget.compact ? 16.5 : 18.0;
    final bodyStyle = TextStyle(
      color: context.colors.textPrimary,
      fontFamily: 'Georgia',
      fontSize: bodySize,
      height: widget.compact ? 1.72 : 1.82,
      letterSpacing: 0.05,
    );
    const horizontalSpacing = quill.HorizontalSpacing(0, 0);
    const lineSpacing = quill.VerticalSpacing(0, 0);

    quill.DefaultTextBlockStyle block(
      TextStyle style, {
      quill.VerticalSpacing spacing = const quill.VerticalSpacing(8, 0),
      BoxDecoration? decoration,
    }) {
      return quill.DefaultTextBlockStyle(
        style,
        horizontalSpacing,
        spacing,
        lineSpacing,
        decoration,
      );
    }

    final quoteDecoration = BoxDecoration(
      color: context.colors.primary.withValues(alpha: 0.055),
      border: Border(left: BorderSide(color: context.colors.primary, width: 3)),
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
    );

    return quill.QuillEditor(
      controller: widget.controller,
      focusNode: _focusNode,
      scrollController: _scrollController,
      config: quill.QuillEditorConfig(
        scrollable: false,
        autoFocus: widget.autoFocus,
        expands: false,
        minHeight: widget.compact ? 360 : 440,
        padding: EdgeInsets.zero,
        placeholder: widget.placeholder,
        enableAlwaysIndentOnTab: true,
        enableInteractiveSelection: true,
        enableSelectionToolbar: true,
        showCursor: !widget.readOnly,
        textCapitalization: TextCapitalization.sentences,
        customStyleBuilder: PlumoraDocumentFonts.styleForAttribute,
        customStyles: quill.DefaultStyles(
          paragraph: block(bodyStyle),
          h1: block(
            bodyStyle.copyWith(
              fontSize: widget.compact ? 27 : 34,
              height: 1.25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            spacing: const quill.VerticalSpacing(18, 6),
          ),
          h2: block(
            bodyStyle.copyWith(
              fontSize: widget.compact ? 23 : 28,
              height: 1.3,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            spacing: const quill.VerticalSpacing(16, 5),
          ),
          h3: block(
            bodyStyle.copyWith(
              fontSize: widget.compact ? 20 : 23,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
            spacing: const quill.VerticalSpacing(14, 4),
          ),
          quote: block(
            bodyStyle.copyWith(
              color: context.colors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            spacing: const quill.VerticalSpacing(12, 8),
            decoration: quoteDecoration,
          ),
          code: block(
            bodyStyle.copyWith(
              fontFamily: 'monospace',
              fontSize: bodySize - 1,
              height: 1.55,
            ),
            decoration: BoxDecoration(
              color: context.colors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          bold: const TextStyle(fontWeight: FontWeight.w800),
          italic: const TextStyle(fontStyle: FontStyle.italic),
          underline: const TextStyle(
            decoration: TextDecoration.underline,
            decorationThickness: 1.4,
          ),
          strikeThrough: const TextStyle(
            decoration: TextDecoration.lineThrough,
          ),
          link: TextStyle(
            color: context.colors.primary,
            decoration: TextDecoration.underline,
          ),
          placeHolder: block(
            bodyStyle.copyWith(
              color: context.colors.textSecondary.withValues(alpha: 0.72),
              fontStyle: FontStyle.italic,
            ),
          ),
          palette: <String, Color>{
            'Plumora': context.colors.primary,
            'Encre': context.colors.textPrimary,
            'Prune': const Color(0xFF6D28D9),
            'Rose': const Color(0xFFDB2777),
            'Bleu': const Color(0xFF2563EB),
            'Vert': const Color(0xFF15803D),
            'Or': const Color(0xFFB7791F),
          },
        ),
      ),
    );
  }
}

class PlumoraDocumentToolbar extends StatelessWidget {
  const PlumoraDocumentToolbar({
    required this.controller,
    this.compact = false,
    super.key,
  });

  final quill.QuillController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconTheme = quill.QuillIconTheme(
      iconButtonUnselectedData: quill.IconButtonData(
        iconSize: compact ? 17 : 18,
        color: context.colors.textSecondary,
        hoverColor: context.colors.primary.withValues(alpha: 0.10),
        highlightColor: context.colors.primary.withValues(alpha: 0.14),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonSelectedData: quill.IconButtonData(
        iconSize: compact ? 17 : 18,
        color: context.colors.primary,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: context.colors.primary.withValues(alpha: 0.13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );

    return quill.QuillSimpleToolbar(
      controller: controller,
      config: quill.QuillSimpleToolbarConfig(
        multiRowsDisplay: false,
        toolbarSize: compact ? 30 : 32,
        color: Colors.transparent,
        sectionDividerColor: context.colors.border,
        sectionDividerSpace: 12,
        showFontFamily: !compact,
        showFontSize: true,
        showBoldButton: true,
        showItalicButton: true,
        showUnderLineButton: true,
        showStrikeThrough: true,
        showInlineCode: false,
        showSubscript: false,
        showSuperscript: false,
        showSmallButton: false,
        showColorButton: !compact,
        showBackgroundColorButton: !compact,
        showClearFormat: true,
        showAlignmentButtons: true,
        showLineHeightButton: !compact,
        showHeaderStyle: true,
        showListNumbers: true,
        showListBullets: true,
        showListCheck: false,
        showCodeBlock: false,
        showQuote: true,
        showIndent: !compact,
        showLink: !compact,
        showUndo: true,
        showRedo: true,
        showSearchButton: !compact,
        iconTheme: iconTheme,
        buttonOptions: quill.QuillSimpleToolbarButtonOptions(
          base: quill.QuillToolbarBaseButtonOptions(
            iconSize: compact ? 17 : 18,
            iconButtonFactor: compact ? 1.8 : 2,
            iconTheme: iconTheme,
          ),
          fontFamily: quill.QuillToolbarFontFamilyButtonOptions(
            defaultDisplayText: 'Police',
            labelOverflow: TextOverflow.ellipsis,
            items: PlumoraDocumentFonts.toolbarItems,
            onSelected: (value) => _formatCurrentParagraph(
              controller,
              value == 'Clear' ? null : value,
            ),
          ),
          fontSize: const quill.QuillToolbarFontSizeButtonOptions(
            defaultDisplayText: 'Taille',
            labelOverflow: TextOverflow.ellipsis,
            items: <String, String>{
              '12': '12',
              '14': '14',
              '16': '16',
              '18': '18',
              '20': '20',
              '24': '24',
              '30': '30',
              '36': '36',
              'Normal': '0',
            },
          ),
        ),
        decoration: const BoxDecoration(color: Colors.transparent),
      ),
    );
  }
}

void _formatCurrentParagraph(
  quill.QuillController controller,
  String? fontFamily,
) {
  final selection = controller.selection;
  if (!selection.isValid || !selection.isCollapsed) {
    return;
  }

  final text = controller.document.toPlainText();
  if (text.isEmpty) {
    return;
  }

  final cursor = selection.extentOffset.clamp(0, text.length - 1);
  final previousBreak = cursor == 0 ? -1 : text.lastIndexOf('\n', cursor - 1);
  final nextBreak = text.indexOf('\n', cursor);
  final start = previousBreak + 1;
  final end = nextBreak == -1 ? text.length : nextBreak;
  if (end <= start) {
    return;
  }

  controller.formatText(
    start,
    end - start,
    quill.Attribute.fromKeyValue(quill.Attribute.font.key, fontFamily),
  );
}
