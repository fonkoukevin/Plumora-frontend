import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/models/chapter_model.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../../book/data/repositories/book_repository.dart';
import '../../book/data/repositories/chapter_repository.dart';

const _detailAccent = Color(0xFF7C5CFF);
const _detailAccentLight = Color(0xFF9B80FF);
const _detailGold = Color(0xFFD6B25E);
const _detailGreen = Color(0xFF3FBF7F);
const _detailSurface = Color(0xFFFFFEFC);
const _detailMuted = Color(0xFFF1EEE8);
const _detailBorder = Color(0xFFE9E1D8);

enum _DetailTab { overview, chapters, stats, settings }

class BookDetailAuthorScreen extends ConsumerStatefulWidget {
  const BookDetailAuthorScreen({required this.bookId, super.key});

  final String bookId;

  @override
  ConsumerState<BookDetailAuthorScreen> createState() =>
      _BookDetailAuthorScreenState();
}

class _BookDetailAuthorScreenState
    extends ConsumerState<BookDetailAuthorScreen> {
  bool _isMutating = false;
  String? _error;
  _DetailTab _activeTab = _DetailTab.overview;

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(authorBookProvider(widget.bookId));
    final chaptersAsync = ref.watch(bookChaptersProvider(widget.bookId));

    return ColoredBox(
      color: PlumoraColors.background,
      child: bookAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => _ErrorPanel(
          title: 'Livre introuvable',
          message: AppError.messageFor(error),
          onRetry: () => ref.invalidate(authorBookProvider(widget.bookId)),
        ),
        data: (book) => _BookDetailBody(
          book: book,
          chaptersAsync: chaptersAsync,
          activeTab: _activeTab,
          isMutating: _isMutating,
          error: _error,
          onTabSelected: (tab) => setState(() => _activeTab = tab),
          onArchive: () => _confirmArchive(book),
        ),
      ),
    );
  }

  Future<void> _confirmArchive(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ArchiveConfirmDialog(title: book.title),
    );
    if (confirmed == true) {
      await _archive(book.id);
    }
  }

  Future<void> _archive(String bookId) async {
    await _mutate(() => ref.read(bookRepositoryProvider).archiveBook(bookId));
  }

  Future<void> _mutate(Future<Object?> Function() action) async {
    setState(() {
      _isMutating = true;
      _error = null;
    });

    try {
      await action();
      ref.invalidate(authorBookProvider(widget.bookId));
      ref.invalidate(myBooksProvider);
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }
}

class _BookDetailBody extends StatelessWidget {
  const _BookDetailBody({
    required this.book,
    required this.chaptersAsync,
    required this.activeTab,
    required this.isMutating,
    required this.onTabSelected,
    required this.onArchive,
    this.error,
  });

  final BookModel book;
  final AsyncValue<List<ChapterModel>> chaptersAsync;
  final _DetailTab activeTab;
  final bool isMutating;
  final ValueChanged<_DetailTab> onTabSelected;
  final VoidCallback onArchive;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 92.0;

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(book: book),
                  _BookHero(book: book, chaptersAsync: chaptersAsync),
                  if (error != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: PlumoraColors.destructive,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  _ActionGrid(
                    book: book,
                    isMutating: isMutating,
                    onArchive: onArchive,
                  ),
                  const SizedBox(height: 12),
                  _DetailTabs(activeTab: activeTab, onSelected: onTabSelected),
                  const SizedBox(height: 14),
                  _TabContent(
                    book: book,
                    chaptersAsync: chaptersAsync,
                    activeTab: activeTab,
                    isMutating: isMutating,
                    onArchive: onArchive,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: PlumoraColors.background.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: PlumoraColors.border)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.write),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Mes histoires'),
            style: TextButton.styleFrom(
              foregroundColor: PlumoraColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          _GradientPillButton(
            icon: Icons.energy_savings_leaf_outlined,
            label: _primaryActionLabel(book),
            onPressed: () => context.go(AppRoutes.chapterEditorPath(book.id)),
          ),
        ],
      ),
    );
  }
}

class _BookHero extends ConsumerWidget {
  const _BookHero({required this.book, required this.chaptersAsync});

  final BookModel book;
  final AsyncValue<List<ChapterModel>> chaptersAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));
    final chapters = chaptersAsync.valueOrNull ?? const <ChapterModel>[];
    final chapterTotal = chapters.isNotEmpty
        ? chapters.length
        : book.chapterCount;
    final doneChapters = _completedChapterCount(book, chapters, chapterTotal);
    final modified = _shortModified(book.updatedAt ?? book.createdAt);
    final status = _statusStyle(book.status);
    final visibility = _visibilityStyle(book.visibility);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 21, 8, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              PlumoraBookCover(
                colors: _bookCoverColors(book),
                imageUrl: book.coverUrl,
                imageBytes: cachedCover,
                width: 90,
                height: 125,
                radius: 10,
              ),
              Positioned(
                right: -5,
                bottom: -7,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.go(AppRoutes.editBookPath(book.id)),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _detailSurface,
                        border: Border.all(color: _detailBorder),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: PlumoraColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title.isEmpty ? 'Livre sans titre' : book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlumoraColors.textPrimary,
                    fontFamily: 'Playfair Display',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _bookMetaLine(book),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 11,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _StatusChip(style: status),
                    _VisibilityChip(style: visibility),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.description_outlined,
                        value: '$doneChapters/$chapterTotal',
                        label: 'Chapitres',
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.energy_savings_leaf_outlined,
                        value: _compactNumber(book.wordCount, fixed: true),
                        label: 'Mots',
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.schedule_outlined,
                        value: modified,
                        label: 'Modifié',
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

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: _detailSurface,
        border: Border.all(color: _detailBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: PlumoraColors.textSecondary),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 8,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.book,
    required this.isMutating,
    required this.onArchive,
  });

  final BookModel book;
  final bool isMutating;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _ActionTile(
              icon: Icons.energy_savings_leaf_outlined,
              label: _primaryActionLabel(book),
              selected: true,
              onTap: isMutating
                  ? null
                  : () => context.go(AppRoutes.chapterEditorPath(book.id)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionTile(
              icon: Icons.group_outlined,
              label: 'Bêta-test',
              onTap: isMutating
                  ? null
                  : () =>
                        context.go(AppRoutes.authorBetaCampaignsPath(book.id)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionTile(
              icon: Icons.upload_outlined,
              label: 'Publier',
              onTap: isMutating
                  ? null
                  : () => context.go(AppRoutes.publishBookPath(book.id)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : PlumoraColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 55,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [_detailAccent, _detailAccentLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : _detailSurface,
            border: selected ? null : Border.all(color: _detailBorder),
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _detailAccent.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: foreground),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
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

class _DetailTabs extends StatelessWidget {
  const _DetailTabs({required this.activeTab, required this.onSelected});

  final _DetailTab activeTab;
  final ValueChanged<_DetailTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PlumoraColors.border)),
      ),
      child: Row(
        children: [
          for (final tab in _DetailTab.values)
            Expanded(
              child: _DetailTabButton(
                label: _tabLabel(tab),
                selected: activeTab == tab,
                onTap: () => onSelected(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailTabButton extends StatelessWidget {
  const _DetailTabButton({
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
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? PlumoraColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? PlumoraColors.primary : PlumoraColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.book,
    required this.chaptersAsync,
    required this.activeTab,
    required this.isMutating,
    required this.onArchive,
  });

  final BookModel book;
  final AsyncValue<List<ChapterModel>> chaptersAsync;
  final _DetailTab activeTab;
  final bool isMutating;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return switch (activeTab) {
      _DetailTab.overview => _OverviewTab(book: book),
      _DetailTab.chapters => _ChaptersTab(
        book: book,
        chaptersAsync: chaptersAsync,
      ),
      _DetailTab.stats => _StatsTab(book: book, chaptersAsync: chaptersAsync),
      _DetailTab.settings => _SettingsTab(
        book: book,
        isMutating: isMutating,
        onArchive: onArchive,
      ),
    };
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    final tags = _bookTags(book);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          _DetailSectionCard(
            title: 'Résumé',
            actionLabel: 'Modifier',
            onAction: () => context.go(AppRoutes.editBookPath(book.id)),
            child: Text(
              _bookSummary(book),
              style: const TextStyle(
                color: PlumoraColors.textSecondary,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DetailSectionCard(
            title: 'Tags',
            child: tags.isEmpty
                ? const Text(
                    'Aucun tag enregistré en base.',
                    style: TextStyle(
                      color: PlumoraColors.textSecondary,
                      fontSize: 12,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in tags) _TagPill(label: '#$tag'),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _MukemeHint(book: book),
        ],
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _detailSurface,
        border: Border.all(color: _detailBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: PlumoraColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: PlumoraColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _detailMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: PlumoraColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MukemeHint extends StatelessWidget {
  const _MukemeHint({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(AppRoutes.mukemeWritingPath()),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _detailAccent.withValues(alpha: 0.05),
            border: Border.all(color: _detailBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_detailAccent, _detailAccentLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Idées de Mukeme pour ce livre',
                      style: TextStyle(
                        color: PlumoraColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Obtenez des suggestions pour enrichir votre histoire',
                      style: TextStyle(
                        color: PlumoraColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 17,
                color: PlumoraColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChaptersTab extends ConsumerWidget {
  const _ChaptersTab({required this.book, required this.chaptersAsync});

  final BookModel book;
  final AsyncValue<List<ChapterModel>> chaptersAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: chaptersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _ErrorPanel(
          title: 'Chapitres indisponibles',
          message: AppError.messageFor(error),
          onRetry: () => ref.invalidate(bookChaptersProvider(book.id)),
        ),
        data: (chapters) {
          if (chapters.isEmpty) {
            return _EmptyChapters(
              onOpenEditor: () =>
                  context.go(AppRoutes.chapterEditorPath(book.id)),
            );
          }

          final published = chapters.where(_chapterHasContent).length;

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$published publié${published > 1 ? 's' : ''} · '
                      '${chapters.length - published} brouillon'
                      '${chapters.length - published > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: PlumoraColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  _SmallGradientButton(
                    icon: Icons.add,
                    label: 'Nouveau chapitre',
                    onPressed: () =>
                        context.go(AppRoutes.chapterEditorPath(book.id)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < chapters.length; index++) ...[
                _ChapterRow(book: book, chapter: chapters[index], index: index),
                const SizedBox(height: 10),
              ],
              _AddChapterCard(
                onTap: () => context.go(AppRoutes.chapterEditorPath(book.id)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.book,
    required this.chapter,
    required this.index,
  });

  final BookModel book;
  final ChapterModel chapter;
  final int index;

  @override
  Widget build(BuildContext context) {
    final published = _chapterHasContent(chapter);
    final wordCount = _chapterWordCount(chapter);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(
          AppRoutes.authorChapterDetailPath(chapter.id, bookId: book.id),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _detailSurface,
            border: Border.all(color: _detailBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: published
                      ? _detailGreen.withValues(alpha: 0.12)
                      : PlumoraColors.textSecondary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: published
                          ? _detailGreen
                          : PlumoraColors.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chapter.title.isEmpty
                                ? 'Chapitre sans titre'
                                : chapter.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlumoraColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _TinyStatePill(
                          label: published ? 'Publié' : 'Brouillon',
                          color: published
                              ? _detailGreen
                              : PlumoraColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${wordCount > 0 ? '$wordCount mots' : 'Vide - à écrire'}'
                      ' · ${_relativeModified(chapter.updatedAt ?? chapter.createdAt)}',
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
              IconButton(
                onPressed: () =>
                    context.go(AppRoutes.chapterEditorPath(book.id)),
                icon: const Icon(Icons.edit_outlined),
                color: PlumoraColors.primary,
                iconSize: 18,
                tooltip: 'Écrire',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyStatePill extends StatelessWidget {
  const _TinyStatePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AddChapterCard extends StatelessWidget {
  const _AddChapterCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: _detailBorder, width: 1.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 19, color: PlumoraColors.textSecondary),
            SizedBox(width: 7),
            Text(
              'Ajouter un chapitre',
              style: TextStyle(
                color: PlumoraColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.book, required this.chaptersAsync});

  final BookModel book;
  final AsyncValue<List<ChapterModel>> chaptersAsync;

  @override
  Widget build(BuildContext context) {
    final chapters = chaptersAsync.valueOrNull ?? const <ChapterModel>[];
    final betaValue = book.feedbackCount > 0
        ? book.feedbackCount.toString()
        : '—';
    final rating = book.averageRating;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final width = (constraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: width,
                    child: _StatsCard(
                      icon: Icons.menu_book_outlined,
                      label: 'Vues totales',
                      value: book.viewCount > 0
                          ? _compactNumber(book.viewCount)
                          : '—',
                      color: _detailAccent,
                      sub: 'Depuis la publication',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _StatsCard(
                      icon: Icons.star_outline,
                      label: 'Note moyenne',
                      value: rating == null
                          ? '—'
                          : '${rating.toStringAsFixed(1)}/5',
                      color: _detailGold,
                      sub: rating == null
                          ? 'Pas encore noté'
                          : 'Moyenne lecteurs',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _StatsCard(
                      icon: Icons.group_outlined,
                      label: 'Bêta-lecteurs',
                      value: betaValue,
                      color: _detailGreen,
                      sub: chapters.isEmpty
                          ? 'En attente'
                          : '${chapters.length} chapitres',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: const _StatsCard(
                      icon: Icons.trending_up,
                      label: 'Revenus',
                      value: '—',
                      color: PlumoraColors.textSecondary,
                      sub: 'Pas encore publié',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _DetailSectionCard(
            title: 'Les statistiques seront disponibles',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Publiez votre livre pour voir les vues, notes et revenus en temps réel.',
                  style: TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () =>
                      context.go(AppRoutes.publishBookPath(book.id)),
                  style: TextButton.styleFrom(
                    foregroundColor: PlumoraColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Préparer la publication'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.sub,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _detailSurface,
        border: Border.all(color: _detailBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.book,
    required this.isMutating,
    required this.onArchive,
  });

  final BookModel book;
  final bool isMutating;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final visibility = _visibilityStyle(book.visibility);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          _DetailSectionCard(
            title: 'Informations du livre',
            actionLabel: 'Modifier',
            onAction: () => context.go(AppRoutes.editBookPath(book.id)),
            child: Column(
              children: [
                _SettingsRow(label: 'Titre', value: book.title),
                _SettingsRow(label: 'Genre', value: _bookGenre(book)),
                _SettingsRow(label: 'Langue', value: _bookLanguage(book)),
                _SettingsRow(
                  label: 'Créé le',
                  value: _dateLabel(book.createdAt),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailSectionCard(
            title: 'Visibilité',
            child: Column(
              children: [
                _VisibilityRow(
                  icon: visibility.icon,
                  label: visibility.label,
                  description: visibility.description,
                  selected: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _QuickLinkCard(
            items: [
              _QuickLink(
                icon: Icons.upload_outlined,
                label: 'Soumettre en bêta-test',
                route: AppRoutes.authorBetaCampaignsPath(book.id),
                color: _detailAccent,
              ),
              _QuickLink(
                icon: Icons.menu_book_outlined,
                label: 'Préparer la publication',
                route: AppRoutes.publishBookPath(book.id),
                color: _detailGold,
              ),
              _QuickLink(
                icon: Icons.chat_bubble_outline,
                label: 'Voir les retours bêta',
                route: AppRoutes.authorBetaCommentsPath(book.id),
                color: _detailGreen,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DangerCard(
            disabled: isMutating || book.isArchived,
            onArchive: onArchive,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: last ? 0 : 10, top: 2),
      margin: EdgeInsets.only(bottom: last ? 0 : 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: PlumoraColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: PlumoraColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: PlumoraColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityRow extends StatelessWidget {
  const _VisibilityRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: selected ? PlumoraColors.primary : PlumoraColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: PlumoraColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  color: PlumoraColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (selected)
          const Icon(Icons.check, size: 17, color: PlumoraColors.primary),
      ],
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({required this.items});

  final List<_QuickLink> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _detailSurface,
        border: Border.all(color: _detailBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++)
            _QuickLinkRow(item: items[index], last: index == items.length - 1),
        ],
      ),
    );
  }
}

class _QuickLinkRow extends StatelessWidget {
  const _QuickLinkRow({required this.item, required this.last});

  final _QuickLink item;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(item.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: PlumoraColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: PlumoraColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 17,
              color: PlumoraColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String route;
  final Color color;
}

class _DangerCard extends StatelessWidget {
  const _DangerCard({required this.disabled, required this.onArchive});

  final bool disabled;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _detailSurface,
        border: Border.all(
          color: PlumoraColors.destructive.withValues(alpha: 0.22),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 17,
                color: PlumoraColors.destructive,
              ),
              const SizedBox(width: 7),
              const Text(
                'Zone de danger',
                style: TextStyle(
                  color: PlumoraColors.destructive,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            'Archive ce livre si tu ne veux plus le voir dans tes histoires actives.',
            style: TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: disabled ? null : onArchive,
              style: OutlinedButton.styleFrom(
                foregroundColor: PlumoraColors.destructive,
                side: BorderSide(
                  color: PlumoraColors.destructive.withValues(alpha: 0.4),
                ),
              ),
              child: const Text('Archiver ce livre'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.style});

  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({required this.style});

  final _VisibilityStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _detailMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 11, color: PlumoraColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientPillButton extends StatelessWidget {
  const _GradientPillButton({
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
          colors: [_detailAccent, _detailAccentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: _detailAccent.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

class _SmallGradientButton extends StatelessWidget {
  const _SmallGradientButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: _detailAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _EmptyChapters extends StatelessWidget {
  const _EmptyChapters({required this.onOpenEditor});

  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    return _DetailSectionCard(
      title: 'Aucun chapitre',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ouvre l’éditeur pour créer le premier chapitre de ce livre.',
            style: TextStyle(color: PlumoraColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          _GradientPillButton(
            icon: Icons.edit_outlined,
            label: 'Ajouter un chapitre',
            onPressed: onOpenEditor,
          ),
        ],
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
              style: const TextStyle(
                color: PlumoraColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ce livre sera retiré de tes histoires actives.',
              style: TextStyle(color: PlumoraColors.textSecondary, height: 1.4),
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
                      backgroundColor: PlumoraColors.destructive,
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
  const _ErrorPanel({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PlumoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(color: PlumoraColors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
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

class _VisibilityStyle {
  const _VisibilityStyle({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;
}

_StatusStyle _statusStyle(BookStatus status) {
  return switch (status) {
    BookStatus.inBetaReading => const _StatusStyle(
      label: 'Bêta-test',
      background: Color(0xFFF1EAFE),
      foreground: _detailAccent,
    ),
    BookStatus.published => const _StatusStyle(
      label: 'Publié',
      background: Color(0xFFE2F8EC),
      foreground: _detailGreen,
    ),
    BookStatus.archived => const _StatusStyle(
      label: 'Archivé',
      background: Color(0xFFF0EEF1),
      foreground: Color(0xFF8F8895),
    ),
    BookStatus.inCorrection => const _StatusStyle(
      label: 'Correction',
      background: Color(0xFFF1EAFE),
      foreground: _detailAccent,
    ),
    BookStatus.readyToPublish => const _StatusStyle(
      label: 'Prêt',
      background: Color(0xFFE2F8EC),
      foreground: _detailGreen,
    ),
    _ => const _StatusStyle(
      label: 'Brouillon',
      background: Color(0xFFF0EEF1),
      foreground: Color(0xFFA8A8B3),
    ),
  };
}

_VisibilityStyle _visibilityStyle(String? value) {
  final normalized = value?.trim().toUpperCase();
  return switch (normalized) {
    'PUBLIC' => const _VisibilityStyle(
      label: 'Public',
      description: 'Visible par toute la communauté',
      icon: Icons.public,
    ),
    'BETA' || 'BETA_ONLY' || 'BETA_READING' => const _VisibilityStyle(
      label: 'Bêta uniquement',
      description: 'Accessible aux bêta-lecteurs',
      icon: Icons.group_outlined,
    ),
    _ => const _VisibilityStyle(
      label: 'Privé',
      description: 'Visible uniquement par vous',
      icon: Icons.lock_outline,
    ),
  };
}

String _tabLabel(_DetailTab tab) {
  return switch (tab) {
    _DetailTab.overview => 'Aperçu',
    _DetailTab.chapters => 'Chapitres',
    _DetailTab.stats => 'Stats',
    _DetailTab.settings => 'Paramètres',
  };
}

String _primaryActionLabel(BookModel book) {
  if (book.status == BookStatus.published) {
    return 'Lire';
  }

  return 'Écrire';
}

String _bookGenre(BookModel book) {
  final genre = book.genre?.trim();
  if (genre == null || genre.isEmpty) {
    return '';
  }

  return genre;
}

String _bookLanguage(BookModel book) {
  final language = book.language?.trim();
  if (language == null || language.isEmpty) {
    return '';
  }

  return switch (language.toLowerCase()) {
    'fr' || 'fra' || 'fre' || 'french' => 'Français',
    'en' || 'eng' || 'english' => 'Anglais',
    _ => language,
  };
}

String _bookMetaLine(BookModel book) {
  final parts = [
    _bookGenre(book),
    _bookLanguage(book),
  ].where((part) => part.trim().isNotEmpty).toList(growable: false);

  if (parts.isEmpty) {
    return 'Informations non renseignées';
  }

  return parts.join(' · ');
}

String _bookSummary(BookModel book) {
  final description = book.description.trim();
  if (description.isNotEmpty) {
    return description;
  }

  return 'Aucun résumé encore.';
}

List<String> _bookTags(BookModel book) {
  return book.tags
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);
}

int _completedChapterCount(
  BookModel book,
  List<ChapterModel> chapters,
  int total,
) {
  if (total <= 0) {
    return 0;
  }

  final nonEmpty = chapters.where(_chapterHasContent).length;
  if (nonEmpty > 0) {
    return math.min(nonEmpty, total);
  }

  if (book.status == BookStatus.published ||
      book.status == BookStatus.inBetaReading) {
    return total;
  }

  final normalizedProgress = book.progress > 1
      ? book.progress / 100
      : book.progress;
  final estimated = (total * normalizedProgress).round();
  return math.min(total, math.max(0, estimated));
}

bool _chapterHasContent(ChapterModel chapter) {
  return chapter.content.trim().isNotEmpty;
}

int _chapterWordCount(ChapterModel chapter) {
  final text = chapter.content.trim();
  if (text.isEmpty) {
    return 0;
  }

  return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
}

List<Color> _bookCoverColors(BookModel book) {
  final title = book.title.toLowerCase();
  if (title.contains('nuit rouge')) {
    return const [Color(0xFF901BFF), Color(0xFF7B08E8), Color(0xFF21005D)];
  }
  if (title.contains('ombres')) {
    return const [Color(0xFF2457FF), Color(0xFF5428E8), Color(0xFF061126)];
  }
  if (title.contains('sang')) {
    return const [Color(0xFFFF0A4F), Color(0xFFE00012), Color(0xFF5B170B)];
  }

  final palettes = [
    [const Color(0xFF7C3AED), const Color(0xFFDB2777)],
    [const Color(0xFF2563EB), const Color(0xFF06B6D4)],
    [const Color(0xFFDC2626), const Color(0xFFEA580C)],
    [const Color(0xFF8FA889), const Color(0xFF5F7A5A)],
  ];
  final key = book.id.isEmpty ? book.title : book.id;
  final index =
      key.codeUnits.fold<int>(0, (sum, code) => sum + code) % palettes.length;
  return palettes[index];
}

String _shortModified(DateTime? date) {
  if (date == null) {
    return "Aujourd'hui";
  }

  final local = date.toLocal();
  final now = DateTime.now();

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  if (isSameDay(local, now)) {
    return "Aujourd'hui";
  }

  if (isSameDay(local, now.subtract(const Duration(days: 1)))) {
    return 'Hier';
  }

  return 'Il y a ${math.max(1, now.difference(local).inDays)} j';
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

  return 'Il y a ${math.max(1, now.difference(local).inDays)} jours';
}

String _dateLabel(DateTime? date) {
  if (date == null) {
    return '—';
  }

  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
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
