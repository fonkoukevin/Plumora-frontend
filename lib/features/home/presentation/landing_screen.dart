import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 500,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          context.colors.brandPrimary.withValues(alpha: 0.16),
                          context.colors.brandPrimary.withValues(alpha: 0),
                        ],
                      ),
                    ),
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
                        _GradientPillButton(
                          label: 'Se connecter',
                          onPressed: () => context.go(AppRoutes.login),
                          radius: 12,
                          minHeight: 42,
                          horizontalPadding: 20,
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
                            constraints: const BoxConstraints(maxWidth: 448),
                            child: Text(
                              "Ecrivez, publiez, lisez et collaborez avec une communaute passionnee. L'IA Plumo vous accompagne a chaque etape.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 16,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _GradientPillButton(
                                label: 'Rejoindre gratuitement',
                                onPressed: () => context.go(AppRoutes.register),
                                trailingIcon: Icons.arrow_forward,
                                radius: 16,
                                minHeight: 56,
                                horizontalPadding: 32,
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
                                    borderRadius: BorderRadius.circular(16),
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
                                  labelStyle: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  backgroundColor: context.colors.cards,
                                  side: BorderSide(
                                    color: context.colors.border,
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

class _GradientPillButton extends StatelessWidget {
  const _GradientPillButton({
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.radius = 16,
    this.minHeight = 56,
    this.horizontalPadding = 32,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? trailingIcon;
  final double radius;
  final double minHeight;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.brandPrimary,
            context.colors.brandPrimaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: context.colors.brandPrimary.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, color: Colors.white, size: 20),
                ],
              ],
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.20),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 15, color: context.colors.accent),
          SizedBox(width: 8),
          Text(
            '+50 000 histoires vous attendent',
            style: TextStyle(
              color: context.colors.primary,
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
    final size = width >= 720 ? 60.0 : 36.0;

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Votre prochaine\n'),
          TextSpan(
            text: 'aventure litteraire\n',
            style: TextStyle(
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [
                    context.colors.brandPrimary,
                    context.colors.brandGold,
                  ],
                ).createShader(const Rect.fromLTWH(0, 0, 420, 80)),
            ),
          ),
          const TextSpan(text: 'commence ici'),
        ],
      ),
      textAlign: TextAlign.center,
      style: GoogleFonts.playfairDisplay(
        color: context.colors.textPrimary,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
    );
  }
}

class _CoverStack extends StatelessWidget {
  const _CoverStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 192,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < LandingScreen._covers.length; index++)
            Positioned(
              left: index * 44,
              top: LandingScreen._covers[index].top,
              child: Transform.rotate(
                angle: LandingScreen._covers[index].angle,
                child: FigmaBookCover(
                  width: 80,
                  height: 128,
                  colors: LandingScreen._covers[index].colors,
                  title: LandingScreen._covers[index].title,
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colors.background,
                      context.colors.background.withValues(alpha: 0),
                      context.colors.background.withValues(alpha: 0),
                      context.colors.background,
                    ],
                    stops: const [0.0, 0.15, 0.85, 1.0],
                  ),
                ),
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
      constraints: const BoxConstraints(maxWidth: 320),
      child: Row(
        children: [
          for (final stat in stats) ...[
            Expanded(
              child: FigmaCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(stat.$1, color: context.colors.primary, size: 16),
                    const SizedBox(height: 7),
                    Text(
                      stat.$2,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      stat.$3,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (stat != stats.last) const SizedBox(width: 16),
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
    final features = [
      _LandingFeature(
        emoji: '✍️',
        title: 'Ecrire',
        description:
            'Editeur puissant avec IA pour creer vos histoires sans limites',
        color: context.colors.brandPrimary,
      ),
      _LandingFeature(
        emoji: '🔍',
        title: 'Decouvrir',
        description:
            'Plumo vous recommande les livres parfaits selon vos gouts',
        color: context.colors.brandNavy,
      ),
      _LandingFeature(
        emoji: '📚',
        title: 'Beta-lire',
        description:
            'Aidez les auteurs et recevez des retours sur vos manuscrits',
        color: context.colors.brandGold,
      ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 896),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 720 ? 3 : 1;
          final spacing = 16.0;
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.emoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          feature.title,
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          feature.description,
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'En savoir plus',
                              style: TextStyle(
                                color: feature.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              color: feature.color,
                              size: 14,
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
      ),
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
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });

  final String emoji;
  final String title;
  final String description;
  final Color color;
}
