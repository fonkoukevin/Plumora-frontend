import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_logo_mark.dart';
import 'controllers/auth_controller.dart';
import 'widgets/auth_screen_shell.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final Set<String> _selectedRoles = {};
  String? _localError;

  Future<void> _submit() async {
    if (_selectedRoles.isEmpty) {
      setState(() => _localError = 'Sélectionne au moins un rôle.');
      return;
    }

    setState(() => _localError = null);

    await ref
        .read(authControllerProvider.notifier)
        .updateRoles(_selectedRoles.toList(growable: false));

    if (!mounted || ref.read(authControllerProvider).hasError) {
      return;
    }

    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final remoteError = authState.hasError
        ? AppError.messageFor(authState.error!)
        : null;
    final hasSelection = _selectedRoles.isNotEmpty;
    final textTheme = Theme.of(context).textTheme;

    return AuthScreenShell(
      maxPanelWidth: 768,
      topPadding: 43,
      horizontalPadding: 14,
      bottomPadding: 26,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          return Column(
            children: [
              Text(
                'Comment veux-tu utiliser\nPlumora ?',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.black,
                  fontSize: isWide ? 36 : 29,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Sélectionne un ou plusieurs rôles pour personnaliser ton\nexpérience',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: PlumoraColors.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 26),
              if (_localError != null || remoteError != null) ...[
                AuthErrorBanner(message: _localError ?? remoteError!),
                const SizedBox(height: 16),
              ],
              if (isWide)
                Row(
                  children: [
                    for (final role in _roleChoices) ...[
                      Expanded(
                        child: _RoleCard(
                          role: role,
                          selected: _selectedRoles.contains(role.value),
                          onTap: isLoading ? null : () => _toggle(role.value),
                        ),
                      ),
                      if (role != _roleChoices.last) const SizedBox(width: 18),
                    ],
                  ],
                )
              else
                for (final role in _roleChoices) ...[
                  _RoleCard(
                    role: role,
                    selected: _selectedRoles.contains(role.value),
                    onTap: isLoading ? null : () => _toggle(role.value),
                  ),
                  const SizedBox(height: 20),
                ],
              SizedBox(height: isWide ? 28 : 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading || !hasSelection ? null : _submit,
                  child: LoadingButtonChild(
                    label: 'Continuer',
                    isLoading: isLoading,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'Tu pourras modifier tes rôles plus tard dans ton profil',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: PlumoraColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggle(String value) {
    setState(() {
      if (_selectedRoles.contains(value)) {
        _selectedRoles.remove(value);
      } else {
        _selectedRoles.add(value);
      }
    });
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final _RoleChoice role;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 155),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: selected
              ? role.iconBackground.withAlpha(100)
              : PlumoraColors.cards,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? PlumoraColors.primary : PlumoraColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 51,
              height: 51,
              decoration: BoxDecoration(
                color: role.iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: role.useLogoMark
                    ? PlumoraLogoMark(
                        size: 27,
                        color: role.iconColor,
                        strokeWidth: 2.0,
                      )
                    : Icon(role.icon, color: role.iconColor, size: 27),
              ),
            ),
            const SizedBox(height: 17),
            Text(
              role.label,
              style: textTheme.titleSmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              role.description,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: PlumoraColors.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<_RoleChoice> _roleChoices = [
  _RoleChoice(
    value: 'AUTHOR',
    label: 'Auteur',
    description: 'Écrire, organiser et publier mes livres',
    icon: Icons.draw_outlined,
    iconBackground: Color(0xFFF0E3FF),
    iconColor: PlumoraColors.primary,
    useLogoMark: true,
  ),
  _RoleChoice(
    value: 'READER',
    label: 'Lecteur',
    description: 'Découvrir, lire et sauvegarder des livres',
    icon: Icons.menu_book_outlined,
    iconBackground: Color(0xFFFFF3BE),
    iconColor: Color(0xFFE1C75D),
  ),
  _RoleChoice(
    value: 'BETA_READER',
    label: 'Bêta-testeur',
    description: 'Lire des manuscrits avant publication et donner mon avis',
    icon: Icons.science_outlined,
    iconBackground: Color(0xFFD9F8E1),
    iconColor: PlumoraColors.mukemeAccent,
  ),
];

class _RoleChoice {
  const _RoleChoice({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.useLogoMark = false,
  });

  final String value;
  final String label;
  final String description;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final bool useLogoMark;
}
