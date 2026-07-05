import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/repositories/book_repository.dart';

class CreateBookScreen extends ConsumerStatefulWidget {
  const CreateBookScreen({this.bookId, super.key});

  final String? bookId;

  @override
  ConsumerState<CreateBookScreen> createState() => _CreateBookScreenState();
}

class _CreateBookScreenState extends ConsumerState<CreateBookScreen> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  String _genre = '';
  String _visibility = 'PRIVATE';
  String? _hydratedBookId;
  bool _isSubmitting = false;
  String? _error;

  bool get _editing =>
      widget.bookId != null && widget.bookId!.trim().isNotEmpty;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BookModel?> bookAsync = _editing
        ? ref.watch(authorBookProvider(widget.bookId!)).whenData((book) => book)
        : const AsyncValue.data(null);

    return bookAsync.when(
      loading: () => const FigmaScreen(
        maxWidth: 780,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, _) => FigmaScreen(
        maxWidth: 780,
        padding: const EdgeInsets.fromLTRB(16, 26, 16, 92),
        child: _ErrorPanel(
          message: AppError.messageFor(error),
          onRetry: () => ref.invalidate(authorBookProvider(widget.bookId!)),
        ),
      ),
      data: (book) {
        if (book != null) {
          _hydrateFrom(book);
        }

        return FigmaScreen(
          maxWidth: 780,
          padding: const EdgeInsets.fromLTRB(16, 26, 16, 92),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FigmaBackButton(
                label: 'Retour',
                onTap: () => context.go(AppRoutes.write),
              ),
              const SizedBox(height: 18),
              Text(
                _editing ? 'Modifier le livre' : 'Creer un nouveau livre',
                style: const TextStyle(
                  color: PlumoraColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Les informations enregistrees ici alimentent directement le backend Plumora.',
                style: TextStyle(
                  color: PlumoraColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 26),
              FigmaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Labelled(
                      label: 'Titre du livre',
                      child: TextField(
                        controller: _titleController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Ex: La Nuit Rouge',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Labelled(
                      label: 'Genre',
                      child: DropdownButtonFormField<String>(
                        initialValue: _genre.isEmpty ? null : _genre,
                        hint: const Text('Selectionner un genre'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Fantasy',
                            child: Text('Fantasy'),
                          ),
                          DropdownMenuItem(
                            value: 'Romance',
                            child: Text('Romance'),
                          ),
                          DropdownMenuItem(
                            value: 'Thriller',
                            child: Text('Thriller'),
                          ),
                          DropdownMenuItem(
                            value: 'Science-Fiction',
                            child: Text('Science-Fiction'),
                          ),
                          DropdownMenuItem(
                            value: 'Mystere',
                            child: Text('Mystere'),
                          ),
                          DropdownMenuItem(
                            value: 'Horreur',
                            child: Text('Horreur'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _genre = value ?? ''),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Labelled(
                      label: 'Resume court',
                      child: TextField(
                        controller: _summaryController,
                        minLines: 5,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText:
                              'Decrivez votre livre en quelques lignes...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Visibilite',
                      style: TextStyle(
                        color: PlumoraColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _VisibilityOption(
                      selected: _visibility == 'PRIVATE',
                      title: 'Prive',
                      subtitle: 'Visible uniquement par vous',
                      onTap: () => setState(() => _visibility = 'PRIVATE'),
                    ),
                    _VisibilityOption(
                      selected: _visibility == 'BETA_ONLY',
                      title: 'Beta-test uniquement',
                      subtitle: 'Accessible aux beta-testeurs selectionnes',
                      onTap: () => setState(() => _visibility = 'BETA_ONLY'),
                    ),
                    _VisibilityOption(
                      selected: _visibility == 'PUBLIC',
                      title: 'Publication interne',
                      subtitle: 'Visible par tous les utilisateurs de Plumora',
                      onTap: () => setState(() => _visibility = 'PUBLIC'),
                    ),
                    const SizedBox(height: 20),
                    FigmaCard(
                      color: PlumoraColors.muted.withValues(alpha: 0.45),
                      shadow: false,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            color: PlumoraColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              book?.coverUrl?.trim().isNotEmpty == true
                                  ? 'Couverture existante conservee.'
                                  : 'La couverture pourra etre ajoutee depuis une mise a jour dediee.',
                              style: const TextStyle(
                                color: PlumoraColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: PlumoraColors.destructive,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => context.go(AppRoutes.write),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: FilledButton(
                            onPressed:
                                _isSubmitting ||
                                    _titleController.text.trim().isEmpty
                                ? null
                                : _submit,
                            child: Text(
                              _isSubmitting
                                  ? 'Enregistrement...'
                                  : _editing
                                  ? 'Enregistrer'
                                  : 'Creer le livre',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _hydrateFrom(BookModel book) {
    if (_hydratedBookId == book.id) {
      return;
    }
    _hydratedBookId = book.id;
    _titleController.text = book.title;
    _summaryController.text = book.description;
    _genre = book.genre ?? '';
    _visibility = _normalizeVisibility(book.visibility);
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final request = BookUpsertRequest(
        title: _titleController.text,
        description: _summaryController.text,
        genre: _genre,
        visibility: _visibility,
      );
      final repository = ref.read(bookRepositoryProvider);
      final saved = _editing
          ? await repository.updateBook(widget.bookId!, request)
          : await repository.createBook(request);

      ref.invalidate(myBooksProvider);
      ref.invalidate(authorBookProvider(saved.id));
      if (_editing) {
        ref.invalidate(authorBookProvider(widget.bookId!));
      }

      if (mounted) {
        context.go(AppRoutes.authorBookDetailPath(saved.id));
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

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: PlumoraColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? PlumoraColors.primary.withValues(alpha: 0.06)
                : Colors.transparent,
            border: Border.all(
              color: selected ? PlumoraColors.primary : PlumoraColors.border,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? PlumoraColors.primary
                        : PlumoraColors.border,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: PlumoraColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: PlumoraColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
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
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Livre indisponible',
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

String _normalizeVisibility(String? visibility) {
  final normalized = visibility?.trim().toUpperCase();
  return switch (normalized) {
    'PUBLIC' => 'PUBLIC',
    'BETA' || 'BETA_ONLY' || 'BETA_READING' => 'BETA_ONLY',
    _ => 'PRIVATE',
  };
}
