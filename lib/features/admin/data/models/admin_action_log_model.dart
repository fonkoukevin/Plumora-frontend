/// Mirrors the backend's `AdminActionLogDto`. [action]/[targetType] are kept
/// as raw strings (not a closed Dart enum) so an unrecognized future value
/// from the backend degrades gracefully instead of crashing parsing.
class AdminActionLog {
  const AdminActionLog({
    required this.id,
    required this.action,
    required this.description,
    this.adminId,
    this.adminEmail,
    this.targetType,
    this.targetId,
    this.createdAt,
  });

  final String id;
  final String action;
  final String description;
  final String? adminId;
  final String? adminEmail;
  final String? targetType;
  final String? targetId;
  final DateTime? createdAt;

  factory AdminActionLog.fromJson(Object? value) {
    final json = _readMap(value);
    return AdminActionLog(
      id: _readString(json, ['id']),
      action: _readString(json, ['action']),
      description: _readString(json, ['description']),
      adminId: _readNullableString(json, ['adminId', 'admin_id']),
      adminEmail: _readNullableString(json, ['adminEmail', 'admin_email']),
      targetType: _readNullableString(json, ['targetType', 'target_type']),
      targetId: _readNullableString(json, ['targetId', 'target_id']),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
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
