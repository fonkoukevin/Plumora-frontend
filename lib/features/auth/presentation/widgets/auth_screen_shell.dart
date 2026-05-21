import 'package:flutter/material.dart';

import '../../../../core/theme/plumora_colors.dart';

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class PlumoraLogo extends StatelessWidget {
  const PlumoraLogo({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.draw_outlined,
          color: PlumoraColors.primary,
          size: compact ? 28 : 40,
        ),
        const SizedBox(width: 8),
        Text(
          'Plumora',
          style: (compact ? textTheme.headlineSmall : textTheme.displaySmall)
              ?.copyWith(
                color: PlumoraColors.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: colorScheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LoadingButtonChild extends StatelessWidget {
  const LoadingButtonChild({
    required this.label,
    required this.isLoading,
    super.key,
  });

  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return Text(label);
    }

    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
