import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../data/repositories/admin_repository.dart';

/// Sidebar/tab-bar badge counts, derived from the real dashboard stats
/// (`GET /admin/dashboard`) rather than re-fetching each list separately.
/// Resolves to all-zero (no badges shown) while loading or on error, since a
/// missing badge is a harmless cosmetic gap — not worth its own error UI.
final adminNavBadgesProvider = Provider<AdminNavBadges>((ref) {
  final stats = ref.watch(adminDashboardProvider).valueOrNull;
  if (stats == null) {
    return const AdminNavBadges();
  }

  return AdminNavBadges(
    users: stats.totalUsers,
    catalog: stats.totalBooks,
    reports: stats.pendingReports,
  );
});

class AdminNavBadges {
  const AdminNavBadges({this.users = 0, this.catalog = 0, this.reports = 0});

  final int users;
  final int catalog;
  final int reports;

  int? forPath(String path) {
    switch (path) {
      case AppRoutes.adminUsers:
        return users;
      case AppRoutes.adminCatalog:
        return catalog;
      case AppRoutes.adminReports:
        return reports;
      default:
        return null;
    }
  }
}
