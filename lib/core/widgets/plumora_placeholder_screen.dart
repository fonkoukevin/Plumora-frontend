import 'package:flutter/material.dart';

import '../theme/plumora_colors.dart';
import 'plumora_ui.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final horizontal = isWide ? 32.0 : 16.0;
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 82.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            28,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: PlumoraCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlumoraIconTile(
                      backgroundColor: context.colors.secondary,
                      child: Icon(
                        icon,
                        color: context.colors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                        height: 1.45,
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
      },
    );
  }
}
