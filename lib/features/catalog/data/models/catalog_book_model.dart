class CatalogBookModel {
  const CatalogBookModel({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    this.authorId,
    this.genre,
    this.coverUrl,
    this.externalSource,
    this.externalId,
    this.rating = 0,
    this.ratingCount = 0,
    this.readCount = 0,
    this.chapterCount = 0,
    this.estimatedReadingMinutes = 0,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String description;
  final String authorName;
  final String? authorId;
  final String? genre;
  final String? coverUrl;
  final String? externalSource;
  final String? externalId;
  final double rating;
  final int ratingCount;
  final int readCount;
  final int chapterCount;
  final int estimatedReadingMinutes;
  final DateTime? publishedAt;

  bool get isExternalImport => externalSource?.trim().isNotEmpty ?? false;

  bool get isPlumoraOriginal => !isExternalImport;

  factory CatalogBookModel.fromJson(Object? value) {
    final json = _readMap(value);
    return CatalogBookModel(
      id: _readString(json, ['id', 'bookId', 'book_id', 'uuid']),
      title: _readString(json, ['title', 'name', 'bookTitle', 'book_title']),
      description: _readString(json, ['description', 'summary', 'synopsis']),
      authorName: _readAuthorName(json),
      authorId: _readNullableString(json, ['authorId', 'author_id']),
      genre: _readNullableString(json, ['genre', 'category']),
      coverUrl: _readNullableString(json, [
        'coverUrl',
        'cover_url',
        'coverImageUrl',
        'cover_image_url',
        'imageUrl',
        'image_url',
      ]),
      externalSource: _readNullableString(json, [
        'externalSource',
        'external_source',
      ]),
      externalId: _readNullableString(json, ['externalId', 'external_id']),
      rating: _readDouble(json, [
        'rating',
        'averageRating',
        'average_rating',
        'avgRating',
      ]),
      ratingCount: _readInt(json, [
        'ratingCount',
        'ratingsCount',
        'reviewCount',
        'reviewsCount',
      ]),
      readCount: _readInt(json, [
        'readCount',
        'reads',
        'readingCount',
        'readersCount',
      ]),
      chapterCount: _readInt(json, [
        'chapterCount',
        'chaptersCount',
        'chapter_count',
      ]),
      estimatedReadingMinutes: _readInt(json, [
        'estimatedReadingMinutes',
        'readingTimeMinutes',
        'readingMinutes',
      ]),
      publishedAt: _readDate(json, ['publishedAt', 'published_at']),
    );
  }

  factory CatalogBookModel.fromDetail(CatalogBookDetailModel detail) {
    return CatalogBookModel(
      id: detail.id,
      title: detail.title,
      description: detail.description,
      authorName: detail.authorName,
      authorId: detail.authorId,
      genre: detail.genre,
      coverUrl: detail.coverUrl,
      externalSource: detail.externalSource,
      externalId: detail.externalId,
      rating: detail.rating,
      ratingCount: detail.ratingCount,
      readCount: detail.readCount,
      chapterCount: detail.chapterCount,
      estimatedReadingMinutes: detail.estimatedReadingMinutes,
      publishedAt: detail.publishedAt,
    );
  }
}

class CatalogBookDetailModel {
  const CatalogBookDetailModel({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    this.authorId,
    this.authorBio,
    this.genre,
    this.coverUrl,
    this.externalSource,
    this.externalId,
    this.rating = 0,
    this.ratingCount = 0,
    this.readCount = 0,
    this.chapterCount = 0,
    this.estimatedReadingMinutes = 0,
    this.chapters = const [],
    this.publishedAt,
  });

  final String id;
  final String title;
  final String description;
  final String authorName;
  final String? authorId;
  final String? authorBio;
  final String? genre;
  final String? coverUrl;
  final String? externalSource;
  final String? externalId;
  final double rating;
  final int ratingCount;
  final int readCount;
  final int chapterCount;
  final int estimatedReadingMinutes;
  final List<CatalogChapterModel> chapters;
  final DateTime? publishedAt;

  CatalogBookModel get summary => CatalogBookModel.fromDetail(this);

  bool get isExternalImport => externalSource?.trim().isNotEmpty ?? false;

  bool get isPlumoraOriginal => !isExternalImport;

  factory CatalogBookDetailModel.fromJson(Object? value) {
    final json = _readMap(value);
    final nestedBook =
        _readMapOrNull(json['book']) ?? _readMapOrNull(json['item']);
    final bookJson = nestedBook == null ? json : {...nestedBook, ...json};
    final chapters = _readChapters(json, bookJson);

    return CatalogBookDetailModel(
      id: _readString(bookJson, ['id', 'bookId', 'book_id', 'uuid']),
      title: _readString(bookJson, [
        'title',
        'name',
        'bookTitle',
        'book_title',
      ]),
      description: _readString(bookJson, [
        'description',
        'summary',
        'synopsis',
      ]),
      authorName: _readAuthorName(bookJson),
      authorId: _readNullableString(bookJson, ['authorId', 'author_id']),
      authorBio: _readNullableString(bookJson, ['authorBio', 'author_bio']),
      genre: _readNullableString(bookJson, ['genre', 'category']),
      coverUrl: _readNullableString(bookJson, [
        'coverUrl',
        'cover_url',
        'coverImageUrl',
        'cover_image_url',
        'imageUrl',
        'image_url',
      ]),
      externalSource: _readNullableString(bookJson, [
        'externalSource',
        'external_source',
      ]),
      externalId: _readNullableString(bookJson, ['externalId', 'external_id']),
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
      readCount: _readInt(bookJson, [
        'readCount',
        'reads',
        'readingCount',
        'readersCount',
      ]),
      chapterCount: _readInt(bookJson, [
        'chapterCount',
        'chaptersCount',
        'chapter_count',
      ]),
      estimatedReadingMinutes: _readInt(bookJson, [
        'estimatedReadingMinutes',
        'readingTimeMinutes',
        'readingMinutes',
      ]),
      chapters: chapters,
      publishedAt: _readDate(bookJson, ['publishedAt', 'published_at']),
    );
  }
}

class CatalogChapterModel {
  const CatalogChapterModel({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
  });

  final String id;
  final String title;
  final String content;
  final int order;

  factory CatalogChapterModel.fromJson(Object? value, {int fallbackOrder = 0}) {
    final json = _readMap(value);
    return CatalogChapterModel(
      id: _readString(json, ['id', 'chapterId', 'chapter_id', 'uuid']),
      title: _readString(json, [
        'title',
        'name',
        'chapterTitle',
        'chapter_title',
      ]),
      content: _readString(json, ['content', 'body', 'text']),
      order: _readInt(json, [
        'order',
        'position',
        'chapterOrder',
        'chapterNumber',
      ], fallback: fallbackOrder),
    );
  }
}

List<CatalogChapterModel> _readChapters(
  Map<String, dynamic> json,
  Map<String, dynamic> bookJson,
) {
  Object? rawChapters;
  for (final key in ['chapters', 'readChapters', 'contents']) {
    if (json[key] is List) {
      rawChapters = json[key];
      break;
    }
    if (bookJson[key] is List) {
      rawChapters = bookJson[key];
      break;
    }
  }

  if (rawChapters is List) {
    final chapters = <CatalogChapterModel>[];
    for (var index = 0; index < rawChapters.length; index++) {
      final chapter = CatalogChapterModel.fromJson(
        rawChapters[index],
        fallbackOrder: index + 1,
      );
      if (chapter.id.isNotEmpty || chapter.content.isNotEmpty) {
        chapters.add(chapter);
      }
    }
    chapters.sort((a, b) => a.order.compareTo(b.order));
    return chapters;
  }

  final content = _readNullableString(bookJson, ['content', 'body', 'text']);
  if (content != null) {
    return [
      CatalogChapterModel(
        id: _readString(bookJson, ['chapterId', 'chapter_id', 'id']),
        title: _readString(bookJson, ['chapterTitle', 'chapter_title']),
        content: content,
        order: 1,
      ),
    ];
  }

  return const [];
}

String _readAuthorName(Map<String, dynamic> json) {
  final direct = _readNullableString(json, [
    'authorName',
    'author_name',
    'authorDisplayName',
    'author_display_name',
    'bookAuthorName',
    'book_author_name',
    'writer',
    'writerName',
    'writerDisplayName',
    'writer_display_name',
    'displayName',
    'display_name',
  ]);
  if (direct != null) {
    return direct;
  }

  final authorValue = json['author'];
  if (authorValue is String && authorValue.trim().isNotEmpty) {
    return authorValue.trim();
  }

  final topLevelName = _readNullableString(json, [
    'authorFullName',
    'author_full_name',
    'writerFullName',
    'writer_full_name',
  ]);
  if (topLevelName != null) {
    return topLevelName;
  }

  final topLevelFirstName = _readNullableString(json, [
    'authorFirstName',
    'author_first_name',
    'writerFirstName',
    'writer_first_name',
  ]);
  final topLevelLastName = _readNullableString(json, [
    'authorLastName',
    'author_last_name',
    'writerLastName',
    'writer_last_name',
  ]);
  final topLevelCombined = [
    topLevelFirstName,
    topLevelLastName,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
  if (topLevelCombined.isNotEmpty) {
    return topLevelCombined;
  }

  final author = _readMapOrNull(json['author']);
  if (author != null) {
    final fullName = _readNullableString(author, [
      'displayName',
      'fullName',
      'full_name',
      'name',
      'username',
    ]);
    if (fullName != null) {
      return fullName;
    }

    final firstName = _readNullableString(author, ['firstName', 'first_name']);
    final lastName = _readNullableString(author, ['lastName', 'last_name']);
    final combined = [
      firstName,
      lastName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
    if (combined.isNotEmpty) {
      return combined;
    }
  }

  final externalAuthors = _readStringList(
    json['externalAuthors'] ?? json['external_authors'],
  );
  if (externalAuthors.isNotEmpty) {
    return externalAuthors.join(', ');
  }

  final username = _readNullableString(json, [
    'authorUsername',
    'author_username',
    'writerUsername',
    'writer_username',
  ]);
  if (username != null) {
    return username;
  }

  return 'Plumora';
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

Map<String, dynamic>? _readMapOrNull(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  return null;
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

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  if (value is String && value.trim().isNotEmpty) {
    return [value.trim()];
  }

  return const [];
}

int _readInt(Map<String, dynamic> json, List<String> keys, {int fallback = 0}) {
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

  return fallback;
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
