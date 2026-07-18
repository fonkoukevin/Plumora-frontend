import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/plumora_colors.dart';
import 'plumora_logo_mark.dart';

class FigmaScreen extends StatelessWidget {
  const FigmaScreen({
    required this.child,
    this.maxWidth = 1280,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 88),
    this.scroll = true,
    this.center = true,
    this.physics,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool scroll;
  final bool center;
  final ScrollPhysics? physics;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.55],
          colors: [
            Color.lerp(
              context.colors.background,
              isDark ? context.colors.cards : Colors.white,
              isDark ? 0.4 : 0.6,
            )!,
            context.colors.background,
          ],
        ),
      ),
      child: scroll
          ? SingleChildScrollView(physics: physics, child: content)
          : content,
    );
  }
}

class FigmaCard extends StatelessWidget {
  const FigmaCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.color,
    this.borderColor,
    this.gradient,
    this.radius = 16,
    this.shadow = true,
    this.clip = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final double radius;
  final bool shadow;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = color ?? context.colors.cards;
    final resolvedBorderColor = borderColor ?? context.elevatedBorderColor;
    final radiusValue = BorderRadius.circular(radius);
    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: gradient == null ? resolvedColor : null,
        gradient: gradient,
        borderRadius: radiusValue,
        border: Border.all(color: resolvedBorderColor),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: isDark
                      ? const Color(0x1FFFFFFF)
                      : const Color(0x1A000000),
                  blurRadius: isDark ? 10 : 3,
                  offset: Offset(0, isDark ? 3 : 1),
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
        hoverColor: context.colors.muted.withValues(alpha: 0.5),
        child: decorated,
      ),
    );
  }
}

/// Renders [itemCount] tiles as a horizontal scrolling rail below
/// [wideBreakpoint] (the mobile/tablet behaviour), and as a wrapping
/// multi-column grid above it -- so wide desktop windows lay tiles out
/// using the extra width instead of forcing a mobile-style horizontal
/// scroll with empty space left and right.
class FigmaAdaptiveRail extends StatelessWidget {
  const FigmaAdaptiveRail({
    required this.itemCount,
    required this.itemBuilder,
    required this.railHeight,
    this.spacing = 12,
    this.runSpacing = 20,
    this.wideBreakpoint = 560,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double railHeight;
  final double spacing;
  final double runSpacing;
  final double wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < wideBreakpoint) {
          return SizedBox(
            height: railHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              separatorBuilder: (_, _) => SizedBox(width: spacing),
              itemBuilder: itemBuilder,
            ),
          );
        }

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (var i = 0; i < itemCount; i++)
              // Tiles built for the horizontal rail get a bounded cross-axis
              // extent for free from the ListView's viewport; some (e.g.
              // recommendation cards) rely on that bound for an internal
              // Expanded/Spacer. Wrap gives unbounded height, so pin it back
              // to railHeight to keep those tiles laying out identically.
              SizedBox(height: railHeight, child: itemBuilder(context, i)),
          ],
        );
      },
    );
  }
}

/// Lays [children] out as a single column on narrow (mobile) widths, and as
/// a wrapping grid of as many [minTileWidth]-wide columns (up to
/// [maxColumns]) as fit above that -- for card lists that read fine as a
/// full-width column on a phone but shouldn't stay a single stretched
/// column on a wide desktop window.
class FigmaResponsiveGrid extends StatelessWidget {
  const FigmaResponsiveGrid({
    required this.children,
    this.spacing = 14,
    this.runSpacing = 14,
    this.minTileWidth = 320,
    this.maxColumns = 3,
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double minTileWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            ((constraints.maxWidth + spacing) / (minTileWidth + spacing))
                .floor()
                .clamp(1, maxColumns);

        if (columns == 1) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) SizedBox(height: runSpacing),
              ],
            ],
          );
        }

        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class FigmaGradientIcon extends StatelessWidget {
  const FigmaGradientIcon({
    required this.icon,
    this.size = 48,
    this.iconSize = 24,
    this.colors,
    this.radius = 16,
    super.key,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final List<Color>? colors;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColors =
        colors ?? [context.colors.primary, context.colors.primaryLight];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: resolvedColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? resolvedColors.first.withValues(alpha: 0.45)
                : const Color(0x22000000),
            blurRadius: isDark ? 18 : 12,
            offset: Offset(0, isDark ? 8 : 6),
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
            color: gradient ? null : context.colors.primary,
            gradient: gradient
                ? LinearGradient(
                    colors: [
                      context.colors.primary,
                      context.colors.primaryLight,
                    ],
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
            style: GoogleFonts.playfairDisplay(
              color: context.colors.textPrimary,
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
    final fg = foregroundColor ?? context.colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            backgroundColor ?? context.colors.primary.withValues(alpha: 0.12),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        border: isDark
            ? Border.all(color: context.colors.accent.withValues(alpha: 0.22))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x33FFFFFF) : const Color(0x26000000),
            blurRadius: isDark ? 16 : 14,
            offset: Offset(0, isDark ? 8 : 7),
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
                      ? context.colors.orange
                      : context.colors.plumora,
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
                  color: context.colors.success.withValues(alpha: 0.9),
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
    this.backgroundColor,
    this.colors,
    super.key,
  });

  final double value;
  final double height;
  final Color? backgroundColor;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final resolvedBackgroundColor = backgroundColor ?? context.colors.muted;
    final resolvedColors =
        colors ?? [context.colors.orange, context.colors.orangeLight];
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, _) {
            final clampedValue = value.clamp(0.0, 1.0);
            return Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: resolvedBackgroundColor),
                ),
                FractionallySizedBox(
                  widthFactor: clampedValue,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: resolvedColors,
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
    this.iconWidget,
    this.trailing,
    this.iconColor,
    this.showAccent = true,
    super.key,
  });

  final String title;
  final IconData? icon;
  final Widget? iconWidget;
  final Widget? trailing;
  final Color? iconColor;
  final bool showAccent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showAccent) ...[
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: context.colors.accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
        ],
        if (iconWidget != null || icon != null) ...[
          iconWidget ??
              Icon(icon, size: 18, color: iconColor ?? context.colors.primary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: context.colors.textPrimary,
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
    this.valueColor,
    this.gradient,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final onGradient = gradient != null;
    final resolvedValueColor = valueColor ?? context.colors.primary;
    return FigmaCard(
      gradient: gradient,
      borderColor: onGradient ? Colors.transparent : context.colors.border,
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
                      : context.colors.textSecondary,
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
                        : context.colors.textSecondary,
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
              color: onGradient ? Colors.white : resolvedValueColor,
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
    this.badgeCount,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pill = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF292631), Color(0xFF5B5563)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : context.colors.cards,
          border: Border.all(
            color: selected ? Colors.transparent : context.elevatedBorderColor,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(
                      0xFF292631,
                    ).withValues(alpha: isDark ? 0.32 : 0.14),
                    blurRadius: isDark ? 16 : 10,
                    offset: Offset(0, isDark ? 6 : 4),
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
                color: selected ? Colors.white : context.colors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : context.colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );

    if (badgeCount == null || badgeCount! <= 0) {
      return pill;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        pill,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.destructive,
              borderRadius: const BorderRadius.all(Radius.circular(999)),
            ),
            child: Text(
              badgeCount! > 9 ? '9+' : '$badgeCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ],
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
        foregroundColor: context.colors.textSecondary,
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
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

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
              color: context.colors.cards,
              shape: BoxShape.circle,
              border: Border.all(color: context.elevatedBorderColor),
            ),
            child: Icon(icon, color: context.colors.textSecondary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}
