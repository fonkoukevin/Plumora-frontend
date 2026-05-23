import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../catalog/data/models/catalog_book_model.dart';
import '../data/models/reading_progress_model.dart';
import '../data/repositories/reading_repository.dart';

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({required this.bookId, super.key});

  final String bookId;

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  int _chapterIndex = 0;
  bool _initializedFromProgress = false;
  bool _createdInitialProgress = false;
  bool _isSavingProgress = false;
  bool _darkMode = false;
  double _fontSize = 18;
  String? _progressError;

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(readableBookProvider(widget.bookId));
    final progressAsync = ref.watch(readingProgressProvider(widget.bookId));

    return bookAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => _ReadingError(
        title: 'Lecture indisponible',
        message: AppError.messageFor(error),
        onRetry: () => ref.invalidate(readableBookProvider(widget.bookId)),
      ),
      data: (book) {
        final chapters = _chaptersFor(book);
        if (chapters.isEmpty) {
          return const _ReadingError(
            title: 'Aucun contenu',
            message: "Ce livre n'a pas encore de chapitre lisible.",
          );
        }

        progressAsync.whenData((progress) {
          if (!_initializedFromProgress && progress != null) {
            _chapterIndex = progress.chapterIndex.clamp(0, chapters.length - 1);
            _initializedFromProgress = true;
          }
          if (!_createdInitialProgress && progress == null) {
            _createdInitialProgress = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _saveProgress(chapters, _chapterIndex, showSaving: false);
              }
            });
          }
        });

        final selected = chapters[_chapterIndex.clamp(0, chapters.length - 1)];
        final progressValue = (_chapterIndex + 1) / chapters.length;

        return Theme(
          data: _darkMode
              ? Theme.of(context).copyWith(
                  scaffoldBackgroundColor: PlumoraColors.darkBackground,
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    surface: PlumoraColors.darkBackground,
                    onSurface: PlumoraColors.background,
                  ),
                )
              : Theme.of(context),
          child: Scaffold(
            backgroundColor: _darkMode
                ? PlumoraColors.darkBackground
                : PlumoraColors.background,
            appBar: AppBar(
              backgroundColor: _darkMode
                  ? PlumoraColors.darkSurface
                  : PlumoraColors.cards,
              foregroundColor: _darkMode
                  ? PlumoraColors.background
                  : PlumoraColors.textPrimary,
              leading: IconButton(
                tooltip: 'Retour',
                onPressed: () => context.go(AppRoutes.library),
                icon: const Icon(Icons.arrow_back),
              ),
              title: Column(
                children: [
                  Text(
                    book.title.isEmpty ? 'Livre sans titre' : book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    selected.title.isEmpty
                        ? 'Chapitre ${_chapterIndex + 1}'
                        : selected.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _darkMode
                          ? const Color(0xFFD5CAB8)
                          : PlumoraColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: _darkMode ? 'Mode clair' : 'Mode sombre',
                  onPressed: () => setState(() => _darkMode = !_darkMode),
                  icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.title.isEmpty
                                  ? 'Chapitre ${_chapterIndex + 1}'
                                  : selected.title,
                              style: TextStyle(
                                color: _darkMode
                                    ? PlumoraColors.background
                                    : PlumoraColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SelectableText(
                              selected.content.isEmpty
                                  ? 'Ce chapitre est vide.'
                                  : selected.content,
                              style: TextStyle(
                                color: _darkMode
                                    ? const Color(0xFFEFE6DA)
                                    : PlumoraColors.textPrimary,
                                fontSize: _fontSize,
                                height: 1.75,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _ReaderFooter(
                  chapterIndex: _chapterIndex,
                  chapterCount: chapters.length,
                  progress: progressValue,
                  isSaving: _isSavingProgress,
                  progressError: _progressError,
                  fontSize: _fontSize,
                  darkMode: _darkMode,
                  onDecreaseText: () => setState(() {
                    _fontSize = (_fontSize - 1).clamp(14, 26).toDouble();
                  }),
                  onIncreaseText: () => setState(() {
                    _fontSize = (_fontSize + 1).clamp(14, 26).toDouble();
                  }),
                  onPrevious: _chapterIndex == 0
                      ? null
                      : () => _goToChapter(chapters, _chapterIndex - 1),
                  onNext: () {
                    if (_chapterIndex == chapters.length - 1) {
                      _finishBook();
                    } else {
                      _goToChapter(chapters, _chapterIndex + 1);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<CatalogChapterModel> _chaptersFor(CatalogBookDetailModel book) {
    if (book.chapters.isNotEmpty) {
      return book.chapters;
    }

    if (book.description.isNotEmpty) {
      return [
        CatalogChapterModel(
          id: book.id,
          title: book.title,
          content: book.description,
          order: 1,
        ),
      ];
    }

    return const [];
  }

  Future<void> _goToChapter(
    List<CatalogChapterModel> chapters,
    int nextIndex,
  ) async {
    setState(() {
      _chapterIndex = nextIndex.clamp(0, chapters.length - 1);
      _progressError = null;
    });

    await _saveProgress(chapters, _chapterIndex);
  }

  Future<void> _saveProgress(
    List<CatalogChapterModel> chapters,
    int chapterIndex, {
    bool showSaving = true,
  }) async {
    if (showSaving) {
      setState(() {
        _isSavingProgress = true;
        _progressError = null;
      });
    }

    final safeIndex = chapterIndex.clamp(0, chapters.length - 1);
    final chapter = chapters[safeIndex];
    final progress = (safeIndex + 1) / chapters.length;

    try {
      await ref
          .read(readingRepositoryProvider)
          .saveProgress(
            widget.bookId,
            ReadingProgressUpdateRequest(
              bookId: widget.bookId,
              chapterId: chapter.id,
              chapterIndex: safeIndex,
              progress: progress,
              finished: false,
            ),
          );
      ref.invalidate(readingProgressProvider(widget.bookId));
      ref.invalidate(myReadingProgressProvider);
    } catch (error) {
      setState(() => _progressError = AppError.messageFor(error));
    } finally {
      if (mounted && showSaving) {
        setState(() => _isSavingProgress = false);
      }
    }
  }

  Future<void> _finishBook() async {
    setState(() {
      _isSavingProgress = true;
      _progressError = null;
    });

    try {
      await ref.read(readingRepositoryProvider).finishProgress(widget.bookId);
      ref.invalidate(readingProgressProvider(widget.bookId));
      ref.invalidate(myReadingProgressProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lecture terminée.')));
      }
    } catch (error) {
      setState(() => _progressError = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isSavingProgress = false);
      }
    }
  }
}

class _ReaderFooter extends StatelessWidget {
  const _ReaderFooter({
    required this.chapterIndex,
    required this.chapterCount,
    required this.progress,
    required this.isSaving,
    required this.fontSize,
    required this.darkMode,
    required this.onDecreaseText,
    required this.onIncreaseText,
    required this.onPrevious,
    required this.onNext,
    this.progressError,
  });

  final int chapterIndex;
  final int chapterCount;
  final double progress;
  final bool isSaving;
  final double fontSize;
  final bool darkMode;
  final VoidCallback onDecreaseText;
  final VoidCallback onIncreaseText;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final String? progressError;

  @override
  Widget build(BuildContext context) {
    final surface = darkMode ? PlumoraColors.darkSurface : PlumoraColors.cards;
    final text = darkMode
        ? PlumoraColors.background
        : PlumoraColors.textPrimary;
    final secondary = darkMode
        ? const Color(0xFFD5CAB8)
        : PlumoraColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(
            color: darkMode ? const Color(0xFF40372D) : PlumoraColors.border,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Chapitre ${chapterIndex + 1} sur $chapterCount',
                    style: TextStyle(color: secondary, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress.clamp(0, 1) * 100).round()}% lu',
                    style: TextStyle(
                      color: text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: progress.clamp(0, 1),
                  backgroundColor: darkMode
                      ? const Color(0xFF40372D)
                      : PlumoraColors.muted,
                  color: PlumoraColors.primary,
                ),
              ),
              if (progressError != null) ...[
                const SizedBox(height: 8),
                Text(
                  progressError!,
                  style: const TextStyle(
                    color: PlumoraColors.destructive,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.chevron_left, size: 18),
                    label: const Text('Précédent'),
                  ),
                  SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 14, label: Text('A-')),
                      ButtonSegment(value: 18, label: Text('A')),
                      ButtonSegment(value: 22, label: Text('A+')),
                    ],
                    selected: {
                      fontSize < 17
                          ? 14
                          : fontSize < 21
                          ? 18
                          : 22,
                    },
                    onSelectionChanged: (values) {
                      final value = values.first;
                      if (value < fontSize) {
                        onDecreaseText();
                      } else if (value > fontSize) {
                        onIncreaseText();
                      }
                    },
                  ),
                  FilledButton.icon(
                    onPressed: isSaving ? null : onNext,
                    icon: isSaving
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right, size: 18),
                    label: Text(
                      chapterIndex == chapterCount - 1 ? 'Terminer' : 'Suivant',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingError extends StatelessWidget {
  const _ReadingError({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: PlumoraCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: PlumoraColors.textSecondary),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
