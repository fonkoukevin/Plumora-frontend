import 'beta_model_helpers.dart';

enum BetaCommentStatus {
  open('OPEN'),
  pending('PENDING'),
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

enum BetaCommentType {
  incoherence('INCOHERENCE', 'Incohérence'),
  rhythm('RHYTHM', 'Rythme lent'),
  typo('TYPO', 'Faute'),
  dialogue('DIALOGUE', 'Dialogue'),
  confusing('CONFUSING', 'Passage confus'),
  style('STYLE', 'Style'),
  character('CHARACTER', 'Personnage'),
  other('OTHER', 'Autre');

  const BetaCommentType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static BetaCommentType fromApi(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    if (normalized == 'RYTHME' || normalized == 'RYTHM') {
      return BetaCommentType.rhythm;
    }
    if (normalized == 'FAUTE' || normalized == 'SPELLING') {
      return BetaCommentType.typo;
    }
    if (normalized == 'CONFUS' || normalized == 'CONFUSION') {
      return BetaCommentType.confusing;
    }

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
    this.selectedText,
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
  final String? selectedText;
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
      content: readBetaString(json, ['content', 'comment', 'message', 'text']),
      type: BetaCommentType.fromApi(json['type']),
      status: BetaCommentStatus.fromApi(json['status']),
      selectedText: readBetaNullableString(json, [
        'selectedText',
        'selected_text',
        'excerpt',
        'quote',
      ]),
      betaReaderName:
          readBetaNullableString(json, [
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
      selectedText: selectedText,
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
  });

  final String bookId;
  final String campaignId;
  final String chapterId;
  final BetaCommentType type;
  final String content;
  final String? selectedText;

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'campaignId': campaignId,
      'chapterId': chapterId,
      'type': type.apiValue,
      'content': content.trim(),
      if (selectedText != null && selectedText!.trim().isNotEmpty)
        'selectedText': selectedText!.trim(),
    };
  }
}
