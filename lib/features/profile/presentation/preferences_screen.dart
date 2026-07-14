import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/figma_plumora.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);

    return FigmaScreen(
      maxWidth: 560,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.profile),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Profil'),
              ),
              Expanded(
                child: Text(
                  'Preferences',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 76),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Theme',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Choisis l'apparence de l'application.",
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _ThemeOption(
            icon: Icons.light_mode_outlined,
            label: 'Clair',
            description: 'Fond clair, texte sombre',
            selected: themeMode == ThemeMode.light,
            onTap: () => ref
                .read(themeModeControllerProvider.notifier)
                .setMode(ThemeMode.light),
          ),
          const SizedBox(height: 10),
          _ThemeOption(
            icon: Icons.dark_mode_outlined,
            label: 'Sombre',
            description: 'Fond sombre, moins de fatigue visuelle',
            selected: themeMode == ThemeMode.dark,
            onTap: () => ref
                .read(themeModeControllerProvider.notifier)
                .setMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FigmaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderColor: selected ? context.colors.primary : null,
      color: selected ? context.colors.primary.withValues(alpha: 0.06) : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.colors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? context.colors.primary : context.colors.border,
          ),
        ],
      ),
    );
  }
}
