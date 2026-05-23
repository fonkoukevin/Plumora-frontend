import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../data/models/review_model.dart';
import '../data/repositories/review_repository.dart';

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(myReviewsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlumoraCard(
          borderColor: const Color(0xFFE7D8B9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PlumoraIconTile(
                backgroundColor: Color(0xFFFFF5D8),
                child: Icon(Icons.star, color: PlumoraColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Mes avis',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Retrouvez les avis que vous avez publiés sur les livres Plumora.',
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
        reviewsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(36),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => _StateCard(
            title: 'Avis indisponibles',
            subtitle: AppError.messageFor(error),
            action: FilledButton(
              onPressed: () => ref.invalidate(myReviewsProvider),
              child: const Text('Réessayer'),
            ),
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return const _StateCard(
                title: 'Aucun avis publié',
                subtitle:
                    'Les avis que tu laisseras depuis les fiches livres apparaîtront ici.',
              );
            }

            return Column(
              children: [
                for (final review in reviews) ...[
                  _MyReviewCard(review: review),
                  const SizedBox(height: 14),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MyReviewCard extends ConsumerStatefulWidget {
  const _MyReviewCard({required this.review});

  final ReviewModel review;

  @override
  ConsumerState<_MyReviewCard> createState() => _MyReviewCardState();
}

class _MyReviewCardState extends ConsumerState<_MyReviewCard> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final book = review.book;
    return PlumoraCard(
      padding: const EdgeInsets.all(16),
      onTap: book == null || book.id.isEmpty
          ? null
          : () => context.go(AppRoutes.catalogBookDetailPath(book.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book?.title.isNotEmpty == true
                          ? book!.title
                          : 'Livre Plumora',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _Stars(rating: review.rating),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _isDeleting ? null : _delete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(_isDeleting ? '...' : 'Supprimer'),
                style: TextButton.styleFrom(
                  foregroundColor: PlumoraColors.destructive,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(
                color: PlumoraColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      await ref.read(reviewRepositoryProvider).deleteReview(widget.review.id);
      ref.invalidate(myReviewsProvider);
      if (widget.review.bookId.isNotEmpty) {
        ref.invalidate(bookReviewsProvider(widget.review.bookId));
        ref.invalidate(myReviewForBookProvider(widget.review.bookId));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

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

class _StateCard extends StatelessWidget {
  const _StateCard({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: PlumoraColors.textSecondary),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}
