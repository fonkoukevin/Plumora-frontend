import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../data/models/admin_book_model.dart';
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
                final filtered = books.where(_matchesTab).where(_matchesSearch).toList();

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
                          width: 200,
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
                                busy: _busyIds.contains(filtered[i].id),
                                onDetail: () => _openDetail(filtered[i]),
                                onArchive: filtered[i].isArchived ? null : () => _archive(filtered[i]),
                                onRestore: filtered[i].isArchived ? () => _restore(filtered[i]) : null,
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

  bool _matchesTab(AdminBook book) {
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

  bool _matchesSearch(AdminBook book) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    return book.title.toLowerCase().contains(query) ||
        book.authorLabel.toLowerCase().contains(query);
  }

  String _tabLabel(_CatalogTab tab) {
    switch (tab) {
      case _CatalogTab.all:
        return 'Tous';
      case _CatalogTab.plumora:
        return 'Œuvres Plumora';
      case _CatalogTab.public:
        return 'Domaine public';
      case _CatalogTab.archived:
        return 'Archivés';
    }
  }

  Future<void> _openDetail(AdminBook book) async {
    setState(() => _busyIds.add(book.id));
    var detail = book;
    try {
      detail = await ref.read(adminRepositoryProvider).getBookDetail(book.id);
    } catch (_) {
      // Falls back to the list-row data if the detail call fails.
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(book.id));
      }
    }
    if (!mounted) {
      return;
    }

    await AdminModal.show<void>(
      context,
      title: 'Détail du livre',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoverThumb(book: detail, width: 56, height: 78),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.title,
                      style: const TextStyle(color: AdminColors.text, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(detail.authorLabel, style: const TextStyle(color: AdminColors.muted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        AdminBadge(
                          label: detail.isPublicDomain ? 'Public' : 'Plumora',
                          color: detail.isPublicDomain ? AdminColors.primary : AdminColors.plumora,
                        ),
                        AdminBadge(label: detail.status, color: _statusColor(detail.status)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((detail.summary ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              detail.summary!,
              style: const TextStyle(color: AdminColors.muted, fontSize: 13, height: 1.45),
            ),
          ],
          const SizedBox(height: 14),
          AdminDetailRow(label: 'Ajouté le', value: Text(_formatDate(detail.createdAt))),
          if (detail.chaptersCount != null)
            AdminDetailRow(label: 'Chapitres', value: Text('${detail.chaptersCount}')),
          AdminDetailRow(
            label: 'Signalements',
            value: Text(
              '${detail.reportsCount}',
              style: TextStyle(color: detail.reportsCount > 0 ? AdminColors.error : AdminColors.text),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _archive(AdminBook book) async {
    final reasonController = TextEditingController();
    final confirmed = await AdminModal.show<bool>(
      context,
      title: 'Archiver le livre',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CoverThumb(book: book, width: 40, height: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  book.title,
                  style: const TextStyle(color: AdminColors.text, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdminColors.error.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 15, color: AdminColors.error),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ce livre ne sera plus visible publiquement.',
                    style: TextStyle(color: AdminColors.error, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text("Raison de l'archivage", style: TextStyle(color: AdminColors.muted, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: reasonController,
            maxLines: 3,
            style: const TextStyle(color: AdminColors.text, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Motif...',
              filled: true,
              fillColor: AdminColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AdminColors.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(foregroundColor: AdminColors.text, side: const BorderSide(color: AdminColors.border)),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AdminDangerButton(
                  label: 'Archiver',
                  outlined: false,
                  icon: Icons.archive_outlined,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final reason = reasonController.text;
    reasonController.dispose();
    if (confirmed != true || !mounted) {
      return;
    }

    await _runBookAction(
      book,
      () => ref.read(adminRepositoryProvider).archiveBook(book.id, reason: reason),
      successMessage: '"${book.title}" a été archivé.',
    );
  }

  Future<void> _restore(AdminBook book) async {
    final confirmed = await AdminModal.show<bool>(
      context,
      title: 'Restaurer le livre',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voulez-vous restaurer "${book.title}" ? Il redeviendra visible publiquement.',
            style: const TextStyle(color: AdminColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(foregroundColor: AdminColors.text, side: const BorderSide(color: AdminColors.border)),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AdminPrimaryButton(
                  label: 'Restaurer',
                  icon: Icons.restore,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runBookAction(
      book,
      () => ref.read(adminRepositoryProvider).restoreBook(book.id),
      successMessage: '"${book.title}" a été restauré.',
    );
  }

  Future<void> _runBookAction(
    AdminBook book,
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _busyIds.add(book.id));
    try {
      await action();
      ref.invalidate(adminBooksProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(book.id));
      }
    }
  }
}

class _CoverThumb extends ConsumerWidget {
  const _CoverThumb({required this.book, required this.width, required this.height});

  final AdminBook book;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: book.coverUrl != null
            ? Image.network(
                book.coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AdminColors.border,
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book_outlined, size: 14, color: AdminColors.muted),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({
    required this.book,
    required this.busy,
    required this.onDetail,
    required this.onArchive,
    required this.onRestore,
  });

  final AdminBook book;
  final bool busy;
  final VoidCallback onDetail;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: book.isArchived ? 0.65 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _CoverThumb(book: book, width: 34, height: 46),
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
                    style: const TextStyle(color: AdminColors.text, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.authorLabel,
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
                color: book.isPublicDomain ? AdminColors.primary : AdminColors.plumora,
              ),
            ),
            Expanded(child: AdminBadge(label: book.status, color: _statusColor(book.status))),
            SizedBox(
              width: 60,
              child: Text(
                book.reportsCount > 0 ? '${book.reportsCount}' : '—',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: book.reportsCount > 0 ? AdminColors.error : AdminColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(
              width: 96,
              child: busy
                  ? const Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Voir le détail',
                          onPressed: onDetail,
                          icon: const Icon(Icons.visibility_outlined, size: 15, color: AdminColors.muted),
                        ),
                        if (onArchive != null)
                          IconButton(
                            tooltip: 'Archiver',
                            onPressed: onArchive,
                            icon: const Icon(Icons.archive_outlined, size: 15, color: AdminColors.error),
                          ),
                        if (onRestore != null)
                          IconButton(
                            tooltip: 'Restaurer',
                            onPressed: onRestore,
                            icon: const Icon(Icons.restore, size: 15, color: AdminColors.success),
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

Color _statusColor(String status) {
  switch (status.trim().toUpperCase()) {
    case 'PUBLISHED':
      return AdminColors.success;
    case 'ARCHIVED':
      return AdminColors.muted;
    case 'DRAFT':
    case 'IN_CORRECTION':
    case 'IN_BETA_READING':
    case 'READY_TO_PUBLISH':
      return AdminColors.warning;
    default:
      return AdminColors.muted;
  }
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return '—';
  }
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
