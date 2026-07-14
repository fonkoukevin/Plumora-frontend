import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../data/models/admin_action_log_model.dart';
import '../data/models/admin_dashboard_model.dart';
import '../data/repositories/admin_repository.dart';
import 'admin_colors.dart';
import 'admin_shell.dart';
import 'widgets/admin_widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardProvider);

    return AdminShell(
      title: 'Tableau de bord',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminPageHeader(
              title: 'Administration',
              subtitle: 'Supervision de la plateforme Plumora',
            ),
            const SizedBox(height: 22),
            statsAsync.when(
              loading: () => const AdminLoadingState(),
              error: (error, _) => AdminErrorState(
                message: AppError.messageFor(error),
                onRetry: () => ref.invalidate(adminDashboardProvider),
              ),
              data: (stats) => _DashboardContent(stats: stats),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            const spacing = 14.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            final cards = [
              AdminStatCard(
                icon: Icons.people_outline,
                label: 'Utilisateurs',
                value: '${stats.totalUsers}',
                sub: '${stats.activeUsers} actifs',
                color: AdminColors.primary,
              ),
              AdminStatCard(
                icon: Icons.menu_book_outlined,
                label: 'Livres publiés',
                value: '${stats.plumoraBooks}',
                sub: 'Œuvres Plumora',
                color: AdminColors.plumora,
              ),
              AdminStatCard(
                icon: Icons.public,
                label: 'Domaine public',
                value: '${stats.publicDomainBooks}',
                sub: 'Dans le catalogue',
                color: AdminColors.success,
              ),
              AdminStatCard(
                icon: Icons.flag_outlined,
                label: 'Signalements',
                value: '${stats.pendingReports}',
                sub: 'En attente',
                color: AdminColors.error,
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
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            final activity = _RecentActivityCard(
              actions: stats.recentAdminActions,
            );
            final side = const _SidePanel();

            if (!wide) {
              return Column(
                children: [activity, const SizedBox(height: 16), side],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 2, child: activity),
                  const SizedBox(width: 20),
                  Expanded(child: side),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.actions});

  final List<AdminActionLog> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dernières actions administratives',
          style: TextStyle(
            color: AdminColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (actions.isEmpty)
          const AdminEmptyState(
            title: 'Aucune action récente',
            message: 'Les actions des administrateurs apparaîtront ici.',
            icon: Icons.history,
          )
        else
          AdminCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  _ActionRow(action: actions[i]),
                  if (i != actions.length - 1)
                    const Divider(color: AdminColors.border, height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});

  final AdminActionLog action;

  @override
  Widget build(BuildContext context) {
    final visuals = _actionVisuals(action.action);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: visuals.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(visuals.icon, size: 14, color: visuals.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.description.isEmpty
                      ? action.action
                      : action.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AdminColors.text, fontSize: 13),
                ),
                if (action.adminEmail != null)
                  Text(
                    'par ${action.adminEmail}',
                    style: const TextStyle(
                      color: AdminColors.muted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeDate(action.createdAt),
            style: const TextStyle(color: AdminColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

({IconData icon, Color color}) _actionVisuals(String action) {
  switch (action) {
    case 'USER_STATUS_UPDATED':
      return (icon: Icons.person_off_outlined, color: AdminColors.error);
    case 'USER_ROLE_UPDATED':
      return (icon: Icons.edit_outlined, color: AdminColors.primary);
    case 'BOOK_IMPORTED':
      return (icon: Icons.cloud_download_outlined, color: AdminColors.primary);
    case 'BOOK_ARCHIVED':
      return (icon: Icons.archive_outlined, color: AdminColors.warning);
    case 'BOOK_RESTORED':
      return (icon: Icons.restore, color: AdminColors.success);
    case 'BOOK_METADATA_UPDATED':
      return (icon: Icons.edit_note_outlined, color: AdminColors.plumora);
    case 'REPORT_RESOLVED':
      return (icon: Icons.check_circle_outline, color: AdminColors.success);
    case 'REPORT_REJECTED':
      return (icon: Icons.cancel_outlined, color: AdminColors.muted);
    case 'AI_SETTINGS_UPDATED':
      return (icon: Icons.auto_awesome_outlined, color: AdminColors.plumo);
    default:
      return (icon: Icons.circle_outlined, color: AdminColors.muted);
  }
}

class _SidePanel extends ConsumerWidget {
  const _SidePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiAsync = ref.watch(adminAiStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        aiAsync.maybeWhen(
          data: (ai) => AdminCard(
            borderColor: AdminColors.plumo.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 15,
                      color: AdminColors.plumo,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Plumo IA',
                      style: TextStyle(
                        color: AdminColors.plumo,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    AdminBadge(
                      label: ai.enabled ? 'Actif' : 'Désactivé',
                      color: ai.enabled
                          ? AdminColors.success
                          : AdminColors.error,
                      icon: ai.enabled ? Icons.check_circle : Icons.cancel,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Fournisseur : ${ai.providerName} ${ai.modelName}',
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Actions rapides',
          style: TextStyle(
            color: AdminColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _QuickActionButton(
          label: 'Gérer les utilisateurs',
          icon: Icons.people_outline,
          onTap: () => context.go(AppRoutes.adminUsers),
        ),
        const SizedBox(height: 8),
        _QuickActionButton(
          label: 'Consulter le catalogue',
          icon: Icons.menu_book_outlined,
          onTap: () => context.go(AppRoutes.adminCatalog),
        ),
        const SizedBox(height: 8),
        _QuickActionButton(
          label: 'Voir les signalements',
          icon: Icons.flag_outlined,
          onTap: () => context.go(AppRoutes.adminReports),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 15, color: AdminColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AdminColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 14, color: AdminColors.muted),
        ],
      ),
    );
  }
}

String _relativeDate(DateTime? date) {
  if (date == null) {
    return '';
  }
  final local = date.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inMinutes < 1) {
    return "à l'instant";
  }
  if (diff.inHours < 1) {
    return 'il y a ${diff.inMinutes} min';
  }
  if (diff.inHours < 24) {
    return 'il y a ${diff.inHours}h';
  }
  if (diff.inDays < 7) {
    return 'il y a ${diff.inDays}j';
  }
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
