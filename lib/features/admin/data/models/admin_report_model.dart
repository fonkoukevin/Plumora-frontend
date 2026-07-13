enum AdminReportStatus {
  open('OPEN'),
  inReview('IN_REVIEW'),
  resolved('RESOLVED'),
  dismissed('DISMISSED'),
  unknown('UNKNOWN');

  const AdminReportStatus(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case AdminReportStatus.open:
        return 'En attente';
      case AdminReportStatus.inReview:
        return 'En cours';
      case AdminReportStatus.resolved:
        return 'Résolu';
      case AdminReportStatus.dismissed:
        return 'Rejeté';
      case AdminReportStatus.unknown:
        return 'Inconnu';
    }
  }

  static AdminReportStatus fromApi(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return AdminReportStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => AdminReportStatus.unknown,
    );
  }
}

class AdminReport {
  const AdminReport({
    required this.id,
    required this.status,
    this.reporterId,
    this.reporterUsername,
    this.bookId,
    this.bookTitle,
    this.bookCoverUrl,
    this.reason = '',
    this.description,
    this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final AdminReportStatus status;
  final String? reporterId;
  final String? reporterUsername;
  final String? bookId;
  final String? bookTitle;
  final String? bookCoverUrl;
  final String reason;
  final String? description;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  factory AdminReport.fromJson(Object? value) {
    final json = _readMap(value);
    return AdminReport(
      id: _readString(json, ['id', 'reportId', 'report_id']),
      status: AdminReportStatus.fromApi(json['status']),
      reporterId: _readNullableString(json, ['reporterId', 'reporter_id']),
      reporterUsername: _readNullableString(json, [
        'reporterUsername',
        'reporter_username',
      ]),
      bookId: _readNullableString(json, ['bookId', 'book_id']),
      bookTitle: _readNullableString(json, ['bookTitle', 'book_title']),
      bookCoverUrl: _readNullableString(json, [
        'bookCoverUrl',
        'book_cover_url',
      ]),
      reason: _readString(json, ['reason']),
      description: _readNullableString(json, ['description']),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
      resolvedAt: _readDate(json, ['resolvedAt', 'resolved_at']),
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
