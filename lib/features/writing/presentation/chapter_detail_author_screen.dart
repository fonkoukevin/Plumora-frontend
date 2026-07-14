import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../ai/data/models/plumo_ai_models.dart';
import '../../ai/data/plumo_ai_error.dart';
import '../../ai/data/repositories/plumo_ai_repository.dart';
import '../../book/data/models/chapter_model.dart';
import '../../book/data/repositories/book_repository.dart';
import '../../book/data/repositories/chapter_repository.dart';
import '../data/writing_cache_invalidator.dart';

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
      invalidateBookPublicationCaches(ref, bookId);
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
            foregroundColor: context.colors.textSecondary,
          ),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Retour'),
        ),
        const SizedBox(height: 24),
        Text(
          chapter.title.isEmpty ? 'Chapitre sans titre' : chapter.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chapitre ${chapter.order == 0 ? '-' : chapter.order} · ${chapter.content.length} caractères',
          style: TextStyle(color: context.colors.textSecondary),
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
                      foregroundColor: context.colors.destructive,
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
        const SizedBox(height: 18),
        _PlumoAnalysisCard(chapter: chapter),
      ],
    );
  }
}

class _PlumoAnalysisCard extends ConsumerStatefulWidget {
  const _PlumoAnalysisCard({required this.chapter});

  final ChapterModel chapter;

  @override
  ConsumerState<_PlumoAnalysisCard> createState() => _PlumoAnalysisCardState();
}

class _PlumoAnalysisCardState extends ConsumerState<_PlumoAnalysisCard> {
  bool _loading = false;
  String? _error;
  BetaReadingAnalysisResponse? _result;

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(plumoAiRepositoryProvider)
          .analyzeForBetaReading(
            BetaReadingAnalysisRequest(
              text: widget.chapter.content,
              chapterId: widget.chapter.id,
            ),
          );
      setState(() => _result = result);
    } catch (error) {
      setState(() => _error = plumoAiErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.chapter.content.trim().isNotEmpty;

    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: context.colors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Analyse Plumo',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (_result != null && !_loading)
                TextButton(onPressed: _analyze, child: const Text('Relancer')),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Demande à Plumo d'analyser ce chapitre avant de l'envoyer en bêta-lecture. Le texte reste inchangé, ce n'est qu'un avis.",
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (_error != null) ...[
            _InlineError(message: _error!),
            const SizedBox(height: 14),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_result == null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: hasContent ? _analyze : null,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Analyser avec Plumo'),
              ),
            )
          else
            _PlumoAnalysisResultView(result: _result!),
        ],
      ),
    );
  }
}

class _PlumoAnalysisResultView extends StatelessWidget {
  const _PlumoAnalysisResultView({required this.result});

  final BetaReadingAnalysisResponse result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.globalFeedback.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              result.globalFeedback,
              style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _PlumoScoreTile(label: 'Clarté', score: result.clarityScore),
            _PlumoScoreTile(label: 'Rythme', score: result.rhythmScore),
            _PlumoScoreTile(label: 'Cohérence', score: result.coherenceScore),
            _PlumoScoreTile(label: 'Personnages', score: result.characterScore),
          ],
        ),
        if (result.strengths.isNotEmpty) ...[
          const SizedBox(height: 16),
          _PlumoBulletSection(
            title: 'Points forts',
            icon: Icons.thumb_up_outlined,
            color: context.colors.success,
            items: result.strengths,
          ),
        ],
        if (result.weaknesses.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PlumoBulletSection(
            title: 'Points faibles',
            icon: Icons.thumb_down_outlined,
            color: context.colors.destructive,
            items: result.weaknesses,
          ),
        ],
        if (result.suggestions.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PlumoBulletSection(
            title: "Suggestions d'amélioration",
            icon: Icons.lightbulb_outline,
            color: context.colors.accent,
            items: result.suggestions,
          ),
        ],
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PlumoBulletSection(
            title: 'Avertissements',
            icon: Icons.warning_amber_outlined,
            color: context.colors.warning,
            items: result.warnings,
          ),
        ],
      ],
    );
  }
}

class _PlumoScoreTile extends StatelessWidget {
  const _PlumoScoreTile({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '/10',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlumoBulletSection extends StatelessWidget {
  const _PlumoBulletSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 22),
            child: Text(
              '• $item',
              style: TextStyle(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
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
            color: context.colors.cards,
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
                      color: context.colors.destructive.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: context.colors.destructive,
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
                          style: TextStyle(
                            color: context.colors.textSecondary,
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
        style: TextStyle(
          color: context.colors.textPrimary,
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
        color: context.colors.destructive.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
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
          Text(message, style: TextStyle(color: context.colors.textSecondary)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
