import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          primaryContainer: const Color(0xFFEDE7F6),
          onPrimaryContainer: PlumoraColors.textPrimary,
          secondaryContainer: PlumoraColors.muted,
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
      textTheme: GoogleFonts.nunitoTextTheme(Typography.material2021().black)
          .apply(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFB9A7D7);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return PlumoraColors.primary.withValues(alpha: 0.9);
            }
            return PlumoraColors.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(PlumoraColors.cards),
          overlayColor: WidgetStatePropertyAll(
            PlumoraColors.cards.withValues(alpha: 0.08),
          ),
          elevation: const WidgetStatePropertyAll(1),
          shadowColor: const WidgetStatePropertyAll(Color(0x1A000000)),
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return PlumoraColors.primary;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return PlumoraColors.cards;
            }
            return PlumoraColors.primary;
          }),
          overlayColor: WidgetStatePropertyAll(
            PlumoraColors.primary.withValues(alpha: 0.08),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          side: const WidgetStatePropertyAll(
            BorderSide(color: PlumoraColors.border, width: 2),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(PlumoraColors.primary),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return PlumoraColors.muted;
            }
            return Colors.transparent;
          }),
          overlayColor: WidgetStatePropertyAll(
            PlumoraColors.primary.withValues(alpha: 0.08),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: PlumoraColors.cards,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: const TextStyle(
          color: PlumoraColors.textPrimary,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: PlumoraColors.textPrimary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(color: PlumoraColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PlumoraColors.border),
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
