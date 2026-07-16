import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/app_shell_header.dart';
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

    return ColoredBox(
      color: context.colors.background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeHeaderDelegate(displayName: displayName),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      MediaQuery.sizeOf(context).width >= 420 ? 16 : 20,
                      16,
                      MediaQuery.sizeOf(context).width >= 420 ? 16 : 20,
                      92,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _QuoteCard(),
                        const SizedBox(height: 22),
                        readingsAsync.when(
                          loading: () => const _LoadingCard(height: 146),
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
                          onPlumo: () =>
                              context.go(AppRoutes.plumoRecommendation),
                        ),
                        const SizedBox(height: 26),
                        _BookRail(
                          title: 'Tendances',
                          icon: Icons.local_fire_department,
                          iconColor: context.colors.primary,
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
                          iconColor: context.colors.accent,
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
  const _HomeHeaderDelegate({required this.displayName});

  final String displayName;

  static const _height = 78.0;

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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: PlumoraAppHeader(
                  title: 'Tableau de bord',
                  subtitle:
                      'Bonjour $displayName 👋 — Que voulez-vous '
                      "faire aujourd'hui ?",
                  emoji: '✨',
                  gradient: [context.colors.primary, context.colors.plumora],
                  trailing: const _ThemeToggleButton(),
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
    return oldDelegate.displayName != displayName;
  }
}

class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Semantics(
      button: true,
      label: isDark ? 'Activer le theme clair' : 'Activer le theme sombre',
      child: Tooltip(
        message: isDark ? 'Thème clair' : 'Thème sombre',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            hoverColor: context.colors.muted.withValues(alpha: 0.6),
            onTap: () async {
              try {
                await ref.read(themeModeControllerProvider.notifier).toggle();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impossible d’enregistrer le thème.'),
                    ),
                  );
                }
              }
            },
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 20,
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final factor = ((constraints.maxWidth - 282) / (456 - 282)).clamp(
          0.0,
          1.0,
        );
        final height = lerpDouble(90, 128, factor)!;
        final horizontalPadding = lerpDouble(17, 24, factor)!;
        final verticalPadding = lerpDouble(16, 20, factor)!;
        final radius = lerpDouble(14, 18, factor)!;
        final iconSize = lerpDouble(30, 44, factor)!;
        final iconGlyphSize = lerpDouble(17, 22, factor)!;
        final gap = lerpDouble(11, 18, factor)!;
        final quoteFontSize = lerpDouble(12, 15.5, factor)!;
        final authorFontSize = lerpDouble(10, 14, factor)!;
        final authorGap = lerpDouble(4, 8, factor)!;
        final textAreaWidth =
            constraints.maxWidth - (horizontalPadding * 2) - iconSize - gap;

        return SizedBox(
          height: height,
          child: FigmaCard(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            radius: radius,
            borderColor: context.colors.accent.withValues(
              alpha: isDark ? 0.25 : 0.4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuoteIcon(size: iconSize, iconSize: iconGlyphSize),
                SizedBox(width: gap),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: textAreaWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"N\'attendez pas l\'inspiration. Elle vient en écrivant."',
                            maxLines: 2,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: quoteFontSize,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.15,
                              height: 1.42,
                            ),
                          ),
                          SizedBox(height: authorGap),
                          Text(
                            '— Victor Hugo',
                            maxLines: 1,
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: authorFontSize,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ],
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
}

class _QuoteIcon extends StatelessWidget {
  const _QuoteIcon({required this.size, required this.iconSize});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = context.colors.accent;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: isDark ? 0.35 : 0.30),
            blurRadius: isDark ? 14 : 10,
            offset: Offset(0, isDark ? 5 : 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.format_quote_rounded, size: iconSize, color: tint),
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
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 146,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF250047), Color(0xFF790FC0), Color(0xFF30267E)],
              stops: [0, 0.58, 1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.2,
                      colors: [Color(0x287C3AED), Color(0x001F174A)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 15,
                child: Container(
                  foregroundDecoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF8B38E9)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: PlumoraBookCover(
                    width: 77,
                    height: 114,
                    radius: 10,
                    colors: _coverColors(reading.bookId),
                    imageUrl: reading.coverUrl,
                    imageBytes: cachedCover,
                  ),
                ),
              ),
              Positioned(
                left: 105,
                right: 46,
                top: 36,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WhiteBadge(
                      icon: Icons.menu_book_outlined,
                      label: 'Continuer la lecture',
                    ),
                    const SizedBox(height: 7),
                    Text(
                      reading.bookTitle.isEmpty
                          ? 'Livre sans titre'
                          : reading.bookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    Text(
                      reading.chapterId == null
                          ? 'Progression sauvegardée'
                          : 'Chapitre ${reading.chapterIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: reading.progress,
                        minHeight: 5,
                        color: Colors.white,
                        backgroundColor: const Color(0x33FFFFFF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reading.progressPercent}% lu',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 7,
                top: 57,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aucune lecture en cours',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Decouvre un livre pour commencer.',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.textSecondary),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onWrite,
    required this.onDiscover,
    required this.onPlumo,
  });

  final VoidCallback onWrite;
  final VoidCallback onDiscover;
  final VoidCallback onPlumo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            label: 'Ecrire',
            icon: Icons.edit_outlined,
            colors: [
              context.colors.brandPrimary,
              context.colors.brandPrimaryLight,
            ],
            onTap: onWrite,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            label: 'Decouvrir',
            icon: Icons.menu_book_outlined,
            colors: [context.colors.brandNavy, context.colors.brandNavyLight],
            onTap: onDiscover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            label: 'Plumo',
            icon: Icons.auto_awesome,
            colors: [context.colors.brandGold, context.colors.brandGoldLight],
            onTap: onPlumo,
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
            return FigmaAdaptiveRail(
              itemCount: books.length,
              railHeight: _homeBookRailHeight,
              itemBuilder: (context, index) {
                final book = books[index];
                return _BookTile(
                  book: book,
                  rank: rankItems ? index + 1 : null,
                );
              },
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
                      decoration: BoxDecoration(
                        color: context.colors.orange,
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
              style: TextStyle(
                color: context.colors.textPrimary,
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
              style: TextStyle(
                color: context.colors.textSecondary,
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
                            color: context.colors.primary.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.notifications_none,
                            color: context.colors.primary,
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
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                notification.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: context.colors.textSecondary,
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
          FigmaGradientIcon(
            icon: Icons.chat_bubble_outline,
            colors: [context.colors.plumora, context.colors.primary],
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
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consulte tes invitations et retours beta',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.textSecondary),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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
          Icon(Icons.error_outline, color: context.colors.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Donnees indisponibles.',
              style: TextStyle(color: context.colors.textSecondary),
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
