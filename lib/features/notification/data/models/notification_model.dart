class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.createdAt,
    this.readAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;

  factory NotificationModel.fromJson(Object? value) {
    final json = _readMap(value);
    return NotificationModel(
      id: _readString(json, [
        'id',
        'notificationId',
        'notification_id',
        'idNotification',
      ]),
      title: _readString(json, ['title', 'subject']),
      message: _readString(json, ['message', 'body', 'content']),
      type: _readString(json, ['type', 'category']),
      isRead: _readBool(json, ['is_read', 'isRead', 'read', 'seen']),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
      readAt: _readDate(json, ['readAt', 'read_at']),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
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

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }

  return '';
}

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (value != null) {
      final normalized = value.toString().trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
  }

  return false;
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
