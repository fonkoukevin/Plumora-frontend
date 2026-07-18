import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/notification/data/repositories/notification_repository.dart';
import '../routing/app_router.dart';
import '../theme/plumora_colors.dart';
import 'plumora_logo_mark.dart';

/// Shared sticky title row for every screen wrapped by [MainShell], matching
/// the Figma `AppHeader.tsx` component: the Plumora logo lockup on mobile
/// (where the sidebar with the logo is hidden), a theme-aware page title with
/// an optional subtitle on desktop, and a bell + avatar on both. Each screen
/// still owns its own pinned `SliverPersistentHeaderDelegate` for the
/// blur/shadow-on-scroll chrome and any extra content (search, tabs) below
/// this row.
class PlumoraAppHeader extends ConsumerWidget {
  const PlumoraAppHeader({
    required this.title,
    required this.gradient,
    this.subtitle,
    this.emoji,
    this.action,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? emoji;
  final List<Color> gradient;

  /// Desktop-only extra action (e.g. "Nouvelle histoire"), matching the
  /// Figma `AppHeader` `action` prop.
  final Widget? action;

  /// Extra control shown on every breakpoint, right before the bell (e.g.
  /// the light/dark theme toggle) -- not part of the Figma spec, kept from
  /// the pre-existing Home header rather than dropped outright.
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final session = ref.watch(authControllerProvider).valueOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: isDesktop
                  ? _DesktopTitle(
                      title: title,
                      subtitle: subtitle,
                      emoji: emoji,
                      gradient: gradient,
                    )
                  : _MobileBrand(gradient: gradient),
            ),
            const SizedBox(width: 12),
            if (action != null && isDesktop) ...[
              action!,
              const SizedBox(width: 8),
            ],
            if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
            _HeaderIconButton(
              onTap: () => context.go(AppRoutes.notifications),
              tooltip: 'Notifications',
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 20,
                    color: context.colors.textSecondary,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _HeaderIconButton(
              onTap: () => context.go(AppRoutes.profile),
              tooltip: 'Profil',
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _initialsFor(session?.user?.displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MobileBrand extends StatelessWidget {
  const _MobileBrand({required this.gradient});

  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const PlumoraLogoMark(
            size: 18,
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'Plumora',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              color: context.colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopTitle extends StatelessWidget {
  const _DesktopTitle({
    required this.title,
    required this.gradient,
    this.subtitle,
    this.emoji,
  });

  final String title;
  final String? subtitle;
  final String? emoji;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.playfairDisplay(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 21)),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: isDark
                  ? ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: titleText,
                    )
                  : titleText,
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.onTap,
    required this.child,
    required this.tooltip,
  });

  final VoidCallback onTap;
  final Widget child;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          hoverColor: context.colors.muted.withValues(alpha: 0.6),
          child: SizedBox(width: 36, height: 36, child: Center(child: child)),
        ),
      ),
    );
  }
}

String _initialsFor(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '?';
  }
  final parts = trimmed
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
