import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import 'controllers/password_reset_controller.dart';
import 'widgets/auth_screen_shell.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(passwordResetRequestControllerProvider.notifier)
        .submit(_emailController.text);

    if (!mounted) {
      return;
    }
    if (!ref.read(passwordResetRequestControllerProvider).hasError) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetRequestControllerProvider);
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
            'Mot de passe oublié ?',
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
            'Indique ton adresse email, nous t’enverrons un lien pour réinitialiser ton mot de passe.',
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
            child: _emailSent
                ? _ConfirmationContent(email: _emailController.text.trim())
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
                          controller: _emailController,
                          label: 'Adresse email',
                          hint: 'votre@email.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => isLoading ? null : _submit(),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Adresse email requise';
                            if (!email.contains('@')) {
                              return 'Adresse email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: LoadingButtonChild(
                            label: 'Envoyer le lien',
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

class _ConfirmationContent extends StatelessWidget {
  const _ConfirmationContent({required this.email});

  final String email;

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
            Icons.mark_email_read_outlined,
            color: context.colors.success,
            size: 28,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          email.isEmpty
              ? 'Si un compte existe avec cette adresse, un email de réinitialisation vient de t’être envoyé.'
              : 'Si un compte existe pour $email, un email de réinitialisation vient de t’être envoyé.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifie aussi tes courriers indésirables.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Retour à la connexion'),
          ),
        ),
      ],
    );
  }
}
