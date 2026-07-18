import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/figma_plumora.dart';
import '../../auth/data/models/update_profile_request.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../auth/presentation/widgets/auth_screen_shell.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _avatarUrl;
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefilled) {
      _prefilled = true;
      final user = ref.read(authControllerProvider).valueOrNull?.user;
      _firstnameController.text = user?.firstname ?? '';
      _lastnameController.text = user?.lastname ?? '';
      _usernameController.text = user?.username ?? '';
      _bioController.text = user?.bio ?? '';
      _avatarUrl = user?.avatarUrl;
    }
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          UpdateProfileRequest(
            firstname: _firstnameController.text,
            lastname: _lastnameController.text,
            username: _usernameController.text,
            bio: _bioController.text,
            avatarUrl: _avatarUrl,
          ),
        );

    if (!mounted || ref.read(authControllerProvider).hasError) {
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profile);
    }
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
          Align(
            alignment: Alignment.centerLeft,
            child: FigmaBackButton(
              label: 'Retour',
              onTap: () => returnToPreviousOr(context, AppRoutes.profile),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Modifier mes informations',
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
            'Prénom, nom, nom utilisateur et biographie',
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
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 18),
                  PlumoraTextField(
                    controller: _usernameController,
                    label: 'Nom utilisateur',
                    hint: 'kevin.martin',
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return "Nom d'utilisateur requis";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  PlumoraTextField(
                    controller: _bioController,
                    label: 'Biographie',
                    hint: 'Parle un peu de toi...',
                    textInputAction: TextInputAction.done,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: LoadingButtonChild(
                      label: 'Enregistrer',
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
