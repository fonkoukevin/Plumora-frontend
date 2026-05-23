import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
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
  AiWritingActionType _selectedAction = AiWritingActionType.improveStyle;
  AiWritingSuggestionModel? _suggestion;
  bool _isLoading = false;
  bool _isMutatingSuggestion = false;
  String? _error;

  @override
  void dispose() {
    _selectedTextController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.editor);
                            }
                          },
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text("Retour à l'éditeur"),
                  ),
                  const SizedBox(height: 18),
                  _Header(chapterId: widget.chapterId),
                  const SizedBox(height: 26),
                  LayoutBuilder(
                    builder: (context, innerConstraints) {
                      final isWide = innerConstraints.maxWidth >= 820;
                      final left = _RequestPanel(
                        selectedTextController: _selectedTextController,
                        contextController: _contextController,
                        selectedAction: _selectedAction,
                        isLoading: _isLoading,
                        error: _error,
                        onActionChanged: (action) {
                          setState(() => _selectedAction = action);
                        },
                        onSubmit: _requestSuggestion,
                      );
                      final right = _SuggestionPanel(
                        suggestion: _suggestion,
                        isBusy: _isMutatingSuggestion,
                        onAccept: _acceptSuggestion,
                        onModify: _modifySuggestion,
                        onIgnore: _ignoreSuggestion,
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: left),
                            const SizedBox(width: 20),
                            Expanded(child: right),
                          ],
                        );
                      }

                      return Column(
                        children: [left, const SizedBox(height: 18), right],
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

  Future<void> _requestSuggestion() async {
    final selectedText = _selectedTextController.text.trim();
    if (selectedText.isEmpty) {
      setState(() => _error = 'Ajoute un extrait à améliorer.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final suggestion = await ref
          .read(aiRepositoryProvider)
          .requestWritingSuggestion(
            AiWritingSuggestionRequest(
              selectedText: selectedText,
              actionType: _selectedAction,
              chapterId: widget.chapterId,
              contextText: _contextController.text,
            ),
          );
      setState(() => _suggestion = suggestion);
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptSuggestion() {
    return _mutateSuggestion((suggestion) {
      if (suggestion.id.isEmpty) {
        return Future.value(
          suggestion.copyWith(status: AiSuggestionStatus.accepted),
        );
      }
      return ref.read(aiRepositoryProvider).acceptSuggestion(suggestion.id);
    });
  }

  Future<void> _ignoreSuggestion() {
    return _mutateSuggestion((suggestion) {
      if (suggestion.id.isEmpty) {
        return Future.value(
          suggestion.copyWith(status: AiSuggestionStatus.ignored),
        );
      }
      return ref.read(aiRepositoryProvider).ignoreSuggestion(suggestion.id);
    });
  }

  Future<void> _modifySuggestion() async {
    final suggestion = _suggestion;
    if (suggestion == null) {
      return;
    }

    final controller = TextEditingController(text: suggestion.suggestionText);
    final modifiedText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la suggestion'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Ajuste la proposition de Mukeme...',
          ),
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

    if (modifiedText == null || modifiedText.trim().isEmpty) {
      return;
    }

    await _mutateSuggestion((suggestion) {
      if (suggestion.id.isEmpty) {
        return Future.value(
          suggestion.copyWith(
            suggestionText: modifiedText,
            status: AiSuggestionStatus.modified,
          ),
        );
      }
      return ref
          .read(aiRepositoryProvider)
          .modifySuggestion(suggestion.id, modifiedText);
    });
  }

  Future<void> _mutateSuggestion(
    Future<AiWritingSuggestionModel> Function(AiWritingSuggestionModel)
    mutation,
  ) async {
    final current = _suggestion;
    if (current == null) {
      return;
    }

    setState(() {
      _isMutatingSuggestion = true;
      _error = null;
    });

    try {
      final updated = await mutation(current);
      setState(() => _suggestion = updated);
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isMutatingSuggestion = false);
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.chapterId});

  final String? chapterId;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      borderColor: const Color(0xFFDCCDEC),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlumoraIconTile(
            backgroundColor: Color(0xFFEADCF7),
            child: Icon(Icons.auto_awesome, color: PlumoraColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Améliore ton texte avec Mukeme',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: PlumoraColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  chapterId == null || chapterId!.trim().isEmpty
                      ? 'Sélectionne une action et laisse Mukeme proposer une amélioration.'
                      : 'Suggestion liée au chapitre en cours.',
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    height: 1.45,
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

class _RequestPanel extends StatelessWidget {
  const _RequestPanel({
    required this.selectedTextController,
    required this.contextController,
    required this.selectedAction,
    required this.isLoading,
    required this.onActionChanged,
    required this.onSubmit,
    this.error,
  });

  final TextEditingController selectedTextController;
  final TextEditingController contextController;
  final AiWritingActionType selectedAction;
  final bool isLoading;
  final ValueChanged<AiWritingActionType> onActionChanged;
  final VoidCallback onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Texte sélectionné',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: selectedTextController,
            minLines: 5,
            maxLines: 8,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText:
                  'Colle ici la phrase ou le paragraphe que Mukeme doit retravailler.',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Contexte optionnel',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: contextController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Ex: ambiance, personnage, intention de la scène...',
            ),
          ),
          const SizedBox(height: 18),
          const Text('Action', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final action in AiWritingActionType.values)
                ChoiceChip(
                  avatar: Icon(_actionIcon(action), size: 17),
                  label: Text(action.label),
                  selected: selectedAction == action,
                  onSelected: isLoading ? null : (_) => onActionChanged(action),
                ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            _InlineError(message: error!),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: isLoading ? null : onSubmit,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(
              isLoading ? 'Mukeme réfléchit...' : 'Demander à Mukeme',
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({
    required this.suggestion,
    required this.isBusy,
    required this.onAccept,
    required this.onModify,
    required this.onIgnore,
  });

  final AiWritingSuggestionModel? suggestion;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onModify;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    final currentSuggestion = suggestion;
    if (currentSuggestion == null) {
      return const PlumoraCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 54),
          child: Column(
            children: [
              PlumoraIconTile(
                backgroundColor: PlumoraColors.muted,
                size: 72,
                child: Icon(
                  Icons.auto_awesome,
                  color: PlumoraColors.textSecondary,
                  size: 34,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Choisis une action',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8),
              Text(
                'La suggestion de Mukeme apparaîtra ici.',
                textAlign: TextAlign.center,
                style: TextStyle(color: PlumoraColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: PlumoraColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Suggestion de Mukeme',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              PlumoraBadge(label: _statusLabel(currentSuggestion.status)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4E8FF),
              borderRadius: BorderRadius.circular(14),
              border: const Border(
                left: BorderSide(color: PlumoraColors.primary, width: 4),
              ),
            ),
            child: Text(
              currentSuggestion.suggestionText.isEmpty
                  ? 'Mukeme n’a pas renvoyé de texte.'
                  : currentSuggestion.suggestionText,
              style: const TextStyle(height: 1.55),
            ),
          ),
          if (currentSuggestion.explanation.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              currentSuggestion.explanation,
              style: const TextStyle(
                color: PlumoraColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: isBusy ? null : onAccept,
                icon: const Icon(Icons.check, size: 17),
                label: Text(isBusy ? '...' : 'Accepter'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onModify,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Modifier'),
              ),
              TextButton.icon(
                onPressed: isBusy ? null : onIgnore,
                icon: const Icon(Icons.close, size: 17),
                label: const Text('Ignorer'),
              ),
            ],
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

IconData _actionIcon(AiWritingActionType action) {
  return switch (action) {
    AiWritingActionType.reformulate => Icons.refresh,
    AiWritingActionType.improveStyle => Icons.auto_fix_high_outlined,
    AiWritingActionType.fixRepetitions => Icons.repeat,
    AiWritingActionType.makeMoreEmotional => Icons.favorite_border,
    AiWritingActionType.makeDialogueNatural => Icons.forum_outlined,
  };
}

String _statusLabel(AiSuggestionStatus status) {
  return switch (status) {
    AiSuggestionStatus.pending => 'En attente',
    AiSuggestionStatus.accepted => 'Acceptée',
    AiSuggestionStatus.modified => 'Modifiée',
    AiSuggestionStatus.ignored => 'Ignorée',
    AiSuggestionStatus.unknown => 'Suggestion',
  };
}
