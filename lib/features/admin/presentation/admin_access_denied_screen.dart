import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import 'admin_colors.dart';

class AdminAccessDeniedScreen extends StatelessWidget {
  const AdminAccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AdminColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AdminColors.error.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AdminColors.error,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Accès interdit',
                  style: TextStyle(
                    color: AdminColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "L'espace Administration est réservé aux comptes disposant du rôle ADMIN.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AdminColors.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("Retour à l'application"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
