class ExternalBook {
  const ExternalBook({
    required this.externalId,
    required this.source,
    required this.title,
    this.authors = const [],
    this.summary = '',
    this.subjects = const [],
    this.languages = const [],
    this.copyright,
    this.mediaType,
    this.downloadCount = 0,
    this.coverUrl,
    this.readUrl,
    this.formats = const {},
    this.sourceUrl,
    this.imported = false,
    this.internalBookId,
  });

  final String externalId;
  final String source;
  final String title;
  final List<String> authors;
  final String summary;
  final List<String> subjects;
  final List<String> languages;
  final bool? copyright;
  final String? mediaType;
  final int downloadCount;
  final String? coverUrl;
  final String? readUrl;
  final Map<String, String> formats;
  final String? sourceUrl;
  final bool imported;
  final String? internalBookId;

  String get authorLabel {
    if (authors.isEmpty) {
      return 'Auteur inconnu';
    }

    return authors.join(', ');
  }

  bool get canReadInPlumora {
    return imported && (internalBookId?.trim().isNotEmpty ?? false);
  }

  ExternalBook copyWith({
    String? externalId,
    String? source,
    String? title,
    List<String>? authors,
    String? summary,
    List<String>? subjects,
    List<String>? languages,
    bool? copyright,
    String? mediaType,
    int? downloadCount,
    String? coverUrl,
    String? readUrl,
    Map<String, String>? formats,
    String? sourceUrl,
    bool? imported,
    String? internalBookId,
  }) {
    return ExternalBook(
      externalId: externalId ?? this.externalId,
      source: source ?? this.source,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      summary: summary ?? this.summary,
      subjects: subjects ?? this.subjects,
      languages: languages ?? this.languages,
      copyright: copyright ?? this.copyright,
      mediaType: mediaType ?? this.mediaType,
      downloadCount: downloadCount ?? this.downloadCount,
      coverUrl: coverUrl ?? this.coverUrl,
      readUrl: readUrl ?? this.readUrl,
      formats: formats ?? this.formats,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      imported: imported ?? this.imported,
      internalBookId: internalBookId ?? this.internalBookId,
    );
  }

  factory ExternalBook.fromJson(Object? value) {
    final json = _readMap(value);
    return ExternalBook(
      externalId: _readString(json, ['externalId', 'id', 'gutendexId']),
      source: _readString(json, ['source'], fallback: 'GUTENDEX'),
      title: _readString(json, ['title', 'name']),
      authors: _readStringList(json['authors']),
      summary: _readString(json, ['summary', 'description', 'synopsis']),
      subjects: _readStringList(json['subjects']),
      languages: _readStringList(json['languages']),
      copyright: _readBool(json['copyright']),
      mediaType: _readNullableString(json, ['mediaType', 'media_type']),
      downloadCount: _readInt(json, ['downloadCount', 'download_count']),
      coverUrl: _readNullableString(json, [
        'coverUrl',
        'cover_url',
        'coverImageUrl',
        'imageUrl',
      ]),
      readUrl: _readNullableString(json, ['readUrl', 'read_url']),
      formats: _readFormats(json['formats']),
      sourceUrl: _readNullableString(json, ['sourceUrl', 'source_url']),
      imported: _readBool(json['imported']) ?? false,
      internalBookId: _readNullableString(json, [
        'internalBookId',
        'internal_book_id',
        'bookId',
        'book_id',
        'plumoraBookId',
        'plumora_book_id',
      ]),
    );
  }
}

class ExternalBookPage {
  const ExternalBookPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  final List<ExternalBook> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  factory ExternalBookPage.fromJson(Object? value) {
    final payload = _unwrap(value);
    if (payload is List) {
      final books = payload
          .map(ExternalBook.fromJson)
          .where((book) => book.externalId.isNotEmpty)
          .toList();
      return ExternalBookPage(
        content: books,
        page: 0,
        size: books.length,
        totalElements: books.length,
        totalPages: books.isEmpty ? 0 : 1,
        first: true,
        last: true,
      );
    }

    final json = _readMap(payload);
    final rawContent = _readPayloadList(json);
    final books = rawContent
        .map(ExternalBook.fromJson)
        .where((book) => book.externalId.isNotEmpty)
        .toList();

    return ExternalBookPage(
      content: books,
      page: _readInt(json, ['page', 'number']),
      size: _readInt(json, ['size'], fallback: books.length),
      totalElements: _readInt(json, [
        'totalElements',
        'total_elements',
        'total',
      ], fallback: books.length),
      totalPages: _readInt(json, ['totalPages', 'total_pages'], fallback: 1),
      first: _readBool(json['first']) ?? _readInt(json, ['page']) == 0,
      last: _readBool(json['last']) ?? true,
    );
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

Object? _unwrap(Object? data) {
  if (data is Map) {
    for (final key in ['data', 'result', 'payload']) {
      final value = data[key];
      if (value != null) {
        return _unwrap(value);
      }
    }
  }

  return data;
}

List<Object?> _readPayloadList(Map<String, dynamic> json) {
  for (final key in ['content', 'items', 'books', 'results', 'data']) {
    final value = json[key];
    if (value is List) {
      return value;
    }
  }

  return const [];
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

Map<String, String> _readFormats(Object? value) {
  if (value is! Map) {
    return const {};
  }

  final formats = <String, String>{};
  for (final entry in value.entries) {
    final key = entry.key?.toString().trim() ?? '';
    final formatUrl = entry.value?.toString().trim() ?? '';
    if (key.isNotEmpty && formatUrl.isNotEmpty) {
      formats[key] = formatUrl;
    }
  }

  return formats;
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

bool? _readBool(Object? value) {
  if (value is bool) {
    return value;
  }

  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true') {
    return true;
  }
  if (normalized == 'false') {
    return false;
  }

  return null;
}
