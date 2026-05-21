import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_screen.dart';
import '../../features/catalog/presentation/discover_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reading/presentation/library_screen.dart';
import '../../features/writing/presentation/write_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.auth,
  routes: [
    GoRoute(
      path: AppRoutes.auth,
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return PlumoraShell(location: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.discover,
          name: 'discover',
          builder: (context, state) => const DiscoverScreen(),
        ),
        GoRoute(
          path: AppRoutes.write,
          name: 'write',
          builder: (context, state) => const WriteScreen(),
        ),
        GoRoute(
          path: AppRoutes.library,
          name: 'library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

abstract final class AppRoutes {
  static const String auth = '/auth';
  static const String home = '/';
  static const String discover = '/discover';
  static const String write = '/write';
  static const String library = '/library';
  static const String profile = '/profile';
}

class PlumoraShell extends StatelessWidget {
  const PlumoraShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  static const List<_ShellDestination> _destinations = [
    _ShellDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      path: AppRoutes.home,
    ),
    _ShellDestination(
      label: 'Discover',
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      path: AppRoutes.discover,
    ),
    _ShellDestination(
      label: 'Write',
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note,
      path: AppRoutes.write,
    ),
    _ShellDestination(
      label: 'Library',
      icon: Icons.local_library_outlined,
      selectedIcon: Icons.local_library,
      path: AppRoutes.library,
    ),
    _ShellDestination(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      path: AppRoutes.profile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexFor(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) => _goTo(context, index),
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final destination in _destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: child),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _goTo(context, index),
            destinations: [
              for (final destination in _destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
          ),
        );
      },
    );
  }

  int _selectedIndexFor(String location) {
    final match = _destinations.indexWhere((destination) {
      if (destination.path == AppRoutes.home) {
        return location == AppRoutes.home;
      }

      return location.startsWith(destination.path);
    });

    return match < 0 ? 0 : match;
  }

  void _goTo(BuildContext context, int index) {
    context.go(_destinations[index].path);
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}
