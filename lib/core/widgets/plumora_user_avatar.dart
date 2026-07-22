import 'package:flutter/material.dart';

import '../theme/plumora_colors.dart';

/// Consistent user avatar used by the application chrome and account areas.
/// It deliberately keeps the initials readable even when no profile photo is
/// available, matching Plumora's compact navigation language.
class PlumoraUserAvatar extends StatelessWidget {
  const PlumoraUserAvatar({
    this.name,
    this.initials,
    this.size = 40,
    this.semanticLabel = 'Profil',
    super.key,
  });

  final String? name;
  final String? initials;
  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedInitials = (initials?.trim().isNotEmpty ?? false)
        ? initials!.trim().toUpperCase()
        : plumoraUserInitials(name);
    final fontSize = (size * 0.31).clamp(10.0, 28.0).toDouble();

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colors.primary, context.colors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.24),
            width: size >= 64 ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: size * 0.22,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: Text(
          resolvedInitials,
          maxLines: 1,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: size >= 64 ? 0.2 : 0,
          ),
        ),
      ),
    );
  }
}

String plumoraUserInitials(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '?';
  }

  final parts = trimmed
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
