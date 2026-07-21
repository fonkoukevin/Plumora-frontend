import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/app_shell_header.dart';
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
    _DiscoverFilter(label: 'Mystère', search: 'mystery'),
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
      language: _language ?? '',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final inlineHeaderControls = constraints.maxWidth >= 900;

        return ColoredBox(
          color: context.colors.background,
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _DiscoverHeaderDelegate(
                    searchController: _searchController,
                    onSearch: _submitSearch,
                    onPlumoTap: () =>
                        context.push(AppRoutes.plumoRecommendation),
                    inlineControls: inlineHeaderControls,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DiscoverFilterTabs(
                              filters: _filters,
                              activeFilter: _activeFilter,
                              onSelected: (filter) =>
                                  setState(() => _activeFilter = filter),
                            ),
                            const SizedBox(height: 12),
                            _LanguageTabs(
                              language: _language,
                              onSelected: (language) =>
                                  setState(() => _language = language),
                            ),
                            const SizedBox(height: 30),
                            if (hasCategory) ...[
                              _PlumoraAsyncRail(
                                title: 'Œuvres Plumora',
                                icon: Icons.auto_stories_outlined,
                                iconColor: context.colors.plumora,
                                query: plumoraQuery,
                              ),
                              const SizedBox(height: 32),
                              _ExternalAsyncRail(
                                title: _activeFilter.label,
                                icon: _iconForFilter(_activeFilter),
                                iconColor: _activeFilter.label == 'Romance'
                                    ? const Color(0xFFEC4899)
                                    : context.colors.primary,
                                query: _queryForCategory(
                                  searchQuery,
                                  activeCategory,
                                ),
                                rankItems: true,
                                subtitle: _language == null
                                    ? 'Gutendex'
                                    : _language!.toUpperCase(),
                              ),
                            ] else ...[
                              _PlumoraAsyncRail(
                                title: 'Œuvres Plumora',
                                icon: Icons.auto_stories_outlined,
                                iconColor: context.colors.plumora,
                                query: plumoraQuery,
                              ),
                              const SizedBox(height: 32),
                              if (searchQuery.isNotEmpty) ...[
                                _ExternalAsyncRail(
                                  title: 'Résultats',
                                  icon: Icons.search,
                                  query: ExternalBookSearchQuery(
                                    search: searchQuery,
                                    language: _language,
                                  ),
                                  rankItems: true,
                                  subtitle: 'Gutendex',
                                ),
                                const SizedBox(height: 32),
                              ],
                              _ExternalAsyncRail(
                                title: 'Tendances',
                                icon: Icons.trending_up,
                                query: ExternalBookSearchQuery(
                                  language: _language,
                                ),
                                rankItems: true,
                                subtitle: "Mis à jour aujourd'hui",
                              ),
                              const SizedBox(height: 32),
                              _ExternalAsyncRail(
                                title: 'Nouveautés',
                                icon: Icons.bolt_outlined,
                                iconColor: context.colors.accent,
                                query: ExternalBookSearchQuery(
                                  language: _language,
                                  page: 1,
                                ),
                                badge: 'NOUVEAU',
                                loadDelay: const Duration(milliseconds: 250),
                              ),
                              const SizedBox(height: 32),
                              _ExternalAsyncRail(
                                title: 'Fantasy',
                                icon: Icons.auto_awesome,
                                query: ExternalBookSearchQuery(
                                  search: 'fantasy',
                                  language: _language,
                                ),
                                loadDelay: const Duration(milliseconds: 650),
                              ),
                              const SizedBox(height: 32),
                              _ExternalAsyncRail(
                                title: 'Romance',
                                icon: Icons.favorite,
                                iconColor: const Color(0xFFEC4899),
                                query: ExternalBookSearchQuery(
                                  search: 'romance',
                                  language: _language,
                                ),
                                loadDelay: const Duration(milliseconds: 950),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _plumoraGenreForFilter(_DiscoverFilter filter) {
    return switch (filter.label) {
      'Tous' => '',
      'Sci-Fi' => 'Science-Fiction',
      'Mystère' => 'Mystère',
      _ => filter.label,
    };
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
        return Icons.favorite;
      case 'Thriller':
        return Icons.local_fire_department_outlined;
      case 'Sci-Fi':
        return Icons.rocket_launch_outlined;
      case 'Mystère':
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

class _DiscoverHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DiscoverHeaderDelegate({
    required this.searchController,
    required this.onSearch,
    required this.onPlumoTap,
    required this.inlineControls,
  });

  final TextEditingController searchController;
  final VoidCallback onSearch;
  final VoidCallback onPlumoTap;
  final bool inlineControls;

  double get _height => inlineControls ? 150 : 234;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final searchField = SizedBox(
      key: const ValueKey('discover_search_field'),
      height: 50,
      child: TextField(
        controller: searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSearch(),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Titre, auteur, genre...',
          suffixIcon: IconButton(
            tooltip: 'Rechercher',
            onPressed: onSearch,
            icon: const Icon(Icons.arrow_forward, size: 18),
          ),
        ),
      ),
    );

    return ClipRect(
      key: const ValueKey('discover_header'),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.background.withValues(alpha: 0.95),
            border: Border(bottom: BorderSide(color: context.colors.border)),
            boxShadow: overlapsContent
                ? const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlumoraAppHeader(
                      title: 'Découvrir',
                      subtitle: "Explorez des milliers d'histoires inédites",
                      emoji: '🔍',
                      gradient: [
                        context.colors.plumora,
                        context.colors.primary,
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (inlineControls)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 12.0;
                          final controlWidth = (constraints.maxWidth - gap) / 2;

                          return SizedBox(
                            height: 50,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: controlWidth,
                                  child: searchField,
                                ),
                                const SizedBox(width: gap),
                                SizedBox(
                                  width: controlWidth,
                                  child: _PlumoHeaderCard(
                                    onTap: onPlumoTap,
                                    compact: true,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else ...[
                      searchField,
                      const SizedBox(height: 12),
                      _PlumoHeaderCard(onTap: onPlumoTap),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DiscoverHeaderDelegate oldDelegate) {
    return oldDelegate.searchController != searchController ||
        oldDelegate.onSearch != onSearch ||
        oldDelegate.onPlumoTap != onPlumoTap ||
        oldDelegate.inlineControls != inlineControls;
  }
}

class _PlumoHeaderCard extends StatelessWidget {
  const _PlumoHeaderCard({required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      key: const ValueKey('discover_plumo_banner'),
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 14,
      ),
      radius: compact ? 14 : 16,
      color: context.colors.brandPrimary.withValues(alpha: 0.05),
      borderColor: context.colors.border,
      shadow: false,
      child: Row(
        children: [
          FigmaGradientIcon(
            icon: Icons.auto_awesome,
            size: compact ? 36 : 48,
            iconSize: compact ? 18 : 24,
            radius: compact ? 11 : 16,
            colors: [
              context.colors.brandPrimary,
              context.colors.brandPrimaryLight,
            ],
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Trouver avec Plumo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: compact ? 13 : 16,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: compact ? 2 : 4),
                Text(
                  'Recommandations personnalisées par IA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: compact ? 10 : 13,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          _PlumoTryButton(onTap: onTap, compact: compact),
        ],
      ),
    );
  }
}

class _PlumoTryButton extends StatelessWidget {
  const _PlumoTryButton({required this.onTap, required this.compact});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.brandPrimary,
            context.colors.brandPrimaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 7 : 10,
            ),
            child: Text(
              'Essayer',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
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
          Icon(Icons.language, size: 17, color: context.colors.primary),
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

class _RomanceHeaderIcon extends StatelessWidget {
  const _RomanceHeaderIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 18,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 1,
            child: Icon(Icons.favorite, size: 9, color: Color(0xFFF43F5E)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(Icons.favorite, size: 14, color: Color(0xFFEC4899)),
          ),
        ],
      ),
    );
  }
}

class _FantasyHeaderIcon extends StatelessWidget {
  const _FantasyHeaderIcon();

  @override
  Widget build(BuildContext context) {
    return const Text('🧙', style: TextStyle(fontSize: 18, height: 1));
  }
}

Widget? _categoryHeaderIcon(String title) {
  return switch (title) {
    'Romance' => const _RomanceHeaderIcon(),
    'Fantasy' => const _FantasyHeaderIcon(),
    _ => null,
  };
}

bool _showCategoryHeaderAccent(String title) {
  return title != 'Romance' && title != 'Fantasy';
}

class _DiscoverSectionFrame extends StatelessWidget {
  const _DiscoverSectionFrame({
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FigmaSectionHeader(
          title: title,
          icon: icon,
          iconWidget: _categoryHeaderIcon(title),
          iconColor: iconColor ?? context.colors.primary,
          showAccent: _showCategoryHeaderAccent(title),
          trailing: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _PlumoraAsyncRail extends ConsumerWidget {
  const _PlumoraAsyncRail({
    required this.title,
    required this.icon,
    required this.query,
    this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final PlumoraCatalogQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(plumoraCatalogBooksProvider(query));
    final resolvedIconColor = iconColor ?? context.colors.plumora;

    return booksAsync.when(
      loading: () => _DiscoverSectionFrame(
        title: title,
        icon: icon,
        iconColor: resolvedIconColor,
        child: const _LoadingRail(),
      ),
      error: (error, _) => _DiscoverSectionFrame(
        title: title,
        icon: icon,
        iconColor: resolvedIconColor,
        child: _InlineError(
          message: AppError.messageFor(error),
          onRetry: () => ref.invalidate(plumoraCatalogBooksProvider(query)),
        ),
      ),
      data: (books) {
        if (books.isEmpty) {
          return _DiscoverSectionFrame(
            title: title,
            icon: icon,
            iconColor: resolvedIconColor,
            child: const _EmptyRail(
              message: 'Aucune œuvre Plumora trouvée pour ce filtre.',
            ),
          );
        }

        return _PlumoraBookRail(
          title: title,
          icon: icon,
          iconColor: resolvedIconColor,
          books: books,
        );
      },
    );
  }
}

class _PlumoraBookRail extends StatelessWidget {
  const _PlumoraBookRail({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.books,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<CatalogBookModel> books;

  @override
  Widget build(BuildContext context) {
    return _DiscoverCarouselRail(
      title: title,
      icon: icon,
      iconColor: iconColor,
      itemCount: books.length,
      keyPrefix: 'plumora_books',
      itemBuilder: (context, index) => _PlumoraBookTile(book: books[index]),
    );
  }
}

class _DiscoverCarouselRail extends StatefulWidget {
  const _DiscoverCarouselRail({
    required this.title,
    required this.icon,
    required this.itemCount,
    required this.itemBuilder,
    this.iconColor,
    this.subtitle,
    this.keyPrefix,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final String? keyPrefix;

  @override
  State<_DiscoverCarouselRail> createState() => _DiscoverCarouselRailState();
}

class _DiscoverCarouselRailState extends State<_DiscoverCarouselRail> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollBack = false;
  bool _canScrollForward = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
    _scheduleScrollButtonUpdate();
  }

  @override
  void didUpdateWidget(covariant _DiscoverCarouselRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleScrollButtonUpdate();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateScrollButtons)
      ..dispose();
    super.dispose();
  }

  void _scheduleScrollButtonUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateScrollButtons();
      }
    });
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final canScrollBack = position.pixels > position.minScrollExtent + 1;
    final canScrollForward = position.pixels < position.maxScrollExtent - 1;
    if (canScrollBack == _canScrollBack &&
        canScrollForward == _canScrollForward) {
      return;
    }

    setState(() {
      _canScrollBack = canScrollBack;
      _canScrollForward = canScrollForward;
    });
  }

  Future<void> _scrollByPage(double direction) async {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final target =
        (position.pixels + position.viewportDimension * 0.82 * direction)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _setHovered(bool hovered) {
    if (_hovered == hovered) {
      return;
    }
    setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showClickControls = constraints.maxWidth >= 560;
        final showPrevious = showClickControls && _canScrollBack;
        final showNext = showClickControls && _canScrollForward;

        return Column(
          children: [
            FigmaSectionHeader(
              title: widget.title,
              icon: widget.icon,
              iconWidget: _categoryHeaderIcon(widget.title),
              iconColor: widget.iconColor ?? context.colors.primary,
              showAccent: _showCategoryHeaderAccent(widget.title),
              trailing: widget.subtitle == null
                  ? null
                  : Text(
                      widget.subtitle!,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 262,
              child: MouseRegion(
                onEnter: (_) => _setHovered(true),
                onExit: (_) => _setHovered(false),
                child: Stack(
                  children: [
                    ListView.separated(
                      key: widget.keyPrefix == null
                          ? null
                          : ValueKey('${widget.keyPrefix}_scroll'),
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.itemCount,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: widget.itemBuilder,
                    ),
                    if (showPrevious)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        width: 48,
                        child: AnimatedOpacity(
                          key: widget.keyPrefix == null
                              ? null
                              : ValueKey('${widget.keyPrefix}_previous'),
                          opacity: _hovered ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: IgnorePointer(
                            ignoring: !_hovered,
                            child: _DiscoverRailButton(
                              icon: Icons.chevron_left_rounded,
                              tooltip: 'Livres précédents',
                              onTap: () => _scrollByPage(-1),
                            ),
                          ),
                        ),
                      ),
                    if (showNext)
                      Positioned(
                        top: 0,
                        right: 0,
                        bottom: 0,
                        width: 48,
                        child: AnimatedOpacity(
                          key: widget.keyPrefix == null
                              ? null
                              : ValueKey('${widget.keyPrefix}_next'),
                          opacity: _hovered ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: IgnorePointer(
                            ignoring: !_hovered,
                            child: _DiscoverRailButton(
                              icon: Icons.chevron_right_rounded,
                              tooltip: 'Livres suivants',
                              onTap: () => _scrollByPage(1),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DiscoverRailButton extends StatelessWidget {
  const _DiscoverRailButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Center(
        child: SizedBox.square(
          dimension: 40,
          child: IconButton(
            onPressed: onTap,
            padding: EdgeInsets.zero,
            icon: Icon(
              icon,
              size: 32,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Color(0xB3000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            hoverColor: Colors.white.withValues(alpha: 0.10),
            highlightColor: Colors.white.withValues(alpha: 0.16),
          ),
        ),
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
      onTap: () => context.push(AppRoutes.catalogBookDetailPath(book.id)),
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
                      backgroundColor: context.colors.plumora.withValues(
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
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            Text(
              book.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 11,
              ),
            ),
            if (genre != null && genre.isNotEmpty)
              Text(
                genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 10,
                ),
              )
            else
              Text(
                '${book.chapterCount} chapitres',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textSecondary,
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
    this.iconColor,
    this.subtitle,
    this.badge,
    this.rankItems = false,
    this.loadDelay = Duration.zero,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
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
    final iconColor = widget.iconColor ?? context.colors.primary;

    if (booksAsync == null) {
      return _DiscoverSectionFrame(
        title: widget.title,
        icon: widget.icon,
        iconColor: iconColor,
        subtitle: widget.subtitle,
        child: const _LoadingRail(),
      );
    }

    return booksAsync.when(
      loading: () => _DiscoverSectionFrame(
        title: widget.title,
        icon: widget.icon,
        iconColor: iconColor,
        subtitle: widget.subtitle,
        child: const _LoadingRail(),
      ),
      error: (error, _) {
        if (_retryCount < 3) {
          _scheduleAutoRetry();
          return _DiscoverSectionFrame(
            title: widget.title,
            icon: widget.icon,
            iconColor: iconColor,
            subtitle: widget.subtitle,
            child: const _LoadingRail(),
          );
        }

        return _DiscoverSectionFrame(
          title: widget.title,
          icon: widget.icon,
          iconColor: iconColor,
          subtitle: widget.subtitle,
          child: _InlineError(
            message: _externalCatalogErrorMessage(error),
            onRetry: _retryNow,
          ),
        );
      },
      data: (page) {
        _retryTimer?.cancel();
        _retryTimer = null;
        if (page.content.isEmpty) {
          return _DiscoverSectionFrame(
            title: widget.title,
            icon: widget.icon,
            iconColor: iconColor,
            subtitle: widget.subtitle,
            child: const _EmptyRail(),
          );
        }

        return _ExternalBookRail(
          title: widget.title,
          icon: widget.icon,
          iconColor: iconColor,
          subtitle: widget.subtitle,
          books: page.content.take(12).toList(),
          badge: widget.badge,
          rankItems: widget.rankItems,
        );
      },
    );
  }
}

String _externalCatalogErrorMessage(Object error) {
  final message = AppError.messageFor(error);
  if (message.toLowerCase().contains('gutendex')) {
    return 'Catalogue externe momentanément indisponible.';
  }

  return message;
}

class _ExternalBookRail extends StatelessWidget {
  const _ExternalBookRail({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.books,
    required this.rankItems,
    this.subtitle,
    this.badge,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final List<ExternalBook> books;
  final String? badge;
  final bool rankItems;

  @override
  Widget build(BuildContext context) {
    return _DiscoverCarouselRail(
      title: title,
      icon: icon,
      iconColor: iconColor,
      subtitle: subtitle,
      itemCount: books.length,
      itemBuilder: (context, index) {
        return _ExternalBookTile(
          book: books[index],
          rank: rankItems ? index + 1 : null,
          badge: badge,
        );
      },
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
      onTap: book.canOpenExternalDetail
          ? () {
              final internalBookId = book.internalBookId?.trim();
              context.push(
                book.imported &&
                        internalBookId != null &&
                        internalBookId.isNotEmpty
                    ? AppRoutes.catalogBookDetailPath(internalBookId)
                    : AppRoutes.publicDomainBookDetailPath(book.externalId),
              );
            }
          : null,
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
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            Text(
              book.authorLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              '${book.downloadCount} lectures',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 10,
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
        ? 'Importé'
        : book.canOpenExternalDetail
        ? badge ?? 'Domaine public'
        : 'Bientôt disponible';

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
                  ? context.colors.success.withValues(alpha: 0.9)
                  : book.canOpenExternalDetail
                  ? context.colors.primary.withValues(alpha: 0.9)
                  : context.colors.textSecondary.withValues(alpha: 0.9),
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
  const _EmptyRail({this.message = 'Aucun livre trouvé pour ce filtre.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      shadow: false,
      child: Row(
        children: [
          Icon(Icons.search_off, color: context.colors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: context.colors.textSecondary),
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
      decoration: BoxDecoration(
        color: context.colors.primary,
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
    return FigmaAdaptiveRail(
      itemCount: 6,
      railHeight: 262,
      itemBuilder: (context, index) => SizedBox(
        width: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 112,
              height: 160,
              decoration: BoxDecoration(
                color: context.colors.muted,
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
        color: context.colors.muted,
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
      color: context.colors.destructive.withValues(alpha: 0.06),
      borderColor: context.colors.destructive.withValues(alpha: 0.18),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.colors.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
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
