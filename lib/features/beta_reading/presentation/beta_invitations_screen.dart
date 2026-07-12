import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/repositories/book_cover_cache.dart';
import '../data/models/beta_campaign_model.dart';
import '../data/models/beta_invitation_model.dart';
import '../data/repositories/beta_reading_repository.dart';
import 'beta_engagement_providers.dart';

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
  bool _markedSeen = false;

  @override
  Widget build(BuildContext context) {
    final openCampaignsAsync = ref.watch(betaOpenCampaignsProvider);
    final invitationsAsync = ref.watch(betaInvitationsProvider);
    final query = widget.query.trim().toLowerCase();

    if (!_markedSeen &&
        invitationsAsync.hasValue &&
        openCampaignsAsync.hasValue) {
      _markedSeen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          markBetaOpportunitiesSeen(ref);
        }
      });
    }

    final content = openCampaignsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => _ErrorPanel(
        message: AppError.messageFor(error),
        onRetry: () => ref.invalidate(betaOpenCampaignsProvider),
      ),
      data: (campaigns) {
        final filtered = campaigns.where((campaign) {
          if (query.isEmpty) {
            return true;
          }
          return campaign.bookTitle.toLowerCase().contains(query) ||
              (campaign.authorUsername ?? '').toLowerCase().contains(query);
        }).toList();

        final pendingInvitations = ref.watch(
          betaActionablePendingInvitationsProvider,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.embedded)
              FigmaBackButton(
                label: "Retour a l'accueil",
                onTap: () => context.go(AppRoutes.home),
              ),
            if (!widget.embedded) const SizedBox(height: 18),
            Text(
              'Beta-tests',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 38,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lisez des manuscrits avant publication et aidez les auteurs avec vos retours',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            _BetaStats(
              openCampaignsCount: campaigns.length,
              pendingInvitationsCount: pendingInvitations.length,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: TextStyle(
                  color: context.colors.destructive,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 26),
            Text(
              'Campagnes ouvertes',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Tout beta-lecteur peut rejoindre l'une de ces campagnes et "
              'commenter directement, sans invitation.',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              const FigmaEmptyState(
                title: 'Aucune campagne active',
                message:
                    'Les campagnes de beta-lecture ouvertes par les auteurs apparaitront ici.',
                icon: Icons.edit_note_outlined,
              )
            else
              for (final campaign in filtered) ...[
                _OpenCampaignCard(campaign: campaign),
                const SizedBox(height: 12),
              ],
            if (pendingInvitations.isNotEmpty) ...[
              const SizedBox(height: 26),
              Text(
                'Mes invitations en attente',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Une invitation ne conditionne plus l'acces a la campagne : "
                "elle sert juste a signaler a l'auteur ta participation.",
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              for (final invitation in pendingInvitations) ...[
                _InvitationCard(
                  invitation: invitation,
                  mutating: _mutatingIds.contains(invitation.id),
                  onAccept: () => _respond(invitation, accept: true),
                  onRefuse: () => _respond(invitation, accept: false),
                ),
                const SizedBox(height: 12),
              ],
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
      if (accept) {
        await repository.acceptInvitation(invitation.id);
        await touchBetaCampaignActivity(ref, invitation.campaignId);
      } else {
        await repository.refuseInvitation(invitation.id);
      }
      ref.invalidate(betaInvitationsProvider);
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
  const _BetaStats({
    required this.openCampaignsCount,
    required this.pendingInvitationsCount,
  });

  final int openCampaignsCount;
  final int pendingInvitationsCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final children = [
          FigmaStatCard(
            label: 'Campagnes actives',
            value: openCampaignsCount.toString(),
          ),
          FigmaStatCard(
            label: 'Invitations en attente',
            value: pendingInvitationsCount.toString(),
            valueColor: context.colors.accent,
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

class _OpenCampaignCard extends ConsumerWidget {
  const _OpenCampaignCard({required this.campaign});

  final BetaCampaignModel campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedCover = ref.watch(bookCoverBytesProvider(campaign.bookId));
    final author = (campaign.authorUsername ?? '').trim();

    return FigmaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlumoraBookCover(
            width: 92,
            height: 124,
            radius: 14,
            colors: _coverColors(campaign.bookId),
            imageUrl: campaign.coverUrl,
            imageBytes: cachedCover,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.bookTitle.isEmpty
                      ? 'Manuscrit sans titre'
                      : campaign.bookTitle,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (author.isNotEmpty)
                  Text(
                    'par $author',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                if (campaign.deadline != null) ...[
                  const SizedBox(height: 10),
                  _MiniMetric(
                    icon: Icons.schedule,
                    label: 'Deadline : ${_shortDate(campaign.deadline!)}',
                    color: context.colors.accent,
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => context.go(
                    AppRoutes.betaChaptersPath(
                      campaign.id,
                      bookId: campaign.bookId,
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: const Text('Lire et commenter'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.mutating,
    required this.onAccept,
    required this.onRefuse,
  });

  final BetaInvitationModel invitation;
  final bool mutating;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;

  @override
  Widget build(BuildContext context) {
    final author = invitation.authorName.trim();

    return FigmaCard(
      child: Row(
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
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (author.isNotEmpty)
                  Text(
                    'par $author',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: mutating ? null : onAccept,
            icon: mutating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, size: 18),
            label: const Text('Accepter'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: mutating ? null : onRefuse,
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? context.colors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: resolvedColor),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: resolvedColor, fontSize: 13)),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      color: context.colors.info.withValues(alpha: 0.08),
      borderColor: context.colors.info.withValues(alpha: 0.30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FigmaGradientIcon(
            icon: Icons.info_outline,
            size: 46,
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conseils pour un bon beta-test',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Soyez constructif et bienveillant, notez les incoherences, partagez ce que vous avez aime et respectez les delais fixes par l'auteur.",
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
            'Campagnes indisponibles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: context.colors.textSecondary)),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Reessayer')),
        ],
      ),
    );
  }
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
