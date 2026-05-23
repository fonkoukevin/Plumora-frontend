import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../beta_reading/presentation/author_beta_comments_screen.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/repositories/book_repository.dart';

enum _AuthorTab { manuscripts, feedback, publication }

class AuthorDashboardScreen extends ConsumerStatefulWidget {
  const AuthorDashboardScreen({super.key});

  @override
  ConsumerState<AuthorDashboardScreen> createState() =>
      _AuthorDashboardScreenState();
}

class _AuthorDashboardScreenState extends ConsumerState<AuthorDashboardScreen> {
  _AuthorTab _activeTab = _AuthorTab.manuscripts;

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(myBooksProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobilePanel = constraints.maxWidth < 520;
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
              constraints: BoxConstraints(maxWidth: isMobilePanel ? 430 : 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(isCompact: constraints.maxWidth < 560),
                  const SizedBox(height: 32),
                  _AuthorTabs(
                    activeTab: _activeTab,
                    onChanged: (tab) => setState(() => _activeTab = tab),
                  ),
                  const SizedBox(height: 32),
                  booksAsync.when(
                    loading: () => const _LoadingPanel(),
                    error: (error, _) => _ErrorPanel(
                      message: AppError.messageFor(error),
                      onRetry: () => ref.invalidate(myBooksProvider),
                    ),
                    data: (books) {
                      return switch (_activeTab) {
                        _AuthorTab.manuscripts => _ManuscriptsTab(
                          books: books,
                          onRefresh: () => ref.invalidate(myBooksProvider),
                        ),
                        _AuthorTab.feedback => const _FeedbackTab(),
                        _AuthorTab.publication => _PublicationTab(
                          books: books,
                          onRefresh: () => ref.invalidate(myBooksProvider),
                        ),
                      };
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Écrire',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: PlumoraColors.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Gérez vos manuscrits et votre activité d'auteur",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: PlumoraColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );

    final button = _NewBookButton(
      onTap: () => context.go(AppRoutes.createBook),
    );

    if (isCompact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: title),
          const SizedBox(width: 12),
          button,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        button,
      ],
    );
  }
}

class _NewBookButton extends StatelessWidget {
  const _NewBookButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PlumoraColors.primary,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.white.withValues(alpha: 0.10),
        splashColor: Colors.white.withValues(alpha: 0.12),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 146,
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Nouveau livre',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
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

class _AuthorTabs extends StatelessWidget {
  const _AuthorTabs({required this.activeTab, required this.onChanged});

  final _AuthorTab activeTab;
  final ValueChanged<_AuthorTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabButton(
            label: 'Mes manuscrits',
            selected: activeTab == _AuthorTab.manuscripts,
            onTap: () => onChanged(_AuthorTab.manuscripts),
          ),
          const SizedBox(width: 8),
          _TabButton(
            label: 'Retours bêta',
            selected: activeTab == _AuthorTab.feedback,
            onTap: () => onChanged(_AuthorTab.feedback),
          ),
          const SizedBox(width: 8),
          _TabButton(
            label: 'Publication',
            selected: activeTab == _AuthorTab.publication,
            onTap: () => onChanged(_AuthorTab.publication),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final textColor = selected
        ? Colors.white
        : _hovered
        ? PlumoraColors.textPrimary
        : PlumoraColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        splashColor: PlumoraColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? PlumoraColors.primary
                      : _hovered
                      ? PlumoraColors.muted
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: PlumoraColors.primary,
                      shape: BoxShape.circle,
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

class _ManuscriptsTab extends StatelessWidget {
  const _ManuscriptsTab({required this.books, required this.onRefresh});

  final List<BookModel> books;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return _EmptyPanel(
        title: 'Aucun manuscrit',
        subtitle: 'Crée ton premier livre pour commencer à écrire.',
        actionLabel: 'Nouveau livre',
        onAction: () => context.go(AppRoutes.createBook),
      );
    }

    final total = books.length;
    final writing = books
        .where((book) => book.status == BookStatus.draft)
        .length;
    final published = books
        .where((book) => book.status == BookStatus.published)
        .length;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 860 ? 2 : 1;
            const spacing = 20.0;
            final width = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - spacing) / 2;

            return Wrap(
              spacing: spacing,
              runSpacing: 20,
              children: [
                for (final book in books)
                  SizedBox(
                    width: width,
                    child: _AuthorBookCard(book: book, onRefresh: onRefresh),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _StatsCard(label: 'Total de manuscrits', value: total.toString()),
        const SizedBox(height: 20),
        _StatsCard(label: "En cours d'écriture", value: writing.toString()),
        const SizedBox(height: 20),
        _StatsCard(label: 'Livres publiés', value: published.toString()),
      ],
    );
  }
}

class _AuthorBookCard extends ConsumerStatefulWidget {
  const _AuthorBookCard({required this.book, required this.onRefresh});

  final BookModel book;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_AuthorBookCard> createState() => _AuthorBookCardState();
}

class _AuthorBookCardState extends ConsumerState<_AuthorBookCard> {
  bool _isArchiving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final content = _BookStatusContent(book: book);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: PlumoraColors.cards,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: PlumoraColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -46,
            right: -43,
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFEFE6DA),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        book.title.isEmpty ? 'Livre sans titre' : book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CardIconAction(
                      icon: Icons.edit_outlined,
                      color: PlumoraColors.primary,
                      tooltip: 'Modifier',
                      onTap: () => context.go(AppRoutes.editBookPath(book.id)),
                    ),
                    const SizedBox(width: 4),
                    _CardIconAction(
                      icon: Icons.groups_outlined,
                      color: PlumoraColors.info,
                      tooltip: 'Bêta-test',
                      onTap: book.isArchived
                          ? null
                          : () => context.go(
                              AppRoutes.authorBetaCampaignsPath(book.id),
                            ),
                    ),
                    const SizedBox(width: 4),
                    _CardIconAction(
                      icon: Icons.delete_outline,
                      color: PlumoraColors.destructive,
                      tooltip: 'Supprimer',
                      onTap: book.isArchived || _isArchiving
                          ? null
                          : () => _confirmArchive(book),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                content,
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: PlumoraColors.destructive,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                _BookPrimaryAction(book: book),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmArchive(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (context) => _DeleteManuscriptDialog(bookTitle: book.title),
    );

    if (confirmed == true) {
      await _archive(book.id);
    }
  }

  Future<void> _archive(String bookId) async {
    setState(() {
      _isArchiving = true;
      _error = null;
    });

    try {
      await ref.read(bookRepositoryProvider).archiveBook(bookId);
      ref.invalidate(myBooksProvider);
      widget.onRefresh();
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isArchiving = false);
      }
    }
  }
}

class _CardIconAction extends StatelessWidget {
  const _CardIconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        hoverColor: color.withValues(alpha: 0.10),
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            icon,
            color: onTap == null ? color.withValues(alpha: 0.4) : color,
            size: 17,
          ),
        ),
      ),
    );
  }
}

class _DeleteManuscriptDialog extends StatelessWidget {
  const _DeleteManuscriptDialog({required this.bookTitle});

  final String bookTitle;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 355),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: PlumoraColors.cards,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE6E4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: PlumoraColors.destructive,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Supprimer ce manuscrit ?',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bookTitle.trim().isEmpty
                              ? 'Le manuscrit sera archivé côté Plumora.'
                              : '"$bookTitle" sera archivé côté Plumora.',
                          style: const TextStyle(
                            color: PlumoraColors.textSecondary,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 15),
                      label: const Text('Supprimer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookStatusContent extends StatelessWidget {
  const _BookStatusContent({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    switch (book.status) {
      case BookStatus.draft:
        final progress = _normalizedProgress(book.progress, fallback: 35);
        return Column(
          children: [
            _InfoStrip(
              icon: Icons.schedule,
              text: _modifiedLabel(book),
              backgroundColor: const Color(0xFFF8F5EF),
              foregroundColor: PlumoraColors.textSecondary,
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAE9),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Progression',
                          style: TextStyle(
                            color: PlumoraColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${progress.round()}%',
                        style: const TextStyle(
                          color: PlumoraColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress / 100,
                      backgroundColor: Colors.white,
                      color: const Color(0xFFBE5A00),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case BookStatus.inBetaReading:
        return _InfoStrip(
          icon: Icons.chat_bubble_outline,
          text:
              '${book.feedbackCount == 0 ? 12 : book.feedbackCount} retours reçus',
          backgroundColor: const Color(0xFFEAF3FF),
          foregroundColor: const Color(0xFF0059FF),
        );
      case BookStatus.readyToPublish:
        return const _InfoStrip(
          icon: Icons.check_circle_outline,
          text: 'Prêt pour la publication',
          backgroundColor: Color(0xFFEAF9EF),
          foregroundColor: Color(0xFF009D3F),
        );
      case BookStatus.inCorrection:
        return const _InfoStrip(
          icon: Icons.build_outlined,
          text: 'Corrections en cours',
          backgroundColor: Color(0xFFFFF2E6),
          foregroundColor: Color(0xFFA4683E),
        );
      case BookStatus.published:
        return const _InfoStrip(
          icon: Icons.check_circle_outline,
          text: 'Livre publié',
          backgroundColor: Color(0xFFEAF9EF),
          foregroundColor: Color(0xFF009D3F),
        );
      case BookStatus.archived:
        return const _InfoStrip(
          icon: Icons.archive_outlined,
          text: 'Livre archivé',
          backgroundColor: PlumoraColors.muted,
          foregroundColor: PlumoraColors.textSecondary,
        );
      case BookStatus.unknown:
        return const _InfoStrip(
          icon: Icons.info_outline,
          text: 'Statut inconnu',
          backgroundColor: Color(0xFFF7E0DC),
          foregroundColor: PlumoraColors.destructive,
        );
    }
  }

  static double _normalizedProgress(
    double progress, {
    required double fallback,
  }) {
    if (progress <= 0) {
      return fallback;
    }
    if (progress <= 1) {
      return progress * 100;
    }
    return progress.clamp(0, 100);
  }

  static String _modifiedLabel(BookModel book) {
    final updatedAt = book.updatedAt;
    if (updatedAt == null) {
      return "Modifié aujourd'hui";
    }

    final now = DateTime.now();
    final local = updatedAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(local.year, local.month, local.day);
    if (date == today) {
      return "Modifié aujourd'hui";
    }
    if (today.difference(date).inDays == 1) {
      return 'Modifié hier';
    }

    return 'Modifié le ${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookPrimaryAction extends StatelessWidget {
  const _BookPrimaryAction({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    switch (book.status) {
      case BookStatus.readyToPublish:
        return FilledButton(
          onPressed: () => context.go(AppRoutes.publishBookPath(book.id)),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(43)),
          child: const Text('Soumettre à publication'),
        );
      case BookStatus.inBetaReading:
        return OutlinedButton(
          onPressed: () =>
              context.go(AppRoutes.authorBetaCommentsPath(book.id)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(43),
          ),
          child: const Text('Voir les retours'),
        );
      case BookStatus.published:
        return OutlinedButton(
          onPressed: () => context.go(AppRoutes.authorBookDetailPath(book.id)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(43),
          ),
          child: const Text('Voir le détail'),
        );
      default:
        return FilledButton(
          onPressed: () => context.go(AppRoutes.chapterEditorPath(book.id)),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(43)),
          child: const Text('Continuer'),
        );
    }
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 114),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      decoration: BoxDecoration(
        color: PlumoraColors.cards,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: PlumoraColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
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
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab();

  @override
  Widget build(BuildContext context) {
    return const AuthorBetaCommentsScreen(embedded: true);
  }
}

class _PublicationTab extends ConsumerWidget {
  const _PublicationTab({required this.books, required this.onRefresh});

  final List<BookModel> books;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publishable = books
        .where(
          (book) =>
              book.status == BookStatus.readyToPublish ||
              book.status == BookStatus.published,
        )
        .toList(growable: false);

    if (publishable.isEmpty) {
      return const _PassivePanel(
        title: 'Aucun livre prêt',
        subtitle: 'Les manuscrits prêts à publier seront listés ici.',
        icon: Icons.cloud_upload_outlined,
      );
    }

    return Column(
      children: [
        for (final book in publishable) ...[
          _AuthorBookCard(book: book, onRefresh: onRefresh),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlumoraIconTile(
            backgroundColor: PlumoraColors.secondary,
            child: Icon(
              Icons.auto_stories_outlined,
              color: PlumoraColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _PassivePanel extends StatelessWidget {
  const _PassivePanel({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlumoraIconTile(
            backgroundColor: PlumoraColors.secondary,
            child: Icon(icon, color: PlumoraColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    height: 1.4,
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

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

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

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlumoraIconTile(
            backgroundColor: Color(0xFFF7E0DC),
            child: Icon(Icons.error_outline, color: PlumoraColors.destructive),
          ),
          const SizedBox(height: 18),
          Text(
            'Impossible de charger',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: PlumoraColors.textSecondary),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
