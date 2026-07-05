import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _covers = [
    _LandingCover(
      title: "Les Chroniques d'Eldoria",
      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5), Color(0xFF312E81)],
      angle: -0.10,
    ),
    _LandingCover(
      title: 'Au-dela des Etoiles',
      colors: [Color(0xFF1E40AF), Color(0xFF3730A3), Color(0xFF0F172A)],
      angle: 0.04,
      top: 16,
    ),
    _LandingCover(
      title: 'La Nuit Rouge',
      colors: [Color(0xFFF43F5E), Color(0xFFDC2626), Color(0xFFC2410C)],
      angle: -0.02,
    ),
    _LandingCover(
      title: "Sang d'Encre",
      colors: [Color(0xFFDB2777), Color(0xFFBE123C), Color(0xFF991B1B)],
      angle: 0.09,
      top: 16,
    ),
    _LandingCover(
      title: 'La Prophetie',
      colors: [Color(0xFF059669), Color(0xFF0F766E), Color(0xFF155E75)],
      angle: -0.06,
    ),
  ];

  static const _genres = [
    'Fantasy',
    'Romance',
    'Thriller',
    'Sci-Fi',
    'Mystere',
    'Aventure',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlumoraColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 500,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PlumoraColors.primary.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                    child: Row(
                      children: [
                        const FigmaBrandMark(size: 36, textSize: 22),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => context.go(AppRoutes.login),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Se connecter'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 56),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        children: [
                          const _HeroBadge(),
                          const SizedBox(height: 22),
                          const _HeroTitle(),
                          const SizedBox(height: 18),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: const Text(
                              "Ecrivez, publiez, lisez et collaborez avec une communaute passionnee. L'IA Mukeme vous accompagne a chaque etape.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: PlumoraColors.textSecondary,
                                fontSize: 16,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: () => context.go(AppRoutes.register),
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Rejoindre gratuitement'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 56),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 26,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => context.go(AppRoutes.discover),
                                icon: const Icon(Icons.menu_book_outlined),
                                label: const Text('Explorer les livres'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 56),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 26,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 42),
                          const _CoverStack(),
                          const SizedBox(height: 34),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final genre in _genres)
                                ActionChip(
                                  label: Text(genre),
                                  onPressed: () =>
                                      context.go(AppRoutes.discover),
                                  labelStyle: const TextStyle(
                                    color: PlumoraColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  backgroundColor: PlumoraColors.cards,
                                  side: const BorderSide(
                                    color: PlumoraColors.border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const _StatsRow(),
                          const SizedBox(height: 52),
                          const _FeatureGrid(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: PlumoraColors.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: PlumoraColors.primary.withValues(alpha: 0.20),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 15, color: PlumoraColors.accent),
          SizedBox(width: 8),
          Text(
            '+50 000 histoires vous attendent',
            style: TextStyle(
              color: PlumoraColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = width >= 720 ? 56.0 : 39.0;

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Votre prochaine\n'),
          TextSpan(
            text: 'aventure litteraire\n',
            style: TextStyle(
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [PlumoraColors.primary, PlumoraColors.accent],
                ).createShader(const Rect.fromLTWH(0, 0, 420, 80)),
            ),
          ),
          const TextSpan(text: 'commence ici'),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: PlumoraColors.textPrimary,
        fontFamily: 'Playfair Display',
        fontSize: size,
        fontWeight: FontWeight.w900,
        height: 1.06,
      ),
    );
  }
}

class _CoverStack extends StatelessWidget {
  const _CoverStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 190,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < LandingScreen._covers.length; index++)
            Positioned(
              left: index * 46,
              top: LandingScreen._covers[index].top,
              child: Transform.rotate(
                angle: LandingScreen._covers[index].angle,
                child: FigmaBookCover(
                  width: 84,
                  height: 132,
                  colors: LandingScreen._covers[index].colors,
                  title: LandingScreen._covers[index].title,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    const stats = [
      (Icons.menu_book_outlined, '50k+', 'Histoires'),
      (Icons.group_outlined, '12k+', 'Auteurs'),
      (Icons.trending_up, '200k+', 'Lecteurs'),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Row(
        children: [
          for (final stat in stats) ...[
            Expanded(
              child: FigmaCard(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(stat.$1, color: PlumoraColors.primary, size: 18),
                    const SizedBox(height: 7),
                    Text(
                      stat.$2,
                      style: const TextStyle(
                        color: PlumoraColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      stat.$3,
                      style: const TextStyle(
                        color: PlumoraColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (stat != stats.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    const features = [
      _LandingFeature(
        icon: Icons.edit_outlined,
        title: 'Ecrire',
        description: 'Editeur puissant avec IA pour creer vos histoires.',
        color: PlumoraColors.primary,
      ),
      _LandingFeature(
        icon: Icons.search,
        title: 'Decouvrir',
        description: 'Mukeme recommande les livres parfaits selon vos gouts.',
        color: PlumoraColors.secondary,
      ),
      _LandingFeature(
        icon: Icons.rate_review_outlined,
        title: 'Beta-lire',
        description: 'Aidez les auteurs et recevez des retours utiles.',
        color: PlumoraColors.accent,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 1;
        final spacing = 14.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final feature in features)
              SizedBox(
                width: width,
                child: FigmaCard(
                  onTap: () => context.go(AppRoutes.register),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(feature.icon, color: feature.color, size: 30),
                      const SizedBox(height: 14),
                      Text(
                        feature.title,
                        style: const TextStyle(
                          color: PlumoraColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feature.description,
                        style: const TextStyle(
                          color: PlumoraColors.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'En savoir plus',
                            style: TextStyle(
                              color: feature.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: feature.color,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LandingCover {
  const _LandingCover({
    required this.title,
    required this.colors,
    required this.angle,
    this.top = 0,
  });

  final String title;
  final List<Color> colors;
  final double angle;
  final double top;
}

class _LandingFeature {
  const _LandingFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}
