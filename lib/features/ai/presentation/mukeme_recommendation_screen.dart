import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../data/models/ai_models.dart';
import '../data/repositories/ai_repository.dart';

class MukemeRecommendationScreen extends ConsumerStatefulWidget {
  const MukemeRecommendationScreen({super.key});

  @override
  ConsumerState<MukemeRecommendationScreen> createState() =>
      _MukemeRecommendationScreenState();
}

class _MukemeRecommendationScreenState
    extends ConsumerState<MukemeRecommendationScreen> {
  final _queryController = TextEditingController();
  String? _selectedMood;
  String? _selectedDuration;
  String? _selectedGenre;
  List<AiRecommendedBookModel> _recommendations = const [];
  bool _isLoading = false;
  String? _error;

  static const _moods = [
    _ChoiceValue('Calme', 'CALM', '🌙'),
    _ChoiceValue('Romance', 'ROMANCE', '💕'),
    _ChoiceValue('Suspense', 'SUSPENSE', '😱'),
    _ChoiceValue('Motivation', 'MOTIVATION', '💪'),
    _ChoiceValue('Évasion', 'EVASION', '✈️'),
  ];

  static const _durations = [
    _ChoiceValue('Court', 'SHORT', '< 2h'),
    _ChoiceValue('Moyen', 'MEDIUM', '2-5h'),
    _ChoiceValue('Long', 'LONG', '> 5h'),
  ];

  static const _genres = [
    _ChoiceValue('Thriller', 'Thriller', ''),
    _ChoiceValue('Romance', 'Romance', ''),
    _ChoiceValue('Fantasy', 'Fantasy', ''),
    _ChoiceValue('Science-Fiction', 'Science-Fiction', ''),
    _ChoiceValue('Mystère', 'Mystère', ''),
    _ChoiceValue('Développement personnel', 'Développement personnel', ''),
  ];

  @override
  void dispose() {
    _queryController.dispose();
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
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => context.go(AppRoutes.discover),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Retour'),
                  ),
                  const SizedBox(height: 20),
                  const _Header(),
                  const SizedBox(height: 28),
                  _PromptCard(
                    controller: _queryController,
                    selectedMood: _selectedMood,
                    selectedDuration: _selectedDuration,
                    selectedGenre: _selectedGenre,
                    moods: _moods,
                    durations: _durations,
                    genres: _genres,
                    isLoading: _isLoading,
                    error: _error,
                    onMoodChanged: (value) => setState(
                      () => _selectedMood = _toggle(value, _selectedMood),
                    ),
                    onDurationChanged: (value) => setState(
                      () =>
                          _selectedDuration = _toggle(value, _selectedDuration),
                    ),
                    onGenreChanged: (value) => setState(
                      () => _selectedGenre = _toggle(value, _selectedGenre),
                    ),
                    onSubmit: _recommend,
                  ),
                  const SizedBox(height: 28),
                  _ResultsSection(
                    recommendations: _recommendations,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _toggle(String value, String? currentValue) {
    return currentValue == value ? null : value;
  }

  Future<void> _recommend() async {
    final query = _queryController.text.trim();
    if (query.isEmpty &&
        _selectedMood == null &&
        _selectedDuration == null &&
        _selectedGenre == null) {
      setState(() {
        _error = 'Décris ton envie ou choisis au moins un critère.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await ref
          .read(aiRepositoryProvider)
          .recommendBooks(
            AiRecommendationRequest(
              queryText: query.isEmpty ? 'Recommandation personnalisée' : query,
              mood: _selectedMood,
              preferredDuration: _selectedDuration,
              preferredGenre: _selectedGenre,
            ),
          );
      ref.invalidate(aiRecommendationRequestsProvider);
      setState(() => _recommendations = results);
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Center(
          child: PlumoraIconTile(
            size: 80,
            radius: 24,
            backgroundColor: PlumoraColors.primary,
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Mukeme',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: PlumoraColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Assistant de lecture',
            style: TextStyle(color: PlumoraColors.textSecondary, fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.controller,
    required this.selectedMood,
    required this.selectedDuration,
    required this.selectedGenre,
    required this.moods,
    required this.durations,
    required this.genres,
    required this.isLoading,
    required this.onMoodChanged,
    required this.onDurationChanged,
    required this.onGenreChanged,
    required this.onSubmit,
    this.error,
  });

  final TextEditingController controller;
  final String? selectedMood;
  final String? selectedDuration;
  final String? selectedGenre;
  final List<_ChoiceValue> moods;
  final List<_ChoiceValue> durations;
  final List<_ChoiceValue> genres;
  final bool isLoading;
  final ValueChanged<String> onMoodChanged;
  final ValueChanged<String> onDurationChanged;
  final ValueChanged<String> onGenreChanged;
  final VoidCallback onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Quel type de livre veux-tu lire aujourd'hui ?",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            minLines: 4,
            maxLines: 7,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText:
                  'Je veux une histoire courte, sombre, avec du suspense et une fin surprenante.',
            ),
          ),
          const SizedBox(height: 22),
          _ChoiceSection(
            title: 'Humeur du moment',
            values: moods,
            selectedValue: selectedMood,
            onChanged: onMoodChanged,
          ),
          const SizedBox(height: 20),
          _ChoiceSection(
            title: 'Durée de lecture',
            values: durations,
            selectedValue: selectedDuration,
            onChanged: onDurationChanged,
          ),
          const SizedBox(height: 20),
          _ChoiceSection(
            title: 'Genre préféré',
            values: genres,
            selectedValue: selectedGenre,
            onChanged: onGenreChanged,
          ),
          if (error != null) ...[
            const SizedBox(height: 18),
            _InlineError(message: error!),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: isLoading ? null : onSubmit,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(isLoading ? 'Recherche...' : 'Me recommander'),
          ),
        ],
      ),
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.values,
    required this.selectedValue,
    required this.onChanged,
  });

  final String title;
  final List<_ChoiceValue> values;
  final String? selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(
                  value.extra.isEmpty
                      ? value.label
                      : '${value.extra} ${value.label}',
                ),
                selected: selectedValue == value.value,
                onSelected: (_) => onChanged(value.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({
    required this.recommendations,
    required this.isLoading,
  });

  final List<AiRecommendedBookModel> recommendations;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && recommendations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (recommendations.isEmpty) {
      return const PlumoraCard(
        shadow: false,
        child: Text(
          'Les recommandations de Mukeme apparaîtront ici.',
          style: TextStyle(color: PlumoraColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélection personnalisée',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        for (final recommendation in recommendations) ...[
          _RecommendationCard(recommendation: recommendation),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _RecommendationCard extends ConsumerWidget {
  const _RecommendationCard({required this.recommendation});

  final AiRecommendedBookModel recommendation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = recommendation.book;
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));
    return PlumoraCard(
      onTap: () => context.go(AppRoutes.catalogBookDetailPath(book.id)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final cover = PlumoraBookCover(
            colors: _coverColors(book.id.isEmpty ? book.title : book.id),
            imageUrl: book.coverUrl,
            imageBytes: cachedCover,
            width: compact ? double.infinity : 148,
            height: compact ? 220 : 220,
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      book.title.isEmpty ? 'Livre sans titre' : book.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (recommendation.matchScore > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: PlumoraColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recommendation.matchScore}%',
                          style: const TextStyle(
                            color: PlumoraColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                book.authorName,
                style: const TextStyle(color: PlumoraColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (book.genre != null) PlumoraBadge(label: book.genre!),
                  if (book.estimatedReadingMinutes > 0)
                    PlumoraBadge(
                      label: '${book.estimatedReadingMinutes} min',
                      backgroundColor: PlumoraColors.muted,
                      foregroundColor: PlumoraColors.textSecondary,
                      icon: Icons.schedule,
                    ),
                ],
              ),
              if (recommendation.reasons.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4E8FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pourquoi ce livre ?',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      for (final reason in recommendation.reasons)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $reason'),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    context.go(AppRoutes.catalogBookDetailPath(book.id)),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('En savoir plus'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [cover, const SizedBox(height: 18), details],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cover,
              const SizedBox(width: 22),
              Expanded(child: details),
            ],
          );
        },
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

class _ChoiceValue {
  const _ChoiceValue(this.label, this.value, this.extra);

  final String label;
  final String value;
  final String extra;
}

List<Color> _coverColors(String key) {
  final palettes = [
    [const Color(0xFF7C3AED), const Color(0xFFDB2777)],
    [const Color(0xFF2563EB), const Color(0xFF06B6D4)],
    [const Color(0xFFDC2626), const Color(0xFFEA580C)],
    [const Color(0xFFDB2777), const Color(0xFFE11D48)],
    [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
    [const Color(0xFF059669), const Color(0xFF0D9488)],
  ];
  final index =
      key.codeUnits.fold<int>(0, (sum, code) => sum + code) % palettes.length;
  return palettes[index];
}
