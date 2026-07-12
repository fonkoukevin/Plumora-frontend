import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'plumora_colors.dart';

abstract final class PlumoraTheme {
  static ThemeData get light => _buildTheme(PlumoraColors.light);

  static ThemeData get dark => _buildTheme(PlumoraColors.dark);

  static ThemeData _buildTheme(PlumoraColors colors) {
    final isDark = colors == PlumoraColors.dark;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    final colorScheme =
        ColorScheme(
          brightness: brightness,
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          secondary: colors.secondary,
          onSecondary: colors.onSecondary,
          error: colors.destructive,
          onError: colors.onDestructive,
          surface: colors.background,
          onSurface: colors.textPrimary,
        ).copyWith(
          tertiary: colors.accent,
          onTertiary: colors.onAccent,
          primaryContainer: colors.primary.withValues(alpha: 0.12),
          onPrimaryContainer: colors.primary,
          secondaryContainer: colors.secondary,
          onSecondaryContainer: colors.onSecondary,
          tertiaryContainer: colors.accent.withValues(alpha: 0.12),
          onTertiaryContainer: colors.accent,
          errorContainer: colors.destructive.withValues(alpha: 0.12),
          onErrorContainer: colors.destructive,
          surfaceContainerLowest: colors.background,
          surfaceContainerLow: colors.cards,
          surfaceContainer: colors.cards,
          surfaceContainerHigh: colors.muted,
          surfaceContainerHighest: colors.muted,
          onSurfaceVariant: colors.textSecondary,
          outline: colors.border,
          outlineVariant: colors.border,
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: colors.textPrimary,
          onInverseSurface: colors.background,
          inversePrimary: colors.primaryLight,
        );

    final baseTypography = isDark
        ? Typography.material2021().white
        : Typography.material2021().black;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [colors],
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.border,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
      splashColor: colors.primary.withValues(alpha: 0.08),
      hoverColor: colors.muted.withValues(alpha: 0.72),
      focusColor: colors.ring.withValues(alpha: 0.16),
      highlightColor: colors.primary.withValues(alpha: 0.05),
      textTheme: GoogleFonts.nunitoTextTheme(baseTypography).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(color: colors.textPrimary),
      primaryIconTheme: IconThemeData(color: colors.onPrimary),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle:
            (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: colors.background,
                  systemNavigationBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.cards,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.primary.withValues(alpha: 0.35);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return colors.primary.withValues(alpha: 0.9);
            }
            return colors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? colors.onPrimary.withValues(alpha: 0.50)
                : colors.onPrimary;
          }),
          overlayColor: WidgetStatePropertyAll(
            colors.onPrimary.withValues(alpha: 0.08),
          ),
          elevation: const WidgetStatePropertyAll(1),
          shadowColor: const WidgetStatePropertyAll(Color(0x1A000000)),
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            if (states.contains(WidgetState.disabled)) {
              return colors.textSecondary.withValues(alpha: 0.50);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return colors.onPrimary;
            }
            return colors.primary;
          }),
          overlayColor: WidgetStatePropertyAll(
            colors.primary.withValues(alpha: 0.08),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          side: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.disabled)
                ? colors.border
                : colors.primary;
            return BorderSide(color: color, width: 2);
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: colors.inputBackground,
        constraints: const BoxConstraints(minHeight: 44),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        labelStyle: TextStyle(color: colors.textPrimary, fontSize: 14),
        floatingLabelStyle: TextStyle(color: colors.textPrimary, fontSize: 14),
        hintStyle: TextStyle(color: colors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.sidebar,
        indicatorColor: colors.primary.withValues(alpha: 0.10),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        selectedLabelTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cards,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        titleTextStyle: GoogleFonts.nunito(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: GoogleFonts.nunito(
          color: colors.textSecondary,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.cards,
        modalBackgroundColor: colors.cards,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: 0.60),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.cards,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: colors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.cards,
        contentTextStyle: TextStyle(color: colors.textPrimary),
        actionTextColor: colors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.cards,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: colors.textPrimary, fontSize: 12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.primary
              : colors.switchBackground;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.primary
              : Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(colors.onPrimary),
        side: BorderSide(color: colors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.primary
              : colors.border;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.muted,
        circularTrackColor: colors.muted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.muted,
        selectedColor: colors.primary,
        disabledColor: colors.muted.withValues(alpha: 0.55),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(color: colors.textSecondary),
        secondaryLabelStyle: TextStyle(color: colors.onPrimary),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.primary.withValues(alpha: 0.28),
        selectionHandleColor: colors.primary,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          colors.textSecondary.withValues(alpha: 0.35),
        ),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
        radius: const Radius.circular(999),
        thickness: const WidgetStatePropertyAll(4),
      ),
    );
  }
}
