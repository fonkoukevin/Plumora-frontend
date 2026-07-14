enum AdminBookType {
  plumoraWork('PLUMORA_WORK'),
  publicDomain('PUBLIC_DOMAIN');

  const AdminBookType(this.apiValue);

  final String apiValue;
}

/// Mirrors the backend's dedicated `AdminBookListDto` / `AdminBookDetailDto`
/// (not the generic `BookResponse`/`BookModel` used elsewhere in the app —
/// admin catalog moderation has its own shape, notably `authors` as a list
/// and a real `reportsCount` computed server-side per book).
class AdminBook {
  const AdminBook({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    this.authors = const [],
    this.coverUrl,
    this.createdAt,
    this.source,
    this.externalId,
    this.reportsCount = 0,
    this.summary,
    this.readUrl,
    this.updatedAt,
    this.chaptersCount,
  });

  final String id;
  final String title;
  final AdminBookType type;
  final String status;
  final List<String> authors;
  final String? coverUrl;
  final DateTime? createdAt;
  final String? source;
  final String? externalId;
  final int reportsCount;
  final String? summary;
  final String? readUrl;
  final DateTime? updatedAt;
  final int? chaptersCount;

  bool get isPublicDomain => type == AdminBookType.publicDomain;

  bool get isArchived => status.trim().toUpperCase() == 'ARCHIVED';

  String get authorLabel =>
      authors.isEmpty ? 'Auteur inconnu' : authors.join(', ');

  factory AdminBook.fromJson(Object? value) {
    final json = _readMap(value);
    return AdminBook(
      id: _readString(json, ['id', 'bookId']),
      title: _readString(json, ['title']),
      type: _readType(json['type']),
      status: _readString(json, ['status']),
      authors: _readStringList(json['authors']),
      coverUrl: _readNullableString(json, [
        'coverUrl',
        'cover_url',
        'coverImageUrl',
        'cover_image_url',
        'imageUrl',
        'image_url',
        'bookCoverUrl',
        'book_cover_url',
      ]),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
      source: _readNullableString(json, ['source']),
      externalId: _readNullableString(json, ['externalId', 'external_id']),
      reportsCount: _readInt(json, ['reportsCount', 'reports_count']),
      summary: _readNullableString(json, ['summary']),
      readUrl: _readNullableString(json, ['readUrl', 'read_url']),
      updatedAt: _readDate(json, ['updatedAt', 'updated_at']),
      chaptersCount: _readNullableInt(json, [
        'chaptersCount',
        'chapters_count',
      ]),
    );
  }
}

AdminBookType _readType(Object? value) {
  final normalized = value?.toString().trim().toUpperCase();
  return AdminBookType.values.firstWhere(
    (type) => type.apiValue == normalized,
    orElse: () => AdminBookType.plumoraWork,
  );
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

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

int _readInt(Map<String, dynamic> json, List<String> keys) {
  return _readNullableInt(json, keys) ?? 0;
}

int? _readNullableInt(Map<String, dynamic> json, List<String> keys) {
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
  return null;
}

DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}
