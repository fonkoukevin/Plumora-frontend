import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../models/notification_model.dart';

class NotificationApiService {
  const NotificationApiService(this._dio);

  final Dio _dio;

  Future<List<NotificationModel>> myNotifications() async {
    final response = await _dio.get('/notifications/my');
    return _readPayloadList(response.data)
        .map(NotificationModel.fromJson)
        .where((notification) => notification.id.isNotEmpty)
        .toList();
  }

  Future<int> unreadCount() async {
    final response = await _dio.get('/notifications/unread-count');
    return _readCount(response.data);
  }

  Future<NotificationModel> markAsRead(String notificationId) async {
    final response = await _dio.patch('/notifications/$notificationId/read');
    final payload = _tryReadPayloadMap(response.data);
    if (payload == null) {
      return NotificationModel(
        id: notificationId,
        title: '',
        message: '',
        type: '',
        isRead: true,
        readAt: DateTime.now(),
      );
    }

    return NotificationModel.fromJson(payload).copyWith(isRead: true);
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/notifications/read-all');
  }

  Map<String, dynamic>? _tryReadPayloadMap(Object? data) {
    if (data == null || data == '') {
      return null;
    }

    final payload = _unwrap(data);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  List<Object?> _readPayloadList(Object? data) {
    final payload = _unwrap(data);
    if (payload is List) {
      return payload;
    }

    if (payload is Map) {
      for (final key in ['content', 'items', 'notifications', 'data']) {
        final nested = payload[key];
        if (nested is List) {
          return nested;
        }
      }
    }

    throw const AppException('La liste de notifications est invalide.');
  }

  int _readCount(Object? data) {
    final payload = _unwrap(data);
    if (payload is int) {
      return payload;
    }
    if (payload is num) {
      return payload.toInt();
    }
    if (payload is Map) {
      for (final key in ['count', 'unreadCount', 'unread', 'value']) {
        final value = payload[key];
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
    }

    return int.tryParse(payload?.toString() ?? '') ?? 0;
  }

  Object? _unwrap(Object? data) {
    if (data is Map) {
      for (final key in ['data', 'result', 'payload', 'notification']) {
        final value = data[key];
        if (value != null) {
          return _unwrap(value);
        }
      }
    }

    return data;
  }
}
