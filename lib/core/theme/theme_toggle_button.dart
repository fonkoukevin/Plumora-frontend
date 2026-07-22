import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/plumora_colors.dart';
import 'theme_mode_controller.dart';

/// Light/dark theme toggle, shared by every screen chrome that wants it
/// (the four [PlumoraAppHeader](../widgets/app_shell_header.dart) screens
/// and [MainShell](../routing/main_shell.dart)'s desktop sidebar), so it
/// stays a single icon + behavior rather than being redefined per screen.
/// Flips [themeModeControllerProvider], surfacing a snackbar if persisting
/// the new mode fails. Shared by [ThemeToggleButton] and
/// [MainShell](../routing/main_shell.dart)'s desktop sidebar row, which
/// render this action with different chrome (a bare icon vs. a labeled list
/// item) but must not duplicate the error handling.
Future<void> toggleThemeMode(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(themeModeControllerProvider.notifier).toggle();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’enregistrer le thème.')),
      );
    }
  }
}

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Semantics(
      button: true,
      label: isDark ? 'Activer le thème clair' : 'Activer le thème sombre',
      child: Tooltip(
        message: isDark ? 'Thème clair' : 'Thème sombre',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            hoverColor: context.colors.muted.withValues(alpha: 0.6),
            onTap: () => toggleThemeMode(context, ref),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 20,
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
