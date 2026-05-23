import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../beta_reading/presentation/beta_invitations_screen.dart';
import '../../catalog/data/models/catalog_book_model.dart';
import '../../catalog/data/repositories/catalog_repository.dart';
import '../data/models/reading_progress_model.dart';
import '../data/repositories/reading_repository.dart';
import 'my_favorites_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _activeTab = 'Mes lectures';
  String _libraryQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final horizontal = isWide ? 32.0 : 16.0;
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 82.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            28,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bibliothèque',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: PlumoraColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tous vos livres au même endroit',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PlumoraColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _LibrarySearchField(
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => _libraryQuery = value.trim()),
                    onSubmitted: _submitSearch,
                  ),
                  const SizedBox(height: 24),
                  PlumoraSegmentedTabs(
                    tabs: const ['Mes lectures', 'Favoris', 'Bêta-lectures'],
                    selectedTab: _activeTab,
                    onSelected: (value) => setState(() => _activeTab = value),
                  ),
                  const SizedBox(height: 26),
                  if (_activeTab == 'Mes lectures')
                    _ReadingsTab(query: _libraryQuery),
                  if (_activeTab == 'Favoris') const MyFavoritesScreen(),
                  if (_activeTab == 'Bêta-lectures') const _BetaReadingsTab(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submitSearch(String value) {
    setState(() => _libraryQuery = value.trim());
  }
}

class _LibrarySearchField extends StatelessWidget {
  const _LibrarySearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          color: PlumoraColors.textPrimary,
          fontSize: 14,
          height: 1.2,
        ),
        decoration: const InputDecoration(
          hintText: 'Rechercher un livre, un auteur, un genre...',
          prefixIcon: Icon(
            Icons.search,
            color: PlumoraColors.textSecondary,
            size: 22,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }
}

class _ReadingsTab extends ConsumerWidget {
  const _ReadingsTab({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(myReadingProgressProvider);
    final normalizedQuery = query.trim();
    final booksAsync = normalizedQuery.isEmpty
        ? ref.watch(catalogBooksProvider(''))
        : ref.watch(catalogSearchProvider(normalizedQuery));

    return booksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => _LibraryStateCard(
        title: 'Catalogue indisponible',
        subtitle: AppError.messageFor(error),
        action: FilledButton(
          onPressed: () {
            if (normalizedQuery.isEmpty) {
              ref.invalidate(catalogBooksProvider(''));
            } else {
              ref.invalidate(catalogSearchProvider(normalizedQuery));
            }
          },
          child: const Text('Réessayer'),
        ),
      ),
      data: (books) {
        if (books.isEmpty) {
          return _LibraryStateCard(
            title: normalizedQuery.isEmpty
                ? 'Aucun livre disponible'
                : 'Aucun résultat',
            subtitle: normalizedQuery.isEmpty
                ? 'Les livres publiés apparaîtront ici dès qu’ils seront disponibles.'
                : 'Aucun livre ne correspond à cette recherche.',
            action: normalizedQuery.isEmpty
                ? FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.discover),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Découvrir'),
                  )
                : null,
          );
        }

        final progressByBookId = progressAsync.maybeWhen(
          data: (readings) => {
            for (final reading in readings) reading.bookId: reading,
          },
          orElse: () => <String, ReadingProgressModel>{},
        );
        final finished = books
            .where((book) => progressByBookId[book.id]?.finished ?? false)
            .length;

        return Column(
          children: [
            if (progressAsync.hasError) ...[
              _InlineWarning(
                message: AppError.messageFor(progressAsync.error!),
              ),
              const SizedBox(height: 16),
            ],
            for (final book in books) ...[
              _CatalogReadingCard(
                book: book,
                progress: progressByBookId[book.id],
              ),
              const SizedBox(height: 16),
            ],
            _LibraryStats(savedCount: books.length, finishedCount: finished),
          ],
        );
      },
    );
  }
}

class _CatalogReadingCard extends StatelessWidget {
  const _CatalogReadingCard({required this.book, this.progress});

  final CatalogBookModel book;
  final ReadingProgressModel? progress;

  @override
  Widget build(BuildContext context) {
    final title = book.title.trim().isEmpty ? 'Livre sans titre' : book.title;
    final readingProgress = progress;
    final progressPercent = readingProgress?.progressPercent ?? 0;
    final isFinished = readingProgress?.finished ?? false;
    final hasProgress = readingProgress != null;

    return PlumoraCard(
      leftAccent: PlumoraColors.primary,
      onTap: () => context.go(AppRoutes.readingPath(book.id)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 480;
          final cover = PlumoraBookCover(
            colors: _catalogCoverColors(book),
            width: compact ? 72 : 96,
            height: compact ? 104 : 128,
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  PlumoraBadge(
                    label: isFinished
                        ? 'Terminé ✓'
                        : hasProgress
                        ? 'En cours'
                        : 'À lire',
                    backgroundColor: isFinished
                        ? const Color(0xFFEADFCF)
                        : const Color(0xFFE6EFE4),
                    foregroundColor: isFinished
                        ? const Color(0xFF7A5E2F)
                        : const Color(0xFF5F7A5A),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'par ${book.authorName}',
                style: const TextStyle(
                  color: PlumoraColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAE9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Progression de lecture',
                            style: TextStyle(
                              color: PlumoraColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '$progressPercent%',
                          style: const TextStyle(
                            color: PlumoraColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: (readingProgress?.progress ?? 0).clamp(0, 1),
                        backgroundColor: Colors.white,
                        color: PlumoraColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _Meta(
                    icon: Icons.schedule,
                    label: hasProgress
                        ? _lastReadLabel(readingProgress.updatedAt)
                        : 'Pas encore lu',
                  ),
                  _RatingStars(rating: book.rating.round().clamp(0, 5)),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [cover, const SizedBox(height: 14), details],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cover,
              const SizedBox(width: 18),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _BetaReadingsTab extends StatelessWidget {
  const _BetaReadingsTab();

  @override
  Widget build(BuildContext context) {
    return const BetaInvitationsScreen(embedded: true);
  }
}

class _LibraryStats extends StatelessWidget {
  const _LibraryStats({required this.savedCount, required this.finishedCount});

  final int savedCount;
  final int finishedCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 3 : 1;
        const spacing = 16.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [
            _LibraryStat(
              label: 'Livres sauvegardés',
              value: savedCount.toString(),
            ),
            _LibraryStat(
              label: 'Livres terminés',
              value: finishedCount.toString(),
            ),
            _LibraryStat(
              label: 'En cours',
              value: (savedCount - finishedCount).toString(),
            ),
          ].map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }
}

class _LibraryStat extends StatelessWidget {
  const _LibraryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      shadow: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: PlumoraColors.primary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryStateCard extends StatelessWidget {
  const _LibraryStateCard({
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

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PlumoraColors.border),
      ),
      child: Text(
        'Progression indisponible : $message',
        style: const TextStyle(
          color: PlumoraColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
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
        Icon(icon, size: 16, color: PlumoraColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: PlumoraColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    if (rating == 0) {
      return const Text(
        'Aucune note',
        style: TextStyle(color: PlumoraColors.textSecondary, fontSize: 12),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < rating; index++)
          Icon(Icons.star, size: 15, color: const Color(0xFFF5C84C)),
        const SizedBox(width: 5),
        Text(
          '$rating/5',
          style: const TextStyle(
            color: PlumoraColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _lastReadLabel(DateTime? updatedAt) {
  if (updatedAt == null) {
    return 'Lecture récente';
  }

  final now = DateTime.now();
  final difference = now.difference(updatedAt.toLocal());
  if (difference.inHours < 1) {
    return 'Lu à l’instant';
  }
  if (difference.inHours < 24) {
    return 'Lu il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
  }
  if (difference.inDays == 1) {
    return 'Lu hier';
  }
  return 'Lu il y a ${difference.inDays} jours';
}

List<Color> _catalogCoverColors(CatalogBookModel book) {
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
