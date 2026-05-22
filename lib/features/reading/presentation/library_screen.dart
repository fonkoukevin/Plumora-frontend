import 'package:flutter/material.dart';

import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _activeTab = 'Mes lectures';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final horizontal = isWide ? 32.0 : 16.0;
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
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bibliothèque',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: PlumoraColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tous vos livres au même endroit',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PlumoraColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PlumoraSegmentedTabs(
                    tabs: const ['Mes lectures', 'Favoris', 'Bêta-lectures'],
                    selectedTab: _activeTab,
                    onSelected: (value) => setState(() => _activeTab = value),
                  ),
                  const SizedBox(height: 26),
                  if (_activeTab == 'Mes lectures') const _ReadingsTab(),
                  if (_activeTab == 'Favoris') const _FavoritesTab(),
                  if (_activeTab == 'Bêta-lectures') const _BetaReadingsTab(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReadingsTab extends StatelessWidget {
  const _ReadingsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final book in _savedBooks) ...[
          _ReadingCard(book: book),
          const SizedBox(height: 16),
        ],
        const _LibraryStats(),
      ],
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.book});

  final _LibraryBook book;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      leftAccent: PlumoraColors.primary,
      onTap: () {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 480;
          final cover = PlumoraBookCover(
            colors: book.colors,
            width: compact ? 72 : 96,
            height: compact ? 104 : 128,
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  PlumoraBadge(
                    label: book.progress == 100 ? 'Terminé' : 'En cours',
                    backgroundColor: book.progress == 100
                        ? const Color(0xFFEADFCF)
                        : const Color(0xFFE6EFE4),
                    foregroundColor: book.progress == 100
                        ? const Color(0xFF7A5E2F)
                        : const Color(0xFF5F7A5A),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'par ${book.author}',
                style: const TextStyle(
                  color: PlumoraColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F0FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Progression de lecture',
                            style: TextStyle(
                              color: PlumoraColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${book.progress}%',
                          style: const TextStyle(
                            color: PlumoraColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: book.progress / 100,
                        backgroundColor: Colors.white,
                        color: PlumoraColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _Meta(icon: Icons.schedule, label: 'Lu ${book.lastRead}'),
                  _RatingStars(rating: book.rating),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [cover, const SizedBox(height: 14), details],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cover,
              const SizedBox(width: 18),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlumoraCard(
          borderColor: const Color(0xFFF1C8C8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PlumoraIconTile(
                backgroundColor: Color(0xFFE95858),
                child: Icon(Icons.favorite, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes Favoris',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Les livres que vous avez adorés et que vous voulez retrouver facilement.',
                      style: TextStyle(
                        color: PlumoraColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 620
                ? 3
                : 2;
            const spacing = 14.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: 14,
              children: [
                for (final book in _savedBooks.take(4))
                  SizedBox(
                    width: width,
                    child: _FavoriteCard(book: book),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.book});

  final _LibraryBook book;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      padding: EdgeInsets.zero,
      clip: true,
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: book.colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFFE95858),
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 7),
                _RatingStars(rating: book.rating, small: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BetaReadingsTab extends StatelessWidget {
  const _BetaReadingsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlumoraCard(
          borderColor: const Color(0xFFD6CCE8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PlumoraIconTile(
                child: Icon(Icons.forum_outlined, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Espace Bêta-lecture',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lisez les manuscrits avant publication et aidez les auteurs avec vos retours constructifs.',
                      style: TextStyle(
                        color: PlumoraColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final beta in _betaBooks) ...[
          _BetaBookCard(book: beta),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _BetaBookCard extends StatelessWidget {
  const _BetaBookCard({required this.book});

  final _BetaBook book;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      leftAccent: PlumoraColors.primary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlumoraBookCover(colors: book.colors, width: 82, height: 112),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    PlumoraBadge(
                      label: book.status,
                      backgroundColor: book.status == 'À lire'
                          ? const Color(0xFFE6EFE4)
                          : const Color(0xFFF8E6D2),
                      foregroundColor: book.status == 'À lire'
                          ? const Color(0xFF5F7A5A)
                          : const Color(0xFFA4683E),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'par ${book.author}',
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoChip(
                  icon: Icons.schedule,
                  label: 'Deadline : ${book.deadline}',
                  foregroundColor: const Color(0xFFA4683E),
                  backgroundColor: const Color(0xFFF8E6D2),
                ),
                if (book.chaptersRead > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: book.chaptersRead / book.totalChapters,
                      backgroundColor: PlumoraColors.muted,
                      color: PlumoraColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    child: Text(
                      book.status == 'À lire'
                          ? 'Commencer la lecture'
                          : 'Continuer',
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

class _LibraryStats extends StatelessWidget {
  const _LibraryStats();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 3 : 1;
        const spacing = 16.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: const [
            _LibraryStat(label: 'Livres sauvegardés', value: '12'),
            _LibraryStat(label: 'Livres terminés', value: '8'),
            _LibraryStat(label: 'Temps de lecture total', value: '45h'),
          ].map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }
}

class _LibraryStat extends StatelessWidget {
  const _LibraryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      shadow: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: PlumoraColors.primary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: PlumoraColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: PlumoraColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating, this.small = false});

  final int rating;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 13.0 : 15.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < rating; index++)
          Icon(Icons.star, size: size, color: const Color(0xFFF5C84C)),
        const SizedBox(width: 5),
        Text(
          '$rating/5',
          style: TextStyle(
            color: PlumoraColors.textPrimary,
            fontSize: small ? 11 : 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foregroundColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

const _savedBooks = [
  _LibraryBook(
    title: "Les Chroniques d'Eldoria",
    author: 'Sophie Martin',
    progress: 65,
    lastRead: 'il y a 2 heures',
    rating: 5,
    colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
  ),
  _LibraryBook(
    title: 'Au-delà des Étoiles',
    author: 'Marc Dubois',
    progress: 23,
    lastRead: 'hier',
    rating: 4,
    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
  ),
  _LibraryBook(
    title: 'Le Dernier Refuge',
    author: 'Emma Laurent',
    progress: 100,
    lastRead: 'il y a 3 jours',
    rating: 5,
    colors: [Color(0xFFDC2626), Color(0xFFEA580C)],
  ),
];

const _betaBooks = [
  _BetaBook(
    title: 'La Nuit Rouge',
    author: 'Kevin Fonkou',
    status: 'À lire',
    deadline: '12 juin',
    chaptersRead: 0,
    totalChapters: 8,
    colors: [Color(0xFFDC2626), Color(0xFFEA580C)],
  ),
  _BetaBook(
    title: 'Les Ombres de Minuit',
    author: 'Sophie Martin',
    status: 'Retour en cours',
    deadline: '20 juin',
    chaptersRead: 5,
    totalChapters: 10,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  ),
];

class _LibraryBook {
  const _LibraryBook({
    required this.title,
    required this.author,
    required this.progress,
    required this.lastRead,
    required this.rating,
    required this.colors,
  });

  final String title;
  final String author;
  final int progress;
  final String lastRead;
  final int rating;
  final List<Color> colors;
}

class _BetaBook {
  const _BetaBook({
    required this.title,
    required this.author,
    required this.status,
    required this.deadline,
    required this.chaptersRead,
    required this.totalChapters,
    required this.colors,
  });

  final String title;
  final String author;
  final String status;
  final String deadline;
  final int chaptersRead;
  final int totalChapters;
  final List<Color> colors;
}
