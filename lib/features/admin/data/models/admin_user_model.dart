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
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.active,
    this.username,
    this.avatarUrl,
    this.bio,
    this.roles = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String firstname;
  final String lastname;
  final String email;
  final bool active;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final List<String> roles;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminUserStatus get status =>
      active ? AdminUserStatus.active : AdminUserStatus.disabled;

  String get displayName {
    final fullName = '$firstname $lastname'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return username ?? email;
  }

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) {
      return '?';
    }

    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  bool get isAdmin => roles.contains('ADMIN');

  AdminUser copyWith({bool? active}) {
    return AdminUser(
      id: id,
      firstname: firstname,
      lastname: lastname,
      email: email,
      active: active ?? this.active,
      username: username,
      avatarUrl: avatarUrl,
      bio: bio,
      roles: roles,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory AdminUser.fromJson(Object? value) {
    final json = _readMap(value);
    return AdminUser(
      id: _readString(json, ['id', 'userId', 'user_id']),
      firstname: _readString(json, ['firstname', 'firstName', 'first_name']),
      lastname: _readString(json, ['lastname', 'lastName', 'last_name']),
      email: _readString(json, ['email']),
      active: _readBool(json['active']) ?? true,
      username: _readNullableString(json, ['username']),
      avatarUrl: _readNullableString(json, ['avatarUrl', 'avatar_url']),
      bio: _readNullableString(json, ['bio']),
      roles: _readRoles(json['roles']),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
      updatedAt: _readDate(json, ['updatedAt', 'updated_at']),
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

bool? _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true') {
    return true;
  }
  if (normalized == 'false') {
    return false;
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
