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

const _writeAccent = Color(0xFF7C5CFF);
const _writeAccentLight = Color(0xFF9B80FF);
const _writeGold = Color(0xFFD6B25E);
const _writeGreen = Color(0xFF3FBF7F);

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
  bool _readMode = false;
  bool _showMukeme = false;
  bool _hasUnsavedChanges = false;
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
                    readMode: _readMode,
                    showMukeme: _showMukeme,
                    hasUnsavedChanges: _hasUnsavedChanges,
                    onSelect: _selectChapter,
                    onNew: () => _startNew(sorted),
                    onSave: () => _save(book.id, sorted),
                    onChanged: _markDirty,
                    onReadModeChanged: (value) =>
                        setState(() => _readMode = value),
                    onMukemeChanged: (value) =>
                        setState(() => _showMukeme = value),
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
                  readMode: _readMode,
                  showMukeme: _showMukeme,
                  hasUnsavedChanges: _hasUnsavedChanges,
                  onSelect: _selectChapter,
                  onNew: () => _startNew(sorted),
                  onSave: () => _save(book.id, sorted),
                  onChanged: _markDirty,
                  onReadModeChanged: (value) =>
                      setState(() => _readMode = value),
                  onMukemeChanged: (value) =>
                      setState(() => _showMukeme = value),
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
        _hasUnsavedChanges = true;
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
    _hasUnsavedChanges = false;
    _titleController.text = selected.title;
    _contentController.text = selected.content;
  }

  void _selectChapter(ChapterModel chapter) {
    setState(() {
      _selectedChapterId = chapter.id;
      _hydratedChapterId = chapter.id;
      _isNewChapter = false;
      _readMode = false;
      _showMukeme = false;
      _hasUnsavedChanges = false;
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
      _readMode = false;
      _showMukeme = false;
      _hasUnsavedChanges = true;
      _error = null;
      _titleController.text = 'Chapitre $nextOrder';
      _contentController.clear();
    });
  }

  void _markDirty() {
    if (_hasUnsavedChanges) {
      return;
    }

    setState(() => _hasUnsavedChanges = true);
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
        _hasUnsavedChanges = false;
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
    required this.onChanged,
    required this.readMode,
    required this.showMukeme,
    required this.hasUnsavedChanges,
    required this.onReadModeChanged,
    required this.onMukemeChanged,
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
  final VoidCallback onChanged;
  final bool readMode;
  final bool showMukeme;
  final bool hasUnsavedChanges;
  final ValueChanged<bool> onReadModeChanged;
  final ValueChanged<bool> onMukemeChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FigmaBookNavigationRail(book: book, chaptersCount: chapters.length),
        _FigmaChapterNavigationRail(
          book: book,
          chapters: chapters,
          selectedChapterId: selectedChapterId,
          isNewChapter: isNewChapter,
          onSelect: onSelect,
          onNew: onNew,
        ),
        Expanded(
          child: _FigmaEditorPane(
            book: book,
            chapters: chapters,
            titleController: titleController,
            contentController: contentController,
            selectedChapterId: selectedChapterId,
            isSaving: isSaving,
            isNewChapter: isNewChapter,
            readMode: readMode,
            showMukeme: showMukeme,
            hasUnsavedChanges: hasUnsavedChanges,
            error: error,
            onSelect: onSelect,
            onNew: onNew,
            onSave: onSave,
            onChanged: onChanged,
            onReadModeChanged: onReadModeChanged,
            onMukemeChanged: onMukemeChanged,
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
    required this.onChanged,
    required this.readMode,
    required this.showMukeme,
    required this.hasUnsavedChanges,
    required this.onReadModeChanged,
    required this.onMukemeChanged,
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
  final VoidCallback onChanged;
  final bool readMode;
  final bool showMukeme;
  final bool hasUnsavedChanges;
  final ValueChanged<bool> onReadModeChanged;
  final ValueChanged<bool> onMukemeChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return _FigmaChapterPageMobileEditorBody(
      book: book,
      chapters: chapters,
      selectedChapterId: selectedChapterId,
      titleController: titleController,
      contentController: contentController,
      isSaving: isSaving,
      isNewChapter: isNewChapter,
      readMode: readMode,
      showMukeme: showMukeme,
      hasUnsavedChanges: hasUnsavedChanges,
      error: error,
      onSelect: onSelect,
      onNew: onNew,
      onSave: onSave,
      onChanged: onChanged,
      onReadModeChanged: onReadModeChanged,
      onMukemeChanged: onMukemeChanged,
    );
  }
}

class _FigmaBookNavigationRail extends StatelessWidget {
  const _FigmaBookNavigationRail({
    required this.book,
    required this.chaptersCount,
  });

  final BookModel book;
  final int chaptersCount;

  @override
  Widget build(BuildContext context) {
    final title = _figmaBookTitle(book);

    return Container(
      width: 224,
      decoration: const BoxDecoration(
        color: PlumoraColors.cards,
        border: Border(right: BorderSide(color: PlumoraColors.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: PlumoraColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => context.go(AppRoutes.write),
                  icon: const Icon(Icons.arrow_back, size: 15),
                  label: const Text('Mes histoires'),
                  style: TextButton.styleFrom(
                    foregroundColor: PlumoraColors.textSecondary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _FigmaBookMiniCover(book: book, title: title),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PlumoraColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_figmaBookGenre(book)} - $chaptersCount chap.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _FigmaBookNavButton(
                  icon: Icons.menu_book_outlined,
                  label: "Vue d'ensemble",
                  onTap: () =>
                      context.go(AppRoutes.authorBookDetailPath(book.id)),
                ),
                _FigmaBookNavButton(
                  icon: Icons.edit_outlined,
                  label: 'Éditeur',
                  selected: true,
                  onTap: () => context.go(AppRoutes.chapterEditorPath(book.id)),
                ),
                _FigmaBookNavButton(
                  icon: Icons.forum_outlined,
                  label: 'Retours bêta',
                  onTap: () =>
                      context.go(AppRoutes.authorBetaCommentsPath(book.id)),
                ),
                _FigmaBookNavButton(
                  icon: Icons.upload_outlined,
                  label: 'Bêta-test',
                  onTap: () =>
                      context.go(AppRoutes.authorBetaCampaignsPath(book.id)),
                ),
                _FigmaBookNavButton(
                  icon: Icons.trending_up,
                  label: 'Royalties',
                  onTap: () => context.go(AppRoutes.royalties),
                ),
                _FigmaBookNavButton(
                  icon: Icons.settings_outlined,
                  label: 'Paramètres',
                  onTap: () => context.go(AppRoutes.editBookPath(book.id)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: PlumoraColors.border)),
            ),
            child: _FigmaBookNavButton(
              icon: Icons.smartphone_outlined,
              label: 'Vue mobile',
              compact: true,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "La vue mobile s'active sur les petits écrans.",
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaChapterNavigationRail extends StatelessWidget {
  const _FigmaChapterNavigationRail({
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
    final totalWords = chapters.fold<int>(
      0,
      (sum, chapter) => sum + _figmaWordCount(chapter.content),
    );

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: PlumoraColors.background,
        border: Border(right: BorderSide(color: PlumoraColors.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: PlumoraColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chapitres',
                        style: TextStyle(
                          color: PlumoraColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${chapters.length} chapitres - ${_figmaCompactNumber(totalWords)} mots',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PlumoraColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _FigmaSquareIconButton(
                  icon: Icons.add,
                  tooltip: 'Nouveau chapitre',
                  color: _writeAccent,
                  onTap: onNew,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                for (var i = 0; i < chapters.length; i++)
                  _FigmaChapterNavTile(
                    index: chapters[i].order == 0 ? i + 1 : chapters[i].order,
                    label: _figmaChapterTitle(
                      chapters[i],
                      fallbackOrder: i + 1,
                    ),
                    detail: _figmaChapterDetail(book, chapters[i]),
                    selected:
                        chapters[i].id == selectedChapterId && !isNewChapter,
                    onTap: () => onSelect(chapters[i]),
                  ),
                if (isNewChapter)
                  _FigmaChapterNavTile(
                    index: chapters.length + 1,
                    label: 'Nouveau chapitre',
                    detail: 'Vide - Brouillon',
                    selected: true,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: PlumoraColors.border)),
            ),
            child: _FigmaDashedButton(
              icon: Icons.add,
              label: 'Nouveau chapitre',
              onTap: onNew,
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaEditorPane extends StatelessWidget {
  const _FigmaEditorPane({
    required this.book,
    required this.chapters,
    required this.titleController,
    required this.contentController,
    required this.selectedChapterId,
    required this.isSaving,
    required this.isNewChapter,
    required this.readMode,
    required this.showMukeme,
    required this.hasUnsavedChanges,
    required this.onSelect,
    required this.onNew,
    required this.onSave,
    required this.onChanged,
    required this.onReadModeChanged,
    required this.onMukemeChanged,
    this.error,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final String? selectedChapterId;
  final bool isSaving;
  final bool isNewChapter;
  final bool readMode;
  final bool showMukeme;
  final bool hasUnsavedChanges;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;
  final VoidCallback onSave;
  final VoidCallback onChanged;
  final ValueChanged<bool> onReadModeChanged;
  final ValueChanged<bool> onMukemeChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final activeIndex = _figmaActiveIndex(
      chapters,
      selectedChapterId,
      isNewChapter,
    );
    final activeChapter = _figmaActiveChapter(
      chapters,
      selectedChapterId,
      isNewChapter,
    );
    final title = _figmaControllerTitle(
      titleController,
      fallbackOrder: activeIndex + 1,
    );
    final published = _figmaChapterIsPublished(book, activeChapter);
    final words = _figmaWordCount(contentController.text);
    final readTime = _figmaReadTimeMinutes(words);
    final prevChapter = activeIndex > 0 ? chapters[activeIndex - 1] : null;
    final nextChapter = activeIndex >= 0 && activeIndex < chapters.length - 1
        ? chapters[activeIndex + 1]
        : null;

    return Column(
      children: [
        _FigmaEditorToolbar(
          readMode: readMode,
          showMukeme: showMukeme,
          isSaving: isSaving,
          hasUnsavedChanges: hasUnsavedChanges || isNewChapter,
          onReadModeChanged: onReadModeChanged,
          onMukemeChanged: onMukemeChanged,
          onSave: onSave,
        ),
        if (showMukeme && !readMode)
          _FigmaMukemeDesktopPanel(onClose: () => onMukemeChanged(false)),
        if (error != null) _FigmaEditorErrorBar(error!),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FigmaEditorBreadcrumb(
                        bookTitle: _figmaBookTitle(book),
                        chapterIndex: activeIndex + 1,
                        chapterTitle: title,
                      ),
                      const SizedBox(height: 22),
                      if (readMode)
                        Text(
                          title,
                          style: const TextStyle(
                            color: PlumoraColors.textPrimary,
                            fontFamily: 'Playfair Display',
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      else
                        TextField(
                          controller: titleController,
                          onChanged: (_) => onChanged(),
                          decoration: const InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'Titre du chapitre...',
                          ),
                          style: const TextStyle(
                            color: PlumoraColors.textPrimary,
                            fontFamily: 'Playfair Display',
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      const SizedBox(height: 18),
                      _FigmaChapterStatusStrip(
                        published: published,
                        wordCount: words,
                        readTime: readTime,
                      ),
                      const SizedBox(height: 26),
                      if (readMode)
                        _FigmaReadingContent(
                          title: title,
                          content: contentController.text,
                          showTitle: false,
                        )
                      else
                        TextField(
                          controller: contentController,
                          onChanged: (_) => onChanged(),
                          keyboardType: TextInputType.multiline,
                          minLines: 18,
                          maxLines: null,
                          decoration: const InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'Commencez à écrire ce chapitre...',
                          ),
                          style: const TextStyle(
                            color: PlumoraColors.textPrimary,
                            fontSize: 17,
                            height: 1.9,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      const SizedBox(height: 34),
                      _FigmaChapterJumpRow(
                        prevChapter: prevChapter,
                        nextChapter: nextChapter,
                        onSelect: onSelect,
                        onNew: onNew,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _FigmaEditorStatsBar(
          controller: contentController,
          activeIndex: activeIndex,
          chaptersLength: chapters.length + (isNewChapter ? 1 : 0),
          saved: !hasUnsavedChanges && !isNewChapter,
        ),
      ],
    );
  }
}

class _FigmaChapterPageMobileEditorBody extends StatelessWidget {
  const _FigmaChapterPageMobileEditorBody({
    required this.book,
    required this.chapters,
    required this.selectedChapterId,
    required this.titleController,
    required this.contentController,
    required this.isSaving,
    required this.isNewChapter,
    required this.readMode,
    required this.showMukeme,
    required this.hasUnsavedChanges,
    required this.onSelect,
    required this.onNew,
    required this.onSave,
    required this.onChanged,
    required this.onReadModeChanged,
    required this.onMukemeChanged,
    this.error,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final String? selectedChapterId;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final bool isSaving;
  final bool isNewChapter;
  final bool readMode;
  final bool showMukeme;
  final bool hasUnsavedChanges;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;
  final VoidCallback onSave;
  final VoidCallback onChanged;
  final ValueChanged<bool> onReadModeChanged;
  final ValueChanged<bool> onMukemeChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final activeIndex = _figmaActiveIndex(
      chapters,
      selectedChapterId,
      isNewChapter,
    );
    final activeChapter = _figmaActiveChapter(
      chapters,
      selectedChapterId,
      isNewChapter,
    );
    final title = _figmaControllerTitle(
      titleController,
      fallbackOrder: activeIndex + 1,
    );
    final words = _figmaWordCount(contentController.text);
    final readTime = _figmaReadTimeMinutes(words);
    final prevChapter = activeIndex > 0 ? chapters[activeIndex - 1] : null;
    final nextChapter = activeIndex >= 0 && activeIndex < chapters.length - 1
        ? chapters[activeIndex + 1]
        : null;
    final saved = !hasUnsavedChanges && !isNewChapter;
    final published = _figmaChapterIsPublished(book, activeChapter);

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
            decoration: const BoxDecoration(
              color: PlumoraColors.cards,
              border: Border(bottom: BorderSide(color: PlumoraColors.border)),
            ),
            child: Row(
              children: [
                _FigmaSquareIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Mes histoires',
                  onTap: () => context.go(AppRoutes.write),
                ),
                const SizedBox(width: 4),
                const _FigmaToolbarIcon(
                  icon: Icons.format_bold,
                  tooltip: 'Gras',
                ),
                const _FigmaToolbarIcon(
                  icon: Icons.format_italic,
                  tooltip: 'Italique',
                ),
                const _FigmaToolbarIcon(
                  icon: Icons.format_underlined,
                  tooltip: 'Souligner',
                ),
                const _FigmaToolbarIcon(
                  icon: Icons.format_quote,
                  tooltip: 'Citation',
                ),
                const _FigmaToolbarIcon(
                  icon: Icons.format_list_bulleted,
                  tooltip: 'Liste',
                ),
                const _FigmaToolbarIcon(
                  icon: Icons.horizontal_rule,
                  tooltip: 'Séparateur',
                ),
                const Spacer(),
                _FigmaSavedStatusPill(isSaving: isSaving, saved: saved),
              ],
            ),
          ),
        ),
        if (error != null) _FigmaEditorErrorBar(error!),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _showChapterSheet(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _FigmaEditorBreadcrumb(
                            bookTitle: _figmaBookTitle(book),
                            chapterIndex: activeIndex + 1,
                            chapterTitle: title,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: titleController,
                        onChanged: (_) => onChanged(),
                        readOnly: readMode,
                        decoration: const InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Titre du chapitre...',
                        ),
                        style: const TextStyle(
                          color: PlumoraColors.textPrimary,
                          fontFamily: 'Playfair Display',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FigmaChapterPublishStrip(
                        published: published,
                        wordCount: words,
                        readTime: readTime,
                        onPublish: onSave,
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: PlumoraColors.border),
                      const SizedBox(height: 20),
                      TextField(
                        controller: contentController,
                        onChanged: (_) => onChanged(),
                        readOnly: readMode,
                        keyboardType: TextInputType.multiline,
                        minLines: 14,
                        maxLines: null,
                        decoration: const InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Commencez à écrire ce chapitre...',
                        ),
                        style: const TextStyle(
                          color: PlumoraColors.textPrimary,
                          fontSize: 16,
                          height: 1.85,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 34),
                      const Divider(color: PlumoraColors.border),
                      const SizedBox(height: 18),
                      _FigmaMobileChapterJumps(
                        prevChapter: prevChapter,
                        nextChapter: nextChapter,
                        onSelect: onSelect,
                        onNew: onNew,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _FigmaMobileFooterStats(
          words: words,
          chars: contentController.text.length,
          readTime: readTime,
          saved: saved,
        ),
        if (showMukeme)
          _FigmaMobileMukemePanel(onClose: () => onMukemeChanged(false))
        else
          _FigmaBottomChapterToolbar(
            onNew: onNew,
            onMukeme: () => onMukemeChanged(true),
            onReadMode: () => onReadModeChanged(!readMode),
            readMode: readMode,
          ),
      ],
    );
  }

  void _showChapterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FigmaChapterBottomSheet(
        book: book,
        chapters: chapters,
        selectedChapterId: selectedChapterId,
        isNewChapter: isNewChapter,
        onSelect: onSelect,
        onNew: onNew,
      ),
    );
  }
}

class _FigmaSavedStatusPill extends StatelessWidget {
  const _FigmaSavedStatusPill({required this.isSaving, required this.saved});

  final bool isSaving;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final label = isSaving
        ? 'Sauvegarde...'
        : saved
        ? 'Sauvegardé'
        : 'À sauvegarder';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: saved
            ? _writeGreen.withValues(alpha: 0.12)
            : _writeAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSaving)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  saved ? _writeGreen : _writeAccent,
                ),
              ),
            )
          else
            Icon(
              saved ? Icons.check : Icons.save_outlined,
              size: 13,
              color: saved ? _writeGreen : _writeAccent,
            ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: saved ? _writeGreen : _writeAccent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaChapterPublishStrip extends StatelessWidget {
  const _FigmaChapterPublishStrip({
    required this.published,
    required this.wordCount,
    required this.readTime,
    required this.onPublish,
  });

  final bool published;
  final int wordCount;
  final int readTime;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 22,
            runSpacing: 8,
            children: [
              _FigmaTinyMeta(
                dot: true,
                value: published ? 'Publié' : 'Brouillon',
              ),
              _FigmaTinyMeta(
                value: '$wordCount mots · ~$readTime min\nlecture',
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onPublish,
          style: OutlinedButton.styleFrom(
            foregroundColor: PlumoraColors.textPrimary,
            side: const BorderSide(color: PlumoraColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          child: const Text(
            'Publier ce\nchapitre',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _FigmaTinyMeta extends StatelessWidget {
  const _FigmaTinyMeta({required this.value, this.dot = false});

  final String value;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: PlumoraColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          value,
          style: const TextStyle(
            color: PlumoraColors.textSecondary,
            fontSize: 10,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _FigmaMobileFooterStats extends StatelessWidget {
  const _FigmaMobileFooterStats({
    required this.words,
    required this.chars,
    required this.readTime,
    required this.saved,
  });

  final int words;
  final int chars;
  final int readTime;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: PlumoraColors.cards,
        border: Border(top: BorderSide(color: PlumoraColors.border)),
      ),
      child: Row(
        children: [
          Text(
            '$words mots',
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$chars car.',
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '~$readTime min lecture',
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const Spacer(),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: saved ? _writeGreen : _writeAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            saved ? 'Sauvegardé' : 'Non sauvegardé',
            style: TextStyle(
              color: saved ? _writeGreen : _writeAccent,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaBottomChapterToolbar extends StatelessWidget {
  const _FigmaBottomChapterToolbar({
    required this.onNew,
    required this.onMukeme,
    required this.onReadMode,
    required this.readMode,
  });

  final VoidCallback onNew;
  final VoidCallback onMukeme;
  final VoidCallback onReadMode;
  final bool readMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: const BoxDecoration(
        color: PlumoraColors.cards,
        border: Border(top: BorderSide(color: PlumoraColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onReadMode,
            icon: Icon(
              readMode ? Icons.edit_outlined : Icons.visibility_outlined,
            ),
            color: PlumoraColors.textSecondary,
            tooltip: readMode ? 'Écrire' : 'Lire',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nouveau chapitre'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PlumoraColors.textSecondary,
                side: const BorderSide(color: PlumoraColors.border),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _FigmaMukemeButton(active: false, onTap: onMukeme),
        ],
      ),
    );
  }
}

class FigmaMobileEditorBodyDeprecated extends StatelessWidget {
  const FigmaMobileEditorBodyDeprecated({
    required this.book,
    required this.chapters,
    required this.selectedChapterId,
    required this.titleController,
    required this.contentController,
    required this.isSaving,
    required this.isNewChapter,
    required this.readMode,
    required this.showMukeme,
    required this.hasUnsavedChanges,
    required this.onSelect,
    required this.onNew,
    required this.onSave,
    required this.onChanged,
    required this.onReadModeChanged,
    required this.onMukemeChanged,
    this.error,
    super.key,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final String? selectedChapterId;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final bool isSaving;
  final bool isNewChapter;
  final bool readMode;
  final bool showMukeme;
  final bool hasUnsavedChanges;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;
  final VoidCallback onSave;
  final VoidCallback onChanged;
  final ValueChanged<bool> onReadModeChanged;
  final ValueChanged<bool> onMukemeChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final activeIndex = _figmaActiveIndex(
      chapters,
      selectedChapterId,
      isNewChapter,
    );
    final activeChapter = _figmaActiveChapter(
      chapters,
      selectedChapterId,
      isNewChapter,
    );
    final title = _figmaControllerTitle(
      titleController,
      fallbackOrder: activeIndex + 1,
    );
    final words = _figmaWordCount(contentController.text);
    final prevChapter = activeIndex > 0 ? chapters[activeIndex - 1] : null;
    final nextChapter = activeIndex >= 0 && activeIndex < chapters.length - 1
        ? chapters[activeIndex + 1]
        : null;
    final totalChapters = chapters.length + (isNewChapter ? 1 : 0);

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
            decoration: const BoxDecoration(
              color: PlumoraColors.cards,
              border: Border(bottom: BorderSide(color: PlumoraColors.border)),
            ),
            child: Row(
              children: [
                _FigmaSquareIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Mes histoires',
                  onTap: () => context.go(AppRoutes.write),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _showChapterSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: PlumoraColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${activeIndex + 1}/$totalChapters - $words mots'
                                  '${_figmaChapterIsPublished(book, activeChapter) ? ' - Publié' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: PlumoraColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: PlumoraColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _FigmaSquareIconButton(
                  icon: readMode
                      ? Icons.edit_outlined
                      : Icons.visibility_outlined,
                  tooltip: readMode ? 'Écrire' : 'Lire',
                  color: readMode ? _writeAccent : PlumoraColors.textSecondary,
                  onTap: () => onReadModeChanged(!readMode),
                ),
                const SizedBox(width: 6),
                _FigmaSaveIconButton(
                  isSaving: isSaving,
                  saved: !hasUnsavedChanges && !isNewChapter,
                  onSave: onSave,
                ),
              ],
            ),
          ),
        ),
        if (readMode)
          _FigmaReadModeBanner(onEdit: () => onReadModeChanged(false)),
        if (error != null) _FigmaEditorErrorBar(error!),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: readMode
                ? _FigmaReadingContent(
                    title: title,
                    content: contentController.text,
                  )
                : TextField(
                    controller: contentController,
                    onChanged: (_) => onChanged(),
                    keyboardType: TextInputType.multiline,
                    minLines: 22,
                    maxLines: null,
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'Commencez à écrire...',
                    ),
                    style: const TextStyle(
                      color: PlumoraColors.textPrimary,
                      fontSize: 16,
                      height: 1.9,
                      fontFamily: 'Georgia',
                    ),
                  ),
          ),
        ),
        _FigmaMobileChapterJumps(
          prevChapter: prevChapter,
          nextChapter: nextChapter,
          onSelect: onSelect,
          onNew: onNew,
        ),
        if (showMukeme)
          _FigmaMobileMukemePanel(onClose: () => onMukemeChanged(false))
        else if (!readMode)
          _FigmaMobileWritingToolbar(onMukeme: () => onMukemeChanged(true)),
      ],
    );
  }

  void _showChapterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FigmaChapterBottomSheet(
        book: book,
        chapters: chapters,
        selectedChapterId: selectedChapterId,
        isNewChapter: isNewChapter,
        onSelect: onSelect,
        onNew: onNew,
      ),
    );
  }
}

class _FigmaEditorToolbar extends StatelessWidget {
  const _FigmaEditorToolbar({
    required this.readMode,
    required this.showMukeme,
    required this.isSaving,
    required this.hasUnsavedChanges,
    required this.onReadModeChanged,
    required this.onMukemeChanged,
    required this.onSave,
  });

  final bool readMode;
  final bool showMukeme;
  final bool isSaving;
  final bool hasUnsavedChanges;
  final ValueChanged<bool> onReadModeChanged;
  final ValueChanged<bool> onMukemeChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: PlumoraColors.cards,
        border: Border(bottom: BorderSide(color: PlumoraColors.border)),
      ),
      child: Row(
        children: [
          if (readMode)
            const _FigmaReadModePill()
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    _FigmaToolbarIcon(icon: Icons.format_bold, tooltip: 'Gras'),
                    _FigmaToolbarIcon(
                      icon: Icons.format_italic,
                      tooltip: 'Italique',
                    ),
                    _FigmaToolbarIcon(
                      icon: Icons.format_underlined,
                      tooltip: 'Souligner',
                    ),
                    _FigmaToolbarSeparator(),
                    _FigmaToolbarIcon(
                      icon: Icons.format_quote,
                      tooltip: 'Citation',
                    ),
                    _FigmaToolbarIcon(
                      icon: Icons.format_list_bulleted,
                      tooltip: 'Liste',
                    ),
                    _FigmaToolbarIcon(
                      icon: Icons.horizontal_rule,
                      tooltip: 'Séparateur',
                    ),
                  ],
                ),
              ),
            ),
          if (readMode) const Spacer(),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () => onReadModeChanged(!readMode),
            icon: Icon(
              readMode ? Icons.edit_outlined : Icons.visibility_outlined,
            ),
            label: Text(readMode ? 'Écrire' : 'Lire'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!readMode) ...[
            const SizedBox(width: 8),
            _FigmaMukemeButton(
              active: showMukeme,
              onTap: () => onMukemeChanged(!showMukeme),
            ),
            const SizedBox(width: 8),
            _FigmaSaveButton(
              isSaving: isSaving,
              saved: !hasUnsavedChanges,
              onSave: onSave,
            ),
          ],
        ],
      ),
    );
  }
}

class _FigmaMukemeDesktopPanel extends StatelessWidget {
  const _FigmaMukemeDesktopPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: const BoxDecoration(
        color: PlumoraColors.cards,
        border: Border(bottom: BorderSide(color: PlumoraColors.border)),
      ),
      child: Row(
        children: [
          const _FigmaGradientIconBox(icon: Icons.auto_awesome, size: 34),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sélectionnez du texte puis demandez à Mukeme.',
              style: TextStyle(
                color: PlumoraColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          for (final action in const [
            'Reformuler',
            'Améliorer le style',
            'Développer',
            'Résumer',
          ])
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(action),
              ),
            ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18),
            color: PlumoraColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _FigmaBookMiniCover extends StatelessWidget {
  const _FigmaBookMiniCover({required this.book, required this.title});

  final BookModel book;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _figmaBookCoverColors(book),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if ((book.coverUrl ?? '').trim().isNotEmpty)
            Image.network(
              book.coverUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.48),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 5,
            right: 5,
            bottom: 5,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaBookNavButton extends StatelessWidget {
  const _FigmaBookNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            gradient: selected ? _figmaWriteGradient : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: compact ? 16 : 18,
                color: selected ? Colors.white : PlumoraColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : PlumoraColors.textSecondary,
                    fontSize: compact ? 12 : 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
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

class _FigmaChapterNavTile extends StatelessWidget {
  const _FigmaChapterNavTile({
    required this.index,
    required this.label,
    required this.detail,
    required this.selected,
    this.onTap,
  });

  final int index;
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? _figmaWriteGradient : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  '$index',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? Colors.white70
                        : PlumoraColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : PlumoraColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white70
                            : PlumoraColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_vert,
                size: 14,
                color: selected ? Colors.white70 : PlumoraColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FigmaToolbarIcon extends StatelessWidget {
  const _FigmaToolbarIcon({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 34,
        height: 34,
        child: IconButton(
          onPressed: () {},
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 18),
          color: PlumoraColors.textSecondary,
          hoverColor: PlumoraColors.muted,
          splashRadius: 18,
        ),
      ),
    );
  }
}

class _FigmaToolbarSeparator extends StatelessWidget {
  const _FigmaToolbarSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: PlumoraColors.border,
    );
  }
}

class _FigmaMukemeButton extends StatelessWidget {
  const _FigmaMukemeButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.auto_awesome, size: 16),
      label: const Text('Mukeme'),
      style: TextButton.styleFrom(
        foregroundColor: _writeAccent,
        backgroundColor: _writeAccent.withValues(alpha: active ? 0.18 : 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _FigmaSaveButton extends StatelessWidget {
  const _FigmaSaveButton({
    required this.isSaving,
    required this.saved,
    required this.onSave,
  });

  final bool isSaving;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: saved ? null : _figmaWriteGradient,
        color: saved ? _writeGreen.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton.icon(
        onPressed: isSaving ? null : onSave,
        icon: isSaving
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(saved ? Icons.check : Icons.save_outlined, size: 16),
        label: Text(
          isSaving
              ? 'Sauvegarde...'
              : saved
              ? 'Sauvegardé'
              : 'Enregistrer',
        ),
        style: TextButton.styleFrom(
          foregroundColor: saved ? _writeGreen : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _FigmaSaveIconButton extends StatelessWidget {
  const _FigmaSaveIconButton({
    required this.isSaving,
    required this.saved,
    required this.onSave,
  });

  final bool isSaving;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isSaving ? null : onSave,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: saved ? null : _figmaWriteGradient,
          color: saved ? _writeGreen.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isSaving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: saved ? _writeGreen : Colors.white,
                  ),
                )
              : Icon(
                  saved ? Icons.check : Icons.save_outlined,
                  color: saved ? _writeGreen : Colors.white,
                  size: 18,
                ),
        ),
      ),
    );
  }
}

class _FigmaSquareIconButton extends StatelessWidget {
  const _FigmaSquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = PlumoraColors.textSecondary,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _FigmaGradientIconBox extends StatelessWidget {
  const _FigmaGradientIconBox({required this.icon, this.size = 44});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _figmaWriteGradient,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.48),
    );
  }
}

class _FigmaReadModePill extends StatelessWidget {
  const _FigmaReadModePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _writeGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 16, color: _writeGreen),
          SizedBox(width: 7),
          Text(
            'Mode lecture',
            style: TextStyle(
              color: _writeGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaReadModeBanner extends StatelessWidget {
  const _FigmaReadModeBanner({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _writeGreen.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, size: 16, color: _writeGreen),
          const SizedBox(width: 8),
          const Text(
            'Mode lecture',
            style: TextStyle(
              color: _writeGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: _writeAccent,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Écrire'),
          ),
        ],
      ),
    );
  }
}

class _FigmaEditorErrorBar extends StatelessWidget {
  const _FigmaEditorErrorBar(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      color: PlumoraColors.destructive.withValues(alpha: 0.08),
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

class _FigmaChapterStatusStrip extends StatelessWidget {
  const _FigmaChapterStatusStrip({
    required this.published,
    required this.wordCount,
    required this.readTime,
  });

  final bool published;
  final int wordCount;
  final int readTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PlumoraColors.border)),
      ),
      child: Row(
        children: [
          Text(
            published ? '● Publié' : '● Brouillon',
            style: TextStyle(
              color: published ? _writeGreen : PlumoraColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$wordCount mots - ~$readTime min lecture',
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaEditorBreadcrumb extends StatelessWidget {
  const _FigmaEditorBreadcrumb({
    required this.bookTitle,
    required this.chapterIndex,
    required this.chapterTitle,
  });

  final String bookTitle;
  final int chapterIndex;
  final String chapterTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            bookTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.chevron_right,
            size: 14,
            color: PlumoraColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            '$chapterIndex. $chapterTitle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FigmaReadingContent extends StatelessWidget {
  const _FigmaReadingContent({
    required this.title,
    required this.content,
    this.showTitle = true,
  });

  final String title;
  final String content;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final text = content.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            title,
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontFamily: 'Playfair Display',
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          text.isEmpty ? 'Ce chapitre est vide.' : content,
          style: TextStyle(
            color: text.isEmpty
                ? PlumoraColors.textSecondary
                : PlumoraColors.textPrimary,
            fontSize: 17,
            height: 1.9,
            fontFamily: 'Georgia',
            fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}

class _FigmaChapterJumpRow extends StatelessWidget {
  const _FigmaChapterJumpRow({
    required this.prevChapter,
    required this.nextChapter,
    required this.onSelect,
    required this.onNew,
  });

  final ChapterModel? prevChapter;
  final ChapterModel? nextChapter;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: PlumoraColors.border)),
      ),
      child: Row(
        children: [
          if (prevChapter != null)
            Expanded(
              child: _FigmaChapterJumpButton(
                chapter: prevChapter!,
                label: 'Chapitre précédent',
                leading: true,
                onTap: () => onSelect(prevChapter!),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 12),
          if (nextChapter != null)
            Expanded(
              child: _FigmaChapterJumpButton(
                chapter: nextChapter!,
                label: 'Chapitre suivant',
                leading: false,
                onTap: () => onSelect(nextChapter!),
              ),
            )
          else
            Expanded(
              child: _FigmaDashedButton(
                icon: Icons.add,
                label: 'Nouveau chapitre',
                onTap: onNew,
              ),
            ),
        ],
      ),
    );
  }
}

class _FigmaMobileChapterJumps extends StatelessWidget {
  const _FigmaMobileChapterJumps({
    required this.prevChapter,
    required this.nextChapter,
    required this.onSelect,
    required this.onNew,
  });

  final ChapterModel? prevChapter;
  final ChapterModel? nextChapter;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: PlumoraColors.background,
        border: Border(top: BorderSide(color: PlumoraColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: prevChapter == null
                ? const SizedBox.shrink()
                : _FigmaMobileJumpButton(
                    icon: Icons.chevron_left,
                    title: 'Précédent',
                    chapter: prevChapter!,
                    onTap: () => onSelect(prevChapter!),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: nextChapter == null
                ? _FigmaDashedButton(
                    icon: Icons.add,
                    label: 'Nouveau chapitre',
                    onTap: onNew,
                  )
                : _FigmaMobileJumpButton(
                    icon: Icons.chevron_right,
                    title: 'Suivant',
                    chapter: nextChapter!,
                    trailing: true,
                    onTap: () => onSelect(nextChapter!),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FigmaChapterBottomSheet extends StatelessWidget {
  const _FigmaChapterBottomSheet({
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
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.80,
        ),
        decoration: const BoxDecoration(
          color: PlumoraColors.cards,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tous les chapitres',
                          style: TextStyle(
                            color: PlumoraColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_figmaBookTitle(book)} - ${chapters.length} chapitres',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PlumoraColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _FigmaSquareIconButton(
                    icon: Icons.add,
                    tooltip: 'Nouveau chapitre',
                    color: _writeAccent,
                    onTap: () {
                      Navigator.of(context).pop();
                      onNew();
                    },
                  ),
                  const SizedBox(width: 6),
                  _FigmaSquareIconButton(
                    icon: Icons.close,
                    tooltip: 'Fermer',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: PlumoraColors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (var i = 0; i < chapters.length; i++)
                    _FigmaBottomSheetChapterTile(
                      index: chapters[i].order == 0 ? i + 1 : chapters[i].order,
                      title: _figmaChapterTitle(
                        chapters[i],
                        fallbackOrder: i + 1,
                      ),
                      detail: _figmaChapterDetail(book, chapters[i]),
                      selected:
                          chapters[i].id == selectedChapterId && !isNewChapter,
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelect(chapters[i]);
                      },
                    ),
                  if (isNewChapter)
                    _FigmaBottomSheetChapterTile(
                      index: chapters.length + 1,
                      title: 'Nouveau chapitre',
                      detail: 'Vide - Brouillon',
                      selected: true,
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

class _FigmaBottomSheetChapterTile extends StatelessWidget {
  const _FigmaBottomSheetChapterTile({
    required this.index,
    required this.title,
    required this.detail,
    required this.selected,
    this.onTap,
  });

  final int index;
  final String title;
  final String detail;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? _figmaWriteGradient : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '$index',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? Colors.white70
                        : PlumoraColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.description_outlined,
                size: 18,
                color: selected ? Colors.white70 : PlumoraColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : PlumoraColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white70
                            : PlumoraColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _FigmaDashedButton extends StatelessWidget {
  const _FigmaDashedButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: PlumoraColors.border, width: 1.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: PlumoraColors.textSecondary),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlumoraColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FigmaChapterJumpButton extends StatelessWidget {
  const _FigmaChapterJumpButton({
    required this.chapter,
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final ChapterModel chapter;
  final String label;
  final bool leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Expanded(
      child: Column(
        crossAxisAlignment: leading
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            _figmaChapterTitle(chapter),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: PlumoraColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: leading
              ? [
                  const Icon(
                    Icons.chevron_left,
                    color: PlumoraColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  content,
                ]
              : [
                  content,
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right,
                    color: PlumoraColors.textSecondary,
                    size: 20,
                  ),
                ],
        ),
      ),
    );
  }
}

class _FigmaMobileJumpButton extends StatelessWidget {
  const _FigmaMobileJumpButton({
    required this.icon,
    required this.title,
    required this.chapter,
    required this.onTap,
    this.trailing = false,
  });

  final IconData icon;
  final String title;
  final ChapterModel chapter;
  final VoidCallback onTap;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final text = Expanded(
      child: Column(
        crossAxisAlignment: trailing
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            _figmaChapterTitle(chapter),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: PlumoraColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: trailing
              ? [text, Icon(icon, color: PlumoraColors.textSecondary, size: 18)]
              : [
                  Icon(icon, color: PlumoraColors.textSecondary, size: 18),
                  text,
                ],
        ),
      ),
    );
  }
}

class _FigmaMobileWritingToolbar extends StatelessWidget {
  const _FigmaMobileWritingToolbar({required this.onMukeme});

  final VoidCallback onMukeme;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: const BoxDecoration(
          color: PlumoraColors.cards,
          border: Border(top: BorderSide(color: PlumoraColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    _FigmaMobileToolbarIcon(
                      icon: Icons.format_bold,
                      tooltip: 'Gras',
                    ),
                    _FigmaMobileToolbarIcon(
                      icon: Icons.format_italic,
                      tooltip: 'Italique',
                    ),
                    _FigmaMobileToolbarIcon(
                      icon: Icons.format_quote,
                      tooltip: 'Citation',
                    ),
                    _FigmaMobileToolbarIcon(
                      icon: Icons.format_list_bulleted,
                      tooltip: 'Liste',
                    ),
                    _FigmaMobileToolbarIcon(
                      icon: Icons.horizontal_rule,
                      tooltip: 'Séparateur',
                    ),
                  ],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onMukeme,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Mukeme'),
              style: TextButton.styleFrom(
                foregroundColor: _writeAccent,
                backgroundColor: _writeAccent.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FigmaMobileToolbarIcon extends StatelessWidget {
  const _FigmaMobileToolbarIcon({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          onPressed: () {},
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 20),
          color: PlumoraColors.textSecondary,
        ),
      ),
    );
  }
}

class _FigmaMobileMukemePanel extends StatelessWidget {
  const _FigmaMobileMukemePanel({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: PlumoraColors.cards,
          border: Border(top: BorderSide(color: PlumoraColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const _FigmaGradientIconBox(icon: Icons.auto_awesome, size: 30),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Mukeme',
                    style: TextStyle(
                      color: PlumoraColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 20),
                  color: PlumoraColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in const [
                  'Reformuler',
                  'Améliorer le style',
                  'Développer',
                  'Corriger',
                ])
                  OutlinedButton(onPressed: () {}, child: Text(action)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FigmaEditorStatsBar extends StatelessWidget {
  const _FigmaEditorStatsBar({
    required this.controller,
    required this.activeIndex,
    required this.chaptersLength,
    required this.saved,
  });

  final TextEditingController controller;
  final int activeIndex;
  final int chaptersLength;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final text = value.text;
        final words = _figmaWordCount(text);
        final readTime = _figmaReadTimeMinutes(words);
        final chapterCount = chaptersLength <= 0 ? 1 : chaptersLength;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: const BoxDecoration(
            color: PlumoraColors.cards,
            border: Border(top: BorderSide(color: PlumoraColors.border)),
          ),
          child: Row(
            children: [
              _FigmaStatsText(label: '$words', suffix: 'mots'),
              const SizedBox(width: 18),
              _FigmaStatsText(label: '${text.length}', suffix: 'car.'),
              const SizedBox(width: 18),
              Text(
                '~$readTime min lecture',
                style: const TextStyle(
                  color: PlumoraColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 18),
              Text(
                'Chapitre ${activeIndex + 1}/$chapterCount',
                style: const TextStyle(
                  color: PlumoraColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                saved ? '● Sauvegardé' : '● Non sauvegardé',
                style: TextStyle(
                  color: saved ? _writeGreen : _writeGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FigmaStatsText extends StatelessWidget {
  const _FigmaStatsText({required this.label, required this.suffix});

  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: ' $suffix'),
        ],
      ),
      style: const TextStyle(color: PlumoraColors.textSecondary, fontSize: 12),
    );
  }
}

const _figmaWriteGradient = LinearGradient(
  colors: [_writeAccent, _writeAccentLight],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

String _figmaBookTitle(BookModel book) {
  final title = book.title.trim();
  return title.isEmpty ? 'Livre sans titre' : title;
}

String _figmaBookGenre(BookModel book) {
  final genre = book.genre?.trim();
  return genre == null || genre.isEmpty ? 'Manuscrit' : genre;
}

String _figmaChapterTitle(ChapterModel chapter, {int? fallbackOrder}) {
  final title = chapter.title.trim();
  if (title.isNotEmpty) {
    return title;
  }

  final order = chapter.order == 0 ? fallbackOrder : chapter.order;
  return order == null ? 'Chapitre sans titre' : 'Chapitre $order';
}

String _figmaControllerTitle(
  TextEditingController controller, {
  required int fallbackOrder,
}) {
  final title = controller.text.trim();
  return title.isEmpty ? 'Chapitre $fallbackOrder' : title;
}

String _figmaChapterDetail(BookModel book, ChapterModel chapter) {
  final words = _figmaWordCount(chapter.content);
  final wordsLabel = words == 0 ? 'Vide' : '$words mots';
  final status = _figmaChapterIsPublished(book, chapter)
      ? 'Publié'
      : 'Brouillon';
  return '$wordsLabel - $status';
}

bool _figmaChapterIsPublished(BookModel book, ChapterModel? chapter) {
  if (chapter == null) {
    return false;
  }

  return book.status == BookStatus.published &&
      chapter.content.trim().isNotEmpty;
}

int _figmaActiveIndex(
  List<ChapterModel> chapters,
  String? selectedChapterId,
  bool isNewChapter,
) {
  if (isNewChapter) {
    return chapters.length;
  }

  final index = chapters.indexWhere(
    (chapter) => chapter.id == selectedChapterId,
  );
  return index < 0 ? 0 : index;
}

ChapterModel? _figmaActiveChapter(
  List<ChapterModel> chapters,
  String? selectedChapterId,
  bool isNewChapter,
) {
  if (isNewChapter) {
    return null;
  }

  final index = chapters.indexWhere(
    (chapter) => chapter.id == selectedChapterId,
  );
  if (index < 0 || index >= chapters.length) {
    return null;
  }

  return chapters[index];
}

int _figmaWordCount(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .length;
}

int _figmaReadTimeMinutes(int words) {
  return words <= 0 ? 1 : (words / 200).round().clamp(1, 999);
}

String _figmaCompactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}

List<Color> _figmaBookCoverColors(BookModel book) {
  final palettes = [
    [const Color(0xFF7C3AED), const Color(0xFF312E81)],
    [const Color(0xFFE11D48), const Color(0xFFC2410C)],
    [const Color(0xFF2563EB), const Color(0xFF1E293B)],
    [const Color(0xFF10B981), const Color(0xFF0891B2)],
    [const Color(0xFFF59E0B), const Color(0xFFB91C1C)],
    [const Color(0xFFDB2777), const Color(0xFF991B1B)],
  ];
  final key = book.id.isEmpty ? book.title : book.id;
  final index =
      key.codeUnits.fold<int>(0, (sum, code) => sum + code) % palettes.length;
  return palettes[index];
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
