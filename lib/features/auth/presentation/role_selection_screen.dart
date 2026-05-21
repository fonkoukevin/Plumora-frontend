import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
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
    final textTheme = Theme.of(context).textTheme;

    return AuthScreenShell(
      child: Column(
        children: [
          Text(
            'Comment veux-tu utiliser Plumora ?',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sélectionne un ou plusieurs rôles pour personnaliser ton expérience',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: PlumoraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 26),
          if (_localError != null || remoteError != null) ...[
            AuthErrorBanner(message: _localError ?? remoteError!),
            const SizedBox(height: 16),
          ],
          for (final role in _roleChoices) ...[
            _RoleCard(
              role: role,
              selected: _selectedRoles.contains(role.value),
              onTap: isLoading
                  ? null
                  : () {
                      setState(() {
                        if (_selectedRoles.contains(role.value)) {
                          _selectedRoles.remove(role.value);
                        } else {
                          _selectedRoles.add(role.value);
                        }
                      });
                    },
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : _submit,
              child: LoadingButtonChild(
                label: 'Continuer',
                isLoading: isLoading,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tu pourras modifier tes rôles plus tard dans ton profil',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: PlumoraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
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
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: selected ? role.color.withAlpha(28) : PlumoraColors.cards,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? PlumoraColors.primary : PlumoraColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: role.color.withAlpha(46),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(role.icon, color: role.color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              role.label,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              role.description,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: PlumoraColors.textSecondary,
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
    color: PlumoraColors.primary,
  ),
  _RoleChoice(
    value: 'READER',
    label: 'Lecteur',
    description: 'Découvrir, lire et sauvegarder des livres',
    icon: Icons.menu_book_outlined,
    color: Color(0xFFE5C95D),
  ),
  _RoleChoice(
    value: 'BETA_READER',
    label: 'Bêta-testeur',
    description: 'Lire des manuscrits avant publication et donner mon avis',
    icon: Icons.science_outlined,
    color: PlumoraColors.mukemeAccent,
  ),
];

class _RoleChoice {
  const _RoleChoice({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
}
