import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../catalog/data/models/catalog_book_model.dart';
import '../data/models/reading_progress_model.dart';
import '../data/repositories/reading_repository.dart';

const Color _readerPaper = Color(0xFFFFFEFA);
const Color _readerInk = Color(0xFF15120E);
const Color _readerMuted = Color(0xFF625A50);
const List<String> _readerFontFallback = [
  'Georgia',
  'Times New Roman',
  'Times',
  'serif',
];

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({required this.bookId, this.initialChapterId, super.key});

  final String bookId;
  final String? initialChapterId;

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  int _chapterIndex = 0;
  bool _initialized = false;
  bool _saving = false;
  String? _saveError;

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(readableBookProvider(widget.bookId));
    final progressAsync = ref.watch(readingProgressProvider(widget.bookId));

    return bookAsync.when(
      loading: () => const Scaffold(
        backgroundColor: PlumoraColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: PlumoraColors.background,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: FigmaCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lecture indisponible',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppError.messageFor(error),
                    style: const TextStyle(color: PlumoraColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(readableBookProvider(widget.bookId)),
                    child: const Text('Reessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (book) {
        final chapters = [...book.chapters]
          ..sort((a, b) {
            final orderCompare = a.order.compareTo(b.order);
            return orderCompare == 0
                ? a.title.compareTo(b.title)
                : orderCompare;
          });

        if (chapters.isEmpty) {
          return _EmptyReader(book: book);
        }

        _ensureInitialChapter(chapters, progressAsync.valueOrNull);
        final safeIndex = _chapterIndex.clamp(0, chapters.length - 1);
        final chapter = chapters[safeIndex];
        final progress = (safeIndex + 1) / chapters.length;

        return Scaffold(
          backgroundColor: _readerPaper,
          appBar: AppBar(
            backgroundColor: _readerPaper,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => context.go(AppRoutes.library),
              icon: const Icon(Icons.arrow_back),
            ),
            title: Column(
              children: [
                Text(
                  book.title.isEmpty ? 'Livre sans titre' : book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  chapter.title.isEmpty
                      ? 'Chapitre ${safeIndex + 1}'
                      : chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Mes avis',
                onPressed: () => context.go(AppRoutes.libraryReviews),
                icon: const Icon(Icons.star_border),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ColoredBox(
                  color: _readerPaper,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 520;
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 20 : 42,
                          compact ? 26 : 42,
                          compact ? 20 : 42,
                          46,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: SelectionArea(
                              child: _ReaderText(
                                chapter: chapter,
                                compact: compact,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: _readerPaper,
                  border: const Border(
                    top: BorderSide(color: PlumoraColors.border),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Chapitre ${safeIndex + 1} sur ${chapters.length}',
                                style: const TextStyle(
                                  color: PlumoraColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _saving
                                    ? 'Sauvegarde...'
                                    : '${(progress * 100).round()}% lu',
                                style: const TextStyle(
                                  color: PlumoraColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          FigmaProgressBar(
                            value: progress,
                            colors: const [
                              PlumoraColors.primary,
                              PlumoraColors.primary,
                            ],
                          ),
                          if (_saveError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _saveError!,
                              style: const TextStyle(
                                color: PlumoraColors.destructive,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: safeIndex == 0 || _saving
                                    ? null
                                    : () => _goTo(chapters, safeIndex - 1),
                                icon: const Icon(Icons.chevron_left),
                                label: const Text('Precedent'),
                              ),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: _saving
                                    ? null
                                    : () {
                                        if (safeIndex == chapters.length - 1) {
                                          _finish();
                                        } else {
                                          _goTo(chapters, safeIndex + 1);
                                        }
                                      },
                                label: Text(
                                  safeIndex == chapters.length - 1
                                      ? 'Terminer'
                                      : 'Suivant',
                                ),
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _ensureInitialChapter(
    List<CatalogChapterModel> chapters,
    ReadingProgressModel? progress,
  ) {
    if (_initialized) {
      return;
    }
    _initialized = true;

    final requestedChapterId = widget.initialChapterId?.trim();
    final requestedIndex =
        requestedChapterId == null || requestedChapterId.isEmpty
        ? -1
        : chapters.indexWhere((chapter) => chapter.id == requestedChapterId);
    if (requestedIndex >= 0) {
      _chapterIndex = requestedIndex;
      return;
    }

    final progressChapterId = progress?.chapterId?.trim();
    final progressIndex = progressChapterId == null || progressChapterId.isEmpty
        ? -1
        : chapters.indexWhere((chapter) => chapter.id == progressChapterId);
    if (progressIndex >= 0) {
      _chapterIndex = progressIndex;
      return;
    }

    final storedIndex = progress?.chapterIndex ?? 0;
    _chapterIndex = storedIndex.clamp(0, chapters.length - 1);
  }

  Future<void> _goTo(List<CatalogChapterModel> chapters, int index) async {
    setState(() {
      _chapterIndex = index;
      _saving = true;
      _saveError = null;
    });

    try {
      final chapter = chapters[index];
      await ref
          .read(readingRepositoryProvider)
          .saveProgress(
            widget.bookId,
            ReadingProgressUpdateRequest(
              bookId: widget.bookId,
              chapterId: chapter.id,
              chapterIndex: index,
              progress: (index + 1) / chapters.length,
              finished: index == chapters.length - 1,
            ),
          );
      ref.invalidate(readingProgressProvider(widget.bookId));
      ref.invalidate(myReadingProgressProvider);
    } catch (error) {
      setState(() => _saveError = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await ref.read(readingRepositoryProvider).finishProgress(widget.bookId);
      ref.invalidate(readingProgressProvider(widget.bookId));
      ref.invalidate(myReadingProgressProvider);
      if (mounted) {
        context.go(AppRoutes.libraryReviews);
      }
    } catch (error) {
      setState(() => _saveError = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _ReaderText extends StatelessWidget {
  const _ReaderText({required this.chapter, required this.compact});

  final CatalogChapterModel chapter;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final blocks = _ReaderBlock.parse(chapter.content);
    final shouldShowChapterTitle =
        chapter.title.trim().isNotEmpty &&
        !_isGenericFullTextTitle(chapter.title) &&
        (blocks.isEmpty || !_similarText(blocks.first.text, chapter.title));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shouldShowChapterTitle) ...[
          Center(
            child: Text(
              chapter.title,
              textAlign: TextAlign.center,
              style: _readerHeadingStyle(compact),
            ),
          ),
          const SizedBox(height: 30),
        ],
        if (blocks.isEmpty)
          Text(
            'Ce chapitre ne contient pas encore de texte.',
            style: TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: compact ? 17 : 18,
              height: 1.65,
            ),
          )
        else
          for (final block in blocks)
            _ReaderBlockView(block: block, compact: compact),
      ],
    );
  }
}

class _ReaderBlockView extends StatelessWidget {
  const _ReaderBlockView({required this.block, required this.compact});

  final _ReaderBlock block;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case _ReaderBlockType.heading:
        return Padding(
          padding: EdgeInsets.only(top: block.isFirst ? 0 : 18, bottom: 24),
          child: Center(
            child: Text(
              block.text,
              textAlign: TextAlign.center,
              style: _readerHeadingStyle(compact),
            ),
          ),
        );
      case _ReaderBlockType.metadata:
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text(
            block.text,
            textAlign: block.center ? TextAlign.center : TextAlign.left,
            style: _readerMetadataStyle(compact),
          ),
        );
      case _ReaderBlockType.preformatted:
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(block.text, style: _readerPreformattedStyle(compact)),
          ),
        );
      case _ReaderBlockType.separator:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Center(
            child: SizedBox(
              width: 260,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: PlumoraColors.textPrimary.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      case _ReaderBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text(
            block.text,
            textAlign: TextAlign.left,
            style: _readerParagraphStyle(compact),
          ),
        );
    }
  }
}

class _ReaderBlock {
  const _ReaderBlock({
    required this.type,
    required this.text,
    required this.isFirst,
    this.center = false,
  });

  final _ReaderBlockType type;
  final String text;
  final bool isFirst;
  final bool center;

  static List<_ReaderBlock> parse(String value) {
    final prepared = _prepareReaderContent(value);
    if (prepared.isEmpty) {
      return const [];
    }

    final rawBlocks = prepared
        .split(RegExp(r'\n[ \t]*\n+'))
        .map((block) => block.trimRight())
        .where((block) => block.trim().isNotEmpty)
        .toList();
    final blocks = <_ReaderBlock>[];

    for (final rawBlock in rawBlocks) {
      final lines = rawBlock
          .split('\n')
          .map((line) => line.replaceAll(RegExp(r'[ \t]+$'), ''))
          .where((line) => line.trim().isNotEmpty)
          .toList();
      if (lines.isEmpty) {
        continue;
      }

      final trimmedLines = lines.map((line) => line.trim()).toList();
      final joinedLines = trimmedLines.join('\n');
      final collapsed = _collapseInlineWhitespace(trimmedLines.join(' '));
      final isFirst = blocks.isEmpty;

      if (_looksLikeSeparator(trimmedLines)) {
        blocks.add(
          _ReaderBlock(
            type: _ReaderBlockType.separator,
            text: joinedLines,
            isFirst: isFirst,
          ),
        );
        continue;
      }

      if (_looksLikeHeading(trimmedLines, isFirst: isFirst)) {
        blocks.add(
          _ReaderBlock(
            type: _ReaderBlockType.heading,
            text: joinedLines,
            isFirst: isFirst,
          ),
        );
        continue;
      }

      if (_looksLikeMetadata(trimmedLines)) {
        blocks.add(
          _ReaderBlock(
            type: _ReaderBlockType.metadata,
            text: collapsed,
            center: _looksCentered(lines),
            isFirst: isFirst,
          ),
        );
        continue;
      }

      if (_looksPreformatted(lines)) {
        blocks.add(
          _ReaderBlock(
            type: _ReaderBlockType.preformatted,
            text: lines.join('\n'),
            isFirst: isFirst,
          ),
        );
        continue;
      }

      blocks.add(
        _ReaderBlock(
          type: _ReaderBlockType.paragraph,
          text: collapsed,
          isFirst: isFirst,
        ),
      );
    }

    return blocks;
  }
}

enum _ReaderBlockType { heading, metadata, paragraph, preformatted, separator }

TextStyle _readerHeadingStyle(bool compact) {
  return TextStyle(
    color: _readerInk,
    fontFamily: 'Georgia',
    fontFamilyFallback: _readerFontFallback,
    fontSize: compact ? 24 : 28,
    fontWeight: FontWeight.w800,
    height: 1.18,
    letterSpacing: 0,
  );
}

TextStyle _readerParagraphStyle(bool compact) {
  return TextStyle(
    color: _readerInk,
    fontFamily: 'Georgia',
    fontFamilyFallback: _readerFontFallback,
    fontSize: compact ? 18 : 19,
    fontWeight: FontWeight.w400,
    height: 1.55,
    letterSpacing: 0,
  );
}

TextStyle _readerMetadataStyle(bool compact) {
  return TextStyle(
    color: _readerMuted,
    fontFamily: 'Georgia',
    fontFamilyFallback: _readerFontFallback,
    fontSize: compact ? 16 : 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );
}

TextStyle _readerPreformattedStyle(bool compact) {
  return TextStyle(
    color: _readerInk,
    fontFamily: 'Georgia',
    fontFamilyFallback: _readerFontFallback,
    fontSize: compact ? 16 : 17,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0,
  );
}

String _prepareReaderContent(String value) {
  var text = value
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\u00a0', ' ');

  text = text
      .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<\s*/p\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<\s*/div\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<\s*/h[1-6]\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<\s*/li\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), ' ');

  text = _decodeHtmlEntities(text);

  return text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]+$'), ''))
      .join('\n')
      .replaceAll(RegExp(r'\n{4,}'), '\n\n\n')
      .trim();
}

String _decodeHtmlEntities(String value) {
  final named = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
    '&ndash;': '-',
    '&mdash;': '-',
    '&rsquo;': "'",
    '&lsquo;': "'",
    '&rdquo;': '"',
    '&ldquo;': '"',
  };

  var text = value;
  for (final entry in named.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }

  text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final code = int.tryParse(match.group(1) ?? '');
    if (code == null) {
      return match.group(0) ?? '';
    }
    return _characterForCode(code, fallback: match.group(0) ?? '');
  });

  text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
    final code = int.tryParse(match.group(1) ?? '', radix: 16);
    if (code == null) {
      return match.group(0) ?? '';
    }
    return _characterForCode(code, fallback: match.group(0) ?? '');
  });

  return text;
}

String _characterForCode(int code, {required String fallback}) {
  try {
    return String.fromCharCode(code);
  } on RangeError {
    return fallback;
  }
}

String _collapseInlineWhitespace(String value) {
  return value.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
}

bool _looksLikeSeparator(List<String> lines) {
  if (lines.length > 2) {
    return false;
  }
  final text = lines.join('').replaceAll(' ', '');
  if (text.length < 3) {
    return false;
  }
  return RegExp(r'^[-_=*•]+$').hasMatch(text);
}

bool _looksLikeHeading(List<String> lines, {required bool isFirst}) {
  final text = lines.join(' ').trim();
  if (text.isEmpty || text.length > 180) {
    return false;
  }

  final lower = text.toLowerCase();
  if (lower.startsWith('the project gutenberg ebook') ||
      lower.startsWith('project gutenberg ebook') ||
      text.startsWith('***') ||
      text.endsWith('***')) {
    return true;
  }

  if (RegExp(
    r'^(chapter|chapitre|book|part|volume)\b',
    caseSensitive: false,
  ).hasMatch(text)) {
    return true;
  }

  if (_isAllCapsHeading(text)) {
    return true;
  }

  if (isFirst && lines.length <= 2 && !RegExp(r'[.!?]$').hasMatch(text)) {
    return true;
  }

  return false;
}

bool _isAllCapsHeading(String text) {
  final letters = RegExp(r'[A-Za-z]').allMatches(text).length;
  if (letters < 4) {
    return false;
  }
  return !RegExp(r'[a-z]').hasMatch(text);
}

bool _looksLikeMetadata(List<String> lines) {
  if (lines.length > 5) {
    return false;
  }

  const keys = [
    'title:',
    'author:',
    'release date:',
    'most recently updated:',
    'language:',
    'credits:',
    'produced by',
    'ebook #',
    'www.gutenberg.org',
  ];

  final text = lines.join(' ').trim().toLowerCase();
  return keys.any(text.contains);
}

bool _looksPreformatted(List<String> lines) {
  if (lines.length < 3) {
    return false;
  }

  final hasIndent = lines.any(
    (line) => line.startsWith('  ') || line.startsWith('\t'),
  );
  if (hasIndent) {
    return true;
  }

  final shortLines = lines.where((line) => line.trim().length <= 42).length;
  final sentenceLines = lines
      .where((line) => RegExp(r'[.!?;:,]$').hasMatch(line.trim()))
      .length;

  return shortLines * 4 >= lines.length * 3 && sentenceLines * 2 < lines.length;
}

bool _looksCentered(List<String> lines) {
  if (lines.isEmpty) {
    return false;
  }
  final centered = lines.where((line) {
    final leading = line.length - line.trimLeft().length;
    return leading >= 6;
  }).length;
  return centered * 2 >= lines.length;
}

bool _isGenericFullTextTitle(String title) {
  final normalized = _comparableText(title);
  return normalized == 'texteintegral' ||
      normalized == 'textintegral' ||
      normalized == 'fulltext';
}

bool _similarText(String a, String b) {
  final left = _comparableText(a);
  final right = _comparableText(b);
  return left.isNotEmpty && right.isNotEmpty && left == right;
}

String _comparableText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '').trim();
}

class _EmptyReader extends StatelessWidget {
  const _EmptyReader({required this.book});

  final CatalogBookDetailModel book;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlumoraColors.background,
      appBar: AppBar(
        backgroundColor: PlumoraColors.cards,
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.catalogBookDetailPath(book.id)),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(book.title.isEmpty ? 'Lecture' : book.title),
      ),
      body: const Center(
        child: FigmaEmptyState(
          title: 'Aucun chapitre',
          message: 'Ce livre ne contient pas encore de chapitre lisible.',
          icon: Icons.menu_book_outlined,
        ),
      ),
    );
  }
}
