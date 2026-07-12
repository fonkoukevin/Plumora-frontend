class ChapterModel {
  const ChapterModel({
    required this.id,
    required this.bookId,
    required this.title,
    required this.content,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookId;
  final String title;
  final String content;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChapterModel.fromJson(Object? value) {
    final json = _readMap(value);
    return ChapterModel(
      id: _readString(json, ['id', 'chapterId', 'chapter_id', 'uuid']),
      bookId: _readString(json, ['bookId', 'book_id']),
      title: _readString(json, ['title', 'name']),
      content: _readString(json, ['content', 'body', 'text']),
      order: _readInt(json, [
        'order',
        'position',
        'chapterOrder',
        'chapterNumber',
      ]),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
      updatedAt: _readDate(json, ['updatedAt', 'updated_at']),
    );
  }

  ChapterModel copyWith({
    String? id,
    String? bookId,
    String? title,
    String? content,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChapterModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      content: content ?? this.content,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'title': title,
      'content': content,
      'order': order,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

class ChapterUpsertRequest {
  const ChapterUpsertRequest({
    required this.title,
    required this.content,
    this.order,
  });

  final String title;
  final String content;
  final int? order;

  Map<String, dynamic> toJson() {
    final normalizedOrder = order ?? 1;
    return {
      'title': title.trim(),
      'content': content,
      'chapterOrder': normalizedOrder,
      'order': normalizedOrder,
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
