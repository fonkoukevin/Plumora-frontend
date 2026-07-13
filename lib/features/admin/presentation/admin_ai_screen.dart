import 'package:flutter/material.dart';

import 'admin_colors.dart';
import 'admin_shell.dart';
import 'widgets/admin_widgets.dart';

class AdminAiScreen extends StatelessWidget {
  const AdminAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Plumo IA',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminPageHeader(
              title: 'Plumo IA',
              subtitle: "Supervision de l'assistant IA Plumora",
            ),
            const SizedBox(height: 18),
            AdminCard(
              borderColor: AdminColors.plumo.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AdminColors.plumo.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 26,
                      color: AdminColors.plumo,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Plumo IA',
                              style: TextStyle(
                                color: AdminColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const AdminBadge(label: 'Actif', color: AdminColors.success),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Fournisseur : Gemini · Modèle : Gemini 2.5 Flash-Lite',
                          style: TextStyle(color: AdminColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lock_outline, size: 15, color: AdminColors.accent),
                      SizedBox(width: 8),
                      Text(
                        'Sécurité',
                        style: TextStyle(
                          color: AdminColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _SecurityRow(
                    icon: Icons.key_outlined,
                    label: 'Clé API Gemini conservée côté backend uniquement',
                  ),
                  const _SecurityRow(
                    icon: Icons.shield_outlined,
                    label: 'Le frontend Flutter ne contacte jamais Gemini directement',
                  ),
                  const _SecurityRow(
                    icon: Icons.fact_check_outlined,
                    label: "Les suggestions de Plumo sont toujours validées manuellement par l'auteur",
                  ),
                  const _SecurityRow(
                    icon: Icons.edit_off_outlined,
                    label: 'Plumo ne modifie jamais automatiquement les manuscrits',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminCard(
              borderColor: AdminColors.border,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AdminColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Le suivi détaillé (volume d'appels, erreurs récentes, signalements liés aux réponses IA) et l'activation/désactivation à distance ne sont pas encore exposés par le backend — cette section affiche uniquement des informations vérifiées, sans données inventées.",
                      style: TextStyle(color: AdminColors.muted, fontSize: 12, height: 1.5),
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

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AdminColors.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 13, color: AdminColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AdminColors.text, fontSize: 13),
            ),
          ),
          const Icon(Icons.check_circle, size: 15, color: AdminColors.success),
        ],
      ),
    );
  }
}
