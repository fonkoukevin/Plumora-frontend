import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../beta_reading/data/repositories/beta_reading_repository.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../../catalog/data/models/catalog_book_model.dart';
import '../../catalog/data/repositories/catalog_repository.dart';
import '../../notification/data/models/notification_model.dart';
import '../../notification/data/repositories/notification_repository.dart';
import '../../reading/data/models/reading_progress_model.dart';
import '../../reading/data/repositories/reading_repository.dart';

const double _homeBookRailHeight = 224;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final displayName = _firstNameFor(session?.user);
    final popularAsync = ref.watch(popularCatalogBooksProvider);
    final latestAsync = ref.watch(latestCatalogBooksProvider);
    final readingsAsync = ref.watch(myReadingProgressProvider);
    final betaAsync = ref.watch(betaInvitationsProvider);
    final notificationsAsync = ref.watch(myNotificationsProvider);
    final unreadCount =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return ColoredBox(
      color: PlumoraColors.background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeHeaderDelegate(
                unreadCount: unreadCount,
                displayName: displayName,
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 92),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _QuoteCard(),
                        const SizedBox(height: 18),
                        readingsAsync.when(
                          loading: () => const _LoadingCard(height: 188),
                          error: (_, _) => _NoReadingCard(
                            onDiscover: () => context.go(AppRoutes.discover),
                          ),
                          data: (readings) {
                            final active =
                                readings
                                    .where((reading) => !reading.finished)
                                    .toList()
                                  ..sort((a, b) {
                                    final aDate = a.updatedAt ?? DateTime(0);
                                    final bDate = b.updatedAt ?? DateTime(0);
                                    return bDate.compareTo(aDate);
                                  });
                            if (active.isEmpty) {
                              return _NoReadingCard(
                                onDiscover: () =>
                                    context.go(AppRoutes.discover),
                              );
                            }
                            return _ContinueReadingCard(reading: active.first);
                          },
                        ),
                        const SizedBox(height: 18),
                        _QuickActions(
                          onWrite: () => context.go(AppRoutes.write),
                          onDiscover: () => context.go(AppRoutes.discover),
                          onMukeme: () =>
                              context.go(AppRoutes.mukemeRecommendation),
                        ),
                        const SizedBox(height: 26),
                        _BookRail(
                          title: 'Tendances',
                          icon: Icons.local_fire_department,
                          iconColor: PlumoraColors.primary,
                          booksAsync: popularAsync,
                          rankItems: true,
                          onSeeAll: () => context.go(AppRoutes.discover),
                          onRetry: () =>
                              ref.invalidate(popularCatalogBooksProvider),
                        ),
                        const SizedBox(height: 24),
                        _BookRail(
                          title: 'Nouveautes',
                          icon: Icons.bolt_outlined,
                          iconColor: PlumoraColors.accent,
                          booksAsync: latestAsync,
                          onSeeAll: () => context.go(AppRoutes.discover),
                          onRetry: () =>
                              ref.invalidate(latestCatalogBooksProvider),
                        ),
                        const SizedBox(height: 24),
                        _ActivityList(notificationsAsync: notificationsAsync),
                        const SizedBox(height: 16),
                        betaAsync.when(
                          loading: () => const _LoadingCard(height: 92),
                          error: (_, _) => _BetaSummaryCard(count: 0),
                          data: (invitations) {
                            final pending = invitations
                                .where((invitation) => invitation.isPending)
                                .length;
                            final accepted = invitations
                                .where((invitation) => invitation.isAccepted)
                                .length;
                            return _BetaSummaryCard(count: pending + accepted);
                          },
                        ),
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
  }

  static String _firstNameFor(dynamic user) {
    final firstname = user?.firstname.trim();
    if (firstname is String && firstname.isNotEmpty) {
      return firstname;
    }

    final username = user?.username?.trim();
    if (username is String && username.isNotEmpty) {
      return username;
    }

    final displayName = user?.displayName.toString().trim();
    if (displayName is String && displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }

    return 'Plumora';
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HomeHeaderDelegate({
    required this.unreadCount,
    required this.displayName,
  });

  final int unreadCount;
  final String displayName;

  static const _height = 98.0;

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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: PlumoraColors.background.withValues(alpha: 0.95),
            border: const Border(
              bottom: BorderSide(color: PlumoraColors.border),
            ),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeHeader(unreadCount: unreadCount),
                    const SizedBox(height: 4),
                    Text(
                      'Bonjour, $displayName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlumoraColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return oldDelegate.unreadCount != unreadCount ||
        oldDelegate.displayName != displayName;
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: FigmaBrandMark(size: 40, textSize: 26)),
        IconButton(
          onPressed: () => context.go(AppRoutes.notifications),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none, size: 23),
              if (unreadCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: PlumoraColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          color: PlumoraColors.textSecondary,
        ),
        InkWell(
          onTap: () => context.go(AppRoutes.profile),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [PlumoraColors.primary, PlumoraColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    return const FigmaCard(
      padding: EdgeInsets.all(20),
      shadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigmaGradientIcon(icon: Icons.format_quote, size: 38, iconSize: 18),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              '"N\'attendez pas l\'inspiration. Elle vient en ecrivant."',
              style: TextStyle(
                color: PlumoraColors.textPrimary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueReadingCard extends ConsumerWidget {
  const _ContinueReadingCard({required this.reading});

  final ReadingProgressModel reading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedCover = ref.watch(bookCoverBytesProvider(reading.bookId));

    return InkWell(
      onTap: () => context.go(
        AppRoutes.readingPath(reading.bookId, chapterId: reading.chapterId),
      ),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 188),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFF4C1D95), Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.26),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PlumoraBookCover(
                    width: 92,
                    height: 138,
                    colors: _coverColors(reading.bookId),
                    imageUrl: reading.coverUrl,
                    imageBytes: cachedCover,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WhiteBadge(
                          icon: Icons.menu_book_outlined,
                          label: 'Continuer la lecture',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          reading.bookTitle.isEmpty
                              ? 'Livre sans titre'
                              : reading.bookTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          reading.chapterId == null
                              ? 'Progression sauvegardee'
                              : 'Chapitre ${reading.chapterIndex + 1}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 170,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: reading.progress,
                              minHeight: 6,
                              color: Colors.white,
                              backgroundColor: const Color(0x33FFFFFF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${reading.progressPercent}% lu',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoReadingCard extends StatelessWidget {
  const _NoReadingCard({required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      onTap: onDiscover,
      child: Row(
        children: [
          const FigmaGradientIcon(icon: Icons.menu_book_outlined),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aucune lecture en cours',
                  style: TextStyle(
                    color: PlumoraColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Decouvre un livre pour commencer.',
                  style: TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: PlumoraColors.textSecondary),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onWrite,
    required this.onDiscover,
    required this.onMukeme,
  });

  final VoidCallback onWrite;
  final VoidCallback onDiscover;
  final VoidCallback onMukeme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            label: 'Ecrire',
            icon: Icons.edit_outlined,
            colors: const [PlumoraColors.primary, PlumoraColors.primaryLight],
            onTap: onWrite,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            label: 'Decouvrir',
            icon: Icons.menu_book_outlined,
            colors: const [PlumoraColors.secondary, Color(0xFF1E3A5F)],
            onTap: onDiscover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            label: 'Mukeme',
            icon: Icons.auto_awesome,
            colors: const [PlumoraColors.accent, Color(0xFFE0B830)],
            onTap: onMukeme,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 21),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookRail extends StatelessWidget {
  const _BookRail({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.booksAsync,
    required this.onSeeAll,
    required this.onRetry,
    this.rankItems = false,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final AsyncValue<List<CatalogBookModel>> booksAsync;
  final VoidCallback onSeeAll;
  final VoidCallback onRetry;
  final bool rankItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FigmaSectionHeader(
          title: title,
          icon: icon,
          iconColor: iconColor,
          trailing: TextButton.icon(
            onPressed: onSeeAll,
            icon: const Icon(Icons.chevron_right, size: 16),
            label: const Text('Tout voir'),
          ),
        ),
        const SizedBox(height: 12),
        booksAsync.when(
          loading: () => const _LoadingCard(height: _homeBookRailHeight),
          error: (_, _) => _InlineRetry(onRetry: onRetry),
          data: (books) {
            if (books.isEmpty) {
              return const FigmaEmptyState(
                title: 'Aucun livre',
                message: 'Le catalogue backend ne renvoie pas encore de livre.',
                icon: Icons.menu_book_outlined,
              );
            }
            return SizedBox(
              height: _homeBookRailHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return _BookTile(
                    book: book,
                    rank: rankItems ? index + 1 : null,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BookTile extends ConsumerWidget {
  const _BookTile({required this.book, this.rank});

  final CatalogBookModel book;
  final int? rank;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));

    return InkWell(
      onTap: () => context.go(AppRoutes.catalogBookDetailPath(book.id)),
      child: SizedBox(
        width: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PlumoraBookCover(
                  width: 112,
                  height: 160,
                  colors: _coverColors(book.id),
                  imageUrl: book.coverUrl,
                  imageBytes: cachedCover,
                ),
                if (rank != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: PlumoraColors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              book.title.isEmpty ? 'Livre sans titre' : book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PlumoraColors.textPrimary,
                fontSize: 12,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              book.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PlumoraColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.notificationsAsync});

  final AsyncValue<List<NotificationModel>> notificationsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FigmaSectionHeader(title: 'Activite recente'),
        const SizedBox(height: 12),
        notificationsAsync.when(
          loading: () => const _LoadingCard(height: 88),
          error: (_, _) => const FigmaEmptyState(
            title: 'Activite indisponible',
            message: 'Les notifications backend ne sont pas accessibles.',
            icon: Icons.notifications_none,
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const FigmaEmptyState(
                title: 'Aucune activite',
                message: 'Tes notifications apparaitront ici.',
                icon: Icons.notifications_none,
              );
            }
            return Column(
              children: [
                for (final notification in notifications.take(3)) ...[
                  FigmaCard(
                    onTap: () => context.go(AppRoutes.notifications),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: PlumoraColors.primary.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_none,
                            color: PlumoraColors.primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: PlumoraColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                notification.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: PlumoraColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: PlumoraColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BetaSummaryCard extends StatelessWidget {
  const _BetaSummaryCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      onTap: () => context.go(AppRoutes.betaInvitations),
      child: Row(
        children: [
          const FigmaGradientIcon(
            icon: Icons.chat_bubble_outline,
            colors: [PlumoraColors.secondary, PlumoraColors.primary],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? 'Aucune beta-lecture active'
                      : '$count beta-lecture(s) a traiter',
                  style: const TextStyle(
                    color: PlumoraColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Consulte tes invitations et retours beta',
                  style: TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: PlumoraColors.textSecondary),
        ],
      ),
    );
  }
}

class _WhiteBadge extends StatelessWidget {
  const _WhiteBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: PlumoraColors.destructive),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Donnees indisponibles.',
              style: TextStyle(color: PlumoraColors.textSecondary),
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
