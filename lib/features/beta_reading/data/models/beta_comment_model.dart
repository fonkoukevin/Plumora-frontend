import 'beta_model_helpers.dart';

enum BetaCommentStatus {
  open('OPEN'),
  inProgress('IN_PROGRESS'),
  resolved('RESOLVED'),
  ignored('IGNORED'),
  unknown('UNKNOWN');

  const BetaCommentStatus(this.apiValue);

  final String apiValue;

  static BetaCommentStatus fromApi(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return BetaCommentStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => BetaCommentStatus.unknown,
    );
  }
}

enum BetaCommentPriority {
  critical('CRITICAL'),
  high('HIGH'),
  medium('MEDIUM'),
  low('LOW'),
  unknown('UNKNOWN');

  const BetaCommentPriority(this.apiValue);

  final String apiValue;

  static BetaCommentPriority fromApi(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return BetaCommentPriority.values.firstWhere(
      (priority) => priority.apiValue == normalized,
      orElse: () => BetaCommentPriority.unknown,
    );
  }

  static BetaCommentPriority forType(BetaCommentType type) {
    return switch (type) {
      BetaCommentType.plot ||
      BetaCommentType.continuity => BetaCommentPriority.high,
      BetaCommentType.pacing ||
      BetaCommentType.character => BetaCommentPriority.medium,
      BetaCommentType.typo ||
      BetaCommentType.style ||
      BetaCommentType.other => BetaCommentPriority.low,
    };
  }
}

enum BetaCommentType {
  plot('PLOT', 'Intrigue'),
  character('CHARACTER', 'Personnage'),
  style('STYLE', 'Style'),
  pacing('PACING', 'Rythme'),
  continuity('CONTINUITY', 'Continuité'),
  typo('TYPO', 'Faute'),
  other('OTHER', 'Autre');

  const BetaCommentType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static BetaCommentType fromApi(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return BetaCommentType.values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => BetaCommentType.other,
    );
  }
}

class BetaCommentModel {
  const BetaCommentModel({
    required this.id,
    required this.bookId,
    required this.campaignId,
    required this.chapterId,
    required this.chapterTitle,
    required this.content,
    required this.type,
    required this.status,
    this.priority = BetaCommentPriority.unknown,
    this.selectedText,
    this.positionStart,
    this.positionEnd,
    this.betaReaderName,
    this.betaReaderId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookId;
  final String campaignId;
  final String chapterId;
  final String chapterTitle;
  final String content;
  final BetaCommentType type;
  final BetaCommentStatus status;
  final BetaCommentPriority priority;
  final String? selectedText;
  final int? positionStart;
  final int? positionEnd;
  final String? betaReaderName;
  final String? betaReaderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BetaCommentModel.fromJson(Object? value) {
    final json = readBetaMap(value);
    final chapter = readBetaMap(readBetaNested(json, ['chapter']));
    final user = readBetaMap(
      readBetaNested(json, ['user', 'reader', 'betaReader']),
    );

    return BetaCommentModel(
      id: readBetaString(json, ['id', 'commentId', 'comment_id', 'uuid']),
      bookId:
          readBetaNullableString(json, ['bookId', 'book_id']) ??
          readBetaString(chapter, ['bookId', 'book_id']),
      campaignId: readBetaString(json, [
        'campaignId',
        'campaign_id',
        'betaCampaignId',
      ]),
      chapterId:
          readBetaNullableString(json, ['chapterId', 'chapter_id']) ??
          readBetaString(chapter, ['id', 'chapterId', 'chapter_id', 'uuid']),
      chapterTitle:
          readBetaNullableString(json, ['chapterTitle', 'chapter_title']) ??
          readBetaString(chapter, ['title', 'name']),
      content: readBetaString(json, [
        'commentText',
        'content',
        'comment',
        'message',
        'text',
      ]),
      type: BetaCommentType.fromApi(json['feedbackType'] ?? json['type']),
      status: BetaCommentStatus.fromApi(json['status']),
      priority: BetaCommentPriority.fromApi(json['priority']),
      selectedText: readBetaNullableString(json, [
        'selectedText',
        'selected_text',
        'excerpt',
        'quote',
      ]),
      positionStart: readBetaNullableInt(json, [
        'positionStart',
        'position_start',
      ]),
      positionEnd: readBetaNullableInt(json, ['positionEnd', 'position_end']),
      betaReaderName:
          readBetaNullableString(json, [
            'betaReaderUsername',
            'betaReaderName',
            'readerName',
            'userName',
          ]) ??
          readBetaNullableString(user, ['fullName', 'name', 'displayName']) ??
          [
            readBetaNullableString(user, ['firstName', 'first_name']),
            readBetaNullableString(user, ['lastName', 'last_name']),
          ].whereType<String>().join(' ').trim(),
      betaReaderId:
          readBetaNullableString(json, [
            'betaReaderId',
            'readerId',
            'userId',
          ]) ??
          readBetaNullableString(user, ['id', 'uuid']),
      createdAt: readBetaDate(json, ['createdAt', 'created_at']),
      updatedAt: readBetaDate(json, ['updatedAt', 'updated_at']),
    );
  }

  BetaCommentModel copyWith({
    String? bookId,
    String? campaignId,
    String? chapterId,
    String? chapterTitle,
    BetaCommentStatus? status,
  }) {
    return BetaCommentModel(
      id: id,
      bookId: bookId ?? this.bookId,
      campaignId: campaignId ?? this.campaignId,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      content: content,
      type: type,
      status: status ?? this.status,
      priority: priority,
      selectedText: selectedText,
      positionStart: positionStart,
      positionEnd: positionEnd,
      betaReaderName: betaReaderName,
      betaReaderId: betaReaderId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class BetaCommentCreateRequest {
  const BetaCommentCreateRequest({
    required this.bookId,
    required this.campaignId,
    required this.chapterId,
    required this.type,
    required this.content,
    this.selectedText,
    this.positionStart,
    this.positionEnd,
  });

  final String bookId;
  final String campaignId;
  final String chapterId;
  final BetaCommentType type;
  final String content;
  final String? selectedText;
  final int? positionStart;
  final int? positionEnd;

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'campaignId': campaignId,
      'chapterId': chapterId,
      'feedbackType': type.apiValue,
      'commentText': content.trim(),
      'priority': BetaCommentPriority.forType(type).apiValue,
      if (selectedText != null && selectedText!.trim().isNotEmpty)
        'selectedText': selectedText!.trim(),
      if (positionStart != null) 'positionStart': positionStart,
      if (positionEnd != null) 'positionEnd': positionEnd,
    };
  }
}
