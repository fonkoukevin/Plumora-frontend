/// Mirrors the backend's public platform stats DTO (`GET /stats/platform`)
/// — every field here is real, server-computed data from the database, used
/// to replace the landing page's previously hardcoded marketing numbers.
class PlatformStatsModel {
  const PlatformStatsModel({
    required this.totalBooks,
    required this.totalAuthors,
    required this.totalReaders,
  });

  final int totalBooks;
  final int totalAuthors;
  final int totalReaders;

  factory PlatformStatsModel.fromJson(Object? value) {
    final json = _readMap(value);
    return PlatformStatsModel(
      totalBooks: _readInt(json, ['totalBooks', 'total_books']),
      totalAuthors: _readInt(json, ['totalAuthors', 'total_authors']),
      totalReaders: _readInt(json, ['totalReaders', 'total_readers']),
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
