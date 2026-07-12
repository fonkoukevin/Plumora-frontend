import 'package:flutter/material.dart';

/// Semantic color palette for the app, exposed as a [ThemeExtension] so it
/// resolves to the light or dark variant depending on [ThemeData.brightness].
///
/// Access it through `context.colors.xxx` (see the `PlumoraColorsContext`
/// extension below) rather than a static constant, so every widget that
/// reads a color reacts to the current theme instead of being frozen at
/// compile time.
class PlumoraColors extends ThemeExtension<PlumoraColors> {
  const PlumoraColors({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.background,
    required this.cards,
    required this.textPrimary,
    required this.textSecondary,
    required this.plumoAccent,
    required this.secondary,
    required this.muted,
    required this.border,
    required this.accent,
    required this.orange,
    required this.orangeLight,
    required this.destructive,
    required this.warning,
    required this.success,
    required this.info,
    required this.appOutside,
    required this.darkBackground,
    required this.darkSurface,
    required this.onPrimary,
    required this.onSecondary,
    required this.onAccent,
    required this.onDestructive,
    required this.inputBackground,
    required this.switchBackground,
    required this.ring,
    required this.sidebar,
    required this.sidebarForeground,
    required this.brandPrimary,
    required this.brandPrimaryLight,
    required this.brandNavy,
    required this.brandNavyLight,
    required this.brandGold,
    required this.brandGoldLight,
  });

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color background;
  final Color cards;
  final Color textPrimary;
  final Color textSecondary;
  final Color plumoAccent;
  final Color secondary;
  final Color muted;
  final Color border;
  final Color accent;
  final Color orange;
  final Color orangeLight;
  final Color destructive;
  final Color warning;
  final Color success;
  final Color info;
  final Color appOutside;
  final Color darkBackground;
  final Color darkSurface;
  final Color onPrimary;
  final Color onSecondary;
  final Color onAccent;
  final Color onDestructive;
  final Color inputBackground;
  final Color switchBackground;
  final Color ring;
  final Color sidebar;
  final Color sidebarForeground;
  final Color brandPrimary;
  final Color brandPrimaryLight;
  final Color brandNavy;
  final Color brandNavyLight;
  final Color brandGold;
  final Color brandGoldLight;

  static const PlumoraColors light = PlumoraColors(
    primary: Color(0xFF4B2E83),
    primaryDark: Color(0xFF3A2268),
    primaryLight: Color(0xFF6B44B8),
    background: Color(0xFFF8F7F3),
    cards: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1F1F1F),
    textSecondary: Color(0xFF6B6B6B),
    plumoAccent: Color(0xFF6B44B8),
    secondary: Color(0xFF16213E),
    muted: Color(0xFFF0EDE6),
    border: Color(0xFFE5E2DA),
    accent: Color(0xFFC9A227),
    orange: Color(0xFFFF6B35),
    orangeLight: Color(0xFFFF8C5A),
    destructive: Color(0xFFD94F4F),
    warning: Color(0xFFC9A227),
    success: Color(0xFF2E8B57),
    info: Color(0xFF16213E),
    appOutside: Color(0xFFF3F3F3),
    darkBackground: Color(0xFF111111),
    darkSurface: Color(0xFF1F1F1F),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onAccent: Color(0xFFFFFFFF),
    onDestructive: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFFFFFFF),
    switchBackground: Color(0xFFE5E2DA),
    ring: Color(0xFF4B2E83),
    sidebar: Color(0xFFF8F7F3),
    sidebarForeground: Color(0xFF1F1F1F),
    brandPrimary: Color(0xFF4B2E83),
    brandPrimaryLight: Color(0xFF6B44B8),
    brandNavy: Color(0xFF16213E),
    brandNavyLight: Color(0xFF1E3A5F),
    brandGold: Color(0xFFC9A227),
    brandGoldLight: Color(0xFFE0B830),
  );

  /// Matches the "figma_sombre" mockup's `theme.css` `:root` tokens exactly.
  static const PlumoraColors dark = PlumoraColors(
    primary: Color(0xFF7C5CFF),
    primaryDark: Color(0xFF6647D9),
    primaryLight: Color(0xFF9B80FF),
    background: Color(0xFF0E1117),
    cards: Color(0xFF1F2633),
    textPrimary: Color(0xFFF4F1EA),
    textSecondary: Color(0xFFA8A8B3),
    plumoAccent: Color(0xFF7C5CFF),
    secondary: Color(0xFF161B22),
    muted: Color(0xFF1A2030),
    border: Color(0xFF2A3142),
    accent: Color(0xFFD6B25E),
    orange: Color(0xFFFF6B35),
    orangeLight: Color(0xFFFF8C5A),
    destructive: Color(0xFFE57373),
    warning: Color(0xFFD6B25E),
    success: Color(0xFF3FBF7F),
    info: Color(0xFF7C5CFF),
    appOutside: Color(0xFF05070B),
    darkBackground: Color(0xFF111111),
    darkSurface: Color(0xFF1F2633),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFF4F1EA),
    onAccent: Color(0xFF0E1117),
    onDestructive: Color(0xFFFFFFFF),
    inputBackground: Color(0xFF1F2633),
    switchBackground: Color(0xFF2A3142),
    ring: Color(0xFF7C5CFF),
    sidebar: Color(0xFF161B22),
    sidebarForeground: Color(0xFFF4F1EA),
    brandPrimary: Color(0xFF4B2E83),
    brandPrimaryLight: Color(0xFF6B44B8),
    brandNavy: Color(0xFF16213E),
    brandNavyLight: Color(0xFF1E3A5F),
    brandGold: Color(0xFFC9A227),
    brandGoldLight: Color(0xFFE0B830),
  );

  @override
  PlumoraColors copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? background,
    Color? cards,
    Color? textPrimary,
    Color? textSecondary,
    Color? plumoAccent,
    Color? secondary,
    Color? muted,
    Color? border,
    Color? accent,
    Color? orange,
    Color? orangeLight,
    Color? destructive,
    Color? warning,
    Color? success,
    Color? info,
    Color? appOutside,
    Color? darkBackground,
    Color? darkSurface,
    Color? onPrimary,
    Color? onSecondary,
    Color? onAccent,
    Color? onDestructive,
    Color? inputBackground,
    Color? switchBackground,
    Color? ring,
    Color? sidebar,
    Color? sidebarForeground,
    Color? brandPrimary,
    Color? brandPrimaryLight,
    Color? brandNavy,
    Color? brandNavyLight,
    Color? brandGold,
    Color? brandGoldLight,
  }) {
    return PlumoraColors(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      background: background ?? this.background,
      cards: cards ?? this.cards,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      plumoAccent: plumoAccent ?? this.plumoAccent,
      secondary: secondary ?? this.secondary,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      orange: orange ?? this.orange,
      orangeLight: orangeLight ?? this.orangeLight,
      destructive: destructive ?? this.destructive,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      info: info ?? this.info,
      appOutside: appOutside ?? this.appOutside,
      darkBackground: darkBackground ?? this.darkBackground,
      darkSurface: darkSurface ?? this.darkSurface,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onAccent: onAccent ?? this.onAccent,
      onDestructive: onDestructive ?? this.onDestructive,
      inputBackground: inputBackground ?? this.inputBackground,
      switchBackground: switchBackground ?? this.switchBackground,
      ring: ring ?? this.ring,
      sidebar: sidebar ?? this.sidebar,
      sidebarForeground: sidebarForeground ?? this.sidebarForeground,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandPrimaryLight: brandPrimaryLight ?? this.brandPrimaryLight,
      brandNavy: brandNavy ?? this.brandNavy,
      brandNavyLight: brandNavyLight ?? this.brandNavyLight,
      brandGold: brandGold ?? this.brandGold,
      brandGoldLight: brandGoldLight ?? this.brandGoldLight,
    );
  }

  @override
  PlumoraColors lerp(ThemeExtension<PlumoraColors>? other, double t) {
    if (other is! PlumoraColors) {
      return this;
    }

    return PlumoraColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      background: Color.lerp(background, other.background, t)!,
      cards: Color.lerp(cards, other.cards, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      plumoAccent: Color.lerp(plumoAccent, other.plumoAccent, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      orangeLight: Color.lerp(orangeLight, other.orangeLight, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      appOutside: Color.lerp(appOutside, other.appOutside, t)!,
      darkBackground: Color.lerp(darkBackground, other.darkBackground, t)!,
      darkSurface: Color.lerp(darkSurface, other.darkSurface, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      onDestructive: Color.lerp(onDestructive, other.onDestructive, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      switchBackground: Color.lerp(
        switchBackground,
        other.switchBackground,
        t,
      )!,
      ring: Color.lerp(ring, other.ring, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      sidebarForeground: Color.lerp(
        sidebarForeground,
        other.sidebarForeground,
        t,
      )!,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandPrimaryLight: Color.lerp(
        brandPrimaryLight,
        other.brandPrimaryLight,
        t,
      )!,
      brandNavy: Color.lerp(brandNavy, other.brandNavy, t)!,
      brandNavyLight: Color.lerp(brandNavyLight, other.brandNavyLight, t)!,
      brandGold: Color.lerp(brandGold, other.brandGold, t)!,
      brandGoldLight: Color.lerp(brandGoldLight, other.brandGoldLight, t)!,
    );
  }
}

extension PlumoraColorsContext on BuildContext {
  PlumoraColors get colors {
    final theme = Theme.of(this);
    final colors = theme.extension<PlumoraColors>();
    assert(
      colors != null,
      'PlumoraColors doit être ajouté aux extensions du ThemeData.',
    );
    return colors ??
        (theme.brightness == Brightness.dark
            ? PlumoraColors.dark
            : PlumoraColors.light);
  }
}
