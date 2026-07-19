import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';
import '../theme/plumora_colors.dart';
import 'plumora_placeholder_screen.dart';

/// Shown when a Flutter Web visitor lands on (or refreshes) a URL that
/// doesn't match any route — e.g. a stale link or a typo — instead of
/// go_router's default bare error page.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: PlumoraPlaceholderScreen(
        title: 'Page introuvable',
        subtitle:
            "Cette page n'existe pas ou plus. Vérifie l'adresse ou "
            'retourne à l\'accueil.',
        icon: Icons.explore_off_outlined,
        actions: [
          FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text("Retour à l'accueil"),
          ),
        ],
      ),
    );
  }
}
