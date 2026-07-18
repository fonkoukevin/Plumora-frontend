import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../catalog/data/models/catalog_book_model.dart';
import '../../catalog/data/repositories/catalog_repository.dart';
import '../data/models/reading_progress_model.dart';
import '../data/repositories/reading_repository.dart';
import '../data/repositories/review_repository.dart';
import 'review_dialog.dart';

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
  final ScrollController _scrollController = ScrollController();
  int _chapterIndex = 0;
  bool _initialized = false;
  bool _saving = false;
  bool _reviewSubmitting = false;
  double _scrollProgress = 0;
  double _fontScale = 1;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncScrollProgress);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_syncScrollProgress)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(readableBookProvider(widget.bookId));
    final progressAsync = ref.watch(readingProgressProvider(widget.bookId));

    return bookAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.colors.background,
        appBar: _readingBackAppBar(context, widget.bookId),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: context.colors.background,
        appBar: _readingBackAppBar(context, widget.bookId),
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
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(readableBookProvider(widget.bookId)),
                    child: const Text('Réessayer'),
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
        final progress = ((safeIndex + _scrollProgress) / chapters.length)
            .clamp(0.0, 1.0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncScrollProgress();
        });

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: _ReaderAppBar(
            bookTitle: book.title.isEmpty ? 'Livre sans titre' : book.title,
            chapterTitle: chapter.title.isEmpty
                ? 'Chapitre ${safeIndex + 1}'
                : chapter.title,
            onBack: () => returnToPreviousOr(
              context,
              AppRoutes.catalogBookDetailPath(widget.bookId),
            ),
            onAppearance: _showAppearanceSettings,
            onReviews: _openReviewDialog,
          ),
          body: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: _readerBackdrop(context)),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 620;
                      final wide = constraints.maxWidth >= 900;
                      return SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          compact ? 0 : (wide ? 44 : 28),
                          compact ? 0 : 30,
                          compact ? 0 : (wide ? 44 : 28),
                          compact ? 28 : 52,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: DecoratedBox(
                              key: const ValueKey('reader_paper'),
                              decoration: BoxDecoration(
                                color: _readerPaper(context),
                                borderRadius: compact
                                    ? BorderRadius.zero
                                    : BorderRadius.circular(28),
                                border: compact
                                    ? null
                                    : Border.all(
                                        color: context.colors.border.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                boxShadow: compact
                                    ? const []
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? 0.22
                                                : 0.07,
                                          ),
                                          blurRadius: 34,
                                          offset: const Offset(0, 16),
                                        ),
                                      ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  compact ? 24 : 68,
                                  compact ? 34 : 58,
                                  compact ? 24 : 68,
                                  compact ? 54 : 76,
                                ),
                                child: SelectionArea(
                                  child: _ReaderText(
                                    chapter: chapter,
                                    compact: compact,
                                    fontScale: _fontScale,
                                    chapterNumber: safeIndex + 1,
                                    readingMinutes: _readingMinutes(
                                      chapter.content,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              _ReaderNavigationDock(
                chapterNumber: safeIndex + 1,
                chapterCount: chapters.length,
                progress: progress,
                saving: _saving,
                error: _saveError,
                canGoPrevious: safeIndex > 0 && !_saving,
                isLastChapter: safeIndex == chapters.length - 1,
                onPrevious: () => _goTo(chapters, safeIndex - 1),
                onNext: _saving
                    ? null
                    : () {
                        if (safeIndex == chapters.length - 1) {
                          _finish();
                        } else {
                          _goTo(chapters, safeIndex + 1);
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  void _syncScrollProgress() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    final maxExtent = _scrollController.position.maxScrollExtent;
    final next = maxExtent <= 0
        ? 1.0
        : (_scrollController.offset / maxExtent).clamp(0.0, 1.0);
    if ((next - _scrollProgress).abs() < 0.005) {
      return;
    }

    setState(() => _scrollProgress = next);
  }

  Future<void> _showAppearanceSettings() async {
    final selected = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.cards,
      builder: (context) => _ReadingAppearanceSheet(selectedScale: _fontScale),
    );
    if (selected != null && mounted) {
      setState(() => _fontScale = selected);
    }
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
      _scrollProgress = 0;
      _saving = true;
      _saveError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
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
        context.go(AppRoutes.catalogBookDetailPath(widget.bookId));
      }
    } catch (error) {
      setState(() => _saveError = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openReviewDialog() async {
    if (_reviewSubmitting) {
      return;
    }

    final request = await showPlumoraReviewDialog(context);
    if (request == null || !mounted) {
      return;
    }

    setState(() => _reviewSubmitting = true);
    try {
      await ref
          .read(reviewRepositoryProvider)
          .createReview(widget.bookId, request);
      ref.invalidate(bookReviewsProvider(widget.bookId));
      ref.invalidate(myReviewsProvider);
      ref.invalidate(myReviewForBookProvider(widget.bookId));
      ref.invalidate(catalogBookDetailProvider(widget.bookId));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avis publié.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _reviewSubmitting = false);
      }
    }
  }
}

class _ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ReaderAppBar({
    required this.bookTitle,
    required this.chapterTitle,
    required this.onBack,
    required this.onAppearance,
    required this.onReviews,
  });

  final String bookTitle;
  final String chapterTitle;
  final VoidCallback onBack;
  final VoidCallback onAppearance;
  final VoidCallback onReviews;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return AppBar(
      toolbarHeight: 70,
      backgroundColor: _readerBackdrop(context),
      foregroundColor: context.colors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(
        bottom: BorderSide(
          color: context.colors.border.withValues(alpha: 0.72),
        ),
      ),
      leadingWidth: compact ? 98 : 112,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: FigmaBackButton(label: 'Retour', onTap: onBack),
      ),
      titleSpacing: 4,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bookTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontFamily: 'Georgia',
              fontFamilyFallback: _readerFontFallback,
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            chapterTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        _ReaderHeaderAction(
          tooltip: 'Confort de lecture',
          icon: Icons.text_fields_rounded,
          onTap: onAppearance,
        ),
        _ReaderHeaderAction(
          tooltip: 'Donner mon avis',
          icon: Icons.star_border_rounded,
          onTap: onReviews,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _ReaderHeaderAction extends StatelessWidget {
  const _ReaderHeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        style: IconButton.styleFrom(
          foregroundColor: context.colors.textPrimary,
          backgroundColor: context.colors.primary.withValues(alpha: 0.08),
          minimumSize: const Size(40, 40),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

class _ReaderNavigationDock extends StatelessWidget {
  const _ReaderNavigationDock({
    required this.chapterNumber,
    required this.chapterCount,
    required this.progress,
    required this.saving,
    required this.canGoPrevious,
    required this.isLastChapter,
    required this.onPrevious,
    required this.onNext,
    this.error,
  });

  final int chapterNumber;
  final int chapterCount;
  final double progress;
  final bool saving;
  final bool canGoPrevious;
  final bool isLastChapter;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: _readerBackdrop(context)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _readerPaper(context),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: context.colors.border.withValues(alpha: 0.8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.09),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 680;
                    final progressPanel = _ReaderProgressPanel(
                      chapterNumber: chapterNumber,
                      chapterCount: chapterCount,
                      progress: progress,
                      saving: saving,
                    );
                    final previous = _ReaderDockButton(
                      label: 'Précédent',
                      icon: Icons.chevron_left_rounded,
                      onTap: canGoPrevious ? onPrevious : null,
                    );
                    final next = _ReaderDockButton(
                      label: isLastChapter ? 'Terminer' : 'Suivant',
                      icon: saving ? null : Icons.chevron_right_rounded,
                      trailingIcon: true,
                      primary: true,
                      loading: saving,
                      onTap: onNext,
                    );

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (compact) ...[
                          progressPanel,
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: previous),
                              const SizedBox(width: 12),
                              Expanded(child: next),
                            ],
                          ),
                        ] else
                          Row(
                            children: [
                              SizedBox(width: 142, child: previous),
                              const SizedBox(width: 22),
                              Expanded(child: progressPanel),
                              const SizedBox(width: 22),
                              SizedBox(width: 142, child: next),
                            ],
                          ),
                        if (error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            error!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.colors.destructive,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderProgressPanel extends StatelessWidget {
  const _ReaderProgressPanel({
    required this.chapterNumber,
    required this.chapterCount,
    required this.progress,
    required this.saving,
  });

  final int chapterNumber;
  final int chapterCount;
  final double progress;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progression de lecture ${(progress * 100).round()} pour cent',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Chapitre $chapterNumber sur $chapterCount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  saving ? 'Sauvegarde...' : '${(progress * 100).round()} %',
                  key: ValueKey(saving),
                  style: TextStyle(
                    color: context.colors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: context.colors.primary,
              backgroundColor: context.colors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderDockButton extends StatelessWidget {
  const _ReaderDockButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.trailingIcon = false,
    this.primary = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool trailingIcon;
  final bool primary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final iconWidget = loading
        ? const SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon == null
        ? null
        : Icon(icon, size: 19);
    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!trailingIcon && iconWidget != null) ...[
            iconWidget,
            const SizedBox(width: 6),
          ],
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (trailingIcon && iconWidget != null) ...[
            const SizedBox(width: 6),
            iconWidget,
          ],
        ],
      ),
    );

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    if (primary) {
      return FilledButton(onPressed: onTap, style: style, child: content);
    }
    return OutlinedButton(onPressed: onTap, style: style, child: content);
  }
}

class _ReadingAppearanceSheet extends StatelessWidget {
  const _ReadingAppearanceSheet({required this.selectedScale});

  final double selectedScale;

  @override
  Widget build(BuildContext context) {
    const choices = [
      (scale: 0.9, symbol: 'A−', label: 'Petit'),
      (scale: 1.0, symbol: 'A', label: 'Confort'),
      (scale: 1.12, symbol: 'A+', label: 'Grand'),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confort de lecture',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choisis la taille de texte qui te convient le mieux.',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    for (var index = 0; index < choices.length; index++) ...[
                      if (index > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _ReadingScaleChoice(
                          symbol: choices[index].symbol,
                          label: choices[index].label,
                          selected:
                              (selectedScale - choices[index].scale).abs() <
                              0.01,
                          onTap: () =>
                              Navigator.of(context).pop(choices[index].scale),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingScaleChoice extends StatelessWidget {
  const _ReadingScaleChoice({
    required this.symbol,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String symbol;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primary.withValues(alpha: 0.12)
              : context.colors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              symbol,
              style: TextStyle(
                color: selected
                    ? context.colors.primary
                    : context.colors.textPrimary,
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderText extends StatelessWidget {
  const _ReaderText({
    required this.chapter,
    required this.compact,
    required this.fontScale,
    required this.chapterNumber,
    required this.readingMinutes,
  });

  final CatalogChapterModel chapter;
  final bool compact;
  final double fontScale;
  final int chapterNumber;
  final int readingMinutes;

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
        Center(
          child: Text(
            'CHAPITRE $chapterNumber  •  $readingMinutes MIN DE LECTURE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (shouldShowChapterTitle) ...[
          Center(
            child: Text(
              chapter.title,
              textAlign: TextAlign.center,
              style: _readerHeadingStyle(context, compact, fontScale),
            ),
          ),
          const SizedBox(height: 22),
        ],
        const _ReaderOrnament(),
        const SizedBox(height: 34),
        if (blocks.isEmpty)
          Text(
            'Ce chapitre ne contient pas encore de texte.',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: (compact ? 17 : 18) * fontScale,
              height: 1.65,
            ),
          )
        else
          for (final block in blocks)
            _ReaderBlockView(
              block: block,
              compact: compact,
              fontScale: fontScale,
            ),
      ],
    );
  }
}

class _ReaderBlockView extends StatelessWidget {
  const _ReaderBlockView({
    required this.block,
    required this.compact,
    required this.fontScale,
  });

  final _ReaderBlock block;
  final bool compact;
  final double fontScale;

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
              style: _readerHeadingStyle(context, compact, fontScale),
            ),
          ),
        );
      case _ReaderBlockType.metadata:
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text(
            block.text,
            textAlign: block.center ? TextAlign.center : TextAlign.left,
            style: _readerMetadataStyle(context, compact, fontScale),
          ),
        );
      case _ReaderBlockType.preformatted:
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              block.text,
              style: _readerPreformattedStyle(context, compact, fontScale),
            ),
          ),
        );
      case _ReaderBlockType.separator:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Center(
            child: SizedBox(
              width: compact ? 112 : 168,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: context.colors.textPrimary.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      case _ReaderBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Text(
            block.text,
            textAlign: compact ? TextAlign.left : TextAlign.justify,
            style: _readerParagraphStyle(context, compact, fontScale),
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

class _ReaderOrnament extends StatelessWidget {
  const _ReaderOrnament();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 116,
        child: Row(
          children: [
            Expanded(
              child: Divider(
                color: context.colors.primary.withValues(alpha: 0.32),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 17,
                color: context.colors.primary,
              ),
            ),
            Expanded(
              child: Divider(
                color: context.colors.primary.withValues(alpha: 0.32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _readerHeadingStyle(
  BuildContext context,
  bool compact,
  double fontScale,
) {
  return TextStyle(
    color: context.colors.textPrimary,
    fontFamily: 'Georgia',
    fontFamilyFallback: _readerFontFallback,
    fontSize: (compact ? 25 : 31) * fontScale,
    fontWeight: FontWeight.w700,
    height: 1.24,
    letterSpacing: -0.35,
  );
}

TextStyle _readerParagraphStyle(
  BuildContext context,
  bool compact,
  double fontScale,
) {
  return TextStyle(
    color: context.colors.textPrimary,
    fontFamily: 'Georgia',
    fontFamilyFallback: _readerFontFallback,
    fontSize: (compact ? 18 : 19.5) * fontScale,
    fontWeight: FontWeight.w400,
    height: compact ? 1.66 : 1.72,
    letterSpacing: 0.05,
  );
}

TextStyle _readerMetadataStyle(
  BuildContext context,
  bool compact,
  double fontScale,
) {
  return TextStyle(
    color: context.colors.textSecondary,
    fontFamily: 'Georgia',
    fontFamilyFallback: _readerFontFallback,
    fontSize: (compact ? 15.5 : 16.5) * fontScale,
    fontWeight: FontWeight.w400,
    height: 1.58,
    letterSpacing: 0,
  );
}

TextStyle _readerPreformattedStyle(
  BuildContext context,
  bool compact,
  double fontScale,
) {
  return TextStyle(
    color: context.colors.textPrimary,
    fontFamily: 'Georgia',
    fontFamilyFallback: _readerFontFallback,
    fontSize: (compact ? 16 : 17) * fontScale,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0,
  );
}

Color _readerBackdrop(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return context.colors.background;
  }
  return const Color(0xFFF5F1EA);
}

Color _readerPaper(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return Color.alphaBlend(
      context.colors.primary.withValues(alpha: 0.025),
      context.colors.cards,
    );
  }
  return const Color(0xFFFFFDF9);
}

int _readingMinutes(String content) {
  final prepared = _prepareReaderContent(content);
  if (prepared.isEmpty) {
    return 1;
  }
  final words = RegExp(r'\S+').allMatches(prepared).length;
  final minutes = (words / 220).ceil();
  return minutes < 1 ? 1 : minutes;
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
  text = _stripGutenbergBoilerplate(text);

  return text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]+$'), ''))
      .join('\n')
      .replaceAll(RegExp(r'\n{4,}'), '\n\n\n')
      .trim();
}

String _stripGutenbergBoilerplate(String value) {
  var text = value;
  final startMarker = RegExp(
    r'^\s*\*{0,3}\s*START OF (?:THE|THIS) PROJECT GUTENBERG EBOOK[^\n]*$',
    caseSensitive: false,
    multiLine: true,
  ).firstMatch(text);
  if (startMarker != null) {
    text = text.substring(startMarker.end);
  }

  final endMarker = RegExp(
    r'^\s*\*{0,3}\s*END OF (?:THE|THIS) PROJECT GUTENBERG EBOOK[^\n]*$',
    caseSensitive: false,
    multiLine: true,
  ).firstMatch(text);
  if (endMarker != null) {
    text = text.substring(0, endMarker.start);
  }

  return text.trim();
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
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.cards,
        leadingWidth: 104,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: FigmaBackButton(
            label: 'Retour',
            onTap: () => returnToPreviousOr(
              context,
              AppRoutes.catalogBookDetailPath(book.id),
            ),
          ),
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

PreferredSizeWidget _readingBackAppBar(BuildContext context, String bookId) {
  return AppBar(
    backgroundColor: context.colors.cards,
    leadingWidth: 104,
    leading: Padding(
      padding: const EdgeInsets.only(left: 12),
      child: FigmaBackButton(
        label: 'Retour',
        onTap: () => returnToPreviousOr(
          context,
          AppRoutes.catalogBookDetailPath(bookId),
        ),
      ),
    ),
  );
}
