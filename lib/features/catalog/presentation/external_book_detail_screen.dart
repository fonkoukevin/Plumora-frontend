import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../reading/data/models/review_model.dart';
import '../../reading/data/repositories/favorite_repository.dart';
import '../../reading/data/repositories/review_repository.dart';
import '../data/models/external_book_model.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/external_book_repository.dart';

class ExternalBookDetailScreen extends ConsumerStatefulWidget {
  const ExternalBookDetailScreen({required this.gutendexId, super.key});

  final String gutendexId;

  @override
  ConsumerState<ExternalBookDetailScreen> createState() =>
      _ExternalBookDetailScreenState();
}

class _ExternalBookDetailScreenState
    extends ConsumerState<ExternalBookDetailScreen> {
  bool _importing = false;
  bool _favoriteMutating = false;
  bool _reviewSubmitting = false;
  String? _importedBookId;
  String? _importError;
  String? _favoriteError;
  String? _reviewError;

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(externalBookDetailProvider(widget.gutendexId));
    final reviewsAsync = ref.watch(
      externalBookReviewsProvider(widget.gutendexId),
    );

    return FigmaScreen(
      maxWidth: 680,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigmaBackButton(
            label: 'Retour',
            onTap: () => context.go(AppRoutes.discover),
          ),
          const SizedBox(height: 24),
          bookAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _ErrorCard(
              title: 'Livre introuvable',
              message: AppError.messageFor(error),
              onRetry: () =>
                  ref.invalidate(externalBookDetailProvider(widget.gutendexId)),
            ),
            data: (book) {
              final effectiveBook = _effectiveBook(book);
              final internalBookId = effectiveBook.internalBookId?.trim();
              final favoriteAsync =
                  internalBookId == null || internalBookId.isEmpty
                  ? null
                  : ref.watch(favoriteStatusProvider(internalBookId));
              return _BookDetailContent(
                book: effectiveBook,
                importing: _importing,
                importError: _importError,
                isFavorite: favoriteAsync?.valueOrNull ?? false,
                favoriteLoading:
                    (favoriteAsync?.isLoading ?? false) || _favoriteMutating,
                favoriteError: _favoriteError,
                onReadInPlumora: () =>
                    _readInPlumora(effectiveBook.internalBookId),
                onSource: () =>
                    _openUrl(effectiveBook.readUrl ?? effectiveBook.sourceUrl),
                onImport: () => _importBook(effectiveBook),
                onToggleFavorite: () => _toggleFavorite(
                  effectiveBook,
                  favoriteAsync?.valueOrNull ?? false,
                ),
                reviewsAsync: reviewsAsync,
                reviewSubmitting: _reviewSubmitting,
                reviewError: _reviewError,
                onWriteReview: () => _openReviewDialog(effectiveBook),
                onRetryReviews: () => ref.invalidate(
                  externalBookReviewsProvider(widget.gutendexId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  ExternalBook _effectiveBook(ExternalBook book) {
    final importedBookId = _importedBookId?.trim();
    if (importedBookId == null || importedBookId.isEmpty) {
      return book;
    }

    return book.copyWith(imported: true, internalBookId: importedBookId);
  }

  Future<void> _openUrl(String? value) async {
    final url = value?.trim();
    final uri = url == null || url.isEmpty ? null : Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      _showMessage('Lien indisponible pour ce livre.');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showMessage('Impossible d ouvrir le lien externe.');
    }
  }

  Future<void> _importBook(ExternalBook book) async {
    setState(() {
      _importing = true;
      _importError = null;
    });

    try {
      final importedBookId = await _importAndRememberBook(book);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Livre disponible dans Plumora.'),
          action: importedBookId.isEmpty
              ? null
              : SnackBarAction(
                  label: 'Lire',
                  onPressed: () {
                    context.go(AppRoutes.readingPath(importedBookId));
                  },
                ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _importError = _importErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  Future<String> _importAndRememberBook(ExternalBook book) async {
    final importedBook = await ref
        .read(externalBookRepositoryProvider)
        .importGutendexBook(book.externalId);

    ref.invalidate(latestCatalogBooksProvider);
    ref.invalidate(popularCatalogBooksProvider);
    ref.invalidate(catalogBooksProvider(''));
    ref.invalidate(catalogBookDetailProvider(importedBook.id));
    ref.invalidate(externalBookDetailProvider(book.externalId));
    ref.invalidate(favoriteStatusProvider(importedBook.id));

    if (mounted) {
      setState(() => _importedBookId = importedBook.id);
    }

    return importedBook.id;
  }

  Future<void> _toggleFavorite(ExternalBook book, bool isFavorite) async {
    final currentBookId = book.internalBookId?.trim();
    final needsImport = currentBookId == null || currentBookId.isEmpty;

    setState(() {
      _favoriteMutating = true;
      _favoriteError = null;
      _importError = null;
      if (needsImport) {
        _importing = true;
      }
    });

    try {
      final bookId = needsImport
          ? await _importAndRememberBook(book)
          : currentBookId;
      final repository = ref.read(favoriteRepositoryProvider);
      if (isFavorite) {
        await repository.removeFavorite(bookId);
      } else {
        await repository.addFavorite(bookId);
      }

      ref.invalidate(favoriteStatusProvider(bookId));
      ref.invalidate(myFavoritesProvider);

      if (!mounted) {
        return;
      }

      _showMessage(
        isFavorite
            ? 'Livre retire des favoris.'
            : needsImport
            ? 'Livre importe et ajoute aux favoris.'
            : 'Livre ajoute aux favoris.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _favoriteError = _favoriteErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _favoriteMutating = false;
          if (needsImport) {
            _importing = false;
          }
        });
      }
    }
  }

  Future<void> _openReviewDialog(ExternalBook book) async {
    final request = await showDialog<ReviewUpsertRequest>(
      context: context,
      builder: (context) => const _ReviewDialog(),
    );
    if (request == null || !mounted) {
      return;
    }

    setState(() {
      _reviewSubmitting = true;
      _reviewError = null;
    });

    try {
      await ref
          .read(reviewRepositoryProvider)
          .createExternalBookReview(book.externalId, request);

      ref.invalidate(externalBookReviewsProvider(book.externalId));
      ref.invalidate(myReviewsProvider);

      if (!mounted) {
        return;
      }

      _showMessage('Avis publie.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _reviewError = _reviewErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _reviewSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _readInPlumora(String? internalBookId) {
    final bookId = internalBookId?.trim();
    if (bookId == null || bookId.isEmpty) {
      _showMessage('Lecture Plumora indisponible pour ce livre.');
      return;
    }

    context.go(AppRoutes.readingPath(bookId));
  }

  String _importErrorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return 'Connecte-toi pour importer ce livre dans Plumora.';
      }
      if (statusCode == 403) {
        return "Le serveur refuse encore l'import pour ce compte.";
      }
    }

    return AppError.messageFor(error);
  }

  String _reviewErrorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return 'Connecte-toi pour publier un avis.';
      }
      if (statusCode == 403) {
        return "Tu n'as pas les droits pour publier cet avis.";
      }
      if (statusCode == 404 || statusCode == 500 || statusCode == 501) {
        return 'Impossible de publier ton avis pour le moment.';
      }
    }

    return AppError.messageFor(error);
  }

  String _favoriteErrorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return 'Connecte-toi pour ajouter ce livre aux favoris.';
      }
      if (statusCode == 403) {
        return "Tu n'as pas les droits pour modifier tes favoris.";
      }
    }

    return AppError.messageFor(error);
  }
}

class _BookDetailContent extends StatelessWidget {
  const _BookDetailContent({
    required this.book,
    required this.importing,
    required this.isFavorite,
    required this.favoriteLoading,
    required this.onReadInPlumora,
    required this.onSource,
    required this.onImport,
    required this.onToggleFavorite,
    required this.reviewsAsync,
    required this.reviewSubmitting,
    required this.onWriteReview,
    required this.onRetryReviews,
    this.importError,
    this.favoriteError,
    this.reviewError,
  });

  final ExternalBook book;
  final bool importing;
  final bool isFavorite;
  final bool favoriteLoading;
  final bool reviewSubmitting;
  final VoidCallback onReadInPlumora;
  final VoidCallback onSource;
  final VoidCallback onImport;
  final VoidCallback onToggleFavorite;
  final AsyncValue<List<ReviewModel>> reviewsAsync;
  final VoidCallback onWriteReview;
  final VoidCallback onRetryReviews;
  final String? importError;
  final String? favoriteError;
  final String? reviewError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroCover(book: book),
        const SizedBox(height: 14),
        if (book.canReadInPlumora)
          FilledButton.icon(
            onPressed: onReadInPlumora,
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Lire dans Plumora'),
          )
        else if (book.imported)
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Lecture Plumora indisponible'),
          )
        else
          FilledButton.icon(
            onPressed: importing ? null : onImport,
            icon: importing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_to_photos_outlined),
            label: Text(
              importing ? 'Import en cours...' : 'Importer dans Plumora',
            ),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: importing || favoriteLoading ? null : onToggleFavorite,
          icon: favoriteLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          label: Text(
            favoriteLoading
                ? 'Mise a jour...'
                : isFavorite
                ? 'Retirer des favoris'
                : 'Ajouter aux favoris',
          ),
        ),
        if (favoriteError != null) ...[
          const SizedBox(height: 8),
          Text(
            favoriteError!,
            style: TextStyle(
              color: context.colors.destructive,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (_hasExternalSource(book)) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onSource,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Voir la source'),
          ),
        ] else if (!book.canReadInPlumora) ...[
          const SizedBox(height: 10),
          Text(
            'Aucune source lisible externe disponible pour ce livre.',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
        ],
        if (importError != null) ...[
          const SizedBox(height: 8),
          Text(
            importError!,
            style: TextStyle(
              color: context.colors.destructive,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 28),
        _BookInfo(book: book),
        const SizedBox(height: 20),
        _SummaryCard(summary: book.summary),
        const SizedBox(height: 18),
        _AuthorCard(book: book),
        const SizedBox(height: 18),
        _ReviewsPreview(
          reviewsAsync: reviewsAsync,
          submitting: reviewSubmitting,
          error: reviewError,
          onWriteReview: onWriteReview,
          onRetry: onRetryReviews,
        ),
      ],
    );
  }
}

class _HeroCover extends StatelessWidget {
  const _HeroCover({required this.book});

  final ExternalBook book;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: PlumoraBookCover(
        width: double.infinity,
        height: double.infinity,
        radius: 10,
        colors: _coverColors(
          book.externalId.isEmpty ? book.title : book.externalId,
        ),
        imageUrl: book.coverUrl,
      ),
    );
  }
}

class _BookInfo extends StatelessWidget {
  const _BookInfo({required this.book});

  final ExternalBook book;

  @override
  Widget build(BuildContext context) {
    final firstSubject = book.subjects.isEmpty ? null : book.subjects.first;
    final language = book.languages.isEmpty
        ? null
        : book.languages.take(2).join(', ').toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title.isEmpty ? 'Livre sans titre' : book.title,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'par ${book.authorLabel}',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (firstSubject != null)
              Tooltip(
                message: firstSubject,
                child: PlumoraBadge(label: firstSubject, maxWidth: 170),
              ),
            if (language != null) PlumoraBadge(label: language),
            if (book.mediaType != null) PlumoraBadge(label: book.mediaType!),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 22,
          runSpacing: 14,
          children: [
            const _MetaMetric(
              icon: Icons.star,
              iconColor: Color(0xFFF5B400),
              label: '4.7',
              sub: '(Gutendex)',
            ),
            _MetaMetric(
              icon: Icons.menu_book_outlined,
              label: _formatCompact(book.downloadCount),
              sub: 'lectures',
            ),
            _MetaMetric(
              icon: Icons.schedule,
              label: book.canReadInPlumora
                  ? 'Lecture Plumora'
                  : book.imported
                  ? 'Lecture indisponible'
                  : 'Import requis',
              sub: '',
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaMetric extends StatelessWidget {
  const _MetaMetric({
    required this.icon,
    required this.label,
    required this.sub,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor ?? context.colors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (sub.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            sub,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatefulWidget {
  const _SummaryCard({required this.summary});

  final String summary;

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.summary.trim().isEmpty
        ? 'Aucun resume disponible pour ce livre.'
        : widget.summary.trim();
    final canCollapse = text.length > 360;

    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resume',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            maxLines: canCollapse && !_expanded ? 5 : null,
            overflow: canCollapse && !_expanded
                ? TextOverflow.ellipsis
                : TextOverflow.visible,
            style: TextStyle(
              color: context.colors.textSecondary,
              height: 1.55,
            ),
          ),
          if (canCollapse) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Voir moins' : 'Voir plus'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({required this.book});

  final ExternalBook book;

  @override
  Widget build(BuildContext context) {
    final initials = book.authorLabel
        .split(RegExp(r'\s+|,'))
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part.trim()[0].toUpperCase())
        .join();

    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "A propos de l'auteur",
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: context.colors.primary,
                child: Text(
                  initials.isEmpty ? 'A' : initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.authorLabel,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${book.source} - domaine public',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${book.subjects.length} sujets repertories  -  ${_formatCompact(book.downloadCount)} lectures',
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ReviewsPreview extends StatelessWidget {
  const _ReviewsPreview({
    required this.reviewsAsync,
    required this.submitting,
    required this.onWriteReview,
    required this.onRetry,
    this.error,
  });

  final AsyncValue<List<ReviewModel>> reviewsAsync;
  final bool submitting;
  final VoidCallback onWriteReview;
  final VoidCallback onRetry;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final loadedReviews = reviewsAsync.valueOrNull;
    final shouldShowReviewsState = error == null || loadedReviews != null;

    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Avis des lecteurs',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: submitting ? null : onWriteReview,
                child: Text(submitting ? 'Publication...' : 'Donner mon avis'),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(
                color: context.colors.destructive,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (shouldShowReviewsState) ...[
            const SizedBox(height: 16),
            reviewsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _ReviewsError(
                message: _reviewLoadErrorMessage(error),
                onRetry: onRetry,
              ),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Text(
                    'Aucun avis pour ce livre pour le moment.',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      height: 1.4,
                    ),
                  );
                }

                final visibleReviews = reviews.take(4).toList();
                return Column(
                  children: [
                    for (
                      var index = 0;
                      index < visibleReviews.length;
                      index++
                    ) ...[
                      _ReviewItem(review: visibleReviews[index]),
                      if (index != visibleReviews.length - 1)
                        Divider(color: context.colors.border),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewsError extends StatelessWidget {
  const _ReviewsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: onRetry, child: const Text('Reessayer')),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Stars(rating: review.rating),
              Text(
                review.userName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (review.createdAt != null)
                Text(
                  _shortDate(review.createdAt!),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: TextStyle(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var value = 1; value <= 5; value++)
          Icon(
            value <= rating ? Icons.star : Icons.star_border,
            color: const Color(0xFFF5C84C),
            size: 16,
          ),
      ],
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _controller = TextEditingController();
  int _rating = 5;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Donner mon avis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Note', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var value = 1; value <= 5; value++)
                IconButton(
                  tooltip: '$value etoiles',
                  onPressed: () => setState(() => _rating = value),
                  icon: Icon(
                    value <= _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFF5C84C),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Commentaire',
              hintText: 'Partage ton ressenti sur ce livre...',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: context.colors.destructive,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Publier')),
      ],
    );
  }

  void _submit() {
    final comment = _controller.text.trim();
    if (comment.length < 3) {
      setState(() => _error = 'Ajoute un commentaire un peu plus detaille.');
      return;
    }

    Navigator.of(
      context,
    ).pop(ReviewUpsertRequest(rating: _rating, comment: comment));
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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

bool _hasExternalSource(ExternalBook book) {
  return (book.readUrl?.trim().isNotEmpty ?? false) ||
      (book.sourceUrl?.trim().isNotEmpty ?? false);
}

String _reviewLoadErrorMessage(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return 'Connecte-toi pour voir les avis de ce livre.';
    }
    if (statusCode == 403) {
      return "Tu n'as pas les droits pour voir ces avis.";
    }
    if (statusCode == 404 || statusCode == 500 || statusCode == 501) {
      return 'Les avis ne sont pas disponibles pour le moment.';
    }
  }

  return AppError.messageFor(error);
}

String _shortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatCompact(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }

  return value.toString();
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
