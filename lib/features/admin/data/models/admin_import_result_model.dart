/// Mirrors the backend's `AdminImportBookResponse`
/// (`POST /admin/books/import/gutendex/{id}`).
class AdminImportResult {
  const AdminImportResult({
    required this.bookId,
    required this.title,
    required this.imported,
    required this.alreadyExisted,
    this.source,
    this.externalId,
    this.message,
  });

  final String bookId;
  final String title;
  final bool imported;
  final bool alreadyExisted;
  final String? source;
  final String? externalId;
  final String? message;

  factory AdminImportResult.fromJson(Object? value) {
    final json = _readMap(value);
    return AdminImportResult(
      bookId: _readString(json, ['bookId', 'book_id']),
      title: _readString(json, ['title']),
      imported: _readBool(json['imported']) ?? false,
      alreadyExisted: _readBool(json['alreadyExisted'] ?? json['already_existed']) ?? false,
      source: _readNullableString(json, ['source']),
      externalId: _readNullableString(json, ['externalId', 'external_id']),
      message: _readNullableString(json, ['message']),
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
