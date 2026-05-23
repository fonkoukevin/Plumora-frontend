import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../data/models/beta_invitation_model.dart';
import '../data/repositories/beta_reading_repository.dart';

class BetaInvitationsScreen extends ConsumerStatefulWidget {
  const BetaInvitationsScreen({
    this.embedded = false,
    this.query = '',
    super.key,
  });

  final bool embedded;
  final String query;

  @override
  ConsumerState<BetaInvitationsScreen> createState() =>
      _BetaInvitationsScreenState();
}

class _BetaInvitationsScreenState extends ConsumerState<BetaInvitationsScreen> {
  String? _busyInvitationId;

  @override
  Widget build(BuildContext context) {
    final invitationsAsync = ref.watch(betaInvitationsProvider);
    final content = invitationsAsync.when(
      loading: () => const _LoadingPanel(),
      error: (error, _) => _ErrorPanel(
        message: AppError.messageFor(error),
        onRetry: () => ref.invalidate(betaInvitationsProvider),
      ),
      data: _buildContent,
    );

    if (widget.embedded) {
      return content;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 92),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: content,
        ),
      ),
    );
  }

  Widget _buildContent(List<BetaInvitationModel> invitations) {
    final active = invitations.where((invitation) => !invitation.isRefused);
    final accepted = invitations.where((invitation) => invitation.isAccepted);
    final feedbackCount = invitations.fold<int>(
      0,
      (sum, invitation) => sum + invitation.feedbackCount,
    );
    final normalizedQuery = widget.query.trim();
    final filteredInvitations = invitations
        .where((invitation) => _matchesInvitation(invitation, normalizedQuery))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlumoraCard(
          borderColor: const Color(0xFFD6CCE8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PlumoraIconTile(
                backgroundColor: Color(0xFF8FA889),
                child: Icon(Icons.forum_outlined, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Espace bêta-lecture',
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
        _SummaryGrid(
          activeCount: active.length,
          acceptedCount: accepted.length,
          feedbackCount: feedbackCount,
        ),
        const SizedBox(height: 20),
        if (filteredInvitations.isEmpty)
          normalizedQuery.isEmpty
              ? const _EmptyPanel()
              : const _QueryEmptyPanel()
        else
          for (final invitation in filteredInvitations) ...[
            _InvitationCard(
              invitation: invitation,
              busy: _busyInvitationId == invitation.id,
              onAccept: invitation.isPending
                  ? () => _acceptInvitation(invitation)
                  : null,
              onRefuse: invitation.isPending
                  ? () => _refuseInvitation(invitation)
                  : null,
              onRead: invitation.isAccepted && invitation.campaignId.isNotEmpty
                  ? () => context.go(
                      AppRoutes.betaChaptersPath(
                        invitation.campaignId,
                        invitationId: invitation.id,
                        bookId: invitation.bookId,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
          ],
      ],
    );
  }

  Future<void> _acceptInvitation(BetaInvitationModel invitation) async {
    setState(() => _busyInvitationId = invitation.id);
    try {
      await ref
          .read(betaReadingRepositoryProvider)
          .acceptInvitation(invitation.id);
      ref.invalidate(betaInvitationsProvider);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _busyInvitationId = null);
      }
    }
  }

  Future<void> _refuseInvitation(BetaInvitationModel invitation) async {
    setState(() => _busyInvitationId = invitation.id);
    try {
      await ref
          .read(betaReadingRepositoryProvider)
          .refuseInvitation(invitation.id);
      ref.invalidate(betaInvitationsProvider);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _busyInvitationId = null);
      }
    }
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
  }

  bool _matchesInvitation(BetaInvitationModel invitation, String query) {
    if (query.isEmpty) {
      return true;
    }

    final normalizedQuery = query.toLowerCase();
    return invitation.bookTitle.toLowerCase().contains(normalizedQuery) ||
        invitation.authorName.toLowerCase().contains(normalizedQuery);
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.activeCount,
    required this.acceptedCount,
    required this.feedbackCount,
  });

  final int activeCount;
  final int acceptedCount;
  final int feedbackCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 3 : 1;
        const spacing = 14.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [
            _StatCard(label: 'Invitations actives', value: '$activeCount'),
            _StatCard(label: 'Lectures acceptées', value: '$acceptedCount'),
            _StatCard(label: 'Retours envoyés', value: '$feedbackCount'),
          ].map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }
}

class _InvitationCard extends ConsumerWidget {
  const _InvitationCard({
    required this.invitation,
    required this.busy,
    required this.onAccept,
    required this.onRefuse,
    required this.onRead,
  });

  final BetaInvitationModel invitation;
  final bool busy;
  final VoidCallback? onAccept;
  final VoidCallback? onRefuse;
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = invitation.chaptersAvailable == 0
        ? 0.0
        : invitation.chaptersRead / invitation.chaptersAvailable;
    final title = invitation.bookTitle.trim().isEmpty
        ? 'Manuscrit bêta'
        : invitation.bookTitle;
    final author = invitation.authorName.trim().isEmpty
        ? 'Auteur Plumora'
        : invitation.authorName;
    final cachedCover = ref.watch(bookCoverBytesProvider(invitation.bookId));

    return PlumoraCard(
      leftAccent: _statusColor(invitation.status),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final cover = PlumoraBookCover(
            colors: _coverColors(invitation.bookId),
            imageUrl: invitation.coverUrl,
            imageBytes: cachedCover,
            width: compact ? 72 : 92,
            height: compact ? 102 : 124,
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: PlumoraColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  PlumoraBadge(
                    label: _statusLabel(invitation.status),
                    icon: _statusIcon(invitation.status),
                    backgroundColor: _statusBackground(invitation.status),
                    foregroundColor: _statusColor(invitation.status),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'par $author',
                style: const TextStyle(
                  color: PlumoraColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.schedule,
                    label: 'Deadline : ${_dateLabel(invitation.deadline)}',
                    foregroundColor: const Color(0xFFA4683E),
                    backgroundColor: const Color(0xFFF8E6D2),
                  ),
                  _InfoChip(
                    icon: Icons.menu_book_outlined,
                    label:
                        '${invitation.chaptersAvailable} chapitre${invitation.chaptersAvailable > 1 ? 's' : ''}',
                    foregroundColor: PlumoraColors.info,
                    backgroundColor: const Color(0xFFEAF3FF),
                  ),
                ],
              ),
              if (invitation.chaptersRead > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F5EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Votre progression',
                              style: TextStyle(
                                color: PlumoraColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '${invitation.chaptersRead}/${invitation.chaptersAvailable}',
                            style: const TextStyle(
                              color: PlumoraColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: progress.clamp(0, 1),
                          backgroundColor: Colors.white,
                          color: PlumoraColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (invitation.isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : onRefuse,
                        child: const Text('Refuser'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: busy ? null : onAccept,
                        child: Text(busy ? '...' : 'Accepter'),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: busy ? null : onRead,
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: Text(
                      invitation.chaptersRead == 0
                          ? 'Commencer la lecture'
                          : 'Continuer',
                    ),
                  ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

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
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return const PlumoraCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlumoraIconTile(
            backgroundColor: Color(0xFFE6EFE4),
            child: Icon(Icons.inbox_outlined, color: Color(0xFF5F7A5A)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aucune invitation bêta',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Les manuscrits partagés par les auteurs apparaîtront ici.',
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
    );
  }
}

class _QueryEmptyPanel extends StatelessWidget {
  const _QueryEmptyPanel();

  @override
  Widget build(BuildContext context) {
    return const PlumoraCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlumoraIconTile(
            backgroundColor: Color(0xFFE6EFE4),
            child: Icon(Icons.search_off_outlined, color: Color(0xFF5F7A5A)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aucun résultat',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Aucune bêta-lecture ne correspond à cette recherche.',
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
          const SizedBox(height: 16),
          Text(
            'Impossible de charger les invitations',
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

String _statusLabel(BetaInvitationStatus status) {
  return switch (status) {
    BetaInvitationStatus.pending => 'À accepter',
    BetaInvitationStatus.accepted => 'En cours',
    BetaInvitationStatus.refused => 'Refusée',
    BetaInvitationStatus.unknown => 'Invitation',
  };
}

IconData _statusIcon(BetaInvitationStatus status) {
  return switch (status) {
    BetaInvitationStatus.pending => Icons.schedule,
    BetaInvitationStatus.accepted => Icons.menu_book_outlined,
    BetaInvitationStatus.refused => Icons.block,
    BetaInvitationStatus.unknown => Icons.info_outline,
  };
}

Color _statusColor(BetaInvitationStatus status) {
  return switch (status) {
    BetaInvitationStatus.pending => const Color(0xFFA4683E),
    BetaInvitationStatus.accepted => const Color(0xFF5F7A5A),
    BetaInvitationStatus.refused => PlumoraColors.destructive,
    BetaInvitationStatus.unknown => PlumoraColors.textSecondary,
  };
}

Color _statusBackground(BetaInvitationStatus status) {
  return switch (status) {
    BetaInvitationStatus.pending => const Color(0xFFF8E6D2),
    BetaInvitationStatus.accepted => const Color(0xFFE6EFE4),
    BetaInvitationStatus.refused => const Color(0xFFF7E0DC),
    BetaInvitationStatus.unknown => PlumoraColors.muted,
  };
}

String _dateLabel(DateTime? date) {
  if (date == null) {
    return 'à venir';
  }

  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
}

List<Color> _coverColors(String seed) {
  final palettes = const [
    [Color(0xFFDC2626), Color(0xFFEA580C)],
    [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    [Color(0xFF2563EB), Color(0xFF06B6D4)],
    [Color(0xFF8FA889), Color(0xFF5F7A5A)],
  ];
  return palettes[seed.hashCode.abs() % palettes.length];
}
