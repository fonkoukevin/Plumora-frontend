import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../models/favorite_model.dart';
import '../services/favorite_api_service.dart';

final favoriteApiServiceProvider = Provider<FavoriteApiService>((ref) {
  return FavoriteApiService(ref.watch(dioProvider));
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(ref.watch(favoriteApiServiceProvider));
});

final myFavoritesProvider = FutureProvider<List<FavoriteModel>>((ref) {
  return ref.watch(favoriteRepositoryProvider).myFavorites();
});

final favoriteStatusProvider = FutureProvider.family<bool, String>((
  ref,
  bookId,
) {
  return ref.watch(favoriteRepositoryProvider).isFavorite(bookId);
});

class FavoriteRepository {
  const FavoriteRepository(this._apiService);

  final FavoriteApiService _apiService;

  Future<void> addFavorite(String bookId) async {
    try {
      await _apiService.addFavorite(bookId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        return;
      }
      rethrow;
    }
  }

  Future<void> removeFavorite(String bookId) async {
    try {
      await _apiService.removeFavorite(bookId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return;
      }
      rethrow;
    }
  }

  Future<List<FavoriteModel>> myFavorites() {
    return _apiService.myFavorites();
  }

  Future<bool> isFavorite(String bookId) async {
    try {
      return await _apiService.isFavorite(bookId);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return false;
      }
      rethrow;
    }
  }
}
