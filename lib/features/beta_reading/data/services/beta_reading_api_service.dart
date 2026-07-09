import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../models/beta_campaign_model.dart';
import '../models/beta_comment_model.dart';
import '../models/beta_invitation_model.dart';
import '../models/beta_shared_chapter_model.dart';

class BetaReadingApiService {
  const BetaReadingApiService(this._dio);

  final Dio _dio;

  Future<List<BetaInvitationModel>> myInvitations() async {
    final response = await _dio.get('/beta-invitations/my-invitations');
    return _readPayloadList(response.data, [
      'content',
      'items',
      'invitations',
      'betaInvitations',
      'data',
    ]).map(BetaInvitationModel.fromJson).where((invitation) {
      return invitation.id.isNotEmpty;
    }).toList();
  }

  Future<BetaCampaignModel> createCampaign(
    String bookId,
    BetaCampaignCreateRequest request,
  ) async {
    final response = await _dio.post(
      '/books/$bookId/beta-campaigns',
      data: request.toJson(),
    );
    return BetaCampaignModel.fromJson(_readPayloadMap(response.data));
  }

  Future<List<BetaCampaignModel>> campaignsForBook(String bookId) async {
    final response = await _dio.get('/books/$bookId/beta-campaigns');
    return _readPayloadList(response.data, [
      'content',
      'items',
      'campaigns',
      'betaCampaigns',
      'data',
    ]).map(BetaCampaignModel.fromJson).where((campaign) {
      return campaign.id.isNotEmpty;
    }).toList();
  }

  Future<List<BetaCampaignModel>> openCampaigns() async {
    final response = await _dio.get('/beta-campaigns');
    return _readPayloadList(response.data, [
      'content',
      'items',
      'campaigns',
      'betaCampaigns',
      'data',
    ]).map(BetaCampaignModel.fromJson).where((campaign) {
      return campaign.id.isNotEmpty;
    }).toList();
  }

  Future<BetaCampaignModel> campaignById(String campaignId) async {
    final response = await _dio.get('/beta-campaigns/$campaignId');
    return BetaCampaignModel.fromJson(_readPayloadMap(response.data));
  }

  Future<BetaCampaignModel> closeCampaign(String campaignId) async {
    final response = await _dio.patch('/beta-campaigns/$campaignId/close');
    final payload = _tryReadPayloadMap(response.data);
    if (payload == null) {
      return BetaCampaignModel(
        id: campaignId,
        bookId: '',
        bookTitle: '',
        status: BetaCampaignStatus.closed,
        closedAt: DateTime.now(),
      );
    }

    return BetaCampaignModel.fromJson(payload);
  }

  Future<BetaCampaignModel> cancelCampaign(String campaignId) async {
    final response = await _dio.patch('/beta-campaigns/$campaignId/cancel');
    final payload = _tryReadPayloadMap(response.data);
    if (payload == null) {
      return BetaCampaignModel(
        id: campaignId,
        bookId: '',
        bookTitle: '',
        status: BetaCampaignStatus.cancelled,
        closedAt: DateTime.now(),
      );
    }

    return BetaCampaignModel.fromJson(payload);
  }

  Future<List<BetaInvitationModel>> invitationsForCampaign(
    String campaignId,
  ) async {
    final response = await _dio.get('/beta-campaigns/$campaignId/invitations');
    return _readPayloadList(response.data, [
          'content',
          'items',
          'invitations',
          'betaInvitations',
          'data',
        ])
        .map(BetaInvitationModel.fromJson)
        .map((invitation) {
          return invitation.campaignId.isEmpty
              ? invitation.copyWith(campaignId: campaignId)
              : invitation;
        })
        .where((invitation) => invitation.id.isNotEmpty)
        .toList();
  }

  Future<BetaInvitationModel> createInvitation(
    String campaignId,
    BetaInvitationCreateRequest request,
  ) async {
    final response = await _dio.post(
      '/beta-campaigns/$campaignId/invitations',
      data: request.toJson(),
    );
    final invitation = BetaInvitationModel.fromJson(
      _readPayloadMap(response.data),
    );
    return invitation.campaignId.isEmpty
        ? invitation.copyWith(campaignId: campaignId)
        : invitation;
  }

  Future<List<BetaSharedChapterModel>> updateSharedChapters(
    String campaignId,
    List<String> chapterIds,
  ) async {
    final response = await _dio.put(
      '/beta-campaigns/$campaignId/chapters',
      data: {'chapterIds': chapterIds, 'chapters': chapterIds},
    );
    return _readPayloadList(response.data, [
          'content',
          'items',
          'chapters',
          'sharedChapters',
          'data',
        ])
        .map(BetaSharedChapterModel.fromJson)
        .map((chapter) {
          return chapter.campaignId.isEmpty
              ? chapter.copyWith(campaignId: campaignId)
              : chapter;
        })
        .where((chapter) => chapter.id.isNotEmpty)
        .toList();
  }

  Future<BetaInvitationModel> acceptInvitation(String invitationId) async {
    final response = await _dio.patch('/beta-invitations/$invitationId/accept');
    final payload = _tryReadPayloadMap(response.data);
    if (payload == null) {
      return BetaInvitationModel(
        id: invitationId,
        campaignId: '',
        bookId: '',
        bookTitle: '',
        authorName: '',
        status: BetaInvitationStatus.accepted,
      );
    }

    return BetaInvitationModel.fromJson(
      payload,
    ).copyWith(status: BetaInvitationStatus.accepted);
  }

  Future<BetaInvitationModel> refuseInvitation(String invitationId) async {
    final response = await _dio.patch('/beta-invitations/$invitationId/refuse');
    final payload = _tryReadPayloadMap(response.data);
    if (payload == null) {
      return BetaInvitationModel(
        id: invitationId,
        campaignId: '',
        bookId: '',
        bookTitle: '',
        authorName: '',
        status: BetaInvitationStatus.refused,
      );
    }

    return BetaInvitationModel.fromJson(
      payload,
    ).copyWith(status: BetaInvitationStatus.refused);
  }

  Future<List<BetaSharedChapterModel>> sharedChapters(String campaignId) async {
    final response = await _dio.get('/beta-campaigns/$campaignId/chapters');
    return _readPayloadList(response.data, [
          'content',
          'items',
          'chapters',
          'sharedChapters',
          'data',
        ])
        .map(BetaSharedChapterModel.fromJson)
        .map((chapter) {
          return chapter.campaignId.isEmpty
              ? chapter.copyWith(campaignId: campaignId)
              : chapter;
        })
        .where((chapter) => chapter.id.isNotEmpty)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<BetaCommentModel> createComment(
    BetaCommentCreateRequest request,
  ) async {
    final response = await _dio.post('/beta-comments', data: request.toJson());
    final comment = BetaCommentModel.fromJson(_readPayloadMap(response.data));
    return comment.copyWith(
      bookId: comment.bookId.isEmpty ? request.bookId : comment.bookId,
      campaignId: comment.campaignId.isEmpty
          ? request.campaignId
          : comment.campaignId,
      chapterId: comment.chapterId.isEmpty
          ? request.chapterId
          : comment.chapterId,
    );
  }

  Future<List<BetaCommentModel>> commentsForBook(String bookId) async {
    final response = await _dio.get('/books/$bookId/beta-comments');
    return _readPayloadList(response.data, [
          'content',
          'items',
          'comments',
          'betaComments',
          'data',
        ])
        .map(BetaCommentModel.fromJson)
        .map((comment) {
          return comment.bookId.isEmpty
              ? comment.copyWith(bookId: bookId)
              : comment;
        })
        .where((comment) {
          return comment.id.isNotEmpty;
        })
        .toList();
  }

  Future<List<BetaCommentModel>> commentsForCampaign(String campaignId) async {
    final response = await _dio.get('/beta-campaigns/$campaignId/comments');
    return _readPayloadList(response.data, [
          'content',
          'items',
          'comments',
          'betaComments',
          'data',
        ])
        .map(BetaCommentModel.fromJson)
        .map((comment) {
          return comment.campaignId.isEmpty
              ? comment.copyWith(campaignId: campaignId)
              : comment;
        })
        .where((comment) => comment.id.isNotEmpty)
        .toList();
  }

  Future<BetaCommentModel> updateCommentStatus(
    String commentId,
    BetaCommentStatus status,
  ) async {
    final response = await _dio.patch(
      '/beta-comments/$commentId/status',
      data: {'status': status.apiValue},
    );
    final payload = _tryReadPayloadMap(response.data);
    if (payload == null) {
      return BetaCommentModel(
        id: commentId,
        bookId: '',
        campaignId: '',
        chapterId: '',
        chapterTitle: '',
        content: '',
        type: BetaCommentType.other,
        status: status,
      );
    }

    return BetaCommentModel.fromJson(payload).copyWith(status: status);
  }

  Future<void> deleteComment(String commentId) {
    return _dio.delete('/beta-comments/$commentId');
  }

  Map<String, dynamic> _readPayloadMap(Object? data) {
    final payload = _tryReadPayloadMap(data);
    if (payload != null) {
      return payload;
    }

    throw const AppException('La réponse bêta est invalide.');
  }

  Map<String, dynamic>? _tryReadPayloadMap(Object? data) {
    if (data == null || data == '') {
      return null;
    }

    final payload = _unwrap(data);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  List<Object?> _readPayloadList(Object? data, List<String> listKeys) {
    final payload = _unwrap(data);
    if (payload is List) {
      return payload;
    }

    if (payload is Map) {
      for (final key in listKeys) {
        final nested = payload[key];
        if (nested is List) {
          return nested;
        }
      }
    }

    throw const AppException('La liste bêta est invalide.');
  }

  Object? _unwrap(Object? data) {
    if (data is Map) {
      for (final key in [
        'data',
        'result',
        'payload',
        'invitation',
        'comment',
        'chapter',
        'item',
      ]) {
        final value = data[key];
        if (value != null) {
          return _unwrap(value);
        }
      }
    }

    return data;
  }
}
