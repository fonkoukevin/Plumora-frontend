import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_theme.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'admin_colors.dart';
import 'providers/admin_nav_providers.dart';

class AdminNavItem {
  const AdminNavItem({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}

/// The four sections shown in the maquette's primary nav (desktop sidebar
/// AND mobile bottom tab bar).
const List<AdminNavItem> adminPrimaryNavItems = [
  AdminNavItem(
    label: 'Tableau de bord',
    icon: Icons.dashboard_outlined,
    path: AppRoutes.admin,
  ),
  AdminNavItem(
    label: 'Utilisateurs',
    icon: Icons.people_outline,
    path: AppRoutes.adminUsers,
  ),
  AdminNavItem(
    label: 'Catalogue',
    icon: Icons.menu_book_outlined,
    path: AppRoutes.adminCatalog,
  ),
  AdminNavItem(
    label: 'Signalements',
    icon: Icons.flag_outlined,
    path: AppRoutes.adminReports,
  ),
];

/// Secondary sections that stay fully functional (real backend endpoints)
/// but aren't part of the maquette's 4-item primary nav — kept reachable
/// from the desktop sidebar so nothing built for them is lost.
const List<AdminNavItem> adminSecondaryNavItems = [
  AdminNavItem(
    label: 'Import domaine public',
    icon: Icons.cloud_download_outlined,
    path: AppRoutes.adminPublicDomainImport,
  ),
  AdminNavItem(
    label: 'Plumo IA',
    icon: Icons.auto_awesome_outlined,
    path: AppRoutes.adminAi,
  ),
];

/// Wraps every `/admin/**` screen with the fixed light-violet control-room
/// chrome from the Figma admin mockup. Each admin screen composes itself
/// with `AdminShell(child: ...)` rather than this being a GoRouter
/// ShellRoute, so screens keep full control of their own scaffolding
/// (dialogs, scrolling) the same way the standalone editor/reading routes
/// do outside `MainShell`.
class AdminShell extends ConsumerWidget {
  const AdminShell({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    // Administration always renders in the fixed light-violet palette
    // regardless of the user's own light/dark preference (per the Figma
    // source of truth). Overriding the Theme here means any shared app
    // widget reused inside admin screens (book covers, badges, ...) that
    // reads `context.colors` resolves to the light palette too.
    return Theme(
      data: PlumoraTheme.light,
      child: Scaffold(
        backgroundColor: AdminColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1024;

              return Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (isDesktop) _AdminSidebar(location: location),
                        Expanded(
                          child: Column(
                            children: [
                              _AdminTopBar(title: title, compact: !isDesktop),
                              Expanded(
                                child: ColoredBox(
                                  color: AdminColors.background,
                                  child: child,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isDesktop) _AdminMobileTabBar(location: location),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AdminSidebar extends ConsumerWidget {
  const _AdminSidebar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(adminNavBadgesProvider);
    final session = ref.watch(authControllerProvider).valueOrNull;

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(right: BorderSide(color: AdminColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AdminBrand(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: [
                for (final item in adminPrimaryNavItems)
                  _AdminNavTile(
                    item: item,
                    active: _isActive(location, item.path),
                    badgeCount: badges.forPath(item.path),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  child: Divider(color: AdminColors.border, height: 1),
                ),
                for (final item in adminSecondaryNavItems)
                  _AdminNavTile(
                    item: item,
                    active: _isActive(location, item.path),
                    compact: true,
                  ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AdminColors.border)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.mutedBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _AdminAvatar(
                        initials: _initialsFor(session?.user?.displayName),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session?.user?.displayName ?? 'Administrateur',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AdminColors.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'Administrateur',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AdminColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _QuitAdminButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMobileTabBar extends ConsumerWidget {
  const _AdminMobileTabBar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(adminNavBadgesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          for (final item in adminPrimaryNavItems)
            Expanded(
              child: _AdminMobileTabItem(
                item: item,
                active: _isActive(location, item.path),
                badgeCount: badges.forPath(item.path),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminMobileTabItem extends StatelessWidget {
  const _AdminMobileTabItem({
    required this.item,
    required this.active,
    this.badgeCount,
  });

  final AdminNavItem item;
  final bool active;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = active ? AdminColors.primary : AdminColors.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(item.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(item.icon, size: 19, color: color),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        decoration: const BoxDecoration(
                          color: AdminColors.error,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Text(
                          badgeCount! > 99 ? '99+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.label == 'Tableau de bord' ? 'Tableau' : item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBrand extends StatelessWidget {
  const _AdminBrand();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AdminColors.primary, AdminColors.plumora],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AdminColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Plumora',
                style: GoogleFonts.playfairDisplay(
                  color: AdminColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AdminColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AdminColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 10,
                  color: AdminColors.error,
                ),
                const SizedBox(width: 6),
                Text(
                  'Espace Administration',
                  style: TextStyle(
                    color: AdminColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({
    required this.item,
    required this.active,
    this.badgeCount,
    this.compact = false,
  });

  final AdminNavItem item;
  final bool active;
  final int? badgeCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = active ? AdminColors.primary : AdminColors.muted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(item.path),
          hoverColor: active ? null : AdminColors.mutedBg,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 9 : 11,
            ),
            decoration: BoxDecoration(
              color: active ? AdminColors.primaryBg : null,
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(
                  color: active ? AdminColors.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(item.icon, size: compact ? 15 : 16, color: color),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: color,
                      fontSize: compact ? 12.5 : 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AdminColors.primary.withValues(alpha: 0.25)
                          : AdminColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeCount! >= 1000
                          ? '${(badgeCount! / 1000).round()}k'
                          : '$badgeCount',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AdminColors.plumora, AdminColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuitAdminButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        hoverColor: AdminColors.mutedBg,
        onTap: () async {
          await ref.read(authControllerProvider.notifier).logout();
          if (context.mounted) {
            context.go(AppRoutes.landing);
          }
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.logout, size: 13, color: AdminColors.muted),
              SizedBox(width: 8),
              Text(
                "Quitter l'administration",
                style: TextStyle(
                  color: AdminColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends ConsumerWidget {
  const _AdminTopBar({required this.title, required this.compact});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 20,
        vertical: compact ? 8 : 14,
      ),
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                color: AdminColors.text,
                fontSize: compact ? 12 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (compact) const _AdminMobileLogoutButton() else _AdminBellButton(),
          SizedBox(width: compact ? 8 : 12),
          _AdminAvatar(initials: _initialsFor(session?.user?.displayName)),
        ],
      ),
    );
  }
}

class _AdminBellButton extends StatelessWidget {
  const _AdminBellButton();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Notifications',
      child: Material(
        color: AdminColors.mutedBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: AdminColors.primaryBg,
          onTap: () {},
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.notifications_outlined,
              size: 15,
              color: AdminColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminMobileLogoutButton extends ConsumerWidget {
  const _AdminMobileLogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = BorderRadius.circular(999);

    return Tooltip(
      message: 'Se déconnecter',
      child: Semantics(
        button: true,
        label: 'Se déconnecter de Plumora',
        child: Material(
          color: AdminColors.primary.withValues(alpha: 0.1),
          borderRadius: radius,
          child: InkWell(
            onTap: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.landing);
              }
            },
            borderRadius: radius,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: AdminColors.primary.withValues(alpha: 0.28),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 13,
                    color: AdminColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Déconnexion',
                    style: TextStyle(
                      color: AdminColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _initialsFor(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '?';
  }
  final parts = trimmed
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

bool _isActive(String location, String path) {
  return location == path ||
      (path != AppRoutes.admin && location.startsWith(path));
}
