import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../../core/widgets/plumora_logo_mark.dart';
import '../data/models/register_request.dart';
import 'controllers/email_verification_controller.dart';
import 'controllers/register_controller.dart';
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
  bool _registered = false;

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
        .read(registerControllerProvider.notifier)
        .submit(
          RegisterRequest(
            firstname: nameParts.first,
            lastname: nameParts.skip(1).join(' '),
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );

    if (!mounted) {
      return;
    }
    if (!ref.read(registerControllerProvider).hasError) {
      setState(() => _registered = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);
    final isLoading = registerState.isLoading;
    final error = registerState.hasError
        ? AppError.messageFor(registerState.error!)
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? context.colors.background
          : const Color(0xFFF8F6FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final compact = viewport.maxWidth < 620;
            final horizontalPadding = compact ? 16.0 : 28.0;
            final verticalPadding = viewport.maxHeight < 720 ? 16.0 : 28.0;
            final minimumHeight = viewport.maxHeight - (verticalPadding * 2);
            final minimumWidth = viewport.maxWidth - (horizontalPadding * 2);

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const ValueKey('register_page_background'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  context.colors.background,
                                  context.colors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  context.colors.background,
                                ]
                              : const [
                                  Color(0xFFF8F6FF),
                                  Color(0xFFF1EDFF),
                                  Color(0xFFFFFCF7),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -90,
                  bottom: -120,
                  child: IgnorePointer(
                    child: Container(
                      width: 310,
                      height: 310,
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.055),
                        shape: BoxShape.circle,
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
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FigmaBackButton(
                              label: 'Retour',
                              onTap: () =>
                                  returnToPreviousOr(context, AppRoutes.login),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: _RegisterCard(
                            formKey: _formKey,
                            fullNameController: _fullNameController,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            confirmPasswordController:
                                _confirmPasswordController,
                            error: error,
                            isLoading: isLoading,
                            registered: _registered,
                            onSubmit: _submit,
                            onLogin: () => context.go(AppRoutes.login),
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

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.error,
    required this.isLoading,
    required this.registered,
    required this.onSubmit,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? error;
  final bool isLoading;
  final bool registered;
  final VoidCallback onSubmit;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return Container(
          key: const ValueKey('register_card'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colors.cards,
            borderRadius: BorderRadius.circular(compact ? 20 : 24),
            border: Border.all(color: context.elevatedBorderColor),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.34)
                    : const Color(0x240F0824),
                blurRadius: compact ? 20 : 30,
                offset: const Offset(0, 13),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RegisterHeader(compact: compact),
              if (registered)
                _RegisterConfirmation(
                  email: emailController.text.trim(),
                  onLogin: onLogin,
                )
              else
                _RegisterForm(
                  compact: compact,
                  formKey: formKey,
                  fullNameController: fullNameController,
                  emailController: emailController,
                  passwordController: passwordController,
                  confirmPasswordController: confirmPasswordController,
                  error: error,
                  isLoading: isLoading,
                  onSubmit: onSubmit,
                  onLogin: onLogin,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('register_brand_header'),
      width: double.infinity,
      height: compact ? 166 : 154,
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
              0.28,
            )!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -28,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.065),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: compact ? 22 : 34,
            bottom: compact ? 19 : 25,
            child: Icon(
              Icons.auto_awesome,
              color: context.colors.accent,
              size: compact ? 22 : 26,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 24 : 34,
              compact ? 20 : 23,
              compact ? 24 : 34,
              compact ? 18 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: compact ? 36 : 40,
                      height: compact ? 36 : 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Center(
                        child: PlumoraLogoMark(
                          size: compact ? 21 : 24,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Plumora',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: compact ? 24 : 27,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Créez votre compte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre prochaine histoire commence ici.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 12,
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

/// Shown in place of the form once registration succeeds: the new account
/// starts unverified, so this replaces the previous auto-login redirect to
/// role selection with instructions to confirm the emailed link first.
/// Mirrors `ForgotPasswordScreen`'s `_ConfirmationContent`.
class _RegisterConfirmation extends ConsumerStatefulWidget {
  const _RegisterConfirmation({required this.email, required this.onLogin});

  final String email;
  final VoidCallback onLogin;

  @override
  ConsumerState<_RegisterConfirmation> createState() =>
      _RegisterConfirmationState();
}

class _RegisterConfirmationState extends ConsumerState<_RegisterConfirmation> {
  bool _resent = false;

  Future<void> _resend() async {
    await ref
        .read(resendVerificationControllerProvider.notifier)
        .submit(widget.email);

    if (!mounted) {
      return;
    }
    if (!ref.read(resendVerificationControllerProvider).hasError) {
      setState(() => _resent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resendState = ref.watch(resendVerificationControllerProvider);
    final isResending = resendState.isLoading;
    final resendError = resendState.hasError
        ? AppError.messageFor(resendState.error!)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 27, 24, 24),
      child: Column(
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
            'Ton compte a été créé !',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.email.isEmpty
                ? 'Vérifie tes emails pour confirmer ton adresse avant de te connecter.'
                : 'Un email de confirmation a été envoyé à ${widget.email}. Clique sur le lien qu\'il contient pour activer ton compte avant de te connecter.',
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
          if (resendError != null) ...[
            AuthErrorBanner(message: resendError),
            const SizedBox(height: 14),
          ],
          if (_resent) ...[
            Text(
              'Email de confirmation renvoyé.',
              style: TextStyle(
                color: context.colors.success,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isResending ? null : _resend,
              child: LoadingButtonChild(
                label: 'Renvoyer l\'email de confirmation',
                isLoading: isResending,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onLogin,
              child: const Text('Aller à la connexion'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.compact,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.error,
    required this.isLoading,
    required this.onSubmit,
    required this.onLogin,
  });

  final bool compact;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? error;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final fullNameField = _RegisterTextField(
      controller: fullNameController,
      label: 'Nom complet',
      hint: 'Kevin Martin',
      textInputAction: TextInputAction.next,
      validator: (value) {
        final trimmed = (value ?? '').trim();
        if (trimmed.isEmpty) return 'Nom complet requis';
        if (!trimmed.contains(RegExp(r'\s'))) {
          return 'Indiquez votre prénom et votre nom';
        }
        return null;
      },
    );
    final emailField = _RegisterTextField(
      controller: emailController,
      label: 'Adresse email',
      hint: 'votre@email.com',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) return 'Email requis';
        if (!email.contains('@')) return 'Email invalide';
        return null;
      },
    );
    final passwordField = _RegisterTextField(
      controller: passwordController,
      label: 'Mot de passe',
      hint: '••••••••',
      obscureText: true,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if ((value ?? '').length < 8) return '8 caractères minimum';
        return null;
      },
    );
    final confirmationField = _RegisterTextField(
      controller: confirmPasswordController,
      label: 'Confirmer le mot de passe',
      hint: '••••••••',
      obscureText: true,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
      validator: (value) {
        if (value != passwordController.text) {
          return 'Les mots de passe ne correspondent pas';
        }
        return null;
      },
    );

    return Container(
      key: const ValueKey('register_form_panel'),
      width: double.infinity,
      color: context.colors.cards,
      padding: EdgeInsets.fromLTRB(
        compact ? 24 : 34,
        compact ? 27 : 30,
        compact ? 24 : 34,
        compact ? 24 : 28,
      ),
      child: AutofillGroup(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quelques informations et vous pourrez commencer.',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              if (error != null) ...[
                AuthErrorBanner(message: error!),
                const SizedBox(height: 16),
              ],
              if (compact) ...[
                fullNameField,
                const SizedBox(height: 17),
                emailField,
                const SizedBox(height: 17),
                passwordField,
                const SizedBox(height: 17),
                confirmationField,
              ] else ...[
                Row(
                  key: const ValueKey('register_name_email_row'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: fullNameField),
                    const SizedBox(width: 18),
                    Expanded(child: emailField),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  key: const ValueKey('register_password_row'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: passwordField),
                    const SizedBox(width: 18),
                    Expanded(child: confirmationField),
                  ],
                ),
              ],
              const SizedBox(height: 25),
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
                    label: 'Créer mon compte',
                    isLoading: isLoading,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Déjà un compte ?',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : onLogin,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 38),
                    ),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterTextField extends StatefulWidget {
  const _RegisterTextField({
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
  State<_RegisterTextField> createState() => _RegisterTextFieldState();
}

class _RegisterTextFieldState extends State<_RegisterTextField> {
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
              ? const [AutofillHints.newPassword]
              : widget.keyboardType == TextInputType.emailAddress
              ? const [AutofillHints.email]
              : const [AutofillHints.name],
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
