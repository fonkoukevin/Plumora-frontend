import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../data/models/register_request.dart';
import 'controllers/auth_controller.dart';
import 'widgets/auth_screen_shell.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final nameParts = _fullNameController.text.trim().split(RegExp(r'\s+'));

    await ref
        .read(authControllerProvider.notifier)
        .register(
          RegisterRequest(
            firstname: nameParts.first,
            lastname: nameParts.skip(1).join(' '),
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );

    final session = ref.read(authControllerProvider).valueOrNull;
    if (!mounted || session?.isAuthenticated != true) {
      return;
    }

    context.go(AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final error = authState.hasError
        ? AppError.messageFor(authState.error!)
        : null;

    return AuthScreenShell(
      topPadding: 58,
      horizontalPadding: 16,
      bottomPadding: 32,
      child: Column(
        children: [
          const AppWordmark(iconSize: 32, textSize: 36, gap: 8),
          const SizedBox(height: 16),
          const Text(
            'Créez votre compte',
            style: TextStyle(
              color: PlumoraColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 32),
          FigmaCard(
            padding: const EdgeInsets.all(32),
            shadow: true,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null) ...[
                    AuthErrorBanner(message: error),
                    const SizedBox(height: 16),
                  ],
                  PlumoraTextField(
                    controller: _fullNameController,
                    label: 'Nom complet',
                    hint: 'Kevin Martin',
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final trimmed = (value ?? '').trim();
                      if (trimmed.isEmpty) {
                        return 'Nom complet requis';
                      }
                      if (!trimmed.contains(RegExp(r'\s'))) {
                        return 'Indiquez votre prenom et votre nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  PlumoraTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'votre@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return 'Email requis';
                      }
                      if (!email.contains('@')) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  PlumoraTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    hint: '••••••••',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final password = value ?? '';
                      if (password.length < 8) {
                        return '8 caracteres minimum';
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
                      label: 'Créer mon compte',
                      isLoading: isLoading,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Déjà un compte ? ',
                        style: TextStyle(
                          color: PlumoraColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.go(AppRoutes.login),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Se connecter'),
                      ),
                    ],
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
