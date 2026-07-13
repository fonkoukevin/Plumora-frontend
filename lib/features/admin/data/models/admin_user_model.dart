enum AdminUserStatus {
  active('ACTIVE'),
  disabled('DISABLED');

  const AdminUserStatus(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case AdminUserStatus.active:
        return 'Actif';
      case AdminUserStatus.disabled:
        return 'Désactivé';
    }
  }

  static AdminUserStatus fromApi(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return AdminUserStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => AdminUserStatus.active,
    );
  }
}

/// Mirrors the backend's `AdminUserListDto` / `AdminUserDetailDto` exactly —
/// note these dedicated admin DTOs only expose `username`/`email` (no
/// firstname/lastname/avatar/bio like the general `UserResponse`).
/// [booksCount]/[reportsCount] are only populated for the detail view
/// (`GET /admin/users/{id}`), null on the list view.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.status,
    this.username,
    this.roles = const [],
    this.createdAt,
    this.updatedAt,
    this.booksCount,
    this.reportsCount,
  });

  final String id;
  final String email;
  final AdminUserStatus status;
  final String? username;
  final List<String> roles;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? booksCount;
  final int? reportsCount;

  bool get active => status == AdminUserStatus.active;

  String get displayName {
    final name = username?.trim() ?? '';
    return name.isNotEmpty ? name : email;
  }

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) {
      return '?';
    }

    final parts = name
        .split(RegExp(r'[\s._-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  bool get isAdmin => roles.any((role) => role.toUpperCase() == 'ADMIN');

  factory AdminUser.fromJson(Object? value) {
    final json = _readMap(value);
    return AdminUser(
      id: _readString(json, ['id', 'userId', 'user_id']),
      email: _readString(json, ['email']),
      status: AdminUserStatus.fromApi(json['status']),
      username: _readNullableString(json, ['username']),
      roles: _readRoles(json['roles']),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
      updatedAt: _readDate(json, ['updatedAt', 'updated_at']),
      booksCount: _readNullableInt(json, ['booksCount', 'books_count']),
      reportsCount: _readNullableInt(json, ['reportsCount', 'reports_count']),
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

List<String> _readRoles(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((entry) {
        if (entry is String) {
          return entry;
        }
        if (entry is Map) {
          return (entry['name'] ?? entry['role'] ?? '').toString();
        }
        return '';
      })
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
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
