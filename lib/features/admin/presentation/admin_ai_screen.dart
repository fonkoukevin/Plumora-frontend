import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../data/models/admin_ai_status_model.dart';
import '../data/repositories/admin_repository.dart';
import 'admin_colors.dart';
import 'admin_shell.dart';
import 'widgets/admin_widgets.dart';

class AdminAiScreen extends ConsumerStatefulWidget {
  const AdminAiScreen({super.key});

  @override
  ConsumerState<AdminAiScreen> createState() => _AdminAiScreenState();
}

class _AdminAiScreenState extends ConsumerState<AdminAiScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(adminAiStatusProvider);

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
            statusAsync.when(
              loading: () => const AdminLoadingState(),
              error: (error, _) => AdminErrorState(
                message: AppError.messageFor(error),
                onRetry: () => ref.invalidate(adminAiStatusProvider),
              ),
              data: (status) =>
                  _AiContent(status: status, busy: _busy, onToggle: _toggle),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(AdminAiStatus status) async {
    final enabling = !status.enabled;
    final reasonController = TextEditingController();

    final confirmed = await AdminModal.show<bool>(
      context,
      title: enabling ? 'Activer Plumo IA' : 'Désactiver Plumo IA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            enabling
                ? "Plumo IA sera de nouveau disponible pour tous les utilisateurs de la plateforme."
                : "Plumo IA ne sera plus disponible pour aucun utilisateur, sur toute la plateforme, jusqu'à réactivation.",
            style: const TextStyle(
              color: AdminColors.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Raison (facultatif)',
            style: TextStyle(color: AdminColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: reasonController,
            maxLines: 3,
            style: const TextStyle(color: AdminColors.text, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Motif...',
              filled: true,
              fillColor: AdminColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AdminColors.border),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.text,
                    side: const BorderSide(color: AdminColors.border),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: enabling
                    ? AdminPrimaryButton(
                        label: 'Activer',
                        onPressed: () => Navigator.of(context).pop(true),
                      )
                    : AdminDangerButton(
                        label: 'Désactiver',
                        outlined: false,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
              ),
            ],
          ),
        ],
      ),
    );

    final reason = reasonController.text;
    reasonController.dispose();
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateAiSettings(enabling, reason: reason);
      ref.invalidate(adminAiStatusProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabling ? 'Plumo IA activé.' : 'Plumo IA désactivé.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _AiContent extends StatelessWidget {
  const _AiContent({
    required this.status,
    required this.busy,
    required this.onToggle,
  });

  final AdminAiStatus status;
  final bool busy;
  final Future<void> Function(AdminAiStatus status) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminCard(
          borderColor: status.enabled
              ? AdminColors.plumo.withValues(alpha: 0.35)
              : AdminColors.border,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      (status.enabled ? AdminColors.plumo : AdminColors.muted)
                          .withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 26,
                  color: status.enabled ? AdminColors.plumo : AdminColors.muted,
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
                        AdminBadge(
                          label: status.enabled ? 'Actif' : 'Désactivé',
                          color: status.enabled
                              ? AdminColors.success
                              : AdminColors.error,
                          icon: status.enabled
                              ? Icons.check_circle
                              : Icons.cancel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fournisseur : ${status.providerName} · Modèle : ${status.modelName}',
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : status.enabled
                  ? AdminDangerButton(
                      label: 'Désactiver',
                      icon: Icons.power_settings_new,
                      onPressed: () => onToggle(status),
                    )
                  : AdminPrimaryButton(
                      label: 'Activer',
                      icon: Icons.power_settings_new,
                      onPressed: () => onToggle(status),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700
                ? 3
                : constraints.maxWidth >= 420
                ? 2
                : 1;
            const spacing = 14.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            final cards = [
              AdminStatCard(
                icon: Icons.edit_note_outlined,
                label: 'Assistance rédaction',
                value: '${status.totalWritingRequests}',
                sub: 'Requêtes cumulées',
                color: AdminColors.plumo,
              ),
              AdminStatCard(
                icon: Icons.recommend_outlined,
                label: 'Recommandations',
                value: '${status.totalRecommendationRequests}',
                sub: 'Requêtes cumulées',
                color: AdminColors.primary,
              ),
              AdminStatCard(
                icon: Icons.functions,
                label: 'Total appels IA',
                value: '${status.totalCalls}',
                color: AdminColors.plumora,
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final card in cards) SizedBox(width: width, child: card),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.lock_outline,
                    size: 15,
                    color: AdminColors.plumora,
                  ),
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
                label:
                    'Le frontend Flutter ne contacte jamais Gemini directement',
              ),
              const _SecurityRow(
                icon: Icons.fact_check_outlined,
                label:
                    "Les suggestions de Plumo sont toujours validées manuellement par l'auteur",
              ),
              const _SecurityRow(
                icon: Icons.edit_off_outlined,
                label: 'Plumo ne modifie jamais automatiquement les manuscrits',
              ),
            ],
          ),
        ),
      ],
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
