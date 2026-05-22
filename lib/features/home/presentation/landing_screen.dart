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
      maxPanelWidth: 896,
      topPadding: 14,
      horizontalPadding: 14,
      bottomPadding: 26,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final introText = isWide
              ? "La plateforme qui accompagne les auteurs de l'écriture à la publication,\net aide les lecteurs à découvrir leur prochain livre."
              : "La plateforme qui accompagne les auteurs de l'écriture à\nla publication, et aide les lecteurs à découvrir leur\nprochain livre.";

          final features = [
            const _LandingFeature(
              icon: Icons.desktop_windows_outlined,
              title: 'Écrire',
              subtitle: 'Un éditeur puissant pour donner vie à vos histoires',
            ),
            const _LandingFeature(
              icon: Icons.menu_book_outlined,
              title: 'Publier',
              subtitle: 'Partagez vos œuvres avec une communauté passionnée',
            ),
            const _LandingFeature(
              icon: Icons.library_books_outlined,
              title: 'Découvrir',
              subtitle: 'Des milliers de livres à explorer et à aimer',
              backgroundColor: Color(0xFFEAF3EA),
              iconColor: PlumoraColors.mukemeAccent,
            ),
          ];

          return Column(
            children: [
              const AppWordmark(),
              const SizedBox(height: 18),
              Text(
                'Écris. Publie. Lis. Partage.',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: isWide ? 24 : 19,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 21),
              Text(
                introText,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: PlumoraColors.textSecondary,
                  fontSize: isWide ? 16 : 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 39),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 672),
                child: const _QuoteCard(),
              ),
              const SizedBox(height: 37),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 121,
                    child: FilledButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Se connecter'),
                    ),
                  ),
                  SizedBox(
                    width: 151,
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.register),
                      child: const Text('Créer un compte'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isWide ? 58 : 70),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final feature in features) Expanded(child: feature),
                  ],
                )
              else
                Column(children: features),
            ],
          );
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        border: Border.all(color: const Color(0xFFEBDDC5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: PlumoraColors.cards,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.format_quote,
              color: PlumoraColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 21),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '"N\'attendez pas l\'inspiration. Elle vient en\nécrivant."',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '— Victor Hugo',
                  style: textTheme.bodySmall?.copyWith(
                    color: PlumoraColors.textSecondary,
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

class _LandingFeature extends StatelessWidget {
  const _LandingFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.backgroundColor = const Color(0xFFF0E5D5),
    this.iconColor = PlumoraColors.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 57),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 27),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: PlumoraColors.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
