import 'package:flutter/material.dart';

import 'admin_colors.dart';
import 'admin_shell.dart';
import 'widgets/admin_widgets.dart';

/// The Figma mockup shows toggles for feature flags, moderation mode and
/// role management, but the backend exposes no settings controller/endpoint
/// today (verified against the API source) — so this screen intentionally
/// does not render controls that can't actually be saved. Wiring the real
/// toggles is a follow-up once `/admin/settings` (or equivalent) exists.
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Paramètres',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminPageHeader(
              title: 'Paramètres',
              subtitle: 'Configuration générale de la plateforme',
            ),
            const SizedBox(height: 20),
            AdminEmptyState(
              title: 'Aucun paramètre configurable pour le moment',
              message:
                  "Le backend n'expose pas encore de réglages administrateur "
                  "(import domaine public, Plumo IA, modération...). Cette page "
                  "affichera les options réelles dès qu'un endpoint /admin/settings "
                  "sera disponible côté API.",
              icon: Icons.tune,
            ),
            const SizedBox(height: 16),
            AdminCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.groups_outlined, size: 16, color: AdminColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rôles disponibles',
                          style: TextStyle(
                            color: AdminColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'USER, AUTHOR, BETA_READER, ADMIN — la gestion du rôle '
                          "d'un compte se fait depuis Utilisateurs (activation/désactivation "
                          "uniquement ; le changement de rôle par un administrateur n'est pas "
                          'encore supporté par le backend).',
                          style: TextStyle(color: AdminColors.muted, fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
