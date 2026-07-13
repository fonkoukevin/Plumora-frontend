import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../data/models/admin_report_model.dart';
import '../data/repositories/admin_repository.dart';
import 'admin_colors.dart';
import 'admin_shell.dart';
import 'widgets/admin_widgets.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  AdminReportStatus _filter = AdminReportStatus.open;
  final Set<String> _busyIds = {};

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(adminReportsProvider);

    return AdminShell(
      title: 'Signalements',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'Signalements',
              subtitle: reportsAsync.maybeWhen(
                data: (reports) =>
                    '${reports.where((r) => r.status == AdminReportStatus.open).length} signalements en attente',
                orElse: () => 'Modération des signalements',
              ),
            ),
            const SizedBox(height: 16),
            reportsAsync.when(
              loading: () => const AdminLoadingState(),
              error: (error, _) => AdminErrorState(
                message: AppError.messageFor(error),
                onRetry: () => ref.invalidate(adminReportsProvider),
              ),
              data: (reports) {
                final visibleStatuses = [
                  AdminReportStatus.open,
                  AdminReportStatus.inReview,
                  AdminReportStatus.resolved,
                  AdminReportStatus.dismissed,
                ];
                final filtered =
                    reports.where((r) => r.status == _filter).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final status in visibleStatuses)
                          AdminFilterChip(
                            label: status.label,
                            selected: _filter == status,
                            count: reports.where((r) => r.status == status).length,
                            onTap: () => setState(() => _filter = status),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      const AdminEmptyState(
                        title: 'Aucun signalement dans cette catégorie',
                        message: 'Tout est traité pour le moment.',
                        icon: Icons.check_circle_outline,
                      )
                    else
                      Column(
                        children: [
                          for (final report in filtered) ...[
                            _ReportCard(
                              report: report,
                              busy: _busyIds.contains(report.id),
                              onResolve: () => _act(report, _Action.resolve),
                              onReject: () => _act(report, _Action.reject),
                              onView: () => _openDetail(report),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(AdminReport report) {
    showDialog<void>(
      context: context,
      builder: (context) => _ReportDetailDialog(
        report: report,
        onResolve: report.status == AdminReportStatus.resolved
            ? null
            : () {
                Navigator.of(context).pop();
                _act(report, _Action.resolve);
              },
        onReject: report.status == AdminReportStatus.dismissed
            ? null
            : () {
                Navigator.of(context).pop();
                _act(report, _Action.reject);
              },
      ),
    );
  }

  Future<void> _act(AdminReport report, _Action action) async {
    final confirmed = await showAdminConfirmationDialog(
      context,
      title: action == _Action.resolve
          ? 'Résoudre ce signalement ?'
          : 'Rejeter ce signalement ?',
      message: action == _Action.resolve
          ? 'Le signalement sera marqué comme résolu.'
          : 'Le signalement sera rejeté sans action supplémentaire.',
      confirmLabel: action == _Action.resolve ? 'Résoudre' : 'Rejeter',
      danger: action == _Action.reject,
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _busyIds.add(report.id));
    try {
      final repository = ref.read(adminRepositoryProvider);
      if (action == _Action.resolve) {
        await repository.resolveReport(report.id);
      } else {
        await repository.rejectReport(report.id);
      }
      ref.invalidate(adminReportsProvider);
      ref.invalidate(adminDashboardStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == _Action.resolve
                  ? 'Signalement résolu.'
                  : 'Signalement rejeté.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppError.messageFor(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(report.id));
      }
    }
  }
}

enum _Action { resolve, reject }

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.busy,
    required this.onResolve,
    required this.onReject,
    required this.onView,
  });

  final AdminReport report;
  final bool busy;
  final VoidCallback onResolve;
  final VoidCallback onReject;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AdminBadge(
                      label: report.status.label,
                      color: _statusColor(report.status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  report.bookTitle ?? 'Contenu Plumora',
                  style: const TextStyle(
                    color: AdminColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Motif : ${report.reason.isEmpty ? 'Non précisé' : report.reason}',
                  style: const TextStyle(color: AdminColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Signalé par ${report.reporterUsername ?? 'utilisateur'} · ${_formatDate(report.createdAt)}',
                  style: const TextStyle(color: AdminColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Voir le détail',
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined, size: 16, color: AdminColors.primary),
              ),
              if (report.status == AdminReportStatus.open ||
                  report.status == AdminReportStatus.inReview) ...[
                IconButton(
                  tooltip: 'Résoudre',
                  onPressed: busy ? null : onResolve,
                  icon: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline, size: 16, color: AdminColors.success),
                ),
                IconButton(
                  tooltip: 'Rejeter',
                  onPressed: busy ? null : onReject,
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: AdminColors.error),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportDetailDialog extends StatelessWidget {
  const _ReportDetailDialog({
    required this.report,
    required this.onResolve,
    required this.onReject,
  });

  final AdminReport report;
  final VoidCallback? onResolve;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AdminColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Détail du signalement',
                style: TextStyle(
                  color: AdminColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailLine('Contenu', report.bookTitle ?? '—'),
                    _DetailLine('Motif', report.reason.isEmpty ? '—' : report.reason),
                    if ((report.description ?? '').isNotEmpty)
                      _DetailLine('Description', report.description!),
                    _DetailLine('Signalé par', report.reporterUsername ?? '—'),
                    _DetailLine('Date', _formatDate(report.createdAt)),
                    _DetailLine('Statut', report.status.label),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: AdminDangerButton(
                        label: 'Rejeter',
                        onPressed: onReject,
                      ),
                    ),
                  if (onReject != null && onResolve != null)
                    const SizedBox(width: 10),
                  if (onResolve != null)
                    Expanded(
                      child: AdminPrimaryButton(
                        label: 'Résoudre',
                        onPressed: onResolve,
                        icon: Icons.check,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer', style: TextStyle(color: AdminColors.muted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AdminColors.muted, fontSize: 12),
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(color: AdminColors.text, fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(AdminReportStatus status) {
  switch (status) {
    case AdminReportStatus.open:
      return AdminColors.warning;
    case AdminReportStatus.inReview:
      return AdminColors.primary;
    case AdminReportStatus.resolved:
      return AdminColors.success;
    case AdminReportStatus.dismissed:
      return AdminColors.muted;
    case AdminReportStatus.unknown:
      return AdminColors.muted;
  }
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return '—';
  }
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
