import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../../catalog/data/repositories/catalog_repository.dart';
import '../../reading/data/repositories/favorite_repository.dart';
import '../data/models/ai_models.dart';
import '../data/repositories/ai_repository.dart';

class PlumoRecommendationScreen extends ConsumerStatefulWidget {
  const PlumoRecommendationScreen({super.key});

  @override
  ConsumerState<PlumoRecommendationScreen> createState() =>
      _PlumoRecommendationScreenState();
}

class _PlumoRecommendationScreenState
    extends ConsumerState<PlumoRecommendationScreen> {
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
      return _PlumoResults(
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
            onTap: () => returnToPreviousOr(context, AppRoutes.discover),
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
                  'Plumo',
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
                ('evasion', 'Évasion', Icons.flight_takeoff),
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
            title: 'Durée de lecture',
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
            title: 'Genres préférés',
            children: [
              for (final genre in const [
                ('Thriller', 'Thriller'),
                ('Romance', 'Romance'),
                ('Fantasy', 'Fantasy'),
                ('Science-Fiction', 'Science-Fiction'),
                ('Développement personnel', 'Développement personnel'),
                ('Mystère', 'Mystère'),
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

class _PlumoResults extends StatelessWidget {
  const _PlumoResults({
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
          FigmaBackButton(label: 'Retour', onTap: onBack),
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
                  'Sélection personnalisée',
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
                  Icon(Icons.error_outline, color: context.colors.destructive),
                  const SizedBox(width: 10),
                  Expanded(child: Text(error!)),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else if (recommendations.isEmpty)
            const FigmaEmptyState(
              title: 'Aucune recommandation',
              message: "Plumo n'a renvoyé aucun livre pour cette demande.",
              icon: Icons.auto_awesome,
            )
          else
            for (final recommendation in recommendations) ...[
              _RecommendationCard(recommendation: recommendation),
              const SizedBox(height: 24),
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

class _RecommendationCard extends ConsumerStatefulWidget {
  const _RecommendationCard({required this.recommendation});

  final AiRecommendedBookModel recommendation;

  @override
  ConsumerState<_RecommendationCard> createState() =>
      _RecommendationCardState();
}

class _RecommendationCardState extends ConsumerState<_RecommendationCard> {
  bool _favoriteMutating = false;
  String? _favoriteError;

  @override
  Widget build(BuildContext context) {
    final recommendation = widget.recommendation;
    final thinBook = recommendation.book;
    // The recommendation payload only carries id/title/coverUrl -- enrich
    // with the real author/genre/rating/reading time from the catalog so
    // this card doesn't fall back to "Plumora" / 0.0 / 0 lectures. Falls
    // back to the thin data while loading or if the book can't be resolved
    // anymore, rather than blocking the whole card.
    final detailAsync = ref.watch(catalogBookDetailProvider(thinBook.id));
    final book = detailAsync.valueOrNull?.summary ?? thinBook;
    final cachedCover = ref.watch(bookCoverBytesProvider(book.id));
    final favoriteAsync = book.id.isEmpty
        ? null
        : ref.watch(favoriteStatusProvider(book.id));
    final isFavorite = favoriteAsync?.valueOrNull ?? false;
    final favoriteLoading =
        _favoriteMutating || (favoriteAsync?.isLoading ?? false);
    final reasons = recommendation.reasons
        .map((reason) => reason.trim())
        .where((reason) => reason.isNotEmpty)
        .toList();
    if (reasons.isEmpty) {
      reasons.add(
        book.genre?.trim().isNotEmpty ?? false
            ? 'Correspond à ton envie de lire un livre ${book.genre!.trim()}.'
            : 'Sélectionné par Plumo à partir de tes préférences de lecture.',
      );
    }

    return FigmaCard(
      key: ValueKey('plumo_recommendation_${book.id}'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final actionsInline = constraints.maxWidth >= 560;
          final coverWidth = wide
              ? 192.0
              : constraints.maxWidth.clamp(150.0, 180.0).toDouble();
          final coverHeight = wide ? 360.0 : 264.0;
          final cover = Align(
            alignment: wide ? Alignment.topLeft : Alignment.topCenter,
            child: PlumoraBookCover(
              key: ValueKey('plumo_recommendation_cover_${book.id}'),
              width: coverWidth,
              height: coverHeight,
              colors: _coverColors(book.id),
              imageUrl: book.coverUrl,
              imageBytes: cachedCover,
              radius: 16,
            ),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RecommendationHeading(
                title: book.title.isEmpty ? 'Livre sans titre' : book.title,
                author: book.authorName,
                matchScore: recommendation.matchScore,
                compact: !wide,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (book.genre?.trim().isNotEmpty ?? false)
                    FigmaBadge(label: book.genre!.trim()),
                  if (book.estimatedReadingMinutes > 0)
                    FigmaBadge(
                      label: _formatReadingDuration(
                        book.estimatedReadingMinutes,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _RecommendationStats(
                rating: book.rating,
                readCount: book.readCount,
              ),
              const SizedBox(height: 16),
              _RecommendationReasons(reasons: reasons),
              const SizedBox(height: 16),
              _RecommendationActions(
                inline: actionsInline,
                bookId: book.id,
                isFavorite: isFavorite,
                favoriteLoading: favoriteLoading,
                onOpen: book.id.isEmpty
                    ? null
                    : () => context.push(
                        AppRoutes.catalogBookDetailPath(book.id),
                      ),
                onToggleFavorite: book.id.isEmpty || favoriteLoading
                    ? null
                    : () => _toggleFavorite(book.id, isFavorite),
              ),
              if (_favoriteError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _favoriteError!,
                  style: TextStyle(
                    color: context.colors.destructive,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [cover, const SizedBox(height: 22), details],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cover,
              const SizedBox(width: 24),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleFavorite(String bookId, bool isFavorite) async {
    setState(() {
      _favoriteMutating = true;
      _favoriteError = null;
    });

    try {
      final repository = ref.read(favoriteRepositoryProvider);
      if (isFavorite) {
        await repository.removeFavorite(bookId);
      } else {
        await repository.addFavorite(bookId);
      }
      ref.invalidate(favoriteStatusProvider(bookId));
      ref.invalidate(myFavoritesProvider);
    } catch (error) {
      if (mounted) {
        setState(() => _favoriteError = AppError.messageFor(error));
      }
    } finally {
      if (mounted) {
        setState(() => _favoriteMutating = false);
      }
    }
  }
}

class _RecommendationHeading extends StatelessWidget {
  const _RecommendationHeading({
    required this.title,
    required this.author,
    required this.matchScore,
    required this.compact,
  });

  final String title;
  final String author;
  final int matchScore;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: compact ? 21 : 24,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (matchScore > 0) ...[
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: context.colors.primary,
                    size: compact ? 19 : 22,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$matchScore%',
                    style: TextStyle(
                      color: context.colors.primary,
                      fontSize: compact ? 21 : 24,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Correspondance',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RecommendationStats extends StatelessWidget {
  const _RecommendationStats({required this.rating, required this.readCount});

  final double rating;
  final int readCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        _RecommendationStat(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFFFB800),
          label: rating.toStringAsFixed(1),
        ),
        _RecommendationStat(
          icon: Icons.menu_book_outlined,
          iconColor: context.colors.textSecondary,
          label: '$readCount lectures',
        ),
      ],
    );
  }
}

class _RecommendationStat extends StatelessWidget {
  const _RecommendationStat({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 17),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _RecommendationReasons extends StatelessWidget {
  const _RecommendationReasons({required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('plumo_recommendation_reasons'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: context.colors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Pourquoi ce livre ?',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final reason in reasons)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 13,
                        height: 1.35,
                      ),
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

class _RecommendationActions extends StatelessWidget {
  const _RecommendationActions({
    required this.inline,
    required this.bookId,
    required this.isFavorite,
    required this.favoriteLoading,
    required this.onOpen,
    required this.onToggleFavorite,
  });

  final bool inline;
  final String bookId;
  final bool isFavorite;
  final bool favoriteLoading;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final openButton = SizedBox(
      key: ValueKey('plumo_recommendation_open_$bookId'),
      height: 48,
      child: FilledButton.icon(
        onPressed: onOpen,
        icon: const Icon(Icons.menu_book_outlined, size: 19),
        label: const Text('En savoir plus'),
      ),
    );
    final favoriteButton = SizedBox(
      key: ValueKey('plumo_recommendation_favorite_$bookId'),
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onToggleFavorite,
        icon: favoriteLoading
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
        label: Text(isFavorite ? 'Dans ma liste' : 'Ajouter à ma liste'),
      ),
    );

    if (!inline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [openButton, const SizedBox(height: 10), favoriteButton],
      );
    }

    return Row(
      children: [
        Expanded(child: openButton),
        const SizedBox(width: 12),
        SizedBox(width: 200, child: favoriteButton),
      ],
    );
  }
}

String _formatReadingDuration(int minutes) {
  if (minutes < 60) {
    return '$minutes min';
  }

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (remainingMinutes == 0) {
    return '${hours}h';
  }

  return '${hours}h${remainingMinutes.toString().padLeft(2, '0')}';
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
