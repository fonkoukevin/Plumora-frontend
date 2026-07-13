import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../../book/presentation/widgets/book_status_badge.dart';
import '../data/models/admin_report_model.dart';
import '../data/repositories/admin_repository.dart';
import 'admin_colors.dart';
import 'admin_shell.dart';
import 'widgets/admin_widgets.dart';

enum _CatalogTab { all, plumora, public, archived }

class AdminCatalogScreen extends ConsumerStatefulWidget {
  const AdminCatalogScreen({super.key});

  @override
  ConsumerState<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends ConsumerState<AdminCatalogScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  _CatalogTab _tab = _CatalogTab.all;
  final Set<String> _busyIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(adminBooksProvider);
    final reportsAsync = ref.watch(adminReportsProvider);

    return AdminShell(
      title: 'Catalogue',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'Catalogue',
              subtitle: booksAsync.maybeWhen(
                data: (books) => '${books.length} œuvres au total',
                orElse: () => 'Modération du catalogue Plumora',
              ),
            ),
            const SizedBox(height: 16),
            booksAsync.when(
              loading: () => const AdminLoadingState(),
              error: (error, _) => AdminErrorState(
                message: AppError.messageFor(error),
                onRetry: () => ref.invalidate(adminBooksProvider),
              ),
              data: (books) {
                final reportCounts = reportsAsync.maybeWhen(
                  data: _countReportsByBook,
                  orElse: () => const <String, int>{},
                );
                final tabbed = books.where(_matchesTab).toList();
                final filtered = tabbed.where(_matchesSearch).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final tab in _CatalogTab.values)
                          AdminFilterChip(
                            label: _tabLabel(tab),
                            selected: _tab == tab,
                            onTap: () => setState(() => _tab = tab),
                          ),
                        SizedBox(
                          width: 220,
                          child: AdminSearchField(
                            controller: _searchController,
                            hintText: 'Rechercher...',
                            onChanged: (value) => setState(() => _search = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      const AdminEmptyState(
                        title: 'Aucun livre trouvé',
                        message: 'Essaie un autre onglet ou une autre recherche.',
                        icon: Icons.menu_book_outlined,
                      )
                    else
                      AdminCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < filtered.length; i++) ...[
                              _BookRow(
                                book: filtered[i],
                                reportCount: reportCounts[filtered[i].id] ?? 0,
                                busy: _busyIds.contains(filtered[i].id),
                                onArchive: filtered[i].isArchived
                                    ? null
                                    : () => _archive(filtered[i]),
                              ),
                              if (i != filtered.length - 1)
                                const Divider(color: AdminColors.border, height: 1),
                            ],
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _countReportsByBook(List<AdminReport> reports) {
    final counts = <String, int>{};
    for (final report in reports) {
      final bookId = report.bookId;
      if (bookId == null || bookId.isEmpty) {
        continue;
      }
      if (report.status != AdminReportStatus.open &&
          report.status != AdminReportStatus.inReview) {
        continue;
      }
      counts[bookId] = (counts[bookId] ?? 0) + 1;
    }
    return counts;
  }

  bool _matchesTab(BookModel book) {
    switch (_tab) {
      case _CatalogTab.all:
        return true;
      case _CatalogTab.plumora:
        return !book.isPublicDomain && !book.isArchived;
      case _CatalogTab.public:
        return book.isPublicDomain;
      case _CatalogTab.archived:
        return book.isArchived;
    }
  }

  bool _matchesSearch(BookModel book) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    return book.title.toLowerCase().contains(query) ||
        (book.authorUsername ?? '').toLowerCase().contains(query);
  }

  String _tabLabel(_CatalogTab tab) {
    switch (tab) {
      case _CatalogTab.all:
        return 'Tous les livres';
      case _CatalogTab.plumora:
        return 'Œuvres Plumora';
      case _CatalogTab.public:
        return 'Domaine public';
      case _CatalogTab.archived:
        return 'Archivés';
    }
  }

  Future<void> _archive(BookModel book) async {
    final confirmed = await showAdminConfirmationDialog(
      context,
      title: 'Archiver ce livre ?',
      message:
          '"${book.title}" ne sera plus visible dans le catalogue public. Cette action est réservée aux administrateurs.',
      confirmLabel: 'Archiver',
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _busyIds.add(book.id));
    try {
      await ref.read(adminRepositoryProvider).archiveBook(book.id);
      ref.invalidate(adminBooksProvider);
      ref.invalidate(adminDashboardStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livre archivé.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppError.messageFor(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(book.id));
      }
    }
  }
}

class _BookRow extends ConsumerWidget {
  const _BookRow({
    required this.book,
    required this.reportCount,
    required this.busy,
    required this.onArchive,
  });

  final BookModel book;
  final int reportCount;
  final bool busy;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 34,
              height: 46,
              child: book.coverUrl != null || cachedCover != null
                  ? Image.network(
                      book.coverUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _coverPlaceholder(),
                    )
                  : _coverPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title.isEmpty ? 'Livre sans titre' : book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.authorUsername ?? 'Auteur inconnu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AdminColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: AdminBadge(
              label: book.isPublicDomain ? 'Public' : 'Plumora',
              color: book.isPublicDomain ? AdminColors.accent : AdminColors.primary,
            ),
          ),
          Expanded(
            child: AdminBadge(
              label: book.status.frenchLabel,
              color: _statusColor(book.status),
            ),
          ),
          SizedBox(
            width: 60,
            child: reportCount > 0
                ? AdminBadge(label: '$reportCount', color: AdminColors.error)
                : const SizedBox.shrink(),
          ),
          SizedBox(
            width: 84,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Voir',
                  onPressed: () =>
                      context.go(AppRoutes.catalogBookDetailPath(book.id)),
                  icon: const Icon(Icons.visibility_outlined, size: 16, color: AdminColors.muted),
                ),
                if (onArchive != null)
                  IconButton(
                    tooltip: 'Archiver',
                    onPressed: busy ? null : onArchive,
                    icon: busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.archive_outlined, size: 16, color: AdminColors.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: AdminColors.border,
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book_outlined, size: 14, color: AdminColors.muted),
    );
  }

  Color _statusColor(BookStatus status) {
    switch (status) {
      case BookStatus.published:
        return AdminColors.success;
      case BookStatus.archived:
        return AdminColors.muted;
      case BookStatus.draft:
      case BookStatus.inCorrection:
      case BookStatus.inBetaReading:
      case BookStatus.readyToPublish:
        return AdminColors.warning;
      case BookStatus.unknown:
        return AdminColors.muted;
    }
  }
}
