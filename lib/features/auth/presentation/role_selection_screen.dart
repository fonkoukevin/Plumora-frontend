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
  const RoleSelectionScreen({this.isOnboarding = true, super.key});

  /// True right after signup, when the user must pick at least one role
  /// before entering the app. False when reopened from the profile to edit
  /// roles later, which pre-fills the current selection and returns to the
  /// previous screen on save instead of routing to home.
  final bool isOnboarding;

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final Set<String> _selectedRoles = {};
  String? _localError;
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefilled) {
      _prefilled = true;
      final currentRoles =
          ref.read(authControllerProvider).valueOrNull?.roles ?? const [];
      _selectedRoles.addAll(
        currentRoles.map((role) => role.name).where((name) => name.isNotEmpty),
      );
    }
  }

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

    if (widget.isOnboarding) {
      context.go(AppRoutes.home);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profile);
    }
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
              if (!widget.isOnboarding) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: FigmaBackButton(
                    label: 'Profil',
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.profile),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Text(
                widget.isOnboarding
                    ? 'Comment veux-tu utiliser Plumora ?'
                    : 'Modifier mes roles',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.isOnboarding
                    ? 'Selectionne un ou plusieurs roles pour personnaliser ton experience'
                    : 'Ajoute ou retire des roles a tout moment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textSecondary,
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
                  for (final role in _roleChoices(context))
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
                    label: widget.isOnboarding ? 'Continuer' : 'Enregistrer',
                    isLoading: isLoading,
                  ),
                ),
              ),
              if (widget.isOnboarding) ...[
                const SizedBox(height: 16),
                Text(
                  'Tu pourras modifier tes roles plus tard dans ton profil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
      borderColor: selected ? context.colors.primary : context.colors.border,
      color: selected
          ? context.colors.primary.withValues(alpha: 0.06)
          : context.colors.cards,
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
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            role.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textSecondary,
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

List<_RoleChoice> _roleChoices(BuildContext context) => [
  _RoleChoice(
    value: 'AUTHOR',
    label: 'Auteur',
    description: 'Ecrire, organiser et publier mes livres',
    icon: Icons.edit_outlined,
    iconBackground: context.colors.primary.withValues(alpha: 0.14),
    iconColor: context.colors.primary,
  ),
  _RoleChoice(
    value: 'READER',
    label: 'Lecteur',
    description: 'Decouvrir, lire et sauvegarder des livres',
    icon: Icons.menu_book_outlined,
    iconBackground: context.colors.accent.withValues(alpha: 0.14),
    iconColor: context.colors.accent,
  ),
  _RoleChoice(
    value: 'BETA_READER',
    label: 'Beta-testeur',
    description: 'Lire des manuscrits avant publication et donner mon avis',
    icon: Icons.science_outlined,
    iconBackground: context.colors.success.withValues(alpha: 0.14),
    iconColor: context.colors.success,
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
