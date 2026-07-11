import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'plumora_colors.dart';

abstract final class PlumoraTheme {
  static ThemeData get light => _buildTheme(PlumoraColors.light);

  static ThemeData get dark => _buildTheme(PlumoraColors.dark);

  static ThemeData _buildTheme(PlumoraColors colors) {
    final isDark = colors == PlumoraColors.dark;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: isDark ? colors.textPrimary : colors.cards,
          secondary: colors.mukemeAccent,
          onSecondary: colors.textPrimary,
          surface: colors.background,
          onSurface: colors.textPrimary,
          onSurfaceVariant: colors.textSecondary,
          primaryContainer: isDark
              ? colors.muted
              : const Color(0xFFEDE7F6),
          onPrimaryContainer: colors.textPrimary,
          secondaryContainer: colors.muted,
          onSecondaryContainer: colors.textPrimary,
          surfaceContainerHighest: colors.cards,
          outlineVariant: colors.border,
          error: colors.destructive,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [colors],
      scaffoldBackgroundColor: colors.background,
      textTheme: GoogleFonts.nunitoTextTheme(
        isDark ? Typography.material2021().white : Typography.material2021().black,
      ).apply(bodyColor: colorScheme.onSurface, displayColor: colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.cards,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return isDark
                  ? colors.primary.withValues(alpha: 0.35)
                  : const Color(0xFFB9A7D7);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return colors.primary.withValues(alpha: 0.9);
            }
            return colors.primary;
          }),
          foregroundColor: WidgetStatePropertyAll(
            isDark ? colors.textPrimary : colors.cards,
          ),
          overlayColor: WidgetStatePropertyAll(
            (isDark ? colors.textPrimary : colors.cards).withValues(alpha: 0.08),
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
              return colors.primary;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return isDark ? colors.textPrimary : colors.cards;
            }
            return colors.primary;
          }),
          overlayColor: WidgetStatePropertyAll(
            colors.primary.withValues(alpha: 0.08),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          side: WidgetStatePropertyAll(BorderSide(color: colors.border, width: 2)),
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
          foregroundColor: WidgetStatePropertyAll(colors.primary),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return colors.muted;
            }
            return Colors.transparent;
          }),
          overlayColor: WidgetStatePropertyAll(
            colors.primary.withValues(alpha: 0.08),
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
        fillColor: colors.cards,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: TextStyle(color: colors.textPrimary, fontSize: 14),
        floatingLabelStyle: TextStyle(color: colors.textPrimary, fontSize: 14),
        hintStyle: TextStyle(color: colors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.2),
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
        backgroundColor: colors.cards,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.cards,
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
