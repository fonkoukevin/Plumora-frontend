import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/repositories/book_repository.dart';
import '../../book/data/repositories/chapter_repository.dart';
import '../../book/presentation/widgets/book_status_badge.dart';

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

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(authorBookProvider(widget.bookId));
    final chaptersAsync = ref.watch(bookChaptersProvider(widget.bookId));

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
              constraints: const BoxConstraints(maxWidth: 960),
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
                  onRetry: () =>
                      ref.invalidate(authorBookProvider(widget.bookId)),
                ),
                data: (book) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BookHeader(
                      book: book,
                      isMutating: _isMutating,
                      error: _error,
                      onPublish: book.canPublish
                          ? () => _publish(book.id)
                          : null,
                      onArchive: book.isArchived
                          ? null
                          : () => _archive(book.id),
                    ),
                    const SizedBox(height: 22),
                    _MetadataGrid(book: book),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Chapitres',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () =>
                              context.go(AppRoutes.chapterEditorPath(book.id)),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ajouter / éditer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    chaptersAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => _ErrorPanel(
                        title: 'Chapitres indisponibles',
                        message: AppError.messageFor(error),
                        onRetry: () =>
                            ref.invalidate(bookChaptersProvider(widget.bookId)),
                      ),
                      data: (chapters) {
                        if (chapters.isEmpty) {
                          return _EmptyChapters(
                            onOpenEditor: () => context.go(
                              AppRoutes.chapterEditorPath(book.id),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (final chapter in chapters) ...[
                              PlumoraCard(
                                padding: const EdgeInsets.all(16),
                                onTap: () => context.go(
                                  AppRoutes.chapterEditorPath(book.id),
                                ),
                                child: Row(
                                  children: [
                                    PlumoraIconTile(
                                      size: 42,
                                      radius: 10,
                                      backgroundColor: PlumoraColors.secondary,
                                      child: Text(
                                        chapter.order == 0
                                            ? '–'
                                            : chapter.order.toString(),
                                        style: const TextStyle(
                                          color: PlumoraColors.primary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chapter.title.isEmpty
                                                ? 'Chapitre sans titre'
                                                : chapter.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '${chapter.content.length} caractères',
                                            style: const TextStyle(
                                              color:
                                                  PlumoraColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: PlumoraColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _publish(String bookId) async {
    await _mutate(() => ref.read(bookRepositoryProvider).publishBook(bookId));
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

class _BookHeader extends StatelessWidget {
  const _BookHeader({
    required this.book,
    required this.isMutating,
    required this.onPublish,
    required this.onArchive,
    this.error,
  });

  final BookModel book;
  final bool isMutating;
  final VoidCallback? onPublish;
  final VoidCallback? onArchive;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PlumoraIconTile(
                child: Icon(Icons.menu_book_outlined, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title.isEmpty ? 'Livre sans titre' : book.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.description.isEmpty
                          ? 'Aucune description'
                          : book.description,
                      style: const TextStyle(
                        color: PlumoraColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              BookStatusBadge(status: book.status),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(
              error!,
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
              FilledButton.icon(
                onPressed: isMutating
                    ? null
                    : () => context.go(AppRoutes.chapterEditorPath(book.id)),
                icon: const Icon(Icons.edit_note_outlined, size: 18),
                label: const Text('Éditer les chapitres'),
              ),
              OutlinedButton(
                onPressed: isMutating ? null : onPublish,
                child: Text(isMutating ? '...' : 'Publier'),
              ),
              TextButton(
                onPressed: isMutating ? null : onArchive,
                child: const Text('Archiver'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetadataGrid extends StatelessWidget {
  const _MetadataGrid({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Meta('Genre', book.genre ?? 'Non défini'),
      _Meta('Visibilité', book.visibility ?? 'Non définie'),
      _Meta('Chapitres', book.chapterCount.toString()),
      _Meta('Mots', book.wordCount.toString()),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: PlumoraCard(
                  shadow: false,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: PlumoraColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyChapters extends StatelessWidget {
  const _EmptyChapters({required this.onOpenEditor});

  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aucun chapitre',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ouvre l’éditeur pour créer le premier chapitre de ce livre.',
            style: TextStyle(color: PlumoraColors.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onOpenEditor,
            child: const Text('Ouvrir l’éditeur'),
          ),
        ],
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
    return PlumoraCard(
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
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _Meta {
  const _Meta(this.label, this.value);

  final String label;
  final String value;
}
