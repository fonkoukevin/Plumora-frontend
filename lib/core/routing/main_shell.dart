import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  static const List<ShellDestination> desktopDestinations = [
    ShellDestination(
      label: 'Tableau de bord',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      path: AppRoutes.home,
    ),
    ShellDestination(
      label: 'Mes manuscrits',
      icon: Icons.folder_copy_outlined,
      selectedIcon: Icons.folder_copy,
      path: AppRoutes.manuscripts,
    ),
    ShellDestination(
      label: 'Éditeur',
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note,
      path: AppRoutes.editor,
    ),
    ShellDestination(
      label: 'Bêta-retours',
      icon: Icons.rate_review_outlined,
      selectedIcon: Icons.rate_review,
      path: AppRoutes.betaFeedback,
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
        if (constraints.maxWidth >= 900) {
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
      backgroundColor: PlumoraColors.appOutside,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 520;
            final panelWidth = isCompact ? constraints.maxWidth : 430.0;
            final panelRadius = isCompact ? 0.0 : 28.0;

            return Center(
              child: SizedBox(
                width: panelWidth,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(panelRadius),
                    child: Material(
                      color: PlumoraColors.background,
                      child: Stack(
                        children: [
                          Positioned.fill(child: child),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _MobileBottomBar(location: location),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MobileBottomBar extends StatelessWidget {
  const _MobileBottomBar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 61,
      decoration: const BoxDecoration(
        color: PlumoraColors.cards,
        border: Border(top: BorderSide(color: PlumoraColors.border)),
      ),
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
        ? PlumoraColors.primary
        : PlumoraColors.textSecondary;

    return InkWell(
      onTap: () => context.go(destination.path),
      child: Padding(
        padding: const EdgeInsets.only(top: 7, bottom: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            destination.useLogoMark
                ? PlumoraLogoMark(size: 20, color: color, strokeWidth: 2.2)
                : Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    color: color,
                    size: 20,
                  ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                destination.label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
      backgroundColor: PlumoraColors.background,
      body: Row(
        children: [
          Container(
            width: 264,
            decoration: const BoxDecoration(
              color: PlumoraColors.cards,
              border: Border(right: BorderSide(color: PlumoraColors.border)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SidebarLogo(),
                    const SizedBox(height: 28),
                    for (final destination in MainShell.desktopDestinations)
                      _SidebarItem(
                        destination: destination,
                        selected: _isSelected(location, destination.path),
                      ),
                  ],
                ),
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
    return const Row(
      children: [
        PlumoraLogoMark(size: 30, color: PlumoraColors.primary),
        SizedBox(width: 10),
        Text(
          'Plumora',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w900,
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
    final color = selected ? PlumoraColors.primary : PlumoraColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go(destination.path),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF1E7D7) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              destination.useLogoMark
                  ? PlumoraLogoMark(size: 22, color: color, strokeWidth: 2.2)
                  : Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      color: color,
                      size: 22,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
