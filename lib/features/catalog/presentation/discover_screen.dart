import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../data/models/catalog_book_model.dart';
import '../data/models/external_book_model.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/external_book_repository.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _language;
  _DiscoverFilter _activeFilter = _filters.first;

  static const _filters = [
    _DiscoverFilter(label: 'Tous'),
    _DiscoverFilter(label: 'Fantasy', search: 'fantasy'),
    _DiscoverFilter(label: 'Romance', search: 'romance'),
    _DiscoverFilter(label: 'Thriller', search: 'thriller'),
    _DiscoverFilter(label: 'Sci-Fi', search: 'science fiction'),
    _DiscoverFilter(label: 'Mystere', search: 'mystery'),
    _DiscoverFilter(label: 'Aventure', search: 'adventure'),
    _DiscoverFilter(label: 'Horreur', search: 'horror'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = _query.trim();
    final activeCategory = _activeFilter.search;
    final hasCategory = activeCategory != null;
    final plumoraQuery = PlumoraCatalogQuery(
      search: searchQuery,
      genre: hasCategory ? _plumoraGenreForFilter(_activeFilter) : '',
    );

    return FigmaScreen(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Decouvrir',
            style: TextStyle(
              color: PlumoraColors.textPrimary,
              fontFamily: 'Playfair Display',
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitSearch(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Titre, auteur, genre...',
              suffixIcon: IconButton(
                tooltip: 'Rechercher',
                onPressed: _submitSearch,
                icon: const Icon(Icons.arrow_forward, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FigmaCard(
            onTap: () => context.go(AppRoutes.mukemeRecommendation),
            color: PlumoraColors.primary.withValues(alpha: 0.05),
            child: Row(
              children: [
                const FigmaGradientIcon(icon: Icons.auto_awesome, size: 52),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trouver avec Mukeme',
                        style: TextStyle(
                          color: PlumoraColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Recommandations personnalisees par IA',
                        style: TextStyle(
                          color: PlumoraColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.mukemeRecommendation),
                  child: const Text('Essayer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _DiscoverFilterTabs(
            filters: _filters,
            activeFilter: _activeFilter,
            onSelected: (filter) => setState(() => _activeFilter = filter),
          ),
          const SizedBox(height: 12),
          _LanguageTabs(
            language: _language,
            onSelected: (language) => setState(() => _language = language),
          ),
          const SizedBox(height: 26),
          if (hasCategory) ...[
            _PlumoraAsyncRail(
              title: 'Oeuvres Plumora',
              icon: Icons.auto_stories_outlined,
              iconColor: PlumoraColors.secondary,
              query: plumoraQuery,
            ),
            const SizedBox(height: 26),
            _ExternalAsyncRail(
              title: _activeFilter.label,
              icon: _iconForFilter(_activeFilter),
              iconColor: _activeFilter.label == 'Romance'
                  ? PlumoraColors.orange
                  : PlumoraColors.primary,
              query: _queryForCategory(searchQuery, activeCategory),
              rankItems: true,
              subtitle: _language == null
                  ? 'Gutendex'
                  : _language!.toUpperCase(),
            ),
          ] else ...[
            _PlumoraAsyncRail(
              title: 'Oeuvres Plumora',
              icon: Icons.auto_stories_outlined,
              iconColor: PlumoraColors.secondary,
              query: plumoraQuery,
            ),
            const SizedBox(height: 26),
            if (searchQuery.isNotEmpty) ...[
              _ExternalAsyncRail(
                title: 'Resultats',
                icon: Icons.search,
                query: ExternalBookSearchQuery(
                  search: searchQuery,
                  language: _language,
                ),
                rankItems: true,
                subtitle: 'Gutendex',
              ),
              const SizedBox(height: 26),
            ],
            _ExternalAsyncRail(
              title: 'Tendances',
              icon: Icons.trending_up,
              query: ExternalBookSearchQuery(language: _language),
              rankItems: true,
            ),
            const SizedBox(height: 26),
            _ExternalAsyncRail(
              title: 'Nouveautes',
              icon: Icons.bolt_outlined,
              iconColor: PlumoraColors.accent,
              query: ExternalBookSearchQuery(language: _language, page: 1),
              badge: 'NOUVEAU',
              loadDelay: const Duration(milliseconds: 250),
            ),
            const SizedBox(height: 26),
            _ExternalAsyncRail(
              title: 'Fantasy',
              icon: Icons.auto_awesome,
              query: ExternalBookSearchQuery(
                search: 'fantasy',
                language: _language,
              ),
              loadDelay: const Duration(milliseconds: 650),
            ),
            const SizedBox(height: 26),
            _ExternalAsyncRail(
              title: 'Romance',
              icon: Icons.favorite_border,
              iconColor: PlumoraColors.orange,
              query: ExternalBookSearchQuery(
                search: 'romance',
                language: _language,
              ),
              loadDelay: const Duration(milliseconds: 950),
            ),
          ],
        ],
      ),
    );
  }

  String _plumoraGenreForFilter(_DiscoverFilter filter) {
    return filter.label == 'Tous' ? '' : filter.label;
  }

  void _submitSearch() {
    setState(() => _query = _searchController.text.trim());
  }

  ExternalBookSearchQuery _queryForCategory(String search, String category) {
    if (search.isEmpty) {
      return ExternalBookSearchQuery(search: category, language: _language);
    }

    return ExternalBookSearchQuery(
      search: search,
      language: _language,
      topic: category,
    );
  }

  IconData _iconForFilter(_DiscoverFilter filter) {
    switch (filter.label) {
      case 'Romance':
        return Icons.favorite_border;
      case 'Thriller':
        return Icons.local_fire_department_outlined;
      case 'Sci-Fi':
        return Icons.rocket_launch_outlined;
      case 'Mystere':
        return Icons.search;
      case 'Aventure':
        return Icons.explore_outlined;
      case 'Horreur':
        return Icons.nightlight_outlined;
      default:
        return Icons.auto_awesome;
    }
  }
}

class _DiscoverFilter {
  const _DiscoverFilter({required this.label, this.search});

  final String label;
  final String? search;
}

class _DiscoverFilterTabs extends StatelessWidget {
  const _DiscoverFilterTabs({
    required this.filters,
    required this.activeFilter,
    required this.onSelected,
  });

  final List<_DiscoverFilter> filters;
  final _DiscoverFilter activeFilter;
  final ValueChanged<_DiscoverFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            FigmaPillTab(
              label: filter.label,
              selected: activeFilter.label == filter.label,
              onTap: () => onSelected(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _LanguageTabs extends StatelessWidget {
  const _LanguageTabs({required this.language, required this.onSelected});

  final String? language;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Icon(Icons.language, size: 17, color: PlumoraColors.primary),
          const SizedBox(width: 8),
          FigmaPillTab(
            label: 'Toutes langues',
            selected: language == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          FigmaPillTab(
            label: 'FR',
            selected: language == 'fr',
            onTap: () => onSelected('fr'),
          ),
          const SizedBox(width: 8),
          FigmaPillTab(
            label: 'EN',
            selected: language == 'en',
            onTap: () => onSelected('en'),
          ),
        ],
      ),
    );
  }
}

class _PlumoraAsyncRail extends ConsumerWidget {
  const _PlumoraAsyncRail({
    required this.title,
    required this.icon,
    required this.query,
    this.iconColor = PlumoraColors.secondary,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final PlumoraCatalogQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(plumoraCatalogBooksProvider(query));

    return Column(
      children: [
        FigmaSectionHeader(title: title, icon: icon, iconColor: iconColor),
        const SizedBox(height: 14),
        booksAsync.when(
          loading: () => const _LoadingRail(),
          error: (error, _) => _InlineError(
            message: AppError.messageFor(error),
            onRetry: () => ref.invalidate(plumoraCatalogBooksProvider(query)),
          ),
          data: (books) {
            if (books.isEmpty) {
              return const _EmptyRail(
                message: 'Aucune oeuvre Plumora trouvee pour ce filtre.',
              );
            }

            return _PlumoraBookRail(books: books.take(12).toList());
          },
        ),
      ],
    );
  }
}

class _PlumoraBookRail extends StatelessWidget {
  const _PlumoraBookRail({required this.books});

  final List<CatalogBookModel> books;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 262,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _PlumoraBookTile(book: books[index]),
      ),
    );
  }
}

class _PlumoraBookTile extends ConsumerWidget {
  const _PlumoraBookTile({required this.book});

  final CatalogBookModel book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));
    final genre = book.genre?.trim();

    return InkWell(
      onTap: () => context.go(AppRoutes.catalogBookDetailPath(book.id)),
      child: SizedBox(
        width: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              height: 160,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PlumoraBookCover(
                      colors: _coverColors(
                        book.id.isEmpty ? book.title : book.id,
                      ),
                      imageUrl: book.coverUrl,
                      imageBytes: cachedCover,
                      width: 112,
                      height: 160,
                      radius: 16,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _CoverBadge(
                      label: 'Plumora',
                      backgroundColor: PlumoraColors.secondary.withValues(
                        alpha: 0.9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Text(
              book.title.isEmpty ? 'Livre sans titre' : book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PlumoraColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            Text(
              book.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PlumoraColors.textSecondary,
                fontSize: 11,
              ),
            ),
            if (genre != null && genre.isNotEmpty)
              Text(
                genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlumoraColors.textSecondary,
                  fontSize: 10,
                ),
              )
            else
              Text(
                '${book.chapterCount} chapitres',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlumoraColors.textSecondary,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExternalAsyncRail extends ConsumerStatefulWidget {
  const _ExternalAsyncRail({
    required this.title,
    required this.icon,
    required this.query,
    this.iconColor = PlumoraColors.primary,
    this.subtitle,
    this.badge,
    this.rankItems = false,
    this.loadDelay = Duration.zero,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final ExternalBookSearchQuery query;
  final String? subtitle;
  final String? badge;
  final bool rankItems;
  final Duration loadDelay;

  @override
  ConsumerState<_ExternalAsyncRail> createState() => _ExternalAsyncRailState();
}

class _ExternalAsyncRailState extends ConsumerState<_ExternalAsyncRail> {
  Timer? _loadTimer;
  Timer? _retryTimer;
  bool _ready = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _armLoad();
  }

  @override
  void didUpdateWidget(covariant _ExternalAsyncRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.loadDelay != widget.loadDelay) {
      _armLoad();
    }
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  void _armLoad() {
    _loadTimer?.cancel();
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;

    if (widget.loadDelay == Duration.zero) {
      _ready = true;
      return;
    }

    _ready = false;
    _loadTimer = Timer(widget.loadDelay, () {
      if (!mounted) {
        return;
      }
      setState(() => _ready = true);
    });
  }

  void _scheduleAutoRetry() {
    if (_retryTimer != null || _retryCount >= 3) {
      return;
    }

    final delay = Duration(milliseconds: 900 + (_retryCount * 900));
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (!mounted) {
        return;
      }

      setState(() => _retryCount += 1);
      ref.invalidate(externalBookSearchProvider(widget.query));
    });
  }

  void _retryNow() {
    _retryTimer?.cancel();
    _retryTimer = null;
    setState(() => _retryCount = 0);
    ref.invalidate(externalBookSearchProvider(widget.query));
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = _ready
        ? ref.watch(externalBookSearchProvider(widget.query))
        : null;

    return Column(
      children: [
        FigmaSectionHeader(
          title: widget.title,
          icon: widget.icon,
          iconColor: widget.iconColor,
          trailing: widget.subtitle == null
              ? null
              : Text(
                  widget.subtitle!,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
        ),
        const SizedBox(height: 14),
        if (booksAsync == null)
          const _LoadingRail()
        else
          booksAsync.when(
            loading: () => const _LoadingRail(),
            error: (error, _) {
              if (_retryCount < 3) {
                _scheduleAutoRetry();
                return const _LoadingRail();
              }

              return _InlineError(
                message: _externalCatalogErrorMessage(error),
                onRetry: _retryNow,
              );
            },
            data: (page) {
              _retryTimer?.cancel();
              _retryTimer = null;
              if (page.content.isEmpty) {
                return const _EmptyRail();
              }

              return _ExternalBookRail(
                books: page.content.take(12).toList(),
                badge: widget.badge,
                rankItems: widget.rankItems,
              );
            },
          ),
      ],
    );
  }
}

String _externalCatalogErrorMessage(Object error) {
  final message = AppError.messageFor(error);
  if (message.toLowerCase().contains('gutendex')) {
    return 'Catalogue externe momentanement indisponible.';
  }

  return message;
}

class _ExternalBookRail extends StatelessWidget {
  const _ExternalBookRail({
    required this.books,
    required this.rankItems,
    this.badge,
  });

  final List<ExternalBook> books;
  final String? badge;
  final bool rankItems;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 262,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _ExternalBookTile(
            book: books[index],
            rank: rankItems ? index + 1 : null,
            badge: badge,
          );
        },
      ),
    );
  }
}

class _ExternalBookTile extends StatelessWidget {
  const _ExternalBookTile({required this.book, this.rank, this.badge});

  final ExternalBook book;
  final int? rank;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          context.go(AppRoutes.publicDomainBookDetailPath(book.externalId)),
      child: SizedBox(
        width: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExternalCover(book: book, rank: rank, badge: badge),
            const SizedBox(height: 9),
            Text(
              book.title.isEmpty ? 'Livre sans titre' : book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PlumoraColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            Text(
              book.authorLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PlumoraColors.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              '${book.downloadCount} lectures',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PlumoraColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Details',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: PlumoraColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExternalCover extends StatelessWidget {
  const _ExternalCover({required this.book, this.rank, this.badge});

  final ExternalBook book;
  final int? rank;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final effectiveBadge = book.imported
        ? 'Importe'
        : badge ?? 'Domaine public';

    return SizedBox(
      width: 112,
      height: 160,
      child: Stack(
        children: [
          Positioned.fill(
            child: PlumoraBookCover(
              colors: _coverColors(
                book.externalId.isEmpty ? book.title : book.externalId,
              ),
              imageUrl: book.coverUrl,
              width: 112,
              height: 160,
              radius: 16,
            ),
          ),
          if (rank != null)
            Positioned(top: 8, left: 8, child: _RoundBadge(label: '$rank')),
          Positioned(
            top: 8,
            right: 8,
            child: _CoverBadge(
              label: effectiveBadge,
              backgroundColor: book.imported
                  ? PlumoraColors.success.withValues(alpha: 0.9)
                  : PlumoraColors.primary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverBadge extends StatelessWidget {
  const _CoverBadge({required this.label, required this.backgroundColor});

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyRail extends StatelessWidget {
  const _EmptyRail({this.message = 'Aucun livre trouve pour ce filtre.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      shadow: false,
      child: Row(
        children: [
          const Icon(Icons.search_off, color: PlumoraColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: PlumoraColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  const _RoundBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: PlumoraColors.orange,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LoadingRail extends StatelessWidget {
  const _LoadingRail();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 262,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 112,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 112,
                height: 160,
                decoration: BoxDecoration(
                  color: PlumoraColors.muted,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 9),
              const _SkeletonLine(width: 96),
              const SizedBox(height: 5),
              const _SkeletonLine(width: 72),
              const SizedBox(height: 5),
              const _SkeletonLine(width: 58),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: PlumoraColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      color: PlumoraColors.destructive.withValues(alpha: 0.06),
      borderColor: PlumoraColors.destructive.withValues(alpha: 0.18),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: PlumoraColors.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: PlumoraColors.textSecondary),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reessayer')),
        ],
      ),
    );
  }
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
