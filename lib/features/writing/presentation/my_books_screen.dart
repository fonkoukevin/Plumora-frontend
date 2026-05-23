import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../../book/data/repositories/book_repository.dart';
import '../../book/presentation/widgets/book_status_badge.dart';

class MyBooksScreen extends ConsumerWidget {
  const MyBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(myBooksProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 760 ? 32.0 : 16.0;
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
                  _Header(
                    title: 'Mes manuscrits',
                    subtitle: 'Tous tes livres auteur et leurs statuts.',
                    action: FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.createBook),
                      icon: const Icon(Icons.add, size: 19),
                      label: const Text('Nouveau livre'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _StatusLegend(),
                  const SizedBox(height: 22),
                  booksAsync.when(
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
                      if (books.isEmpty) {
                        return _EmptyBooks(
                          onCreate: () => context.go(AppRoutes.createBook),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, listConstraints) {
                          final columns = listConstraints.maxWidth >= 880
                              ? 2
                              : 1;
                          const spacing = 16.0;
                          final width = columns == 1
                              ? listConstraints.maxWidth
                              : (listConstraints.maxWidth - spacing) / 2;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: 16,
                            children: [
                              for (final book in books)
                                SizedBox(
                                  width: width,
                                  child: _BookCard(
                                    book: book,
                                    onRefresh: () =>
                                        ref.invalidate(myBooksProvider),
                                  ),
                                ),
                            ],
                          );
                        },
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
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final String title;
  final String subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: PlumoraColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: PlumoraColors.textSecondary),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text,
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: action),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: text),
            action,
          ],
        );
      },
    );
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    const statuses = [
      BookStatus.draft,
      BookStatus.inBetaReading,
      BookStatus.inCorrection,
      BookStatus.readyToPublish,
      BookStatus.published,
      BookStatus.archived,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final status in statuses) ...[
            BookStatusBadge(status: status),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _BookCard extends ConsumerStatefulWidget {
  const _BookCard({required this.book, required this.onRefresh});

  final BookModel book;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends ConsumerState<_BookCard> {
  bool _isMutating = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));

    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlumoraBookCover(
                colors: _bookCoverColors(book),
                imageUrl: book.coverUrl,
                imageBytes: cachedCover,
                width: 54,
                height: 76,
                radius: 10,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title.isEmpty ? 'Livre sans titre' : book.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.description.isEmpty
                          ? 'Aucune description'
                          : book.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PlumoraColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              BookStatusBadge(status: book.status),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: const TextStyle(
                color: PlumoraColors.destructive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: _isMutating
                    ? null
                    : () => context.go(AppRoutes.authorBookDetailPath(book.id)),
                child: const Text('Détail'),
              ),
              OutlinedButton(
                onPressed: _isMutating
                    ? null
                    : () => context.go(AppRoutes.chapterEditorPath(book.id)),
                child: const Text('Éditer'),
              ),
              FilledButton(
                onPressed: _isMutating || !book.canPublish
                    ? null
                    : () => context.go(AppRoutes.publishBookPath(book.id)),
                child: Text(_isMutating ? '...' : 'Publier'),
              ),
              TextButton(
                onPressed: _isMutating || book.isArchived
                    ? null
                    : () => _archive(book.id),
                child: const Text('Archiver'),
              ),
            ],
          ),
        ],
      ),
    );
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
      widget.onRefresh();
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlumoraIconTile(
            backgroundColor: Color(0xFFF7E0DC),
            child: Icon(Icons.error_outline, color: PlumoraColors.destructive),
          ),
          const SizedBox(height: 18),
          Text(
            'Impossible de charger les manuscrits',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: PlumoraColors.textSecondary),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _EmptyBooks extends StatelessWidget {
  const _EmptyBooks({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlumoraIconTile(
            backgroundColor: PlumoraColors.secondary,
            child: Icon(
              Icons.auto_stories_outlined,
              color: PlumoraColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Aucun manuscrit',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crée ton premier livre, puis ajoute des chapitres dans l’éditeur.',
            style: TextStyle(color: PlumoraColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onCreate,
            child: const Text('Créer un livre'),
          ),
        ],
      ),
    );
  }
}

List<Color> _bookCoverColors(BookModel book) {
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
