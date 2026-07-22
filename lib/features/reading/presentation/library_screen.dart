import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../../../core/widgets/app_shell_header.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../beta_reading/data/models/beta_campaign_model.dart';
import '../../beta_reading/data/models/beta_invitation_model.dart';
import '../../beta_reading/data/repositories/beta_reading_repository.dart';
import '../../beta_reading/presentation/beta_engagement_providers.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../data/models/favorite_model.dart';
import '../data/models/reading_progress_model.dart';
import '../data/repositories/favorite_repository.dart';
import '../data/repositories/reading_repository.dart';

const double _libraryMaxContentWidth = 1520;

/// Livre beta-lu par l'utilisateur, qu'il vienne d'une invitation acceptee
/// ou d'une campagne ouverte rejointe et commentee sans invitation.
class _BetaLibraryEntry {
  const _BetaLibraryEntry({
    required this.campaignId,
    required this.bookId,
    required this.bookTitle,
    required this.authorName,
    this.coverUrl,
    this.invitationId,
    this.fallbackDate,
  });

  factory _BetaLibraryEntry.fromInvitation(BetaInvitationModel invitation) {
    return _BetaLibraryEntry(
      campaignId: invitation.campaignId,
      bookId: invitation.bookId,
      bookTitle: invitation.bookTitle,
      authorName: invitation.authorName,
      coverUrl: invitation.coverUrl,
      invitationId: invitation.id,
      fallbackDate: invitation.respondedAt ?? invitation.createdAt,
    );
  }

  factory _BetaLibraryEntry.fromCampaign(BetaCampaignModel campaign) {
    return _BetaLibraryEntry(
      campaignId: campaign.id,
      bookId: campaign.bookId,
      bookTitle: campaign.bookTitle,
      authorName: campaign.authorUsername ?? '',
      coverUrl: campaign.coverUrl,
      fallbackDate: campaign.createdAt,
    );
  }

  final String campaignId;
  final String bookId;
  final String bookTitle;
  final String authorName;
  final String? coverUrl;
  final String? invitationId;
  // Utilise seulement si aucune activite locale (lecture/commentaire) n'a
  // encore ete enregistree pour cette campagne -- voir
  // `touchBetaCampaignActivity`.
  final DateTime? fallbackDate;
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  String _activeTab = 'readings';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(myReadingProgressProvider);
    final favoritesAsync = ref.watch(myFavoritesProvider);
    final invitationsAsync = ref.watch(betaInvitationsProvider);
    final query = _searchController.text.trim().toLowerCase();
    final betaBadgeCount = ref.watch(betaNewOpportunitiesCountProvider);

    return ColoredBox(
      color: context.colors.background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _LibraryHeaderDelegate(
                searchController: _searchController,
                activeTab: _activeTab,
                betaBadgeCount: betaBadgeCount,
                onSearchChanged: () => setState(() {}),
                onTabSelected: (tab) => setState(() => _activeTab = tab),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _libraryMaxContentWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
                    child: _activeTab == 'readings'
                        ? _ReadingsTab(
                            readingsAsync: readingsAsync,
                            query: query,
                            onRetry: () =>
                                ref.invalidate(myReadingProgressProvider),
                          )
                        : _activeTab == 'favorites'
                        ? _FavoritesTab(
                            favoritesAsync: favoritesAsync,
                            query: query,
                            onRetry: () => ref.invalidate(myFavoritesProvider),
                          )
                        : _BetaTab(
                            invitationsAsync: invitationsAsync,
                            query: query,
                            onRetry: () =>
                                ref.invalidate(betaInvitationsProvider),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _LibraryHeaderDelegate({
    required this.searchController,
    required this.activeTab,
    required this.betaBadgeCount,
    required this.onSearchChanged,
    required this.onTabSelected,
  });

  final TextEditingController searchController;
  final String activeTab;
  final int betaBadgeCount;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onTabSelected;

  static const _height = 196.0;

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
    return DecoratedBox(
      decoration: BoxDecoration(
        // Fully opaque: this pins above the book-cover rails, which are
        // saturated enough that any translucency here let them show
        // through legibly on scroll instead of just tinting the blur.
        color: context.colors.background,
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
          constraints: const BoxConstraints(maxWidth: _libraryMaxContentWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlumoraAppHeader(
                  title: 'Bibliothèque',
                  subtitle: 'Vos lectures, vos favoris, votre univers',
                  emoji: '📚',
                  gradient: [context.colors.accent, context.colors.plumora],
                  trailing: const ThemeToggleButton(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Rechercher un livre ou auteur...',
                    ),
                    onChanged: (_) => onSearchChanged(),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FigmaPillTab(
                        label: 'Lectures',
                        icon: Icons.menu_book_outlined,
                        selected: activeTab == 'readings',
                        onTap: () => onTabSelected('readings'),
                      ),
                      const SizedBox(width: 8),
                      FigmaPillTab(
                        label: 'Favoris',
                        icon: Icons.favorite_border,
                        selected: activeTab == 'favorites',
                        onTap: () => onTabSelected('favorites'),
                      ),
                      const SizedBox(width: 8),
                      FigmaPillTab(
                        label: 'Bêta',
                        icon: Icons.edit_note_outlined,
                        selected: activeTab == 'beta',
                        badgeCount: betaBadgeCount,
                        onTap: () => onTabSelected('beta'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LibraryHeaderDelegate oldDelegate) {
    return oldDelegate.searchController != searchController ||
        oldDelegate.activeTab != activeTab ||
        oldDelegate.betaBadgeCount != betaBadgeCount;
  }
}

class _ReadingsTab extends StatelessWidget {
  const _ReadingsTab({
    required this.readingsAsync,
    required this.query,
    required this.onRetry,
  });

  final AsyncValue<List<ReadingProgressModel>> readingsAsync;
  final String query;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return readingsAsync.when(
      loading: () => const _Loading(),
      error: (error, _) =>
          _ErrorPanel(message: AppError.messageFor(error), onRetry: onRetry),
      data: (readings) {
        final filtered = readings.where((reading) {
          if (query.isEmpty) {
            return true;
          }
          return reading.bookTitle.toLowerCase().contains(query) ||
              reading.authorName.toLowerCase().contains(query);
        }).toList();
        final finished = readings.where((reading) => reading.finished).length;
        final active = readings.length - finished;
        final average = readings.isEmpty
            ? 0
            : (readings
                          .map((reading) => reading.progressPercent)
                          .reduce((a, b) => a + b) /
                      readings.length)
                  .round();

        return Column(
          children: [
            _ResponsiveStats(
              stats: [
                _Stat(
                  'En cours',
                  active.toString(),
                  Icons.bookmark_added_outlined,
                ),
                _Stat(
                  'Terminés',
                  finished.toString(),
                  Icons.bar_chart,
                  color: context.colors.accent,
                ),
                _Stat(
                  'Moyenne',
                  '$average%',
                  Icons.schedule,
                  color: context.colors.primaryLight,
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              const FigmaEmptyState(
                title: 'Aucune lecture',
                message:
                    'Tes lectures reprises depuis le backend apparaîtront ici.',
                icon: Icons.menu_book_outlined,
              )
            else
              FigmaResponsiveGrid(
                minTileWidth: 420,
                maxColumns: 3,
                children: [
                  for (final reading in filtered)
                    _ReadingTile(reading: reading),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab({
    required this.favoritesAsync,
    required this.query,
    required this.onRetry,
  });

  final AsyncValue<List<FavoriteModel>> favoritesAsync;
  final String query;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return favoritesAsync.when(
      loading: () => const _Loading(),
      error: (error, _) =>
          _ErrorPanel(message: AppError.messageFor(error), onRetry: onRetry),
      data: (favorites) {
        final filtered = favorites.where((favorite) {
          if (query.isEmpty) {
            return true;
          }
          final book = favorite.book;
          return book.title.toLowerCase().contains(query) ||
              book.authorName.toLowerCase().contains(query);
        }).toList();

        return Column(
          children: [
            _LibraryBanner(
              title: 'Mes Favoris',
              subtitle: '${favorites.length} livres sauvegardés',
              icon: Icons.favorite,
              colors: [context.colors.destructive, const Color(0xFFB03030)],
            ),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              const FigmaEmptyState(
                title: 'Aucun favori',
                message: 'Ajoute un livre en favori depuis sa fiche catalogue.',
                icon: Icons.favorite_border,
              )
            else
              _FavoritesGrid(favorites: filtered),
          ],
        );
      },
    );
  }
}

class _BetaTab extends ConsumerWidget {
  const _BetaTab({
    required this.invitationsAsync,
    required this.query,
    required this.onRetry,
  });

  final AsyncValue<List<BetaInvitationModel>> invitationsAsync;
  final String query;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newOpportunitiesCount = ref.watch(betaNewOpportunitiesCountProvider);
    final engagedCampaignsAsync = ref.watch(betaEngagedCampaignsProvider);
    final pendingCount = ref
        .watch(betaActionablePendingInvitationsProvider)
        .length;
    final activityByCampaignId =
        ref.watch(betaCampaignActivityProvider).valueOrNull ??
        const <String, DateTime>{};

    return invitationsAsync.when(
      loading: () => const _Loading(),
      error: (error, _) =>
          _ErrorPanel(message: AppError.messageFor(error), onRetry: onRetry),
      data: (invitations) {
        final knownCampaignIds = invitations
            .map((invitation) => invitation.campaignId)
            .toSet();
        final entries = [
          for (final invitation in invitations)
            if (invitation.isAccepted)
              _BetaLibraryEntry.fromInvitation(invitation),
          ...engagedCampaignsAsync.maybeWhen(
            data: (campaigns) => campaigns
                .where((campaign) => !knownCampaignIds.contains(campaign.id))
                .map(_BetaLibraryEntry.fromCampaign),
            orElse: () => const Iterable<_BetaLibraryEntry>.empty(),
          ),
        ];
        final filtered =
            entries.where((entry) {
              if (query.isEmpty) {
                return true;
              }
              return entry.bookTitle.toLowerCase().contains(query) ||
                  entry.authorName.toLowerCase().contains(query);
            }).toList()..sort((a, b) {
              final aDate =
                  activityByCampaignId[a.campaignId] ?? a.fallbackDate;
              final bDate =
                  activityByCampaignId[b.campaignId] ?? b.fallbackDate;
              if (aDate == null && bDate == null) {
                return 0;
              }
              if (aDate == null) {
                return 1;
              }
              if (bDate == null) {
                return -1;
              }
              return bDate.compareTo(aDate);
            });

        return Column(
          children: [
            _LibraryBanner(
              title: 'Espace Bêta-lecture',
              subtitle: 'Aidez les auteurs avec vos retours',
              icon: Icons.chat_bubble_outline,
              colors: [context.colors.plumora, context.colors.primary],
              backgroundGradientColors: [Color(0xFF5BA8FF), Color(0xFFC084FC)],
            ),
            if (pendingCount > 0) ...[
              const SizedBox(height: 12),
              _PendingInvitationsBanner(count: pendingCount),
            ],
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              const FigmaEmptyState(
                title: 'Aucune bêta-lecture',
                message:
                    'Les livres que tu as acceptés, commencés à lire ou commentés apparaîtront ici.',
                icon: Icons.edit_note_outlined,
              )
            else
              FigmaResponsiveGrid(
                minTileWidth: 420,
                maxColumns: 3,
                children: [
                  for (final entry in filtered) _BetaTile(entry: entry),
                ],
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push(AppRoutes.betaInvitations),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pendingCount > 0
                          ? 'Gérer les invitations ($pendingCount en attente)'
                          : 'Gérer les invitations',
                    ),
                    if (newOpportunitiesCount > 0) ...[
                      const SizedBox(width: 8),
                      _NewInvitationsBadge(count: newOpportunitiesCount),
                    ],
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

class _NewInvitationsBadge extends StatelessWidget {
  const _NewInvitationsBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.destructive,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _PendingInvitationsBanner extends StatelessWidget {
  const _PendingInvitationsBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      onTap: () => context.push(AppRoutes.betaInvitations),
      color: context.colors.orange.withValues(alpha: 0.08),
      borderColor: context.colors.orange.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.orange.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: context.colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count > 1
                  ? '$count nouveaux livres te sont proposés en bêta-lecture'
                  : "Un nouveau livre t'est proposé en bêta-lecture",
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.orange),
        ],
      ),
    );
  }
}

class _ReadingTile extends ConsumerWidget {
  const _ReadingTile({required this.reading});

  final ReadingProgressModel reading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complete = reading.finished;
    final cachedCover = ref.watch(bookCoverBytesProvider(reading.bookId));

    return FigmaCard(
      onTap: () =>
          context.push(AppRoutes.catalogBookDetailPath(reading.bookId)),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlumoraBookCover(
            width: 64,
            height: 96,
            radius: 12,
            colors: _coverColors(reading.bookId),
            imageUrl: reading.coverUrl,
            imageBytes: cachedCover,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        reading.bookTitle.isEmpty
                            ? 'Livre sans titre'
                            : reading.bookTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FigmaBadge(
                      label: complete ? 'Terminé' : 'En cours',
                      backgroundColor: complete
                          ? context.colors.success.withValues(alpha: 0.15)
                          : context.colors.primary.withValues(alpha: 0.15),
                      foregroundColor: complete
                          ? context.colors.success
                          : context.colors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'par ${reading.authorName}',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Progression',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${reading.progressPercent}%',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                FigmaProgressBar(value: reading.progress),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: context.colors.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reading.updatedAt == null
                          ? 'Progression sauvegardée'
                          : 'Lu le ${_shortDate(reading.updatedAt!)}',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if (reading.rating > 0) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.star, size: 13, color: Colors.amber),
                      Text(
                        ' ${reading.rating.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
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

class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({required this.favorites});

  final List<FavoriteModel> favorites;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1320
            ? 8
            : constraints.maxWidth >= 720
            ? 6
            : 3;
        final spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: 18,
          children: [
            for (final favorite in favorites)
              SizedBox(
                width: width,
                child: _FavoriteTile(favorite: favorite),
              ),
          ],
        );
      },
    );
  }
}

class _FavoriteTile extends ConsumerStatefulWidget {
  const _FavoriteTile({required this.favorite});

  final FavoriteModel favorite;

  @override
  ConsumerState<_FavoriteTile> createState() => _FavoriteTileState();
}

class _FavoriteTileState extends ConsumerState<_FavoriteTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final book = widget.favorite.book;
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: () => context.push(AppRoutes.catalogBookDetailPath(book.id)),
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: context.colors.primary.withValues(alpha: 0.08),
        child: Column(
          key: ValueKey('library_favorite_tile_${book.id}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return PlumoraHoverBookCover(
                    key: ValueKey('library_favorite_cover_${book.id}'),
                    hovered: _hovered,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    radius: 12,
                    actionKey: ValueKey(
                      'library_favorite_hover_cta_${book.id}',
                    ),
                    child: PlumoraBookCover(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      radius: 12,
                      colors: _coverColors(book.id),
                      imageUrl: book.coverUrl,
                      imageBytes: cachedCover,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title.isEmpty ? 'Livre sans titre' : book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _hovered
                    ? context.colors.primary
                    : context.colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            Text(
              book.authorName,
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

class _BetaTile extends ConsumerWidget {
  const _BetaTile({required this.entry});

  final _BetaLibraryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = entry.authorName.trim();
    final cachedCover = ref.watch(bookCoverBytesProvider(entry.bookId));

    return FigmaCard(
      onTap: entry.campaignId.isEmpty
          ? null
          : () => context.push(
              AppRoutes.betaChaptersPath(
                entry.campaignId,
                invitationId: entry.invitationId,
                bookId: entry.bookId,
              ),
            ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          PlumoraBookCover(
            width: 64,
            height: 96,
            radius: 12,
            colors: _coverColors(entry.bookId),
            imageUrl: entry.coverUrl,
            imageBytes: cachedCover,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.bookTitle.isEmpty
                      ? 'Manuscrit sans titre'
                      : entry.bookTitle,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (author.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'par $author',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.textSecondary),
        ],
      ),
    );
  }
}

class _LibraryBanner extends StatelessWidget {
  const _LibraryBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    this.backgroundGradientColors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final List<Color>? backgroundGradientColors;

  @override
  Widget build(BuildContext context) {
    final backgroundColors = backgroundGradientColors;
    return FigmaCard(
      color: colors.first.withValues(alpha: 0.06),
      gradient: backgroundColors == null
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: backgroundColors
                  .map((color) => color.withValues(alpha: 0.06))
                  .toList(),
            ),
      child: Row(
        children: [
          FigmaGradientIcon(icon: icon, colors: colors, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveStats extends StatelessWidget {
  const _ResponsiveStats({required this.stats});

  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < stats.length; index++) ...[
          Expanded(child: _LibraryStatCard(stat: stats[index])),
          if (index != stats.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _LibraryStatCard extends StatelessWidget {
  const _LibraryStatCard({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      shadow: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            stat.icon,
            size: 17,
            color: stat.color ?? context.colors.primary,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat.value,
              maxLines: 1,
              style: TextStyle(
                color: stat.color ?? context.colors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat.label,
              maxLines: 1,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon, {this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
}

class _Loading extends StatelessWidget {
  const _Loading();

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
            'Données indisponibles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: context.colors.textSecondary)),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
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
