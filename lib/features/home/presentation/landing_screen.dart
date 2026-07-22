import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  static const _covers = [
    _LandingCover(
      title: "Les Chroniques d'Eldoria",
      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5), Color(0xFF312E81)],
      angle: -0.10,
    ),
    _LandingCover(
      title: 'Au-delà des Étoiles',
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
      title: 'La Prophétie',
      colors: [Color(0xFF059669), Color(0xFF0F766E), Color(0xFF155E75)],
      angle: -0.06,
    ),
  ];

  static const _genres = [
    'Fantasy',
    'Romance',
    'Thriller',
    'Sci-Fi',
    'Mystère',
    'Aventure',
  ];

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  );
  bool _motionConfigured = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;

    if (MediaQuery.of(context).disableAnimations) {
      _entranceController.value = 1;
    } else {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            _LandingAmbientBackdrop(animation: _entranceController),
            SingleChildScrollView(
              child: Column(
                children: [
                  _LandingEntrance(
                    animation: _entranceController,
                    start: 0,
                    end: 0.28,
                    offsetY: -14,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final loginButton = _GradientPillButton(
                            key: const ValueKey('landing_login_button'),
                            label: 'Se connecter',
                            onPressed: () => context.push(AppRoutes.login),
                            radius: 12,
                            minHeight: 42,
                            horizontalPadding: 20,
                          );

                          if (constraints.maxWidth >= 420) {
                            return Row(
                              children: [
                                const FigmaBrandMark(size: 36, textSize: 22),
                                const Spacer(),
                                loginButton,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              const Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: FigmaBrandMark(
                                      size: 36,
                                      textSize: 22,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              SizedBox(
                                width: constraints.maxWidth < 280 ? 118 : 136,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: loginButton,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 56),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        children: [
                          _LandingEntrance(
                            animation: _entranceController,
                            start: 0.06,
                            end: 0.34,
                            child: const _LandingHoverLift(
                              lift: 2,
                              scale: 1.015,
                              child: _HeroBadge(),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _LandingEntrance(
                            animation: _entranceController,
                            start: 0.10,
                            end: 0.48,
                            offsetY: 28,
                            child: _HeroTitle(animation: _entranceController),
                          ),
                          const SizedBox(height: 18),
                          _LandingEntrance(
                            animation: _entranceController,
                            start: 0.18,
                            end: 0.52,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 448),
                              child: Text(
                                "Écrivez, publiez, lisez et collaborez avec une communauté passionnée. L'IA Plumo vous accompagne à chaque étape.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 16,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          _LandingEntrance(
                            animation: _entranceController,
                            start: 0.24,
                            end: 0.60,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _GradientPillButton(
                                  key: const ValueKey('landing_primary_cta'),
                                  label: 'Rejoindre gratuitement',
                                  onPressed: () =>
                                      context.push(AppRoutes.register),
                                  trailingIcon: Icons.arrow_forward,
                                  radius: 16,
                                  minHeight: 56,
                                  horizontalPadding: 32,
                                ),
                                _LandingSecondaryButton(
                                  label: 'Explorer les livres',
                                  icon: Icons.menu_book_outlined,
                                  onPressed: () =>
                                      context.go(AppRoutes.discover),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 42),
                          _LandingEntrance(
                            animation: _entranceController,
                            start: 0.34,
                            end: 0.72,
                            offsetY: 34,
                            child: _CoverStack(
                              onBookPressed: () =>
                                  context.go(AppRoutes.discover),
                            ),
                          ),
                          const SizedBox(height: 34),
                          _LandingEntrance(
                            animation: _entranceController,
                            start: 0.48,
                            end: 0.78,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final genre in LandingScreen._genres)
                                  _GenreChip(
                                    label: genre,
                                    onPressed: () =>
                                        context.go(AppRoutes.discover),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          _LandingEntrance(
                            animation: _entranceController,
                            start: 0.56,
                            end: 0.86,
                            child: const _StatsRow(),
                          ),
                          const SizedBox(height: 52),
                          _LandingEntrance(
                            animation: _entranceController,
                            start: 0.66,
                            end: 1,
                            offsetY: 32,
                            child: const _FeatureGrid(),
                          ),
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

class _LandingAmbientBackdrop extends StatelessWidget {
  const _LandingAmbientBackdrop({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final value = Curves.easeOutCubic.transform(animation.value);
                final width = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 42 - (12 * value),
                      left: (width - 620) / 2,
                      child: Opacity(
                        opacity: 0.35 + (0.65 * value),
                        child: Container(
                          width: 620,
                          height: 320,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                context.colors.brandPrimary.withValues(
                                  alpha: 0.16,
                                ),
                                context.colors.brandGold.withValues(
                                  alpha: 0.045,
                                ),
                                context.colors.brandPrimary.withValues(
                                  alpha: 0,
                                ),
                              ],
                              stops: const [0, 0.52, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 206 - (24 * value),
                      left: width * 0.075,
                      child: _AmbientSparkle(
                        color: context.colors.primary,
                        size: 20,
                        opacity: 0.12 * value,
                        angle: -0.18 + (0.32 * value),
                      ),
                    ),
                    Positioned(
                      top: 132 + (18 * value),
                      right: width * 0.10,
                      child: _AmbientSparkle(
                        color: context.colors.accent,
                        size: 15,
                        opacity: 0.18 * value,
                        angle: 0.30 - (0.24 * value),
                      ),
                    ),
                    Positioned(
                      top: 460 - (20 * value),
                      right: width * 0.18,
                      child: _AmbientDot(
                        color: context.colors.primary,
                        size: 9,
                        opacity: 0.10 * value,
                      ),
                    ),
                    Positioned(
                      top: 520 + (16 * value),
                      left: width * 0.16,
                      child: _AmbientDot(
                        color: context.colors.accent,
                        size: 7,
                        opacity: 0.15 * value,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AmbientSparkle extends StatelessWidget {
  const _AmbientSparkle({
    required this.color,
    required this.size,
    required this.opacity,
    required this.angle,
  });

  final Color color;
  final double size;
  final double opacity;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Transform.rotate(
        angle: angle,
        child: Icon(Icons.auto_awesome, color: color, size: size),
      ),
    );
  }
}

class _AmbientDot extends StatelessWidget {
  const _AmbientDot({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _LandingEntrance extends StatelessWidget {
  const _LandingEntrance({
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
    this.offsetY = 20,
  });

  final Animation<double> animation;
  final double start;
  final double end;
  final double offsetY;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final raw = ((animation.value - start) / (end - start)).clamp(0.0, 1.0);
        final value = Curves.easeOutCubic.transform(raw);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - value)),
            child: Transform.scale(
              scale: 0.985 + (0.015 * value),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _LandingHoverLift extends StatefulWidget {
  const _LandingHoverLift({
    required this.child,
    this.lift = 6,
    this.scale = 1.02,
  });

  final Widget child;
  final double lift;
  final double scale;

  @override
  State<_LandingHoverLift> createState() => _LandingHoverLiftState();
}

class _LandingHoverLiftState extends State<_LandingHoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: Offset(0, _hovered ? -widget.lift / 100 : 0),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          scale: _hovered ? widget.scale : 1,
          child: widget.child,
        ),
      ),
    );
  }
}

class _GradientPillButton extends StatefulWidget {
  const _GradientPillButton({
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.radius = 16,
    this.minHeight = 56,
    this.horizontalPadding = 32,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? trailingIcon;
  final double radius;
  final double minHeight;
  final double horizontalPadding;

  @override
  State<_GradientPillButton> createState() => _GradientPillButtonState();
}

class _GradientPillButtonState extends State<_GradientPillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.brandPrimary;
    final secondary = context.colors.brandPrimaryLight;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        offset: Offset(0, _hovered ? -0.055 : 0),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          scale: _hovered ? 1.025 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 190),
            constraints: BoxConstraints(minHeight: widget.minHeight),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hovered
                    ? [
                        Color.lerp(primary, Colors.white, 0.08)!,
                        Color.lerp(secondary, context.colors.accent, 0.14)!,
                      ]
                    : [primary, secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: _hovered ? 0.40 : 0.30),
                  blurRadius: _hovered ? 26 : 18,
                  spreadRadius: _hovered ? 1 : 0,
                  offset: Offset(0, _hovered ? 11 : 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(widget.radius),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.horizontalPadding,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.trailingIcon != null) ...[
                          const SizedBox(width: 8),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 190),
                            curve: Curves.easeOutCubic,
                            offset: Offset(_hovered ? 0.18 : 0, 0),
                            child: Icon(
                              widget.trailingIcon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LandingSecondaryButton extends StatefulWidget {
  const _LandingSecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_LandingSecondaryButton> createState() =>
      _LandingSecondaryButtonState();
}

class _LandingSecondaryButtonState extends State<_LandingSecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        offset: Offset(0, _hovered ? -0.05 : 0),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          scale: _hovered ? 1.02 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 190),
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              color: _hovered
                  ? context.colors.primary.withValues(alpha: 0.09)
                  : context.colors.cards.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered
                    ? context.colors.primary
                    : context.colors.primary.withValues(alpha: 0.72),
                width: _hovered ? 1.6 : 1.2,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: context.colors.primary.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          color: context.colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          widget.label,
                          maxLines: 1,
                          style: TextStyle(
                            color: context.colors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenreChip extends StatefulWidget {
  const _GenreChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_GenreChip> createState() => _GenreChipState();
}

class _GenreChipState extends State<_GenreChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        offset: Offset(0, _hovered ? -0.08 : 0),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          scale: _hovered ? 1.045 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: _hovered
                  ? context.colors.primary.withValues(alpha: 0.10)
                  : context.colors.cards,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _hovered
                    ? context.colors.primary.withValues(alpha: 0.65)
                    : context.colors.border,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: context.colors.primary.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: _hovered
                          ? context.colors.primary
                          : context.colors.textSecondary,
                      fontWeight: _hovered ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 15, color: context.colors.accent),
            SizedBox(width: 8),
            Text(
              '+50 000 histoires vous attendent',
              maxLines: 1,
              style: TextStyle(
                color: context.colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = width >= 720 ? 60.0 : 36.0;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final sweep = Curves.easeOutCubic.transform(animation.value);
        return Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Votre prochaine\n'),
              TextSpan(
                text: 'aventure littéraire\n',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = LinearGradient(
                      begin: Alignment(-1.4 + sweep, 0),
                      end: Alignment(0.4 + sweep, 0),
                      colors: [
                        context.colors.brandPrimary,
                        context.colors.brandGold,
                        context.colors.brandPrimaryLight,
                      ],
                    ).createShader(const Rect.fromLTWH(0, 0, 520, 90)),
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
      },
    );
  }
}

class _CoverStack extends StatefulWidget {
  const _CoverStack({required this.onBookPressed});

  final VoidCallback onBookPressed;

  @override
  State<_CoverStack> createState() => _CoverStackState();
}

class _CoverStackState extends State<_CoverStack> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: SizedBox(
        key: const ValueKey('landing_cover_stack'),
        width: double.infinity,
        height: 192,
        child: MouseRegion(
          onEnter: (_) => setState(() => _expanded = true),
          onExit: (_) => setState(() => _expanded = false),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final coverWidth = width < 300 ? 70.0 : 80.0;
              final coverHeight = coverWidth * 1.6;
              final available = width - coverWidth;
              final closedSpan = available * 0.74;
              final start = _expanded ? 0.0 : (available - closedSpan) / 2;
              final spacing =
                  (_expanded ? available : closedSpan) /
                  (LandingScreen._covers.length - 1);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: width * 0.16,
                    right: width * 0.16,
                    top: 102,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      height: _expanded ? 34 : 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primary.withValues(
                              alpha: _expanded ? 0.20 : 0.10,
                            ),
                            blurRadius: _expanded ? 30 : 20,
                            spreadRadius: _expanded ? 4 : 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                  for (
                    var index = 0;
                    index < LandingScreen._covers.length;
                    index++
                  )
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: start + (index * spacing),
                      top:
                          LandingScreen._covers[index].top +
                          (_expanded ? (index.isOdd ? -5 : 0) : 7),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        tween: Tween(
                          end: _expanded
                              ? LandingScreen._covers[index].angle * 0.45
                              : LandingScreen._covers[index].angle,
                        ),
                        builder: (context, angle, child) =>
                            Transform.rotate(angle: angle, child: child),
                        child: _LandingCoverButton(
                          key: ValueKey('landing_cover_$index'),
                          cover: LandingScreen._covers[index],
                          width: coverWidth,
                          height: coverHeight,
                          onPressed: widget.onBookPressed,
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
                            stops: const [0.0, 0.10, 0.90, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _expanded ? 1 : 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Découvrir ces histoires',
                              style: TextStyle(
                                color: context.colors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: context.colors.primary,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LandingCoverButton extends StatefulWidget {
  const _LandingCoverButton({
    required this.cover,
    required this.width,
    required this.height,
    required this.onPressed,
    super.key,
  });

  final _LandingCover cover;
  final double width;
  final double height;
  final VoidCallback onPressed;

  @override
  State<_LandingCoverButton> createState() => _LandingCoverButtonState();
}

class _LandingCoverButtonState extends State<_LandingCoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Découvrir ${widget.cover.title}',
      child: Tooltip(
        message: widget.cover.title,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 190),
            curve: Curves.easeOutCubic,
            offset: Offset(0, _hovered ? -0.08 : 0),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 190),
              curve: Curves.easeOutBack,
              scale: _hovered ? 1.075 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 190),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _hovered ? 0.24 : 0.12,
                      ),
                      blurRadius: _hovered ? 22 : 10,
                      offset: Offset(0, _hovered ? 12 : 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPressed,
                    borderRadius: BorderRadius.circular(10),
                    child: FigmaBookCover(
                      width: widget.width,
                      height: widget.height,
                      colors: widget.cover.colors,
                      title: widget.cover.title,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
              child: _LandingHoverLift(
                lift: 4,
                scale: 1.035,
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
        title: 'Écrire',
        description:
            'Éditeur puissant avec IA pour créer vos histoires sans limites',
        color: context.colors.brandPrimary,
      ),
      _LandingFeature(
        emoji: '🔍',
        title: 'Découvrir',
        description:
            'Plumo vous recommande les livres parfaits selon vos goûts',
        color: context.colors.brandNavy,
      ),
      _LandingFeature(
        emoji: '📚',
        title: 'Bêta-lire',
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
                  child: _LandingHoverLift(
                    lift: 7,
                    scale: 1.018,
                    child: FigmaCard(
                      onTap: () => context.push(AppRoutes.register),
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
