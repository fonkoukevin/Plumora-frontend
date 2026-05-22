enum BookStatus {
  draft('DRAFT'),
  inBetaReading('IN_BETA_READING'),
  inCorrection('IN_CORRECTION'),
  readyToPublish('READY_TO_PUBLISH'),
  published('PUBLISHED'),
  archived('ARCHIVED'),
  unknown('UNKNOWN');

  const BookStatus(this.apiValue);

  final String apiValue;

  static BookStatus fromApi(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return BookStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => BookStatus.unknown,
    );
  }
}

class BookModel {
  const BookModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.genre,
    this.visibility,
    this.authorId,
    this.coverUrl,
    this.chapterCount = 0,
    this.wordCount = 0,
    this.progress = 0,
    this.feedbackCount = 0,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String description;
  final BookStatus status;
  final String? genre;
  final String? visibility;
  final String? authorId;
  final String? coverUrl;
  final int chapterCount;
  final int wordCount;
  final double progress;
  final int feedbackCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  bool get isArchived => status == BookStatus.archived;

  bool get canPublish {
    return status == BookStatus.readyToPublish ||
        status == BookStatus.draft ||
        status == BookStatus.inCorrection;
  }

  factory BookModel.fromJson(Object? value) {
    final json = _readMap(value);
    return BookModel(
      id: _readString(json, ['id', 'bookId', 'book_id', 'uuid']),
      title: _readString(json, ['title', 'name']),
      description: _readString(json, ['description', 'summary', 'synopsis']),
      status: BookStatus.fromApi(json['status']),
      genre: _readNullableString(json, ['genre', 'category']),
      visibility: _readNullableString(json, ['visibility']),
      authorId: _readNullableString(json, ['authorId', 'author_id']),
      coverUrl: _readNullableString(json, ['coverUrl', 'cover_url']),
      chapterCount: _readInt(json, [
        'chapterCount',
        'chaptersCount',
        'chapter_count',
      ]),
      wordCount: _readInt(json, ['wordCount', 'wordsCount', 'word_count']),
      progress: _readDouble(json, [
        'progress',
        'completion',
        'completionPercentage',
        'completion_percentage',
      ]),
      feedbackCount: _readInt(json, [
        'feedbackCount',
        'betaFeedbackCount',
        'feedback_count',
        'commentsCount',
      ]),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
      updatedAt: _readDate(json, ['updatedAt', 'updated_at']),
      publishedAt: _readDate(json, ['publishedAt', 'published_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.apiValue,
      if (genre != null) 'genre': genre,
      if (visibility != null) 'visibility': visibility,
      if (authorId != null) 'authorId': authorId,
      if (coverUrl != null) 'coverUrl': coverUrl,
      'chapterCount': chapterCount,
      'wordCount': wordCount,
      'progress': progress,
      'feedbackCount': feedbackCount,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    };
  }
}

class BookUpsertRequest {
  const BookUpsertRequest({
    required this.title,
    this.description = '',
    this.genre,
    this.visibility,
  });

  final String title;
  final String description;
  final String? genre;
  final String? visibility;

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      if (genre != null && genre!.trim().isNotEmpty) 'genre': genre!.trim(),
      if (visibility != null && visibility!.trim().isNotEmpty)
        'visibility': visibility!.trim(),
    };
  }
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  return const {};
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  return _readNullableString(json, keys) ?? '';
}

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }

  return null;
}

int _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }

  return 0;
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }

  return 0;
}

DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is DateTime) {
      return value;
    }
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}
