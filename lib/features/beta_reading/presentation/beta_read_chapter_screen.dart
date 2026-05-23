import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../data/models/beta_shared_chapter_model.dart';
import '../data/repositories/beta_reading_repository.dart';
import 'create_beta_comment_bottom_sheet.dart';

class BetaReadChapterScreen extends ConsumerStatefulWidget {
  const BetaReadChapterScreen({
    required this.campaignId,
    required this.chapterId,
    this.bookId,
    this.invitationId,
    super.key,
  });

  final String campaignId;
  final String chapterId;
  final String? bookId;
  final String? invitationId;

  @override
  ConsumerState<BetaReadChapterScreen> createState() =>
      _BetaReadChapterScreenState();
}

class _BetaReadChapterScreenState extends ConsumerState<BetaReadChapterScreen> {
  double _fontSize = 18;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(
      betaSharedChaptersProvider(widget.campaignId),
    );

    final background = _darkMode
        ? const Color(0xFF1F1A15)
        : PlumoraColors.background;
    final cardColor = _darkMode ? const Color(0xFF2B241B) : PlumoraColors.cards;
    final textColor = _darkMode
        ? const Color(0xFFF8F4EE)
        : PlumoraColors.textPrimary;
    final mutedColor = _darkMode
        ? const Color(0xFFCDBFA8)
        : PlumoraColors.textSecondary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: chaptersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ReaderError(
            message: AppError.messageFor(error),
            onRetry: () =>
                ref.invalidate(betaSharedChaptersProvider(widget.campaignId)),
          ),
          data: (chapters) {
            final chapter = chapters.cast<BetaSharedChapterModel?>().firstWhere(
              (item) => item?.id == widget.chapterId,
              orElse: () => chapters.isEmpty ? null : chapters.first,
            );

            if (chapter == null) {
              return _ReaderError(
                message: 'Ce chapitre bêta est introuvable.',
                onRetry: () => ref.invalidate(
                  betaSharedChaptersProvider(widget.campaignId),
                ),
              );
            }

            final index = chapters.indexWhere((item) => item.id == chapter.id);
            final previous = index > 0 ? chapters[index - 1] : null;
            final next = index >= 0 && index < chapters.length - 1
                ? chapters[index + 1]
                : null;

            return Column(
              children: [
                _ReaderHeader(
                  chapter: chapter,
                  index: index,
                  count: chapters.length,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  cardColor: cardColor,
                  darkMode: _darkMode,
                  onBack: () => context.go(
                    AppRoutes.betaChaptersPath(
                      widget.campaignId,
                      invitationId: widget.invitationId,
                      bookId: widget.bookId,
                    ),
                  ),
                  onComment: () => _openCommentSheet(chapter),
                  onToggleDarkMode: () =>
                      setState(() => _darkMode = !_darkMode),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: SelectableText(
                          _chapterContent(chapter),
                          style: TextStyle(
                            color: textColor,
                            fontSize: _fontSize,
                            height: 1.75,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _ReaderFooter(
                  previous: previous,
                  next: next,
                  fontSize: _fontSize,
                  cardColor: cardColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  onFontChanged: (value) => setState(() => _fontSize = value),
                  onPrevious: previous == null
                      ? null
                      : () => _goToChapter(previous),
                  onNext: next == null ? null : () => _goToChapter(next),
                  onComment: () => _openCommentSheet(chapter),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _goToChapter(BetaSharedChapterModel chapter) {
    context.go(
      AppRoutes.betaReadChapterPath(
        widget.campaignId,
        chapter.id,
        bookId: widget.bookId,
        invitationId: widget.invitationId,
      ),
    );
  }

  Future<void> _openCommentSheet(BetaSharedChapterModel chapter) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PlumoraColors.cards,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return CreateBetaCommentBottomSheet(
          bookId: widget.bookId ?? chapter.bookId,
          campaignId: widget.campaignId,
          chapterId: chapter.id,
          defaultSelectedText: _defaultSelectedText(chapter.content),
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Retour bêta envoyé.')));
    }
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({
    required this.chapter,
    required this.index,
    required this.count,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    required this.darkMode,
    required this.onBack,
    required this.onComment,
    required this.onToggleDarkMode,
  });

  final BetaSharedChapterModel chapter;
  final int index;
  final int count;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final bool darkMode;
  final VoidCallback onBack;
  final VoidCallback onComment;
  final VoidCallback onToggleDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cardColor,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back, color: mutedColor),
                tooltip: 'Retour',
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      chapter.title.isEmpty ? 'Chapitre bêta' : chapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Chapitre ${index + 1} sur $count',
                      style: TextStyle(color: mutedColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggleDarkMode,
                icon: Icon(
                  darkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: mutedColor,
                ),
                tooltip: 'Mode sombre',
              ),
              FilledButton.icon(
                onPressed: onComment,
                icon: const Icon(Icons.chat_bubble_outline, size: 17),
                label: const Text('Commenter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderFooter extends StatelessWidget {
  const _ReaderFooter({
    required this.previous,
    required this.next,
    required this.fontSize,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.onFontChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onComment,
  });

  final BetaSharedChapterModel? previous;
  final BetaSharedChapterModel? next;
  final double fontSize;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final ValueChanged<double> onFontChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cardColor,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.format_size, color: mutedColor, size: 18),
                  SizedBox(
                    width: 150,
                    child: Slider(
                      value: fontSize,
                      min: 15,
                      max: 24,
                      divisions: 9,
                      label: fontSize.round().toString(),
                      onChanged: onFontChanged,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: onPrevious,
                    child: const Text('Chapitre précédent'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onNext,
                    child: const Text('Chapitre suivant'),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onComment,
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip: 'Commenter',
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

class _ReaderError extends StatelessWidget {
  const _ReaderError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PlumoraColors.cards,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PlumoraColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lecture indisponible',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: PlumoraColors.textSecondary),
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ),
        ),
      ),
    );
  }
}

String _chapterContent(BetaSharedChapterModel chapter) {
  final content = chapter.content.trim();
  if (content.isEmpty) {
    return 'Le contenu de ce chapitre n’est pas encore disponible.';
  }

  return content;
}

String _defaultSelectedText(String content) {
  final normalized = content.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) {
    return '';
  }
  if (normalized.length <= 140) {
    return normalized;
  }

  return '${normalized.substring(0, 140)}...';
}
