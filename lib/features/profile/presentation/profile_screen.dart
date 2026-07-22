import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../../../core/widgets/app_shell_header.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_user_avatar.dart';
import '../../auth/data/models/role_model.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../book/data/repositories/book_repository.dart';
import '../../reading/data/repositories/favorite_repository.dart';
import '../../reading/data/repositories/reading_repository.dart';

const double _profileMaxContentWidth = 1488;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _showPersonalInfo = false;
  bool _loggingOut = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final session = authState.valueOrNull;
    final user = session?.user;
    final roles = session?.roles ?? const <RoleModel>[];

    if (user == null) {
      return FigmaScreen(
        maxWidth: 560,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 92),
        child: FigmaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profil indisponible',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Connecte-toi pour afficher les données de ton compte.',
                style: TextStyle(color: context.colors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }

    if (_showPersonalInfo) {
      return _PersonalInfoView(
        user: user,
        roles: roles,
        onBack: () => setState(() => _showPersonalInfo = false),
      );
    }

    final heroCard = FigmaCard(
      padding: const EdgeInsets.all(28),
      borderColor: Colors.transparent,
      gradient: const LinearGradient(
        colors: [Color(0xFF8B5E3C), Color(0xFF6D3A5D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          PlumoraUserAvatar(name: user.displayName, size: 82),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            _roleLabel(roles),
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showPersonalInfo = true),
            icon: const Icon(Icons.person_outline),
            label: const Text('Informations du compte'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
              backgroundColor: Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );

    final aboutSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À propos',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        FigmaCard(
          child: Text(
            (user.bio ?? '').trim().isEmpty
                ? 'Aucune biographie renseignée.'
                : user.bio!,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
      ],
    );

    final settingsTiles = <Widget>[
      _SettingsTile(
        icon: Icons.person_outline,
        title: 'Informations personnelles',
        subtitle: 'Nom, email et rôles',
        color: const Color(0xFF8B5E3C),
        onTap: () => setState(() => _showPersonalInfo = true),
      ),
      _SettingsTile(
        icon: Icons.notifications_none,
        title: 'Notifications',
        subtitle: 'Voir les notifications du backend',
        color: const Color(0xFF6D3A5D),
        onTap: () => context.push(AppRoutes.notifications),
      ),
      _SettingsTile(
        icon: Icons.auto_awesome,
        title: 'Assistant Plumo',
        subtitle: 'Ouvrir les assistants IA',
        color: const Color(0xFF6D3A5D),
        onTap: () => context.push(AppRoutes.plumoWriting),
      ),
      _SettingsTile(
        icon: Icons.settings_outlined,
        title: 'Préférences',
        subtitle: 'Thème clair ou sombre',
        color: const Color(0xFF6B6B6B),
        onTap: () => context.push(AppRoutes.preferences),
      ),
      if (roles.any((role) => role.name.trim().toUpperCase() == 'ADMIN'))
        _SettingsTile(
          icon: Icons.shield_outlined,
          title: 'Administration',
          subtitle: 'Utilisateurs, catalogue, signalements, Plumo IA',
          color: const Color(0xFFE57373),
          onTap: () => context.go(AppRoutes.admin),
        ),
    ];

    final settingsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        FigmaResponsiveGrid(
          minTileWidth: 500,
          maxColumns: 2,
          spacing: 12,
          runSpacing: 0,
          children: settingsTiles,
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _loggingOut ? null : _logout,
          icon: _loggingOut
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: Text(_loggingOut ? 'Déconnexion...' : 'Se déconnecter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.colors.destructive,
            side: BorderSide(color: context.colors.destructive),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final isDesktop = outerConstraints.maxWidth >= Breakpoints.expanded;

        return FigmaScreen(
          // 1488 px plus this screen's 16 px padding on both sides matches
          // the 1520 px frame used by the Discover navigation page.
          maxWidth: isDesktop ? _profileMaxContentWidth : 860,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 92),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlumoraAppHeader(
                title: 'Mon profil',
                subtitle: '${user.displayName} · ${_roleLabel(roles)}',
                emoji: '👤',
                gradient: [context.colors.plumora, context.colors.accent],
                trailing: const ThemeToggleButton(),
              ),
              const SizedBox(height: 18),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: heroCard),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _ProfileStats(),
                          const SizedBox(height: 24),
                          aboutSection,
                          const SizedBox(height: 24),
                          settingsSection,
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                heroCard,
                const SizedBox(height: 18),
                const _ProfileStats(),
                const SizedBox(height: 24),
                aboutSection,
                const SizedBox(height: 24),
                settingsSection,
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) {
      context.go(AppRoutes.landing);
    }
  }
}

class _PersonalInfoView extends StatelessWidget {
  const _PersonalInfoView({
    required this.user,
    required this.roles,
    required this.onBack,
  });

  final UserModel user;
  final List<RoleModel> roles;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final fields = [
      (Icons.person_outline, 'Prénom', user.firstname),
      (Icons.person_outline, 'Nom', user.lastname),
      (Icons.mail_outline, 'Email', user.email),
      (Icons.alternate_email, 'Nom utilisateur', user.username ?? ''),
      (Icons.edit_note_outlined, 'Biographie', user.bio ?? ''),
    ];

    return FigmaScreen(
      maxWidth: 560,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
      child: Column(
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
              Expanded(
                child: Text(
                  'Informations personnelles',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.editProfile),
                child: const Text('Modifier'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PlumoraUserAvatar(name: user.displayName, size: 96),
          const SizedBox(height: 18),
          for (final field in fields) ...[
            _InfoField(icon: field.$1, label: field.$2, value: field.$3),
            const SizedBox(height: 10),
          ],
          _RolesField(roles: roles),
        ],
      ),
    );
  }
}

class _RolesField extends StatelessWidget {
  const _RolesField({required this.roles});

  final List<RoleModel> roles;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5E3C).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: context.colors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rôles',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _roleLabel(roles),
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.editRoles),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5E3C).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: context.colors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.trim().isEmpty ? 'Non renseigné' : value,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats extends ConsumerWidget {
  const _ProfileStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(myBooksProvider).valueOrNull ?? const [];
    final readings =
        ref.watch(myReadingProgressProvider).valueOrNull ?? const [];
    final favorites = ref.watch(myFavoritesProvider).valueOrNull ?? const [];
    final wordCount = books.fold<int>(0, (sum, book) => sum + book.wordCount);
    final stats = [
      (Icons.menu_book_outlined, books.length.toString(), 'Manuscrits'),
      (Icons.edit_outlined, _compactNumber(wordCount), 'Mots'),
      (Icons.auto_stories_outlined, readings.length.toString(), 'Lectures'),
      (Icons.favorite_border, favorites.length.toString(), 'Favoris'),
    ];

    return FigmaCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final stat in stats)
            Expanded(
              child: Column(
                children: [
                  Icon(stat.$1, color: context.colors.textSecondary, size: 21),
                  const SizedBox(height: 8),
                  Text(
                    stat.$2,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    stat.$3,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FigmaCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

String _roleLabel(List<RoleModel> roles) {
  final names = roles
      .map((role) => _friendlyRoleName(role.name))
      .where((name) => name.isNotEmpty);
  if (names.isEmpty) {
    return 'Utilisateur Plumora';
  }
  return names.join(', ');
}

String _friendlyRoleName(String value) {
  return switch (value.trim().toUpperCase()) {
    'AUTHOR' => 'Auteur',
    'READER' => 'Lecteur',
    'BETA_READER' => 'Bêta-testeur',
    _ => value,
  };
}

String _compactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}
