import 'beta_model_helpers.dart';

enum BetaCampaignStatus {
  active('ACTIVE'),
  closed('CLOSED'),
  cancelled('CANCELLED'),
  unknown('UNKNOWN');

  const BetaCampaignStatus(this.apiValue);

  final String apiValue;

  String get label => switch (this) {
    BetaCampaignStatus.active => 'Active',
    BetaCampaignStatus.closed => 'Fermée',
    BetaCampaignStatus.cancelled => 'Annulée',
    BetaCampaignStatus.unknown => 'Inconnue',
  };

  static BetaCampaignStatus fromApi(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return BetaCampaignStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => BetaCampaignStatus.unknown,
    );
  }
}

class BetaCampaignModel {
  const BetaCampaignModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.status,
    this.title,
    this.coverUrl,
    this.authorId,
    this.authorUsername,
    this.instructions,
    this.deadline,
    this.createdAt,
    this.closedAt,
  });

  final String id;
  final String bookId;
  final String bookTitle;
  final String? title;
  final BetaCampaignStatus status;
  final String? coverUrl;
  final String? authorId;
  final String? authorUsername;
  final String? instructions;
  final DateTime? deadline;
  final DateTime? createdAt;
  final DateTime? closedAt;

  factory BetaCampaignModel.fromJson(Object? value) {
    final json = readBetaMap(value);
    final book = readBetaMap(readBetaNested(json, ['book', 'manuscript']));

    return BetaCampaignModel(
      id: readBetaString(json, ['id', 'campaignId', 'campaign_id', 'uuid']),
      bookId:
          readBetaNullableString(json, ['bookId', 'book_id']) ??
          readBetaString(book, ['id', 'bookId', 'book_id', 'uuid']),
      bookTitle:
          readBetaNullableString(json, ['bookTitle', 'book_title']) ??
          readBetaNullableString(book, ['title', 'name']) ??
          readBetaString(json, ['title']),
      title: readBetaNullableString(json, [
        'title',
        'campaignTitle',
        'campaign_title',
      ]),
      status: BetaCampaignStatus.fromApi(json['status']),
      coverUrl:
          readBetaNullableString(json, [
            'bookCoverUrl',
            'coverUrl',
            'cover_url',
            'coverImageUrl',
            'cover_image_url',
            'imageUrl',
            'image_url',
          ]) ??
          readBetaNullableString(book, [
            'coverUrl',
            'cover_url',
            'coverImageUrl',
            'cover_image_url',
            'imageUrl',
            'image_url',
          ]),
      authorId: readBetaNullableString(json, ['authorId', 'author_id']),
      authorUsername: readBetaNullableString(json, [
        'authorUsername',
        'authorName',
        'author_name',
      ]),
      instructions: readBetaNullableString(json, [
        'instructions',
        'guidelines',
        'notes',
      ]),
      deadline: readBetaDate(json, ['deadline', 'dueDate', 'due_date']),
      createdAt: readBetaDate(json, ['createdAt', 'created_at']),
      closedAt: readBetaDate(json, ['closedAt', 'closed_at']),
    );
  }
}

class BetaCampaignCreateRequest {
  const BetaCampaignCreateRequest({
    required this.title,
    this.instructions,
    this.deadline,
  });

  final String title;
  final String? instructions;
  final DateTime? deadline;

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      if (instructions != null && instructions!.trim().isNotEmpty)
        'instructions': instructions!.trim(),
      if (deadline != null)
        'deadline':
            '${deadline!.year.toString().padLeft(4, '0')}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}',
    };
  }
}

class BetaInvitationCreateRequest {
  const BetaInvitationCreateRequest({required this.betaReaderId});

  final String betaReaderId;

  Map<String, dynamic> toJson() {
    return {'betaReaderId': betaReaderId.trim()};
  }
}
