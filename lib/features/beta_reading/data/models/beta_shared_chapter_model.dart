import 'beta_model_helpers.dart';

class BetaSharedChapterModel {
  const BetaSharedChapterModel({
    required this.id,
    required this.campaignId,
    required this.bookId,
    required this.title,
    required this.content,
    required this.order,
    this.commentsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String campaignId;
  final String bookId;
  final String title;
  final String content;
  final int order;
  final int commentsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BetaSharedChapterModel.fromJson(Object? value) {
    final json = readBetaMap(value);
    final chapter = readBetaMap(readBetaNested(json, ['chapter']));
    final order = readBetaInt(json, [
      'order',
      'position',
      'chapterOrder',
      'chapterNumber',
    ]);
    final nestedOrder = readBetaInt(chapter, [
      'order',
      'position',
      'chapterOrder',
      'chapterNumber',
    ]);

    return BetaSharedChapterModel(
      id:
          readBetaNullableString(json, [
            'id',
            'chapterId',
            'chapter_id',
            'uuid',
          ]) ??
          readBetaString(chapter, ['id', 'chapterId', 'chapter_id', 'uuid']),
      campaignId: readBetaString(json, [
        'campaignId',
        'campaign_id',
        'betaCampaignId',
      ]),
      bookId:
          readBetaNullableString(json, ['bookId', 'book_id']) ??
          readBetaString(chapter, ['bookId', 'book_id']),
      title:
          readBetaNullableString(json, ['title', 'name']) ??
          readBetaString(chapter, ['title', 'name']),
      content:
          readBetaNullableString(json, ['content', 'body', 'text']) ??
          readBetaString(chapter, ['content', 'body', 'text']),
      order: order == 0 ? nestedOrder : order,
      commentsCount: readBetaInt(json, [
        'commentsCount',
        'betaCommentsCount',
        'feedbackCount',
      ]),
      createdAt: readBetaDate(json, ['createdAt', 'created_at']),
      updatedAt: readBetaDate(json, ['updatedAt', 'updated_at']),
    );
  }

  BetaSharedChapterModel copyWith({String? campaignId, String? bookId}) {
    return BetaSharedChapterModel(
      id: id,
      campaignId: campaignId ?? this.campaignId,
      bookId: bookId ?? this.bookId,
      title: title,
      content: content,
      order: order,
      commentsCount: commentsCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
