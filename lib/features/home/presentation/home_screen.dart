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
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = viewportWidth >= 1024;
    final compactSpacing = viewportWidth < 600;
    final primaryGap = compactSpacing ? 20.0 : 24.0;
    final sectionGap = compactSpacing ? 24.0 : 28.0;
    final session = ref.watch(authControllerProvider).valueOrNull;
    final displayName = _firstNameFor(session?.user);
    final popularAsync = ref.watch(popularCatalogBooksProvider);
    final latestAsync = ref.watch(latestCatalogBooksProvider);
    final readingsAsync = ref.watch(myReadingProgressProvider);
    final betaAsync = ref.watch(betaInvitationsProvider);
    final notificationsAsync = ref.watch(myNotificationsProvider);
    final readingCard = readingsAsync.when<Widget>(
      loading: () => const _LoadingCard(height: 146),
      error: (_, _) =>
          _NoReadingCard(onDiscover: () => context.go(AppRoutes.discover)),
      data: (readings) {
        final active = readings.where((reading) => !reading.finished).toList()
          ..sort((a, b) {
            final aDate = a.updatedAt ?? DateTime(0);
            final bDate = b.updatedAt ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
        if (active.isEmpty) {
          return _NoReadingCard(
            onDiscover: () => context.go(AppRoutes.discover),
          );
        }
        return _ContinueReadingCard(reading: active.first);
      },
    );

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
                      16,
                      20,
                      16,
                      isDesktop ? 40 : 92,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HomeHighlights(
                          readingCard: readingCard,
                          stackedGap: primaryGap,
                        ),
                        SizedBox(height: primaryGap),
                        _QuickActions(
                          onWrite: () => context.go(AppRoutes.write),
                          onDiscover: () => context.go(AppRoutes.discover),
                          onPlumo: () =>
                              context.push(AppRoutes.plumoRecommendation),
                        ),
                        SizedBox(height: sectionGap),
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
                        SizedBox(height: sectionGap),
                        _BookRail(
                          title: 'Nouveautés',
                          icon: Icons.bolt_outlined,
                          iconColor: context.colors.accent,
                          booksAsync: latestAsync,
                          onSeeAll: () => context.go(AppRoutes.discover),
                          onRetry: () =>
                              ref.invalidate(latestCatalogBooksProvider),
                        ),
                        SizedBox(height: sectionGap),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PlumoraAppHeader(
                  title: 'Accueil',
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
      label: isDark ? 'Activer le thème clair' : 'Activer le thème sombre',
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

class _HomeHighlights extends StatelessWidget {
  const _HomeHighlights({required this.readingCard, required this.stackedGap});

  final Widget readingCard;
  final double stackedGap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            key: const ValueKey('home_highlights_column'),
            children: [
              const _QuoteCard(),
              SizedBox(height: stackedGap),
              readingCard,
            ],
          );
        }

        return SizedBox(
          key: const ValueKey('home_highlights_row'),
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: _QuoteCard()),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: readingCard),
            ],
          ),
        );
      },
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;
        final featured = constraints.minHeight >= 180;
        final centerCopy = constraints.maxWidth >= 1024;
        const centeredCopyWidth = 900.0;
        final featuredBackground = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.cards,
            Color.lerp(context.colors.cards, context.colors.primary, 0.06)!,
          ],
        );

        return FigmaCard(
          key: const ValueKey('home_quote_card'),
          padding: EdgeInsets.all(compact ? 16 : 20),
          radius: 16,
          borderColor: featured
              ? Color.lerp(context.colors.border, context.colors.primary, 0.25)
              : context.colors.border,
          gradient: featured ? featuredBackground : null,
          child: featured
              ? Column(
                  key: const ValueKey('home_quote_featured_content'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _QuoteIcon(compact: false, featured: true),
                    const SizedBox(height: 10),
                    const _QuoteCopy(
                      centered: true,
                      compact: false,
                      featured: true,
                    ),
                  ],
                )
              : centerCopy
              ? SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _QuoteIcon(compact: compact),
                      ),
                      Center(
                        child: SizedBox(
                          width: centeredCopyWidth,
                          child: const _QuoteCopy(
                            centered: true,
                            compact: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _QuoteIcon(compact: compact),
                    SizedBox(width: compact ? 12 : 16),
                    Expanded(
                      child: _QuoteCopy(centered: false, compact: compact),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _QuoteCopy extends StatelessWidget {
  const _QuoteCopy({
    required this.centered,
    required this.compact,
    this.featured = false,
  });

  final bool centered;
  final bool compact;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('home_quote_content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          '"N\'attendez pas l\'inspiration. Elle vient en écrivant."',
          maxLines: featured ? 3 : null,
          overflow: featured ? TextOverflow.ellipsis : null,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: featured
              ? GoogleFonts.playfairDisplay(
                  color: context.colors.textPrimary,
                  fontSize: 14.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                )
              : TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: centered ? 15 : (compact ? 13 : 14),
                  fontStyle: FontStyle.italic,
                  fontWeight: centered ? FontWeight.w500 : FontWeight.w400,
                  height: centered ? 1.5 : (compact ? 1.5 : 1.6),
                  letterSpacing: centered ? 0.1 : null,
                ),
        ),
        SizedBox(height: featured ? 8 : (centered ? 7 : (compact ? 6 : 8))),
        Text(
          '— Victor Hugo',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: featured ? 12 : (centered ? 12.5 : (compact ? 11.5 : 12)),
            fontWeight: featured ? FontWeight.w600 : FontWeight.w500,
            height: 1.35,
            letterSpacing: featured ? 0.2 : null,
          ),
        ),
      ],
    );
  }
}

class _QuoteIcon extends StatelessWidget {
  const _QuoteIcon({required this.compact, this.featured = false});

  final bool compact;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final tint = context.colors.primary;

    final size = featured ? 40.0 : (compact ? 32.0 : 36.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: featured ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(
          featured ? 14 : (compact ? 10 : 12),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.format_quote_rounded,
        size: featured ? 18 : (compact ? 15 : 16),
        color: tint,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final cardHeight = compact ? 156.0 : 180.0;
        final horizontalPadding = compact ? 16.0 : 20.0;
        final verticalPadding = compact ? 16.0 : 18.0;
        final coverWidth = compact ? 82.0 : 96.0;
        final coverHeight = cardHeight - (verticalPadding * 2);
        final radius = compact ? 20.0 : 24.0;

        return InkWell(
          onTap: () => context.push(
            AppRoutes.readingPath(reading.bookId, chapterId: reading.chapterId),
          ),
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            key: const ValueKey('home_continue_reading_card'),
            height: cardHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF250047),
                  Color(0xFF790FC0),
                  Color(0xFF30267E),
                ],
                stops: [0, 0.58, 1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned.fill(
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
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        foregroundDecoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                          borderRadius: BorderRadius.circular(
                            compact ? 12 : 16,
                          ),
                        ),
                        child: PlumoraBookCover(
                          width: coverWidth,
                          height: coverHeight,
                          radius: compact ? 12 : 16,
                          colors: _coverColors(reading.bookId),
                          imageUrl: reading.coverUrl,
                          imageBytes: cachedCover,
                        ),
                      ),
                      SizedBox(width: compact ? 12 : 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _WhiteBadge(
                              icon: Icons.menu_book_outlined,
                              label: 'Continuer la lecture',
                            ),
                            SizedBox(height: compact ? 7 : 9),
                            Text(
                              reading.bookTitle.isEmpty
                                  ? 'Livre sans titre'
                                  : reading.bookTitle,
                              maxLines: compact ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: compact ? 16 : 20,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reading.chapterId == null
                                  ? 'Progression sauvegardée'
                                  : 'Chapitre ${reading.chapterIndex + 1}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: compact ? 11 : 12,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: compact ? 8 : 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 360,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          key: const ValueKey(
                                            'home_reading_progress',
                                          ),
                                          value: reading.progress,
                                          minHeight: compact ? 4 : 6,
                                          color: Colors.white,
                                          backgroundColor: const Color(
                                            0x33FFFFFF,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${reading.progressPercent}% lu',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.68,
                                          ),
                                          fontSize: compact ? 10 : 11,
                                          height: 1,
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
                      SizedBox(width: compact ? 8 : 16),
                      Container(
                        width: compact ? 34 : 40,
                        height: compact ? 34 : 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: compact ? 20 : 22,
                          color: Colors.white,
                        ),
                      ),
                    ],
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

class _NoReadingCard extends StatelessWidget {
  const _NoReadingCard({required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;

        return FigmaCard(
          onTap: onDiscover,
          padding: EdgeInsets.all(compact ? 16 : 20),
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
                      'Découvre un livre pour commencer.',
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
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;
        final gap = compact ? 8.0 : 12.0;

        return Row(
          children: [
            Expanded(
              child: _QuickAction(
                label: 'Écrire',
                icon: Icons.edit_outlined,
                colors: [
                  context.colors.brandPrimary,
                  context.colors.brandPrimaryLight,
                ],
                compact: compact,
                onTap: onWrite,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _QuickAction(
                label: 'Découvrir',
                icon: Icons.menu_book_outlined,
                colors: [
                  context.colors.brandNavy,
                  context.colors.brandNavyLight,
                ],
                compact: compact,
                onTap: onDiscover,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _QuickAction(
                label: 'Plumo',
                icon: Icons.auto_awesome,
                colors: [
                  context.colors.brandGold,
                  context.colors.brandGoldLight,
                ],
                compact: compact,
                onTap: onPlumo,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.colors,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        key: ValueKey('home_quick_action_$label'),
        height: compact ? 72 : 80,
        alignment: Alignment.center,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: compact ? 20 : 22),
            SizedBox(height: compact ? 6 : 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
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
          showAccent: false,
          trailing: TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tout voir'),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16),
              ],
            ),
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
      onTap: () => context.push(AppRoutes.catalogBookDetailPath(book.id)),
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
                  radius: 16,
                  colors: _coverColors(book.id),
                  imageUrl: book.coverUrl,
                  imageBytes: cachedCover,
                ),
                if (rank != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 20,
                      height: 20,
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
        const FigmaSectionHeader(title: 'Activité récente', showAccent: false),
        const SizedBox(height: 12),
        notificationsAsync.when(
          loading: () => const _LoadingCard(height: 88),
          error: (_, _) => const FigmaEmptyState(
            title: 'Activité indisponible',
            message: 'Les notifications backend ne sont pas accessibles.',
            icon: Icons.notifications_none,
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const FigmaEmptyState(
                title: 'Aucune activité',
                message: 'Tes notifications apparaîtront ici.',
                icon: Icons.notifications_none,
              );
            }
            return Column(
              children: [
                for (final notification in notifications.take(3)) ...[
                  FigmaCard(
                    onTap: () => context.push(AppRoutes.notifications),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;

        return FigmaCard(
          onTap: () => context.push(AppRoutes.betaInvitations),
          padding: EdgeInsets.all(compact ? 16 : 20),
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
                          ? 'Aucune bêta-lecture active'
                          : '$count bêta-lecture(s) à traiter',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Consulte tes invitations et retours bêta',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
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
              'Données indisponibles.',
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
