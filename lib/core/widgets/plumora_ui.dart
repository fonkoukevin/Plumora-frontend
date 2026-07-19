import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/plumora_colors.dart';

class PlumoraCard extends StatefulWidget {
  const PlumoraCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.borderColor,
    this.leftAccent,
    this.radius = 16,
    this.shadow = true,
    this.clip = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? leftAccent;
  final double radius;
  final bool shadow;
  final bool clip;

  @override
  State<PlumoraCard> createState() => _PlumoraCardState();
}

class _PlumoraCardState extends State<PlumoraCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasHover = widget.onTap != null && _hovered;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      clipBehavior: widget.clip || widget.leftAccent != null
          ? Clip.antiAlias
          : Clip.none,
      decoration: BoxDecoration(
        color: context.colors.cards,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: widget.borderColor ?? context.elevatedBorderColor,
        ),
        boxShadow: widget.shadow
            ? [
                BoxShadow(
                  color: isDark
                      ? Color(hasHover ? 0x29FFFFFF : 0x14FFFFFF)
                      : const Color(0x1A000000),
                  blurRadius: hasHover ? (isDark ? 14 : 8) : (isDark ? 6 : 3),
                  offset: Offset(0, hasHover ? 4 : 1),
                ),
              ]
            : null,
      ),
      child: widget.leftAccent == null
          ? Padding(padding: widget.padding, child: widget.child)
          : Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(
                    color: widget.leftAccent!,
                    child: const SizedBox(width: 4),
                  ),
                ),
                Padding(padding: widget.padding, child: widget.child),
              ],
            ),
    );

    if (widget.onTap == null) {
      return card;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          hoverColor: Colors.transparent,
          splashColor: context.colors.primary.withValues(alpha: 0.08),
          highlightColor: context.colors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(widget.radius),
          child: card,
        ),
      ),
    );
  }
}

class PlumoraIconTile extends StatelessWidget {
  const PlumoraIconTile({
    required this.child,
    this.backgroundColor,
    this.size = 56,
    this.radius = 12,
    super.key,
  });

  final Widget child;
  final Color? backgroundColor;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.primary,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x10000000),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.maxWidth,
    super.key,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedForegroundColor = foregroundColor ?? context.colors.primary;
    final resolvedBackgroundColor =
        backgroundColor ?? context.colors.primary.withValues(alpha: 0.12);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: resolvedBackgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: resolvedForegroundColor),
            const SizedBox(width: 4),
          ],
          if (maxWidth == null)
            Text(
              label,
              style: TextStyle(
                color: resolvedForegroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: resolvedForegroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );

    if (maxWidth == null) {
      return badge;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: badge,
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
          for (var index = 0; index < tabs.length; index++) ...[
            _PlumoraTabButton(
              label: tabs[index],
              selected: selectedTab == tabs[index],
              onTap: () => onSelected(tabs[index]),
            ),
            if (index != tabs.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PlumoraTabButton extends StatefulWidget {
  const _PlumoraTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PlumoraTabButton> createState() => _PlumoraTabButtonState();
}

class _PlumoraTabButtonState extends State<_PlumoraTabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = selected
        ? Colors.white
        : _hovered
        ? context.colors.textPrimary
        : context.colors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        splashColor: context.colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? context.colors.primary
                      : _hovered
                      ? context.colors.muted
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: isDark
                                ? context.colors.primary.withValues(alpha: 0.45)
                                : const Color(0x33000000),
                            blurRadius: isDark ? 16 : 10,
                            offset: Offset(0, isDark ? 6 : 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlumoraBookCover extends StatelessWidget {
  const PlumoraBookCover({
    required this.colors,
    this.imageUrl,
    this.imageBytes,
    this.width = 80,
    this.height = 112,
    this.radius = 12,
    super.key,
  });

  final List<Color> colors;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = resolvePlumoraImageUrl(imageUrl);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: isDark
            ? Border.all(color: context.colors.accent.withValues(alpha: 0.22))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x33FFFFFF) : const Color(0x22000000),
            blurRadius: isDark ? 16 : 12,
            offset: Offset(0, isDark ? 8 : 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          if (imageBytes != null)
            Image.memory(
              imageBytes!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            )
          else if (normalizedImageUrl != null)
            Image.network(
              normalizedImageUrl,
              fit: BoxFit.cover,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

String? resolvePlumoraImageUrl(String? value) {
  final url = value?.trim();
  if (url == null || url.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(url);
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null) {
    return null;
  }

  if (uri.hasScheme) {
    return scheme == 'http' || scheme == 'https' ? url : null;
  }

  final apiUri = Uri.tryParse(AppConfig.apiBaseUrl);
  if (apiUri == null || !apiUri.hasScheme) {
    return null;
  }

  final backendOrigin = apiUri.replace(path: '', query: null, fragment: null);
  final apiBasePath = apiUri.path.endsWith('/')
      ? apiUri.path
      : '${apiUri.path}/';
  final normalizedPath = url.startsWith('/') ? url : '$apiBasePath$url';

  return backendOrigin.resolve(normalizedPath).toString();
}
