import '../../../core/routing/app_router.dart';

/// Pure routing decision for `/admin/**` locations, kept isolated from
/// [GoRouter] wiring so the three cases in the spec are easy to reason about
/// and test in one place:
///  - not authenticated              -> send to login
///  - authenticated without ADMIN    -> send to the access-denied screen
///  - authenticated ADMIN            -> allow (returns null)
///
/// This is a UX convenience only — it hides the admin UI from non-admins so
/// they never see controls they can't use, but the backend independently
/// enforces `hasRole('ADMIN')` on every `/admin/**` call and returns 403 if
/// bypassed, which is the actual security boundary.
class AdminRouteGuard {
  const AdminRouteGuard._();

  static bool isAdminLocation(String location) {
    return location == AppRoutes.admin || location.startsWith('${AppRoutes.admin}/');
  }

  static String? redirect({
    required String location,
    required bool isAuthenticated,
    required List<String> roleNames,
  }) {
    if (!isAdminLocation(location) || location == AppRoutes.adminAccessDenied) {
      return null;
    }

    if (!isAuthenticated) {
      return AppRoutes.login;
    }

    final isAdmin = roleNames.any((role) => role.trim().toUpperCase() == 'ADMIN');
    if (!isAdmin) {
      return AppRoutes.adminAccessDenied;
    }

    return null;
  }
}
