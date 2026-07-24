import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../data/models/report_model.dart';
import '../data/repositories/report_repository.dart';

/// Opens the "Signaler ce livre" bottom sheet. Returns `true` once the
/// report has been created, `false`/`null` if the user cancelled or closed
/// it without submitting — the caller is expected to show a success message
/// on `true` and do nothing otherwise (this sheet already surfaces its own
/// validation/submission errors inline).
Future<bool?> showReportBookDialog(BuildContext context, String bookId) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ReportBookBottomSheet(bookId: bookId),
  );
}

class ReportBookBottomSheet extends ConsumerStatefulWidget {
  const ReportBookBottomSheet({required this.bookId, super.key});

  final String bookId;

  @override
  ConsumerState<ReportBookBottomSheet> createState() =>
      _ReportBookBottomSheetState();
}

class _ReportBookBottomSheetState extends ConsumerState<ReportBookBottomSheet> {
  final _descriptionController = TextEditingController();
  ReportReason? _selectedReason;
  bool _isSubmitting = false;
  String? _reasonError;
  String? _descriptionError;
  String? _submitError;

  static const _maxDescriptionLength = 1000;
  static const _minDescriptionLengthWhenRequired = 10;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.escape): () {
          if (!_isSubmitting) {
            Navigator.of(context).pop(false);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        PlumoraIconTile(
                          backgroundColor: context.colors.destructive
                              .withValues(alpha: 0.12),
                          size: 44,
                          child: Icon(
                            Icons.flag_outlined,
                            color: context.colors.destructive,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Signaler ce livre',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Fermer',
                          child: IconButton(
                            tooltip: 'Fermer',
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(false),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Votre signalement sera examiné par un administrateur.',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Motif',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 480 ? 2 : 1;
                        const spacing = 10.0;
                        final width =
                            (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final reason in ReportReason.values)
                              SizedBox(
                                width: width,
                                child: _ReasonTile(
                                  reason: reason,
                                  selected: _selectedReason == reason,
                                  onTap: _isSubmitting
                                      ? null
                                      : () => setState(() {
                                          _selectedReason = reason;
                                          _reasonError = null;
                                        }),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    if (_reasonError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _reasonError!,
                        style: TextStyle(
                          color: context.colors.destructive,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    TextField(
                      controller: _descriptionController,
                      enabled: !_isSubmitting,
                      maxLines: 5,
                      minLines: 3,
                      maxLength: _maxDescriptionLength,
                      onChanged: (_) {
                        if (_descriptionError != null) {
                          setState(() => _descriptionError = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: _selectedReason?.requiresDescription ?? false
                            ? 'Description (obligatoire)'
                            : 'Description (facultative)',
                        hintText:
                            'Explique en quelques mots ce qui pose problème...',
                        errorText: _descriptionError,
                      ),
                    ),
                    if (_submitError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _submitError!,
                        style: TextStyle(
                          color: context.colors.destructive,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: context.colors.destructive,
                              foregroundColor: context.colors.onDestructive,
                              minimumSize: const Size(0, 44),
                            ),
                            icon: _isSubmitting
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.colors.onDestructive,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined, size: 18),
                            label: Text(
                              _isSubmitting
                                  ? 'Envoi...'
                                  : 'Envoyer le signalement',
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
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final reason = _selectedReason;
    final description = _descriptionController.text.trim();

    setState(() {
      _reasonError = reason == null ? 'Choisis un motif de signalement.' : null;
      _descriptionError =
          (reason?.requiresDescription ?? false) &&
              description.length < _minDescriptionLengthWhenRequired
          ? 'Précise ce motif (10 caractères minimum).'
          : null;
    });

    if (reason == null || _reasonError != null || _descriptionError != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await ref
          .read(reportRepositoryProvider)
          .createReport(
            widget.bookId,
            ReportCreateRequest(
              reason: reason,
              description: description.isEmpty ? null : description,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _submitError = _reportErrorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

String _reportErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.response?.statusCode) {
      case 401:
        return 'Votre session a expiré. Veuillez vous reconnecter.';
      case 403:
        return "Vous n'êtes pas autorisé à effectuer cette action.";
      case 404:
        return 'Ce livre n\'est plus disponible.';
      case 409:
        return 'Vous avez déjà signalé ce livre.';
    }

    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Impossible de transmettre le signalement. Vérifiez votre connexion.';
      default:
        if (error.response != null) {
          return 'Une erreur est survenue. Réessayez plus tard.';
        }
    }
  }

  return AppError.messageFor(error);
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final ReportReason reason;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.destructive;

    return Semantics(
      button: true,
      selected: selected,
      label: reason.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.1)
                : context.colors.cards,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : context.colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(_reasonIcon(reason), color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reason.label,
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
      ),
    );
  }
}

IconData _reasonIcon(ReportReason reason) {
  return switch (reason) {
    ReportReason.inappropriateContent => Icons.report_gmailerrorred_outlined,
    ReportReason.harassment => Icons.front_hand_outlined,
    ReportReason.hateSpeech => Icons.record_voice_over_outlined,
    ReportReason.plagiarism => Icons.copy_all_outlined,
    ReportReason.copyright => Icons.gavel_outlined,
    ReportReason.misleadingInformation => Icons.error_outline,
    ReportReason.other => Icons.more_horiz,
  };
}
