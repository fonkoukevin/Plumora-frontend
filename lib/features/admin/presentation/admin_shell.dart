import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_theme.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'admin_colors.dart';

class AdminNavItem {
  const AdminNavItem({required this.label, required this.icon, required this.path});

  final String label;
  final IconData icon;
  final String path;
}

const List<AdminNavItem> adminNavItems = [
  AdminNavItem(label: 'Tableau de bord', icon: Icons.dashboard_outlined, path: AppRoutes.admin),
  AdminNavItem(label: 'Utilisateurs', icon: Icons.people_outline, path: AppRoutes.adminUsers),
  AdminNavItem(label: 'Catalogue', icon: Icons.menu_book_outlined, path: AppRoutes.adminCatalog),
  AdminNavItem(
    label: 'Import domaine public',
    icon: Icons.cloud_download_outlined,
    path: AppRoutes.adminPublicDomainImport,
  ),
  AdminNavItem(label: 'Signalements', icon: Icons.flag_outlined, path: AppRoutes.adminReports),
  AdminNavItem(label: 'Plumo IA', icon: Icons.auto_awesome_outlined, path: AppRoutes.adminAi),
  AdminNavItem(label: 'Paramètres', icon: Icons.settings_outlined, path: AppRoutes.adminSettings),
];

/// Wraps every `/admin/**` screen with the fixed dark control-room chrome
/// (sidebar on desktop, drawer on mobile, top bar) from the Figma admin
/// mockup. Each admin screen composes itself with `AdminShell(child: ...)`
/// rather than this being a GoRouter ShellRoute, so screens keep full
/// control of their own scaffolding (dialogs, scrolling) the same way the
/// standalone editor/reading routes do outside `MainShell`.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  bool _drawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    // Administration always renders in the fixed dark control-room palette
    // regardless of the user's own light/dark preference (per the Figma
    // source of truth). Overriding the Theme here means any shared app
    // widget reused inside admin screens (book covers, badges, ...) that
    // reads `context.colors` resolves to the dark palette too, instead of
    // following whatever theme the rest of the app is currently in.
    return Theme(
      data: PlumoraTheme.dark,
      child: Container(
      color: AdminColors.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1024;

            return Stack(
              children: [
                Row(
                  children: [
                    if (isDesktop) _AdminSidebar(location: location),
                    Expanded(
                      child: Column(
                        children: [
                          _AdminTopBar(
                            title: widget.title,
                            showMenuButton: !isDesktop,
                            onMenuTap: () => setState(() => _drawerOpen = true),
                          ),
                          Expanded(
                            child: ColoredBox(
                              color: AdminColors.background,
                              child: widget.child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isDesktop && _drawerOpen)
                  _AdminMobileDrawer(
                    location: location,
                    onClose: () => setState(() => _drawerOpen = false),
                  ),
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
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AdminColors.sidebar,
        border: Border(right: BorderSide(color: AdminColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AdminBrand(),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: [
                for (final item in adminNavItems)
                  _AdminNavTile(item: item, active: _isActive(location, item.path)),
              ],
            ),
          ),
          const Divider(color: AdminColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _AdminBackToAppButton(),
          ),
        ],
      ),
    );
  }
}

class _AdminMobileDrawer extends StatelessWidget {
  const _AdminMobileDrawer({required this.location, required this.onClose});

  final String location;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: Container(
            width: 260,
            decoration: const BoxDecoration(
              color: AdminColors.sidebar,
              border: Border(right: BorderSide(color: AdminColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: _AdminBrand()),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, color: AdminColors.muted),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    children: [
                      for (final item in adminNavItems)
                        _AdminNavTile(
                          item: item,
                          active: _isActive(location, item.path),
                          onTapExtra: onClose,
                        ),
                    ],
                  ),
                ),
                const Divider(color: AdminColors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _AdminBackToAppButton(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminBrand extends StatelessWidget {
  const _AdminBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AdminColors.error.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AdminColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, size: 12, color: AdminColors.error),
                const SizedBox(width: 6),
                Text(
                  'Accès Administrateur',
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
  const _AdminNavTile({required this.item, required this.active, this.onTapExtra});

  final AdminNavItem item;
  final bool active;
  final VoidCallback? onTapExtra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            onTapExtra?.call();
            context.go(item.path);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: active ? AdminColors.primary.withValues(alpha: 0.14) : null,
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
                Icon(
                  item.icon,
                  size: 17,
                  color: active ? AdminColors.primary : AdminColors.muted,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: active ? AdminColors.primary : AdminColors.muted,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
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

class _AdminBackToAppButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.go(AppRoutes.home),
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminColors.muted,
        side: const BorderSide(color: AdminColors.border),
        padding: const EdgeInsets.symmetric(vertical: 10),
        minimumSize: const Size(double.infinity, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.arrow_back, size: 14),
      label: const Text("Retour à l'app", style: TextStyle(fontSize: 12)),
    );
  }
}

class _AdminTopBar extends ConsumerWidget {
  const _AdminTopBar({
    required this.title,
    required this.showMenuButton,
    required this.onMenuTap,
  });

  final String title;
  final bool showMenuButton;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final initials = _initialsFor(session?.user?.displayName ?? 'Admin');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AdminColors.sidebar,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu, color: AdminColors.muted),
            ),
            const SizedBox(width: 4),
          ],
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AdminColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: AdminColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

bool _isActive(String location, String path) {
  return location == path || (path != AppRoutes.admin && location.startsWith(path));
}
