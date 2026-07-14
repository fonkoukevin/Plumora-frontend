import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
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
                error: (error, _) => FigmaEmptyState(
                  icon: Icons.search_off,
                  title: 'Campagne introuvable',
                  message: AppError.messageFor(error),
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
          PlumoraIconTile(
            backgroundColor: context.colors.info,
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
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  campaign.instructions?.isNotEmpty == true
                      ? campaign.instructions!
                      : 'Aucune consigne renseignée.',
                  style: TextStyle(
                    color: context.colors.textSecondary,
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
                        backgroundColor: context.colors.muted,
                        foregroundColor: context.colors.textSecondary,
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
                        icon: Icon(
                          Icons.cancel_outlined,
                          size: 17,
                          color: context.colors.destructive,
                        ),
                        label: Text(
                          isCancelling ? 'Annulation...' : 'Annuler',
                          style: TextStyle(color: context.colors.destructive),
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
      error: (error, _) => FigmaEmptyState(
        icon: Icons.error_outline,
        title: 'Invitations indisponibles',
        message: AppError.messageFor(error),
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
            Text(
              "L'invitation ne conditionne pas l'accès : tout bêta-lecteur "
              'peut déjà lire et commenter cette campagne.',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            if (invitations.isEmpty)
              Text(
                "Aucun bêta-lecteur invité personnellement pour l'instant.",
                style: TextStyle(color: context.colors.textSecondary),
              )
            else
              for (final invitation in invitations) ...[
                _InvitationRow(invitation: invitation),
                if (invitation != invitations.last) const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _InvitationRow extends StatelessWidget {
  const _InvitationRow({required this.invitation});

  final BetaInvitationModel invitation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          PlumoraIconTile(
            size: 38,
            radius: 10,
            backgroundColor: context.colors.primary.withValues(alpha: 0.12),
            child: Icon(
              Icons.person_outline,
              color: context.colors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              invitation.betaReaderName?.trim().isNotEmpty == true
                  ? invitation.betaReaderName!
                  : 'Bêta-lecteur',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          PlumoraBadge(label: _invitationStatusLabel(invitation.status)),
        ],
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
      error: (error, _) => FigmaEmptyState(
        icon: Icons.error_outline,
        title: 'Chapitres partagés indisponibles',
        message: AppError.messageFor(error),
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
              Text(
                'Aucun chapitre partagé pour cette campagne.',
                style: TextStyle(color: context.colors.textSecondary),
              )
            else
              for (final chapter in chapters) ...[
                _ChapterRow(chapter: chapter),
                if (chapter != chapters.last) const SizedBox(height: 10),
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
      error: (error, _) => FigmaEmptyState(
        icon: Icons.error_outline,
        title: 'Retours indisponibles',
        message: AppError.messageFor(error),
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
              Text(
                'Aucun commentaire reçu pour cette campagne.',
                style: TextStyle(color: context.colors.textSecondary),
              )
            else
              for (final comment in comments) ...[
                _CommentRow(comment: comment),
                if (comment != comments.last) const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter});

  final BetaSharedChapterModel chapter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          PlumoraIconTile(
            size: 38,
            radius: 10,
            backgroundColor: context.colors.secondary,
            child: Text(
              chapter.order == 0 ? '-' : '${chapter.order}',
              style: TextStyle(
                color: context.colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.title.isEmpty ? 'Chapitre sans titre' : chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${chapter.content.length} caractères',
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
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});

  final BetaCommentModel comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlumoraIconTile(
            size: 38,
            radius: 10,
            backgroundColor: context.colors.primary.withValues(alpha: 0.12),
            child: Icon(
              Icons.forum_outlined,
              color: context.colors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.content, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 4),
                Text(
                  comment.type.label,
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

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
