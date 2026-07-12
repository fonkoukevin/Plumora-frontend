import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../data/models/beta_campaign_model.dart';
import '../data/models/beta_shared_chapter_model.dart';
import '../data/repositories/beta_reading_repository.dart';

class BetaReadingChaptersScreen extends ConsumerWidget {
  const BetaReadingChaptersScreen({
    required this.campaignId,
    this.invitationId,
    this.bookId,
    super.key,
  });

  final String campaignId;
  final String? invitationId;
  final String? bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(betaCampaignProvider(campaignId));
    final chaptersAsync = ref.watch(betaSharedChaptersProvider(campaignId));
    final commentsAsync = ref.watch(
      betaCommentsForCampaignProvider(campaignId),
    );

    return FigmaScreen(
      maxWidth: 900,
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigmaBackButton(
            label: 'Retour',
            onTap: () => context.go(AppRoutes.betaInvitations),
          ),
          const SizedBox(height: 18),
          campaignAsync.maybeWhen(
            data: (campaign) => _CampaignHeader(campaign: campaign),
            orElse: () => const _CampaignHeader(),
          ),
          const SizedBox(height: 22),
          campaignAsync.maybeWhen(
            data: (campaign) => campaign.deadline == null
                ? const SizedBox.shrink()
                : FigmaCard(
                    color: context.colors.warning.withValues(alpha: 0.08),
                    borderColor: context.colors.warning.withValues(alpha: 0.35),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: context.colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Deadline : ${_shortDate(campaign.deadline!)}',
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 22),
          chaptersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _ErrorPanel(
              message: AppError.messageFor(error),
              onRetry: () =>
                  ref.invalidate(betaSharedChaptersProvider(campaignId)),
            ),
            data: (chapters) {
              final sorted = [...chapters]
                ..sort((a, b) {
                  final orderCompare = a.order.compareTo(b.order);
                  return orderCompare == 0
                      ? a.title.compareTo(b.title)
                      : orderCompare;
                });

              if (sorted.isEmpty) {
                return const FigmaEmptyState(
                  title: 'Aucun chapitre partage',
                  message:
                      "L'auteur n'a pas encore ouvert de chapitre pour cette campagne.",
                  icon: Icons.menu_book_outlined,
                );
              }

              final commentsByChapter = commentsAsync.maybeWhen(
                data: (comments) => <String, int>{
                  for (final chapter in sorted)
                    chapter.id: comments
                        .where((comment) => comment.chapterId == chapter.id)
                        .length,
                },
                orElse: () => const <String, int>{},
              );

              return Column(
                children: [
                  for (final chapter in sorted) ...[
                    _ChapterCard(
                      chapter: chapter,
                      campaignId: campaignId,
                      invitationId: invitationId,
                      fallbackBookId: bookId,
                      commentsCount: commentsByChapter[chapter.id] ?? 0,
                    ),
                    const SizedBox(height: 12),
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

class _CampaignHeader extends StatelessWidget {
  const _CampaignHeader({this.campaign});

  final BetaCampaignModel? campaign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          campaign?.bookTitle.trim().isNotEmpty == true
              ? campaign!.bookTitle
              : 'Beta-lecture',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          campaign == null ? 'Chapitres disponibles' : 'Chapitres disponibles',
          style: TextStyle(color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.campaignId,
    required this.invitationId,
    required this.fallbackBookId,
    required this.commentsCount,
  });

  final BetaSharedChapterModel chapter;
  final String campaignId;
  final String? invitationId;
  final String? fallbackBookId;
  final int commentsCount;

  @override
  Widget build(BuildContext context) {
    final hasFeedback = commentsCount > 0;

    return FigmaCard(
      onTap: () => context.go(
        AppRoutes.betaReadChapterPath(
          campaignId,
          chapter.id,
          invitationId: invitationId,
          bookId: chapter.bookId.isEmpty ? fallbackBookId : chapter.bookId,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: hasFeedback
                  ? context.colors.success.withValues(alpha: 0.12)
                  : context.colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasFeedback
                  ? Icons.check_circle_outline
                  : Icons.description_outlined,
              color: hasFeedback
                  ? context.colors.success
                  : context.colors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.title.isEmpty ? 'Chapitre sans titre' : chapter.title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$commentsCount commentaire(s) laisse(s)',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.textSecondary),
        ],
      ),
    );
  }
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
            'Chapitres indisponibles',
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

String _shortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
