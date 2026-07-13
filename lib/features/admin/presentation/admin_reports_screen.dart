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

  static const _filters = [
    AdminReportStatus.open,
    AdminReportStatus.inReview,
    AdminReportStatus.resolved,
    AdminReportStatus.dismissed,
  ];

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
                final filtered = reports.where((r) => r.status == _filter).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final status in _filters)
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
                              onView: () => _openDetail(report),
                              onInReview: () => _markInReview(report),
                              onResolve: () => _resolve(report),
                              onReject: () => _reject(report),
                              onArchiveContent: report.bookId != null ? () => _archiveContent(report) : null,
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
    AdminModal.show<void>(
      context,
      title: 'Signalement ${report.id.length > 8 ? report.id.substring(0, 8) : report.id}',
      maxWidth: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminDetailRow(
            label: 'Contenu signalé',
            value: Text(report.bookTitle ?? '—', textAlign: TextAlign.right),
          ),
          AdminDetailRow(label: 'Signalé par', value: Text(report.reporterUsername ?? '—')),
          AdminDetailRow(label: 'Motif', value: Text(report.reason.isEmpty ? '—' : report.reason)),
          AdminDetailRow(label: 'Statut', value: AdminBadge(label: report.status.label, color: _statusColor(report.status))),
          AdminDetailRow(label: 'Date', value: Text(_formatDate(report.createdAt))),
          if (report.resolvedAt != null)
            AdminDetailRow(label: 'Clôturé le', value: Text(_formatDate(report.resolvedAt))),
          if ((report.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Description', style: TextStyle(color: AdminColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(report.description!, style: const TextStyle(color: AdminColors.text, fontSize: 13, height: 1.45)),
          ],
        ],
      ),
    );
  }

  Future<void> _markInReview(AdminReport report) => _act(
        report,
        (repo) => repo.markReportInReview(report.id),
        successMessage: 'Signalement passé en cours.',
      );

  Future<void> _resolve(AdminReport report) async {
    final reason = await _promptReason(
      title: 'Résoudre le signalement',
      label: 'Commentaire administrateur (facultatif)',
      confirmLabel: 'Résoudre',
      danger: false,
    );
    if (reason == null || !mounted) {
      return;
    }
    await _act(
      report,
      (repo) => repo.resolveReport(report.id, reason: reason),
      successMessage: 'Signalement résolu.',
    );
  }

  Future<void> _reject(AdminReport report) async {
    final reason = await _promptReason(
      title: 'Rejeter le signalement',
      label: 'Justification',
      confirmLabel: 'Rejeter',
      danger: true,
    );
    if (reason == null || !mounted) {
      return;
    }
    await _act(
      report,
      (repo) => repo.rejectReport(report.id, reason: reason),
      successMessage: 'Signalement rejeté.',
    );
  }

  Future<void> _archiveContent(AdminReport report) async {
    final confirmed = await showAdminConfirmationDialog(
      context,
      title: 'Archiver le contenu',
      message: 'Le livre "${report.bookTitle ?? ''}" sera archivé et ne sera plus visible publiquement.',
      confirmLabel: 'Archiver le contenu',
    );
    if (!confirmed || !mounted) {
      return;
    }
    final bookId = report.bookId;
    if (bookId == null) {
      return;
    }
    await _act(
      report,
      (repo) => repo.archiveBook(bookId).then((_) => repo.resolveReport(report.id)),
      successMessage: 'Contenu archivé.',
    );
  }

  Future<String?> _promptReason({
    required String title,
    required String label,
    required String confirmLabel,
    required bool danger,
  }) async {
    final controller = TextEditingController();
    final confirmed = await AdminModal.show<bool>(
      context,
      title: title,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AdminColors.muted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                maxLines: 3,
                onChanged: (_) => setModalState(() {}),
                style: const TextStyle(color: AdminColors.text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: danger ? 'Raison du rejet...' : 'Résumé de la décision...',
                  filled: true,
                  fillColor: AdminColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AdminColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(foregroundColor: AdminColors.text, side: const BorderSide(color: AdminColors.border)),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: danger
                        ? AdminDangerButton(
                            label: confirmLabel,
                            outlined: false,
                            onPressed: controller.text.trim().isEmpty
                                ? null
                                : () => Navigator.of(context).pop(true),
                          )
                        : AdminPrimaryButton(
                            label: confirmLabel,
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final reason = controller.text;
    controller.dispose();
    return confirmed == true ? reason : null;
  }

  Future<void> _act(
    AdminReport report,
    Future<void> Function(AdminRepository repo) action, {
    required String successMessage,
  }) async {
    setState(() => _busyIds.add(report.id));
    try {
      await action(ref.read(adminRepositoryProvider));
      ref.invalidate(adminReportsProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(report.id));
      }
    }
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.busy,
    required this.onView,
    required this.onInReview,
    required this.onResolve,
    required this.onReject,
    required this.onArchiveContent,
  });

  final AdminReport report;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onInReview;
  final VoidCallback onResolve;
  final VoidCallback onReject;
  final VoidCallback? onArchiveContent;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      borderColor: report.status == AdminReportStatus.open
          ? AdminColors.primary.withValues(alpha: 0.4)
          : AdminColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminBadge(label: report.status.label, color: _statusColor(report.status)),
                    const SizedBox(height: 8),
                    Text(
                      report.bookTitle ?? 'Contenu Plumora',
                      style: const TextStyle(color: AdminColors.text, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Motif : ${report.reason.isEmpty ? 'Non précisé' : report.reason}',
                      style: const TextStyle(color: AdminColors.muted, fontSize: 12),
                    ),
                    Text(
                      'Signalé par ${report.reporterUsername ?? 'utilisateur'} · ${_formatDate(report.createdAt)}',
                      style: const TextStyle(color: AdminColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                  tooltip: 'Consulter',
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 16, color: AdminColors.primary),
                ),
            ],
          ),
          if (!busy && report.status == AdminReportStatus.open) ...[
            const Divider(color: AdminColors.border, height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SmallActionButton(label: 'Passer en cours', icon: Icons.schedule, color: AdminColors.primary, onTap: onInReview),
                _SmallActionButton(label: 'Résoudre', icon: Icons.check_circle_outline, color: AdminColors.success, onTap: onResolve),
                _SmallActionButton(label: 'Rejeter', icon: Icons.cancel_outlined, color: AdminColors.error, outline: true, onTap: onReject),
              ],
            ),
          ],
          if (!busy && report.status == AdminReportStatus.inReview) ...[
            const Divider(color: AdminColors.border, height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SmallActionButton(label: 'Résoudre', icon: Icons.check_circle_outline, color: AdminColors.success, onTap: onResolve),
                _SmallActionButton(label: 'Rejeter', icon: Icons.cancel_outlined, color: AdminColors.error, outline: true, onTap: onReject),
                if (onArchiveContent != null)
                  _SmallActionButton(label: 'Archiver le contenu', icon: Icons.archive_outlined, color: AdminColors.error, onTap: onArchiveContent!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outline = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: outline ? color : Colors.white,
        backgroundColor: outline ? Colors.transparent : color,
        side: BorderSide(color: color),
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
