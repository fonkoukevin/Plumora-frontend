import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../data/models/login_request.dart';
import 'controllers/auth_controller.dart';
import 'widgets/auth_screen_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .login(
          LoginRequest(
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
      topPadding: 124,
      horizontalPadding: 44,
      bottomPadding: 32,
      child: Column(
        children: [
          const BrandIconBox(),
          const SizedBox(height: 22),
          Text(
            'Bienvenue sur Plumora',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Connectez-vous pour continuer votre aventure littéraire',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: PlumoraColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          AuthFormCard(
            padding: const EdgeInsets.fromLTRB(25, 28, 25, 23),
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
                    controller: _emailController,
                    label: 'Adresse email',
                    hint: 'votre@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return 'Adresse email requise';
                      }
                      if (!email.contains('@')) {
                        return 'Adresse email invalide';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 17),
                  PlumoraTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => isLoading ? null : _submit(),
                    validator: (value) {
                      if ((value ?? '').isEmpty) {
                        return 'Mot de passe requis';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 11),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : () {},
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: LoadingButtonChild(
                      label: 'Se connecter',
                      isLoading: isLoading,
                    ),
                  ),
                  const SizedBox(height: 19),
                  const AuthDivider(),
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: isLoading ? null : () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GoogleLogo(),
                        const SizedBox(width: 11),
                        Text(
                          'Continuer avec Google',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.go(AppRoutes.register),
                    child: const Text("Pas encore de compte ? S'inscrire"),
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
