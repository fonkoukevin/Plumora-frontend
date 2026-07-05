import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../beta_reading/data/models/beta_invitation_model.dart';
import '../../beta_reading/data/repositories/beta_reading_repository.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../data/models/favorite_model.dart';
import '../data/models/reading_progress_model.dart';
import '../data/repositories/favorite_repository.dart';
import '../data/repositories/reading_repository.dart';

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

    return FigmaScreen(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bibliotheque',
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
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher un livre ou auteur...',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FigmaPillTab(
                  label: 'Lectures',
                  icon: Icons.menu_book_outlined,
                  selected: _activeTab == 'readings',
                  onTap: () => setState(() => _activeTab = 'readings'),
                ),
                const SizedBox(width: 8),
                FigmaPillTab(
                  label: 'Favoris',
                  icon: Icons.favorite_border,
                  selected: _activeTab == 'favorites',
                  onTap: () => setState(() => _activeTab = 'favorites'),
                ),
                const SizedBox(width: 8),
                FigmaPillTab(
                  label: 'Beta',
                  icon: Icons.edit_note_outlined,
                  selected: _activeTab == 'beta',
                  onTap: () => setState(() => _activeTab = 'beta'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_activeTab == 'readings')
            _ReadingsTab(
              readingsAsync: readingsAsync,
              query: query,
              onRetry: () => ref.invalidate(myReadingProgressProvider),
            )
          else if (_activeTab == 'favorites')
            _FavoritesTab(
              favoritesAsync: favoritesAsync,
              query: query,
              onRetry: () => ref.invalidate(myFavoritesProvider),
            )
          else
            _BetaTab(
              invitationsAsync: invitationsAsync,
              query: query,
              onRetry: () => ref.invalidate(betaInvitationsProvider),
            ),
        ],
      ),
    );
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
                _Stat('Termines', finished.toString(), Icons.bar_chart),
                _Stat('Moyenne', '$average%', Icons.schedule),
              ],
            ),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              const FigmaEmptyState(
                title: 'Aucune lecture',
                message:
                    'Tes lectures reprises depuis le backend apparaitront ici.',
                icon: Icons.menu_book_outlined,
              )
            else
              for (final reading in filtered) ...[
                _ReadingTile(reading: reading),
                const SizedBox(height: 12),
              ],
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
              subtitle: '${favorites.length} livres sauvegardes',
              icon: Icons.favorite,
              colors: const [PlumoraColors.destructive, Color(0xFFB03030)],
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

class _BetaTab extends StatelessWidget {
  const _BetaTab({
    required this.invitationsAsync,
    required this.query,
    required this.onRetry,
  });

  final AsyncValue<List<BetaInvitationModel>> invitationsAsync;
  final String query;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return invitationsAsync.when(
      loading: () => const _Loading(),
      error: (error, _) =>
          _ErrorPanel(message: AppError.messageFor(error), onRetry: onRetry),
      data: (invitations) {
        final filtered = invitations.where((invitation) {
          if (query.isEmpty) {
            return true;
          }
          return invitation.bookTitle.toLowerCase().contains(query) ||
              invitation.authorName.toLowerCase().contains(query);
        }).toList();

        return Column(
          children: [
            _LibraryBanner(
              title: 'Espace Beta-lecture',
              subtitle:
                  '${invitations.length} invitation(s) liee(s) a ton compte',
              icon: Icons.chat_bubble_outline,
              colors: const [PlumoraColors.secondary, PlumoraColors.primary],
            ),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              const FigmaEmptyState(
                title: 'Aucune beta-lecture',
                message:
                    'Tes invitations acceptees ou en attente apparaitront ici.',
                icon: Icons.edit_note_outlined,
              )
            else
              for (final invitation in filtered) ...[
                _BetaTile(invitation: invitation),
                const SizedBox(height: 12),
              ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go(AppRoutes.betaInvitations),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Gerer les invitations'),
              ),
            ),
          ],
        );
      },
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
      onTap: () => context.go(
        AppRoutes.readingPath(reading.bookId, chapterId: reading.chapterId),
      ),
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
                        style: const TextStyle(
                          color: PlumoraColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FigmaBadge(
                      label: complete ? 'Termine' : 'En cours',
                      backgroundColor: complete
                          ? PlumoraColors.success.withValues(alpha: 0.15)
                          : PlumoraColors.primary.withValues(alpha: 0.15),
                      foregroundColor: complete
                          ? PlumoraColors.success
                          : PlumoraColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'par ${reading.authorName}',
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Progression',
                      style: TextStyle(
                        color: PlumoraColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${reading.progressPercent}%',
                      style: const TextStyle(
                        color: PlumoraColors.primary,
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
                    const Icon(
                      Icons.schedule,
                      color: PlumoraColors.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reading.updatedAt == null
                          ? 'Progression sauvegardee'
                          : 'Lu le ${_shortDate(reading.updatedAt!)}',
                      style: const TextStyle(
                        color: PlumoraColors.textSecondary,
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
        final columns = constraints.maxWidth >= 720 ? 6 : 3;
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

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.favorite});

  final FavoriteModel favorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = favorite.book;
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));

    return InkWell(
      onTap: () => context.go(AppRoutes.catalogBookDetailPath(book.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: PlumoraBookCover(
              width: double.infinity,
              height: double.infinity,
              colors: _coverColors(book.id),
              imageUrl: book.coverUrl,
              imageBytes: cachedCover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title.isEmpty ? 'Livre sans titre' : book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          Text(
            book.authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _BetaTile extends ConsumerWidget {
  const _BetaTile({required this.invitation});

  final BetaInvitationModel invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = invitation.chaptersAvailable == 0
        ? 0.0
        : invitation.chaptersRead / invitation.chaptersAvailable;
    final cachedCover = ref.watch(bookCoverBytesProvider(invitation.bookId));

    return FigmaCard(
      onTap: invitation.campaignId.isEmpty
          ? null
          : () => context.go(
              AppRoutes.betaChaptersPath(
                invitation.campaignId,
                invitationId: invitation.id,
                bookId: invitation.bookId,
              ),
            ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          PlumoraBookCover(
            width: 64,
            height: 96,
            radius: 12,
            colors: _coverColors(invitation.bookId),
            imageUrl: invitation.coverUrl,
            imageBytes: cachedCover,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invitation.bookTitle.isEmpty
                            ? 'Manuscrit sans titre'
                            : invitation.bookTitle,
                        style: const TextStyle(
                          color: PlumoraColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FigmaBadge(label: _statusLabel(invitation.status)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'par ${invitation.authorName}',
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 9),
                if (invitation.deadline != null)
                  FigmaBadge(
                    label: 'Deadline : ${_shortDate(invitation.deadline!)}',
                    icon: Icons.schedule,
                    backgroundColor: PlumoraColors.orange.withValues(
                      alpha: 0.12,
                    ),
                    foregroundColor: PlumoraColors.orange,
                  ),
                if (invitation.chaptersAvailable > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${invitation.chaptersRead}/${invitation.chaptersAvailable} chapitres',
                        style: const TextStyle(
                          color: PlumoraColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: PlumoraColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  FigmaProgressBar(
                    value: progress,
                    colors: const [
                      PlumoraColors.secondary,
                      PlumoraColors.primary,
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: PlumoraColors.textSecondary),
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      color: colors.first.withValues(alpha: 0.06),
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
                  style: const TextStyle(
                    color: PlumoraColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
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
    );
  }
}

class _ResponsiveStats extends StatelessWidget {
  const _ResponsiveStats({required this.stats});

  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final children = [
          for (final stat in stats)
            FigmaStatCard(
              label: stat.label,
              value: stat.value,
              icon: stat.icon,
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
              if (index != children.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
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
            'Donnees indisponibles',
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

String _statusLabel(BetaInvitationStatus status) {
  return switch (status) {
    BetaInvitationStatus.pending => 'En attente',
    BetaInvitationStatus.accepted => 'Acceptee',
    BetaInvitationStatus.refused => 'Refusee',
    BetaInvitationStatus.unknown => 'Inconnue',
  };
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
