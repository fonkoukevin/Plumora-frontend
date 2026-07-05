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

  static const String anonymousUserName = 'Lecteur Plumora';

  bool get hasDisplayableUserName => !_isAnonymousUserName(userName);

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
    final userJson = _readFirstMapOrNull(json, [
      'user',
      'reader',
      'reviewer',
      'reviewerUser',
      'reviewer_user',
      'createdBy',
      'created_by',
      'createdByUser',
      'created_by_user',
    ]);

    return ReviewModel(
      id: _readString(json, [
        'id',
        'reviewId',
        'review_id',
        'idReview',
        'id_review',
        'uuid',
      ]),
      bookId: _or(
        _readString(json, [
          'bookId',
          'book_id',
          'idBook',
          'id_book',
          'externalBookId',
          'external_book_id',
          'externalId',
          'external_id',
          'gutendexId',
          'gutendex_id',
        ]),
        bookJson == null
            ? ''
            : _readString(bookJson, [
                'id',
                'bookId',
                'book_id',
                'idBook',
                'id_book',
              ]),
      ),
      userId: _or(
        _readString(json, [
          'userId',
          'user_id',
          'idUser',
          'id_user',
          'readerId',
          'reader_id',
          'reviewerId',
          'reviewer_id',
        ]),
        userJson == null
            ? ''
            : _readString(userJson, [
                'id',
                'uuid',
                'userId',
                'user_id',
                'idUser',
                'id_user',
              ]),
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

Map<String, dynamic>? _readFirstMapOrNull(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = _readMapOrNull(json[key]);
    if (value != null) {
      return value;
    }
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
  final directCombined = _combinedName(
    json,
    firstNameKeys: const [
      'firstName',
      'firstname',
      'first_name',
      'userFirstName',
      'user_first_name',
      'readerFirstName',
      'reader_first_name',
      'reviewerFirstName',
      'reviewer_first_name',
    ],
    lastNameKeys: const [
      'lastName',
      'lastname',
      'last_name',
      'userLastName',
      'user_last_name',
      'readerLastName',
      'reader_last_name',
      'reviewerLastName',
      'reviewer_last_name',
    ],
  );
  if (directCombined.isNotEmpty) {
    return directCombined;
  }

  final direct = _readDisplayName(json, [
    'displayName',
    'display_name',
    'fullName',
    'full_name',
    'name',
    'userName',
    'user_name',
    'readerName',
    'reader_name',
    'reviewerName',
    'reviewer_name',
    'authorName',
    'author_name',
    'username',
  ]);
  if (direct.isNotEmpty) {
    return direct;
  }

  if (userJson != null) {
    final combined = _combinedName(
      userJson,
      firstNameKeys: const ['firstName', 'firstname', 'first_name'],
      lastNameKeys: const ['lastName', 'lastname', 'last_name'],
    );
    if (combined.isNotEmpty) {
      return combined;
    }

    final nested = _readDisplayName(userJson, [
      'displayName',
      'display_name',
      'fullName',
      'full_name',
      'name',
      'username',
    ]);
    if (nested.isNotEmpty) {
      return nested;
    }
  }

  return ReviewModel.anonymousUserName;
}

String _readDisplayName(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys).trim();
  return _isAnonymousUserName(value) ? '' : value;
}

String _combinedName(
  Map<String, dynamic> json, {
  required List<String> firstNameKeys,
  required List<String> lastNameKeys,
}) {
  final firstName = _readString(json, firstNameKeys);
  final lastName = _readString(json, lastNameKeys);
  return [
    firstName,
    lastName,
  ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(' ');
}

bool _isAnonymousUserName(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty || normalized == 'lecteur plumora';
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
