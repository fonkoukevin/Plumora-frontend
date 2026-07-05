import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
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
      setState(() => _localError = 'Selectionne au moins un role.');
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

    return AuthScreenShell(
      maxPanelWidth: 768,
      topPadding: 58,
      horizontalPadding: 16,
      bottomPadding: 32,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final cardWidth = isWide
              ? (constraints.maxWidth - 48) / 3
              : constraints.maxWidth;

          return Column(
            children: [
              const Text(
                'Comment veux-tu utiliser Plumora ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlumoraColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Selectionne un ou plusieurs roles pour personnaliser ton experience',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlumoraColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              if (_localError != null || remoteError != null) ...[
                AuthErrorBanner(message: _localError ?? remoteError!),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  for (final role in _roleChoices)
                    SizedBox(
                      width: cardWidth,
                      child: _RoleCard(
                        role: role,
                        selected: _selectedRoles.contains(role.value),
                        onTap: isLoading ? null : () => _toggle(role.value),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),
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
              const SizedBox(height: 16),
              const Text(
                'Tu pourras modifier tes roles plus tard dans ton profil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PlumoraColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
    return FigmaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      borderColor: selected ? PlumoraColors.primary : PlumoraColors.border,
      color: selected
          ? PlumoraColors.primary.withValues(alpha: 0.06)
          : PlumoraColors.cards,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: role.iconBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(role.icon, color: role.iconColor, size: 32),
          ),
          const SizedBox(height: 18),
          Text(
            role.label,
            style: const TextStyle(
              color: PlumoraColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            role.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

const List<_RoleChoice> _roleChoices = [
  _RoleChoice(
    value: 'AUTHOR',
    label: 'Auteur',
    description: 'Ecrire, organiser et publier mes livres',
    icon: Icons.edit_outlined,
    iconBackground: Color(0xFFF3E8FF),
    iconColor: PlumoraColors.primary,
  ),
  _RoleChoice(
    value: 'READER',
    label: 'Lecteur',
    description: 'Decouvrir, lire et sauvegarder des livres',
    icon: Icons.menu_book_outlined,
    iconBackground: Color(0xFFFFF3C4),
    iconColor: PlumoraColors.secondary,
  ),
  _RoleChoice(
    value: 'BETA_READER',
    label: 'Beta-testeur',
    description: 'Lire des manuscrits avant publication et donner mon avis',
    icon: Icons.science_outlined,
    iconBackground: Color(0xFFDDF8E8),
    iconColor: PlumoraColors.accent,
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
  });

  final String value;
  final String label;
  final String description;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
}
