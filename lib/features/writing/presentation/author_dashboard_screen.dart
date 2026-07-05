import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/repositories/book_repository.dart';
import '../../book/presentation/widgets/book_status_badge.dart';

class AuthorDashboardScreen extends ConsumerStatefulWidget {
  const AuthorDashboardScreen({super.key});

  @override
  ConsumerState<AuthorDashboardScreen> createState() =>
      _AuthorDashboardScreenState();
}

class _AuthorDashboardScreenState extends ConsumerState<AuthorDashboardScreen> {
  String _activeTab = 'manuscripts';

  static const _tabs = [
    ('manuscripts', 'Mes manuscrits'),
    ('feedback', 'Retours beta'),
    ('publication', 'Publication'),
  ];

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(myBooksProvider);

    return FigmaScreen(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ecrire',
                      style: TextStyle(
                        color: PlumoraColors.textPrimary,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Gerez vos manuscrits et votre activite d'auteur",
                      style: TextStyle(
                        color: PlumoraColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.createBook),
                icon: const Icon(Icons.add),
                label: const Text('Nouveau livre'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tab in _tabs) ...[
                  _SegmentTab(
                    label: tab.$2,
                    selected: _activeTab == tab.$1,
                    onTap: () => setState(() => _activeTab = tab.$1),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          booksAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _ErrorPanel(
              message: AppError.messageFor(error),
              onRetry: () => ref.invalidate(myBooksProvider),
            ),
            data: (books) {
              if (_activeTab == 'manuscripts') {
                return _ManuscriptsTab(books: books);
              }
              if (_activeTab == 'feedback') {
                return _FeedbackTab(books: books);
              }
              return _PublicationTab(books: books);
            },
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? PlumoraColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: PlumoraColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : PlumoraColors.textSecondary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ManuscriptsTab extends StatelessWidget {
  const _ManuscriptsTab({required this.books});

  final List<BookModel> books;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return FigmaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FigmaEmptyState(
              title: 'Aucun manuscrit',
              message: 'Cree ton premier livre pour commencer a ecrire.',
              icon: Icons.edit_outlined,
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go(AppRoutes.createBook),
                icon: const Icon(Icons.add),
                label: const Text('Creer un livre'),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 980
                ? 3
                : constraints.maxWidth >= 680
                ? 2
                : 1;
            final spacing = 18.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final book in books)
                  SizedBox(
                    width: width,
                    child: _ManuscriptCard(book: book),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _AuthorStats(books: books),
      ],
    );
  }
}

class _AuthorStats extends StatelessWidget {
  const _AuthorStats({required this.books});

  final List<BookModel> books;

  @override
  Widget build(BuildContext context) {
    final writing = books
        .where(
          (book) =>
              book.status == BookStatus.draft ||
              book.status == BookStatus.inCorrection,
        )
        .length;
    final published = books
        .where((book) => book.status == BookStatus.published)
        .length;
    final totalWords = books.fold<int>(0, (sum, book) => sum + book.wordCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final children = [
          FigmaStatCard(label: 'Manuscrits', value: books.length.toString()),
          FigmaStatCard(
            label: "En cours d'ecriture",
            value: writing.toString(),
            valueColor: PlumoraColors.secondary,
          ),
          FigmaStatCard(
            label: 'Mots',
            value: _compactNumber(totalWords),
            valueColor: PlumoraColors.accent,
          ),
          FigmaStatCard(
            label: 'Publies',
            value: published.toString(),
            valueColor: PlumoraColors.success,
          ),
        ];
        if (compact) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _ManuscriptCard extends StatelessWidget {
  const _ManuscriptCard({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      clip: true,
      child: Stack(
        children: [
          Positioned(
            top: -62,
            right: -62,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: PlumoraColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      book.title.isEmpty ? 'Livre sans titre' : book.title,
                      style: const TextStyle(
                        color: PlumoraColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusBadge(status: book.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                book.description.trim().isEmpty
                    ? 'Aucun resume renseigne.'
                    : book.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlumoraColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FigmaBadge(label: '${book.chapterCount} chapitres'),
                  FigmaBadge(label: '${book.wordCount} mots'),
                  if (book.feedbackCount > 0)
                    FigmaBadge(
                      label: '${book.feedbackCount} retours',
                      icon: Icons.chat_bubble_outline,
                      backgroundColor: PlumoraColors.secondary.withValues(
                        alpha: 0.12,
                      ),
                      foregroundColor: PlumoraColors.secondary,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (book.status == BookStatus.draft ||
                  book.status == BookStatus.inCorrection) ...[
                Row(
                  children: [
                    const Text(
                      'Progression',
                      style: TextStyle(
                        color: PlumoraColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(book.progress.clamp(0, 1) * 100).round()}%',
                      style: const TextStyle(
                        color: PlumoraColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FigmaProgressBar(
                  value: book.progress,
                  height: 9,
                  colors: const [
                    PlumoraColors.primary,
                    PlumoraColors.primaryLight,
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          context.go(AppRoutes.chapterEditorPath(book.id)),
                      child: Text(
                        book.status == BookStatus.published
                            ? 'Voir les chapitres'
                            : 'Continuer',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () =>
                        context.go(AppRoutes.authorBookDetailPath(book.id)),
                    child: const Icon(Icons.open_in_new),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab({required this.books});

  final List<BookModel> books;

  @override
  Widget build(BuildContext context) {
    final withFeedback = books
        .where((book) => book.feedbackCount > 0)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Retours beta',
                style: TextStyle(
                  color: PlumoraColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.betaFeedback),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (withFeedback.isEmpty)
          const FigmaEmptyState(
            title: 'Aucun retour beta',
            message: 'Les retours relies a tes livres apparaitront ici.',
            icon: Icons.chat_bubble_outline,
          )
        else
          for (final book in withFeedback) ...[
            FigmaCard(
              onTap: () =>
                  context.go(AppRoutes.authorBetaCommentsPath(book.id)),
              borderColor: PlumoraColors.primary,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FigmaGradientIcon(icon: Icons.chat_bubble_outline),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FigmaBadge(
                          label: '${book.feedbackCount} retours',
                          backgroundColor: PlumoraColors.primary.withValues(
                            alpha: 0.12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          book.title.isEmpty ? 'Livre sans titre' : book.title,
                          style: const TextStyle(
                            color: PlumoraColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          book.status.shortFrenchLabel,
                          style: const TextStyle(
                            color: PlumoraColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        context.go(AppRoutes.authorBetaCommentsPath(book.id)),
                    child: const Text('Ouvrir'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _PublicationTab extends StatelessWidget {
  const _PublicationTab({required this.books});

  final List<BookModel> books;

  @override
  Widget build(BuildContext context) {
    final candidates = books
        .where((book) => book.canPublish && !book.isArchived)
        .toList(growable: false);

    return Column(
      children: [
        FigmaCard(
          borderColor: PlumoraColors.primary,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FigmaGradientIcon(icon: Icons.upload_outlined, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pret a publier ?',
                      style: TextStyle(
                        color: PlumoraColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Les livres publies passent directement dans le catalogue selon le contrat MVP.',
                      style: TextStyle(
                        color: PlumoraColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (candidates.isEmpty)
                      const Text(
                        'Aucun livre candidat pour le moment.',
                        style: TextStyle(color: PlumoraColors.textSecondary),
                      )
                    else
                      for (final book in candidates) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            book.title.isEmpty
                                ? 'Livre sans titre'
                                : book.title,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${book.chapterCount} chapitres - ${book.wordCount} mots',
                          ),
                          trailing: FilledButton.icon(
                            onPressed: () =>
                                context.go(AppRoutes.publishBookPath(book.id)),
                            icon: const Icon(Icons.upload_outlined),
                            label: const Text('Publier'),
                          ),
                        ),
                        const Divider(color: PlumoraColors.border),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BookStatus status;

  @override
  Widget build(BuildContext context) {
    return FigmaBadge(
      label: status.shortFrenchLabel,
      backgroundColor: status.backgroundColor,
      foregroundColor: status.foregroundColor,
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
            'Manuscrits indisponibles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: PlumoraColors.textSecondary),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Reessayer')),
        ],
      ),
    );
  }
}

String _compactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}
