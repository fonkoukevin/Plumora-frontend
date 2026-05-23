import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../data/models/catalog_book_model.dart';
import '../data/repositories/catalog_repository.dart';

class CatalogSearchScreen extends ConsumerStatefulWidget {
  const CatalogSearchScreen({this.initialQuery = '', super.key});

  final String initialQuery;

  @override
  ConsumerState<CatalogSearchScreen> createState() =>
      _CatalogSearchScreenState();
}

class _CatalogSearchScreenState extends ConsumerState<CatalogSearchScreen> {
  late final TextEditingController _controller;
  late String _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _controller = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(catalogSearchProvider(_query));

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 760 ? 32.0 : 16.0;
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 82.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            24,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.discover),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Retour'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Recherche',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: PlumoraColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un livre ou un auteur...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Rechercher',
                        onPressed: () => _search(_controller.text),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  resultsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => _SearchStateCard(
                      title: 'Recherche indisponible',
                      subtitle: AppError.messageFor(error),
                      action: FilledButton(
                        onPressed: () =>
                            ref.invalidate(catalogSearchProvider(_query)),
                        child: const Text('Réessayer'),
                      ),
                    ),
                    data: (books) {
                      if (books.isEmpty) {
                        return const _SearchStateCard(
                          title: 'Aucun résultat',
                          subtitle:
                              'Essaie un autre titre, auteur ou genre Plumora.',
                        );
                      }

                      return Column(
                        children: [
                          for (final book in books) ...[
                            _SearchBookCard(book: book),
                            const SizedBox(height: 14),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _search(String value) {
    final query = value.trim();
    setState(() => _query = query);
    context.go(AppRoutes.catalogSearchPath(query));
  }
}

class _SearchBookCard extends StatelessWidget {
  const _SearchBookCard({required this.book});

  final CatalogBookModel book;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      onTap: () => context.go(AppRoutes.catalogBookDetailPath(book.id)),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _Cover(book: book),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title.isEmpty ? 'Livre sans titre' : book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'par ${book.authorName}',
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (book.genre != null) PlumoraBadge(label: book.genre!),
                    _Meta(
                      icon: Icons.star,
                      label: book.rating == 0
                          ? 'Aucune note'
                          : book.rating.toStringAsFixed(1),
                    ),
                    _Meta(
                      icon: Icons.menu_book_outlined,
                      label: '${book.chapterCount} chapitres',
                    ),
                  ],
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

class _Cover extends ConsumerWidget {
  const _Cover({required this.book});

  final CatalogBookModel book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));

    return PlumoraBookCover(
      colors: _coverColors(book),
      imageUrl: book.coverUrl,
      imageBytes: cachedCover,
      width: 72,
      height: 100,
      radius: 13,
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: PlumoraColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: PlumoraColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SearchStateCard extends StatelessWidget {
  const _SearchStateCard({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: PlumoraColors.textSecondary),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

List<Color> _coverColors(CatalogBookModel book) {
  final palettes = [
    [const Color(0xFF7C3AED), const Color(0xFFDB2777)],
    [const Color(0xFF2563EB), const Color(0xFF06B6D4)],
    [const Color(0xFFDC2626), const Color(0xFFEA580C)],
    [const Color(0xFFDB2777), const Color(0xFFE11D48)],
    [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
    [const Color(0xFF059669), const Color(0xFF0D9488)],
  ];
  final key = book.id.isEmpty ? book.title : book.id;
  final index =
      key.codeUnits.fold<int>(0, (sum, code) => sum + code) % palettes.length;
  return palettes[index];
}
