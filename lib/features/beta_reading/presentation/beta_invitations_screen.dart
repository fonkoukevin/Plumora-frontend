import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
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
  final Set<String> _mutatingIds = {};
  String? _error;

  @override
  Widget build(BuildContext context) {
    final invitationsAsync = ref.watch(betaInvitationsProvider);

    final content = invitationsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => _ErrorPanel(
        message: AppError.messageFor(error),
        onRetry: () => ref.invalidate(betaInvitationsProvider),
      ),
      data: (invitations) {
        final query = widget.query.trim().toLowerCase();
        final filtered = invitations.where((invitation) {
          if (query.isEmpty) {
            return true;
          }
          return invitation.bookTitle.toLowerCase().contains(query) ||
              invitation.authorName.toLowerCase().contains(query);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.embedded)
              FigmaBackButton(
                label: "Retour a l'accueil",
                onTap: () => context.go(AppRoutes.home),
              ),
            if (!widget.embedded) const SizedBox(height: 18),
            const Text(
              'Beta-tests',
              style: TextStyle(
                color: PlumoraColors.textPrimary,
                fontSize: 38,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lisez des manuscrits avant publication et aidez les auteurs avec vos retours',
              style: TextStyle(
                color: PlumoraColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            _BetaStats(invitations: invitations),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: const TextStyle(
                  color: PlumoraColors.destructive,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 26),
            const Text(
              'Invitations et manuscrits',
              style: TextStyle(
                color: PlumoraColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              const FigmaEmptyState(
                title: 'Aucune invitation',
                message:
                    'Les invitations de beta-lecture liees a ton compte apparaitront ici.',
                icon: Icons.edit_note_outlined,
              )
            else
              for (final invitation in filtered) ...[
                _BetaInviteCard(
                  invitation: invitation,
                  mutating: _mutatingIds.contains(invitation.id),
                  onAccept: invitation.isPending
                      ? () => _respond(invitation, accept: true)
                      : null,
                  onRefuse: invitation.isPending
                      ? () => _respond(invitation, accept: false)
                      : null,
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 14),
            const _TipsCard(),
          ],
        );
      },
    );

    if (widget.embedded) {
      return content;
    }

    return FigmaScreen(
      maxWidth: 1120,
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 92),
      child: content,
    );
  }

  Future<void> _respond(
    BetaInvitationModel invitation, {
    required bool accept,
  }) async {
    setState(() {
      _mutatingIds.add(invitation.id);
      _error = null;
    });

    try {
      final repository = ref.read(betaReadingRepositoryProvider);
      final updated = accept
          ? await repository.acceptInvitation(invitation.id)
          : await repository.refuseInvitation(invitation.id);
      ref.invalidate(betaInvitationsProvider);

      if (accept && mounted) {
        context.go(
          AppRoutes.betaChaptersPath(
            updated.campaignId.isEmpty
                ? invitation.campaignId
                : updated.campaignId,
            invitationId: updated.id,
            bookId: updated.bookId,
          ),
        );
      }
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _mutatingIds.remove(invitation.id));
      }
    }
  }
}

class _BetaStats extends StatelessWidget {
  const _BetaStats({required this.invitations});

  final List<BetaInvitationModel> invitations;

  @override
  Widget build(BuildContext context) {
    final active = invitations
        .where((invitation) => invitation.isAccepted)
        .length;
    final pending = invitations
        .where((invitation) => invitation.isPending)
        .length;
    final feedbacks = invitations.fold<int>(
      0,
      (sum, invitation) => sum + invitation.feedbackCount,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final children = [
          FigmaStatCard(label: 'Actives', value: active.toString()),
          FigmaStatCard(
            label: 'En attente',
            value: pending.toString(),
            valueColor: PlumoraColors.accent,
          ),
          FigmaStatCard(
            label: 'Retours donnes',
            value: feedbacks.toString(),
            valueColor: PlumoraColors.secondary,
          ),
        ];
        if (compact) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }
}

class _BetaInviteCard extends ConsumerWidget {
  const _BetaInviteCard({
    required this.invitation,
    required this.mutating,
    required this.onAccept,
    required this.onRefuse,
  });

  final BetaInvitationModel invitation;
  final bool mutating;
  final VoidCallback? onAccept;
  final VoidCallback? onRefuse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = invitation.isRefused;
    final progress = invitation.chaptersAvailable == 0
        ? 0.0
        : invitation.chaptersRead / invitation.chaptersAvailable;
    final cachedCover = ref.watch(bookCoverBytesProvider(invitation.bookId));

    return FigmaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlumoraBookCover(
            width: 92,
            height: 124,
            radius: 14,
            colors: _coverColors(invitation.bookId),
            imageUrl: invitation.coverUrl,
            imageBytes: cachedCover,
          ),
          const SizedBox(width: 16),
          Expanded(
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
                            invitation.bookTitle.isEmpty
                                ? 'Manuscrit sans titre'
                                : invitation.bookTitle,
                            style: const TextStyle(
                              color: PlumoraColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'par ${invitation.authorName}',
                            style: const TextStyle(
                              color: PlumoraColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FigmaBadge(label: _statusLabel(invitation.status)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _MiniMetric(
                      icon: Icons.chat_bubble_outline,
                      label: '${invitation.chaptersAvailable} chapitres',
                    ),
                    _MiniMetric(
                      icon: Icons.thumb_up_outlined,
                      label: '${invitation.feedbackCount} retours donnes',
                    ),
                    if (invitation.deadline != null)
                      _MiniMetric(
                        icon: Icons.schedule,
                        label: 'Deadline : ${_shortDate(invitation.deadline!)}',
                        color: PlumoraColors.accent,
                      ),
                  ],
                ),
                if (invitation.isAccepted &&
                    invitation.chaptersAvailable > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Progression',
                        style: TextStyle(
                          color: PlumoraColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${invitation.chaptersRead}/${invitation.chaptersAvailable} chapitres',
                        style: const TextStyle(
                          color: PlumoraColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  FigmaProgressBar(value: progress),
                ],
                const SizedBox(height: 14),
                if (invitation.isPending)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: mutating ? null : onAccept,
                          icon: mutating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Accepter'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: mutating ? null : onRefuse,
                        child: const Text('Refuser'),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: completed
                            ? OutlinedButton(
                                onPressed: null,
                                child: const Text('Invitation refusee'),
                              )
                            : FilledButton(
                                onPressed: () => context.go(
                                  AppRoutes.betaChaptersPath(
                                    invitation.campaignId,
                                    invitationId: invitation.id,
                                    bookId: invitation.bookId,
                                  ),
                                ),
                                child: const Text('Continuer la lecture'),
                              ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.label,
    this.color = PlumoraColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      color: const Color(0xFFEFF6FF),
      borderColor: const Color(0xFFBFDBFE),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigmaGradientIcon(
            icon: Icons.info_outline,
            size: 46,
            colors: [Colors.blue, Color(0xFF2563EB)],
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conseils pour un bon beta-test',
                  style: TextStyle(
                    color: PlumoraColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Soyez constructif et bienveillant, notez les incoherences, partagez ce que vous avez aime et respectez les delais fixes par l'auteur.",
                  style: TextStyle(
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
            'Invitations indisponibles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: PlumoraColors.textSecondary),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Reessayer')),
        ],
      ),
    );
  }
}

String _statusLabel(BetaInvitationStatus status) {
  return switch (status) {
    BetaInvitationStatus.pending => 'Nouveau',
    BetaInvitationStatus.accepted => 'Acceptee',
    BetaInvitationStatus.refused => 'Refusee',
    BetaInvitationStatus.unknown => 'Inconnue',
  };
}

String _shortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
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
