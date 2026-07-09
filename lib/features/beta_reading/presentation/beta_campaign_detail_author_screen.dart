import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../data/models/beta_campaign_model.dart';
import '../data/models/beta_comment_model.dart';
import '../data/models/beta_invitation_model.dart';
import '../data/models/beta_shared_chapter_model.dart';
import '../data/repositories/beta_reading_repository.dart';

class BetaCampaignDetailAuthorScreen extends ConsumerStatefulWidget {
  const BetaCampaignDetailAuthorScreen({
    required this.campaignId,
    this.bookId,
    super.key,
  });

  final String campaignId;
  final String? bookId;

  @override
  ConsumerState<BetaCampaignDetailAuthorScreen> createState() =>
      _BetaCampaignDetailAuthorScreenState();
}

class _BetaCampaignDetailAuthorScreenState
    extends ConsumerState<BetaCampaignDetailAuthorScreen> {
  bool _isClosing = false;
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final campaignAsync = ref.watch(betaCampaignProvider(widget.campaignId));
    final chaptersAsync = ref.watch(
      betaSharedChaptersProvider(widget.campaignId),
    );
    final commentsAsync = ref.watch(
      betaCommentsForCampaignProvider(widget.campaignId),
    );
    final invitationsAsync = ref.watch(
      betaCampaignInvitationsProvider(widget.campaignId),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 760 ? 32.0 : 16.0;
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 92.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            28,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: campaignAsync.when(
                loading: () => const _LoadingCard(),
                error: (error, _) => _StateCard(
                  title: 'Campagne introuvable',
                  subtitle: AppError.messageFor(error),
                  action: FilledButton(
                    onPressed: () =>
                        ref.invalidate(betaCampaignProvider(widget.campaignId)),
                    child: const Text('Réessayer'),
                  ),
                ),
                data: (campaign) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: _isClosing ? null : () => _goBack(campaign),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Retour'),
                    ),
                    const SizedBox(height: 22),
                    _CampaignHeader(
                      campaign: campaign,
                      isClosing: _isClosing,
                      isCancelling: _isCancelling,
                      onClose: campaign.status == BetaCampaignStatus.active
                          ? () => _closeCampaign(campaign)
                          : null,
                      onCancel: campaign.status == BetaCampaignStatus.active
                          ? () => _cancelCampaign(campaign)
                          : null,
                    ),
                    const SizedBox(height: 24),
                    _AsyncInvitations(
                      invitationsAsync: invitationsAsync,
                      onRetry: () => ref.invalidate(
                        betaCampaignInvitationsProvider(widget.campaignId),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AsyncChapters(
                      chaptersAsync: chaptersAsync,
                      onRetry: () => ref.invalidate(
                        betaSharedChaptersProvider(widget.campaignId),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AsyncComments(
                      commentsAsync: commentsAsync,
                      onRetry: () => ref.invalidate(
                        betaCommentsForCampaignProvider(widget.campaignId),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _goBack(BetaCampaignModel campaign) {
    final bookId = widget.bookId?.trim().isNotEmpty == true
        ? widget.bookId!.trim()
        : campaign.bookId;
    context.go(
      bookId.isEmpty
          ? AppRoutes.write
          : AppRoutes.authorBetaCampaignsPath(bookId),
    );
  }

  Future<void> _closeCampaign(BetaCampaignModel campaign) async {
    setState(() => _isClosing = true);
    try {
      await ref.read(betaReadingRepositoryProvider).closeCampaign(campaign.id);
      ref.invalidate(betaCampaignProvider(campaign.id));
      if (campaign.bookId.isNotEmpty) {
        ref.invalidate(betaCampaignsForBookProvider(campaign.bookId));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isClosing = false);
      }
    }
  }

  Future<void> _cancelCampaign(BetaCampaignModel campaign) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler cette campagne ?'),
        content: const Text(
          "Les bêta-lecteurs ne pourront plus lire ni commenter cette "
          "campagne. Cette action n'est pas réversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Annuler la campagne'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _isCancelling = true);
    try {
      await ref.read(betaReadingRepositoryProvider).cancelCampaign(campaign.id);
      ref.invalidate(betaCampaignProvider(campaign.id));
      if (campaign.bookId.isNotEmpty) {
        ref.invalidate(betaCampaignsForBookProvider(campaign.bookId));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }
}

class _CampaignHeader extends StatelessWidget {
  const _CampaignHeader({
    required this.campaign,
    required this.isClosing,
    required this.isCancelling,
    required this.onClose,
    required this.onCancel,
  });

  final BetaCampaignModel campaign;
  final bool isClosing;
  final bool isCancelling;
  final VoidCallback? onClose;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlumoraIconTile(
            backgroundColor: PlumoraColors.info,
            child: Icon(Icons.groups_outlined, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.bookTitle.isEmpty
                      ? 'Campagne bêta'
                      : campaign.bookTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: PlumoraColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  campaign.instructions?.isNotEmpty == true
                      ? campaign.instructions!
                      : 'Aucune consigne renseignée.',
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    PlumoraBadge(label: campaign.status.label),
                    if (campaign.deadline != null)
                      PlumoraBadge(
                        label: _dateLabel(campaign.deadline!),
                        backgroundColor: PlumoraColors.muted,
                        foregroundColor: PlumoraColors.textSecondary,
                        icon: Icons.schedule,
                      ),
                    OutlinedButton.icon(
                      onPressed: isClosing || isCancelling ? null : onClose,
                      icon: const Icon(Icons.lock_outline, size: 17),
                      label: Text(isClosing ? 'Fermeture...' : 'Fermer'),
                    ),
                    if (onCancel != null)
                      TextButton.icon(
                        onPressed: isClosing || isCancelling ? null : onCancel,
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 17,
                          color: PlumoraColors.destructive,
                        ),
                        label: Text(
                          isCancelling ? 'Annulation...' : 'Annuler',
                          style: const TextStyle(
                            color: PlumoraColors.destructive,
                          ),
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

class _AsyncInvitations extends StatelessWidget {
  const _AsyncInvitations({
    required this.invitationsAsync,
    required this.onRetry,
  });

  final AsyncValue<List<BetaInvitationModel>> invitationsAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return invitationsAsync.when(
      loading: () => const _LoadingCard(),
      error: (error, _) => _StateCard(
        title: 'Invitations indisponibles',
        subtitle: AppError.messageFor(error),
        action: FilledButton(
          onPressed: onRetry,
          child: const Text('Réessayer'),
        ),
      ),
      data: (invitations) => PlumoraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invités (${invitations.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              "L'invitation ne conditionne pas l'accès : tout bêta-lecteur "
              'peut déjà lire et commenter cette campagne.',
              style: TextStyle(
                color: PlumoraColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            if (invitations.isEmpty)
              const Text(
                "Aucun bêta-lecteur invité personnellement pour l'instant.",
                style: TextStyle(color: PlumoraColors.textSecondary),
              )
            else
              for (final invitation in invitations) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.person_outline,
                    color: PlumoraColors.primary,
                  ),
                  title: Text(
                    invitation.betaReaderName?.trim().isNotEmpty == true
                        ? invitation.betaReaderName!
                        : 'Bêta-lecteur',
                  ),
                  trailing: PlumoraBadge(
                    label: _invitationStatusLabel(invitation.status),
                  ),
                ),
                const Divider(height: 18),
              ],
          ],
        ),
      ),
    );
  }
}

String _invitationStatusLabel(BetaInvitationStatus status) {
  return switch (status) {
    BetaInvitationStatus.pending => 'En attente',
    BetaInvitationStatus.accepted => 'Acceptée',
    BetaInvitationStatus.refused => 'Refusée',
    BetaInvitationStatus.unknown => 'Inconnue',
  };
}

class _AsyncChapters extends StatelessWidget {
  const _AsyncChapters({required this.chaptersAsync, required this.onRetry});

  final AsyncValue<List<BetaSharedChapterModel>> chaptersAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return chaptersAsync.when(
      loading: () => const _LoadingCard(),
      error: (error, _) => _StateCard(
        title: 'Chapitres partagés indisponibles',
        subtitle: AppError.messageFor(error),
        action: FilledButton(
          onPressed: onRetry,
          child: const Text('Réessayer'),
        ),
      ),
      data: (chapters) => PlumoraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chapitres partagés',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            if (chapters.isEmpty)
              const Text(
                'Aucun chapitre partagé pour cette campagne.',
                style: TextStyle(color: PlumoraColors.textSecondary),
              )
            else
              for (final chapter in chapters) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: PlumoraColors.secondary,
                    foregroundColor: PlumoraColors.primary,
                    child: Text(chapter.order == 0 ? '-' : '${chapter.order}'),
                  ),
                  title: Text(
                    chapter.title.isEmpty
                        ? 'Chapitre sans titre'
                        : chapter.title,
                  ),
                  subtitle: Text('${chapter.content.length} caractères'),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _AsyncComments extends StatelessWidget {
  const _AsyncComments({required this.commentsAsync, required this.onRetry});

  final AsyncValue<List<BetaCommentModel>> commentsAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return commentsAsync.when(
      loading: () => const _LoadingCard(),
      error: (error, _) => _StateCard(
        title: 'Retours indisponibles',
        subtitle: AppError.messageFor(error),
        action: FilledButton(
          onPressed: onRetry,
          child: const Text('Réessayer'),
        ),
      ),
      data: (comments) => PlumoraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Retours bêta (${comments.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            if (comments.isEmpty)
              const Text(
                'Aucun commentaire reçu pour cette campagne.',
                style: TextStyle(color: PlumoraColors.textSecondary),
              )
            else
              for (final comment in comments) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.forum_outlined,
                    color: PlumoraColors.primary,
                  ),
                  title: Text(comment.content),
                  subtitle: Text(comment.type.label),
                ),
                const Divider(height: 18),
              ],
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

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

class _StateCard extends StatelessWidget {
  const _StateCard({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
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

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
