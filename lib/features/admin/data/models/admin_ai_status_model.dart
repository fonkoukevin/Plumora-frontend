/// Mirrors the backend's `AdminAiStatusDto` (`GET /admin/ai/status`,
/// `PATCH /admin/ai/settings`). Never carries the Gemini API key or prompts
/// — the backend DTO itself doesn't expose them.
class AdminAiStatus {
  const AdminAiStatus({
    required this.enabled,
    required this.providerName,
    required this.modelName,
    required this.totalWritingRequests,
    required this.totalRecommendationRequests,
    this.updatedAt,
  });

  final bool enabled;
  final String providerName;
  final String modelName;
  final int totalWritingRequests;
  final int totalRecommendationRequests;
  final DateTime? updatedAt;

  int get totalCalls => totalWritingRequests + totalRecommendationRequests;

  factory AdminAiStatus.fromJson(Object? value) {
    final json = _readMap(value);
    return AdminAiStatus(
      enabled: _readBool(json['enabled']) ?? false,
      providerName: _readString(json, ['providerName', 'provider_name']),
      modelName: _readString(json, ['modelName', 'model_name']),
      totalWritingRequests: _readInt(json, [
        'totalWritingRequests',
        'total_writing_requests',
      ]),
      totalRecommendationRequests: _readInt(json, [
        'totalRecommendationRequests',
        'total_recommendation_requests',
      ]),
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
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return '';
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
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}
