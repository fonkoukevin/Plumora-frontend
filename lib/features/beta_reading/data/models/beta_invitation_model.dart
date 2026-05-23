import 'beta_campaign_model.dart';
import 'beta_model_helpers.dart';

enum BetaInvitationStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  refused('REFUSED'),
  unknown('UNKNOWN');

  const BetaInvitationStatus(this.apiValue);

  final String apiValue;

  static BetaInvitationStatus fromApi(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    if (normalized == 'DECLINED' || normalized == 'REJECTED') {
      return BetaInvitationStatus.refused;
    }

    return BetaInvitationStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => BetaInvitationStatus.unknown,
    );
  }
}

class BetaInvitationModel {
  const BetaInvitationModel({
    required this.id,
    required this.campaignId,
    required this.bookId,
    required this.bookTitle,
    required this.authorName,
    required this.status,
    this.campaign,
    this.deadline,
    this.chaptersAvailable = 0,
    this.chaptersRead = 0,
    this.feedbackCount = 0,
    this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String campaignId;
  final String bookId;
  final String bookTitle;
  final String authorName;
  final BetaInvitationStatus status;
  final BetaCampaignModel? campaign;
  final DateTime? deadline;
  final int chaptersAvailable;
  final int chaptersRead;
  final int feedbackCount;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  bool get isPending => status == BetaInvitationStatus.pending;

  bool get isAccepted => status == BetaInvitationStatus.accepted;

  bool get isRefused => status == BetaInvitationStatus.refused;

  factory BetaInvitationModel.fromJson(Object? value) {
    final json = readBetaMap(value);
    final campaignJson = readBetaNested(json, ['campaign', 'betaCampaign']);
    final campaign = campaignJson == null
        ? null
        : BetaCampaignModel.fromJson(campaignJson);
    final book = readBetaMap(
      readBetaNested(json, ['book', 'manuscript', 'campaignBook']),
    );
    final author = readBetaMap(readBetaNested(json, ['author', 'writer']));

    return BetaInvitationModel(
      id: readBetaString(json, ['id', 'invitationId', 'invitation_id', 'uuid']),
      campaignId:
          readBetaNullableString(json, [
            'campaignId',
            'campaign_id',
            'betaCampaignId',
          ]) ??
          campaign?.id ??
          '',
      bookId:
          readBetaNullableString(json, ['bookId', 'book_id']) ??
          campaign?.bookId ??
          readBetaString(book, ['id', 'bookId', 'book_id', 'uuid']),
      bookTitle:
          readBetaNullableString(json, ['bookTitle', 'book_title']) ??
          campaign?.bookTitle ??
          readBetaString(book, ['title', 'name']),
      authorName:
          readBetaNullableString(json, ['authorName', 'author_name']) ??
          readBetaNullableString(author, ['fullName', 'name', 'displayName']) ??
          [
            readBetaNullableString(author, ['firstName', 'first_name']),
            readBetaNullableString(author, ['lastName', 'last_name']),
          ].whereType<String>().join(' ').trim(),
      status: BetaInvitationStatus.fromApi(json['status']),
      campaign: campaign,
      deadline:
          readBetaDate(json, ['deadline', 'dueDate', 'due_date']) ??
          campaign?.deadline,
      chaptersAvailable: readBetaInt(json, [
        'chaptersAvailable',
        'chaptersCount',
        'chapterCount',
        'totalChapters',
      ]),
      chaptersRead: readBetaInt(json, [
        'chaptersRead',
        'readChapters',
        'completedChapters',
      ]),
      feedbackCount: readBetaInt(json, [
        'feedbackCount',
        'commentsCount',
        'betaCommentsCount',
      ]),
      createdAt: readBetaDate(json, ['createdAt', 'created_at']),
      respondedAt: readBetaDate(json, ['respondedAt', 'responded_at']),
    );
  }

  BetaInvitationModel copyWith({
    String? campaignId,
    String? bookId,
    String? bookTitle,
    String? authorName,
    BetaInvitationStatus? status,
    BetaCampaignModel? campaign,
    DateTime? deadline,
    int? chaptersAvailable,
    int? chaptersRead,
    int? feedbackCount,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return BetaInvitationModel(
      id: id,
      campaignId: campaignId ?? this.campaignId,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      authorName: authorName ?? this.authorName,
      status: status ?? this.status,
      campaign: campaign ?? this.campaign,
      deadline: deadline ?? this.deadline,
      chaptersAvailable: chaptersAvailable ?? this.chaptersAvailable,
      chaptersRead: chaptersRead ?? this.chaptersRead,
      feedbackCount: feedbackCount ?? this.feedbackCount,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
