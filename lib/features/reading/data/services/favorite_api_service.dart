import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../models/favorite_model.dart';

class FavoriteApiService {
  const FavoriteApiService(this._dio);

  final Dio _dio;

  Future<void> addFavorite(String bookId) async {
    await _dio.post('/books/$bookId/favorites');
  }

  Future<void> removeFavorite(String bookId) async {
    await _dio.delete('/books/$bookId/favorites');
  }

  Future<List<FavoriteModel>> myFavorites() async {
    final response = await _dio.get('/favorites/my');
    return _readPayloadList(response.data)
        .map(FavoriteModel.fromJson)
        .where((favorite) => favorite.book.id.isNotEmpty)
        .toList();
  }

  Future<bool> isFavorite(String bookId) async {
    final response = await _dio.get('/books/$bookId/favorites/status');
    return _readFavoriteStatus(response.data);
  }

  bool _readFavoriteStatus(Object? data) {
    final payload = _unwrap(data);
    if (payload is bool) {
      return payload;
    }

    if (payload is Map) {
      for (final key in [
        'favorite',
        'favorited',
        'isFavorite',
        'saved',
        'status',
        'value',
      ]) {
        final value = payload[key];
        if (value is bool) {
          return value;
        }
        if (value != null) {
          final normalized = value.toString().trim().toLowerCase();
          if ([
            'true',
            '1',
            'yes',
            'favorite',
            'favorited',
          ].contains(normalized)) {
            return true;
          }
          if (['false', '0', 'no'].contains(normalized)) {
            return false;
          }
        }
      }
    }

    if (payload is String) {
      final normalized = payload.trim().toLowerCase();
      if (['true', '1', 'yes', 'favorite', 'favorited'].contains(normalized)) {
        return true;
      }
      if (['false', '0', 'no'].contains(normalized)) {
        return false;
      }
    }

    return false;
  }

  List<Object?> _readPayloadList(Object? data) {
    final payload = _unwrap(data);
    if (payload is List) {
      return payload;
    }

    if (payload is Map) {
      for (final key in ['content', 'items', 'favorites', 'books', 'data']) {
        final nested = payload[key];
        if (nested is List) {
          return nested;
        }
      }
    }

    throw const AppException('La liste de favoris est invalide.');
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
}
