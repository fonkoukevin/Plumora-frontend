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

    context.go(AppRoutes.home);
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PlumoraColors.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.draw_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Bienvenue sur Plumora',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connectez-vous pour continuer votre aventure littéraire',
            textAlign: TextAlign.center,
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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Adresse email',
                        hintText: 'votre@email.com',
                      ),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => isLoading ? null : _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                      ),
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Mot de passe requis';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ou',
                            style: textTheme.bodySmall?.copyWith(
                              color: PlumoraColors.textSecondary,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : () {},
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('Continuer avec Google'),
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
          ),
        ],
      ),
    );
  }
}
