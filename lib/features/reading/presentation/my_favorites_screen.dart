import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../../catalog/data/models/catalog_book_model.dart';
import '../data/models/favorite_model.dart';
import '../data/repositories/favorite_repository.dart';

class MyFavoritesScreen extends ConsumerWidget {
  const MyFavoritesScreen({this.query = '', super.key});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(myFavoritesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlumoraCard(
          borderColor: context.colors.destructive.withValues(alpha: 0.35),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PlumoraIconTile(
                backgroundColor: Color(0xFFE95858),
                child: Icon(Icons.favorite, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mes Favoris',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les livres que vous avez adorés et que vous voulez retrouver facilement.',
                      style: TextStyle(
                        color: context.colors.textSecondary,
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
        favoritesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(36),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => FigmaEmptyState(
            icon: Icons.error_outline,
            title: 'Favoris indisponibles',
            message: AppError.messageFor(error),
            action: FilledButton(
              onPressed: () => ref.invalidate(myFavoritesProvider),
              child: const Text('Réessayer'),
            ),
          ),
          data: (favorites) {
            final normalizedQuery = query.trim();
            final filteredFavorites = favorites
                .where(
                  (favorite) => _matchesFavorite(favorite, normalizedQuery),
                )
                .toList(growable: false);

            if (filteredFavorites.isEmpty) {
              return FigmaEmptyState(
                icon: normalizedQuery.isEmpty
                    ? Icons.favorite_border
                    : Icons.search_off,
                title: normalizedQuery.isEmpty
                    ? 'Aucun favori'
                    : 'Aucun résultat',
                message: normalizedQuery.isEmpty
                    ? 'Ajoute des livres depuis leur fiche pour les retrouver ici.'
                    : 'Aucun favori ne correspond à cette recherche.',
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 620
                    ? 3
                    : 2;
                const spacing = 14.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: 14,
                  children: [
                    for (final favorite in filteredFavorites)
                      SizedBox(
                        width: width,
                        child: _FavoriteCard(favorite: favorite),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  bool _matchesFavorite(FavoriteModel favorite, String query) {
    if (query.isEmpty) {
      return true;
    }

    final normalizedQuery = query.toLowerCase();
    final book = favorite.book;
    return book.title.toLowerCase().contains(normalizedQuery) ||
        book.authorName.toLowerCase().contains(normalizedQuery) ||
        (book.genre?.toLowerCase().contains(normalizedQuery) ?? false);
  }
}

class _FavoriteCard extends ConsumerWidget {
  const _FavoriteCard({required this.favorite});

  final FavoriteModel favorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = favorite.book;
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));
    return PlumoraCard(
      padding: EdgeInsets.zero,
      clip: true,
      onTap: () => context.go(AppRoutes.catalogBookDetailPath(book.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: PlumoraBookCover(
                    colors: _coverColors(book),
                    imageUrl: book.coverUrl,
                    imageBytes: cachedCover,
                    width: double.infinity,
                    height: double.infinity,
                    radius: 0,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFFE95858),
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title.isEmpty ? 'Livre sans titre' : book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF5C84C), size: 14),
                    const SizedBox(width: 3),
                    Text(
                      book.rating == 0 ? '-' : book.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
