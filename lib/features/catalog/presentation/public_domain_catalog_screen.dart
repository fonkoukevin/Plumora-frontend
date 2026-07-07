import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../data/models/external_book_model.dart';
import '../data/repositories/external_book_repository.dart';

class PublicDomainCatalogScreen extends ConsumerStatefulWidget {
  const PublicDomainCatalogScreen({
    this.initialSearch = '',
    this.initialLanguage,
    this.initialTopic = '',
    super.key,
  });

  final String initialSearch;
  final String? initialLanguage;
  final String initialTopic;

  @override
  ConsumerState<PublicDomainCatalogScreen> createState() =>
      _PublicDomainCatalogScreenState();
}

class _PublicDomainCatalogScreenState
    extends ConsumerState<PublicDomainCatalogScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _topicController;
  String? _language;
  List<ExternalBook> _books = const [];
  int _page = 0;
  int _totalElements = 0;
  bool _last = true;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch);
    _topicController = TextEditingController(text: widget.initialTopic);
    _language = _normalizeLanguage(widget.initialLanguage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load(reset: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FigmaScreen(
      maxWidth: 1040,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigmaBackButton(
            label: 'Retour',
            onTap: () => context.go(AppRoutes.discover),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Domaine public',
                      style: GoogleFonts.playfairDisplay(
                        color: PlumoraColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Classiques et livres libres disponibles dans Plumora.',
                      style: TextStyle(color: PlumoraColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FigmaGradientIcon(
                icon: Icons.public,
                size: 54,
                colors: const [PlumoraColors.primary, PlumoraColors.accent],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SearchPanel(
            searchController: _searchController,
            topicController: _topicController,
            language: _language,
            onLanguageChanged: (value) => setState(() => _language = value),
            onSubmitted: _search,
            onClear: _clearFilters,
          ),
          const SizedBox(height: 24),
          _ResultsHeader(
            count: _totalElements,
            loading: _loading,
            hasResults: _books.isNotEmpty,
          ),
          const SizedBox(height: 14),
          _buildResults(),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading && _books.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(44),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null && _books.isEmpty) {
      return _StateCard(
        title: 'Catalogue externe indisponible',
        subtitle: _error!,
        action: FilledButton(
          onPressed: () => _load(reset: true),
          child: const Text('Reessayer'),
        ),
      );
    }

    if (_books.isEmpty) {
      return const FigmaEmptyState(
        title: 'Aucun livre',
        message: 'Essaie un autre titre, auteur, sujet ou filtre de langue.',
        icon: Icons.public,
      );
    }

    return Column(
      children: [
        for (final book in _books) ...[
          _ExternalBookCard(book: book),
          const SizedBox(height: 14),
        ],
        if (_error != null) ...[
          const SizedBox(height: 2),
          _InlineError(message: _error!, onRetry: () => _load(reset: false)),
        ],
        if (!_last) ...[
          const SizedBox(height: 8),
          Center(
            child: FilledButton.icon(
              onPressed: _loadingMore ? null : () => _load(reset: false),
              icon: _loadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: const Text('Charger plus'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _search() async {
    _updateUrl();
    await _load(reset: true);
  }

  Future<void> _clearFilters() async {
    _searchController.clear();
    _topicController.clear();
    setState(() => _language = null);
    context.go(AppRoutes.publicDomainCatalog);
    await _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (_loading || _loadingMore) {
      return;
    }

    setState(() {
      _error = null;
      if (reset) {
        _loading = true;
        _books = const [];
        _page = 0;
        _last = true;
      } else {
        _loadingMore = true;
      }
    });

    final nextPage = reset ? 0 : _page + 1;

    try {
      final response = await ref
          .read(externalBookRepositoryProvider)
          .searchExternalBooks(
            search: _searchController.text,
            language: _language,
            topic: _topicController.text,
            page: nextPage,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _books = reset ? response.content : [..._books, ...response.content];
        _page = response.page;
        _totalElements = response.totalElements;
        _last = response.last;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _updateUrl() {
    context.go(
      AppRoutes.publicDomainCatalogPath(
        search: _searchController.text,
        language: _language,
        topic: _topicController.text,
      ),
    );
  }

  String? _normalizeLanguage(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'fr' || normalized == 'en') {
      return normalized;
    }

    return null;
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.searchController,
    required this.topicController,
    required this.language,
    required this.onLanguageChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController searchController;
  final TextEditingController topicController;
  final String? language;
  final ValueChanged<String?> onLanguageChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSubmitted(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Titre ou auteur...',
              suffixIcon: IconButton(
                tooltip: 'Rechercher',
                onPressed: onSubmitted,
                icon: const Icon(Icons.arrow_forward, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 680;
              final topicField = TextField(
                controller: topicController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSubmitted(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.sell_outlined),
                  hintText: 'Sujet',
                ),
              );

              final languageFilters = _LanguageFilters(
                language: language,
                onChanged: onLanguageChanged,
              );

              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    languageFilters,
                    const SizedBox(height: 12),
                    topicField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: languageFilters),
                  const SizedBox(width: 14),
                  SizedBox(width: 260, child: topicField),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Effacer'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onSubmitted,
                icon: const Icon(Icons.search),
                label: const Text('Rechercher'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageFilters extends StatelessWidget {
  const _LanguageFilters({required this.language, required this.onChanged});

  final String? language;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = language ?? '';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FigmaPillTab(
            label: 'Toutes',
            selected: selected.isEmpty,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          FigmaPillTab(
            label: 'FR',
            selected: selected == 'fr',
            onTap: () => onChanged('fr'),
          ),
          const SizedBox(width: 8),
          FigmaPillTab(
            label: 'EN',
            selected: selected == 'en',
            onTap: () => onChanged('en'),
          ),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.count,
    required this.loading,
    required this.hasResults,
  });

  final int count;
  final bool loading;
  final bool hasResults;

  @override
  Widget build(BuildContext context) {
    final label = loading && !hasResults
        ? 'Recherche en cours'
        : count <= 0
        ? 'Resultats'
        : '$count resultats';

    return FigmaSectionHeader(
      title: label,
      icon: Icons.public,
      trailing: loading && hasResults
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}

class _ExternalBookCard extends StatelessWidget {
  const _ExternalBookCard({required this.book});

  final ExternalBook book;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      onTap: () =>
          context.go(AppRoutes.publicDomainBookDetailPath(book.externalId)),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlumoraBookCover(
            colors: _coverColors(book.externalId),
            imageUrl: book.coverUrl,
            width: 76,
            height: 112,
            radius: 12,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title.isEmpty ? 'Livre sans titre' : book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlumoraColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.authorLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  book.summary.trim().isEmpty
                      ? 'Aucun resume disponible.'
                      : book.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PlumoraBadge(
                      label: book.imported ? 'Importe' : 'Domaine public',
                      backgroundColor: book.imported
                          ? PlumoraColors.success.withValues(alpha: 0.14)
                          : const Color(0xFFEADFCF),
                      foregroundColor: book.imported
                          ? PlumoraColors.success
                          : PlumoraColors.primary,
                    ),
                    if (book.languages.isNotEmpty)
                      PlumoraBadge(
                        label: book.languages.take(2).join(', ').toUpperCase(),
                      ),
                    if (book.downloadCount > 0)
                      PlumoraBadge(
                        icon: Icons.download_outlined,
                        label: '${book.downloadCount}',
                      ),
                    if (book.subjects.isNotEmpty)
                      Tooltip(
                        message: book.subjects.first,
                        child: PlumoraBadge(
                          label: book.subjects.first,
                          maxWidth: 260,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_right, color: PlumoraColors.textSecondary),
              const SizedBox(height: 6),
              const Text(
                'Details',
                style: TextStyle(
                  color: PlumoraColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

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
            subtitle,
            style: const TextStyle(color: PlumoraColors.textSecondary),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      color: PlumoraColors.destructive.withValues(alpha: 0.06),
      borderColor: PlumoraColors.destructive.withValues(alpha: 0.18),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: PlumoraColors.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: PlumoraColors.textSecondary),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reessayer')),
        ],
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
