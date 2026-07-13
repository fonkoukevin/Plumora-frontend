import 'dart:typed_data';

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
    this.language,
    this.authorId,
    this.authorUsername,
    this.coverUrl,
    this.externalSource,
    this.tags = const [],
    this.chapterCount = 0,
    this.wordCount = 0,
    this.progress = 0,
    this.feedbackCount = 0,
    this.viewCount = 0,
    this.averageRating,
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
  final String? language;
  final String? authorId;
  final String? authorUsername;
  final String? coverUrl;
  final String? externalSource;
  final List<String> tags;
  final int chapterCount;
  final int wordCount;
  final double progress;
  final int feedbackCount;
  final int viewCount;
  final double? averageRating;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  bool get isArchived => status == BookStatus.archived;

  bool get isPublicDomain => externalSource != null && externalSource!.trim().isNotEmpty;

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
      language: _readNullableString(json, [
        'language',
        'languageCode',
        'language_code',
        'lang',
      ]),
      authorId: _readNullableString(json, ['authorId', 'author_id']),
      authorUsername: _readNullableString(json, [
        'authorUsername',
        'author_username',
        'authorName',
        'author_name',
      ]),
      externalSource: _readNullableString(json, [
        'externalSource',
        'external_source',
      ]),
      coverUrl: _readNullableString(json, [
        'coverUrl',
        'cover_url',
        'coverImageUrl',
        'cover_image_url',
        'imageUrl',
        'image_url',
      ]),
      tags: _readStringList(json, ['tags', 'keywords']),
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
      viewCount: _readInt(json, [
        'viewCount',
        'readingCount',
        'reading_count',
        'views',
      ]),
      averageRating: _readNullableDouble(json, [
        'averageRating',
        'average_rating',
        'rating',
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
      if (language != null) 'language': language,
      if (authorId != null) 'authorId': authorId,
      if (authorUsername != null) 'authorUsername': authorUsername,
      if (coverUrl != null && coverUrl!.trim().isNotEmpty)
        'coverUrl': coverUrl!.trim(),
      if (externalSource != null) 'externalSource': externalSource,
      if (tags.isNotEmpty) 'tags': tags,
      'chapterCount': chapterCount,
      'wordCount': wordCount,
      'progress': progress,
      'feedbackCount': feedbackCount,
      'viewCount': viewCount,
      if (averageRating != null) 'averageRating': averageRating,
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
    this.language,
    this.tags = const [],
    this.mature = false,
    this.coverUrl,
    this.coverImage,
  });

  final String title;
  final String description;
  final String? genre;
  final String? visibility;
  final String? language;
  final List<String> tags;
  final bool mature;
  final String? coverUrl;
  final BookCoverUpload? coverImage;

  bool get hasCoverImage => coverImage != null;

  Map<String, dynamic> toJson() {
    final trimmedDescription = description.trim();
    return {
      'title': title.trim(),
      // The backend's book DTO field is "summary", not "description" — it
      // silently ignores "description" and saves no summary at all. Both
      // are sent so the request also works against a backend expecting the
      // other name.
      'summary': trimmedDescription,
      'description': trimmedDescription,
      if (genre != null && genre!.trim().isNotEmpty) 'genre': genre!.trim(),
      if (visibility != null && visibility!.trim().isNotEmpty)
        'visibility': visibility!.trim(),
      // "language_code" is the documented column; "language" is sent too in
      // case the backend DTO field is named differently (same defensive
      // dual-send as summary/description above).
      if (language != null && language!.trim().isNotEmpty) ...{
        'languageCode': language!.trim(),
        'language': language!.trim(),
      },
      // tags/mature have no confirmed backend column yet — sent anyway since
      // unknown fields are silently ignored (see summary/description above),
      // so this is forward-compatible and costs nothing if unsupported.
      if (tags.isNotEmpty) 'tags': tags,
      'mature': mature,
      if (coverUrl != null && coverUrl!.trim().isNotEmpty)
        'coverUrl': coverUrl!.trim(),
    };
  }
}

class BookCoverUpload {
  const BookCoverUpload({required this.fileName, this.bytes, this.path})
    : assert(bytes != null || path != null);

  final String fileName;
  final Uint8List? bytes;
  final String? path;
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

List<String> _readStringList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
  }

  return const [];
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

double? _readNullableDouble(Map<String, dynamic> json, List<String> keys) {
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

  return null;
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
