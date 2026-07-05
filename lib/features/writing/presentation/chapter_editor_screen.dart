import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/models/chapter_model.dart';
import '../../book/data/repositories/book_repository.dart';
import '../../book/data/repositories/chapter_repository.dart';

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
  String? _hydratedChapterId;
  bool _isNewChapter = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookId = widget.bookId?.trim();
    if (bookId == null || bookId.isEmpty) {
      return _BookSelectionView(
        booksAsync: ref.watch(myBooksProvider),
        onRetry: () => ref.invalidate(myBooksProvider),
      );
    }

    final bookAsync = ref.watch(authorBookProvider(bookId));
    final chaptersAsync = ref.watch(bookChaptersProvider(bookId));

    return Scaffold(
      backgroundColor: PlumoraColors.background,
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _CenteredError(
          message: AppError.messageFor(error),
          onRetry: () => ref.invalidate(authorBookProvider(bookId)),
        ),
        data: (book) => chaptersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CenteredError(
            message: AppError.messageFor(error),
            onRetry: () => ref.invalidate(bookChaptersProvider(bookId)),
          ),
          data: (chapters) {
            final sorted = [...chapters]
              ..sort((a, b) {
                final orderCompare = a.order.compareTo(b.order);
                return orderCompare == 0
                    ? a.title.compareTo(b.title)
                    : orderCompare;
              });
            _syncSelection(sorted);

            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 820;
                if (compact) {
                  return _MobileEditor(
                    book: book,
                    chapters: sorted,
                    selectedChapterId: _selectedChapterId,
                    titleController: _titleController,
                    contentController: _contentController,
                    isSaving: _isSaving,
                    error: _error,
                    isNewChapter: _isNewChapter,
                    onSelect: _selectChapter,
                    onNew: () => _startNew(sorted),
                    onSave: () => _save(book.id, sorted),
                  );
                }

                return _DesktopEditor(
                  book: book,
                  chapters: sorted,
                  selectedChapterId: _selectedChapterId,
                  titleController: _titleController,
                  contentController: _contentController,
                  isSaving: _isSaving,
                  error: _error,
                  isNewChapter: _isNewChapter,
                  onSelect: _selectChapter,
                  onNew: () => _startNew(sorted),
                  onSave: () => _save(book.id, sorted),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _syncSelection(List<ChapterModel> chapters) {
    if (_isNewChapter) {
      return;
    }

    final existing = _selectedChapterId == null
        ? null
        : chapters.cast<ChapterModel?>().firstWhere(
            (chapter) => chapter?.id == _selectedChapterId,
            orElse: () => null,
          );
    final selected = existing ?? (chapters.isEmpty ? null : chapters.first);
    if (selected == null) {
      if (_hydratedChapterId != '__new__') {
        _selectedChapterId = null;
        _hydratedChapterId = '__new__';
        _isNewChapter = true;
        _titleController.text = 'Chapitre 1';
        _contentController.clear();
      }
      return;
    }

    if (_hydratedChapterId == selected.id) {
      return;
    }

    _selectedChapterId = selected.id;
    _hydratedChapterId = selected.id;
    _titleController.text = selected.title;
    _contentController.text = selected.content;
  }

  void _selectChapter(ChapterModel chapter) {
    setState(() {
      _selectedChapterId = chapter.id;
      _hydratedChapterId = chapter.id;
      _isNewChapter = false;
      _error = null;
      _titleController.text = chapter.title;
      _contentController.text = chapter.content;
    });
  }

  void _startNew(List<ChapterModel> chapters) {
    final nextOrder = chapters.isEmpty
        ? 1
        : chapters
                  .map((chapter) => chapter.order)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    setState(() {
      _selectedChapterId = null;
      _hydratedChapterId = '__new__';
      _isNewChapter = true;
      _error = null;
      _titleController.text = 'Chapitre $nextOrder';
      _contentController.clear();
    });
  }

  Future<void> _save(String bookId, List<ChapterModel> chapters) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Ajoute un titre de chapitre.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final repository = ref.read(chapterRepositoryProvider);
      final order = _isNewChapter
          ? (chapters.isEmpty
                ? 1
                : chapters
                          .map((chapter) => chapter.order)
                          .reduce((a, b) => a > b ? a : b) +
                      1)
          : chapters
                .cast<ChapterModel?>()
                .firstWhere(
                  (chapter) => chapter?.id == _selectedChapterId,
                  orElse: () => null,
                )
                ?.order;
      final request = ChapterUpsertRequest(
        title: title,
        content: _contentController.text,
        order: order,
      );
      final saved = _isNewChapter || _selectedChapterId == null
          ? await repository.createChapter(bookId, request)
          : await repository.updateChapter(_selectedChapterId!, request);

      ref.invalidate(bookChaptersProvider(bookId));
      ref.invalidate(authorBookProvider(bookId));
      ref.invalidate(chapterProvider(saved.id));
      ref.invalidate(myBooksProvider);
      setState(() {
        _selectedChapterId = saved.id;
        _hydratedChapterId = saved.id;
        _isNewChapter = false;
        _titleController.text = saved.title;
        _contentController.text = saved.content;
      });
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _BookSelectionView extends StatelessWidget {
  const _BookSelectionView({required this.booksAsync, required this.onRetry});

  final AsyncValue<List<BookModel>> booksAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FigmaScreen(
      maxWidth: 900,
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigmaBackButton(
            label: 'Retour',
            onTap: () => context.go(AppRoutes.write),
          ),
          const SizedBox(height: 18),
          const Text(
            'Choisir un manuscrit',
            style: TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          booksAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _ErrorCard(
              message: AppError.messageFor(error),
              onRetry: onRetry,
            ),
            data: (books) {
              if (books.isEmpty) {
                return FigmaCard(
                  child: Column(
                    children: [
                      const FigmaEmptyState(
                        title: 'Aucun manuscrit',
                        message: "Cree un livre avant d'ouvrir l'editeur.",
                        icon: Icons.edit_outlined,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.go(AppRoutes.createBook),
                          icon: const Icon(Icons.add),
                          label: const Text('Creer un livre'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (final book in books) ...[
                    FigmaCard(
                      onTap: () =>
                          context.go(AppRoutes.chapterEditorPath(book.id)),
                      child: Row(
                        children: [
                          const FigmaGradientIcon(icon: Icons.edit_outlined),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title.isEmpty
                                      ? 'Livre sans titre'
                                      : book.title,
                                  style: const TextStyle(
                                    color: PlumoraColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${book.chapterCount} chapitres - ${book.wordCount} mots',
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
    );
  }
}

class _DesktopEditor extends StatelessWidget {
  const _DesktopEditor({
    required this.book,
    required this.chapters,
    required this.selectedChapterId,
    required this.titleController,
    required this.contentController,
    required this.isSaving,
    required this.isNewChapter,
    required this.onSelect,
    required this.onNew,
    required this.onSave,
    this.error,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final String? selectedChapterId;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final bool isSaving;
  final bool isNewChapter;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;
  final VoidCallback onSave;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Sidebar(
          book: book,
          chapters: chapters,
          selectedChapterId: selectedChapterId,
          isNewChapter: isNewChapter,
          onSelect: onSelect,
          onNew: onNew,
        ),
        Expanded(
          child: _EditorPane(
            book: book,
            titleController: titleController,
            contentController: contentController,
            selectedChapterId: selectedChapterId,
            isSaving: isSaving,
            isNewChapter: isNewChapter,
            error: error,
            onSave: onSave,
          ),
        ),
      ],
    );
  }
}

class _MobileEditor extends StatelessWidget {
  const _MobileEditor({
    required this.book,
    required this.chapters,
    required this.selectedChapterId,
    required this.titleController,
    required this.contentController,
    required this.isSaving,
    required this.isNewChapter,
    required this.onSelect,
    required this.onNew,
    required this.onSave,
    this.error,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final String? selectedChapterId;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final bool isSaving;
  final bool isNewChapter;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;
  final VoidCallback onSave;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            color: PlumoraColors.cards,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go(AppRoutes.write),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Retour'),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Chapitres',
                      onSelected: (value) {
                        if (value == '__new__') {
                          onNew();
                          return;
                        }
                        final chapter = chapters.firstWhere(
                          (chapter) => chapter.id == value,
                        );
                        onSelect(chapter);
                      },
                      itemBuilder: (context) => [
                        for (final chapter in chapters)
                          PopupMenuItem(
                            value: chapter.id,
                            child: Text(
                              chapter.title.isEmpty
                                  ? 'Chapitre sans titre'
                                  : chapter.title,
                            ),
                          ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: '__new__',
                          child: Text('Nouveau chapitre'),
                        ),
                      ],
                      child: const Icon(Icons.list_alt_outlined),
                    ),
                    IconButton(
                      onPressed: isSaving ? null : onSave,
                      icon: const Icon(Icons.save_outlined),
                      color: PlumoraColors.primary,
                    ),
                  ],
                ),
                Text(
                  book.title.isEmpty ? 'Livre sans titre' : book.title,
                  style: const TextStyle(
                    color: PlumoraColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    hintText: 'Titre du chapitre',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: const TextStyle(
                      color: PlumoraColors.destructive,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: TextField(
              controller: contentController,
              expands: true,
              maxLines: null,
              minLines: null,
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Commencez a ecrire...',
              ),
              style: const TextStyle(
                color: PlumoraColors.textPrimary,
                fontSize: 16,
                height: 1.8,
              ),
            ),
          ),
        ),
        _StatsBar(controller: contentController),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.book,
    required this.chapters,
    required this.selectedChapterId,
    required this.isNewChapter,
    required this.onSelect,
    required this.onNew,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final String? selectedChapterId;
  final bool isNewChapter;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: PlumoraColors.cards,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title.isEmpty ? 'Livre sans titre' : book.title,
                  style: const TextStyle(
                    color: PlumoraColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.genre ?? 'Manuscrit',
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: PlumoraColors.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                _EditorNavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Tableau de bord',
                  onTap: () => context.go(AppRoutes.write),
                ),
                _EditorNavItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Fiche du livre',
                  onTap: () =>
                      context.go(AppRoutes.authorBookDetailPath(book.id)),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Chapitres',
                  style: TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (isNewChapter)
                  const _ChapterNavTile(
                    label: 'Nouveau chapitre',
                    selected: true,
                  ),
                for (final chapter in chapters)
                  _ChapterNavTile(
                    label: chapter.title.isEmpty
                        ? 'Chapitre sans titre'
                        : chapter.title,
                    selected: chapter.id == selectedChapterId && !isNewChapter,
                    onTap: () => onSelect(chapter),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onNew,
                icon: const Icon(Icons.add),
                label: const Text('Nouveau chapitre'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorPane extends StatelessWidget {
  const _EditorPane({
    required this.book,
    required this.titleController,
    required this.contentController,
    required this.selectedChapterId,
    required this.isSaving,
    required this.isNewChapter,
    required this.onSave,
    this.error,
  });

  final BookModel book;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final String? selectedChapterId;
  final bool isSaving;
  final bool isNewChapter;
  final VoidCallback onSave;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: PlumoraColors.cards,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    hintText: 'Titre du chapitre',
                  ),
                  style: const TextStyle(
                    color: PlumoraColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: selectedChapterId == null || isNewChapter
                    ? null
                    : () => context.go(
                        AppRoutes.mukemeWritingPath(
                          chapterId: selectedChapterId,
                        ),
                      ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Mukeme'),
              ),
              FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'Sauvegarde...' : 'Enregistrer'),
              ),
            ],
          ),
        ),
        if (error != null)
          Container(
            width: double.infinity,
            color: PlumoraColors.destructive.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            child: Text(
              error!,
              style: const TextStyle(
                color: PlumoraColors.destructive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const Divider(height: 1, color: PlumoraColors.border),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: TextField(
                  controller: contentController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Commencez a ecrire votre histoire...',
                  ),
                  style: const TextStyle(
                    color: PlumoraColors.textPrimary,
                    fontSize: 18,
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ),
        ),
        _StatsBar(controller: contentController),
      ],
    );
  }
}

class _ChapterNavTile extends StatelessWidget {
  const _ChapterNavTile({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? PlumoraColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: selected ? Colors.white : PlumoraColors.textPrimary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : PlumoraColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final words = controller.text
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .length;

    return Container(
      color: PlumoraColors.cards,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Text('$words mots'),
          const SizedBox(width: 24),
          Text('${controller.text.length} caracteres'),
          const Spacer(),
          const Text('Sauvegarde manuelle'),
        ],
      ),
    );
  }
}

class _EditorNavItem extends StatelessWidget {
  const _EditorNavItem({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: PlumoraColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredError extends StatelessWidget {
  const _CenteredError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: _ErrorCard(message: message, onRetry: onRetry),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editeur indisponible',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: PlumoraColors.textSecondary),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Reessayer')),
        ],
      ),
    );
  }
}
