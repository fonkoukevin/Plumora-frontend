import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../data/repositories/admin_repository.dart';
import 'admin_colors.dart';
import 'admin_shell.dart';
import 'widgets/admin_widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

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
                onRetry: () => ref.invalidate(adminDashboardStatsProvider),
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
            final columns = constraints.maxWidth >= 1100
                ? 3
                : constraints.maxWidth >= 700
                ? 2
                : 1;
            const spacing = 14.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            final cards = [
              AdminStatCard(
                icon: Icons.people_outline,
                label: 'Utilisateurs inscrits',
                value: '${stats.totalUsers}',
                sub: '${stats.activeUsers} actifs',
                color: AdminColors.primary,
              ),
              AdminStatCard(
                icon: Icons.menu_book_outlined,
                label: 'Œuvres Plumora',
                value: '${stats.publishedPlumoraWorks}',
                color: AdminColors.accent,
              ),
              AdminStatCard(
                icon: Icons.public,
                label: 'Domaine public',
                value: '${stats.publicDomainBooks}',
                sub: 'Livres importés',
                color: AdminColors.success,
              ),
              AdminStatCard(
                icon: Icons.archive_outlined,
                label: 'Livres archivés',
                value: '${stats.archivedBooks}',
                color: AdminColors.muted,
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
            final activity = _RecentActivityCard(stats: stats);
            final actions = const _QuickActionsCard();

            if (!wide) {
              return Column(
                children: [activity, const SizedBox(height: 16), actions],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 2, child: activity),
                  const SizedBox(width: 20),
                  Expanded(child: actions),
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
  const _RecentActivityCard({required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIVITÉ RÉCENTE',
          style: TextStyle(
            color: AdminColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        if (stats.recentActivity.isEmpty)
          const AdminEmptyState(
            title: 'Aucune activité récente',
            message: 'Les derniers livres et signalements apparaîtront ici.',
            icon: Icons.history,
          )
        else
          AdminCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < stats.recentActivity.length; i++) ...[
                  _ActivityRow(item: stats.recentActivity[i]),
                  if (i != stats.recentActivity.length - 1)
                    const Divider(color: AdminColors.border, height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final AdminActivityItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.kind == AdminActivityKind.report
        ? AdminColors.error
        : AdminColors.primary;
    final icon = item.kind == AdminActivityKind.report
        ? Icons.flag_outlined
        : Icons.menu_book_outlined;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.text, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeDate(item.date),
            style: const TextStyle(color: AdminColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIONS RAPIDES',
          style: TextStyle(
            color: AdminColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        _QuickActionButton(
          label: 'Importer un livre',
          icon: Icons.cloud_download_outlined,
          color: AdminColors.primary,
          onTap: () => context.go(AppRoutes.adminPublicDomainImport),
        ),
        const SizedBox(height: 8),
        _QuickActionButton(
          label: 'Voir les signalements',
          icon: Icons.flag_outlined,
          color: AdminColors.error,
          onTap: () => context.go(AppRoutes.adminReports),
        ),
        const SizedBox(height: 8),
        _QuickActionButton(
          label: 'Gérer les utilisateurs',
          icon: Icons.people_outline,
          color: AdminColors.accent,
          onTap: () => context.go(AppRoutes.adminUsers),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
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
          const Icon(Icons.chevron_right, size: 16, color: AdminColors.muted),
        ],
      ),
    );
  }
}

String _relativeDate(DateTime date) {
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
