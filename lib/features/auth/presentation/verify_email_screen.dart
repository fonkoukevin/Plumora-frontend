import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import 'controllers/email_verification_controller.dart';
import 'widgets/auth_screen_shell.dart';

/// Reached from the link sent by the registration confirmation email —
/// [token] is prefilled from the `?token=` query param and submitted
/// automatically on load (no other input is needed, unlike
/// ResetPasswordScreen). The field stays editable so a user who
/// copy-pastes the code by hand (e.g. it didn't deep-link cleanly, notably
/// on mobile — see ResetPasswordScreen's identical rationale) can still
/// complete the flow.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({this.token, super.key});

  final String? token;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _tokenController = TextEditingController(text: widget.token);
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if ((widget.token ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(verifyEmailControllerProvider.notifier)
        .submit(_tokenController.text);

    if (!mounted) {
      return;
    }
    if (!ref.read(verifyEmailControllerProvider).hasError) {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyEmailControllerProvider);
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
            'Confirmation du compte',
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
            'Nous confirmons ton adresse email à partir du lien reçu.',
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
                ? _VerifiedContent(onLogin: () => context.go(AppRoutes.login))
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
                          label: 'Code de confirmation',
                          hint: 'Reçu par email',
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => isLoading ? null : _submit(),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Code requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: LoadingButtonChild(
                            label: 'Confirmer mon compte',
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

class _VerifiedContent extends StatelessWidget {
  const _VerifiedContent({required this.onLogin});

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
          'Ton adresse email a été confirmée avec succès.',
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
