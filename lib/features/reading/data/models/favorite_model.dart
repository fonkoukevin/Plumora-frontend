import '../../../catalog/data/models/catalog_book_model.dart';

class FavoriteModel {
  const FavoriteModel({required this.id, required this.book, this.createdAt});

  final String id;
  final CatalogBookModel book;
  final DateTime? createdAt;

  factory FavoriteModel.fromJson(Object? value) {
    final json = _readMap(value);
    final bookJson =
        _readMapOrNull(json['book']) ??
        _readMapOrNull(json['catalogBook']) ??
        _readMapOrNull(json['favoriteBook']) ??
        json;

    return FavoriteModel(
      id: _readString(json, ['id', 'favoriteId', 'favorite_id', 'uuid']),
      book: CatalogBookModel.fromJson(bookJson),
      createdAt: _readDate(json, ['createdAt', 'created_at', 'favoritedAt']),
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
