import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../../reading/data/models/review_model.dart';
import '../../reading/data/repositories/favorite_repository.dart';
import '../../reading/data/repositories/review_repository.dart';
import '../data/models/catalog_book_model.dart';
import '../data/repositories/catalog_repository.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({required this.bookId, super.key});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(catalogBookDetailProvider(bookId));

    return detailAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => _DetailError(
        message: AppError.messageFor(error),
        onRetry: () => ref.invalidate(catalogBookDetailProvider(bookId)),
      ),
      data: (book) => _BookDetailContent(book: book),
    );
  }
}

class _BookDetailContent extends StatelessWidget {
  const _BookDetailContent({required this.book});

  final CatalogBookDetailModel book;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final horizontal = isWide ? 32.0 : 16.0;
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 82.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            24,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.discover),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Retour'),
                  ),
                  const SizedBox(height: 12),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 300, child: _ActionRail(book: book)),
                        const SizedBox(width: 30),
                        Expanded(child: _DetailBody(book: book)),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ActionRail(book: book),
                        const SizedBox(height: 24),
                        _DetailBody(book: book),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionRail extends ConsumerStatefulWidget {
  const _ActionRail({required this.book});

  final CatalogBookDetailModel book;

  @override
  ConsumerState<_ActionRail> createState() => _ActionRailState();
}

class _ActionRailState extends ConsumerState<_ActionRail> {
  bool _isMutatingFavorite = false;

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final summary = book.summary;
    final favoriteAsync = ref.watch(favoriteStatusProvider(book.id));
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 2 / 3,
          child: PlumoraBookCover(
            colors: _coverColors(summary),
            imageUrl: summary.coverUrl,
            imageBytes: cachedCover,
            width: double.infinity,
            height: double.infinity,
            radius: 18,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.readingPath(book.id)),
          icon: const Icon(Icons.play_arrow, size: 20),
          label: const Text('Lire maintenant'),
        ),
        const SizedBox(height: 10),
        favoriteAsync.when(
          loading: () => OutlinedButton.icon(
            onPressed: null,
            icon: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: const Text('Favori'),
          ),
          error: (_, _) => OutlinedButton.icon(
            onPressed: _isMutatingFavorite
                ? null
                : () => _toggleFavorite(false),
            icon: const Icon(Icons.favorite_border, size: 18),
            label: const Text('Ajouter aux favoris'),
          ),
          data: (isFavorite) => OutlinedButton.icon(
            onPressed: _isMutatingFavorite
                ? null
                : () => _toggleFavorite(isFavorite),
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 18,
            ),
            label: Text(
              _isMutatingFavorite
                  ? 'Mise à jour...'
                  : isFavorite
                  ? 'Déjà favori'
                  : 'Ajouter aux favoris',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFavorite(bool isFavorite) async {
    setState(() => _isMutatingFavorite = true);

    try {
      final repository = ref.read(favoriteRepositoryProvider);
      if (isFavorite) {
        await repository.removeFavorite(widget.book.id);
      } else {
        await repository.addFavorite(widget.book.id);
      }
      ref.invalidate(favoriteStatusProvider(widget.book.id));
      ref.invalidate(myFavoritesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite
                  ? 'Livre retiré des favoris.'
                  : 'Livre ajouté aux favoris.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isMutatingFavorite = false);
      }
    }
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.book});

  final CatalogBookDetailModel book;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title.isEmpty ? 'Livre sans titre' : book.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: PlumoraColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'par ${book.authorName}',
          style: const TextStyle(
            color: PlumoraColors.textSecondary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (book.genre != null)
              PlumoraBadge(
                label: book.genre!,
                foregroundColor: const Color(0xFF7A5E2F),
              ),
            PlumoraBadge(
              label: '${book.chapterCount} chapitres',
              backgroundColor: const Color(0xFFF3EBDD),
              foregroundColor: PlumoraColors.textSecondary,
              icon: Icons.menu_book_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            _Metric(
              icon: Icons.star,
              label: book.rating == 0 ? '-' : book.rating.toStringAsFixed(1),
              subtitle: '${book.ratingCount} avis',
              iconColor: const Color(0xFFF5C84C),
            ),
            _Metric(
              icon: Icons.auto_stories_outlined,
              label: _formatReads(book.readCount),
              subtitle: 'lectures',
            ),
            _Metric(
              icon: Icons.schedule,
              label: book.estimatedReadingMinutes == 0
                  ? '-'
                  : '${book.estimatedReadingMinutes} min',
              subtitle: 'temps estimé',
            ),
          ],
        ),
        const SizedBox(height: 24),
        PlumoraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Résumé',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                book.description.isEmpty
                    ? 'Aucun résumé disponible pour ce livre.'
                    : book.description,
                style: const TextStyle(
                  color: PlumoraColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PlumoraCard(
          borderColor: const Color(0xFFDCCDEC),
          onTap: () => context.go(AppRoutes.mukemeRecommendation),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PlumoraIconTile(
                backgroundColor: Color(0xFFEADCF7),
                child: Icon(Icons.auto_awesome, color: PlumoraColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Pourquoi Mukeme pourrait te le recommander',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mukeme analysera bientôt tes goûts de lecture pour expliquer ses recommandations.',
                      style: TextStyle(
                        color: PlumoraColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PlumoraCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: PlumoraColors.primary,
                child: Text(
                  _initials(book.authorName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "À propos de l'auteur",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.authorBio?.isNotEmpty == true
                          ? book.authorBio!
                          : '${book.authorName} publie ses livres sur Plumora.',
                      style: const TextStyle(
                        color: PlumoraColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ReviewsSection(bookId: book.id),
      ],
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(bookReviewsProvider(bookId));
    final myReviewAsync = ref.watch(myReviewForBookProvider(bookId));

    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Avis des lecteurs',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ),
              reviewsAsync.maybeWhen(
                data: (reviews) => PlumoraBadge(
                  label: '${reviews.length} avis',
                  backgroundColor: PlumoraColors.muted,
                  foregroundColor: PlumoraColors.textSecondary,
                  icon: Icons.rate_review_outlined,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ReviewEditor(bookId: bookId, myReviewAsync: myReviewAsync),
          const SizedBox(height: 20),
          reviewsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _InlineState(
              title: 'Avis indisponibles',
              subtitle: AppError.messageFor(error),
              action: TextButton(
                onPressed: () => ref.invalidate(bookReviewsProvider(bookId)),
                child: const Text('Réessayer'),
              ),
            ),
            data: (reviews) {
              if (reviews.isEmpty) {
                return const _InlineState(
                  title: 'Aucun avis pour le moment',
                  subtitle: 'Sois le premier à partager ton ressenti.',
                );
              }

              return Column(
                children: [
                  for (final review in reviews) ...[
                    _ReviewCard(review: review),
                    if (review != reviews.last) const Divider(height: 24),
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

class _ReviewEditor extends ConsumerStatefulWidget {
  const _ReviewEditor({required this.bookId, required this.myReviewAsync});

  final String bookId;
  final AsyncValue<ReviewModel?> myReviewAsync;

  @override
  ConsumerState<_ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends ConsumerState<_ReviewEditor> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _isSaving = false;
  String? _loadedReviewId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.myReviewAsync.when(
      loading: () => const _InlineState(
        title: 'Chargement de ton avis',
        subtitle: 'On vérifie si tu as déjà donné ton avis.',
      ),
      error: (error, _) => _InlineState(
        title: 'Ton avis est indisponible',
        subtitle: AppError.messageFor(error),
        action: TextButton(
          onPressed: () =>
              ref.invalidate(myReviewForBookProvider(widget.bookId)),
          child: const Text('Réessayer'),
        ),
      ),
      data: (myReview) {
        _syncReview(myReview);
        final hasReview = myReview != null;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PlumoraColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasReview ? 'Ton avis' : 'Donner mon avis',
                style: const TextStyle(
                  color: PlumoraColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _StarRatingInput(
                rating: _rating,
                onChanged: _isSaving
                    ? null
                    : (rating) => setState(() => _rating = rating),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                enabled: !_isSaving,
                minLines: 3,
                maxLines: 5,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Ce livre t’a plu ? Partage ton avis...',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _isSaving ? null : () => _submit(myReview),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined, size: 16),
                    label: Text(
                      _isSaving
                          ? 'Sauvegarde...'
                          : hasReview
                          ? 'Mettre à jour'
                          : 'Publier mon avis',
                    ),
                  ),
                  if (hasReview)
                    TextButton.icon(
                      onPressed: _isSaving ? null : () => _delete(myReview),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Supprimer'),
                      style: TextButton.styleFrom(
                        foregroundColor: PlumoraColors.destructive,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _syncReview(ReviewModel? review) {
    final reviewId = review?.id;
    if (_loadedReviewId == reviewId) {
      return;
    }

    _loadedReviewId = reviewId;
    _rating = review?.rating == 0 ? 5 : (review?.rating ?? 5);
    _commentController.text = review?.comment ?? '';
  }

  Future<void> _submit(ReviewModel? existingReview) async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoute un commentaire avant de publier.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final request = ReviewUpsertRequest(rating: _rating, comment: comment);
      final repository = ref.read(reviewRepositoryProvider);
      if (existingReview == null) {
        await repository.createReview(widget.bookId, request);
      } else {
        await repository.updateReview(existingReview.id, request);
      }
      _invalidateReviews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingReview == null ? 'Avis publié.' : 'Avis mis à jour.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete(ReviewModel review) async {
    setState(() => _isSaving = true);

    try {
      await ref.read(reviewRepositoryProvider).deleteReview(review.id);
      _commentController.clear();
      _loadedReviewId = null;
      _rating = 5;
      _invalidateReviews();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avis supprimé.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _invalidateReviews() {
    ref.invalidate(bookReviewsProvider(widget.bookId));
    ref.invalidate(myReviewsProvider);
    ref.invalidate(myReviewForBookProvider(widget.bookId));
    ref.invalidate(catalogBookDetailProvider(widget.bookId));
  }
}

class _StarRatingInput extends StatelessWidget {
  const _StarRatingInput({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var value = 1; value <= 5; value++)
          IconButton(
            tooltip: '$value étoile${value > 1 ? 's' : ''}',
            visualDensity: VisualDensity.compact,
            onPressed: onChanged == null ? null : () => onChanged!(value),
            icon: Icon(
              value <= rating ? Icons.star : Icons.star_border,
              color: const Color(0xFFF5C84C),
            ),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StaticStars(rating: review.rating),
                  Text(
                    review.userName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    _dateLabel(review.createdAt),
                    style: const TextStyle(
                      color: PlumoraColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _StaticStars extends StatelessWidget {
  const _StaticStars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var value = 1; value <= 5; value++)
          Icon(
            value <= rating ? Icons.star : Icons.star_border,
            color: const Color(0xFFF5C84C),
            size: 16,
          ),
      ],
    );
  }
}

class _InlineState extends StatelessWidget {
  const _InlineState({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PlumoraColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 10), action!],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.iconColor = PlumoraColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(width: 4),
        Text(
          subtitle,
          style: const TextStyle(color: PlumoraColors.textSecondary),
        ),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: PlumoraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Livre introuvable',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: PlumoraColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatReads(int reads) {
  if (reads <= 0) {
    return '-';
  }
  if (reads >= 1000) {
    return '${(reads / 1000).toStringAsFixed(1)}k';
  }
  return reads.toString();
}

String _dateLabel(DateTime? date) {
  if (date == null) {
    return '';
  }

  final now = DateTime.now();
  final local = date.toLocal();
  final difference = now.difference(local);
  if (difference.inDays == 0) {
    return "aujourd'hui";
  }
  if (difference.inDays == 1) {
    return 'hier';
  }
  if (difference.inDays < 7) {
    return 'il y a ${difference.inDays} jours';
  }

  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'P';
  }
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

List<Color> _coverColors(CatalogBookModel book) {
  final palettes = [
    [const Color(0xFF7C3AED), const Color(0xFFDB2777)],
    [const Color(0xFF2563EB), const Color(0xFF06B6D4)],
    [const Color(0xFFDC2626), const Color(0xFFEA580C)],
    [const Color(0xFFDB2777), const Color(0xFFE11D48)],
    [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
    [const Color(0xFF059669), const Color(0xFF0D9488)],
  ];
  final key = book.id.isEmpty ? book.title : book.id;
  final index =
      key.codeUnits.fold<int>(0, (sum, code) => sum + code) % palettes.length;
  return palettes[index];
}
