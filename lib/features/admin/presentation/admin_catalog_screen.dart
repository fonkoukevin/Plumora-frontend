import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/widgets/plumora_ui.dart';
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 20,
              compact ? 16 : 20,
              compact ? 14 : 20,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminPageHeader(
                  title: 'Catalogue',
                  compact: compact,
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
                    final filtered = books
                        .where(_matchesTab)
                        .where(_matchesSearch)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (compact)
                          _CompactCatalogFilters(
                            selectedTab: _tab,
                            searchController: _searchController,
                            onTabSelected: (tab) => setState(() => _tab = tab),
                            onSearchChanged: (value) =>
                                setState(() => _search = value),
                          )
                        else
                          Row(
                            children: [
                              for (
                                var index = 0;
                                index < _CatalogTab.values.length;
                                index++
                              ) ...[
                                AdminFilterChip(
                                  label: _tabLabel(_CatalogTab.values[index]),
                                  selected: _tab == _CatalogTab.values[index],
                                  compact: true,
                                  onTap: () => setState(
                                    () => _tab = _CatalogTab.values[index],
                                  ),
                                ),
                                if (index != _CatalogTab.values.length - 1)
                                  const SizedBox(width: 8),
                              ],
                              const Spacer(),
                              SizedBox(
                                width: 176,
                                child: AdminSearchField(
                                  controller: _searchController,
                                  compact: true,
                                  hintText: 'Rechercher...',
                                  onChanged: (value) =>
                                      setState(() => _search = value),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        if (filtered.isEmpty)
                          const AdminEmptyState(
                            title: 'Aucun livre trouvé',
                            message:
                                'Essaie un autre onglet ou une autre recherche.',
                            icon: Icons.menu_book_outlined,
                          )
                        else if (compact)
                          Column(
                            children: [
                              for (var i = 0; i < filtered.length; i++) ...[
                                _BookMobileCard(
                                  book: filtered[i],
                                  busy: _busyIds.contains(filtered[i].id),
                                  onDetail: () => _openDetail(filtered[i]),
                                  onArchive: filtered[i].isArchived
                                      ? null
                                      : () => _archive(filtered[i]),
                                  onRestore: filtered[i].isArchived
                                      ? () => _restore(filtered[i])
                                      : null,
                                ),
                                if (i != filtered.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            ],
                          )
                        else
                          AdminCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                const _BookTableHeader(),
                                for (var i = 0; i < filtered.length; i++) ...[
                                  _BookRow(
                                    book: filtered[i],
                                    busy: _busyIds.contains(filtered[i].id),
                                    onDetail: () => _openDetail(filtered[i]),
                                    onArchive: filtered[i].isArchived
                                        ? null
                                        : () => _archive(filtered[i]),
                                    onRestore: filtered[i].isArchived
                                        ? () => _restore(filtered[i])
                                        : null,
                                  ),
                                  if (i != filtered.length - 1)
                                    const Divider(
                                      color: AdminColors.border,
                                      height: 1,
                                    ),
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
          );
        },
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
                      style: const TextStyle(
                        color: AdminColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail.authorLabel,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        AdminBadge(
                          label: detail.isPublicDomain ? 'Public' : 'Plumora',
                          color: detail.isPublicDomain
                              ? AdminColors.primary
                              : AdminColors.plumora,
                        ),
                        AdminBadge(
                          label: detail.status,
                          color: _statusColor(detail.status),
                          icon: _statusIcon(detail.status),
                        ),
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
              style: const TextStyle(
                color: AdminColors.muted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          AdminDetailRow(
            label: 'Ajouté le',
            value: Text(_formatDate(detail.createdAt)),
          ),
          if (detail.chaptersCount != null)
            AdminDetailRow(
              label: 'Chapitres',
              value: Text('${detail.chaptersCount}'),
            ),
          AdminDetailRow(
            label: 'Signalements',
            value: Text(
              '${detail.reportsCount}',
              style: TextStyle(
                color: detail.reportsCount > 0
                    ? AdminColors.error
                    : AdminColors.text,
              ),
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
                  style: const TextStyle(
                    color: AdminColors.text,
                    fontWeight: FontWeight.w700,
                  ),
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
              border: Border.all(
                color: AdminColors.error.withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 15,
                  color: AdminColors.error,
                ),
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
          const Text(
            "Raison de l'archivage",
            style: TextStyle(color: AdminColors.muted, fontSize: 12),
          ),
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.text,
                    side: const BorderSide(color: AdminColors.border),
                  ),
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
      () => ref
          .read(adminRepositoryProvider)
          .archiveBook(book.id, reason: reason),
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.text,
                    side: const BorderSide(color: AdminColors.border),
                  ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(book.id));
      }
    }
  }
}

class _CompactCatalogFilters extends StatelessWidget {
  const _CompactCatalogFilters({
    required this.selectedTab,
    required this.searchController,
    required this.onTabSelected,
    required this.onSearchChanged,
  });

  final _CatalogTab selectedTab;
  final TextEditingController searchController;
  final ValueChanged<_CatalogTab> onTabSelected;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tab in const [
              _CatalogTab.all,
              _CatalogTab.plumora,
              _CatalogTab.public,
            ])
              AdminFilterChip(
                label: _labelFor(tab),
                selected: selectedTab == tab,
                compact: true,
                onTap: () => onTabSelected(tab),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AdminFilterChip(
              label: _labelFor(_CatalogTab.archived),
              selected: selectedTab == _CatalogTab.archived,
              compact: true,
              onTap: () => onTabSelected(_CatalogTab.archived),
            ),
            const Spacer(),
            SizedBox(
              width: 151,
              child: AdminSearchField(
                controller: searchController,
                compact: true,
                hintText: 'Rechercher...',
                onChanged: onSearchChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _labelFor(_CatalogTab tab) {
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
}

class _CoverThumb extends ConsumerWidget {
  const _CoverThumb({
    required this.book,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final AdminBook book;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlumoraBookCover(
      width: width,
      height: height,
      radius: radius,
      colors: _coverColors(book),
      imageUrl: book.coverUrl,
      semanticLabel: 'Couverture de ${book.title}',
    );
  }
}

List<Color> _coverColors(AdminBook book) {
  const palettes = [
    [Color(0xFF7C2CFF), Color(0xFF3E2AC9)],
    [Color(0xFFD86600), Color(0xFF302727)],
    [Color(0xFFFF315F), Color(0xFFD83A00)],
    [Color(0xFF00964F), Color(0xFF006B67)],
    [Color(0xFF7D8CA7), Color(0xFF596277)],
    [Color(0xFF9B52D1), Color(0xFF4E3DA7)],
  ];
  final seed = '${book.id}${book.title}'.codeUnits.fold<int>(
    0,
    (sum, value) => sum + value,
  );
  return palettes[seed % palettes.length];
}

class _BookMobileCard extends StatelessWidget {
  const _BookMobileCard({
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
      opacity: book.isArchived ? 0.68 : 1,
      child: AdminCard(
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoverThumb(book: book, width: 38, height: 52),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title.isEmpty ? 'Livre sans titre' : book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AdminColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.authorLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AdminColors.muted,
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(spacing: 5, runSpacing: 4, children: _badgesFor(book)),
                  const SizedBox(height: 7),
                  if (busy)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _CompactCatalogAction(
                          label: 'Détail',
                          icon: Icons.visibility_outlined,
                          color: AdminColors.text,
                          onTap: onDetail,
                        ),
                        if (onArchive != null)
                          _CompactCatalogAction(
                            label: 'Archiver',
                            icon: Icons.archive_outlined,
                            color: AdminColors.error,
                            filled: true,
                            onTap: onArchive!,
                          ),
                        if (onRestore != null)
                          _CompactCatalogAction(
                            label: 'Restaurer',
                            icon: Icons.restore,
                            color: AdminColors.success,
                            filled: true,
                            onTap: onRestore!,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _badgesFor(AdminBook book) {
    final badges = <Widget>[
      _CatalogBadge(
        label: book.isPublicDomain ? 'Public' : 'Plumora',
        color: book.isPublicDomain ? AdminColors.primary : AdminColors.plumora,
      ),
    ];

    if (book.isArchived) {
      badges.add(
        const _CatalogBadge(
          label: 'Archivé',
          color: AdminColors.muted,
          icon: Icons.archive_outlined,
        ),
      );
    } else if (book.reportsCount > 0) {
      badges.add(
        const _CatalogBadge(
          label: 'Signalé',
          color: AdminColors.error,
          icon: Icons.warning_amber_rounded,
        ),
      );
      badges.add(
        _CatalogBadge(
          label:
              '${book.reportsCount} signalement${book.reportsCount > 1 ? 's' : ''}',
          color: AdminColors.error,
          icon: Icons.flag_outlined,
        ),
      );
    } else {
      badges.add(
        _CatalogBadge(
          label: _statusLabel(book.status),
          color: _statusColor(book.status),
          icon: book.status.trim().toUpperCase() == 'PUBLISHED'
              ? Icons.check_circle_outline
              : null,
        ),
      );
    }

    return badges;
  }
}

class _CatalogBadge extends StatelessWidget {
  const _CatalogBadge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCatalogAction extends StatelessWidget {
  const _CompactCatalogAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            // Cible tactile Android >= 48dp (RGAA/WCAG 2.5.5) : la pastille
            // visuelle reste compacte (26px) mais la zone tactile est
            // agrandie symétriquement autour du même centre.
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: filled ? color : AdminColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: filled ? Colors.white : color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: filled ? Colors.white : color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

class _BookTableHeader extends StatelessWidget {
  const _BookTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 18, child: _BookHeaderLabel('TITRE')),
          Expanded(flex: 22, child: _BookHeaderLabel('AUTEUR', centered: true)),
          Expanded(flex: 19, child: _BookHeaderLabel('TYPE', centered: true)),
          Expanded(flex: 19, child: _BookHeaderLabel('STATUT', centered: true)),
          SizedBox(
            width: 90,
            child: _BookHeaderLabel('SIGNALEMENTS', centered: true),
          ),
          SizedBox(
            width: 78,
            child: _BookHeaderLabel('ACTIONS', centered: true),
          ),
        ],
      ),
    );
  }
}

class _BookHeaderLabel extends StatelessWidget {
  const _BookHeaderLabel(this.label, {this.centered = false});

  final String label;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: centered ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        color: AdminColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.25,
      ),
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
    final isReported = !book.isArchived && book.reportsCount > 0;
    final statusLabel = isReported ? 'Signalé' : _statusLabel(book.status);
    final statusColor = isReported
        ? AdminColors.error
        : _statusColor(book.status);
    final statusIcon = isReported
        ? Icons.warning_amber_rounded
        : _statusIcon(book.status);

    return Opacity(
      opacity: book.isArchived ? 0.65 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 18,
              child: Row(
                children: [
                  _CoverThumb(book: book, width: 32, height: 44, radius: 4),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      book.title.isEmpty ? 'Livre sans titre' : book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 22,
              child: Text(
                book.authorLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AdminColors.muted, fontSize: 11),
              ),
            ),
            Expanded(
              flex: 19,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: SizedBox(
                      width: double.infinity,
                      child: AdminBadge(
                        label: book.isPublicDomain ? 'Public' : 'Plumora',
                        color: book.isPublicDomain
                            ? AdminColors.primary
                            : AdminColors.plumora,
                        compact: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 19,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: SizedBox(
                      width: double.infinity,
                      child: AdminBadge(
                        label: statusLabel,
                        color: statusColor,
                        icon: statusIcon,
                        compact: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 90,
              child: Text(
                book.reportsCount > 0 ? '${book.reportsCount}' : '—',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: book.reportsCount > 0
                      ? AdminColors.error
                      : AdminColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            SizedBox(
              width: 78,
              child: busy
                  ? const Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _BookTableAction(
                          tooltip: 'Voir le détail',
                          onPressed: onDetail,
                          icon: Icons.visibility_outlined,
                          color: AdminColors.muted,
                        ),
                        if (onArchive != null)
                          _BookTableAction(
                            tooltip: 'Archiver',
                            onPressed: onArchive!,
                            icon: Icons.archive_outlined,
                            color: AdminColors.error,
                          ),
                        if (onRestore != null)
                          _BookTableAction(
                            tooltip: 'Restaurer',
                            onPressed: onRestore!,
                            icon: Icons.restore,
                            color: AdminColors.success,
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

class _BookTableAction extends StatelessWidget {
  const _BookTableAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.color,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 13, color: color),
    );
  }
}

String _statusLabel(String status) {
  switch (status.trim().toUpperCase()) {
    case 'PUBLISHED':
      return 'Publié';
    case 'ARCHIVED':
      return 'Archivé';
    case 'DRAFT':
      return 'Brouillon';
    case 'IN_CORRECTION':
      return 'En correction';
    case 'IN_BETA_READING':
      return 'Bêta-lecture';
    case 'READY_TO_PUBLISH':
      return 'Prêt à publier';
    default:
      return status.isEmpty ? 'Inconnu' : status;
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

IconData _statusIcon(String status) {
  switch (status.trim().toUpperCase()) {
    case 'PUBLISHED':
      return Icons.check_circle;
    case 'ARCHIVED':
      return Icons.archive;
    case 'DRAFT':
    case 'IN_CORRECTION':
    case 'IN_BETA_READING':
    case 'READY_TO_PUBLISH':
      return Icons.schedule;
    default:
      return Icons.schedule;
  }
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return '—';
  }
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
