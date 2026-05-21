import 'package:flutter/material.dart';

class PlumoraPlaceholderScreen extends StatelessWidget {
  const PlumoraPlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      icon,
                      color: colorScheme.onPrimaryContainer,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(title, style: textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Wrap(spacing: 12, runSpacing: 12, children: actions),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
