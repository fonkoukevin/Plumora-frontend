import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../data/models/beta_comment_model.dart';
import '../data/repositories/beta_reading_repository.dart';

class CreateBetaCommentBottomSheet extends ConsumerStatefulWidget {
  const CreateBetaCommentBottomSheet({
    required this.bookId,
    required this.campaignId,
    required this.chapterId,
    required this.defaultSelectedText,
    this.defaultPositionStart,
    this.defaultPositionEnd,
    super.key,
  });

  final String bookId;
  final String campaignId;
  final String chapterId;
  final String defaultSelectedText;
  final int? defaultPositionStart;
  final int? defaultPositionEnd;

  @override
  ConsumerState<CreateBetaCommentBottomSheet> createState() =>
      _CreateBetaCommentBottomSheetState();
}

class _CreateBetaCommentBottomSheetState
    extends ConsumerState<CreateBetaCommentBottomSheet> {
  final _commentController = TextEditingController();
  late final TextEditingController _selectedTextController;
  BetaCommentType? _selectedType;
  bool _isSubmitting = false;
  String? _error;

  static const _types = BetaCommentType.values;

  @override
  void initState() {
    super.initState();
    _selectedTextController = TextEditingController(
      text: widget.defaultSelectedText,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _selectedTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    PlumoraIconTile(
                      backgroundColor: context.colors.info.withValues(
                        alpha: 0.12,
                      ),
                      size: 44,
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: context.colors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ajouter un commentaire',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _selectedTextController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Passage concerné',
                    hintText: 'Copie ici le passage que tu veux commenter.',
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Type de retour',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 520 ? 3 : 2;
                    const spacing = 10.0;
                    final width =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final type in _types)
                          SizedBox(
                            width: width,
                            child: _TypeButton(
                              type: type,
                              selected: _selectedType == type,
                              onTap: () => setState(() => _selectedType = type),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _commentController,
                  maxLines: 5,
                  minLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Votre commentaire',
                    hintText:
                        "Ce passage arrive trop vite, on ne comprend pas la décision du personnage.",
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: context.colors.destructive,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          _isSubmitting ? 'Envoi...' : 'Envoyer le retour',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final type = _selectedType;
    final comment = _commentController.text.trim();

    if (type == null || comment.isEmpty) {
      setState(() {
        _error = 'Choisis un type de retour et ajoute un commentaire.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final selectedTextUnedited =
        _selectedTextController.text.trim() ==
        widget.defaultSelectedText.trim();

    try {
      await ref
          .read(betaReadingRepositoryProvider)
          .createComment(
            BetaCommentCreateRequest(
              bookId: widget.bookId,
              campaignId: widget.campaignId,
              chapterId: widget.chapterId,
              type: type,
              content: comment,
              selectedText: _selectedTextController.text,
              positionStart: selectedTextUnedited
                  ? widget.defaultPositionStart
                  : null,
              positionEnd: selectedTextUnedited
                  ? widget.defaultPositionEnd
                  : null,
            ),
          );
      ref.invalidate(betaSharedChaptersProvider(widget.campaignId));
      if (widget.bookId.isNotEmpty) {
        ref.invalidate(betaCommentsForBookProvider(widget.bookId));
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final BetaCommentType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(context, type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : context.colors.cards,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : context.colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(_typeIcon(type), color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textPrimary,
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

IconData _typeIcon(BetaCommentType type) {
  return switch (type) {
    BetaCommentType.plot => Icons.auto_stories_outlined,
    BetaCommentType.character => Icons.person_outline,
    BetaCommentType.style => Icons.auto_fix_high_outlined,
    BetaCommentType.pacing => Icons.schedule,
    BetaCommentType.continuity => Icons.sync_problem_outlined,
    BetaCommentType.typo => Icons.spellcheck,
    BetaCommentType.other => Icons.chat_bubble_outline,
  };
}

Color _typeColor(BuildContext context, BetaCommentType type) {
  return switch (type) {
    BetaCommentType.plot => const Color(0xFFB42318),
    BetaCommentType.character => const Color(0xFF2563EB),
    BetaCommentType.style => const Color(0xFF8B5CF6),
    BetaCommentType.pacing => const Color(0xFFC69200),
    BetaCommentType.continuity => const Color(0xFFA4683E),
    BetaCommentType.typo => context.colors.info,
    BetaCommentType.other => context.colors.textSecondary,
  };
}
