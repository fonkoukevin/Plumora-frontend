import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../book/data/models/chapter_model.dart';
import '../../book/data/repositories/chapter_repository.dart';
import '../data/models/ai_models.dart';
import '../data/repositories/ai_repository.dart';

class MukemeWritingScreen extends ConsumerStatefulWidget {
  const MukemeWritingScreen({this.chapterId, super.key});

  final String? chapterId;

  @override
  ConsumerState<MukemeWritingScreen> createState() =>
      _MukemeWritingScreenState();
}

class _MukemeWritingScreenState extends ConsumerState<MukemeWritingScreen> {
  final _selectedTextController = TextEditingController();
  final _contextController = TextEditingController();
  AiWritingActionType? _selectedAction;
  AiWritingSuggestionModel? _suggestion;
  String? _hydratedChapterId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _selectedTextController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ChapterModel?> chapterAsync = widget.chapterId == null
        ? const AsyncValue<ChapterModel?>.data(null)
        : ref
              .watch(chapterProvider(widget.chapterId!))
              .whenData((chapter) => chapter);

    return chapterAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.colors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ScaffoldError(
        message: AppError.messageFor(error),
        onRetry: () => ref.invalidate(chapterProvider(widget.chapterId!)),
      ),
      data: (chapter) {
        if (chapter != null) {
          _hydrateChapter(chapter);
        }

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            backgroundColor: context.colors.cards,
            leading: IconButton(
              onPressed: () {
                if (chapter?.bookId.trim().isNotEmpty == true) {
                  context.go(AppRoutes.chapterEditorPath(chapter!.bookId));
                } else {
                  context.go(AppRoutes.editor);
                }
              },
              icon: const Icon(Icons.arrow_back),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FigmaGradientIcon(
                  icon: Icons.auto_awesome,
                  size: 40,
                  iconSize: 21,
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mukeme',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      "Assistant d'ecriture",
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            centerTitle: true,
          ),
          body: FigmaScreen(
            maxWidth: 1120,
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
            child: Column(
              children: [
                Text(
                  'Ameliore ton texte avec Mukeme',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  chapter == null
                      ? 'Colle un passage, choisis une action et envoie la demande au backend IA.'
                      : 'Chapitre charge : ${chapter.title.isEmpty ? "sans titre" : chapter.title}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 860;
                    final left = _ActionColumn(
                      selectedTextController: _selectedTextController,
                      contextController: _contextController,
                      selectedAction: _selectedAction,
                      loading: _loading,
                      onAction: _requestSuggestion,
                    );
                    final right = _SuggestionColumn(
                      suggestion: _suggestion,
                      loading: _loading,
                      error: _error,
                      onAccept: _suggestion == null ? null : _acceptSuggestion,
                      onModify: _suggestion == null ? null : _modifySuggestion,
                      onIgnore: _suggestion == null ? null : _ignoreSuggestion,
                    );

                    if (!wide) {
                      return Column(
                        children: [left, const SizedBox(height: 18), right],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 24),
                        Expanded(child: right),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hydrateChapter(ChapterModel chapter) {
    if (_hydratedChapterId == chapter.id) {
      return;
    }
    _hydratedChapterId = chapter.id;
    final content = chapter.content.trim();
    _selectedTextController.text = content.length <= 260
        ? content
        : '${content.substring(0, 260)}...';
    _contextController.text = chapter.content;
  }

  Future<void> _requestSuggestion(AiWritingActionType action) async {
    final selectedText = _selectedTextController.text.trim();
    if (selectedText.isEmpty) {
      setState(() => _error = 'Ajoute un passage a ameliorer.');
      return;
    }

    setState(() {
      _selectedAction = action;
      _loading = true;
      _error = null;
    });

    try {
      final suggestion = await ref
          .read(aiRepositoryProvider)
          .requestWritingSuggestion(
            AiWritingSuggestionRequest(
              selectedText: selectedText,
              actionType: action,
              chapterId: widget.chapterId,
              contextText: _contextController.text,
            ),
          );
      setState(() => _suggestion = suggestion);
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _acceptSuggestion() async {
    await _mutateSuggestion(
      (id) => ref.read(aiRepositoryProvider).acceptSuggestion(id),
    );
  }

  Future<void> _modifySuggestion() async {
    final suggestion = _suggestion;
    if (suggestion == null) {
      return;
    }
    final controller = TextEditingController(text: suggestion.suggestionText);
    final modified = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la suggestion'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Texte modifie'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (modified == null || modified.trim().isEmpty) {
      return;
    }

    await _mutateSuggestion(
      (id) => ref.read(aiRepositoryProvider).modifySuggestion(id, modified),
    );
  }

  Future<void> _ignoreSuggestion() async {
    await _mutateSuggestion(
      (id) => ref.read(aiRepositoryProvider).ignoreSuggestion(id),
      clearAfter: true,
    );
  }

  Future<void> _mutateSuggestion(
    Future<AiWritingSuggestionModel> Function(String suggestionId) action, {
    bool clearAfter = false,
  }) async {
    final suggestion = _suggestion;
    if (suggestion == null) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final updated = await action(suggestion.id);
      setState(() => _suggestion = clearAfter ? null : updated);
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class _ActionColumn extends StatelessWidget {
  const _ActionColumn({
    required this.selectedTextController,
    required this.contextController,
    required this.selectedAction,
    required this.loading,
    required this.onAction,
  });

  final TextEditingController selectedTextController;
  final TextEditingController contextController;
  final AiWritingActionType? selectedAction;
  final bool loading;
  final ValueChanged<AiWritingActionType> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FigmaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FigmaBadge(label: 'Texte selectionne'),
              const SizedBox(height: 14),
              TextField(
                controller: selectedTextController,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Colle ici le passage a ameliorer.',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: contextController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Contexte optionnel',
                  hintText: 'Ajoute le contexte du chapitre si besoin.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FigmaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actions disponibles',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final action in AiWritingActionType.values)
                    _ActionButton(
                      label: action.label,
                      icon: _actionIcon(action),
                      selected: selectedAction == action,
                      loading: loading && selectedAction == action,
                      onTap: () => onAction(action),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FigmaCard(
          color: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFBFDBFE),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, color: context.colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Mukeme est une aide a l'ecriture : chaque suggestion peut etre acceptee, modifiee ou ignoree.",
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuggestionColumn extends StatelessWidget {
  const _SuggestionColumn({
    required this.suggestion,
    required this.loading,
    required this.onAccept,
    required this.onModify,
    required this.onIgnore,
    this.error,
  });

  final AiWritingSuggestionModel? suggestion;
  final bool loading;
  final String? error;
  final VoidCallback? onAccept;
  final VoidCallback? onModify;
  final VoidCallback? onIgnore;

  @override
  Widget build(BuildContext context) {
    if (suggestion == null && !loading && error == null) {
      return FigmaCard(
        child: SizedBox(
          height: 360,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FigmaGradientIcon(
                  icon: Icons.auto_awesome,
                  size: 78,
                  iconSize: 38,
                  colors: [context.colors.muted, context.colors.border],
                ),
                SizedBox(height: 16),
                Text(
                  'Choisis une action',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'La suggestion du backend IA apparaitra ici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: context.colors.primary),
              SizedBox(width: 8),
              Text(
                'Suggestion de Mukeme',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(42),
                child: CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            Text(
              error!,
              style: TextStyle(
                color: context.colors.destructive,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (suggestion != null) ...[
            FigmaCard(
              color: context.colors.primary.withValues(alpha: 0.06),
              borderColor: context.colors.primary,
              shadow: false,
              child: Text(
                suggestion!.suggestionText,
                style: const TextStyle(
                  height: 1.45,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (suggestion!.explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                suggestion!.explanation,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check),
                    label: const Text('Accepter'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onModify,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onIgnore,
                icon: const Icon(Icons.close),
                label: const Text('Ignorer'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: context.colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaffoldError extends StatelessWidget {
  const _ScaffoldError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: FigmaCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mukeme indisponible',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Reessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _actionIcon(AiWritingActionType action) {
  return switch (action) {
    AiWritingActionType.reformulate => Icons.refresh,
    AiWritingActionType.improveStyle => Icons.auto_fix_high,
    AiWritingActionType.fixRepetitions => Icons.repeat,
    AiWritingActionType.makeMoreEmotional => Icons.favorite_border,
    AiWritingActionType.makeDialogueNatural => Icons.chat_bubble_outline,
  };
}
