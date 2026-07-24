import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    show GoogleSignInCredentials;

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_logo_mark.dart';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? context.colors.background
          : const Color(0xFFF8F6FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final compact = viewport.maxWidth < 820;
            final horizontalPadding = compact ? 16.0 : 32.0;
            final verticalPadding = viewport.maxHeight < 720 ? 16.0 : 28.0;
            final minimumHeight = viewport.maxHeight - (verticalPadding * 2);
            final minimumWidth = viewport.maxWidth - (horizontalPadding * 2);

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const ValueKey('login_page_background'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  context.colors.background,
                                  context.colors.primary.withValues(
                                    alpha: 0.10,
                                  ),
                                  context.colors.background,
                                ]
                              : const [
                                  Color(0xFFF8F6FF),
                                  Color(0xFFF0EBFF),
                                  Color(0xFFFFFBF5),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -110,
                  right: -80,
                  child: IgnorePointer(
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.primary.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minimumHeight > 0 ? minimumHeight : 0,
                      minWidth: minimumWidth > 0 ? minimumWidth : 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FigmaBackButton(
                              label: 'Retour',
                              onTap: () => returnToPreviousOr(
                                context,
                                AppRoutes.landing,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: _LoginSplitCard(
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            error: error,
                            isLoading: isLoading,
                            onSubmit: _submit,
                            onGoogle: _submitGoogle,
                            googleSignInButton: _webGoogleSignInButton,
                            onRegister: () => context.push(AppRoutes.register),
                            onForgotPassword: () =>
                                context.push(AppRoutes.forgotPassword),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoginSplitCard extends StatelessWidget {
  const _LoginSplitCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.error,
    required this.isLoading,
    required this.onSubmit,
    required this.onGoogle,
    this.googleSignInButton,
    required this.onRegister,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? error;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final Widget? googleSignInButton;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 820;
        final form = _LoginFormPane(
          compact: !desktop,
          formKey: formKey,
          emailController: emailController,
          passwordController: passwordController,
          error: error,
          isLoading: isLoading,
          onSubmit: onSubmit,
          onGoogle: onGoogle,
          googleSignInButton: googleSignInButton,
          onRegister: onRegister,
          onForgotPassword: onForgotPassword,
        );

        return Container(
          key: const ValueKey('login_split_card'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colors.cards,
            borderRadius: BorderRadius.circular(desktop ? 28 : 22),
            border: Border.all(color: context.elevatedBorderColor),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.38)
                    : const Color(0x290F0824),
                blurRadius: desktop ? 34 : 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: desktop
              ? SizedBox(
                  key: const ValueKey('login_desktop_layout'),
                  height: 620,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(
                        flex: 10,
                        child: _LoginBrandPanel(compact: false),
                      ),
                      Expanded(flex: 9, child: form),
                    ],
                  ),
                )
              : Column(
                  key: const ValueKey('login_mobile_layout'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 220,
                      child: _LoginBrandPanel(compact: true),
                    ),
                    form,
                  ],
                ),
        );
      },
    );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('login_brand_panel'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primaryDark,
            context.colors.primary,
            Color.lerp(
              context.colors.primary,
              context.colors.plumoAccent,
              0.38,
            )!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -54,
            child: Container(
              width: compact ? 170 : 250,
              height: compact ? 170 : 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.055),
              ),
            ),
          ),
          Positioned(
            left: -58,
            bottom: -72,
            child: Container(
              width: compact ? 150 : 230,
              height: compact ? 150 : 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.accent.withValues(alpha: 0.09),
              ),
            ),
          ),
          Padding(
            padding: compact
                ? const EdgeInsets.fromLTRB(24, 20, 20, 20)
                : const EdgeInsets.fromLTRB(42, 38, 42, 34),
            child: compact
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final showIllustration = constraints.maxWidth >= 330;
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _PlumoraWhiteBrand(compact: true),
                                const Spacer(),
                                const Text(
                                  'Les histoires nous rassemblent.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Écrivez • Lisez • Partagez',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (showIllustration) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 145,
                              child: _LiteraryCommunityIllustration(
                                compact: true,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PlumoraWhiteBrand(compact: false),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 330),
                            child: _LiteraryCommunityIllustration(
                              compact: false,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Les histoires nous rassemblent.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 9),
                      Text(
                        'Écrivez, découvrez et partagez des mondes qui vous ressemblent.',
                        style: TextStyle(
                          color: Color(0xC9FFFFFF),
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlumoraWhiteBrand extends StatelessWidget {
  const _PlumoraWhiteBrand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Plumora',
      header: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 38 : 46,
            height: compact ? 38 : 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(compact ? 11 : 13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Center(
              child: PlumoraLogoMark(
                size: compact ? 22 : 27,
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
          SizedBox(width: compact ? 10 : 12),
          Text(
            'Plumora',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: compact ? 25 : 31,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiteraryCommunityIllustration extends StatelessWidget {
  const _LiteraryCommunityIllustration({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 34.0 : 58.0;
    final globeSize = compact ? 88.0 : 172.0;

    return AspectRatio(
      aspectRatio: compact ? 1.05 : 1.12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Container(
              width: globeSize,
              height: globeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8F7CFF), Color(0xFF4932B9)],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D1263).withValues(alpha: 0.30),
                    blurRadius: compact ? 14 : 28,
                    offset: Offset(0, compact ? 7 : 15),
                  ),
                ],
              ),
              child: Icon(
                Icons.public_rounded,
                color: Colors.white.withValues(alpha: 0.76),
                size: compact ? 60 : 118,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.78),
            child: Container(
              width: compact ? 48 : 78,
              height: compact ? 38 : 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(compact ? 10 : 14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x320F0824),
                    blurRadius: 14,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                color: context.colors.primary,
                size: compact ? 25 : 40,
              ),
            ),
          ),
          Positioned(
            left: compact ? 4 : 14,
            top: compact ? 15 : 28,
            child: _CommunityAvatar(
              size: avatarSize,
              colors: const [Color(0xFFEAB54D), Color(0xFFE87945)],
            ),
          ),
          Positioned(
            right: compact ? 4 : 8,
            top: compact ? 8 : 17,
            child: _CommunityAvatar(
              size: avatarSize,
              colors: const [Color(0xFF63D0C2), Color(0xFF258B91)],
            ),
          ),
          Positioned(
            left: compact ? 0 : 3,
            bottom: compact ? 6 : 17,
            child: _CommunityAvatar(
              size: avatarSize,
              colors: const [Color(0xFFF48FB1), Color(0xFFC24787)],
            ),
          ),
          Positioned(
            right: compact ? 0 : 2,
            bottom: compact ? 10 : 25,
            child: _CommunityAvatar(
              size: avatarSize,
              colors: const [Color(0xFF9CA5FF), Color(0xFF6067C8)],
            ),
          ),
          Positioned(
            top: compact ? 1 : 8,
            left: compact ? 58 : 132,
            child: Icon(
              Icons.auto_awesome,
              color: context.colors.accent,
              size: compact ? 13 : 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityAvatar extends StatelessWidget {
  const _CommunityAvatar({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: size > 40 ? 3 : 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x300F0824),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.person_rounded, color: Colors.white, size: size * 0.62),
    );
  }
}

class _LoginFormPane extends StatelessWidget {
  const _LoginFormPane({
    required this.compact,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.error,
    required this.isLoading,
    required this.onSubmit,
    required this.onGoogle,
    this.googleSignInButton,
    required this.onRegister,
    required this.onForgotPassword,
  });

  final bool compact;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? error;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final Widget? googleSignInButton;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final content = Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Connexion',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: compact ? 28 : 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Heureux de vous retrouver dans votre univers littéraire.',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: compact ? 26 : 30),
          if (error != null) ...[
            AuthErrorBanner(message: error!),
            const SizedBox(height: 16),
          ],
          _LoginTextField(
            controller: emailController,
            label: 'Adresse email',
            hint: 'votre@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Adresse email requise';
              if (!email.contains('@')) return 'Adresse email invalide';
              return null;
            },
          ),
          const SizedBox(height: 17),
          _LoginTextField(
            controller: passwordController,
            label: 'Mot de passe',
            hint: '••••••••',
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
            validator: (value) {
              if ((value ?? '').isEmpty) return 'Mot de passe requis';
              return null;
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : onForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              child: const Text('Mot de passe oublié ?'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: LoadingButtonChild(
                label: 'Connexion',
                isLoading: isLoading,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const AuthDivider(),
          const SizedBox(height: 18),
          if (googleSignInButton != null)
            SizedBox(
              height: 40,
              child: Opacity(
                opacity: isLoading ? 0.6 : 1,
                child: IgnorePointer(
                  ignoring: isLoading,
                  child: Center(child: googleSignInButton),
                ),
              ),
            )
          else
            _SocialButton(
              icon: const GoogleLogo(),
              label: 'Connexion avec Google',
              onPressed: isLoading ? null : onGoogle,
            ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Pas de compte ?',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                ),
              ),
              TextButton(
                onPressed: isLoading ? null : onRegister,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 38),
                ),
                child: const Text('Créer un compte'),
              ),
            ],
          ),
        ],
      ),
    );

    final padding = compact
        ? const EdgeInsets.fromLTRB(24, 30, 24, 26)
        : const EdgeInsets.fromLTRB(48, 42, 48, 36);

    return Container(
      key: const ValueKey('login_form_panel'),
      color: context.colors.cards,
      child: compact
          ? Padding(padding: padding, child: content)
          : SingleChildScrollView(padding: padding, child: content),
    );
  }
}

class _LoginTextField extends StatefulWidget {
  const _LoginTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<_LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<_LoginTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText && _obscured,
          validator: widget.validator,
          onFieldSubmitted: widget.onFieldSubmitted,
          autofillHints: widget.obscureText
              ? const [AutofillHints.password]
              : const [AutofillHints.email],
          autocorrect: false,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: context.colors.inputBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            constraints: const BoxConstraints(minHeight: 52),
            suffixIcon: widget.obscureText
                ? Semantics(
                    button: true,
                    label: _obscured
                        ? 'Afficher le mot de passe'
                        : 'Masquer le mot de passe',
                    child: IconButton(
                      tooltip: _obscured
                          ? 'Afficher le mot de passe'
                          : 'Masquer le mot de passe',
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    ),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: radius),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: context.colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: context.colors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: context.colors.destructive),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: context.colors.destructive,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
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
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return context.colors.primary.withValues(alpha: 0.08);
            }
            return context.colors.inputBackground;
          }),
          foregroundColor: WidgetStatePropertyAll(context.colors.textPrimary),
          overlayColor: WidgetStatePropertyAll(
            context.colors.primary.withValues(alpha: 0.08),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            return BorderSide(
              color: states.contains(WidgetState.hovered)
                  ? context.colors.primary.withValues(alpha: 0.55)
                  : context.colors.border,
            );
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 18, height: 18, child: Center(child: icon)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
