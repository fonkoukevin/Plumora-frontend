import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../data/models/admin_user_model.dart';
import '../data/repositories/admin_repository.dart';
import 'admin_colors.dart';
import 'admin_shell.dart';
import 'widgets/admin_widgets.dart';

/// Real backend `RoleName` values — the maquette's dropdown mockup listed a
/// non-existent "USER" role; this uses the actual enum instead.
const List<String> _assignableRoles = [
  'AUTHOR',
  'READER',
  'BETA_READER',
  'ADMIN',
];

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _roleFilter;
  AdminUserStatus? _statusFilter;
  final Set<String> _busyIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return AdminShell(
      title: 'Utilisateurs',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'Utilisateurs',
              subtitle: usersAsync.maybeWhen(
                data: (users) => '${users.length} comptes inscrits',
                orElse: () => 'Gestion des comptes Plumora',
              ),
            ),
            const SizedBox(height: 18),
            _Filters(
              searchController: _searchController,
              roleFilter: _roleFilter,
              statusFilter: _statusFilter,
              onSearchChanged: (value) => setState(() => _search = value),
              onRoleChanged: (value) => setState(() => _roleFilter = value),
              onStatusChanged: (value) => setState(() => _statusFilter = value),
            ),
            const SizedBox(height: 16),
            usersAsync.when(
              loading: () => const AdminLoadingState(),
              error: (error, _) => AdminErrorState(
                message: AppError.messageFor(error),
                onRetry: () => ref.invalidate(adminUsersProvider),
              ),
              data: (users) {
                final filtered = users.where(_matches).toList();
                if (filtered.isEmpty) {
                  return const AdminEmptyState(
                    title: 'Aucun utilisateur trouvé',
                    message: 'Essaie une autre recherche ou un autre filtre.',
                    icon: Icons.people_outline,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 860) {
                      return _UsersTable(
                        users: filtered,
                        busyIds: _busyIds,
                        onDetail: _openDetail,
                        onRole: _openRoleEditor,
                        onToggleActive: _toggleActive,
                      );
                    }

                    return Column(
                      children: [
                        for (final user in filtered) ...[
                          _UserCard(
                            user: user,
                            busy: _busyIds.contains(user.id),
                            onDetail: () => _openDetail(user),
                            onRole: () => _openRoleEditor(user),
                            onToggleActive: () => _toggleActive(user),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _matches(AdminUser user) {
    final query = _search.trim().toLowerCase();
    final matchesSearch =
        query.isEmpty ||
        user.displayName.toLowerCase().contains(query) ||
        user.email.toLowerCase().contains(query);
    final matchesRole = _roleFilter == null || user.roles.contains(_roleFilter);
    final matchesStatus = _statusFilter == null || user.status == _statusFilter;
    return matchesSearch && matchesRole && matchesStatus;
  }

  Future<void> _openDetail(AdminUser user) async {
    setState(() => _busyIds.add(user.id));
    AdminUser detail = user;
    try {
      detail = await ref.read(adminRepositoryProvider).getUserDetail(user.id);
    } catch (_) {
      // Falls back to the list-row data if the detail call fails.
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(user.id));
      }
    }
    if (!mounted) {
      return;
    }

    await AdminModal.show<void>(
      context,
      title: 'Détail utilisateur',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AdminColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  detail.initials,
                  style: const TextStyle(
                    color: AdminColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.displayName,
                      style: const TextStyle(
                        color: AdminColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      detail.email,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final role in detail.roles)
                          AdminRoleBadge(role: role),
                        AdminBadge(
                          label: detail.status.label,
                          color: detail.active
                              ? AdminColors.success
                              : AdminColors.error,
                          icon: detail.active
                              ? Icons.check_circle
                              : Icons.cancel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminDetailRow(
            label: 'Inscription',
            value: Text(_formatDate(detail.createdAt)),
          ),
          if (detail.booksCount != null)
            AdminDetailRow(
              label: 'Livres publiés',
              value: Text(
                '${detail.booksCount}',
                style: const TextStyle(color: AdminColors.text),
              ),
            ),
          if (detail.reportsCount != null)
            AdminDetailRow(
              label: 'Signalements reçus',
              value: Text(
                '${detail.reportsCount}',
                style: const TextStyle(color: AdminColors.text),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openRoleEditor(AdminUser user) async {
    var selectedRole = user.roles.isNotEmpty
        ? user.roles.first.toUpperCase()
        : _assignableRoles.first;
    if (!_assignableRoles.contains(selectedRole)) {
      selectedRole = _assignableRoles.first;
    }

    final confirmed = await AdminModal.show<bool>(
      context,
      title: 'Modifier le rôle',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 13,
                  ),
                  children: [
                    const TextSpan(text: 'Rôle actuel de '),
                    TextSpan(
                      text: user.displayName,
                      style: const TextStyle(
                        color: AdminColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' : '),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final role in user.roles) AdminRoleBadge(role: role),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Nouveau rôle',
                style: TextStyle(color: AdminColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AdminColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    items: [
                      for (final role in _assignableRoles)
                        DropdownMenuItem(value: role, child: Text(role)),
                    ],
                    onChanged: (value) =>
                        setModalState(() => selectedRole = value!),
                    style: const TextStyle(
                      color: AdminColors.text,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                    child: AdminPrimaryButton(
                      label: 'Confirmer',
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

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busyIds.add(user.id));
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateUserRole(user.id, selectedRole);
      ref.invalidate(adminUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rôle de ${user.displayName} modifié en $selectedRole.',
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
        setState(() => _busyIds.remove(user.id));
      }
    }
  }

  Future<void> _toggleActive(AdminUser user) async {
    final activating = !user.active;
    final reasonController = TextEditingController();

    final confirmed = await AdminModal.show<bool>(
      context,
      title: activating ? 'Réactiver le compte' : 'Désactiver le compte',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!activating)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AdminColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AdminColors.error.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: AdminColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: AdminColors.error,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: user.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text:
                                ' ne pourra plus se connecter ni accéder à la plateforme.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'Voulez-vous réactiver le compte de ${user.displayName} ? L\'utilisateur pourra de nouveau se connecter.',
                style: const TextStyle(color: AdminColors.muted, fontSize: 13),
              ),
            ),
          if (!activating) ...[
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
                hintText: 'Motif de désactivation...',
                filled: true,
                fillColor: AdminColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AdminColors.border),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                child: activating
                    ? AdminPrimaryButton(
                        label: 'Réactiver',
                        icon: Icons.person_outline,
                        onPressed: () => Navigator.of(context).pop(true),
                      )
                    : AdminDangerButton(
                        label: 'Désactiver',
                        outlined: false,
                        icon: Icons.person_off_outlined,
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

    setState(() => _busyIds.add(user.id));
    try {
      await ref
          .read(adminRepositoryProvider)
          .setUserActive(user.id, activating, reason: reason);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              activating ? 'Compte réactivé.' : 'Compte désactivé.',
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
        setState(() => _busyIds.remove(user.id));
      }
    }
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.searchController,
    required this.roleFilter,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String? roleFilter;
  final AdminUserStatus? statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<AdminUserStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 240,
          child: AdminSearchField(
            controller: searchController,
            hintText: 'Nom ou email...',
            onChanged: onSearchChanged,
          ),
        ),
        AdminFilterChip(
          label: 'Tous',
          selected: roleFilter == null,
          onTap: () => onRoleChanged(null),
        ),
        for (final role in _assignableRoles)
          AdminFilterChip(
            label: role,
            selected: roleFilter == role,
            onTap: () => onRoleChanged(role),
          ),
        _StatusDropdown(value: statusFilter, onChanged: onStatusChanged),
      ],
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});

  final AdminUserStatus? value;
  final ValueChanged<AdminUserStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AdminUserStatus?>(
          value: value,
          items: [
            const DropdownMenuItem(value: null, child: Text('Tous statuts')),
            for (final status in AdminUserStatus.values)
              DropdownMenuItem(value: status, child: Text(status.label)),
          ],
          onChanged: onChanged,
          style: const TextStyle(color: AdminColors.text, fontSize: 12),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AdminColors.muted,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.busyIds,
    required this.onDetail,
    required this.onRole,
    required this.onToggleActive,
  });

  final List<AdminUser> users;
  final Set<String> busyIds;
  final ValueChanged<AdminUser> onDetail;
  final ValueChanged<AdminUser> onRole;
  final ValueChanged<AdminUser> onToggleActive;

  static const _columns = [2, 2, 1, 1, 1, 1];

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Row(
              children: [
                for (final entry in [
                  'NOM',
                  'EMAIL',
                  'RÔLE',
                  'STATUT',
                  'INSCRIPTION',
                  'ACTIONS',
                ].asMap().entries)
                  Expanded(
                    flex: _columns[entry.key],
                    child: Text(
                      entry.value,
                      textAlign: entry.key == 5 ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < users.length; i++) ...[
            _UserRow(
              user: users[i],
              busy: busyIds.contains(users[i].id),
              onDetail: () => onDetail(users[i]),
              onRole: () => onRole(users[i]),
              onToggleActive: () => onToggleActive(users[i]),
            ),
            if (i != users.length - 1)
              const Divider(color: AdminColors.border, height: 1),
          ],
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.busy,
    required this.onDetail,
    required this.onRole,
    required this.onToggleActive,
  });

  final AdminUser user;
  final bool busy;
  final VoidCallback onDetail;
  final VoidCallback onRole;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: AdminColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AdminColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminColors.muted, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: user.roles.isEmpty
                ? const Text('—', style: TextStyle(color: AdminColors.muted))
                : AdminRoleBadge(role: user.roles.first),
          ),
          Expanded(
            flex: 1,
            child: AdminBadge(
              label: user.status.label,
              color: user.active ? AdminColors.success : AdminColors.error,
              icon: user.active ? Icons.check_circle : Icons.cancel,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _formatDate(user.createdAt),
              style: const TextStyle(color: AdminColors.muted, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Voir le détail',
                          onPressed: onDetail,
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 15,
                            color: AdminColors.muted,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Changer le rôle',
                          onPressed: onRole,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: AdminColors.muted,
                          ),
                        ),
                        IconButton(
                          tooltip: user.active ? 'Désactiver' : 'Réactiver',
                          onPressed: onToggleActive,
                          icon: Icon(
                            user.active
                                ? Icons.person_off_outlined
                                : Icons.person_outline,
                            size: 15,
                            color: user.active
                                ? AdminColors.error
                                : AdminColors.success,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.busy,
    required this.onDetail,
    required this.onRole,
    required this.onToggleActive,
  });

  final AdminUser user;
  final bool busy;
  final VoidCallback onDetail;
  final VoidCallback onRole;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AdminColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: AdminColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: AdminColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (user.roles.isNotEmpty)
                          AdminRoleBadge(role: user.roles.first),
                        AdminBadge(
                          label: user.status.label,
                          color: user.active
                              ? AdminColors.success
                              : AdminColors.error,
                          icon: user.active ? Icons.check_circle : Icons.cancel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (busy)
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDetail,
                    icon: const Icon(Icons.visibility_outlined, size: 13),
                    label: const Text('Détail', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.text,
                      side: const BorderSide(color: AdminColors.border),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRole,
                    icon: const Icon(Icons.edit_outlined, size: 13),
                    label: const Text('Rôle', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.text,
                      side: const BorderSide(color: AdminColors.border),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: user.active
                      ? AdminDangerButton(
                          label: 'Désactiver',
                          onPressed: onToggleActive,
                          icon: Icons.person_off_outlined,
                        )
                      : OutlinedButton.icon(
                          onPressed: onToggleActive,
                          icon: const Icon(Icons.person_outline, size: 13),
                          label: const Text(
                            'Réactiver',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AdminColors.success,
                            side: const BorderSide(color: AdminColors.success),
                          ),
                        ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return '—';
  }
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
