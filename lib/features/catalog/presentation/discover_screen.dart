import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../data/models/catalog_book_model.dart';
import '../data/repositories/catalog_repository.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _selectedGenre = '';

  static const _genres = [
    '',
    'Fantasy',
    'Romance',
    'Thriller',
    'Science-Fiction',
    'Mystère',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latestAsync = ref.watch(latestCatalogBooksProvider);
    final popularAsync = ref.watch(popularCatalogBooksProvider);
    final genreAsync = ref.watch(catalogBooksProvider(_selectedGenre));

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
                  _SearchBlock(
                    controller: _searchController,
                    isWide: isWide,
                    onSearch: _openSearch,
                    onMukeme: () => context.go(AppRoutes.mukemeRecommendation),
                  ),
                  const SizedBox(height: 22),
                  _GenreFilters(
                    genres: _genres,
                    selectedGenre: _selectedGenre,
                    onSelected: (genre) => setState(() {
                      _selectedGenre = genre;
                    }),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Nouveautés',
                    trailingIcon: Icons.auto_stories_outlined,
                    trailing: 'Dernières publications',
                  ),
                  const SizedBox(height: 16),
                  _BooksAsyncGrid(
                    booksAsync: latestAsync,
                    compactCards: false,
                    onRetry: () => ref.invalidate(latestCatalogBooksProvider),
                  ),
                  const SizedBox(height: 30),
                  _SectionHeader(
                    title: 'Populaires',
                    trailingIcon: Icons.trending_up,
                    trailing: "Mis à jour aujourd'hui",
                  ),
                  const SizedBox(height: 16),
                  _BooksAsyncGrid(
                    booksAsync: popularAsync,
                    compactCards: false,
                    onRetry: () => ref.invalidate(popularCatalogBooksProvider),
                  ),
                  const SizedBox(height: 30),
                  _SectionHeader(
                    title: _selectedGenre.isEmpty
                        ? 'Tous les genres'
                        : _selectedGenre,
                  ),
                  const SizedBox(height: 16),
                  _BooksAsyncGrid(
                    booksAsync: genreAsync,
                    compactCards: true,
                    onRetry: () =>
                        ref.invalidate(catalogBooksProvider(_selectedGenre)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openSearch() {
    final query = _searchController.text.trim();
    context.go(AppRoutes.catalogSearchPath(query));
  }
}

class _SearchBlock extends StatelessWidget {
  const _SearchBlock({
    required this.controller,
    required this.isWide,
    required this.onSearch,
    required this.onMukeme,
  });

  final TextEditingController controller;
  final bool isWide;
  final VoidCallback onSearch;
  final VoidCallback onMukeme;

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSearch(),
      decoration: InputDecoration(
        hintText: 'Rechercher un livre, un auteur, un genre...',
        prefixIcon: const Icon(
          Icons.search,
          color: PlumoraColors.textSecondary,
        ),
        suffixIcon: IconButton(
          tooltip: 'Rechercher',
          onPressed: onSearch,
          icon: const Icon(Icons.arrow_forward, size: 18),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final mukemeButton = OutlinedButton.icon(
      onPressed: onMukeme,
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
  const _GenreFilters({
    required this.genres,
    required this.selectedGenre,
    required this.onSelected,
  });

  final List<String> genres;
  final String selectedGenre;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final genre in genres) ...[
            _GenreChip(
              label: genre.isEmpty ? 'Tous' : genre,
              selected: selectedGenre == genre,
              onTap: () => onSelected(genre),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
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
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? PlumoraColors.primary : PlumoraColors.muted,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : PlumoraColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
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

class _BooksAsyncGrid extends StatelessWidget {
  const _BooksAsyncGrid({
    required this.booksAsync,
    required this.compactCards,
    required this.onRetry,
  });

  final AsyncValue<List<CatalogBookModel>> booksAsync;
  final bool compactCards;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return booksAsync.when(
      loading: () => const _LoadingPanel(),
      error: (error, _) =>
          _ErrorPanel(message: AppError.messageFor(error), onRetry: onRetry),
      data: (books) {
        if (books.isEmpty) {
          return const _EmptyPanel(
            title: 'Aucun livre disponible',
            subtitle: 'Les publications Plumora apparaîtront ici.',
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = compactCards
                ? constraints.maxWidth >= 980
                      ? 6
                      : constraints.maxWidth >= 650
                      ? 4
                      : 2
                : constraints.maxWidth >= 980
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
                for (final book in books)
                  SizedBox(
                    width: width,
                    child: compactCards
                        ? _BookCoverCard(book: book)
                        : _BookListCard(book: book),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BookListCard extends StatelessWidget {
  const _BookListCard({required this.book});

  final CatalogBookModel book;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.go(AppRoutes.catalogBookDetailPath(book.id)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CatalogCover(book: book, width: 76, height: 104),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title.isEmpty ? 'Livre sans titre' : book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: PlumoraColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.authorName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PlumoraColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                if (book.genre != null)
                  PlumoraBadge(
                    label: book.genre!,
                    foregroundColor: const Color(0xFF7A5E2F),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF5C84C), size: 17),
                    const SizedBox(width: 4),
                    Text(
                      book.rating == 0 ? '-' : book.rating.toStringAsFixed(1),
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
                      _formatReads(book.readCount),
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

  final CatalogBookModel book;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      padding: EdgeInsets.zero,
      clip: true,
      onTap: () => context.go(AppRoutes.catalogBookDetailPath(book.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: _CatalogCover(book: book, expand: true),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.authorName,
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
                      book.rating == 0 ? '-' : book.rating.toStringAsFixed(1),
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

class _CatalogCover extends StatelessWidget {
  const _CatalogCover({
    required this.book,
    this.width,
    this.height,
    this.expand = false,
  });

  final CatalogBookModel book;
  final double? width;
  final double? height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = _coverColors(book);
    return Container(
      width: expand ? double.infinity : width,
      height: expand ? double.infinity : height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(expand ? 0 : 14),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: expand
            ? null
            : const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, 7),
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
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
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
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catalogue indisponible',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: PlumoraColors.textSecondary),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: PlumoraColors.textSecondary),
          ),
        ],
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
