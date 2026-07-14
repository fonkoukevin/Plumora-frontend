import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../beta_reading/data/models/beta_comment_model.dart';
import '../../beta_reading/data/repositories/beta_reading_repository.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/models/chapter_model.dart';
import '../../book/data/repositories/book_repository.dart';
import '../../book/data/repositories/chapter_repository.dart';
import '../../book/presentation/widgets/book_status_badge.dart';
import '../data/writing_cache_invalidator.dart';

class PublishBookScreen extends ConsumerStatefulWidget {
  const PublishBookScreen({required this.bookId, super.key});

  final String bookId;

  @override
  ConsumerState<PublishBookScreen> createState() => _PublishBookScreenState();
}

class _PublishBookScreenState extends ConsumerState<PublishBookScreen> {
  bool _isPublishing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(authorBookProvider(widget.bookId));
    final chaptersAsync = ref.watch(bookChaptersProvider(widget.bookId));
    final betaCommentsAsync = ref.watch(
      betaCommentsForBookProvider(widget.bookId),
    );

    return FigmaScreen(
      maxWidth: 840,
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigmaBackButton(
            label: 'Retour',
            onTap: () =>
                context.go(AppRoutes.authorBookDetailPath(widget.bookId)),
          ),
          const SizedBox(height: 18),
          Text(
            'Preparer la publication',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'La publication est directe dans le catalogue Plumora.',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 24),
          bookAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _ErrorPanel(
              message: AppError.messageFor(error),
              onRetry: () => ref.invalidate(authorBookProvider(widget.bookId)),
            ),
            data: (book) => chaptersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _ErrorPanel(
                message: AppError.messageFor(error),
                onRetry: () =>
                    ref.invalidate(bookChaptersProvider(widget.bookId)),
              ),
              data: (chapters) => _PublishContent(
                book: book,
                chapters: chapters,
                betaCommentsAsync: betaCommentsAsync,
                isPublishing: _isPublishing,
                error: _error,
                onPublish: _publish,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publish() async {
    setState(() {
      _isPublishing = true;
      _error = null;
    });

    try {
      final published = await ref
          .read(bookRepositoryProvider)
          .publishBook(widget.bookId);
      ref.invalidate(authorBookProvider(widget.bookId));
      ref.invalidate(authorBookProvider(published.id));
      ref.invalidate(myBooksProvider);
      ref.invalidate(bookChaptersProvider(widget.bookId));
      invalidateBookPublicationCaches(ref, published.id);
      if (mounted) {
        context.go(AppRoutes.authorBookDetailPath(published.id));
      }
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }
}

class _PublishContent extends StatelessWidget {
  const _PublishContent({
    required this.book,
    required this.chapters,
    required this.betaCommentsAsync,
    required this.isPublishing,
    required this.onPublish,
    this.error,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final AsyncValue<List<BetaCommentModel>> betaCommentsAsync;
  final bool isPublishing;
  final VoidCallback onPublish;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final betaFeedbackResolved = betaCommentsAsync.maybeWhen(
      data: (comments) => comments.every(
        (comment) =>
            comment.status == BetaCommentStatus.resolved ||
            comment.status == BetaCommentStatus.ignored,
      ),
      orElse: () => false,
    );

    final checklist = [
      _CheckItem('Titre renseigne', book.title.trim().isNotEmpty),
      _CheckItem('Resume renseigne', book.description.trim().isNotEmpty),
      _CheckItem(
        'Categorie / genre renseigne',
        (book.genre ?? '').trim().isNotEmpty,
      ),
      _CheckItem('Au moins un chapitre', chapters.isNotEmpty),
      _CheckItem(
        'Chapitres avec contenu',
        chapters.isNotEmpty &&
            chapters.every((chapter) => chapter.content.trim().isNotEmpty),
      ),
      _CheckItem(
        'Retours beta traites (optionnel)',
        betaFeedbackResolved,
        required: false,
      ),
      _CheckItem('Livre non archive', !book.isArchived),
    ];
    final completed = checklist.where((item) => item.done).length;
    final progress = completed / checklist.length;
    final canPublish =
        checklist.where((item) => item.required).every((item) => item.done) &&
        book.canPublish;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FigmaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title.isEmpty ? 'Livre sans titre' : book.title,
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.status.shortFrenchLabel,
                          style: TextStyle(color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: context.colors.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FigmaProgressBar(value: progress, height: 10),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FigmaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Checklist de publication',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              for (final item in checklist) ...[
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: item.done
                        ? context.colors.success.withValues(alpha: 0.08)
                        : context.colors.muted.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: item.done
                            ? context.colors.success
                            : context.colors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: item.done
                                ? context.colors.textPrimary
                                : context.colors.textSecondary,
                            fontWeight: item.done
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        FigmaCard(
          color: context.colors.primary.withValues(alpha: 0.06),
          borderColor: context.colors.primary.withValues(alpha: 0.18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: context.colors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Paiements, royalties, abonnements et validation admin ne sont pas inclus dans le MVP actuel.",
                  style: TextStyle(height: 1.4),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 14),
          Text(
            error!,
            style: TextStyle(
              color: context.colors.destructive,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isPublishing
                    ? null
                    : () => context.go(AppRoutes.authorBookDetailPath(book.id)),
                child: const Text('Continuer plus tard'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: FilledButton.icon(
                onPressed: canPublish && !isPublishing ? onPublish : null,
                icon: isPublishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(isPublishing ? 'Publication...' : 'Publier'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckItem {
  const _CheckItem(this.label, this.done, {this.required = true});

  final String label;
  final bool done;
  final bool required;
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Publication indisponible',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: context.colors.textSecondary)),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Reessayer')),
        ],
      ),
    );
  }
}
