import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import 'controllers/password_reset_controller.dart';
import 'widgets/auth_screen_shell.dart';

/// Reached from the link sent by [ForgotPasswordScreen]'s email — [token]
/// is prefilled from the `?token=` query param but stays editable so a user
/// who copy-pastes the code by hand (e.g. it didn't deep-link cleanly) can
/// still complete the flow.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({this.token, super.key});

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _tokenController = TextEditingController(text: widget.token);
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(resetPasswordControllerProvider.notifier)
        .submit(
          token: _tokenController.text,
          newPassword: _passwordController.text,
        );

    if (!mounted) {
      return;
    }
    if (!ref.read(resetPasswordControllerProvider).hasError) {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);
    final isLoading = state.isLoading;
    final error = state.hasError ? AppError.messageFor(state.error!) : null;

    return AuthScreenShell(
      topPadding: 58,
      horizontalPadding: 16,
      bottomPadding: 32,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FigmaBackButton(
              label: 'Retour',
              onTap: () => returnToPreviousOr(context, AppRoutes.login),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Nouveau mot de passe',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choisis un nouveau mot de passe pour ton compte.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          FigmaCard(
            padding: const EdgeInsets.all(28),
            child: _done
                ? _DoneContent(onLogin: () => context.go(AppRoutes.login))
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (error != null) ...[
                          AuthErrorBanner(message: error),
                          const SizedBox(height: 16),
                        ],
                        PlumoraTextField(
                          controller: _tokenController,
                          label: 'Code de réinitialisation',
                          hint: 'Reçu par email',
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Code requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        PlumoraTextField(
                          controller: _passwordController,
                          label: 'Nouveau mot de passe',
                          hint: '••••••••',
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if ((value ?? '').length < 8) {
                              return '8 caractères minimum';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        PlumoraTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmer le mot de passe',
                          hint: '••••••••',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => isLoading ? null : _submit(),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: LoadingButtonChild(
                            label: 'Réinitialiser le mot de passe',
                            isLoading: isLoading,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DoneContent extends StatelessWidget {
  const _DoneContent({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: context.colors.success.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            color: context.colors.success,
            size: 28,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Ton mot de passe a été réinitialisé avec succès.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onLogin,
            child: const Text('Se connecter'),
          ),
        ),
      ],
    );
  }
}
