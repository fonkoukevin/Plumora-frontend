import '../../../catalog/data/models/catalog_book_model.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.book,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final CatalogBookModel? book;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReviewModel copyWith({
    String? id,
    String? bookId,
    String? userId,
    String? userName,
    int? rating,
    String? comment,
    CatalogBookModel? book,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      book: book ?? this.book,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ReviewModel.fromJson(Object? value) {
    final json = _readMap(value);
    final bookJson =
        _readMapOrNull(json['book']) ??
        _readMapOrNull(json['catalogBook']) ??
        _readMapOrNull(json['reviewedBook']);
    final userJson =
        _readMapOrNull(json['user']) ?? _readMapOrNull(json['reader']);

    return ReviewModel(
      id: _readString(json, ['id', 'reviewId', 'review_id', 'uuid']),
      bookId: _or(
        _readString(json, ['bookId', 'book_id']),
        bookJson == null
            ? ''
            : _readString(bookJson, ['id', 'bookId', 'book_id']),
      ),
      userId: _or(
        _readString(json, ['userId', 'user_id', 'readerId']),
        userJson == null
            ? ''
            : _readString(userJson, ['id', 'userId', 'user_id']),
      ),
      userName: _readUserName(json, userJson),
      rating: _readInt(json, ['rating', 'score', 'stars']).clamp(0, 5),
      comment: _readString(json, ['comment', 'content', 'body', 'text']),
      book: bookJson == null ? null : CatalogBookModel.fromJson(bookJson),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
      updatedAt: _readDate(json, ['updatedAt', 'updated_at']),
    );
  }
}

class ReviewUpsertRequest {
  const ReviewUpsertRequest({required this.rating, required this.comment});

  final int rating;
  final String comment;

  Map<String, dynamic> toJson() {
    return {'rating': rating.clamp(1, 5), 'comment': comment.trim()};
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
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }

  return '';
}

String _readUserName(
  Map<String, dynamic> json,
  Map<String, dynamic>? userJson,
) {
  final direct = _readString(json, [
    'userName',
    'user_name',
    'readerName',
    'authorName',
  ]);
  if (direct.isNotEmpty) {
    return direct;
  }

  if (userJson != null) {
    final fullName = _readString(userJson, ['displayName', 'fullName', 'name']);
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final firstName = _readString(userJson, [
      'firstName',
      'firstname',
      'first_name',
    ]);
    final lastName = _readString(userJson, [
      'lastName',
      'lastname',
      'last_name',
    ]);
    final combined = [
      firstName,
      lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    if (combined.isNotEmpty) {
      return combined;
    }
  }

  return 'Lecteur Plumora';
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

String _or(String value, String fallback) {
  return value.trim().isEmpty ? fallback : value;
}
