import 'package:flutter/material.dart';

import '../theme/plumora_colors.dart';

class PlumoraCard extends StatelessWidget {
  const PlumoraCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.borderColor = PlumoraColors.border,
    this.leftAccent,
    this.radius = 16,
    this.shadow = true,
    this.clip = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color borderColor;
  final Color? leftAccent;
  final double radius;
  final bool shadow;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      clipBehavior: clip || leftAccent != null ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: PlumoraColors.cards,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: leftAccent == null
          ? Padding(padding: padding, child: child)
          : Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(
                    color: leftAccent!,
                    child: const SizedBox(width: 4),
                  ),
                ),
                Padding(padding: padding, child: child),
              ],
            ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

class PlumoraIconTile extends StatelessWidget {
  const PlumoraIconTile({
    required this.child,
    this.backgroundColor = PlumoraColors.primary,
    this.size = 56,
    this.radius = 12,
    super.key,
  });

  final Widget child;
  final Color backgroundColor;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class PlumoraBadge extends StatelessWidget {
  const PlumoraBadge({
    required this.label,
    this.backgroundColor = const Color(0xFFEADFCF),
    this.foregroundColor = PlumoraColors.primary,
    this.icon,
    super.key,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PlumoraSegmentedTabs extends StatelessWidget {
  const PlumoraSegmentedTabs({
    required this.tabs,
    required this.selectedTab,
    required this.onSelected,
    super.key,
  });

  final List<String> tabs;
  final String selectedTab;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs) ...[
            _PlumoraTabButton(
              label: tab,
              selected: selectedTab == tab,
              onTap: () => onSelected(tab),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PlumoraTabButton extends StatelessWidget {
  const _PlumoraTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        elevation: selected ? 3 : 0,
        backgroundColor: selected
            ? PlumoraColors.primary
            : const Color(0xFFF3EBDD),
        foregroundColor: selected ? Colors.white : PlumoraColors.textSecondary,
        shadowColor: const Color(0x33000000),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        minimumSize: const Size(0, 44),
      ),
      child: Text(label),
    );
  }
}

class PlumoraBookCover extends StatelessWidget {
  const PlumoraBookCover({
    required this.colors,
    this.width = 80,
    this.height = 112,
    this.radius = 14,
    super.key,
  });

  final List<Color> colors;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 7),
          ),
        ],
      ),
    );
  }
}
