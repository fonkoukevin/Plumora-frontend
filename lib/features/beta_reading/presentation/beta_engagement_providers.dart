import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/beta_campaign_model.dart';
import '../data/models/beta_invitation_model.dart';
import '../data/repositories/beta_campaign_activity_storage.dart';
import '../data/repositories/beta_reading_repository.dart';
import '../data/repositories/beta_seen_ids_storage.dart';

/// Campagnes ouvertes avec lesquelles l'utilisateur s'est deja engage --
/// commentaire laisse ou chapitre partage ouvert -- meme sans avoir accepte
/// d'invitation personnelle. `engagedByMe` est calcule cote serveur (voir
/// `GET /beta-campaigns`), qui verifie a la fois les commentaires et les vues
/// de chapitre du beta-lecteur courant pour chaque campagne active.
final betaEngagedCampaignsProvider = FutureProvider<List<BetaCampaignModel>>((
  ref,
) async {
  final campaigns = await ref.watch(betaOpenCampaignsProvider.future);
  return campaigns.where((campaign) => campaign.engagedByMe).toList();
});

/// Invitations personnelles encore "en attente" pour lesquelles l'utilisateur
/// n'a pas deja rejoint/commente la campagne. Des qu'il a commente (acces
/// libre, sans avoir besoin d'accepter l'invitation), le livre vit desormais
/// dans la Bibliotheque Beta et l'invitation ne doit plus apparaitre comme
/// une action a traiter dans "Gerer les invitations".
final betaActionablePendingInvitationsProvider =
    Provider<List<BetaInvitationModel>>((ref) {
      final invitations =
          ref.watch(betaInvitationsProvider).valueOrNull ??
          const <BetaInvitationModel>[];
      final engagedCampaignIds =
          ref
              .watch(betaEngagedCampaignsProvider)
              .valueOrNull
              ?.map((campaign) => campaign.id)
              .toSet() ??
          const <String>{};

      return invitations
          .where(
            (invitation) =>
                invitation.isPending &&
                !engagedCampaignIds.contains(invitation.campaignId),
          )
          .toList();
    });

final betaInvitationSeenStorageProvider = Provider<BetaSeenIdsStorage>((ref) {
  return const BetaSeenIdsStorage('plumora_beta_invitations_seen');
});

final betaSeenInvitationIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.watch(betaInvitationSeenStorageProvider).readSeenIds();
});

final betaCampaignSeenStorageProvider = Provider<BetaSeenIdsStorage>((ref) {
  return const BetaSeenIdsStorage('plumora_beta_campaigns_seen');
});

final betaSeenCampaignIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.watch(betaCampaignSeenStorageProvider).readSeenIds();
});

/// Nombre d'opportunites de beta-lecture pas encore vues : invitations
/// personnelles en attente et pas deja engagees + campagnes ouvertes que
/// n'importe quel beta-lecteur peut rejoindre sans invitation.
final betaNewOpportunitiesCountProvider = Provider<int>((ref) {
  final actionableInvitations = ref.watch(
    betaActionablePendingInvitationsProvider,
  );
  final seenInvitationIds =
      ref.watch(betaSeenInvitationIdsProvider).valueOrNull ?? const <String>{};
  final newInvitations = actionableInvitations
      .where((invitation) => !seenInvitationIds.contains(invitation.id))
      .length;

  final campaigns =
      ref.watch(betaOpenCampaignsProvider).valueOrNull ??
      const <BetaCampaignModel>[];
  final seenCampaignIds =
      ref.watch(betaSeenCampaignIdsProvider).valueOrNull ?? const <String>{};
  final newCampaigns = campaigns
      .where((campaign) => !seenCampaignIds.contains(campaign.id))
      .length;

  return newInvitations + newCampaigns;
});

/// Marque les invitations en attente et les campagnes ouvertes comme vues
/// (persiste localement) et rafraichit le compteur de nouvelles opportunites.
Future<void> markBetaOpportunitiesSeen(WidgetRef ref) async {
  final invitations =
      ref.read(betaInvitationsProvider).valueOrNull ??
      const <BetaInvitationModel>[];
  final pendingIds = invitations
      .where((invitation) => invitation.isPending)
      .map((invitation) => invitation.id);

  final campaigns =
      ref.read(betaOpenCampaignsProvider).valueOrNull ??
      const <BetaCampaignModel>[];
  final campaignIds = campaigns.map((campaign) => campaign.id);

  await Future.wait([
    ref.read(betaInvitationSeenStorageProvider).markSeen(pendingIds),
    ref.read(betaCampaignSeenStorageProvider).markSeen(campaignIds),
  ]);
  ref.invalidate(betaSeenInvitationIdsProvider);
  ref.invalidate(betaSeenCampaignIdsProvider);
}

final betaCampaignActivityStorageProvider =
    Provider<BetaCampaignActivityStorage>((ref) {
      return const BetaCampaignActivityStorage();
    });

/// Derniere fois (locale, par appareil) que l'utilisateur a lu un chapitre
/// ou commente sur chaque campagne. Sert uniquement a trier la Bibliotheque
/// Beta par activite recente -- le backend n'expose pas ce timestamp par
/// utilisateur.
final betaCampaignActivityProvider = FutureProvider<Map<String, DateTime>>((
  ref,
) {
  return ref.watch(betaCampaignActivityStorageProvider).readAll();
});

/// A appeler juste apres une lecture de chapitre ou un commentaire reussi
/// (et apres l'acceptation d'une invitation) pour que ce livre remonte en
/// tete de la Bibliotheque Beta.
Future<void> touchBetaCampaignActivity(WidgetRef ref, String campaignId) async {
  await ref.read(betaCampaignActivityStorageProvider).touch(campaignId);
  ref.invalidate(betaCampaignActivityProvider);
}
