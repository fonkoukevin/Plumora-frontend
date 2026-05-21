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
      child: Column(
        children: [
          const PlumoraLogo(compact: true),
          const SizedBox(height: 10),
          Text(
            'Créez votre compte',
            style: textTheme.bodyMedium?.copyWith(
              color: PlumoraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null) ...[
                      AuthErrorBanner(message: error),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _firstnameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        hintText: 'Kevin',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Prénom requis';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastnameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        hintText: 'Martin',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Nom requis';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'votre@email.com',
                      ),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                      ),
                      validator: (value) {
                        final password = value ?? '';
                        if (password.length < 8) {
                          return '8 caracteres minimum';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => isLoading ? null : _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                      ),
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
          ),
        ],
      ),
    );
  }
}
