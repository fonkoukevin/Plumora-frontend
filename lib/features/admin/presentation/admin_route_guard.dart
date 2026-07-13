import '../../../core/routing/app_router.dart';

/// Routing decisions for the Administration space, kept isolated from
/// [GoRouter] wiring so they're easy to reason about and test in one place.
///
/// Two responsibilities:
///  1. Gate `/admin/**`: not authenticated -> login; authenticated without
///     ADMIN -> access-denied screen; ADMIN -> allow.
///  2. Confine ADMIN accounts: once logged in with the ADMIN role, every
///     non-admin, non-public location redirects back into `/admin` — an
///     admin account only ever sees the Administration space, never the
///     regular reader/author app, per product requirement.
///
/// This is a UX convenience only — it hides/redirects the admin UI so
/// non-admins never see controls they can't use, and keeps admin accounts
/// inside their own space. The backend independently enforces
/// `hasRole('ADMIN')` on every `/admin/**` call and returns 403 if bypassed,
/// which is the actual security boundary.
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
    final isAdmin = roleNames.any((role) => role.trim().toUpperCase() == 'ADMIN');

    if (isAdminLocation(location)) {
      if (location == AppRoutes.adminAccessDenied) {
        return null;
      }
      if (!isAuthenticated) {
        return AppRoutes.login;
      }
      if (!isAdmin) {
        return AppRoutes.adminAccessDenied;
      }
      return null;
    }

    // An authenticated ADMIN account is confined to the admin space and the
    // handful of locations that must stay reachable regardless (auth
    // screens mid-flow, the landing page before redirect settles).
    if (isAuthenticated && isAdmin && !_isAlwaysReachable(location)) {
      return AppRoutes.admin;
    }

    return null;
  }

  static bool _isAlwaysReachable(String location) {
    const alwaysReachable = [AppRoutes.landing, AppRoutes.login, AppRoutes.register];
    return alwaysReachable.contains(location);
  }
}
