import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
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
    final chaptersAsync = ref.watch(betaSharedChaptersProvider(campaignId));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 92),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.library),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Retour à la bibliothèque'),
              ),
              const SizedBox(height: 12),
              Text(
                'Lecture bêta',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: PlumoraColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lisez les chapitres partagés et laissez vos retours structurés.',
                style: TextStyle(color: PlumoraColors.textSecondary),
              ),
              const SizedBox(height: 24),
              chaptersAsync.when(
                loading: () => const _LoadingPanel(),
                error: (error, _) => _ErrorPanel(
                  title: 'Chapitres indisponibles',
                  message: AppError.messageFor(error),
                  onRetry: () =>
                      ref.invalidate(betaSharedChaptersProvider(campaignId)),
                ),
                data: (chapters) {
                  if (chapters.isEmpty) {
                    return const _EmptyPanel();
                  }

                  return Column(
                    children: [
                      _ProgressHeader(chapters: chapters),
                      const SizedBox(height: 18),
                      for (final chapter in chapters) ...[
                        _ChapterCard(
                          chapter: chapter,
                          onTap: () => context.go(
                            AppRoutes.betaReadChapterPath(
                              campaignId,
                              chapter.id,
                              bookId: bookId,
                              invitationId: invitationId,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.chapters});

  final List<BetaSharedChapterModel> chapters;

  @override
  Widget build(BuildContext context) {
    final comments = chapters.fold<int>(
      0,
      (sum, chapter) => sum + chapter.commentsCount,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 3 : 1;
        const spacing = 14.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [
            _StatCard(label: 'Chapitres partagés', value: '${chapters.length}'),
            _StatCard(label: 'Retours envoyés', value: '$comments'),
            const _StatCard(label: 'Mode', value: 'Bêta'),
          ].map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.onTap});

  final BetaSharedChapterModel chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final excerpt = chapter.content.trim().isEmpty
        ? 'Aperçu indisponible pour ce chapitre.'
        : chapter.content.trim().replaceAll(RegExp(r'\s+'), ' ');

    return PlumoraCard(
      onTap: onTap,
      leftAccent: PlumoraColors.primary,
      child: Row(
        children: [
          PlumoraIconTile(
            backgroundColor: const Color(0xFFEFE6DA),
            child: Text(
              '${chapter.order == 0 ? '' : chapter.order}',
              style: const TextStyle(
                color: PlumoraColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.title.isEmpty ? 'Chapitre sans titre' : chapter.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (chapter.commentsCount > 0) ...[
                  const SizedBox(height: 10),
                  PlumoraBadge(
                    icon: Icons.chat_bubble_outline,
                    label:
                        '${chapter.commentsCount} retour${chapter.commentsCount > 1 ? 's' : ''}',
                    backgroundColor: const Color(0xFFEAF3FF),
                    foregroundColor: PlumoraColors.info,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right, color: PlumoraColors.primary),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      shadow: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: PlumoraColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return const PlumoraCard(
      child: Row(
        children: [
          PlumoraIconTile(
            backgroundColor: PlumoraColors.secondary,
            child: Icon(Icons.menu_book_outlined, color: PlumoraColors.primary),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Aucun chapitre partagé pour cette campagne.',
              style: TextStyle(color: PlumoraColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlumoraIconTile(
            backgroundColor: Color(0xFFF7E0DC),
            child: Icon(Icons.error_outline, color: PlumoraColors.destructive),
          ),
          const SizedBox(height: 16),
          Text(
            title,
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
    );
  }
}
