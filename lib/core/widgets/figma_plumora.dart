import 'package:flutter/material.dart';

import '../theme/plumora_colors.dart';
import 'plumora_logo_mark.dart';

class FigmaScreen extends StatelessWidget {
  const FigmaScreen({
    required this.child,
    this.maxWidth = 1280,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 88),
    this.scroll = true,
    this.center = true,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool scroll;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

    final content = center ? Center(child: body) : body;

    return ColoredBox(
      color: PlumoraColors.background,
      child: scroll ? SingleChildScrollView(child: content) : content,
    );
  }
}

class FigmaCard extends StatelessWidget {
  const FigmaCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.color = PlumoraColors.cards,
    this.borderColor = PlumoraColors.border,
    this.gradient,
    this.radius = 16,
    this.shadow = true,
    this.clip = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final Gradient? gradient;
  final double radius;
  final bool shadow;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final radiusValue = BorderRadius.circular(radius);
    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: radiusValue,
        border: Border.all(color: borderColor),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return decorated;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radiusValue,
        hoverColor: PlumoraColors.muted.withValues(alpha: 0.5),
        child: decorated,
      ),
    );
  }
}

class FigmaGradientIcon extends StatelessWidget {
  const FigmaGradientIcon({
    required this.icon,
    this.size = 48,
    this.iconSize = 24,
    this.colors = const [PlumoraColors.primary, PlumoraColors.primaryLight],
    this.radius = 16,
    super.key,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final List<Color> colors;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

class FigmaBrandMark extends StatelessWidget {
  const FigmaBrandMark({
    this.size = 40,
    this.showText = true,
    this.textSize = 24,
    this.gradient = true,
    super.key,
  });

  final double size;
  final bool showText;
  final double textSize;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: gradient ? null : PlumoraColors.primary,
            gradient: gradient
                ? const LinearGradient(
                    colors: [PlumoraColors.primary, PlumoraColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Center(
            child: PlumoraLogoMark(
              size: size * 0.55,
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Text(
            'Plumora',
            style: TextStyle(
              color: PlumoraColors.textPrimary,
              fontFamily: 'Playfair Display',
              fontSize: textSize,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}

class FigmaBadge extends StatelessWidget {
  const FigmaBadge({
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    super.key,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? PlumoraColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? PlumoraColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class FigmaBookCover extends StatelessWidget {
  const FigmaBookCover({
    required this.colors,
    this.width = 112,
    this.height = 160,
    this.radius = 16,
    this.title,
    this.rank,
    this.badge,
    this.icon,
    super.key,
  });

  final List<Color> colors;
  final double width;
  final double height;
  final double radius;
  final String? title;
  final int? rank;
  final String? badge;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.58),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          if (rank != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: rank! <= 3
                      ? PlumoraColors.orange
                      : PlumoraColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          if (badge != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: PlumoraColors.success.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          if (icon != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.yellow.shade300, size: 14),
              ),
            ),
          if (title != null)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FigmaProgressBar extends StatelessWidget {
  const FigmaProgressBar({
    required this.value,
    this.height = 6,
    this.backgroundColor = PlumoraColors.muted,
    this.colors = const [PlumoraColors.orange, PlumoraColors.orangeLight],
    super.key,
  });

  final double value;
  final double height;
  final Color backgroundColor;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, _) {
            final clampedValue = value.clamp(0.0, 1.0);
            return Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: backgroundColor)),
                FractionallySizedBox(
                  widthFactor: clampedValue,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class FigmaSectionHeader extends StatelessWidget {
  const FigmaSectionHeader({
    required this.title,
    this.icon,
    this.trailing,
    this.iconColor = PlumoraColors.primary,
    super.key,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class FigmaStatCard extends StatelessWidget {
  const FigmaStatCard({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor = PlumoraColors.primary,
    this.gradient,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color valueColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final onGradient = gradient != null;
    return FigmaCard(
      gradient: gradient,
      borderColor: onGradient ? Colors.transparent : PlumoraColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: onGradient
                      ? Colors.white.withValues(alpha: 0.85)
                      : PlumoraColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onGradient
                        ? Colors.white.withValues(alpha: 0.85)
                        : PlumoraColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: onGradient ? Colors.white : valueColor,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class FigmaPillTab extends StatelessWidget {
  const FigmaPillTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [PlumoraColors.orange, PlumoraColors.orangeLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : PlumoraColors.cards,
          border: Border.all(
            color: selected ? Colors.transparent : PlumoraColors.border,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x22FF6B35),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : PlumoraColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : PlumoraColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FigmaBackButton extends StatelessWidget {
  const FigmaBackButton({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_back, size: 19),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: PlumoraColors.textSecondary,
        padding: EdgeInsets.zero,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class FigmaEmptyState extends StatelessWidget {
  const FigmaEmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.search,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: PlumoraColors.cards,
              shape: BoxShape.circle,
              border: Border.all(color: PlumoraColors.border),
            ),
            child: Icon(icon, color: PlumoraColors.textSecondary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
