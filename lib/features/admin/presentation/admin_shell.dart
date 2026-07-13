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
  const AdminNavItem({required this.label, required this.icon, required this.path});

  final String label;
  final IconData icon;
  final String path;
}

/// The four sections shown in the maquette's primary nav (desktop sidebar
/// AND mobile bottom tab bar).
const List<AdminNavItem> adminPrimaryNavItems = [
  AdminNavItem(label: 'Tableau de bord', icon: Icons.dashboard_outlined, path: AppRoutes.admin),
  AdminNavItem(label: 'Utilisateurs', icon: Icons.people_outline, path: AppRoutes.adminUsers),
  AdminNavItem(label: 'Catalogue', icon: Icons.menu_book_outlined, path: AppRoutes.adminCatalog),
  AdminNavItem(label: 'Signalements', icon: Icons.flag_outlined, path: AppRoutes.adminReports),
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
  AdminNavItem(label: 'Plumo IA', icon: Icons.auto_awesome_outlined, path: AppRoutes.adminAi),
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
                              _AdminTopBar(title: title),
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
      width: 232,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      _AdminAvatar(initials: _initialsFor(session?.user?.displayName)),
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
                              'ADMIN',
                              style: TextStyle(color: AdminColors.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(item.icon, size: 20, color: color),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
              const SizedBox(height: 4),
              Text(
                item.label == 'Tableau de bord' ? 'Tableau' : item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AdminColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_note, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Plumora',
                style: GoogleFonts.playfairDisplay(
                  color: AdminColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AdminColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AdminColors.error.withValues(alpha: 0.27)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, size: 11, color: AdminColors.error),
                const SizedBox(width: 6),
                Text(
                  'Administration',
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
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 9 : 11),
            decoration: BoxDecoration(
              color: active ? AdminColors.primary.withValues(alpha: 0.12) : null,
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(color: active ? AdminColors.primary : Colors.transparent, width: 3),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: active ? AdminColors.primary.withValues(alpha: 0.25) : AdminColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeCount! >= 1000 ? '${(badgeCount! / 1000).round()}k' : '$badgeCount',
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
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
      decoration: BoxDecoration(
        color: AdminColors.plumora.withValues(alpha: 0.28),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(color: AdminColors.plumora, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _QuitAdminButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        await ref.read(authControllerProvider.notifier).logout();
        if (context.mounted) {
          context.go(AppRoutes.landing);
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminColors.muted,
        side: const BorderSide(color: AdminColors.border),
        padding: const EdgeInsets.symmetric(vertical: 9),
        minimumSize: const Size(double.infinity, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.logout, size: 13),
      label: const Text("Quitter l'admin", style: TextStyle(fontSize: 12)),
    );
  }
}

class _AdminTopBar extends ConsumerWidget {
  const _AdminTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              style: const TextStyle(
                color: AdminColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.notifications_outlined, size: 18, color: AdminColors.muted.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          _AdminAvatar(initials: _initialsFor(session?.user?.displayName)),
        ],
      ),
    );
  }
}

String _initialsFor(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '?';
  }
  final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

bool _isActive(String location, String path) {
  return location == path || (path != AppRoutes.admin && location.startsWith(path));
}
