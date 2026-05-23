import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService(ref.watch(dioProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(notificationApiServiceProvider));
});

final myNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationRepositoryProvider).myNotifications();
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationRepositoryProvider).unreadCount();
});

class NotificationRepository {
  const NotificationRepository(this._apiService);

  final NotificationApiService _apiService;

  Future<List<NotificationModel>> myNotifications() async {
    try {
      return await _apiService.myNotifications();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const <NotificationModel>[];
      }

      rethrow;
    }
  }

  Future<int> unreadCount() async {
    try {
      return await _apiService.unreadCount();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return 0;
      }

      rethrow;
    }
  }

  Future<NotificationModel> markAsRead(String notificationId) {
    return _apiService.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() {
    return _apiService.markAllAsRead();
  }
}
