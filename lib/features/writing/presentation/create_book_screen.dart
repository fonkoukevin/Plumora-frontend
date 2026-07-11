import 'dart:typed_data';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart' show resolvePlumoraImageUrl;
import '../../book/data/models/book_model.dart';
import '../../book/data/repositories/book_repository.dart';
import '../data/writing_cache_invalidator.dart';

const XTypeGroup _coverImageTypeGroup = XTypeGroup(
  label: 'images',
  extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
);

const _writeAccent = Color(0xFF7C5CFF);
const _writeAccentLight = Color(0xFF9B80FF);

const double _formMaxWidth = 680;

const List<List<Color>> _coverPresets = [
  [Color(0xFF7C3AED), Color(0xFF7E22CE), Color(0xFF3730A3)],
  [Color(0xFFF43F5E), Color(0xFFDC2626), Color(0xFFC2410C)],
  [Color(0xFF2563EB), Color(0xFF4338CA), Color(0xFF1E293B)],
  [Color(0xFF10B981), Color(0xFF0D9488), Color(0xFF0E7490)],
  [Color(0xFFF59E0B), Color(0xFFEA580C), Color(0xFFB91C1C)],
  [Color(0xFFDB2777), Color(0xFFBE123C), Color(0xFF991B1B)],
  [Color(0xFF06B6D4), Color(0xFF2563EB), Color(0xFF4338CA)],
  [Color(0xFFC026D3), Color(0xFF7E22CE), Color(0xFF1E40AF)],
];

const List<String> _genres = [
  'Fantasy',
  'Romance',
  'Thriller',
  'Science-Fiction',
  'Mystère',
  'Horreur',
  'Contemporain',
  'Aventure',
  'Historique',
  'Poésie',
];

const List<String> _languages = [
  'Français',
  'English',
  'Español',
  'Português',
  'Deutsch',
];

const Map<String, String> _languageCodes = {
  'Français': 'fr',
  'English': 'en',
  'Español': 'es',
  'Português': 'pt',
  'Deutsch': 'de',
};

typedef _VisibilityOption = ({
  String id,
  IconData icon,
  String label,
  String description,
});

const List<_VisibilityOption> _visibilityOptions = [
  (
    id: 'PRIVATE',
    icon: Icons.lock_outline,
    label: 'Privé',
    description: 'Visible uniquement par vous',
  ),
  (
    id: 'BETA_ONLY',
    icon: Icons.groups_outlined,
    label: 'Bêta-test',
    description: 'Accessible aux bêta-lecteurs',
  ),
  (
    id: 'PUBLIC',
    icon: Icons.public,
    label: 'Public',
    description: 'Visible par toute la communauté',
  ),
];

class CreateBookScreen extends ConsumerStatefulWidget {
  const CreateBookScreen({this.bookId, super.key});

  final String? bookId;

  @override
  ConsumerState<CreateBookScreen> createState() => _CreateBookScreenState();
}

class _CreateBookScreenState extends ConsumerState<CreateBookScreen> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _tagsController = TextEditingController();
  int _selectedCoverIndex = 0;
  Uint8List? _coverImageBytes;
  String? _coverImageName;
  String? _existingCoverUrl;
  String _genre = '';
  String _language = 'Français';
  String _visibility = 'PRIVATE';
  bool _mature = false;
  String? _hydratedBookId;
  bool _isSubmitting = false;
  String? _error;

  bool get _editing =>
      widget.bookId != null && widget.bookId!.trim().isNotEmpty;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty && _genre.trim().isNotEmpty;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BookModel?> bookAsync = _editing
        ? ref.watch(authorBookProvider(widget.bookId!)).whenData((book) => book)
        : const AsyncValue.data(null);

    return bookAsync.when(
      loading: () => const FigmaScreen(
        maxWidth: _formMaxWidth,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, _) => FigmaScreen(
        maxWidth: _formMaxWidth,
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

        final canSubmit = _canSubmit && !_isSubmitting;

        return ColoredBox(
          color: context.colors.background,
          child: Column(
            children: [
              _Header(
                editing: _editing,
                canSubmit: canSubmit,
                submitting: _isSubmitting,
                onBack: () => context.go(AppRoutes.write),
                onSubmit: _submit,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 100),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _formMaxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('Couverture'),
                          const SizedBox(height: 14),
                          _CoverSection(
                            title: _titleController.text,
                            selectedIndex: _selectedCoverIndex,
                            pickedImageBytes: _coverImageBytes,
                            existingImageUrl: _existingCoverUrl,
                            onSelect: (index) => setState(() {
                              _selectedCoverIndex = index;
                              _coverImageBytes = null;
                              _coverImageName = null;
                              _existingCoverUrl = null;
                            }),
                            onImportTap: _pickCoverImage,
                          ),
                          const SizedBox(height: 30),
                          const _SectionLabel('Informations'),
                          const SizedBox(height: 16),
                          const _FieldLabel('Titre', required: true),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _titleController,
                            maxLength: 100,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Ex: La Nuit Rouge',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const _FieldLabel('Genre', required: true),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final genre in _genres)
                                _GenreChip(
                                  label: genre,
                                  selected: _genre == genre,
                                  onTap: () => setState(() => _genre = genre),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const _FieldLabel('Langue'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _language,
                            items: [
                              for (final language in _languages)
                                DropdownMenuItem(
                                  value: language,
                                  child: Text(language),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _language = value ?? _language),
                          ),
                          const SizedBox(height: 16),
                          const _FieldLabel('Résumé'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _summaryController,
                            minLines: 4,
                            maxLines: 4,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              hintText:
                                  'Décrivez votre histoire pour attirer les lecteurs...',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const _FieldLabel('Tags'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _tagsController,
                            decoration: const InputDecoration(
                              hintText:
                                  'magie, amour, aventure... (séparés par des virgules)',
                            ),
                          ),
                          const SizedBox(height: 30),
                          const _SectionLabel('Visibilité'),
                          const SizedBox(height: 12),
                          for (final option in _visibilityOptions)
                            _VisibilityTile(
                              data: option,
                              selected: _visibility == option.id,
                              onTap: () =>
                                  setState(() => _visibility = option.id),
                            ),
                          const SizedBox(height: 6),
                          _MatureToggle(
                            value: _mature,
                            onChanged: (value) =>
                                setState(() => _mature = value),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: context.colors.destructive,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          _CreateCta(
                            canSubmit: canSubmit,
                            submitting: _isSubmitting,
                            editing: _editing,
                            onTap: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
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
    _tagsController.text = book.tags.join(', ');
    _genre = book.genre ?? '';
    _visibility = _normalizeVisibility(book.visibility);
    _language = _labelForLanguageCode(book.language);
    _existingCoverUrl = book.coverUrl;
  }

  Future<void> _pickCoverImage() async {
    try {
      final file = await openFile(acceptedTypeGroups: [_coverImageTypeGroup]);
      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _coverImageBytes = bytes;
        _coverImageName = file.name;
        _existingCoverUrl = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'ouvrir le sélecteur d'image."),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isSubmitting) {
      return;
    }

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
        language: _languageCodes[_language] ?? 'fr',
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        mature: _mature,
        coverImage: _coverImageBytes == null
            ? null
            : BookCoverUpload(
                fileName: _coverImageName ?? 'cover.jpg',
                bytes: _coverImageBytes,
              ),
      );
      final repository = ref.read(bookRepositoryProvider);
      final saved = _editing
          ? await repository.updateBook(widget.bookId!, request)
          : await repository.createBook(request);

      ref.invalidate(myBooksProvider);
      ref.invalidate(authorBookProvider(saved.id));
      if (_editing) {
        ref.invalidate(authorBookProvider(widget.bookId!));
        invalidateBookPublicationCaches(ref, widget.bookId!);
      }

      if (!mounted) {
        return;
      }

      context.go(
        _editing
            ? AppRoutes.authorBookDetailPath(saved.id)
            : AppRoutes.chapterEditorPath(saved.id),
      );
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.editing,
    required this.canSubmit,
    required this.submitting,
    required this.onBack,
    required this.onSubmit,
  });

  final bool editing;
  final bool canSubmit;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.background.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(color: context.colors.border),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Mes histoires'),
                    style: TextButton.styleFrom(
                      foregroundColor: _writeAccent,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    editing ? "Modifier l'histoire" : 'Nouvelle histoire',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  _HeaderSubmitButton(
                    editing: editing,
                    canSubmit: canSubmit,
                    submitting: submitting,
                    onTap: onSubmit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSubmitButton extends StatelessWidget {
  const _HeaderSubmitButton({
    required this.editing,
    required this.canSubmit,
    required this.submitting,
    required this.onTap,
  });

  final bool editing;
  final bool canSubmit;
  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = submitting ? '...' : (editing ? 'Enregistrer' : 'Créer');

    return InkWell(
      onTap: canSubmit ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: canSubmit
              ? const LinearGradient(colors: [_writeAccent, _writeAccentLight])
              : null,
          color: canSubmit ? null : context.colors.muted,
          borderRadius: BorderRadius.circular(12),
          boxShadow: canSubmit
              ? [
                  BoxShadow(
                    color: _writeAccent.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: canSubmit ? Colors.white : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: context.colors.textPrimary,
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label.toUpperCase(),
        style: TextStyle(
          color: context.colors.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: context.colors.destructive),
                ),
              ]
            : null,
      ),
    );
  }
}

class _CoverSection extends StatelessWidget {
  const _CoverSection({
    required this.title,
    required this.selectedIndex,
    required this.onSelect,
    required this.onImportTap,
    this.pickedImageBytes,
    this.existingImageUrl,
  });

  final String title;
  final int selectedIndex;
  final Uint8List? pickedImageBytes;
  final String? existingImageUrl;
  final ValueChanged<int> onSelect;
  final VoidCallback onImportTap;

  @override
  Widget build(BuildContext context) {
    final trimmedTitle = title.trim();
    final resolvedExistingUrl = resolvePlumoraImageUrl(existingImageUrl);
    final hasImage = pickedImageBytes != null || resolvedExistingUrl != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Column(
            children: [
              Container(
                width: 112,
                height: 160,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: _coverPresets[selectedIndex],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (pickedImageBytes != null)
                      Positioned.fill(
                        child: Image.memory(
                          pickedImageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      )
                    else if (resolvedExistingUrl != null)
                      Positioned.fill(
                        child: Image.network(
                          resolvedExistingUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    if (trimmedTitle.isNotEmpty)
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Text(
                          trimmedTitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onImportTap,
                  icon: Icon(
                    hasImage ? Icons.edit_outlined : Icons.camera_alt_outlined,
                    size: 15,
                  ),
                  label: Text(hasImage ? 'Changer' : 'Importer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.textSecondary,
                    side: BorderSide(color: context.colors.border),
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisir une couleur',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _coverPresets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2 / 3,
                ),
                itemBuilder: (context, index) {
                  return _CoverSwatch(
                    colors: _coverPresets[index],
                    selected: index == selectedIndex,
                    onTap: () => onSelect(index),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoverSwatch extends StatelessWidget {
  const _CoverSwatch({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: selected ? Border.all(color: _writeAccent, width: 2.5) : null,
        ),
        child: selected
            ? Container(
                color: Colors.black.withValues(alpha: 0.18),
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 13,
                      color: _writeAccent,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [_writeAccent, _writeAccentLight])
              : null,
          color: selected ? null : context.colors.cards,
          border: Border.all(
            color: selected ? Colors.transparent : context.colors.border,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _VisibilityTile extends StatelessWidget {
  const _VisibilityTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _VisibilityOption data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? _writeAccent.withValues(alpha: 0.06)
                : context.colors.cards,
            border: Border.all(
              color: selected
                  ? _writeAccent.withValues(alpha: 0.5)
                  : context.colors.border,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? _writeAccent.withValues(alpha: 0.15)
                      : context.colors.muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data.icon,
                  size: 20,
                  color: selected ? _writeAccent : context.colors.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.description,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _writeAccent : context.colors.border,
                    width: 2,
                  ),
                  color: selected ? _writeAccent : Colors.transparent,
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatureToggle extends StatelessWidget {
  const _MatureToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.cards,
          border: Border.all(color: context.colors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contenu mature',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Violence, thèmes adultes — réservé aux +18',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: _writeAccent,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: context.colors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCta extends StatelessWidget {
  const _CreateCta({
    required this.canSubmit,
    required this.submitting,
    required this.editing,
    required this.onTap,
  });

  final bool canSubmit;
  final bool submitting;
  final bool editing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: canSubmit ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 17),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: canSubmit
                  ? const LinearGradient(
                      colors: [_writeAccent, _writeAccentLight],
                    )
                  : null,
              color: canSubmit ? null : context.colors.muted,
              borderRadius: BorderRadius.circular(18),
              boxShadow: canSubmit
                  ? [
                      BoxShadow(
                        color: _writeAccent.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              submitting
                  ? 'Enregistrement...'
                  : (editing
                        ? 'Enregistrer les modifications'
                        : 'Créer et commencer à écrire'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: canSubmit ? Colors.white : context.colors.textSecondary,
              ),
            ),
          ),
        ),
        if (!canSubmit && !submitting) ...[
          const SizedBox(height: 8),
          Text(
            'Remplissez le titre et le genre pour continuer',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
        ],
      ],
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
            style: TextStyle(color: context.colors.textSecondary),
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

String _labelForLanguageCode(String? code) {
  final normalized = code?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return 'Français';
  }

  for (final entry in _languageCodes.entries) {
    if (entry.value == normalized || entry.key.toLowerCase() == normalized) {
      return entry.key;
    }
  }

  return 'Français';
}
