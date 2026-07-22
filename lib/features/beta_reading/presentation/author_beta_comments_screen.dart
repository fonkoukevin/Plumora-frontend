import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/repositories/book_repository.dart';
import '../data/models/beta_comment_model.dart';
import '../data/repositories/beta_reading_repository.dart';

const double _betaFeedbackMaxContentWidth = 1488;

class AuthorBetaCommentsScreen extends ConsumerStatefulWidget {
  const AuthorBetaCommentsScreen({
    this.bookId,
    this.embedded = false,
    super.key,
  });

  final String? bookId;
  final bool embedded;

  @override
  ConsumerState<AuthorBetaCommentsScreen> createState() =>
      _AuthorBetaCommentsScreenState();
}

class _AuthorBetaCommentsScreenState
    extends ConsumerState<AuthorBetaCommentsScreen> {
  String _typeFilter = 'Tous';
  String _statusFilter = 'Tous';
  String? _busyCommentId;

  @override
  Widget build(BuildContext context) {
    final content = widget.bookId == null
        ? _buildAllBooksContent()
        : _buildSingleBookContent(widget.bookId!);

    if (widget.embedded) {
      return content;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 92),
      child: Center(
        child: ConstrainedBox(
          // The surrounding 16 px padding brings the complete frame to the
          // same 1520 px footprint as the Discover page.
          constraints: const BoxConstraints(
            maxWidth: _betaFeedbackMaxContentWidth,
          ),
          child: widget.bookId == null
              ? content
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FigmaBackButton(
                      label: 'Retour',
                      onTap: () => returnToPreviousOr(
                        context,
                        AppRoutes.authorBookDetailPath(widget.bookId!),
                      ),
                    ),
                    const SizedBox(height: 18),
                    content,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSingleBookContent(String bookId) {
    final bookAsync = ref.watch(authorBookProvider(bookId));
    final commentsAsync = ref.watch(betaCommentsForBookProvider(bookId));

    return bookAsync.when(
      loading: () => const _LoadingPanel(),
      error: (_, _) => commentsAsync.when(
        loading: () => const _LoadingPanel(),
        error: (error, _) => _ErrorPanel(
          message: AppError.messageFor(error),
          onRetry: () => ref.invalidate(betaCommentsForBookProvider(bookId)),
        ),
        data: (comments) => _CommentsContent(
          title: 'Retours bêta',
          subtitle:
              '${comments.length} commentaire${comments.length > 1 ? 's' : ''}',
          comments: comments,
          bookTitles: const {},
          typeFilter: _typeFilter,
          statusFilter: _statusFilter,
          busyCommentId: _busyCommentId,
          onTypeFilterChanged: (value) => setState(() => _typeFilter = value),
          onStatusFilterChanged: (value) =>
              setState(() => _statusFilter = value),
          onUpdateStatus: _updateStatus,
        ),
      ),
      data: (book) => commentsAsync.when(
        loading: () => const _LoadingPanel(),
        error: (error, _) => _ErrorPanel(
          message: AppError.messageFor(error),
          onRetry: () => ref.invalidate(betaCommentsForBookProvider(bookId)),
        ),
        data: (comments) => _CommentsContent(
          title: 'Retours bêta',
          subtitle:
              '${book.title.isEmpty ? 'Manuscrit' : book.title} - ${comments.length} commentaire${comments.length > 1 ? 's' : ''}',
          comments: comments,
          bookTitles: {book.id: book.title},
          typeFilter: _typeFilter,
          statusFilter: _statusFilter,
          busyCommentId: _busyCommentId,
          onTypeFilterChanged: (value) => setState(() => _typeFilter = value),
          onStatusFilterChanged: (value) =>
              setState(() => _statusFilter = value),
          onUpdateStatus: _updateStatus,
        ),
      ),
    );
  }

  Widget _buildAllBooksContent() {
    final booksAsync = ref.watch(myBooksProvider);

    return booksAsync.when(
      loading: () => const _LoadingPanel(),
      error: (error, _) => _ErrorPanel(
        message: AppError.messageFor(error),
        onRetry: () => ref.invalidate(myBooksProvider),
      ),
      data: (books) {
        final betaBooks = books
            .where(
              (book) =>
                  book.status == BookStatus.inBetaReading ||
                  book.status == BookStatus.inCorrection ||
                  book.feedbackCount > 0,
            )
            .toList(growable: false);

        if (betaBooks.isEmpty) {
          return const _PassivePanel(
            title: 'Aucun retour bêta',
            subtitle:
                'Les commentaires reçus sur vos livres en bêta-lecture apparaîtront ici.',
          );
        }

        final states = <_BookCommentsState>[];
        for (final book in betaBooks) {
          states.add(
            _BookCommentsState(
              book: book,
              value: ref.watch(betaCommentsForBookProvider(book.id)),
            ),
          );
        }

        final comments = <BetaCommentModel>[];
        Object? firstError;
        var loading = false;
        for (final state in states) {
          state.value.when(
            loading: () => loading = true,
            error: (error, _) => firstError ??= error,
            data: (items) => comments.addAll(items),
          );
        }

        if (loading && comments.isEmpty) {
          return const _LoadingPanel();
        }

        if (firstError != null && comments.isEmpty) {
          return _ErrorPanel(
            message: AppError.messageFor(firstError!),
            onRetry: () {
              for (final book in betaBooks) {
                ref.invalidate(betaCommentsForBookProvider(book.id));
              }
            },
          );
        }

        final titles = {for (final book in betaBooks) book.id: book.title};
        return _CommentsContent(
          title: 'Retours bêta récents',
          subtitle:
              '${comments.length} commentaire${comments.length > 1 ? 's' : ''} reçu${comments.length > 1 ? 's' : ''}',
          comments: comments,
          bookTitles: titles,
          typeFilter: _typeFilter,
          statusFilter: _statusFilter,
          busyCommentId: _busyCommentId,
          onTypeFilterChanged: (value) => setState(() => _typeFilter = value),
          onStatusFilterChanged: (value) =>
              setState(() => _statusFilter = value),
          onUpdateStatus: _updateStatus,
        );
      },
    );
  }

  Future<void> _updateStatus(
    BetaCommentModel comment,
    BetaCommentStatus status,
  ) async {
    setState(() => _busyCommentId = comment.id);
    try {
      await ref
          .read(betaReadingRepositoryProvider)
          .updateCommentStatus(comment.id, status);
      if (comment.bookId.isNotEmpty) {
        ref.invalidate(betaCommentsForBookProvider(comment.bookId));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _busyCommentId = null);
      }
    }
  }
}

class _CommentsContent extends StatelessWidget {
  const _CommentsContent({
    required this.title,
    required this.subtitle,
    required this.comments,
    required this.bookTitles,
    required this.typeFilter,
    required this.statusFilter,
    required this.busyCommentId,
    required this.onTypeFilterChanged,
    required this.onStatusFilterChanged,
    required this.onUpdateStatus,
  });

  final String title;
  final String subtitle;
  final List<BetaCommentModel> comments;
  final Map<String, String> bookTitles;
  final String typeFilter;
  final String statusFilter;
  final String? busyCommentId;
  final ValueChanged<String> onTypeFilterChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final void Function(BetaCommentModel, BetaCommentStatus) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final filtered = comments.where(_matchesFilters).toList(growable: false);
    final summary = _summaryFor(context, comments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: context.colors.textSecondary)),
        const SizedBox(height: 22),
        _SummaryGrid(summary: summary),
        const SizedBox(height: 20),
        _FilterBar(
          activeType: typeFilter,
          activeStatus: statusFilter,
          onTypeChanged: onTypeFilterChanged,
          onStatusChanged: onStatusFilterChanged,
        ),
        const SizedBox(height: 18),
        if (comments.isEmpty)
          const _PassivePanel(
            title: 'Aucun commentaire reçu',
            subtitle:
                'Les retours des bêta-lecteurs apparaîtront ici dès leur envoi.',
          )
        else if (filtered.isEmpty)
          const _PassivePanel(
            title: 'Aucun retour pour ce filtre',
            subtitle: 'Change de type ou de statut pour revoir les retours.',
          )
        else
          FigmaResponsiveGrid(
            minTileWidth: 620,
            maxColumns: 2,
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final comment in filtered)
                _AuthorCommentCard(
                  comment: comment,
                  bookTitle: bookTitles[comment.bookId],
                  busy: busyCommentId == comment.id,
                  onResolve: () =>
                      onUpdateStatus(comment, BetaCommentStatus.resolved),
                  onIgnore: () =>
                      onUpdateStatus(comment, BetaCommentStatus.ignored),
                ),
            ],
          ),
      ],
    );
  }

  bool _matchesFilters(BetaCommentModel comment) {
    final typeMatches =
        typeFilter == 'Tous' || comment.type.label == typeFilter;
    final statusMatches = switch (statusFilter) {
      'Tous' => true,
      'À traiter' =>
        comment.status == BetaCommentStatus.open ||
            comment.status == BetaCommentStatus.inProgress ||
            comment.status == BetaCommentStatus.unknown,
      'Résolus' => comment.status == BetaCommentStatus.resolved,
      'Ignorés' => comment.status == BetaCommentStatus.ignored,
      _ => true,
    };

    return typeMatches && statusMatches;
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final List<_SummaryItem> summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: summary
              .map((item) => SizedBox(width: width, child: _SummaryCard(item)))
              .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.item);

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      shadow: false,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.count}',
                  style: TextStyle(
                    color: context.colors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '${item.count}',
              style: TextStyle(
                color: item.color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.activeType,
    required this.activeStatus,
    required this.onTypeChanged,
    required this.onStatusChanged,
  });

  final String activeType;
  final String activeStatus;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onStatusChanged;

  static const _types = [
    'Tous',
    'Intrigue',
    'Personnage',
    'Style',
    'Rythme',
    'Continuité',
    'Faute',
    'Autre',
  ];

  static const _statuses = ['Tous', 'À traiter', 'Résolus', 'Ignorés'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipLine(
          icon: Icons.filter_list,
          values: _types,
          activeValue: activeType,
          onChanged: onTypeChanged,
        ),
        const SizedBox(height: 10),
        _ChipLine(
          icon: Icons.check_circle_outline,
          values: _statuses,
          activeValue: activeStatus,
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}

class _ChipLine extends StatelessWidget {
  const _ChipLine({
    required this.icon,
    required this.values,
    required this.activeValue,
    required this.onChanged,
  });

  final IconData icon;
  final List<String> values;
  final String activeValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Icon(icon, color: context.colors.textSecondary, size: 20),
          const SizedBox(width: 8),
          for (final value in values) ...[
            ChoiceChip(
              label: Text(value),
              selected: activeValue == value,
              onSelected: (_) => onChanged(value),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _AuthorCommentCard extends StatelessWidget {
  const _AuthorCommentCard({
    required this.comment,
    required this.bookTitle,
    required this.busy,
    required this.onResolve,
    required this.onIgnore,
  });

  final BetaCommentModel comment;
  final String? bookTitle;
  final bool busy;
  final VoidCallback onResolve;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(comment.status);
    final typeBadgeColor =
        _priorityColor(context, comment.priority) ??
        _typeColor(context, comment.type);
    final chapter = comment.chapterTitle.isEmpty
        ? 'Chapitre'
        : comment.chapterTitle;
    final reader =
        comment.betaReaderName == null || comment.betaReaderName!.trim().isEmpty
        ? 'Bêta-lecteur'
        : comment.betaReaderName!;

    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlumoraIconTile(
                backgroundColor: _typeColor(
                  context,
                  comment.type,
                ).withValues(alpha: 0.1),
                size: 44,
                child: Icon(
                  _typeIcon(comment.type),
                  color: _typeColor(context, comment.type),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PlumoraBadge(
                          label: chapter,
                          backgroundColor: context.colors.success.withValues(
                            alpha: 0.12,
                          ),
                          foregroundColor: context.colors.success,
                        ),
                        PlumoraBadge(
                          label: comment.type.label,
                          backgroundColor: typeBadgeColor.withValues(
                            alpha: 0.12,
                          ),
                          foregroundColor: typeBadgeColor,
                        ),
                        PlumoraBadge(
                          label: status,
                          backgroundColor: _statusColor(
                            context,
                            comment.status,
                          ).withValues(alpha: 0.12),
                          foregroundColor: _statusColor(
                            context,
                            comment.status,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (bookTitle != null && bookTitle!.isNotEmpty) ...[
                      Text(
                        bookTitle!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      comment.content,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (comment.selectedText != null &&
                        comment.selectedText!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '"${comment.selectedText}"',
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontStyle: FontStyle.italic,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Par $reader',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: comment.bookId.isEmpty
                    ? null
                    : () => context.push(
                        AppRoutes.chapterEditorPath(comment.bookId),
                      ),
                icon: const Icon(Icons.open_in_new, size: 17),
                label: const Text("Ouvrir dans l'éditeur"),
              ),
              FilledButton.icon(
                onPressed: busy || comment.status == BetaCommentStatus.resolved
                    ? null
                    : onResolve,
                icon: const Icon(Icons.check_circle_outline, size: 17),
                label: Text(busy ? '...' : 'Résoudre'),
              ),
              TextButton(
                onPressed: busy || comment.status == BetaCommentStatus.ignored
                    ? null
                    : onIgnore,
                child: const Text('Ignorer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookCommentsState {
  const _BookCommentsState({required this.book, required this.value});

  final BookModel book;
  final AsyncValue<List<BetaCommentModel>> value;
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

class _PassivePanel extends StatelessWidget {
  const _PassivePanel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlumoraIconTile(
            backgroundColor: context.colors.info.withValues(alpha: 0.12),
            child: Icon(Icons.forum_outlined, color: context.colors.info),
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
                  style: TextStyle(
                    color: context.colors.textSecondary,
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
          PlumoraIconTile(
            backgroundColor: context.colors.destructive.withValues(alpha: 0.12),
            child: Icon(Icons.error_outline, color: context.colors.destructive),
          ),
          const SizedBox(height: 16),
          Text(
            'Impossible de charger les retours',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: context.colors.textSecondary)),
          const SizedBox(height: 18),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

List<_SummaryItem> _summaryFor(
  BuildContext context,
  List<BetaCommentModel> comments,
) {
  int count(BetaCommentType type) {
    return comments.where((comment) => comment.type == type).length;
  }

  return [
    _SummaryItem(
      label: 'Intrigue',
      count: count(BetaCommentType.plot),
      icon: Icons.auto_stories_outlined,
      color: context.colors.destructive,
    ),
    _SummaryItem(
      label: 'Personnage',
      count: count(BetaCommentType.character),
      icon: Icons.person_outline,
      color: context.colors.info,
    ),
    _SummaryItem(
      label: 'Style',
      count: count(BetaCommentType.style),
      icon: Icons.auto_fix_high_outlined,
      color: const Color(0xFF7C3AED),
    ),
    _SummaryItem(
      label: 'Rythme',
      count: count(BetaCommentType.pacing),
      icon: Icons.schedule,
      color: const Color(0xFFC69200),
    ),
  ];
}

String _statusLabel(BetaCommentStatus status) {
  return switch (status) {
    BetaCommentStatus.open || BetaCommentStatus.inProgress => 'À traiter',
    BetaCommentStatus.resolved => 'Résolu',
    BetaCommentStatus.ignored => 'Ignoré',
    BetaCommentStatus.unknown => 'À traiter',
  };
}

Color _statusColor(BuildContext context, BetaCommentStatus status) {
  return switch (status) {
    BetaCommentStatus.resolved => context.colors.success,
    BetaCommentStatus.ignored => context.colors.textSecondary,
    BetaCommentStatus.open ||
    BetaCommentStatus.inProgress ||
    BetaCommentStatus.unknown => context.colors.primary,
  };
}

IconData _typeIcon(BetaCommentType type) {
  return switch (type) {
    BetaCommentType.plot => Icons.auto_stories_outlined,
    BetaCommentType.character => Icons.person_outline,
    BetaCommentType.style => Icons.auto_fix_high_outlined,
    BetaCommentType.pacing => Icons.schedule,
    BetaCommentType.continuity => Icons.sync_problem_outlined,
    BetaCommentType.typo => Icons.spellcheck,
    BetaCommentType.other => Icons.chat_bubble_outline,
  };
}

Color? _priorityColor(BuildContext context, BetaCommentPriority priority) {
  return switch (priority) {
    BetaCommentPriority.critical => context.colors.destructive,
    BetaCommentPriority.high => context.colors.destructive,
    BetaCommentPriority.medium => const Color(0xFFA4683E),
    BetaCommentPriority.low => context.colors.textSecondary,
    BetaCommentPriority.unknown => null,
  };
}

Color _typeColor(BuildContext context, BetaCommentType type) {
  return switch (type) {
    BetaCommentType.plot => context.colors.destructive,
    BetaCommentType.continuity => const Color(0xFFA4683E),
    BetaCommentType.typo => context.colors.info,
    BetaCommentType.pacing => const Color(0xFFC69200),
    BetaCommentType.style => const Color(0xFF8B5CF6),
    BetaCommentType.character => const Color(0xFF2563EB),
    BetaCommentType.other => context.colors.textSecondary,
  };
}
