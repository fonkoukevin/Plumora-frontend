import 'admin_action_log_model.dart';

/// Mirrors the backend's `AdminDashboardDto` exactly (`GET /admin/dashboard`)
/// — every field here is real, server-computed data, no client-side guesses.
class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalBooks,
    required this.plumoraBooks,
    required this.publicDomainBooks,
    required this.pendingReports,
    required this.resolvedReports,
    required this.archivedBooks,
    required this.aiCallsCount,
    this.recentAdminActions = const [],
  });

  final int totalUsers;
  final int activeUsers;
  final int totalBooks;
  final int plumoraBooks;
  final int publicDomainBooks;
  final int pendingReports;
  final int resolvedReports;
  final int archivedBooks;
  final int aiCallsCount;
  final List<AdminActionLog> recentAdminActions;

  factory AdminDashboardStats.fromJson(Object? value) {
    final json = _readMap(value);
    return AdminDashboardStats(
      totalUsers: _readInt(json, ['totalUsers', 'total_users']),
      activeUsers: _readInt(json, ['activeUsers', 'active_users']),
      totalBooks: _readInt(json, ['totalBooks', 'total_books']),
      plumoraBooks: _readInt(json, ['plumoraBooks', 'plumora_books']),
      publicDomainBooks: _readInt(json, [
        'publicDomainBooks',
        'public_domain_books',
      ]),
      pendingReports: _readInt(json, ['pendingReports', 'pending_reports']),
      resolvedReports: _readInt(json, ['resolvedReports', 'resolved_reports']),
      archivedBooks: _readInt(json, ['archivedBooks', 'archived_books']),
      aiCallsCount: _readInt(json, ['aiCallsCount', 'ai_calls_count']),
      recentAdminActions: _readActions(
        json['recentAdminActions'] ?? json['recent_admin_actions'],
      ),
    );
  }
}

List<AdminActionLog> _readActions(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.map(AdminActionLog.fromJson).toList(growable: false);
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
