import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/models/chapter_model.dart';
import '../../book/data/repositories/book_repository.dart';
import '../../book/data/repositories/chapter_repository.dart';

class ChapterDetailAuthorScreen extends ConsumerStatefulWidget {
  const ChapterDetailAuthorScreen({
    required this.chapterId,
    this.bookId,
    super.key,
  });

  final String chapterId;
  final String? bookId;

  @override
  ConsumerState<ChapterDetailAuthorScreen> createState() =>
      _ChapterDetailAuthorScreenState();
}

class _ChapterDetailAuthorScreenState
    extends ConsumerState<ChapterDetailAuthorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _loadedChapterId;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterProvider(widget.chapterId));

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
              constraints: const BoxConstraints(maxWidth: 920),
              child: chapterAsync.when(
                loading: () => const _LoadingCard(),
                error: (error, _) => _ErrorCard(
                  title: 'Chapitre introuvable',
                  message: AppError.messageFor(error),
                  onRetry: () =>
                      ref.invalidate(chapterProvider(widget.chapterId)),
                ),
                data: (chapter) {
                  _syncChapter(chapter);
                  return _ChapterDetailForm(
                    chapter: chapter,
                    titleController: _titleController,
                    contentController: _contentController,
                    error: _error,
                    isSaving: _isSaving,
                    isDeleting: _isDeleting,
                    onBack: () => _goBack(chapter),
                    onOpenEditor: () => context.go(
                      AppRoutes.chapterEditorPath(_bookId(chapter)),
                    ),
                    onSave: () => _save(chapter),
                    onDelete: () => _confirmDelete(chapter),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _syncChapter(ChapterModel chapter) {
    if (_loadedChapterId == chapter.id) {
      return;
    }

    _loadedChapterId = chapter.id;
    _titleController.text = chapter.title;
    _contentController.text = chapter.content;
    _error = null;
  }

  String _bookId(ChapterModel chapter) {
    final explicit = widget.bookId?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    return chapter.bookId;
  }

  void _goBack(ChapterModel chapter) {
    final bookId = _bookId(chapter);
    if (bookId.isNotEmpty) {
      context.go(AppRoutes.authorBookDetailPath(bookId));
      return;
    }

    context.go(AppRoutes.write);
  }

  Future<void> _save(ChapterModel chapter) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final saved = await ref
          .read(chapterRepositoryProvider)
          .updateChapter(
            chapter.id,
            ChapterUpsertRequest(
              title: _titleController.text,
              content: _contentController.text,
              order: chapter.order == 0 ? null : chapter.order,
            ),
          );
      _invalidateAfterMutation(saved);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chapitre sauvegardé.')));
      }
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete(ChapterModel chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (context) => _DeleteChapterDialog(chapterTitle: chapter.title),
    );

    if (confirmed == true) {
      await _delete(chapter);
    }
  }

  Future<void> _delete(ChapterModel chapter) async {
    setState(() {
      _isDeleting = true;
      _error = null;
    });

    final bookId = _bookId(chapter);
    try {
      await ref.read(chapterRepositoryProvider).deleteChapter(chapter.id);
      _invalidateAfterMutation(chapter);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chapitre supprimé.')));
        context.go(
          bookId.isEmpty
              ? AppRoutes.write
              : AppRoutes.chapterEditorPath(bookId),
        );
      }
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _invalidateAfterMutation(ChapterModel chapter) {
    ref.invalidate(chapterProvider(chapter.id));
    final bookId = _bookId(chapter);
    if (bookId.isNotEmpty) {
      ref.invalidate(bookChaptersProvider(bookId));
      ref.invalidate(authorBookProvider(bookId));
    }
    ref.invalidate(myBooksProvider);
  }
}

class _ChapterDetailForm extends StatelessWidget {
  const _ChapterDetailForm({
    required this.chapter,
    required this.titleController,
    required this.contentController,
    required this.onBack,
    required this.onOpenEditor,
    required this.onSave,
    required this.onDelete,
    required this.isSaving,
    required this.isDeleting,
    this.error,
  });

  final ChapterModel chapter;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final VoidCallback onBack;
  final VoidCallback onOpenEditor;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final bool isSaving;
  final bool isDeleting;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final busy = isSaving || isDeleting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: busy ? null : onBack,
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
          chapter.title.isEmpty ? 'Chapitre sans titre' : chapter.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: PlumoraColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chapitre ${chapter.order == 0 ? '-' : chapter.order} · ${chapter.content.length} caractères',
          style: const TextStyle(color: PlumoraColors.textSecondary),
        ),
        const SizedBox(height: 24),
        PlumoraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                _InlineError(message: error!),
                const SizedBox(height: 16),
              ],
              const _FieldLabel('Titre du chapitre'),
              TextField(
                controller: titleController,
                enabled: !busy,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Ex: Chapitre 1 - La rencontre',
                ),
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Contenu'),
              TextField(
                controller: contentController,
                enabled: !busy,
                minLines: 14,
                maxLines: 24,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Écris ton chapitre ici...',
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: busy ? null : onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Supprimer'),
                    style: TextButton.styleFrom(
                      foregroundColor: PlumoraColors.destructive,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onOpenEditor,
                    icon: const Icon(Icons.edit_note_outlined, size: 18),
                    label: const Text('Ouvrir l’éditeur'),
                  ),
                  FilledButton(
                    onPressed: busy ? null : onSave,
                    child: Text(isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
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

class _DeleteChapterDialog extends StatelessWidget {
  const _DeleteChapterDialog({required this.chapterTitle});

  final String chapterTitle;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: PlumoraColors.cards,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE6E4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: PlumoraColors.destructive,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Supprimer ce chapitre ?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          chapterTitle.trim().isEmpty
                              ? 'Cette action est définitive.'
                              : '"$chapterTitle" sera définitivement supprimé.',
                          style: const TextStyle(
                            color: PlumoraColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Supprimer'),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          color: PlumoraColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
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
