import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../../reading/data/models/review_model.dart';
import '../../reading/data/repositories/favorite_repository.dart';
import '../../reading/data/repositories/review_repository.dart';
import '../data/models/catalog_book_model.dart';
import '../data/repositories/catalog_repository.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({required this.bookId, super.key});

  final String bookId;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  bool _favoriteMutating = false;
  String? _favoriteError;

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(catalogBookDetailProvider(widget.bookId));
    final favoriteAsync = ref.watch(favoriteStatusProvider(widget.bookId));
    final reviewsAsync = ref.watch(bookReviewsProvider(widget.bookId));

    return FigmaScreen(
      maxWidth: 1120,
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigmaBackButton(
            label: 'Retour',
            onTap: () => context.go(AppRoutes.discover),
          ),
          const SizedBox(height: 22),
          bookAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _ErrorCard(
              title: 'Livre introuvable',
              message: AppError.messageFor(error),
              onRetry: () =>
                  ref.invalidate(catalogBookDetailProvider(widget.bookId)),
            ),
            data: (book) => LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 780;
                final cover = _ActionColumn(
                  book: book,
                  isFavorite: favoriteAsync.valueOrNull ?? false,
                  favoriteLoading: favoriteAsync.isLoading || _favoriteMutating,
                  favoriteError: _favoriteError,
                  onToggleFavorite: () =>
                      _toggleFavorite(favoriteAsync.valueOrNull ?? false),
                );
                final details = _BookDetails(
                  book: book,
                  reviewsAsync: reviewsAsync,
                  onRetryReviews: () =>
                      ref.invalidate(bookReviewsProvider(widget.bookId)),
                );

                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [cover, const SizedBox(height: 28), details],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 300, child: cover),
                    const SizedBox(width: 34),
                    Expanded(child: details),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(bool isFavorite) async {
    setState(() {
      _favoriteMutating = true;
      _favoriteError = null;
    });

    try {
      final repository = ref.read(favoriteRepositoryProvider);
      if (isFavorite) {
        await repository.removeFavorite(widget.bookId);
      } else {
        await repository.addFavorite(widget.bookId);
      }
      ref.invalidate(favoriteStatusProvider(widget.bookId));
      ref.invalidate(myFavoritesProvider);
    } catch (error) {
      setState(() => _favoriteError = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _favoriteMutating = false);
      }
    }
  }
}

class _ActionColumn extends ConsumerWidget {
  const _ActionColumn({
    required this.book,
    required this.isFavorite,
    required this.favoriteLoading,
    required this.onToggleFavorite,
    this.favoriteError,
  });

  final CatalogBookDetailModel book;
  final bool isFavorite;
  final bool favoriteLoading;
  final VoidCallback onToggleFavorite;
  final String? favoriteError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 2 / 3,
          child: PlumoraBookCover(
            width: double.infinity,
            height: double.infinity,
            radius: 18,
            colors: _coverColors(book.id.isEmpty ? book.title : book.id),
            imageUrl: book.coverUrl,
            imageBytes: cachedCover,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.readingPath(book.id)),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Lire maintenant'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: favoriteLoading ? null : onToggleFavorite,
          icon: favoriteLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          label: Text(
            isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
          ),
        ),
        if (favoriteError != null) ...[
          const SizedBox(height: 8),
          Text(
            favoriteError!,
            style: TextStyle(
              color: context.colors.destructive,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _BookDetails extends StatelessWidget {
  const _BookDetails({
    required this.book,
    required this.reviewsAsync,
    required this.onRetryReviews,
  });

  final CatalogBookDetailModel book;
  final AsyncValue<List<ReviewModel>> reviewsAsync;
  final VoidCallback onRetryReviews;

  @override
  Widget build(BuildContext context) {
    final loadedReviews = reviewsAsync.valueOrNull;
    final reviewCount = loadedReviews?.length ?? book.ratingCount;
    final averageRating = loadedReviews != null && loadedReviews.isNotEmpty
        ? loadedReviews.map((review) => review.rating).reduce((a, b) => a + b) /
              loadedReviews.length
        : book.rating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title.isEmpty ? 'Livre sans titre' : book.title,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'par ${book.authorName}',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (book.genre != null && book.genre!.trim().isNotEmpty)
              FigmaBadge(label: book.genre!),
            FigmaBadge(label: '${book.chapterCount} chapitres'),
            if (book.publishedAt != null)
              FigmaBadge(label: 'Publie le ${_shortDate(book.publishedAt!)}'),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 22,
          runSpacing: 12,
          children: [
            _Metric(
              icon: Icons.star,
              label: averageRating == 0
                  ? '-'
                  : averageRating.toStringAsFixed(1),
              sub: '($reviewCount avis)',
            ),
            _Metric(
              icon: Icons.menu_book_outlined,
              label: book.readCount.toString(),
              sub: 'lectures',
            ),
            _Metric(
              icon: Icons.schedule,
              label: _readingDuration(book.estimatedReadingMinutes),
              sub: 'de lecture',
            ),
          ],
        ),
        const SizedBox(height: 26),
        _SummaryCard(description: book.description),
        const SizedBox(height: 18),
        _AuthorCard(book: book),
        const SizedBox(height: 18),
        _ChaptersCard(book: book),
        const SizedBox(height: 18),
        _ReviewsCard(
          bookId: book.id,
          reviewsAsync: reviewsAsync,
          onRetry: onRetryReviews,
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.sub});

  final IconData icon;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: icon == Icons.star
              ? Colors.amber
              : context.colors.textSecondary,
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 4),
        Text(sub, style: TextStyle(color: context.colors.textSecondary)),
      ],
    );
  }
}

class _SummaryCard extends StatefulWidget {
  const _SummaryCard({required this.description});

  final String description;

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.description.trim().isEmpty
        ? 'Aucun resume disponible pour ce livre.'
        : widget.description.trim();
    final canCollapse = text.length > 360;

    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resume',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            maxLines: canCollapse && !_expanded ? 5 : null,
            overflow: canCollapse && !_expanded
                ? TextOverflow.ellipsis
                : TextOverflow.visible,
            style: TextStyle(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
          ),
          if (canCollapse) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Voir moins' : 'Voir plus'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({required this.book});

  final CatalogBookDetailModel book;

  @override
  Widget build(BuildContext context) {
    final initials = book.authorName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return FigmaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: context.colors.primary,
            child: Text(
              initials.isEmpty ? 'P' : initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "A propos de l'auteur",
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  book.authorName,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (book.authorBio ?? '').trim().isEmpty
                      ? 'Aucune biographie publique pour le moment.'
                      : book.authorBio!,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChaptersCard extends StatelessWidget {
  const _ChaptersCard({required this.book});

  final CatalogBookDetailModel book;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chapitres',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (book.chapters.isEmpty)
            Text(
              'Aucun chapitre lisible pour le moment.',
              style: TextStyle(color: context.colors.textSecondary),
            )
          else
            for (final chapter in book.chapters.take(5)) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                  child: Text(
                    chapter.order == 0 ? '-' : chapter.order.toString(),
                    style: TextStyle(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                title: Text(
                  chapter.title.isEmpty ? 'Chapitre sans titre' : chapter.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(
                  AppRoutes.readingPath(book.id, chapterId: chapter.id),
                ),
              ),
              Divider(color: context.colors.border),
            ],
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard({
    required this.bookId,
    required this.reviewsAsync,
    required this.onRetry,
  });

  final String bookId;
  final AsyncValue<List<ReviewModel>> reviewsAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Avis des lecteurs',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.libraryReviews),
                child: const Text('Mes avis'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          reviewsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _ErrorCard(
              title: 'Avis indisponibles',
              message: AppError.messageFor(error),
              onRetry: onRetry,
            ),
            data: (reviews) {
              if (reviews.isEmpty) {
                return Text(
                  'Aucun avis pour ce livre pour le moment.',
                  style: TextStyle(color: context.colors.textSecondary),
                );
              }

              return Column(
                children: [
                  for (final review in reviews.take(4)) ...[
                    _Review(review: review),
                    Divider(color: context.colors.border),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () =>
                          context.go(AppRoutes.readingPath(bookId)),
                      child: Text('Lire le livre (${reviews.length} avis)'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Icon(
                  Icons.star,
                  size: 16,
                  color: i < review.rating
                      ? Colors.amber
                      : Colors.grey.shade300,
                ),
              const SizedBox(width: 8),
              Text(
                review.userName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (review.createdAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  _shortDate(review.createdAt!),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Reessayer')),
        ],
      ),
    );
  }
}

String _readingDuration(int minutes) {
  if (minutes <= 0) {
    return '-';
  }
  if (minutes < 60) {
    return '${minutes}min';
  }
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0
      ? '${hours}h'
      : '${hours}h${rest.toString().padLeft(2, '0')}';
}

String _shortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

List<Color> _coverColors(String key) {
  final palettes = [
    [const Color(0xFF7C3AED), const Color(0xFFDB2777)],
    [const Color(0xFF2563EB), const Color(0xFF06B6D4)],
    [const Color(0xFFDC2626), const Color(0xFFEA580C)],
    [const Color(0xFFDB2777), const Color(0xFFE11D48)],
    [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
    [const Color(0xFF059669), const Color(0xFF0D9488)],
  ];
  final index =
      key.codeUnits.fold<int>(0, (sum, code) => sum + code) % palettes.length;
  return palettes[index];
}
