import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../catalog/data/models/external_book_model.dart';
import '../../catalog/data/repositories/external_book_repository.dart';
import '../data/repositories/admin_repository.dart';
import 'admin_colors.dart';
import 'admin_shell.dart';
import 'widgets/admin_widgets.dart';

class AdminPublicDomainImportScreen extends ConsumerStatefulWidget {
  const AdminPublicDomainImportScreen({super.key});

  @override
  ConsumerState<AdminPublicDomainImportScreen> createState() =>
      _AdminPublicDomainImportScreenState();
}

class _AdminPublicDomainImportScreenState
    extends ConsumerState<AdminPublicDomainImportScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _language;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(
      externalBookSearchProvider(
        ExternalBookSearchQuery(search: _query, language: _language),
      ),
    );

    return AdminShell(
      title: 'Import domaine public',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminPageHeader(
              title: 'Import domaine public',
              subtitle: 'Source : Gutendex',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: AdminSearchField(
                    controller: _searchController,
                    hintText: 'Titre ou auteur...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                for (final lang in const [null, 'fr', 'en'])
                  AdminFilterChip(
                    label: lang == null
                        ? 'Toutes les langues'
                        : lang == 'fr'
                        ? 'Français'
                        : 'Anglais',
                    selected: _language == lang,
                    onTap: () => setState(() => _language = lang),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            resultsAsync.when(
              loading: () => const AdminLoadingState(),
              error: (error, _) => AdminErrorState(
                message: AppError.messageFor(error),
                onRetry: () => ref.invalidate(
                  externalBookSearchProvider(
                    ExternalBookSearchQuery(
                      search: _query,
                      language: _language,
                    ),
                  ),
                ),
              ),
              data: (page) {
                if (page.content.isEmpty) {
                  return const AdminEmptyState(
                    title: 'Aucun résultat',
                    message: 'Essaie un autre titre, auteur ou langue.',
                    icon: Icons.public_off_outlined,
                  );
                }

                return FigmaResponsiveGrid(
                  minTileWidth: 440,
                  maxColumns: 2,
                  children: [
                    for (final book in page.content)
                      _ExternalBookCard(book: book),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExternalBookCard extends ConsumerWidget {
  const _ExternalBookCard({required this.book});

  final ExternalBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 66,
            decoration: BoxDecoration(
              color: AdminColors.border,
              borderRadius: BorderRadius.circular(8),
              image: book.coverUrl != null
                  ? DecorationImage(
                      image: NetworkImage(book.coverUrl!),
                      fit: BoxFit.cover,
                      onError: (error, stackTrace) {},
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: book.coverUrl == null
                ? const Icon(
                    Icons.menu_book_outlined,
                    size: 16,
                    color: AdminColors.muted,
                  )
                : null,
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
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AdminColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AdminBadge(
                      label: book.imported ? 'Déjà importé' : 'Domaine public',
                      color: book.imported
                          ? AdminColors.success
                          : AdminColors.plumora,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${book.authorLabel} · ${book.languages.isEmpty ? '—' : book.languages.first.toUpperCase()}',
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 12,
                      color: AdminColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${book.downloadCount} téléchargements',
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          book.imported
              ? OutlinedButton(
                  onPressed: book.canReadInPlumora
                      ? () => context.go(
                          AppRoutes.catalogBookDetailPath(book.internalBookId!),
                        )
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.success,
                    side: const BorderSide(color: AdminColors.success),
                  ),
                  child: const Text('Voir catalogue'),
                )
              : AdminPrimaryButton(
                  label: book.isOpenLibrary ? 'Bientôt disponible' : 'Importer',
                  onPressed: book.isOpenLibrary
                      ? null
                      : () => _confirmImport(context, ref),
                ),
        ],
      ),
    );
  }

  Future<void> _confirmImport(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ImportConfirmationDialog(book: book),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final gutendexId = int.tryParse(book.externalId);
    if (gutendexId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiant Gutendex invalide.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(adminRepositoryProvider)
          .importGutendexBook(gutendexId);
      ref.invalidate(externalBookSearchProvider);
      ref.invalidate(adminDashboardProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyExisted
                ? '"${result.title}" était déjà dans le catalogue.'
                : '"${result.title}" importé dans le catalogue.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppError.messageFor(error))),
      );
    }
  }
}

class _ImportConfirmationDialog extends StatefulWidget {
  const _ImportConfirmationDialog({required this.book});

  final ExternalBook book;

  @override
  State<_ImportConfirmationDialog> createState() =>
      _ImportConfirmationDialogState();
}

class _ImportConfirmationDialogState extends State<_ImportConfirmationDialog> {
  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AdminColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Confirmer l'import",
                style: const TextStyle(
                  color: AdminColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                book.title,
                style: const TextStyle(
                  color: AdminColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book.authorLabel,
                style: const TextStyle(color: AdminColors.muted, fontSize: 12),
              ),
              if (book.summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  book.summary,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (book.formats.isNotEmpty)
                Text(
                  'Formats : ${book.formats.keys.join(', ')}',
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 11,
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminColors.plumora.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AdminColors.plumora.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: AdminColors.plumora,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Action réservée aux administrateurs. Le livre sera ajouté au catalogue Plumora.',
                        style: TextStyle(
                          color: AdminColors.plumora,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                      label: "Confirmer l'import",
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
