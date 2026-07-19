import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart' show resolvePlumoraImageUrl;
import '../../book/data/models/book_model.dart';
import '../../book/data/repositories/book_repository.dart';
import 'widgets/continue_on_web_card.dart';

const _writeAccent = Color(0xFF7C5CFF);
const _writeAccentLight = Color(0xFF9B80FF);
const _writeGold = Color(0xFFD6B25E);
const _writeGreen = Color(0xFF3FBF7F);

const _writeTabs = ['Toutes', 'En cours', 'Bêta-test', 'Publiées'];

Color _softWriteBorder(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return context.elevatedBorderColor;
  }
  return Color.lerp(context.colors.border, context.colors.cards, 0.28)!;
}

class AuthorDashboardScreen extends ConsumerStatefulWidget {
  const AuthorDashboardScreen({super.key});

  @override
  ConsumerState<AuthorDashboardScreen> createState() =>
      _AuthorDashboardScreenState();
}

class _AuthorDashboardScreenState extends ConsumerState<AuthorDashboardScreen> {
  String _activeTab = _writeTabs.first;

  bool _matchesTab(BookModel book) {
    switch (_activeTab) {
      case 'En cours':
        return book.status == BookStatus.draft ||
            book.status == BookStatus.inCorrection ||
            book.status == BookStatus.readyToPublish;
      case 'Bêta-test':
        return book.status == BookStatus.inBetaReading;
      case 'Publiées':
        return book.status == BookStatus.published;
      default:
        return true;
    }
  }

  Future<void> _confirmArchive(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ArchiveConfirmDialog(title: book.title),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref.read(bookRepositoryProvider).archiveBook(book.id);
      ref.invalidate(myBooksProvider);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
    }
  }

  void _goToPublish(List<BookModel> books) {
    final candidates = books
        .where((book) => book.canPublish && !book.isArchived)
        .toList(growable: false);

    if (candidates.length == 1) {
      context.push(AppRoutes.publishBookPath(candidates.first.id));
    } else {
      context.go(AppRoutes.manuscripts);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(myBooksProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(myBooksProvider.future),
      child: FigmaScreen(
        maxWidth: 1180,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 88),
        physics: const AlwaysScrollableScrollPhysics(),
        child: booksAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => _ErrorPanel(
            message: AppError.messageFor(error),
            onRetry: () => ref.invalidate(myBooksProvider),
          ),
          data: (books) {
            final filtered = books.where(_matchesTab).toList(growable: false);
            final totalChapters = books.fold<int>(
              0,
              (sum, book) => sum + book.chapterCount,
            );
            final totalWords = books.fold<int>(
              0,
              (sum, book) => sum + book.wordCount,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 900;
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final showFullButtonLabel = constraints.maxWidth >= 600;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: isDesktop ? 40 : 36,
                                height: isDesktop ? 40 : 36,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_writeAccent, _writeAccentLight],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    isDark
                                        ? ShaderMask(
                                            shaderCallback: (bounds) =>
                                                LinearGradient(
                                                  colors: [
                                                    _writeAccent,
                                                    context.colors.plumoAccent,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ).createShader(bounds),
                                            child: Text(
                                              'Mes manuscrits',
                                              style:
                                                  GoogleFonts.playfairDisplay(
                                                    color: Colors.white,
                                                    fontSize: isDesktop
                                                        ? 25
                                                        : 20,
                                                    fontWeight: FontWeight.w900,
                                                    height: 1.05,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            'Mes manuscrits',
                                            style: GoogleFonts.playfairDisplay(
                                              color: Colors.black,
                                              fontSize: isDesktop ? 25 : 20,
                                              fontWeight: FontWeight.w900,
                                              height: 1.05,
                                            ),
                                          ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isDesktop
                                          ? '${books.length} histoires · '
                                                '$totalChapters chapitres · '
                                                '${_compactNumber(totalWords)} mots'
                                          : '${books.length} histoires · '
                                                '$totalChapters chapitres',
                                      style: TextStyle(
                                        color: context.colors.textSecondary,
                                        fontSize: isDesktop ? 11 : 10,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _GradientActionButton(
                          icon: Icons.add,
                          label: showFullButtonLabel
                              ? 'Nouvelle histoire'
                              : 'Créer',
                          onPressed: () => context.push(AppRoutes.createBook),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Histoires',
                        value: books.length.toString(),
                        icon: Icons.menu_book_outlined,
                        color: _writeAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        label: 'Chapitres',
                        value: totalChapters.toString(),
                        icon: Icons.description_outlined,
                        color: _writeGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        label: 'Mots\nécrits',
                        value: _compactNumber(totalWords, fixed: true),
                        icon: Icons.energy_savings_leaf_outlined,
                        color: _writeGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final tab in _writeTabs) ...[
                        _FilterTab(
                          label: tab,
                          selected: _activeTab == tab,
                          onTap: () => setState(() => _activeTab = tab),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (filtered.isEmpty)
                  _EmptyStories(
                    onCreate: () => context.push(AppRoutes.createBook),
                  )
                else
                  FigmaResponsiveGrid(
                    minTileWidth: 340,
                    maxColumns: 3,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final book in filtered)
                        _StoryCard(book: book, onArchive: _confirmArchive),
                    ],
                  ),
                const SizedBox(height: 20),
                _WriteCta(
                  icon: Icons.auto_awesome,
                  iconColors: const [_writeAccent, _writeAccentLight],
                  title: "Plumo — Votre assistant d'écriture IA",
                  subtitle: 'Reformulez, améliorez le style, générez des idées',
                  borderColor: _writeAccent,
                  onTap: () => context.push(AppRoutes.plumoWritingPath()),
                ),
                const SizedBox(height: 12),
                _WriteCta(
                  icon: Icons.upload_outlined,
                  iconColors: const [_writeGold, Color(0xFFC49A40)],
                  title: 'Prêt à publier ?',
                  subtitle: 'Soumettez votre manuscrit à la communauté',
                  borderColor: _writeGold,
                  onTap: () => _goToPublish(books),
                ),
                if (ContinueOnWebCard.isRelevant && books.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ContinueOnWebCard(manuscriptId: _mostRecentBookId(books)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 150;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final iconSize = compact ? 28.0 : 44.0;
        final backgroundStart = Color.lerp(
          context.colors.cards,
          color,
          isDark ? 0.10 : 0.07,
        )!;
        final outline = Color.lerp(
          _softWriteBorder(context),
          color,
          isDark ? 0.18 : 0.12,
        )!;

        return Container(
          key: ValueKey('manuscript_stat_$label'),
          height: compact ? 64 : 80,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 16,
            vertical: compact ? 9 : 12,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colors.cards,
            gradient: LinearGradient(
              colors: [backgroundStart, context.colors.cards],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: outline, width: 0.8),
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.08 : 0.055),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!compact)
                Positioned(
                  right: 2,
                  top: 0,
                  bottom: 0,
                  child: Icon(
                    icon,
                    key: ValueKey('manuscript_stat_watermark_$label'),
                    size: 52,
                    color: color.withValues(alpha: isDark ? 0.07 : 0.05),
                  ),
                ),
              Row(
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.16 : 0.12),
                      border: compact
                          ? null
                          : Border.all(
                              color: color.withValues(alpha: 0.12),
                              width: 0.8,
                            ),
                      borderRadius: BorderRadius.circular(compact ? 9 : 13),
                    ),
                    child: Icon(icon, size: compact ? 15 : 21, color: color),
                  ),
                  SizedBox(width: compact ? 7 : 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: compact ? 13 : 19,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: compact ? 3 : 5),
                        Text(
                          label.replaceAll('\n', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: compact ? 8 : 10.5,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!compact) const SizedBox(width: 44),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
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
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [_writeAccent, _writeAccentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : context.colors.muted,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _writeAccent.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : context.colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_writeAccent, _writeAccentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: _writeAccent.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: Colors.white),
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
          ),
        ),
      ),
    );
  }
}

class _EmptyStories extends StatelessWidget {
  const _EmptyStories({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.colors.muted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.menu_book_outlined,
              size: 36,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune histoire ici',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Commencez à écrire votre première histoire',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 22),
          _GradientActionButton(
            icon: Icons.add,
            label: 'Créer une histoire',
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatefulWidget {
  const _StoryCard({required this.book, required this.onArchive});

  final BookModel book;
  final void Function(BookModel book) onArchive;

  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> {
  bool _hovered = false;

  BookModel get book => widget.book;

  bool get _isDraftish =>
      book.status == BookStatus.draft ||
      book.status == BookStatus.inCorrection ||
      book.status == BookStatus.readyToPublish;

  @override
  Widget build(BuildContext context) {
    final title = book.title.isEmpty ? 'Histoire sans titre' : book.title;
    final primaryLabel = _isDraftish ? 'Écrire' : 'Lire';
    final secondary = _secondaryAction(book);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      key: ValueKey('manuscript_card_${book.id}'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.cards,
        border: Border.all(
          color: _hovered
              ? context.colors.primary.withValues(alpha: 0.55)
              : _softWriteBorder(context),
          width: _hovered ? 1.1 : 0.8,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _hovered
                ? context.colors.primary.withValues(alpha: isDark ? 0.22 : 0.16)
                : isDark
                ? Colors.black.withValues(alpha: 0.16)
                : context.colors.primary.withValues(alpha: 0.055),
            blurRadius: _hovered ? 22 : 14,
            offset: Offset(0, _hovered ? 9 : 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('manuscript_card_link_${book.id}'),
          onTap: () => context.push(AppRoutes.authorBookDetailPath(book.id)),
          onHover: (hovered) => setState(() => _hovered = hovered),
          mouseCursor: SystemMouseCursors.click,
          hoverColor: context.colors.primary.withValues(alpha: 0.045),
          splashColor: context.colors.primary.withValues(alpha: 0.12),
          highlightColor: context.colors.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedScale(
                  scale: _hovered ? 1.045 : 1,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: _StoryCover(book: book, title: title),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                                if ((book.genre ?? '').isNotEmpty)
                                  Text(
                                    book.genre!,
                                    style: TextStyle(
                                      color: context.colors.textSecondary,
                                      fontSize: 10.5,
                                      height: 1.3,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          AnimatedOpacity(
                            key: ValueKey(
                              'manuscript_card_hover_arrow_${book.id}',
                            ),
                            opacity: _hovered ? 1 : 0,
                            duration: const Duration(milliseconds: 150),
                            child: Container(
                              width: 27,
                              height: 27,
                              decoration: BoxDecoration(
                                color: context.colors.primary.withValues(
                                  alpha: 0.11,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_outward_rounded,
                                size: 14,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          _StoryMenu(book: book, onArchive: widget.onArchive),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _StatusChip(status: book.status),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 9,
                        runSpacing: 5,
                        children: [
                          _InlineStat(
                            icon: Icons.description_outlined,
                            label: '${book.chapterCount} chap.',
                          ),
                          _InlineStat(
                            icon: Icons.edit_outlined,
                            label:
                                '${_compactNumber(book.wordCount, fixed: true)} mots',
                          ),
                          if (book.viewCount > 0)
                            _InlineStat(
                              icon: Icons.visibility_outlined,
                              label: _compactNumber(book.viewCount),
                            ),
                          if (book.feedbackCount > 0)
                            _InlineStat(
                              icon: Icons.chat_bubble_outline,
                              label: '${book.feedbackCount}',
                            ),
                          if ((book.averageRating ?? 0) > 0)
                            _InlineStat(
                              icon: Icons.star,
                              iconColor: const Color(0xFFFACC15),
                              label: book.averageRating!.toStringAsFixed(1),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _InlineStat(
                        icon: Icons.schedule,
                        label: _relativeModified(
                          book.updatedAt ?? book.createdAt,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _GradientMiniButton(
                              icon: Icons.energy_savings_leaf_outlined,
                              label: primaryLabel,
                              onPressed: () => context.push(
                                AppRoutes.chapterEditorPath(book.id),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _OutlineMiniButton(
                              icon: secondary.icon,
                              label: secondary.label,
                              onPressed: () => context.push(secondary.route),
                            ),
                          ),
                        ],
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
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: style.foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              color: style.foreground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

_StatusStyle _statusStyle(BuildContext context, BookStatus status) {
  return switch (status) {
    BookStatus.inBetaReading => _StatusStyle(
      label: 'Bêta-test',
      background: context.colors.primary.withValues(alpha: 0.12),
      foreground: context.colors.primary,
    ),
    BookStatus.published => _StatusStyle(
      label: 'Publié',
      background: context.colors.success.withValues(alpha: 0.12),
      foreground: context.colors.success,
    ),
    BookStatus.archived => _StatusStyle(
      label: 'Archivé',
      background: context.colors.muted,
      foreground: context.colors.textSecondary,
    ),
    _ => _StatusStyle(
      label: 'Brouillon',
      background: context.colors.textSecondary.withValues(alpha: 0.15),
      foreground: context.colors.textSecondary,
    ),
  };
}

class _SecondaryAction {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

_SecondaryAction _secondaryAction(BookModel book) {
  if (book.status == BookStatus.inBetaReading) {
    return _SecondaryAction(
      icon: Icons.chat_bubble_outline,
      label: 'Retours',
      route: AppRoutes.authorBetaCommentsPath(book.id),
    );
  }

  if (book.status == BookStatus.published) {
    return const _SecondaryAction(
      icon: Icons.bar_chart_outlined,
      label: 'Stats',
      route: AppRoutes.royalties,
    );
  }

  return _SecondaryAction(
    icon: Icons.description_outlined,
    label: 'Chapitres',
    route: AppRoutes.chapterEditorPath(book.id),
  );
}

class _StoryCover extends StatelessWidget {
  const _StoryCover({required this.book, required this.title});

  final BookModel book;
  final String title;

  @override
  Widget build(BuildContext context) {
    final resolvedCoverUrl = resolvePlumoraImageUrl(book.coverUrl);

    return Container(
      width: 68,
      height: 96,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _coverColorsForBook(book),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          if (resolvedCoverUrl != null)
            Image.network(
              resolvedCoverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 5,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.icon, required this.label, this.iconColor});

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: iconColor ?? context.colors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 10,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _GradientMiniButton extends StatelessWidget {
  const _GradientMiniButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_writeAccent, _writeAccentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineMiniButton extends StatelessWidget {
  const _OutlineMiniButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: context.colors.cards,
            border: Border.all(color: _softWriteBorder(context), width: 0.8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: context.colors.textPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryMenu extends StatelessWidget {
  const _StoryMenu({required this.book, required this.onArchive});

  final BookModel book;
  final void Function(BookModel book) onArchive;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        size: 16,
        color: context.colors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onSelected: (value) {
        switch (value) {
          case 'write':
            context.push(AppRoutes.chapterEditorPath(book.id));
          case 'edit':
            context.push(AppRoutes.editBookPath(book.id));
          case 'beta':
            context.push(AppRoutes.authorBetaCampaignsPath(book.id));
          case 'archive':
            onArchive(book);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'write',
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Écrire'),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: _MenuRow(
            icon: Icons.description_outlined,
            label: 'Modifier les infos',
          ),
        ),
        const PopupMenuItem(
          value: 'beta',
          child: _MenuRow(icon: Icons.group_outlined, label: 'Envoyer en bêta'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'archive',
          child: _MenuRow(
            icon: Icons.delete_outline,
            label: 'Supprimer',
            color: context.colors.destructive,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color ?? context.colors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color ?? context.colors.textPrimary),
        ),
      ],
    );
  }
}

class _WriteCta extends StatelessWidget {
  const _WriteCta({
    required this.icon,
    required this.iconColors,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> iconColors;
  final String title;
  final String subtitle;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: borderColor.withValues(alpha: 0.05),
            border: Border.all(color: _softWriteBorder(context), width: 0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: iconColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: context.colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveConfirmDialog extends StatelessWidget {
  const _ArchiveConfirmDialog({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Archiver « $title » ?',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ce livre sera archivé et retiré de tes histoires actives. '
              'Tu pourras toujours le retrouver et le republier plus tard.',
              style: TextStyle(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colors.destructive,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Archiver'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
            'Manuscrits indisponibles',
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

List<Color> _coverColorsForBook(BookModel book) {
  final title = book.title.toLowerCase();
  if (title.contains('nuit rouge')) {
    return const [Color(0xFF901BFF), Color(0xFF7B08E8), Color(0xFF180038)];
  }
  if (title.contains('ombres')) {
    return const [Color(0xFF2457FF), Color(0xFF5428E8), Color(0xFF061126)];
  }
  if (title.contains('sang')) {
    return const [Color(0xFFFF0A4F), Color(0xFFE00012), Color(0xFF5B170B)];
  }

  return _coverColors(book.id.isEmpty ? book.title : book.id);
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

String _relativeModified(DateTime? date) {
  if (date == null) {
    return '—';
  }

  final local = date.toLocal();
  final now = DateTime.now();
  final time =
      '${local.hour.toString().padLeft(2, '0')}h'
      '${local.minute.toString().padLeft(2, '0')}';

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  if (isSameDay(local, now)) {
    return "Aujourd'hui, $time";
  }

  if (isSameDay(local, now.subtract(const Duration(days: 1)))) {
    return 'Hier, $time';
  }

  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String _mostRecentBookId(List<BookModel> books) {
  DateTime lastActivity(BookModel book) =>
      book.updatedAt ??
      book.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  return books
      .reduce((a, b) => lastActivity(a).isAfter(lastActivity(b)) ? a : b)
      .id;
}

String _compactNumber(int value, {bool fixed = false}) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    final scaled = value / 1000;
    if (!fixed && value % 1000 == 0) {
      return '${scaled.toStringAsFixed(0)}k';
    }
    return '${scaled.toStringAsFixed(1)}k';
  }
  return value.toString();
}
