class ReadingProgressModel {
  const ReadingProgressModel({
    required this.bookId,
    this.chapterId,
    this.bookTitle = '',
    this.authorName = '',
    this.coverUrl,
    this.rating = 0,
    this.ratingCount = 0,
    this.chapterIndex = 0,
    this.progress = 0,
    this.finished = false,
    this.updatedAt,
  });

  final String bookId;
  final String? chapterId;
  final String bookTitle;
  final String authorName;
  final String? coverUrl;
  final double rating;
  final int ratingCount;
  final int chapterIndex;
  final double progress;
  final bool finished;
  final DateTime? updatedAt;

  int get progressPercent => (progress.clamp(0, 1) * 100).round();

  factory ReadingProgressModel.fromJson(Object? value) {
    final json = _readMap(value);
    final bookJson = _readBookMap(json);
    final progress = _readProgress(json);
    return ReadingProgressModel(
      bookId: _readString(json, [
        'bookId',
        'book_id',
        'id',
      ], fallback: _readString(bookJson, ['id', 'bookId', 'book_id'])),
      chapterId: _readNullableString(json, [
        'chapterId',
        'chapter_id',
        'currentChapterId',
        'current_chapter_id',
      ]),
      bookTitle: _readString(bookJson, ['title', 'name']),
      authorName: _readAuthorName(bookJson),
      coverUrl: _readNullableString(bookJson, [
        'coverUrl',
        'cover_url',
        'coverImageUrl',
        'cover_image_url',
        'imageUrl',
        'image_url',
      ]),
      rating: _readDouble(bookJson, [
        'rating',
        'averageRating',
        'average_rating',
        'avgRating',
      ]),
      ratingCount: _readInt(bookJson, [
        'ratingCount',
        'ratingsCount',
        'reviewCount',
        'reviewsCount',
      ]),
      chapterIndex: _readInt(json, [
        'chapterIndex',
        'chapter_index',
        'currentChapterIndex',
        'current_chapter_index',
        'currentChapterOrder',
      ]),
      progress: progress,
      finished:
          _readBool(json, ['finished', 'completed', 'isFinished']) ||
          progress >= 1,
      updatedAt: _readDate(json, ['updatedAt', 'updated_at', 'lastReadAt']),
    );
  }
}

class ReadingProgressUpdateRequest {
  const ReadingProgressUpdateRequest({
    required this.bookId,
    this.chapterId,
    this.chapterIndex = 0,
    this.progress = 0,
    this.finished = false,
  });

  final String bookId;
  final String? chapterId;
  final int chapterIndex;
  final double progress;
  final bool finished;

  Map<String, dynamic> toJson() {
    final normalizedProgress = progress.clamp(0, 1);
    return {
      'bookId': bookId,
      if (chapterId != null && chapterId!.isNotEmpty) 'chapterId': chapterId,
      'chapterIndex': chapterIndex,
      'currentChapterIndex': chapterIndex,
      'progress': normalizedProgress,
      'progressPercentage': (normalizedProgress * 100).round(),
      'finished': finished,
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

Map<String, dynamic> _readBookMap(Map<String, dynamic> json) {
  for (final key in ['book', 'catalogBook', 'item']) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
  }

  return json;
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  return _readNullableString(json, keys) ?? fallback;
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

double _readProgress(Map<String, dynamic> json) {
  for (final key in [
    'progress',
    'completion',
    'progressPercentage',
    'progress_percent',
    'percentage',
  ]) {
    final value = json[key];
    if (value is num) {
      final doubleValue = value.toDouble();
      return doubleValue > 1 ? doubleValue / 100 : doubleValue;
    }
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed > 1 ? parsed / 100 : parsed;
    }
  }

  return 0;
}

String _readAuthorName(Map<String, dynamic> json) {
  final direct = _readNullableString(json, [
    'authorName',
    'author_name',
    'author',
    'writerName',
  ]);
  if (direct != null) {
    return direct;
  }

  final author = json['author'];
  if (author is Map<String, dynamic>) {
    return _readAuthorNameFromMap(author);
  }
  if (author is Map) {
    return _readAuthorNameFromMap(
      author.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  return 'Auteur Plumora';
}

String _readAuthorNameFromMap(Map<String, dynamic> author) {
  final fullName = _readNullableString(author, ['fullName', 'name']);
  if (fullName != null) {
    return fullName;
  }

  final firstName = _readNullableString(author, ['firstName', 'first_name']);
  final lastName = _readNullableString(author, ['lastName', 'last_name']);
  final combined = [
    firstName,
    lastName,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
  return combined.isEmpty ? 'Auteur Plumora' : combined;
}

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (value != null) {
      final normalized = value.toString().trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
  }

  return false;
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
