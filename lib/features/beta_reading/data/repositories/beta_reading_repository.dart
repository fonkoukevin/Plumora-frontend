import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../models/beta_campaign_model.dart';
import '../models/beta_comment_model.dart';
import '../models/beta_invitation_model.dart';
import '../models/beta_reader_summary_model.dart';
import '../models/beta_shared_chapter_model.dart';
import '../services/beta_reading_api_service.dart';
import 'beta_seen_ids_storage.dart';

final betaReadingApiServiceProvider = Provider<BetaReadingApiService>((ref) {
  return BetaReadingApiService(ref.watch(dioProvider));
});

final betaReadingRepositoryProvider = Provider<BetaReadingRepository>((ref) {
  return BetaReadingRepository(ref.watch(betaReadingApiServiceProvider));
});

final betaReaderOptionsProvider = FutureProvider<List<BetaReaderSummaryModel>>((
  ref,
) {
  return ref.watch(betaReadingRepositoryProvider).betaReaders();
});

final betaInvitationsProvider = FutureProvider<List<BetaInvitationModel>>((
  ref,
) {
  return ref.watch(betaReadingRepositoryProvider).myInvitations();
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
/// personnelles en attente + campagnes ouvertes que n'importe quel
/// beta-lecteur peut rejoindre sans invitation.
final betaNewOpportunitiesCountProvider = Provider<int>((ref) {
  final invitations =
      ref.watch(betaInvitationsProvider).valueOrNull ??
      const <BetaInvitationModel>[];
  final seenInvitationIds =
      ref.watch(betaSeenInvitationIdsProvider).valueOrNull ?? const <String>{};
  final newInvitations = invitations
      .where(
        (invitation) =>
            invitation.isPending && !seenInvitationIds.contains(invitation.id),
      )
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

final betaCampaignsForBookProvider =
    FutureProvider.family<List<BetaCampaignModel>, String>((ref, bookId) {
      return ref.watch(betaReadingRepositoryProvider).campaignsForBook(bookId);
    });

final betaOpenCampaignsProvider = FutureProvider<List<BetaCampaignModel>>((
  ref,
) {
  return ref.watch(betaReadingRepositoryProvider).openCampaigns();
});

final betaCampaignProvider = FutureProvider.family<BetaCampaignModel, String>((
  ref,
  campaignId,
) {
  return ref.watch(betaReadingRepositoryProvider).campaignById(campaignId);
});

final betaSharedChaptersProvider =
    FutureProvider.family<List<BetaSharedChapterModel>, String>((
      ref,
      campaignId,
    ) {
      return ref
          .watch(betaReadingRepositoryProvider)
          .sharedChapters(campaignId);
    });

final betaCommentsForBookProvider =
    FutureProvider.family<List<BetaCommentModel>, String>((ref, bookId) {
      return ref.watch(betaReadingRepositoryProvider).commentsForBook(bookId);
    });

final betaCommentsForCampaignProvider =
    FutureProvider.family<List<BetaCommentModel>, String>((ref, campaignId) {
      return ref
          .watch(betaReadingRepositoryProvider)
          .commentsForCampaign(campaignId);
    });

final betaCampaignInvitationsProvider =
    FutureProvider.family<List<BetaInvitationModel>, String>((ref, campaignId) {
      return ref
          .watch(betaReadingRepositoryProvider)
          .invitationsForCampaign(campaignId);
    });

class BetaReadingRepository {
  const BetaReadingRepository(this._apiService);

  final BetaReadingApiService _apiService;

  Future<List<BetaReaderSummaryModel>> betaReaders() async {
    try {
      return await _apiService.betaReaders();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return <BetaReaderSummaryModel>[];
      }

      rethrow;
    }
  }

  Future<List<BetaInvitationModel>> myInvitations() async {
    try {
      return await _apiService.myInvitations();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return <BetaInvitationModel>[];
      }

      rethrow;
    }
  }

  Future<BetaInvitationModel> acceptInvitation(String invitationId) {
    return _apiService.acceptInvitation(invitationId);
  }

  Future<BetaInvitationModel> refuseInvitation(String invitationId) {
    return _apiService.refuseInvitation(invitationId);
  }

  Future<BetaCampaignModel> createCampaign(
    String bookId,
    BetaCampaignCreateRequest request,
  ) {
    return _apiService.createCampaign(bookId, request);
  }

  Future<List<BetaCampaignModel>> campaignsForBook(String bookId) async {
    try {
      return await _apiService.campaignsForBook(bookId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return <BetaCampaignModel>[];
      }

      rethrow;
    }
  }

  Future<List<BetaCampaignModel>> openCampaigns() async {
    try {
      return await _apiService.openCampaigns();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return <BetaCampaignModel>[];
      }

      rethrow;
    }
  }

  Future<BetaCampaignModel> campaignById(String campaignId) {
    return _apiService.campaignById(campaignId);
  }

  Future<BetaCampaignModel> closeCampaign(String campaignId) {
    return _apiService.closeCampaign(campaignId);
  }

  Future<BetaCampaignModel> cancelCampaign(String campaignId) {
    return _apiService.cancelCampaign(campaignId);
  }

  Future<List<BetaInvitationModel>> invitationsForCampaign(
    String campaignId,
  ) async {
    try {
      return await _apiService.invitationsForCampaign(campaignId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return <BetaInvitationModel>[];
      }

      rethrow;
    }
  }

  Future<BetaInvitationModel> createInvitation(
    String campaignId,
    BetaInvitationCreateRequest request,
  ) {
    return _apiService.createInvitation(campaignId, request);
  }

  Future<List<BetaSharedChapterModel>> updateSharedChapters(
    String campaignId,
    List<String> chapterIds,
  ) {
    return _apiService.updateSharedChapters(campaignId, chapterIds);
  }

  Future<List<BetaSharedChapterModel>> sharedChapters(String campaignId) {
    return _apiService.sharedChapters(campaignId);
  }

  Future<BetaCommentModel> createComment(BetaCommentCreateRequest request) {
    return _apiService.createComment(request);
  }

  Future<List<BetaCommentModel>> commentsForBook(String bookId) async {
    try {
      return await _apiService.commentsForBook(bookId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return <BetaCommentModel>[];
      }

      rethrow;
    }
  }

  Future<List<BetaCommentModel>> commentsForCampaign(String campaignId) async {
    try {
      return await _apiService.commentsForCampaign(campaignId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return <BetaCommentModel>[];
      }

      rethrow;
    }
  }

  Future<BetaCommentModel> updateCommentStatus(
    String commentId,
    BetaCommentStatus status,
  ) {
    return _apiService.updateCommentStatus(commentId, status);
  }

  Future<void> deleteComment(String commentId) {
    return _apiService.deleteComment(commentId);
  }
}
