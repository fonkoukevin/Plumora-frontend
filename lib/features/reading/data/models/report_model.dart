enum ReportReason {
  inappropriateContent('INAPPROPRIATE_CONTENT', 'Contenu inapproprié'),
  harassment('HARASSMENT', 'Harcèlement'),
  hateSpeech('HATE_SPEECH', 'Discours haineux'),
  plagiarism('PLAGIARISM', 'Plagiat'),
  copyright('COPYRIGHT', "Atteinte aux droits d'auteur"),
  misleadingInformation('MISLEADING_INFORMATION', 'Information trompeuse'),
  other('OTHER', 'Autre');

  const ReportReason(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// The description becomes mandatory for this reason since it is the only
  /// one that carries no context on its own.
  bool get requiresDescription => this == ReportReason.other;
}

class ReportCreateRequest {
  const ReportCreateRequest({required this.reason, this.description});

  final ReportReason reason;
  final String? description;

  Map<String, dynamic> toJson() {
    final trimmedDescription = description?.trim() ?? '';
    return {
      'reason': reason.apiValue,
      if (trimmedDescription.isNotEmpty) 'description': trimmedDescription,
    };
  }
}

class ReportModel {
  const ReportModel({
    required this.id,
    required this.bookId,
    required this.reason,
    required this.status,
    this.description,
    this.createdAt,
  });

  final String id;
  final String bookId;
  final String reason;
  final String status;
  final String? description;
  final DateTime? createdAt;

  factory ReportModel.fromJson(Object? value) {
    final json = _readMap(value);
    return ReportModel(
      id: _readString(json, ['id', 'reportId', 'report_id']),
      bookId: _readString(json, ['bookId', 'book_id']),
      reason: _readString(json, ['reason']),
      status: _readString(json, ['status']),
      description: _readNullableString(json, ['description']),
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
    final parsed = DateTime.tryParse(json[key]?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}
