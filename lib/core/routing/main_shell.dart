import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/data/models/role_model.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../theme/plumora_colors.dart';
import '../widgets/plumora_logo_mark.dart';
import 'app_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  static const List<ShellDestination> mobileDestinations = [
    ShellDestination(
      label: 'Accueil',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      path: AppRoutes.home,
    ),
    ShellDestination(
      label: 'Decouvrir',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      path: AppRoutes.discover,
    ),
    ShellDestination(
      label: 'Écrire',
      icon: Icons.draw_outlined,
      selectedIcon: Icons.draw,
      path: AppRoutes.write,
      useLogoMark: true,
    ),
    ShellDestination(
      label: 'Bibliothèque',
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books,
      path: AppRoutes.library,
    ),
    ShellDestination(
      label: 'Profil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      path: AppRoutes.profile,
    ),
  ];

  /// Matches the updated Figma `AppLayout.tsx` `NAV_ITEMS` exactly: six
  /// entries (no more standalone "Éditeur" destination — the chapter editor
  /// is reached from within "Mes manuscrits" now).
  static const List<ShellDestination> desktopDestinations = [
    ShellDestination(
      label: 'Tableau de bord',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      path: AppRoutes.home,
    ),
    ShellDestination(
      label: 'Mes manuscrits',
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note,
      path: AppRoutes.manuscripts,
    ),
    ShellDestination(
      label: 'Découvrir',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      path: AppRoutes.discover,
    ),
    ShellDestination(
      label: 'Bibliothèque',
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books,
      path: AppRoutes.library,
    ),
    ShellDestination(
      label: 'Bêta-retours',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      path: AppRoutes.betaFeedback,
    ),
    ShellDestination(
      label: 'Profil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      path: AppRoutes.profile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return _DesktopShell(location: location, child: child);
        }

        return _MobileShell(location: location, child: child);
      },
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _MobileBottomBar(location: location),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileBottomBar extends StatelessWidget {
  const _MobileBottomBar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: context.colors.cards.withValues(alpha: 0.95),
            border: Border(top: BorderSide(color: context.colors.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                for (final destination in MainShell.mobileDestinations)
                  Expanded(
                    child: _BottomNavItem(
                      destination: destination,
                      selected: _isSelected(location, destination.path),
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

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({required this.destination, required this.selected});

  final ShellDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.colors.primary
        : context.colors.textSecondary;

    return InkWell(
      onTap: () => context.go(destination.path),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: selected ? 1.1 : 1,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  destination.useLogoMark
                      ? PlumoraLogoMark(
                          size: 22,
                          color: color,
                          strokeWidth: 2.2,
                        )
                      : Icon(
                          selected
                              ? destination.selectedIcon
                              : destination.icon,
                          color: color,
                          size: 22,
                        ),
                  if (selected)
                    Positioned(
                      bottom: -5,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                destination.label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Row(
        children: [
          Container(
            width: 240,
            decoration: BoxDecoration(
              // The sidebar is fixed pure white, contrasting with the pale
              // violet page background -- matches AppLayout.tsx, which
              // hardcodes `#FFFFFF` here rather than reading the `sidebar`
              // token (which equals the page background).
              color: context.colors.cards,
              border: Border(right: BorderSide(color: context.colors.border)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
                    child: _SidebarLogo(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (final destination in MainShell.desktopDestinations)
                          _SidebarItem(
                            destination: destination,
                            selected: _isSelected(location, destination.path),
                          ),
                      ],
                    ),
                  ),
                  const _SidebarFooter(),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.colors.primary, context.colors.plumora],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const PlumoraLogoMark(
            size: 18,
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Plumora',
          style: GoogleFonts.playfairDisplay(
            color: context.colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.destination, required this.selected});

  final ShellDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.colors.primary
        : context.colors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(destination.path),
          hoverColor: context.colors.background,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? context.colors.secondary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                destination.useLogoMark
                    ? PlumoraLogoMark(size: 20, color: color, strokeWidth: 2.2)
                    : Icon(
                        selected ? destination.selectedIcon : destination.icon,
                        color: color,
                        size: 20,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final roles = session?.roles ?? const <RoleModel>[];
    final isAdmin = roles.any(
      (role) => role.name.trim().toUpperCase() == 'ADMIN',
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isAdmin) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.go(AppRoutes.admin),
                hoverColor: context.colors.background,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: context.colors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Administration',
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [context.colors.primary, context.colors.plumora],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initialsFor(session?.user?.displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        session?.user?.displayName ?? 'Utilisateur Plumora',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _roleLabel(roles),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
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

String _roleLabel(List<RoleModel> roles) {
  final name = roles.isEmpty ? '' : roles.first.name;
  return switch (name.trim().toUpperCase()) {
    'AUTHOR' => 'Auteur',
    'READER' => 'Lecteur',
    'BETA_READER' => 'Bêta-testeur',
    'ADMIN' => 'Administrateur',
    _ => 'Utilisateur Plumora',
  };
}

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    this.useLogoMark = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  final bool useLogoMark;
}

bool _isSelected(String location, String path) {
  return location == path ||
      (path != AppRoutes.home && location.startsWith(path));
}
