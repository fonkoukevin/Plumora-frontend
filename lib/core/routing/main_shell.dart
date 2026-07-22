import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/data/models/role_model.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../theme/plumora_colors.dart';
import '../theme/theme_mode_controller.dart';
import '../theme/theme_toggle_button.dart';
import '../widgets/plumora_logo_mark.dart';
import '../widgets/plumora_user_avatar.dart';
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
      label: 'Découvrir',
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
  /// is reached from within the "Écrire" space now).
  static const List<ShellDestination> desktopDestinations = [
    ShellDestination(
      label: 'Accueil',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      path: AppRoutes.home,
    ),
    ShellDestination(
      label: 'Découvrir',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      path: AppRoutes.discover,
    ),
    ShellDestination(
      label: 'Écrire',
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note,
      path: AppRoutes.manuscripts,
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

class _DesktopShell extends StatefulWidget {
  const _DesktopShell({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  State<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<_DesktopShell> {
  static const _collapsedWidth = 76.0;
  static const _expandedWidth = 240.0;
  static const _labelVisibilityWidth = 180.0;
  static const _snapThreshold = (_collapsedWidth + _expandedWidth) / 2;

  double _sidebarWidth = _expandedWidth;
  bool _isResizing = false;

  bool get _showLabels => _sidebarWidth >= _labelVisibilityWidth;

  void _startResizing(DragStartDetails _) {
    setState(() => _isResizing = true);
  }

  void _resizeSidebar(DragUpdateDetails details) {
    setState(() {
      _sidebarWidth = (_sidebarWidth + details.delta.dx)
          .clamp(_collapsedWidth, _expandedWidth)
          .toDouble();
    });
  }

  void _finishResizing() {
    setState(() {
      _isResizing = false;
      _sidebarWidth = _sidebarWidth < _snapThreshold
          ? _collapsedWidth
          : _expandedWidth;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isResizing = false;
      _sidebarWidth = _showLabels ? _collapsedWidth : _expandedWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showLabels = _showLabels;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Row(
        children: [
          Container(
            key: const ValueKey('desktop_sidebar'),
            width: _sidebarWidth,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              // The sidebar is fixed pure white, contrasting with the pale
              // violet page background -- matches AppLayout.tsx, which
              // hardcodes `#FFFFFF` here rather than reading the `sidebar`
              // token (which equals the page background).
              color: context.colors.cards,
              border: Border(right: BorderSide(color: context.colors.border)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            24,
                            showLabels ? 20 : 19,
                            28,
                          ),
                          child: _SidebarLogo(showLabel: showLabels),
                        ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.symmetric(
                              horizontal: showLabels ? 12 : 10,
                            ),
                            children: [
                              for (final destination
                                  in MainShell.desktopDestinations)
                                _SidebarItem(
                                  destination: destination,
                                  selected: _isSelected(
                                    widget.location,
                                    destination.path,
                                  ),
                                  showLabel: showLabels,
                                ),
                            ],
                          ),
                        ),
                        _SidebarFooter(showLabels: showLabels),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: _SidebarResizeHandle(
                    resizing: _isResizing,
                    onDragStart: _startResizing,
                    onDragUpdate: _resizeSidebar,
                    onDragEnd: (_) => _finishResizing(),
                    onDragCancel: _finishResizing,
                    onDoubleTap: _toggleSidebar,
                  ),
                ),
                Positioned(
                  top: 64,
                  right: 0,
                  child: _SidebarToggleButton(
                    collapsed: !showLabels,
                    onPressed: _toggleSidebar,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _SidebarToggleButton extends StatelessWidget {
  const _SidebarToggleButton({
    required this.collapsed,
    required this.onPressed,
  });

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tooltip = collapsed
        ? 'Agrandir la barre latérale'
        : 'Réduire la barre latérale';

    return Tooltip(
      message: tooltip,
      child: Material(
        key: const ValueKey('desktop_sidebar_toggle_button'),
        color: context.colors.primary,
        elevation: 3,
        shadowColor: context.colors.primary.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 22,
            child: Icon(
              collapsed
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarResizeHandle extends StatelessWidget {
  const _SidebarResizeHandle({
    required this.resizing,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    required this.onDoubleTap,
  });

  final bool resizing;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final GestureDragCancelCallback onDragCancel;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Glisser pour réduire ou agrandir la barre latérale',
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          key: const ValueKey('desktop_sidebar_resize_handle'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: onDragStart,
          onHorizontalDragUpdate: onDragUpdate,
          onHorizontalDragEnd: onDragEnd,
          onHorizontalDragCancel: onDragCancel,
          onDoubleTap: onDoubleTap,
          child: Semantics(
            button: true,
            label: 'Redimensionner la barre latérale',
            child: SizedBox(
              width: 12,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: resizing ? 4 : 3,
                  height: 48,
                  decoration: BoxDecoration(
                    color: resizing
                        ? context.colors.primary
                        : context.colors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo({required this.showLabel});

  final bool showLabel;

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
        if (showLabel) ...[
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
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.showLabel,
  });

  final ShellDestination destination;
  final bool selected;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.colors.primary
        : context.colors.textSecondary;
    final icon = destination.useLogoMark
        ? PlumoraLogoMark(size: 20, color: color, strokeWidth: 2.2)
        : Icon(
            selected ? destination.selectedIcon : destination.icon,
            color: color,
            size: 20,
          );

    final item = Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(destination.path),
          hoverColor: context.colors.background,
          child: Container(
            width: double.infinity,
            height: 44,
            padding: showLabel
                ? const EdgeInsets.symmetric(horizontal: 12)
                : EdgeInsets.zero,
            alignment: showLabel ? Alignment.centerLeft : Alignment.center,
            decoration: BoxDecoration(
              color: selected ? context.colors.secondary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: showLabel
                ? Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                : icon,
          ),
        ),
      ),
    );

    if (showLabel) {
      return item;
    }

    return Tooltip(message: destination.label, child: item);
  }
}

class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter({required this.showLabels});

  final bool showLabels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final roles = session?.roles ?? const <RoleModel>[];
    final displayName = session?.user?.displayName ?? 'Utilisateur Plumora';
    final isAdmin = roles.any(
      (role) => role.name.trim().toUpperCase() == 'ADMIN',
    );
    final isDark = ref.watch(themeModeControllerProvider) == ThemeMode.dark;
    final themeToggleRow = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => toggleThemeMode(context, ref),
        hoverColor: context.colors.background,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: showLabels ? 12 : 0),
            child: Row(
              mainAxisAlignment: showLabels
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: context.colors.textSecondary,
                  size: 20,
                ),
                if (showLabels) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isDark ? 'Thème clair' : 'Thème sombre',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final adminButton = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(AppRoutes.admin),
        hoverColor: context.colors.background,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: showLabels ? 12 : 0),
            child: Row(
              mainAxisAlignment: showLabels
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: context.colors.textSecondary,
                  size: 20,
                ),
                if (showLabels) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Administration',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final avatar = PlumoraUserAvatar(name: displayName, size: 32);
    final profileCard = Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabels ? 12 : 0,
        vertical: showLabels ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: showLabels
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          avatar,
          if (showLabels) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
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
            Tooltip(
              message: 'Se déconnecter',
              child: Semantics(
                button: true,
                label: 'Se déconnecter de Plumora',
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    hoverColor: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.1),
                    onTap: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) {
                        context.go(AppRoutes.landing);
                      }
                    },
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        showLabels ? 12 : 10,
        12,
        showLabels ? 12 : 10,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isAdmin) ...[
            if (showLabels)
              adminButton
            else
              Tooltip(message: 'Administration', child: adminButton),
            const SizedBox(height: 8),
          ],
          if (showLabels)
            themeToggleRow
          else
            Tooltip(
              message: isDark ? 'Thème clair' : 'Thème sombre',
              child: themeToggleRow,
            ),
          const SizedBox(height: 8),
          if (showLabels)
            profileCard
          else
            Tooltip(message: displayName, child: profileCard),
        ],
      ),
    );
  }
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
