import 'package:flutter/material.dart';

import 'plumora_colors.dart';

abstract final class PlumoraTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: PlumoraColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: PlumoraColors.primary,
          onPrimary: PlumoraColors.cards,
          secondary: PlumoraColors.mukemeAccent,
          onSecondary: PlumoraColors.textPrimary,
          surface: PlumoraColors.background,
          onSurface: PlumoraColors.textPrimary,
          onSurfaceVariant: PlumoraColors.textSecondary,
          primaryContainer: const Color(0xFFE9DDC8),
          onPrimaryContainer: PlumoraColors.textPrimary,
          secondaryContainer: const Color(0xFFDCE8D8),
          onSecondaryContainer: PlumoraColors.textPrimary,
          surfaceContainerHighest: PlumoraColors.cards,
          outlineVariant: PlumoraColors.border,
        );

    return _buildTheme(colorScheme);
  }

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: PlumoraColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: PlumoraColors.primary,
          secondary: PlumoraColors.mukemeAccent,
          surface: PlumoraColors.darkBackground,
          onSurface: PlumoraColors.background,
          onSurfaceVariant: const Color(0xFFD5CAB8),
          surfaceContainerHighest: PlumoraColors.darkSurface,
        );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? PlumoraColors.darkBackground
          : PlumoraColors.background,
      textTheme: Typography.material2021().black.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : PlumoraColors.cards,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        selectedLabelTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
