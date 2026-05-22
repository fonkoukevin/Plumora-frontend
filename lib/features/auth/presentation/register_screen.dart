import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
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
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .register(
          RegisterRequest(
            firstname: _firstnameController.text,
            lastname: _lastnameController.text,
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
    final textTheme = Theme.of(context).textTheme;

    return AuthScreenShell(
      topPadding: 108,
      horizontalPadding: 16,
      bottomPadding: 32,
      child: Column(
        children: [
          const AppWordmark(compact: true),
          const SizedBox(height: 15),
          Text(
            'Créez votre compte',
            style: textTheme.bodyMedium?.copyWith(
              color: PlumoraColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          AuthFormCard(
            padding: const EdgeInsets.fromLTRB(25, 27, 25, 22),
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
                    controller: _firstnameController,
                    label: 'Prénom',
                    hint: 'Kevin',
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Prénom requis';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 17),
                  PlumoraTextField(
                    controller: _lastnameController,
                    label: 'Nom',
                    hint: 'Martin',
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Nom requis';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 17),
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
                  const SizedBox(height: 17),
                  PlumoraTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
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
                  const SizedBox(height: 17),
                  PlumoraTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmer le mot de passe',
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
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: LoadingButtonChild(
                      label: 'Créer mon compte',
                      isLoading: isLoading,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.go(AppRoutes.login),
                    child: const Text('Déjà un compte ? Se connecter'),
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
