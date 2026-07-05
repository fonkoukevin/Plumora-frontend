import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../data/models/beta_comment_model.dart';
import '../data/models/beta_shared_chapter_model.dart';
import '../data/repositories/beta_reading_repository.dart';
import 'create_beta_comment_bottom_sheet.dart';

class BetaReadChapterScreen extends ConsumerWidget {
  const BetaReadChapterScreen({
    required this.campaignId,
    required this.chapterId,
    this.invitationId,
    this.bookId,
    super.key,
  });

  final String campaignId;
  final String chapterId;
  final String? invitationId;
  final String? bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(betaSharedChaptersProvider(campaignId));
    final commentsAsync = ref.watch(
      betaCommentsForCampaignProvider(campaignId),
    );

    return chaptersAsync.when(
      loading: () => const Scaffold(
        backgroundColor: PlumoraColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ErrorScaffold(
        title: 'Chapitre indisponible',
        message: AppError.messageFor(error),
        onRetry: () => ref.invalidate(betaSharedChaptersProvider(campaignId)),
      ),
      data: (chapters) {
        final sorted = [...chapters]
          ..sort((a, b) {
            final orderCompare = a.order.compareTo(b.order);
            return orderCompare == 0
                ? a.title.compareTo(b.title)
                : orderCompare;
          });
        final index = sorted.indexWhere((chapter) => chapter.id == chapterId);
        if (index < 0) {
          return _ErrorScaffold(
            title: 'Chapitre introuvable',
            message: "Ce chapitre n'est pas partage dans cette campagne.",
            onRetry: () =>
                ref.invalidate(betaSharedChaptersProvider(campaignId)),
          );
        }

        final chapter = sorted[index];
        final effectiveBookId =
            (chapter.bookId.isEmpty ? bookId : chapter.bookId) ?? '';

        return Scaffold(
          backgroundColor: PlumoraColors.background,
          appBar: AppBar(
            backgroundColor: PlumoraColors.cards,
            leading: IconButton(
              onPressed: () => context.go(
                AppRoutes.betaChaptersPath(
                  campaignId,
                  invitationId: invitationId,
                  bookId: effectiveBookId,
                ),
              ),
              icon: const Icon(Icons.arrow_back),
            ),
            title: Column(
              children: [
                const Text(
                  'Beta-lecture',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                Text(
                  chapter.title.isEmpty
                      ? 'Chapitre ${index + 1}'
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
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  onPressed: () =>
                      _openCommentSheet(context, ref, chapter, effectiveBookId),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Commenter'),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 28,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ChapterText(chapter: chapter),
                          const SizedBox(height: 26),
                          _CommentsBlock(
                            commentsAsync: commentsAsync,
                            chapterId: chapter.id,
                            onRetry: () => ref.invalidate(
                              betaCommentsForCampaignProvider(campaignId),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                color: PlumoraColors.cards,
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Text(
                        'Chapitre ${index + 1} sur ${sorted.length}',
                        style: const TextStyle(
                          color: PlumoraColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: index == 0
                            ? null
                            : () => context.go(
                                AppRoutes.betaReadChapterPath(
                                  campaignId,
                                  sorted[index - 1].id,
                                  invitationId: invitationId,
                                  bookId: effectiveBookId,
                                ),
                              ),
                        child: const Text('Precedent'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: index == sorted.length - 1
                            ? null
                            : () => context.go(
                                AppRoutes.betaReadChapterPath(
                                  campaignId,
                                  sorted[index + 1].id,
                                  invitationId: invitationId,
                                  bookId: effectiveBookId,
                                ),
                              ),
                        child: const Text('Suivant'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCommentSheet(
    BuildContext context,
    WidgetRef ref,
    BetaSharedChapterModel chapter,
    String effectiveBookId,
  ) async {
    final text = chapter.content.trim();
    final selectedText = text.length <= 180
        ? text
        : '${text.substring(0, 180)}...';
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => CreateBetaCommentBottomSheet(
        bookId: effectiveBookId,
        campaignId: campaignId,
        chapterId: chapter.id,
        defaultSelectedText: selectedText,
      ),
    );
    if (created == true) {
      ref.invalidate(betaCommentsForCampaignProvider(campaignId));
      ref.invalidate(betaSharedChaptersProvider(campaignId));
    }
  }
}

class _ChapterText extends StatelessWidget {
  const _ChapterText({required this.chapter});

  final BetaSharedChapterModel chapter;

  @override
  Widget build(BuildContext context) {
    final paragraphs = chapter.content
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          chapter.title.isEmpty ? 'Chapitre' : chapter.title,
          style: const TextStyle(
            color: PlumoraColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 24),
        if (paragraphs.isEmpty)
          const Text(
            'Ce chapitre ne contient pas encore de texte.',
            style: TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 18,
              height: 1.7,
            ),
          )
        else
          for (final paragraph in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Text(
                paragraph,
                style: const TextStyle(
                  color: PlumoraColors.textPrimary,
                  fontSize: 18,
                  height: 1.7,
                ),
              ),
            ),
      ],
    );
  }
}

class _CommentsBlock extends StatelessWidget {
  const _CommentsBlock({
    required this.commentsAsync,
    required this.chapterId,
    required this.onRetry,
  });

  final AsyncValue<List<BetaCommentModel>> commentsAsync;
  final String chapterId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes retours sur ce chapitre',
            style: TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          commentsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppError.messageFor(error),
                  style: const TextStyle(color: PlumoraColors.textSecondary),
                ),
                const SizedBox(height: 10),
                TextButton(onPressed: onRetry, child: const Text('Reessayer')),
              ],
            ),
            data: (comments) {
              final chapterComments = comments
                  .where((comment) => comment.chapterId == chapterId)
                  .toList();
              if (chapterComments.isEmpty) {
                return const Text(
                  'Aucun retour ajoute pour ce chapitre.',
                  style: TextStyle(color: PlumoraColors.textSecondary),
                );
              }

              return Column(
                children: [
                  for (final comment in chapterComments) ...[
                    _CommentTile(comment: comment),
                    const Divider(color: PlumoraColors.border),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final BetaCommentModel comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FigmaBadge(label: comment.type.label),
              FigmaBadge(label: comment.status.apiValue),
            ],
          ),
          if ((comment.selectedText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment.selectedText!,
              style: const TextStyle(
                color: PlumoraColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(comment.content),
        ],
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlumoraColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: FigmaCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(color: PlumoraColors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Reessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
