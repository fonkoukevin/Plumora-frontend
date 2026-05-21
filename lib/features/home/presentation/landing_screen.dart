import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../auth/presentation/widgets/auth_screen_shell.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AuthScreenShell(
      child: Column(
        children: [
          const PlumoraLogo(),
          const SizedBox(height: 18),
          Text(
            'Écris. Publie. Lis. Partage.',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          Text(
            "La plateforme qui accompagne les auteurs de l'écriture à la publication, et aide les lecteurs à découvrir leur prochain livre.",
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: PlumoraColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              border: Border.all(color: const Color(0xFFE8D8B8)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.format_quote,
                  color: PlumoraColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  '"N\'attendez pas l\'inspiration. Elle vient en écrivant."',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Victor Hugo',
                  style: textTheme.bodySmall?.copyWith(
                    color: PlumoraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Se connecter'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.register),
                  child: const Text('Créer un compte'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const _LandingFeature(
            icon: Icons.desktop_windows_outlined,
            title: 'Ecrire',
            subtitle: 'Un éditeur puissant pour donner vie à vos histoires',
          ),
          const _LandingFeature(
            icon: Icons.menu_book_outlined,
            title: 'Publier',
            subtitle: 'Partagez vos oeuvres avec une communauté passionnée',
          ),
          const _LandingFeature(
            icon: Icons.library_books_outlined,
            title: 'Découvrir',
            subtitle: 'Des milliers de livres à explorer et à aimer',
            accent: PlumoraColors.mukemeAccent,
          ),
        ],
      ),
    );
  }
}

class _LandingFeature extends StatelessWidget {
  const _LandingFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = PlumoraColors.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withAlpha(36),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: PlumoraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
