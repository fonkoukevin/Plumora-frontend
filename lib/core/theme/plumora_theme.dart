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
          primaryContainer: PlumoraColors.secondary,
          onPrimaryContainer: PlumoraColors.textPrimary,
          secondaryContainer: const Color(0xFFDCE8D8),
          onSecondaryContainer: PlumoraColors.textPrimary,
          surfaceContainerHighest: PlumoraColors.cards,
          outlineVariant: PlumoraColors.border,
          error: PlumoraColors.destructive,
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
        fontFamily: 'Roboto',
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
          backgroundColor: PlumoraColors.primary,
          foregroundColor: PlumoraColors.cards,
          disabledBackgroundColor: const Color(0xFFD7C49E),
          disabledForegroundColor: PlumoraColors.cards,
          elevation: 2,
          shadowColor: const Color(0x33000000),
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PlumoraColors.primary,
          minimumSize: const Size(0, 42),
          side: const BorderSide(color: PlumoraColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PlumoraColors.primary,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: PlumoraColors.cards,
        constraints: const BoxConstraints(minHeight: 38),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        labelStyle: const TextStyle(
          color: PlumoraColors.textSecondary,
          fontSize: 13,
        ),
        floatingLabelStyle: const TextStyle(
          color: PlumoraColors.textSecondary,
          fontSize: 13,
        ),
        hintStyle: const TextStyle(color: Color(0xFF9E9A96), fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4D7C7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: PlumoraColors.primary,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
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
