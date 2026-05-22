import 'package:flutter/material.dart';

import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

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
            28,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Découvrir',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: PlumoraColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SearchBlock(isWide: isWide),
                  const SizedBox(height: 22),
                  const _GenreFilters(),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Tendances du moment',
                    trailingIcon: Icons.trending_up,
                    trailing: "Mis à jour aujourd'hui",
                  ),
                  const SizedBox(height: 16),
                  _TrendingGrid(isWide: isWide),
                  const SizedBox(height: 30),
                  const _SectionHeader(title: 'Recommandé pour vous'),
                  const SizedBox(height: 16),
                  _RecommendationGrid(isWide: isWide),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchBlock extends StatelessWidget {
  const _SearchBlock({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      decoration: InputDecoration(
        hintText: 'Rechercher un livre, un auteur, un genre...',
        prefixIcon: const Icon(
          Icons.search,
          color: PlumoraColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final mukemeButton = OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.auto_awesome, size: 19),
      label: const Text('Trouver avec Mukeme'),
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 12),
          SizedBox(width: 220, child: mukemeButton),
        ],
      );
    }

    return Column(
      children: [
        search,
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: mukemeButton),
      ],
    );
  }
}

class _GenreFilters extends StatelessWidget {
  const _GenreFilters();

  static const genres = [
    'Tous',
    'Fantasy',
    'Romance',
    'Thriller',
    'Science-Fiction',
    'Mystère',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final genre in genres) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: genre == 'Tous'
                    ? PlumoraColors.primary
                    : PlumoraColors.muted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                genre,
                style: TextStyle(
                  color: genre == 'Tous'
                      ? Colors.white
                      : PlumoraColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing, this.trailingIcon});

  final String title;
  final String? trailing;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: PlumoraColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) ...[
          if (trailingIcon != null)
            Icon(trailingIcon, size: 18, color: PlumoraColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            trailing!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: PlumoraColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _TrendingGrid extends StatelessWidget {
  const _TrendingGrid({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 650
            ? 2
            : 1;
        const spacing = 16.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 16,
          children: [
            for (final book in _books)
              SizedBox(
                width: width,
                child: _BookListCard(book: book),
              ),
          ],
        );
      },
    );
  }
}

class _RecommendationGrid extends StatelessWidget {
  const _RecommendationGrid({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 6
            : constraints.maxWidth >= 650
            ? 4
            : 2;
        const spacing = 14.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [
            for (final book in _books)
              SizedBox(
                width: width,
                child: _BookCoverCard(book: book),
              ),
          ],
        );
      },
    );
  }
}

class _BookListCard extends StatelessWidget {
  const _BookListCard({required this.book});

  final _Book book;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      padding: const EdgeInsets.all(16),
      onTap: () {},
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlumoraBookCover(colors: book.colors, width: 76, height: 104),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: PlumoraColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PlumoraColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                PlumoraBadge(
                  label: book.genre,
                  foregroundColor: const Color(0xFF7A5E2F),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF5C84C), size: 17),
                    const SizedBox(width: 4),
                    Text(
                      book.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.schedule,
                      color: PlumoraColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(book.reads / 1000).toStringAsFixed(1)}k',
                      style: const TextStyle(
                        color: PlumoraColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.favorite_border, color: PlumoraColors.textSecondary),
        ],
      ),
    );
  }
}

class _BookCoverCard extends StatelessWidget {
  const _BookCoverCard({required this.book});

  final _Book book;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      padding: EdgeInsets.zero,
      clip: true,
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: book.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF5C84C), size: 14),
                    const SizedBox(width: 3),
                    Text(
                      book.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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

const _books = [
  _Book(
    title: "Les Chroniques d'Eldoria",
    author: 'Sophie Martin',
    genre: 'Fantasy',
    rating: 4.8,
    reads: 12500,
    colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
  ),
  _Book(
    title: 'Au-delà des Étoiles',
    author: 'Marc Dubois',
    genre: 'Science-Fiction',
    rating: 4.6,
    reads: 8900,
    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
  ),
  _Book(
    title: 'Le Dernier Refuge',
    author: 'Emma Laurent',
    genre: 'Thriller',
    rating: 4.9,
    reads: 15200,
    colors: [Color(0xFFDC2626), Color(0xFFEA580C)],
  ),
  _Book(
    title: 'Cœurs Enchevêtrés',
    author: 'Julie Petit',
    genre: 'Romance',
    rating: 4.7,
    reads: 10800,
    colors: [Color(0xFFDB2777), Color(0xFFE11D48)],
  ),
  _Book(
    title: 'Les Secrets de Minuit',
    author: 'Thomas Moreau',
    genre: 'Mystère',
    rating: 4.5,
    reads: 7600,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  ),
  _Book(
    title: 'La Prophétie Oubliée',
    author: 'Claire Bernard',
    genre: 'Fantasy',
    rating: 4.8,
    reads: 11300,
    colors: [Color(0xFF059669), Color(0xFF0D9488)],
  ),
];

class _Book {
  const _Book({
    required this.title,
    required this.author,
    required this.genre,
    required this.rating,
    required this.reads,
    required this.colors,
  });

  final String title;
  final String author;
  final String genre;
  final double rating;
  final int reads;
  final List<Color> colors;
}
