import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    show GoogleSignInCredentials;

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../data/models/login_request.dart';
import '../data/models/role_model.dart';
import '../data/services/google_auth_service.dart';
import 'controllers/auth_controller.dart';
import 'widgets/auth_screen_shell.dart';

/// ADMIN accounts land directly in the Administration space rather than the
/// regular home dashboard — they never see the reader/author app (see
/// `AdminRouteGuard`, which also enforces this on every subsequent
/// navigation, not just this first redirect).
String _postLoginDestination(List<RoleModel> roles) {
  if (roles.any((role) => role.name.trim().toUpperCase() == 'ADMIN')) {
    return AppRoutes.admin;
  }
  return roles.isEmpty ? AppRoutes.roleSelection : AppRoutes.home;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Built once (not per-build): Google Identity Services' web SDK renders
  // this into its own DOM node, so recreating it on every rebuild would
  // tear down and re-mount that node for no reason. Null on non-web
  // platforms, where the native flow drives itself from a plain button
  // instead (see _submitGoogle).
  Widget? _webGoogleSignInButton;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _webGoogleSignInButton = ref
          .read(googleAuthServiceProvider)
          .webSignInButton(onSignIn: _onGoogleCredentials);
    }
  }

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

    context.go(_postLoginDestination(session!.roles));
  }

  Future<void> _submitGoogle() async {
    await ref.read(authControllerProvider.notifier).loginWithGoogle();

    final session = ref.read(authControllerProvider).valueOrNull;
    if (!mounted || session?.isAuthenticated != true) {
      return;
    }

    context.go(_postLoginDestination(session!.roles));
  }

  /// Web counterpart of [_submitGoogle]: called once Google Identity
  /// Services' own button (see [_webGoogleSignInButton]) has already
  /// completed the browser-side flow and handed back credentials.
  Future<void> _onGoogleCredentials(GoogleSignInCredentials credentials) async {
    final idToken = credentials.idToken;
    if (idToken == null || idToken.isEmpty) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .loginWithGoogleIdToken(idToken);

    final session = ref.read(authControllerProvider).valueOrNull;
    if (!mounted || session?.isAuthenticated != true) {
      return;
    }

    context.go(_postLoginDestination(session!.roles));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final error = authState.hasError
        ? AppError.messageFor(authState.error!)
        : null;

    return AuthScreenShell(
      topPadding: 72,
      horizontalPadding: 16,
      bottomPadding: 32,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FigmaBackButton(
              label: 'Retour',
              onTap: () => returnToPreviousOr(context, AppRoutes.landing),
            ),
          ),
          const SizedBox(height: 18),
          const _PlumoraLetterMark(),
          const SizedBox(height: 24),
          Text(
            'Bienvenue sur Plumora',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Connectez-vous pour continuer votre aventure littéraire',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 30),
          FigmaCard(
            padding: const EdgeInsets.all(30),
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
                  const SizedBox(height: 18),
                  PlumoraTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    hint: '********',
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
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 22),
                  const AuthDivider(),
                  const SizedBox(height: 18),
                  if (_webGoogleSignInButton != null)
                    SizedBox(
                      height: 40,
                      child: Opacity(
                        opacity: isLoading ? 0.6 : 1,
                        child: IgnorePointer(
                          ignoring: isLoading,
                          child: Center(child: _webGoogleSignInButton),
                        ),
                      ),
                    )
                  else
                    _SocialButton(
                      icon: const GoogleLogo(),
                      label: 'Continuer avec Google',
                      onPressed: isLoading ? null : _submitGoogle,
                    ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    icon: Icon(Icons.code, color: context.colors.textPrimary),
                    label: 'Continuer avec GitHub',
                    onPressed: isLoading
                        ? null
                        : () => context.go(AppRoutes.roleSelection),
                  ),
                  const SizedBox(height: 22),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.push(AppRoutes.register),
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

class _PlumoraLetterMark extends StatelessWidget {
  const _PlumoraLetterMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'P',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colors.textPrimary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 18, height: 18, child: Center(child: icon)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
