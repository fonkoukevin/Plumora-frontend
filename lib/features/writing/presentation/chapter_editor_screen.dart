import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/text/plumora_document_codec.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../ai/data/models/plumo_ai_models.dart';
import '../../ai/data/plumo_ai_error.dart';
import '../../ai/data/repositories/plumo_ai_repository.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/models/chapter_model.dart';
import '../../book/data/repositories/book_repository.dart';
import '../../book/data/repositories/chapter_repository.dart';
import '../data/writing_cache_invalidator.dart';
import 'widgets/plumora_document_editor.dart';

const _writeAccent = Color(0xFF7C5CFF);
const _writeAccentLight = Color(0xFF9B80FF);
const _writeGold = Color(0xFFD6B25E);
const _writeGreen = Color(0xFF3FBF7F);

enum _UnsavedDecision { stay, discard, save }

class ChapterEditorScreen extends ConsumerStatefulWidget {
  const ChapterEditorScreen({this.bookId, super.key});

  final String? bookId;

  @override
  ConsumerState<ChapterEditorScreen> createState() =>
      _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends ConsumerState<ChapterEditorScreen> {
  final _titleController = TextEditingController();
  late final quill.QuillController _contentController;
  String? _selectedChapterId;
  String? _hydratedChapterId;
  bool _isNewChapter = false;
  bool _isSaving = false;
  bool _readMode = false;
  bool _showPlumo = false;
  bool _hasUnsavedChanges = false;
  bool _isHydratingContent = false;
  String _documentSnapshot = '';
  Timer? _autoSaveTimer;
  List<ChapterModel> _currentChapters = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _contentController = quill.QuillController.basic();
    _documentSnapshot = PlumoraDocumentCodec.encodeDocument(
      _contentController.document,
    );
    _contentController.addListener(_handleDocumentChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.removeListener(_handleDocumentChanged);
    _contentController.dispose();
    super.dispose();
  }

  void _handleDocumentChanged() {
    if (_isHydratingContent || !mounted) {
      return;
    }
    final snapshot = PlumoraDocumentCodec.encodeDocument(
      _contentController.document,
    );
    if (snapshot == _documentSnapshot) {
      return;
    }
    _documentSnapshot = snapshot;
    _markDirty();
  }

  void _hydrateContent(String content) {
    _isHydratingContent = true;
    final document = PlumoraDocumentCodec.decodeDocument(content);
    _contentController.document = document;
    _contentController.readOnly = false;
    _documentSnapshot = PlumoraDocumentCodec.encodeDocument(document);
    _isHydratingContent = false;
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

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _leaveEditor();
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: bookAsync.when(
          loading: () => _EditorStateWithBack(
            onBack: () => returnToPreviousOr(context, AppRoutes.write),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _EditorStateWithBack(
            onBack: () => returnToPreviousOr(context, AppRoutes.write),
            child: _CenteredError(
              message: AppError.messageFor(error),
              onRetry: () => ref.invalidate(authorBookProvider(bookId)),
            ),
          ),
          data: (book) => chaptersAsync.when(
            loading: () => _EditorStateWithBack(
              onBack: () => returnToPreviousOr(context, AppRoutes.write),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _EditorStateWithBack(
              onBack: () => returnToPreviousOr(context, AppRoutes.write),
              child: _CenteredError(
                message: AppError.messageFor(error),
                onRetry: () => ref.invalidate(bookChaptersProvider(bookId)),
              ),
            ),
            data: (chapters) {
              final sorted = [...chapters]
                ..sort((a, b) {
                  final orderCompare = a.order.compareTo(b.order);
                  return orderCompare == 0
                      ? a.title.compareTo(b.title)
                      : orderCompare;
                });
              _currentChapters = sorted;
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
                      showPlumo: _showPlumo,
                      hasUnsavedChanges: _hasUnsavedChanges,
                      onSelect: _selectChapter,
                      onNew: () => _startNew(sorted),
                      onSave: () => _save(book.id, sorted),
                      onChanged: _markDirty,
                      onReadModeChanged: (value) =>
                          setState(() => _readMode = value),
                      onPlumoChanged: (value) =>
                          setState(() => _showPlumo = value),
                      onBack: _leaveEditor,
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
                    showPlumo: _showPlumo,
                    hasUnsavedChanges: _hasUnsavedChanges,
                    onSelect: _selectChapter,
                    onNew: () => _startNew(sorted),
                    onSave: () => _save(book.id, sorted),
                    onChanged: _markDirty,
                    onReadModeChanged: (value) =>
                        setState(() => _readMode = value),
                    onPlumoChanged: (value) =>
                        setState(() => _showPlumo = value),
                    onBack: _leaveEditor,
                  );
                },
              );
            },
          ),
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

    if (existing != null) {
      if (_hydratedChapterId == existing.id) {
        return;
      }
      _hydratedChapterId = existing.id;
      _hasUnsavedChanges = false;
      _titleController.text = existing.title;
      _hydrateContent(existing.content);
      return;
    }

    // We have a selected chapter (e.g. one just created/saved) but it isn't
    // in this `chapters` list yet — most likely a provider invalidation
    // triggered by the save is still refetching. Keep the current state
    // instead of wiping it and creating a phantom new chapter; this will
    // resolve itself once the refreshed list arrives.
    if (_selectedChapterId != null) {
      return;
    }

    if (chapters.isEmpty) {
      if (_hydratedChapterId != '__new__') {
        _selectedChapterId = null;
        _hydratedChapterId = '__new__';
        _isNewChapter = true;
        _hasUnsavedChanges = true;
        _setNewChapterTitle(1);
        _hydrateContent('');
      }
      return;
    }

    final selected = _mostRecentlyEditedChapter(chapters);
    if (_hydratedChapterId == selected.id) {
      return;
    }

    _selectedChapterId = selected.id;
    _hydratedChapterId = selected.id;
    _hasUnsavedChanges = false;
    _titleController.text = selected.title;
    _hydrateContent(selected.content);
  }

  Future<void> _selectChapter(ChapterModel chapter) async {
    if (chapter.id == _selectedChapterId && !_isNewChapter) {
      return;
    }
    if (!await _confirmCanReplaceDraft()) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedChapterId = chapter.id;
      _hydratedChapterId = chapter.id;
      _isNewChapter = false;
      _readMode = false;
      _showPlumo = false;
      _hasUnsavedChanges = false;
      _error = null;
      _titleController.text = chapter.title;
      _hydrateContent(chapter.content);
    });
  }

  Future<void> _startNew(List<ChapterModel> chapters) async {
    if (!await _confirmCanReplaceDraft()) {
      return;
    }
    if (!mounted) {
      return;
    }
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
      _showPlumo = false;
      _hasUnsavedChanges = true;
      _error = null;
      _setNewChapterTitle(nextOrder);
      _hydrateContent('');
    });
  }

  Future<bool> _confirmCanReplaceDraft() async {
    if (!_hasUnsavedChanges) {
      return true;
    }
    _autoSaveTimer?.cancel();
    final decision = await showDialog<_UnsavedDecision>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text(
          'Souhaites-tu enregistrer ce chapitre avant de continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_UnsavedDecision.stay),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_UnsavedDecision.discard),
            child: const Text('Ignorer'),
          ),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_UnsavedDecision.save),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (decision == _UnsavedDecision.discard) {
      setState(() => _hasUnsavedChanges = false);
      return true;
    }
    if (decision != _UnsavedDecision.save) {
      _scheduleAutoSave();
      return false;
    }

    final bookId = widget.bookId?.trim() ?? '';
    return bookId.isNotEmpty && await _save(bookId, _currentChapters);
  }

  Future<void> _leaveEditor() async {
    if (!await _confirmCanReplaceDraft() || !mounted) {
      return;
    }
    returnToPreviousOr(context, AppRoutes.write);
  }

  void _setNewChapterTitle(int order) {
    final title = 'Chapitre $order - ';
    _titleController.value = TextEditingValue(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );
  }

  void _markDirty() {
    // Always rebuild (not just on the first keystroke) so live UI derived
    // from the controllers — word count, character count, read time — keeps
    // updating as the user types, even once `_hasUnsavedChanges` is already
    // true.
    setState(() => _hasUnsavedChanges = true);
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    final bookId = widget.bookId?.trim() ?? '';
    if (_isNewChapter || _isSaving || bookId.isEmpty) {
      return;
    }
    _autoSaveTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted && _hasUnsavedChanges && !_isSaving) {
        _save(bookId, _currentChapters, automatic: true);
      }
    });
  }

  Future<bool> _save(
    String bookId,
    List<ChapterModel> chapters, {
    bool automatic = false,
  }) async {
    if (_isSaving) {
      return false;
    }
    _autoSaveTimer?.cancel();
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      if (!automatic) {
        setState(() => _error = 'Ajoute un titre de chapitre.');
      }
      return false;
    }
    if (_isNewChapter &&
        RegExp(
          r'^Chapitre\s+\d+\s*-\s*$',
          caseSensitive: false,
        ).hasMatch(title)) {
      if (!automatic) {
        setState(() => _error = 'Ajoute le nom du chapitre après le tiret.');
      }
      return false;
    }

    final wasNewChapter = _isNewChapter;
    final targetChapterId = _selectedChapterId;
    final savedSnapshot = PlumoraDocumentCodec.encodeDocument(
      _contentController.document,
    );

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final repository = ref.read(chapterRepositoryProvider);
      final order = wasNewChapter
          ? (chapters.isEmpty
                ? 1
                : chapters
                          .map((chapter) => chapter.order)
                          .reduce((a, b) => a > b ? a : b) +
                      1)
          : chapters
                .cast<ChapterModel?>()
                .firstWhere(
                  (chapter) => chapter?.id == targetChapterId,
                  orElse: () => null,
                )
                ?.order;
      final request = ChapterUpsertRequest(
        title: title,
        content: savedSnapshot,
        order: order,
      );
      final saved = wasNewChapter || targetChapterId == null
          ? await repository.createChapter(bookId, request)
          : await repository.updateChapter(targetChapterId, request);

      if (!mounted) {
        return true;
      }

      ref.invalidate(bookChaptersProvider(bookId));
      ref.invalidate(authorBookProvider(bookId));
      ref.invalidate(chapterProvider(saved.id));
      ref.invalidate(myBooksProvider);
      invalidateBookPublicationCaches(ref, bookId);
      final stillOnSavedChapter = wasNewChapter
          ? _isNewChapter && _selectedChapterId == targetChapterId
          : !_isNewChapter && _selectedChapterId == targetChapterId;
      final contentUnchanged =
          PlumoraDocumentCodec.encodeDocument(_contentController.document) ==
          savedSnapshot;
      final titleUnchanged = _titleController.text.trim() == title;
      setState(() {
        if (stillOnSavedChapter) {
          _selectedChapterId = saved.id;
          _hydratedChapterId = saved.id;
          _isNewChapter = false;
          _hasUnsavedChanges = !(contentUnchanged && titleUnchanged);
        }
      });
      return true;
    } catch (error) {
      if (mounted) {
        setState(() => _error = AppError.messageFor(error));
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        // Une nouvelle frappe peut arriver pendant la requête. Dans ce cas,
        // le brouillon reste sale et doit repartir dans le cycle d'autosave
        // une fois la sauvegarde courante terminée.
        if (_hasUnsavedChanges) {
          _scheduleAutoSave();
        }
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
            onTap: () => returnToPreviousOr(context, AppRoutes.write),
          ),
          const SizedBox(height: 18),
          Text(
            'Choisir un manuscrit',
            style: TextStyle(
              color: context.colors.textPrimary,
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
                        message: "Crée un livre avant d'ouvrir l'éditeur.",
                        icon: Icons.edit_outlined,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.push(AppRoutes.createBook),
                          icon: const Icon(Icons.add),
                          label: const Text('Créer un livre'),
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
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${book.chapterCount} chapitres - ${book.wordCount} mots',
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: context.colors.textSecondary,
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
    required this.showPlumo,
    required this.hasUnsavedChanges,
    required this.onReadModeChanged,
    required this.onPlumoChanged,
    required this.onBack,
    this.error,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final String? selectedChapterId;
  final TextEditingController titleController;
  final quill.QuillController contentController;
  final bool isSaving;
  final bool isNewChapter;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;
  final VoidCallback onSave;
  final VoidCallback onChanged;
  final bool readMode;
  final bool showPlumo;
  final bool hasUnsavedChanges;
  final ValueChanged<bool> onReadModeChanged;
  final ValueChanged<bool> onPlumoChanged;
  final VoidCallback onBack;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FigmaChapterNavigationRail(
          book: book,
          chapters: chapters,
          selectedChapterId: selectedChapterId,
          isNewChapter: isNewChapter,
          onSelect: onSelect,
          onNew: onNew,
          onBack: onBack,
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
            showPlumo: showPlumo,
            hasUnsavedChanges: hasUnsavedChanges,
            error: error,
            onSave: onSave,
            onChanged: onChanged,
            onReadModeChanged: onReadModeChanged,
            onPlumoChanged: onPlumoChanged,
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
    required this.showPlumo,
    required this.hasUnsavedChanges,
    required this.onReadModeChanged,
    required this.onPlumoChanged,
    required this.onBack,
    this.error,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final String? selectedChapterId;
  final TextEditingController titleController;
  final quill.QuillController contentController;
  final bool isSaving;
  final bool isNewChapter;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;
  final VoidCallback onSave;
  final VoidCallback onChanged;
  final bool readMode;
  final bool showPlumo;
  final bool hasUnsavedChanges;
  final ValueChanged<bool> onReadModeChanged;
  final ValueChanged<bool> onPlumoChanged;
  final VoidCallback onBack;
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
      showPlumo: showPlumo,
      hasUnsavedChanges: hasUnsavedChanges,
      error: error,
      onSelect: onSelect,
      onNew: onNew,
      onSave: onSave,
      onChanged: onChanged,
      onReadModeChanged: onReadModeChanged,
      onPlumoChanged: onPlumoChanged,
      onBack: onBack,
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
    required this.onBack,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final String? selectedChapterId;
  final bool isNewChapter;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final totalWords = chapters.fold<int>(
      0,
      (sum, chapter) => sum + PlumoraDocumentCodec.wordCount(chapter.content),
    );

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: context.colors.background,
        border: Border(right: BorderSide(color: context.colors.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FigmaBackButton(label: 'Retour', onTap: onBack),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chapitres',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${chapters.length} chapitres - ${_figmaCompactNumber(totalWords)} mots',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.colors.textSecondary,
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
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.colors.border)),
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
    required this.showPlumo,
    required this.hasUnsavedChanges,
    required this.onSave,
    required this.onChanged,
    required this.onReadModeChanged,
    required this.onPlumoChanged,
    this.error,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final TextEditingController titleController;
  final quill.QuillController contentController;
  final String? selectedChapterId;
  final bool isSaving;
  final bool isNewChapter;
  final bool readMode;
  final bool showPlumo;
  final bool hasUnsavedChanges;
  final VoidCallback onSave;
  final VoidCallback onChanged;
  final ValueChanged<bool> onReadModeChanged;
  final ValueChanged<bool> onPlumoChanged;
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
    final contentText = _figmaControllerPlainText(contentController);
    final words = _figmaWordCount(contentText);
    final readTime = _figmaReadTimeMinutes(words);
    return Column(
      children: [
        _FigmaEditorToolbar(
          contentController: contentController,
          readMode: readMode,
          showPlumo: showPlumo,
          isSaving: isSaving,
          hasUnsavedChanges: hasUnsavedChanges || isNewChapter,
          onReadModeChanged: onReadModeChanged,
          onPlumoChanged: onPlumoChanged,
          onSave: onSave,
        ),
        if (showPlumo && !readMode)
          _FigmaPlumoDesktopPanel(
            onClose: () => onPlumoChanged(false),
            contentController: contentController,
            titleController: titleController,
            onChanged: onChanged,
          ),
        if (error != null) _FigmaEditorErrorBar(error!),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 820,
                  minHeight: 720,
                ),
                margin: const EdgeInsets.symmetric(vertical: 28),
                padding: const EdgeInsets.fromLTRB(52, 42, 52, 48),
                decoration: BoxDecoration(
                  color: context.colors.cards,
                  border: Border.all(color: context.colors.border),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.055),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
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
                        style: GoogleFonts.playfairDisplay(
                          color: context.colors.textPrimary,
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
                        style: GoogleFonts.playfairDisplay(
                          color: context.colors.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    if (isNewChapter && !readMode) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Ajoutez le nom du chapitre après le tiret.',
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _FigmaChapterStatusStrip(
                      published: published,
                      wordCount: words,
                      readTime: readTime,
                    ),
                    const SizedBox(height: 26),
                    PlumoraDocumentEditor(
                      controller: contentController,
                      readOnly: readMode,
                      autoFocus: isNewChapter,
                      placeholder: 'Commencez à écrire ce chapitre…',
                    ),
                  ],
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
    required this.showPlumo,
    required this.hasUnsavedChanges,
    required this.onSelect,
    required this.onNew,
    required this.onSave,
    required this.onChanged,
    required this.onReadModeChanged,
    required this.onPlumoChanged,
    required this.onBack,
    this.error,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final String? selectedChapterId;
  final TextEditingController titleController;
  final quill.QuillController contentController;
  final bool isSaving;
  final bool isNewChapter;
  final bool readMode;
  final bool showPlumo;
  final bool hasUnsavedChanges;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;
  final VoidCallback onSave;
  final VoidCallback onChanged;
  final ValueChanged<bool> onReadModeChanged;
  final ValueChanged<bool> onPlumoChanged;
  final VoidCallback onBack;
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
    final contentText = _figmaControllerPlainText(contentController);
    final words = _figmaWordCount(contentText);
    final readTime = _figmaReadTimeMinutes(words);
    final saved = !hasUnsavedChanges && !isNewChapter;
    final published = _figmaChapterIsPublished(book, activeChapter);

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
            decoration: BoxDecoration(
              color: context.colors.cards,
              border: Border(bottom: BorderSide(color: context.colors.border)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    FigmaBackButton(label: 'Retour', onTap: onBack),
                    const Spacer(),
                    _FigmaSavedStatusPill(
                      isSaving: isSaving,
                      saved: saved,
                      onSave: onSave,
                    ),
                  ],
                ),
                if (!readMode) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: PlumoraDocumentToolbar(
                      controller: contentController,
                      compact: true,
                    ),
                  ),
                ],
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
                        style: GoogleFonts.playfairDisplay(
                          color: context.colors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      if (isNewChapter && !readMode) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Ajoutez le nom du chapitre après le tiret.',
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _FigmaChapterPublishStrip(
                        published: published,
                        wordCount: words,
                        readTime: readTime,
                        onPublish: onSave,
                      ),
                      const SizedBox(height: 18),
                      Divider(color: context.colors.border),
                      const SizedBox(height: 20),
                      PlumoraDocumentEditor(
                        controller: contentController,
                        readOnly: readMode,
                        compact: true,
                        autoFocus: isNewChapter,
                        placeholder: 'Commencez à écrire ce chapitre…',
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _FigmaMobileFooterStats(
          words: words,
          chars: contentText.length,
          readTime: readTime,
          saved: saved,
        ),
        if (showPlumo)
          _FigmaMobilePlumoPanel(
            onClose: () => onPlumoChanged(false),
            contentController: contentController,
            titleController: titleController,
            onChanged: onChanged,
          )
        else
          _FigmaBottomChapterToolbar(
            onPlumo: () => onPlumoChanged(true),
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
  const _FigmaSavedStatusPill({
    required this.isSaving,
    required this.saved,
    required this.onSave,
  });

  final bool isSaving;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final label = isSaving
        ? 'Sauvegarde...'
        : saved
        ? 'Sauvegardé'
        : 'À sauvegarder';

    return InkWell(
      onTap: (isSaving || saved) ? null : onSave,
      borderRadius: BorderRadius.circular(999),
      child: Container(
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
            foregroundColor: context.colors.textPrimary,
            side: BorderSide(color: context.colors.border),
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
            decoration: BoxDecoration(
              color: context.colors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          value,
          style: TextStyle(
            color: context.colors.textSecondary,
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
      decoration: BoxDecoration(
        color: context.colors.cards,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        children: [
          Text(
            '$words mots',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$chars car.',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '~$readTime min',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 10),
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
            saved ? 'Sauvé' : 'À sauver',
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
    required this.onPlumo,
    required this.onReadMode,
    required this.readMode,
  });

  final VoidCallback onPlumo;
  final VoidCallback onReadMode;
  final bool readMode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        decoration: BoxDecoration(
          color: context.colors.cards,
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onReadMode,
              icon: Icon(
                readMode ? Icons.edit_outlined : Icons.visibility_outlined,
              ),
              color: context.colors.textSecondary,
              tooltip: readMode ? 'Écrire' : 'Lire',
            ),
            const SizedBox(width: 8),
            Expanded(child: _FigmaPlumoButton(active: false, onTap: onPlumo)),
          ],
        ),
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
    required this.showPlumo,
    required this.hasUnsavedChanges,
    required this.onSelect,
    required this.onNew,
    required this.onSave,
    required this.onChanged,
    required this.onReadModeChanged,
    required this.onPlumoChanged,
    this.error,
    super.key,
  });

  final BookModel book;
  final List<ChapterModel> chapters;
  final String? selectedChapterId;
  final TextEditingController titleController;
  final quill.QuillController contentController;
  final bool isSaving;
  final bool isNewChapter;
  final bool readMode;
  final bool showPlumo;
  final bool hasUnsavedChanges;
  final ValueChanged<ChapterModel> onSelect;
  final VoidCallback onNew;
  final VoidCallback onSave;
  final VoidCallback onChanged;
  final ValueChanged<bool> onReadModeChanged;
  final ValueChanged<bool> onPlumoChanged;
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
    final contentText = _figmaControllerPlainText(contentController);
    final words = _figmaWordCount(contentText);
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
            decoration: BoxDecoration(
              color: context.colors.cards,
              border: Border(bottom: BorderSide(color: context.colors.border)),
            ),
            child: Row(
              children: [
                FigmaBackButton(
                  label: 'Retour',
                  onTap: () => returnToPreviousOr(context, AppRoutes.write),
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
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
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
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: context.colors.textSecondary,
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
                  color: readMode ? _writeAccent : context.colors.textSecondary,
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
            child: PlumoraDocumentEditor(
              controller: contentController,
              readOnly: readMode,
              compact: true,
            ),
          ),
        ),
        _FigmaMobileChapterJumps(
          prevChapter: prevChapter,
          nextChapter: nextChapter,
          onSelect: onSelect,
          onNew: onNew,
        ),
        if (showPlumo)
          _FigmaMobilePlumoPanel(
            onClose: () => onPlumoChanged(false),
            contentController: contentController,
            titleController: titleController,
            onChanged: onChanged,
          )
        else if (!readMode)
          _FigmaMobileWritingToolbar(onPlumo: () => onPlumoChanged(true)),
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
    required this.contentController,
    required this.readMode,
    required this.showPlumo,
    required this.isSaving,
    required this.hasUnsavedChanges,
    required this.onReadModeChanged,
    required this.onPlumoChanged,
    required this.onSave,
  });

  final quill.QuillController contentController;
  final bool readMode;
  final bool showPlumo;
  final bool isSaving;
  final bool hasUnsavedChanges;
  final ValueChanged<bool> onReadModeChanged;
  final ValueChanged<bool> onPlumoChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.cards,
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        children: [
          if (readMode)
            const _FigmaReadModePill()
          else
            Expanded(
              child: PlumoraDocumentToolbar(controller: contentController),
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
            _FigmaPlumoButton(
              active: showPlumo,
              onTap: () => onPlumoChanged(!showPlumo),
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

class _FigmaPlumoDesktopPanel extends ConsumerStatefulWidget {
  const _FigmaPlumoDesktopPanel({
    required this.onClose,
    required this.contentController,
    required this.titleController,
    required this.onChanged,
  });

  final VoidCallback onClose;
  final quill.QuillController contentController;
  final TextEditingController titleController;
  final VoidCallback onChanged;

  @override
  ConsumerState<_FigmaPlumoDesktopPanel> createState() =>
      _FigmaPlumoDesktopPanelState();
}

class _FigmaPlumoDesktopPanelState
    extends ConsumerState<_FigmaPlumoDesktopPanel> {
  _PlumoQuickAction? _pendingAction;

  @override
  void initState() {
    super.initState();
    widget.contentController.addListener(_handleSelectionChanged);
  }

  @override
  void didUpdateWidget(covariant _FigmaPlumoDesktopPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contentController != widget.contentController) {
      oldWidget.contentController.removeListener(_handleSelectionChanged);
      widget.contentController.addListener(_handleSelectionChanged);
    }
  }

  @override
  void dispose() {
    widget.contentController.removeListener(_handleSelectionChanged);
    super.dispose();
  }

  void _handleSelectionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = _plumoSelectionSnapshot(widget.contentController);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
      decoration: BoxDecoration(
        color: context.colors.cards,
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _FigmaGradientIconBox(icon: Icons.auto_awesome, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plumo, ton complice d’écriture',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tu choisis le passage, Plumo propose, tu gardes toujours le dernier mot.',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                tooltip: 'Fermer Plumo',
                icon: const Icon(Icons.close, size: 18),
                color: context.colors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PlumoSelectionCoach(selection: selection),
          const SizedBox(height: 12),
          _PlumoActionGrid(
            selectionReady: selection.isReady,
            pendingAction: _pendingAction,
            onAction: _run,
            compact: false,
          ),
        ],
      ),
    );
  }

  Future<void> _run(_PlumoQuickAction action) async {
    if (_pendingAction != null) {
      return;
    }
    setState(() => _pendingAction = action);
    await _runPlumoQuickAction(
      context: context,
      ref: ref,
      action: action,
      contentController: widget.contentController,
      titleController: widget.titleController,
      onChanged: widget.onChanged,
    );
    if (mounted) {
      setState(() => _pendingAction = null);
    }
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
                        : context.colors.textSecondary,
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
                            : context.colors.textPrimary,
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
                            : context.colors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_vert,
                size: 14,
                color: selected ? Colors.white70 : context.colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FigmaPlumoButton extends StatelessWidget {
  const _FigmaPlumoButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.auto_awesome, size: 16),
      label: const Text('Plumo'),
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
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

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
          child: Icon(
            icon,
            size: 20,
            color: color ?? context.colors.textSecondary,
          ),
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
      color: context.colors.destructive.withValues(alpha: 0.08),
      child: Text(
        message,
        style: TextStyle(
          color: context.colors.destructive,
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
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        children: [
          Text(
            published ? '● Publié' : '● Brouillon',
            style: TextStyle(
              color: published ? _writeGreen : context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$wordCount mots - ~$readTime min lecture',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
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
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.chevron_right,
            size: 14,
            color: context.colors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            '$chapterIndex. $chapterTitle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
      decoration: BoxDecoration(
        color: context.colors.background,
        border: Border(top: BorderSide(color: context.colors.border)),
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
        decoration: BoxDecoration(
          color: context.colors.cards,
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
                        Text(
                          'Tous les chapitres',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_figmaBookTitle(book)} - ${chapters.length} chapitres',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.colors.textSecondary,
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
            Divider(height: 1, color: context.colors.border),
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
                        : context.colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.description_outlined,
                size: 18,
                color: selected ? Colors.white70 : context.colors.textSecondary,
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
                            : context.colors.textPrimary,
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
                            : context.colors.textSecondary,
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
          border: Border.all(color: context.colors.border, width: 1.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: context.colors.textSecondary),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textSecondary,
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
            style: TextStyle(color: context.colors.textSecondary, fontSize: 10),
          ),
          Text(
            _figmaChapterTitle(chapter),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.textPrimary,
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
          border: Border.all(color: context.colors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: trailing
              ? [
                  text,
                  Icon(icon, color: context.colors.textSecondary, size: 18),
                ]
              : [
                  Icon(icon, color: context.colors.textSecondary, size: 18),
                  text,
                ],
        ),
      ),
    );
  }
}

class _FigmaMobileWritingToolbar extends StatelessWidget {
  const _FigmaMobileWritingToolbar({required this.onPlumo});

  final VoidCallback onPlumo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          color: context.colors.cards,
          border: Border(top: BorderSide(color: context.colors.border)),
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
              onPressed: onPlumo,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Plumo'),
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
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

class _FigmaMobilePlumoPanel extends ConsumerStatefulWidget {
  const _FigmaMobilePlumoPanel({
    required this.onClose,
    required this.contentController,
    required this.titleController,
    required this.onChanged,
  });

  final VoidCallback onClose;
  final quill.QuillController contentController;
  final TextEditingController titleController;
  final VoidCallback onChanged;

  @override
  ConsumerState<_FigmaMobilePlumoPanel> createState() =>
      _FigmaMobilePlumoPanelState();
}

class _FigmaMobilePlumoPanelState
    extends ConsumerState<_FigmaMobilePlumoPanel> {
  _PlumoQuickAction? _pendingAction;

  @override
  void initState() {
    super.initState();
    widget.contentController.addListener(_handleSelectionChanged);
  }

  @override
  void didUpdateWidget(covariant _FigmaMobilePlumoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contentController != widget.contentController) {
      oldWidget.contentController.removeListener(_handleSelectionChanged);
      widget.contentController.addListener(_handleSelectionChanged);
    }
  }

  @override
  void dispose() {
    widget.contentController.removeListener(_handleSelectionChanged);
    super.dispose();
  }

  void _handleSelectionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = _plumoSelectionSnapshot(widget.contentController);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.cards,
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const _FigmaGradientIconBox(icon: Icons.auto_awesome, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plumo',
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Ton passage, tes choix.',
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  tooltip: 'Fermer Plumo',
                  icon: const Icon(Icons.close, size: 20),
                  color: context.colors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _PlumoSelectionCoach(selection: selection, compact: true),
            const SizedBox(height: 10),
            _PlumoActionGrid(
              selectionReady: selection.isReady,
              pendingAction: _pendingAction,
              onAction: _run,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(_PlumoQuickAction action) async {
    if (_pendingAction != null) {
      return;
    }
    setState(() => _pendingAction = action);
    await _runPlumoQuickAction(
      context: context,
      ref: ref,
      action: action,
      contentController: widget.contentController,
      titleController: widget.titleController,
      onChanged: widget.onChanged,
    );
    if (mounted) {
      setState(() => _pendingAction = null);
    }
  }
}

class _PlumoSelectionSnapshot {
  const _PlumoSelectionSnapshot({
    required this.start,
    required this.end,
    required this.text,
    required this.selectionExists,
  });

  final int start;
  final int end;
  final String text;
  final bool selectionExists;

  String get trimmedText => text.trim();
  String get leadingWhitespace =>
      RegExp(r'^\s*').firstMatch(text)?.group(0) ?? '';
  String get trailingWhitespace =>
      RegExp(r'\s*$').firstMatch(text)?.group(0) ?? '';
  bool get hasWords => trimmedText.isNotEmpty;
  bool get isTooLong => trimmedText.length > plumoAiMaxInputChars;
  bool get isReady => selectionExists && hasWords && !isTooLong;
  int get wordCount => _figmaWordCount(trimmedText);
  int get characterCount => trimmedText.length;

  String replacementFor(String suggestion) {
    return '$leadingWhitespace${suggestion.trim()}$trailingWhitespace';
  }
}

class _PlumoSelectionCoach extends StatelessWidget {
  const _PlumoSelectionCoach({required this.selection, this.compact = false});

  final _PlumoSelectionSnapshot selection;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (selection.isReady) {
      return Container(
        key: const ValueKey('plumo-selection-ready'),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 11,
        ),
        decoration: BoxDecoration(
          color: context.colors.success.withValues(alpha: 0.09),
          border: Border.all(
            color: context.colors.success.withValues(alpha: 0.35),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: context.colors.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passage prêt pour Plumo ✨',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_plumoWordLabel(selection.wordCount)} sélectionnés · '
                    '${selection.characterCount} caractères',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '“${_plumoPreview(selection.trimmedText, 150)}”',
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final tooLong = selection.selectionExists && selection.isTooLong;
    final onlyWhitespace = selection.selectionExists && !selection.hasWords;
    final accent = tooLong ? context.colors.warning : context.colors.primary;
    final title = tooLong
        ? 'Raccourcis un peu ta sélection'
        : onlyWhitespace
        ? 'Sélectionne quelques mots'
        : 'Surligne un passage pour commencer';
    final message = tooLong
        ? '${selection.characterCount} caractères sélectionnés : Plumo accepte '
              'jusqu’à $plumoAiMaxInputChars caractères à la fois.'
        : onlyWhitespace
        ? 'Ta sélection ne contient que des espaces. Surligne une phrase ou un paragraphe.'
        : 'Dans l’éditeur, surligne la phrase ou le paragraphe à retravailler. '
              'Plumo ne touchera jamais tout le chapitre par surprise.';

    return Container(
      key: const ValueKey('plumo-selection-coach'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 11,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '1',
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
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

class _PlumoActionGrid extends StatelessWidget {
  const _PlumoActionGrid({
    required this.selectionReady,
    required this.pendingAction,
    required this.onAction,
    required this.compact,
  });

  final bool selectionReady;
  final _PlumoQuickAction? pendingAction;
  final ValueChanged<_PlumoQuickAction> onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact
            ? 2
            : constraints.maxWidth < 760
            ? 2
            : 5;
        final spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in _PlumoQuickAction.values)
              SizedBox(
                width: itemWidth,
                child: _PlumoActionCard(
                  action: action,
                  ready: selectionReady,
                  loading: pendingAction == action,
                  enabled: pendingAction == null,
                  onTap: () => onAction(action),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlumoActionCard extends StatelessWidget {
  const _PlumoActionCard({
    required this.action,
    required this.ready,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final _PlumoQuickAction action;
  final bool ready;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ready
        ? context.colors.primary
        : context.colors.textSecondary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '${action.label}. ${action.description}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('plumo-action-${action.name}'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(11),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: ready
                  ? context.colors.primary.withValues(alpha: 0.055)
                  : context.colors.muted.withValues(alpha: 0.42),
              border: Border.all(
                color: ready
                    ? context.colors.primary.withValues(alpha: 0.38)
                    : context.colors.border,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                if (loading)
                  const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(action.icon, size: 19, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ready
                              ? context.colors.textPrimary
                              : context.colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ready ? action.description : 'Sélection requise',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PlumoQuickAction {
  rewrite(
    'Reformuler',
    Icons.autorenew,
    'Même idée, plus fluide',
    'Reformule ce passage avec fluidité, sans changer son sens ni les événements.',
  ),
  improveStyle(
    'Améliorer le style',
    Icons.auto_fix_high,
    'Plus vivant et précis',
    'Améliore le style de ce passage sans changer son sens ni les événements.',
  ),
  summarize(
    'Résumer',
    Icons.short_text,
    'Aller à l’essentiel',
    'Résume fidèlement ce passage en conservant les informations importantes.',
  ),
  continueStory(
    'Continuer l’histoire',
    Icons.fast_forward,
    'Imaginer la suite',
    'Continue ce passage dans le même ton, sans contredire les éléments déjà présents.',
  ),
  titles(
    'Proposer des titres',
    Icons.title,
    'Nommer ce chapitre',
    'Propose des titres évocateurs pour le chapitre à partir de ce passage.',
  );

  const _PlumoQuickAction(
    this.label,
    this.icon,
    this.description,
    this.instruction,
  );

  final String label;
  final IconData icon;
  final String description;
  final String instruction;
}

_PlumoSelectionSnapshot _plumoSelectionSnapshot(
  quill.QuillController controller,
) {
  final plainText = _figmaControllerPlainText(controller);
  final selection = controller.selection;
  if (!selection.isValid || selection.isCollapsed) {
    final cursor = selection.isValid
        ? selection.extentOffset.clamp(0, plainText.length)
        : 0;
    return _PlumoSelectionSnapshot(
      start: cursor,
      end: cursor,
      text: '',
      selectionExists: false,
    );
  }

  final start = selection.start.clamp(0, plainText.length);
  final end = selection.end.clamp(start, plainText.length);
  return _PlumoSelectionSnapshot(
    start: start,
    end: end,
    text: plainText.substring(start, end),
    selectionExists: end > start,
  );
}

String _plumoWordLabel(int count) => count == 1 ? '1 mot' : '$count mots';

String _plumoPreview(String text, int maxCharacters) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxCharacters) {
    return normalized;
  }
  return '${normalized.substring(0, maxCharacters).trimRight()}…';
}

class _PlumoQuickResult {
  const _PlumoQuickResult({
    this.suggestion,
    this.titles = const [],
    this.explanation = '',
    this.warnings = const [],
  });

  final String? suggestion;
  final List<String> titles;
  final String explanation;
  final List<String> warnings;
}

/// Runs a quick Plumo IA action only on the passage explicitly selected by
/// the author and shows the result in a bottom sheet.
/// Never touches [contentController]/[titleController] itself -- only the
/// sheet's Remplacer/Insérer/Utiliser buttons do, and only once the user taps
/// them, per the "never auto-apply" rule.
Future<void> _runPlumoQuickAction({
  required BuildContext context,
  required WidgetRef ref,
  required _PlumoQuickAction action,
  required quill.QuillController contentController,
  required TextEditingController titleController,
  required VoidCallback onChanged,
}) async {
  final selection = _plumoSelectionSnapshot(contentController);
  final plainText = _figmaControllerPlainText(contentController);
  if (!selection.selectionExists || !selection.hasWords) {
    if (context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Commence par surligner le passage que tu veux retravailler.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }

  if (selection.isTooLong) {
    if (context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Cette sélection est trop longue. Choisis un passage plus court pour aider Plumo à être précis.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }

  final start = selection.start;
  final end = selection.end;
  final sourceText = selection.trimmedText;

  final repository = ref.read(plumoAiRepositoryProvider);
  final request = AiWritingRequest(
    text: sourceText,
    instruction: action.instruction,
  );

  Future<_PlumoQuickResult> load() async {
    switch (action) {
      case _PlumoQuickAction.rewrite:
      case _PlumoQuickAction.improveStyle:
        final result = await repository.rewriteText(request);
        return _PlumoQuickResult(
          suggestion: result.suggestion,
          explanation: result.explanation,
          warnings: result.warnings,
        );
      case _PlumoQuickAction.summarize:
        final result = await repository.summarizeText(request);
        return _PlumoQuickResult(
          suggestion: result.suggestion,
          explanation: result.explanation,
          warnings: result.warnings,
        );
      case _PlumoQuickAction.continueStory:
        final result = await repository.continueText(request);
        return _PlumoQuickResult(
          suggestion: result.suggestion,
          explanation: result.explanation,
          warnings: result.warnings,
        );
      case _PlumoQuickAction.titles:
        final result = await repository.suggestTitles(request);
        return _PlumoQuickResult(
          titles: result.titles,
          explanation: result.explanation,
          warnings: result.warnings,
        );
    }
  }

  final resultFuture = load();
  if (!context.mounted) {
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _PlumoResultSheet(
      action: action,
      sourceText: sourceText,
      initialFuture: resultFuture,
      onRegenerate: load,
      onReplace: (text) {
        final replacement = selection.replacementFor(text);
        contentController.replaceText(
          start,
          end - start,
          replacement,
          TextSelection.collapsed(offset: start + replacement.length),
        );
        onChanged();
        _showPlumoAppliedSnackBar(
          context,
          message: 'Passage remplacé par la proposition de Plumo.',
          onUndo: () {
            contentController.undo();
            onChanged();
          },
        );
      },
      onInsertAfter: (text) {
        final insertAt = end;
        final separator = insertAt == 0 ? '' : '\n\n';
        final trailingSeparator = insertAt < plainText.length ? '\n\n' : '';
        final insertedText = '$separator${text.trim()}$trailingSeparator';
        contentController.replaceText(
          insertAt,
          0,
          insertedText,
          TextSelection.collapsed(offset: insertAt + insertedText.length),
        );
        onChanged();
        _showPlumoAppliedSnackBar(
          context,
          message: 'Proposition ajoutée après le passage sélectionné.',
          onUndo: () {
            contentController.undo();
            onChanged();
          },
        );
      },
      onUseAsTitle: (text) {
        final previousTitle = titleController.text;
        titleController.text = text;
        onChanged();
        _showPlumoAppliedSnackBar(
          context,
          message: 'Titre du chapitre mis à jour.',
          onUndo: () {
            titleController.text = previousTitle;
            onChanged();
          },
        );
      },
    ),
  );
}

void _showPlumoAppliedSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  if (!context.mounted) {
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(label: 'Annuler', onPressed: onUndo),
    ),
  );
}

class _PlumoResultSheet extends StatefulWidget {
  const _PlumoResultSheet({
    required this.action,
    required this.sourceText,
    required this.initialFuture,
    required this.onRegenerate,
    required this.onReplace,
    required this.onInsertAfter,
    required this.onUseAsTitle,
  });

  final _PlumoQuickAction action;
  final String sourceText;
  final Future<_PlumoQuickResult> initialFuture;
  final Future<_PlumoQuickResult> Function() onRegenerate;
  final ValueChanged<String> onReplace;
  final ValueChanged<String> onInsertAfter;
  final ValueChanged<String> onUseAsTitle;

  @override
  State<_PlumoResultSheet> createState() => _PlumoResultSheetState();
}

class _PlumoResultSheetState extends State<_PlumoResultSheet> {
  late Future<_PlumoQuickResult> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.initialFuture;
  }

  void _regenerate() {
    setState(() => _future = widget.onRegenerate());
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.cards,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: FutureBuilder<_PlumoQuickResult>(
            future: _future,
            builder: (context, snapshot) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: context.colors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const _FigmaGradientIconBox(
                        icon: Icons.auto_awesome,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.action.label,
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 18),
                        color: context.colors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: _buildBody(context, snapshot),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<_PlumoQuickResult> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 38),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Plumo cherche la bonne formule…',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (snapshot.hasError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.destructive.withValues(alpha: 0.06),
          border: Border.all(
            color: context.colors.destructive.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plumo a perdu le fil',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              plumoAiErrorMessage(snapshot.error!),
              style: TextStyle(color: context.colors.destructive),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _regenerate,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final result = snapshot.data!;
    if (widget.action == _PlumoQuickAction.titles) {
      if (result.titles.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlumoOriginalPassageCard(text: widget.sourceText),
            const SizedBox(height: 14),
            Text(
              "Plumo n'a proposé aucun titre.",
              style: TextStyle(color: context.colors.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _regenerate,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Essayer à nouveau'),
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlumoOriginalPassageCard(text: widget.sourceText),
          const SizedBox(height: 16),
          Text(
            'Les idées de Plumo',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final title in result.titles) ...[
            _PlumoTitleTile(
              title: title,
              onUseAsTitle: () {
                widget.onUseAsTitle(title);
                Navigator.of(context).pop();
              },
              onCopy: () => _copy(title),
            ),
            const SizedBox(height: 8),
          ],
          if (result.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Pourquoi ces titres ?',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.explanation,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          ..._warningWidgets(context, result.warnings),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _regenerate,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('D’autres idées'),
          ),
        ],
      );
    }

    final suggestion = result.suggestion ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlumoOriginalPassageCard(text: widget.sourceText),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 17, color: context.colors.primary),
            const SizedBox(width: 7),
            Text(
              'Proposition de Plumo',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.06),
            border: Border.all(
              color: context.colors.primary.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            suggestion.isEmpty
                ? "Plumo n'a renvoyé aucune suggestion."
                : suggestion,
            style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600),
          ),
        ),
        if (result.explanation.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Ce que Plumo a travaillé',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.explanation,
            style: TextStyle(color: context.colors.textSecondary, height: 1.4),
          ),
        ],
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final warning in result.warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 15,
                    color: context.colors.accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      warning,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (suggestion.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildApplyButtons(context, suggestion),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: _regenerate,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Une autre version'),
              ),
              TextButton.icon(
                onPressed: () => _editBeforeApplying(context, suggestion),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Ajuster'),
              ),
              TextButton.icon(
                onPressed: () => _copy(suggestion),
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Copier'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 14,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Rien ne change dans ton chapitre sans ton accord.',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildApplyButtons(BuildContext context, String suggestion) {
    void replace() {
      widget.onReplace(suggestion);
      Navigator.of(context).pop();
    }

    void insert() {
      widget.onInsertAfter(suggestion);
      Navigator.of(context).pop();
    }

    if (widget.action == _PlumoQuickAction.continueStory) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: insert,
          icon: const Icon(Icons.playlist_add, size: 18),
          label: const Text('Ajouter la suite'),
        ),
      );
    }

    final summarize = widget.action == _PlumoQuickAction.summarize;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: summarize ? insert : replace,
            icon: Icon(
              summarize ? Icons.playlist_add : Icons.find_replace,
              size: 18,
            ),
            label: Text(
              summarize ? 'Insérer le résumé' : 'Remplacer la sélection',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: summarize ? replace : insert,
            icon: Icon(
              summarize ? Icons.find_replace : Icons.playlist_add,
              size: 18,
            ),
            label: Text(summarize ? 'Remplacer la sélection' : 'Insérer après'),
          ),
        ),
      ],
    );
  }

  Future<void> _editBeforeApplying(
    BuildContext sheetContext,
    String suggestion,
  ) async {
    final controller = TextEditingController(text: suggestion);
    final modified = await showDialog<String>(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajuster la proposition'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 5,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'Modifie librement la proposition de Plumo…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(
              widget.action == _PlumoQuickAction.continueStory ||
                      widget.action == _PlumoQuickAction.summarize
                  ? 'Ajouter au chapitre'
                  : 'Remplacer la sélection',
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (modified == null || modified.trim().isEmpty || !mounted) {
      return;
    }
    if (widget.action == _PlumoQuickAction.continueStory ||
        widget.action == _PlumoQuickAction.summarize) {
      widget.onInsertAfter(modified.trim());
    } else {
      widget.onReplace(modified.trim());
    }
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }
  }

  List<Widget> _warningWidgets(BuildContext context, List<String> warnings) {
    if (warnings.isEmpty) {
      return const [];
    }
    return [
      const SizedBox(height: 12),
      for (final warning in warnings)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 15, color: context.colors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  warning,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}

class _PlumoOriginalPassageCard extends StatelessWidget {
  const _PlumoOriginalPassageCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.format_quote,
              size: 17,
              color: context.colors.textSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              'Passage original',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              _plumoWordLabel(_figmaWordCount(text)),
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.muted.withValues(alpha: 0.55),
            border: Border.all(color: context.colors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _plumoPreview(text, 420),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlumoTitleTile extends StatelessWidget {
  const _PlumoTitleTile({
    required this.title,
    required this.onUseAsTitle,
    required this.onCopy,
  });

  final String title;
  final VoidCallback onUseAsTitle;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, size: 18),
            tooltip: 'Copier',
          ),
          TextButton(onPressed: onUseAsTitle, child: const Text('Utiliser')),
        ],
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

  final quill.QuillController controller;
  final int activeIndex;
  final int chaptersLength;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final text = _figmaControllerPlainText(controller);
        final words = _figmaWordCount(text);
        final readTime = _figmaReadTimeMinutes(words);
        final chapterCount = chaptersLength <= 0 ? 1 : chaptersLength;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: context.colors.cards,
            border: Border(top: BorderSide(color: context.colors.border)),
          ),
          child: Row(
            children: [
              _FigmaStatsText(label: '$words', suffix: 'mots'),
              const SizedBox(width: 18),
              _FigmaStatsText(label: '${text.length}', suffix: 'car.'),
              const SizedBox(width: 18),
              Text(
                '~$readTime min lecture',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 18),
              Text(
                'Chapitre ${activeIndex + 1}/$chapterCount',
                style: TextStyle(
                  color: context.colors.textSecondary,
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
            style: TextStyle(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: ' $suffix'),
        ],
      ),
      style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
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
  final words = PlumoraDocumentCodec.wordCount(chapter.content);
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
      PlumoraDocumentCodec.hasMeaningfulContent(chapter.content);
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

/// The chapter to open by default when arriving without a specific
/// selection (e.g. tapping "Écrire" from the story list): the one most
/// recently worked on, not simply the first by chapter order.
ChapterModel _mostRecentlyEditedChapter(List<ChapterModel> chapters) {
  return chapters.reduce((a, b) {
    final aTime = a.updatedAt ?? a.createdAt;
    final bTime = b.updatedAt ?? b.createdAt;
    if (aTime == null) return b;
    if (bTime == null) return a;
    return aTime.isAfter(bTime) ? a : b;
  });
}

int _figmaWordCount(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .length;
}

String _figmaControllerPlainText(quill.QuillController controller) {
  return PlumoraDocumentCodec.plainTextFromDocument(controller.document);
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

class _EditorStateWithBack extends StatelessWidget {
  const _EditorStateWithBack({required this.onBack, required this.child});

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: FigmaBackButton(label: 'Retour', onTap: onBack),
        ),
        Expanded(child: child),
      ],
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
            'Éditeur indisponible',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: context.colors.textSecondary)),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
