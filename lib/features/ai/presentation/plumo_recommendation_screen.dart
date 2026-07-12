import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
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
  final Set<String> _moods = {};
  final Set<String> _genres = {};
  String _duration = '';
  bool _loading = false;
  String? _error;
  List<AiRecommendedBookModel>? _results;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_results != null) {
      return _MukemeResults(
        recommendations: _results!,
        loading: _loading,
        error: _error,
        onBack: () => setState(() {
          _results = null;
          _error = null;
        }),
        onRetry: _submit,
      );
    }

    return FigmaScreen(
      maxWidth: 840,
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigmaBackButton(
            label: 'Retour',
            onTap: () => context.go(AppRoutes.discover),
          ),
          const SizedBox(height: 22),
          Center(
            child: Column(
              children: [
                FigmaGradientIcon(
                  icon: Icons.auto_awesome,
                  size: 78,
                  iconSize: 38,
                ),
                SizedBox(height: 14),
                Text(
                  'Mukeme',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Assistant de lecture',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          FigmaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Quel type de livre veux-tu lire aujourd'hui ?",
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _queryController,
                  onChanged: (_) => setState(() {}),
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText:
                        'Je veux une histoire courte, sombre, avec du suspense et une fin surprenante.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ChoiceCard(
            title: 'Humeur du moment',
            children: [
              for (final mood in const [
                ('calm', 'Calme', Icons.nightlight_round),
                ('romance', 'Romance', Icons.favorite_border),
                ('suspense', 'Suspense', Icons.visibility_outlined),
                ('motivation', 'Motivation', Icons.fitness_center),
                ('evasion', 'Evasion', Icons.flight_takeoff),
              ])
                _ChoiceButton(
                  label: mood.$2,
                  icon: mood.$3,
                  selected: _moods.contains(mood.$1),
                  onTap: () => setState(() {
                    _moods.contains(mood.$1)
                        ? _moods.remove(mood.$1)
                        : _moods.add(mood.$1);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _ChoiceCard(
            title: 'Duree de lecture',
            children: [
              for (final duration in const [
                ('short', 'Court', '< 2h'),
                ('medium', 'Moyen', '2-5h'),
                ('long', 'Long', '> 5h'),
              ])
                _ChoiceButton(
                  label: duration.$2,
                  subtitle: duration.$3,
                  selected: _duration == duration.$1,
                  onTap: () => setState(() => _duration = duration.$1),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _ChoiceCard(
            title: 'Genres preferes',
            children: [
              for (final genre in const [
                ('Thriller', 'Thriller'),
                ('Romance', 'Romance'),
                ('Fantasy', 'Fantasy'),
                ('Science-Fiction', 'Science-Fiction'),
                ('Developpement personnel', 'Developpement personnel'),
                ('Mystere', 'Mystere'),
              ])
                _ChoiceButton(
                  label: genre.$2,
                  selected: _genres.contains(genre.$1),
                  onTap: () => setState(() {
                    _genres.contains(genre.$1)
                        ? _genres.remove(genre.$1)
                        : _genres.add(genre.$1);
                  }),
                ),
            ],
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
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  (_queryController.text.trim().isEmpty && _moods.isEmpty) ||
                      _loading
                  ? null
                  : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'Recherche...' : 'Me recommander'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final request = AiRecommendationRequest(
        queryText: _queryController.text.trim().isEmpty
            ? 'Recommande-moi un livre.'
            : _queryController.text,
        mood: _moods.join(', '),
        preferredDuration: _duration,
        preferredGenre: _genres.join(', '),
      );
      final results = await ref
          .read(aiRepositoryProvider)
          .recommendBooks(request);
      setState(() => _results = results);
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: children),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.subtitle,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primary.withValues(alpha: 0.07)
              : Colors.transparent,
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (icon != null)
              Icon(icon, color: context.colors.primary, size: 26),
            if (icon != null) const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MukemeResults extends StatelessWidget {
  const _MukemeResults({
    required this.recommendations,
    required this.loading,
    required this.onBack,
    required this.onRetry,
    this.error,
  });

  final List<AiRecommendedBookModel> recommendations;
  final bool loading;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FigmaScreen(
      maxWidth: 1120,
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigmaBackButton(label: 'Nouvelle recherche', onTap: onBack),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: context.colors.primary,
                  size: 34,
                ),
                SizedBox(height: 8),
                Text(
                  'Selection personnalisee',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (error != null)
            FigmaCard(
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: context.colors.destructive,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(error!)),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Reessayer'),
                  ),
                ],
              ),
            )
          else if (recommendations.isEmpty)
            const FigmaEmptyState(
              title: 'Aucune recommandation',
              message: "Mukeme n'a renvoye aucun livre pour cette demande.",
              icon: Icons.auto_awesome,
            )
          else
            for (final recommendation in recommendations) ...[
              _RecommendationCard(recommendation: recommendation),
              const SizedBox(height: 16),
            ],
          Center(
            child: OutlinedButton(
              onPressed: loading ? null : onBack,
              child: const Text('Affiner la recherche'),
            ),
          ),
        ],
      ),
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

    return FigmaCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;
          final cover = PlumoraBookCover(
            width: wide ? 170 : double.infinity,
            height: wide ? 250 : 250,
            colors: _coverColors(book.id),
            imageUrl: book.coverUrl,
            imageBytes: cachedCover,
            radius: 14,
          );
          final detail = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            book.authorName,
                            style: TextStyle(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (recommendation.matchScore > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: context.colors.primary,
                              ),
                              Text(
                                '${recommendation.matchScore}%',
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Correspondance',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (book.genre != null) FigmaBadge(label: book.genre!),
                    if (book.estimatedReadingMinutes > 0)
                      FigmaBadge(label: '${book.estimatedReadingMinutes} min'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 17),
                    Text(' ${book.rating.toStringAsFixed(1)}'),
                    const SizedBox(width: 18),
                    const Icon(Icons.menu_book_outlined, size: 17),
                    Text(' ${book.readCount} lectures'),
                  ],
                ),
                if (recommendation.reasons.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  FigmaCard(
                    color: context.colors.primary.withValues(alpha: 0.06),
                    shadow: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final reason in recommendation.reasons)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              reason,
                              style: const TextStyle(height: 1.4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: book.id.isEmpty
                        ? null
                        : () => context.go(
                            AppRoutes.catalogBookDetailPath(book.id),
                          ),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('En savoir plus'),
                  ),
                ),
              ],
            ),
          );
          if (!wide) {
            return Column(
              children: [
                cover,
                const SizedBox(height: 18),
                Row(children: [detail]),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [cover, const SizedBox(width: 22), detail],
          );
        },
      ),
    );
  }
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
