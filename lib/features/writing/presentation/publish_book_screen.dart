import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/models/chapter_model.dart';
import '../../book/data/repositories/book_repository.dart';
import '../../book/data/repositories/chapter_repository.dart';
import '../../book/presentation/widgets/book_status_badge.dart';

class PublishBookScreen extends ConsumerStatefulWidget {
  const PublishBookScreen({required this.bookId, super.key});

  final String bookId;

  @override
  ConsumerState<PublishBookScreen> createState() => _PublishBookScreenState();
}

class _PublishBookScreenState extends ConsumerState<PublishBookScreen> {
  bool _isPublishing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(authorBookProvider(widget.bookId));
    final chaptersAsync = ref.watch(bookChaptersProvider(widget.bookId));

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 760 ? 32.0 : 16.0;
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 92.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            28,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: bookAsync.when(
                loading: () => const _LoadingCard(),
                error: (error, _) => _ErrorCard(
                  title: 'Livre introuvable',
                  message: AppError.messageFor(error),
                  onRetry: () =>
                      ref.invalidate(authorBookProvider(widget.bookId)),
                ),
                data: (book) => chaptersAsync.when(
                  loading: () => const _LoadingCard(),
                  error: (error, _) => _ErrorCard(
                    title: 'Chapitres indisponibles',
                    message: AppError.messageFor(error),
                    onRetry: () =>
                        ref.invalidate(bookChaptersProvider(widget.bookId)),
                  ),
                  data: (chapters) => _PublishContent(
                    book: book,
                    chapters: chapters,
                    error: _error,
                    isPublishing: _isPublishing,
                    onBack: () => context.go(
                      AppRoutes.authorBookDetailPath(widget.bookId),
                    ),
                    onOpenEditor: () =>
                        context.go(AppRoutes.chapterEditorPath(widget.bookId)),
                    onPublish: _canSubmit(book, chapters)
                        ? () => _publish(book.id)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _canSubmit(BookModel book, List<ChapterModel> chapters) {
    return book.canPublish && chapters.isNotEmpty && !_isPublishing;
  }

  Future<void> _publish(String bookId) async {
    setState(() {
      _isPublishing = true;
      _error = null;
    });

    try {
      await ref.read(bookRepositoryProvider).publishBook(bookId);
      ref.invalidate(authorBookProvider(bookId));
      ref.invalidate(myBooksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livre soumis à publication.')),
        );
        context.go(AppRoutes.authorBookDetailPath(bookId));
      }
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }
}

class _PublishContent extends StatelessWidget {
  const _PublishContent({
    required this.book,
    required this.chapters,
    required this.onBack,
    required this.onOpenEditor,
    required this.onPublish,
    required this.isPublishing,
    this.error,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final VoidCallback onBack;
  final VoidCallback onOpenEditor;
  final VoidCallback? onPublish;
  final bool isPublishing;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasTitle = book.title.trim().isNotEmpty;
    final hasDescription = book.description.trim().isNotEmpty;
    final hasChapters = chapters.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: isPublishing ? null : onBack,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: PlumoraColors.textSecondary,
          ),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Retour'),
        ),
        const SizedBox(height: 24),
        Text(
          'Soumettre à publication',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: PlumoraColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vérifie ton manuscrit avant de le publier dans Plumora.',
          style: TextStyle(color: PlumoraColors.textSecondary),
        ),
        const SizedBox(height: 24),
        PlumoraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PlumoraIconTile(
                    child: Icon(Icons.upload_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasTitle ? book.title : 'Livre sans titre',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        BookStatusBadge(status: book.status),
                      ],
                    ),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                _InlineError(message: error!),
              ],
              const SizedBox(height: 24),
              _ChecklistItem(
                label: 'Titre du livre',
                valid: hasTitle,
                detail: hasTitle ? book.title : 'Titre requis',
              ),
              const SizedBox(height: 12),
              _ChecklistItem(
                label: 'Résumé court',
                valid: hasDescription,
                detail: hasDescription
                    ? 'Résumé renseigné'
                    : 'Ajoute un résumé avant publication',
              ),
              const SizedBox(height: 12),
              _ChecklistItem(
                label: 'Chapitres',
                valid: hasChapters,
                detail: hasChapters
                    ? '${chapters.length} chapitre(s) prêt(s)'
                    : 'Ajoute au moins un chapitre',
              ),
              const SizedBox(height: 12),
              _ChecklistItem(
                label: 'Statut',
                valid: book.canPublish,
                detail: book.canPublish
                    ? 'Publication possible'
                    : 'Ce statut ne permet pas la publication',
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: isPublishing ? null : onOpenEditor,
                    icon: const Icon(Icons.edit_note_outlined, size: 18),
                    label: const Text('Ouvrir l’éditeur'),
                  ),
                  FilledButton.icon(
                    onPressed: onPublish,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text(
                      isPublishing
                          ? 'Publication...'
                          : 'Confirmer la publication',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.label,
    required this.valid,
    required this.detail,
  });

  final String label;
  final bool valid;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final color = valid ? PlumoraColors.success : PlumoraColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: valid ? const Color(0xFFEAF9EF) : const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7E0DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: PlumoraColors.destructive,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
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
