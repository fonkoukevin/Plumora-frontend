import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final user = session?.user;
    final fullName = user?.displayName.toString().trim().isNotEmpty == true
        ? user!.displayName
        : 'Kevin Martin';
    final email = user?.email.toString().trim().isNotEmpty == true
        ? user!.email
        : 'kevin@plumora.app';
    final initials = _initials(fullName);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final horizontal = isWide ? 32.0 : 16.0;
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 82.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            28,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroProfile(fullName: fullName, initials: initials),
                  const SizedBox(height: 16),
                  const _ProfileStats(),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'À propos',
                    child: const PlumoraCard(
                      shadow: false,
                      child: Text(
                        "Passionné d'écriture depuis mon plus jeune âge, je crée des mondes où la magie rencontre l'émotion.",
                        style: TextStyle(
                          color: PlumoraColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'Compte',
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.mail_outline,
                          title: email,
                          subtitle: 'Adresse email principale',
                        ),
                        const SizedBox(height: 12),
                        const _SettingsTile(
                          icon: Icons.person_outline,
                          title: 'Informations personnelles',
                          subtitle: 'Modifier votre nom, email et photo',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'Paramètres',
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.notifications_none_outlined,
                          title: 'Notifications',
                          subtitle: 'Gérer vos préférences de notification',
                          background: Color(0xFFE8F0F5),
                          color: PlumoraColors.info,
                          onTap: () => context.go(AppRoutes.notifications),
                        ),
                        const SizedBox(height: 12),
                        _SettingsTile(
                          icon: Icons.auto_awesome,
                          title: 'Assistant Mukeme',
                          subtitle: "Configurer votre assistant IA d'écriture",
                          background: Color(0xFFE6EFE4),
                          color: PlumoraColors.mukemeAccent,
                          onTap: () => context.go(AppRoutes.mukemeWriting),
                        ),
                        const SizedBox(height: 12),
                        const _SettingsTile(
                          icon: Icons.shield_outlined,
                          title: 'Confidentialité & sécurité',
                          subtitle:
                              'Mot de passe, authentification et visibilité',
                          background: Color(0xFFE6F0E7),
                          color: PlumoraColors.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .logout();
                        if (context.mounted) {
                          context.go(AppRoutes.landing);
                        }
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Se déconnecter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PlumoraColors.destructive,
                        side: const BorderSide(
                          color: PlumoraColors.destructive,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'PM';
    }
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _HeroProfile extends StatelessWidget {
  const _HeroProfile({required this.fullName, required this.initials});

  final String fullName;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: PlumoraColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: Color(0x22FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(36),
                  border: Border.all(
                    color: Colors.white.withAlpha(80),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                fullName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Auteur passionné',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Modifier le profil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withAlpha(90)),
                    backgroundColor: Colors.white.withAlpha(22),
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

class _ProfileStats extends StatelessWidget {
  const _ProfileStats();

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _ProfileStat(
            icon: Icons.menu_book_outlined,
            value: '12',
            label: 'Manuscrits',
          ),
          _ProfileStat(icon: Icons.draw_outlined, value: '248K', label: 'Mots'),
          _ProfileStat(icon: Icons.schedule, value: '456', label: 'Heures'),
          _ProfileStat(
            icon: Icons.emoji_events_outlined,
            value: '8',
            label: 'Prix',
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          Icon(icon, color: PlumoraColors.textSecondary, size: 20),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.background = PlumoraColors.secondary,
    this.color = PlumoraColors.primary,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          PlumoraIconTile(
            size: 46,
            radius: 11,
            backgroundColor: background,
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
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
