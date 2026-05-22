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

class ChapterEditorScreen extends ConsumerStatefulWidget {
  const ChapterEditorScreen({this.bookId, super.key});

  final String? bookId;

  @override
  ConsumerState<ChapterEditorScreen> createState() =>
      _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends ConsumerState<ChapterEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedChapterId;
  String? _loadedChapterId;
  bool _isSaving = false;
  bool _isCreating = false;
  bool _isPublishing = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookId = widget.bookId;
    if (bookId == null || bookId.isEmpty) {
      return const _EditorBookPicker();
    }

    final bookAsync = ref.watch(authorBookProvider(bookId));
    final chaptersAsync = ref.watch(bookChaptersProvider(bookId));

    return bookAsync.when(
      loading: () => const _FullPageLoader(),
      error: (error, _) => _FullPageError(
        title: 'Livre introuvable',
        message: AppError.messageFor(error),
        onRetry: () => ref.invalidate(authorBookProvider(bookId)),
      ),
      data: (book) => chaptersAsync.when(
        loading: () => const _FullPageLoader(),
        error: (error, _) => _FullPageError(
          title: 'Chapitres indisponibles',
          message: AppError.messageFor(error),
          onRetry: () => ref.invalidate(bookChaptersProvider(bookId)),
        ),
        data: (chapters) => _buildEditor(context, book, chapters),
      ),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    BookModel book,
    List<ChapterModel> chapters,
  ) {
    final selectedChapter = _selectedChapter(chapters);
    if (selectedChapter != null) {
      _syncControllers(selectedChapter);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        if (isDesktop) {
          return _DesktopEditor(
            book: book,
            chapters: chapters,
            selectedChapter: selectedChapter,
            titleController: _titleController,
            contentController: _contentController,
            error: _error,
            isSaving: _isSaving,
            isCreating: _isCreating,
            isPublishing: _isPublishing,
            onSelectChapter: _selectChapter,
            onCreateChapter: () => _createChapter(book.id, chapters.length),
            onSave: selectedChapter == null
                ? null
                : () => _saveChapter(selectedChapter),
            onPublish: book.canPublish ? () => _publishBook(book.id) : null,
          );
        }

        return _MobileEditor(
          book: book,
          chapters: chapters,
          selectedChapter: selectedChapter,
          titleController: _titleController,
          contentController: _contentController,
          error: _error,
          isSaving: _isSaving,
          isCreating: _isCreating,
          isPublishing: _isPublishing,
          onSelectChapter: _selectChapter,
          onCreateChapter: () => _createChapter(book.id, chapters.length),
          onSave: selectedChapter == null
              ? null
              : () => _saveChapter(selectedChapter),
          onPublish: book.canPublish ? () => _publishBook(book.id) : null,
        );
      },
    );
  }

  ChapterModel? _selectedChapter(List<ChapterModel> chapters) {
    if (chapters.isEmpty) {
      _loadedChapterId = null;
      return null;
    }

    if (_selectedChapterId == null) {
      return chapters.first;
    }

    return chapters.firstWhere(
      (chapter) => chapter.id == _selectedChapterId,
      orElse: () => chapters.first,
    );
  }

  void _syncControllers(ChapterModel chapter) {
    if (_loadedChapterId == chapter.id) {
      return;
    }

    _loadedChapterId = chapter.id;
    _selectedChapterId = chapter.id;
    _titleController.text = chapter.title;
    _contentController.text = chapter.content;
  }

  void _selectChapter(ChapterModel chapter) {
    setState(() {
      _selectedChapterId = chapter.id;
      _loadedChapterId = null;
      _error = null;
    });
  }

  Future<void> _createChapter(String bookId, int currentCount) async {
    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final chapter = await ref
          .read(chapterRepositoryProvider)
          .createChapter(
            bookId,
            ChapterUpsertRequest(
              title: 'Nouveau chapitre',
              content: '',
              order: currentCount + 1,
            ),
          );
      ref.invalidate(bookChaptersProvider(bookId));
      ref.invalidate(authorBookProvider(bookId));
      setState(() {
        _selectedChapterId = chapter.id;
        _loadedChapterId = null;
      });
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _saveChapter(ChapterModel chapter) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref
          .read(chapterRepositoryProvider)
          .updateChapter(
            chapter.id,
            ChapterUpsertRequest(
              title: _titleController.text,
              content: _contentController.text,
              order: chapter.order == 0 ? null : chapter.order,
            ),
          );
      ref.invalidate(bookChaptersProvider(chapter.bookId));
      ref.invalidate(authorBookProvider(chapter.bookId));
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _publishBook(String bookId) async {
    setState(() {
      _isPublishing = true;
      _error = null;
    });

    try {
      await ref.read(bookRepositoryProvider).publishBook(bookId);
      ref.invalidate(authorBookProvider(bookId));
      ref.invalidate(myBooksProvider);
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }
}

class _DesktopEditor extends StatelessWidget {
  const _DesktopEditor({
    required this.book,
    required this.chapters,
    required this.selectedChapter,
    required this.titleController,
    required this.contentController,
    required this.onSelectChapter,
    required this.onCreateChapter,
    required this.onSave,
    required this.onPublish,
    required this.isSaving,
    required this.isCreating,
    required this.isPublishing,
    this.error,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final ChapterModel? selectedChapter;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final ValueChanged<ChapterModel> onSelectChapter;
  final VoidCallback onCreateChapter;
  final VoidCallback? onSave;
  final VoidCallback? onPublish;
  final bool isSaving;
  final bool isCreating;
  final bool isPublishing;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 292,
            child: _ChapterSidebar(
              book: book,
              chapters: chapters,
              selectedChapter: selectedChapter,
              onSelectChapter: onSelectChapter,
              onCreateChapter: onCreateChapter,
              isCreating: isCreating,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: _EditorCard(
              book: book,
              selectedChapter: selectedChapter,
              titleController: titleController,
              contentController: contentController,
              error: error,
              onSave: onSave,
              onPublish: onPublish,
              isSaving: isSaving,
              isPublishing: isPublishing,
              expanded: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileEditor extends StatelessWidget {
  const _MobileEditor({
    required this.book,
    required this.chapters,
    required this.selectedChapter,
    required this.titleController,
    required this.contentController,
    required this.onSelectChapter,
    required this.onCreateChapter,
    required this.onSave,
    required this.onPublish,
    required this.isSaving,
    required this.isCreating,
    required this.isPublishing,
    this.error,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final ChapterModel? selectedChapter;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final ValueChanged<ChapterModel> onSelectChapter;
  final VoidCallback onCreateChapter;
  final VoidCallback? onSave;
  final VoidCallback? onPublish;
  final bool isSaving;
  final bool isCreating;
  final bool isPublishing;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 84),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookEditorHeader(book: book),
          const SizedBox(height: 16),
          _MobileChapterSelector(
            chapters: chapters,
            selectedChapter: selectedChapter,
            onSelectChapter: onSelectChapter,
            onCreateChapter: onCreateChapter,
            isCreating: isCreating,
          ),
          const SizedBox(height: 16),
          _EditorCard(
            book: book,
            selectedChapter: selectedChapter,
            titleController: titleController,
            contentController: contentController,
            error: error,
            onSave: onSave,
            onPublish: onPublish,
            isSaving: isSaving,
            isPublishing: isPublishing,
            expanded: false,
          ),
        ],
      ),
    );
  }
}

class _ChapterSidebar extends StatelessWidget {
  const _ChapterSidebar({
    required this.book,
    required this.chapters,
    required this.selectedChapter,
    required this.onSelectChapter,
    required this.onCreateChapter,
    required this.isCreating,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final ChapterModel? selectedChapter;
  final ValueChanged<ChapterModel> onSelectChapter;
  final VoidCallback onCreateChapter;
  final bool isCreating;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookEditorHeader(book: book),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isCreating ? null : onCreateChapter,
              icon: const Icon(Icons.add, size: 18),
              label: Text(isCreating ? 'Création...' : 'Nouveau chapitre'),
            ),
          ),
          const SizedBox(height: 18),
          if (chapters.isEmpty)
            const Text(
              'Aucun chapitre. Crée le premier pour commencer.',
              style: TextStyle(color: PlumoraColors.textSecondary),
            )
          else
            for (final chapter in chapters) ...[
              _ChapterListItem(
                chapter: chapter,
                selected: chapter.id == selectedChapter?.id,
                onTap: () => onSelectChapter(chapter),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _BookEditorHeader extends StatelessWidget {
  const _BookEditorHeader({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title.isEmpty ? 'Livre sans titre' : book.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        BookStatusBadge(status: book.status),
      ],
    );
  }
}

class _ChapterListItem extends StatelessWidget {
  const _ChapterListItem({
    required this.chapter,
    required this.selected,
    required this.onTap,
  });

  final ChapterModel chapter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? PlumoraColors.secondary : PlumoraColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? PlumoraColors.primary : PlumoraColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(
              chapter.order == 0 ? '–' : chapter.order.toString(),
              style: const TextStyle(
                color: PlumoraColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                chapter.title.isEmpty ? 'Chapitre sans titre' : chapter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileChapterSelector extends StatelessWidget {
  const _MobileChapterSelector({
    required this.chapters,
    required this.selectedChapter,
    required this.onSelectChapter,
    required this.onCreateChapter,
    required this.isCreating,
  });

  final List<ChapterModel> chapters;
  final ChapterModel? selectedChapter;
  final ValueChanged<ChapterModel> onSelectChapter;
  final VoidCallback onCreateChapter;
  final bool isCreating;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (chapters.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: selectedChapter?.id,
              decoration: const InputDecoration(labelText: 'Chapitre'),
              items: [
                for (final chapter in chapters)
                  DropdownMenuItem(
                    value: chapter.id,
                    child: Text(
                      chapter.title.isEmpty
                          ? 'Chapitre sans titre'
                          : chapter.title,
                    ),
                  ),
              ],
              onChanged: (value) {
                final selected = chapters.firstWhere(
                  (chapter) => chapter.id == value,
                  orElse: () => chapters.first,
                );
                onSelectChapter(selected);
              },
            )
          else
            const Text(
              'Aucun chapitre pour ce livre.',
              style: TextStyle(color: PlumoraColors.textSecondary),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isCreating ? null : onCreateChapter,
            icon: const Icon(Icons.add, size: 18),
            label: Text(isCreating ? 'Création...' : 'Nouveau chapitre'),
          ),
        ],
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({
    required this.book,
    required this.selectedChapter,
    required this.titleController,
    required this.contentController,
    required this.onSave,
    required this.onPublish,
    required this.isSaving,
    required this.isPublishing,
    required this.expanded,
    this.error,
  });

  final BookModel book;
  final ChapterModel? selectedChapter;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final VoidCallback? onSave;
  final VoidCallback? onPublish;
  final bool isSaving;
  final bool isPublishing;
  final bool expanded;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        height: expanded ? MediaQuery.sizeOf(context).height - 112 : null,
        child: selectedChapter == null
            ? const _NoChapterState()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Éditeur',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (expanded) BookStatusBadge(status: book.status),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: PlumoraColors.destructive,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Titre'),
                  ),
                  const SizedBox(height: 14),
                  if (expanded)
                    Expanded(
                      child: TextField(
                        controller: contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          labelText: 'Contenu',
                          alignLabelWithHint: true,
                          hintText: 'Écris ton chapitre ici...',
                        ),
                      ),
                    )
                  else
                    TextField(
                      controller: contentController,
                      minLines: 12,
                      maxLines: 18,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        labelText: 'Contenu',
                        alignLabelWithHint: true,
                        hintText: 'Écris ton chapitre ici...',
                      ),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: isPublishing ? null : onPublish,
                        child: Text(
                          isPublishing ? 'Publication...' : 'Publier le livre',
                        ),
                      ),
                      FilledButton(
                        onPressed: isSaving ? null : onSave,
                        child: Text(isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _NoChapterState extends StatelessWidget {
  const _NoChapterState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Crée un chapitre dans la liste pour commencer à écrire.',
          textAlign: TextAlign.center,
          style: TextStyle(color: PlumoraColors.textSecondary),
        ),
      ),
    );
  }
}

class _EditorBookPicker extends ConsumerWidget {
  const _EditorBookPicker();

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
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Éditeur',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choisis un livre pour ouvrir son éditeur de chapitres.',
                    style: TextStyle(color: PlumoraColors.textSecondary),
                  ),
                  const SizedBox(height: 22),
                  booksAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => _FullPageError(
                      title: 'Impossible de charger les livres',
                      message: AppError.messageFor(error),
                      onRetry: () => ref.invalidate(myBooksProvider),
                    ),
                    data: (books) {
                      if (books.isEmpty) {
                        return PlumoraCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Aucun livre disponible',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Crée un livre avant d’ouvrir l’éditeur.',
                                style: TextStyle(
                                  color: PlumoraColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () =>
                                    context.go(AppRoutes.createBook),
                                child: const Text('Créer un livre'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          for (final book in books) ...[
                            PlumoraCard(
                              onTap: () => context.go(
                                AppRoutes.chapterEditorPath(book.id),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  PlumoraIconTile(
                                    size: 46,
                                    radius: 11,
                                    backgroundColor:
                                        book.status.backgroundColor,
                                    child: Icon(
                                      Icons.menu_book_outlined,
                                      color: book.status.foregroundColor,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book.title.isEmpty
                                              ? 'Livre sans titre'
                                              : book.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          book.status.frenchLabel,
                                          style: const TextStyle(
                                            color: PlumoraColors.textSecondary,
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
        );
      },
    );
  }
}

class _FullPageLoader extends StatelessWidget {
  const _FullPageLoader();

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

class _FullPageError extends StatelessWidget {
  const _FullPageError({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
              constraints: const BoxConstraints(maxWidth: 720),
              child: PlumoraCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        color: PlumoraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Réessayer'),
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
}
