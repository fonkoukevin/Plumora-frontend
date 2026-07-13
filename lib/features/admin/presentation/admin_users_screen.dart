import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../data/models/admin_user_model.dart';
import '../data/repositories/admin_repository.dart';
import 'admin_colors.dart';
import 'admin_shell.dart';
import 'widgets/admin_widgets.dart';

const List<String> _roleFilters = ['USER', 'AUTHOR', 'BETA_READER', 'ADMIN'];

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
                        onToggleActive: _toggleActive,
                      );
                    }

                    return Column(
                      children: [
                        for (final user in filtered) ...[
                          _UserCard(
                            user: user,
                            busy: _busyIds.contains(user.id),
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

  Future<void> _toggleActive(AdminUser user) async {
    final activating = !user.active;
    final confirmed = await showAdminConfirmationDialog(
      context,
      title: activating ? 'Réactiver ce compte ?' : 'Désactiver ce compte ?',
      message: activating
          ? '${user.displayName} pourra de nouveau se connecter à Plumora.'
          : '${user.displayName} ne pourra plus se connecter tant que le compte est désactivé.',
      confirmLabel: activating ? 'Réactiver' : 'Désactiver',
      danger: !activating,
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _busyIds.add(user.id));
    try {
      await ref.read(adminRepositoryProvider).setUserActive(user.id, activating);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminDashboardStatsProvider);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppError.messageFor(error))),
        );
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
          width: 260,
          child: AdminSearchField(
            controller: searchController,
            hintText: 'Rechercher un utilisateur...',
            onChanged: onSearchChanged,
          ),
        ),
        _Dropdown<String?>(
          value: roleFilter,
          hint: 'Tous les rôles',
          items: [
            const DropdownMenuItem(value: null, child: Text('Tous les rôles')),
            for (final role in _roleFilters)
              DropdownMenuItem(value: role, child: Text(role)),
          ],
          onChanged: onRoleChanged,
        ),
        _Dropdown<AdminUserStatus?>(
          value: statusFilter,
          hint: 'Tous les statuts',
          items: [
            const DropdownMenuItem(value: null, child: Text('Tous les statuts')),
            for (final status in AdminUserStatus.values)
              DropdownMenuItem(value: status, child: Text(status.label)),
          ],
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: (v) => onChanged(v as T),
          dropdownColor: AdminColors.card,
          style: const TextStyle(color: AdminColors.text, fontSize: 13),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AdminColors.muted,
            size: 18,
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
    required this.onToggleActive,
  });

  final List<AdminUser> users;
  final Set<String> busyIds;
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
                  'Nom',
                  'Email',
                  'Rôle',
                  'Statut',
                  'Inscription',
                  '',
                ].asMap().entries)
                  Expanded(
                    flex: _columns[entry.key],
                    child: Text(
                      entry.value,
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
    required this.onToggleActive,
  });

  final AdminUser user;
  final bool busy;
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
              child: _StatusToggleButton(
                active: user.active,
                busy: busy,
                onTap: onToggleActive,
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
    required this.onToggleActive,
  });

  final AdminUser user;
  final bool busy;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AdminColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              user.initials,
              style: const TextStyle(
                color: AdminColors.primary,
                fontSize: 12,
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
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(color: AdminColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
          _StatusToggleButton(active: user.active, busy: busy, onTap: onToggleActive),
        ],
      ),
    );
  }
}

class _StatusToggleButton extends StatelessWidget {
  const _StatusToggleButton({
    required this.active,
    required this.busy,
    required this.onTap,
  });

  final bool active;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: busy ? null : onTap,
      tooltip: active ? 'Désactiver' : 'Réactiver',
      icon: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              active ? Icons.person_off_outlined : Icons.person_outline,
              size: 17,
              color: active ? AdminColors.error : AdminColors.success,
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
