import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/repositories/book_repository.dart';

class CreateBookScreen extends ConsumerStatefulWidget {
  const CreateBookScreen({this.bookId, super.key});

  final String? bookId;

  @override
  ConsumerState<CreateBookScreen> createState() => _CreateBookScreenState();
}

class _CreateBookScreenState extends ConsumerState<CreateBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedGenre;
  String _visibility = 'PRIVATE';
  String? _loadedBookId;
  bool _isSaving = false;
  String? _error;

  static const _genres = [
    'Fantasy',
    'Romance',
    'Thriller',
    'Science-fiction',
    'Mystère',
    'Poésie',
    'Essai',
    'Autre',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookId = widget.bookId?.trim();
    if (bookId != null && bookId.isNotEmpty) {
      final bookAsync = ref.watch(authorBookProvider(bookId));
      return bookAsync.when(
        loading: () => const _CreateBookLoader(),
        error: (error, _) => _CreateBookLoadError(
          message: AppError.messageFor(error),
          onRetry: () => ref.invalidate(authorBookProvider(bookId)),
        ),
        data: (book) {
          _syncBook(book);
          return _buildFormLayout(context, isEditing: true, bookId: bookId);
        },
      );
    }

    return _buildFormLayout(context, isEditing: false, bookId: null);
  }

  Widget _buildFormLayout(
    BuildContext context, {
    required bool isEditing,
    required String? bookId,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontal = 16.0;
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 92.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            32,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth >= 760 ? 768 : 430,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () {
                            if (isEditing && bookId != null) {
                              context.go(
                                AppRoutes.authorBookDetailPath(bookId),
                              );
                            } else if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.write);
                            }
                          },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: PlumoraColors.textSecondary,
                    ),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Retour'),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    isEditing ? 'Modifier le livre' : 'Créer un nouveau livre',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: PlumoraColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEditing
                        ? 'Mets à jour les informations de ton manuscrit'
                        : 'Remplissez les informations pour commencer votre nouveau projet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PlumoraColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PlumoraCard(
                    radius: 16,
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            _ErrorBanner(message: _error!),
                            const SizedBox(height: 14),
                          ],
                          const _FieldLabel('Titre du livre'),
                          TextFormField(
                            controller: _titleController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Ex: La Nuit Rouge',
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Titre requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          const _FieldLabel('Genre'),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGenre,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              hintText: 'Sélectionner un genre',
                            ),
                            items: [
                              for (final genre in _genreOptions)
                                DropdownMenuItem(
                                  value: genre,
                                  child: Text(genre),
                                ),
                            ],
                            onChanged: _isSaving
                                ? null
                                : (value) => setState(() {
                                    _selectedGenre = value;
                                  }),
                          ),
                          const SizedBox(height: 24),
                          const _FieldLabel('Résumé court'),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            minLines: 5,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(
                              hintText:
                                  'Décrivez votre livre en quelques lignes...',
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _FieldLabel('Visibilité'),
                          RadioGroup<String>(
                            groupValue: _visibility,
                            onChanged: _setVisibility,
                            child: Column(
                              children: [
                                _VisibilityOption(
                                  value: 'PRIVATE',
                                  selected: _visibility == 'PRIVATE',
                                  title: 'Privé',
                                  subtitle: 'Visible uniquement par vous',
                                  onTap: () => _setVisibility('PRIVATE'),
                                ),
                                const SizedBox(height: 8),
                                _VisibilityOption(
                                  value: 'BETA_ONLY',
                                  selected: _visibility == 'BETA_ONLY',
                                  title: 'Bêta-test uniquement',
                                  subtitle:
                                      'Accessible aux bêta-testeurs sélectionnés',
                                  onTap: () => _setVisibility('BETA_ONLY'),
                                ),
                                const SizedBox(height: 8),
                                _VisibilityOption(
                                  value: 'PUBLIC',
                                  selected: _visibility == 'PUBLIC',
                                  title: 'Publication interne',
                                  subtitle:
                                      'Visible par tous les utilisateurs de Plumora',
                                  onTap: () => _setVisibility('PUBLIC'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          if (isEditing && bookId != null) {
                                            context.go(
                                              AppRoutes.authorBookDetailPath(
                                                bookId,
                                              ),
                                            );
                                          } else {
                                            context.go(AppRoutes.write);
                                          }
                                        },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 42),
                                  ),
                                  child: const Text('Annuler'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _isSaving ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 42),
                                  ),
                                  child: Text(
                                    _isSaving
                                        ? isEditing
                                              ? 'Sauvegarde...'
                                              : 'Création...'
                                        : isEditing
                                        ? 'Enregistrer'
                                        : 'Créer le livre',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> get _genreOptions {
    final selectedGenre = _selectedGenre?.trim();
    if (selectedGenre == null ||
        selectedGenre.isEmpty ||
        _genres.contains(selectedGenre)) {
      return _genres;
    }

    return [..._genres, selectedGenre];
  }

  void _syncBook(BookModel book) {
    if (_loadedBookId == book.id) {
      return;
    }

    _loadedBookId = book.id;
    _titleController.text = book.title;
    _descriptionController.text = book.description;
    _selectedGenre = book.genre?.trim().isEmpty ?? true
        ? null
        : book.genre?.trim();
    _visibility = _normalizeVisibility(book.visibility);
    _error = null;
  }

  String _normalizeVisibility(String? visibility) {
    final normalized = visibility?.trim().toUpperCase();
    return switch (normalized) {
      'PUBLIC' || 'INTERNAL' => 'PUBLIC',
      'BETA' || 'BETA_ONLY' || 'BETA_TEST' => 'BETA_ONLY',
      _ => 'PRIVATE',
    };
  }

  void _setVisibility(String? value) {
    if (value == null || _isSaving) {
      return;
    }
    setState(() => _visibility = value);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final request = BookUpsertRequest(
        title: _titleController.text,
        description: _descriptionController.text,
        genre: _selectedGenre,
        visibility: _visibility,
      );
      final bookId = widget.bookId?.trim();
      final book = bookId == null || bookId.isEmpty
          ? await ref.read(bookRepositoryProvider).createBook(request)
          : await ref.read(bookRepositoryProvider).updateBook(bookId, request);
      ref.invalidate(myBooksProvider);
      if (bookId != null && bookId.isNotEmpty) {
        ref.invalidate(authorBookProvider(bookId));
      }

      if (mounted) {
        final targetBookId = book.id.isEmpty ? (bookId ?? '') : book.id;
        if (bookId == null || bookId.isEmpty) {
          context.go(AppRoutes.chapterEditorPath(targetBookId));
        } else {
          context.go(AppRoutes.authorBookDetailPath(targetBookId));
        }
      }
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _CreateBookLoader extends StatelessWidget {
  const _CreateBookLoader();

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

class _CreateBookLoadError extends StatelessWidget {
  const _CreateBookLoadError({required this.message, required this.onRetry});

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
              constraints: const BoxConstraints(maxWidth: 560),
              child: PlumoraCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Livre introuvable',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          color: PlumoraColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({
    required this.value,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String value;
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PlumoraColors.cards,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? PlumoraColors.primary : PlumoraColors.border,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: PlumoraColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: PlumoraColors.textSecondary,
                      fontSize: 14,
                    ),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
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
